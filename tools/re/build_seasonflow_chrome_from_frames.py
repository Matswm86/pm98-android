#!/usr/bin/env python3
"""Season-flow screens chrome, frame-baked from the live-witnessed originals:
TEAMS IN CHAMPIONSHIPS + CHARITY SHIELD CHAMPION + START OF SEASON (charter #4,
audit C1 #7/8/9 -- the season-entry chain the app never showed).

Binding frames (owned game, captured live from MANAGER.EXE under wine):
  screenshots/parity-run-2026-07-16/orig/06_champs.png        TEAMS IN CHAMPIONSHIPS
  screenshots/parity-run-2026-07-16/orig/70_after_ft.png      CHARITY SHIELD CHAMPION
  screenshots/parity-run-2026-07-16/orig/71_next.png          START OF SEASON (PREMIER, 20 rows)
  screenshots/promanager-career-2026-07-16/12_..._3rddiv.png  START OF SEASON (3RD DIV, 24 rows)

Doctrine (pm98_stay_true_to_original): the PNGs are the real frames' pixels; the ONLY
regions painted over are the ones the app renders live from Career state:
  champs.png  - the six panel bodies' text rows (flat fill 75,109,172); the title
                bands, trophies, plaque, ball and CONTINUE stay 1:1.
  shield.png  - winner/runner-up kit boxes + name/manager lines, patched with the
                card's own mottled texture (a clean same-card patch, not a flat
                invention); title, shield art, RUNNER-UP label and OK stay 1:1.
  season.png  - the PREMIER-frame table: title-band text, all 20 row texts (the
                user's black row restored to the shared row fills) stay blanked;
                corner plaque, tabs column and CONTINUE stay 1:1.
  season_box24.png - the 24-row table box cut from the 3RD DIV frame (row texts +
                title blanked the same way) for 24-club divisions.
  season_row_user.png - the witnessed black user-row style (text-free) to blit at
                the managed club's row.
  season_tab_hot.png / season_tab_cold.png - tab chip sprites (label area patched
                from the chip's own gradient rows) so any division can be the
                selected tab; only PREMIER-hot + 3RD-hot are witnessed, so other
                hot tabs reuse this chip art (approximation, flagged).
Anchors land in seasonflow_chrome.json.
"""

from __future__ import annotations

import json
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
F_CHAMPS = ROOT / "screenshots/parity-run-2026-07-16/orig/06_champs.png"
F_SHIELD = ROOT / "screenshots/parity-run-2026-07-16/orig/70_after_ft.png"
F_SEASON = ROOT / "screenshots/parity-run-2026-07-16/orig/71_next.png"
F_SEASON24 = (
    ROOT / "screenshots/promanager-career-2026-07-16/12_start_of_season_objectives_3rddiv.png"
)
OUT = ROOT / "app/art/screens/seasonflow"

W, H = 640, 480

CHAMPS_FILL = (75, 109, 172)
# panel body blanks (x0, y0, x1, y1) -- measured off frame 06 (probe session 2026-07-17)
CHAMPS_BLANKS = [
    (12, 135, 233, 163),  # EUROPEAN CUP body (trophy pixels start x236)
    (390, 124, 621, 173),  # U.E.F.A. CUP body
    (12, 258, 233, 276),  # CUP WINNERS' CUP body
    (386, 254, 621, 281),  # CHARITY SHIELD body (shield art ends x382)
    (12, 386, 233, 415),  # EUROPEAN SUPERCUP body
    (390, 386, 621, 415),  # INTERCONTINENTAL CUP body
]
# live-draw anchors: [panel key, club_x, mgr_x, [row baselines]]
CHAMPS_ANCHORS = [
    ["european_cup", 20, 160, [146, 159]],
    ["uefa_cup", 392, 532, [133, 146, 159, 172]],
    ["cup_winners_cup", 20, 160, [271]],
    ["charity_shield", 392, 532, [265, 278]],
    ["supercup", 20, 160, [398, 411]],
    ["intercontinental", 392, 532, [398, 411]],
]

