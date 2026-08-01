#!/usr/bin/env python3
"""Scan every committed capture for the YOUTH TEAM screen.

The screen is identified by a lattice of probe pixels taken from the two binding
frames' SHARED chrome (087_154632 and 047_164509 agree there regardless of live
state), so any frame of the screen matches whatever the scout/manager bars hold.
For each hit the PLAYERS FOUND interior and the roster band are summarised so a
FILLED panel or a FILLED row stands out of the list.
"""
from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SHOTS = ROOT / "screenshots"
A = SHOTS / "original-walkthrough-2026-07-02" / "087_154632.png"
B = SHOTS / "original-walkthrough-2026-07-02" / "047_164509.png"

# frame-measured (docs/re/youth_re.md): PLAYERS FOUND interior and the 11 roster rows
PF = (326, 102, 302, 117)
ROWS = (56, 303, 400, 176)


def as_frame(im: Image.Image) -> Image.Image:
    im = im.convert("RGB")
    if im.width == 641:
        im = im.crop((0, 0, 640, im.height))
    return im


def probes() -> list[tuple[int, int, tuple[int, int, int]]]:
    a, b = as_frame(Image.open(A)), as_frame(Image.open(B))
    pa, pb = a.load(), b.load()
    out = []
    for y in range(60, 480, 6):
        for x in range(2, 640, 6):
            if pa[x, y] == pb[x, y]:
                out.append((x, y, pa[x, y]))
    return out


def main() -> int:
    pr = probes()
    print(f"{len(pr)} shared probes")
    hits = []
    for p in sorted(SHOTS.rglob("*.png")):
        try:
            im = as_frame(Image.open(p))
        except Exception:
            continue
        if im.size[0] < 640 or im.size[1] < 480:
            continue
        px = im.load()
        good = sum(1 for x, y, c in pr if px[x, y] == c)
        if good / len(pr) < 0.93:
            continue
        pf = im.crop((PF[0], PF[1], PF[0] + PF[2], PF[1] + PF[3]))
        rows = im.crop((ROWS[0], ROWS[1], ROWS[0] + ROWS[2], ROWS[1] + ROWS[3]))
        hits.append((p, good / len(pr), len(pf.getcolors(1 << 16) or []),
                     len(rows.getcolors(1 << 16) or [])))
    for p, f, npf, nrow in hits:
        print(f"{f:.3f}  pf_colors={npf:<4} row_colors={nrow:<4} {p.relative_to(ROOT)}")
    print(f"{len(hits)} youth-screen frames")
    return 0


if __name__ == "__main__":
    sys.exit(main())
