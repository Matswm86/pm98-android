extends SceneTree
## Oracle-backed parity test for FUN_0058e2c0 (vtable+0xc on match+0x1610, the BALL advance), ported in
## Pm98Movement.ball_advance. SLICE A = prologue timers + lerp-to-target. SLICE B = the free-flight
## branch (integration + gravity + ground bounce/roll).
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_balladvance.gd
##
## ORACLE = the REAL FUN_0058e2c0 under the Ghidra PCode emulator, run to a clean RET
## (tools/re/run_balladvance_oracle.sh -> specs/balladvance_oracle.txt).
## SLICE A (lerp_*): forces the lerp branch (post-dec +0x68==0 && +0x6c!=0), velocity +0x20!=0 so the
## epilogue leaves pos intact. Validates +0x58=+0x54 copy, the 3 timer decrements (0-guards), and the
## per-axis lerp pos[a] += (target[a]-pos[a])/N with x86 idiv trunc toward zero (lerp_neg witness:
## -1398101, not the floor -1398102).
## SLICE B (fb_*): forces the free-flight branch (+0x6c==0). Validates integration pos += vel, gravity
## while airborne (vel.z += -178), ground bounce (pos.z->0; vel damped *0xc51e horiz / -*0x9c28 vert;
## |vel.z|<0x28f settles to 0), roll-stop (|vx|,|vy|<0x22 -> halt) / roll-friction (subtract a
## 0x22-magnitude step along atan2(vx,vy), real cos/atan LUT), and the held gate (byte ball+0x63).

const B0 := 0x230000
const U32 := 0xffffffff

# Each fixture mirrors the oracle's fix()/fixb(): the ball-field state poked before the call. Offsets:
# 0x54/0x5c/0x68/0x6c/0x70 timers, 0x4/0x8/0xc pos, 0x9c/0xa0/0xa4 target, 0x20/0x24/0x28 velocity.
# Slice-B rows leave all timers 0 (so +0x6c==0 -> free-flight); held flag = byte key 0x63
# (the live writers' convention -- _kick_execute / slice-C set ball[0x63], not a packed 0x60 dword).
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
	"fb_gravity": {0x4: 0x10000, 0x8: 0x20000, 0xc: 0x40000,
		0x20: 0x1000, 0x24: -0x2000, 0x28: 0x3000},
	"fb_bounce": {0x4: 0x5000, 0x8: 0x6000, 0xc: 0x1000,
		0x20: 0x8000, 0x24: -0x4000, 0x28: -0x9000},
	"fb_settle": {0x4: 0x4000, 0x8: 0x4000, 0xc: 0x100,
		0x20: 0x100, 0x24: 0x100, 0x28: -0x200},
	"fb_rollstop": {0x4: 0x3000, 0x8: 0x3000, 0xc: 0,
		0x20: 0x10, 0x24: -0x20, 0x28: 0},
	"fb_rollfric": {0x4: 0x3000, 0x8: 0x3000, 0xc: 0,
		0x20: 0x800, 0x24: 0x400, 0x28: 0},
	"fb_held": {0x4: 0x1000, 0x8: 0x2000, 0xc: 0x3000,
		0x20: 0x100, 0x24: 0x200, 0x28: 0x300, 0x63: 1},
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
