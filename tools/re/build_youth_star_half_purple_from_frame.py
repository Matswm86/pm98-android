#!/usr/bin/env python3
"""Cut the YOUTH TEAM scout bar's HALF star (the purple row) out of a live capture.

`YouthScreen._stars` was called with `null` for the scout row's half-star sprite, because
no frame in the corpus had ever shown a youth scout on a .5 rating -- the two walkthrough
witnesses are P. Mitchell (5.0) and the no-scout state. B9's drive hired **C. Stump, 4.5**,
so `tools/re/refs/b9-players-found-2026-08-01/02_players_found_first.png` carries the fifth
star cell filled and the port drew nothing there (34 px on `diff_youth_parity`).

## Where the alpha comes from

From `app/art/screens/youth/youth_body.png`, the screen's own baked chrome, at the same
cell. That bake is frame 087's pixels -- a career with NO staff hired -- so the scout bar
under the star cells is exactly the background the original blits the stars onto, and the
port already reproduces frame 047's five FULL stars over it at 0 px, which is what proves
the bar is the backdrop and not something the hire redraws.

The first version of this script took the background from a RENDER of the port instead,
and that is a trap worth naming: run it a second time and the render already contains the
sprite, every pixel matches, and the sprite is rewritten fully transparent -- which is
exactly what happened on 2026-08-01, undetected, because Godot's import cache kept serving
the previous `.ctex` so the parity gate still read 0 px. Deriving from the static bake is
idempotent, and the opaque-count assertion below fails loudly rather than silently emptying
a sprite.

Usage: python3 tools/re/build_youth_star_half_purple_from_frame.py
"""

from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
FRAME = (ROOT / "tools" / "re" / "refs" / "b9-players-found-2026-08-01"
         / "02_players_found_first.png")
BODY = ROOT / "app" / "art" / "screens" / "youth" / "youth_body.png"
OUT = ROOT / "app" / "art" / "screens" / "youth" / "star_half_purple.png"
BODY_Y = 58                          # youth_chrome.json body_y: the bake starts here
# scout_stars in youth_chrome.json: x0 248, y 85, pitch 11 -> cell 5 (C. Stump's half)
CELL = (248 + 4 * 11, 85, 11, 11)
MIN_OPAQUE = 8                       # a star this size cannot be fewer pixels than this


def main() -> int:
    x, y, w, h = CELL
    frame = np.asarray(Image.open(FRAME).convert("RGB")).astype(int)[y:y + h, x:x + w]
    body = np.asarray(Image.open(BODY).convert("RGB")).astype(int)
    bg = body[y - BODY_Y:y - BODY_Y + h, x:x + w]
    if bg.shape != frame.shape:
        print(f"FAIL: bake cell is {bg.shape}, frame cell is {frame.shape}")
        return 1

    opaque = np.abs(frame - bg).max(axis=2) > 0
    n = int(opaque.sum())
    if n < MIN_OPAQUE:
        print(f"FAIL: only {n} opaque px — the background already contains the sprite?")
        return 1

    rgba = np.zeros((h, w, 4), np.uint8)
    rgba[..., :3] = frame
    rgba[..., 3] = np.where(opaque, 255, 0)
    Image.fromarray(rgba).save(OUT)
    print(f"wrote {OUT.relative_to(ROOT)} {w}x{h}, {n} opaque px")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
