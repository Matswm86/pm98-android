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

	var ps := int(p.get(0x2c, 0))
	if ps < 3 or ps > 8:
		# L121-170: play-state-9 chase / out-of-range -- geometry only, 0 RNG draws.
		res.draws = dc[0]
		return res

	# --- L172: main resolution tree --------------------------------------------
	# Guard: no active resolver this tick, player not already mid-shot, target
	# exists and is "live". `t` empty dict models target == null (P+0xac == 0).
	if int(m.get(0x43c, 0)) == 0 and int(p.get(0x62, 0)) == 0 \
			and not t.is_empty() and int(t.get(0x2bc, 0)) != 0:
		var t40 := int(t.get(0x40, 0))
		# L174/181/188 type guards -> fall to LAB_005afabf (no resolution).
		if t40 == 8 or t40 == 9 or t40 == 6 or t40 == 7 \
				or t40 == 0x17 or t40 == 0x15 or t40 == 0x14:
			return _afabf(p, m, t, dc, res)

		# L196: reach-radius local_34 (consumes 1 draw; geometry result unused here).
		var reach := ((100 - int(t.get(0x388, 0))) * 0x13333) / 100
		var _local_34 := _prob_scale(draw.call(), reach) + 0x4000

		# L207 projection + L212-235 distance gate. Geometry firstgate (L212) is
		# LUT-dependent -> deferred to S3; the LUT-free position fallback (L223-235)
		# governs the validated fixtures. If it fails -> LAB_005afabf.
		if not _position_gate(p, t, _local_34):
			return _afabf(p, m, t, dc, res)

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

		# L257: header block (only when 8 < M+4). Consumes draws as it goes.
		if 8 < int(m.get(4, 0)) \
				and _permil(draw.call()) < ((300 if ang < power else 0) + 400):
			t[0x40] = (1 if ang < 0x4000 else 0) + 6            # L261 set target state 6/7
			var iv14 := int(t[0x40])
			# L272: keeper-beaten flag (consumes 1 draw).
			if _permil(draw.call()) < ((-50 if iv14 != 7 else 0) + 100):
				m[0x440] = 1                                     # (resolver-owner slot)
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
						return _resolve_outcome(p, t, m, stats, dc, res, bvar5, bvar6, bvar7, bvar8, draw)
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

		return _resolve_outcome(p, t, m, stats, dc, res, bvar5, bvar6, bvar7, bvar8, draw)

	return _afabf(p, m, t, dc, res)


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
		draw: Callable) -> Dictionary:
	if bvar5:
		# L392: suppress the save flag in some low-rated, already-flagged states.
		if int(m.get(4, 0)) < 9 and bvar8 and int(p.get(0x2da, 0)) != 0:
			bvar8 = false
		m[0x43c] = 1
		# L397/413 FUN_0058fb50 = "ball ends in the goal box?" -> bit0. Pure geometry
		# on P+4; deferred to S3 (bvar5-true outcomes are not yet in the oracle matrix).
		var bvar17 := 0
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
		return _afabf(p, m, t, dc, res)

	# L466: engaged player, shot not resolved -> deflection / corner.
	if int(p.get(0x60, 0)) != 0:
		var code := -1
		if bvar6:
			if (100 - int(p.get(0x384, 0))) * 10 <= _permil(draw.call()):   # L469
				return _afabf(p, m, t, dc, res)
			code = 0x14
		else:
			code = 0x14 if 499 < _permil(draw.call()) else 0x13            # L478
		res.enqueue = code                                                  # FUN_00594470(code,P,0)
	return _afabf(p, m, t, dc, res)


## LAB_005afabf / LAB_005afe9e tail: clears P+0x54/+0x58 and finalises the result
## (reads back the mutated match+0x461 bits + target play-state for assertions).
static func _afabf(p: Dictionary, m: Dictionary, t: Dictionary, dc: Array, res: Dictionary) -> Dictionary:
	p[0x54] = 0
	p[0x58] = 0
	res.bits = int(m.get(0x461, 0))
	res.target_state = int(t.get(0x40, res.get("target_state", 0)))
	res.off_target = (res.bits & 4) != 0
	res.draws = dc[0]
	return res
