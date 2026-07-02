class_name Pm98Driver
extends RefCounted
## EXACT port of MANAGER.EXE's per-tick MATCH DRIVER FUN_00598740 (the function that
## advances one simulation frame and returns 1=continue / 0=match-over) plus its one-shot
## restart handler FUN_00593b70 (docs/re/EXACT_PORT_PLAN.md Stage 3 task 2, item 2;
## skeleton in docs/re/MATCH_TICK_DRIVER_MAP.md). This is the integration shell that wires
## together every DONE piece (predicates, dispatcher, events, the movement cluster) in the
## binary's exact per-tick order and reproduces its load-bearing RNG-draw stream.
##
## ====================== HONEST VALIDATION STATUS (read this) ======================
## This is a TRANSCRIPTION of the decompile + disasm (the ground truth), NOT an
## end-to-end-oracle-validated port. Two blockers (EXACT_PORT_PLAN items 3+4) mean a
## full-match parity kill-test is NOT yet possible:
##   * NO 22-player match-init (FUN_00591180) -> no real `m` to drive end-to-end.
##   * NO end-to-end oracle (wine MANAGER.EXE harness OR full-match PCode-emu).
## So test_driver.gd locks only what is a PURE function of the match Dict and needs no
## live players: the control-flow skeleton, the match-over return, FUN_00593a30 flag
## clear, the FUN_00594570 dequeue, the open-play predicate-cascade DISPATCH CODES, and
## -- the real prize -- the COMPLETE per-tick RNG-draw inventory (the +0x19e4/+0x19e8/
## +0x19ec commentary timers, the L465 goal-area discard draw, the FUN_00593b70 restart
## draw, and the dispatch case-2/6 draws via Pm98Dispatch). A single missed/extra draw
## desyncs the whole deterministic match, so this inventory is the load-bearing surface
## for the eventual scoreline+event-stream parity test.
##
## WHAT IS FAITHFUL vs BEST-EFFORT:
##   * EXACT (decompile-verified, testable now): the control flow, every match-SCALAR
##     read/write, the RNG-draw inventory, the dispatch-code selection, match-over.
##   * BEST-EFFORT (needs match-init to exercise): the player-pointer field writes inside
##     the goal-area / restart-placement / keeper-throw branches, and the movement core
##     wiring (decide/advance/relmatrix/markers/nearest/ball_advance/keeper_advance per
##     team). These read/write nested Dicts via _ref and no-op cleanly when the sub-objects
##     are absent (the shell), then run for real once FUN_00591180 populates m["sim"],
##     m["ball"], m["keepers"].
##
## DATA MODEL (same offset->Variant Dictionary convention as Pm98Predicates/Dispatch/Events):
##   * `m`          : the match struct.
##   * m["ball"]    : the ball struct (ball-local offsets), aliased at match+0x1610. The
##                    driver's `match+0x16XX` reads map to ball[0x16XX-0x1610]
##                    (0x1614->b[4] x, 0x1618->b[8] y, 0x1630/34/38->b[0x20/24/28] vel,
##                    0x1650->b[0x40] controller, 0x1658->b[0x48] engaged target,
##                    0x165c->b[0x4c], 0x1664->b[0x54] side). ball+0x1d4 -> m.
##   * m["sim"]     : [ctx_team0, ctx_team1], the two per-team movement contexts.
##   * m["keepers"] : [keeper_team0, keeper_team1] (each keeper+0x18c -> m).
##   * m[0x468]     : the team/session sub-object (read for play-state +0xfa0 and the
##                    display-flag drivers +0xfe8/+0xfec/+0xff0).
##   * m["ring"]    : the global 1024-frame replay-ring counter DAT_006d31bc.
##   Player-pointer match fields (+0x43c booked, +0x440 prepend, +0x444 scorer, +0x438
##   taker) are nested Dicts (or absent == null).
##
## REPLAY/RECORD globals DAT_006d31c4 (playback) and DAT_00665d8c (record) are 0 in a live
## deterministic sim, so the snapshot-ring and playback branches are SKIPPED (commented in
## place). DISPLAY/SOUND (FUN_00590f00/f40/f60 sound, FUN_004e* commentary, all gated by
## match+0x180a/+0x180b/+0x180c which FUN_00593a30 forces to 0 headless) are no-ops. The
## FUN_005ec240/FUN_005ec230 pairs that bracket skipped commentary are an RNG save/restore
## that net-zeros the seed and are dropped (only UNBRACKETED FUN_005ec250 advances it).

const ENGINE_CONTINUE := 1
const ENGINE_OVER := 0


static func _g(d: Dictionary, off: int) -> int:
	return int(d.get(off, 0))


static func _ref(d: Dictionary, off: int) -> Dictionary:
	var v: Variant = d.get(off, null)
	return v if v is Dictionary else {}


static func _i(v: int) -> int:
	return Pm98Trig._i32(v)


static func _ball(m: Dictionary) -> Dictionary:
	var v: Variant = m.get("ball", null)
	return v if v is Dictionary else {}


## The binary's `(int)(roll*K + (roll*K >> 0x1f & 0x7fffU)) >> 0xf` scale idiom. For the
## MSVC rand() output roll in [0, 0x7fff] and a positive K, roll*K is non-negative, so the
## `>> 0x1f` arithmetic shift is 0 and the bias term vanishes: the result is (roll*K) >> 15.
static func _scale15(roll: int, k: int) -> int:
	var p := roll * k
	return (p + ((p >> 31) & 0x7fff)) >> 15


