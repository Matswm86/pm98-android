extends SceneTree
## Oracle-backed parity test for Pm98Movement.settle_8680 (the FUN_005a8680 "settle" mover).
## For each fixture it rebuilds the exact memory the PCode emulator ran (the same pokes as
## tools/re/run_settle_oracle.sh), calls settle_8680, and asserts:
##   * settle_trace (the leaf SELECTION + arg0 sequence) == the oracle's `CALL 0 STUB <label> .. arg0=`
##     lines, in order;
##   * p+0x5d (windup-edge flag) and p+0x54 (possession-claim clear) == the oracle's RET-line mem[].
## FUN_005a8680 is pure integer, so the ground truth is exact (no LUT / ftol). Run headless:
##   ~/godot462 --headless --path app --script res://tests/test_settle.gd

const U32 := 0xffffffff
var _fail := 0
var _pass := 0

# Region base -> struct key. value-of-poke that equals one of these links the referenced Dict.
const BASES := {0x230000: "p", 0x260000: "m", 0x270000: "ball", 0x280000: "gs", 0x2a0000: "other"}

# Shared pointer pokes + the two role links, mirrored from run_settle_oracle.sh.
const PTRS := [[0x23018c, 0x260000], [0x230190, 0x270000], [0x230184, 0x280000]]
const TAKER := [0x260438, 0x230000]   # M+0x438 = P (set-piece taker)
const CTRL := [0x270040, 0x230000]    # BALL+0x40 = P (ball controller)

# name -> the fixture's own pokes ([addr, value]); PTRS are prepended to every fixture in _build.
var FIXTURES := {
	"b1_p3_i0": [TAKER, [0x260448, 3], [0x230040, 4], [0x230004, 0x10000], [0x230008, -0x10000], [0x230034, 0x100]],
	"b1_p3_i3": [TAKER, [0x260448, 3], [0x230040, 4], [0x230004, -0x10000], [0x230008, 0x10000], [0x230034, 0x7000]],
	"b1_p4_i4": [TAKER, [0x260448, 4], [0x230040, 4], [0x230004, 0], [0x230008, 0], [0x230034, 0x5000]],
	"b1_p4_i7": [TAKER, [0x260448, 4], [0x230040, 4], [0x230004, -1], [0x230008, 0x10000], [0x230034, 0x9000]],
	"b1_p7_i8": [TAKER, [0x260448, 7], [0x230040, 4], [0x230004, 0], [0x230008, 0], [0x230034, 0x2000]],
	"b1_p7_i11": [TAKER, [0x260448, 7], [0x230040, 4], [0x230004, -1], [0x230008, 1], [0x230034, 0xc000]],
	"b1_p5": [TAKER, [0x260448, 5], [0x230040, 4], [0x230004, 0], [0x230008, 0], [0x230034, 0x3456]],
	"b1_gsadj": [TAKER, [0x260448, 3], [0x230040, 4], [0x230004, 0x10000], [0x230008, -0x10000], [0x230034, 0x100], [0x280210, 1]],
	"b2_fall": [[0x230040, 2], [0x260448, 0], [0x230034, 0x2222]],
	"b2_call8ac0": [[0x230040, 1], [0x260448, 0], [0x230034, 0x2222], [0x280213, 1], [0x26181c, 0x2000]],
	"b2_skip_action": [[0x230040, 5], [0x260448, 0], [0x230034, 0x1111]],
	"b2_skip_phase": [[0x230040, 2], [0x260448, 1], [0x230034, 0x1111]],
	"reset_b1420": [[0x230040, 2], [0x260448, 0], [0x2302bc, 1], [0x230034, 0x4321]],
	"tail_aa4d0": [[0x230040, 0x16], [0x260448, 1], CTRL, [0x280214, 1]],
	"tail_aa870": [[0x230040, 0x16], [0x260448, 1], CTRL, [0x280215, 1]],
	"tail_aafd0": [[0x230040, 0x16], [0x260448, 1], [0x280214, 1]],
	"tail_b8ce0": [[0x230040, 0x16], [0x260448, 1], [0x230054, 5]],
	"tail_b8ce0_team": [[0x230040, 0x16], [0x260448, 1], [0x230054, 5], [0x27004c, 0x2a0000], [0x2302b8, 10], [0x2a02b8, 20]],
	"tail_b8ce0_same": [[0x230040, 0x16], [0x260448, 1], [0x230054, 5], [0x27004c, 0x2a0000], [0x2302b8, 10], [0x2a02b8, 10]],
}


