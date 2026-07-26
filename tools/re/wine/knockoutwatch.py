#!/usr/bin/env python3
"""Find the two knockout cells the port still has no witness for, in a drive's frames.

The build of the BRACKET and FINAL layouts needs two things no forward probe catches
(`docs/re/knockout_views_re.md`): a bracket `AGGR.` cell with a DECIDED tie in it, and a
`WINNER` band with a club in it. Both exist only for the few days between a phase resolving
and the next being drawn, so they are found by scanning every frame a drive banks rather
than by photographing a moment.

    knockoutwatch.py scan  <dir> [--keep <dir>]   report (and copy) every hit
    knockoutwatch.py watch <dir> [--keep <dir>]   the same, once a minute, forever

Both cells are detected by their GROUND colour first and their ink second, which is the
lesson the previous watcher cost: the domestic form of the same bracket puts a light-grey
`REPLAY` plate where the European one puts a navy `AGGR.` box, so a plain "is there ink
here" test fires on every unplayed F.A. Cup quarter-final. Require the rect to BE navy.
"""

from __future__ import annotations

import argparse
import shutil
import sys
import time
from pathlib import Path

import numpy as np
from PIL import Image

# --- the bracket, measured on 03_euroleague_qtrfinals_LEG1_PLAYED_1998-03-14.png ---
PANEL_TOPS = (113, 193, 273, 353)
AGGR_BOX = (310, 414)        # x span of the third plate slot's value box
AGGR_DY = (48, 61)           # its rows, relative to the panel top
NAVY = (20, 0, 90)

# --- the final, measured on 05_euroleague_final_UNDECIDED_1998-04-25.png ---
WINNER_BAR = (70, 370, 383, 397)   # x0, x1, y0, y1 of the empty band (the
                                   # laurel wreath overlaps it from x374, so stop short)
WINNER_BG = (200, 220, 240)


def frame(path: Path) -> np.ndarray | None:
    try:
        a = np.asarray(Image.open(path).convert("RGB"), dtype=np.int16)
    except Exception:
        return None
    if a.shape[0] != 480 or a.shape[1] < 640:
        return None
    return a[:, :640]


def is_bracket(a: np.ndarray) -> bool:
    """The four-panel layout, by its own black frame rules -- not by the AGGR box.

    Without this the compact LIST layout scores hits: its AGGR. column head is a navy
    gradient in very nearly the same rect, with white column-title ink on it.
    """
    for top in PANEL_TOPS:
        for y in (top, top + 71):
            if int((a[y, 20:478].max(axis=1) < 24).sum()) < 440:
                return False
    return True


def aggr_hit(a: np.ndarray) -> int:
    """Ink inside a bracket AGGR. box, counted only where the box really is navy."""
    if not is_bracket(a):
        return 0
    total = 0
    for top in PANEL_TOPS:
        box = a[top + AGGR_DY[0]:top + AGGR_DY[1] + 1, AGGR_BOX[0]:AGGR_BOX[1] + 1]
        navy = (np.abs(box - np.array(NAVY)).max(axis=2) == 0)
        if navy.sum() < 800:          # not the European form of this slot
            continue
        total += int((box.min(axis=2) > 200).sum())
    return total


def is_final(a: np.ndarray) -> bool:
    """The FINAL layout, by the WINNER band's own black frame rows.

    The CHARITY SHIELD screen is a different single-match layout that happens to paint
    something in the same rows, and scored a hit before this guard existed.
    """
    return all(int((a[y, 60:430].max(axis=1) < 24).sum()) > 280 for y in (354, 355, 414))


def winner_hit(a: np.ndarray) -> int:
    """Ink inside the FINAL's WINNER band, counted only where the band really is there."""
    if not is_final(a):
        return 0
    x0, x1, y0, y1 = WINNER_BAR
    bar = a[y0:y1 + 1, x0:x1 + 1]
    bg = (np.abs(bar - np.array(WINNER_BG)).max(axis=2) == 0)
    if bg.sum() < 3000:
        return 0
    return int((~bg).sum())


def scan(d: Path, keep: Path | None) -> int:
    hits = 0
    for f in sorted(d.glob("*.png")):
        a = frame(f)
        if a is None:
            continue
        ag = aggr_hit(a)
        wn = winner_hit(a)
        if ag == 0 and wn == 0:
            continue
        hits += 1
        what = " ".join(x for x in [f"AGGR({ag})" if ag else "", f"WINNER({wn})" if wn else ""] if x)
        print(f"HIT {f.name}  {what}", flush=True)
        if keep is not None:
            keep.mkdir(parents=True, exist_ok=True)
            shutil.copy2(f, keep / f.name)
    return hits


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("mode", choices=["scan", "watch"])
    ap.add_argument("dir", type=Path)
    ap.add_argument("--keep", type=Path, help="copy every hit here")
    ap.add_argument("--every", type=float, default=60.0)
    a = ap.parse_args()
    if a.mode == "scan":
        n = scan(a.dir, a.keep)
        print(f"{n} frame(s) carry one of the two cells")
        return 0 if n else 1
    seen: set = set()
    while True:
        for f in sorted(a.dir.glob("*.png")):
            if f.name in seen:
                continue
            seen.add(f.name)
            arr = frame(f)
            if arr is None:
                continue
            ag = aggr_hit(arr)
            wn = winner_hit(arr)
            if ag or wn:
                what = " ".join(x for x in [f"AGGR({ag})" if ag else "",
                                            f"WINNER({wn})" if wn else ""] if x)
                print(f"HIT {f.name}  {what}", flush=True)
                if a.keep is not None:
                    a.keep.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(f, a.keep / f.name)
        time.sleep(a.every)


if __name__ == "__main__":
    sys.exit(main())
