#!/usr/bin/env python3
"""Match a text cell in a captured frame to the FACE and SIZE that drew it, by shape.

    DISPLAY=:1 PM98_SHOT_DIR=/tmp/faces PM98_FACE_TEXT='£5,000' PM98_FACE_INK=150,0,0 \\
        ~/godot462 --rendering-driver opengl3 --path app \\
        --script res://tests/shot_face_probe.gd
    python3 tools/re/probe_text_face.py /tmp/faces \\
        tools/re/refs/b9-players-found-2026-08-01/02_players_found_first.png \\
        509 118 578 134 150,0,0

Width is not enough to pick a face and eyeballing is not evidence. This crops the witness
cell's INK MASK (every pixel of the given colour, tight-bounded), crops each rendered
candidate the same way, and XORs the two masks. A face/size pair that scores 0 drew the
cell; anything else is a different face, and a candidate whose bounding box is the wrong
SHAPE is reported as such rather than scored.

Result that made this exist (YOUTH TEAM, the PLAYERS FOUND money column, "£5,000" at
x526..558 / y122..131, 94 ink px): `euro8 @11` scores **0** and is the only pair that does.
The bold list face the port had been using renders the same string 10 px wider.
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image


def ink_mask(a: np.ndarray, colour: tuple[int, int, int]) -> np.ndarray | None:
    m = (a == np.array(colour)).all(axis=2)
    if not m.any():
        return None
    ys, xs = np.nonzero(m.any(1))[0], np.nonzero(m.any(0))[0]
    return m[ys.min():ys.max() + 1, xs.min():xs.max() + 1]


def main() -> int:
    if len(sys.argv) < 8:
        print(__doc__)
        return 2
    faces = Path(sys.argv[1])
    frame = Path(sys.argv[2])
    x0, y0, x1, y1 = (int(v) for v in sys.argv[3:7])
    colour = tuple(int(v) for v in sys.argv[7].split(","))

    want = ink_mask(np.asarray(Image.open(frame).convert("RGB")).astype(int)[y0:y1, x0:x1],
                    colour)
    if want is None:
        print(f"FAIL: no {colour} ink in {frame.name}[{x0}:{x1}, {y0}:{y1}]")
        return 1
    print(f"witness ink mask {want.shape[1]}x{want.shape[0]}, {int(want.sum())} px")

    rows = []
    for f in sorted(faces.glob("face_*.png")):
        got = ink_mask(np.asarray(Image.open(f).convert("RGB")).astype(int), colour)
        if got is None:
            continue
        if got.shape != want.shape:
            rows.append((None, f.name, f"{got.shape[1]}x{got.shape[0]}", int(got.sum())))
            continue
        rows.append((int((got ^ want).sum()), f.name,
                     f"{got.shape[1]}x{got.shape[0]}", int(got.sum())))

    scored = sorted((r for r in rows if r[0] is not None), key=lambda r: r[0])
    wrong_shape = [r for r in rows if r[0] is None]
    for xor, name, shape, n in scored:
        print(f"  {name:22s} xor {xor:5d}  {shape}  {n} px" + ("   <-- MATCH" if not xor else ""))
    print(f"  ({len(wrong_shape)} candidates skipped: bounding box the wrong shape)")
    exact = [r for r in scored if r[0] == 0]
    if len(exact) == 1:
        print(f"\n{exact[0][1]} is the ONLY exact match.")
        return 0
    print(f"\n{len(exact)} exact matches — not decisive.")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
