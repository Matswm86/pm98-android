class_name Pm98Predicates
extends RefCounted
## EXACT ports of MANAGER.EXE's ball-physics scoring predicates
## (docs/re/EXACT_PORT_PLAN.md, Stage 3 task 3). These are the continuous
## fixed-point ball-physics that classify a live shot and bounce the ball off the
## goal frame; the driver FUN_00598740 calls them every tick. Coordinate system:
## 0x10000 (65536) = one pitch unit; ball state at obj+4=x / +8=y / +0xc=z(height),
## velocity at +0x20=vx / +0x24=vy / +0x28=vz, match ptr at obj+0x1d4.
##
## Ported here (all verified bit-for-bit against the PCode-emulator oracle,
## tools/re/run_predicate_oracle.sh -> specs/predicate_oracle.txt, locked by
## test_predicates.gd):
##   * goal_area  = FUN_0058ede0 -- goal-area test + height-band bits (match+0x462)
##                  + z/y clamp-and-reflect with velocity damping.
##   * traj_copy  = FUN_0058f100 -- copy the ball's target trajectory to +0x90..0x98.
##   * post_bar   = FUN_0058fbe0 -- post/bar collision: clamp + reflect velocity.
##   * keeper_save = FUN_0058f140 -- keeper-reach save: box/reach test + ball+0x61
##                  latch + atan_angle reach geometry + deflect-write. Returns
##                  {ret, save}; the save-stat bump + 0x15/0x16 event enqueue
##                  (FUN_005909f0 -> FUN_00594470) are deferred to driver task 2.
##
## Like Pm98Resolver, `b` (ball) and `m` (match) are offset->int Dictionaries that
## are MUTATED in place exactly as the binary mutates the structs. Sound/commentary
## (FUN_00590f00, guarded by match+0x180a) and the keeper stat counter
## (FUN_005909f0, no-op when ball+0x50==0) are display-only and not modelled; the
## oracle fixtures set match+0x180a=0 + ball+0x50=0 so the binary skips them too.

const VEL_DAMP := 0x9eb8   # FUN_005ee1c0 scalar applied to the ball velocity on a bounce


static func _g(d: Dictionary, off: int) -> int:
	return int(d.get(off, 0))


## sign bucket: +1 when v >= 0, -1 when v < 0 (the binary's `((-1<v)-1 & ~1)+1`).
static func _sign(v: int) -> int:
	return 1 if v >= 0 else -1


## clamp v into [lo, hi] = min(hi, max(lo, v)); mirrors the keeper-box clamp asm
## (max(lo,v) via cmp/cmov then min(hi,.)). Assumes lo <= hi as the goal box always is.
static func _clamp(v: int, lo: int, hi: int) -> int:
	var r := lo if lo > v else v
	return hi if hi < r else r


## FUN_005ee1c0 on the ball velocity vector (+0x20/+0x24/+0x28): each *= s >> 16.
static func _damp_velocity(b: Dictionary) -> void:
	b[0x20] = Pm98Trig.mul16(_g(b, 0x20), VEL_DAMP)
	b[0x24] = Pm98Trig.mul16(_g(b, 0x24), VEL_DAMP)
	b[0x28] = Pm98Trig.mul16(_g(b, 0x28), VEL_DAMP)