# =============================================================================
# FUN_00598740 -- one simulation tick. this=match; returns 1=continue / 0=over.
# `rng` is the live MatchEngine.Pm98Rng match seed (== FUN_005ec250).
# =============================================================================
static func tick(m: Dictionary, rng: MatchEngine.Pm98Rng) -> int:
	var b := _ball(m)
	if not b.is_empty():
		b[0x1d4] = m                                  # ball+0x1d4 -> match (real layout)

	# --- display head (L42-62): commentary start/stop latch, all DISPLAY/SOUND. The only
	# state is the +0x180c/+0x180d display flags; FUN_00593a30 reclobbers +0x180a-c next. ---
	var t468 := _ref(m, 0x468)
	if _g(t468, 0xfec) == 0:
		if _g(m, 0x180d) != 0:
			m[0x180d] = 0                             # FUN_00590f40 commentary-stop: no-op
	elif _g(m, 0x180d) == 0:
		m[0x180c] = 1
		m[0x180d] = 1                                 # FUN_00590f00 sound x2: no-op

	_pre_update(m)                                    # FUN_00593a30 (display flags)

	# --- +0x1a1e one-shot skip-tick gate (L64-69): run the restart handler this tick
	# INSTEAD of the movement core, then jump straight to the match-over check. ---
	var gate := _g(m, 0x1a1e) & 0xff
	m[0x1a1e] = 0
	if gate != 0:
		restart_handler(m, rng)                       # FUN_00593b70
		return _match_over(m)

	# --- set-piece special (L70-104): phase 7, or phase 5 with +0x19cc, on the taker side,
	# first-time (the +0x1a20 latch). Rebuild the taker queue, pick the active taker, run the
	# positioning pass for both teams, then early-return. DAT_006d31c4==0 (live). ---
	var phase448 := _g(m, 0x448)
	var setpiece := (phase448 == 7) or (phase448 == 5 and _g(m, 0x19cc) != 0)
	if setpiece and _team_byte(m, 0x759) != 0:
		var latch := _g(m, 0x1a20) & 0xff
		m[0x1a20] = 1
		if latch == 0:
			_build_taker_queue(m)                     # FUN_005bbf10 queue append (best-effort)
			var ctx_taker := _sim_ctx(m, _g(m, 0x45c))
			if not ctx_taker.is_empty():
				m[0x438] = _active_ref(ctx_taker, Pm98Movement.select_active(ctx_taker))   # FUN_005b8f20 -> +0x438 (player ptr)
			# FUN_005b70e0 x2 RENDER (skip). FUN_005b73a0 x2 positioning (set-piece -> draws RNG).
			_position_both(m, rng)
			return _match_over(m)

	# --- queue-exhausted early-out (L105-106): latched set-piece + replay queue drained. ---
	if (_g(m, 0x1a20) != 0) and (_g(m, 0x27e8) <= _g(m, 0x27ec)):
		return _match_over(m)

	# --- open-play clock + periodic reset (L107-112). +0x450 (the open-play tick counter,
	# minute = +0x450*0x2d / +0x19ac) advances ONLY in phase 0 non-penalty; on a low-byte
	# wrap (every 256 ticks) run the per-team reset + a commentary % refresh (both display). ---
	if _g(m, 0x448) == 0 and _g(m, 0x19a0) != 4:
		m[0x450] = _i(_g(m, 0x450) + 1)
		if (_g(m, 0x450) & 0xff) == 0:
			_team_reset(m)                            # FUN_005946d0 (modeled no-op; RNG unverified)
			# FUN_00594410 commentary % -> FUN_00451180 display: no-op (guard div by +0x19ac).
	m[0x181c] = _g(m, 0x287c)                          # L113 copy a display short

	# --- replay record / playback (L114-163): SKIP in a live no-record run (DAT_00665d8c==0
	# record flag, DAT_006d31c4==0 playback flag). The +0x27dc/+0x27e4 snapshot rings and
	# FUN_005910c0/FUN_00591120 are not modeled here. ---

	# --- per-team idle counters (L164-179): if a team's +0x67c..+0x67f input bytes are all 0,
	# bump its +0x748 idle counter; else clear it. Integer-only, no RNG, fed by nothing on the
	# scoreline path -- ported for faithfulness. ---
	for t in 2:
		var base := 0x67c + t * 800
		if _g(m, base) == 0 and _g(m, base + 1) == 0 and _g(m, base + 2) == 0 and _g(m, base + 3) == 0:
			m[base + 0xcc] = _i(_g(m, base + 0xcc) + 1)
		else:
			m[base + 0xcc] = 0

	# --- movement core (L180-208): all NO-RNG. Decide/relmatrix/markers/advance/nearest per
	# team + the ball/keeper physics, then bump the 1024-frame ring counter. ---
	_movement_core(m, int(m.get("ring", 0)), rng)
	m["ring"] = (int(m.get("ring", 0)) + 1) & 0x3ff   # DAT_006d31bc = (DAT_006d31bc+1)&0x3ff

	# --- open-play / restart classification (L209-692): exactly one dispatch code fires. ---
	if _g(m, 0x448) == 0:
		_classify_open_play(m, rng, b)
	_stat_commentary_tail(m, rng, b)                  # the 3 commentary RNG timers (self-gates phase 0)

	# --- event-queue dequeue (L889) + the +0x454 cooldown decrement (L890-893). ---
	_dequeue(m)                                        # FUN_00594570(0)
	if _g(m, 0x454) > 1 and (_g(m, 0x461) & 0x80) == 0 and (_g(m, 0x160c) & 0xff) == 0:
		m[0x454] = _i(_g(m, 0x454) - 1)

	return _match_over(m)


## FUN_00593a30: set the display flags +0x180a/+0x180b/+0x180c from the team sub-object
## (match+0x468 -> +0xfe8/+0xfec/+0xff0), gated by the headless flag match+0x180e. Headless
## (+0x180e==0) forces all three to 0. Nothing on the scoreline path reads them.
static func _pre_update(m: Dictionary) -> void:
	var t := _ref(m, 0x468)
	var hl := _g(m, 0x180e) != 0
	m[0x180b] = 1 if (hl and _g(t, 0xff0) != 0) else 0
	m[0x180a] = 1 if (hl and _g(t, 0xfe8) != 0) else 0
	m[0x180c] = 1 if (hl and _g(t, 0xfec) != 0) else 0


## LAB_0059a06e: the match-over return. Live (DAT_006d31c4==0) -> over iff +0x454 == 1.
static func _match_over(m: Dictionary) -> int:
	if _g(m, 0x454) == 1:
		return ENGINE_OVER
	return ENGINE_CONTINUE


