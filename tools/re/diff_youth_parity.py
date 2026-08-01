#!/usr/bin/env python3
"""Pixel-diff the YOUTH TEAM parity shots against the binding walkthrough frames.
Usage:  python3 tools/re/diff_youth_parity.py <shot_dir> [--heatmap-dir out]

Diffs the BODY (y >= BODY_Y): the barra above it is PMChrome's shared live header,
pixel-proven by the CALENDAR/entry gates and containing the club crest the shots
don't pin (club_id -1). Header diffs are printed as info, never gate.
Exit 0 iff every shot's body diff is 0px.
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

BODY_Y = 58
PAIRS = [
    ("youth_087.png", "087_154632.png"),
    ("youth_088.png", "088_154633.png"),
    ("youth_089.png", "089_154635.png"),
    ("youth_047.png", "047_164509.png"),
    ("youth_048.png", "048_164510.png"),
]
# B9's own un-occluded witness of the FILLED list — a live wine capture, not a
# walkthrough frame, so it carries its own directory.
B9 = ROOT / "tools" / "re" / "refs" / "b9-players-found-2026-08-01"
B9ROW = ROOT / "tools" / "re" / "refs" / "youth-roster-2026-08-01"
EXTRA_PAIRS = [
    ("youth_b9found.png", B9 / "02_players_found_first.png"),
    # B9's third and last gap, CLOSED 2026-08-01 (s87) and now GATED like the rest. It was
    # REPORT-ONLY at 1,816 px while the row PLATE and per-cell GRID were still the port's
    # own. Five defects fell out of closing it, every one measured off this frame:
    #   * the row's PLATE, its nine cell DIVIDERS, the black-bordered ROL box and its own
    #     LEFT CHIP (162 px apart from the empty row's) are now cut from the frame
    #     (`tools/re/build_youth_rowgrid_from_frame.py`);
    #   * AV is the four-attribute AVERAGE, not CA — the row reads 20/19/20/21 with AV 20;
    #   * the row's text baseline is +3 inside the plate, not +2;
    #   * NAME starts at x62 (not 59), WAGE centres on 359 (not 358), ST on 212 (not 211);
    #   * the ROL icon is `camrol01`, matched 0-mismatch against all eighteen sprites.
    # It also settled two things the panel above it had left open — see the module note
    # in build_youth_found_list_from_frames.py (the cell grid belongs to the POPULATED row)
    # and build_youth_star_halves_from_frames.py (the half star has TWO parities).
    ("youth_b9roster.png", B9ROW / "b9_roster_signed_1998-10-03.png"),
]
REPORT_ONLY: list[tuple[str, Path]] = []  # nothing is report-only any more


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    shot_dir = Path(sys.argv[1])
    heat_dir = None
    if "--heatmap-dir" in sys.argv:
        heat_dir = Path(sys.argv[sys.argv.index("--heatmap-dir") + 1])
        heat_dir.mkdir(parents=True, exist_ok=True)
    ok = True
    todo = [(s, FRAMES / f) for s, f in PAIRS] + EXTRA_PAIRS + REPORT_ONLY
    report_only = {s for s, _ in REPORT_ONLY}
    for shot_name, fp in todo:
        frame_name = fp.name
        sp = shot_dir / shot_name
        only = shot_name in report_only
        if not sp.exists() or not fp.exists():
            print(f"[MISS] {shot_name} vs {frame_name}: file missing")
            ok = ok and only
            continue
        shot = np.asarray(Image.open(sp).convert("RGB")).astype(int)[:480, :640]
        frame = np.asarray(Image.open(fp).convert("RGB")).astype(int)[:480, :640]
        d = np.abs(shot - frame).max(axis=2) > 12
        # (58,522): the original's own header football/plate seam is PHASE-dependent
        # (frame 051 in-season = 44,44,44; preseason frames = 22,22,22). PMChrome's
        # shared header asset is the 051 cut, so this single pixel differs on
        # preseason screens — an original-state variance, not a youth-body defect.
        d[58, 522] = False
        head = int(d[:BODY_Y].sum())
        body = d[BODY_Y:]
        n = int(body.sum())
        status = "PASS" if n == 0 else ("INFO" if only else "FAIL")
        print(f"[{status}] {shot_name} vs {frame_name}: body {n}px (header {head}px, not gated)")
        if n:
            ok = ok and only
            ys, xs = np.nonzero(body)
            # top mismatch clusters (coarse 20px bands) so drift is locatable
            import collections

            bands = collections.Counter((ys + BODY_Y) // 20)
            for band, cnt in sorted(bands.items(), key=lambda kv: -kv[1])[:6]:
                sel = (ys + BODY_Y) // 20 == band
                print(
                    f"     y {band * 20}..{band * 20 + 19}: {cnt}px "
                    f"x{xs[sel].min()}..{xs[sel].max()}"
                )
            if heat_dir is not None:
                hm = np.zeros((480, 640, 3), np.uint8)
                hm[..., 0] = np.where(d, 255, 0)
                Image.blend(
                    Image.open(fp).convert("RGB").resize((640, 480)),
                    Image.fromarray(hm),
                    0.5,
                ).save(heat_dir / f"heat_{shot_name}")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
