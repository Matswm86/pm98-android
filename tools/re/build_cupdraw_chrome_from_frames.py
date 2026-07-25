#!/usr/bin/env python3
"""Bake the SORTEO (cup-draw) screen chrome from the real game's own frames.

Binding frames -- three, all captured from the real MANAGER.EXE under Wine:

  74_after_wk4.png   wine-captures-2026-07-18-goalscorers (Bolton W, Manager League):
                     Coca-Cola Cup ROUND 2, four ties drawn, the fourth still waiting
                     for its away club ("Coventry -"). PRIMARY -- the bake is this frame.
  75_scout_wk5.png   the same draw a moment later: nine ties, ninth waiting. Proves the
                     list fills progressively and that the scrollbar does NOT move while
                     it fills. (Its row 17 is white -- a mouse-hover highlight, excluded.)
  10_fa_cup_draw_round1.png  promanager-career-2026-07-16 (Brighton, 3rd Div.):
                     F.A. Cup ROUND 1. Different competition, title, strip, drum frame,
                     tie count and bottom-left labels -- the second half of every diff.

Doctrine (docs/re/SPEC_BINDING.md): the chrome layer IS the original frame with ONLY
the state-dependent pixels cleared. Everything the three frames agree on is static and
is kept byte-for-byte -- the bezelled panels, the green MATCHES header and its checker
rail, all 23 row separators, the scrollbar arrows, FINISH and CONTINUE.

Cleared, and why (all frame-absolute):

  picture window (31,76) 260x144   the competition strip + drum backdrop + drum frame.
                                   Filled BLACK, which is what the game clears it to
                                   (measured: every pixel no layer covers is (0,0,0)).
                                   Redrawn from the real art by export_sorteo_art.py.
  title plate    (44,34)-(288,58)   the competition name (ProMan14, white, centred 161)
  ROUND plate    (44,232)-(288,254) the round label (ProMan14, (255,223,0), centred 158)
  leg plates     (26,410)/(26,437)  1ST LEG / 2ND LEG on a two-legged tie, MATCH / REPLAY
                                    on a single one (ProMan10, (255,255,0), centred 57)
  MATCHES rows   x334..605, 23 rows the drawn ties (ProMan10, (80,100,120))
  scroll trough  x606..623 y70..401 the proportional thumb

The plates are DITHERED (44,44,44)/(80,80,80) noise, so a flat refill would show. They
are cleared by UNION instead: a pixel is taken from frame 74 unless 74 has ink there, in
which case it comes from frame 10 -- the same screen, so outside the ink the two frames
are pixel-identical and the recovered texture is the ORIGINAL's, not a synthesis. Only
pixels where BOTH frames ink (the centred titles overlap) need the row's modal colour;
the count is printed and asserted small. The list rows need no such trick: their
background is the flat (200,220,240) the game itself paints.

Outputs (app/art/screens/cupdraw/):
  chrome.png                              the 640x480 screen, dynamic spans cleared
  tools/re/specs/cupdraw_chrome_samples.json   geometry + colours + hit rects

Run:  python3 tools/re/build_cupdraw_chrome_from_frames.py
"""

from __future__ import annotations

import json
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
WCAP = ROOT / "screenshots" / "wine-captures-2026-07-18-goalscorers"
PCAP = ROOT / "screenshots" / "promanager-career-2026-07-16"
OUT = ROOT / "app" / "art" / "screens" / "cupdraw"
SPEC = ROOT / "tools" / "re" / "specs" / "cupdraw_chrome_samples.json"

F_MAIN = WCAP / "74_after_wk4.png"
F_LATE = WCAP / "75_scout_wk5.png"
F_FACUP = PCAP / "10_fa_cup_draw_round1.png"

