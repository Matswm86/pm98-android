extends SceneTree
## Oracle-backed parity test for the FUN_005a7260 EXECUTE-KICK sub-arm 1 (L544-605), ported as
## Pm98Movement._kick_execute / _kick_strike (reached from ball_touch_7260's same-side open-play gate).
## Covers the primary shot/pass STRIKE: action advance, ball-velocity zero, ball-anim target record
## (ball+0x9c/a0/a4), the engage (FUN_0058eca0) and the engage-copy / turnover guards.
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_7260kick.gd
##
## ORACLE = the REAL FUN_005a7260 driven into the kick block through the Ghidra PCode emulator
## (tools/re/run_7260kick_oracle.sh -> specs/7260kick_oracle.txt). Each row banks the post-call P
## (0x230000) + ball (0x240000) + m (0x210000) + stat (0x270000) fields as `<abs-addr>=<u LE>`. Here we
## rebuild the identical Dict fixture, run ball_touch_7260 with a seed-0 LCG, and assert every banked
## field bit-exact. The grid/static cross-check reads (0x674xxx / 0x665xxx / 0x6d3184) are NOT asserted
## here -- they confirm the KICK_GRID/KICK_FRAME/KICK_THRESH transcription in the oracle output itself.

const P_BASE := 0x230000
const B_BASE := 0x240000
const M_BASE := 0x210000
const STAT_BASE := 0x270000

const WIDTH := {0x63: 1}            # offsets within their region (ball+0x63 is a byte)

var _fail := 0
var _pass := 0

# name -> [action, px, py, p3a4, idx, power, anim_x, anim_y, anim_z]
var _fixtures := {
	"kick26": [0x26, 0x1000, 0x2000, 0x500, 2, 100, 0x4333, 0x2000, 0x1cccc],
	"kick31": [0x31, 0x1000, 0x2000, 0x500, 2, 100, 0x4333, 0x2000, 0x1cccc],
}


func _init() -> void:
	var orc := _load_oracle()
	if orc.is_empty():
		_ok(false, "7260kick oracle empty/unreadable (run tools/re/run_7260kick_oracle.sh)")
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
	var f := FileAccess.open(_spec_path("7260kick_oracle.txt"), FileAccess.READ)
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
	var STAT := {}
	P[0x184] = GS
	P[0x18c] = M
	P[0x190] = BALL
	P[0x40] = spec[0]                                  # action
	P[0x2c] = 5                                        # kick-block gate
	P[0x44] = spec[4]                                  # marker idx
	P[0x38c] = spec[5]                                 # power
	P[0x4] = spec[1]                                   # px
	P[0x8] = spec[2]                                   # py
	P[0xc] = 0
	P[0x3a4] = spec[3]                                 # same-side anchor
	P[0x2b8] = 1                                       # team
	P[0x34] = 0x2000                                   # facing
	P[0x54] = 7; P[0x58] = 7                           # -> 0 (engage zeroes target+0x54/0x58)
	P[0x3b8] = STAT                                    # stat struct
	M[0x448] = 0
	M[0x461] = 0
	M[0x460] = 0
	M[0x458] = 0
	M[0x1a38] = 1                                      # freeze event queue (enqueue no-op)
	M[0x180b] = 0; M[0x180c] = 0
	M[0x19a0] = 0
	M[0x1820] = 0
	M[0x1970] = 0x7f000000
	M[0x1978] = 0x7f000000
	M[0x1828] = -0x10000000; M[0x182c] = -0x10000000; M[0x1830] = -0x10000000
	M[0x1834] = 0x10000000;  M[0x1838] = 0x10000000;  M[0x183c] = 0x10000000
	BALL[0x40] = OTHER                                 # carrier = OTHER (not-carrier)
	BALL[0x44] = 0; BALL[0x48] = 0
	BALL[0x54] = 5                                     # old team (!= p team -> engage bumps m+0x458)
	BALL[0x80] = 0
	BALL[0x4c] = 0
	BALL[0x50] = 0                                     # keeper null (keeper_event no-op)
	BALL[0x63] = 0
	BALL[0x68] = 0; BALL[0x6c] = 0; BALL[0x70] = 0
	BALL[0x20] = 0; BALL[0x24] = 0; BALL[0x28] = 0
	BALL[0x114] = spec[6]; BALL[0x118] = spec[7]; BALL[0x11c] = spec[8]   # ball-anim @ (frame+0x12)*0xc
	BALL[0x1d4] = M                                    # ball+0x1d4 -> m (engage turnover counter)
	return P


func _run_fixture(name: String, exp: Dictionary) -> void:
	var P := _build(_fixtures[name])
	var BALL: Dictionary = P[0x190]
	var M: Dictionary = P[0x18c]
	var STAT: Dictionary = P[0x3b8]
	Pm98Movement.ball_touch_7260(P, MatchEngine.Pm98Rng.new(0))

	for addr in exp:
		var a: int = addr
		var tag: String
		var off: int
		var src: Dictionary
		if a >= P_BASE and a < P_BASE + 0x1000:
			off = a - P_BASE; src = P; tag = "P+0x%x" % off
		elif a >= B_BASE and a < B_BASE + 0x1000:
			off = a - B_BASE; src = BALL; tag = "ball+0x%x" % off
		elif a >= M_BASE and a < M_BASE + 0x1000:
			off = a - M_BASE; src = M; tag = "m+0x%x" % off
		elif a >= STAT_BASE and a < STAT_BASE + 0x1000:
			off = a - STAT_BASE; src = STAT; tag = "stat+0x%x" % off
		else:
			continue                                  # grid/static cross-check read -- not a Dict field

		# ball+0x40/0x44/0x48 are carrier IDENTITY refs in the Dict model (an emulated address in the
		# oracle). Don't int-compare -- a nonzero banked value means "engaged to a player" (Dict ref).
		if src == BALL and (off == 0x40 or off == 0x44 or off == 0x48):
			var fld: Variant = BALL.get(off, 0)
			var is_ref := fld is Dictionary
			if int(exp[addr]) == 0:
				_ok(not is_ref and int(fld) == 0, "%s %s: expected released (int 0), got ref=%s" % [name, tag, is_ref])
			else:
				_ok(is_ref and is_same(fld, P), "%s %s: expected engaged-to-player ref, got ref=%s" % [name, tag, is_ref])
			continue

		var mask: int = 0xffffffff
		match int(WIDTH.get(off, 4)):
			2: mask = 0xffff
			1: mask = 0xff
		var want: int = int(exp[addr]) & mask
		var got: int = int(src.get(off, 0)) & mask
		_ok(got == want, "%s %s: got %d want %d" % [name, tag, got, want])
