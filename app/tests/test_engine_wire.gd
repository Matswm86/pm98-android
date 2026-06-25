extends SceneTree
## Task #4 WIRING parity for Pm98Action.engine_tick's action switch (FUN_005a4600 cases 4/0x25, 5/0x24,
## 0x14/0x16, 0x15, 0x19/0x1a, 0x36, 0x37). Each arm is now wired to its oracle-GREEN Pm98Movement port.
##
## Run: ~/godot462 --headless --path app --script res://tests/test_engine_wire.gd
##
## PROOF STRATEGY (transitive, no new Ghidra run needed):
##   engine_tick residue  ==  standalone handler residue  ==  the binary (the standalone handlers are each
##   oracle-GREEN against the REAL FUN under the PCode emulator -- test_acc40/ad010/ad970/adc60/kick).
## We build two IDENTICAL states from the same standalone-test fixture, run the bare handler on one and
## engine_tick on the other (same seed), and assert they agree on EVERY int field of player/ball/match,
## EXCEPT the inert-prologue bookkeeping set, plus identical rng end-state (-> rng threaded correctly).
##
## NON-INTERFERENCE (why the wrapper is transparent here): the chosen fixtures are NON-SPECIAL (gs+0x2ee=0)
## and the state is set so the prologue/epilogue are inert to the handler's I/O and draw ZERO rng:
##   * +0x48 locked (!=0) so tick_action (FUN_005a50c0) takes its decrement-and-return path -- it touches
##     ONLY +0x48 and no handler reads +0x48 (verified). +0x40 (the action code) is preserved -> dispatch.
##   * +0x88 = 0 so the 16-tick stamina block is skipped (no +0x70/+0x74 writes, no rng).
##   * +0x80 = +0x84 = 0 so the post-switch interpolation is skipped (no handler writes player +0x80/+0x84,
##     so it stays skipped after the handler too) -> the handler's pos/facing/aim survive.
##   * gs+0x2ee = 0 so the highlight power-accumulate AND the open-play power reset are both inactive
##     (they would otherwise clobber the handler's +0x54/+0x58).
##   * 4 of the 5 movement leaves (8680/65a0/9490/8f20) + the teammate-count + the case-8/9 resolver are
##     still NO-OP stubs, so they add no field writes. FUN_005a7260 (ball-touch) is now WIRED+REAL: for a
##     not-same-side player it runs the goal-anchor steer, whose handler-INDEPENDENT outputs are excluded
##     via STEER_7260 (see below). The Family-A cascade leaf (setup_shot/resolve_post_shot) now runs REAL
##     on BOTH sides (call_setup/call_resolve=true), so it adds the SAME writes to each -> they still agree.
## The remaining prologue writes are a FIXED, handler-independent set (INERT_P) we exclude from the diff;
## any OTHER divergence -- a missed dispatch, a clobbered output, an extra/short rng draw -- fails loudly.

const SEED := 0x12345678

# Fields the inert prologue legitimately writes on the engine_tick side but not on the bare-handler side:
#   0x48 tick_action decrement · 0x88 the &0xf counter · 0x6c cleared · 0x2d7/0x2d8 prologue flags ·
#   0x50 the phase-0 possession touch counter · 0x4c the (here-unreached) possession owner-touch counter.
const INERT_P := {0x48: true, 0x88: true, 0x6c: true, 0x2d7: true, 0x2d8: true, 0x50: true, 0x4c: true}

# FUN_005a7260 (the ball-touch decision) is now WIRED+REAL in engine_tick (no longer a no-op stub). For a
# not-same-side, non-carrier player it runs the goal-anchor steer (steer_89c0->8bc0->8f20), whose outputs
# are HANDLER-INDEPENDENT (they depend only on the player's side/goal geometry, not which handler fired) --
# the same class as INERT_P. The bare standalone handler does NOT run 7260, so we exclude the steer's
# rotational outputs from the player diff: 0x34 facing, 0x64 yaw, 0x68 speed, 0x90 flip-hysteresis (its
# curve 0x6c is already in INERT_P). Position 0x4/8/c is NOT excluded -- these fixtures keep speed 0 so the
# steer never integrates position; a handler's pos output stays fully checked.
const STEER_7260 := {0x34: true, 0x64: true, 0x68: true, 0x90: true}

