#!/usr/bin/env python3
"""Pixel-diff the SUSPENDED LINE-UP row against the wine witness.

Usage:  python3 tools/re/diff_lineup_ban_parity.py <shot_dir>

Shot:  DISPLAY=:4 PM98_SHOT_DIR=<dir> ~/godot462 --rendering-driver opengl3 \\
           --resolution 640x480 --path app --script res://tests/shot_lineup_ban_row.gd

Witness: `out/refrun-manutd-9798/play/p0349_UNKNOWN.png` — the reference Manchester Utd.
1997-98 season, RESERVES row `2 Gary Neville [two yellow cards] 2 MATCHES`. The shot
reproduces the same ban count, so the three banner boxes must be identical.

Only the banner is compared: the rest of the row is this club's own name / number /
values, which are deliberately different. The rows are aligned on the gold plate's top
edge rather than assumed, because the witness row is a RESERVE and the shot's is in the
XI. Exit 0 iff all three boxes diff 0 px.
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
REF = ROOT / "out" / "refrun-manutd-9798" / "play" / "p0349_UNKNOWN.png"

GOLD = np.array([212, 191, 85])
PLATE_PROBE_X = 60
ROW_H = 13
BOXES = {"icon": (174, 198), "count": (199, 223), "unit": (224, 298)}


def frame(path: Path) -> np.ndarray:
    a = np.asarray(Image.open(path).convert("RGB"), dtype=np.int16)
    if a.shape[0] != 480 or a.shape[1] < 640:
        raise SystemExit(f"{path} is {a.shape[1]}x{a.shape[0]}, need 640x480")
    return a[:, :640]


def plate_top(a: np.ndarray) -> int | None:
    """Top row of the first SUSPENDED gold plate below the column header.

    A frame can carry several unavailable rows; the witness carries an injured reserve
    ABOVE the banned one. The two are told apart by the icon cell: a suspension has no
    red medical cross in it.
    """
    m = np.abs(a[:, PLATE_PROBE_X] - GOLD).max(axis=1) <= 8
    x0, x1 = BOXES["icon"]
    for y in range(88, 460):
        if not (m[y] and not m[y - 1]):
            continue
        cell = a[y:y + ROW_H, x0:x1]
        red = ((cell[:, :, 0] > 170) & (cell[:, :, 1] < 70) & (cell[:, :, 2] < 70)).sum()
        if red == 0:
            return y
    return None


def main() -> int:
    shot_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("/tmp")
    shot = shot_dir / "lineup_ban_row.png"
    if not shot.exists():
        print(f"missing {shot}", file=sys.stderr)
        return 2
    if not REF.exists():
        print(f"witness missing: {REF}", file=sys.stderr)
        return 2
    a, b = frame(shot), frame(REF)
    ta, tb = plate_top(a), plate_top(b)
    if ta is None or tb is None:
        print("no gold unavailable row found", file=sys.stderr)
        return 2
    total = 0
    for name, (x0, x1) in BOXES.items():
        d = int((np.abs(a[ta:ta + ROW_H, x0:x1] - b[tb:tb + ROW_H, x0:x1]).max(axis=2) > 8).sum())
        total += d
        print(f"  {name:6s} {d:5d}")
    print(f"  {'TOTAL':6s} {total:5d}")
    return 0 if total == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
