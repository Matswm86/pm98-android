class_name Pm98Dispatch
extends RefCounted
## EXACT port of MANAGER.EXE's match-event DISPATCHER FUN_005966d0
## (docs/re/EXACT_PORT_PLAN.md, Stage 3 task 2). __thiscall(this=match, outcome).
## The resolver (FUN_005aeda0) classifies a play into an outcome category 1-7; this
## function turns that category into the concrete commentary events it appends to the
## match event queue via Pm98Events.enqueue (FUN_00594470, already oracle-locked).
##
## What is and is NOT modelled (the whole correctness argument):
##   * COMMENTARY DISPLAY is stubbed. Every `FUN_004e*` call in the binary is guarded
##     by `if (match+0x180b != 0)` -- the on-screen-commentary flag, 0 in the headless
##     scoreline sim -- so those text formatters never run and are not ported. The
##     `FUN_005ec240`/`FUN_005ec230` pairs that bracket them are an RNG-state
##     save/restore (return DAT_006d3184 / write it back): with the commentary skipped
##     nothing is drawn between them, so they net-zero the seed and are dropped.
##   * RNG DRAWS that the binary makes OUTSIDE those brackets ARE load-bearing for seed
##     parity and ARE replicated: a conditional draw in case 2 (geometry-gated) and one
##     in case 6 (goal). Each consumes exactly one MSVC-LCG draw (MatchEngine.Pm98Rng).
##   * The event ENQUEUES (code + player + flag) are the real output and are all ported.
##   * Display-only fields (match+0x19d4 etc.) are written faithfully so the oracle can
##     prove the port perturbs nothing; they do not gate any event.
##
## match is an offset->Variant Dictionary (same representation as Pm98Events /
## Pm98Predicates); nested pointers (match+0x468 -> team, match+0x440/0x444/0x43c ->
## player, the per-team corner-taker slot at 0x46c+team*800) are nested Dictionaries.
## Oracle-validated bit-for-bit: tools/re/run_dispatch_oracle.sh ->
## specs/dispatch_oracle.txt, locked by test_dispatch.gd. The REAL FUN_005966d0 is
## driven through the PCode emulator (FUN_005bbf10 realloc stubbed, event buffer
## pre-allocated, cos LUT injected for the case-2 projection); the aggregate helper
## FUN_00450e60 is pinned by its own direct fixtures.

const PHASE_LOCK := 8        # FUN_005942e0(8): match+0x448/+0x44c phase-lock value
const COOLDOWN := 0x168      # match+0x454 := 0x168 on every dispatch
const COOLDOWN_PHASE := 0x2d0  # match+0x454 := 0x2d0 in case 1 (phase boundary)
const COUNTER_DEFAULT := 0x157c  # match+0x1998 default when 0


static func _g(d: Dictionary, off: int) -> int:
	return int(d.get(off, 0))


static func _ref(d: Dictionary, off: int) -> Dictionary:
	var v: Variant = d.get(off, null)
	return v if v is Dictionary else {}


static func _s16(v: int) -> int:
	v &= 0xffff
	return v - 0x10000 if v >= 0x8000 else v


## FUN_005942e0(match, value): phase-lock. Once match+0x448 reaches 8 it sticks; until
## then both +0x448 and (for value!=1) +0x44c take `value`. Called with 8 at the end.
static func _phase_set(m: Dictionary, value: int) -> void:
	if _g(m, 0x448) != PHASE_LOCK:
		m[0x448] = value
		if value != 1:
			m[0x44c] = value


## FUN_005966d0. `rng` = the live MatchEngine.Pm98Rng (the match seed). `subs` models
## the display global DAT_00674e7c (0 in-sim); it only selects the case-6 display value
## match+0x19d4 (7 vs 6), never an event. Returns the final freeze value written to
## match+0x1a38 (the resolved outcome, which case 1 may rewrite to 10).
static func dispatch(m: Dictionary, outcome: int, rng: MatchEngine.Pm98Rng, subs: int = 0) -> int:
	if _g(m, 0x454) != 0:        # a dispatch is already cooling down -> ignore
		return _g(m, 0x1a38)
	var counter := _g(m, 0x1998)
	m[0x454] = COOLDOWN
	if counter == 0:
		counter = COUNTER_DEFAULT
	m[0x1998] = counter
	m[0x19d4] = -1               # 0xffffffff
	m[0x19d8] = 0
	m[0x434] = 0
	m[0x1809] = 0
	if not _ref(m, 0x440).is_empty():
		Pm98Events.enqueue(m, 6, _ref(m, 0x440), 2)
		# FUN_005ec240 / (FUN_004e9810 behind 0x180b) / FUN_005ec230 -> net-zero, skipped.

	match outcome:
		1: outcome = _case_phase(m)
		2: _case_buildup(m, rng)
		3: _case_restart(m)
		4: _case_corner(m)
		5: _case_foul(m)
		6: _case_goal(m, rng, subs)
		7: _case_penalty(m)

	m[0x1a38] = outcome
	_phase_set(m, PHASE_LOCK)
	return outcome


