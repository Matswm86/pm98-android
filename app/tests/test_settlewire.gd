extends SceneTree
## Wire test for the three ALREADY-PORTED settle leaves now CALLED for real by settle_8680(p, wire=true):
##   * AA4D0 = kick_setup(p, m)              (FUN_005aa4d0, oracle-locked via test_kicksetup.gd)
##   * B8CE0 = select_nearest(gs, 1)         (FUN_005b8ce0, oracle-locked via test_selectactive.gd)
##   * AA870 = _arm2_active_tail(p, 0, rng)  (FUN_005aa870(0), oracle-locked via test_arm2tail.gd)
## This is NOT a fresh emulator oracle (each leaf is already oracle-GREEN standalone). It proves the
## WIRE: that settle_8680's action-gated tail reaches each leaf and calls it under wire=true, that the
## leaf is NOT called under wire=false (trace-only), and that the trace is appended either way -- so the
## bare test_settle selection oracle is unaffected. For B8CE0 and AA870 the wired mutation is compared
## against a DIRECT call of the same leaf on an identical context + same rng seed (self-checking against
## the locked port). Run:
##   ~/godot462 --headless --path app --script res://tests/test_settlewire.gd

const SEED := 0x4d2

var _fail := 0
var _pass := 0


func _init() -> void:
	_test_aa4d0()
	_test_b8ce0()
	_test_aa870()
	print("")
	print("ALL PASS (%d checks)" % _pass if _fail == 0 else "FAILED: %d / %d" % [_fail, _pass + _fail])
	quit(1 if _fail > 0 else 0)


func _ok(cond: bool, msg: String) -> void:
	if cond:
		_pass += 1
	else:
		_fail += 1
		print("  [FAIL] ", msg)


func _trace_has(label: String) -> bool:
	for e in Pm98Movement.settle_trace:
		if e is Array and e.size() > 0 and String(e[0]) == label:
			return true
	return false


# --- AA4D0 = kick_setup ---------------------------------------------------------------------------
# phase 2, p IS the ball controller (ball+0x40 == p), gs+0x215 set -> tail dispatches AA4D0. A preset
# pass target (p+0xb4) lets kick_setup run its full body instead of selecting a receiver.
func _aa4d0_fixture() -> Array:
	var M := {0x448: 2}
	var BALL := {}
	var GS := {0x215: 1}                                   # phase==2 && gs+0x215 -> AA4D0 gate
	var TGT := {}
	var P := {0x18c: M, 0x190: BALL, 0x184: GS, 0x40: 0, 0x2bc: 1, 0xb4: TGT}
	BALL[0x40] = P                                         # p IS the ball controller
	return [P, BALL, TGT]


func _test_aa4d0() -> void:
	var made := _aa4d0_fixture()
	var P: Dictionary = made[0]
	var BALL: Dictionary = made[1]
	var TGT: Dictionary = made[2]
	Pm98Movement.settle_8680(P, true)
	_ok(_trace_has("AA4D0"), "AA4D0 wire: tail records AA4D0")
	_ok(int(P.get(0x80, -1)) == 1, "AA4D0 wire: kick_setup set p+0x80=1 (got %d)" % int(P.get(0x80, -1)))
	_ok(int(P.get(0x84, -1)) == 8, "AA4D0 wire: kick_setup set p+0x84=8")
	_ok(P.get(0xb4, null) == 0, "AA4D0 wire: kick_setup cleared p+0xb4")
	_ok(BALL.get(0x4c, null) == TGT, "AA4D0 wire: controller+0x4c == target")
	_ok(int(BALL.get(0x68, -1)) == 1, "AA4D0 wire: controller+0x68=1")
	_ok(int(BALL.get(0x6c, -1)) == 8, "AA4D0 wire: controller+0x6c=8")

	# wire=false: leaf NOT called, trace still recorded, preset target untouched.
	var made2 := _aa4d0_fixture()
	var P2: Dictionary = made2[0]
	var TGT2: Dictionary = made2[2]
	Pm98Movement.settle_8680(P2, false)
	_ok(_trace_has("AA4D0"), "AA4D0 no-wire: tail still records AA4D0")
	_ok(not P2.has(0x80), "AA4D0 no-wire: kick_setup NOT called (p+0x80 unset)")
	_ok(P2.get(0xb4, null) == TGT2, "AA4D0 no-wire: p+0xb4 untouched")


# --- B8CE0 = select_nearest -----------------------------------------------------------------------
# A valid select_nearest sim-context (this=gs at the binary's call site): one on-pitch player at +x,
# find_in_front=1 cone (facing 0) selects it. gs carries BOTH the input-edge flags (0x214/0x215 clear)
# and the ctx fields select_nearest reads. p is NOT the ball controller and p+0x54 != 0 -> tail B8CE0.
func _b8ce0_gs() -> Dictionary:
	var sm := {0x1614: 0, 0x1618: 0, 0x161c: 0, 0x1644: 0, 0x1650: -1, 0x165c: -1, 0x1664: 0}
	var q0 := {0x2bc: 1, 0x4: 0x10000, 0x8: 0, 0xc: 0, 0x5c: 0, 0x184: {}, 0x18c: sm}
	return {"players": [q0], 0x8: 0, 0x138: sm, 0x168: -1}


func _b8ce0_player(gs: Dictionary) -> Dictionary:
	var M := {0x448: 2}                                    # phase 2 -> branch 2, non-taker, no windup
	var BALL := {}                                         # no 0x40 -> p NOT controller; no 0x4c -> other empty
	return {0x18c: M, 0x190: BALL, 0x184: gs, 0x40: 0, 0x54: 5, 0x2b8: 0}