var _fail := 0
var _pass := 0


func _init() -> void:
	# label, action code, builder name, the bare-handler Callable (call_setup/call_resolve = true, matching
	# the engine_tick wiring -- both sides run the full handler -> setup_shot/resolve_post_shot cascade).
	var cases := [
		["acc40 (case 4)",      0x04, "acc40",
			func(p, r): Pm98Movement.goal_aim_025(p, r, true)],
		["acc40 alias (0x25)",  0x25, "acc40",
			func(p, r): Pm98Movement.goal_aim_025(p, r, true)],
		["ad010 (case 5)",      0x05, "ad010",
			func(p, r): Pm98Movement.ai_feed_024(p, r, true)],
		["ad010 alias (0x24)",  0x24, "ad010",
			func(p, r): Pm98Movement.ai_feed_024(p, r, true)],
		["ad970 (case 0x36)",   0x36, "ad970",
			func(p, r): Pm98Movement.feed_layoff_036(p, r, true)],
		["adc60 (case 0x37)",   0x37, "adc60",
			func(p, r): Pm98Movement.feed_layoff_037(p, r, true)],
		["adfc0 (case 0x19)",   0x19, "adfc0",
			func(p, r): Pm98Movement.kick_resolve(p, r, Pm98Movement.KICK_ADFC0, true)],
		["adfc0 alias (0x1a)",  0x1a, "adfc0",
			func(p, r): Pm98Movement.kick_resolve(p, r, Pm98Movement.KICK_ADFC0, true)],
		["ae4c0 (case 0x14)",   0x14, "ae4c0",
			func(p, r): Pm98Movement.kick_resolve(p, r, Pm98Movement.KICK_AE4C0, true)],
		["ae4c0 alias (0x16)",  0x16, "ae4c0",
			func(p, r): Pm98Movement.kick_resolve(p, r, Pm98Movement.KICK_AE4C0, true)],
		["ae910 (case 0x15)",   0x15, "ae910",
			func(p, r): Pm98Movement.kick_resolve(p, r, Pm98Movement.KICK_AE910, true)],
	]
	for c in cases:
		_run(c[0], c[1], c[2], c[3])
	print("")
	print("ALL PASS (%d checks)" % _pass if _fail == 0 else "FAILED: %d / %d" % [_fail, _pass + _fail])
	quit(1 if _fail > 0 else 0)


func _run(label: String, action: int, fixture: String, bare: Callable) -> void:
	var sa := _build(fixture)            # for the bare standalone handler
	var et := _build(fixture)            # an independent identical state for engine_tick
	if sa.is_empty() or et.is_empty():
		_ok(false, "%s: no builder for fixture %s" % [label, fixture])
		return
	for st in [sa, et]:
		st["p"][0x40] = action           # the action code the switch dispatches on
		st["p"][0x48] = 5                # lock tick_action -> decrement-and-return (preserves +0x40/+0x2c)
	# tick_action ALWAYS advances the 2-bit sub-tick counter +0x30 (= (+0x30 + 1) & 3) even on the locked
	# path. The standalone handler is verified at the TRIGGER frame (+0x30 == guard value); so engine_tick
	# must enter ONE sub-tick earlier and let tick_action advance +0x30 up to the guard -- exactly how the
	# real sim reaches the handler. After the tick both states sit at the guard value, so the diff agrees.
	et["p"][0x30] = (int(sa["p"][0x30]) - 1) & 3

	var rng_sa := MatchEngine.Pm98Rng.new(SEED)
	var rng_et := MatchEngine.Pm98Rng.new(SEED)
	bare.call(sa["p"], rng_sa)
	Pm98Action.engine_tick(et["p"], et["p"][0x18c], rng_et)

	# rng threaded identically (same draw count + order). When the path draws (>=1), the equal-AND-advanced
	# state is positive proof the shared rng reached the handler; the full-field diff below independently
	# proves dispatch even on the 0-draw redirect path (acc40 not_special).
	if rng_sa.state != SEED:
		_ok(rng_et.state != SEED, "%s: handler drew no rng via engine_tick (dispatch missed?)" % label)
	_ok(rng_et.state == rng_sa.state,
		"%s rng end-state: engine_tick 0x%x vs standalone 0x%x" % [label, rng_et.state, rng_sa.state])

	# every int field of player / ball / match must agree, except the inert-prologue set + the now-wired
	# 7260 goal-anchor steer outputs on player (both handler-independent).
	_diff(label, "p", sa["p"], et["p"], _merge(INERT_P, STEER_7260))
	_diff(label, "ball", sa["p"][0x190], et["p"][0x190], {})
	_diff(label, "m", sa["p"][0x18c], et["p"][0x18c], {})


