#!/usr/bin/env python3
"""Bake THE CALENDAR (hub FIXTURES icon; EMPAREJAMIENTOS family) STATIC CHROME
from the real game's own walkthrough frames.

Binding frame: 051_154519.png (run 1, 15:45:19) — the hub FIXTURES icon click
(050_154518 = MANAGER MENU hub) lands on the screen titled THE CALENDAR; RETURN
goes back to the hub (055_154527). Frames 052/053/054 are the same screen state:
their only diff vs 051 is the RETURN button's ANIMATED ball/arrow icon
(asserted below), so 051 is the chrome verbatim.

Same doctrine as build_entry_chrome_from_frames.py: the screen is engine-
composited (fondo + barra + sheet furniture + fonts); the chrome layer IS the
original frame VERBATIM. For the WITNESSED state (fresh MU career, Fri 1 Aug
1997) the screen shows this chrome unmodified, so the month-title / day-grid /
TODAY / NEXT text is the frame's own bitmap art — frame-true, not re-rasterised
with an approximate app font. Only when a career DIVERGES from the witnessed
state does FixturesScreen white-clear the body regions (rects emitted to the
spec as `clear_rects`) and redraw them with the app fonts (an honest, un-
witnessed approximation — the original CALENDAR bitmap font is not pixel-
identified; a full font-redraw drifted ~9% of the frame).
Header band (y 0..61) is baked but the screen repaints it whole via
PMChrome.draw_match_header (band.png is opaque full-width) + the title sprite
cut here — the same recomposition the LINE-UP/VIEW RIVAL rollout proved 0px.
The ball / kit sprites are still cut for the divergent same-club redraw.

Outputs (app/art/screens/fixtures/):
  chrome.png            640x480 frame 051 VERBATIM (witnessed CALENDAR, text baked)
  title_calendar.png    the barra "THE CALENDAR" title sprite (+ anchor in specs)
  ball_next.png         28x31 NEXT-row ball cell (dark-gold radial + ball)
  ball_today.png        28x31 TODAY stage-bar end ball cell (== right end, SAD 0)
  kit_today_1021.png    frame-rendered TODAY band kit, Juventus (left slot)
  kit_today_40.png      frame-rendered TODAY band kit, Man Utd (right slot)
  kit_row_<id>h.png     24x32 frame-rendered NEXT-row home-column kits (40, 1000)
  kit_row_<id>a.png     24x32 away-column kits (49, 40, 1301, 1361)
  tools/re/specs/fixtures_chrome_samples.json  sampled geometry + colours

Every measured invariant is asserted so a regenerated walkthrough or a bad crop
fails loudly instead of baking garbage.

Run from anywhere:  python3 tools/re/build_fixtures_chrome_from_frames.py
"""

from __future__ import annotations

import json
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
FRAMES = ROOT / "screenshots" / "original-walkthrough-2026-07-02"
if not FRAMES.exists():  # full capture set is local-only; binding frames are committed
    FRAMES = ROOT / "tools" / "re" / "refs" / "walkthrough-2026-07-02"
ART = ROOT / "app" / "art" / "screens" / "fixtures"
SPECS = Path(__file__).resolve().parent / "specs"

F051 = "051_154519.png"  # THE CALENDAR, binding (fresh MU career, Fri 1 Aug 1997)
WITNESSES = ["052_154521.png", "053_154523.png", "054_154525.png"]

WHITE = np.array([255, 255, 255], dtype="uint8")

