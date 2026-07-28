class_name Pm98CamCtrl
extends RefCounted
## EXACT port of the simulador CAMERA CONTROLLER -- `matchctx + 0x27f0` -- and of the
## per-frame driver that feeds it. This is the object `docs/re/camera_re.md` reversed and
## §7 of that document listed as "the port is still open"; the three things §7 said a port
## needed are read out of the image in `docs/re/camera_motion_re.md` and are all here.
##
## Two functions, both integer 16.16 throughout, like the binary:
##   * `step()`      = `FUN_005f5850`, the interpolator -- the tail of every match frame.
##   * `drive()`     = the display driver `0x597906..0x598276`, which each frame rebuilds
##                     both clamp boxes, picks the eye offset off the MATCH OPTIONS camera
##                     mode, swings to the ball, and cuts on a restart.
##
## ## What is NOT modelled, said plainly
##
## `camctrl+0x00` / `+0x04` are two scripted shot PATHS (`FUN_005f3510` samples them and
## `FUN_005f6210` gives their length). When they are non-null they override the whole
## interpolation with a canned move and clear themselves when they run out. Nothing in the
## port ever sets them, so `step()` implements the null branch only -- the branch every
## ordinary frame takes. `_shot_a` / `_shot_b` exist and are asserted null so this stays
## visible rather than silently absent.
##
## Angle unit: 0x10000 = a full circle (`Pm98Trig`). Distance unit: 0x10000 = 1 metre.

# ---- the interpolation rate --------------------------------------------------
## `FUN_005f5850` @0x5f5a71: `ftol(dt_ms * 0.003 * 65536.0)`, the two doubles read from
## .rdata at 0x63a098 (0.003000000003) and 0x63a090 (65536.0). At 60 fps that is 0.05 --
## a 5 %-per-frame exponential ease, NOT a constant speed.
const RATE_PER_MS := 0.003000000003
const RATE_SCALE := 65536.0

## @0x5f5b44 / 0x5f5b58 / 0x5f5b6c: if EVERY axis of (dir_target - dir) is under this, the
## direction takes the straight-line path; otherwise it takes the ARC (a polar lerp).
const ARC_THRESHOLD := 0x40000          # 4 m

## @0x5f5d25..0x5f5d36: the look-at is clamped into the look-at box INSET by this in X and
## Y. Z is not inset.
const LOOKAT_INSET := 0x20000           # 2 m

# ---- the driver's pitch constants (FUN_00593600 @0x593724..) -----------------
## `matchctx+0x194c` is a flat constant; `+0x1950` and `+0x1960` are built from the
## session's own half-length (`matchctx+0x1820`) and half-width (`+0x1824`).
const CAM_BASE_Z := 0x190000            # +0x194c = 25 m
const CAM_OUT_LEN := 0x230000           # +0x1950 = halfLen + 35 m
const CAM_OUT_WID := 0x230000           # +0x1960 = halfWid + 35 m
const CAM_LIFT_HIGH := 0xf0000          # the +15 m the eight compass modes add -> 40 m
const CAM_LIFT_LOW := 0x50000           # the  +5 m modes 8/9 add               -> 30 m
const CAM_LIFT_BALL := 0x90000          # the  +9 m the ball swing adds         -> 34 m
const DIST_DEFAULT := 0x1e0000          # +0x1804 = 30 m (FUN_00593600 @0x593867)
const DIST_BALL := 0x160000             # the ball swing's own distance, 22 m

# ---- the restart cut (driver @0x598094..0x598166) ----------------------------
const CUT_BEHIND := 0x320000            # 50 m behind the tracked actor, along his facing
const CUT_HEIGHT := 0x60000             # 6 m ...
const CUT_HEIGHT_GOAL := 0x50000        # ... or 5 m when the restart is a GOAL
const CUT_DIST := 0x90000               # 9 m ...
const CUT_DIST_GOAL := 0x58000          # ... or 5.5 m on a goal
const RESTART_GOAL := 6
## @0x59804e..0x59808c: the restart types that cut. 6 (a GOAL) additionally requires
## `matchctx+0x19dc` to be zero.
const CUT_RESTARTS := [3, 4, 5, 6, 7]

## @0x597fc8: the ball swing only fires while the ball's own travel is under 20 m.
const BALL_TRAVEL_MAX := 0x140000

## @0x597c5c: the mode index is clamped by `cmp eax, 0xa / ja` -- ELEVEN arms, 0..10.
## `camera_re.md` §5's "eight arms" counted only the compass ring; modes 8 and 9 are the
## two low goal-line angles and mode 10 is the free camera.
const MODE_MAX := 10