## case 1 -- phase boundary (kick-off / half-time / full-time / extra-time), keyed by
## the phase sub-state match+0x19a0. May rewrite the outcome to 10 (the "go to replay /
## penalties" path), which becomes the freeze value. Returns the (possibly 10) outcome.
static func _case_phase(m: Dictionary) -> int:
	m[0x19d4] = 4
	if _g(m, 0x19a0) != 4:
		m[0x1809] = 1
	m[0x454] = COOLDOWN_PHASE
	var to_ten := false
	var team := _ref(m, 0x468)
	match _g(m, 0x19a0):
		0:
			Pm98Events.enqueue(m, 0x1c, {}, 2)
		1:
			if _agg_decision(team) != 0 or (_g(team, 0x44) == 0 and _g(team, 0x48) == 0):
				to_ten = true
			else:
				Pm98Events.enqueue(m, 0x1d, {}, 2)
				if _g(team, 0x44) == 0:
					Pm98Events.enqueue(m, 0x1f, {}, 2)
		2:
			Pm98Events.enqueue(m, 0x1e, {}, 2)
		3:
			if _agg_decision(team) != 0 or _g(team, 0x48) == 0:
				to_ten = true
			else:
				Pm98Events.enqueue(m, 0x1f, {}, 2)
		4:
			to_ten = true
	if to_ten:
		_team_reset(m)            # FUN_005946d0 -> FUN_005b7080 x2 (no-op when team+4==0)
		Pm98Events.enqueue(m, 0x20, {}, 2)
		return 10
	return 1


## FUN_005946d0: two passes of FUN_005b7080(team), each looping team+4 times over the
## undecompiled per-player reset FUN_005a32c0. FUN_005a32c0 is NOT in the 9 enqueue
## generators (it emits no event) but its RNG behaviour is unverified, so this is a
## VERIFIED no-op only when team+4 == 0 (the loop never runs) -- which is how the
## case-1 oracle fixtures pin it. Modelled as a no-op; revisit when the movement
## cluster is ported (it sits in the 0x5a3xxx AI block, Stage 3 task 2 bulk).
static func _team_reset(_m: Dictionary) -> void:
	pass


## case 2 -- build-up / loose ball. One conditional, geometry-gated RNG draw then an
## empty (type 0, no-commentary) event. The gate iVar4 is the ball-velocity projection
## onto its own heading = its speed: FUN_005edfb0(vx, cos t, vy, sin t) with
## t = atan(vx,vy), i.e. Pm98Trig.muladd16. `(double)iVar4 <= 0.2508` is exactly
## `iVar4 <= 0` for the integer projection, so the draw fires iff the ball is moving
## (iVar4 > 0) AND match+0x165c is set. The draw only selects (skipped) commentary.
static func _case_buildup(m: Dictionary, rng: MatchEngine.Pm98Rng) -> void:
	m[0x19d4] = 5
	if _ref(m, 0x440).is_empty():
		# match+0x1630/+0x1634 = ball vel x/y via the +0x1610 embedding (Pm98Movement._bm).
		var vx := Pm98Movement._bm(m, 0x1630)
		var vy := Pm98Movement._bm(m, 0x1634)
		var theta := Pm98Trig.atan_angle(vx, vy)
		var proj := Pm98Trig.muladd16(vx, Pm98Trig.cos_a(theta), vy, Pm98Trig.sin_a(theta))
		if proj > 0 and _g(m, 0x165c) != 0:
			rng.next()            # FUN_005ec250 -- (roll*500)>>15==0 only picks commentary
		Pm98Events.enqueue(m, 0, {}, 0)


