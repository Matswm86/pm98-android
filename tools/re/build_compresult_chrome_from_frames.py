#!/usr/bin/env python3
"""Bake the PM98 single-match COMPETITION RESULT chrome 1:1 from the real frames.

The screen is RESULTS -> <competition> for a competition that is ONE match: the
CHARITY SHIELD and the INTERCONTINENTAL CUP. MANAGER.EXE proves they are the same
screen: `FUN_004717a0` (charity) and `FUN_0048daf0` (intercontinental) are 1107 bytes
each and differ in exactly two operands -- the title string (0x653fc0 'CHARITY SHIELD'
vs 0x6543b4 'INTERCONTINENTAL CUP') and the trophy bitmap (0x653f94
`img\\premier\\copas\\charity big.bmp` vs 0x654390 `img\\copas\\intercontinental
big.bmp`). Every other differing byte is an `e8` rel32 whose delta is exactly 0x1c350,
the distance between the two entry points.

Binding frames (live drive of the original this session, Bolton W career, week 9):
  screenshots/wine-captures-2026-07-25-euro-competitions/09_comp_charity.png
  screenshots/wine-captures-2026-07-25-euro-competitions/09_comp_intercont.png

One chrome per competition, cut from its OWN frame below the shared barra, so the
title plate, the RESULT plate, the panel frame, the STADIUM caption, the trophy, the
laurel, the competition rail with this competition's chip lit, the division chips and
RETURN are all the original's own pixels and are never redrawn.

Only the club-dependent cells are cleared, for CompResultScreen.gd to redraw:

  * the two kit figures + the two country flags        -> flat white (panel interior)
  * the STADIUM name line                              -> flat white
  * the two club-name cells / the two score cells      -> their flat plate colours
  * the WINNER band's club name + the kit in the laurel -> BORROWED from the
    intercontinental frame, whose tie has not been played, so its band and laurel are
    the original's own EMPTY state rather than a synthesised fill.

Rects were measured off the frame pixel grid: the plate borders are the only long
black runs in the panel column (x137/138 and x362/363; rows 84/85, 109/110, 155/156,
265/266, 287/288, 296/297, 318/319, 334/335), the flag boxes are the black-bordered
squares at x198..229 / x269..300 y162..183, and the kit blobs are the non-white
interior either side of them (x146..193 and x306..353, y158..217).

Run:  python3 tools/re/build_compresult_chrome_from_frames.py
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
FRAMES = ROOT / "screenshots" / "wine-captures-2026-07-25-euro-competitions"
OUT_DIR = ROOT / "app" / "art" / "screens" / "compresult"

# The whole 640x480 frame is baked, barra included: CompResultScreen redraws the four
# textless header patches over it exactly as ResultsScreen does (the shared band.png
# grammar), so the baked manager / calendar / status text never shows through.
BODY_Y0 = 0

WHITE = (255, 255, 255)
NAME_FILL = (200, 220, 240)  # club-name cell (flat, verified)
SCORE_FILL = (42, 63, 170)  # score cell (flat, verified)

# (left, top, right, bottom, fill) -- right/bottom exclusive.
FLAT_BLANKS = [
    (146, 158, 194, 218, WHITE),  # home kit
    (306, 158, 354, 218, WHITE),  # away kit
    (199, 163, 229, 183, WHITE),  # home flag (inside its black box)
    (270, 163, 300, 183, WHITE),  # away flag
    (139, 237, 361, 254, WHITE),  # STADIUM name line
    (150, 267, 306, 287, NAME_FILL),  # home club cell
    (306, 267, 345, 287, SCORE_FILL),  # home score cell
    (150, 298, 306, 318, NAME_FILL),  # away club cell
    (306, 298, 345, 318, SCORE_FILL),  # away score cell
]

# Regions copied from the un-played intercontinental frame (its own empty state).
BORROW_EMPTY = [
    (41, 356, 382, 400),  # WINNER band + its rounded name plate
    (398, 334, 450, 396),  # the kit well inside the laurel
]

COMPS = {"charity": "09_comp_charity.png", "intercont": "09_comp_intercont.png"}
EMPTY_FRAME = "09_comp_intercont.png"


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    empty = Image.open(FRAMES / EMPTY_FRAME).convert("RGB")
    for key, fname in COMPS.items():
        frame = Image.open(FRAMES / fname).convert("RGB")
        out = Image.new("RGBA", (640, 480), (0, 0, 0, 0))
        out.paste(frame.crop((0, BODY_Y0, 640, 480)).convert("RGBA"), (0, BODY_Y0))
        for x0, y0, x1, y1, rgb in FLAT_BLANKS:
            out.paste(Image.new("RGBA", (x1 - x0, y1 - y0), (*rgb, 255)), (x0, y0))
        for x0, y0, x1, y1 in BORROW_EMPTY:
            out.paste(empty.crop((x0, y0, x1, y1)).convert("RGBA"), (x0, y0))
        dst = OUT_DIR / f"{key}.png"
        out.save(dst)
        print(
            f"wrote {dst.relative_to(ROOT)} (640x480 RGBA, "
            f"{len(FLAT_BLANKS)} cells cleared, {len(BORROW_EMPTY)} borrowed)"
        )


if __name__ == "__main__":
    main()