# ---- the SECOND panel form (REFRUN R8) -------------------------------------
# The MATCHES panel has TWO forms and the switch is LIST LENGTH: a round of MORE than 16
# ties draws one centred `Home - Away` line per tie over 23 scrollable rows (the form
# above); a round of 16 or fewer draws a 16-row GRID of four columns -- home kit, home
# club, away club, away kit -- with no scrollbar at all.
#
# Binding frames, both EMPTY grids, so the bake has no list ink to clear:
#   p0125  Coca-Cola Cup ROUND 3, grid drawn, no tie yet -- PRIMARY, the bake is this
#   p0747  U.E.F.A. Cup 1/16 FINAL -- the plate-recovery partner. p0445 (F.A. Cup ROUND
#          4) is the other empty grid, but "ROUND 4" inks almost exactly where "ROUND 3"
#          does, so it recovers nothing; "1/16 FINAL" and "U.E.F.A. CUP" do.
# and two POPULATED frames the geometry and the text anchors were solved against:
#   p0133  the same Coca-Cola round with all 16 ties, the manager's own tie marked
#   p0747  the tie-detail card filled in (F.C. Barcelona / Van Gaal v Karlsruher)
REFS = ROOT / "tools" / "re" / "refs" / "refrun-manutd-1997-98"
G_MAIN = REFS / "p0125_cup_draw.png"
G_ALT = REFS / "p0747_cup_draw.png"
G_ALT2 = REFS / "p0445_cup_draw.png"

# ---- geometry, all measured off the frames ---------------------------------
PICTURE = (31, 76, 260, 144)  # x, y, w, h -- cleared to black
STRIP_AT = (31, 76)  # the competition's 72x144 SORTEO strip
FONDO_AT = (103, 76)  # the 188x144 drum backdrop
BOMBO_AT = (136, 76)  # the 92x92 drum frame, blitted OPAQUE

TITLE_SPAN = (44, 34, 288, 58)  # x0, y0, x1, y1 (exclusive)
TITLE_CENTRE = 161  # ink centre of BOTH witnessed titles
TITLE_TOP = 40  # ink top row of BOTH witnessed titles
C_TITLE = (255, 255, 255)

ROUND_SPAN = (44, 232, 288, 254)
ROUND_CENTRE = 158
ROUND_TOP = 237
C_ROUND = (255, 223, 0)

LEG_SPANS = [(26, 410, 90, 426), (26, 437, 90, 453)]
LEG_CENTRE = 57
LEG_TOPS = [415, 442]
C_LEG = (255, 255, 0)

LIST_X = (334, 606)  # the row band, black borders at 332-333 and 606
LIST_Y0, LIST_PITCH, LIST_ROWS = 51, 16, 23  # row k spans y0+16k .. y0+16k+14
LIST_TEXT_TOP = 3  # ink top row inside the row band (row 0 ink starts y 54)
C_ROW_BG = (200, 220, 240)
C_ROW_TXT = (80, 100, 120)
HOME_RIGHT = 465  # home club's pen END x (right-aligned)
DASH_X = 466  # the fixed "-" between the two clubs
AWAY_LEFT = 475  # away club's pen START x

SCROLL_X = (606, 624)  # the trough box is 18px wide: 606 and 622-623 are the thumb's
SCROLL_Y = (70, 402)  # own black edges, not the panel border; 69 and 402 are static bevels
C_TROUGH = (180, 200, 220)

BTN_FINISH = (350, 440, 462, 464)
BTN_CONTINUE = (492, 438, 610, 466)

# ---- grid form geometry, off the frames' own black borders ------------------
# Column borders at x332-333 / 355 / 477-478 / 600 / 622-623; row separators every 23px
# from y49-50 to y418-419, so 16 rows of 22.
GRID_Y0, GRID_PITCH, GRID_ROWS = 51, 23, 16
GRID_ROW_H = 22
GRID_KIT_L = (334, 355)      # home kit cell (x0, x1 exclusive)
GRID_HOME = (356, 477)       # home club cell
GRID_AWAY = (479, 600)       # away club cell
GRID_KIT_R = (601, 622)      # away kit cell
# Row bands alternate, and the INK follows the band. The manager's own tie takes a dark
# plate with his club's name in bright yellow; a highlighted row goes white. All four
# states are witnessed across p0125 / p0133 / p0747.
C_GRID_BG = [(200, 220, 240), (160, 180, 200)]
C_GRID_KIT_BG = [(180, 200, 220), (140, 160, 180)]
C_GRID_INK = [(100, 120, 140), (60, 80, 100)]
C_GRID_OWN_BG = (60, 60, 100)
C_GRID_OWN_INK = (255, 255, 85)
C_GRID_SEL_BG = (255, 255, 255)

