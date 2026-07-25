#!/usr/bin/env python3
"""Pixel-diff the three season-end parity shots against the frames they were baked from.

Usage:  python3 tools/re/diff_seasonend_year_parity.py <shot_dir>

Produce the shots first:

    DISPLAY=:5 PM98_SHOT_DIR=<dir> ~/godot462 --rendering-driver opengl3 \\
        --resolution 640x480 --path app --script res://tests/shot_seasonend_year.gd

Each shot reproduces the WITNESSED state of its frame — the reference run's own eight
finals, its own four-division overview, its own twenty Premier awards — so the chrome
must be exact everywhere and the redrawn text must land on the original's own pixels.

The KIT blocks are reported separately and are NOT required to be zero: the app has no
kit art for the frame's European clubs (Real Madrid, Parma, AEK Atenas, Sturm Graz,
Cruzeiro), and for the domestic ones the shot is fed club_id -1 so no kit is drawn at
all. That is a data gap in the shot's inputs, not a geometry error, and it is the only
region excluded.
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
REFS = ROOT / "tools" / "re" / "refs" / "season-end-2026-07-25"

# shot -> (reference frame, {region: (x0, y0, x1, y1, must_be_zero)})
SHOTS = {
    "championships.png": (
        "20_the_championships.png",
        {
            "barra": (0, 0, 640, 60, True),
            "trophies + titles": (0, 60, 640, 113, True),
            "kit blocks": (54, 113, 82, 432, False),
            "kit blocks (right)": (332, 113, 360, 432, False),
            "club names": (82, 113, 242, 432, True),
            "club names (right)": (360, 113, 520, 432, True),
            "scores": (243, 113, 276, 432, True),
            "scores (right)": (521, 113, 584, 432, True),
            "CONTINUE": (490, 432, 640, 480, True),
        },
    ),
    "endofseason.png": (
        "21_end_of_season.png",
        {
            "barra": (0, 0, 640, 60, True),
            "division bands": (0, 60, 640, 100, True),
            "champion kits": (16, 96, 36, 440, False),
            "champion names": (36, 96, 174, 440, True),
            "middle column": (185, 96, 333, 465, True),
            "relegated column": (345, 96, 493, 465, True),
            "CONTINUE": (500, 420, 640, 465, True),
        },
    ),
    "players_year.png": (
        "23_players_of_the_year.png",
        {
            "barra": (0, 0, 640, 60, True),
            "panel + headers": (24, 84, 616, 127, True),
            "TEAM / PLAYER rows": (24, 127, 616, 290, True),
            "division tabs": (378, 343, 616, 406, True),
            "CONTINUE": (500, 424, 616, 453, True),
        },
    ),
}


def main() -> int:
    shot_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("/tmp")
    hard_fail = False
    for shot_name, (ref_name, regions) in SHOTS.items():
        shot = shot_dir / shot_name
        ref = REFS / ref_name
        if not shot.exists():
            print(f"missing {shot}", file=sys.stderr)
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
        for name, (x0, y0, x1, y1, zero) in regions.items():
            n = int(d[y0:y1, x0:x1].sum())
            flag = ""
            if zero and n:
                flag = "  <-- MUST BE 0"
                hard_fail = True
            print(f"  {name:22s} {n:6d}{flag}")
        print(f"  {'TOTAL':22s} {int(d.sum()):6d}")
    return 1 if hard_fail else 0


if __name__ == "__main__":
    raise SystemExit(main())