# CHARITY SHIELD card: dynamic zones restored with the card's own texture. The
# mottle is horizontally streaked (no clean tile period), so each zone row is
# refilled by cycling the SAME ROW's pixels from a clean x-range (x335..420 is
# text/kit/shield-free for every card row) -- streaks stay continuous. Zones
# cover only the BAKED text/kit extents; live text may draw beyond them onto
# already-clean texture.
# (zone, same-row clean source x-range). The winner kit overlaps the title-band
# rows, where x335..420 carries title glyphs -- those rows source from the
# band's own glyph-free columns (x150..250, title text starts x258).
SHIELD_ZONES = [
    ((60, 108, 140, 146), (150, 250)),  # winner kit, title-band rows
    ((60, 146, 140, 232), (335, 420)),  # winner kit, card rows
    ((140, 146, 332, 188), (335, 420)),  # winner club + manager lines
    ((60, 240, 140, 340), (335, 420)),  # runner-up kit box
    ((140, 267, 340, 320), (335, 420)),  # runner-up club + manager (label ends y265)
]
SHIELD_ANCHORS = {
    "kit_winner": [70, 112, 60, 84],  # x, y, w, h boxes for PMChrome.draw_crest
    "kit_runner": [70, 244, 60, 84],
    "winner_x": 147,
    "winner_base": 163,
    "winner_mgr_base": 180,
    "runner_x": 147,
    "runner_base": 299,
    "runner_mgr_base": 316,
}

# START OF SEASON (PREMIER frame): table x44..483. The DIVISION NAME sits white
# on the BLACK title band y72..90 (dynamic -- patched from the band's own
# glyph-free left columns); the white TEAM|MANAGER|OBJECTIVE header row y91..104
# is STATIC and stays baked. 20 rows y0=106 pitch 16 band-h 12. Cells: TEAM
# x46..201 (0,0,128) text x59 white; MANAGER x202..341 (42,63,170) centered
# (200,220,240); OBJECTIVE x343..476 (166,202,240) centered (60,80,100). User
# row: (0,0,50)/(42,31,85)/(80,100,120) pale ink -- cut as season_row_user.png.
SEASON_TITLE_ZONE = (100, 73, 430, 90)  # division-name glyphs ("PREMIER LEAGUE" x186..340)
SEASON_TITLE_SRC = (48, 98)  # glyph-free band columns (same rows)
SEASON_ROWS = 20
SEASON_ROW_Y0 = 106
SEASON_PITCH = 16
SEASON_BAND_H = 12
SEASON_CELLS = [
    ((46, 201), (0, 0, 128)),
    ((202, 341), (42, 63, 170)),
    ((343, 476), (166, 202, 240)),
]
USER_ROW_SRC_IDX = 4  # Bolton W row in frame 71
USER_CELL_FILLS = [(0, 0, 50), (42, 31, 85), (80, 100, 120)]

# 24-row box from the 3RD DIV frame: black title band y52..70 (division name
# patched out the same way), white header row y71..84 static, rows y0=86 pitch
# 16 (ends y470). Brighton (user) row idx 1 restored to shared fills.
SEASON24_BOX = (44, 52, 484, 472)
SEASON24_TITLE_ZONE = (100, 53, 430, 70)
SEASON24_ROWS = 24
SEASON24_ROW_Y0 = 86

# Division tab chips (right column, PREMIER frame): x513..623, four slots.
TAB_RECTS = [
    (513, 253, 624, 278),
    (513, 283, 624, 308),
    (513, 313, 624, 338),
    (513, 343, 624, 368),
]


def fill(a: np.ndarray, rgb, x0: int, y0: int, x1: int, y1: int) -> None:
    a[y0:y1, x0:x1] = np.array(rgb, dtype=a.dtype)


def load(p: Path) -> np.ndarray:
    return np.array(Image.open(p).convert("RGB").crop((0, 0, W, H)))


def patch_rows(a: np.ndarray, src_x: tuple, zone: tuple) -> None:
    """Refill zone rows by cycling the same row's pixels from the clean src x-range."""
    sx0, sx1 = src_x
    x0, y0, x1, y1 = zone
    sw = sx1 - sx0
    for y in range(y0, y1):
        row = a[y, sx0:sx1].copy()
        for x in range(x0, x1, sw):
            w = min(sw, x1 - x)
            a[y, x : x + w] = row[:w]


