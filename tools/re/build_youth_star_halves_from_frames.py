#!/usr/bin/env python3
"""Cut all FOUR half-star glyphs of the YOUTH TEAM star bars out of live frames.

## Why there are four and not two

`YouthScreen._stars` lays a bar as `tex_a` at even cells and `tex_b` at odd ones -- the
original alternates TWO star sprites along the row, pixel-verified on frame 047's scout row
AND manager row, and a uniform sprite diffs on every second cell. The HALF glyph sits at
cell `floor(rating)`, so it lands on an EVEN cell for x.5 ratings with an even floor (4.5)
and on an ODD cell for an odd floor (1.5, 3.5) -- and it is subject to the same alternation.
The port carried one half sprite per bar colour, so it rendered the right glyph only for the
parity its witness happened to have:

| sprite | witness | cell | parity |
|---|---|---|---|
| `star_half_purple_a` | `b9-players-found-2026-08-01/02_players_found_first.png` C. Stump 4.5* | 4 | A |
| `star_half_purple_b` | `youth-roster-2026-08-01/b9_roster_signed_1998-10-03.png` S. Munt 1.5* | 1 | B |
| `star_half_blue_a`   | `youth-roster-2026-08-01/b9_roster_signed_1998-10-03.png` H. Constantine 4.5* | 4 | A |
| `star_half_blue_b`   | walkthrough `047_164509.png` G. Keeping 3.5* | 3 | B |

Before this builder the port had only the purple A and the blue B, and drew them at both
parities. That is 23 px on the scout bar and 17 px on the manager bar of the roster witness
-- the last two non-row diffs on that frame.

## Where the alpha comes from

From `app/art/screens/youth/youth_body.png`, the screen's own baked chrome, at the same
cell. That bake is frame 087's pixels -- a career with NO staff hired -- so the bar under
the star cells is exactly the background the original blits the stars onto, and the port
already reproduces frame 047's FULL stars over it at 0 px, which is what proves the bar is
the backdrop and not something the hire redraws.

Deriving the alpha from the STATIC bake (never from a render of the port) is what makes
this idempotent: run it against a render and the second run would find every pixel equal
and write a fully transparent sprite. The opaque-count assertion fails loudly instead.

Usage: python3 tools/re/build_youth_star_halves_from_frames.py [--check]
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
REFS = ROOT / "tools" / "re" / "refs"
FRAMES = ROOT / "screenshots" / "original-walkthrough-2026-07-02"
if not FRAMES.exists():  # binding frames are the committed subset
    FRAMES = REFS / "walkthrough-2026-07-02"
OUT_DIR = ROOT / "app" / "art" / "screens" / "youth"
BODY = OUT_DIR / "youth_body.png"
BODY_Y = 58  # youth_chrome.json body_y

# youth_chrome.json: scout_stars x0 248 / y 85, mgr_stars x0 290 / y 246, pitch 11
SCOUT = (248, 85)
MGR = (290, 246)
PITCH = 11
CELL_H = 11
MIN_OPAQUE = 8  # a glyph this size cannot be fewer

# (out name, frame, bar origin, cell index) -- each row names its own witness.
CUTS = [
    (
        "star_half_purple_a.png",
        REFS / "b9-players-found-2026-08-01" / "02_players_found_first.png",
        SCOUT,
        4,
    ),
    (
        "star_half_purple_b.png",
        REFS / "youth-roster-2026-08-01" / "b9_roster_signed_1998-10-03.png",
        SCOUT,
        1,
    ),
    (
        "star_half_blue_a.png",
        REFS / "youth-roster-2026-08-01" / "b9_roster_signed_1998-10-03.png",
        MGR,
        4,
    ),
    ("star_half_blue_b.png", FRAMES / "047_164509.png", MGR, 3),
]


def cut_one(
    frame_path: Path, origin: tuple[int, int], idx: int, body: np.ndarray
) -> tuple[Image.Image, int] | None:
    x = origin[0] + idx * PITCH
    y = origin[1]
    if not frame_path.exists():
        print(f"FAIL: missing witness {frame_path}")
        return None
    frame = np.asarray(Image.open(frame_path).convert("RGB")).astype(int)
    frame = frame[y : y + CELL_H, x : x + PITCH]
    bg = body[y - BODY_Y : y - BODY_Y + CELL_H, x : x + PITCH]
    if bg.shape != frame.shape:
        print(f"FAIL: bake cell {bg.shape} vs frame cell {frame.shape}")
        return None
    opaque = np.abs(frame - bg).max(axis=2) > 0
    n = int(opaque.sum())
    if n < MIN_OPAQUE:
        print(
            f"FAIL: {frame_path.name} cell {idx}: only {n} opaque px "
            "— is the background already the sprite?"
        )
        return None
    rgba = np.zeros((CELL_H, PITCH, 4), np.uint8)
    rgba[..., :3] = frame
    rgba[..., 3] = np.where(opaque, 255, 0)
    return Image.fromarray(rgba), n


def main() -> int:
    check_only = "--check" in sys.argv
    body = np.asarray(Image.open(BODY).convert("RGB")).astype(int)
    bad = 0
    for name, frame_path, origin, idx in CUTS:
        got = cut_one(frame_path, origin, idx, body)
        if got is None:
            bad += 1
            continue
        img, n = got
        if check_only:
            cur = OUT_DIR / name
            same = cur.exists() and np.array_equal(
                np.asarray(img), np.asarray(Image.open(cur).convert("RGBA"))
            )
            print(f"{'OK  ' if same else 'DIFF'} {name} ({n} opaque px)")
            bad += 0 if same else 1
        else:
            img.save(OUT_DIR / name)
            print(f"wrote {name} {PITCH}x{CELL_H}, {n} opaque px (cell {idx} of {frame_path.name})")
    # The two parities must actually DIFFER, or the alternation claim is wrong.
    if not check_only:
        for a, b in [
            ("star_half_purple_a.png", "star_half_purple_b.png"),
            ("star_half_blue_a.png", "star_half_blue_b.png"),
        ]:
            pa = np.asarray(Image.open(OUT_DIR / a).convert("RGBA"))
            pb = np.asarray(Image.open(OUT_DIR / b).convert("RGBA"))
            if np.array_equal(pa, pb):
                print(f"FAIL: {a} and {b} are identical — no alternation to model")
                bad += 1
    print("HALF-STARS: 0 FAIL" if not bad else f"HALF-STARS: {bad} FAIL")
    return 1 if bad else 0


if __name__ == "__main__":
    raise SystemExit(main())