# ---- per-team / sub-object accessors -----------------------------------------------------

## A per-team byte in the 800-byte team-stat block: match[team*800 + off], team = match+0x45c.
static func _team_byte(m: Dictionary, off: int) -> int:
	return _g(m, _g(m, 0x45c) * 800 + off)


## The sim-context for a team (m["sim"][team]) or {} when match-init has not built it.
static func _sim_ctx(m: Dictionary, team: int) -> Dictionary:
	var sim: Variant = m.get("sim", null)
	if sim is Array and team >= 0 and team < (sim as Array).size():
		var c: Variant = (sim as Array)[team]
		return c if c is Dictionary else {}
	return {}


## Resolve select_active's INDEX (-1 = none) into the player POINTER (Dict ref) that match+0x438
## holds in the binary. The decide/engine taker-identity checks (Pm98Action.is_taker,
## decide_slice_c, the resolver) compare match+0x438 by Dict identity, NOT by index -- so the
## driver must store the ref, not the raw index. 0 = none (the no-active sentinel used elsewhere).
static func _active_ref(ctx: Dictionary, idx: int) -> Variant:
	if idx < 0:
		return 0
	var players: Array = ctx.get("players", [])
	if idx < players.size():
		return players[idx]
	return 0


## FUN_005bbf10 set-piece-queue append for the +0x45c team's taker (best-effort; the real
## walk finds the first taker with +0x8c==0 in the +0x46c team and pushes it onto the
## +0x674 queue). No RNG. Modeled as a Dict-level append where the data is present.
static func _build_taker_queue(m: Dictionary) -> void:
	var team := _g(m, 0x45c)
	var ctx := _sim_ctx(m, team)
	if ctx.is_empty():
		return
	var q: Array = ctx.get("queue", [])
	# faithful effect is "make a taker active"; left to position_team/select_active downstream.
	ctx["queue"] = q


# ---- movement core (FUN_00598740 L180-208) -----------------------------------------------
# All NO-RNG. Runs only when match-init has populated m["sim"]/m["ball"]/m["keepers"]; the
# shell (no match-init) skips it so the deterministic skeleton + RNG inventory stay testable.

static func _movement_core(m: Dictionary, ring: int, rng = null) -> void:
	var sim: Variant = m.get("sim", null)
	if not (sim is Array) or (sim as Array).is_empty():
		return                                        # no match-init -> nothing to advance
	var ctxs: Array = sim
	# The NORMAL per-tick "decide" pass FUN_005b8bf0 dispatches player vtable+8. With the
	# wine-corrected vtable base 0x639228, vtable+8 = FUN_005a4560 (the replay record/playback
	# pass) -- a NO-OP on the live headless path -- NOT FUN_005a3400 (the real DECIDE, which is
	# vtable+4, dispatched only by FUN_005b70e0 at restart/set-piece; see restart_handler). The
	# old off-by-4 map (base 0x639224) put DECIDE at +8, so this loop wrongly ran decide_slice
	# every tick and reset the kickoff taker's windup +0x48 each tick -> phase 2 frozen.
	# ball/GK/ref DECIDE (+8) are replay snapshot -> NO-OP live.
	for ctx in ctxs:
		Pm98Movement.build_relationship_matrix(ctx)   # FUN_005b8690
	for ctx in ctxs:
		Pm98Movement.assign_markers(ctx)              # FUN_005b94f0
	for ctx in ctxs:
		_advance_team(ctx, m, rng)                     # FUN_005b8c20 -> [vtable+0xc]=FUN_005a4600 (engine_tick)
	# sub-entity ADVANCE (+0xc): ball physics + the 2 keepers (referee skipped, outcome-irrelevant).
	var ball := _ball(m)
	if not ball.is_empty():
		Pm98Movement.ball_advance(ball)               # FUN_0058e2c0
	for k in _keepers(m):
		Pm98Movement.keeper_advance(k)                # FUN_005a22d0 x2
	for ctx in ctxs:
		Pm98Movement.select_nearest(ctx, 0)           # FUN_005b8ce0(0)


static func _keepers(m: Dictionary) -> Array:
	var v: Variant = m.get("keepers", null)
	return v if v is Array else []


## FUN_005b8bf0: per-player DECIDE loop -> FUN_005a3400 (decide_slice_a/b/c). Open-play
## (phase 0) hits decide_slice_c's clean DEFAULT; the set-piece taker/non-taker branches
## (slices C1/C2/C3) are all ported -- no push_error, the decide tail is complete.
static func _decide_team(ctx: Dictionary, m: Dictionary) -> void:
	for p in ctx.get("players", []):
		Pm98Movement.decide_slice_a(p, m)
		Pm98Movement.decide_slice_b(p, m)
		Pm98Movement.decide_slice_c(p, m)


## FUN_005b8c20: per-player ADVANCE loop. The player vtable+0xc slot (base 0x639228, live-confirmed
## via wine trace -- [[handoff-pm98-vtable-offset-rootcause-2026-06-23]]) is FUN_005a4600 = the
## per-player OPEN-PLAY ENGINE (Pm98Action.engine_tick), NOT the replay no-op FUN_005a4560 that the old
## off-by-4 vtable map (base 0x639224) attributed here. engine_tick reaches the resolver FUN_005aeda0
## and sets phase 0/1, advancing kickoff (phase 2) -> open play. Threads the shared match `rng` (the
## handler arms draw from the match LCG).
static func _advance_team(ctx: Dictionary, m: Dictionary, rng = null) -> void:
	for p in ctx.get("players", []):
		Pm98Action.engine_tick(p, m, rng)


## FUN_005b73a0 x2 (position_team for both teams). Set-piece branches draw RNG.
static func _position_both(m: Dictionary, rng: MatchEngine.Pm98Rng) -> void:
	for t in 2:
		var ctx := _sim_ctx(m, t)
		if not ctx.is_empty():
			Pm98Movement.position_team(ctx, rng)


