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
# The two DETAIL views (walkthrough finance tour, run 3). 006 is INCOME/PER WEEK with the
# named `SALE Jordi Cruyff` row; 011 is EXPENSES/PER SEASON (== 012's body pixel for
# pixel — they differ only by the mouse). 007 donates a hover-ring-free INCOME tab
# (006's mouse sat on it); 013 donates a clean PER SEASON tab (011's mouse sat on that).
FRAME_INCOME = ROOT / "screenshots/original-walkthrough-2026-07-02/006_164349.png"
FRAME_INCOME_TAB = ROOT / "screenshots/original-walkthrough-2026-07-02/007_164351.png"
FRAME_EXPENSES = ROOT / "screenshots/original-walkthrough-2026-07-02/011_164402.png"
OUT_DIR = ROOT / "app/art/screens/finance"
OUT_PNG = OUT_DIR / "chrome.png"
OUT_PNG_WEEK = OUT_DIR / "chrome_perweek.png"
OUT_PNG_INCOME = OUT_DIR / "chrome_income.png"                    # INCOME / PER WEEK
OUT_PNG_INCOME_SEASON = OUT_DIR / "chrome_income_perseason.png"   # INCOME / PER SEASON
OUT_PNG_EXPENSES = OUT_DIR / "chrome_expenses.png"                # EXPENSES / PER SEASON
OUT_PNG_EXPENSES_WEEK = OUT_DIR / "chrome_expenses_perweek.png"   # EXPENSES / PER WEEK
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

# ---- the DYNAMIC euro-income row label (income row 3) ---------------------
# The 4th income row names the European competition the club is in, and the original
# picks one of THREE strings for it (FUN_0050812e @0x5081B0..0x50838F; see
# finance_screen_re.md "the SUMMARY view's euro label"). It was baked static out of
# frame 013's `EUROPEAN CUP INCOME` until 2026-07-27, which printed Man Utd's
# competition on every career.
#
# The plate under it is FLAT: in y146..158 the panel runs (220,220,220) from x32 to
# x197 with white margins at x25..31 and x198..199 — asserted below against the frame
# itself, and cross-checked between the two witnesses (013 `EUROPEAN CUP INCOME`,
# `orig/51_finance_season.png` `U.E.F.A. CUP INCOME`), which are pixel-identical
# everywhere outside the ink. So a flat refill IS the original's own ground.
EURO_LABEL_BOX = (32, 146, 198, 159)   # x0,y0,x1,y1 — inside the white margins
EURO_LABEL_BG = (220, 220, 220)

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


# ---- DETAIL views (frames 006 / 011, measured 2026-07-27) -----------------
# Both detail bodies share one grid: label plates (220,220,220) at x41..196 (left column)
# and x338..494 (right), value plates at x199..298 / x496..595 inclusive, every row 13px
# tall. The value-plate TINTS vary by row kind (khaki income, tan expense, pale-green
# gross sub-row, pale-blue insurance sub-row, blue transfer, loan green) and col_copy
# picks each row's own tint up automatically. 011 vs 010 proves the whole body is
# IDENTICAL across PER WEEK / PER SEASON except the tab strip, the arrow band and the
# header band — so each view is baked once and the OTHER period is composited from the
# already-proven summary bakes (P1/P2 verified 0 px cross-career AND cross-view:
# 004 vs p0495 and 013 vs 011 both diff to zero over these rects).
DET_VAL_L = (199, 299)        # left value plate interior [x0,x1)
DET_VAL_R = (496, 596)        # right value plate interior
DET_ROW_H = 13
# income view rows (plate tops): 4 left sections x3 rows, supercup x3, intercont x2
INC_ROWS_L = [108, 124, 140, 186, 202, 218, 264, 280, 296, 341, 357, 373]
INC_ROWS_R = [108, 124, 140, 186, 202]
INC_ROW_SALE = 237            # TRANSFERS row (blue plate; green SALE label pen 341)
INC_ROW_INSGRP = 273          # INSURANCE COMPENSATION GROUP row
INC_ROWS_LOANS = [309, 325, 341, 357]
NOT_PLAYED = [(339, 95, 420, 107), (339, 173, 420, 185)]   # grey `Not played` spans
SALE_LABEL = (341, 238, 494, 249)   # dynamic green label span inside the grey plate
# expenses view rows
EXP_ROWS_L = [96, 129, 162, 178, 194, 226, 258, 292, 325, 341, 357, 373]
EXP_ROWS_R = [96, 136, 152, 168, 184, 224, 260, 276, 292, 308]
# dynamic label cells (appear only with a nonzero figure: witnessed empty in 008's £0
# week, filled in 011/012's season): Players´ Wage / N bonuses / Staff Wages
EXP_DYN_LABELS = [(43, 163, 196, 173), (43, 227, 196, 237), (340, 97, 493, 107)]
# the single TOTAL bar each detail view carries (proman10, pen END 605, top 381)
DET_TOT = (460, 379, 605, 394)   # value span blanked from clean col 459
# tab transplant rects (cover the donor tab incl. its 2px hover-ring halo)
TAB_INCOME_RECT = (110, 2, 222, 36)     # from 007 onto 006
TAB_PERSEASON_RECT = (492, 2, 630, 36)  # from 013 onto 011
# period-swap composites, proven 0 px cross-career and cross-view
P1_STRIP = (332, 2, 640, 46)     # PER WEEK / PER SEASON tabs + their arrow band
P2_HEADER = (210, 50, 610, 80)   # week stepper bezel / season white panel