# ---- the object's own fields (offsets from matchctx+0x27f0) ------------------
var _shot_a = null                      # +0x00  scripted path A -- never set, see header
var _shot_b = null                      # +0x04  scripted path B
var elapsed := 0                        # +0x08
var lookat_box := [0, 0, 0, 0, 0, 0]    # +0x0c..+0x20  minX minY minZ maxX maxY maxZ
var eye_box := [0, 0, 0, 0, 0, 0]       # +0x24..+0x38
var eye := [0, 0, 0]                    # +0x3c  COMPUTED, never lerped
var dir := [0, 0, 0]                    # +0x48  current ANCHOR point (see _recompute_eye)
var dir_t := [0, 0, 0]                  # +0x54  its target
var look := [0, 0, 0]                   # +0x60  current look-at
var look_t := [0, 0, 0]                 # +0x6c  its target
var dist := 0                           # +0x78
var dist_t := 0                         # +0x7c
var zoom := 0                           # +0x80
var zoom_t := 0                         # +0x84
var zoom_x := 0x10000                   # +0x88  the SetCamera scale factor
var yaw := 0                            # +0x8c  COMPUTED
var pitch := 0                          # +0x8e  COMPUTED
var roll := 0                           # +0x90  never written by anything (camera_re.md §2)
var eye_mode := 0                       # +0x92  picks which eye formula runs


# ---- the four setters the driver calls ---------------------------------------

## `FUN_005f5740(v)`: writes BOTH `+0x48` and `+0x54` -- it SNAPS the anchor.
func snap_dir(v: Array) -> void:
	dir = [int(v[0]), int(v[1]), int(v[2])]
	dir_t = [int(v[0]), int(v[1]), int(v[2])]


## `FUN_005f5780(v)`: writes `+0x54` only -- the anchor LERPS toward `v`.
func aim_dir(v: Array) -> void:
	dir_t = [int(v[0]), int(v[1]), int(v[2])]


## `FUN_005f57a0(v)`: writes `+0x6c` only -- the look-at LERPS.
func aim_look(v: Array) -> void:
	look_t = [int(v[0]), int(v[1]), int(v[2])]


## `FUN_005f57e0(v)`: writes `+0x6c` from a pointer the driver hands it (the tracked
## actor's own xyz, or the ball anchor `matchctx+0x1614`).
func aim_look_at(v: Array) -> void:
	aim_look(v)


## `FUN_005f5800(d)`: snaps BOTH distances (`+0x78`/`+0x7c`) -- the eye's distance FROM
## the look-at, not from the anchor. `FUN_005f5810(d)` sets the target only.
func snap_dist(d: int) -> void:
	dist = d
	dist_t = d


func aim_dist(d: int) -> void:
	dist_t = d


# ---- FUN_005f5850, the interpolator -----------------------------------------

## The per-frame rate, exactly as the binary computes it: `ftol(dt * 0.003 * 65536.0)`.
## `ftol` truncates toward zero, which `int()` reproduces.
static func rate_for(dt_ms: int) -> int:
	return int(float(dt_ms) * RATE_PER_MS * RATE_SCALE)


