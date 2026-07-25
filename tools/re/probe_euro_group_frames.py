"""Read the EURO. LEAGUE group frames back out as data.

Prints, per frame: the four table rows' cell backgrounds, and for the two results rows the
two score boxes' ink colours. Used to settle which goal digit the original inks yellow --
the "winner's goals" reading is retracted (docs/re/euro_league_screen_re.md) and the rule
is still open, so this dumps the evidence rather than asserting one.

Usage: python tools/re/probe_euro_group_frames.py [frames...]
"""

from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image

REPO = Path(__file__).resolve().parents[2]
REFS = REPO / "tools/re/refs/euro-competitions-2026-07-25"

YELLOW = (255, 255, 0)
# Measured 2026-07-25 (docs/re/euro_league_screen_re.md): two results rows, pitch 22,
# bar height 13; the two black score boxes at x181..196 and x199..214.
ROW_TOPS = (278, 300)
BOX_X = ((181, 196), (199, 214))
BAR_H = 13


def ink_of(im: Image.Image, x0: int, x1: int, y0: int, y1: int) -> tuple:
    """The most common non-background colour inside a score box (its digit's ink)."""
    hist: dict = {}
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            p = im.getpixel((x, y))
            hist[p] = hist.get(p, 0) + 1
    ranked = sorted(hist.items(), key=lambda kv: -kv[1])
    bg = ranked[0][0]
    for col, n in ranked[1:]:
        if n >= 4:  # a digit is far more than 4 px; noise is not
            return col, n, bg
    return bg, 0, bg


def main() -> None:
    frames = [Path(a) for a in sys.argv[1:]] or sorted(REFS.glob("1*_euroleague_group_*.png"))
    for f in frames:
        im = Image.open(f).convert("RGB")
        print(f"== {f.name}")
        for r, top in enumerate(ROW_TOPS):
            marks = []
            for b, (x0, x1) in enumerate(BOX_X):
                col, n, bg = ink_of(im, x0, x1, top, top + BAR_H - 1)
                marks.append(f"box{b + 1}={col} n={n}{' <-YELLOW' if col == YELLOW else ''}")
            print(f"   row{r + 1} y{top}: " + " | ".join(marks))


if __name__ == "__main__":
    main()
