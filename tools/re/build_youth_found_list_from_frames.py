#!/usr/bin/env python3
"""Cut the YOUTH TEAM "PLAYERS FOUND" LIST widget out of its own live capture.

Until 2026-08-01 the port had never seen this widget un-occluded. The only frame that
carried it -- refrun `p0759_UNKNOWN.png` -- has the contract-offer card on top of it, and
the card DIMS what it covers, so the column inks read off that frame
(AV `(132,26,26)`, WAGE `(100,0,0)`, AGE `(30,52,98)`) are the dimmed values, not the
game's. The row plate colour, the cell grid and the scrollbar were never in evidence at
all and the port drew its own.

B9's wine drive closed that. `tools/re/refs/b9-players-found-2026-08-01/
02_players_found_first.png` is the YOUTH TEAM screen of a TOTAL-level Bolton W career on
Saturday 28 March 1998 with the scout's first report on the panel -- one prospect,
`Chapman  41  [ROL]  GBP5,000  19` -- and nothing over it. Its twin
`03_players_found_last_1999-05-02.png` is the same panel 14 months later and differs from
it by 494 px, ALL of them in the header date/week plaque: the list region is
byte-identical, so the widget is stable and one cut is enough.

What this builder does NOT invent:

* the whole widget rect is copied verbatim from the frame;
* only the five LIVE cells of the populated row are cleared, to the plate colour the
  frame's own empty rows carry (240,240,240);
* the ROL cell is cleared to BLACK, which is what the frame itself carries at every one of
  the 82 pixels camrol10 leaves transparent -- the 25x14 camrol icon sits on a black
  backing, the same backing `build_lineup_chrome_from_frames.py` bakes under the LINE-UP
  screen's own camrol column. Nothing is interpolated.

Two sprites come out, because one filled row cannot distinguish "the cell grid belongs to
slot 0" from "the cell grid belongs to a POPULATED row":

* `found_list.png`   -- the widget as the frame shows it (header labels, the six row
                        plates, slot 0's cell grid, the scrollbar), live cells cleared;
* `found_rowgrid.png` -- slot 0's 14-px grid band on its own, which the port stamps at
                        every populated slot ABOVE the first. With one prospect the render
                        is the frame verbatim; with more, the grid repeats. Declared.

Usage: python3 tools/re/build_youth_found_list_from_frames.py [--check]
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
FRAME = (ROOT / "tools" / "re" / "refs" / "b9-players-found-2026-08-01"
         / "02_players_found_first.png")
TWIN = (ROOT / "tools" / "re" / "refs" / "b9-players-found-2026-08-01"
        / "03_players_found_last_1999-05-02.png")
OUT = ROOT / "app" / "art" / "screens" / "youth"

# The widget, measured off the frame (see the module docstring for the method):
#   x333..x624   the list box incl. its 16-px scrollbar at x609..624
#   y105..y212   the header label row (ink y107..113) down to the last plate's foot
LIST = (333, 105, 625, 213)          # left, top, right+1, bottom+1
ROW0_TOP = 119                       # slot 0's top rule; plate y120..131; foot rule y132
ROW_PITCH = 16
GRID_H = 14                          # rule + 12-px plate + rule
PLATE = (240, 240, 240)
RULE = (128, 128, 128)
# The five cells of a populated row. PLAYER/AV/WAGE/AGE are text; ROL is a 25x14 camrol
# icon whose own black border doubles as the two dividers around it.
CELLS = [(334, 458), (460, 483), (509, 577), (579, 604)]   # text cells, x-inclusive
ROL = (484, 508)


def build() -> tuple[Image.Image, Image.Image]:
    src = Image.open(FRAME).convert("RGBA")
    a = np.asarray(src).copy()

    # --- clear the live cells of slot 0 -------------------------------------------------
    y0, y1 = ROW0_TOP + 1, ROW0_TOP + 12          # the plate rows, 120..131
    for x0, x1 in CELLS:
        a[y0:y1, x0:x1 + 1, :3] = PLATE
    # the ROL cell is a 25x14 BLACK backing the camrol icon is blitted onto, and it
    # overlaps the row's own two rules -- black is what the frame has under the sprite
    a[ROW0_TOP:ROW0_TOP + 14, ROL[0]:ROL[1] + 1, :3] = (0, 0, 0)

    cleared = Image.fromarray(a)
    widget = cleared.crop(LIST)
    grid = cleared.crop((LIST[0], ROW0_TOP, LIST[2], ROW0_TOP + GRID_H))
    return widget, grid


def check() -> int:
    """The frame's own invariants, re-measured rather than trusted."""
    a = np.asarray(Image.open(FRAME).convert("RGB")).astype(int)
    b = np.asarray(Image.open(TWIN).convert("RGB")).astype(int)
    bad = 0

    d = np.abs(a - b).sum(2) > 0
    if d[LIST[1]:LIST[3], LIST[0]:LIST[2]].sum():
        print("FAIL: the two witnesses disagree inside the list rect")
        bad += 1

    # six plates, pitch 16, 12 rows tall, x334..604
    for i in range(6):
        top = ROW0_TOP + 1 + i * ROW_PITCH
        band = a[top:top + 12, 334:605]
        if i == 0:
            continue                              # slot 0 is the populated one
        if not (band == np.array(PLATE)).all():
            print(f"FAIL: slot {i} plate is not flat {PLATE}")
            bad += 1

    # slot 0's grid: rules at y119/y132, dividers at x333/x459/x578/x605
    for y in (ROW0_TOP, ROW0_TOP + 13):
        row = a[y, 333:606]
        grey = (row == np.array(RULE)).all(1)
        black = (row == np.array([0, 0, 0])).all(1)          # the ROL icon border
        if not (grey | black).all():
            print(f"FAIL: rule row y{y} is not continuous")
            bad += 1
    for x in (333, 459, 578, 605):
        col = a[ROW0_TOP:ROW0_TOP + 14, x]
        if not (col == np.array(RULE)).all():
            print(f"FAIL: divider x{x} is not continuous grey")
            bad += 1

    # the ROL icon IS the port's own camrol sprite, unmodified
    icons = sorted((ROOT / "app" / "art" / "icons" / "camrol").glob("camrol*.png"))
    cut = a[ROW0_TOP:ROW0_TOP + 14, ROL[0]:ROL[1] + 1]
    hits = []
    for f in icons:
        arr = np.asarray(Image.open(f).convert("RGBA")).astype(int)
        opaque = arr[..., 3] > 0
        if not ((np.abs(arr[..., :3] - cut).max(2) > 0) & opaque).sum():
            hits.append(f.name)
    if hits != ["camrol10.png"]:
        print(f"FAIL: ROL cell matched {hits or 'no camrol sprite'}, expected camrol10.png")
        bad += 1

    print("CHECK: 0 FAIL" if not bad else f"CHECK: {bad} FAIL")
    return 1 if bad else 0


def main() -> int:
    if "--check" in sys.argv:
        return check()
    rc = check()
    widget, grid = build()
    OUT.mkdir(parents=True, exist_ok=True)
    widget.save(OUT / "found_list.png")
    grid.save(OUT / "found_rowgrid.png")
    print(f"wrote {OUT / 'found_list.png'} {widget.size}")
    print(f"wrote {OUT / 'found_rowgrid.png'} {grid.size}")
    return rc


if __name__ == "__main__":
    raise SystemExit(main())