## One frame of interpolation. `dt_ms` is the frame's own elapsed milliseconds -- the
## binary's `[esp+0x6c]` argument, which it also accumulates into `+0x08`.
func step(dt_ms: int) -> void:
	assert(_shot_a == null and _shot_b == null,
		"scripted camera shots are not modelled -- see the header")
	var rate := rate_for(dt_ms)
	elapsed += dt_ms

	# --- the DIRECTION -------------------------------------------------------
	# @0x5f5b08: nothing to do at all when current == target on every axis.
	if dir != dir_t:
		var near: bool = absi(int(dir[0]) - int(dir_t[0])) < ARC_THRESHOLD \
			and absi(int(dir[1]) - int(dir_t[1])) < ARC_THRESHOLD \
			and absi(int(dir[2]) - int(dir_t[2])) < ARC_THRESHOLD
		if near:
			# @0x5f5b80: the straight line -- scale the whole delta by the rate.
			var d := Pm98Trig.scale_vec3(int(dir_t[0]) - int(dir[0]), int(dir_t[1]) - int(dir[1]),
				int(dir_t[2]) - int(dir[2]), rate)
			dir = [Pm98Trig._i32(int(dir[0]) + int(d[0])),
				Pm98Trig._i32(int(dir[1]) + int(d[1])),
				Pm98Trig._i32(int(dir[2]) + int(d[2]))]
		else:
			# @0x5f5bc2: the ARC. Both the current and the target offset are taken
			# RELATIVE TO THE LOOK-AT, turned into (radius, heading), and lerped in
			# polar -- which is what swings the camera around the pitch instead of
			# dragging it across the middle.
			var cx: int = dir[0] - look[0]
			var cy: int = dir[1] - look[1]
			var tx: int = dir_t[0] - look[0]
			var ty: int = dir_t[1] - look[1]
			var r_cur := Pm98Trig._dist3(cx, cy, 0)
			var r_tgt := Pm98Trig._dist3(tx, ty, 0)
			var dr := Pm98Trig.mul16(r_tgt - r_cur, rate)
			var a_cur := Pm98Trig.atan_angle(cx, cy)
			var a_tgt := Pm98Trig.atan_angle(tx, ty)
			# @0x5f5c74: the angle delta is sign-extended to 16 bits BEFORE scaling,
			# which is what makes the swing take the short way round.
			var da := Pm98Trig._asr(Pm98Trig._s16(a_tgt - a_cur) * rate, 16)
			var dz := Pm98Trig.mul16(int(dir_t[2]) - int(dir[2]), rate)
			var v := Pm98Trig.polar_vec(r_cur + dr, a_cur)
			var rv := Pm98Trig.rotate_vec(int(v[0]), int(v[1]), da)
			dir = [Pm98Trig._i32(int(look[0]) + int(rv[0])),
				Pm98Trig._i32(int(look[1]) + int(rv[1])),
				Pm98Trig._i32(int(dir[2]) + dz)]

	# --- the DISTANCE (@0x5f5cff) --------------------------------------------
	dist = Pm98Trig._i32(dist + Pm98Trig.mul16(dist_t - dist, rate))

	# --- the LOOK-AT (@0x5f5a86) ---------------------------------------------
	var ld := Pm98Trig.scale_vec3(int(look_t[0]) - int(look[0]), int(look_t[1]) - int(look[1]),
		int(look_t[2]) - int(look[2]), rate)
	look = [Pm98Trig._i32(int(look[0]) + int(ld[0])),
		Pm98Trig._i32(int(look[1]) + int(ld[1])),
		Pm98Trig._i32(int(look[2]) + int(ld[2]))]
	# and the ZOOM, on the same rate (@0x5f5abe).
	zoom = Pm98Trig._i32(zoom + Pm98Trig.mul16(zoom_t - zoom, rate))

	# --- the look-at CLAMP (@0x5f5d19) ---------------------------------------
	# The box is inset by 2 m in X and Y before the clamp, and the binary swaps any
	# pair whose min ended up above its max rather than trusting the order.
	look = _clamp_box(look, _inset(lookat_box, LOOKAT_INSET))

	# --- the EYE and the ORIENTATION (camera_re.md §3) -----------------------
	_recompute_eye()


## The eye and the two written angles, from `FUN_005f5850`'s tail (@0x5f5de4..0x5f5fd0).
## The eye is DERIVED every frame and never stored between frames, which is exactly why a
## displacement sweep for a writer of `+0x3c` found none (`camera_re.md` §2).
##
## ⚠ `+0x48` is an ANCHOR POINT, not a unit direction -- `camera_re.md` §3's
## "`eye = lookAt - dir*distance`" reads as if it were a direction, and at the values the
## mode table actually produces (a point 93 m out and 40 m up) that product would be
## astronomical. What the binary does is normalise FIRST:
##
##     delta = clampedLookAt - anchor
##     unit  = delta * 0x10000 / |delta|          (FUN_005ee200, an integer divide)
##     eye   = (mode == 0) ? lookAt - unit*dist   (FUN_005ee170 = scale_vec3)
##                         : anchor + unit*dist
##
## so `+0x78` is the eye's distance FROM the look-at along the anchor's line, and the
## anchor only picks the direction. That is what makes a 50 m-behind-the-actor anchor with
## a 5.5 m distance come out as the tight goal close-up `watch_04` shows.
func _recompute_eye() -> void:
	var dx: int = look[0] - dir[0]
	var dy: int = look[1] - dir[1]
	var dz: int = look[2] - dir[2]
	var unit := [0, 0, 0]
	if dx != 0 or dy != 0 or dz != 0:
		var l := Pm98Trig._dist3(dx, dy, dz)
		if l != 0:
			unit = [Pm98Trig.ratio16(dx, l), Pm98Trig.ratio16(dy, l),
				Pm98Trig.ratio16(dz, l)]
	var s := Pm98Trig.scale_vec3(int(unit[0]), int(unit[1]), int(unit[2]), dist)
	var e: Array
	if eye_mode == 0:
		e = [int(look[0]) - int(s[0]), int(look[1]) - int(s[1]), int(look[2]) - int(s[2])]
	else:
		e = [int(dir[0]) + int(s[0]), int(dir[1]) + int(s[1]), int(dir[2]) + int(s[2])]
	eye = _clamp_box(e, eye_box)
	var lx: int = look[0] - eye[0]
	var ly: int = look[1] - eye[1]
	var lz: int = look[2] - eye[2]
	yaw = Pm98Trig.atan_angle(lx, ly)
	var flat := Pm98Trig.rotate_vec(lx, ly, -yaw)
	pitch = Pm98Trig.atan_angle(int(flat[0]), lz)


