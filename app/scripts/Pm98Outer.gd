class_name Pm98Outer
extends RefCounted
## EXACT port of MANAGER.EXE's per-FRAME outer match step FUN_005983f0 (667 B, tail-called
## via the 0x5910a0 thunk from the career match loop FUN_0044ee70 @0x44f394) plus its
## wait-frame FUN_00593ab0 (184 B). Decompiles: docs/re/sim/fn_005983f0_FUN_005983f0.c +
## fn_00593ab0/fn_00598340/fn_0044d3d0/fn_00451200/fn_004511f0/fn_00594310/fn_00594380
## (regenerated + banked 2026-07-01; classifications in docs/re/MATCH_TICK_DRIVER_MAP.md).
## This is the layer ABOVE Pm98Driver.tick that turns
## "segment over" (tick returns 0 after a dispatch cooldown) into the +0x1a1e restart arm,
## and turns dispatch code 10 (Pm98Dispatch._case_phase full-time rewrite) into "match over"
## (step returns false).
##
## ============================ HONEST VALIDATION STATUS ============================
## TRANSCRIPTION of the decompile (same posture as Pm98Driver at its birth): NOT yet
## end-to-end-oracle-validated. The shell's own residue (branch select, +0x1a19 clear,
## score copy, +0x1a1e arm, the return flag) is the run_outer_oracle.sh target.
##
## CALLEE MAP (each classification decompile-verified 2026-07-01, do NOT re-derive):
##   * FUN_005b6ee0 x2  -- per-team KIT/PALETTE refresh: copies session (+0x468) kit words
##     +0xfa8/+0xfac/+0xfb0.. into team+0x2f0..0x2fa then FUN_005f5520/5600 palette setters.
##     DISPLAY, draws 0 (verified in the kickoff_init draw audit). Modeled no-op.
##   * FUN_005943d0 / FUN_005943b0 / FUN_005943f0 -- play-state == 4 / 0 / 2 predicates
##     (DONE: Pm98Movement.play_state_eq).
##   * FUN_00451200 / FUN_004511f0 -- 12-byte career thunks: `if (*career) FUN_005398e0/a0()`
##     (display). Modeled no-op.
##   * FUN_00594310 / FUN_00594380 -- display blit (vtable+0xc0 with DAT_00666f70 surface,
##     0x4000 flag) / display epilogue (vtable+0xc4 + FUN_005bd200(0) + FUN_005965a0).
##     Modeled no-op.
##   * FUN_00598740 -- the per-tick driver (DONE: Pm98Driver.tick).
##   * FUN_00598340 -- the PS==2 replay-cut check. SIM-RELEVANT: ONE UNBRACKETED
##     FUN_005ec250 draw on its ball-behind-own-goal-side path. Ported below (_replay_cut).
##   * FUN_00598690 -- the goal-REPLAY player: spins FUN_00598740 under DAT_006d31c4=1
##     (playback) over the +0x27e8/+0x27ec ring, arms +0x1a1e, restores. DISPLAY/replay;
##     playback ticks mutate no live sim state (the driver's DAT_006d31c4 gates). Modeled
##     no-op EXCEPT its +0x1a1e arm is NOT taken headless (the live branch already armed it
##     when tick returned 0 -- the replay path re-arms for the post-replay restart, which
##     headless has no replay ring to satisfy).
##   * FUN_00594570(1) -- the FLUSH variant of the event dequeue: fire + remove ALL queued
##     events unconditionally, then clear +0x1a2c/+0x1a30 (decompile
##     docs/re/sim/fn_00594570_FUN_00594570.c param_2 != 0 path). Ported (_dequeue_flush).
##   * FUN_0044d3d0(0)/(1) -- per-team ROSTER text/sprite refresh on the career/UI object
##     (11 slots x stride 0xac, FUN_00584c00 + DAT_0066b1e0 vtable+0x118/0x11c). Pure
##     DISPLAY (confirms the 06-24 classification). Modeled no-op.
##
## HEADLESS DEVIATION (the ONE deliberate one, same class as the timeGetTime stub):
## FUN_00593ab0's message pump FUN_005bce40(0) returns -1 with no window -> the binary maps
## it to result 10 -> +0x1a38=10 -> MATCH OVER (the user-quit path). A headless sim must
## model "no user input, keep playing" = pump result 0 instead, else every match ends at its
## first wait-frame. `PUMP_RESULT_HEADLESS = 0` encodes that; an e2e oracle driving the real
## binary interactively will see the same 0 (message processed, no quit/skip request).
##
## OPEN CAVEAT (flagged, not resolved -- needs fouls to actually fire, which needs the
## deferred open-play movement): the +0x1a20 set-piece latch is cleared ONLY by kickoff_init
## (FUN_00593600 L94) in the sim corpus; its steady-state past the first free-kick/penalty
## interacts with the replay-ring counters (+0x27e8/+0x27ec, which REAL play advances via
## the record flag DAT_00665d8c=1; headless models record=0). The wait loop carries an
## iteration guard (push_error, no silent failure) until the e2e oracle settles it.

