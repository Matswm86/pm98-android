#!/usr/bin/env python3
"""Render-diff the ported LINE-UP -> STATISTICS season table against the wine witness.

    python3 tools/re/diff_statistics_parity.py <app.png> <witness.png> [out_dir]

Witness: screenshots/wine-captures-2026-07-24-cadence-season-store/
         01_season_store_before_7matches.png (real MANAGER.EXE, Man Utd, 7 matches in).

Masked, with the reason for each mask:
  * the shared barra (y < 62) -- live career chrome (date panel, competition plate,
    opponent crest), not this screen's own drawing. Masked on every parity run here.
  * the RETURN button (505,446,128,30) -- the witness caught it mid-hover-highlight.
  * the scroll thumb track, x577..592 y126..411 -- the witness's squad is longer than
    the 19 visible slots and its thumb is sized/positioned to that. The port draws no
    thumb because it does NOT scroll this list (statistics_screen_re.md: "only the 19
    visible slots are drawn, no invented per-section scrolling"), so the thumb is the
    visual signature of a missing feature, not of a mis-drawn table. It is the ONLY
    masked pixel inside the table and is tracked as the screen's remaining gap.
Everything else, including all 19 row slots and the TEAM TOTAL row, is compared.
Exit code 1 when the table region is not pixel-identical.
"""

from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image

BARRA_H = 62
RETURN_BOX = (505, 446, 633, 476)
# Scroll thumb track (see the module docstring): the port does not scroll this list.
SCROLL_BOX = (577, 126, 593, 412)
# The table card itself: the region this screen is responsible for drawing.
TABLE_BOX = (8, 62, 632, 470)
# Per-row bands, for a readable failure report: 19 slots at 111 + 16i, plus TEAM TOTAL.
ROW_TOPS = [111 + 16 * i for i in range(19)]
TOTAL_TOP = 425


def load(p: str) -> Image.Image:
    im = Image.open(p).convert("RGB")
    if im.size != (640, 480):
        raise SystemExit(f"{p}: expected 640x480, got {im.size}")
    return im


def main() -> None:
    app = load(sys.argv[1])
    wit = load(sys.argv[2])
    out = Path(sys.argv[3] if len(sys.argv) > 3 else "/tmp")

    a = app.load()
    w = wit.load()
    diff = Image.new("RGB", (640, 480), (0, 0, 0))
    d = diff.load()

    x0, y0, x1, y1 = TABLE_BOX
    total = 0
    bad: dict[str, int] = {}
    for y in range(max(y0, BARRA_H), y1):
        for x in range(x0, x1):
            if RETURN_BOX[0] <= x < RETURN_BOX[2] and RETURN_BOX[1] <= y < RETURN_BOX[3]:
                continue
            if SCROLL_BOX[0] <= x < SCROLL_BOX[2] and SCROLL_BOX[1] <= y < SCROLL_BOX[3]:
                continue
            if a[x, y] != w[x, y]:
                total += 1
                d[x, y] = (255, 0, 0)
                label = "chrome"
                for i, t in enumerate(ROW_TOPS):
                    if t <= y < t + 13:
                        label = f"row{i:02d}"
                        break
                else:
                    if TOTAL_TOP <= y < TOTAL_TOP + 13:
                        label = "TEAM TOTAL"
                bad[label] = bad.get(label, 0) + 1

    area = (x1 - x0) * (y1 - max(y0, BARRA_H))
    print(f"table region {TABLE_BOX}: {total} differing pixels of {area}")
    for k in sorted(bad, key=lambda k: -bad[k]):
        print(f"  {k:<12} {bad[k]}")
    if total:
        diff.save(out / "diff_statistics.png")
        print(f"diff mask -> {out / 'diff_statistics.png'}")
    raise SystemExit(1 if total else 0)


main()