# ---- the tie-detail card (bottom-left panel), solved with probe_text_anchor.py ------
# Every line centres on its own field sum and every font came out at ZERO differing
# pixels against BOTH populated frames.
CARD_CLUB_SUM, CARD_CLUB_TOPS, CARD_CLUB_FONT = 325, (323, 361), "proman10"
CARD_MGR_SUM, CARD_MGR_TOPS, CARD_MGR_FONT = 325, (335, 373), "calend12"
CARD_STADIUM_SUM, CARD_STADIUM_TOPS, CARD_STADIUM_FONT = 398, (411, 438), "proman10"
C_CARD_CLUB = (255, 223, 0)
C_CARD_MGR = (166, 202, 240)
C_CARD_MGR_OWN = (42, 191, 85)      # the MANAGER'S OWN name, witnessed on "MWM"
C_CARD_STADIUM = (42, 191, 255)
CARD_KIT_L = (33, 325, 110, 381)    # x0, y0, x1, y1 -- the home club's kit panel
CARD_KIT_R = (236, 329, 287, 385)   # the away club's


def load(p: Path) -> np.ndarray:
    return np.array(Image.open(p).convert("RGB"))[:, :640]


def expect(cond: bool, what: str) -> None:
    if not cond:
        raise SystemExit(f"ASSERT FAILED: {what}")


def modal(block: np.ndarray) -> np.ndarray:
    vals, counts = np.unique(block.reshape(-1, 3), axis=0, return_counts=True)
    return vals[counts.argmax()].astype("uint8")


def clear_by_union(
    a: np.ndarray,
    main: np.ndarray,
    alt: np.ndarray,
    span: tuple[int, int, int, int],
    ink: tuple[int, int, int],
) -> int:
    """Replace `main`'s ink inside `span` with `alt`'s pixels. Where BOTH frames ink the
    same pixel, borrow the nearest ink-free pixel on the SAME row of the same plate --
    the plate face is a 2-colour dither, so a same-row neighbour is the real texture,
    where a modal refill would flatten it to a solid block. Returns the borrowed count."""
    x0, y0, x1, y1 = span
    ink_a = (main[y0:y1, x0:x1] == np.array(ink)).all(axis=2)
    ink_b = (alt[y0:y1, x0:x1] == np.array(ink)).all(axis=2)
    clean = ~ink_a & ~ink_b
    both = 0
    for r in range(y1 - y0):
        free = np.where(clean[r])[0]
        for c in np.where(ink_a[r])[0]:
            if not ink_b[r, c]:
                a[y0 + r, x0 + c] = alt[y0 + r, x0 + c]
                continue
            if free.size == 0:
                a[y0 + r, x0 + c] = modal(alt[y0 + r : y0 + r + 1, x0:x1])
            else:
                a[y0 + r, x0 + c] = main[y0 + r, x0 + int(free[np.abs(free - c).argmin()])]
            both += 1
    return both


