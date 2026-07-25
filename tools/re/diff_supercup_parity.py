#!/usr/bin/env python3
"""Pixel-diff the EUROPEAN SUPERCUP parity shot against the frame it was baked from.

Usage:  python3 tools/re/diff_supercup_parity.py <shot_dir>

The shot is `app/tests/shot_euro_supercup.gd` rendered at exactly 640x480:

    DISPLAY=:4 PM98_SHOT_DIR=<dir> ~/godot462 --rendering-driver opengl3 \\
        --resolution 640x480 --path app --script res://tests/shot_euro_supercup.gd

It reproduces the WITNESSED tie — Borussia D. v F.C. Barcelona, drawn but not played,
leg 1 at Camp Nou and leg 2 at Westfalen — so every static pixel must match.

Reported per region, because the residuals have different causes:
  * title / WINNER band / rail / trophy      -> must be 0 (baked chrome)
  * the venue lines                          -> must be 0 (redrawn, and they land)
  * the club-name and mini-kit cells         -> the font-metric and kit-art gaps that
                                                every screen in this repo carries
  * the barra                                -> the shared header recomposition, whose
                                                residual is IDENTICAL on the already
                                                shipped CompResultScreen shots (3291 px),
                                                so it is not this screen's
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
REF = ROOT / "screenshots" / "wine-captures-2026-07-25-euro-competitions" / "09_comp_supercup.png"

# region -> (x0, y0, x1, y1, must_be_zero)
REGIONS = {
    "title plate": (137, 84, 364, 110, True),
    "leg1 venue": (139, 144, 362, 176, True),
    "leg2 venue": (139, 257, 362, 289, True),
    "leg1 rows": (139, 176, 362, 222, False),
    "leg2 rows": (139, 288, 362, 334, False),
    "WINNER band": (0, 346, 640, 420, True),
    "competition rail": (490, 60, 640, 430, True),
    "trophy column": (0, 60, 137, 430, True),
    "barra": (0, 0, 640, 60, False),
}


def main() -> int:
    shot_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("/tmp")
    shot = shot_dir / "euro_supercup.png"
    if not shot.exists():
        print(f"missing {shot}", file=sys.stderr)
        return 2
    a = np.asarray(Image.open(shot).convert("RGB"), dtype=np.int16)
    b = np.asarray(Image.open(REF).convert("RGB"), dtype=np.int16)[:, :640]
    if a.shape[:2] != (480, 640):
        print(
            f"shot is {a.shape[1]}x{a.shape[0]}, need 640x480 "
            f"(pass --resolution 640x480 on a 640x480 display)",
            file=sys.stderr,
        )
        return 2
    d = np.abs(a - b).max(axis=2) > 8
    hard_fail = False
    for name, (x0, y0, x1, y1, zero) in REGIONS.items():
        n = int(d[y0:y1, x0:x1].sum())
        flag = ""
        if zero and n:
            flag = "  <-- MUST BE 0"
            hard_fail = True
        print(f"  {name:18s} {n:6d}{flag}")
    print(f"  {'TOTAL':18s} {int(d.sum()):6d}")
    return 1 if hard_fail else 0


if __name__ == "__main__":
    raise SystemExit(main())