## Grow a box's minima and shrink its maxima in X and Y only (@0x5f5d25..0x5f5d36).
static func _inset(box: Array, by: int) -> Array:
	return [int(box[0]) + by, int(box[1]) + by, int(box[2]),
		int(box[3]) - by, int(box[4]) - by, int(box[5])]


## Clamp a point into a box, swapping any inverted pair first -- the binary does the
## same three compare-and-swap pairs before every clamp (@0x5f5d4a / 0x598199 / 0x598217).
static func _clamp_box(p: Array, box: Array) -> Array:
	var out := []
	for i in 3:
		var lo: int = box[i]
		var hi: int = box[i + 3]
		if lo > hi:
			var t := lo
			lo = hi
			hi = t
		out.append(clampi(int(p[i]), lo, hi))
	return out


# ---- the driver, 0x597906..0x598276 -----------------------------------------

## The eleven camera-mode eye OFFSETS, as the jump table at 0x59830c builds them.
## `half_len` / `half_wid` are `matchctx+0x1820` / `+0x1824`; `free` is the mode-10
## triple `(+0x1810+ +0x285c, +0x1814+ +0x2860, +0x1818+ +0x2864)` and `pan_x` is
## `matchctx+0x285c`, which modes 8 and 9 use as their X.
##
## Modes 0..7 are the eight points of the compass around the pitch at 25 + 15 = 40 m;
## 8 and 9 are the two goal-line angles at 25 + 5 = 30 m; 10 is the free camera.
static func mode_offset(mode: int, half_len: int, half_wid: int, pan_x: int,
		free: Array) -> Array:
	var out_len := half_len + CAM_OUT_LEN
	var out_wid := half_wid + CAM_OUT_WID
	var high := CAM_BASE_Z + CAM_LIFT_HIGH
	var low := CAM_BASE_Z + CAM_LIFT_LOW
	match clampi(mode, 0, MODE_MAX):
		0: return [out_len, 0, high]
		1: return [out_len, out_wid, high]
		2: return [0, out_wid, high]
		3: return [-out_len, out_wid, high]
		4: return [-out_len, 0, high]
		5: return [-out_len, -out_wid, high]
		6: return [0, -out_wid, high]
		7: return [out_len, -out_wid, high]
		8: return [pan_x, -out_wid, low]
		9: return [pan_x, out_wid, low]
		_: return [int(free[0]), int(free[1]), int(free[2])]


## The ball-side swing (@0x597fe0). The camera goes to the ball's OWN quadrant: the sign
## of each axis is the sign of the ball's coordinate on that axis, at 25 + 9 = 34 m.
static func ball_offset(ball_x: int, ball_y: int, half_len: int, half_wid: int) -> Array:
	var sx := 1 if ball_x >= 0 else -1
	var sy := 1 if ball_y >= 0 else -1
	return [(half_len + CAM_OUT_LEN) * sx, (half_wid + CAM_OUT_WID) * sy,
		CAM_BASE_Z + CAM_LIFT_BALL]


## Does the ball swing fire? @0x597f44: only with `matchctx+0x461 & 0x40` set, a non-null
## `matchctx+0x444` (the ball), and the ball's own travel under 20 m. The travel is
## `ball+0x1e0..+0x1e8` minus `ball+4..+0xc`, and the magnitude the binary takes is the
## atan2-then-dot form -- `Pm98Trig.planar_mag`, which IS that computation.
static func ball_swing_due(flags: int, travel_x: int, travel_y: int) -> bool:
	if (flags & 0x40) == 0:
		return false
	return Pm98Trig.planar_mag(travel_x, travel_y) < BALL_TRAVEL_MAX


