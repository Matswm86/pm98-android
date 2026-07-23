"""Cut the INJURIES populated-row strip out of the real game frame.

Source: `screenshots/wine-captures-2026-07-18-goalscorers/83_injuries_populated.png`
(the only witnessed populated INJURIES row: Bolton's Branagan, week 5).

A populated row repaints a strip of the resting panel — verified by diffing the
witness's row band against the baked resting chrome, which differs in exactly
two spans: x28..48 (the PHYS. treatment button) and x59..610 (the name cell
through COST). x0..27 (panel edge + the vertical section label), x49..58 and the
scrollbar are chrome and stay untouched.

This writes that strip verbatim with ONLY the dynamic value cells blanked to
their own flat fills, the same way every other chrome baker in this tree works,
so InjuriesScreen blits original pixels and overlays nothing but text.

    python3 tools/re/build_injuries_row_from_frame.py
    -> app/art/screens/injuries/row_strip.png  (+ row_strip.json geometry)
"""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "screenshots" / "wine-captures-2026-07-18-goalscorers" / "83_injuries_populated.png"
OUT_PNG = ROOT / "app" / "art" / "screens" / "injuries" / "row_strip.png"
OUT_JSON = ROOT / "app" / "art" / "screens" / "injuries" / "row_strip.json"

# The witnessed row: black borders at y104 and y121, 16 rows of fill between.
Y0, Y1 = 104, 121
X0, X1 = 28, 610  # the strip the row repaints
KEEP_GAP = (49, 58)  # inside the strip but owned by the chrome

# Dynamic value cells -> the flat fill they sit on (measured on the witness).
PALE = (180, 200, 220)
DARK = (80, 100, 120)
CELLS = {
    "name": (60, 158, PALE),
    "type": (180, 356, PALE),
    "week": (358, 385, DARK),
    "h": (387, 408, PALE),
    "price": (410, 482, PALE),
    "insur": (484, 538, PALE),
    "cost": (540, 609, DARK),
}


def main() -> None:
    src = Image.open(SRC).convert("RGBA")
    sp = src.load()
    w, h = X1 - X0 + 1, Y1 - Y0 + 1
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    op = out.load()

    for y in range(Y0, Y1 + 1):
        for x in range(X0, X1 + 1):
            if KEEP_GAP[0] <= x <= KEEP_GAP[1]:
                continue  # chrome shows through
            op[x - X0, y - Y0] = sp[x, y]

    # Blank the value cells to their own fill (borders y0/y-1 stay original).
    for _k, (cx0, cx1, fill) in CELLS.items():
        for y in range(1, h - 1):
            for x in range(cx0, cx1 + 1):
                op[x - X0, y] = (fill[0], fill[1], fill[2], 255)

    OUT_PNG.parent.mkdir(parents=True, exist_ok=True)
    out.save(OUT_PNG)
    OUT_JSON.write_text(
        json.dumps(
            {
                "source": str(SRC.relative_to(ROOT)),
                "strip_x": X0,
                "strip_y_offset": Y0 - 105,  # blit at (X0, row_top + this)
                "row_top": 105,
                "height": h,
                "chrome_gap": list(KEEP_GAP),
                "cells": {k: [v[0], v[1]] for k, v in CELLS.items()},
            },
            indent=2,
        )
        + "\n"
    )
    print(f"wrote {OUT_PNG.relative_to(ROOT)}  {w}x{h}")
    print(f"wrote {OUT_JSON.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