const PUMP_RESULT_HEADLESS := 0    # FUN_005bce40(0) modeled: no input, no quit (see header)
const WAIT_LOOP_GUARD := 40000     # > 2 halves of ticks; breach = deadlock -> push_error


static func _g(d: Dictionary, off: int) -> int:
	return int(d.get(off, 0))


## One outer match FRAME (FUN_005983f0). Returns the binary's bVar8: true = keep playing,
## false = segment/match boundary (the career loop keeps calling while true; +0x1a38==10
## is the definitive match-over signal the caller reads alongside).
static func step(m: Dictionary, rng: MatchEngine.Pm98Rng) -> bool:
	m[0x1a19] = 0
	# FUN_005b6ee0 x2 (kit/palette refresh, per team): DISPLAY no-op, 0 draws.

	# paused = play-state 4 (FUN_005943d0) or 0 (FUN_005943b0).
	var paused: bool = Pm98Movement.play_state_eq(m, 4) or Pm98Movement.play_state_eq(m, 0)

	var cont: bool
	if paused or _g(m, 0x19a0) == 4 or (_g(m, 0x1a20) & 0xff) != 0:
		cont = _pause_branch(m, rng)
	else:
		cont = _live_branch(m, rng)

	# Common tail (L133-137): a pending restart refreshes both roster panels (DISPLAY).
	# NOTE the decompile's LAB_00598684 fast path skips this; _live_branch returns through
	# `_skip_tail` to model the goto (see below).
	if (_g(m, 0x1a1e) & 0xff) != 0 and not _skip_tail:
		pass                          # FUN_0044d3d0(0) + FUN_0044d3d0(1): DISPLAY no-op
	_skip_tail = false
	return cont


## The decompile's `goto LAB_00598684` (fast path: playing normally, no restart pending)
## bypasses the +0x1a1e display tail. The tail is a no-op headless, but the flag keeps the
## control flow honest for the oracle comparison.
static var _skip_tail := false


## L34-73: the PAUSE / SET-PIECE branch (play-state 0/4, or penalty +0x19a0==4, or the
## +0x1a20 set-piece latch). Spins wait-frames until an abort/priority-event/full-time/
## pause-latch break, then syncs the displayed score, flushes the event queue, and
## recomputes the continue flag.
static func _pause_branch(m: Dictionary, rng: MatchEngine.Pm98Rng) -> bool:
	# viewing = PS==2 (FUN_005943f0) and not the penalty mode.
	var viewing: bool = Pm98Movement.play_state_eq(m, 2) and _g(m, 0x19a0) != 4
	# FUN_00451200 (career display thunk) + FUN_00594310 (display blit): no-ops.

	var guard := 0
	while true:
		_wait_frame(m, rng)                              # FUN_00593ab0
		if (_g(m, 0x1a19) & 0xff) != 0 or viewing:
			break
		var code := _g(m, 0x1a38)
		if (_g(m, 0x1a2c) != 0 and code != 3 and code != 4 \
				and (code != 5 or (_g(m, 0x461) & 6) != 0)) \
				or code == 10 or (_g(m, 0x1a1f) & 0xff) != 0:
			break
		guard += 1
		if guard > WAIT_LOOP_GUARD:
			push_error("Pm98Outer: wait-loop guard breached (set-piece never resolves; +0x1a20 latch caveat)")
			break

	_sync_score(m)                                       # +0x19b0/+0x19b4 = team scores
	_dequeue_flush(m)                                    # FUN_00594570(1)
	# FUN_00594380 + FUN_004511f0: display no-ops.
	return (_g(m, 0x1a1e) & 0xff) == 0 and _g(m, 0x1a38) != 10 and (_g(m, 0x1a19) & 0xff) == 0


