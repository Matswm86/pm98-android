class_name Pm98Resolver
extends RefCounted
## EXACT ports of decoded primitives from MANAGER.EXE's shot/tackle/save resolver
## FUN_005aeda0 (docs/re/EXACT_PORT_PLAN.md, stage S3-B). Unlike MatchEngine.gd's
## CALIBRATED per-shot model, every function here is verified bit-for-bit against
## the original binary: the raw x86 disassembly AND the Ghidra PCode emulator (the
## oracle in tools/re/ghidra_scripts/PcodeEmu.java). Do NOT "tune" these numbers --
## they are not parameters, they are the binary. tests/test_resolver_gate.gd locks
## them to the emulator's output table.
##
## This is the first decoded slice. The full positional sim + tactics coupling are
## still to be ported (stages S4-S6); MatchEngine.simulate() keeps using the
## calibrated model until the exact engine is wired in at stage S7.


## PM98's per-mil probability scaling, the exact x86 idiom from the resolver:
##   roll*1000  -> cdq/and 0x7fff (round toward zero for negatives) -> sar 15
## For a valid RNG draw (0..32767) the product is non-negative, so the rounding
## term is 0 and this reduces to (roll*1000) >> 15 -- a uniform value in [0,1000).
## Verified at 0x5aeee2..0x5aeeff: draw 41 -> 1, matching the emulator.
static func permil_scale(roll: int) -> int:
	var p := roll * 1000
	var round_term := 0
	if p < 0:
		round_term = (p >> 31) & 0x7fff
	return (p + round_term) >> 15


## Finishing-gate threshold (per-mil), piecewise-linear in the shooter's finishing
## attribute at player+0x398, with a KINK at 55. Exact form from FUN_005aeda0
## (0x5aeec3..0x5aeefc): `imul 0x55555556` = signed div-by-3 (truncating), then x9;
## above the kink it is (ATTR-25)*9. The sub-55 branch is STEPPED -- 9*floor(ATTR/3),
## NOT linear 3*ATTR (e.g. ATTR 50 -> 144, not 150). The emulator's register dump
## confirms the whole table (tests/test_resolver_gate.gd): 54->162 then 55->270.
static func finishing_threshold_permil(attr: int) -> int:
	if attr < 55:
		return 9 * (attr / 3)   # integer division: 9 * floor(attr/3)
	return 9 * (attr - 25)


## The shot-proceeds gate itself: consume one RNG draw and compare. Returns true
## when the chance is taken to resolution. `rng` is MatchEngine.Pm98Rng (the exact
## MSVC LCG, itself oracle-verified against srand(1) -> 41,18467,6334,26500,19169).
static func shot_proceeds(rng: MatchEngine.Pm98Rng, attr: int) -> bool:
	return permil_scale(rng.next()) < finishing_threshold_permil(attr)


# ============================================================================
# Stage 2b: the goal/save/miss DECISION TREE of FUN_005aeda0 (lines 120-485 of
# docs/re/sim/fn_005aeda0_FUN_005aeda0.c), ported faithfully and validated
# bit-for-bit against the PCode-emulator oracle ground truth in
# tools/re/specs/tree_oracle_streams.txt (test_resolver_tree.gd). The RNG draw
# ORDER is load-bearing: every FUN_005ec250 call consumes one MSVC-LCG draw and
# the branch structure decides how many are consumed; reproducing that exactly is
# the whole point. Proven LUT-INVARIANT (tools/re/check_lut_invariance.sh), so the
# sin/cos projection geometry is NOT modelled here -- the position-fallback
# distance gate (lines 213-235, pure integer, no LUT) governs for the constructed
# fixtures, and real ball coordinates + the movement block (491-607) are Stage 3.
#
# The player/target/match/stats structs are passed as Dictionaries keyed by the
# raw byte offset (int), defaulting to 0. resolve_tree() mutates t/m/stats in place
# (target play-state, match+0x461 outcome bits, stat counters) exactly as the
# binary does, and returns a small result dict for assertions.
# ============================================================================