func _init() -> void:
	var path := ProjectSettings.globalize_path("res://").path_join("../tools/re/specs/settle_oracle.txt").simplify_path()
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		_ok(false, "settle oracle unreadable (run tools/re/run_settle_oracle.sh)")
		_finish()
		return
	var rx_stub := RegEx.new()
	rx_stub.compile("STUB (\\w+) #\\d+ step=\\d+ ECX=\\d+ arg0=(\\d+)")
	var rx_5d := RegEx.new()
	rx_5d.compile("mem\\[0x23005d:1\\]=(-?\\d+)")
	var rx_54 := RegEx.new()
	rx_54.compile("mem\\[0x230054:4\\]=(-?\\d+)")

	var name := ""
	var trace := []
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if line.begins_with("## FIX "):
			name = line.substr(7)
			trace = []
		elif line.find("CALL 0 STUB ") != -1:
			var m := rx_stub.search(line)
			if m != null:
				trace.append([m.get_string(1), m.get_string(2).to_int()])
		elif line.find("CALL 0 RET") != -1 or line.find("CALL 0 HALT") != -1:
			if name != "":
				var m5d := rx_5d.search(line)
				var m54 := rx_54.search(line)
				var p5d := m5d.get_string(1).to_int() if m5d != null else -0xBAD
				var p54 := m54.get_string(1).to_int() if m54 != null else -0xBAD
				_check(name, trace, p5d, p54)
				name = ""
	_finish()


func _finish() -> void:
	print("")
	print("ALL PASS (%d checks)" % _pass if _fail == 0 else "FAILED: %d / %d" % [_fail, _pass + _fail])
	quit(1 if _fail > 0 else 0)


func _check(name: String, want_trace: Array, want_5d: int, want_54: int) -> void:
	if not FIXTURES.has(name):
		_ok(false, "%s: no fixture mirror in test_settle.gd" % name)
		return
	var p := _build(FIXTURES[name])
	Pm98Movement.settle_8680(p)
	var got: Array = Pm98Movement.settle_trace

	# trace: same length, same [label, arg0] in order.
	if got.size() != want_trace.size():
		_ok(false, "%s trace length: got %d %s want %d %s" % [name, got.size(), str(got), want_trace.size(), str(want_trace)])
	else:
		for i in got.size():
			var gl: String = got[i][0]
			var ga: int = int(got[i][1]) & U32
			var wl: String = want_trace[i][0]
			var wa: int = int(want_trace[i][1]) & U32
			_ok(gl == wl, "%s trace[%d] label: got %s want %s" % [name, i, gl, wl])
			_ok(ga == wa, "%s trace[%d] arg0: got %d want %d" % [name, i, ga, wa])

	_ok((int(p.get(0x5d, 0)) & 0xff) == (want_5d & 0xff), "%s p+0x5d: got %d want %d" % [name, int(p.get(0x5d, 0)) & 0xff, want_5d & 0xff])
	_ok((Pm98Trig._i32(int(p.get(0x54, 0))) & U32) == (want_54 & U32), "%s p+0x54: got %d want %d" % [name, Pm98Trig._i32(int(p.get(0x54, 0))) & U32, want_54 & U32])


## Rebuild the fixture's Dict graph from the poke list. A poke whose VALUE is a known region base
## links the referenced struct Dict; otherwise it is a scalar field write keyed by the offset.
func _build(pokes: Array) -> Dictionary:
	var structs := {"p": {}, "m": {}, "ball": {}, "gs": {}, "other": {}}
	var all_pokes: Array = []
	for pk in PTRS:
		all_pokes.append(pk)
	for pk in pokes:
		all_pokes.append(pk)
	for pk in all_pokes:
		var addr: int = int(pk[0])
		var val: int = int(pk[1])
		var base: int = addr & 0xffff0000
		var off: int = addr & 0xffff
		if not BASES.has(base):
			continue
		var struct: Dictionary = structs[BASES[base]]
		if BASES.has(val):
			struct[off] = structs[BASES[val]]
		else:
			struct[off] = val
	return structs["p"]


func _ok(cond: bool, msg: String) -> void:
	if cond:
		_pass += 1
	else:
		_fail += 1
		print("  [FAIL] ", msg)