def blank_season_rows(a: np.ndarray, y0: int, rows: int) -> None:
    for r in range(rows):
        ry = y0 + r * SEASON_PITCH
        for (cx0, cx1), rgb in SEASON_CELLS:
            fill(a, rgb, cx0, ry, cx1, ry + SEASON_BAND_H)


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)

    # ---- TEAMS IN CHAMPIONSHIPS ----
    a = load(F_CHAMPS)
    for z in CHAMPS_BLANKS:
        fill(a, CHAMPS_FILL, *z)
    Image.fromarray(a).save(OUT / "champs.png")

    # ---- CHARITY SHIELD CHAMPION ----
    a = load(F_SHIELD)
    for z, src in SHIELD_ZONES:
        patch_rows(a, src, z)
    Image.fromarray(a).save(OUT / "shield.png")

    # ---- START OF SEASON (20-row PREMIER chrome) ----
    a = load(F_SEASON)
    # cut the text-free user row sprite BEFORE blanking (restore its texts first)
    uy = SEASON_ROW_Y0 + USER_ROW_SRC_IDX * SEASON_PITCH
    urow = a[uy : uy + SEASON_BAND_H, 44:484].copy()
    for ((cx0, cx1), _rgb), f in zip(SEASON_CELLS, USER_CELL_FILLS):
        urow[:, cx0 - 44 : cx1 - 44] = np.array(f, dtype=urow.dtype)
    Image.fromarray(urow).save(OUT / "season_row_user.png")
    patch_rows(a, SEASON_TITLE_SRC, SEASON_TITLE_ZONE)
    blank_season_rows(a, SEASON_ROW_Y0, SEASON_ROWS)

    # tab chips: cut hot (PREMIER) + cold (1ST DIVISION), label patched from the
    # chip's own text-free gradient columns (left margin), tiled with row phase.
    def cut_tab(rect, out_name):
        x0, y0, x1, y1 = rect
        chip = a[y0:y1, x0:x1].copy()
        # label zone = interior; patch source = 6px column just inside the left bevel
        src = chip[:, 6:12].copy()
        for x in range(12, chip.shape[1] - 6, src.shape[1]):
            w = min(src.shape[1], chip.shape[1] - 6 - x)
            chip[:, x : x + w] = src[:, :w]
        Image.fromarray(chip).save(OUT / out_name)

    cut_tab(TAB_RECTS[0], "season_tab_hot.png")
    cut_tab(TAB_RECTS[1], "season_tab_cold.png")
    Image.fromarray(a).save(OUT / "season.png")

    # ---- 24-row table box (3RD DIV frame) ----
    a24 = load(F_SEASON24)
    patch_rows(a24, SEASON_TITLE_SRC, SEASON24_TITLE_ZONE)
    blank_season_rows(a24, SEASON24_ROW_Y0, SEASON24_ROWS)
    bx0, by0, bx1, by1 = SEASON24_BOX
    Image.fromarray(a24[by0:by1, bx0:bx1]).save(OUT / "season_box24.png")

    spec = {
        "binding_frames": [F_CHAMPS.name, F_SHIELD.name, F_SEASON.name, F_SEASON24.name],
        "champs": {
            "fill": list(CHAMPS_FILL),
            "blanks": [list(z) for z in CHAMPS_BLANKS],
            "anchors": CHAMPS_ANCHORS,
            "club_ink": [255, 255, 255],
            "mgr_ink": [180, 200, 220],
            "continue_btn": [508, 438, 116, 30],
        },
        "shield": {
            "zones": [list(z) for z, _src in SHIELD_ZONES],
            "anchors": SHIELD_ANCHORS,
            "winner_ink": [255, 251, 240],
            "runner_ink": [170, 0, 0],
            "mgr_ink": [255, 255, 255],
            "ok_btn": [88, 340, 52, 22],
        },
        "season": {
            "title_center": 263,
            "title_base": 86,
            "title_base24": 66,
            "rows": SEASON_ROWS,
            "row_y0": SEASON_ROW_Y0,
            "pitch": SEASON_PITCH,
            "band_h": SEASON_BAND_H,
            "cells": [[list(c[0]), list(c[1])] for c in SEASON_CELLS],
            "team_x": 59,
            "mgr_center": 271,
            "obj_center": 409,
            "team_ink": [255, 255, 255],
            "mgr_ink": [200, 220, 240],
            "obj_ink": [60, 80, 100],
            "user_obj_ink": [166, 202, 240],
            "box24": {
                "pos": [SEASON24_BOX[0], SEASON24_BOX[1]],
                "rows": SEASON24_ROWS,
                "row_y0": SEASON24_ROW_Y0,
            },
            "tabs": [list(r) for r in TAB_RECTS],
            "continue_btn": [513, 438, 116, 30],
        },
    }
    (OUT / "seasonflow_chrome.json").write_text(json.dumps(spec, indent=2))
    for f in sorted(OUT.iterdir()):
        print("wrote", f.name, f.stat().st_size)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