## Faithful top-level entry of FUN_005aeda0 -- the case-8/9 post-shot RESOLVER that engine_tick's
## action switch dispatches to (Pm98Action._resolve_action). The decompile has THREE sections:
##
##   * L41-118  the finishing PRE-BLOCK (fires only when player play-state +0x2c == 3 AND +0x30 == 0):
##              a tackle/intercept windup laid on the TARGET. PORTED s59 (2026-07-26) as
##              _finishing_1b -- the s59 capture falsified the old "provably inert" claim at
##              clk 1449 (silicon drew its C79 roll there). FUN_005b1230/FUN_005a1700 are
##              trivial vec3 ops (scale / add), FUN_005a7220 arms the motion-lerp.
##   * L120-485 the play-state dispatch (chase for +0x2c < 3 / > 8; tree for [3,8]) + the main
##              goal/save/miss DECISION TREE -> resolve_tree() below (oracle-GREEN, test_resolver_tree).
##   * L491-607 the post-resolution ball-touch MOVEMENT tail (probe + touch + velocity
##              redirect). PORTED s59 as _touch_tail, reached through _afabf on every
##              LAB_005afabf route exactly as the binary falls through -- it is the mid-air
##              deflection the s59 capture showed at clk 1450 (ball vy 686 -> 5414, carrier
##              cleared, ball+0x70 cooldown armed).
##
## `p`/`t`/`m`/`stats` are offset->int dicts; `rng` is MatchEngine.Pm98Rng. Returns
## resolve_tree's result dict.
static func resolve_action(p: Dictionary, t: Dictionary, m: Dictionary, stats: Dictionary,
		rng: MatchEngine.Pm98Rng) -> Dictionary:
	# L38 entry guard (match+0x448 != 0 -> no resolution this tick) is inside resolve_tree,
	# and since s59 (2026-07-26) so are the finishing pre-block (L41-118, _finishing_1b) and
	# the ball-touch movement tail (L491-607, _touch_tail via _afabf). The old "provably
	# inert" claim was falsified by the s59 capture at clk 1449-1450: silicon ran the C79
	# finishing roll and the touch tail's C550/C585 draws + mid-air deflection there.
	return resolve_tree(p, t, m, stats, rng)


## Signed (a*b) >> 15 with the binary's round-toward-zero term (`>>31 & 0x7fff`).
## For non-negative products this is just (a*b)>>15.
static func _fixmul15(a: int, b: int) -> int:
	var p := a * b
	if p < 0:
		return (p + 0x7fff) >> 15
	return p >> 15


## The binary's two forms of (roll*scale)>>15: a direct fixmul when scale < 0x8000,
## else an overflow-safe >>8-then->>7 split (`((scale+round8)>>8)*roll` then `>>7`).
## The split is NOT algebraically equal to the direct form (intermediate truncation),
## so it must be replicated exactly -- e.g. scale 78643, roll 41 -> 98, not 98.4.
static func _prob_scale(roll: int, scale: int) -> int:
	if scale < 0x8000:
		return _fixmul15(roll, scale)
	var t := ((scale + ((scale >> 31) & 0xff)) >> 8) * roll
	return (t + ((t >> 31) & 0x7f)) >> 7


## PM98's permil idiom on a single draw: (roll*1000)>>15, uniform in [0,1000).
static func _permil(roll: int) -> int:
	return (roll * 1000) >> 15


## 16-bit sign-extension (the facing angles at player/target +0x34 are `short`).
static func _s16(v: int) -> int:
	v &= 0xffff
	return v - 0x10000 if v >= 0x8000 else v


