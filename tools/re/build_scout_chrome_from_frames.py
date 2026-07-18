#!/usr/bin/env python3
"""Bake the PM98 SCOUT screen chrome from the live wine witness run.

BINDING SOURCES (docs/re/scout_screen_re.md; wine captures are 641px wide,
crop [:, :640]):
  screenshots/wine-captures-2026-07-18-goalscorers/
    43_scout.png             NO-SCOUT state: everything washed + gate text
    61_scout_with_scout.png  scout hired, nothing selected -> THE chrome base
    63_premier_checked.png   Premier league LED ON (cell (284,140) 22x13)
    67_pos_enabled.png       POSITION LED ON + dropdown "GOALKEEPER"
    68_results3.png          SEARCH armed ring + searching text
    81_scout_found2.png      results: headers + 8 rows + scroll column

Output (app/art/screens/scout/):
  chrome.png          640x480 from 61: scout-strip ink cleared back to the
                      EMPTY plate (pixels copied from 43 -- the strip zone is
                      identical outside the name/stars/wage ink), barra text
                      interiors blanked (the transfer-baker §C2 recipe)
  noscout_patch.png   the 43 body y62..435 (washed criteria + gate text) --
                      blitted whole when no scout is hired
  led_on.png          the bright-red LED cell (22x13; 67 POSITION == 63
                      Premier asserted identical before saving one sprite)
  search_armed.png    the armed SEARCH button + red ring (from 68)
  searching_text.png  the 2-line "scout is now searching" strip (from 68)
  headers.png         the NAME/AV/MO/CLUB FEE/WAGE/YEARS header strip (81)
  plus.png            the [+] row icon (81 row 1)
  scroll_up_off.png / scroll_dn_on.png / scroll_slider.png  (81; enabled-up /
                      disabled-dn are vflips, pattern-derived)
  scout_chrome.json   measured geometry + sampled inks
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
WD = ROOT / "screenshots" / "wine-captures-2026-07-18-goalscorers"
OUT_DIR = ROOT / "app" / "art" / "screens" / "scout"

W, H = 640, 480

# barra live-text blanks (build_transfer_chrome_from_frames.py §C2 recipe)
MGR_BAND_FILL = (180, 200, 220)
CLUB_BAND_FILL = (80, 100, 120)
RP_TOP_FILL = (127, 159, 85)
RP_BOT_FILL = (85, 95, 0)
WHITE = (255, 255, 255)
BLANK_MGR = (0, 15, 108, 30)
BLANK_CLUB = (0, 33, 108, 48)
BLANK_CREST = (112, 14, 140, 47)
BLANK_SHEET_WD = (447, 17, 521, 26)
BLANK_SHEET_DAY = (447, 28, 521, 35)
BLANK_SHEET_MON = (447, 37, 521, 46)
BLANK_SHEET_YR = (447, 48, 521, 55)
BLANK_RP_TOP = (541, 15, 616, 30)
BLANK_RP_BOT = (541, 33, 624, 48)

# scout-strip dynamic ink (43-vs-61 diff bands, +1 pad): name / stars / wage
STRIP_ZONES = [(63, 90, 136, 106), (170, 90, 204, 106), (244, 90, 297, 106)]

# LED cells (22x13): ON sprites witnessed on POSITION (67) + Premier (63)
LED_POSITION = (114, 113)
LED_PREMIER = (284, 140)
LED_W, LED_H = 22, 13

SEARCH_ARMED = (516, 209, 620, 238)   # x0,y0,x1,y1 exclusive
SEARCHING_TEXT = (120, 336, 390, 370)
HEADERS = (50, 284, 473, 294)
NOSCOUT_BODY = (0, 62, 640, 435)

ROW_Y0 = 297          # first row top border
ROW_PITCH = 16
N_ROWS = 8


def fill(a: np.ndarray, rgb, x0: int, y0: int, x1: int, y1: int) -> None:
    a[y0:y1, x0:x1] = np.array(rgb, dtype=a.dtype)


def load(name: str) -> np.ndarray:
    return np.array(Image.open(WD / name).convert("RGB"))[:, :W]


def save(a: np.ndarray, name: str) -> None:
    Image.fromarray(a).save(OUT_DIR / name)


def main() -> int:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    a43, a61, a63, a67, a68, a81 = (load(n) for n in (
        "43_scout.png", "61_scout_with_scout.png", "63_premier_checked.png",
        "67_pos_enabled.png", "68_results3.png", "81_scout_found2.png"))

    # ---- chrome: 61 with the strip ink cleared from 43 + barra blanked ----
    chrome = a61.copy()
    for (x0, y0, x1, y1) in STRIP_ZONES:
        chrome[y0:y1, x0:x1] = a43[y0:y1, x0:x1]
    fill(chrome, MGR_BAND_FILL, *BLANK_MGR)
    fill(chrome, CLUB_BAND_FILL, *BLANK_CLUB)
    fill(chrome, WHITE, *BLANK_CREST)
    for r in (BLANK_SHEET_WD, BLANK_SHEET_DAY, BLANK_SHEET_MON, BLANK_SHEET_YR):
        fill(chrome, WHITE, *r)
    fill(chrome, RP_TOP_FILL, *BLANK_RP_TOP)
    fill(chrome, RP_BOT_FILL, *BLANK_RP_BOT)
    save(chrome, "chrome.png")

    # ---- no-scout body patch (43, same strip zone already empty there) ----
    x0, y0, x1, y1 = NOSCOUT_BODY
    save(a43[y0:y1, x0:x1], "noscout_patch.png")

    # ---- LED ON sprite (67 POSITION; assert == 63 Premier) ----------------
    led_a = a67[LED_POSITION[1]:LED_POSITION[1] + LED_H, LED_POSITION[0]:LED_POSITION[0] + LED_W]
    led_b = a63[LED_PREMIER[1]:LED_PREMIER[1] + LED_H, LED_PREMIER[0]:LED_PREMIER[0] + LED_W]
    assert (led_a == led_b).all(), "POSITION-on != Premier-on LED sprite"
    save(led_a, "led_on.png")

    # ---- armed SEARCH + searching text + headers --------------------------
    x0, y0, x1, y1 = SEARCH_ARMED
    save(a68[y0:y1, x0:x1], "search_armed.png")
    x0, y0, x1, y1 = SEARCHING_TEXT
    save(a68[y0:y1, x0:x1], "searching_text.png")
    x0, y0, x1, y1 = HEADERS
    save(a81[y0:y1, x0:x1], "headers.png")

    # ---- row geometry (measured 2026-07-18: y297 border run x33..473, white
    # gap x474..477, scrollbar column x478..493, [+] icon x10..29 y296..311) --
    box_x0, box_x1 = 33, 473
    sb_x0, sb_x1 = 478, 493
    save(a81[296:312, 11:34], "plus.png")
    # witnessed non-EU flag (Filan row 4, Australia code 4; ink x36..55
    # y347..356 -> cut with 1px pad, blit at (35, row_top+1))
    save(a81[346:358, 35:57], "flag_4.png")

    # scrollbar rows pinned by the per-row scan (docs/re/scout_screen_re.md):
    # up arrow y297..312 (grey base row 312), slider y313..330 (black top
    # border + steel bevel body + 2px black bottom), plain track (120,140,160)
    # y331..406, down arrow face y407..421 + border 422. Track for the slider
    # formula = y313..406 (94 rows): floor(94*8/40) == the witnessed 18px.
    save(a81[297:313, sb_x0:sb_x1 + 1], "scroll_up_off.png")
    dn_y0, dn_y1 = 407, 422
    save(a81[dn_y0:dn_y1 + 1, sb_x0:sb_x1 + 1], "scroll_dn_on.png")
    sl_y0, sl_y1 = 313, 330
    save(a81[sl_y0:sl_y1 + 1, sb_x0:sb_x1 + 1], "scroll_slider.png")

    # star glyph sprites (row 1 Beeney = 3.5 stars: full pitch 14 from x159,
    # half glyph at x201). Cut on the row fill; panel-fill corners ride along.
    save(a81[298:310, 158:172], "star_full.png")
    save(a81[298:310, 200:208], "star_half.png")
    # the scout-strip star (61: 3 stars ink x171..202, pitch 11 on the plate).
    # strip_stars3 = the whole witnessed 3-star zone incl the drop shadows
    # (blitted 1:1 for the witnessed 3.0 rating; other counts tile the single)
    save(a61[92:105, 170:181], "strip_star.png")
    save(a61[90:107, 168:206], "strip_stars3.png")
    # enabled dropdown arrows (67 POSITION row; 65-vs-67 diff x115..130 /
    # x256..271 y131..146) — blitted on any enabled toggle's spinner
    save(a67[131:147, 115:131], "arrow_l_on.png")
    save(a67[131:147, 256:272], "arrow_r_on.png")

    # ---- value-column ink anchors (row 1 = Beeney 69/89/125,000/40,000/1|1)
    def ink_spans(y0r: int, lo: int, hi: int, pred) -> list[tuple[int, int]]:
        cell = a81[y0r + 1:y0r + 14, lo:hi]
        m = pred(cell)
        xs = np.where(m.any(axis=0))[0]
        if len(xs) == 0:
            return []
        spans, s, p = [], xs[0], xs[0]
        for x in xs[1:]:
            if x - p > 2:
                spans.append((int(lo + s), int(lo + p)))
                s = x
            p = x
        spans.append((int(lo + s), int(lo + p)))
        return spans

    rows_meta = {}
    y1r = ROW_Y0
    rows_meta["name_black"] = ink_spans(y1r, 40, 150, lambda c: (c < 60).all(axis=2))
    rows_meta["stars_gold"] = ink_spans(
        y1r, 140, 235,
        lambda c: (c[:, :, 0] > 200) & (c[:, :, 1] > 150) & (c[:, :, 2] < 120))
    rows_meta["av_red"] = ink_spans(
        y1r, 235, 262, lambda c: (c[:, :, 0] > 180) & (c[:, :, 1] < 120) & (c[:, :, 2] < 60))
    rows_meta["mo_blue"] = ink_spans(
        y1r, 258, 285, lambda c: (c[:, :, 2] > 140) & (c[:, :, 0] < 120))
    rows_meta["fee_red"] = ink_spans(
        y1r, 285, 350, lambda c: (c[:, :, 0] > 180) & (c[:, :, 1] < 90) & (c[:, :, 2] < 90))
    rows_meta["wage_darkred"] = ink_spans(
        y1r, 350, 415, lambda c: (c[:, :, 0] > 110) & (c[:, :, 0] < 190)
        & (c[:, :, 1] < 70) & (c[:, :, 2] < 70))
    rows_meta["years_cells"] = ink_spans(
        y1r, 415, box_x1, lambda c: ((c[:, :, 0] < 120) & (c[:, :, 2] > 120))
        | ((c[:, :, 0] > 200) & (c[:, :, 1] < 90) & (c[:, :, 2] < 90)))

    # the YEARS yellow final-year fill (row 1 LEFT cell)
    yellow = ink_spans(y1r, 415, box_x1,
                       lambda c: (c[:, :, 0] > 230) & (c[:, :, 1] > 230) & (c[:, :, 2] < 180))

    meta = {
        "row_box_x": [box_x0, box_x1],
        "row_y0": ROW_Y0,
        "row_pitch": ROW_PITCH,
        "n_rows": N_ROWS,
        "scroll_x": [sb_x0, sb_x1],
        "scroll_up_y": ROW_Y0,
        "scroll_dn_y": [dn_y0, dn_y1],
        "slider_y": [sl_y0, sl_y1],
        "led_cells": {
            "POSITION": [114, 113], "AGE": [17, 158], "ROLE": [114, 158],
            "QUALITY": [17, 204], "PRICE": [114, 204],
            "PREMIER": [284, 140], "DIV1": [367, 140], "DIV2": [450, 140],
            "DIV3": [533, 140],
        },
        "led_size": [LED_W, LED_H],
        "dropdown_pos_field": [131, 131, 255, 146],
        "search_armed_xy": [SEARCH_ARMED[0], SEARCH_ARMED[1]],
        "searching_text_xy": [SEARCHING_TEXT[0], SEARCHING_TEXT[1]],
        "headers_xy": [HEADERS[0], HEADERS[1]],
        "noscout_xy": [NOSCOUT_BODY[0], NOSCOUT_BODY[1]],
        "strip": {
            "name_ink": [64, 91, 134, 105], "stars_ink": [171, 91, 202, 105],
            "wage_ink": [245, 91, 295, 105],
        },
        "row1_ink_spans": rows_meta,
        "row1_years_yellow": yellow,
    }
    (OUT_DIR / "scout_chrome.json").write_text(json.dumps(meta, indent=1))
    print("row box x:", box_x0, box_x1, "scroll x:", sb_x0, sb_x1,
          "dn arrow y:", dn_y0, dn_y1, "slider y:", sl_y0, sl_y1)
    for k, v in rows_meta.items():
        print(f"  {k}: {v}")
    print("  years yellow:", yellow)
    print(f"wrote {OUT_DIR}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
