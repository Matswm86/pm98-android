#!/usr/bin/env python3
"""Bake the PM98 EUROPEAN SUPERCUP chrome 1:1 from the real frame.

The screen is RESULTS -> Euro. Superc. Unlike the CHARITY SHIELD / INTERCONTINENTAL pair
(one match, `FUN_004717a0` == `FUN_0048daf0`), the Supercup is its own builder
`FUN_004a1820` mounting the two-leg panel widget `FUN_0046a110` at (137, 124) — two
`1ST LEG MATCH` / `2ND LEG MATCH` blocks, each with its own STADIUM caption, two club
plates and two score cells. Full evidence: `docs/re/euro_supercup_screen_re.md`.

Binding frame (live drive of the original, Bolton W career 1997-98, the tie drawn but
not yet played):
  screenshots/wine-captures-2026-07-25-euro-competitions/09_comp_supercup.png

The whole 640x480 frame is baked — barra, trophy, title plate, both green header bars,
both STADIUM captions, the WINNER band, the laurel, the competition rail with Euro.
Superc. lit, the division chips and RETURN are all the original's own pixels and are
never redrawn. Only the club-dependent cells are cleared for EuroSupercupScreen.gd:

  * the two venue-name lines            -> flat white (panel interior)
  * the four mini-kit wells             -> the club-plate fill
  * the four club-name cells            -> the club-plate fill
  * the four score cells                -> the score-plate fill

The WINNER band and the laurel kit are left exactly as the frame has them: this tie has
not been played, so they are already the original's own EMPTY state.

Rects were measured off the frame pixel grid and each one agrees with a literal in
FUN_0046a110 offset by the panel origin (137, 124) — see the doc's table.

Run:  python3 tools/re/build_supercup_chrome_from_frames.py
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
FRAMES = ROOT / "tools" / "re" / "refs" / "euro-competitions-2026-07-25"
if not (FRAMES / "09_comp_supercup.png").exists():
    FRAMES = ROOT / "screenshots" / "wine-captures-2026-07-25-euro-competitions"
FRAME = "09_comp_supercup.png"
OUT = ROOT / "app" / "art" / "screens" / "compresult" / "supercup.png"

WHITE = (255, 255, 255)
NAME_FILL = (200, 220, 240)   # club plate interior (flat, verified)
SCORE_FILL = (42, 63, 170)    # score cell interior (flat, verified)

# The two leg blocks. Panel origin (137,124); leg 2 repeats the rows at +112 and the
# captions at +113, exactly as the two sets of literals in FUN_0046a110 do.
ROW_Y = [178, 200, 290, 312]          # club plate tops
VENUE_Y = [(161, 174), (274, 287)]    # venue-name line (STADIUM caption above stays)

# (left, top, right, bottom, fill) — right/bottom exclusive.
FLAT_BLANKS: list[tuple[int, int, int, int, tuple[int, int, int]]] = []
for _y0, _y1 in VENUE_Y:
    FLAT_BLANKS.append((139, _y0, 362, _y1, WHITE))
for _y in ROW_Y:
    FLAT_BLANKS.append((144, _y, 319, _y + 20, NAME_FILL))   # kit well + name cell
    FLAT_BLANKS.append((321, _y, 357, _y + 20, SCORE_FILL))  # score cell


def main() -> None:
    OUT.parent.mkdir(parents=True, exist_ok=True)
    frame = Image.open(FRAMES / FRAME).convert("RGB").crop((0, 0, 640, 480))
    out = frame.convert("RGBA")
    for x0, y0, x1, y1, rgb in FLAT_BLANKS:
        out.paste(Image.new("RGBA", (x1 - x0, y1 - y0), (*rgb, 255)), (x0, y0))
    out.save(OUT)
    print(f"wrote {OUT.relative_to(ROOT)} (640x480 RGBA, {len(FLAT_BLANKS)} cells cleared)")


if __name__ == "__main__":
    main()