## Is the actor-object POINTER at match+`off` set? `+0x43c` / `+0x440` / `+0x444` hold actor
## objects, not scalars ("`+0x43c`/`+0x440` are actor-object pointers, `+4` is their position
## vec3" — docs/re/jug_render_spec.md), so the binary's `!= 0` on them is a null test.
##
## UNIFIED 2026-07-26 to the binary's model: the only null is int `0` (fn_0058eca0 L25 and the
## driver reset both write 0; every binary read is a `!= 0` / pointer compare) and every non-null
## write stores the player object (fn_005aeda0 L396 and fn_005b0bb0 L81 both write param_1).
## The port's former `-1` (set_engagement) and `1` (resolve_tree commit) sentinels were
## inventions and are gone. This helper still tolerates them (plus a raw int pointer from a
## mid-match struct import) defensively — `int(<Dictionary>)` was a hard crash that killed
## seeds 18 and 35 of the 50-seed sweep before it learned to.
static func _actor_set(m: Dictionary, off: int) -> bool:
	var v: Variant = m.get(off, 0)
	if v is Dictionary:
		return not (v as Dictionary).is_empty()
	return v is int and v != 0 and v != -1


## FUN_0058fb50: ball at (x,y,z) inside the match goal box (bounds m+0x1828..0x183c),
## past the goal line (m+0x1820 - 0x108000 < |x|) and within |y| < 0x1428f5. Reads
## the match struct only; pure geometry, LUT-free (compares already-resolved coords).
static func _goal_box(x: int, y: int, z: int, m: Dictionary) -> bool:
	var in_box := not (x < int(m.get(0x1828, 0)) or int(m.get(0x1834, 0)) < x \
			or y < int(m.get(0x182c, 0)) or int(m.get(0x1838, 0)) < y \
			or z < int(m.get(0x1830, 0)) or int(m.get(0x183c, 0)) < z)
	return in_box and (int(m.get(0x1820, 0)) - 0x108000 < absi(x)) and (absi(y) < 0x1428f5)


## The binary's sign bucket from `((-1 < v) - 1 & 0xfffffffe) + 1`: +1 when v >= 0, -1 when v < 0.
static func _sign_bucket(v: int) -> int:
	return 1 if v >= 0 else -1


## L397-424: decide outcome bit0 (bVar17). FUN_0058fb50 on the shooter's ball coords
## (P+4) AND sign_bucket(P+4) == sign_bucket(P+0x3a4); on miss it retries the target's
## coords (T+4) with the sign test INVERTED (!=). Either hit sets bit0.
static func _goal_box_hit(p: Dictionary, t: Dictionary, m: Dictionary) -> bool:
	if _goal_box(int(p.get(4, 0)), int(p.get(8, 0)), int(p.get(0xc, 0)), m) \
			and _sign_bucket(int(p.get(4, 0))) == _sign_bucket(int(p.get(0x3a4, 0))):
		return true
	return _goal_box(int(t.get(4, 0)), int(t.get(8, 0)), int(t.get(0xc, 0)), m) \
			and _sign_bucket(int(t.get(4, 0))) != _sign_bucket(int(t.get(0x3a4, 0)))


