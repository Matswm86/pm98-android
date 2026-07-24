extends SceneTree
## M5 s54: which TARGET POINT does silicon's applied heading correspond to?
##
## s53 measured the heading argument silicon hands FUN_005a8f20 at the applied call
## (ret0 0x5a8eee, guard 0) together with the player position at that instant:
##
##   clk 639 pos (350402,-1839495) -> 771      clk 643 pos (351448,-1838509) -> 765
##   clk 640 pos (350939,-1838834) -> 767      clk 644 pos (351970,-1838470) -> 765
##   clk 641 pos (351187,-1838528) -> 765      clk 645 pos (352753,-1838411) -> 765
##   clk 642 pos (351187,-1838528) -> 765      clk 646 pos (353798,-1838333) -> 765
##
## FUN_005a8bc0 computes that heading as atan_angle(target - P) (the curve-flip cannot fire
## here: |delta| is far outside the +-0x20000 box, s52 §1). So EVERY candidate target point is
## testable against 8 independent (pos, heading) pairs with zero free parameters. This drill
## runs the port's own Pm98Trig.atan_angle -- the LUT-faithful one -- over the candidates.
##
## Run: ~/godot462 --headless --path app --script res://tests/diag_m5_s54_headingsolve.gd

# clk, pos_x, pos_y, silicon heading at the applied 0x5a8eee call (s53 steer8f20 capture)
const SIL := [
	[639, 350402, -1839495, 771],
	[640, 350939, -1838834, 767],
	[641, 351187, -1838528, 765],
	[642, 351187, -1838528, 765],
	[643, 351448, -1838509, 765],
	[644, 351970, -1838470, 765],
	[645, 352753, -1838411, 765],
	[646, 353798, -1838333, 765],
]

# Live ball pos/vel per clk (oracle_dartwatch_s53_arm_630_660.jsonl, t1.i10 window).
const BALL := {
	639: [770857, -1945817, 161386],
	640: [784490, -1943366, 168100],
	641: [798123, -1940915, 174636],
	642: [811756, -1938464, 180994],
	643: [825389, -1936013, 187174],
	644: [839022, -1933562, 193176],
	645: [852655, -1931111, 199000],
	646: [866288, -1928660, 204646],
}
const BVEL := [13633, 2451]
const BFACE := 1854

# Candidate C1: ctrl+0x84/0x88/0x8c, the b0040 CARRIER-block point. Constant across the whole
# window in the port (app/tests/diag_m5_t1i10_b0040iter.gd, clk 640-646).
const C84 := [2078007, -1710796, 0]


func _init() -> void:
	_run()
	quit(0)


func _run() -> void:
	print("# candidate C1 = ctrl+0x84 = %s" % str(C84))
	print("# clk |    pos          | silicon | atan(C84-P) | d   || best marker slot | lead for hdg")
	var hits := 0
	for e in SIL:
		var clk := int(e[0])
		var px := int(e[1])
		var py := int(e[2])
		var sil := int(e[3])
		var h84 := Pm98Trig.atan_angle(Pm98Trig._i32(C84[0] - px), Pm98Trig._i32(C84[1] - py))
		if h84 == sil:
			hits += 1
		# best of the 16 interception marker slots (ball.pos + i*4*ball.vel)
		var b: Array = BALL[clk]
		var best := -1
		var best_d := 1 << 30
		for i in range(16):
			var mx := int(b[0]) + i * 4 * BVEL[0]
			var my := int(b[1]) + i * 4 * BVEL[1]
			var hm := Pm98Trig.atan_angle(Pm98Trig._i32(mx - px), Pm98Trig._i32(my - py))
			var dd: int = absi(hm - sil)
			if dd < best_d:
				best_d = dd
				best = i
		# lead L such that atan(ball.pos + facedir*L - P) == silicon heading
		var fd: Array = Pm98Trig.polar_vec(0x10000, BFACE)
		var lead := _solve_lead(px, py, int(b[0]), int(b[1]), int(fd[0]), int(fd[1]), sil)
		print("%5d | (%d,%d) | %7d | %11d | %+3d || slot %2d (d=%d) | lead=%s" % [
			clk, px, py, sil, h84, h84 - sil, best, best_d, str(lead)])
	print("\n# C84 exact hits: %d / %d" % [hits, SIL.size()])


## Bisect the smallest non-negative lead whose interception point reproduces `want`.
func _solve_lead(px: int, py: int, bx: int, by: int, fx: int, fy: int, want: int) -> int:
	var found := -1
	# atan of (ball + facedir*L - P) is monotone in L along this ray, so a plain scan of
	# decades then a refine is enough; keep it simple and robust.
	var l := 1
	while l < (1 << 31):
		var hx := Pm98Trig._i32(bx + Pm98Trig._tdiv(l * fx, 0x10000) - px)
		var hy := Pm98Trig._i32(by + Pm98Trig._tdiv(l * fy, 0x10000) - py)
		if Pm98Trig.atan_angle(hx, hy) == want:
			found = l
			break
		l = l + max(1, l / 64)
	if found < 0:
		return -1
	# walk back to the smallest lead with the same heading
	while found > 1:
		var t := found - 1
		var hx2 := Pm98Trig._i32(bx + Pm98Trig._tdiv(t * fx, 0x10000) - px)
		var hy2 := Pm98Trig._i32(by + Pm98Trig._tdiv(t * fy, 0x10000) - py)
		if Pm98Trig.atan_angle(hx2, hy2) != want:
			break
		found = t
	return found


func absi(v: int) -> int:
	return -v if v < 0 else v
