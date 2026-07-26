#!/usr/bin/env python3
"""Pixel-parity gate: the RESULTS -> cup KNOCKOUT list view vs its live-witnessed frames.

Compares shot_knockout_parity.gd's captures against
  tools/re/refs/knockout-2026-07-26/06_euroleague_round1_played.png     (European columns)
  tools/re/refs/knockout-2026-07-26/03_facup_r3_drawn_UNPLAYED_1997-12-20.png (domestic)

Two buckets are reported separately because each has a stated, documented cause:

* the BARRA manager kit at (106,6) -- the pre-existing hole shared with ResultsScreen and
  EuroGroupScreen: only Man Utd's 35x44 header patch has been cut from the original, so a
  Bolton W barra differs by the whole blit;
* the SCROLLBAR column x478..493 -- its arrows and trough are the original's own, but the
  thumb's length and tracking are an INFERENCE (the two frames in hand differ only in the
  thumb's length, which fixes neither the rounding nor the minimum), recorded as such in
  docs/re/knockout_views_re.md.

Everything else must be zero.

Usage: diff_knockout_parity.py <shot_dir>
"""

from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
REFS = ROOT / "tools/re/refs/knockout-2026-07-26"

CASES = [
    ("knockout_euro_round1", "06_euroleague_round1_played.png"),
    ("knockout_facup_round3", "03_facup_r3_drawn_UNPLAYED_1997-12-20.png"),
]

BARRA_KIT = (106, 6, 35, 44)
SCROLL_COL = (478, 125, 16, 286)


def _in(rect: tuple[int, int, int, int], x: int, y: int) -> bool:
    rx, ry, rw, rh = rect
    return rx <= x < rx + rw and ry <= y < ry + rh


def main() -> int:
    shot_dir = Path(sys.argv[1])
    fail = False
    for name, ref in CASES:
        shot = Image.open(shot_dir / f"{name}.png").convert("RGB")
        wit = Image.open(REFS / ref).convert("RGB").crop((0, 0, 640, 480))
        if shot.size != (640, 480):
            print(f"{name}: unexpected shot size {shot.size}")
            fail = True
            continue
        n = kit = scroll = 0
        first = None
        diff = Image.new("RGB", (640, 480), (0, 0, 0))
        for y in range(480):
            for x in range(640):
                a = shot.getpixel((x, y))
                b = wit.getpixel((x, y))
                if a == b:
                    continue
                if _in(BARRA_KIT, x, y):
                    kit += 1
                    continue
                if _in(SCROLL_COL, x, y):
                    scroll += 1
                    continue
                n += 1
                diff.putpixel((x, y), (255, 0, 0))
                if first is None:
                    first = (x, y, a, b)
        tag = "OK " if n == 0 else "BAD"
        print(f"{tag} {name}: {n} outside (barra kit {kit}, scrollbar {scroll})")
        if first is not None:
            print(f"      first at {first[0]},{first[1]} got {first[2]} want {first[3]}")
            diff.save(shot_dir / f"diff_{name}.png")
            fail = True
    return 1 if fail else 0


if __name__ == "__main__":
    sys.exit(main())
