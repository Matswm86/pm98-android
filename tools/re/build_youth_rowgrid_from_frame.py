#!/usr/bin/env python3
"""Cut the YOUTH TEAM roster row's PLATE + per-cell GRID out of its own live witness.

Until 2026-08-01 no frame in the corpus had ever carried a FILLED youth roster row, so the
port drew its own: black text on the empty row plate, with no cell grid and the empty row's
own left chip. s86 banked the witness -- `tools/re/refs/youth-roster-2026-08-01/
b9_roster_signed_1998-10-03.png`, a TOTAL-level Bolton W career on Saturday 3 October 1998
with one signed youngster on the roster, `Burgess 20 19 20 21 20 [ROL] £5,000 3 3` -- and
closed the row's INKS and COLUMNS off it. The PLATE and the GRID it left open, at
1,816 px on `diff_youth_parity`. This closes them, and nothing here is drawn by hand.

## What the frame says about the row band

Measured, not assumed (`y302..315`, the rule + the 12-px plate + the rule):

* horizontal rules at **y302** and **y315**, grey `(128,128,128)`, x40..444;
* vertical dividers at **x40, 175, 200, 225, 250, 275, 394, 419, 444**, so the cells are
  NAME x41..174, the five parameters at a 25-px pitch x176..299, WAGE x325..393 and the
  TWO year cells x395..418 / x420..443 (one header, two figures -- s86's finding);
* the ROL cell is a **black-bordered box x300..324** whose interior is the camrol icon;
* the plate is flat `(240,240,240)`;
* and the row's LEFT CHIP is not the empty row's: the populated chip differs from the
  empty one directly below it by **162 px** in the same frame, which is exactly the 162 px
  the port was out there. So the chip belongs to the band and is cut with it.

## What is cleared

Only the LIVE cells -- the name, the five parameter figures, the money, the two year
figures -- to the plate colour the frame's own empty rows carry, and the ROL box to BLACK,
which is what the frame holds at every pixel the camrol sprite leaves transparent (the same
backing `build_youth_found_list_from_frames.py` bakes under the PLAYERS FOUND ROL cell).
Nothing is interpolated and nothing outside the cells is touched.

Usage: python3 tools/re/build_youth_rowgrid_from_frame.py [--check]
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
FRAME = (
    ROOT / "tools" / "re" / "refs" / "youth-roster-2026-08-01" / "b9_roster_signed_1998-10-03.png"
)
OUT = ROOT / "app" / "art" / "screens" / "youth" / "row_grid.png"

BAND = (14, 302, 445, 316)  # left, top, right+1, bottom+1 -> 431 x 14
PLATE = (240, 240, 240)
RULE = (128, 128, 128)
RULE_Y = (302, 315)
RULE_X = (40, 444)  # inclusive
DIVIDERS = (40, 175, 200, 225, 250, 275, 394, 419, 444)
ROL = (300, 324)  # inclusive, black-bordered box
# live text cells, x-inclusive, cleared to PLATE over the plate rows y303..314
CELLS = [
    (41, 174),  # NAME
    (176, 199),
    (201, 224),
    (226, 249),
    (251, 274),
    (276, 299),  # SP ST AG QU AV
    (325, 393),  # WAGE
    (395, 418),
    (420, 443),
]  # YEARS / LEFT
EMPTY_ROW_Y = 319  # the plate top of the row below -- the empty twin


def build() -> Image.Image:
    a = np.asarray(Image.open(FRAME).convert("RGBA")).copy()[:480, :640]
    for x0, x1 in CELLS:
        a[303:315, x0 : x1 + 1, :3] = PLATE
    a[BAND[1] : BAND[3], ROL[0] : ROL[1] + 1, :3] = (0, 0, 0)
    return Image.fromarray(a).crop(BAND)


def check() -> int:
    """Re-measure the frame's own invariants instead of trusting the constants."""
    a = np.asarray(Image.open(FRAME).convert("RGB")).astype(int)[:480, :640]
    bad = 0

    for y in RULE_Y:
        row = a[y, RULE_X[0] : RULE_X[1] + 1]
        grey = (row == np.array(RULE)).all(1)
        black = (row == np.array([0, 0, 0])).all(1)  # the ROL box border
        if not (grey | black).all():
            print(f"FAIL: rule row y{y} is not continuous over x{RULE_X[0]}..{RULE_X[1]}")
            bad += 1
    for x in DIVIDERS:
        col = a[BAND[1] : BAND[3], x]
        if not (col == np.array(RULE)).all():
            print(f"FAIL: divider x{x} is not a continuous grey column")
            bad += 1
    for x in ROL:
        col = a[BAND[1] : BAND[3], x]
        if not (col == np.array([0, 0, 0])).all():
            print(f"FAIL: ROL box border x{x} is not a continuous black column")
            bad += 1

    # the row BELOW is empty, and its chip must DIFFER -- that difference is the whole
    # reason the chip is part of this sprite rather than of the baked body.
    chip_full = a[BAND[1] : BAND[3], 14:40]
    chip_empty = a[EMPTY_ROW_Y - 1 : EMPTY_ROW_Y + 13, 14:40]
    n = int((np.abs(chip_full - chip_empty).max(2) > 0).sum())
    if n == 0:
        print("FAIL: the populated row's chip equals the empty row's — no variant to cut")
        bad += 1
    else:
        print(f"CHECK: populated chip differs from the empty one by {n} px")

    # the empty row's own plate must be flat, or 'PLATE' is the wrong clear colour
    if not (a[EMPTY_ROW_Y : EMPTY_ROW_Y + 12, 41:174] == np.array(PLATE)).all():
        print(f"FAIL: the empty row's NAME cell is not flat {PLATE}")
        bad += 1

    print("ROWGRID: 0 FAIL" if not bad else f"ROWGRID: {bad} FAIL")
    return 1 if bad else 0


def main() -> int:
    if "--check" in sys.argv:
        return check()
    rc = check()
    img = build()
    img.save(OUT)
    print(f"wrote {OUT.relative_to(ROOT)} {img.size}")
    return rc


if __name__ == "__main__":
    raise SystemExit(main())
