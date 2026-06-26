extends SceneTree
## Oracle-backed parity test for Pm98Movement.windup_8ac0 (the FUN_005a8ac0 "windup" settle leaf).
## For each fixture it rebuilds the exact memory the PCode emulator ran (the same pokes as
## tools/re/run_8ac0_oracle.sh), pre-sets the once-per-tick steer guard p+0x2d7 so the inner
## steer_8f20 (already GREEN via run_steering_oracle.sh) is inert -- isolating M8AC0's own write
## exactly as the oracle's 8f20 STUB does -- then calls windup_8ac0 and asserts:
##   * p+0x6c (the curve/windup speed) == the oracle's read_mem mem[0x23006c:4];
##   * the heading handed to the function == the oracle's forwarded m8f20_arg0 (passthrough check).
## FUN_005a8ac0 is pure integer (FPU lives in the stubbed 8f20), so the ground truth is exact. Run:
##   ~/godot462 --headless --path app --script res://tests/test_8ac0.gd

const U32 := 0xffffffff
var _fail := 0
var _pass := 0

# Region base -> struct key (a poke whose VALUE is a base links the referenced Dict).
const BASES := {0x230000: "p", 0x260000: "m", 0x270000: "ball", 0x2a0000: "other"}

# Shared pointer pokes + the curve-formula inputs, mirrored from run_8ac0_oracle.sh.
const PTRS := [[0x23018c, 0x260000], [0x230190, 0x270000]]
const FORMULA := [[0x230070, 15000], [0x2303ac, 0x10000], [0x2303a8, 0x111]]
const CTRL := [0x270040, 0x230000]    # BALL+0x40 = P (p IS the ball controller -> 75% strength cut)
const TEAMP := [0x260444, 0x2a0000]   # M+0x444 -> OTHER (team-id holder for the mismatch fixture)

# name -> [pokes, heading, strength]. PTRS + FORMULA are prepended to every fixture in _build.
var FIXTURES := {
	"formula": [[], 0x2222, 100],
	"formula_str80": [[], 0x1234, 80],
	"formula_scale": [[CTRL], 0x2222, 100],
	"park_flagclear": [[[0x260448, 3]], 0x3000, 100],
	"park_mismatch": [[[0x260448, 4], [0x260461, 0x40], TEAMP, [0x2302b8, 10], [0x2a02b8, 20]], 0x4000, 100],
	"noscale_match": [[[0x260448, 5], [0x260461, 0x40], TEAMP, [0x2302b8, 10], [0x2a02b8, 10]], 0x5000, 100],
	"phase1_formula": [[[0x260448, 1]], 0x6000, 100],
}


func _init() -> void:
	var path := ProjectSettings.globalize_path("res://").path_join("../tools/re/specs/8ac0_oracle.txt").simplify_path()
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		_ok(false, "8ac0 oracle unreadable (run tools/re/run_8ac0_oracle.sh)")
		_finish()
		return
	var rx_6c := RegEx.new()
	rx_6c.compile("mem\\[0x23006c:4\\]=(-?\\d+)")
	var rx_arg := RegEx.new()
	rx_arg.compile("m8f20_arg0=(-?\\d+)")

	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if not line.begins_with("FIX "):
			continue
		var name := line.substr(4, line.find("|") - 4).strip_edges()
		var m6c := rx_6c.search(line)
		var marg := rx_arg.search(line)
		if m6c == null or marg == null:
			_ok(false, "%s: malformed oracle row" % name)
			continue
		_check(name, m6c.get_string(1).to_int(), marg.get_string(1).to_int())
	_finish()


func _finish() -> void:
	print("")
	print("ALL PASS (%d checks)" % _pass if _fail == 0 else "FAILED: %d / %d" % [_fail, _pass + _fail])
	quit(1 if _fail > 0 else 0)


func _check(name: String, want_6c: int, want_arg0: int) -> void:
	if not FIXTURES.has(name):
		_ok(false, "%s: no fixture mirror in test_8ac0.gd" % name)
		return
	var spec: Array = FIXTURES[name]
	var heading: int = int(spec[1])
	var strength: int = int(spec[2])
	# Heading passthrough: the value we hand the function must equal the one the oracle forwarded to 8f20.
	_ok((heading & U32) == (want_arg0 & U32), "%s heading passthrough: fixture %d vs oracle arg0 %d" % [name, heading & U32, want_arg0 & U32])

	var p := _build(spec[0])
	p[0x2d7] = 1                                         # pre-arm the once-per-tick guard -> 8f20 inert
	Pm98Movement.windup_8ac0(p, heading, strength)
	var got_6c := Pm98Trig._i32(int(p.get(0x6c, 0))) & U32
	_ok(got_6c == (want_6c & U32), "%s p+0x6c: got %d want %d" % [name, got_6c, want_6c & U32])


## Rebuild the fixture's Dict graph from the poke list. A poke whose VALUE is a known region base
## links the referenced struct Dict; otherwise it is a scalar field write keyed by the offset.
func _build(pokes: Array) -> Dictionary:
	var structs := {"p": {}, "m": {}, "ball": {}, "other": {}}
	var all_pokes: Array = []
	for pk in PTRS:
		all_pokes.append(pk)
	for pk in FORMULA:
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
