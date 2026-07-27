#!/usr/bin/env python3
"""Pixel-diff the FINANCES INCOME / EXPENSES detail-view parity shots against the
walkthrough frames they were baked from (finance tour run 3, Man Utd, week "CURRENT 4").

Usage:  python3 tools/re/diff_finance_detail_parity.py <shot_dir>

Produce the shots first:

    DISPLAY=:5 PM98_SHOT_DIR=<dir> ~/godot462 --rendering-driver opengl3 \\
        --resolution 640x480 --path app --script res://tests/shot_finance_detail.gd

Three shots, three witnessed states:

  finance_income_week.png      vs 006  INCOME / PER WEEK, the named SALE row
  finance_expenses_week.png    vs 008  EXPENSES / PER WEEK, every cell £0
  finance_expenses_season.png  vs 012  EXPENSES / PER SEASON, wages/bonus/staff live

EVERY region must be 0. The single exclusion per frame is the mouse's own hover ring
on the tab it was parked on when the frame was grabbed (006: INCOME, 008: EXPENSES,
012: INC.+EXP.) — the app bakes the ring-free tab witnessed one frame later, and the
baker asserts that transplant, so the ring is the camera's cursor, not chrome.
There is NO balance-chart exclusion here: the detail views carry no chart.
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
FRAMES = ROOT / "screenshots" / "original-walkthrough-2026-07-02"

# shot -> (frame, hover-ring exclusion rect x0,y0,x1,y1)
SHOTS = [
    ("finance_income_week.png", "006_164349.png", (110, 2, 222, 38)),
    ("finance_expenses_week.png", "008_164357.png", (218, 2, 330, 38)),
    ("finance_expenses_season.png", "012_164404.png", (2, 2, 114, 38)),
]

# region -> (x0, y0, x1, y1); every one must diff to zero
REGIONS = {
    "tab strip": (0, 0, 640, 46),
    "header": (0, 46, 640, 80),
    "left column": (0, 80, 320, 396),
    "right column": (320, 80, 640, 396),
    "bottom tiles": (0, 396, 640, 480),
}


def main() -> int:
    shot_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("/tmp")
    hard_fail = False
    for shot_name, ref_name, ring in SHOTS:
        shot = shot_dir / shot_name
        ref = FRAMES / ref_name
        if not shot.exists() or not ref.exists():
            print(f"missing {shot if not shot.exists() else ref}", file=sys.stderr)
            return 2
        a = np.asarray(Image.open(shot).convert("RGB"), dtype=np.int16)
        b = np.asarray(Image.open(ref).convert("RGB"), dtype=np.int16)[:, :640]
        if a.shape[:2] != (480, 640):
            print(f"{shot_name} is {a.shape[1]}x{a.shape[0]}, need 640x480", file=sys.stderr)
            return 2
        d = np.abs(a - b).max(axis=2) > 8
        rx0, ry0, rx1, ry1 = ring
        d[ry0:ry1, rx0:rx1] = False
        print(f"{shot_name}  vs  {ref_name}  (cursor-ring exclusion x{rx0}..{rx1} y{ry0}..{ry1})")
        for name, (x0, y0, x1, y1) in REGIONS.items():
            n = int(d[y0:y1, x0:x1].sum())
            flag = ""
            if n:
                flag = "  <-- MUST BE 0"
                hard_fail = True
            print(f"  {name:14s} {n:6d}{flag}")
        print(f"  {'TOTAL':14s} {int(d.sum()):6d}")
    return 1 if hard_fail else 0


if __name__ == "__main__":
    raise SystemExit(main())