def bake_grid() -> dict:
    """The <=16-tie GRID form (REFRUN R8). Both binding frames are EMPTY grids, so the
    only spans this has to clear are the picture window and the three dithered plates --
    the sixteen rows and the tie-detail card are already the original's own blank state."""
    if not G_MAIN.exists() or not G_ALT.exists() or not G_ALT2.exists():
        raise SystemExit(f"ASSERT FAILED: grid binding frames missing under {REFS}")
    f = load(G_MAIN)
    alt = load(G_ALT)
    alt2 = load(G_ALT2)
    # p0445 is a second EMPTY grid on a different competition: it proves the grid
    # furniture itself is static before any of it is trusted as chrome.
    grid_static = (f[GRID_Y0:419, 334:622] == alt2[GRID_Y0:419, 334:622]).all()
    expect(bool(grid_static), "the two empty grids are pixel-identical in the panel")
    expect(tuple(f[60, 400]) == C_GRID_BG[0], "grid row 0 is the light band")
    expect(tuple(f[83, 400]) == C_GRID_BG[1], "grid row 1 is the darker band")
    expect(tuple(f[60, 345]) == C_GRID_KIT_BG[0], "grid row 0's kit cell is a shade darker")
    for k in range(GRID_ROWS - 1):
        sep = GRID_Y0 + GRID_PITCH * k + 22
        expect(tuple(f[sep, 400]) == (0, 0, 0), f"grid row separator at y={sep}")
    a = f.copy()
    px, py, pw, ph = PICTURE
    a[py : py + ph, px : px + pw] = (0, 0, 0)
    both = clear_by_union(a, f, alt, TITLE_SPAN, C_TITLE)
    both += clear_by_union(a, f, alt, ROUND_SPAN, C_ROUND)
    both += sum(clear_by_union(a, f, alt, s, C_LEG) for s in LEG_SPANS)
    print(f"  grid plates cleared — both-ink fallback px: {both}")
    # The LEG plates are the same two words on both frames (MATCH / REPLAY v 1ST LEG /
    # 2ND LEG share strokes), so their overlap is inherently higher than the list form's.
    expect(both < 1000, "the two grid titles overlap only partially")
    Image.fromarray(a).save(OUT / "chrome_grid.png")
    print(f"  {(OUT / 'chrome_grid.png').relative_to(ROOT)}  {a.shape[1]}x{a.shape[0]}")
    return {
        "source_frames": [str(p.relative_to(ROOT)) for p in (G_MAIN, G_ALT, G_ALT2)],
        "rows": GRID_ROWS,
        "y0": GRID_Y0,
        "pitch": GRID_PITCH,
        "row_h": GRID_ROW_H,
        "kit_left": list(GRID_KIT_L),
        "home": list(GRID_HOME),
        "away": list(GRID_AWAY),
        "kit_right": list(GRID_KIT_R),
        "band_bg": [list(c) for c in C_GRID_BG],
        "band_kit_bg": [list(c) for c in C_GRID_KIT_BG],
        "band_ink": [list(c) for c in C_GRID_INK],
        "own_bg": list(C_GRID_OWN_BG),
        "own_ink": list(C_GRID_OWN_INK),
        "selected_bg": list(C_GRID_SEL_BG),
        "switch": "grid when the round has <= 16 ties, the scrollable list otherwise",
    }


def card_spec() -> dict:
    return {
        "club": {"field_sum": CARD_CLUB_SUM, "tops": list(CARD_CLUB_TOPS),
                 "font": CARD_CLUB_FONT, "colour": list(C_CARD_CLUB)},
        "manager": {"field_sum": CARD_MGR_SUM, "tops": list(CARD_MGR_TOPS),
                    "font": CARD_MGR_FONT, "colour": list(C_CARD_MGR),
                    "own_colour": list(C_CARD_MGR_OWN)},
        "stadium": {"field_sum": CARD_STADIUM_SUM, "tops": list(CARD_STADIUM_TOPS),
                    "font": CARD_STADIUM_FONT, "colour": list(C_CARD_STADIUM)},
        "kit_left": list(CARD_KIT_L),
        "kit_right": list(CARD_KIT_R),
    }


