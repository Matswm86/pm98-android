#!/usr/bin/env python3
"""Render-diff the ported ROLE popup against MANAGER.EXE's own frame.

    DISPLAY=:1 PM98_SHOT_DIR=out ~/godot462 --rendering-driver opengl3 --path app \\
        --script res://tests/shot_role_popup.gd
    python3 tools/re/diff_role_popup_parity.py app/out/rolepopup_bergsson.png

The chrome — popup frame, striped title bar, item backgrounds, separators and all 18
camrol pitch icons — is the frame's own pixels and must diff **0**. The glyph bands are
reported separately: the app draws its own PROMAN/EURO8 rasters, the standing app-wide
font substitution (see docs/re/offers_map_re.md), so those rows are expected to differ
and are NOT counted as chrome failure. What IS asserted inside them is the INK: the
natural role must be gold (255,223,0), the alternates white, the rest black.
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
REF = ROOT / "screenshots/wine-captures-2026-07-24-role-training-staff/13_pos_arrow.png"
POPUP = (220, 87, 200, 277)
# The whole title-bar INTERIOR is glyph territory: the original's surname ink sits on
# rows 96..103 but the app's PROMAN raster puts the 'g' descender of "Bergsson" a row
# lower, so a tighter band would score a font difference as a chrome failure.
TITLE_INK = (92, 107)
ITEM_Y0, ITEM_PITCH, ITEM_H, TEXT_X = 112, 14, 12, 246
N = 18
GOLD = (255, 223, 0)
WHITE = (255, 255, 255)
NATURAL = 2  # Bergsson: RIGHT BACK
ALTS = (5, 6)  # INSIDE CENTRE LEFT / RIGHT


def main() -> int:
    shot = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "app/out/rolepopup_bergsson.png"
    a = np.asarray(Image.open(shot).convert("RGB")).astype(int)
    b = np.asarray(Image.open(REF).convert("RGB")).astype(int)
    x, y, w, h = POPUP
    diff = np.abs(a[y : y + h, x : x + w] - b[y : y + h, x : x + w]).sum(2) > 0

    text = np.zeros_like(diff)
    text[TITLE_INK[0] - y : TITLE_INK[1] - y, :] = True
    for i in range(N):
        top = ITEM_Y0 + ITEM_PITCH * i - y
        text[top : top + ITEM_H, TEXT_X - x : w - 2] = True

    chrome_bad = int((diff & ~text).sum())
    text_bad = int((diff & text).sum())
    print(f"chrome (frame-cut): {chrome_bad} differing px")
    print(f"glyph bands (app font raster): {text_bad} differing px  [expected, not asserted]")

    rc = 0 if chrome_bad == 0 else 1

    # the ink rule is the load-bearing claim, so assert it on the SHOT
    for i in range(N):
        top = ITEM_Y0 + ITEM_PITCH * i
        band = a[top : top + ITEM_H, TEXT_X : x + w - 2]
        want = GOLD if i + 1 == NATURAL else (WHITE if i + 1 in ALTS else (0, 0, 0))
        hits = int((np.abs(band - np.array(want)).sum(2) == 0).sum())
        if hits == 0:
            print(f"FAIL row {i + 1} carries no {want} ink")
            rc = 1
    print("OK" if rc == 0 else "FAIL")
    return rc


if __name__ == "__main__":
    sys.exit(main())
