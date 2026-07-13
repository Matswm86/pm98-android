#!/usr/bin/env python3
"""BOARD OF DIRECTORS (DIRECTIVA) body chrome, frame-baked from the real MANAGER.EXE
walkthrough.

Source (ground truth, owned game frames):
  screenshots/original-walkthrough-2026-07-02/167_154921.png
      the clean BOARD OF DIRECTORS screen (run1 15:49:21, Man Utd / MWM, preseason):
      MANAGER + MANAGER RATING, DIRECTORS/SUPPORTERS CONFIDENCE (with the two-directors
      and crowd VGA figures), the APPLY FOR LOAN empty form, the BONUS panel (Win bonus /
      for Champion, each with flechal/flechar spinners + OK), and RETURN. Layout matches
      the decompile FUN_0050c350 / FUN_0050b580 / FUN_0050b5f0 / FUN_0050ae90 exactly
      (docs/re/directiva_screen_re.md, docs/re/directiva/*.c).

Output:
  app/art/screens/directiva/body.png   640x436 opaque, drawn 1:1 at (0,44)

Doctrine (pm98_stay_true_to_original): the PNG is the real frame's pixels. The ONLY
regions painted over are the ones the app must render live from Career state, blanked
back to their own baked background so nothing is invented:
  - the MANAGER name box interior (navy)   -> app draws the manager name
  - each meter's block strip (white)        -> app draws value blocks (red->brown)
  - each meter's value tab digit (lt-blue)  -> app draws the value number
Everything else (stadium backdrop, label bars, the two figure icons, the loan form, the
bonus panel with its spinners + OK, RETURN) is baked pixel-exact. The header barra is NOT
baked (PMChrome.draw_header draws it live over the top).
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
FRAME = ROOT / "screenshots/original-walkthrough-2026-07-02/167_154921.png"
OUT = ROOT / "app/art/screens/directiva/body.png"

BODY_Y0 = 44                 # first row below the header barra (PMChrome draws y0..~44)
WHITE = (255, 255, 255)
NAVY = (0, 0, 128)
LBLUE = (166, 202, 240)      # meter value-tab fill (reversed light-blue)

# Blank rects in FRAME coords (x0, y0, x1, y1) -> fill. Measured off 167_154921 (see
# tools/re geom probes); each is inside a baked flat field so the fill is invisible until
# the app draws the live value on top.
BLANKS = [
    # MANAGER name box interior -> navy (erase the walkthrough's "MWM")
    ((49, 125, 295, 146), NAVY),
    # MANAGER RATING: block strip -> white, value tab digit -> light-blue
    ((351, 125, 553, 146), WHITE),
    ((563, 127, 601, 145), LBLUE),
    # DIRECTORS CONFIDENCE (block strip below the label bar, from just right of the icon)
    ((64, 188, 245, 209), WHITE),
    ((252, 190, 293, 207), LBLUE),
    # SUPPORTERS CONFIDENCE (block strip from just right of the crowd icon)
    ((362, 188, 553, 209), WHITE),
    ((558, 190, 601, 207), LBLUE),
]


def main() -> None:
    im = Image.open(FRAME).convert("RGB")
    for (x0, y0, x1, y1), col in BLANKS:
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                im.putpixel((x, y), col)
    # The header calendar sheet + plaque (drawn live by PMChrome.draw_header) bleed their
    # bottom rows into the body's top-right strip. Replace with the real stadium backdrop
    # immediately below them (row 62), so the body never carries a baked date/plaque.
    for y in range(BODY_Y0, 61):
        for x in range(440, 640):
            im.putpixel((x, y), im.getpixel((x, 62)))
    body = im.crop((0, BODY_Y0, 640, 480))
    OUT.parent.mkdir(parents=True, exist_ok=True)
    body.save(OUT)
    print(f"wrote {OUT.relative_to(ROOT)} ({body.width}x{body.height}) from {FRAME.name}")


if __name__ == "__main__":
    main()
