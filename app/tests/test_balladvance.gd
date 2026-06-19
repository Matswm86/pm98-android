extends SceneTree
## Oracle-backed parity test for FUN_0058e2c0 (vtable+0xc on match+0x1610, the BALL advance) SLICE A
## -- the prologue timers + the lerp-to-target branch, ported in Pm98Movement.ball_advance.
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_balladvance.gd
##
## ORACLE = the REAL FUN_0058e2c0 under the Ghidra PCode emulator, run to a clean RET
## (tools/re/run_balladvance_oracle.sh -> specs/balladvance_oracle.txt). Each fixture forces the lerp
## branch (post-dec +0x68==0 && +0x6c!=0) with velocity +0x20!=0 so the epilogue leaves pos intact.
## Validates: +0x58=+0x54 copy, the three timer decrements (with 0-guards), and the per-axis lerp
## pos[a] += (target[a]-pos[a])/N with x86 idiv truncation toward zero (lerp_neg is the truncation
## witness: -1398101, not the floor -1398102).

const B0 := 0x230000
const U32 := 0xffffffff

# Each fixture mirrors the oracle's fix(): the ball-field state poked before the call. Offsets:
# 0x54/0x5c/0x68/0x6c/0x70 timers, 0x4/0x8/0xc pos, 0x9c/0xa0/0xa4 target, 0x20 velocity (nonzero).
const FIX := {
	"lerp_pos": {0x54: 0x1234, 0x5c: 3, 0x68: 1, 0x6c: 4, 0x70: 5,
		0x4: 0x100000, 0x8: 0x200000, 0xc: 0x80000,
		0x9c: 0x500000, 0xa0: 0x600000, 0xa4: 0x180000, 0x20: 0x10000},
	"lerp_neg": {0x54: 0x2, 0x5c: 1, 0x68: 0, 0x6c: 3, 0x70: 0,
		0x4: 0x500000, 0x8: 0x500000, 0xc: 0x100000,
		0x9c: 0x100000, 0xa0: 0x100000, 0xa4: 0x0, 0x20: 0x10000},
	"lerp_n1": {0x54: 0x9, 0x5c: 0, 0x68: 0, 0x6c: 1, 0x70: 2,
		0x4: 0x111111, 0x8: 0x222222, 0xc: 0x33333,
		0x9c: 0x777777, 0xa0: 0x888888, 0xa4: 0x99999, 0x20: 0x10000},
	"lerp_guard": {0x54: 0xabcd, 0x5c: 0, 0x68: 0, 0x6c: 2, 0x70: 0,
		0x4: 0, 0x8: 0, 0xc: 0,
		0x9c: 0x80000, 0xa0: -0x80000, 0xa4: 0x40000, 0x20: 0x10000},
}

var _fail := 0
var _pass := 0


func _init() -> void:
	var orc := _load_oracle()
	if orc.is_empty():
		_ok(false, "balladvance oracle file empty/unreadable")
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


# Parse "FIX <name> ... mem[0xADDR:W]=val ...": row -> {offset_from_B0: value}.
func _load_oracle() -> Dictionary:
	var out := {}
	var f := FileAccess.open(_spec_path("balladvance_oracle.txt"), FileAccess.READ)
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
			row[("0x" + mtch.get_string(1)).hex_to_int() - B0] = mtch.get_string(2).to_int()
		out[toks[1]] = row
	return out


func _run(name: String, exp: Dictionary) -> void:
	var src: Dictionary = FIX[name]
	var ball := {}
	for off in src:
		ball[int(off)] = int(src[off])

	Pm98Movement.ball_advance(ball)

	for off in exp:
		var got := int(ball.get(off, 0)) & U32
		var want := int(exp[off]) & U32
		_ok(got == want, "%s +0x%x: got 0x%x want 0x%x" % [name, off, got, want])