# ---- open-play classification ladder (FUN_00598740 L209-692) ------------------------------
# Exactly ONE Pm98Dispatch.dispatch fires. The predicate cascade and the dispatch codes are
# decompile-exact; the player-pointer field writes inside each branch are best-effort (no-op
# without match-init). The only LOAD-BEARING raw draw in this region is the L465 goal-area
# discard (dispatch case-2/6 draws live inside Pm98Dispatch).

static func _classify_open_play(m: Dictionary, rng: MatchEngine.Pm98Rng, b: Dictionary) -> void:
	# +0x460 cooldown byte (L210-212).
	if _g(m, 0x460) > 1:
		m[0x460] = (_g(m, 0x460) - 1) & 0xff

	# restart-placement ladder (L213-359) -> dispatch 5 or 7.
	if not _ref(m, 0x43c).is_empty() and (_g(m, 0x460) & 0xff) < 2:
		_restart_placement(m, rng, b)
		return

	# predicate cascade (L361-691).
	Pm98Predicates.traj_copy(b, m, _traj_src(b))      # FUN_0058f100 side effect
	var armed := (_g(b, 0x63) & 0xff) != 0            # its return AL = ball+0x63 (disasm-verified)

	if not armed and Pm98Predicates.goal_area(b, m) != 0:        # FUN_0058ede0 goal-area -> GOAL
		_goal_area_branch(m, rng, b)
		return
	if _g(m, 0x19a0) == 4:                                       # penalty / ET special
		_penalty_branch(m, rng, b)
		return
	if Pm98Predicates.post_bar(b, m) != 0:                       # FUN_0058fbe0 -> CORNER (4)
		m[0x45c] = _i(1 - _g(b, 0x54))
		if _g(m, 0x45c) >= 0 and _g(m, 0x45c) < 2:
			m[_g(m, 0x45c) * 800 + 0x480] = _i(_g(m, _g(m, 0x45c) * 800 + 0x480) + 1)
		Pm98Dispatch.dispatch(m, 4, rng)
		return
	Pm98Predicates.traj_copy(b, m, _traj_src(b))                 # FUN_0058f100 again (L559)
	if (_g(b, 0x63) & 0xff) != 0 and _g(_ref(b, 0x40), 0x40) == 0x1f:   # keeper distribution
		_keeper_throw_branch(m, b)
		return
	if Pm98Predicates.dead_ball(b, m) != 0:                      # FUN_0058f3c0 -> RESTART (3)
		m[0x45c] = _i(1 - _g(b, 0x54))
		Pm98Dispatch.dispatch(m, 3, rng)
		return
	var ks := Pm98Predicates.keeper_save(b, m, _defending_keeper(m))   # FUN_0058f140 -> SAVE (2)
	if bool(ks.get("save", false)):
		Pm98Events.keeper_event(b, 0)                # the deferred FUN_005909f0 wire
	if int(ks.get("ret", 0)) != 0:
		m[0x45c] = _i(1 - _g(b, 0x54))
		Pm98Dispatch.dispatch(m, 2, rng)
		return

	_buildup_branch(m, rng, b)                        # attacking move -> dispatch 1


## The trajectory source vector for traj_copy: ball+0x40 -> target struct +4/+8/+0xc.
static func _traj_src(b: Dictionary) -> Array:
	var tgt := _ref(b, 0x40)
	return [_g(tgt, 4), _g(tgt, 8), _g(tgt, 0xc)]


## The defending keeper (m["keepers"][match+0x45c]) for the keeper-save reach geometry.
static func _defending_keeper(m: Dictionary) -> Dictionary:
	var ks := _keepers(m)
	var d := _g(m, 0x45c)
	if d >= 0 and d < ks.size() and ks[d] is Dictionary:
		return ks[d]
	return {}


## Goal-area branch (L362-479): loops the 2 teams; the defending team gets a GOAL (dispatch
## 6) unless a penalty/ET decisive condition routes to dispatch 1. The L465 conditional draw
## is the load-bearing one.
static func _goal_area_branch(m: Dictionary, rng: MatchEngine.Pm98Rng, b: Dictionary) -> void:
	var scorer := _ref(b, 0x48)                       # match+0x444 = ball+0x48 (engaged target)
	m[0x444] = scorer if not scorer.is_empty() else 0
	# scorer goal-vector write (+0x1e0/+0x1e4/+0x1e8) -- best-effort, needs the real scorer.
	if not scorer.is_empty():
		var post := _i(_g(m, 0x1824))
		scorer[0x1e0] = _i((_g(m, 0x1820) - 0x50000) * (1 if _g(scorer, 4) >= 0 else -1))
		scorer[0x1e4] = _i(-((post - 0x50000) * (1 if _g(scorer, 8) >= 0 else -1)))
		scorer[0x1e8] = 0

	var penalty := _g(m, 0x19a0) == 4
	for team in 2:                                    # local_40 = 1,0 -> iStack_44 = 0,1
		if not _opposite_half(m, b, team):            # FUN_0058f0b0(ball, team)
			continue
		m[0x45c] = team
		if penalty:
			if _pen_decisive(m):
				_team_sub(m, 0x24, 1)                 # match+0x468 -> +0x24 = 1
				Pm98Dispatch.dispatch(m, 1, rng)      # decisive -> dispatch 1, skip the goal
				continue
			m[0x461] = _g(m, 0x461) & 0x3f
		else:
			# possession counter + the per-player commentary draw.
			m[0x478 + team * 800] = _i(_g(m, 0x478 + team * 800) + 1)
			# L461-467: (char)piVar16[0xb8] != 0 -> ONE unbracketed FUN_005ec250 (discarded).
			if (_g(m, 0x478 + team * 800 + 0x2e0) & 0xff) != 0:
				rng.next()                            # THE L465 load-bearing discard draw
		Pm98Dispatch.dispatch(m, 6, rng)              # GOAL (case 6 may draw internally)