## FUN_0058ede0: is the ball in the goal area? Sets the match+0x462 height-band bits
## and clamps the ball into the goal volume (reflecting + damping velocity on a
## clamp). Returns 1 if in-area (the binary's `local_35`), else 0.
static func goal_area(b: Dictionary, m: Dictionary) -> int:
	var line := Pm98Trig._i32(_g(m, 0x1820))
	var x := Pm98Trig._i32(_g(b, 4))
	var y := Pm98Trig._i32(_g(b, 8))
	var z := Pm98Trig._i32(_g(b, 0xc))
	# window1 = (-0x10000-line, -line) ; window2 = (line, line+0x10000) (post-sort).
	var w1lo := -0x10000 - line
	var w1hi := -line
	if w1hi < w1lo:
		var t := w1lo; w1lo = w1hi; w1hi = t
	var w2lo := line
	var w2hi := line + 0x10000
	if w2hi < w2lo:
		var t := w2lo; w2lo = w2hi; w2hi = t
	var in1 := w1lo < x and x < w1hi and -0x3a8f5 < y and y < 0x3a8f5 and -1 < z and z < 0x270a3
	var in2 := w2lo < x and x < w2hi and -0x3a8f5 < y and y < 0x3a8f5 and -1 < z and z < 0x270a3
	if not (in1 or in2):
		return 0

	# Height-band bits into match+0x462 (each step re-reads the running byte).
	var bb := _g(m, 0x462) & 0xff
	bb = (bb & 0xfe) | (1 if absi(y) > 0x2ffff else 0)                       # bit0: wide
	bb = (bb & 0xfd) | ((1 if z > 0x21eb7 else 0) << 1)                      # bit1: over bar
	var c2 := 1 if ((bb & 1) != 0 and z >= 0x1e666) else 0                   # bit2: high+wide
	bb = (bb & 0xfb) | (c2 << 2)
	bb = (bb & 0xf7) | ((1 if z < 0x6667 else 0) << 3)                       # bit3: low
	bb = (bb & 0xef) | ((1 if (bb & 7) == 0 else 0) << 4)                    # bit4: on-target
	m[0x462] = bb & 0xff
	# FUN_005909f0(1): no-op for the isolated fixture (ball+0x50 == 0).

	var reflected := false
	if z > 0x2170a:
		z = 0x2170a
		b[0xc] = z
		if _g(b, 0x28) > 0:
			reflected = true
			b[0x28] = Pm98Trig._i32(-_g(b, 0x28))
	if absi(y) > 0x37333:
		var ny := _sign(y) * 0x37333
		b[8] = ny
		if _sign(_g(b, 0x24)) == _sign(ny):
			reflected = true
			b[0x24] = Pm98Trig._i32(-_g(b, 0x24))
	if reflected:
		_damp_velocity(b)
	return 1


## FUN_0058f100: if armed (ball+0x63 != 0) and the match isn't paused (+0x448 == 0),
## copy the ball's target trajectory vector (the struct ball+0x40 points at, fields
## +4/+8/+0xc) into ball +0x90/+0x94/+0x98. `src` is that [x,y,z] vector.
static func traj_copy(b: Dictionary, m: Dictionary, src: Array) -> void:
	if _g(b, 0x63) != 0 and _g(m, 0x448) == 0:
		b[0x90] = Pm98Trig._i32(int(src[0]))
		b[0x94] = Pm98Trig._i32(int(src[1]))
		b[0x98] = Pm98Trig._i32(int(src[2]))


## FUN_0058fbe0: post/bar collision. If the ball is in the goal-frame box, write the
## deflection target (+0x90/+0x94/+0x98) and, when it crosses the bar (z) or post (y)
## boundary, clamp the position and reflect+damp the velocity. Returns 1 on collision.
static func post_bar(b: Dictionary, m: Dictionary) -> int:
	var line := Pm98Trig._i32(_g(m, 0x1820))
	var poss := _g(m, 0x19a0)
	var side := _g(b, 0x54)
	var x := Pm98Trig._i32(_g(b, 4))
	var y := Pm98Trig._i32(_g(b, 8))
	var z := Pm98Trig._i32(_g(b, 0xc))
	var post := Pm98Trig._i32(_g(m, 0x1824))

	var local_c := -line if (poss & 1) == side else line
	var xhi := (-line if (poss & 1) == side else line) * 2
	var w_lo := xhi
	if local_c < xhi:
		w_lo = local_c
		local_c = xhi
	# y window: (yw_lo, local_8) normalised to (-|post|, |post|).
	var yw_lo := -post
	var local_8 := post
	if -post != post and post <= -post:
		yw_lo = post
		local_8 = -post

	if x <= w_lo or local_c <= x or y <= yw_lo or local_8 <= y or z < 0 or z > 0x3e7ffff:
		return 0

	var d := 0x4ccc - line
	if (poss & 1) != side:
		d = -d
	b[0x90] = Pm98Trig._i32(d)
	b[0x94] = Pm98Trig._i32((post - 0xb333) * _sign(y))
	b[0x98] = 0
	if z < 0x2828e:
		var ay := absi(y)
		if ay < 0x3deb7:
			var reflected := false
			if absi(z - 0x2828e) < absi(ay - 0x3deb7):
				b[0xc] = 0x2828e
				if _g(b, 0x28) < 0:
					reflected = true
					b[0x28] = Pm98Trig._i32(-_g(b, 0x28))
			else:
				reflected = true
				b[8] = _sign(y) * 0x3deb7
				b[0x24] = Pm98Trig._i32(-_g(b, 0x24))
			if reflected:
				_damp_velocity(b)
	return 1


