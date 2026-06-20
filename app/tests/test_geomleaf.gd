extends SceneTree
## Oracle-backed parity test for the goal/pitch collision-geometry leaves
## FUN_005a1870 / 005a1990 / 005a18a0 / 005a1a30, ported in Pm98Trig.vec3_div_scalar /
## quad_copy / vec3_lerp / quad_bilerp. These build the master geometry array (match+0x27c8)
## the post/collider list is copied from -- see docs/re/goal/collision_geometry_builder_re.md.
##
## Run headless: ~/godot462 --headless --path app --script res://tests/test_geomleaf.gd
## ORACLE = tools/re/run_geomleaf_oracle.sh -> specs/geomleaf_oracle.txt (REAL leaves, PCode emu).

const OUTV := 0x210000
const U32 := 0xffffffff

# inputs mirror the oracle MATRIX exactly (run_geomleaf_oracle.sh)
const DIV := {
	"div_pos": [[0x64, 0x2710, -0x4d2], 0x7],
	"div_neg": [[-0x100000, 0x30001, 0x1], 0x10000],
	"div_tz": [[0x7, -0x7, 0x9], 0x4],
}
const LERP := {
	# a, b, mult, div
	"lerp_half": [[0x0, 0x0, 0x0], [0x20000, 0x40000, 0x60000], 0x1, 0x2],
	"lerp_third": [[0x10000, -0x10000, 0x4000], [0x70000, 0x20000, -0x8000], 0x1, 0x3],
	"lerp_off": [[0x12345, 0x6789, -0x4321], [-0x55555, 0x33333, 0x10000], 0x5, 0x8],
}
const BILERP := {
	# c0, c1, c2, c3, m1, d1, m2, d2   (oracle passes M1 M2 D1 D2)
	"bilerp_mid": [[0x0, 0x0, 0x0], [0x40000, 0x0, 0x0], [0x40000, 0x40000, 0x0], [0x0, 0x40000, 0x0], 0x1, 0x2, 0x1, 0x2],
	"bilerp_q": [[0x10000, 0x20000, 0x0], [0x50000, 0x20000, 0x4000], [0x50000, 0x60000, 0x8000], [0x10000, 0x60000, 0x2000], 0x1, 0x4, 0x2, 0x3],
}
# batch 2: face normal (flat 9-int quad c0|c1|c2), broadcast translate, AABB init/expand/copy6
const FNORM := {
	"fnorm_axis": [0x0, 0x0, 0x0, 0x10000, 0x0, 0x0, 0x10000, 0x10000, 0x0],
	"fnorm_arb": [0x12345, -0x6789, 0x3333, 0x40000, 0x10000, -0x8000, -0x20000, 0x50000, 0x12000],
}
const ADDSC := {
	# v, scalar
	"addsc_pos": [[0x100, -0x200, 0x300], 0x50],
	"addsc_neg": [[0x1000, 0x2000, -0x3000], -0x1234],
	"addsc_wrap": [[0x7ffffff0, 0x0, 0x0], 0x20],
}
const AABBEXP := {
	# aabb (6), point (3)  -- "fresh" uses the init sentinels (max = signed -0x70000000)
	"aabbexp_fresh": [[0x70000000, 0x70000000, 0x70000000, -0x70000000, -0x70000000, -0x70000000], [0x100, -0x200, 0x300]],
	"aabbexp_part": [[0x0, 0x0, 0x0, 0x1000, 0x1000, 0x1000], [-0x50, 0x800, 0x2000]],
}
const COPY6 := {"copy6_a": 0x1000, "copy6_b": -0x8000}

var _fail := 0
var _pass := 0


func _init() -> void:
	var orc := _load_oracle()
	if orc.is_empty():
		_ok(false, "geomleaf oracle file empty/unreadable")
	else:
		for name in DIV:
			_check(name, orc, Pm98Trig.vec3_div_scalar(DIV[name][0], int(DIV[name][1])))
		for name in ["copy_a", "copy_b"]:
			_check_quad(name, orc, Pm98Trig.quad_copy(_ramp(name)))
		for name in LERP:
			var l: Array = LERP[name]
			_check(name, orc, Pm98Trig.vec3_lerp(l[0], l[1], int(l[2]), int(l[3])))
		for name in BILERP:
			var b: Array = BILERP[name]
			_check(name, orc, Pm98Trig.quad_bilerp(b[0], b[1], b[2], b[3], int(b[4]), int(b[5]), int(b[6]), int(b[7])))
		for name in FNORM:
			_check(name, orc, Pm98Trig.quad_face_normal(FNORM[name]))
		for name in ADDSC:
			_check(name, orc, Pm98Trig.vec3_add_scalar(ADDSC[name][0], int(ADDSC[name][1])))
		_check6("aabbinit_x", orc, Pm98Trig.aabb_init())
		for name in AABBEXP:
			var a: Array = AABBEXP[name]
			_check6(name, orc, Pm98Trig.aabb_expand_point(a[0].duplicate(), a[1]))
		for name in COPY6:
			_check6(name, orc, Pm98Trig.copy6(_ramp6(int(COPY6[name]))))
	print("")
	if _fail == 0:
		print("ALL PASS (%d checks)" % _pass)
	else:
		print("FAILED: %d / %d" % [_fail, _pass + _fail])
	quit(1 if _fail > 0 else 0)


func _ramp(name: String) -> Array:
	var base := 0x1000 if name == "copy_a" else -0x8000
	var out := []
	for i in range(12):
		out.append(base + i * 0x1111)
	return out


func _check(name: String, orc: Dictionary, v: Array) -> void:
	if not orc.has(name):
		_ok(false, name + ": missing from oracle file")
		return
	var exp: Dictionary = orc[name]
	var got := {0x0: int(v[0]) & U32, 0x4: int(v[1]) & U32, 0x8: int(v[2]) & U32}
	for off in [0x0, 0x4, 0x8]:
		_ok(got[off] == (int(exp[off]) & U32), "%s +0x%x: got 0x%x want 0x%x" % [name, off, got[off], int(exp[off]) & U32])


func _ramp6(base: int) -> Array:
	var out := []
	for i in range(6):
		out.append(base + i * 0x1111)
	return out


func _check6(name: String, orc: Dictionary, v: Array) -> void:
	if not orc.has(name):
		_ok(false, name + ": missing from oracle file")
		return
	var exp: Dictionary = orc[name]
	for i in range(6):
		var off := i * 4
		_ok((int(v[i]) & U32) == (int(exp[off]) & U32), "%s +0x%x: got 0x%x want 0x%x" % [name, off, int(v[i]) & U32, int(exp[off]) & U32])


func _check_quad(name: String, orc: Dictionary, v: Array) -> void:
	if not orc.has(name):
		_ok(false, name + ": missing from oracle file")
		return
	var exp: Dictionary = orc[name]
	for i in range(12):
		var off := i * 4
		_ok((int(v[i]) & U32) == (int(exp[off]) & U32), "%s [%d]: got 0x%x want 0x%x" % [name, i, int(v[i]) & U32, int(exp[off]) & U32])


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
	var f := FileAccess.open(_spec_path("geomleaf_oracle.txt"), FileAccess.READ)
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
			row[("0x" + mtch.get_string(1)).hex_to_int() - OUTV] = mtch.get_string(2).to_int()
		out[toks[1]] = row
	return out
