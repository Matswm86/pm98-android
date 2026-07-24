#!/usr/bin/env python3
"""Pixel-diff the CupDrawScreen (SORTEO) parity shots against their binding frames.

Usage:  python3 tools/re/diff_cupdraw_parity.py <shot_dir> [--heatmap out_prefix]

Two shots, two real MANAGER.EXE frames:
  cupdraw_74.png  vs  wine-captures-2026-07-18-goalscorers/74_after_wk4.png
                      Coca-Cola Cup ROUND 2, 4 of 25 ties, the 4th mid-draw
  cupdraw_10.png  vs  promanager-career-2026-07-16/10_fa_cup_draw_round1.png
                      F.A. Cup ROUND 1, 4 of 40 ties, MATCH / REPLAY plates

The whole screen is engine-composited (baked chrome + the redrawn dynamic layer), so the
diff is against the FULL 640x480 frame. Excluded rects are listed with a reason each and
counted separately; exit 0 iff the post-exclusion differing fraction is under THRESH.
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
CASES = [
    (
        "cupdraw_74.png",
        ROOT / "screenshots" / "wine-captures-2026-07-18-goalscorers" / "74_after_wk4.png",
    ),
    (
        "cupdraw_10.png",
        ROOT / "screenshots" / "promanager-career-2026-07-16" / "10_fa_cup_draw_round1.png",
    ),
]
THRESH = 0.004  # <0.4% of the 640x480 frame after the documented exclusions

# Excluded rects [x0,y0,x1,y1], each a documented un-witnessed or animated region:
#  - CONTINUE's ball ANIMATES and its lit/unlit rule is un-reversed (74 dark, 75 green),
#    so the chrome bakes frame 74's phase and frame 10's own phase differs.
EXCLUDE = [
    (489, 436, 614, 470),  # CONTINUE button: animated ball + un-witnessed lit state
]


def load(p: Path) -> np.ndarray:
    return np.asarray(Image.open(p).convert("RGB"))[:480, :640]


def report(shot: Path, frame: Path, heat: str | None) -> float:
    a, b = load(shot), load(frame)
    d = (a != b).any(axis=2)
    raw = float(d.mean())
    m = d.copy()
    for x0, y0, x1, y1 in EXCLUDE:
        m[y0:y1, x0:x1] = False
    net = float(m.mean())
    print(f"{shot.name} vs {frame.name}")
    print(f"  raw      {d.sum():6d} px  {100 * raw:6.3f}%")
    print(f"  excluded {m.sum():6d} px  {100 * net:6.3f}%   (threshold {100 * THRESH:.1f}%)")
    if m.any():
        ys, xs = np.where(m)
        print(f"  bbox     x {xs.min()}..{xs.max()}  y {ys.min()}..{ys.max()}")
        # coarse 32px buckets, so drift is locatable
        buckets: dict[tuple[int, int], int] = {}
        for y, x in zip(ys.tolist(), xs.tolist()):
            k = (x // 32 * 32, y // 32 * 32)
            buckets[k] = buckets.get(k, 0) + 1
        top = sorted(buckets.items(), key=lambda kv: -kv[1])[:8]
        for (bx, by), n in top:
            print(f"    x{bx:3d} y{by:3d}  {n:5d}")
    if heat:
        Image.fromarray((m * 255).astype(np.uint8)).save(f"{heat}_{shot.stem}.png")
    return net


def main() -> None:
    if len(sys.argv) < 2:
        print(__doc__)
        raise SystemExit(2)
    shot_dir = Path(sys.argv[1])
    heat = None
    if "--heatmap" in sys.argv:
        heat = sys.argv[sys.argv.index("--heatmap") + 1]
    worst = 0.0
    for shot_name, frame in CASES:
        shot = shot_dir / shot_name
        if not shot.exists():
            print(f"MISSING {shot}")
            raise SystemExit(2)
        worst = max(worst, report(shot, frame, heat))
        print()
    print(f"worst {100 * worst:.3f}%  -> {'PASS' if worst < THRESH else 'FAIL'}")
    raise SystemExit(0 if worst < THRESH else 1)


if __name__ == "__main__":
    main()
