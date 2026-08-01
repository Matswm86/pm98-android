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

Two sprites come out, and 2026-08-01 (s87) SETTLED which of them owns the cell grid.
One filled row could not distinguish "the grid belongs to slot 0" from "the grid belongs to
a POPULATED row", so the port stamped it per populated row and said so. The ROSTER witness
`tools/re/refs/youth-roster-2026-08-01/b9_roster_signed_1998-10-03.png` is the second
witness that was missing: the SAME career with an EMPTY panel. Measured, not read --

    the two frames differ inside the list rect by 1,270 px and every one of them is in
    y119..132, x333..605, i.e. slot 0's grid band alone; all SIX plates of the empty
    frame are flat (240,240,240).

So the grid belongs to the POPULATED row. The idle widget carries none, and it is
`found_list.png`:

* `found_list.png`    -- the IDLE widget, copied verbatim from the ROSTER witness (header
                         labels, six flat plates, the scrollbar). Nothing cleared: the
                         frame's own panel is already empty.
* `found_rowgrid.png` -- the 14-px grid band cut from the POPULATED frame's slot 0 with its
                         live cells cleared, stamped at EVERY populated slot. Cropped to
                         x333..605 so it never repaints the scrollbar column, whose top
                         arrow sits inside slot 0's band.

Usage: python3 tools/re/build_youth_found_list_from_frames.py [--check]
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
FRAME = (
    ROOT / "tools" / "re" / "refs" / "b9-players-found-2026-08-01" / "02_players_found_first.png"
)
TWIN = (
    ROOT
    / "tools"
    / "re"
    / "refs"
    / "b9-players-found-2026-08-01"
    / "03_players_found_last_1999-05-02.png"
)
# The IDLE witness -- the same screen with the panel EMPTY (the prospect signed and gone
# onto the roster). It is what `found_list.png` is cut from, and its disagreement with
# FRAME is what proves the grid is the populated row's.
IDLE = (
    ROOT / "tools" / "re" / "refs" / "youth-roster-2026-08-01" / "b9_roster_signed_1998-10-03.png"
)
OUT = ROOT / "app" / "art" / "screens" / "youth"

# The widget, measured off the frame (see the module docstring for the method):
#   x333..x624   the list box incl. its 16-px scrollbar at x609..624
#   y105..y212   the header label row (ink y107..113) down to the last plate's foot
LIST = (333, 105, 625, 213)  # left, top, right+1, bottom+1
ROW0_TOP = 119  # slot 0's top rule; plate y120..131; foot rule y132
ROW_PITCH = 16
GRID_H = 14  # rule + 12-px plate + rule
GRID_RIGHT = 606  # x333..605 inclusive -- the plates, NOT the scrollbar
PLATE = (240, 240, 240)
RULE = (128, 128, 128)
# The five cells of a populated row. PLAYER/AV/WAGE/AGE are text; ROL is a 25x14 camrol
# icon whose own black border doubles as the two dividers around it.
CELLS = [(334, 458), (460, 483), (509, 577), (579, 604)]  # text cells, x-inclusive
ROL = (484, 508)


def build() -> tuple[Image.Image, Image.Image]:
    # The IDLE widget is a straight copy -- the frame's own panel is already empty, so
    # there is nothing to clear and nothing to reconstruct.
    widget = Image.open(IDLE).convert("RGBA").crop(LIST)

    # The populated row's grid comes off the POPULATED frame, live cells cleared.
    a = np.asarray(Image.open(FRAME).convert("RGBA")).copy()
    y0, y1 = ROW0_TOP + 1, ROW0_TOP + 12  # the plate rows, 120..131
    for x0, x1 in CELLS:
        a[y0:y1, x0 : x1 + 1, :3] = PLATE
    # the ROL cell is a 25x14 BLACK backing the camrol icon is blitted onto, and it
    # overlaps the row's own two rules -- black is what the frame has under the sprite
    a[ROW0_TOP : ROW0_TOP + 14, ROL[0] : ROL[1] + 1, :3] = (0, 0, 0)
    # x333..605 only: the scrollbar column x606..624 carries the box's TOP ARROW inside
    # slot 0's band, and stamping that at slot 3 would draw a second arrow there.
    grid = Image.fromarray(a).crop((LIST[0], ROW0_TOP, GRID_RIGHT, ROW0_TOP + GRID_H))
    return widget, grid


def check() -> int:
    """The frame's own invariants, re-measured rather than trusted."""
    a = np.asarray(Image.open(FRAME).convert("RGB")).astype(int)
    b = np.asarray(Image.open(TWIN).convert("RGB")).astype(int)
    bad = 0

    d = np.abs(a - b).sum(2) > 0
    if d[LIST[1] : LIST[3], LIST[0] : LIST[2]].sum():
        print("FAIL: the two witnesses disagree inside the list rect")
        bad += 1

    # --- the grid-ownership proof (s87) -------------------------------------------------
    # POPULATED vs IDLE must differ inside the list rect ONLY in slot 0's grid band, and
    # every plate of the IDLE frame must be flat. Either half failing means the sprite
    # split below is no longer what the frames say.
    # the 2026-07 wine captures are 641 px wide (one black column at x640) -- crop, don't
    # resize, so no pixel moves.
    c = np.asarray(Image.open(IDLE).convert("RGB")).astype(int)[:480, :640]
    di = (np.abs(a[:480, :640] - c).max(2) > 0)[LIST[1] : LIST[3], LIST[0] : LIST[2]]
    ys, xs = np.nonzero(di)
    if not di.sum():
        print("FAIL: POPULATED and IDLE agree everywhere - one of them is the wrong frame")
        bad += 1
    elif (ys.min() + LIST[1], ys.max() + LIST[1]) != (ROW0_TOP, ROW0_TOP + 13):
        print(
            f"FAIL: POPULATED-vs-IDLE spills outside slot 0's band "
            f"(y{ys.min() + LIST[1]}..{ys.max() + LIST[1]})"
        )
        bad += 1
    for i in range(6):
        top = ROW0_TOP + 1 + i * ROW_PITCH
        if not (c[top : top + 12, 334:605] == np.array(PLATE)).all():
            print(f"FAIL: IDLE slot {i} plate is not flat {PLATE}")
            bad += 1

    # six plates, pitch 16, 12 rows tall, x334..604
    for i in range(6):
        top = ROW0_TOP + 1 + i * ROW_PITCH
        band = a[top : top + 12, 334:605]
        if i == 0:
            continue  # slot 0 is the populated one
        if not (band == np.array(PLATE)).all():
            print(f"FAIL: slot {i} plate is not flat {PLATE}")
            bad += 1

    # slot 0's grid: rules at y119/y132, dividers at x333/x459/x578/x605
    for y in (ROW0_TOP, ROW0_TOP + 13):
        row = a[y, 333:606]
        grey = (row == np.array(RULE)).all(1)
        black = (row == np.array([0, 0, 0])).all(1)  # the ROL icon border
        if not (grey | black).all():
            print(f"FAIL: rule row y{y} is not continuous")
            bad += 1
    for x in (333, 459, 578, 605):
        col = a[ROW0_TOP : ROW0_TOP + 14, x]
        if not (col == np.array(RULE)).all():
            print(f"FAIL: divider x{x} is not continuous grey")
            bad += 1

    # the ROL icon IS the port's own camrol sprite, unmodified
    icons = sorted((ROOT / "app" / "art" / "icons" / "camrol").glob("camrol*.png"))
    cut = a[ROW0_TOP : ROW0_TOP + 14, ROL[0] : ROL[1] + 1]
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