# --- frame-measured geometry (all asserted below) ---------------------------
SHEET_X = (80, 280)          # sheet white body left edges; body x..x+169
SHEET_TOP, SHEET_BOT = 84, 206
TITLE_ROWS = (85, 98)        # month-title band (cleared; "AUGUST 1997" rows 86..96)
CELL_ROWS = (111, 204)       # day-cell region (cleared; red ring tops at 112)
CELL_X0, CELL_Y0 = 16, 114   # first cell box (sheet-relative x; absolute y)
CELL_PW, CELL_PH = 20, 18    # cell pitch
CELL_W, CELL_H = 17, 15      # cell box (inclusive border)
LEGEND_TOPS = [69, 86, 103, 120, 137, 154, 171, 188, 204, 220]
LEGEND_CHIP = (538, 551)     # chip box x span (14 px)
TODAY_INT = (40, 500, 226, 296)   # band interior x0,x1,y0,y1 (inclusive)
NEXT_INT = (40, 500, 311, 467)
TD_NAME = (99, 232, 438, 253)     # name-bar border box x0,y0,x1,y1
TD_BARS = (99, 258, 439, 290)     # stage-bars border box (rows 258/290, sep 274)
TD_BALL_L, TD_BALL_R = (100, 259), (411, 259)   # 28x31 ball cells
TD_FLAG_H, TD_FLAG_A = (100, 233), (408, 233)   # 30x20 BANDERAS in the name bar
NX_Y0, NX_PITCH = 317, 38    # row interior tops (4 rows); borders y0-1 / y0+31
NX_BALL_X = 45               # ball cell interior x (28 wide; borders 44/73)
NX_KIT_H_X, NX_KIT_A_X = 88, 389   # 24x32 kit blit anchors (plates 84..114/385..415)
NX_DATE = (422, 494)         # date panel border cols; interior 423..493

COMP_COLORS = {              # legend chip fills, top->bottom (frame-sampled)
    "league": (166, 202, 240),
    "fa_cup": (255, 255, 170),
    "euro_league": (170, 255, 170),
    "cup_winners": (255, 191, 170),
    "uefa": (255, 204, 255),
    "charity": (192, 192, 192),
    "supercup": (192, 192, 192),
    "intercont": (160, 160, 164),
    "preseason": (212, 191, 0),
    "cocacola": (160, 160, 200),
}


def load(name: str) -> np.ndarray:
    a = np.asarray(Image.open(FRAMES / name).convert("RGB"))
    if a.shape[0] != 480 or a.shape[1] not in (640, 641):
        raise SystemExit(f"{name}: unexpected size {a.shape}")
    return a[:, :640].copy()  # 641st column = capture artifact


def save(a: np.ndarray, rel: str) -> None:
    p = ART / rel
    p.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(a.astype("uint8")).save(p)
    print(f"  {p.relative_to(ROOT)}  {a.shape[1]}x{a.shape[0]}")


def expect(cond: bool, what: str) -> None:
    if not cond:
        raise SystemExit(f"frame invariant FAILED: {what}")


def px(a: np.ndarray, x: int, y: int) -> tuple:
    return tuple(int(v) for v in a[y, x])