## FUN_0058f0b0(this=ball, side): is the ball on the half opposite `side`'s goal. goalx =
## -(match+0x1820) when (match+0x19a0 & 1) == side else +. (player_opposite_half with p=ball.)
static func _opposite_half(m: Dictionary, b: Dictionary, side: int) -> bool:
	var goalx := _i(_g(m, 0x1820))
	if ((_g(m, 0x19a0) & 1) ^ side) == 0:
		goalx = _i(-goalx)
	var sx := 1 if _g(b, 4) >= 0 else -1
	var sg := 1 if goalx >= 0 else -1
	return sx != sg


## The penalty-shootout decisive test (shared by the goal-area + penalty branches): the two
## shootout scores are match+0x47c / +0x79c, the kick count match+0x19c0.
static func _pen_decisive(m: Dictionary) -> bool:
	var n := _g(m, 0x19c0)
	var a := _g(m, 0x47c)
	var c := _g(m, 0x79c)
	if n < 0xb:
		return ((c - n / 2) + 5 < a) or ((a - (n + 1) / 2) + 5 < c)
	return (n & 1) == 0 and a != c


## Penalty / extra-time special (L481-544): keeper-save short-circuit, then dispatch 1
## (decisive) or 3 (restart).
static func _penalty_branch(m: Dictionary, rng: MatchEngine.Pm98Rng, b: Dictionary) -> void:
	var ks := Pm98Predicates.keeper_save(b, m, _defending_keeper(m))
	if bool(ks.get("save", false)):
		Pm98Events.keeper_event(b, 0)
	Pm98Predicates.traj_copy(b, m, _traj_src(b))
	if int(ks.get("ret", 0)) == 0 and (_g(b, 0x63) & 0xff) == 0:
		# velocity / goal-line geometry gate: a slow ball still in front of goal -> no event.
		var line := _i(_g(m, 0x1820))
		if _g(m, 0x45c) == (_g(m, 0x19a0) & 1):
			line = _i(-line)
		var sv := 1 if _g(b, 0x20) >= 0 else -1
		var sl := 1 if line >= 0 else -1
		if sv != sl:
			if _g(b, 0x20) == 0 and _g(b, 0x24) == 0 and _g(b, 0x28) == 0 and _ref(b, 0x40).is_empty():
				return                                # ball dead in front + no controller -> no dispatch
	m[0x45c] = _i(1 - _g(m, 0x45c))
	# penalty kick counter (L501-507).
	m[0x19c0] = _i(_g(m, 0x19c0) + 1)
	if _pen_decisive(m):
		_team_sub(m, 0x24, 1)
		Pm98Dispatch.dispatch(m, 1, rng)
	else:
		Pm98Dispatch.dispatch(m, 3, rng)             # LAB_005996d2


## Keeper-throw / goal-kick distribution setup (L559-581): no dispatch; arms phase 6, the
## +0x19dc timer and the taker. Player-pointer heavy -> best-effort match-scalar writes.
static func _keeper_throw_branch(m: Dictionary, b: Dictionary) -> void:
	m[0x45c] = _i(_g(b, 0x54))
	Pm98Movement.set_phase(m, 6)                      # FUN_005942e0(6)
	m[0x19dc] = 0x6a4
	var d := _g(m, 0x45c)
	var taker := _ref(m, d * 800 + 0x46c)
	m[0x438] = taker if not taker.is_empty() else 0
	# taker+0x48 stamina/timer = (-(decisive?1:0) & 0x2d0) + 0xb4 -- needs the real taker.
	if not taker.is_empty():
		var booked := 1 if (_g(_ref(taker, 0x184), 0x2ee) != 0 and Pm98Movement.play_state_eq(m, 0)) else 0
		if booked == 1 and _g(taker, 0x5c) != 0:
			taker[0x48] = (-1 & 0x2d0) + 0xb4
		else:
			taker[0x48] = 0xb4


## Attacking build-up (L593-691): the time/position gate, then dispatch 1. The case-0/1/2/3
## commentary switch is all 240/230-bracketed (seed-neutral) -> no load-bearing draw here.
static func _buildup_branch(m: Dictionary, rng: MatchEngine.Pm98Rng, b: Dictionary) -> void:
	var poss := _g(m, 0x19a0)
	if poss > 3:
		return
	var half := _g(m, 0x19ac)
	if half == 0:
		return                                        # guard the div the binary assumes nonzero
	var thresh := half
	if poss > 1:
		thresh = half / 3
	var elapsed := _g(m, 0x450) - thresh
	if elapsed < 0:
		return
	if _i(_g(m, 0x1820)) - 0x1e0000 <= absi(_i(_g(b, 4))) and elapsed <= half / 9:
		return
	if poss == 2:
		_team_sub(m, 0x20, 1)
	m[0x45c] = _i((1 - _g(m, 0x19c8)) ^ (_g(m, 0x19a0) & 1))
	Pm98Dispatch.dispatch(m, 1, rng)
	# the +0x19a0 commentary switch (L614-691): FUN_00450e60 reads (no RNG) + 240/230 brackets.


## Restart-placement ladder (L213-359): sets match+0x45c, the +0x461 outcome bits, the
## +0x19cc region {0,1,2,6} via a within-box cascade, then dispatch 5 or 7. RNG-FREE. The
## region geometry is best-effort (the DONE leaves) pending the e2e oracle; the dispatch
## code and +0x45c are exact.
static func _restart_placement(m: Dictionary, rng: MatchEngine.Pm98Rng, _b: Dictionary) -> void:
	var foul := _ref(m, 0x43c)
	if (_g(m, 0x461) & 2) != 0:
		m[0x19d0] = _i(_g(m, 0x19d0) + 1)
	if (_g(foul, 0x2d9) & 0xff) != 0:
		m[0x461] = _g(m, 0x461) | 4
	m[0x45c] = _i(1 - _g(foul, 0x2b8))

	# region cascade -> +0x19cc (best-effort). within_box(spot, ballpos, lx, ly, lz).
	var goalx := _i(_g(m, 0x1820))
	var same := _g(foul, 0x2b8) != (_g(m, 0x19a0) & 1)
	var ballpos := [_g(_ball(m), 4), _g(_ball(m), 8), _g(_ball(m), 0xc)]
	var region := 0
	if Pm98Movement.within_box(ballpos, _spot(0x134000 - goalx, same), 0x54000, 0x1a28f5, 0x640000) \
			or Pm98Movement.within_box(ballpos, _spot(0x164000 - goalx, same), 0x84000, 0x2028f5, 0x640000):
		region = 2
	elif Pm98Movement.within_box(ballpos, _spot(0x134000 - goalx, same), 0x54000, 0x1a28f5, 0x640000):
		region = 6
	elif Pm98Movement.within_box(ballpos, _spot(0xa8000 - goalx, same), 0x38000, 0x640000, 0x640000):
		region = 2
	elif Pm98Movement.within_box(ballpos, _spot(0x38000 - goalx, same), 0x38000, 0x640000, 0x640000):
		region = 1
	m[0x19cc] = region

	Pm98Dispatch.dispatch(m, ((_g(m, 0x461) & 1) << 1) | 5, rng)   # 5 or 7