def col_copy(a: np.ndarray, src_x: int, x0: int, x1: int, y0: int, y1: int) -> None:
    """Broadcast the clean column at src_x across [x0,x1) for rows [y0,y1)."""
    a[y0:y1, x0:x1] = a[y0:y1, src_x][:, None, :]


def fill(a: np.ndarray, rgb, x0: int, y0: int, x1: int, y1: int) -> None:
    a[y0:y1, x0:x1] = np.array(rgb, dtype=a.dtype)


def blank_tiles(a: np.ndarray) -> None:
    """The LAST WEEK / CURRENT WEEK value cells — identical on every view (the whole
    y>=398 band diffs to zero between the summary and detail frames)."""
    for (ry0, ry1) in BOT_ROWS:
        col_copy(a, LW_SRC, LW_VAL_L, LW_VAL_R, ry0, ry1)
        col_copy(a, CW_SRC, CW_VAL_L, CW_VAL_R, ry0, ry1)


def blank_body(a: np.ndarray) -> None:
    """The ledger, totals, bottom tiles and chart bars — identical geometry on BOTH
    views, because the original draws the same body and only swaps the header."""
    for i in range(N_INCOME):
        y0 = ROW_Y0 + i * ROW_STEP
        col_copy(a, INC_SRC_X, INC_SRC_X + 1, INC_CELL_R, y0, y0 + ROW_H)
    for i in range(N_EXPENSE):
        y0 = ROW_Y0 + i * ROW_STEP
        col_copy(a, EXP_SRC_X, EXP_SRC_X + 1, EXP_CELL_R, y0, y0 + ROW_H)
    # the euro-income row's LABEL (the scene redraws whichever of the three it is)
    ex0, ey0, ex1, ey1 = EURO_LABEL_BOX
    margin = {tuple(int(v) for v in a[y, x])
              for y in range(ey0, ey1) for x in (25, 31, 198, 199)}
    if margin != {(255, 255, 255)}:
        raise SystemExit(f"euro label margins are not the white rules: {margin}")
    fill(a, EURO_LABEL_BG, ex0, ey0, ex1, ey1)
    col_copy(a, TOT_INC_SRC, TOT_INC_SRC + 1, TOT_INC_R, TOT_Y0, TOT_Y1)
    col_copy(a, TOT_EXP_SRC, TOT_EXP_SRC + 1, TOT_EXP_R, TOT_Y0, TOT_Y1)
    blank_tiles(a)
    fill(a, CHART_BLUE, CHART_BAR_X0, CHART_TOP_Y, CHART_BAR_X1, CHART_ZERO_Y)
    fill(a, CHART_YELLOW, CHART_BAR_X0, CHART_ZERO_Y + 1, CHART_BAR_X1, CHART_BOT_Y)


def bake_per_week() -> np.ndarray | None:
    """The INC. + EXP. / PER WEEK view (REFRUN R5).

    Same body, own tab strip (PER WEEK lit) and own header. The frame is the reference
    run's CURRENT week, whose every cell already reads £0, so the only pixels this has
    to clear beyond the shared body are the week label and the date span.
    Returns the blanked array (bake_details composites its P1/P2 rects off it).
    """
    if not FRAME_WEEK.exists():
        print(f"ERROR: PER WEEK binding frame missing: {FRAME_WEEK}", file=sys.stderr)
        return None
    a = np.array(Image.open(FRAME_WEEK).convert("RGB").crop((0, 0, W, H)))
    # Refuse to bake against a frame that is not this view: the PER WEEK tab must be
    # lit and the stepper's gold box must be there.
    if tuple(int(v) for v in a[65, 600]) != (255, 255, 255):
        print("ERROR: header panel is not white at (600,65) — wrong frame?", file=sys.stderr)
        return None
    if tuple(int(v) for v in a[65, 301]) != WEEK_GOLD:
        print("ERROR: no gold week box at (301,65) — this is not the PER WEEK view",
              file=sys.stderr)
        return None
    blank_body(a)
    fill(a, WEEK_GOLD, *WEEK_BOX_INK)
    fill(a, (255, 255, 255), *DATE_BOX)
    Image.fromarray(a).save(OUT_PNG_WEEK)
    print(f"wrote {OUT_PNG_WEEK} ({OUT_PNG_WEEK.stat().st_size} bytes)")
    return a


def copy_rect(dst: np.ndarray, src: np.ndarray, rect) -> None:
    x0, y0, x1, y1 = rect
    dst[y0:y1, x0:x1] = src[y0:y1, x0:x1]


