#!/usr/bin/env python3
"""Pixel-diff the NEWS extra parity shots against the binding walkthrough frames.
Usage:  python3 tools/re/diff_news_parity.py <shot_dir> [--heatmap-dir out]

Diffs ONLY the overlay footprint (page rect x145..494, y27..451): outside it the
original frames show the live animated hub, which the bare parity shot does not
render. Exit 0 iff every shot's footprint diff is 0px.
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
FRAMES = ROOT / "screenshots" / "original-walkthrough-2026-07-02"
if not FRAMES.exists():  # full capture set is local-only; binding frames are committed
    FRAMES = ROOT / "tools" / "re" / "refs" / "walkthrough-2026-07-02"

PAGE = (145, 27, 350, 425)  # x, y, w, h — the whole overlay footprint
PAIRS = [
    ("news_155.png", "155_154857.png"),
    ("news_156.png", "156_154859.png"),
    ("news_158.png", "158_154905.png"),
]


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    shot_dir = Path(sys.argv[1])
    heat_dir = None
    if "--heatmap-dir" in sys.argv:
        heat_dir = Path(sys.argv[sys.argv.index("--heatmap-dir") + 1])
        heat_dir.mkdir(parents=True, exist_ok=True)
    x, y, w, h = PAGE
    ok = True
    for shot_name, frame_name in PAIRS:
        sp = shot_dir / shot_name
        fp = FRAMES / frame_name
        if not sp.exists() or not fp.exists():
            print(f"[MISS] {shot_name} vs {frame_name}: file missing")
            ok = False
            continue
        shot = np.asarray(Image.open(sp).convert("RGB")).astype(int)
        frame = np.asarray(Image.open(fp).convert("RGB")).astype(int)
        s = shot[y : y + h, x : x + w]
        f = frame[y : y + h, x : x + w]
        d = np.abs(s - f).max(axis=2)
        n = int((d > 0).sum())
        if n == 0:
            print(f"[OK]   {shot_name} vs {frame_name}: 0px")
        else:
            ys, xs = np.nonzero(d > 0)
            print(
                f"[FAIL] {shot_name} vs {frame_name}: {n}px "
                f"(page-rel x{xs.min()}..{xs.max()} y{ys.min()}..{ys.max()})"
            )
            ok = False
            if heat_dir is not None:
                hm = np.zeros((h, w, 3), dtype=np.uint8)
                hm[..., 0] = np.clip(d * 8, 0, 255)
                Image.fromarray(hm).save(heat_dir / f"heat_{shot_name}")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