## A restart spot vector [x, 0, 0], x negated when not same-side (the ladder's sign flip).
static func _spot(x: int, same: bool) -> Array:
	return [_i(x if same else -x), 0, 0]


## Write a scalar into the team/session sub-object (match+0x468 -> +off).
static func _team_sub(m: Dictionary, off: int, val: int) -> void:
	var t: Variant = m.get(0x468, null)
	if t is Dictionary:
		(t as Dictionary)[off] = val


# ---- stat / commentary tail (FUN_00598740 L692-888) --------------------------------------
# The three per-tick commentary/event TIMERS. Their text output is display, but their
# UNBRACKETED FUN_005ec250 draws advance the match seed and MUST be reproduced in lockstep.
# Pure match-scalar functions (counters + ball.x + team-stat scalars) -> oracle-free testable.

static func _stat_commentary_tail(m: Dictionary, rng: MatchEngine.Pm98Rng, b: Dictionary) -> void:
	if _g(m, 0x448) != 0:
		return
	if _g(m, 0x19ac) == 0:
		return                                        # the minute math divides by +0x19ac
	# possession % bar (FUN_00590f60 x2) -- display, no RNG. The +0x19e0 smoothing IS state:
	var minute := (_g(m, 0x450) * 0x2d) / _g(m, 0x19ac)
	_update_possession_meter(m, b)

	# --- +0x19e4 block: EXACTLY 3 draws on expiry. ---
	m[0x19e4] = _g(m, 0x19e4) - 1
	if _g(m, 0x19e4) < 1:
		var r0 := rng.next()                          # DRAW 1: reset the timer
		m[0x19e4] = _scale15(r0, 0x708)
		rng.next()                                    # DRAW 2: branch select (<500)
		rng.next()                                    # DRAW 3: the value (either branch)
		# FUN_00590f60 + FUN_00590f00 are display/sound.

	# --- +0x19e8 block: 1-3 draws on expiry. ---
	m[0x19e8] = _g(m, 0x19e8) - 1
	if _g(m, 0x19e8) < 1:
		var diff: int
		if (_g(m, 0xa78) & 0xff) == 0:
			diff = _g(m, 0x478) - _g(m, 0x798)
		else:
			diff = 0
		var r1 := rng.next()                          # DRAW 1: reset the timer
		m[0x19e8] = _scale15(r1, 0xe10)
		if diff < -1:
			pass                                      # short-circuit: no further draw
		else:
			var r2 := rng.next()                      # DRAW 2: the (diff+2)*300 gate
			if (diff + 2) * 300 <= _scale15(r2, 1000):
				pass                                  # gate fails -> stop (no DRAW 3)
			else:
				rng.next()                            # DRAW 3: the 0..6 commentary switch

	# --- +0x19ec block: 1 draw when the whole gate passes. ---
	if (_g(m, 0x461) & 0x80) == 0 and _g(m, 0x19a0) != 4 and _g(m, 0x448) == 0 \
			and minute > 5 and minute < 0x2a:
		m[0x19ec] = _g(m, 0x19ec) - 1
		if _g(m, 0x19ec) < 1 and absi(_i(_g(b, 4))) < 0xe0000 and _stat_event_zero(m):
			var r3 := rng.next()                      # DRAW: reset the timer
			m[0x19ec] = _scale15(r3, 0x960) + 900
			# the FUN_004e9e00/9f40/a070 commentary is 240/230-bracketed (seed-neutral).
			_stat_event_commit(m)


## +0x19e0 possession-meter smoothing (L694-741): a pure-scalar value stepped +/-1 toward a
## ball-position ratio, fed to FUN_00590f60 (display). State, but no RNG and not seed-bearing
## (the +0x19e4 block reads +0x19e0 only to SCALE a draw value, never to gate a draw). Ported
## faithfully. match+0x1664 == ball+0x54 (the ball-side field).
static func _update_possession_meter(m: Dictionary, b: Dictionary) -> void:
	var line := _i(_g(m, 0x1820))
	if (1 - _g(b, 0x54)) == (_g(m, 0x19a0) & 1):
		line = _i(-line)
	var dx := absi(_i(_g(b, 4) - line))
	var dy := absi(_i(_g(b, 8))) / 3
	var d: int = dx if dx > dy else dy
	var ratio := 100 - (d * 100) / 0x280000
	if ratio < 0:
		ratio = 0
	# the two sequential piecewise remaps (L726-739).
	if ratio < 0x19:
		ratio = 0
	elif ratio < 0x32:
		ratio = ratio * 2 - 0x32
	if ratio < 0x4c:
		if ratio > 0x32:
			ratio = ratio * 2 - 0x32
	else:
		ratio = 100
	var cur := _g(m, 0x19e0)
	# step = +1 if ratio > cur else -1 (the binary's `(((ratio<=cur)-1)&2)-1`).
	m[0x19e0] = cur + (1 if ratio > cur else -1)


## FUN_005e2750 stand-in: the +0x19ec gate's non-RNG predicate (==0 to proceed). Modeled
## true (no pending blocking state) on the headless path; nothing on the scoreline reads it.
static func _stat_event_zero(_m: Dictionary) -> bool:
	return true


