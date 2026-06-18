extends SceneTree
## Oracle-backed parity test for the EXACT trig-LUT initializer (Stage 3 task 1):
## FUN_005edff0 + its reader primitives, ported in Pm98Trig.gd.
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_trig_lut.gd
##
## ORACLE = the PM98 binary's own constants + its real x87 fcos/fpatan, captured by
## tools/re/lut_oracle.c (which embeds the exact 8-byte .rdata doubles and executes
## the same instructions). Its ground-truth tables are banked at
## tools/re/specs/{cos,atan}_lut.txt. This test regenerates the tables in GDScript
## (int(cos()*65536) truncation, exact C1..C4 literals) and asserts every one of the
## 4096 cos + 8193 atan entries reproduces the binary bit-for-bit, then locks the
## reader primitives (polar/rotate/atan2) to vectors derived from that verified LUT.

var _fail := 0
var _pass := 0


func _init() -> void:
	_test_tables()
	_test_structural()
	_test_readers()
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


func _spec_path(name: String) -> String:
	# res:// globalizes to <repo>/app/ ; the oracle files live in <repo>/tools/re/specs/.
	return ProjectSettings.globalize_path("res://").path_join("../tools/re/specs/").path_join(name).simplify_path()


func _load_ints(name: String) -> PackedInt64Array:
	var out := PackedInt64Array()
	var f := FileAccess.open(_spec_path(name), FileAccess.READ)
	if f == null:
		_ok(false, "cannot open oracle " + _spec_path(name))
		return out
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if line != "":
			out.append(line.to_int())
	return out


func _test_tables() -> void:
	print("== LUT bit-for-bit vs banked fcos/fpatan oracle ==")
	var cos_oracle := _load_ints("cos_lut.txt")
	var atan_oracle := _load_ints("atan_lut.txt")
	_ok(cos_oracle.size() == 4096, "cos oracle has 4096 rows (got %d)" % cos_oracle.size())
	_ok(atan_oracle.size() == 8193, "atan oracle has 8193 rows (got %d)" % atan_oracle.size())
	_ok(Pm98Trig.COS.size() == 4096, "Pm98Trig.COS size 4096 (got %d)" % Pm98Trig.COS.size())
	_ok(Pm98Trig.ATAN.size() == 8193, "Pm98Trig.ATAN size 8193 (got %d)" % Pm98Trig.ATAN.size())

	var cos_diff := 0
	var first_cd := -1
	for k in min(4096, cos_oracle.size()):
		if Pm98Trig.COS[k] != cos_oracle[k]:
			cos_diff += 1
			if first_cd < 0:
				first_cd = k
	_ok(cos_diff == 0, "cos LUT: %d entries differ (first k=%d)" % [cos_diff, first_cd])

	var atan_diff := 0
	var first_ad := -1
	for j in min(8193, atan_oracle.size()):
		if Pm98Trig.ATAN[j] != atan_oracle[j]:
			atan_diff += 1
			if first_ad < 0:
				first_ad = j
	_ok(atan_diff == 0, "atan LUT: %d entries differ (first j=%d)" % [atan_diff, first_ad])

	# Compact 63-bit checksum (banked from tools/re/lut_oracle.c / the Python derive).
	var hc := 0
	for v in Pm98Trig.COS:
		hc = (hc * 131 + (v & 0xffffffff)) & 0x7fffffffffffffff
	var ha := 0
	for v in Pm98Trig.ATAN:
		ha = (ha * 131 + (v & 0xffffffff)) & 0x7fffffffffffffff
	_ok(hc == 6965426268288122880, "cos checksum (got %d)" % hc)
	_ok(ha == 2786881516485502172, "atan checksum (got %d)" % ha)
	print("  cos diffs=%d  atan diffs=%d" % [cos_diff, atan_diff])


func _test_structural() -> void:
	print("== structural invariants ==")
	_ok(Pm98Trig.COS[0] == 65536, "COS[0] = 1.0 (65536)")
	_ok(Pm98Trig.COS[1024] == 0, "COS[1024] = cos(90) = 0")
	_ok(Pm98Trig.COS[2048] == -65536, "COS[2048] = cos(180) = -1.0")
	_ok(Pm98Trig.COS[3072] == 0, "COS[3072] = cos(270) = 0")
	# cos is even about the circle: COS[k] == COS[4096-k].
	var sym_bad := 0
	for k in range(1, 2048):
		if Pm98Trig.COS[k] != Pm98Trig.COS[4096 - k]:
			sym_bad += 1
	_ok(sym_bad == 0, "cos even-symmetry COS[k]==COS[4096-k] (%d bad)" % sym_bad)
	_ok(Pm98Trig.ATAN[0] == 0, "ATAN[0] = atan(0) = 0")
	_ok(Pm98Trig.ATAN[8192] == 8191, "ATAN[8192] = atan(1) = 0x2000-1")


func _test_readers() -> void:
	print("== reader primitives (vectors from the verified LUT) ==")
	# polar_vec(r, angle) -> [(r*cos)>>16, (r*sin)>>16, 0]
	_ok(Pm98Trig.polar_vec(0x100000, 0) == [1048576, 1600, 0], "polar r=0x100000 a=0")
	_ok(Pm98Trig.polar_vec(0x100000, 0x1000) == [968752, 402752, 0], "polar a=0x1000")
	_ok(Pm98Trig.polar_vec(0x100000, 0x2000) == [741440, 742576, 0], "polar a=0x2000")
	_ok(Pm98Trig.polar_vec(0x100000, 0x3000) == [401264, 969360, 0], "polar a=0x3000")
	_ok(Pm98Trig.polar_vec(0x80000, -0x1000) == [484376, -199888, 0], "polar a=-0x1000 (neg)")
	# rotate_vec(x, y, angle)
	_ok(Pm98Trig.rotate_vec(0x100000, 0, 0x1000) == [968752, 402752], "rotate (r,0) by 0x1000")
	_ok(Pm98Trig.rotate_vec(0x100000, 0x80000, 0x2000) == [370152, 1113296], "rotate by 0x2000")
	_ok(Pm98Trig.rotate_vec(-0x40000, 0x40000, -0x800) == [-206360, 307848], "rotate neg by neg")
	# atan_angle(p1, p2)
	_ok(Pm98Trig.atan_angle(0x10000, 0) == 0, "atan (x,0) = 0")
	_ok(Pm98Trig.atan_angle(0, 0x10000) == 16384, "atan (0,y) = 0x4000")
	_ok(Pm98Trig.atan_angle(0x10000, 0x10000) == 8191, "atan (1,1) = 0x2000-1")
	_ok(Pm98Trig.atan_angle(-0x10000, 0x8000) == 27932, "atan quadrant fold (neg p1)")
	_ok(Pm98Trig.atan_angle(0x8000, -0x10000) == -11548, "atan quadrant fold (neg p2)")
	_ok(Pm98Trig.atan_angle(0, 0) == 0, "atan (0,0) = 0")
	_ok(Pm98Trig.atan_angle(0x4000, 0x10000) == 13829, "atan steep case (p1<p2)")
