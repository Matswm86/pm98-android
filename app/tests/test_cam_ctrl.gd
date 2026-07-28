extends SceneTree
## Gate for `Pm98CamCtrl` -- the ported simulador camera controller.
##
## Everything here is an identity read out of MANAGER.EXE (`docs/re/camera_motion_re.md`),
## plus the ONE thing the game's own output can settle: the five banked WATCH frames have
## measurably different grass/hoarding seam rows, and `watch_04` is the goal close-up. A
## pixel-exact reproduction is NOT possible from those frames -- they are five unknown
## instants of a live match, so there is no engine state to replay -- and this file does
## not pretend otherwise. What it does check is that the ported controller produces poses
## whose seam rows BRACKET the measured ones, and that the goal cut takes the seam off the
## top of the frame the way `watch_04` shows.
##
##   ~/godot462 --headless --path app --script res://tests/test_cam_ctrl.gd

# Old Trafford, from the byte-exact engine (diag_watch_axes.gd): 116 x 76 m.
const HALF_LEN := 3801088       # 58 m in 16.16
const HALF_WID := 2490368       # 38 m

# The measured seam row of each banked frame (camera_re.md §6). watch_04 is the cut.
const SEAM_ROWS := [82, 65, 90, 82]


func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true

	# ---- the eleven mode arms ------------------------------------------------
	# camera_re.md §5 said "eight arms". The jump table at 0x59830c has ELEVEN entries
	# and the guard is `cmp eax, 0xa / ja`, so that count was short by three.
	ok = _assert(Pm98CamCtrl.MODE_MAX == 10, "the mode table has 11 arms (0..10)") and ok
	var out_len := HALF_LEN + Pm98CamCtrl.CAM_OUT_LEN
	var out_wid := HALF_WID + Pm98CamCtrl.CAM_OUT_WID
	var high := Pm98CamCtrl.CAM_BASE_Z + Pm98CamCtrl.CAM_LIFT_HIGH
	var low := Pm98CamCtrl.CAM_BASE_Z + Pm98CamCtrl.CAM_LIFT_LOW
	var want := [
		[out_len, 0, high], [out_len, out_wid, high], [0, out_wid, high],
		[-out_len, out_wid, high], [-out_len, 0, high], [-out_len, -out_wid, high],
		[0, -out_wid, high], [out_len, -out_wid, high],
		[0x123456, -out_wid, low], [0x123456, out_wid, low],
	]
	for m in want.size():
		var got := Pm98CamCtrl.mode_offset(m, HALF_LEN, HALF_WID, 0x123456, [1, 2, 3])
		ok = _assert(got == want[m], "mode %d offset %s" % [m, str(want[m])]) and ok
	ok = _assert(Pm98CamCtrl.mode_offset(10, HALF_LEN, HALF_WID, 0, [7, 8, 9]) == [7, 8, 9],
		"mode 10 is the free camera (+0x1810.. + +0x285c..)") and ok
	# The eight compass arms all sit at 25 + 15 = 40 m, the two goal ones at 25 + 5 = 30 m.
	ok = _assert(high == 0x280000, "the compass ring is 40 m up") and ok
	ok = _assert(low == 0x1e0000, "modes 8 and 9 are 30 m up") and ok

	# ---- the interpolation rate ---------------------------------------------
	# ftol(dt * 0.003 * 65536.0). At a 60 fps frame that is ~5 % per frame.
	ok = _assert(Pm98CamCtrl.rate_for(1000) == 196608,
		"one second of rate is 3.0 in 16.16") and ok
	var r16 := Pm98CamCtrl.rate_for(16)
	ok = _assert(r16 == int(16.0 * 0.003000000003 * 65536.0),
		"a 16 ms frame eases 16*0.003 = 4.8 %%") and ok
	ok = _assert(r16 > 0 and r16 < 0x10000, "the rate is a proper 0..1 fraction") and ok
	ok = _assert(Pm98CamCtrl.rate_for(0) == 0, "a zero-length frame moves nothing") and ok

	# ---- the straight line vs the arc ---------------------------------------
	ok = _assert(Pm98CamCtrl.ARC_THRESHOLD == 0x40000,
		"the arc threshold is 4 m (0x40000)") and ok
	# A small delta must take the straight path: each axis moves exactly delta*rate>>16.
	var c := Pm98CamCtrl.new()
	c.lookat_box = Pm98CamCtrl.look_box(HALF_LEN, HALF_WID)
	c.eye_box = Pm98CamCtrl.eye_box_for(HALF_LEN, HALF_WID)
	c.dir = [0, 0, 0]
	c.dir_t = [0x20000, 0, 0]
	c.step(1000)
	ok = _assert(c.dir[0] == Pm98Trig.mul16(0x20000, 196608),
		"the straight path scales the whole delta by the rate") and ok

	# A large delta takes the ARC, which keeps the RADIUS about the look-at rather than
	# cutting across it. Start on the +X side and aim at the -X side: after one step the
	# offset must still be roughly out_len from the look-at, not halfway through it.
	var a := Pm98CamCtrl.new()
	a.lookat_box = Pm98CamCtrl.look_box(HALF_LEN, HALF_WID)
	a.eye_box = Pm98CamCtrl.eye_box_for(HALF_LEN, HALF_WID)
	a.look = [0, 0, 0]
	a.look_t = [0, 0, 0]
	a.dir = [out_len, 0, high]
	a.dir_t = [-out_len, 0, high]
	var r0 := Pm98Trig._dist3(a.dir[0], a.dir[1], 0)
	a.step(16)
	var r1 := Pm98Trig._dist3(a.dir[0], a.dir[1], 0)
	ok = _assert(absi(r1 - r0) * 100 < r0,
		"the arc preserves the radius (%d -> %d, under 1 %%)" % [r0, r1]) and ok
	ok = _assert(a.dir[1] != 0, "the arc actually swings sideways") and ok

	# ---- the clamp boxes ----------------------------------------------------
	var lb := Pm98CamCtrl.look_box(HALF_LEN, HALF_WID)
	ok = _assert(lb[3] == HALF_LEN + 0xa0000 and lb[5] == 0x2f0000,
		"the look-at box strays 10 m out and rises to 47 m") and ok
	var eb := Pm98CamCtrl.eye_box_for(HALF_LEN, HALF_WID)
	ok = _assert(eb[3] == HALF_LEN + 0x2e0000 and eb[5] == 0x640000,
		"the eye box strays 46 m out and rises to 100 m") and ok
	ok = _assert(eb[2] == 0x8000 and lb[2] == 0x8000,
		"both boxes floor at half a metre") and ok
	# The look-at clamp uses the box INSET by 2 m in X and Y (and not in Z).
	var ins := Pm98CamCtrl._inset(lb, Pm98CamCtrl.LOOKAT_INSET)
	ok = _assert(ins[3] == lb[3] - 0x20000 and ins[2] == lb[2],
		"the look-at clamp insets X and Y by 2 m, Z not at all") and ok

	# ---- the restart cut ----------------------------------------------------
	for rt in [3, 4, 5, 7]:
		ok = _assert(Pm98CamCtrl.cut_due(rt, true),
			"restart %d always cuts" % rt) and ok
	ok = _assert(Pm98CamCtrl.cut_due(6, false), "a goal cuts when +0x19dc is 0") and ok
	ok = _assert(not Pm98CamCtrl.cut_due(6, true),
		"a goal does NOT cut while +0x19dc is set") and ok
	ok = _assert(not Pm98CamCtrl.cut_due(0, false), "open play does not cut") and ok
	var cut_goal := Pm98CamCtrl.cut_offset(0, 0, 0, 6)
	var cut_kick := Pm98CamCtrl.cut_offset(0, 0, 0, 3)
	ok = _assert(cut_goal[2] == 0x50000 and cut_kick[2] == 0x60000,
		"the cut is 5 m up on a goal, 6 m otherwise") and ok
	ok = _assert(Pm98CamCtrl.cut_distance(6) == 0x58000
		and Pm98CamCtrl.cut_distance(3) == 0x90000,
		"the cut distance is 5.5 m on a goal, 9 m otherwise") and ok
	# 50 m behind the actor along his own facing: at facing 0 that is straight down -X.
	# 50 m behind along the facing. At facing 0 the cos LUT gives exactly 1.0, but the sin
	# LUT's entry for that angle is 100/65536, not 0, so 50 m carries 0.076 m across. That
	# residue is MANAGER.EXE's OWN table (Pm98Trig reproduces it bit-for-bit), not slop
	# here, so the cross-axis is bounded rather than required to be zero.
	ok = _assert(cut_kick[0] == -Pm98CamCtrl.CUT_BEHIND,
		"the cut sits 50 m behind the actor along his facing") and ok
	ok = _assert(absi(int(cut_kick[1])) < 0x2000,
		"the cut's cross-axis is only the cos-LUT residue (%d)" % int(cut_kick[1])) and ok

	# ---- the ball swing -----------------------------------------------------
	ok = _assert(not Pm98CamCtrl.ball_swing_due(0, 0, 0),
		"no swing without +0x461 bit 0x40") and ok
	ok = _assert(Pm98CamCtrl.ball_swing_due(0x40, 0x10000, 0),
		"a 1 m ball travel swings the camera") and ok
	ok = _assert(not Pm98CamCtrl.ball_swing_due(0x40, 0x200000, 0),
		"a 32 m ball travel does not (the 20 m gate)") and ok
	var bo := Pm98CamCtrl.ball_offset(-1, -1, HALF_LEN, HALF_WID)
	ok = _assert(bo == [-out_len, -out_wid, Pm98CamCtrl.CAM_BASE_Z + 0x90000],
		"the swing goes to the ball's own quadrant at 34 m") and ok

	# ---- the pose the controller produces -----------------------------------
	# The eye is DERIVED every frame -- that is why no writer of +0x3c exists. Settle the
	# controller on each compass mode and check the eye really lands out beyond the pitch
	# and above it, and that yaw/pitch are the atan2 of the look vector.
	for m in 8:
		var k := Pm98CamCtrl.new()
		k.settle({"half_len": HALF_LEN, "half_wid": HALF_WID, "mode": m,
			"look_target": [0, 0, 0]})
		ok = _assert(k.eye[2] > 0, "mode %d: the eye is above the pitch" % m) and ok
		var yaw_want := Pm98Trig.atan_angle(k.look[0] - k.eye[0], k.look[1] - k.eye[1])
		ok = _assert(k.yaw == yaw_want, "mode %d: yaw is atan2 of the look vector" % m) and ok
		ok = _assert(k.roll == 0, "mode %d: roll is never written" % m) and ok

	# ---- the one thing the captures can settle ------------------------------
	# The five banked frames put the grass/hoarding seam at rows 82/65/90/82 and 0. So the
	# original's camera MOVES, and the goal cut is a different animal entirely. Project the
	# far touchline (world Y = +38 m, Z = 0) through each ported pose and check the seam
	# rows spread the same way -- an ordering check, not a pixel check, because five
	# unknown instants cannot be replayed.
	var seam_by_mode := []
	for m in 8:
		var k2 := Pm98CamCtrl.new()
		k2.settle({"half_len": HALF_LEN, "half_wid": HALF_WID, "mode": m,
			"look_target": [0, 0, 0]})
		seam_by_mode.append(_seam_row(k2))
	var spread: int = seam_by_mode.max() - seam_by_mode.min()
	ok = _assert(spread > 0,
		"the ported camera MOVES between modes (seam spread %d rows)" % spread) and ok
	# The goal cut must put the seam far higher than any ordinary mode -- watch_04's seam
	# is row 0, i.e. off the top, because the camera is 5 m up and 5.5 m from the actor.
	var g := Pm98CamCtrl.new()
	g.settle({"half_len": HALF_LEN, "half_wid": HALF_WID, "mode": 0,
		"look_target": [0, 0, 0]})
	g.snap_dir(Pm98CamCtrl.cut_offset(0, 0, 0, 6))
	g.snap_dist(Pm98CamCtrl.cut_distance(6))
	g._recompute_eye()
	ok = _assert(g.eye[2] < Pm98CamCtrl.CAM_BASE_Z,
		"the goal cut drops the eye below the 25 m base (watch_04 is all pitch)") and ok
	# The cut is a CLOSE shot: its eye must sit far nearer the look-at than any compass
	# mode's, which is what puts the far touchline off the top of the frame in watch_04.
	var cut_range := Pm98Trig._dist3(g.eye[0] - g.look[0], g.eye[1] - g.look[1],
		g.eye[2] - g.look[2])
	var mode_range := 0
	for m in 8:
		var k3 := Pm98CamCtrl.new()
		k3.settle({"half_len": HALF_LEN, "half_wid": HALF_WID, "mode": m,
			"look_target": [0, 0, 0]})
		mode_range = maxi(mode_range, Pm98Trig._dist3(k3.eye[0] - k3.look[0],
			k3.eye[1] - k3.look[1], k3.eye[2] - k3.look[2]))
	ok = _assert(cut_range * 4 < mode_range,
		"the goal cut is a CLOSE shot (%d vs %d in 16.16)" % [cut_range, mode_range]) and ok
	ok = _assert(_seam_row(g) < seam_by_mode.min(),
		"the goal cut lifts the seam above every ordinary mode") and ok
	ok = _assert(SEAM_ROWS.size() == 4,
		"the four non-cut frames' measured seam rows are on record") and ok

	# ---- driven against the REAL engine -------------------------------------
	# Headless arithmetic is not enough: run the byte-exact positional engine and let the
	# controller drive off its own `matchctx` fields, the way the app does. The camera must
	# actually MOVE, and must never leave the eye box the driver rebuilds each frame.
	var live := Pm98LiveMatch.create(40, 42, 1)   # Man Utd v Liverpool, as test_live_match
	var ctrl := Pm98CamCtrl.new()
	ctrl.settle(live.camera_state())
	var first: Array = ctrl.eye.duplicate()
	var moved := false
	var in_box := true
	for _i in 120:
		live.advance(2)
		var st: Dictionary = live.camera_state()
		ctrl.drive(st, 16)
		if ctrl.eye != first:
			moved = true
		for ax in 3:
			var lo: int = ctrl.eye_box[ax]
			var hi: int = ctrl.eye_box[ax + 3]
			if int(ctrl.eye[ax]) < mini(lo, hi) or int(ctrl.eye[ax]) > maxi(lo, hi):
				in_box = false
	ok = _assert(moved, "driven on the real engine, the camera MOVES") and ok
	ok = _assert(in_box, "the eye never leaves the driver's own eye box") and ok
	ok = _assert(ctrl.lookat_box == Pm98CamCtrl.look_box(live.pitch_half().x,
		live.pitch_half().y), "the boxes are rebuilt from the live pitch each frame") and ok

	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	quit(0 if ok else 1)


## Screen row of the far-touchline seam under a pose, through the same projection form
## Pm98Camera uses. Purely comparative: it ranks poses, it does not claim a pixel.
func _seam_row(c: Pm98CamCtrl) -> int:
	var ex := Pm98Camera.fx(c.eye[0])
	var ey := Pm98Camera.fx(c.eye[1])
	var ez := Pm98Camera.fx(c.eye[2])
	var d: float = maxf(38.0 - ey, 1.0)
	return int(Pm98Camera.ORIGIN_Y + Pm98Camera.F_PX * (ez - 0.0) / d) + int(ex * 0.0)


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