## The +0x19ec block's stat snapshot (L882-886): cache the team-stat scalars for next compare.
static func _stat_event_commit(m: Dictionary) -> void:
	m[0x19f4] = _g(m, 0x754)
	m[0x19f0] = _g(m, 0x478) - _g(m, 0x798)
	m[0x19f8] = _g(m, 0xa74)
	m[0x19fc] = _g(m, 0x750)
	m[0x1a00] = _g(m, 0xa70)


# ---- event-queue dequeue (FUN_00594570, this=match, flush=0) ------------------------------
# Decrement each queued event's delay; fire (and remove) it when the play-state is 0/4 OR
# (phase 0 AND its delay hit 0). Firing only runs FUN_004511d0 commentary (display) -> the
# dequeue has NO RNG and NO scoreline effect; ported so the queue does not grow unbounded.

static func _dequeue(m: Dictionary) -> void:
	var queue: Array = m.get(0x1a24, [])
	var ps := _g(_ref(m, 0x468), 0xfa0)
	var fire_state := ps == 0 or ps == 4              # FUN_005943d0 (==4) || FUN_005943b0 (==0)
	var phase0 := _g(m, 0x448) == 0
	var i := 0
	while i < queue.size():
		var ev: Array = queue[i]
		var fire := false
		if fire_state:
			fire = true
		elif phase0:
			ev[3] = int(ev[3]) - 1                     # --delay (only when not fire_state)
			if int(ev[3]) < 1:
				fire = true
		if fire:
			queue.remove_at(i)                        # FUN_004511d0 commentary = display no-op
		else:
			i += 1
	m[0x1a24] = queue
	m[0x1a28] = queue.size()
	if _g(m, 0x1a30) != 0:                            # decrement the save/event timer
		m[0x1a30] = _g(m, 0x1a30) - 1


