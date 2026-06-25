extends SceneTree
## Oracle-backed parity test for the NON-ACTIVE MOVEMENT CORE FUN_005b0040, ported in
## Pm98Movement._b0040_target (targeting half) + _move_b0040 (target -> steer_89c0 tail-call).
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_b0040.gd
##
## ORACLE = the REAL FUN_005b0040 driven through the Ghidra PCode emulator (tools/re/
## run_b0040_oracle.sh -> specs/b0040_oracle.txt). Each row banks the post-call P (0x230000)
## field dump PLUS the clamped steer target local_c (stack 0x307ff0/f4/f8) as `<abs-addr>=<u32 LE>`.
## Here we rebuild the identical Dict fixture, assert _b0040_target == the banked target, then
## drive _move_b0040 and assert every banked P field bit-exact (unsigned 32-bit).

const P_BASE := 0x230000
const C_BASE := 0x240000
const T_BASE := 0x307ff0          # local_c (steer target) stack triple

var _fail := 0
var _pass := 0

# name -> [phase, active_is_P, carry, octl_is_P, px, py, bx, by, bz, bvx, bvy, bface]
var _fixtures := {
	"stationary":  [0, false, 0, false, 0x60000, 0x10000, 0,      0, 0,       0,      0,      0],
	"intercept":   [0, false, 0, false, 0x60000, 0x10000, 0,      0, 0,       0x4000, 0x2000, 0x2000],
	"carriernear": [0, true,  1, true,  0x60000, 0x10000, 0x1000, 0, 0x20000, 0,      0,      0],
	"markeradj":   [0, false, 1, false, 0x60000, 0x10000, 0,      0, 0,       0x4000, 0x2000, 0x2000],
}


func _init() -> void:
	var orc := _load_oracle()
	if orc.is_empty():
		_ok(false, "b0040 oracle empty/unreadable (run tools/re/run_b0040_oracle.sh)")
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
	var f := FileAccess.open(_spec_path("b0040_oracle.txt"), FileAccess.READ)
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
	var C := {}
	var GS := {}
	var OTHER := {}
	P[0x184] = GS
	P[0x18c] = M
	P[0x190] = C
	P[0x4] = spec[4]                                   # px
	P[0x8] = spec[5]                                   # py
	P[0xc] = 0
	P[0x70] = 15000
	P[0x3ac] = 65536
	P[0x3a8] = 0
	P[0x388] = 0x4000
	P[0x2bc] = spec[2]                                 # carry flag
	M[0x448] = spec[0]                                 # phase
	M[0x461] = 0
	M[0x1970] = 0x7f000000
	M[0x1978] = 0x7f000000
	M[0x1828] = -0x10000000; M[0x182c] = -0x10000000; M[0x1830] = -0x10000000
	M[0x1834] = 0x10000000;  M[0x1838] = 0x10000000;  M[0x183c] = 0x10000000
	C[0x40] = P if spec[1] else OTHER                  # active-player ref
	C[0x4c] = P if spec[3] else OTHER                  # other-control slot (octl)
	C[0x4] = spec[6]; C[0x8] = spec[7]; C[0xc] = spec[8]
	C[0x20] = spec[9]; C[0x24] = spec[10]; C[0x28] = 0
	C[0x34] = spec[11]
	C[0x84] = 0x60000; C[0x88] = 0x20000; C[0x8c] = 0
	C[0xb0] = 0x30000; C[0xbc] = 0                     # marker-adjust thresholds
	C[0xcc] = 0x50000; C[0xd0] = 0x10000; C[0xd4] = 0  # marker A
	C[0xd8] = 0x40000; C[0xdc] = 0x18000; C[0xe0] = 0  # marker B
	return P


func _run_fixture(name: String, exp: Dictionary) -> void:
	# 1) targeting half: assert the clamped steer target (local_c) bit-exact, pre-steer.
	var Pt := _build(_fixtures[name])
	var target: Array = Pm98Movement._b0040_target(Pt)
	# 2) full routine on a fresh fixture: assert the post-steer P field dump.
	var P := _build(_fixtures[name])
	var C: Dictionary = P[0x190]
	Pm98Movement._move_b0040(P)

	for addr in exp:
		var a: int = int(addr)
		var want: int = int(exp[addr]) & 0xffffffff
		var got: int
		var tag: String
		if a >= T_BASE:
			var ti: int = (a - T_BASE) / 4
			got = int(target[ti]) & 0xffffffff
			tag = "target[%d]" % ti
		elif a >= C_BASE:
			var off: int = a - C_BASE
			got = int(C.get(off, 0)) & 0xffffffff
			tag = "ctrl+0x%x" % off
		else:
			var off: int = a - P_BASE
			got = int(P.get(off, 0)) & 0xffffffff
			tag = "P+0x%x" % off
		_ok(got == want, "%s %s: got %d want %d" % [name, tag, got, want])