## The restart CUT (@0x598094). `restart` is `matchctx+0x448`, `blocked` is the extra
## `matchctx+0x19dc != 0` condition that suppresses the cut on a GOAL only.
static func cut_due(restart: int, blocked: bool) -> bool:
	if not CUT_RESTARTS.has(restart):
		return false
	if restart == RESTART_GOAL and blocked:
		return false
	return true


## Where the cut puts the eye offset: 50 m behind the tracked actor along his own facing
## (`actor+0x34`), at 6 m -- or 5 m when the restart is a goal.
static func cut_offset(actor_x: int, actor_y: int, facing: int, restart: int) -> Array:
	var back := Pm98Trig.polar_vec(CUT_BEHIND, facing)
	var z := CUT_HEIGHT_GOAL if restart == RESTART_GOAL else CUT_HEIGHT
	return [actor_x - int(back[0]), actor_y - int(back[1]), z]


static func cut_distance(restart: int) -> int:
	return CUT_DIST_GOAL if restart == RESTART_GOAL else CUT_DIST


## The two clamp boxes, rebuilt every frame from the session's own pitch (@0x59816b and
## @0x5981f1). `camera_re.md` §4 already carried these figures; they are here so the
## controller is self-contained and so the swap-if-inverted the binary does is kept.
static func look_box(half_len: int, half_wid: int) -> Array:
	return [-0xa0000 - half_len, -0xa0000 - half_wid, 0x8000,
		half_len + 0xa0000, half_wid + 0xa0000, 0x2f0000]


static func eye_box_for(half_len: int, half_wid: int) -> Array:
	return [-0x2e0000 - half_len, -0x2e0000 - half_wid, 0x8000,
		half_len + 0x2e0000, half_wid + 0x2e0000, 0x640000]


## One driver frame, in the binary's own order.
##
## `state` carries what the driver reads out of `matchctx`:
##   half_len / half_wid   +0x1820 / +0x1824
##   mode                  +0x17fc  (the MATCH OPTIONS setting, `session+0xfe0`)
##   look_target           the tracked actor's xyz, or the ball anchor +0x1614
##   pan_x, free           +0x285c and the mode-10 triple
##   ball                  {x, y, travel_x, travel_y} or {} when +0x444 is null
##   flags                 +0x461
##   restart               +0x448
##   restart_blocked       +0x19dc != 0
##   actor                 {x, y, facing} or {} when +0x438 is null
func drive(state: Dictionary, dt_ms: int) -> void:
	var half_len := int(state.get("half_len", 0))
	var half_wid := int(state.get("half_wid", 0))

	aim_look_at(state.get("look_target", [0, 0, 0]))
	aim_dir(mode_offset(int(state.get("mode", 0)), half_len, half_wid,
		int(state.get("pan_x", 0)), state.get("free", [0, 0, 0])))
	aim_dist(int(state.get("distance", DIST_DEFAULT)))

	var ball: Dictionary = state.get("ball", {})
	if not ball.is_empty() and ball_swing_due(int(state.get("flags", 0)),
			int(ball.get("travel_x", 0)), int(ball.get("travel_y", 0))):
		aim_look_at([int(ball.get("x", 0)), int(ball.get("y", 0)), int(ball.get("z", 0))])
		aim_dir(ball_offset(int(ball.get("x", 0)), int(ball.get("y", 0)),
			half_len, half_wid))
		aim_dist(DIST_BALL)

	var actor: Dictionary = state.get("actor", {})
	var restart := int(state.get("restart", -1))
	if not actor.is_empty() and cut_due(restart, bool(state.get("restart_blocked", false))):
		snap_dir(cut_offset(int(actor.get("x", 0)), int(actor.get("y", 0)),
			int(actor.get("facing", 0)), restart))
		snap_dist(cut_distance(restart))

	lookat_box = look_box(half_len, half_wid)
	eye_box = eye_box_for(half_len, half_wid)
	step(dt_ms)


## Seed the controller so its first frame is already settled rather than easing in from
## the origin -- the binary reaches the same state because the driver runs from kick-off.
func settle(state: Dictionary) -> void:
	var half_len := int(state.get("half_len", 0))
	var half_wid := int(state.get("half_wid", 0))
	lookat_box = look_box(half_len, half_wid)
	eye_box = eye_box_for(half_len, half_wid)
	var lt: Array = state.get("look_target", [0, 0, 0])
	look = [int(lt[0]), int(lt[1]), int(lt[2])]
	look_t = look.duplicate()
	snap_dir(mode_offset(int(state.get("mode", 0)), half_len, half_wid,
		int(state.get("pan_x", 0)), state.get("free", [0, 0, 0])))
	snap_dist(int(state.get("distance", DIST_DEFAULT)))
	_recompute_eye()