## Assert two field dicts agree on all INT keys outside `skip`. Dict/Array values are topology pointers
## (m/ball/gs/roster/teammate refs) that legitimately point to each state's own copies -> compared by
## TYPE only, not identity. A type mismatch (int vs Dict) on the same key is a real divergence.
func _diff(label: String, region: String, a: Dictionary, b: Dictionary, skip: Dictionary) -> void:
	var keys := {}
	for k in a: keys[k] = true
	for k in b: keys[k] = true
	for k in keys:
		if skip.has(k):
			continue
		var va: Variant = a.get(k, 0)
		var vb: Variant = b.get(k, 0)
		var ia := va is int or va is float
		var ib := vb is int or vb is float
		if ia and ib:
			_ok(int(va) == int(vb),
				"%s %s+0x%x: standalone 0x%x vs engine_tick 0x%x"
					% [label, region, int(k), int(va) & 0xffffffff, int(vb) & 0xffffffff])
		elif ia != ib:
			_ok(false, "%s %s+0x%x: type mismatch (standalone %s vs engine_tick %s)"
				% [label, region, int(k), typeof(va), typeof(vb)])
		# both Dict/Array -> topology pointer, skip.


func _merge(a: Dictionary, b: Dictionary) -> Dictionary:
	var out := a.duplicate()
	for k in b:
		out[k] = b[k]
	return out


func _ok(cond: bool, msg: String) -> void:
	if cond:
		_pass += 1
	else:
		_fail += 1
		print("  [FAIL] ", msg)


# --- fixture builders (mirror the NON-SPECIAL MISS path of each standalone oracle test) --------------

func _build(name: String) -> Dictionary:
	match name:
		"acc40":   return _build_acc40()
		"ad010":   return _build_ad010()
		"ad970":   return _build_ad970()
		"adc60":   return _build_adc60()
		"adfc0":   return _build_kick(4, 3)
		"ae4c0":   return _build_kick(8, 0)
		"ae910":   return _build_kick(5, 0)
	return {}


## test_acc40.gd _fixture("not_special").
func _build_acc40() -> Dictionary:
	var m := {
		0x1820: 0x2000000, 0x19a0: 0, 0x44c: 0, 0x180a: 0,
		0x1828: 0x1000000, 0x182c: -0x800000, 0x1830: -0x100000,
		0x1834: 0x3000000, 0x1838: 0x800000, 0x183c: 0x100000,
	}
	var target := {0x4: 0x1000000, 0x8: 0x80000, 0xc: 0, 0x34: 0}
	var ball := {0x4c: target}
	var gs := {0x2ee: 0}
	var p := {0x18c: m, 0x190: ball, 0x184: gs}
	p[0x2c] = 4; p[0x30] = 3; p[0x2b8] = 0
	p[0x54] = 0xd; p[0x58] = 0x10; p[0x5c] = 0
	p[0x3a4] = 0x100000; p[0x4] = 0; p[0x8] = 0; p[0xc] = 0
	return {"p": p}


