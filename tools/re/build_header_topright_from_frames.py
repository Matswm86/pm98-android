#!/usr/bin/env python3
"""Shared management-header top-right chrome from the original hub frame.

The PMChrome.draw_header top-right was procedural (grey bevel plaques) — the
user-visible "grey bar over the calendar". The original (binding frame
screenshots/original-walkthrough-2026-07-02/016_162419.png, the MANAGER MENU
hub; same band on every management screen, e.g. TRAINING 005_162348) shows:
  * a white spiral-bound CALENDAR SHEET (rings on top) overlapping the barra,
  * a lavender rounded PLAQUE to its right holding two GREEN BANDS
    ("Preseason" black on the top band / "Preparation" pale on the bottom
    band) and the football graphic at its right end.

Outputs (texts inpainted out so live values redraw):
  app/art/screens/header/cal_sheet.png     (445,6)  78x54
  app/art/screens/header/plaque_right.png  (529,4)  111x52
  app/data/header_chrome_samples.json      frame-sampled inks + band rects
"""

from __future__ import annotations

import json
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
FRAME = ROOT / "screenshots/original-walkthrough-2026-07-02/016_162419.png"
ART = ROOT / "app/art/screens/header"

SHEET = (445, 6, 78, 54)  # incl. rings row + right/bottom shadow edge
PLAQUE = (529, 4, 111, 52)
# text interiors to inpaint (abs coords), row-median (backgrounds are per-row flat)
SHEET_TXT = (449, 15, 518, 58)
BAND1_TXT = (541, 13, 610, 27)  # "Preseason" glyphs
BAND2_TXT = (536, 33, 615, 48)  # "Preparation" glyphs


def row_median_inpaint(
    arr: np.ndarray, x0: int, y0: int, x1: int, y1: int, ox: int, oy: int
) -> None:
    """Replace the region with each row's median colour sampled OUTSIDE glyphs.
    Glyph = pixel far from the row median; two passes for stability."""
    for y in range(y0 - oy, y1 - oy):
        row = arr[y, x0 - ox : x1 - ox]
        med = np.median(row, axis=0)
        d = np.abs(row - med).sum(axis=1)
        keep = row[d < 60]
        fill = np.median(keep, axis=0) if len(keep) else med
        mask = d >= 60
        row[mask] = fill.astype(row.dtype)


def sample(im: np.ndarray, x: int, y: int) -> list[int]:
    return [int(v) for v in im[y, x]]


def main() -> None:
    im = Image.open(FRAME).convert("RGB")
    arr = np.asarray(im).copy()
    ART.mkdir(parents=True, exist_ok=True)

    # ---- colour samples BEFORE inpainting (glyph inks) ----------------------
    a = arr.astype(int)

    def glyph_ink(x0, y0, x1, y1, pred):
        px = [(x, y) for y in range(y0, y1) for x in range(x0, x1) if pred(a[y, x])]
        if not px:
            raise SystemExit(f"no glyph pixels in ({x0},{y0})-({x1},{y1})")
        vals = np.array([a[y, x] for x, y in px])
        return [int(v) for v in np.median(vals, axis=0)]

    ink = {
        # sheet: "Monday" black, "4" red, "August" black, "1997" blue
        "sheet_ink": glyph_ink(449, 15, 518, 26, lambda p: p.sum() < 200),
        "sheet_day": glyph_ink(449, 24, 518, 40, lambda p: p[0] > 150 and p[1] < 90 and p[2] < 90),
        "sheet_year": glyph_ink(449, 47, 518, 58, lambda p: p[2] > 130 and p[2] - p[0] > 60),
        "band1_ink": glyph_ink(*BAND1_TXT, lambda p: p.sum() < 200),
        "band2_ink": glyph_ink(*BAND2_TXT, lambda p: p.sum() > 600),
    }

    # ---- inpaint the live texts out -----------------------------------------
    sx, sy, sw, sh = SHEET
    sheet = arr[sy : sy + sh, sx : sx + sw].copy()
    row_median_inpaint(sheet, *SHEET_TXT, sx, sy)
    # alpha: sheet body (x>=447,y>=14) opaque; ring rows keep only the dark ring
    # pixels; everything else (marble margins) transparent so the cut composes
    # cleanly on every management screen's own backdrop
    sh_a = np.dstack([sheet, np.full(sheet.shape[:2], 255, np.uint8)])
    for y in range(sh_a.shape[0]):
        for x in range(sh_a.shape[1]):
            ax, ay = x + sx, y + sy
            in_body = ax >= 447 and 14 <= ay <= 58
            is_ring = ay < 14 and int(sheet[y, x].astype(int).sum()) < 260
            if not (in_body or is_ring):
                sh_a[y, x, 3] = 0
    Image.fromarray(sh_a, "RGBA").save(ART / "cal_sheet.png")

    px_, py_, pw, ph = PLAQUE
    plaque = arr[py_ : py_ + ph, px_ : px_ + pw].copy()
    # bands are flat fills (frame-measured): band1 rows 15-29 (127,159,85) black
    # glyphs; band2 rows 33-47 (85,95,0) white glyphs. The football graphic
    # overlaps the bands' right end — find its left edge (first column whose
    # whole-plaque whiteish count exceeds a band-glyph's max height) and only
    # clean text pixels left of it.
    ap = plaque.astype(int)
    whiteish = (ap > 200).all(axis=2)
    fl = pw
    for x in range(600 - px_, pw):
        if whiteish[:, x].sum() > 18:
            fl = x
            break
    for (r0, r1), fill, pred in [
        ((15, 30), (127, 159, 85), lambda p: p.sum() < 200),
        ((33, 48), (85, 95, 0), lambda p: (p > 200).all()),
    ]:
        for y in range(r0 - py_, r1 - py_):
            for x in range(532 - px_, fl):
                if pred(ap[y, x]):
                    plaque[y, x] = fill
    # alpha: transparent marble in the rounded corners / outside the plaque body
    pl_a = np.dstack([plaque, np.full(plaque.shape[:2], 255, np.uint8)])
    lav = (np.abs(ap[:, :, 0] - ap[:, :, 1]) < 30) & (ap[:, :, 2] >= ap[:, :, 1])
    for y in range(ph):
        row = np.where(lav[y] | (ap[y].sum(axis=1) < 260) | whiteish[y])[0]
        if len(row) == 0:
            pl_a[y, :, 3] = 0
            continue
        pl_a[y, : row[0], 3] = 0
        pl_a[y, row[-1] + 1 :, 3] = 0
    Image.fromarray(pl_a, "RGBA").save(ART / "plaque_right.png")
    print(f"football left edge at abs x={fl + px_}")

    meta = {
        "frame": FRAME.name,
        "sheet_rect": list(SHEET),
        "plaque_rect": list(PLAQUE),
        "band1_txt": list(BAND1_TXT),
        "band2_txt": list(BAND2_TXT),
        "football_left": int(fl + px_),
        **ink,
    }
    out = ROOT / "app/data/header_chrome_samples.json"
    out.write_text(json.dumps(meta, indent=1) + "\n")
    print(json.dumps(meta, indent=1))
    print(
        f"wrote {ART.relative_to(ROOT)}/cal_sheet.png + plaque_right.png + {out.relative_to(ROOT)}"
    )


if __name__ == "__main__":
    main()