## Faithful port of FUN_005aeda0's resolution tree (lines 120-485). `p`,`t`,`m`,
## `stats` are offset->int dicts; `rng` is MatchEngine.Pm98Rng. Returns
## {draws, bits, target_state, goal, save, off_target, header, enqueue}.
## NOTE: covers play-states 3-8 (the shot/tackle resolution). The play-state-9
## chase branch (121-170, 0 RNG draws) and the finishing block (42-119, the
## Stage-1b gate) are integrated at S7; the movement block (491-607) is Stage 3.
static func resolve_tree(p: Dictionary, t: Dictionary, m: Dictionary, stats: Dictionary,
		rng: MatchEngine.Pm98Rng) -> Dictionary:
	var dc := [0]
	var draw := func() -> int:
		dc[0] += 1
		return rng.next()
	var res := {"draws": 0, "bits": 0, "target_state": int(t.get(0x40, 0)),
			"goal": false, "save": false, "off_target": false, "header": false,
			"enqueue": -1}

	# L38 entry guard.
	if int(m.get(0x448, 0)) != 0:
		res.draws = dc[0]
		return res

	# L41-118: the finishing pre-block runs BEFORE the play-state dispatch (its own
	# ps==3 gate keeps it inert elsewhere). Draws C79 (+C102 on success).
	_finishing_1b(p, t, draw)

	var ps := int(p.get(0x2c, 0))
	if ps < 3 or ps > 8:
		# L120-170: out-of-range play-states RETURN DIRECTLY (C L128-133 `return`s) --
		# they never reach LAB_005afabf, so no touch tail and no p54/58 epilogue here.
		# The ps==9 chase branch is geometry + RNG-neutral commentary only (deferred).
		res.draws = dc[0]
		return res

	# --- L172: main resolution tree --------------------------------------------
	# Guard: no active resolver this tick, player not already mid-shot, target
	# exists and is "live". `t` empty dict models target == null (P+0xac == 0).
	if not _actor_set(m, 0x43c) and int(p.get(0x62, 0)) == 0 \
			and not t.is_empty() and int(t.get(0x2bc, 0)) != 0:
		var t40 := int(t.get(0x40, 0))
		# L174/181/188 type guards -> fall to LAB_005afabf (no resolution).
		if t40 == 8 or t40 == 9 or t40 == 6 or t40 == 7 \
				or t40 == 0x17 or t40 == 0x15 or t40 == 0x14:
			return _afabf(p, m, t, dc, res, draw, 0xC000)

		# L196: reach-radius local_34 (consumes 1 draw; geometry result unused here).
		var reach := ((100 - int(t.get(0x388, 0))) * 0x13333) / 100
		var _local_34 := _prob_scale(draw.call(), reach) + 0x4000

		# L207 projection: the reach point 0x4ccc ahead of the resolver's facing
		# (FUN_005ee0f0 polar + FUN_005a1700 vec3 add with this = P.pos). L212-222 is
		# the REAL first gate -- target within local_34 of that point, per axis; the
		# L223-235 position fallback only runs when it misses. Formerly the first gate
		# was deferred and only the fallback ran: s59 caught silicon resolving t0.i6's
		# chase at clk 1449 (4 draws -> the clk-1450 mid-air deflection) where the
		# fallback-only port bailed after 1 draw.
		var pv: Array = Pm98Trig.polar_vec(0x4ccc, _s16(int(p.get(0x34, 0))))
		var gate := true
		for ax in 3:
			var ahead := Pm98Trig._i32(int(p.get(4 + 4 * ax, 0)) + int(pv[ax]))
			if absi(Pm98Trig._i32(int(t.get(4 + 4 * ax, 0)) - ahead)) >= _local_34:
				gate = false
				break
		if not gate and not _position_gate(p, t, _local_34):
			return _afabf(p, m, t, dc, res, draw, _local_34)

		var ang := absi(_s16(int(p.get(0x34, 0)) - int(t.get(0x34, 0))))   # iVar12
		# L243: shot-power scale iVar13 (consumes 1 draw).
		var power := (int(p.get(0x384, 0)) * 0x71c) / 100 + 0x71c
		power = _prob_scale(draw.call(), power)
		p[0x62] = 1

		var skill := int(p.get(0x384, 0))
		var is_fwd := 1 if int(p.get(0x40, 0)) == 9 else 0
		var engaged := int(p.get(0x60, 0)) != 0
		var bvar6 := false
		var bvar7 := false
		var bvar8 := false
		var bvar5 := false

		# L257: header block. The C gate is `8 < *(*(target+0x184) + 4)` -- the TARGET's
		# team-header roster count (gs+4, = 11 in a real match), NOT a match scalar.
		# The old m.get(4) mapping only ever passed in fixtures that poked m[4] (s59:
		# silicon ran the header trio at clk 1460 where the port skipped it).
		if 8 < int(Pm98Movement._ref(t, 0x184).get(0x4, 0)) \
				and _permil(draw.call()) < ((300 if ang < power else 0) + 400):
			# L261: FUN_005a5430 with this=TARGET (disasm 0x5af328) -- the remap LUT
			# clears t+0x2c/+0x30 since LUT[6]=LUT[7]=10; the s59 fork at clk 1495 was
			# the old bare t[0x40]= keeping a stale anim frame alive.
			Pm98Movement.set_position_code(t, (1 if ang < 0x4000 else 0) + 6)
			# L263-269: arm the target's motion-lerp to a point 0x20000 ahead of its
			# facing (FUN_005ee0f0 + FUN_005a7220 this=target @0x5af374, steps 0x30),
			# then release the ball's carrier if it IS the target (FUN_0058ed50
			# this=ball @0x5af39e).
			var pvh: Array = Pm98Trig.polar_vec(0x20000, _s16(int(t.get(0x34, 0))))
			for ax in 3:
				t[0x94 + 4 * ax] = Pm98Trig._i32(int(t.get(4 + 4 * ax, 0)) + int(pvh[ax]))
			t[0x84] = 0x30
			t[0x80] = 1
			t[0x66] = int(t.get(0x34, 0)) & 0xffff
			var ballh: Dictionary = Pm98Movement._ref(p, 0x190)
			if not ballh.is_empty() and is_same(ballh.get(0x40, null), t):
				ballh[0x40] = 0
			var iv14 := int(t.get(0x40, 0))
			# L272: keeper-beaten flag (consumes 1 draw). On success match+0x440 = the
			# TARGET pointer (C L275 comma-expr -- not a flag) and, live
			# (DAT_006d31c4 == 0), the target's team stats +0xa4 = 1.
			if _permil(draw.call()) < ((-50 if iv14 != 7 else 0) + 100):
				m[0x440] = t
				Pm98Movement._ref(t, 0x3b8)[0xa4] = 1
			bvar6 = true
			res.header = true
			m[0x461] = int(m.get(0x461, 0)) | 8                  # L281
			var _sel: int = (int(draw.call()) * 5) >> 15        # L282 direction switch (commentary)
			# commentary (M+0x180a/0x2ec/0x180c) is RNG-neutral; skipped.

		# L312: does the shot resolve at all? (consumes 1 draw, 90% gate).
		if _permil(draw.call()) < 900:
			if ang < power:
				# L314 branch: shot roughly on the player's facing line.
				var thr := (-100 if engaged else 0) + 100 + (skill + is_fwd * 0x32) * 2
				bvar7 = bvar6 and _permil(draw.call()) < thr            # L317
				if bvar7 or (not bvar6) or thr <= _permil(draw.call()): # L326 (|| short-circuits)
					bvar8 = false
				else:
					bvar8 = true
				if (not bvar7) and (not bvar8):
					var iv13c := (skill + is_fwd * 0x14) * 5 + (-200 if engaged else 0) + 200 \
							if bvar6 else skill << 1
					if iv13c <= _permil(draw.call()):                   # L345
						bvar5 = false
						return _resolve_outcome(p, t, m, stats, dc, res, bvar5, bvar6, bvar7, bvar8, draw, _local_34)
				bvar5 = true
			elif not engaged:
				# L353 branch.
				var iv13d := (skill + is_fwd * 100) * 2 if bvar6 else skill
				bvar5 = _permil(draw.call()) < iv13d
				if bvar5 and bvar6 and _permil(draw.call()) < (skill * 3 + is_fwd * 100):  # L364
					bvar8 = true
				else:
					bvar8 = false
			else:
				# L374 branch.
				var iv13e := skill + is_fwd * 100 if bvar6 else skill / 2
				bvar5 = _permil(draw.call()) < iv13e
				if (not bvar5) or (not bvar6) or (skill / 2 <= _permil(draw.call())):  # L383
					bvar8 = false
				else:
					bvar8 = true

		return _resolve_outcome(p, t, m, stats, dc, res, bvar5, bvar6, bvar7, bvar8, draw, _local_34)

	return _afabf(p, m, t, dc, res, draw, 0xC000)


