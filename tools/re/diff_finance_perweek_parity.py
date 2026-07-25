#!/usr/bin/env python3
"""Pixel-diff the FINANCES / PER WEEK parity shots against the frames they were baked
from (REFRUN R5/R9, Manchester Utd. 1997-98).

Usage:  python3 tools/re/diff_finance_perweek_parity.py <shot_dir>

Produce the shots first:

    DISPLAY=:5 PM98_SHOT_DIR=<dir> ~/godot462 --rendering-driver opengl3 \\
        --resolution 640x480 --path app --script res://tests/shot_finance_perweek.gd

Two frames, two states of the same view:

  finance_perweek_31.png  the LIVE week — "CURRENT 31", 15-2-1998..21-2-1998, all £0
  finance_perweek_29.png  stepped back — "29", 1-2-1998..7-2-1998, the played HOME week

Reported per region. Everything must be 0 EXCEPT the BALANCE chart: the frame carries
the reference season's own 52 weeks of bars and this shot is fed only the two weeks the
run actually measured, so the rest of that plot cannot be reproduced without inventing
figures. It is excluded rather than faked, and the exclusion is the only one.
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
REFS = ROOT / "tools" / "re" / "refs" / "refrun-manutd-1997-98"

SHOTS = [
    ("finance_perweek_31.png", "p0495_finance_perweek_wk31.png"),
    ("finance_perweek_29.png", "p0509_finance_perweek_wk29.png"),
]

# region -> (x0, y0, x1, y1, must_be_zero)
REGIONS = {
    "tab strip": (0, 0, 640, 40, True),
    "week label": (300, 57, 392, 73, True),
    "date span": (414, 57, 610, 73, True),
    "income column": (0, 80, 320, 280, True),
    "expense column": (320, 80, 640, 280, True),
    "totals": (0, 280, 640, 300, True),
    "balance chart": (0, 300, 640, 400, False),
    "bottom tiles": (0, 400, 640, 480, True),
}


def main() -> int:
    shot_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("/tmp")
    hard_fail = False
    for shot_name, ref_name in SHOTS:
        shot = shot_dir / shot_name
        ref = REFS / ref_name
        if not shot.exists():
            print(f"missing {shot}", file=sys.stderr)
            return 2
        if not ref.exists():
            print(f"missing {ref}", file=sys.stderr)
            return 2
        a = np.asarray(Image.open(shot).convert("RGB"), dtype=np.int16)
        b = np.asarray(Image.open(ref).convert("RGB"), dtype=np.int16)[:, :640]
        if a.shape[:2] != (480, 640):
            print(
                f"{shot_name} is {a.shape[1]}x{a.shape[0]}, need 640x480 "
                f"(pass --resolution 640x480 on a 640x480 display)",
                file=sys.stderr,
            )
            return 2
        d = np.abs(a - b).max(axis=2) > 8
        print(f"{shot_name}  vs  {ref_name}")
        for name, (x0, y0, x1, y1, zero) in REGIONS.items():
            n = int(d[y0:y1, x0:x1].sum())
            flag = ""
            if zero and n:
                flag = "  <-- MUST BE 0"
                hard_fail = True
            print(f"  {name:18s} {n:6d}{flag}")
        print(f"  {'TOTAL':18s} {int(d.sum()):6d}")
    return 1 if hard_fail else 0


if __name__ == "__main__":
    raise SystemExit(main())
