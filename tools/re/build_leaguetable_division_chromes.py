#!/usr/bin/env python3
"""Bake the LOWER-DIVISION League Tables chromes + the position-movement markers
from the LIVE-WITNESSED original frames (wine campaign 2026-07-19).

Binding sources (all 641x480 window grabs; column 640 is dropped — the frames
align with the ma_10-baked chrome at dx=0, MAD 0.0 on the header band):
  screenshots/wine-captures-2026-07-19-lowerdiv/
    w5_lt_default.png     FIRST DIVISION, P=0 seed state  (Manchester C career)
    w7_lt_second.png      SECOND DIVISION, P=0 seed state (Barnet career)
    w7_lt_third_seed.png  THIRD DIVISION, P=0 seed state  (Barnet career)
    lt_wk2_premier.png    Premier week 2 — the movement markers (white UP
                          triangle / red DOWN triangle / grey no-change square)

Each division chrome is the original frame cut 1:1 with ONLY the dynamic layers
blanked (same recipe as build_leaguetable_chrome_from_frames.py):
  * the 24 standings rows (x71..487, y115..472) -> white; the zone-tag column
    (PROMOTION / PLAY-OFFS / RELEGATION pennants, x8..70) stays BAKED, as do the
    division subtitle, the selected tab, Date frame, column headers, buttons;
  * the LEADER card kit interior (empty in the seed frames anyway);
  * the date-box digits -> navy;
  * the manager plaque -> header marble (PMChrome.draw_header overdraws live).

The movement markers are cut verbatim from lt_wk2_premier (10x9 px at x106,
band-top +3 on the 20-row grid / +2 on the 24-row grid — measured):
  marker_up.png / marker_down.png / marker_flat.png
NOTE: ma_10's per-row "low-detail placeholder square" (the old doc read it as a
crest placeholder) IS this marker in its no-change state — witnessed by the
week-2 frame where it becomes the red/white triangles. There is NO crest/kit in
the rows.

24-row grid (measured off lt_first/w5_lt_default): y0=115, pitch=15, band=12px.
Column x anchors are IDENTICAL to the Premier grid (separators at
270/295/320/345/370/406/442/482 verified on lt_first y210).
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "screenshots/wine-captures-2026-07-19-lowerdiv"
OUT_DIR = ROOT / "app/art/screens/leaguetable"

W, H = 640, 480

CHROMES = {
    "first": "w5_lt_default.png",
    "second": "w7_lt_second.png",
    "third": "w7_lt_third_seed.png",
}

# 24-row grid (measured).
ROW_X0, ROW_X1 = 71, 488
ROW_Y0 = 115
ROW_PITCH = 15
ROW_FILL_H = 12
N_ROWS = 24
ROW_BAND_Y1 = ROW_Y0 + ROW_PITCH * (N_ROWS - 1) + ROW_FILL_H + 1   # 473

LEADER_KIT_BOX = (553, 97, 604, 162)
DATE_BOX = (342, 74, 451, 93)
DATE_BG = (0, 0, 50)
PLAQUE_BOX = (3, 2, 160, 47)
PLAQUE_MARBLE = (115, 135, 158)

# Movement markers (lt_wk2_premier rows 1 / 2 / 9; 20-row grid y=114+16r).
MARKER_X = 106
MARKER_W, MARKER_H = 10, 9
MARKERS = {"up": (0, 117), "down": (1, 133), "flat": (8, 245)}   # row idx, sprite y


def fill(a: np.ndarray, rgb, x0: int, y0: int, x1: int, y1: int) -> None:
    a[y0:y1, x0:x1] = np.array(rgb, dtype=a.dtype)


def main() -> int:
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    for key, fname in CHROMES.items():
        src = SRC / fname
        if not src.exists():
            print(f"ERROR: witness frame missing: {src}", file=sys.stderr)
            return 1
        a = np.array(Image.open(src).convert("RGB"))[:, :W]   # drop col 640
        assert a.shape == (H, W, 3), a.shape
        fill(a, (255, 255, 255), ROW_X0, ROW_Y0, ROW_X1, ROW_BAND_Y1)
        x0, y0, x1, y1 = LEADER_KIT_BOX
        fill(a, (255, 255, 255), x0, y0, x1, y1)
        x0, y0, x1, y1 = DATE_BOX
        fill(a, DATE_BG, x0, y0, x1, y1)
        x0, y0, x1, y1 = PLAQUE_BOX
        fill(a, PLAQUE_MARBLE, x0, y0, x1, y1)
        out = OUT_DIR / f"chrome_{key}.png"
        Image.fromarray(a).save(out)
        print(f"wrote {out} ({out.stat().st_size} bytes)")

    wk2 = SRC / "lt_wk2_premier.png"
    a = np.array(Image.open(wk2).convert("RGB"))[:, :W]
    for key, (_row, sy) in MARKERS.items():
        sprite = a[sy:sy + MARKER_H, MARKER_X:MARKER_X + MARKER_W]
        out = OUT_DIR / f"marker_{key}.png"
        Image.fromarray(sprite).save(out)
        print(f"wrote {out}")

    spec_path = OUT_DIR / "leaguetable_divisions.json"
    spec = {
        "binding_sources": {k: str((SRC / v).relative_to(ROOT)) for k, v in CHROMES.items()},
        "note": "Lower-division chromes + movement markers, live-witnessed "
                "2026-07-19. Rows/leader/date/plaque blanked; zone tags, "
                "subtitle and the selected tab stay baked per division.",
        "row_grid_24": {"y0": ROW_Y0, "pitch": ROW_PITCH, "fill_h": ROW_FILL_H,
                        "n": N_ROWS, "x0": ROW_X0, "x1": ROW_X1},
        "marker": {"x": MARKER_X, "w": MARKER_W, "h": MARKER_H,
                   "dy_20row": 3, "dy_24row": 2},
        "tabs": {"x": 525, "w": 100, "h": 26,
                 "y": {"premier": 194, "first": 224, "second": 254, "third": 284}},
    }
    spec_path.write_text(json.dumps(spec, indent=2))
    print(f"wrote {spec_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