## L213-235 position fallback gate (LUT-free): true if |target - player| < reach on
## all three axes (+4/+8/+0xc). The geometry firstgate (L212) can only ADD pass
## cases; for the constructed fixtures this fallback governs (positions at origin).
static func _position_gate(p: Dictionary, t: Dictionary, reach: int) -> bool:
	for off in [4, 8, 0xc]:
		if abs(int(t.get(off, 0)) - int(p.get(off, 0))) >= reach:
			return false
	return true


## LAB_005af7d4 onward (lines 390-485): commit the resolved outcome. With bvar5 the
## goal/save block writes the match+0x461 bits + stat counters; otherwise an engaged
## player may enqueue a deflection/corner (0x13/0x14). Then LAB_005afabf.
static func _resolve_outcome(p: Dictionary, t: Dictionary, m: Dictionary, stats: Dictionary,
		dc: Array, res: Dictionary, bvar5: bool, bvar6: bool, bvar7: bool, bvar8: bool,
		draw: Callable, local_34: int = 0xC000) -> Dictionary:
	if bvar5:
		# L392: the C reads `*(*(param_1+0x184) + 4) < 9` -- the RESOLVER's own
		# team-header roster count (gs+4), not a match scalar (s59 correction, same
		# mis-mapping as the L257 header gate). The comma-expr also forces bvar7
		# false on that branch (redundant but ported faithfully).
		if int(Pm98Movement._ref(p, 0x184).get(0x4, 0)) < 9:
			bvar7 = false
			if bvar8 and int(p.get(0x2da, 0)) != 0:
				bvar8 = false
		m[0x43c] = p    # fn_005aeda0 L396: *(match+0x43c) = param_1 -- the SHOOTER pointer, not a flag
		# L397-424: bit0 = "ball ends in the goal box" (FUN_0058fb50 + sign-bucket gate).
		# Oracle-validated by hi_face/hi_angle in test_resolver_tree.gd (origin coords ->
		# bvar17=1). Real ball coordinates arrive with the Stage-3 movement block + LUT.
		var bvar17 := 1 if _goal_box_hit(p, t, m) else 0
		var bits := int(m.get(0x461, 0))
		bits = (bits & ~1) | bvar17
		bits = (bits & ~4) | (int(bvar7) << 2)
		bits = (bits & ~2) | (int(bvar8) << 1)
		m[0x461] = bits
		# L431 stat counters (DAT_006d31c4 == 0 in-sim).
		if bvar8:
			stats[0x98] = int(stats.get(0x98, 0)) + 1
		if bvar7:
			stats[0x9c] = int(stats.get(0x9c, 0)) + 1
		if int(p.get(0x60, 0)) != 0:
			stats[0x8c] = int(stats.get(0x8c, 0)) - 1
			stats[0x90] = int(stats.get(0x90, 0)) + 1
		if bvar7 or int(stats.get(0x98, 0)) > 1:
			stats[0xa0] = int(stats.get(0xa0, 0)) + 1
			p[0x2d9] = 1
		res.goal = bvar8
		res.save = bvar7
		return _afabf(p, m, t, dc, res, draw, local_34)

	# L466: engaged player, shot not resolved -> deflection / corner.
	if int(p.get(0x60, 0)) != 0:
		var code := -1
		if bvar6:
			if (100 - int(p.get(0x384, 0))) * 10 <= _permil(draw.call()):   # L469
				return _afabf(p, m, t, dc, res, draw, local_34)
			code = 0x14
		else:
			code = 0x14 if 499 < _permil(draw.call()) else 0x13            # L478
		res.enqueue = code                                                  # FUN_00594470(code,P,0)
	return _afabf(p, m, t, dc, res, draw, local_34)


