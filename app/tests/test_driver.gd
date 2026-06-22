extends SceneTree
## Control-flow + RNG-draw-inventory lock for the per-tick match driver Pm98Driver
## (FUN_00598740) and its restart handler (FUN_00593b70).
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_driver.gd
##
## NO end-to-end oracle exists yet (EXACT_PORT_PLAN items 3+4: no 22-player match-init,
## no full-match oracle), so this is a TRANSCRIPTION lock, NOT bit-for-bit-vs-binary. It
## pins what is a pure function of the match Dict and needs no live players:
##   * the match-over return (the +0x454 == 1 condition and the cooldown decrement),
##   * the +0x1a1e skip-tick gate -> restart_handler and ITS lone seed-advancing draw,
##   * the set-piece special early-return + the +0x1a20 latch,
##   * FUN_00593a30 headless flag clear,
##   * the open-play predicate-cascade DISPATCH CODES (read back from match+0x1a38),
##   * the COMPLETE per-tick RNG-draw inventory: the +0x19e4 (3) / +0x19e8 (1-3) / +0x19ec
##     (1) commentary timers and the L465 goal-area discard draw,
##   * the FUN_00594570 event-queue dequeue.
## The draw count is measured by replaying a reference Pm98Rng from the pre-tick state and
## counting next() calls to reach the post-tick state -- a single missed/extra draw (the
## failure mode that desyncs a deterministic match) is caught.

var _fail := 0
var _pass := 0


func _init() -> void:
	_test_match_over()
	_test_flag_clear()
	_test_skip_gate_restart()
	_test_setpiece_early_return()
	_test_dispatch_codes()
	_test_goal_area_l465_draw()
	_test_tail_timer_draws()
	_test_dequeue()
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


## Reproduce how many Pm98Rng.next() draws move `before_state` to `after_state` (<= 40).
func _draws(before_state: int, after_state: int) -> int:
	if before_state == after_state:
		return 0
	var ref := MatchEngine.Pm98Rng.new(before_state)
	for n in range(1, 41):
		ref.next()
		if ref.state == after_state:
			return n
	return -1


## A match Dict with the minimal fields the driver reads, plus a team sub-object at 0x468.
func _base_match() -> Dictionary:
	return {
		0x448: 0,        # set-piece phase (0 = open play)
		0x454: 0,        # dispatch cooldown
		0x460: 0,        # restart cooldown byte
		0x1a38: 0,       # outcome freeze (queue gate)
		0x19ac: 0x2d,    # half length (minute = +0x450*0x2d/+0x19ac)
		0x1820: 0xb0000, # goal line
		0x1824: 0x40000, # post half-width
		0x468: {0xfa0: 1, 0xfe8: 0, 0xfec: 0, 0xff0: 0},  # team/session: play-state 1
		"ball": {},
	}


func _rng() -> MatchEngine.Pm98Rng:
	return MatchEngine.Pm98Rng.new(1)


# ---------------------------------------------------------------------------
func _test_match_over() -> void:
	# phase != 0 -> classification skipped; isolate the +0x454 match-over logic.
	for spec in [[1, Pm98Driver.ENGINE_OVER, 1], [0, Pm98Driver.ENGINE_CONTINUE, 0],
			[2, Pm98Driver.ENGINE_OVER, 1], [3, Pm98Driver.ENGINE_CONTINUE, 2]]:
		var m := _base_match()
		m[0x448] = 1                      # not open play -> no classification, no clock
		m[0x454] = int(spec[0])
		var ret := Pm98Driver.tick(m, _rng())
		_ok(ret == int(spec[1]), "match_over: +0x454=%d -> ret %d (want %d)" % [spec[0], ret, spec[1]])
		_ok(int(m[0x454]) == int(spec[2]),
			"match_over: +0x454 %d -> %d (want %d)" % [spec[0], int(m[0x454]), spec[2]])


