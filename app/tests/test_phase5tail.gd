extends SceneTree
## Oracle-backed parity test for FUN_005b73a0 slice E (the phase-5 TAIL Path C, our-set-piece
## follow-up), ported in Pm98Movement._phase5_tail_pathC (via position_team / _position_phase5_tail).
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_phase5tail.gd
##
## ORACLE = the REAL FUN_005b73a0 phase-5 tail (match+0x448==5, 0x19cc==0, 0x45c==team -> wall skipped)
## under the Ghidra PCode emulator with the faithful _ftol injected (clamp_min_sep fires for P0),
## tools/re/run_phase5tail_oracle.sh -> specs/phase5tail_oracle.txt. OUR players base 0x240000, stride
## 0x3bc (P0 sign-diff+count0 -> MOVE+clamp ; P1 sign-same -> SKIP ; P2 count>=2 -> SKIP).

const U32 := 0xffffffff
const BASE := 0x240000
const STRIDE := 0x3bc

var _fail := 0
var _pass := 0


func _init() -> void:
	var orc := _load_oracle()
	if not orc.has("pathC"):
		_ok(false, "phase5tail oracle missing pathC")
	else:
		_run(orc["pathC"])
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
	var f := FileAccess.open(_spec_path("phase5tail_oracle.txt"), FileAccess.READ)
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


func _chk(players: Array, idx: int, off: int, exp: Dictionary) -> void:
	var addr := BASE + idx * STRIDE + off
	if not exp.has(addr):
		_ok(false, "P%d+0x%x: addr 0x%x missing from oracle" % [idx, off, addr])
		return
	var got := int((players[idx] as Dictionary).get(off, 0)) & U32
	var want := int(exp[addr]) & U32
	_ok(got == want, "P%d+0x%x: got 0x%x want 0x%x" % [idx, off, got, want])


func _run(exp: Dictionary) -> void:
	var taker := {0x4: 0, 0x8: 0, 0xc: 0}
	var m := {0x448: 5, 0x19cc: 0, 0x45c: 0, 0x438: taker}
	# OUR team: P0 sign-diff + count 0 (MOVE) ; P1 sign-same (SKIP) ; P2 sign-diff + count 2 (SKIP).
	var players := [
		{0x4: 0x100000, 0x3a4: -0x100000, 0x8: 0, 0xc: 0},
		{0x4: 0x100000, 0x3a4: 0x100000},
		{0x4: 0x100000, 0x3a4: -0x40000},
	]
	# shared goal-side opponents (x=0, anchor=0): d=0 -> count vs each player's lim.
	var opponents := [{0x4: 0, 0x3a4: 0}, {0x4: 0, 0x3a4: 0}]
	var ctx := {
		0x0: 0, 0x4: 3, 0x8: 0, 0x138: m, 0x2e0: 0,
		"players": players, "opponents": opponents, "spc_anchor": {0x4: 0x55000},
	}

	Pm98Movement.position_team(ctx)

	_chk(players, 0, 0x4, exp)
	_chk(players, 0, 0x8, exp)
	_chk(players, 0, 0xc, exp)
	_chk(players, 1, 0x4, exp)
	_chk(players, 2, 0x4, exp)
