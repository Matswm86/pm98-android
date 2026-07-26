#!/usr/bin/env python3
"""Pixel-parity gate: the EURO. LEAGUE GROUP screen vs the six live-witnessed frames.

Compares shot_euroleague_parity.gd's captures against
tools/re/refs/euro-competitions-2026-07-25/1[0-5]_euroleague_group_[A-F].png.

Prints the total differing pixels AND how many of them fall inside the four kit blits,
because that residual has a known cause: the engine shades the kit's 1-px outline against
whatever is behind it (a pass that is not reversed yet -- 32 of 221 opaque px per RIDIESC
kit, 79 of 419 for the header NANOESC kit). Everything outside those rects must be zero.

Usage: diff_euroleague_parity.py <shot_dir>
"""

from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
REFS = ROOT / "tools/re/refs/euro-competitions-2026-07-25"
LETTERS = "ABCDEF"

# The kit rects, where the un-reversed engine blit lives:
#   (106,6)   the BARRA manager kit -- a pre-existing hole shared with ResultsScreen: only
#             Man Utd's 35x44 header patch has been cut, every other club falls back to the
#             24x32 NANOESC kit, so a Bolton W barra differs by the whole blit
#   (75,178)  the group leader's NANOESC kit  (79 of 419 opaque px: the outline shading)
#   the four RIDIESC results-row kits         (32 of 221 opaque px each, same pass)
KITS = [(106, 6, 35, 44), (75, 178, 24, 32)] + [
    (x, y, 17, 20) for y in (274, 296) for x in (80, 301)
]


# The MINIBAND flag cells. These used to carry 99 differing px over the six frames, blamed on
# "dither"; it was actually the wrong palette (the flags were decoded with DAT.PKF's shared VGA
# table instead of MANAGER.PAL + the Windows static colours -- see export_flags.flag_palette
# and euro_league_screen_re.md §Parity). Since 2026-07-26 this bucket reports **0**; the rect
# list stays so a palette regression is reported here instead of silently landing in "outside".
FLAGS = [(183, top + 2, 14, 10) for top in (209, 224, 239, 254)]


def _in(rects: list, x: int, y: int) -> bool:
    return any(rx <= x < rx + rw and ry <= y < ry + rh for rx, ry, rw, rh in rects)


def in_kit(x: int, y: int) -> bool:
    return _in(KITS, x, y)


def main() -> None:
    shot_dir = Path(sys.argv[1])
    fail = False
    for i, L in enumerate(LETTERS):
        shot = Image.open(shot_dir / f"euro_group_{L}.png").convert("RGB")
        wit = Image.open(REFS / f"{10 + i}_euroleague_group_{L}.png").convert("RGB")
        wit = wit.crop((0, 0, 640, 480))
        if shot.size != (640, 480):
            print(f"group {L}: unexpected shot size {shot.size}")
            fail = True
            continue
        n = kit_n = flag_n = 0
        first = None
        diff = Image.new("RGB", (640, 480), (0, 0, 0))
        for y in range(480):
            for x in range(640):
                a = shot.getpixel((x, y))
                b = wit.getpixel((x, y))
                if a == b:
                    continue
                n += 1
                if in_kit(x, y):
                    kit_n += 1
                elif _in(FLAGS, x, y):
                    flag_n += 1
                elif first is None:
                    first = (x, y, a, b)
                diff.putpixel((x, y), (255, 0, 255))
        outside = n - kit_n - flag_n
        print(
            f"group {L}: {n}px differ ({kit_n} kit blits, {flag_n} MINIBAND flags, "
            f"{outside} outside)" + (f", first outside at {first}" if first else "")
        )
        if outside:
            fail = True
            diff.save(shot_dir / f"diff_euro_group_{L}.png")
    sys.exit(1 if fail else 0)


if __name__ == "__main__":
    main()