## L74-131: the LIVE branch -- one driver tick; tick-ret-0 arms the +0x1a1e restart gate for
## the NEXT frame's tick; then the PS==2 replay-cut ladder (headless PS==1 skips to the
## fast path).
static func _live_branch(m: Dictionary, rng: MatchEngine.Pm98Rng) -> bool:
	m[0x180e] = 0
	var ret := Pm98Driver.tick(m, rng)                   # FUN_00598740
	if ret == 0:
		m[0x1a1e] = 1                                    # segment over -> restart next tick

	# pause-latch bVar2: the user is steering a highlight (match+0x440 player's gs+0x2ee)
	# or the global pause byte DAT_00674cb3 (modeled 0 headless). Headless: both 0.
	var steering := false
	var prepend: Variant = m.get(0x440, null)
	if prepend is Dictionary:
		var gs: Variant = (prepend as Dictionary).get(0x184, null)
		if gs is Dictionary and (int((gs as Dictionary).get(0x2ee, 0)) & 0xff) != 0:
			steering = true
	if steering:
		m[0x1a1f] = _g(m, 0x1a1f) | 1

	var cont := _g(m, 0x1a38) != 10

	if not Pm98Movement.play_state_eq(m, 2):
		# LAB_005984f1: only a pending restart WITH the pause-latch takes the replay path.
		if (_g(m, 0x1a1e) & 0xff) != 0 and (_g(m, 0x1a1f) & 0xff) != 0:
			cont = _replay_path(m)
	else:
		var cut := _replay_cut(m, rng)                   # FUN_00598340 (may draw the seed)
		if not cut:
			if (_g(m, 0x1a1e) & 0xff) == 0:
				pass                                     # goto LAB_0059855c (fall through)
			elif _g(m, 0x1a2c) != 2:
				# goto LAB_005984f1
				if (_g(m, 0x1a1f) & 0xff) != 0:
					cont = _replay_path(m)
			else:
				cont = _replay_path(m)
		else:
			cont = _replay_path(m)

	# LAB_0059855c: fast path -- still playing and no restart pending -> goto LAB_00598684
	# (skips the flush AND the +0x1a1e display tail).
	if cont and (_g(m, 0x1a1e) & 0xff) == 0:
		_skip_tail = true
		return cont
	_dequeue_flush(m)                                    # FUN_00594570(1)
	return cont


## LAB_00598505: the goal/highlight REPLAY path -- FUN_00598690 (display playback; headless
## no-op) for codes 6 / 3-unlatched / priority-1, then the score sync. Always returns false
## (bVar8 = 0: this frame ends the playing stretch; the career loop re-enters).
static func _replay_path(m: Dictionary) -> bool:
	if Pm98Movement.play_state_eq(m, 2):
		var code := _g(m, 0x1a38)
		if code == 6 or (code == 3 and (_g(m, 0x1a1f) & 0xff) == 0) or _g(m, 0x1a2c) == 1:
			pass                                         # FUN_00598690 goal replay: no-op headless
	_sync_score(m)
	return false


