extends SceneTree
## Oracle-backed parity test for FUN_005b73a0 slice D (the phase-4 DEFENSIVE-WALL branch, loop 1
## role-pulling + loop 5 facing/min-sep), ported in Pm98Movement._position_wall (via position_team).
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_wall.gd
##
## ORACLE = the REAL FUN_005b73a0 phase-4 under the Ghidra PCode emulator, two-team memory layout
## (tools/re/run_wall_oracle.sh -> specs/wall_oracle.txt). OUR players base 0x240000, stride 0x3bc
## (P0 GK, P1 role 5, P2 role 10, P3 role 2); OPP players base 0x250000 (O0 keeper, O1 role 9, O2 role
## 10). Each fixture varies match+0x19a0 (orientation) -> iVar21 sign + wall-anchor negation.

const U32 := 0xffffffff
const BASE := 0x240000
const STRIDE := 0x3bc
const FIX := {"wall_orient0": 0, "wall_orient1": 1}

var _fail := 0
var _pass := 0


func _init() -> void:
	var orc := _load_oracle()
	if orc.is_empty():
		_ok(false, "wall oracle file empty/unreadable")
	else:
		for name in FIX:
			if not orc.has(name):
				_ok(false, name + ": missing from oracle file")
				continue
			_run(name, int(FIX[name]), orc[name])
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
	var f := FileAccess.open(_spec_path("wall_oracle.txt"), FileAccess.READ)
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
		_ok(false, "%s P%d+0x%x: addr 0x%x missing from oracle" % [name, idx, off, addr])
		return
	var got := int((players[idx] as Dictionary).get(off, 0)) & U32
	var want := int(exp[addr]) & U32
	_ok(got == want, "%s P%d+0x%x: got 0x%x want 0x%x" % [name, idx, off, got, want])


func _run(name: String, orient: int, exp: Dictionary) -> void:
	var m := {
		0x448: 4, 0x45c: 1, 0x19a0: orient, 0x16a4: 0x30000, 0x1820: 0x140000,
		0x1614: 0, 0x1618: 0, 0x161c: 0,
	}
	# OUR team: P0 GK(role 0xc,id0), P1(role 5,id1), P2(role 10,id2), P3(role 2,id3, ep1.y +, team 0).
	var players := [
		{0x2c8: 0xc, 0x2c4: 0, 0x2bc: 1, 0x18c: m, 0x4: 0, 0x8: 0, 0xc: 0},
		{0x2c8: 5, 0x2c4: 1, 0x2bc: 1, 0x18c: m, 0x4: 0, 0x8: 0, 0xc: 0},
		{0x2c8: 10, 0x2c4: 2, 0x2bc: 1, 0x18c: m, 0x4: 0, 0x8: 0, 0xc: 0},
		{0x2c8: 2, 0x2c4: 3, 0x2bc: 1, 0x18c: m, 0x1e4: 0x10000, 0x2b8: 0, 0x4: 0, 0x8: 0, 0xc: 0},
	]
	# OPP team: O0 keeper(id0), O1(role 9,id1), O2(role 10,id2).
	var opponents := [
		{0x2c8: 0xc, 0x2c4: 0, 0x18c: m, 0x4: 0, 0x8: 0, 0xc: 0},
		{0x2c8: 9, 0x2c4: 1, 0x18c: m, 0x4: 0x200000, 0x8: 0x100000, 0xc: 0},
		{0x2c8: 10, 0x2c4: 2, 0x18c: m, 0x4: 0x400000, 0x8: 0x180000, 0xc: 0},
	]
	var ctx := {
		0x0: 0, 0x4: 4, 0x8: 0, 0x138: m, 0x2e0: 0,
		"players": players, "opponents": opponents, "opp_keeper": 0,
	}

	Pm98Movement.position_team(ctx, MatchEngine.Pm98Rng.new(1))

	for idx in [1, 2, 3]:
		_chk(name, players, idx, 0x4, exp)
		_chk(name, players, idx, 0x8, exp)
		_chk(name, players, idx, 0xc, exp)
