class_name Pm98Camera
extends RefCounted
## The WATCH view's 3/4 camera, in the ORIGINAL's own projection.
##
## ## The projection is reversed, exactly
##
## `FUN_005eec60` is the vertex transform every match-scene draw call goes through. Per world
## point `p` (16.16), against the composed matrix `M` at `camctrl+0x7c` and the screen origin
## `camctrl+0xf0` (which `FUN_005d7db0` sets to the VIEWPORT CENTRE):
##
##     d  = (p·Mcol0 >> 16) + M[9]
##     u  = (p·Mcol1 >> 16) + M[10]
##     v  = (p·Mcol2 >> 16) + M[11]
##     z  = (d & 0xffffff00) == 0 ? -1 : -(d >> 8)
##     sx = origin.x + u / z ,  sy = origin.y + v / z
##
## and the second matrix `SetCamera` composes is a diagonal SCALE `FUN_005eea50(0x10000,k,k)`
## with `k = ftol(width · 0.00390625 · 65536.0) · camctrl+0x88 >> 16` — both doubles read from
## `.rdata` (`0x639ac0`, `0x639ae0`), and `0.00390625 * 65536 = 256`. So `k = width·256·zoom`,
## which after the `>>8` in `z` makes the **focal length exactly the viewport width in pixels**
## (640 at zoom 1.0). That part needs no calibration and is not calibrated here.
##
## ## The camera POSE is measured, not reversed — and that is a correction
##
## `jug_render_spec.md` §5 concluded "yaw/pitch/roll are the constant-0 words `camctrl+0x8c/
## 0x8e/0x90`, so the view matrix is pure translation". **The game's own output contradicts
## that**: a real WATCH capture (`tools/re/refs/watch-2026-07-28/`) looks ACROSS the pitch —
## the ad hoardings run flat along the top as the FAR TOUCHLINE and the halfway line recedes
## from the viewer — so the depth axis is world Y (the width), not world X. A rotation-free
## matrix cannot produce that. Two things therefore remain UNREVERSED, and are stated rather
## than invented:
##   * what writes the eye `camctrl+0x3c` (its ctor `FUN_005f56a0` @0x5f56d2 zeroes it and no
##     other writer exists in 0x5d7000..0x5f9000), and
##   * what supplies the orientation the rendered frame plainly has.
##
## So the POSE below is SOLVED BY FITTING this same projection to the original's own frame —
## three exact pitch landmarks (the far-touchline seam at world Y=+38 m, and the centre
## circle's far and near arcs at Y=±9.15 m), residuals ~1e-12 px. `tools/re/fit_watch_camera.py`
## re-runs the fit from the capture and prints these numbers. It is calibration against source
## output, not a look chosen by hand — but it is a FIT, and it is labelled one.
##
## ## World axes, measured off the byte-exact engine (`tests/diag_watch_axes.gd`)
##   X = pitch LENGTH, goal to goal   (`match+0x1820` = half, 58 m at Old Trafford)
##   Y = pitch WIDTH, touchline to touchline (`match+0x1824` = half, 38 m)
##   Z = height (ball `+0xc` reaches ~4.9 m on a loft)
## all 16.16 fixed point about the centre spot.

## Focal length in pixels = the viewport width (the `k = width*256` result above), at zoom 1.
const F_PX := 640.0
## Screen origin. `cx` lands on the viewport centre exactly as `FUN_005d7db0` sets it; `cy`
## does NOT, and the fit is what says so — see the pose note above.
const ORIGIN_X := 320.4
const ORIGIN_Y := -72.2
## Eye, in metres, from the fit. Y is the depth axis, so the camera sits 36.0 m in front of
## the centre spot — i.e. 2 m BEHIND the near touchline — 18.65 m up and 6.1 m off centre.
const EYE_X := -6.08
const EYE_Y := -36.02
const EYE_Z := 18.65
## Points nearer than this are behind/at the lens; the binary's own guard is the
## `(d & 0xffffff00) == 0 -> z = -1` clamp in FUN_005eec60.
const MIN_DEPTH := 1.0

var eye := Vector3(EYE_X, EYE_Y, EYE_Z)
var origin := Vector2(ORIGIN_X, ORIGIN_Y)
var focal := F_PX


## Depth of a world point along the view axis, in metres. <= 0 means behind the camera.
func depth(world: Vector3) -> float:
	return world.y - eye.y


## Project a world point (metres) to design-space screen pixels. Callers must check
## `depth()` first; a point at or behind the lens is clamped to MIN_DEPTH so a stray
## coordinate cannot produce an infinity that silently paints garbage.
func project(world: Vector3) -> Vector2:
	var d: float = maxf(depth(world), MIN_DEPTH)
	return Vector2(origin.x + focal * (world.x - eye.x) / d,
		origin.y + focal * (eye.z - world.z) / d)


## Pixels per metre at a given depth — the scale a billboard at that depth is drawn at.
func scale_at(d: float) -> float:
	return focal / maxf(d, MIN_DEPTH)


## Convert one of the engine's 16.16 world fields to metres.
static func fx(v: int) -> float:
	return float(v) / 65536.0