## case 3 -- restart / dead ball. Empty event; an extra-time restart also sets the
## display latch match+0x1809.
static func _case_restart(m: Dictionary) -> void:
	m[0x19d4] = 5
	if _g(m, 0x19a0) == 4:
		m[0x1809] = 1
	Pm98Events.enqueue(m, 0, {}, 0)


## case 4 -- corner. Event 0xc for the per-team corner taker, the player slot at
## match + 0x46c + 800*defending-team-index (match+0x45c).
static func _case_corner(m: Dictionary) -> void:
	m[0x19d4] = 4
	var taker := _ref(m, 0x46c + _g(m, 0x45c) * 800)
	Pm98Events.enqueue(m, 0xc, taker, 0)


## case 5 -- foul / card / offside. match+0x460 set => offside (event 0xb). Otherwise
## the outcome bits match+0x461 pick: normal foul (1), yellow (3), second-yellow send
## off (4), or straight red (5). The booked player is match+0x43c, copied into +0x434.
static func _case_foul(m: Dictionary) -> void:
	m[0x434] = m.get(0x43c, 0)
	m[0x19d4] = 4
	var player := _ref(m, 0x434)
	if _g(m, 0x460) == 0:
		var bits := _g(m, 0x461)
		if (bits & 4) == 0 or (bits & 2) == 0:
			if (bits & 4) == 0:
				if (bits & 2) == 0:
					Pm98Events.enqueue(m, 1, player, 2)       # foul
				else:
					m[0x19d4] = 1
					Pm98Events.enqueue(m, 3, player, 2)       # yellow card
			else:
				m[0x19d4] = 2
				Pm98Events.enqueue(m, 4, player, 2)           # 2nd yellow -> off
		else:
			m[0x19d4] = 3
			Pm98Events.enqueue(m, 5, player, 2)               # straight red
	else:
		Pm98Events.enqueue(m, 0xb, player, 0)                 # offside


## case 6 -- GOAL. Event 7 (goal) unless the scorer's team field (player+0x2b8) equals
## the defending-team index match+0x45c, which makes it 8 (own goal): code = 8 - (a!=b).
## One conditional RNG draw (commentary selection) fires for a normal-time genuine goal
## with match+0x462 bit2 clear and match+0x461 bit5 set.
static func _case_goal(m: Dictionary, rng: MatchEngine.Pm98Rng, subs: int) -> void:
	var scorer := _ref(m, 0x444)
	var defend := _g(m, 0x45c)
	var code := 8 - (1 if _g(scorer, 0x2b8) != defend else 0)
	Pm98Events.enqueue(m, code, scorer, 2)
	# match+0x19d4 display value: 7 unless the cup-second-leg flag (team+0x14) is set and
	# the sub global (DAT_00674e7c) isn't 8. Display only; no event depends on it.
	m[0x19d4] = 7 if (_g(_ref(m, 0x468), 0x14) == 0 or subs == 8) else 6
	if _g(m, 0x19a0) != 4 and _g(scorer, 0x2b8) != defend:
		if (_g(m, 0x462) & 4) == 0 and (_g(m, 0x461) & 0x20) != 0:
			rng.next()            # FUN_005ec250 -- 499 < (roll*1000)>>15 picks commentary
	m[0x1809] = 1
	m[0x434] = m.get(0x444, 0)


## case 7 -- penalty conceded. Event 9 for the conceding player (match+0x43c, copied to
## +0x434), then the same yellow/second-yellow/red card selection as case 5 keyed on
## match+0x461 -- but a both-bits-clear value here books no card (only the penalty).
static func _case_penalty(m: Dictionary) -> void:
	m[0x434] = m.get(0x43c, 0)
	Pm98Events.enqueue(m, 9, _ref(m, 0x43c), 2)
	var bits := _g(m, 0x461)
	m[0x19d4] = 4
	var player := _ref(m, 0x434)
	if (bits & 4) == 0 or (bits & 2) == 0:
		if (bits & 4) != 0:
			m[0x19d4] = 2
			Pm98Events.enqueue(m, 4, player, 2)               # 2nd yellow -> off
		elif (bits & 2) != 0:
			m[0x19d4] = 1
			Pm98Events.enqueue(m, 3, player, 2)               # yellow
		# both clear: no card
	else:
		m[0x19d4] = 3
		Pm98Events.enqueue(m, 5, player, 2)                   # straight red


