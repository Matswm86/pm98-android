#!/usr/bin/env python3
"""Solve a text cell on a real MANAGER.EXE frame: WHICH font, and WHERE the pen sits.

Every screen in this repo redraws dynamic text over baked chrome, and getting that text
to land on the original's own pixels means knowing three things exactly: the BMFont atlas
the game used, the pen's x origin, and the pen's top row. Guessing any of them costs a
render-diff round trip; this reads them straight off the frame.

Method: render the expected string from EVERY atlas the game ships (`app/data/
font_metrics.json` + `app/art/fonts/<key>.png`), crop each render to its ink, crop the
frame's cell to the pixels of the given ink colour, and keep only the atlas whose bitmap
is IDENTICAL. A hit is therefore proof, not a best fit — and no hit means the cell is not
that string, not that colour, or the crop window caught a border.

Usage:
    python3 tools/re/probe_text_anchor.py <frame.png> <y0> <y1> <x0> <x1> <r,g,b> <text>

Prints, per matching atlas: pen_x, pen_top, pen_end (x after the last advance) and the
ink bbox. Right-aligned cells anchor on pen_end, centred ones on `2*pen_x + advance`.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
METRICS = ROOT / "app" / "data" / "font_metrics.json"
FONT_DIR = ROOT / "app" / "art" / "fonts"


def _atlases() -> dict:
    return json.loads(METRICS.read_text())


def render(metrics: dict, pages: dict, key: str, s: str):
    """Ink bitmap of `s` in atlas `key`, plus (ink_left - pen_x, ink_top - pen_top, advance)."""
    ch = metrics[key]["chars"]
    try:
        width = sum(ch[str(ord(c))][6] for c in s) + 8
    except KeyError:
        return None            # the atlas has no glyph for one of the characters
    page = pages[key]
    buf = np.zeros((metrics[key]["line_height"] + 8, width), bool)
    pen = 4
    for c in s:
        x, y, w, h, ox, oy, adv = ch[str(ord(c))]
        if w > 0:
            sub = page[y : y + h, x : x + w]
            buf[4 + oy : 4 + oy + h, pen + ox : pen + ox + w] |= (sub[..., 3] > 0) & (
                sub[..., :3].sum(axis=2) > 0
            )
        pen += adv
    ys, xs = np.nonzero(buf)
    if len(ys) == 0:
        return None
    return (
        buf[ys.min() : ys.max() + 1, xs.min() : xs.max() + 1],
        int(xs.min()) - 4,
        int(ys.min()) - 4,
        pen - 4,
    )


def probe(frame: Path, y0: int, y1: int, x0: int, x1: int, ink, text: str) -> list:
    metrics = _atlases()
    pages = {
        k: np.array(Image.open(FONT_DIR / f"{k}.png").convert("RGBA"))
        for k in metrics
        if (FONT_DIR / f"{k}.png").exists()
    }
    a = np.array(Image.open(frame).convert("RGB"))
    cell = (a[y0:y1, x0:x1] == np.array(ink)).all(axis=2)
    if not cell.any():
        return []
    ys, xs = np.nonzero(cell)
    ref = cell[ys.min() : ys.max() + 1, xs.min() : xs.max() + 1]
    bb = (x0 + int(xs.min()), x0 + int(xs.max()), y0 + int(ys.min()), y0 + int(ys.max()))
    hits = []
    for key in pages:
        r = render(metrics, pages, key, text)
        if r and r[0].shape == ref.shape and not (r[0] != ref).any():
            hits.append(
                {
                    "font": key,
                    "pen_x": bb[0] - r[1],
                    "pen_top": bb[2] - r[2],
                    "pen_end": bb[0] - r[1] + r[3],
                    "advance": r[3],
                    "ink_bbox": bb,
                }
            )
    return hits


def main() -> int:
    if len(sys.argv) != 8:
        print(__doc__, file=sys.stderr)
        return 2
    frame = Path(sys.argv[1])
    y0, y1, x0, x1 = (int(v) for v in sys.argv[2:6])
    ink = tuple(int(v) for v in sys.argv[6].split(","))
    text = sys.argv[7]
    hits = probe(frame, y0, y1, x0, x1, ink, text)
    if not hits:
        print("NO MATCH — wrong string, wrong ink colour, or the window caught a border")
        return 1
    for h in hits:
        print(
            f"{h['font']:9s} pen_x={h['pen_x']:4d} pen_top={h['pen_top']:4d} "
            f"pen_end={h['pen_end']:4d} advance={h['advance']:3d} ink={h['ink_bbox']}"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
