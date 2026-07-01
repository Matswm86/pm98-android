extends SceneTree
## Locks Pm98Outer (FUN_005983f0 outer step + FUN_00598340 replay-cut) against the PCode-emu
## oracle tools/re/run_outer_oracle.sh -> specs/outer_oracle.txt.
##
## The oracle STUBS every callee except the play-state predicates; the port runs the REAL
## Pm98Driver.tick. Fixtures keep the real tick residue-free on the checked surface: phase
## +0x448=3 (no clock, no classify, no commentary-timer draws), +0x454 in {0,1} selects the
## tick return (1/0 -- _match_over is +0x454==1), empty queue, no sub-objects. Checked per
## row: the return flag (oracle AL), +0x1a19 entry clear, the +0x1a1e arm, and the score
## copy +0x478/+0x798 -> +0x19b0/+0x19b4 (sim[0][0xc]=7 / sim[1][0xc]=3 vs 0x55 poison).
##
## Oracle rows NOT port-locked here (documented, not silent): live_ps2_keep needs the CUT
## stub forced true with +0x1a38=6, unrealizable against the real FUN_00598340 gate
## (+0x1a38==0); its shell path is locked via live_ps2_1a2c2 instead. Stub-hit ORDER lines
## are oracle-only evidence (the port exposes no call trace). DEQ/WAIT internals are hidden
## by their oracle stubs: the flush semantics (+0x1a2c/+0x1a30 clear + queue wipe) and the
## wait-frame writes (+0x180e=1, +0x1990=0, +0x198c=6000, per the FUN_00593ab0 decompile)
## get their own checks below; pause-row +0x180e therefore expects the PORT-faithful 1, not
## the stub-hidden oracle 0.

var _fail := 0
var _n := 0


func _init() -> void:
	_shell_rows()
	_cut_rows()
	_flush_semantics()
	_wait_frame_writes()
	print("test_outer: %d checks, %d FAIL" % [_n, _fail])
	quit(1 if _fail > 0 else 0)


func _ok(cond: bool, msg: String) -> void:
	_n += 1
	if not cond:
		_fail += 1
		print("FAIL: " + msg)


## A fixture match: tick inert (phase 3), tick-return via +0x454, scores 7/3, poisons set.
func _fix(ps: int, tick_ret: int, extra: Dictionary = {}) -> Dictionary:
	var m := {
		0x468: {0xfa0: ps},
		"sim": [{0xc: 7}, {0xc: 3}],
		"ball": {},
		0x448: 3,
		0x454: 0 if tick_ret == 1 else 1,
		0x19b0: 0x55, 0x19b4: 0x55,
		0x1a19: 1,
		0x1a24: [], 0x1a28: 0,
	}
	for k in extra:
		m[k] = extra[k]
	return m


func _step(m: Dictionary) -> bool:
	return Pm98Outer.step(m, MatchEngine.Pm98Rng.new(1))


## name, fixture, expected: [al, a1e, score_copied]
func _row(name: String, m: Dictionary, al: bool, a1e: int, copied: bool) -> void:
	var got := _step(m)
	_ok(got == al, "%s: return %s != oracle AL %s" % [name, got, al])
	_ok(int(m.get(0x1a19, -1)) == 0, "%s: +0x1a19 not cleared" % name)
	_ok(int(m.get(0x1a1e, 0)) == a1e, "%s: +0x1a1e=%d != %d" % [name, int(m.get(0x1a1e, 0)), a1e])
	var want0 := 7 if copied else 0x55
	var want1 := 3 if copied else 0x55
	_ok(int(m.get(0x19b0, -1)) == want0 and int(m.get(0x19b4, -1)) == want1,
		"%s: score copy dest (%s,%s) != (%s,%s)" % [name, m.get(0x19b0), m.get(0x19b4), want0, want1])


func _shell_rows() -> void:
	# oracle live_cont:     EAX&0xff=1  a1e=0  scores 0x55/0x55
	_row("live_cont", _fix(1, 1), true, 0, false)
	# oracle live_segend:   EAX=1  a1e=1  scores untouched
	_row("live_segend", _fix(1, 0), true, 1, false)
	# oracle live_fulltime: EAX=0  a1e=0  scores untouched (+0x1a38=10)
	_row("live_fulltime", _fix(1, 1, {0x1a38: 10}), false, 0, false)
	# oracle live_ps2_skip: EAX=1  a1e=0  scores untouched (real CUT gate fails: +0x1a2c=0)
	_row("live_ps2_skip", _fix(2, 1), true, 0, false)
	# oracle live_ps2_1a2c2: EAX=0  a1e=1  scores 7/3 (replay path, REPLAY-player gate not met)
	_row("live_ps2_1a2c2", _fix(2, 0, {0x1a2c: 2}), false, 1, true)
	# oracle pause_latch:   EAX=1  a1e=0  scores 7/3 (+0x1a1f=1 breaks the wait loop)
	_row("pause_latch", _fix(0, 1, {0x1a1f: 1}), true, 0, true)
	# oracle pause_code10:  EAX=0  a1e=0  scores 7/3
	_row("pause_code10", _fix(0, 1, {0x1a38: 10}), false, 0, true)
	# oracle pause_viewing: EAX=1  a1e=0  scores 7/3 (PS=2 + +0x1a20 latch; viewing breaks)
	_row("pause_viewing", _fix(2, 1, {0x1a20: 1}), true, 0, true)
	# oracle pause_event:   EAX=1  a1e=0  scores 7/3 (+0x1a2c=2, code 0 not in {3,4,5})
	_row("pause_event", _fix(0, 1, {0x1a2c: 2}), true, 0, true)


