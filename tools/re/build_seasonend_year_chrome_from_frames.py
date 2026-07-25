#!/usr/bin/env python3
"""Bake the three MISSING season-end screens from the reference run's own frames.

REFRUN R15 walked the original's end-of-season sequence for the first time. Five of its
eight steps were already built; these are the other three, and their binding frames were
committed at `tools/re/refs/season-end-2026-07-25/` with the geometry unmeasured:

  20_the_championships.png   step 3 — the eight finals, with scorelines
  21_end_of_season.png       step 4 — champion / U.E.F.A. / promoted / relegated x4
  23_players_of_the_year.png step 6 — one award per club, four division tabs

Doctrine (docs/re/SPEC_BINDING.md): the chrome IS the original frame with ONLY the
state-dependent pixels cleared. Everything else — the barra, the eight trophy bitmaps,
the competition titles, the division bands, the column headers, the tabs, CONTINUE — is
the original's own pixels and is never redrawn.

Every rect below was read off the frames' own black borders and flat plate fills, and
every text anchor the scenes use was solved with `tools/re/probe_text_anchor.py` (render
each candidate BMFont atlas against the frame and keep only the zero-differing-pixel
answer). The anchors travel in the emitted JSON so the scenes and this bake cannot drift.

Outputs (app/art/screens/seasonend/):
  championships.png · endofseason.png · players_year.png
  tools/re/specs/seasonend_year_samples.json

Run:  python3 tools/re/build_seasonend_year_chrome_from_frames.py
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
REFS = ROOT / "tools" / "re" / "refs" / "season-end-2026-07-25"
OUT = ROOT / "app" / "art" / "screens" / "seasonend"
SPEC = ROOT / "tools" / "re" / "specs" / "seasonend_year_samples.json"

W, H = 640, 480

# ---------------------------------------------------------------- CHAMPIONSHIPS
# Eight cards in two columns. The LEFT column's cards carry ONE score cell and the
# RIGHT column's carry TWO — that is the frame's own layout, not a data-driven
# choice, and the four two-score slots are exactly the four competitions PM98 can
# decide over two legs or a replay. Slot -> competition is fixed by the baked titles.
CH_CARD_TOPS = [113, 204, 295, 388]        # row 1 top of each card; row 2 is +22
CH_ROW2_DY = 22
CH_ROW_H = 20
CH_COL = {
    # kit_x, name_pen_x, name_cell_x1
    "left": {"kit_x": 56, "name_pen": 82, "name_x1": 242},
    "right": {"kit_x": 334, "name_pen": 360, "name_x1": 520},
}
# Score cells are per CARD, not per column. The left column's four cards each carry ONE;
# on the right, the F.A. Cup, the European Supercup and the Coca-Cola Cup carry TWO and
# the U.E.F.A. Cup carries one — its card is simply narrower, and the desktop shows to
# the right of it. Read straight off the frame's own panel borders.
CH_SCORE1 = (523, 551)
CH_SCORE2 = (554, 582)
CH_LEFT_SCORES = [(245, 273)]
CH_KIT_W, CH_KIT_H = 17, 19
CH_NAME_BG = (200, 220, 240)
CH_SCORE_BG = (42, 63, 170)
CH_SCORE2_BG = (0, 95, 0)
CH_NAME_PEN_DY = 5                          # pen top inside the row band
CH_WIN_INK = (0, 0, 0)                      # the winner's name, solid black
CH_LOSE_INK = (80, 100, 120)                # the loser's, grey — REFRUN R15's rule
CH_SCORE_INK = (255, 255, 255)
# Slot order, read straight off the baked titles.
CH_SLOTS = [
    ("left", 0, "charity_shield", CH_LEFT_SCORES),
    ("left", 1, "european_cup", CH_LEFT_SCORES),
    ("left", 2, "cup_winners_cup", CH_LEFT_SCORES),
    ("left", 3, "intercontinental", CH_LEFT_SCORES),
    ("right", 0, "fa_cup", [CH_SCORE1, CH_SCORE2]),
    ("right", 1, "uefa_cup", [CH_SCORE1]),
    ("right", 2, "supercup", [CH_SCORE1, CH_SCORE2]),
    ("right", 3, "coca_cola", [CH_SCORE1, CH_SCORE2]),
]

# ---------------------------------------------------------------- END OF SEASON
# Four division blocks. Each has a navy CHAMPION plate (kit + name) on the left, a
# green middle column and a yellow right column; the Premier alone has a second navy
# plate (RUNNER-UP) and its middle column is headed U.E.F.A. CUP instead of PROMOTED,
# and the Third Division has no relegation column at all. Plate counts are the
# chrome's own and are never assumed.
EOS_NAVY = (0, 0, 128)
EOS_GREEN = (192, 220, 192)
EOS_YELLOW = (255, 255, 170)
EOS_PLATE_X = (17, 172)                     # navy plate span (inclusive)
EOS_KIT_X, EOS_KIT_W, EOS_KIT_H = 18, 17, 19
EOS_NAME_PEN_DY = 5
EOS_PLATES = [                              # (y0, pen_x) — pen_x is WITNESSED per plate
    (100, 50),   # Premier CHAMPION
    (137, 50),   # Premier RUNNER-UP
    (219, 49),   # First Division CHAMPION
    (314, 49),   # Second Division CHAMPION
    (418, 48),   # Third Division CHAMPION
]
EOS_PLATE_H = 21
EOS_MID_X = (186, 331)                      # green column plates
EOS_REL_X = (346, 491)                      # yellow column plates
EOS_ROW_H = 12
EOS_MID_ROWS = {                            # tier -> plate tops
    1: [99, 116, 133, 150],
    2: [204, 221, 238],
    3: [294, 311, 328],
    4: [398, 415, 432, 449],
}
EOS_REL_ROWS = {
    1: [99, 116, 133],
    2: [204, 221, 238],
    3: [294, 311, 328, 345],
    4: [],
}
EOS_INK = (0, 0, 0)
EOS_PLATE_INK = (255, 255, 255)
EOS_PEN_DY = 1                              # pen top inside a green/yellow plate

# ------------------------------------------------------------ PLAYERS OF THE YEAR
# Its own screen, NOT the month sheet: the title lives in the top barra, the panel is
# its own size and the four division tabs are a 2x2 grid over a CONTINUE button.
PY_SUBHDR = (96, 105)                       # the black band carrying the division name
PY_PANEL_X = (26, 614)
PY_ROW_Y0, PY_ROW_PITCH, PY_ROWS = 127, 16, 10
PY_ROW_H = 12
PY_COLS = [(34, 178, 182, 309), (330, 474, 478, 605)]   # team x0,x1  player x0,x1
PY_TEAM_INK = (0, 0, 0)
PY_PLAYER_INK = (255, 255, 255)
PY_TABS = [                                 # key, x0, y0, x1, y1
    (1, 380, 345, 491, 369),
    (2, 502, 345, 613, 369),
    (3, 380, 379, 491, 403),
    (4, 502, 379, 613, 403),
]
PY_CONTINUE = (502, 426, 613, 450)


def load(name: str) -> np.ndarray:
    p = REFS / name
    if not p.exists():
        raise SystemExit(f"ERROR: binding frame missing: {p}")
    return np.array(Image.open(p).convert("RGB").crop((0, 0, W, H)))


def expect(cond: bool, what: str) -> None:
    if not cond:
        raise SystemExit(f"ASSERT FAILED: {what}")


def modal(block: np.ndarray) -> np.ndarray:
    vals, counts = np.unique(block.reshape(-1, 3), axis=0, return_counts=True)
    return vals[counts.argmax()].astype("uint8")


def clear_rows(a: np.ndarray, f: np.ndarray, y0: int, y1: int, x0: int, x1: int) -> None:
    """Refill [y0:y1, x0:x1] with EACH ROW's own modal colour inside that span, so a
    graded cell keeps its gradient and only the ink goes."""
    for y in range(y0, y1):
        a[y, x0:x1] = modal(f[y : y + 1, x0:x1])


def save(a: np.ndarray, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(a).save(path)
    print(f"  {path.relative_to(ROOT)}  {a.shape[1]}x{a.shape[0]}")


def bake_championships() -> dict:
    f = load("20_the_championships.png")
    # Refuse to bake against anything but this screen.
    expect(tuple(f[120, 200]) == CH_NAME_BG, "left card row 1 name cell is light blue")
    expect(tuple(f[120, 250]) == CH_SCORE_BG, "left card row 1 score cell is navy")
    expect(tuple(f[120, 565]) == CH_SCORE2_BG, "right card's SECOND score cell is green")
    a = f.copy()
    for side, idx, _comp, cells in CH_SLOTS:
        col = CH_COL[side]
        for row in (0, 1):
            y0 = CH_CARD_TOPS[idx] + (CH_ROW2_DY if row else 0)
            # the club's kit block -> the cell's own light-blue ground
            a[y0 + 1 : y0 + 1 + CH_KIT_H, col["kit_x"] : col["kit_x"] + CH_KIT_W] = CH_NAME_BG
            clear_rows(a, f, y0 + 1, y0 + CH_ROW_H, col["kit_x"] + CH_KIT_W, col["name_x1"] + 1)
            for sx0, sx1 in cells:
                clear_rows(a, f, y0 + 1, y0 + CH_ROW_H, sx0, sx1 + 1)
    save(a, OUT / "championships.png")
    return {
        "binding_frame": "20_the_championships.png",
        "card_tops": CH_CARD_TOPS,
        "row2_dy": CH_ROW2_DY,
        "row_h": CH_ROW_H,
        "kit_wh": [CH_KIT_W, CH_KIT_H],
        "name_pen_dy": CH_NAME_PEN_DY,
        "columns": CH_COL,
        "slots": [{"side": s, "card": i, "comp": c, "scores": [list(x) for x in sc]}
                  for (s, i, c, sc) in CH_SLOTS],
        "winner_ink": list(CH_WIN_INK),
        "loser_ink": list(CH_LOSE_INK),
        "score_ink": list(CH_SCORE_INK),
        # solved with probe_text_anchor.py against this frame:
        "name_font": "proman10",
        "score_font": "proman10",
        # a score centres on x0 + x1 + 1 (both columns and both cards solve on it)
        "score_field_bias": 1,
    }


def bake_end_of_season() -> dict:
    f = load("21_end_of_season.png")
    expect(tuple(f[110, 60]) == EOS_NAVY, "Premier CHAMPION plate is navy")
    expect(tuple(f[103, 250]) == EOS_GREEN, "the middle column's plates are pale green")
    expect(tuple(f[103, 430]) == EOS_YELLOW, "the right column's plates are pale yellow")
    a = f.copy()
    for y0, _pen in EOS_PLATES:
        a[y0 : y0 + EOS_KIT_H, EOS_KIT_X : EOS_KIT_X + EOS_KIT_W] = EOS_NAVY
        clear_rows(a, f, y0 + 1, y0 + EOS_PLATE_H - 1,
                   EOS_KIT_X + EOS_KIT_W, EOS_PLATE_X[1] + 1)
    for rows, span in ((EOS_MID_ROWS, EOS_MID_X), (EOS_REL_ROWS, EOS_REL_X)):
        for _tier, tops in rows.items():
            for y0 in tops:
                clear_rows(a, f, y0 + 1, y0 + EOS_ROW_H, span[0] + 1, span[1])
    save(a, OUT / "endofseason.png")
    return {
        "binding_frame": "21_end_of_season.png",
        "plates": [{"y": y, "pen_x": p} for (y, p) in EOS_PLATES],
        "plate_h": EOS_PLATE_H,
        "plate_x": list(EOS_PLATE_X),
        "kit": {"x": EOS_KIT_X, "w": EOS_KIT_W, "h": EOS_KIT_H},
        "name_pen_dy": EOS_NAME_PEN_DY,
        "mid_x": list(EOS_MID_X),
        "rel_x": list(EOS_REL_X),
        "mid_rows": {str(k): v for k, v in EOS_MID_ROWS.items()},
        "rel_rows": {str(k): v for k, v in EOS_REL_ROWS.items()},
        "row_h": EOS_ROW_H,
        "pen_dy": EOS_PEN_DY,
        "ink": list(EOS_INK),
        "plate_ink": list(EOS_PLATE_INK),
        "font": "proman8",
        # a green/yellow plate centres on x0 + x1 + 1
        "field_bias": 1,
    }


def bake_players_year() -> dict:
    f = load("23_players_of_the_year.png")
    expect(tuple(f[136, 100]) == (160, 180, 200), "row 0 TEAM cell is the pale tint")
    expect(tuple(f[136, 250]) == (42, 63, 170), "row 0 PLAYER cell is navy")
    a = f.copy()
    # the division sub-header (the black band's white caption changes with the tab)
    clear_rows(a, f, PY_SUBHDR[0], PY_SUBHDR[1] + 1, PY_PANEL_X[0] + 2, PY_PANEL_X[1] - 1)
    for r in range(PY_ROWS):
        y = PY_ROW_Y0 + PY_ROW_PITCH * r
        for tx0, tx1, px0, px1 in PY_COLS:
            clear_rows(a, f, y, y + PY_ROW_H, tx0, tx1)
            clear_rows(a, f, y, y + PY_ROW_H, px0, px1)
    save(a, OUT / "players_year.png")
    # The four tab faces, cut verbatim. PREMIER is the only SELECTED face witnessed.
    for key, x0, y0, x1, y1 in PY_TABS:
        save(f[y0 : y1 + 1, x0 : x1 + 1], OUT / f"py_tab_{key}.png")
    return {
        "binding_frame": "23_players_of_the_year.png",
        "subhdr_y": list(PY_SUBHDR),
        "panel_x": list(PY_PANEL_X),
        "row_y0": PY_ROW_Y0,
        "row_pitch": PY_ROW_PITCH,
        "row_h": PY_ROW_H,
        "rows": PY_ROWS,
        "cols": [list(c) for c in PY_COLS],
        "team_ink": list(PY_TEAM_INK),
        "player_ink": list(PY_PLAYER_INK),
        "tabs": [{"tier": k, "rect": [x0, y0, x1 - x0 + 1, y1 - y0 + 1]}
                 for (k, x0, y0, x1, y1) in PY_TABS],
        "continue": [PY_CONTINUE[0], PY_CONTINUE[1],
                     PY_CONTINUE[2] - PY_CONTINUE[0] + 1,
                     PY_CONTINUE[3] - PY_CONTINUE[1] + 1],
    }


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    spec = {
        "championships": bake_championships(),
        "end_of_season": bake_end_of_season(),
        "players_year": bake_players_year(),
    }
    SPEC.parent.mkdir(parents=True, exist_ok=True)
    SPEC.write_text(json.dumps(spec, indent=2) + "\n")
    print(f"  {SPEC.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except SystemExit as e:
        if e.code not in (0, None):
            print(e.code if isinstance(e.code, str) else "", file=sys.stderr)
        raise