func _test_flag_clear() -> void:
	# FUN_00593a30 headless (+0x180e == 0) forces +0x180a/+0x180b/+0x180c to 0.
	var m := _base_match()
	m[0x448] = 1
	m[0x180a] = 1; m[0x180b] = 1; m[0x180c] = 1; m[0x180e] = 0
	Pm98Driver.tick(m, _rng())
	_ok(int(m[0x180a]) == 0 and int(m[0x180b]) == 0 and int(m[0x180c]) == 0,
		"flag_clear: headless -> +0x180a/b/c = %d/%d/%d" % [int(m[0x180a]), int(m[0x180b]), int(m[0x180c])])


func _test_skip_gate_restart() -> void:
	# +0x1a1e latched -> restart_handler runs (resets state) then match-over. The handler's
	# lone unbracketed draw fires iff the resulting +0x448 lands in {2,3,4,5,6}.
	# Case A: restart type 3 -> +0x448 = 3 -> 1 draw.
	var m := _base_match()
	m[0x1a1e] = 1; m[0x1a38] = 3; m[0x19a0] = 0; m[0x448] = 0
	var rng := _rng()
	var s0 := rng.state
	Pm98Driver.tick(m, rng)
	_ok(int(m[0x1a1e]) == 0, "skip_gate: +0x1a1e cleared")
	_ok(int(m[0x460]) == 0 and int(m[0x454]) == 0, "skip_gate: restart_handler reset +0x460/+0x454")
	_ok(int(m[0x448]) == 3, "skip_gate: restart type 3 -> +0x448 = %d (want 3)" % int(m[0x448]))
	_ok(_draws(s0, rng.state) == 1, "skip_gate: phase-3 restart draws %d (want 1)" % _draws(s0, rng.state))

	# Case B: no restart type, +0x448 stays 0 -> 0 draws.
	var m2 := _base_match()
	m2[0x1a1e] = 1; m2[0x1a38] = 0; m2[0x19a0] = 0; m2[0x448] = 0
	var rng2 := _rng()
	var s1 := rng2.state
	Pm98Driver.tick(m2, rng2)
	_ok(_draws(s1, rng2.state) == 0, "skip_gate: phase-0 restart draws %d (want 0)" % _draws(s1, rng2.state))


func _test_setpiece_early_return() -> void:
	# phase 7 + the taker-present team byte (team*800 + 0x759) -> latch +0x1a20, position pass,
	# early return. No sim -> no positioning RNG. Classification must NOT have run (+0x1a38 == 0).
	var m := _base_match()
	m[0x448] = 7
	m[0x45c] = 0
	m[0 * 800 + 0x759] = 1            # taker present for team 0
	m[0x1a20] = 0
	var rng := _rng()
	var s0 := rng.state
	Pm98Driver.tick(m, rng)
	_ok(int(m[0x1a20]) == 1, "setpiece: +0x1a20 latched")
	_ok(int(m[0x1a38]) == 0, "setpiece: classification skipped (+0x1a38 == 0)")
	_ok(_draws(s0, rng.state) == 0, "setpiece: no-sim positioning draws %d (want 0)" % _draws(s0, rng.state))


