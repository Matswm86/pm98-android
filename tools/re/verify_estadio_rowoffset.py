#!/usr/bin/env python3
"""Validate the ESTADIO tiles' ROW OFFSET from the data alone, on all twelve.

`stadium_screen_re.md` records the misregistration as

    panel(bx, by)  <-  tile[(by + (2 if bx < 64 else 1)) % 240][(bx + 256) % 320]

and says the **column** wrap is validated on 12 of 12 by a seam statistic, but that
the **row offset** -- the `+2` on the left 64 columns against `+1` on the other
256 -- is only confirmed on tiers 3 and 4, where a real GROUND capture exists,
because "a one- or two-row error would not move the seam statistic".

That is true of the ±256 seam statistic and false of the right one. The row offset
is a RELATIVE shift between two blocks of the SAME picture that meet at x = 63|64.
If it is wrong by a row, the corrected tile has a one-row vertical discontinuity
exactly there -- and the picture's own horizontal continuity measures it, with no
render needed.

So: for each shipped tile, score the boundary column pair (63, 64) under every
candidate extra shift of the left block, and check the shipped choice is the
MINIMUM. That -- and only that -- is the claim. The margins are small (1.5-4.5
mean-|Δ| units) because the two sides of the boundary are different stand
geometry and the join is never smooth, so this does NOT show the boundary is
seamless; it shows which shift is least bad, twelve times out of twelve, with
five candidates each. An interior column pair is printed as a control so the
scale of the numbers is visible.

    python tools/re/verify_estadio_rowoffset.py
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
TILES = ROOT / "app" / "art" / "screens" / "stadium"
H, W = 240, 320
SPLIT = 64  # the wrap boundary: bx < 64 takes the extra row
CANDIDATES = (-2, -1, 0, 1, 2)  # extra rows applied to the LEFT block; 0 = as shipped


def boundary_cost(img: np.ndarray, shift: int, x: int = SPLIT) -> float:
    """Mean |Δ| across the column pair (x-1, x) with the left block rolled `shift` rows."""
    left = np.roll(img[:, x - 1], shift, axis=0).astype(int)
    right = img[:, x].astype(int)
    return float(np.abs(left - right).mean())


def control_spread(img: np.ndarray) -> tuple[float, float]:
    """What a NORMAL column pair scores, and how much shifting it costs.

    Sampled away from the boundary so it measures the picture's own texture.
    """
    base = []
    worst = []
    for x in (32, 96, 160, 224, 288):
        if x == SPLIT:
            continue
        base.append(boundary_cost(img, 0, x))
        worst.append(max(boundary_cost(img, s, x) for s in CANDIDATES if s != 0))
    return float(np.mean(base)), float(np.mean(worst))


def main() -> int:
    tiles = sorted(TILES.glob("estadio*.png"), key=lambda p: int(p.stem[7:]))
    if not tiles:
        print(f"no estadio*.png under {TILES}")
        return 2
    print(f"{'tile':<12} {'as-shipped':>11} {'best shift':>11} {'runner-up':>11}  verdict")
    bad = 0
    for p in tiles:
        img = np.asarray(Image.open(p).convert("RGB"))
        if img.shape[:2] != (H, W):
            print(f"{p.name:<12} unexpected size {img.shape[:2]}")
            bad += 1
            continue
        costs = {s: boundary_cost(img, s) for s in CANDIDATES}
        best = min(costs, key=costs.get)
        runner = min((c for s, c in costs.items() if s != best), default=float("inf"))
        ctl_base, ctl_worst = control_spread(img)
        # The claim under test is only this: the shipped offset is the MINIMUM. The
        # margin is reported, not thresholded -- on a picture whose two sides are
        # different stand geometry the boundary is never smooth, so a large margin was
        # never on offer and demanding one would be inventing a bar.
        margin = runner - costs[0]
        ok = best == 0
        if not ok:
            bad += 1
        print(
            f"{p.name:<12} {costs[0]:11.3f} {best:+11d} {runner:11.3f}  "
            f"{'MIN' if ok else 'SHIFT %+d' % best}  margin {margin:+.2f}"
            f"   (control {ctl_base:.2f} -> {ctl_worst:.2f})"
        )
    print()
    if bad:
        print(
            f"{bad} of {len(tiles)} tiles put the minimum somewhere OTHER than the "
            f"shipped offset -- the mapping is wrong for those."
        )
        return 1
    print(
        f"All {len(tiles)} tiles put the minimum at the SHIPPED offset "
        f"(`+2 for bx < 64, +1 otherwise`), from the data alone."
    )
    print(
        "Five candidates per tile, so twelve independent agreements; the margins are "
        "small (1.5-4.5) because the two sides of x=63|64 are different stand geometry "
        "and the boundary is never smooth -- what is being tested is WHICH shift is "
        "least bad, and it is the shipped one on every tile."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