def main() -> None:
    f = load(F051)

    # --- witnesses: 052/053/054 differ from 051 ONLY at the animated RETURN icon
    for w in WITNESSES:
        d = (load(w) != f).any(axis=2)
        ys, xs = np.where(d)
        expect(
            len(xs) > 0 and xs.min() >= 520 and xs.max() <= 628 and ys.min() >= 433 and ys.max() <= 463,
            f"{w}: diff outside the RETURN icon box ({xs.min()},{ys.min()})-({xs.max()},{ys.max()})",
        )

    # --- sheet invariants ----------------------------------------------------
    for sx in SHEET_X:
        expect(px(f, sx, 120) == (255, 255, 255), f"sheet white at ({sx},120)")
        expect(px(f, sx + 169, 120) == (255, 255, 255), f"sheet white at ({sx + 169},120)")
        # cell border columns at sx+16+20c (verify on row-3 top border y150)
        for c in range(7):
            expect(px(f, sx + CELL_X0 + CELL_PW * c, 150)[0] < 60,
                   f"cell border col {c} sheet@{sx}")
    # weekday header row (S M T W T F S) identical across the two sheets (baked)
    expect(
        (f[99:111, 82:249] == f[99:111, 282:449]).all(),
        "weekday header rows identical between sheets",
    )
    # today red ring bbox (Fri 1 AUG cell, col 5 row 0)
    reg = f[105:135, 188:222].astype(int)
    m = (reg[:, :, 0] > 150) & (reg[:, :, 1] < 60) & (reg[:, :, 2] < 60)
    ys, xs = np.where(m)
    expect(
        (xs.min() + 188, xs.max() + 188, ys.min() + 105, ys.max() + 105) == (194, 214, 112, 130),
        "today red ring bbox",
    )
    # month-title red ink
    treg = f[86:97, 96:230]
    tm = (treg[:, :, 0] > 150) & (treg[:, :, 1] < 80)
    month_red = tuple(int(v) for v in np.median(treg[tm].reshape(-1, 3), axis=0))
    expect(month_red == (210, 0, 0), f"month title red {month_red}")

    # --- legend chips ----------------------------------------------------------
    for (key, want), top in zip(COMP_COLORS.items(), LEGEND_TOPS):
        got = px(f, 545, top + 7)
        expect(got == want, f"legend {key} chip {got} != {want}")

    # --- cell fills == legend colours (witnessed cells) ------------------------
    def cellfill(sheet: int, c: int, r: int) -> tuple:
        return px(f, SHEET_X[sheet] + CELL_X0 + CELL_PW * c + 2, CELL_Y0 + CELL_PH * r + 2)

    expect(cellfill(0, 1, 1) == COMP_COLORS["preseason"], "AUG 4 preseason gold")
    expect(cellfill(0, 0, 1) == COMP_COLORS["charity"], "AUG 3 charity grey")
    expect(cellfill(0, 0, 2) == COMP_COLORS["league"], "AUG 10 league blue")
    expect(cellfill(1, 0, 0) == COMP_COLORS["league"], "SEP sheet leading 31-AUG league blue")
    expect(cellfill(1, 3, 2) == COMP_COLORS["euro_league"], "SEP 17 euro-league green")

    # --- TODAY band invariants --------------------------------------------------
    expect(px(f, 200, 242) == (212, 191, 0), "TODAY name bar gold (preseason)")
    expect(px(f, 200, 265) == (212, 127, 0), "TODAY stage bar1 fill")
    expect(px(f, 200, 281) == (212, 159, 0), "TODAY stage bar2 fill")
    expect(px(f, 300, 274)[0] < 60, "TODAY bar separator row 274")
    ball_l = f[259:290, 100:128]
    ball_r = f[259:290, 411:439]
    expect((ball_l == ball_r).all(), "TODAY bar-end balls identical L/R")
    # Italy/England 30x20 flags at the bar ends (probe a green + a red pixel)
    expect(px(f, 103, 242)[1] > 120, "Italy flag green at (103,242)")
    expect(px(f, 421, 240)[0] > 150, "England flag cross at (421,240)")

    # --- NEXT band invariants -----------------------------------------------------
    for r in range(4):
        y0 = NX_Y0 + NX_PITCH * r
        expect(px(f, 150, y0 - 1)[0] < 60, f"row {r} top border")
        expect(px(f, 150, y0 + 31)[0] < 60, f"row {r} bottom border")
        expect(px(f, 150, y0 + 15)[0] < 60, f"row {r} name/bars separator")
    expect(px(f, 117, 361) == (212, 191, 0), "row2 name fill preseason gold")
    expect(px(f, 117, 323) == (192, 192, 192), "row1 name fill charity grey")
    expect(px(f, 150, 377) == (212, 127, 0), "row2 comp bar fill")
    expect(px(f, 380, 379) == (212, 159, 0), "row2 round bar fill")
    expect(px(f, 240, 339) == (80, 80, 80), "row1 bars charity dark grey")
    expect(px(f, 426, 358) == (102, 50, 12), "row2 date panel brown")
    expect(px(f, 426, 320) == (80, 80, 80), "row1 date panel charity dark")
    # ball cells: rows 2..4 identical; row 1 (charity) is the plain black cell
    ball_next = f[NX_Y0 + NX_PITCH : NX_Y0 + NX_PITCH + 31, NX_BALL_X : NX_BALL_X + 28]
    for r in (2, 3):
        y0 = NX_Y0 + NX_PITCH * r
        expect((f[y0 : y0 + 31, NX_BALL_X : NX_BALL_X + 28] == ball_next).all(),
               f"row {r} ball cell == row 1 ball cell")
    expect(f[NX_Y0 : NX_Y0 + 31, NX_BALL_X : NX_BALL_X + 28].max() < 60,
           "row 0 (charity) ball cell plain black")
    # home kits: rows 2/3 both Man Utd — identical frame-rendered patches
    kit_r2 = f[NX_Y0 + 2 * NX_PITCH : NX_Y0 + 2 * NX_PITCH + 32, NX_KIT_H_X : NX_KIT_H_X + 24]
    kit_r3 = f[NX_Y0 + 3 * NX_PITCH : NX_Y0 + 3 * NX_PITCH + 32, NX_KIT_H_X : NX_KIT_H_X + 24]
    expect((kit_r2 == kit_r3).all(), "rows 3/4 home kit (Man Utd) identical")

    # --- inks (sampled for the specs; the screen hardcodes these) -----------------
    def darkest(x0: int, x1: int, y0: int, y1: int) -> tuple:
        reg = f[y0:y1, x0:x1].astype(int).reshape(-1, 3)
        return tuple(int(v) for v in reg[reg.sum(axis=1).argmin()])

    inks = {
        "today_name_ink": darkest(140, 400, 234, 251),      # (10,15,0) dark olive
        "bar1_ink": (102, 50, 12),                           # "Preseason" strokes
        "bar2_ink": (135, 73, 22),                           # "Preparation" strokes
        "date_month_preseason": (212, 127, 0),               # "AUG" on rows 2-4
        "date_month_charity": (192, 192, 192),               # "3 AUG" month on row 1
        "month_red": month_red,
    }

    # ============================ CUT SPRITES =====================================

    # barra title sprite: the 17-tall bar strip around the white "THE CALENDAR"
    # glyphs (same cut style/height as header/title_lineup.png, anchored y 22).
    # Assert the strip's non-glyph background equals the shared band.png, so the
    # opaque rectangle sprite composes seamlessly over the recomposed header.
    band = np.asarray(Image.open(ROOT / "app/art/screens/header/band.png").convert("RGB"))
    w = f[:62].min(axis=2) > 200
    w[:20] = w[40:] = False
    w[:, :170] = w[:, 440:] = False
    ys, xs = np.where(w)
    expect((xs.min(), xs.max(), ys.min(), ys.max()) == (219, 376, 23, 33),
           "title glyph bbox")
    d = np.abs(f[22:39, 150:460].astype(int) - band[22:39, 150:460].astype(int)).mean(axis=2) > 12
    ys2, xs2 = np.where(d)
    expect(xs2.min() + 150 >= 217 and xs2.max() + 150 <= 382,
           "title strip differs from band.png only at the glyphs")
    save(f[22:39, 217:383], "title_calendar.png")
    title_anchor = [217, 22]

    save(np.array(ball_next), "ball_next.png")
    save(np.array(ball_l), "ball_today.png")

    # TODAY band frame-rendered kits (larger art family than the app's 48x64 export;
    # un-walked clubs fall back to PMChrome.kit — documented in fixtures_screen_re.md)
    save(f[230:297, 44:102], "kit_today_1021.png")   # Juventus, left slot
    save(f[235:297, 447:497], "kit_today_40.png")    # Man Utd, right slot
    kit_today_anchor = {"1021": [44, 230], "40": [447, 235]}

    # NEXT-row frame-rendered 24x32 kit patches (composited soft shadow — same
    # reason the entry bake keeps per-frame panel kits; x-parity fixed per column)
    save(f[NX_Y0 : NX_Y0 + 32, NX_KIT_H_X : NX_KIT_H_X + 24], "kit_row_40h.png")
    save(f[NX_Y0 + NX_PITCH : NX_Y0 + NX_PITCH + 32, NX_KIT_H_X : NX_KIT_H_X + 24],
         "kit_row_1000h.png")
    for r, cid in ((0, 49), (1, 40), (2, 1301), (3, 1361)):
        y0 = NX_Y0 + NX_PITCH * r
        save(f[y0 : y0 + 32, NX_KIT_A_X : NX_KIT_A_X + 24], f"kit_row_{cid}a.png")

    # ============================ CHROME ==========================================
    # chrome.png = frame 051 VERBATIM (the whole witnessed CALENDAR, text included).
    # PRECEDENT (PreseasonScreen / build_entry_chrome_from_frames.py): the resting
    # WITNESSED state renders as the frame's OWN pixels, so the month-title / day-grid
    # / TODAY / NEXT text is frame-true bitmap art — NOT re-rasterised with an
    # approximate app font (the original CALENDAR bitmap font is not pixel-identified;
    # font-redraw drifted ~9% of the frame — see docs/re/fixtures_screen_re.md).
    # FixturesScreen shows this chrome for the frame-051 baseline and only WHITE-clears
    # + redraws the body (app fonts, honest approximation) when a career DIVERGES from
    # the witnessed state. The clear rects it uses are recorded in the spec below.
    save(f.copy(), "chrome.png")
    clear_rects = {
        "sheet_title": [[sx + 2, TITLE_ROWS[0], sx + 168, TITLE_ROWS[1] + 1] for sx in SHEET_X],
        "sheet_cells": [[sx + 2, CELL_ROWS[0], sx + 168, CELL_ROWS[1] + 1] for sx in SHEET_X],
        "today_interior": list(TODAY_INT),
        "next_interior": list(NEXT_INT),
    }

    # ============================ SPECS ===========================================
    spec = {
        "binding_frame": F051,
        "witness_frames": WITNESSES,
        "hub_frames": ["050_154518.png", "055_154527.png"],
        "sheets": {
            "x": list(SHEET_X), "top": SHEET_TOP, "bottom": SHEET_BOT,
            "title_rows": list(TITLE_ROWS), "cell_rows_cleared": list(CELL_ROWS),
            "cell_x0": CELL_X0, "cell_y0": CELL_Y0,
            "cell_pitch": [CELL_PW, CELL_PH], "cell_box": [CELL_W, CELL_H],
            "today_ring": [194, 112, 21, 19],
        },
        "legend": {"chip_x": list(LEGEND_CHIP), "tops": LEGEND_TOPS,
                   "colors": {k: list(v) for k, v in COMP_COLORS.items()}},
        "today": {
            "interior": list(TODAY_INT), "name_box": list(TD_NAME),
            "bars_box": list(TD_BARS), "bar_sep_row": 274,
            "ball_l": list(TD_BALL_L), "ball_r": list(TD_BALL_R),
            "flag_h": list(TD_FLAG_H), "flag_a": list(TD_FLAG_A),
            "kit_anchor": kit_today_anchor,
        },
        "next": {
            "interior": list(NEXT_INT), "row_y0": NX_Y0, "pitch": NX_PITCH,
            "ball_x": NX_BALL_X, "kit_h_x": NX_KIT_H_X, "kit_a_x": NX_KIT_A_X,
            "plate_h": [83, 115], "name_span": [115, 384], "bar_split_x": 249,
            "date_cols": list(NX_DATE),
        },
        "clear_rects": clear_rects,
        "inks": {k: list(v) for k, v in inks.items()},
        "fills": {
            "preseason_bar1": [212, 127, 0], "preseason_bar2": [212, 159, 0],
            "preseason_date_bg": [102, 50, 12],
            "charity_bars": [80, 80, 80], "charity_date_bg": [80, 80, 80],
        },
        "title_anchor": title_anchor,
    }
    SPECS.mkdir(parents=True, exist_ok=True)
    out = SPECS / "fixtures_chrome_samples.json"
    out.write_text(json.dumps(spec, indent=1) + "\n")
    print(f"  {out.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
