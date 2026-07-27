#!/usr/bin/env python3
"""Pixel-diff the FINANCES summary's dynamic euro-income LABEL against its witnesses.

Usage:  python3 tools/re/diff_finance_eurolabel_parity.py <shot_dir>

Produce the shots first:

    DISPLAY=:5 PM98_SHOT_DIR=<dir> ~/godot462 --rendering-driver opengl3 \\
        --resolution 640x480 --path app --script res://tests/shot_finance_eurolabel.gd

The 4th income row names the European competition the club is in. The original chooses
it at draw time -- `FUN_0050812e` @0x5081B0..0x50838F is a three-arm ladder over two
competition globals, with `U.E.F.A. CUP INCOME` as the fall-through (see
docs/re/finance_screen_re.md). Two arms are witnessed by real frames, from two different
careers, and both must land on the frame's own pixels inside the label plate:

    european_cup  013_164406.png              Manchester Utd., in the European Cup
    uefa_cup      orig/51_finance_season.png  a non-European lower-club career

The third arm (`CUP WINNERS CUP INCOME`) has no capture. It is not faked here: the gate
only asserts it renders and differs from both witnessed labels, and the string itself is
the binary's own (0x659AF4 + 0x659B00).

The compared rect is the label PLATE only -- x32..197, y146..158, the flat (220,220,220)
ground between the panel's white rules. Everything else on those two frames belongs to
two different careers and is not comparable.
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

BOX = (32, 146, 198, 159)  # x0, y0, x1, y1 -- the label plate, inside the white rules

WITNESSED = [
    ("european_cup", WALK / "013_164406.png"),
    ("uefa_cup", PARITY / "51_finance_season.png"),
]
UNWITNESSED = "cup_winners_cup"


def _band(path: Path) -> np.ndarray:
    x0, y0, x1, y1 = BOX
    return np.asarray(Image.open(path).convert("RGB"))[y0:y1, x0:x1].astype(int)


def main() -> int:
    shot_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("/tmp")
    ok = True
    bands = {}
    for key, ref in WITNESSED + [(UNWITNESSED, None)]:
        shot = shot_dir / f"finance_eurolabel_{key}.png"
        if not shot.exists():
            print(f"missing {shot}", file=sys.stderr)
            return 2
        bands[key] = _band(shot)
        if ref is None:
            continue
        if not ref.exists():
            print(f"missing witness {ref}", file=sys.stderr)
            return 2
        n = int((np.abs(bands[key] - _band(ref)).mean(axis=2) > 8).sum())
        print(f"  {key:<16} vs {ref.name:<28} {n:>5} px")
        if n:
            ok = False

    other = [bands[k] for k, _ in WITNESSED]
    if any(np.array_equal(bands[UNWITNESSED], b) for b in other):
        print(f"  {UNWITNESSED:<16} FAIL — renders the same label as a witnessed arm")
        ok = False
    elif not bands[UNWITNESSED].any():
        print(f"  {UNWITNESSED:<16} FAIL — nothing drawn")
        ok = False
    else:
        print(f"  {UNWITNESSED:<16} drawn, distinct — UNWITNESSED (binary string only)")

    print("PASS" if ok else "FAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
