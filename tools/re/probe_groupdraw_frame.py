#!/usr/bin/env python3
"""Measure the EUROPEAN CUP **GROUP DRAW** form off its own witness frame.

The SORTEO screen has, so far, two witnessed forms — the >16-tie centred LIST and the
<=16-tie four-column GRID (`docs/re/cupdraw_screen_re.md`). `manutd_s1_eurocup_groups_1_8_final.png`
(banked s87) is a THIRD: the right-hand panel is a header plate reading `GROUPS` over six
group boxes in a 2x3 grid, each box a green `GROUP <letter>` header over four
`kit | club | flag` rows, and the bottom-left tie card is entirely blank.

This script does not draw anything. It reports the frame's own geometry so the builder and
the scene are derived from pixels rather than from the eye:

  * the right panel's plate and box rectangles, found by scanning for the box borders;
  * each box header's ink colour and its plate colour;
  * the row pitch and the alternating row backgrounds;
  * the columns the kit sprite, the club name and the flag occupy;
  * which boxes are EMPTY (all rows flat) — the draw is mid-reveal on this frame.

Run: python3 tools/re/probe_groupdraw_frame.py [frame.png]
"""

from __future__ import annotations

import sys
from collections import Counter
from pathlib import Path

import numpy as np
from PIL import Image

HERE = Path(__file__).resolve().parent
REPO = HERE.parent.parent
DEFAULT = REPO / "tools/re/refs/cupdraw-rounds-2026-08-01/manutd_s1_eurocup_groups_1_8_final.png"


def runs(mask: np.ndarray) -> list[tuple[int, int]]:
    """Contiguous True runs of a 1-D mask as (start, length)."""
    out: list[tuple[int, int]] = []
    i = 0
    n = len(mask)
    while i < n:
        if mask[i]:
            j = i
            while j < n and mask[j]:
                j += 1
            out.append((i, j - i))
            i = j
        else:
            i += 1
    return out


def rgb(a: np.ndarray, x: int, y: int) -> tuple[int, int, int]:
    return tuple(int(v) for v in a[y, x, :3])


def main() -> None:
    path = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT
    im = Image.open(path).convert("RGB")
    a = np.asarray(im)
    h, w = a.shape[:2]
    print(f"{path.name}  {w}x{h}")

    # ---- the right panel: the boxes are light plates on the desktop wallpaper.
    # A box interior is one of two near-white/blue plate tones; find them by frequency
    # over the right half.
    right = a[:, 320:, :]
    cnt = Counter(map(tuple, right.reshape(-1, 3)))
    print("\n-- right half, 12 most common colours")
    for c, n in cnt.most_common(12):
        print(f"   {c}  {n}")

    # ---- horizontal rules: rows whose right-half is dominated by a single colour
    print("\n-- right-half row profile (x 328..628), rows that are >=80% one colour")
    band = a[:, 328:628, :]
    for y in range(h):
        row = band[y]
        c = Counter(map(tuple, row))
        col, n = c.most_common(1)[0]
        if n >= 240:
            print(f"   y={y:3d} {col} {n}/300")

    # ---- vertical structure: scan one row inside a box header and one inside a row band
    for label, y in (
        ("GROUPS plate", 24),
        ("box-A header", 64),
        ("row 0 of A", 85),
        ("row 0 of C", 210),
        ("black rule y99", 99),
    ):
        row = a[y]
        print(f"\n-- x-profile at y={y} ({label})")
        segs = []
        x = 0
        while x < w:
            c0 = rgb(a, x, y)
            j = x
            while j < w and rgb(a, j, y) == c0:
                j += 1
            if j - x >= 3:
                segs.append((x, j - x, c0))
            x = j
        for s in segs:
            print(f"   x={s[0]:3d} len={s[1]:3d} {s[2]}")


if __name__ == "__main__":
    main()
