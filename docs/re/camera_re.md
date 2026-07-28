# The simulador CAMERA — the controller object, reversed (corrects two s75 "NOT reversed" rows)

Status: **REVERSED 2026-07-28. The motion is NOT yet ported** — said plainly in §6.

Evidence: `extracted/Premier Manager 98/MANAGER.EXE`, `tools/re/refs/watch-2026-07-28/`,
`app/scripts/Pm98Camera.gd`

Method: Ghidra 12.1.2 headless (`~/ghidra-projects/pm98`, `DecompileAt.java`) on `FUN_005f5850`
/ `FUN_005f5740` / `FUN_005f57a0` / `FUN_005f57e0` / `FUN_005f5800` / `FUN_005f5820` /
`FUN_005f5840` / `FUN_005f6230` / `FUN_005ee080` / `FUN_005ee170` / `FUN_005ee670` /
`FUN_005edfa0` / `FUN_005edf90`, plus `objdump -M intel -b pei-i386` over the display driver at
`0x597906..0x598276` (one function whose frame pointer Ghidra cannot recover).

## 1. The controller object is `matchctx + 0x27f0`

`FUN_00598141` builds two clamp boxes each frame and stores them at `matchctx+0x27fc` and
`matchctx+0x2814` before calling `FUN_005f5850`. `FUN_005f5850` reads those boxes as
`param_1[3..8]` and `param_1[9..0xe]`, i.e. `this + 0x0c` and `this + 0x24`. Both fix
`this = matchctx + 0x27f0`, and every offset the rest of the code uses then lands:

| offset | dwords | field |
|---|---|---|
| `+0x00` / `+0x04` | 0 / 1 | the two shot-path objects (null when no scripted move is running) |
| `+0x08` | 2 | the shot's elapsed time |
| `+0x0c..+0x20` | 3..8 | the LOOK-AT clamp box (min xyz, max xyz) |
| `+0x24..+0x38` | 9..0xe | the EYE clamp box |
| **`+0x3c..+0x44`** | **0xf..0x11** | **the EYE — computed, see §3** |
| `+0x48..+0x50` | 0x12..0x14 | the current eye OFFSET / direction |
| `+0x54..+0x5c` | 0x15..0x17 | its target (`FUN_005f5740` writes BOTH, i.e. it snaps) |
| `+0x60..+0x68` | 0x18..0x1a | the current LOOK-AT |
| `+0x6c..+0x74` | 0x1b..0x1d | its target (`FUN_005f57e0` writes only this, i.e. it lerps) |
| `+0x78` / `+0x7c` | 0x1e / 0x1f | the current / target DISTANCE (`FUN_005f5800` snaps both) |
| `+0x80` / `+0x84` / `+0x88` | 0x20 / 0x21 / 0x22 | the zoom triple (`FUN_005f5820` snaps all three, `FUN_005f5840` only the target) |
| `+0x8c` / `+0x8e` / `+0x90` | 0x23 | **yaw / pitch — computed, see §3** / roll (never written) |
| `+0x92` | — | the mode byte that picks which of the two eye formulas runs |

`FUN_005f6230` then hands `+0x3c` (the eye), `+0x8c`, `+0x8e`, `+0x90` and `+0x88` to
`SetCamera` — which is exactly the call the s75 write-up could not explain.

## 2. ⛔ CORRECTION — "the eye is NOT reversed" was wrong, and so was "yaw is a constant 0"

`handoff-pm98-match-presentation-2026-07-28` recorded two hard blanks:

> **the eye** — ⛔ NOT reversed. `camctrl+0x3c` is zeroed by its ctor `FUN_005f56a0` and a
> disassembly sweep of `0x5d7000..0x5f9000` finds no other writer — yet `FUN_005f6230` passes
> that very address to `SetCamera`.
> **the orientation** — ⛔ NOT reversed.

Both are now read out of the binary, and the reason the sweep missed them is concrete: the
writer is `FUN_005f5850`, and it writes **through a register pointer** (`puVar19 = param_1 +
0xf`, then `*puVar19 = …`), not through a `[reg + 0x3c]` displacement. A disp32 scan cannot
see it. The same is true of the yaw/pitch stores.

`jug_render_spec.md` §5's "yaw/pitch/roll are the constant-0 words `camctrl+0x8c/0x8e/0x90`,
so the view matrix is pure translation" is therefore refuted **twice over**: s75 refuted it
from the game's own rendered frame, and this pass refutes it from the code. Only **roll**
(`+0x90`) is genuinely never written.

## 3. The eye and the orientation, as the engine computes them

Every frame, at the end of `FUN_005f5850`:

```
if (camctrl+0x92 == 0):
    eye = lookAt - dir * distance          # dir = +0x48..+0x50, distance = +0x78
else:
    eye = anchor + dir * distance          # anchor = +0x48..+0x50
eye = clamp(eye, eyeBox)                   # +0x24..+0x38
look = lookAt - eye                        # the vector the camera is pointed along
yaw   = atan2_16(look.x, look.y)           # FUN_005ee080, 65536 = a full circle
pitch = atan2_16(rot_z(look, -yaw).x, look.z)
```

