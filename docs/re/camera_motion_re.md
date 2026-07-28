# The camera MOTION — the three things `camera_re.md` §7 said a port needed, read out of the image

Status: **CLOSED 2026-07-28 (s78). Ported and driven in the real app.**
Supersedes `camera_re.md` §7 ("Still open — the port").

Evidence: `extracted/Premier Manager 98/MANAGER.EXE` (capstone, decoded per function entry),
`tools/re/refs/watch-2026-07-28/`, `tools/re/refs/cammotion-2026-07-28/`.
Port: `app/scripts/Pm98CamCtrl.gd`. Gate: `app/tests/test_cam_ctrl.gd` (70 checks).

`camera_re.md` §7 listed exactly three prerequisites. All three are below.

## 1. ⛔ FIRST CORRECTION — the mode table has ELEVEN arms, not eight

§5 said "eight arms, one per mode". The guard at `0x597c5c` is `cmp eax, 0xa / ja`, and the
jump table at `0x59830c` has **eleven** entries. The eight §5 counted are the compass ring;
there are two more low angles and a free camera.

The three pitch constants the arms are built from come from `FUN_00593600`:

| field | built at | value |
|---|---|---|
| `matchctx+0x194c` | `0x593724` | a flat **`0x190000`** = 25 m |
| `+0x1950` | `0x59372e` | `matchctx+0x1820` (half LENGTH) **+ 35 m** |
| `+0x1954` / `+0x1958` | `0x593746` / `0x593757` | half length + 15 m (both) |
| `+0x195c` | `0x593769` | half length + 6 m |
| `+0x1960` | `0x59377b` | `matchctx+0x1824` (half WIDTH) **+ 35 m** |
| `+0x1804` | `0x593867` | **`0x1e0000`** = the default distance, 30 m |

and the eleven arms are:

| mode | arm | eye ANCHOR (x, y, z) |
|---|---|---|
| 0 | `0x597c6c` | `(+len, 0, 40 m)` |
| 1 | `0x597c93` | `(+len, +wid, 40 m)` |
| 2 | `0x597cc0` | `(0, +wid, 40 m)` |
| 3 | `0x597ce7` | `(-len, +wid, 40 m)` |
| 4 | `0x597d17` | `(-len, 0, 40 m)` |
| 5 | `0x597d41` | `(-len, -wid, 40 m)` |
| 6 | `0x597d72` | `(0, -wid, 40 m)` |
| 7 | `0x597da7` | `(+len, -wid, 40 m)` |
| 8 | `0x597ddc` | `(matchctx+0x285c, -wid, 30 m)` |
| 9 | `0x597e15` | `(matchctx+0x285c, +wid, 30 m)` |
| 10 | `0x597e3f` | `(+0x1810 + +0x285c, +0x1814 + +0x2860, +0x1818 + +0x2864)` — the free camera |

where `len = halfLen + 35 m`, `wid = halfWid + 35 m`, `40 m = 25 + 15` and `30 m = 25 + 5`.
Modes 0..7 are literally the eight points of the compass around the ground.

## 2. ⛔ SECOND CORRECTION — `+0x48` is an ANCHOR POINT, not a direction

`camera_re.md` §3 wrote the eye as `eye = lookAt - dir*distance`. Read literally that is
wrong: `dir` here is a mode arm, i.e. a point 93 m out and 40 m up, and multiplying it by a
30 m distance would put the eye 2.8 km away. The binary **normalises first**
(`0x5f5de4..0x5f5efe`):

```
delta = clampedLookAt - anchor                       ; the vector from the anchor to the look-at
unit  = delta * 0x10000 / |delta|                    ; FUN_005ee200, an integer divide per axis
scaled = unit * distance                             ; FUN_005ee170
eye   = (camctrl+0x92 == 0) ? lookAt - scaled        ; the ordinary case
                            : anchor + scaled
eye   = clamp(eye, eyeBox)                           ; +0x24..+0x38
```

So `+0x78` is **the eye's distance from the LOOK-AT**, and the anchor only chooses the
direction. That is what makes "50 m behind the actor" with a 5.5 m distance come out as a
tight close-up rather than a distant wide.

`yaw` and `pitch` then follow §3 exactly, and `roll` is still never written.

## 3. The interpolation rates — the `ftol` Ghidra dropped

`FUN_005f5850` @`0x5f5a71`:

```
rate = ftol(dt_ms * 0.003000000003 * 65536.0)
```

both doubles read from `.rdata` (`0x63a098` and `0x63a090`). It is a **fraction, not a
speed**: at a 16 ms frame it is 4.8 %, so every quantity eases exponentially toward its
target. `dt_ms` is the same argument the function accumulates into `+0x08`.

That one rate drives all four interpolations:

| quantity | site | form |
|---|---|---|
| look-at `+0x60` | `0x5f5a86` | `look += (look_t - look) * rate` (`FUN_005ee170`) |
| zoom `+0x80` | `0x5f5abe` | `zoom += (zoom_t - zoom) * rate` |
| distance `+0x78` | `0x5f5cff` | `dist += (dist_t - dist) * rate` |
| anchor `+0x48` | `0x5f5b08` | two paths, below |

**The anchor has two paths and the threshold is `0x40000` (4 m)** (`0x5f5b44` / `0x5f5b58` /
`0x5f5b6c`). When every axis of `anchor_t - anchor` is under it, the whole delta is simply
scaled by the rate. When any axis is over it, the move is an **ARC** (`0x5f5bc2`), and the
arc is a polar lerp taken **relative to the look-at**:

