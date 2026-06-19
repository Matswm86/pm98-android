extends SceneTree
## Oracle-backed parity test for FUN_005b73a0 slice B (the phase-3 kickoff/restart positioning
## branch), ported in Pm98Movement._position_phase3 (via position_team).
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_phase3.gd
##
## ORACLE = the REAL FUN_005b73a0 phase-3 under the Ghidra PCode emulator (relmatrix throttle-skipped,
## atan LUT injected, RNG seed @0x6d3184), tools/re/run_phase3_oracle.sh -> specs/phase3_oracle.txt.
## Players live at base 0x240000, stride 0x3bc (P0=taker @0x240000, P1 @0x2403bc, P2 @0x240778).

const U32 := 0xffffffff
const BASE := 0x240000
const STRIDE := 0x3bc
const FIX := {
	"our_jitter": {"k": "our", "seed": 12345},
	"our_seed1":  {"k": "our", "seed": 1},
	"else_min":   {"k": "else"},
}

var _fail := 0
var _pass := 0


func _init() -> void:
	var orc := _load_oracle()
	if orc.is_empty():
		_ok(false, "phase3 oracle file empty/unreadable")
	else:
		for name in FIX:
			if not orc.has(name):
				_ok(false, name + ": missing from oracle file")
				continue
			_run(name, orc[name])
	print("")
	if _fail == 0:
		print("ALL PASS (%d checks)" % _pass)
	else:
		print("FAILED: %d / %d" % [_fail, _pass + _fail])
	quit(1 if _fail > 0 else 0)


func _ok(cond: bool, msg: String) -> void:
	if cond:
		_pass += 1
	else:
		_fail += 1
		print("  [FAIL] ", msg)


func _spec_path(n: String) -> String:
	return ProjectSettings.globalize_path("res://").path_join("../tools/re/specs/").path_join(n).simplify_path()


# Parse "FIX <name> ... mem[0xADDR:W]=val": row -> {absolute_addr: value}.
func _load_oracle() -> Dictionary:
	var out := {}
	var f := FileAccess.open(_spec_path("phase3_oracle.txt"), FileAccess.READ)
	if f == null:
		return {}
	var rx := RegEx.new()
	rx.compile("mem\\[0x([0-9a-fA-F]+):[0-9]+\\]=(-?[0-9]+)")
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if not line.begins_with("FIX "):
			continue
		var toks := line.split(" ", false)
		var row := {}
		for mtch in rx.search_all(line):
			row[("0x" + mtch.get_string(1)).hex_to_int()] = mtch.get_string(2).to_int()
		out[toks[1]] = row
	return out


# Compare players[idx][off] against the banked value at the player's absolute address.
func _chk(name: String, players: Array, idx: int, off: int, exp: Dictionary) -> void:
	var addr := BASE + idx * STRIDE + off
	if not exp.has(addr):
		return
	var got := int((players[idx] as Dictionary).get(off, 0)) & U32
	var want := int(exp[addr]) & U32
	_ok(got == want, "%s P%d+0x%x: got 0x%x want 0x%x" % [name, idx, off, got, want])


func _run(name: String, exp: Dictionary) -> void:
	var fx: Dictionary = FIX[name]
	var m := {0x448: 3, 0x19a0: 0, 0x1820: 0x140000}
	var players := []
	for i in 3:
		players.append({0x4: 0, 0x8: 0, 0xc: 0, 0x2bc: 1, 0x18c: m, 0x34: 0, 0x64: 0})
	m[0x438] = players[0]                                     # taker = P0
	var ctx := {0x0: 0, 0x4: 3, 0x8: 0, 0x138: m, 0x2e0: 0, "players": players}

	if fx["k"] == "our":
		m[0x45c] = 0                                         # our team has the set-piece
		players[1][0x4] = 0x50000; players[1][0x8] = 0x20000
		players[2][0x4] = 0x30000; players[2][0x8] = 0x40000   # P2 nearest (|0x30000| < |0x50000|)
		Pm98Movement.position_team(ctx, MatchEngine.Pm98Rng.new(int(fx["seed"])))
		_chk(name, players, 2, 0x4, exp)                     # P2.x jittered
		_chk(name, players, 2, 0x8, exp)                     # P2.y jittered
		_chk(name, players, 0, 0x34, exp)                    # taker (P0) facing
	else:
		m[0x45c] = 1                                         # opponent's set-piece
		players[0][0x4] = 0x20000                            # taker.x
		players[1][0x4] = 0x60000                            # role.x (role = ctx[0x200] = index 1)
		ctx[0x200] = 1
		Pm98Movement.position_team(ctx, null)
		_chk(name, players, 1, 0x4, exp)                     # role.x clamped to min(role.x, taker.x)
		_chk(name, players, 1, 0x8, exp)                     # role.y = 0