## LAB_005afabf -> LAB_005afe9e: EVERY route (guard bails, out-of-range play-state,
## post-commit, post-deflection-enqueue) lands at LAB_005afabf, where p+0x60
## ("already touched this play") skips straight to the epilogue and everyone else
## runs the ball-touch tail (L491-607). `local_34` is the C's live reach box:
## 0xc000 from the prologue on pre-draw routes, the drawn reach + 0x4000 after
## L196 (the binary never resets it). The epilogue clears P+0x54/+0x58 and
## finalises the result (match+0x461 bits + target play-state for assertions).
static func _afabf(p: Dictionary, m: Dictionary, t: Dictionary, dc: Array, res: Dictionary,
		draw: Callable, local_34: int) -> Dictionary:
	if int(p.get(0x60, 0)) == 0:
		_touch_tail(p, m, t, draw, local_34)
	p[0x54] = 0
	p[0x58] = 0
	res.bits = int(m.get(0x461, 0))
	res.target_state = int(t.get(0x40, res.get("target_state", 0)))
	res.off_target = (res.bits & 4) != 0
	res.draws = dc[0]
	return res


## L41-118: the Stage-1b finishing pre-block (the tackle-intercept windup). Fires only
## for P in play-state 3 frame 0 with a live target in action 0..3 moving fast
## (t+0x68 > 0x1332). Both players project 8 ticks ahead (pos + vel*8 -- FUN_005b1230
## vec3*k + FUN_005a1700 vec3 add, this-regs disasm-verified at 0x5aee38-0x5aee5f);
## within 0x10000 per axis the C79 roll (permil < adj(t+0x398)*9, adj = t/3 truncating
## below 0x37 else t-0x19) catches the target: state 0x17 (this=TARGET at 0x5aef0c),
## motion-lerp to its 32-tick projection (FUN_005a7220, this=target; DAT_00665014=8,
## k=8*4), the ball mirroring the lerp when the target carries it, and the C102
## commentary-pick draw (its save/restore triple is RNG-neutral; leaf headless-gated
## on m+0x180b, elided).
static func _finishing_1b(p: Dictionary, t: Dictionary, draw: Callable) -> void:
	if int(p.get(0x2c, 0)) != 3 or int(p.get(0x30, 0)) != 0 or t.is_empty():
		return
	var t40 := int(t.get(0x40, 0))
	if t40 < 0 or t40 > 3 or int(t.get(0x68, 0)) <= 0x1332:
		return
	for ax in 3:
		var pj_p := Pm98Trig._i32(int(p.get(4 + 4 * ax, 0)) + Pm98Trig._i32(int(p.get(0x20 + 4 * ax, 0)) * 8))
		var pj_t := Pm98Trig._i32(int(t.get(4 + 4 * ax, 0)) + Pm98Trig._i32(int(t.get(0x20 + 4 * ax, 0)) * 8))
		if absi(Pm98Trig._i32(pj_t - pj_p)) >= 0x10000:
			return
	var sk := int(t.get(0x398, 0))
	sk = Pm98Trig._tdiv(sk, 3) if sk < 0x37 else sk - 0x19
	if _permil(draw.call()) >= sk * 9:
		return
	Pm98Movement.set_position_code(t, 0x17)
	var k := 8 * 4                                  # DAT_00665014 (= 8, .data 0x665014) * 4
	for ax in 3:
		t[0x94 + 4 * ax] = Pm98Trig._i32(int(t.get(4 + 4 * ax, 0)) + Pm98Trig._i32(int(t.get(0x20 + 4 * ax, 0)) * k))
	t[0x84] = k
	t[0x80] = 1
	t[0x66] = int(t.get(0x34, 0)) & 0xffff
	var ball: Dictionary = Pm98Movement._ref(p, 0x190)
	if not ball.is_empty() and is_same(ball.get(0x40, null), t):
		ball[0x68] = 1
		ball[0x6c] = k
		for ax in 3:
			ball[0x9C + 4 * ax] = Pm98Trig._i32(int(ball.get(4 + 4 * ax, 0)) + Pm98Trig._i32(int(t.get(0x20 + 4 * ax, 0)) * k))
	var _pick := _permil(draw.call()) < 600          # C102: commentary choice draw only


