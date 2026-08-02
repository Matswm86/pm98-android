#!/usr/bin/env python3
"""Decide, per palette index, which of the two tables the RUNNING game realises.

The method is `realised_palette_re.md` §5's, generalised: do not look for a SPRITE in a
frame (which needs the sprite's own witness and its exact blit rect); look for the COLOUR.
The shared VGA table at `DAT.PKF +0x5CA` and the realised MANAGER.PAL + Windows statics
differ at 21 indices, and — checked, not assumed — none of the 21 VGA colours appears
anywhere in the realised table. So a frame MANAGER.EXE painted either contains the VGA
colour or it does not, and that is a decision with no free parameter.

    probe_realised_palette_witness.py [FRAME_DIR ...]

Default corpus is every original capture under `screenshots/`, which is every frame the
project has ever banked off the real game. Frames drawn by another executable (the DATABASE
is Dbasewin under its own palette; the 3D match view) are NOT excluded here — the counts
are reported per directory so those show up as themselves rather than being hand-waved.
"""

from __future__ import annotations

import sys
from collections import Counter
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import export_flags as EF  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
SHOTS = ROOT / "screenshots"


def tables() -> tuple[list[int], list[tuple[int, int, int]], list[tuple[int, int, int]]]:
    vga = EF.vga_palette()
    real = EF.flag_palette()
    return [i for i in range(256) if vga[i] != real[i]], vga, real


def count(frames: list[Path], bad: list[int], vga, real) -> tuple[Counter, Counter]:
    v, r = Counter(), Counter()
    for f in frames:
        a = np.array(Image.open(f).convert("RGB")).reshape(-1, 3)
        for i in bad:
            for tbl, acc in ((vga[i], v), (real[i], r)):
                n = int(((a[:, 0] == tbl[0]) & (a[:, 1] == tbl[1]) & (a[:, 2] == tbl[2])).sum())
                if n:
                    acc[i] += n
    return v, r


def main() -> int:
    bad, vga, real = tables()
    # The premise the whole method rests on, re-checked every run rather than trusted.
    overlap = {i: vga[i] for i in bad if vga[i] in set(real)}
    if overlap:
        print(f"AMBIGUOUS — VGA colours that also live in the realised table: {overlap}")
        return 1
    print(
        f"{len(bad)} affected indices; none of their VGA colours is anywhere in the "
        f"realised table, so a hit is unambiguous.\n"
    )

    dirs = [Path(a) for a in sys.argv[1:]] or sorted(d for d in SHOTS.iterdir() if d.is_dir())
    tot_v, tot_r = Counter(), Counter()
    for d in dirs:
        frames = sorted(d.rglob("*.png"))
        if not frames:
            continue
        v, r = count(frames, bad, vga, real)
        tot_v.update(v)
        tot_r.update(r)
        print(
            f"{d.name:<48} {len(frames):>4} frames   VGA {sum(v.values()):>9}   "
            f"realised {sum(r.values()):>9}"
        )

    print("\nper index, over the whole corpus:")
    print(f"  {'idx':>4}  {'VGA colour':<18} {'px':>10}   {'realised colour':<18} {'px':>10}")
    for i in bad:
        print(
            f"  {i:>4}  {str(vga[i]):<18} {tot_v.get(i, 0):>10}   "
            f"{str(real[i]):<18} {tot_r.get(i, 0):>10}"
        )
    print(f"\ntotal   VGA {sum(tot_v.values())}   realised {sum(tot_r.values())}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