func _test_dispatch_codes() -> void:
	# Each open-play state routes to exactly one dispatch code, read back from match+0x1a38.
	# Tail timers held non-expiring (set to 5) so only the classification draws (here 0) count.
	# -- DEAD BALL (FUN_0058f3c0 true) -> code 3 --
	var m := _open_play_match()
	m[0x19a0] = 0
	m["ball"] = {0x4: 0x100000, 0x8: 0, 0xc: 0, 0x54: 0}   # in the dead-ball x-box [line, 2line]
	Pm98Driver.tick(m, _rng())
	_ok(int(m[0x1a38]) == 3, "dispatch: dead_ball -> +0x1a38 = %d (want 3)" % int(m[0x1a38]))

	# -- CORNER (FUN_0058fbe0 / post_bar true) -> code 4 --
	var m2 := _open_play_match()
	m2[0x19a0] = 0
	m2["ball"] = {0x4: -0x100000, 0x8: 0, 0xc: 0, 0x54: 0}  # in the negative-side post box
	Pm98Driver.tick(m2, _rng())
	_ok(int(m2[0x1a38]) == 4, "dispatch: post_bar -> +0x1a38 = %d (want 4)" % int(m2[0x1a38]))

	# -- BUILD-UP (cascade falls through) -> code 1 --
	var m3 := _open_play_match()
	m3[0x19a0] = 0; m3[0x450] = 100; m3[0x19c8] = 0
	m3["ball"] = {}                  # at origin -> all predicates fall through
	Pm98Driver.tick(m3, _rng())
	_ok(int(m3[0x1a38]) == 1, "dispatch: build-up -> +0x1a38 = %d (want 1)" % int(m3[0x1a38]))

	# -- RESTART PLACEMENT (+0x43c booked, +0x460 < 2) -> code 5 or 7 by (+0x461 & 1) --
	var m4 := _open_play_match()
	m4[0x43c] = {0x2b8: 0, 0x2d9: 0}; m4[0x460] = 0; m4[0x461] = 0
	Pm98Driver.tick(m4, _rng())
	_ok(int(m4[0x1a38]) == 5, "dispatch: restart-placement (bit0=0) -> +0x1a38 = %d (want 5)" % int(m4[0x1a38]))

	var m5 := _open_play_match()
	m5[0x43c] = {0x2b8: 0, 0x2d9: 0}; m5[0x460] = 0; m5[0x461] = 1
	Pm98Driver.tick(m5, _rng())
	_ok(int(m5[0x1a38]) == 7, "dispatch: restart-placement (bit0=1) -> +0x1a38 = %d (want 7)" % int(m5[0x1a38]))


func _test_goal_area_l465_draw() -> void:
	# goal_area true + a defending team -> dispatch 6; the per-team flag (team*800 + 0x478 +
	# 0x2e0) gates the lone L465 discard draw.
	# Flag SET -> 1 draw.
	var m := _open_play_match()
	m[0x19a0] = 0
	m[0 * 800 + 0x478 + 0x2e0] = 1
	m["ball"] = {0x4: 0xb8000, 0x8: 0, 0xc: 0, 0x48: {0x2b8: 0}, 0x54: 0}  # in goal window w2
	var rng := _rng()
	var s0 := rng.state
	Pm98Driver.tick(m, rng)
	_ok(int(m[0x1a38]) == 6, "goal_area: -> +0x1a38 = %d (want 6)" % int(m[0x1a38]))
	_ok(_draws(s0, rng.state) == 1, "goal_area: flag set -> L465 draws %d (want 1)" % _draws(s0, rng.state))

	# Flag CLEAR -> 0 draws (scorer+0x2b8 == defend -> no case-6 draw either).
	var m2 := _open_play_match()
	m2[0x19a0] = 0
	m2[0 * 800 + 0x478 + 0x2e0] = 0
	m2["ball"] = {0x4: 0xb8000, 0x8: 0, 0xc: 0, 0x48: {0x2b8: 0}, 0x54: 0}
	var rng2 := _rng()
	var s1 := rng2.state
	Pm98Driver.tick(m2, rng2)
	_ok(int(m2[0x1a38]) == 6, "goal_area: flag clear -> +0x1a38 = %d (want 6)" % int(m2[0x1a38]))
	_ok(_draws(s1, rng2.state) == 0, "goal_area: flag clear -> draws %d (want 0)" % _draws(s1, rng2.state))