def _tab_lit(a: np.ndarray, x0: int, x1: int) -> bool:
    """A lit tab glows red/green inside its box; unlit is near-black behind grey text."""
    box = a[10:28, x0:x1].astype(int)
    return float(box.max(axis=2).mean()) > 90.0


def blank_detail_values(a: np.ndarray, rows_l, rows_r) -> None:
    for y0 in rows_l:
        col_copy(a, DET_VAL_L[0] + 1, DET_VAL_L[0] + 2, DET_VAL_L[1], y0, y0 + DET_ROW_H)
    for y0 in rows_r:
        col_copy(a, DET_VAL_R[0] + 1, DET_VAL_R[0] + 2, DET_VAL_R[1], y0, y0 + DET_ROW_H)
    col_copy(a, DET_TOT[0] - 1, DET_TOT[0], DET_TOT[2], DET_TOT[1], DET_TOT[3])
    blank_tiles(a)


def bake_details(sum_season: np.ndarray, sum_week: np.ndarray) -> int:
    """The INCOME and EXPENSES detail views, each baked from its own frame with the
    hover-ringed tab transplanted from the neighbouring frame, plus the two composited
    other-period variants (P1 strip + P2 header off the summary bakes — both rects
    proven 0 px across careers and across views)."""
    for f in (FRAME_INCOME, FRAME_INCOME_TAB, FRAME_EXPENSES):
        if not f.exists():
            print(f"ERROR: binding frame missing: {f}", file=sys.stderr)
            return 1
    inc = np.array(Image.open(FRAME_INCOME).convert("RGB").crop((0, 0, W, H)))
    inc_tab = np.array(Image.open(FRAME_INCOME_TAB).convert("RGB").crop((0, 0, W, H)))
    exp = np.array(Image.open(FRAME_EXPENSES).convert("RGB").crop((0, 0, W, H)))
    f013 = np.array(Image.open(FRAME).convert("RGB").crop((0, 0, W, H)))

    # de-ring the lit tabs (006's mouse ringed INCOME, 011's ringed PER SEASON)
    copy_rect(inc, inc_tab, TAB_INCOME_RECT)
    copy_rect(exp, f013, TAB_PERSEASON_RECT)
    if tuple(int(v) for v in inc[5, 114]) == (255, 255, 255):
        print("ERROR: hover ring survived on the INCOME tab", file=sys.stderr)
        return 1
    if tuple(int(v) for v in exp[5, 497]) == (255, 255, 255):
        print("ERROR: hover ring survived on the PER SEASON tab", file=sys.stderr)
        return 1

    # INCOME / PER WEEK: values, the SALE label, the two `Not played` spans, the
    # stepper's gold box + date span, the tiles.
    blank_detail_values(inc, INC_ROWS_L, INC_ROWS_R + [INC_ROW_SALE, INC_ROW_INSGRP]
                        + INC_ROWS_LOANS)
    col_copy(inc, SALE_LABEL[2] - 1, SALE_LABEL[0], SALE_LABEL[2], SALE_LABEL[1], SALE_LABEL[3])
    for r in NOT_PLAYED:
        fill(inc, (255, 255, 255), *r)
    fill(inc, WEEK_GOLD, *WEEK_BOX_INK)
    fill(inc, (255, 255, 255), *DATE_BOX)

    # EXPENSES / PER SEASON: values, the three data-driven labels, the SEASON text.
    blank_detail_values(exp, EXP_ROWS_L, EXP_ROWS_R)
    for (lx0, ly0, lx1, ly1) in EXP_DYN_LABELS:
        col_copy(exp, lx1 - 1, lx0, lx1, ly0, ly1 + 1)
    fill(exp, (255, 255, 255), *SEASON_BOX)

    # other-period composites off the summary bakes (already value-blanked)
    inc_season = inc.copy()
    copy_rect(inc_season, sum_season, P1_STRIP)
    copy_rect(inc_season, sum_season, P2_HEADER)
    exp_week = exp.copy()
    copy_rect(exp_week, sum_week, P1_STRIP)
    copy_rect(exp_week, sum_week, P2_HEADER)

    for name, arr, view_lit, week_lit in (
            (OUT_PNG_INCOME, inc, "income", True),
            (OUT_PNG_INCOME_SEASON, inc_season, "income", False),
            (OUT_PNG_EXPENSES, exp, "expenses", False),
            (OUT_PNG_EXPENSES_WEEK, exp_week, "expenses", True)):
        ok = (_tab_lit(arr, 116, 216) == (view_lit == "income")
              and _tab_lit(arr, 224, 324) == (view_lit == "expenses")
              and not _tab_lit(arr, 8, 108)
              and _tab_lit(arr, 365, 490) == week_lit
              and _tab_lit(arr, 499, 624) != week_lit)
        if not ok:
            print(f"ERROR: tab lighting wrong on {name.name}", file=sys.stderr)
            return 1
        Image.fromarray(arr).save(name)
        print(f"wrote {name} ({name.stat().st_size} bytes)")
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
    week_arr = bake_per_week()
    if week_arr is None:
        return 1
    return bake_details(a, week_arr)


if __name__ == "__main__":
    raise SystemExit(main())