def main() -> None:
    f = load(F_MAIN)
    late = load(F_LATE)
    fa = load(F_FACUP)

    # The three frames must actually BE the same screen, or none of this holds.
    static = (f == fa).all(axis=2) & (f == late).all(axis=2)
    expect(bool(static[300, 100]), "the three frames agree on the bottom-left panel face")
    expect(tuple(f[30, 340]) == (80, 110, 5), "the MATCHES header band starts dark green")
    expect(tuple(f[30, 598]) == (120, 150, 20), "the MATCHES header band lightens rightward")
    expect(tuple(f[60, 400]) == C_ROW_BG, "list row background is (200,220,240)")
    for k in range(LIST_ROWS - 1):
        sep = LIST_Y0 + LIST_PITCH * k + 15
        expect(tuple(f[sep, 400]) == (0, 0, 0), f"row separator at y={sep}")

    a = f.copy()

    # 1. picture window -> black (the game's own clear colour under every layer)
    px, py, pw, ph = PICTURE
    a[py : py + ph, px : px + pw] = (0, 0, 0)

    # 2/3/4. the three dithered plates, recovered from the other frame
    both_t = clear_by_union(a, f, fa, TITLE_SPAN, C_TITLE)
    both_r = clear_by_union(a, f, fa, ROUND_SPAN, C_ROUND)
    both_l = sum(clear_by_union(a, f, fa, s, C_LEG) for s in LEG_SPANS)
    print(f"  plates cleared — both-ink fallback px: title {both_t}, round {both_r}, legs {both_l}")
    expect(both_t + both_r + both_l < 900, "the two titles overlap only partially")

    # 5. the MATCHES rows: flat background, so an exact refill
    x0, x1 = LIST_X
    for k in range(LIST_ROWS):
        ry = LIST_Y0 + LIST_PITCH * k
        band = a[ry : ry + 15, x0:x1]
        band[(band == np.array(C_ROW_TXT)).all(axis=2)] = C_ROW_BG

    # 6. the scrollbar thumb -> empty trough
    a[SCROLL_Y[0] : SCROLL_Y[1], SCROLL_X[0] : SCROLL_X[1]] = C_TROUGH

    OUT.mkdir(parents=True, exist_ok=True)
    Image.fromarray(a).save(OUT / "chrome.png")
    print(f"  {(OUT / 'chrome.png').relative_to(ROOT)}  {a.shape[1]}x{a.shape[0]}")

    grid = bake_grid()
    spec = {
        "source_frames": [str(p.relative_to(ROOT)) for p in (F_MAIN, F_LATE, F_FACUP)],
        "grid": grid,
        "tie_card": card_spec(),
        "picture": {
            "rect": list(PICTURE),
            "clear": [0, 0, 0],
            "strip_at": list(STRIP_AT),
            "fondo_at": list(FONDO_AT),
            "bombo_at": list(BOMBO_AT),
            "bombo_opaque": True,
            "palette": "MANAGER.PAL",
        },
        "title": {
            "span": list(TITLE_SPAN),
            "centre": TITLE_CENTRE,
            "top": TITLE_TOP,
            "font": "proman14",
            "colour": list(C_TITLE),
        },
        "round": {
            "span": list(ROUND_SPAN),
            "centre": ROUND_CENTRE,
            "top": ROUND_TOP,
            "font": "proman14",
            "colour": list(C_ROUND),
        },
        "legs": {
            "spans": [list(s) for s in LEG_SPANS],
            "centre": LEG_CENTRE,
            "tops": LEG_TOPS,
            "font": "proman10",
            "colour": list(C_LEG),
        },
        "list": {
            "x": list(LIST_X),
            "y0": LIST_Y0,
            "pitch": LIST_PITCH,
            "rows": LIST_ROWS,
            "text_top": LIST_TEXT_TOP,
            "font": "proman10",
            "colour": list(C_ROW_TXT),
            "bg": list(C_ROW_BG),
            "home_right": HOME_RIGHT,
            "dash_x": DASH_X,
            "away_left": AWAY_LEFT,
        },
        "scroll": {"x": list(SCROLL_X), "y": list(SCROLL_Y), "trough": list(C_TROUGH)},
        "buttons": {"finish": list(BTN_FINISH), "continue": list(BTN_CONTINUE)},
    }
    SPEC.parent.mkdir(parents=True, exist_ok=True)
    SPEC.write_text(json.dumps(spec, indent=2) + "\n")
    print(f"  {SPEC.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