with the fixed-point primitives all 16.16: `FUN_005edfa0` = multiply, `FUN_005edf90` =
divide, `FUN_005ee170` = scale a vec3, `FUN_005ee670` = rotate a vec3's (x, y) about z through
the `DAT_006d31c8` cos LUT, `FUN_005ee080` = `atan2` through the `DAT_006d71c8` arctan LUT
(argument order **x first**).

`FUN_005f5850`'s body before that is the interpolation: each of the direction, the look-at and
the distance steps a fraction of the way from its current value toward its target every frame,
with a straight-line path when the remaining delta is under `0x40000` and an ARC (a yaw lerp
through `FUN_005ee290`/`FUN_005ee670`) when it is larger. `param_1[0]`/`[1]`, when non-null,
override all of it with a scripted two-path shot that samples both paths at the elapsed time
(`FUN_005f3510`) and clears itself when it runs out.

## 4. The bounds, exactly

`FUN_00598141` rebuilds both boxes from the session's own pitch every frame:

| box | x | y | z |
|---|---|---|---|
| LOOK-AT (`+0x27fc`) | `±(halfLen + 0xa0000)` | `±(halfWid + 0xa0000)` | `0x8000 .. 0x2f0000` |
| EYE (`+0x2814`) | `±(halfLen + 0x2e0000)` | `±(halfWid + 0x2e0000)` | `0x8000 .. 0x640000` |

In metres: the look-at may stray 10 m outside the pitch and sit 0.5 m to 47 m up; the eye may
stray 46 m outside it and sit 0.5 m to 100 m up.

## 5. What makes it MOVE

* **The camera MODE is a MATCH OPTIONS setting.** `matchctx+0x17fc = session+0xfe0`, clamped
  into `+0x1800` when under 8, and the driver `switch`es on it to build the eye offset out of
  the pitch constants `matchctx+0x194c` / `+0x1950` / `+0x1960` — eight arms, one per mode.
* **The restart CUT is the goal close-up.** When `matchctx+0x448` is 3, 4, 5, 6 or 7 (the
  restart type) and the tracked actor `matchctx+0x438` is set, the driver places the eye at
  `actor.xy − rot(0x320000)` — 50 m behind him along his own facing — at height `0x60000`
  (6 m), or `0x50000` when the restart is a **GOAL** (`+0x448 == 6`). That is the low angle the
  capture shows.
* **It tracks the ball when the ball is near the tracked actor**: gated on `matchctx+0x461 &
  0x40` with `matchctx+0x444` non-null, and only when the separation is under `0x140000` (20 m).

## 6. The capture agrees — measured, not asserted

The five banked WATCH frames are not the same camera. Taking the grass/hoarding seam (the far
touchline) as the marker, its screen row is:

| frame | `watch_00` | `watch_01` | `watch_02` | `watch_03` | `watch_04` |
|---|---|---|---|---|---|
| seam row | 82 | 65 | 90 | 82 | **0** (all pitch — the goal close-up) |

So the camera translates vertically between frames, and `watch_04` is the cut. The s75 pose fit
(`tools/re/fit_watch_camera.py`, eye (-6.08, -36.02, 18.65) m, vertical residuals ~1e-12 px) was
fitted to `watch_02` alone, so **it is that one instant's camera**, and it is correct for that
instant only.

## 7. ✅ CLOSED 2026-07-28 (s78) — see `camera_motion_re.md`

This section listed three prerequisites for a port. **All three are read out of the image
and the port is built, gated and rendering**: `docs/re/camera_motion_re.md`,
`app/scripts/Pm98CamCtrl.gd`, `app/tests/test_cam_ctrl.gd`.

Two things on THIS page turned out to be wrong and are corrected there:

* **"eight arms, one per mode"** (§5) — the guard is `cmp eax, 0xa / ja` and the jump table
  at `0x59830c` has **eleven** entries. The eight are the compass ring; modes 8 and 9 are
  two low goal-line angles and mode 10 is a free camera.
* **"`eye = lookAt - dir*distance`"** (§3) — `+0x48` is an ANCHOR POINT, not a unit
  direction. The binary normalises `lookAt - anchor` first (`FUN_005ee200`) and `+0x78` is
  the eye's distance **from the look-at**. Read literally, §3's form would put the eye
  kilometres away.

Also newly read there: the interpolation rate is `ftol(dt_ms * 0.003 * 65536.0)`, the arc
path is a polar lerp about the look-at with the angle delta sign-extended to 16 bits, the
look-at box is inset 2 m in X/Y before its clamp, and the restart cut sets a **distance** as
well as a height (9 m, or 5.5 m on a goal).