## L491-607: the resolver's ball-touch tail. The player probes the ball against a
## per-axis local_34 box at three points -- polar(0x9998) ahead of facing,
## polar(0x4ccc) ahead, then the player itself. A hit is a TOUCH: the C550 power
## roll; the possession stat swap when the toucher is not the recorded actor at
## match+0x43c (the unified pointer model); p+0x60 = 1; engage the ball to the
## toucher (FUN_0058eca0, this=BALL, disasm 0x5afd43/0x5afda5) and -- on the strong
## arm (power + 0x20000 >= 0x10ccd, always for sane attributes; the weak arm's
## commentary triple is RNG-neutral and headless-gated) -- release the carrier
## (FUN_0058ed70: ball+0x40 = 0); the 0xc touch cooldown on ball+0x70 (the once-only
## gate the s59 capture proved at clk 1450-1452); then the redirect: ball.vel =
## trunc(ball.vel/16) + rot(scale_vec3(P.vel, power+0x20000), jitter) with the C585
## jitter draw (jit = prob_scale(jbase*2+1) - jbase, jbase = (100-p390)*0x2000/100).
static func _touch_tail(p: Dictionary, m: Dictionary, t: Dictionary,
		draw: Callable, local_34: int) -> void:
	var ball: Dictionary = Pm98Movement._ref(p, 0x190)
	if ball.is_empty() or int(ball.get(0x70, 0)) != 0:
		return
	var carr: Variant = ball.get(0x40, null)
	if carr is Dictionary:
		if is_same(carr, p) or int((carr as Dictionary).get(0x2bc, 0)) == 0:
			return
	if not t.is_empty() and int(t.get(0x40, 0)) == 0x17:
		return
	var hit := false
	for reach in [0x9998, 0x4CCC, -1]:
		var probe := [int(p.get(4, 0)), int(p.get(8, 0)), int(p.get(0xc, 0))]
		if reach > 0:
			var pv: Array = Pm98Trig.polar_vec(reach, _s16(int(p.get(0x34, 0))))
			for ax in 3:
				probe[ax] = Pm98Trig._i32(int(probe[ax]) + int(pv[ax]))
		hit = true
		for ax in 3:
			if absi(Pm98Trig._i32(int(ball.get(4 + 4 * ax, 0)) - int(probe[ax]))) >= local_34:
				hit = false
				break
		if hit:
			break
	if not hit:
		return
	# C550: the touch-power draw.
	var pow_base := Pm98Trig._tdiv(int(p.get(0x384, 0)) << 0x11, 100) \
			+ Pm98Trig._tdiv((100 - int(p.get(0x390, 0))) * 0x10000, 100)
	var powr := _prob_scale(draw.call(), pow_base)
	# L558 stat swap (DAT_006d31c4 == 0 live).
	var stats: Dictionary = Pm98Movement._ref(p, 0x3b8)
	if not is_same(m.get(0x43c, 0), p):
		stats[0x90] = int(stats.get(0x90, 0)) - 1
		stats[0x8c] = int(stats.get(0x8c, 0)) + 1
	p[0x60] = 1
	Pm98Movement._ball_engage_player(ball, p)
	if powr + 0x20000 >= 0x10CCD:
		ball[0x40] = 0                              # FUN_0058ed70: release the carrier
	if int(ball.get(0x70, 0)) < 0xd:
		ball[0x70] = 0xc                            # the touch cooldown
	# C585: the jitter draw + the velocity redirect.
	var jbase := Pm98Trig._tdiv((100 - int(p.get(0x390, 0))) * 0x2000, 100)
	var ang := Pm98Trig._i32(_prob_scale(draw.call(), jbase * 2 + 1) - jbase)
	for off in [0x20, 0x24, 0x28]:
		var v := int(ball.get(off, 0))
		ball[off] = (v + ((v >> 31) & 0xf)) >> 4
	var buf: Array = Pm98Trig.scale_vec3(int(p.get(0x20, 0)), int(p.get(0x24, 0)),
			int(p.get(0x28, 0)), Pm98Trig._i32(powr + 0x20000))
	Pm98Trig.rot_vec3(buf, ang, 0)
	for ax in 3:
		var voff := 0x20 + 4 * ax
		ball[voff] = Pm98Trig._i32(int(ball.get(voff, 0)) + int(buf[ax]))
