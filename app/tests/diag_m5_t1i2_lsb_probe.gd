extends SceneTree
## M5 s46 one-off: map the atan LSB boundary around the t1.i2 clk-286 steer target.
## Port face = flip(atan_angle(target - pos)) = 0x7b3c; silicon = 0x7b3d. The port trio is
## PCode-exonerated on these exact inputs (tools/re/run_steering_t1i2_clk286.sh), so the
## silicon target must differ. This probe finds WHICH (tx,ty) neighborhood lands 0x7b3d.
## Run: ~/godot462 --headless --path app --script res://tests/diag_m5_t1i2_lsb_probe.gd

const PX := 768985
const PY := -895007
const FACE := 0x7b19


func _face_for(tx: int, ty: int) -> int:
	var dx := tx - PX
	var dy := ty - PY
	var heading := Pm98Trig.atan_angle(dx, dy)
	# 8bc0 flip: a1 = s16(heading - face - 0x8000); |a1| < 0x2000 and boxes pass -> fold.
	var a1 := Pm98Trig._s16(heading - FACE - 0x8000)
	if absi(a1) < 0x2000:
		heading = Pm98Trig._i32(heading - 0x8000)
	# 8f20: d = heading - face; |s16 d| < 0x500 -> steps 1 -> face = heading.
	return heading & 0xffff


func _init() -> void:
	var base := _face_for(858960, -905589)
	print("base target (858960,-905589) -> face %x" % base)
	# sweep tx at fixed ty
	var flips := []
	for tx in range(858960 - 200, 858960 + 201):
		if _face_for(tx, -905589) != base:
			flips.append(tx - 858960)
	print("tx offsets (ty fixed) landing != base within +/-200: %s" % [
		"none" if flips.is_empty() else str(flips.slice(0, 8)) + (" ... n=%d" % flips.size())])
	# nearest boundary above/below in tx
	var up := -1
	for d in range(1, 5000):
		if _face_for(858960 + d, -905589) != base:
			up = d
			break
	var dn := -1
	for d in range(1, 5000):
		if _face_for(858960 - d, -905589) != base:
			dn = d
			break
	print("nearest tx flip: +%d -> %x | -%d -> %x" % [
		up, _face_for(858960 + up, -905589) if up > 0 else -1,
		dn, _face_for(858960 - dn, -905589) if dn > 0 else -1])
	# sweep ty at fixed tx
	var upy := -1
	for d in range(1, 5000):
		if _face_for(858960, -905589 + d) != base:
			upy = d
			break
	var dny := -1
	for d in range(1, 5000):
		if _face_for(858960, -905589 - d) != base:
			dny = d
			break
	print("nearest ty flip: +%d -> %x | -%d -> %x" % [
		upy, _face_for(858960, -905589 + upy) if upy > 0 else -1,
		dny, _face_for(858960, -905589 - dny) if dny > 0 else -1])
	# what does a 1-unit ball_x shift do (target x moves by ~1/2)?
	print("tx+1 -> %x  tx-1 -> %x  ty+1 -> %x  ty-1 -> %x" % [
		_face_for(858961, -905589), _face_for(858959, -905589),
		_face_for(858960, -905588), _face_for(858960, -905590)])
	# also: pos 1-unit variants (if silicon pos differed sub-capture... it did not; sanity)
	quit(0)
