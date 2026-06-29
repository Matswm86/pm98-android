#!/usr/bin/env python3
"""Build the PM98 MAIN MENU (MENUPRINCIPAL) static chrome -> app/art/screens/menu_bg.png.

The menu hub's look is engine-COMPOSITED at runtime (FUN_005469c0): the 12 picture icons
(RECURSOS\\...\\MENUPRINCIPAL\\*off.bmp) are blitted over a marble FONDO with the BARRA
quadrant cross, then each gets a colour-coded SLANTED caption bar (green / blue / red /
orange per group) drawn with FUN_00437020 colours, plus the INFORMATION / MANAGER /
TRANSFER MARKET / FINANCES section labels and the central club CIRCLE with its slot
boxes. None of that exists as a single extractable PKF asset -- only the composited
output does. The most faithful representation of that output (without hand-drawing the
bars and risking the "invented art" trap, see feedback_pm98_stay_true_to_original) is the
real game's own 640x480 MENUPRINCIPAL frame.

So this takes the captured original screen (refs/menuprincipal_ma_6.png == the real
gallery ma_6.png, a native 640x480 PNG) and clears ONLY the club-specific data so the
chrome is reusable for any career:
  * the top header band (y0..55)  -> flat marble; MenuScreen redraws it with PMChrome
    .draw_header (the same plaque row every faithful management screen shares).
  * the two circle crests          -> circle-interior marble; MenuScreen redraws the live
    managed-club + opponent kits there.
The bars / icons / section labels / control bar / circle frame + slot boxes / background
are the REAL pixels, untouched. MenuScreen.gd blits this and draws the dynamic layer
(header + the circle's live slots) on top. Reversed coordinates: docs/re/menu_screen_re.md.

Run from the repo root:  python3 tools/re/build_menu_bg_from_ref.py
"""
from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
REF = ROOT / "tools" / "re" / "refs" / "menuprincipal_ma_6.png"
OUT = ROOT / "app" / "art" / "screens" / "menu_bg.png"

# Crest spots in the central circle (left = managed club, right = next opponent).
CREST_SPOTS = [(222, 208, 258, 258), (394, 256, 426, 306)]
CIRCLE_MARBLE = (108, 120, 150)
# Clean marble sample points (away from header / bars / icons) for the top-band fill.
MARBLE_PTS = [(12, 210), (627, 210), (12, 300), (627, 300), (320, 470)]
TOP_BAND_H = 56


def main() -> None:
    im = Image.open(REF).convert("RGB")
    if im.size != (640, 480):
        raise SystemExit(f"ref must be 640x480, got {im.size}")
    px = im.load()
    marble = tuple(sum(px[x, y][c] for x, y in MARBLE_PTS) // len(MARBLE_PTS)
                   for c in range(3))
    for y in range(TOP_BAND_H):
        for x in range(640):
            px[x, y] = marble
    for x0, y0, x1, y1 in CREST_SPOTS:
        for y in range(y0, y1):
            for x in range(x0, x1):
                px[x, y] = CIRCLE_MARBLE
    OUT.parent.mkdir(parents=True, exist_ok=True)
    im.save(OUT)
    print(f"wrote {OUT} (640x480) - real MENUPRINCIPAL chrome, club data cleared; "
          f"top-band marble {marble}")


if __name__ == "__main__":
    main()