func _test_b8ce0() -> void:
	# Expected = the locked leaf called directly on an identical context.
	var gs_exp := _b8ce0_gs()
	Pm98Movement.select_nearest(gs_exp, 1)
	var exp_active := int(gs_exp.get(0x168, -99))
	var exp_flag := int((gs_exp["players"][0] as Dictionary).get(0x5c, -99))
	_ok(exp_active == 0, "B8CE0 setup: direct leaf committed active 0 (got %d)" % exp_active)

	var gs := _b8ce0_gs()
	var P := _b8ce0_player(gs)
	Pm98Movement.settle_8680(P, true)
	_ok(_trace_has("B8CE0"), "B8CE0 wire: tail records B8CE0")
	_ok(int(gs.get(0x168, -99)) == exp_active,
		"B8CE0 wire: gs[0x168] %d == direct leaf %d" % [int(gs.get(0x168, -99)), exp_active])
	_ok(int((gs["players"][0] as Dictionary).get(0x5c, -99)) == exp_flag,
		"B8CE0 wire: player active flag matches the leaf")
	_ok(int(P.get(0x54, -99)) == 0, "B8CE0 wire: p+0x54 cleared")

	# wire=false: select_nearest NOT called (gs[0x168] stays -1) but p+0x54 still cleared + trace kept.
	var gs2 := _b8ce0_gs()
	var P2 := _b8ce0_player(gs2)
	Pm98Movement.settle_8680(P2, false)
	_ok(_trace_has("B8CE0"), "B8CE0 no-wire: tail still records B8CE0")
	_ok(int(gs2.get(0x168, -99)) == -1, "B8CE0 no-wire: select_nearest NOT called (gs[0x168] still -1)")
	_ok(int((gs2["players"][0] as Dictionary).get(0x5c, -99)) == 0, "B8CE0 no-wire: player flag untouched")
	_ok(int(P2.get(0x54, -99)) == 0, "B8CE0 no-wire: p+0x54 still cleared (settle's own write)")


# --- AA870 = _arm2_active_tail(p, 0, rng) ---------------------------------------------------------
# Open play (phase 0), action 0x1e (passes the tail guards + the leaf's 0x13/0x1d guard), p IS the ball
# controller (ball+0x40 == p, so the leaf's istack==0 carrier guard holds), gs+0x214 clear (AA4D0 gate
# fails) and gs+0x215 set -> tail dispatches AA870. Branch-2 windup is skipped (action 0x1e not in 0..3),
# so settle draws NO rng before the tail and writes nothing to p ahead of the leaf -- the wired p/ball
# mutation must equal a DIRECT _arm2_active_tail(p, 0, rng) on an identical fixture + same seed.
func _aa870_fixture() -> Array:
	var ctx := {0x2b8: 0, 0x2c4: 0}                        # ctx slot/team 0 -> sVar11 = p[0xb8] (unset = 0)
	var team_struct := {0: ctx}
	var M := {0x448: 0, 0x1820: 0x100000, 0x19a0: 0}       # phase 0 (open play), goal-X scale, orient bit
	var GS := {0x214: 0, 0x215: 1}                         # AA4D0 gate fails (0x214 clear); AA870 gate set
	var BALL := {0x20: 0x6000, 0x24: 0x1000, 0x28: -0x400, 0x4: 0x10000, 0x8: 0x8000, 0xc: -0x2000}
	var P := {
		0x40: 0x1e, 0x2b8: 0,
		0x4: 0, 0x8: 0, 0xc: 0,
		0x20: 0x4000, 0x24: -0x2000, 0x28: 0x800,
		0x34: 0x800, 0x3a0: 40, 0x2bc: 1,
		0x18c: M, 0x190: BALL, 0x184: GS, 0x188: team_struct}
	BALL[0x40] = P                                          # p IS the ball controller
	return [P, BALL]


func _test_aa870() -> void:
	# Expected = the locked leaf called directly on an identical fixture + same seed.
	var made_exp := _aa870_fixture()
	var P_exp: Dictionary = made_exp[0]
	var BALL_exp: Dictionary = made_exp[1]
	var rng_exp = MatchEngine.Pm98Rng.new(SEED)
	Pm98Movement._arm2_active_tail(P_exp, 0, rng_exp)

	var made := _aa870_fixture()
	var P: Dictionary = made[0]
	var BALL: Dictionary = made[1]
	var rng = MatchEngine.Pm98Rng.new(SEED)
	Pm98Movement.settle_8680(P, true, rng)
	_ok(_trace_has("AA870"), "AA870 wire: tail records AA870")
	for off in [0x48, 0x5e, 0x66, 0x80, 0x84, 0x94, 0x98, 0x9c, 0xa0, 0xa4, 0xa8]:
		_ok(int(P.get(off, 0)) == int(P_exp.get(off, 0)),
			"AA870 wire: p+0x%x %d == direct leaf %d" % [off, int(P.get(off, 0)), int(P_exp.get(off, 0))])
	for off in [0x68, 0x6c, 0x9c, 0xa0, 0xa4]:
		_ok(int(BALL.get(off, 0)) == int(BALL_exp.get(off, 0)),
			"AA870 wire: ball+0x%x %d == direct leaf %d" % [off, int(BALL.get(off, 0)), int(BALL_exp.get(off, 0))])
	_ok(rng.state == rng_exp.state, "AA870 wire: rng state %d == direct leaf %d" % [rng.state, rng_exp.state])

	# wire=false: _arm2_active_tail NOT called (p+0x80 stays unset), trace still recorded.
	var made2 := _aa870_fixture()
	var P2: Dictionary = made2[0]
	Pm98Movement.settle_8680(P2, false)
	_ok(_trace_has("AA870"), "AA870 no-wire: tail still records AA870")
	_ok(not P2.has(0x80), "AA870 no-wire: _arm2_active_tail NOT called (p+0x80 unset)")