## FUN_00593ab0: ONE wait-frame. Ticks the driver once (return DISCARDED by the binary),
## pumps messages, and on a pump result of 10 (quit) forces +0x1a38=10; a nonzero non-10
## result (skip request) spins the driver to segment end and arms +0x1a1e. Headless the
## pump yields PUMP_RESULT_HEADLESS=0 -> exactly one tick per wait-frame.
static func _wait_frame(m: Dictionary, rng: MatchEngine.Pm98Rng) -> void:
	# bVar3 = match+0x3ec == 0 gates FUN_00594310/FUN_00594380 (display): no-ops.
	m[0x180e] = 1
	m[0x1990] = 0
	m[0x198c] = 6000
	Pm98Driver.tick(m, rng)                              # FUN_00598740 (ret discarded)
	var pump := PUMP_RESULT_HEADLESS                     # FUN_005bce40(0); -1 -> 10 (quit)
	m[0x1a3c] = pump
	if pump == 10:
		m[0x1a38] = 10
		return
	if pump != 0:                                        # skip request: spin to segment end
		var guard := 0
		while Pm98Driver.tick(m, rng) != 0:
			guard += 1
			if guard > WAIT_LOOP_GUARD:
				push_error("Pm98Outer: skip-spin guard breached")
				break
		if _g(m, 0x1a38) != 0:
			m[0x1a1e] = 1


## FUN_00598340: the PS==2 replay-cut check. Fires only when +0x1a2c==1 && +0x1a30==0 &&
## +0x1a38==0; then if the ball sits on the possession side's OWN half x-sign (ball.x sign
## == the side-adjusted goal sign): engaged ball (+0x1650 = ball+0x40) keeps the replay
## (true), else ONE UNBRACKETED seed draw decides (roll*1000>>15 < 500 -> cut = false).
## Returns the decompile's cVar2 (true = keep).
static func _replay_cut(m: Dictionary, rng: MatchEngine.Pm98Rng) -> bool:
	if not (_g(m, 0x1a2c) == 1 and _g(m, 0x1a30) == 0 and _g(m, 0x1a38) == 0):
		return false
	var b := Pm98Driver._ball(m)
	var goalx := Pm98Trig._i32(_g(m, 0x1820))
	if _g(b, 0x54) == (_g(m, 0x19a0) & 1):               # +0x1664 side word vs half parity
		goalx = -goalx
	var sx := 1 if Pm98Trig._i32(_g(b, 4)) >= 0 else -1  # +0x1614 = ball.x sign idiom
	var sg := 1 if goalx >= 0 else -1
	if sx == sg:
		var eng: Variant = b.get(0x40, null)             # +0x1650 aliases ball+0x40 (pointer)
		if (eng is Dictionary) or (eng is int and int(eng) != 0):
			return true                                  # engaged -> keep (goto with cVar2 set)
		var roll := rng.next()                           # FUN_005ec250 -- SEED-ADVANCING
		if ((roll * 1000) >> 15) >= 500:
			return true
	return false


## FUN_00594570(param_2=1): flush ALL queued events (fire FUN_004511d0 commentary thunk --
## headless no-op -- and remove each), then clear the +0x1a2c priority max-flag and the
## +0x1a30 cooldown. Skipped entirely under playback (DAT_006d31c4, live==0).
static func _dequeue_flush(m: Dictionary) -> void:
	var q: Variant = m.get(0x1a24, null)
	if q is Array:
		(q as Array).clear()
	m[0x1a28] = 0
	m[0x1a2c] = 0
	m[0x1a30] = 0


## The L52-61 / L114-123 score sync: match+0x19b0/+0x19b4 = team0+0xc / team1+0xc (the
## +0x478/+0x798 dwords; the decompile's puVar6+200-dword stride == the 0x320-byte team
## header stride at +0x46c/+0x78c).
static func _sync_score(m: Dictionary) -> void:
	var sim: Variant = m.get("sim", null)
	if sim is Array and (sim as Array).size() >= 2:
		m[0x19b0] = _g((sim as Array)[0], 0xc)
		m[0x19b4] = _g((sim as Array)[1], 0xc)
