#!/usr/bin/env python3
"""Pixel-parity gate: MANAGER HISTORY renders vs the live-witnessed original frames.

Compares the shot_managerhistory_parity.gd captures against
screenshots/promanager-career-2026-07-16/ frames 15 (TOTAL off) and 16 (TOTAL on)
over the full 640x480 screen (the witness frames carry one extra border column at
x=640, dropped here).

Usage: diff_managerhistory_parity.py <shot_dir>
"""

from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
WIT = ROOT / "screenshots/promanager-career-2026-07-16"
PAIRS = [
    ("mh_15.png", "15_manager_history.png"),
    ("mh_16.png", "16_manager_history_total_on.png"),
]


def main() -> None:
    shot_dir = Path(sys.argv[1])
    fail = False
    for shot_name, wit_name in PAIRS:
        shot = Image.open(shot_dir / shot_name).convert("RGB")
        wit = Image.open(WIT / wit_name).convert("RGB").crop((0, 0, 640, 480))
        if shot.size != (640, 480):
            print(f"{shot_name}: unexpected size {shot.size}")
            fail = True
            continue
        n = 0
        worst = None
        for y in range(480):
            for x in range(640):
                a = shot.getpixel((x, y))
                b = wit.getpixel((x, y))
                if a != b:
                    n += 1
                    if worst is None:
                        worst = (x, y, a, b)
        pct = 100.0 * n / (640 * 480)
        print(f"{shot_name} vs {wit_name}: {n}px differ ({pct:.4f}%)"
              + (f", first at {worst}" if worst else ""))
        if n:
            fail = True
            diff = Image.new("RGB", (640, 480), (0, 0, 0))
            for y in range(480):
                for x in range(640):
                    if shot.getpixel((x, y)) != wit.getpixel((x, y)):
                        diff.putpixel((x, y), (255, 0, 255))
            diff.save(shot_dir / f"diff_{shot_name}")
    sys.exit(1 if fail else 0)


if __name__ == "__main__":
    main()
