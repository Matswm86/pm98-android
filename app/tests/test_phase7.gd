extends SceneTree
## Oracle-backed parity test for FUN_005b73a0 slice C (the phase-7 scatter sub-branch,
## match+0x19a0 == 4), ported in Pm98Movement._position_phase7 (via position_team).
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_phase7.gd
##
## ORACLE = the REAL FUN_005b73a0 phase-7 under the Ghidra PCode emulator (relmatrix throttle-skipped,
## cos LUT injected, RNG seed @0x6d3184), tools/re/run_phase7_oracle.sh -> specs/phase7_oracle.txt.
## Players: base 0x240000, stride 0x3bc (P0=taker @0x240000, P1 @0x2403bc, P2 @0x240778).

const U32 := 0xffffffff
const BASE := 0x240000
const STRIDE := 0x3bc
const FIX := {
	"scatter_seed1": {"k": "all_on", "seed": 1},
	"offpitch_skip": {"k": "off", "seed": 1},
}

var _fail := 0
var _pass := 0


func _init() -> void:
	var orc := _load_oracle()
	if orc.is_empty():
		_ok(false, "phase7 oracle file empty/unreadable")
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


func _load_oracle() -> Dictionary:
	var out := {}
	var f := FileAccess.open(_spec_path("phase7_oracle.txt"), FileAccess.READ)
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


func _chk(name: String, players: Array, idx: int, off: int, exp: Dictionary) -> void:
	var addr := BASE + idx * STRIDE + off
	if not exp.has(addr):
		return
	var got := int((players[idx] as Dictionary).get(off, 0)) & U32
	var want := int(exp[addr]) & U32
	_ok(got == want, "%s P%d+0x%x: got 0x%x want 0x%x" % [name, idx, off, got, want])


func _run(name: String, exp: Dictionary) -> void:
	var fx: Dictionary = FIX[name]
	var m := {0x448: 7, 0x19a0: 4}
	var players := []
	for i in 3:
		players.append({0x4: 0, 0x8: 0, 0xc: 0, 0x2bc: 1, 0x18c: m})
	m[0x438] = players[0]                                     # taker = P0
	var ctx := {0x0: 0, 0x4: 3, 0x8: 0, 0x138: m, 0x2e0: 0, "players": players}

	if fx["k"] == "all_on":
		m[0x45c] = 0                                         # our set-piece side (== team 0)
	else:
		m[0x45c] = 1                                         # not our side
		players[1][0x2bc] = 0                                # P1 off-pitch -> skipped (no draws)
		players[1][0x4] = 0x11110000                         # sentinel proving P1 untouched

	Pm98Movement.position_team(ctx, MatchEngine.Pm98Rng.new(int(fx["seed"])))

	_chk(name, players, 1, 0x4, exp)                         # P1.x (scattered, or sentinel when skipped)
	_chk(name, players, 1, 0x8, exp)                         # P1.y
	_chk(name, players, 1, 0xc, exp)                         # P1.z
	_chk(name, players, 1, 0x1e0, exp)                       # P1.endpoint1.x
	_chk(name, players, 2, 0x4, exp)                         # P2.x
	_chk(name, players, 2, 0x8, exp)                         # P2.y
