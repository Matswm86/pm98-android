extends SceneTree
## Oracle-backed parity test for the BALL-TOUCH decision FUN_005a7260 (slice 1, L63-176), ported as
## Pm98Movement.ball_touch_7260. Covers the same-side test, the NOT-same-side goal-anchor steer, and the
## carrier ball-drag (release + polar pull-back) incl. the FUN_0058f100 engage-copy guard/side-effect.
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_7260.gd
##
## ORACLE = the REAL FUN_005a7260 driven through the Ghidra PCode emulator (tools/re/run_7260_oracle.sh
## -> specs/7260_oracle.txt). Each row banks the post-call P (0x230000) + ball (0x240000) + m (0x210000)
## fields as `<abs-addr>=<u LE>`. Here we rebuild the identical Dict fixture, run ball_touch_7260, and
## assert every banked field bit-exact (masked to the banked read width).

const P_BASE := 0x230000
const B_BASE := 0x240000
const M_BASE := 0x210000

# Read widths (bytes) for the non-dword banked fields; everything else is 4.
const WIDTH := {0x34: 2, 0x63: 1}            # offsets within their region

var _fail := 0
var _pass := 0

# name -> [action, p48, px, py, p3a4, facing, carrier_is_P, guard, goalx, bx, by, bz]
var _fixtures := {
	"goalanchor":   [2, 5, 0x60000, 0, -1, 0x2000, false, 0, 0x200000, 0,     0,     0],
	"carrier_drag": [2, 5, 0x500,   0, -1, 0x2000, true,  0, 0,        0x500, 0x100, 0],
	"carrier_guard":[2, 5, 0x500,   0, -1, 0x2000, true,  1, 0,        0x500, 0x100, 0],
}


func _init() -> void:
	var orc := _load_oracle()
	if orc.is_empty():
		_ok(false, "7260 oracle empty/unreadable (run tools/re/run_7260_oracle.sh)")
	else:
		for name in _fixtures:
			if not orc.has(name):
				_ok(false, name + ": missing from oracle file")
				continue
			_run_fixture(name, orc[name])
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
	var f := FileAccess.open(_spec_path("7260_oracle.txt"), FileAccess.READ)
	if f == null:
		return {}
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if not line.begins_with("FIX "):
			continue
		var parts := line.split("|")
		if parts.size() < 2:
			continue
		var name := parts[0].substr(4).strip_edges()
		var fields := {}
		for tok in parts[1].split(" ", false):
			var kv := tok.split("=")
			if kv.size() == 2:
				fields[kv[0].hex_to_int()] = kv[1].to_int()
		out[name] = fields
	return out


func _build(spec: Array) -> Dictionary:
	var P := {}
	var M := {}
	var BALL := {}
	var GS := {}
	var OTHER := {}
	P[0x184] = GS
	P[0x18c] = M
	P[0x190] = BALL
	P[0x40] = spec[0]                                  # action
	P[0x48] = spec[1]                                  # P+0x48
	P[0x4] = spec[2]                                   # px
	P[0x8] = spec[3]                                   # py
	P[0xc] = 0
	P[0x3a4] = spec[4]                                 # side anchor
	P[0x34] = spec[5]                                  # facing
	P[0x70] = 15000
	P[0x3ac] = 65536
	P[0x3a8] = 0
	P[0x388] = 0x4000
	P[0x2b8] = 0
	M[0x448] = 0
	M[0x461] = 0
	M[0x19a0] = 0
	M[0x1820] = spec[8]                                # goalx
	M[0x1970] = 0x7f000000
	M[0x1978] = 0x7f000000
	M[0x1828] = -0x10000000; M[0x182c] = -0x10000000; M[0x1830] = -0x10000000
	M[0x1834] = 0x10000000;  M[0x1838] = 0x10000000;  M[0x183c] = 0x10000000
	BALL[0x40] = P if spec[6] else OTHER               # carrier ref
	BALL[0x63] = spec[7]                               # engage-copy guard
	BALL[0x4] = spec[9]; BALL[0x8] = spec[10]; BALL[0xc] = spec[11]
	BALL[0x20] = 0; BALL[0x24] = 0; BALL[0x28] = 0
	BALL[0x34] = 0
	return P


func _run_fixture(name: String, exp: Dictionary) -> void:
	var P := _build(_fixtures[name])
	var BALL: Dictionary = P[0x190]
	var M: Dictionary = P[0x18c]
	Pm98Movement.ball_touch_7260(P)

	for addr in exp:
		var a: int = addr
		var tag: String
		var off: int
		var src: Dictionary
		if a >= P_BASE and a < P_BASE + 0x1000:
			off = a - P_BASE; src = P; tag = "P+0x%x" % off
		elif a >= B_BASE and a < B_BASE + 0x1000:
			off = a - B_BASE; src = BALL; tag = "ball+0x%x" % off
		else:
			off = a - M_BASE; src = M; tag = "m+0x%x" % off

		# ball+0x40 is a carrier IDENTITY ref in the Dict model (an emulated address in the oracle).
		# Don't int-compare it -- assert the RELEASE semantics: 0 banked => released (Dict field is int 0);
		# nonzero banked => still engaged (the field is preserved as a Dict ref).
		if src == BALL and off == 0x40:
			var fld: Variant = BALL.get(0x40, 0)
			var is_ref := fld is Dictionary                      # don't str() fld: it is a cyclic Dict
			if int(exp[addr]) == 0:
				_ok(not is_ref and int(fld) == 0, "%s %s: expected released (int 0), got ref=%s" % [name, tag, is_ref])
			else:
				_ok(is_ref, "%s %s: expected engaged ref, got ref=%s" % [name, tag, is_ref])
			continue

		var mask: int = 0xffffffff
		match int(WIDTH.get(off, 4)):
			2: mask = 0xffff
			1: mask = 0xff
		var want: int = int(exp[addr]) & mask
		var got: int = int(src.get(off, 0)) & mask
		_ok(got == want, "%s %s: got %d want %d" % [name, tag, got, want])