## test_ad010.gd _fixture("p0_nonspec_miss") -- the bare BASE (tm0 off-axis -> corridor miss -> blind+tail).
func _build_ad010() -> Dictionary:
	var m := {
		0x1820: 0x2000000, 0x19a0: 0, 0x44c: 0, 0x180a: 0, 0x19cc: 0, 0x462: 0,
		0x1828: 0x1000000, 0x182c: -0x800000, 0x1830: -0x100000,
		0x1834: 0x3000000, 0x1838: 0x800000, 0x183c: 0x100000,
	}
	var ball := {0x1d4: m}
	var tm0 := {0x2bc: 1, 0x2b8: 0, 0x2c4: 1, 0x4: 0x2000000, 0x8: 0x900000, 0xc: 0}
	var gs := {0: [tm0], 0x2ee: 0}
	var p := {0x18c: m, 0x190: ball, 0x184: gs, 0x188: [tm0]}
	p[0x2c] = 3; p[0x30] = 3; p[0x34] = 0
	p[0x54] = 0xd; p[0x58] = 0x10; p[0x5c] = 0; p[0x5e] = 0
	p[0x3a4] = 0x100000; p[0x2b8] = 0; p[0x2bc] = 0
	p[0x4] = 0x2000000; p[0x8] = 0; p[0xc] = 0
	p[0xe8] = 0x100000; p[0xba] = 0
	return {"p": p}


## test_ad970.gd _fixture("nonspecial_miss") -- teammates off-axis -> corridor miss -> blind polar.
func _build_ad970() -> Dictionary:
	var m := {}
	var ball := {0x1d4: m}
	var tm0 := {0x4: 0x2fa000, 0x8: 0x900000, 0xc: 0, 0x2b8: 0, 0x2c4: 1, 0x2bc: 1}
	var tm1 := {0x4: 0x100000, 0x8: 0x900000, 0xc: 0, 0x2b8: 0, 0x2c4: 2, 0x2bc: 1}
	var roster := [tm0, tm1]
	var gs := {0: roster, 0x2ee: 0}
	var p := {0x18c: m, 0x190: ball, 0x184: gs, 0x188: roster}
	p[0x2c] = 0x13; p[0x30] = 0; p[0x34] = 0
	p[0x54] = 0xd; p[0x58] = 0x10; p[0x5c] = 0
	p[0xe8] = 0x100000; p[0xec] = 0x200000; p[0xba] = 0
	return {"p": p}


## test_adc60.gd _fixture("nonspecial_miss") -- teammates on-axis cleared via BASE off-axis (y huge here).
func _build_adc60() -> Dictionary:
	var m := {}
	var ball := {0x1d4: m}
	var tm0 := {0x4: 0x2fa000, 0x8: 0x900000, 0xc: 0, 0x2b8: 0, 0x2c4: 1, 0x2bc: 1, 0x3a4: 0}
	var tm1 := {0x4: 0x100000, 0x8: 0x900000, 0xc: 0, 0x2b8: 0, 0x2c4: 2, 0x2bc: 1, 0x3a4: 0}
	var roster := [tm0, tm1]
	var gs := {0: roster, 0x2ee: 0, 0x30c: 0}
	var p := {0x18c: m, 0x190: ball, 0x184: gs, 0x188: roster}
	p[0x2c] = 6; p[0x30] = 0; p[0x34] = 0
	p[0x54] = 0xd; p[0x58] = 0x10; p[0x5c] = 0; p[0x4] = 0
	p[0xe8] = 0x100000; p[0xec] = 0x200000; p[0xba] = 0
	return {"p": p}


## test_kick.gd _fixture(v, "base") for the 3 KICK_* variants (g2c/g30 set the guard per cfg).
func _build_kick(g2c: int, g30: int) -> Dictionary:
	var tm0 := {0x2b8: 0, 0x2c4: 0}
	var m := {0x1820: 0x300000, 0x19a0: 0}
	var ball := {0x80: 1, 0x63: 0, 0x20: 0x30000, 0x24: 0x40000, 0x28: 0, 0x70: 100, 0x1d4: m}
	var p := {0x18c: m, 0x190: ball, 0x188: [tm0]}
	p[0x2c] = g2c; p[0x30] = g30; p[0x7c] = 1; p[0x34] = 0
	p[0x2b8] = 0; p[0xb8] = 0x7fff; p[0x39c] = 50; p[0x388] = 50; p[0x54] = 10
	return {"p": p}
