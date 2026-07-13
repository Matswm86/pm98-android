#!/usr/bin/env python3
"""Bake the PM98 LEAGUE TABLES (CLASIFICACION) screen chrome from the ORIGINAL, following
the frame-bake precedent (build_finance_chrome_from_frames.py / build_transfer_chrome_from_frames.py):
cut the original pixels 1:1 and blank ONLY the dynamic layers so the scene redraws live data.

BINDING SOURCE — READ THIS.
  There is NO LEAGUE TABLES frame in the 636-frame walkthrough
  (screenshots/original-walkthrough-2026-07-02). Every one of the 239 distinct
  management screens deduped from that walkthrough was scanned; the standings grid
  never appears (the closest, "STATISTICS FOR MANCHESTER UTD", is the player-stats
  screen, not the league table). So per the doctrine, the binding source falls back to
  the genuine PC capture:
      /home/mats/MWM-AI/data/pm98-refs/real-gallery/ma_10.png   (640x480, native)
  cross-checked against hires_league_table.jpg (same screen, 474x355 JPEG). Both show
  the SAME single witnessed state: Premier, Week 17, Man Utd top. Lower divisions are
  NOT witnessed anywhere -> the baked chrome (PREMIER LEAGUE subtitle, Premier-selected
  tab, EURO CUP / U.E.F.A. / RELEGATION zone tags) is Premier-only; a non-Premier career
  is a documented gap (docs/re/league_table_screen_re.md), never invented here.

Output:
  app/art/screens/leaguetable/chrome.png            - 640x480 chrome, dynamic layers blanked
  app/art/screens/leaguetable/leaguetable_chrome.json - sampled inks + overlay anchors

What is BAKED (frozen, verbatim ma_10): the light-marble background, the white table
panel + its border, the "PREMIER LEAGUE" subtitle, the Date-stepper frame (Date label,
[<]/[>] arrows, date-box frame), the column-header strip + labels (POS TEAM P W D L GF GA
PTS, per-column tinted), the EURO CUP / U.E.F.A. / RELEGATION zone-tag column (pennants +
trophy icons, fixed Premier slots), the LEADER card frame + "LEADER" label, the four
division tabs (Premier selected), GOAL SCORERS, RETURN. The barra/header widgets are also
baked here but the scene OVERDRAWS them live with PMChrome.draw_header (transfer-screen
pattern) so manager/club/date/week track the real career.

What is BLANKED here (redrawn live by LeagueTableScreen.gd from Career.standings()):
  * the 20 standings rows (x71..487, y114..431): POS, crest, name, P/W/D/L/GF/GA/Pts and
    the per-row backgrounds/cells — so the LIVE table (any club order, any my-club row)
    is drawn, not ma_10's frozen Week-17 order. Zone tags (x8..70) are LEFT baked.
  * the LEADER card kit (redrawn from standings[0]).
  * the date-box digits (redrawn from PMChrome.date_parts so the stepper tracks the week).

All colours below were SAMPLED off ma_10 (no hand-invented hex); see the sampling log in
the accompanying RE doc.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
FRAME = Path("/home/mats/MWM-AI/data/pm98-refs/real-gallery/ma_10.png")
OUT_DIR = ROOT / "app/art/screens/leaguetable"
OUT_PNG = OUT_DIR / "chrome.png"
OUT_JSON = OUT_DIR / "leaguetable_chrome.json"

W, H = 640, 480

# ---- row grid (measured off ma_10) ---------------------------------------
ROW_Y0 = 114          # top of row 1
ROW_PITCH = 16        # row-to-row step
ROW_FILL_H = 14       # coloured band per row (2px white gap below)
N_ROWS = 20

# row content span to blank (KEEP zone tags x8..70 and panel right border x488+)
ROW_X0, ROW_X1 = 71, 488
ROW_BAND_Y1 = ROW_Y0 + ROW_PITCH * N_ROWS   # 434

# ---- LEADER card kit interior (white card, remove the frozen Man Utd kit) -
LEADER_KIT_BOX = (553, 97, 604, 162)         # x0,y0,x1,y1

# ---- date-box digit interior (green DD/MM/YYYY on navy) -------------------
DATE_BOX = (342, 74, 451, 93)                # x0,y0,x1,y1
DATE_BG = (0, 0, 50)                         # navy fill under the digits

# ---- manager plaque blank -------------------------------------------------
# The barra is OVERDRAWN live by PMChrome.draw_header; its title bar, calendar sheet and
# green plaque cover ma_10's baked ones exactly, but PMChrome's manager plaque is a hair
# shorter than the frame's, leaving the baked "Manchester Utd." line peeking below it. So
# blank JUST the plaque region to the header marble (the live plaque then draws clean).
PLAQUE_BOX = (3, 2, 160, 47)                 # x0,y0,x1,y1
PLAQUE_MARBLE = (115, 135, 158)              # header-band marble (sampled around the plaque)


def fill(a: np.ndarray, rgb, x0: int, y0: int, x1: int, y1: int) -> None:
    a[y0:y1, x0:x1] = np.array(rgb, dtype=a.dtype)


def main() -> int:
    if not FRAME.exists():
        print(f"ERROR: binding source missing: {FRAME}", file=sys.stderr)
        return 1
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    im = Image.open(FRAME).convert("RGB")
    if im.size != (W, H):
        im = im.resize((W, H), Image.NEAREST)
    a = np.array(im)

    # sampled palette (measured off ma_10 clean-bg pixels; see RE-doc sampling log). The
    # scene reads these for the live overlay. All hardcoded from the pixel dumps (a live
    # sample at a fixed x can land on a digit stroke, so exact values are pinned here).
    samples = {
        # normal (non-managed) row
        "row_pos_bg": [180, 200, 220],     # light-blue POS+crest region
        "row_pos_ink": [0, 0, 128],        # navy POS number
        "row_name_bg": [0, 0, 128],        # navy name plate
        "row_name_ink": [255, 255, 255],   # white team name
        "cell_p_bg": [220, 220, 220], "cell_p_ink": [128, 128, 128],
        "cell_w_bg": [180, 200, 220], "cell_w_ink": [100, 120, 140],
        "cell_d_bg": [212, 223, 170], "cell_d_ink": [127, 159, 85],
        "cell_l_bg": [212, 191, 170], "cell_l_ink": [170, 127, 85],
        "cell_gf_bg": [180, 200, 220], "cell_gf_ink": [100, 120, 140],
        "cell_ga_bg": [212, 191, 170], "cell_ga_ink": [170, 127, 85],
        "cell_pts_bg": [72, 30, 2], "cell_pts_ink": [255, 223, 0],   # brown / gold
        "cell_sep": [0, 0, 0],             # black column separators
        # managed (my-club) row — the dark/saturated variant
        "mine_pos_bg": [42, 63, 170], "mine_pos_ink": [166, 202, 240],
        "mine_name_bg": [0, 0, 0], "mine_name_ink": [255, 255, 255],
        "mine_p_bg": [80, 80, 80], "mine_p_ink": [192, 192, 192],
        "mine_w_bg": [80, 100, 120], "mine_w_ink": [166, 202, 240],
        "mine_d_bg": [80, 110, 5], "mine_d_ink": [170, 223, 170],
        "mine_l_bg": [85, 0, 0], "mine_l_ink": [255, 31, 0],
        "mine_gf_bg": [80, 100, 120], "mine_gf_ink": [166, 202, 240],
        "mine_ga_bg": [170, 127, 85], "mine_ga_ink": [212, 191, 170],
        "mine_pts_bg": [150, 0, 0], "mine_pts_ink": [255, 255, 255],  # red / white
        # date stepper
        "date_ink": [180, 210, 50],        # yellow-green DD/MM/YYYY
        "date_bg": list(DATE_BG),
        "panel_bg": [255, 255, 255],       # white gap behind rows
    }

    # 1) standings rows: blank to white so the live table draws fresh (tags kept).
    fill(a, (255, 255, 255), ROW_X0, ROW_Y0, ROW_X1, ROW_BAND_Y1)

    # 2) LEADER card kit -> white (card frame + LEADER label kept).
    x0, y0, x1, y1 = LEADER_KIT_BOX
    fill(a, (255, 255, 255), x0, y0, x1, y1)

    # 3) date-box digits -> navy (frame + arrows kept).
    x0, y0, x1, y1 = DATE_BOX
    fill(a, DATE_BG, x0, y0, x1, y1)

    # 4) manager plaque -> header marble (live PMChrome.draw_header redraws it).
    x0, y0, x1, y1 = PLAQUE_BOX
    fill(a, PLAQUE_MARBLE, x0, y0, x1, y1)

    Image.fromarray(a).save(OUT_PNG)

    spec = {
        "binding_source": str(FRAME),
        "note": "No walkthrough frame shows LEAGUE TABLES; binding = real-gallery ma_10.png "
                "(Premier, Week 17). Rows/leader-kit/date blanked, redrawn live by "
                "LeagueTableScreen.gd. Header overdrawn by PMChrome.draw_header.",
        "size": [W, H],
        "row_grid": {"y0": ROW_Y0, "pitch": ROW_PITCH, "fill_h": ROW_FILL_H, "n": N_ROWS,
                     "x0": ROW_X0, "x1": ROW_X1},
        # x anchors (measured): Region1 POS+crest, Region2 name, then 7 stat cells [x,w].
        "cols": {
            "pos_region": [73, 122],       # POS + crest light-blue region
            "pos_num_cx": 86,              # POS number centre
            "crest_box": [99, 20],         # crest x, width (fitted, row height)
            "name_x": 127,                 # team-name left
            "name_region": [123, 270],
            "cells": {                     # column: [left_x, width]
                "P": [271, 23], "W": [296, 23], "D": [321, 23], "L": [346, 23],
                "GF": [371, 34], "GA": [407, 34], "PTS": [443, 38],
            },
            "cell_sep_x": [270, 295, 320, 345, 370, 406, 442, 482],
        },
        "leader_kit_box": list(LEADER_KIT_BOX),
        "date_box": list(DATE_BOX),
        "return_btn": [525, 423, 99, 25],
        "samples": samples,
    }
    OUT_JSON.write_text(json.dumps(spec, indent=2))
    print(f"wrote {OUT_PNG} ({OUT_PNG.stat().st_size} bytes)")
    print(f"wrote {OUT_JSON}")
    print("samples:", json.dumps(samples))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
