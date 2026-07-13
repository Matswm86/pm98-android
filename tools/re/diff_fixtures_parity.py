#!/usr/bin/env python3
"""Pixel-diff the FixturesScreen (THE CALENDAR) parity shot against the binding
walkthrough frame 051_154519.png.

Usage:  python3 tools/re/diff_fixtures_parity.py <shot_dir> [--heatmap out.png]

The whole screen is engine-composited, so the shot (chrome baked from 051 + the
redrawn dynamic layer) is diffed against the FULL frame. Known-approximated /
un-witnessed regions are excluded explicitly and each carries a docs/re reason.
Prints the differing-pixel count + fraction (both raw and after exclusions),
mean abs diff, and the top mismatch clusters so any drift is locatable.
Exit 0 iff the excluded-region fraction is under THRESH.
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

SHOT = "fixtures_051.png"
FRAME = "051_154519.png"
THRESH = 0.004  # <0.4% of the 640x480 frame after documented exclusions

# Excluded rects [x0,y0,x1,y1] — each a documented approximation (fixtures_screen_re.md):
#  - RETURN ball/arrow icon: the SEGUIR ball ANIMATES (052/053/054 differ from 051
#    ONLY here); the chrome bakes 051's phase, so this is a stability guard not drift.
#  - header text band: recomposed via PMChrome.draw_match_header (band + PROMAN
#    rasters + baked title sprite) — sub-pixel raster hinting can drift 1px vs the
#    frame's own text, the same tolerance the LINE-UP/VIEW RIVAL header rollout took.
EXCLUDE = [
    (519, 429, 632, 466),   # RETURN animated ball/arrow icon
]


def load(p: Path) -> np.ndarray:
    a = np.asarray(Image.open(p).convert("RGB"))
    return a[:480, :640]


def clusters(mask: np.ndarray, max_out: int = 8) -> list[str]:
    out: list[str] = []
    m = mask.copy()
    for _ in range(max_out):
        ys, xs = np.where(m)
        if len(xs) == 0:
            break
        y0, x0 = int(ys.min()), int(xs.min())
        # grow a bbox around the densest corner greedily
        yb, xb = y0, x0
        for _ in range(6):
            sub = m[y0 : yb + 40, x0 : xb + 40]
            sy, sx = np.where(sub)
            if len(sx) == 0:
                break
            yb, xb = y0 + int(sy.max()), x0 + int(sx.max())
        cnt = int(m[y0 : yb + 1, x0 : xb + 1].sum())
        out.append(f"({x0},{y0})-({xb},{yb}) {cnt}px")
        m[y0 : yb + 1, x0 : xb + 1] = False
    return out


def main() -> None:
    if len(sys.argv) < 2:
        raise SystemExit("usage: diff_fixtures_parity.py <shot_dir> [--heatmap out.png]")
    shot_dir = Path(sys.argv[1])
    shot = load(shot_dir / SHOT)
    frame = load(FRAMES / FRAME)
    if shot.shape != frame.shape:
        raise SystemExit(f"size mismatch: shot {shot.shape} vs frame {frame.shape}")

    diff = np.abs(shot.astype(int) - frame.astype(int)).sum(axis=2)
    raw_mask = diff > 12                 # >4/channel: ignore capture JPEG-ish noise
    total = raw_mask.size
    raw = int(raw_mask.sum())

    excl_mask = raw_mask.copy()
    for x0, y0, x1, y1 in EXCLUDE:
        excl_mask[y0 : y1 + 1, x0 : x1 + 1] = False
    kept = int(excl_mask.sum())

    print(f"frame:   {FRAME}")
    print(f"shot:    {shot_dir / SHOT}")
    print(f"raw diff (>12/px):   {raw:6d} px  ({raw / total:.4%})")
    print(f"after exclusions:    {kept:6d} px  ({kept / total:.4%})   thresh {THRESH:.2%}")
    print(f"mean abs diff:       {diff.mean():.3f}")
    if kept:
        print("top mismatch clusters (after exclusions):")
        for c in clusters(excl_mask):
            print(f"   {c}")

    if "--heatmap" in sys.argv:
        hp = Path(sys.argv[sys.argv.index("--heatmap") + 1])
        heat = np.zeros((480, 640, 3), dtype="uint8")
        heat[..., 0] = np.clip(diff, 0, 255)
        heat[excl_mask, 1] = 255
        Image.fromarray(heat).save(hp)
        print(f"heatmap -> {hp}")

    sys.exit(0 if kept / total < THRESH else 1)


if __name__ == "__main__":
    main()