## FUN_0058f140: keeper-reach save. Classifies a live shot against the keeper's
## expanded reach box + goal mouth, latches the reach state in ball+0x61, and on the
## "was-reachable, now shooting past" edge runs the keeper-save geometry (an atan
## reach gate through the arctan LUT) and writes the deflection target (+0x90/+0x94/
## +0x98). `k` is the keeper struct (offset->int Dictionary); the keeper's own
## match-context (keeper+0x18c) is the same match `m` in play, so the kmatch reads
## (goal line +0x1820, possession +0x19a0) use `m`. DAT_006d31c4 is 0 in-sim.
##
## Returns {ret, save}: ret = the binary's bool return (1 = out-of-reach shot that
## survives the 0x61 latch -> deflection written; 0 = in-reach or latch not armed).
## save = whether the keeper-save fires -- the EXACT gate the binary uses to call
## FUN_005909f0 (bump the keeper save-stat + maybe enqueue commentary event 0x15/0x16).
## That stat increment + event enqueue (-> FUN_00594470, the match event queue) is
## driver-integration (Stage 3 task 2); keeper_save exposes the validated boolean.
## Oracle-validated bit-for-bit: tools/re/run_keeper_oracle.sh -> specs/keeper_oracle.txt.
static func keeper_save(b: Dictionary, m: Dictionary, k: Dictionary) -> Dictionary:
	var x := Pm98Trig._i32(_g(b, 4))
	var y := Pm98Trig._i32(_g(b, 8))
	var z := Pm98Trig._i32(_g(b, 0xc))
	# Expanded keeper box: match+0x1828..+0x1830 (min) / +0x1834..+0x183c (max), +-0xccc.
	var min_x := Pm98Trig._i32(_g(m, 0x1828)) - 0xccc
	var min_y := Pm98Trig._i32(_g(m, 0x182c)) - 0xccc
	var min_z := Pm98Trig._i32(_g(m, 0x1830)) - 0xccc
	var max_x := Pm98Trig._i32(_g(m, 0x1834)) + 0xccc
	var max_y := Pm98Trig._i32(_g(m, 0x1838)) + 0xccc
	var max_z := Pm98Trig._i32(_g(m, 0x183c)) + 0xccc
	var inside := not (x < min_x or max_x < x or y < min_y or max_y < y or z < min_z or max_z < z)

	var line := Pm98Trig._i32(_g(m, 0x1820))
	var bvar12 := 0 if (inside or (absi(y) < 0x3a8f5 and absi(x) <= line + 0x10000 and z < 0x270a3)) else 1

	# ball+0x61 reach latch: bit0 is SET whenever in-reach (bvar12==0); the save path
	# survives only on the out-of-reach edge while the latch is already odd.
	var b9 := (_g(b, 0x61) | (1 if bvar12 == 0 else 0)) & 0xff
	b[0x61] = b9
	bvar12 = bvar12 & b9          # byte AND; bvar12 in {0,1}
	if bvar12 == 0:
		return {"ret": bvar12, "save": false}

	var save_fired := false
	if _g(b, 0x4c) == 0 and _g(b, 0x50) != 0:
		# DAT_006d31c4 == 0 in-sim -> run the keeper-reach geometry, then clear the keeper.
		var sgn_sel := (1 - _g(k, 0x2b8)) ^ (_g(m, 0x19a0) & 1)
		var gline := line if sgn_sel != 0 else -line      # signed goal line (kmatch+0x1820)
		var kx := Pm98Trig._i32(_g(k, 4))
		var ky := Pm98Trig._i32(_g(k, 8))
		# angle keeper->goal-line vs keeper->ball; keeper+0x34 cancels (k34 - k34).
		var a1 := Pm98Trig.atan_angle(gline - kx, -ky)
		var a2 := Pm98Trig.atan_angle(x - kx, y - ky)
		if absi(Pm98Trig._s16(a2 - a1)) < 0x3555:
			if absi(Pm98Trig._i32(_g(k, 0x3a4) + kx)) < 0x370000:
				save_fired = true
		b[0x50] = 0

	# Deflection target: clamp the ball into the RAW goal box, zero z, nudge y outward.
	b[0x90] = _clamp(x, Pm98Trig._i32(_g(m, 0x1828)), Pm98Trig._i32(_g(m, 0x1834)))
	b[0x98] = 0
	var oy := _clamp(y, Pm98Trig._i32(_g(m, 0x182c)), Pm98Trig._i32(_g(m, 0x1838)))
	b[0x94] = Pm98Trig._i32(oy + _sign(oy) * 0x6666)
	return {"ret": bvar12, "save": save_fired}