# ============================================================================
# FUN_00450e60(match+0x468) -- the two-leg aggregate / away-goals / extra-time
# decision read in case 1 sub-cases 1 and 3. Pure reads over the match goal log
# (team+0xf98 ptr, team+0xf9c count, 16-byte records [type,_,sideflag,teamid]) plus
# the leg/ET control flags at team+0x20..+0x48 and the two team ids +0x7e8/+0xf88.
# Returns 0 (undecided / draw), 1 (home through) or 2 (away through). Faithful port;
# GDScript ints are 64-bit so the binary's SBORROW signed compares are plain `<`.
# The goal log is modelled as team[0xf98] = Array of 4-int records, team[0xf9c] = len.
# ============================================================================

static func _log(t: Dictionary) -> Array:
	var v: Variant = t.get(0xf98, null)
	return v if v is Array else []


## FUN_00450d60 / FUN_00450db0: goals for one side. `home` picks which id the
## sideflag==0 records belong to (home id = team+0x7e8, away id = team+0xf88).
static func _count_goals(t: Dictionary, home: bool) -> int:
	var id_a := _s16(_g(t, 0x7e8 if home else 0xf88))   # sideflag==0 owner
	var id_b := _s16(_g(t, 0xf88 if home else 0x7e8))   # sideflag!=0 owner
	var cnt := 0
	for ev: Array in _log(t):
		if int(ev[0]) == 4:
			continue
		if int(ev[2]) == 0:
			if _s16(int(ev[3])) == id_a:
				cnt += 1
		elif _s16(int(ev[3])) == id_b:
			cnt += 1
	return cnt


## FUN_00450e00 / FUN_00450e30: type-4 (away-goal-rule) records for one team id.
static func _count_type4(t: Dictionary, home: bool) -> int:
	var wanted := _s16(_g(t, 0x7e8 if home else 0xf88))
	var cnt := 0
	for ev: Array in _log(t):
		if int(ev[0]) == 4 and _s16(int(ev[3])) == wanted:
			cnt += 1
	return cnt


## Tie-break used at two leaves (LAB_0045106a): home<=away -> (away<=home)?0:2, else 1.
static func _leaf_cmp(t: Dictionary) -> int:
	var a := _count_goals(t, true)
	var b := _count_goals(t, false)
	if a <= b:
		return 0 if b <= a else 2
	return 1


## The away-goals leaf (the +0x24-gated tail shared by several branches).
static func _away_goal_leaf(t: Dictionary) -> int:
	if _g(t, 0x24) != 0:
		var c := _count_type4(t, true)
		var d := _count_type4(t, false)
		if d < c:
			return 1
		if c < d:
			return 2
	return 0


static func _agg_decision(t: Dictionary) -> int:
	var v2 := _g(t, 0x2c)
	var v4 := _g(t, 0x30)
	var v1 := _g(t, 0x34)
	if v1 != 0xff and _g(t, 0x38) != 0xff and _g(t, 0x44) != 0 and _g(t, 0x20) != 0:
		v4 = _g(t, 0x38)
		v2 = v1
	if _g(t, 0x48) == 0:
		return _leaf_cmp(t)
	if v2 == 0xff and v4 == 0xff:
		var a := _count_goals(t, true)
		var b := _count_goals(t, false)
		if a != b:
			return 2 if a <= b else 1
		if _g(t, 0x24) == 0:
			return 0
		var c := _count_type4(t, true)
		var d := _count_type4(t, false)
		if d < c:
			return 1
		return 0 if d <= c else 2
	if _g(t, 0x28) != 0 and (_g(t, 0x44) == 0 or _g(t, 0x20) == 0 or v1 == 0xff):
		var a := _count_goals(t, true)
		var b := _count_goals(t, false)
		if b + v4 < a + v2:
			return 1
		if a + v2 < b + v4:
			return 2
		return _away_goal_leaf(t)
	var skip_first := false
	if v2 == v4:
		var a := _count_goals(t, true)
		var b := _count_goals(t, false)
		if a == b:
			skip_first = true
	if not skip_first:
		var a := _count_goals(t, true)
		var b := _count_goals(t, false)
		if a + v2 != b + v4:
			if b + v4 < a + v2:
				return 1
			if a + v2 < b + v4:
				return 2
			return _leaf_cmp(t)
	var bb := _count_goals(t, false)
	if bb < v2:
		return 1
	if v2 < bb:
		return 2
	return _away_goal_leaf(t)
