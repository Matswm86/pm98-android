extends SceneTree
## Oracle-backed parity test for FUN_005b73a0 slice G (the phase-7 wall-ELSE, match+0x19a0 != 4),
## ported in Pm98Movement._position_phase7_wall (via position_team / _position_phase7).
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_phase7wall.gd
##
## ORACLE = the REAL FUN_005b73a0 phase-7 branch under the Ghidra PCode emulator (relmatrix throttle-
## skipped, atan LUT + faithful _ftol injected), tools/re/run_phase7wall_oracle.sh ->
## specs/phase7wall_oracle.txt. OUR players base 0x240000, stride 0x3bc; taker a separate struct
## @0x270000 (except taker_p, where match+0x438 aliases P1 so P1 is skipped). Reads +0x4/+0x8/+0xc/+0x34.

const U32 := 0xffffffff
const BASE := 0x240000
const STRIDE := 0x3bc
const FIX := ["flag0", "flag1", "orient1", "taker_p"]

var _fail := 0
var _pass := 0


func _init() -> void:
	var orc := _load_oracle()
	if orc.is_empty():
		_ok(false, "phase7wall oracle file empty/unreadable")
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
	var f := FileAccess.open(_spec_path("phase7wall_oracle.txt"), FileAccess.READ)
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
	# Match: phase 7, goalx 0x40000, yscale 0x180000, ball at origin. orient/side per fixture.
	var orient := 1 if name == "orient1" else 0
	var side := 1 if name == "flag1" else 0
	var m := {
		0x448: 7, 0x19a0: orient, 0x45c: side, 0x1820: 0x40000, 0x1824: 0x180000,
		0x1614: 0, 0x1618: 0, 0x161c: 0,
	}
	# Taker: separate struct parked far, unless taker_p (= P1).
	var taker := {0x4: 0x3000000, 0x8: 0, 0xc: 0}
	var players: Array
	match name:
		"flag0":
			players = [
				{0x2bc: 1, 0x2c8: 7, 0x18c: m, 0x4: 0, 0x8: 0, 0xc: 0},          # row0[1]
				{0x2bc: 1, 0x2c8: 8, 0x18c: m, 0x4: 0, 0x8: 0, 0xc: 0},          # row0[2]
				{0x2bc: 1, 0x2c8: 99, 0x18c: m, 0x4: 0x5000000, 0x8: 0x1000000, 0xc: 0},  # no match
			]
		"flag1":
			players = [
				{0x2bc: 1, 0x2c8: 11, 0x18c: m, 0x4: 0, 0x8: 0, 0xc: 0},         # row1[1]
				{0x2bc: 1, 0x2c8: 3, 0x18c: m, 0x4: 0, 0x8: 0, 0xc: 0},          # row1[0]
				{0x2bc: 1, 0x2c8: 99, 0x18c: m, 0x4: 0x5000000, 0x8: 0x1000000, 0xc: 0},
			]
		"orient1":
			players = [
				{0x2bc: 1, 0x2c8: 12, 0x18c: m, 0x4: 0, 0x8: 0, 0xc: 0},         # row0[0]
				{0x2bc: 1, 0x2c8: 7, 0x18c: m, 0x4: 0, 0x8: 0, 0xc: 0},          # row0[1]
			]
		"taker_p":
			var p1 := {0x2bc: 1, 0x2c8: 4, 0x18c: m, 0x4: 0x7777777, 0x8: 0x6666666, 0xc: 0x5555555}
			taker = p1                                                          # match+0x438 aliases P1
			players = [
				{0x2bc: 1, 0x2c8: 7, 0x18c: m, 0x4: 0, 0x8: 0, 0xc: 0},
				p1,                                                             # skipped as taker
				{0x2bc: 1, 0x2c8: 8, 0x18c: m, 0x4: 0, 0x8: 0, 0xc: 0},
			]
	m[0x438] = taker

	var ctx := {0x0: 0, 0x4: players.size(), 0x8: 0, 0x138: m, 0x2e0: 0, "players": players}
	Pm98Movement.position_team(ctx)

	for idx in players.size():
		for off in [0x4, 0x8, 0xc, 0x34]:
			_chk(name, players, idx, off, exp)
