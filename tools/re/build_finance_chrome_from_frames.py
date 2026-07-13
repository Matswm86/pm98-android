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
OUT_DIR = ROOT / "app/art/screens/finance"
OUT_PNG = OUT_DIR / "chrome.png"
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
EXP_CELL_L, EXP_CELL_R = 497, 603      # brown value cell x-span
INC_SRC_X = 207                        # clean green column (digit-free)
EXP_SRC_X = 500                        # clean brown column

# ---- totals --------------------------------------------------------------
TOT_Y0, TOT_Y1 = 282, 296
TOT_INC_L, TOT_INC_R, TOT_INC_SRC = 160, 306, 163   # (180,200,220) light-blue box
TOT_EXP_L, TOT_EXP_R, TOT_EXP_SRC = 458, 604, 461   # (255,255,170) pale-yellow box

# ---- SEASON header text (white panel) ------------------------------------
SEASON_BOX = (468, 57, 606, 74)        # fill white

# ---- bottom LAST WEEK / CURRENT WEEK value cells --------------------------
# rows: INCOME / EXPENSES / CASH; value area is the right portion of each box.
LW_VAL_L, LW_VAL_R, LW_SRC = 131, 248, 130          # LAST WEEK box
CW_VAL_L, CW_VAL_R, CW_SRC = 369, 498, 368          # CURRENT WEEK box
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

    # 1) ledger value cells --------------------------------------------------
    for i in range(N_INCOME):
        y0 = ROW_Y0 + i * ROW_STEP
        col_copy(a, INC_SRC_X, INC_SRC_X + 1, INC_CELL_R, y0, y0 + ROW_H)
    for i in range(N_EXPENSE):
        y0 = ROW_Y0 + i * ROW_STEP
        col_copy(a, EXP_SRC_X, EXP_SRC_X + 1, EXP_CELL_R, y0, y0 + ROW_H)

    # 2) total boxes ---------------------------------------------------------
    col_copy(a, TOT_INC_SRC, TOT_INC_SRC + 1, TOT_INC_R, TOT_Y0, TOT_Y1)
    col_copy(a, TOT_EXP_SRC, TOT_EXP_SRC + 1, TOT_EXP_R, TOT_Y0, TOT_Y1)

    # 3) SEASON header text (white panel) -----------------------------------
    fill(a, (255, 255, 255), *SEASON_BOX)

    # 4) bottom boxes --------------------------------------------------------
    for (ry0, ry1) in BOT_ROWS:
        col_copy(a, LW_SRC, LW_VAL_L, LW_VAL_R, ry0, ry1)
        col_copy(a, CW_SRC, CW_VAL_L, CW_VAL_R, ry0, ry1)

    # 5) balance-chart captured bars ----------------------------------------
    fill(a, CHART_BLUE, CHART_BAR_X0, CHART_TOP_Y, CHART_BAR_X1, CHART_ZERO_Y)
    fill(a, CHART_YELLOW, CHART_BAR_X0, CHART_ZERO_Y + 1, CHART_BAR_X1, CHART_BOT_Y)

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
    }
    OUT_JSON.write_text(json.dumps(spec, indent=2))
    print(f"wrote {OUT_PNG} ({OUT_PNG.stat().st_size} bytes)")
    print(f"wrote {OUT_JSON}")
    print("samples:", json.dumps(samples))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