# =============================================================================
# FUN_00593b70 -- the one-shot match-restart / phase-reset handler. this=match.
# Invoked from the +0x1a1e skip-tick gate. Runs the kickoff/restart placement, a full
# match-state reset, re-seeds the movement, and (for +0x448 in {2,3,4,5,6}) draws ONE
# unbracketed FUN_005ec250. Callee RNG VERIFIED 2026-07-02 (ScanRngReach.java, real fn
# boundaries): FUN_0044d0d0-family closure 125 fns / FUN_005946d0 closure 4 /
# FUN_005946f0 closure 52 -- ZERO FUN_005ec250 sites with the highlight replayer
# FUN_0044cae0 gated off (headless: no human-manager flags). position_team
# (FUN_005b73a0) DOES draw on set-piece phases and is wired with `rng`.
# =============================================================================
static func restart_handler(m: Dictionary, rng: MatchEngine.Pm98Rng) -> void:
	# L23-30: a 240/230-bracketed commentary probe (seed-neutral) -- skipped.

	# L31-111: the +0x1a38 restart-type dispatch (DAT_006d31c4==0 live).
	var rtype := _g(m, 0x1a38)
	if rtype != 0:
		var phase := _restart_phase(rtype)            # DAT_00664070[rtype]
		m[0x44c] = phase
		m[0x448] = phase
		_team_reset(m)                                # FUN_005946d0 (stats banking; see below)
		if rtype == 1:                                # KICKOFF
			m[0x19a8] = _i(_g(m, 0x19a8) + _g(m, 0x450))
			m[0x1a1f] = 0
			m[0x450] = 0
			m[0x19a4] = 0
			# The per-rung FUN_0044d0d0/d190/d250/d310 (ECX = session, asm 0x593d04..) are NOT
			# placement: each banks the finished period into the season record (FUN_0044e440 ->
			# DAT_0066afd0 + per-player fitness) and rebuilds the session summary panels
			# (FUN_0044d5f0). RNG-clean live: ScanRngReach closure 125 fns, 0 draw sites, with
			# the highlight replayer FUN_0044cae0 gated off (DAT_00652a10 && phase{0,1[,5]} &&
			# a HUMAN manager flag session+0x7f0/+0xf90 -- always false headless/CPU-vs-CPU).
			# The one sim-feedback write is FUN_0044d5f0 L9: session+0x14 = 0 (read back by the
			# ball restart decide's +0x1d8 flag) -- modeled below; the rest is display/records.
			match _g(m, 0x19a0):
				0:
					_ref(m, 0x468)[0x14] = 0          # FUN_0044d0d0 -> FUN_0044d5f0
				1:
					_ref(m, 0x468)[0x14] = 0          # FUN_0044d190 -> FUN_0044d5f0
					# caller tail: if team+0x44 == 0 -> +0x19a0 += 2 (skip the ET rungs)
					if _g(_ref(m, 0x468), 0x44) == 0:
						m[0x19a0] = _i(_g(m, 0x19a0) + 2)
				2:
					_ref(m, 0x468)[0x14] = 0          # FUN_0044d250 -> FUN_0044d5f0
				3:
					_ref(m, 0x468)[0x14] = 0          # FUN_0044d310 -> FUN_0044d5f0
					m[0x45c] = 0
			m[0x19a0] = _i(_g(m, 0x19a0) + 1)
		# 1 < rtype < 9: a 2x11 player-position snapshot/compare (FUN_0044d3d0) -- feeds only
		# the bVar3 commentary gate (display), skipped.
		# L96-102: the ACTUAL kickoff placement -- FUN_005b6ba0 x2 (ECX = team header
		# m+0x46c/+0x78c, asm 0x593d6e..): re-runs the per-player ctor FUN_005a2830 IN PLACE
		# over both rosters (start positions reload, action state resets; ctor write-set
		# pinned in specs/playerbuild_writeset.txt). 0 draws (call-graph proven, banked in
		# _team_kickoff_reset docs). The decide + position passes below then arm the taker
		# and spread the formations.
		if _g(m, 0x19a0) != 4 or _g(m, 0x19c0) == 0:
			for ti in range(2):
				Pm98Match._team_kickoff_reset(m, ti, rng)
		# FUN_005946f0 (collider rebuild, Pm98CollBuilder): idempotent over unchanged pitch
		# geometry -- the STEP-1 populate_posts(m) result stands, so it is not re-run here.

	# L112-122: penalty/ET ball spot. match+0x16a0/+0x16a4/+0x16a8 == ball+0x90/+0x94/+0x98
	# (the +0x1610 embedding); write the ball Dict when populated, the match keys otherwise
	# (shell/fixture path, matching the old model).
	if _g(m, 0x19a0) == 4:
		m[0x44c] = 7
		m[0x448] = 7
		var spot := _i(_g(m, 0x1820) - 0xb0000)
		if _g(m, 0x45c) != 0:
			spot = _i(-spot)
		var bpen := _ball(m)
		if not bpen.is_empty():
			bpen[0x90] = spot
			bpen[0x94] = 0
			bpen[0x98] = 0
		else:
			m[0x16a0] = spot
			m[0x16a4] = 0
			m[0x16a8] = 0

	# L123-148: the always-run state reset block.
	m[0x460] = 0
	m[0x461] = _g(m, 0x461) & 0x38
	m[0x1994] = 0
	m[0x1998] = 0
	m[0x454] = 0
	m[0x19dc] = 0
	m[0x434] = 0
	m[0x43c] = 0
	m[0x440] = 0
	m[0x438] = 0
	m[0x444] = 0
	# FUN_005946f0 = the collider builder (Pm98CollBuilder, exactly ported): rebuilds the
	# post geometry from unchanged pitch dims -> idempotent over populate_posts(m); not re-run.
	# +0x1a34 = timeGetTime() -- WALL CLOCK, non-deterministic. STUBBED to 0 on the headless
	# path (nothing on the scoreline reads it); a real e2e oracle must inject the same value.
	m[0x1a34] = 0
	m[0x1a38] = 0
	m[0x461] = _g(m, 0x461) & 0xcf
	m[0x1a1f] = 0
	m["ring_c0"] = 0                                  # DAT_006d31c0 = 0
	m["ring"] = 0                                     # DAT_006d31bc = 0 (reset the 1024-frame ring)
	m[0x27ec] = 0
	# live (DAT_006d31c4==0): clear the 2 replay rings (FUN_005bbf10 ., 0) + counts.
	m[0x27e0] = 0
	m[0x27e8] = 0

	# L159-184: movement re-seed (all NO-RNG; render/trail calls skipped).
	# L159: (match+0x1610)->vt+4 = FUN_0058e120, the BALL restart decide -- releases the
	# carrier, zeroes vel, snaps the ball to the restart spot (centre at kickoff) and arms
	# the +0x58 = -2 prev-side sentinel. Runs BEFORE the active re-select below.
	var brd := _ball(m)
	if not brd.is_empty():
		Pm98Movement.ball_restart_decide(brd, m)
	var ctx0 := _sim_ctx(m, 0)
	if not ctx0.is_empty():
		m[0x438] = _active_ref(ctx0, Pm98Movement.select_active(ctx0))   # FUN_005b8f20 -> +0x438 (player ptr)
	# FUN_00593b70 calls FUN_005b70e0 x2 -- the DECIDE dispatcher (player vtable+4 = FUN_005a3400
	# per player) + the phase-2 kickoff-partner placement tail. The old framing wrongly dismissed
	# FUN_005b70e0 as a "render, SKIP" pass (it is vtable+4 = render only under the off-by-4 base).
	# This decide pass is what assigns the kickoff taker its action + windup (decide_slice case 2).
	# TODO(next): port FUN_005b70e0's kickoff-partner placement tail (nearest-teammate +0x63=1).
	for ctx in [ctx0, _sim_ctx(m, 1)]:
		if not ctx.is_empty():
			_decide_team(ctx, m)
	_position_both(m, rng)                            # FUN_005b73a0 x2 (set-piece -> draws)
	# L172-174: sub-entity vt+4 -- keeper restart decide x2 (FUN_005a2140: park each keeper
	# at its goal, position code 0x42) + the referee FUN_005b5790 (outcome-irrelevant, SKIP;
	# see keeper_restart_decide docs).
	for k in _keepers(m):
		Pm98Movement.keeper_restart_decide(k, m)
	m[0x458] = 0

	# L185-283: the restart-type commentary tail. ONE unbracketed FUN_005ec250 (L198) fires
	# only when +0x448 lands in {2,3,4,5,6}; for any other phase the routine returns BEFORE it.
	var p448 := _g(m, 0x448)
	if p448 == 2 or p448 == 3 or p448 == 4 or p448 == 5 or p448 == 6:
		rng.next()                                    # L198: the lone seed-advancing draw
		# everything after (FUN_00606220 etc.) is 240/230-bracketed display -> seed-neutral.


## DAT_00664070[rtype]: the restart-type -> phase table, banked 2026-06-22 from MANAGER.EXE
## .data 0x664070 (objdump -s): {0->0, 1->2, 2->3, 3->6, 4->4, 5->5, 6->2, 7->7}. Maps the
## +0x1a38 restart code to the +0x448/+0x44c phase. (Was modeled as identity; codes 3 and 6
## are the two that differ -- 3->6 and 6->2.)
const RESTART_PHASE_TABLE := [0, 2, 3, 6, 4, 5, 2, 7]

static func _restart_phase(rtype: int) -> int:
	return RESTART_PHASE_TABLE[rtype] if rtype >= 0 and rtype < RESTART_PHASE_TABLE.size() else rtype


## FUN_005946d0 team-reset: FUN_005b7080 x2 -> per-player FUN_005a32c0. Decompiled 2026-07-02:
## it BANKS per-player distance/steps into the match-stats record (p+0x3b8 +0x6c/+0x70/+0x78,
## team-header snapshot rows) and reduces the p+0x4c/+0x50 accumulators -- stats-side only;
## no engine-read field is touched and the closure (4 fns) has ZERO RNG sites (ScanRngReach).
## The engine port does not accumulate p+0x4c/+0x50, so the banking pass stays a no-op here.
static func _team_reset(_m: Dictionary) -> void:
	pass
