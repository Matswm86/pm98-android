#!/usr/bin/env python3
"""Pixel-diff the FINANCES summary's ±N K. balance-chart axis against its witnesses.

Usage:  python3 tools/re/diff_finance_axis_parity.py <shot_dir>

Produce the shots first:

    DISPLAY=:1 PM98_SHOT_DIR=<dir> ~/godot462 --rendering-driver opengl3 \\
        --resolution 640x480 --path app --script res://tests/shot_finance_axis.gd

The axis is NOT a static blit, which is what the 2026-07-27 "LATENT DEFECT" note in
docs/re/finance_screen_re.md recorded as unexplained. `FUN_00509760` walks the plotted
weeks accumulating the largest |week-on-week balance delta| (@0x50994a..0x509990), then
picks the SMALLEST entry of a three-float table in .data that is at least that value --

    0x659540   50,000,000f   ->  "250"
    0x659544  100,000,000f   ->  "500"
    0x659548  500,000,000f   -> "2,500"

walked downwards from the largest at @0x509a31..0x509a57 -- and prints that entry times
5e-06 (the double at 0x62d930) between "+" / "-" (0x6587d4 / 0x654448) and " K."
(0x659b2c), in the face the same routine selects by name at @0x509d92: "euro8"
(0x6597a4). Two of the three states are on real frames, from two different careers:

    k2500   013_164406.png              +/-2,500 K.
    k250    orig/51_finance_season.png  +/-250 K.

The middle step has no capture. It is not faked here: the gate only asserts it renders
and differs from both witnessed states.

The compared rects are the two label PLATES only -- x28..74, y332..352 (blue, "+") and
y354..374 (dark red, "-"). Everything else on those two frames belongs to two different
careers and is not comparable.
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
WALK = ROOT / "screenshots" / "original-walkthrough-2026-07-02"
if not WALK.exists():  # full capture set is local-only; binding frames are committed
    WALK = ROOT / "tools" / "re" / "refs" / "walkthrough-2026-07-02"
PARITY = ROOT / "screenshots" / "parity-run-2026-07-16" / "orig"

PLATES = [("+ plate", 28, 332, 75, 353), ("- plate", 28, 354, 75, 375)]

WITNESSED = [
    ("k2500", WALK / "013_164406.png"),
    ("k250", PARITY / "51_finance_season.png"),
]
UNWITNESSED = "k500"


def _bands(path: Path) -> list[np.ndarray]:
    im = np.asarray(Image.open(path).convert("RGB")).astype(int)
    return [im[y0:y1, x0:x1] for _tag, x0, y0, x1, y1 in PLATES]


def main() -> int:
    shot_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("/tmp")
    ok = True
    for key, ref in WITNESSED:
        shot = shot_dir / f"finance_axis_{key}.png"
        if not shot.exists():
            print(f"BAD  {key}: {shot} is missing")
            ok = False
            continue
        got = _bands(shot)
        want = _bands(ref)
        for (tag, _x0, _y0, _x1, _y1), a, b in zip(PLATES, got, want):
            n = int((a != b).any(axis=2).sum())
            print(f"{'OK ' if n == 0 else 'BAD'} {key} {tag}: {n} differing px vs {ref.name}")
            ok = ok and n == 0
    mid = shot_dir / f"finance_axis_{UNWITNESSED}.png"
    if mid.exists():
        m = _bands(mid)
        for key, _ref in WITNESSED:
            other = _bands(shot_dir / f"finance_axis_{key}.png")
            same = all(int((x != y).any(axis=2).sum()) == 0 for x, y in zip(m, other))
            if same:
                print(f"BAD  {UNWITNESSED}: renders identically to {key}")
                ok = False
        if ok:
            print(f"OK  {UNWITNESSED}: renders and differs from both witnessed states")
    else:
        print(f"BAD  {UNWITNESSED}: {mid} is missing")
        ok = False
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
