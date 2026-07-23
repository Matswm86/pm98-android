"""Diff the rendered INJURIES row against wine witness 83.

    python3 tools/re/diff_injuries_row_parity.py out/injuries_row_live.png

Compares the first GOAL row band (y104..121, the black borders included) cell by
cell against
`screenshots/wine-captures-2026-07-18-goalscorers/83_injuries_populated.png`,
reporting an exact-pixel count per column so a text-advance drift in one cell
cannot hide behind a clean grid.
"""

from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
WITNESS = (
    ROOT / "screenshots" / "wine-captures-2026-07-18-goalscorers" / "83_injuries_populated.png"
)

ROW_Y0, ROW_Y1 = 104, 121  # inclusive, borders included
CELLS = [
    ("frame", 6, 7),
    ("PHYS.", 8, 27),
    ("N", 29, 45),
    ("icon", 49, 58),
    ("PLAYER", 60, 158),
    ("cross", 160, 178),
    ("TYPE", 180, 356),
    ("Week", 358, 385),
    ("H", 387, 408),
    ("PRICE", 410, 482),
    ("INSUR.", 484, 538),
    ("COST", 540, 609),
]


def main() -> int:
    live_path = Path(sys.argv[1] if len(sys.argv) > 1 else ROOT / "out" / "injuries_row_live.png")
    live = Image.open(live_path).convert("RGB")
    ref = Image.open(WITNESS).convert("RGB")
    lp, rp = live.load(), ref.load()

    total = bad = 0
    print(f"{live_path.name}  vs  {WITNESS.name}   rows y{ROW_Y0}..{ROW_Y1}")
    for name, x0, x1 in CELLS:
        n = d = 0
        for y in range(ROW_Y0, ROW_Y1 + 1):
            for x in range(x0, x1 + 1):
                n += 1
                if lp[x, y] != rp[x, y]:
                    d += 1
        total += n
        bad += d
        pct = 100.0 * (n - d) / n
        print(f"  {name:8} x{x0:>3}..{x1:<3} {n:>5} px  diff {d:>4}  exact {pct:6.2f}%")
    print(
        f"  TOTAL              {total:>5} px  diff {bad:>4}  exact {100.0 * (total - bad) / total:6.2f}%"
    )
    return 0 if bad == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
