extends SceneTree
## Oracle-backed parity test for the two restart-DECIDE entity methods FUN_00593b70
## dispatches per restart (vtable+4 on the ball @match+0x1610 and both keepers):
##   FUN_0058e120 -> Pm98Movement.ball_restart_decide
##   FUN_005a2140 -> Pm98Movement.keeper_restart_decide
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_restartdecide.gd
##
## ORACLE = the REAL functions under the Ghidra PCode emulator, run to a clean RET
## (tools/re/run_restartdecide_oracle.sh -> specs/restartdecide_oracle.txt). Fixture
## pokes below mirror the oracle spec 1:1 (ball@0x220000, keeper@0x230000; the ring
## pointers +0x38/+0x1dc/+0x3b0 are alloc-side [5bbf10 stubbed] and not compared).

const Pm98Movement := preload("res://scripts/Pm98Movement.gd")
const Pm98Trig := preload("res://scripts/Pm98Trig.gd")

const B0 := 0x220000
const K0 := 0x230000

# Dirty pre-state mirroring BALL_DIRTY in the oracle spec (owner ptrs -> 1: any nonzero;
# the fn clears them unconditionally).
const BALL_DIRTY := {
	0x4: 0x111111, 0x8: 0x222222, 0xc: 0x33333,
	0x20: 0x4444, 0x24: 0x5555, 0x28: 0x6666,
	0x40: 1, 0x44: 1, 0x48: 1, 0x4c: 1, 0x50: 7,
	0x58: 1, 0x5c: 9, 0x61: 1, 0x63: 1, 0x64: 1, 0x1d8: 1,
	0x90: 0x123400, 0x94: 0x56780, 0x98: 0x9ab0,
}
# name -> [match+0x448, session+0x14, DAT_00674e7c]
const BALL_FIX := {
	"kickoff_s14z": [2, 0, 1],
	"kickoff_s14set": [2, 1, 1],
	"kickoff_mode8": [2, 1, 8],
	"phase0_spot": [0, 0, 1],
}
const BALL_CHECK := [0x4, 0x8, 0xc, 0x20, 0x24, 0x28, 0x40, 0x44, 0x48, 0x4c, 0x50,
	0x58, 0x5c, 0x1e0, 0x61, 0x63, 0x64, 0x1d8, 0x90, 0x94, 0x98]

const KEEP_DIRTY := {
	0x4: 0x1111, 0x8: 0x2222, 0xc: 0x3333,
	0x3c0: 0x999, 0x3c4: 0x888, 0x2c: 5, 0x30: 6,
}
# name -> [keeper+0x3bc, match+0x1a5c]
const KEEP_FIX := {
	"idx1": [1, 0x30],
	"idx2": [2, 0x30],
	"idx1_a5c": [1, 0x1234],
}
const KEEP_M := {0x1820: 0x2a0001, 0x1824: 0x150000}
const KEEP_CHECK := [0x4, 0x8, 0xc, 0x2dc, 0x3c0, 0x3c4, 0x3b4, 0x40, 0x2c, 0x30]

var _fail := 0
var _pass := 0


func _init() -> void:
	var orc := _load_oracle()
	if orc.is_empty():
		_ok(false, "restartdecide oracle file empty/unreadable")
	else:
		for name in BALL_FIX:
			if not orc.has("BALL " + name):
				_ok(false, name + ": missing BALL row")
				continue
			_run_ball(name, orc["BALL " + name])
		for name in KEEP_FIX:
			if not orc.has("KEEP " + name):
				_ok(false, name + ": missing KEEP row")
				continue
			_run_keep(name, orc["KEEP " + name])
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


# Parse "BALL|KEEP <name> ... mem[0xADDR:W]=val ..." -> {"BALL name": {abs_addr: value}}.
func _load_oracle() -> Dictionary:
	var out := {}
	var f := FileAccess.open(_spec_path("restartdecide_oracle.txt"), FileAccess.READ)
	if f == null:
		return {}
	var rx := RegEx.new()
	rx.compile("mem\\[0x([0-9a-fA-F]+):[0-9]+\\]=(-?[0-9]+)")
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if not (line.begins_with("BALL ") or line.begins_with("KEEP ")):
			continue
		var toks := line.split(" ", false)
		var row := {}
		for mtch in rx.search_all(line):
			row[("0x" + mtch.get_string(1)).hex_to_int()] = mtch.get_string(2).to_int()
		out[toks[0] + " " + toks[1]] = row
	return out


func _u32(v: int) -> int:
	return v & 0xffffffff


func _run_ball(name: String, exp: Dictionary) -> void:
	var ball := BALL_DIRTY.duplicate()
	var cfg: Array = BALL_FIX[name]
	var m := {0x448: int(cfg[0]), 0x468: {0x14: int(cfg[1])}, "viewmode_674e7c": int(cfg[2]),
		"ball": {}}
	Pm98Movement.ball_restart_decide(ball, m)
	for off in BALL_CHECK:
		var want: int = exp.get(B0 + off, -12345)
		var got := _u32(int(ball.get(off, 0)))
		_ok(got == _u32(want), "%s +0x%x: port %d != oracle %d" % [name, off, got, want])
	# the restart decide must also drop the port-side control mirrors.
	_ok(int(m.get(0x1650, 0)) == -1, name + ": m[0x1650] not cleared to -1")
	_ok(int(m.get(0x165c, 0)) == -1, name + ": m[0x165c] not cleared to -1")


func _run_keep(name: String, exp: Dictionary) -> void:
	var k := KEEP_DIRTY.duplicate()
	var cfg: Array = KEEP_FIX[name]
	k[0x3bc] = int(cfg[0])
	var m := KEEP_M.duplicate()
	m[0x1a5c] = int(cfg[1])
	Pm98Movement.keeper_restart_decide(k, m)
	for off in KEEP_CHECK:
		var want: int = exp.get(K0 + off, -12345)
		var got := _u32(int(k.get(off, 0)))
		_ok(got == _u32(want), "%s +0x%x: port %d != oracle %d" % [name, off, got, want])
