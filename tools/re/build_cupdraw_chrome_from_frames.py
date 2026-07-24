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

    spec = {
        "source_frames": [str(p.relative_to(ROOT)) for p in (F_MAIN, F_LATE, F_FACUP)],
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