func _test_tail_timer_draws() -> void:
	# Isolate the three commentary timers: classification falls through with 0 draws
	# (+0x19a0 = 5 -> build-up returns immediately; predicates miss at origin).
	# +0x19e4 expiry alone -> exactly 3 draws.
	var m := _tail_match()
	m[0x19e4] = 1; m[0x19e8] = 5; m[0x19ec] = 5; m[0x450] = 0
	var r := _rng(); var s := r.state
	Pm98Driver.tick(m, r)
	_ok(_draws(s, r.state) == 3, "tail: +0x19e4 expiry draws %d (want 3)" % _draws(s, r.state))

	# +0x19e8 expiry, diff < -1 -> exactly 1 draw (short-circuit).
	var m2 := _tail_match()
	m2[0x19e4] = 5; m2[0x19e8] = 1; m2[0x19ec] = 5; m2[0x450] = 0
	m2[0xa78] = 0; m2[0x478] = 0; m2[0x798] = 10           # diff = -10
	var r2 := _rng(); var s2 := r2.state
	Pm98Driver.tick(m2, r2)
	_ok(_draws(s2, r2.state) == 1, "tail: +0x19e8 diff<-1 draws %d (want 1)" % _draws(s2, r2.state))

	# +0x19e8 expiry, diff >= -1 and (diff+2)*300 > scale -> 3 draws.
	var m3 := _tail_match()
	m3[0x19e4] = 5; m3[0x19e8] = 1; m3[0x19ec] = 5; m3[0x450] = 0
	m3[0xa78] = 0; m3[0x478] = 10; m3[0x798] = 0           # diff = +10 -> 3600 > scale(<=999)
	var r3 := _rng(); var s3 := r3.state
	Pm98Driver.tick(m3, r3)
	_ok(_draws(s3, r3.state) == 3, "tail: +0x19e8 big-diff draws %d (want 3)" % _draws(s3, r3.state))

	# +0x19ec gate passes (minute in (5,42), ball near, +0x461 bit7 clear) -> 1 draw.
	var m4 := _tail_match()
	m4[0x19e4] = 5; m4[0x19e8] = 5; m4[0x19ec] = 1; m4[0x450] = 10; m4[0x461] = 0
	var r4 := _rng(); var s4 := r4.state
	Pm98Driver.tick(m4, r4)
	_ok(_draws(s4, r4.state) == 1, "tail: +0x19ec gate draws %d (want 1)" % _draws(s4, r4.state))

	# all timers held -> 0 draws.
	var m5 := _tail_match()
	m5[0x19e4] = 5; m5[0x19e8] = 5; m5[0x19ec] = 5; m5[0x450] = 0
	var r5 := _rng(); var s5 := r5.state
	Pm98Driver.tick(m5, r5)
	_ok(_draws(s5, r5.state) == 0, "tail: timers held draws %d (want 0)" % _draws(s5, r5.state))


func _test_dequeue() -> void:
	# play-state 0/4 -> every queued event fires (removed). play-state 1 + phase 0 -> the
	# delay decrements and only delay<=0 events fire.
	# play-state 0 -> flush all.
	var m := _tail_match()
	m[0x468] = {0xfa0: 0, 0xfe8: 0, 0xfec: 0, 0xff0: 0}
	m[0x1a24] = [[1, 0, 0, 5], [2, 0, 0, 9]]; m[0x1a28] = 2
	Pm98Driver.tick(m, _rng())
	_ok((m[0x1a24] as Array).is_empty() and int(m[0x1a28]) == 0,
		"dequeue: play-state 0 flushes (count %d, want 0)" % int(m[0x1a28]))

	# play-state 1, phase 0 -> decrement; the delay-1 event fires, the delay-9 survives.
	var m2 := _tail_match()
	m2[0x468] = {0xfa0: 1}                       # not 0/4 -> per-delay
	m2[0x1a24] = [[1, 0, 0, 1], [2, 0, 0, 9]]; m2[0x1a28] = 2
	Pm98Driver.tick(m2, _rng())
	_ok(int(m2[0x1a28]) == 1, "dequeue: phase-0 fires delay<=0 (count %d, want 1)" % int(m2[0x1a28]))
	var q: Array = m2[0x1a24]
	_ok(q.size() == 1 and int(q[0][0]) == 2 and int(q[0][3]) == 8,
		"dequeue: survivor is the delay-9 event decremented to 8")


# match set up so the open-play classification runs and the tail draws 0 (minute outside
# the +0x19ec window, timers held).
func _open_play_match() -> Dictionary:
	var m := _base_match()
	m[0x19e4] = 5; m[0x19e8] = 5; m[0x19ec] = 5
	m[0x450] = 0
	return m


# match where the predicate cascade misses (poss > 3 -> build-up returns, predicates at
# origin) so the only draws come from the commentary timers under test.
func _tail_match() -> Dictionary:
	var m := _base_match()
	m[0x19a0] = 5            # > 3 -> build-up returns, no dispatch
	m["ball"] = {}
	return m
