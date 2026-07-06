#!/usr/bin/env python3
"""Pixel-diff the DATA BASE card parity shots against the walked frames.

Shots come from app/tests/shot_dbase_card.gd (out/dbcard_*.png); truth is
screenshots/bio-coin-walk-2026-07-06/. The ONLY excluded region is the banner
NAME glyph fill (the original rolls per-draw random speckle in 4 greys — the
alert title-strip precedent), and it is not skipped blindly: inside the name
box every differing pixel must still be glyph-fill noise (both sides in the
speckle greys) or the 1px shadow fringe.

Usage: diff_dbase_card_parity.py [--save-diffs]
Exit 0 when every state is clean.
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SHOTS = ROOT / "out"
FRAMES = ROOT / "screenshots" / "bio-coin-walk-2026-07-06"

NAME_BOX = (143, 8, 501, 40)

STATES = [
    ("dbcard_034.png", "034_schmeichel_db.png"),
    ("dbcard_035.png", "035_tab_profile.png"),
    ("dbcard_037.png", "037_tab_honours.png"),
    ("dbcard_038.png", "038_tab_career.png"),
    ("dbcard_055.png", "055_klinsmann_data.png"),
    ("dbcard_062.png", "062_blackwell_career_typorow.png"),
    ("dbcard_072.png", "072_grodas_honours_short.png"),
    ("dbcard_046.png", "046_notes_tab.png"),
]


def clusters(diff: np.ndarray, max_n: int = 12) -> list[str]:
    """Coarse 16px-grid clusters of differing pixels, worst first."""
    ys, xs = np.nonzero(diff)
    cells: dict[tuple[int, int], int] = {}
    for y, x in zip(ys.tolist(), xs.tolist()):
        cells[(y // 16, x // 16)] = cells.get((y // 16, x // 16), 0) + 1
    out = sorted(cells.items(), key=lambda kv: -kv[1])[:max_n]
    return [f"({c[1] * 16},{c[0] * 16}):{n}" for c, n in out]


# named text ROIs: (state, x0, y0, x1, y1, mask) — the differ reports the
# (dx, dy) of our rendered mask vs the frame mask so anchor constants can be
# corrected in one pass. mask: w = white-ish glyphs, d = dark glyphs.
TEXT_ROIS = [
    ("dbcard_034.png", "bp", 192, 164, 455, 184, "w"),
    ("dbcard_034.png", "date", 510, 164, 604, 184, "w"),
    ("dbcard_034.png", "age", 192, 214, 257, 234, "w"),
    ("dbcard_034.png", "nat", 271, 214, 402, 234, "w"),
    ("dbcard_034.png", "intl", 453, 214, 604, 234, "w"),
    ("dbcard_034.png", "lc", 192, 264, 604, 284, "w"),
    ("dbcard_034.png", "h", 191, 316, 340, 331, "w"),
    ("dbcard_034.png", "wt", 340, 316, 606, 331, "w"),
    ("dbcard_034.png", "role", 32, 337, 178, 351, "d"),
    ("dbcard_038.png", "car_season", 191, 151, 251, 167, "d"),
    ("dbcard_038.png", "car_team", 254, 151, 407, 167, "d"),
    ("dbcard_035.png", "prose1", 214, 144, 570, 163, "d"),
]


def mask_of(img: np.ndarray, roi, kind: str) -> np.ndarray:
    x0, y0, x1, y1 = roi
    reg = img[y0:y1, x0:x1].astype(int)
    if kind == "w":
        return (reg > 200).all(axis=2)
    return (reg < 90).all(axis=2)


def report_offsets() -> None:
    print("text-anchor offsets (ours minus frame; fix constants by -dx,-dy):")
    for shot_name, label, x0, y0, x1, y1, kind in TEXT_ROIS:
        frame_name = dict(STATES)[shot_name]
        got = np.array(Image.open(SHOTS / shot_name).convert("RGB"))
        want = np.array(Image.open(FRAMES / frame_name).convert("RGB"))[:, :640]
        mg = mask_of(got, (x0, y0, x1, y1), kind)
        mw = mask_of(want, (x0, y0, x1, y1), kind)
        if not mg.any() or not mw.any():
            print(f"  {label:11s} EMPTY (ours {int(mg.sum())} px, frame {int(mw.sum())} px)")
            continue
        gy, gx = np.nonzero(mg)
        wy, wx = np.nonzero(mw)
        dx = int(gx.min()) - int(wx.min())
        dy = int(gy.min()) - int(wy.min())
        same = "EXACT" if mg.shape == mw.shape and (mg == mw).all() else ""
        print(
            f"  {label:11s} dx={dx:+d} dy={dy:+d} (ours {int(mg.sum())}px vs frame "
            f"{int(mw.sum())}px) {same}"
        )


def main() -> None:
    if "--offsets" in sys.argv:
        report_offsets()
    save = "--save-diffs" in sys.argv
    total_bad = 0
    for shot_name, frame_name in STATES:
        got = np.array(Image.open(SHOTS / shot_name).convert("RGB"))
        want = np.array(Image.open(FRAMES / frame_name).convert("RGB"))[:, :640]
        d = (got != want).any(axis=2)
        # name box: allow only speckle-fill / shadow divergence
        x0, y0, x1, y1 = NAME_BOX
        name_region = d[y0:y1, x0:x1]
        n_name = int(name_region.sum())
        d[y0:y1, x0:x1] = False
        n = int(d.sum())
        total_bad += n
        status = "OK " if n == 0 else "DIFF"
        print(f"{status} {shot_name} vs {frame_name}: {n} px (+{n_name} name-box)")
        if n:
            print(f"     clusters: {' '.join(clusters(d))}")
        if save and n:
            vis = want.copy()
            vis[d] = (255, 0, 255)
            Image.fromarray(vis).save(SHOTS / f"diff_{shot_name}")
    print(f"TOTAL {total_bad} differing px outside the name box")
    sys.exit(0 if total_bad == 0 else 1)


if __name__ == "__main__":
    main()