```
cur = anchor   - lookAt ;  tgt = anchor_t - lookAt        (x/y only)
r   = ftol(|cur|)      ;  dr  = (ftol(|tgt|) - r) * rate
a   = atan2_16(cur)    ;  da  = (int16)(atan2_16(tgt) - a) * rate    ; <- sign-extended FIRST
dz  = (anchor_t.z - anchor.z) * rate
anchor.xy = lookAt.xy + rotate(polar(r + dr, a), da)
anchor.z += dz
```

The 16-bit sign extension at `0x5f5c74` is what makes the swing take the short way round
the ground instead of the long one. And because the radius is preserved, a mode change
**orbits** the pitch rather than dragging the camera through the middle of it.

Also read, and small but load-bearing: before the look-at is clamped, its box is **inset by
2 m in X and Y** (`0x5f5d25..0x5f5d36`), Z untouched; and every clamp in this cluster swaps
an inverted min/max pair first rather than trusting the order.

## 4. `+0x438` / `+0x444` / `+0x461` — what the camera tracks, and when

**The ball swing** (`0x597f44..0x598041`), gated on `matchctx+0x461 & 0x40` and a non-null
`matchctx+0x444` (the ball):

```
v = ball(+0x1e0,+0x1e4,+0x1e8) - ball(+4,+8,+0xc)      ; the ball's own travel
d = dot((cos t, sin t), v.xy) where t = atan2_16(v.x, v.y)   ; == the planar magnitude
if d < 0x140000 (20 m):
    look at the ball; anchor = (sign(ball.x)*len, sign(ball.y)*wid, 25 + 9 = 34 m)
    distance = 0x160000 (22 m)
```

`d` is `FUN_005b1260`'s shape exactly — the port already has it as `Pm98Trig.planar_mag` —
so the gate is "the ball is travelling less than 20 m", and the camera goes to **the ball's
own quadrant**.

**The restart cut** (`0x598046..0x598166`), on `matchctx+0x448` in {3,4,5,6,7}, with 6 (a
GOAL) additionally requiring `matchctx+0x19dc == 0`, and a non-null tracked actor
`matchctx+0x438`:

```
anchor = actor.xy - polar(0x320000, actor.facing)     ; 50 m behind him along his own facing
anchor.z = 0x60000 (6 m)   or 0x50000 (5 m) on a GOAL
distance = 0x90000 (9 m)   or 0x58000 (5.5 m) on a GOAL      ; <- NEW, §5 did not have this
```

both **snapped**, not lerped (`FUN_005f5740` / `FUN_005f5800` write current AND target).
The goal's tighter pair is exactly the low close-up `watch_04` shows.

## 5. The port, and what it is verified against

`app/scripts/Pm98CamCtrl.gd` is all of the above in integer 16.16, on `Pm98Trig`'s own LUTs.
`Pm98LiveMatch.camera_state()` feeds it the driver's inputs off the live `matchctx`, and
`MatchSimulador._drive_camera()` runs it once per display frame.

**Verified three ways:**

1. **Arithmetic identities** — 70 checks in `app/tests/test_cam_ctrl.gd`: all eleven arms,
   both clamp boxes, the inset, the rate at three dts, the arc preserving its radius, every
   restart-cut figure, both ball-swing gates, and yaw being the atan2 of the look vector.
2. **Driven on the byte-exact engine** — a real `Pm98LiveMatch`, 120 steps: the camera
   moves, and the eye never leaves the box the driver rebuilds each frame.
3. **Rendered in the real app** under Xvfb + GL (`tools/re/refs/cammotion-2026-07-28/`):
   three frames of a live Man Utd v Liverpool. The grass/hoarding seam sits at rows
   **77 / 79 / 80** — and the original's own five WATCH captures put it at **82 / 65 / 90 /
   82** and 0. Same band, moving frame to frame. That is corroboration, not a pixel match,
   and it is the strongest check these captures can support: they are five unknown instants
   of a live match, so there is no engine state to replay.

## 6. Declared divergences — the honest list

* **The rotation is not applied to the render.** The controller produces the engine's own
  `yaw`/`pitch`, but the app's projection is the axis-aligned reduction `Pm98Camera` was
  FITTED with (residuals ~1e-12 px against `watch_02`). Feeding it an absolute moving pose
  would discard that calibration for one nothing can re-fit. So the controller drives the
  fitted pose **by delta** — which is exactly the vertical translation the captures measure
  — and the rotation stays out. Stated in `Pm98Camera.gd` too, not only here.
* **The camera MODE is a choice, not a read.** `matchctx+0x17fc` comes from `session+0xfe0`,
  a MATCH OPTIONS setting the port's session does not carry (the field reads back
  `0xffffffff`). Mode **6** is used because the capture's hoardings run across the TOP as the
  far touchline, which puts the eye on -Y, and 6 is the only arm that does that.
  `Pm98LiveMatch.DEFAULT_CAMERA_MODE` is that choice; read `+0xfe0` the day a MATCH OPTIONS
  capture exists.
* **The look-at fallback is substituted.** `matchctx+0x1614`, the ball anchor the driver
  falls back to, is a DISPLAY field this port does not model. The ball object's own position
  stands in for it.
* **The scripted shot paths (`+0x00` / `+0x04`) are not modelled.** They override the whole
  interpolation with a canned move. Nothing in the port sets them; `step()` asserts they are
  null so the omission stays visible.
* **`matchctx+0x461 & 0x40` is never set by this port**, so the ball swing never fires here
  even though it is wired and gated.
