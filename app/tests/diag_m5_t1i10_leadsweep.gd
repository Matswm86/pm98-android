extends SceneTree
## M5 s52: the b0040 LEAD sweep at the clk-639 fork.
##
## The apply path (FUN_005b0040 tail -> FUN_005b1330 clamp -> FUN_005a89c0 -> FUN_005a8bc0 ->
## FUN_005a8f20) never re-clamps and never re-picks a target: 8f20 only turns P+0x34 toward the
## heading it is handed (+/-0x400, SNAP under 0x500) and commits P+0x64 when |s16 d| < 0x1555.
## So silicon's captured 0x34/0x64/0x68 ladder pins the APPLIED heading exactly, and that heading
## back-solves to a b0040 `lead` -- the loop's only free term. Every other b0040 input at the fork
## tick is byte-identical between port and silicon (player pos, ball pos/vel/face, the 16 marker
## slots); the ONLY unverified one is curve_rate = (P+0x70 * P+0x3ac)/15000 + P+0x3a8.
##
## This replays the REAL bisection (same formulas as Pm98Movement._b0040_target) on the captured
## fork-tick inputs while sweeping curve_rate, and prints the final lead + the heading the steering
## trio would then apply -- so "silicon's curve_rate differs" is either confirmed or killed.
##
## Run: ~/godot462 --headless --path app --script res://tests/diag_m5_t1i10_leadsweep.gd

# Fork-tick b0040 inputs, from diag_m5_t1i10_apply.gd (port) and cross-checked against the live
# s51 capture (data/pm98-m4-oracle/capture2/oracle_dartwatch_s51_630_660.jsonl, clk 639).
const P_POS := [350402, -1839495, 0]
const B_POS := [770857, -1945817, 161386]
const B_VEL := [13633, 2451, 6714]
const B_FACE := 1854
const PORT_CRATE := 6703                                # (13429*2739)/15000 + 4251
const SIL_HEADING := 765                                # back-solved from the s51 0x34/0x64 ladder


func _init() -> void:
	_run()
	quit(0)


func _run() -> void:
	var facedir: Array = Pm98Trig.polar_vec(0x10000, B_FACE)
	print("facedir=%s  ball_planar=%d" % [str(facedir), Pm98Trig.planar_mag(B_VEL[0], B_VEL[1])])
	print("# crate | iters  final lead        | steer target            | heading  (silicon=%d)" % SIL_HEADING)
	var rates := [PORT_CRATE, 6781, 8000, 10000, 12000, 13851, 14000, 16000, 20000, 30000, 50000, 100000]
	for cr in rates:
		var r: Array = _lead(int(cr), facedir)
		var lead: int = int(r[0])
		var tgt: Array = _target(lead, facedir)
		var hdg := Pm98Trig.atan_angle(Pm98Trig._i32(int(tgt[0]) - P_POS[0]),
			Pm98Trig._i32(int(tgt[1]) - P_POS[1]))
		print("%7d | %2d  %14d | %-24s | %5d%s" % [
			int(cr), int(r[1]), lead, "%d,%d" % [int(tgt[0]), int(tgt[1])], hdg,
			"   <-- MATCH" if hdg == SIL_HEADING else ""])

	# What lead does silicon's applied heading imply? heading rises monotonically with lead over
	# this range (see the table), so bisect on lead: the next capture knows what to compare against.
	var lo := 0
	var hi := 3600000
	while lo < hi:
		@warning_ignore("integer_division")
		var mid := (lo + hi) / 2
		var t2: Array = _target(mid, facedir)
		var h2 := Pm98Trig.atan_angle(Pm98Trig._i32(int(t2[0]) - P_POS[0]),
			Pm98Trig._i32(int(t2[1]) - P_POS[1]))
		if h2 < SIL_HEADING:
			lo = mid + 1
		else:
			hi = mid
	var tf: Array = _target(lo, facedir)
	print("\n# silicon heading %d  <=>  lead ~= %d  -> steer target (%d,%d)  [in pitch box, NO clamp]"
		% [SIL_HEADING, lo, int(tf[0]), int(tf[1])])
	print("# port lead at the same tick = -1040510322 (i18 signed wrap) -> clamped -corner, heading 34076")
	# The curve_rate needed for the loop to land there, and the P+0x70 it would take.
	print("# heading 765 sits between crate 16000 (990) and 20000 (277): crate ~1.7e4 => P+0x70 ~= %d"
		% Pm98Trig._tdiv((17000 - 4251) * 15000, 2739))
	print("# real P+0x70 at frame 0 = 13860 (frame0_struct_import.json); port at the fork tick = 13429")


## The <=0x12-iteration interception bisection, verbatim from Pm98Movement._b0040_target, with
## curve_rate as a free parameter. Returns [final_lead, iterations].
func _lead(curve_rate: int, facedir: Array) -> Array:
	var px: int = P_POS[0]
	var py: int = P_POS[1]
	var pz: int = P_POS[2]
	var bx: int = B_POS[0]
	var by: int = B_POS[1]
	var bz: int = B_POS[2]
	var rel := [Pm98Trig._i32(px - bx), Pm98Trig._i32(py - by), Pm98Trig._i32(pz - bz)]
	var lead := Pm98Movement._dot3_16(rel, facedir)
	var k := 0
	var conv := absi(lead)
	while conv > 0xccc and k < 0x12:
		var lp: Array = Pm98Trig.scale_vec3(int(facedir[0]), int(facedir[1]), int(facedir[2]), lead)
		var dx := Pm98Trig._i32(Pm98Trig._i32(px - int(lp[0])) - bx)
		var dy := Pm98Trig._i32(Pm98Trig._i32(py - by) - int(lp[1]))
		var ticks := Pm98Trig._tdiv(Pm98Trig.planar_mag(dx, dy), curve_rate)
		var uv9 := Pm98Trig._i32(ticks - 0x3c)
		if uv9 < 0:
			uv9 = 0
		var idx := Pm98Trig._tdiv(ticks, 4)
		if idx > 0xf:
			idx = 0xf
		# marker slot[i] == ball.pos.xy + i*4*ball.vel.xy in this window (s50 §4, s51 §3 live-verified)
		var mkx := Pm98Trig._i32(bx + idx * 4 * B_VEL[0])
		var mky := Pm98Trig._i32(by + idx * 4 * B_VEL[1])
		var tp := [
			Pm98Trig._i32(Pm98Trig._i32(uv9 * B_VEL[0]) + mkx - bx),
			Pm98Trig._i32(Pm98Trig._i32(uv9 * B_VEL[1]) + mky - by),
			Pm98Trig._i32(-bz),
		]
		var nd := Pm98Movement._dot3_16(tp, facedir)
		lead = Pm98Trig._tdiv(Pm98Trig._i32(nd + lead), 2)
		conv = absi(Pm98Trig._i32(lead - nd))
		k += 1
	return [lead, k]


## point = ball.pos + facedir*lead, then the per-axis pitch clamp (m+0x1828 lo / +0x1834 hi).
func _target(lead: int, facedir: Array) -> Array:
	var fp: Array = Pm98Trig.scale_vec3(int(facedir[0]), int(facedir[1]), int(facedir[2]), lead)
	var pt := [
		Pm98Trig._i32(B_POS[0] + int(fp[0])),
		Pm98Trig._i32(B_POS[1] + int(fp[1])),
		Pm98Trig._i32(B_POS[2] + int(fp[2])),
	]
	return [
		clampi(int(pt[0]), -3768320, 3768320),
		clampi(int(pt[1]), -2359296, 2359296),
		clampi(int(pt[2]), -65536, 65536000),
	]
