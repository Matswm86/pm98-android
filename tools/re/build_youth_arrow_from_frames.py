#!/usr/bin/env python3
"""Cut the YOUTH screen's PARAMETERS/RATING selection arrow and un-bake it from the body.

The arrow was baked into `youth_body.png` at the PARAMETERS slot and treated as static
furniture. It is not static — MANAGER.EXE moves it:

    FUN_0053e760   invalidates (0x1db,0x10a)-(0x1e4,0x11b) = (475,266)-(484,283)
                   and sets DAT_00658a40 = 1        <- PARAMETERS selected
    FUN_0053e7e0   invalidates (0x1db,0x122)-(0x1e4,0x133) = (475,290)-(484,307)
                   and sets DAT_00658a40 = 0        <- RATING selected

Each handler repaints its OWN slot, which is only meaningful if the arrow moves between
them. Confirmed live 2026-08-01 on a driven Man Utd career: with PARAMETERS selected the
dark-red arrow ink sits at x476..483 y266..281, and one tap on RATING moves it to
x476..483 y290..305 — the two rects the binary names, and nothing else in the column
changes.

Output:
  * `arrow.png`        RGBA, the arrow ink only (transparent elsewhere), so it can be
                       stamped over either backdrop — the two slots sit on different
                       background bands, so a rectangular blit of one would drag the
                       wrong backdrop onto the other.
  * `youth_body.png`   patched in place: the PARAMETERS slot's baked arrow is replaced
                       with the clean pixels from the RATING-selected frame, where that
                       slot is empty.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "app/art/screens/youth"
SPEC = ART / "youth_chrome.json"
BODY = ART / "youth_body.png"

# The two live witnesses of the driven career (see the module docstring), kept IN THE
# REPO so this stays re-runnable: the drive that produced them wrote to a session
# scratchpad that does not survive a reboot.
SHOTS = ROOT / "screenshots/wine-captures-2026-08-01-youth-arrow"
F_PARAMS = SHOTS / "y17_youth.png"
F_RATING = SHOTS / "y18_rating.png"

SLOT_X, SLOT_W = 475, 11
SLOT_H = 18
Y_PARAMS, Y_RATING = 266, 290


def as_frame(p: Path) -> Image.Image:
    im = Image.open(p).convert("RGB")
    return im.crop((0, 0, 640, im.height)) if im.width == 641 else im


def main() -> int:
    for f in (F_PARAMS, F_RATING, BODY, SPEC):
        if not f.exists():
            print(f"missing {f}", file=sys.stderr)
            return 1
    a = as_frame(F_PARAMS)      # arrow on PARAMETERS, RATING slot clean
    b = as_frame(F_RATING)      # arrow on RATING, PARAMETERS slot clean

    # --- the two arrow sprites: ink only, alpha elsewhere ---
    # Ink is the DIFFERENCE between the two witnesses over one slot: in `a` the arrow is
    # on PARAMETERS and the RATING slot is clean, in `b` it is the other way round, so
    # each slot is its own before/after pair. Colour-agnostic on purpose — the sprite is
    # dithered against the panel and carries eight distinct colours (85,0,0 / 127,95,85 /
    # 108,21,21 / 70,40,80 / 85,31,85 / 127,63,85 / 72,30,2 / 102,50,12), so a hand-listed
    # ink set silently drops pixels. The first cut listed two and dropped 22 of 81.
    #
    # TWO sprites, not one moved: 11 of the 81 px change colour between the slots, because
    # the dither is against a different background band in each. One sprite stamped at the
    # other slot is 11px wrong; per-slot cuts are exact in both states.
    def cut(with_arrow: Image.Image, without: Image.Image, y: int, name: str) -> int:
        box = (SLOT_X, y, SLOT_X + SLOT_W, y + SLOT_H)
        on, off = with_arrow.crop(box).load(), without.crop(box).load()
        img = Image.new("RGBA", (SLOT_W, SLOT_H), (0, 0, 0, 0))
        px = img.load()
        n = 0
        for yy in range(SLOT_H):
            for xx in range(SLOT_W):
                if on[xx, yy] != off[xx, yy]:
                    px[xx, yy] = (*on[xx, yy], 255)
                    n += 1
        img.save(ART / name)
        print(f"cut {name} {SLOT_W}x{SLOT_H}, {n} ink px")
        return n

    n_par = cut(a, b, Y_PARAMS, "arrow.png")
    n_rat = cut(b, a, Y_RATING, "arrow_rating.png")
    if n_par == 0 or n_rat == 0:
        print("one of the slots came out empty — the witnesses are not the pair they "
              "are documented to be", file=sys.stderr)
        return 1

    # --- un-bake the PARAMETERS slot from the body ---
    spec = json.loads(SPEC.read_text())
    body_y = int(spec.get("body_y", 58))
    body = Image.open(BODY).convert("RGB")
    clean = b.crop((SLOT_X, Y_PARAMS, SLOT_X + SLOT_W, Y_PARAMS + SLOT_H))
    body.paste(clean, (SLOT_X, Y_PARAMS - body_y))
    body.save(BODY)
    print(f"patched youth_body.png: PARAMETERS slot cleared at ({SLOT_X},{Y_PARAMS - body_y})")

    spec["arrow"] = {"x": SLOT_X, "w": SLOT_W, "h": SLOT_H,
                     "y_parameters": Y_PARAMS, "y_rating": Y_RATING,
                     "sprites": {"parameters": "arrow.png", "rating": "arrow_rating.png"}}
    SPEC.write_text(json.dumps(spec, indent=1))
    print("youth_chrome.json: + arrow")
    return 0


if __name__ == "__main__":
    sys.exit(main())
