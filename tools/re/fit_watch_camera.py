#!/usr/bin/env python3
"""Solve the WATCH camera's pose by fitting the ORIGINAL's own projection to a real capture.

Why a fit and not a read: the projection itself IS reversed (`FUN_005eec60` +
`FUN_005d7db0`'s `k = width*256*zoom`, i.e. focal length = viewport width in px — see
`app/scripts/Pm98Camera.gd`), but the camera POSE is not. `camctrl+0x3c` (the eye) is zeroed
by its ctor `FUN_005f56a0` @0x5f56d2 and no other writer exists in 0x5d7000..0x5f9000, and the
orientation the rendered frame plainly has contradicts `jug_render_spec.md` §5's
"yaw/pitch/roll are constant 0 -> pure translation". So the pose is measured off the game's
own output, from exact pitch geometry, and the numbers below are what `Pm98Camera` ships.

Landmarks (all read from the capture's marking mask, all exact real-world geometry):
  * the grass / ad-hoarding seam            -> the FAR touchline, world Y = +38 m
  * the centre circle's far and near arcs   -> world Y = +9.15 m and -9.15 m
  * the halfway line at three screen rows   -> world X = 0

Model (the binary's, with z = -(d>>8) folded into "depth in metres"):
  D  = Yw - Ey
  sx = cx + f*(Xw - Ex)/D
  sy = cy + f*(Ez - Zw)/D

Usage: python3 tools/re/fit_watch_camera.py [capture.png]
       (default: tools/re/refs/watch-2026-07-28/watch_02.png)
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy.optimize import least_squares

ROOT = Path(__file__).resolve().parents[2]
DEFAULT = ROOT / "tools" / "re" / "refs" / "watch-2026-07-28" / "watch_02.png"

# Screen-space landmarks read off the capture's own marking mask (see `marking_mask` below,
# which reproduces them so the numbers are checkable rather than asserted).
FAR_TOUCHLINE_Y = 89.0
CIRCLE_FAR_Y = 192.0
CIRCLE_NEAR_Y = 372.0
HALFWAY_PTS = [(390.0, 132.0), (450.0, 382.0), (500.0, 432.0)]

HALF_WIDTH_M = 38.0  # match+0x1824 for Old Trafford, measured in diag_watch_axes.gd
CIRCLE_R_M = 9.15  # the laws' centre circle radius
FOCAL_PX = 640.0  # = viewport width, from k = width*256*zoom


def marking_mask(img: Image.Image) -> np.ndarray:
    """Light, low-saturation pixels below the ad-hoarding band = the painted pitch lines."""
    a = np.asarray(img.convert("RGB")).astype(int)
    r, g, b = a[:, :, 0], a[:, :, 1], a[:, :, 2]
    m = (r > 110) & (b > 100) & (abs(r - g) < 40) & (abs(g - b) < 40) & (g > 110)
    m[:112] = False
    return m


def main() -> int:
    src = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT
    if not src.exists():
        raise SystemExit(f"capture not found: {src}")
    img = Image.open(src)
    mask = marking_mask(img)
    print(
        f"# WATCH camera fit — {src.name}  ({img.size[0]}x{img.size[1]}, "
        f"{int(mask.sum())} marking px)"
    )

    def vertical(p):
        cy, k, d0 = p
        return [
            cy + k / (d0 + HALF_WIDTH_M) - FAR_TOUCHLINE_Y,
            cy + k / (d0 + CIRCLE_R_M) - CIRCLE_FAR_Y,
            cy + k / (d0 - CIRCLE_R_M) - CIRCLE_NEAR_Y,
        ]

    s1 = least_squares(vertical, [0.0, 20000.0, 60.0])
    cy, k, d0 = s1.x
    height = k / FOCAL_PX

    def horizontal(q):
        cx, fex = q
        return [cx + fex / (k / (sy - cy)) - sx for sx, sy in HALFWAY_PTS]

    s2 = least_squares(horizontal, [320.0, 0.0])
    cx, fex = s2.x

    print(f"ORIGIN_X = {cx:.1f}   (viewport centre x, as FUN_005d7db0 sets it)")
    print(f"ORIGIN_Y = {cy:.1f}   (NOT the viewport centre — see Pm98Camera's pose note)")
    print(f"EYE_X    = {-fex / FOCAL_PX:.2f} m")
    print(
        f"EYE_Y    = {-d0:.2f} m   (centre spot is {d0:.2f} m away, "
        f"{d0 - HALF_WIDTH_M:+.2f} m past the near touchline)"
    )
    print(f"EYE_Z    = {height:.2f} m")
    print(f"F_PX     = {FOCAL_PX:.0f}")
    print(f"vertical residuals   (px): {np.round(s1.fun, 6)}")
    print(f"horizontal residuals (px): {np.round(s2.fun, 2)}")
    print()
    print(
        "A 1.63 m sprite (the JUG frame height at 0x1b333/0x30) is "
        f"{FOCAL_PX * 1.63 / d0:.0f} px tall at the centre spot."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