## FUN_00598340 rows (oracle entry 0x598340, REAL, seed 0x12345678). Ball fields alias the
## embedded ball object: +0x1614=b[4], +0x1650=b[0x40], +0x1664=b[0x54].
func _cut_rows() -> void:
	# cut_gate_off: +0x1a2c=0 -> false, 0 draws.
	var rng := MatchEngine.Pm98Rng.new(0x12345678)
	var m := {"ball": {}, 0x1820: 0x300000}
	_ok(Pm98Outer._replay_cut(m, rng) == false, "cut_gate_off: not false")
	_ok(rng.state == 0x12345678, "cut_gate_off: drew")

	# cut_sidemiss: +0x1664=1 vs +0x19a0&1=0 -> no negate; ball.x<0 -> sx!=sg -> false, 0 draws.
	rng = MatchEngine.Pm98Rng.new(0x12345678)
	m = {"ball": {4: -0x10000, 0x54: 1}, 0x1820: 0x300000, 0x1a2c: 1, 0x1a30: 0, 0x1a38: 0}
	_ok(Pm98Outer._replay_cut(m, rng) == false, "cut_sidemiss: not false")
	_ok(rng.state == 0x12345678, "cut_sidemiss: drew")

	# cut_engaged: +0x1664=0 == 0 -> goalx negated; ball.x<0 same side; +0x1650!=0 -> true, 0 draws.
	rng = MatchEngine.Pm98Rng.new(0x12345678)
	m = {"ball": {4: -0x10000, 0x54: 0, 0x40: 1}, 0x1820: 0x300000, 0x1a2c: 1, 0x1a30: 0, 0x1a38: 0}
	_ok(Pm98Outer._replay_cut(m, rng) == true, "cut_engaged: not true")
	_ok(rng.state == 0x12345678, "cut_engaged: drew")

	# cut_draw: same side, not engaged -> EXACTLY 1 draw; oracle: EAX=256 -> AL=0 (roll<500),
	# post-seed 3018423131.
	rng = MatchEngine.Pm98Rng.new(0x12345678)
	m = {"ball": {4: -0x10000, 0x54: 0}, 0x1820: 0x300000, 0x1a2c: 1, 0x1a30: 0, 0x1a38: 0}
	_ok(Pm98Outer._replay_cut(m, rng) == false, "cut_draw: != oracle AL 0")
	_ok(rng.state == 3018423131, "cut_draw: post-seed %d != 3018423131" % rng.state)


## FUN_00594570(1) flush residue (the oracle stubs DEQ; the decompile is the ground truth:
## fire+remove ALL, then +0x1a2c=0 / +0x1a30=0).
func _flush_semantics() -> void:
	var m := {0x1a24: [[7, 0, 0, 5]], 0x1a28: 1, 0x1a2c: 3, 0x1a30: 9}
	Pm98Outer._dequeue_flush(m)
	_ok((m[0x1a24] as Array).is_empty() and int(m[0x1a28]) == 0, "flush: queue not wiped")
	_ok(int(m[0x1a2c]) == 0 and int(m[0x1a30]) == 0, "flush: +0x1a2c/+0x1a30 not cleared")


## FUN_00593ab0 writes (decompile: +0x180e=1, +0x1990=0, +0x198c=6000 before the tick; the
## pump models PUMP_RESULT_HEADLESS=0 -> +0x1a3c=0, no code-10, no spin).
func _wait_frame_writes() -> void:
	var m := _fix(0, 1)
	m[0x1990] = 0x55
	m[0x198c] = 0x55
	Pm98Outer._wait_frame(m, MatchEngine.Pm98Rng.new(1))
	_ok(int(m[0x180e]) == 1, "wait: +0x180e != 1")
	_ok(int(m[0x1990]) == 0 and int(m[0x198c]) == 6000, "wait: timers not set")
	_ok(int(m[0x1a3c]) == 0, "wait: pump result != 0")
	_ok(int(m.get(0x1a38, 0)) != 10, "wait: code-10 quit path taken headless")
