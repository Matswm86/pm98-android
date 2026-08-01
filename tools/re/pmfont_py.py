#!/usr/bin/env python3
"""Render a PM98 BMFont string to an ink MASK, in Python.

The port renders text through `PMFont` inside Godot. Identifying which FACE drew a cell in
a captured frame does not need Godot: `app/data/font_metrics.json` carries every glyph's
page rect and advance and `app/art/fonts/<face>.png` is the page, so the same string can be
laid out here and XOR'd against the witness's ink mask. That is what
`tools/re/probe_text_face.py` does with rendered shots; this module is the same measurement
without a running engine, which is what the GROUP DRAW build used.

A glyph entry is `[x, y, w, h, xoff, yoff, advance]` on the face's page. A page pixel is INK
where its alpha is non-zero (the pages are white-on-transparent).

    from tools.re.pmfont_py import text_mask, advance
    m = text_mask("proman10", "Real Madrid C.F.")   # 2-D bool array, tight-bounded
"""

from __future__ import annotations

import json
from functools import cache
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
METRICS = ROOT / "app" / "data" / "font_metrics.json"
PAGES = ROOT / "app" / "art" / "fonts"


@cache
def _face(name: str) -> tuple[dict, np.ndarray]:
    m = json.loads(METRICS.read_text())[name]
    page = np.array(Image.open(PAGES / f"{name}.png").convert("RGBA"))
    return m, page[..., 3] > 0


def advance(face: str, s: str) -> int:
    m, _ = _face(face)
    return sum(m["chars"][str(ord(c))][6] for c in s if str(ord(c)) in m["chars"])


def text_mask(face: str, s: str, tight: bool = True) -> np.ndarray:
    """The string's ink as a bool array. Origin is the pen (x = 0, y = pen top)."""
    m, ink = _face(face)
    w = max(advance(face, s), 1)
    h = int(m.get("base", 16)) + 8
    out = np.zeros((h + 8, w + 8), dtype=bool)
    pen = 0
    for c in s:
        g = m["chars"].get(str(ord(c)))
        if g is None:
            continue
        gx, gy, gw, gh, xo, yo, adv = g
        if gw > 0 and gh > 0:
            sub = ink[gy : gy + gh, gx : gx + gw]
            y0, x0 = yo, pen + xo
            out[y0 : y0 + gh, x0 : x0 + gw] |= sub
        pen += adv
    if not tight or not out.any():
        return out
    ys, xs = np.nonzero(out.any(1))[0], np.nonzero(out.any(0))[0]
    return out[ys.min() : ys.max() + 1, xs.min() : xs.max() + 1]


def best_face(witness: np.ndarray, s: str, faces: list[str] | None = None) -> list[tuple]:
    """Score every face against a witness ink mask. Returns (mismatch, face, shape)."""
    m = json.loads(METRICS.read_text())
    out = []
    for f in faces or sorted(m):
        r = text_mask(f, s)
        if r.shape != witness.shape:
            out.append(
                (
                    10**6
                    + abs(r.shape[0] - witness.shape[0]) * 1000
                    + abs(r.shape[1] - witness.shape[1]),
                    f,
                    r.shape,
                )
            )
            continue
        out.append((int((r ^ witness).sum()), f, r.shape))
    return sorted(out)
