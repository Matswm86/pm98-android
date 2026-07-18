#!/usr/bin/env python3
"""Bake the PM98 GOAL SCORERS screen chrome from the ORIGINAL frames (frame-bake
precedent: build_leaguetable_chrome_from_frames.py).

BINDING SOURCES (all witnessed, see docs/re/goalscorers_screen_re.md):
  EMPTY state (main chrome, verbatim):
    screenshots/original-walkthrough-2026-07-02/047_154510.png
    (== 048_154514.png == parity-run orig/12_goalscorers.png at 0.00 mean-abs-diff —
     three independent captures of the identical preseason state)
  POPULATED state (palette/ink sampling only, NOT baked):
    screenshots/wine-captures-2026-07-18-goalscorers/18_goalscorers.png (WEEKS 2)
    screenshots/wine-captures-2026-07-18-goalscorers/87_gs_wk5.png      (WEEKS 4)
  ARMED compare button ("SELECT" label sprite):
    screenshots/wine-captures-2026-07-18-goalscorers/21_compare_white.png (white slot)
    cross-checked vs 24_red_armed.png (red slot shows the SAME label block)
  PLAYER GOAL-LOG POPUP (baked from):
    screenshots/wine-captures-2026-07-18-goalscorers/27_row_unarmed.png
    (Stuart Edward RIPLEY, 2 goals: wk1 Blackburn R.-Derby County '88,
     wk2 Aston Villa-Blackburn R. '51, "Data up to MATCH 2")
  GRAPH mark geometry (pixel-calibrated, 3 witnesses):
    23_compare_confirm.png  Heskey  white, 2 goals wk1..wk2 -> x67..73, y299..300
    26_red_confirmed.png    Sheringham red, 2 goals wk2     -> x72..73, y299..300
    90_abou_compare.png     Abou    white, 3 goals wk3..wk4 -> x77..83, y294..295
    => week w, total g plots a 2x2 dot at (67+5*(w-1), 309-5*g); consecutive weeks
       connect (flat runs witnessed contiguous). Zero-total weeks draw NOTHING
       (Sheringham wk1 absent). Slot colour = mark colour; later slots overdraw.

Output:
  app/art/screens/goalscorers/chrome.png        - 640x480 empty-state chrome
  app/art/screens/goalscorers/select_label.png  - the armed "SELECT" label block
  app/art/screens/goalscorers/popup.png         - goal-log popup chrome, rows blanked
  app/art/screens/goalscorers/goalscorers_chrome.json - geometry + sampled inks

What is BAKED (frozen, verbatim 047): marble bg, both panels, the GOALS/WEEKS graph
grid + axis labels + football icon, the week-pager band + stepper arrows (arrows are
INERT in the witness build - single clicks at weeks 2 and 4 changed 0 px; see RE doc),
the G./PLAYER/TEAM header strip, the 14 empty list bars, the 3 compare slot bars +
COMPARE buttons, RETURN. The barra is baked but overdrawn live by PMChrome.draw_header.

What is BLANKED here:
  * the manager plaque (live PMChrome.draw_header plaque draws clean over marble).
Everything else in the empty state IS the empty state - live text/marks draw on top.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
F_EMPTY = ROOT / "screenshots/original-walkthrough-2026-07-02/047_154510.png"
F_ARMED = ROOT / "screenshots/wine-captures-2026-07-18-goalscorers/21_compare_white.png"
F_ARMED_RED = ROOT / "screenshots/wine-captures-2026-07-18-goalscorers/24_red_armed.png"
F_POPUP = ROOT / "screenshots/wine-captures-2026-07-18-goalscorers/27_row_unarmed.png"
OUT_DIR = ROOT / "app/art/screens/goalscorers"

W, H = 640, 480

# ---- barra plaque (blank -> marble; PMChrome.draw_header overdraws live) ---
PLAQUE_BOX = (3, 2, 160, 47)

# ---- list grid (measured off 047/18: navy bands y123..342, pitch 16, h 12) -
ROW_Y0, ROW_PITCH, ROW_H, N_ROWS = 123, 16, 12, 14
CELL_G = (319, 355)  # light-blue G. cell   (180,200,220)
CELL_PLAYER = (356, 466)  # navy player bar      (0,0,128)
CELL_TEAM = (467, 606)  # grey team bar        (220,220,220)

# ---- week pager band + steppers (baked; arrows witnessed INERT) ------------
PAGER_BAND = (330, 81, 544, 96)  # dark-red value band (blank in empty state)

# ---- graph (pixel-calibrated marks; see module docstring) ------------------
GRAPH_X0, GRAPH_Y_BASE, GRAPH_STEP = 67, 309, 5  # dot x = X0+5*(w-1), y = 309-5*g

# ---- compare slots + buttons (measured off 047/21/22) ----------------------
# Slot bar: colour stripe y378..383 (slot1 WHITE 255,255,255 / slot2 RED 255,31,0 /
# slot3 BLUE 0,0,220 - sampled off 047), black sep y384, light name area y385..401.
SLOT_BARS = [(10, 377, 147, 402), (160, 377, 297, 402), (310, 377, 447, 402)]
SLOT_KIT_BOX = (13, 384, 24, 17)  # kit x-off, y, w, h inside slot bar (from 22)
SLOT_NAME_X = 44  # name left edge in the light area (from 22)
COMPARE_BTNS = [(16, 420, 127, 26), (166, 420, 127, 26), (316, 420, 127, 26)]
RETURN_BTN = (508, 420, 125, 26)
# Armed state = ONLY the label text swaps COMPARE->SELECT (21 vs 24: arrows keep the
# slot colour; 21's white ring is the standard click-focus border - also seen on the
# insurance PARAM. button - NOT armed-state chrome, so it is not baked). One label
# sprite serves all three buttons; cut from 21 slot-1, cross-checked vs 24 slot-2.
SELECT_LABEL_SRC = (44, 424, 117, 442)  # x0,y0,x1,y1 in 21 (slot-1 label region)
SELECT_LABEL_OFF = (28, 4)  # blit offset inside each button rect

# ---- popup (cut from 27; rows measured: WEEK red bands y150..337 pitch 16) -
POPUP_BOX = (104, 104, 538, 372)  # x0,y0,x1,y1 crop in frame coords
POP_ROW_Y0, POP_ROW_PITCH, POP_ROW_H, POP_N_ROWS = 150, 16, 12, 12
POP_CELL_WEEK = (113, 159)  # dark red (85,0,0), gold digit
POP_CELL_M1 = (160, 306)  # navy (0,0,128), white text
POP_CELL_M2 = (307, 453)  # navy
POP_CELL_MIN = (455, 505)  # light blue (200,220,240), navy text
POP_TITLE_BAND = (150, 111, 505, 131)  # title text region (band kept, per-row bg)
POP_STRIP = (115, 348, 366, 362)  # "Data up to MATCH N" strip text region (border at 367 kept)
POP_STRIP_BG = (166, 202, 240)
POP_RETURN = (455, 344, 78, 20)  # RETURN hitbox (frame coords; witnessed click 492,352)


def fill(a: np.ndarray, rgb, x0: int, y0: int, x1: int, y1: int) -> None:
    a[y0:y1, x0:x1] = np.array(rgb, dtype=a.dtype)


def main() -> int:
    for f in (F_EMPTY, F_ARMED, F_ARMED_RED, F_POPUP):
        if not f.exists():
            print(f"ERROR: binding source missing: {f}", file=sys.stderr)
            return 1
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    # ---- main chrome: verbatim empty state, plaque blanked ----
    a = np.array(Image.open(F_EMPTY).convert("RGB").crop((0, 0, W, H)))
    marble = tuple(int(v) for v in a[8, 170])  # header marble right of the plaque
    x0, y0, x1, y1 = PLAQUE_BOX
    fill(a, marble, x0, y0, x1, y1)
    Image.fromarray(a).save(OUT_DIR / "chrome.png")

    # ---- SELECT label sprite (armed compare button) ----
    im21 = np.array(Image.open(F_ARMED).convert("RGB").crop((0, 0, W, H)))
    im24 = np.array(Image.open(F_ARMED_RED).convert("RGB").crop((0, 0, W, H)))
    sx0, sy0, sx1, sy1 = SELECT_LABEL_SRC
    lbl = im21[sy0:sy1, sx0:sx1]
    # cross-check: the red slot's armed label (24, slot-2 offset +150) must match
    lbl_red = im24[sy0:sy1, sx0 + 150 : sx1 + 150]
    diff = float(np.abs(lbl.astype(int) - lbl_red.astype(int)).mean())
    print(f"SELECT label white-vs-red slot mean-abs-diff: {diff:.2f} (expect ~0)")
    Image.fromarray(lbl).save(OUT_DIR / "select_label.png")

    # ---- popup chrome: cut from 27, blank title text + row text + strip text ----
    p = np.array(Image.open(F_POPUP).convert("RGB").crop((0, 0, W, H)))
    tx0, ty0, tx1, ty1 = POP_TITLE_BAND
    for yy in range(ty0, ty1):  # per-row bg keeps the band's vertical gradient
        p[yy, tx0:tx1] = p[yy, tx0 - 6]
    for i in range(POP_N_ROWS):
        ry = POP_ROW_Y0 + i * POP_ROW_PITCH
        fill(p, (85, 0, 0), POP_CELL_WEEK[0], ry, POP_CELL_WEEK[1], ry + POP_ROW_H)
        fill(p, (0, 0, 128), POP_CELL_M1[0], ry, POP_CELL_M1[1], ry + POP_ROW_H)
        fill(p, (0, 0, 128), POP_CELL_M2[0], ry, POP_CELL_M2[1], ry + POP_ROW_H)
        fill(p, (200, 220, 240), POP_CELL_MIN[0], ry, POP_CELL_MIN[1], ry + POP_ROW_H)
    fill(p, POP_STRIP_BG, *POP_STRIP)
    px0, py0, px1, py1 = POPUP_BOX
    Image.fromarray(p[py0:py1, px0:px1]).save(OUT_DIR / "popup.png")

    spec = {
        "binding_sources": {
            "empty": str(F_EMPTY.relative_to(ROOT)),
            "identical_captures": [
                "048_154514.png",
                "parity-run-2026-07-16/orig/12_goalscorers.png",
            ],
            "populated_sampling": "wine-captures-2026-07-18-goalscorers/18,87",
            "armed_label": str(F_ARMED.relative_to(ROOT)),
            "popup": str(F_POPUP.relative_to(ROOT)),
        },
        "size": [W, H],
        "row_grid": {"y0": ROW_Y0, "pitch": ROW_PITCH, "h": ROW_H, "n": N_ROWS},
        "cells": {"g": CELL_G, "player": CELL_PLAYER, "team": CELL_TEAM},
        "pager_band": PAGER_BAND,
        "graph": {"x0": GRAPH_X0, "y_base": GRAPH_Y_BASE, "step": GRAPH_STEP},
        "slot_bars": SLOT_BARS,
        "slot_kit_box": SLOT_KIT_BOX,
        "slot_name_x": SLOT_NAME_X,
        "compare_btns": COMPARE_BTNS,
        "return_btn": RETURN_BTN,
        "select_label_off": SELECT_LABEL_OFF,
        "popup_box": POPUP_BOX,
        "popup": {
            "row_y0": POP_ROW_Y0,
            "pitch": POP_ROW_PITCH,
            "h": POP_ROW_H,
            "n": POP_N_ROWS,
            "week": POP_CELL_WEEK,
            "m1": POP_CELL_M1,
            "m2": POP_CELL_M2,
            "min": POP_CELL_MIN,
            "title_band": POP_TITLE_BAND,
            "strip": POP_STRIP,
            "return": POP_RETURN,
        },
        "samples": {
            # populated-list inks (sampled off 18_goalscorers.png rows)
            "g_ink": [30, 52, 98],
            "g_bg": [180, 200, 220],
            "player_ink": [255, 255, 255],
            "player_bg": [0, 0, 128],
            "team_ink": [0, 0, 0],
            "team_bg": [220, 220, 220],
            "pager_ink": [255, 223, 0],  # gold "WEEKS N"
            "row_sel_border": [85, 127, 255],  # armed-selection outline (22)
            "slot_name_ink": [0, 0, 0],  # dark name on the light slot bar (22)
            "slot_bar_bg": [200, 220, 240],
            # graph mark colours: slot1 white + slot2 red WITNESSED (23/26/90);
            # slot3 blue = the slot bar's own stripe colour (pattern of slots 1-2,
            # never armed in a witness - documented in the RE doc).
            "mark_colors": [[255, 255, 255], [255, 31, 0], [0, 0, 220]],
            # popup inks (27)
            "pop_week_ink": [255, 223, 0],
            "pop_match_ink": [255, 255, 255],
            "pop_min_ink": [0, 0, 128],
            "pop_title_ink": [255, 255, 255],
            "pop_strip_ink": [30, 52, 98],
        },
    }
    (OUT_DIR / "goalscorers_chrome.json").write_text(json.dumps(spec, indent=2))
    for f in ("chrome.png", "select_label.png", "popup.png", "goalscorers_chrome.json"):
        print(f"wrote {OUT_DIR / f} ({(OUT_DIR / f).stat().st_size} bytes)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
