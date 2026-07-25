#!/usr/bin/env python3
"""Bake the PM98 FINANCES ("INCOME + EXPENSES") screen chrome from the real
walkthrough frame, following the PreseasonScreen frame-bake precedent
(tools/re/build_pretemp_states_from_frames.py): cut the original pixels 1:1 and
blank ONLY the dynamic value cells so the scene can redraw live numbers on top.

Binding frame: screenshots/original-walkthrough-2026-07-02/013_164406.png
  == 014_164407.png (pixel-identical). This is the INC. + EXP. / PER SEASON
  summary view (header "SEASON 1997 . 98"), chosen because FinanceModel produces
  SEASON figures, so the model's numbers land on the view whose semantics match.
  Totals in the frame validate the mapping exactly:
    TICKETS 541,500 + PUBLICITY 9,750 + TELEVISION 187,500 + SALE 9,120,000
      = TOTAL INCOME 9,858,750
    PLAYERS' WAGE 676,442 + PLAYERS' BONUS 5,000 + STAFF WAGES 1,211
      = TOTAL EXPENSES 682,653

Output:
  app/art/screens/finance/chrome.png        - 640x480 chrome, value cells blanked
  app/art/screens/finance/finance_chrome.json - sampled inks + overlay anchors

The frame is 641x480 (1px capture artefact); we crop to the game's native 640x480.

Blanking method = column-copy: for each dynamic cell we copy a clean (digit-free)
vertical column of that same cell across the digit span. This preserves each
row's exact background (green income tint, brown expense tint, the lavender /
dark-blue bottom-box rows, the yellow/blue total boxes, the white header panel)
without hand-coding any colour, and keeps any 1px top/bottom cell border intact.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
FRAME = ROOT / "screenshots/original-walkthrough-2026-07-02/013_164406.png"
# PER WEEK binding frame: the reference run's week 31, the CURRENT week, in which every
# value cell on the screen already reads £0 — so the blanking passes have nothing to
# fight and the surviving chrome is unambiguously the original's.
FRAME_WEEK = ROOT / "tools/re/refs/refrun-manutd-1997-98/p0495_finance_perweek_wk31.png"
OUT_DIR = ROOT / "app/art/screens/finance"
OUT_PNG = OUT_DIR / "chrome.png"
OUT_PNG_WEEK = OUT_DIR / "chrome_perweek.png"
OUT_JSON = OUT_DIR / "finance_chrome.json"

W, H = 640, 480

# ---- ledger geometry (measured off frame 013) ----------------------------
# 7 income rows / 11 expense rows on a 16px grid; first cell top at y=98.
ROW_Y0 = 98
ROW_STEP = 16
ROW_H = 13            # green/brown tint height per cell
N_INCOME = 7
N_EXPENSE = 11
INC_CELL_L, INC_CELL_R = 200, 306      # green value cell x-span
EXP_CELL_L, EXP_CELL_R = 497, 602      # brown value cell x-span (601 is the last
#                                        interior column; 602 is the cell's own edge)
INC_SRC_X = 207                        # clean green column (digit-free)
EXP_SRC_X = 500                        # clean brown column

# ---- totals --------------------------------------------------------------
TOT_Y0, TOT_Y1 = 282, 296
TOT_INC_L, TOT_INC_R, TOT_INC_SRC = 160, 306, 163   # (180,200,220) light-blue box
TOT_EXP_L, TOT_EXP_R, TOT_EXP_SRC = 458, 604, 461   # (255,255,170) pale-yellow box

# ---- SEASON header text (white panel) ------------------------------------
SEASON_BOX = (468, 57, 606, 74)        # fill white

# ---- PER WEEK header (REFRUN R5) -----------------------------------------
# The PER WEEK view replaces the SEASON stamp with a week stepper and a date span:
#   [<] (278..299)  [ gold box 300..391 ]  [>] (392..413)   From D-M-YYYY to D-M-YYYY
# Both texts sit on the SAME ink rows y62..68 and were identified by rendering every
# shipped BMFont atlas against the frame's own pixels at 0 differing px:
#   week box  proman10, (255,223,0), centred, floor((693 - advance) / 2)
#   date      proman8,  (128,128,128), pen x=416
# Only those two spans are dynamic; the arrows, the box bezel and the "WEEK" label
# are the frame's own pixels and are never redrawn.
# Both spans are two-colour (ink on one flat ground, verified on the frame), so a flat
# refill IS the original's own ground and nothing is approximated.
WEEK_BOX_INK = (302, 60, 391, 72)      # gold box interior, text span only
WEEK_GOLD = (181, 105, 9)
DATE_BOX = (416, 60, 593, 72)          # white panel

# ---- bottom LAST WEEK / CURRENT WEEK value cells --------------------------
# rows: INCOME / EXPENSES / CASH; value area is the right portion of each box.
# The two tiles' value cells end INSIDE their box's own black border: LAST WEEK's border
# is at x=228 and CURRENT WEEK's at x=461, and the last interior column is the one before
# it. The old 248 / 498 reached PAST both, wiping the LAST WEEK box's right border, the
# CURRENT WEEK box's left border and 30px of the desktop behind it.
LW_VAL_L, LW_VAL_R, LW_SRC = 131, 228, 130          # LAST WEEK box
CW_VAL_L, CW_VAL_R, CW_SRC = 369, 461, 368          # CURRENT WEEK box
# value rows only (title "LAST WEEK"/"CURRENT WEEK" is y414-426 and must be kept)
BOT_ROWS = [(428, 441), (442, 453), (454, 465)]     # INCOME, EXPENSES, CASH y-spans

# ---- balance chart bars (blank the captured Man-Utd bars) -----------------
# plot field: blue (200,220,240) above the zero axis (y~353), yellow
# (255,255,170) below. Blank the FULL plot width (the field is otherwise
# uniform; the witnessed bars sit near weeks 1-4 but we clear the lot so no
# stub survives) and let the scene redraw the model's balance bars.
CHART_BAR_X0, CHART_BAR_X1 = 60, 634
CHART_TOP_Y, CHART_BOT_Y = 333, 377
CHART_ZERO_Y = 353
CHART_BLUE = (200, 220, 240)
CHART_YELLOW = (255, 255, 170)


def col_copy(a: np.ndarray, src_x: int, x0: int, x1: int, y0: int, y1: int) -> None:
    """Broadcast the clean column at src_x across [x0,x1) for rows [y0,y1)."""
    a[y0:y1, x0:x1] = a[y0:y1, src_x][:, None, :]


def fill(a: np.ndarray, rgb, x0: int, y0: int, x1: int, y1: int) -> None:
    a[y0:y1, x0:x1] = np.array(rgb, dtype=a.dtype)


def blank_body(a: np.ndarray) -> None:
    """The ledger, totals, bottom tiles and chart bars — identical geometry on BOTH
    views, because the original draws the same body and only swaps the header."""
    for i in range(N_INCOME):
        y0 = ROW_Y0 + i * ROW_STEP
        col_copy(a, INC_SRC_X, INC_SRC_X + 1, INC_CELL_R, y0, y0 + ROW_H)
    for i in range(N_EXPENSE):
        y0 = ROW_Y0 + i * ROW_STEP
        col_copy(a, EXP_SRC_X, EXP_SRC_X + 1, EXP_CELL_R, y0, y0 + ROW_H)
    col_copy(a, TOT_INC_SRC, TOT_INC_SRC + 1, TOT_INC_R, TOT_Y0, TOT_Y1)
    col_copy(a, TOT_EXP_SRC, TOT_EXP_SRC + 1, TOT_EXP_R, TOT_Y0, TOT_Y1)
    for (ry0, ry1) in BOT_ROWS:
        col_copy(a, LW_SRC, LW_VAL_L, LW_VAL_R, ry0, ry1)
        col_copy(a, CW_SRC, CW_VAL_L, CW_VAL_R, ry0, ry1)
    fill(a, CHART_BLUE, CHART_BAR_X0, CHART_TOP_Y, CHART_BAR_X1, CHART_ZERO_Y)
    fill(a, CHART_YELLOW, CHART_BAR_X0, CHART_ZERO_Y + 1, CHART_BAR_X1, CHART_BOT_Y)


def bake_per_week() -> int:
    """The INC. + EXP. / PER WEEK view (REFRUN R5).

    Same body, own tab strip (PER WEEK lit) and own header. The frame is the reference
    run's CURRENT week, whose every cell already reads £0, so the only pixels this has
    to clear beyond the shared body are the week label and the date span.
    """
    if not FRAME_WEEK.exists():
        print(f"ERROR: PER WEEK binding frame missing: {FRAME_WEEK}", file=sys.stderr)
        return 1
    a = np.array(Image.open(FRAME_WEEK).convert("RGB").crop((0, 0, W, H)))
    # Refuse to bake against a frame that is not this view: the PER WEEK tab must be
    # lit and the stepper's gold box must be there.
    if tuple(int(v) for v in a[65, 600]) != (255, 255, 255):
        print("ERROR: header panel is not white at (600,65) — wrong frame?", file=sys.stderr)
        return 1
    if tuple(int(v) for v in a[65, 301]) != WEEK_GOLD:
        print("ERROR: no gold week box at (301,65) — this is not the PER WEEK view",
              file=sys.stderr)
        return 1
    blank_body(a)
    fill(a, WEEK_GOLD, *WEEK_BOX_INK)
    fill(a, (255, 255, 255), *DATE_BOX)
    Image.fromarray(a).save(OUT_PNG_WEEK)
    print(f"wrote {OUT_PNG_WEEK} ({OUT_PNG_WEEK.stat().st_size} bytes)")
    return 0


def main() -> int:
    if not FRAME.exists():
        print(f"ERROR: binding frame missing: {FRAME}", file=sys.stderr)
        return 1
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    im = Image.open(FRAME).convert("RGB").crop((0, 0, W, H))   # 641 -> 640
    a = np.array(im)

    def C(x: int, y: int):
        return tuple(int(v) for v in a[y, x])

    # sampled inks (measured off the frame BEFORE blanking; hard-coded here so
    # they survive the blanking passes below — the scene reads these for overlay).
    samples = {
        "income_ink": [0, 0, 0],
        "expense_ink": [0, 0, 0],
        "total_income_ink": [30, 52, 98],
        "total_expense_ink": [170, 0, 0],
        "season_ink": [0, 0, 0],
        "cash_gold_ink": list(C(171, 462)),          # (255,223,0)
        "bottom_ink": [0, 0, 0],
        "income_cell_bg": list(C(INC_SRC_X, 104)),
        "expense_cell_bg": list(C(EXP_SRC_X, 104)),
    }

    # 1-2, 4-5) the shared body: ledger cells, totals, bottom tiles, chart bars
    blank_body(a)

    # 3) SEASON header text (white panel) -----------------------------------
    fill(a, (255, 255, 255), *SEASON_BOX)

    Image.fromarray(a).save(OUT_PNG)

    spec = {
        "binding_frame": FRAME.name,
        "note": "INC.+EXP. / PER SEASON summary; dynamic values redrawn by "
                "FinanceScreen.gd from FinanceModel.summary + Career cash.",
        "size": [W, H],
        "samples": samples,
        "anchors": {
            "row_y0": ROW_Y0, "row_step": ROW_STEP,
            "income_right": INC_CELL_R - 1, "expense_right": EXP_CELL_R - 1,
            "total_y": TOT_Y0 + 2,
            "total_income_right": TOT_INC_R - 1, "total_expense_right": TOT_EXP_R - 1,
            "season_right": 600, "season_y": 60,
            "last_week_right": LW_VAL_R - 2, "current_week_right": CW_VAL_R - 2,
            "bottom_rows_y": BOT_ROWS,
            "chart_zero_y": CHART_ZERO_Y,
        },
        "per_week": {
            "binding_frame": FRAME_WEEK.name,
            "week_box_font": "proman10", "week_box_ink": [255, 223, 0],
            "week_box_field_sum": 693, "week_box_pen_top": 62,
            "date_font": "proman8", "date_ink": [128, 128, 128],
            "date_pen_x": 416, "date_pen_top": 62,
            "prev_btn": [278, 57, 22, 21], "next_btn": [392, 57, 22, 21],
            "tab_per_week": [365, 7, 125, 25], "tab_per_season": [499, 7, 125, 25],
        },
    }
    OUT_JSON.write_text(json.dumps(spec, indent=2))
    print(f"wrote {OUT_PNG} ({OUT_PNG.stat().st_size} bytes)")
    print(f"wrote {OUT_JSON}")
    print("samples:", json.dumps(samples))
    return bake_per_week()


if __name__ == "__main__":
    raise SystemExit(main())
