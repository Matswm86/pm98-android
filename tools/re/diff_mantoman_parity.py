#!/usr/bin/env python3
"""Pixel-diff MAN-TO-MAN MARKINGS against the real frames.

Usage:  python3 tools/re/diff_mantoman_parity.py <shot_dir>

Produce the shots first:

    DISPLAY=:1 PM98_SHOT_DIR=<dir> ~/godot462 --rendering-driver opengl3 \\
        --resolution 640x480 --path app --script res://tests/shot_mantoman.gd

Three cases, three real frames, two careers:

    bolton    parity-run 66_mantoman_match.png     Bolton W. vs Aston Villa, idle
    manutd    walkthrough 058_162622.png           Manchester Utd. vs F.C. Barcelona, idle
    assigned  walkthrough 064_162633.png           after two commits, one row selected

The compared band is the BODY (y62..479) — the barra above it is the shared
match header and has its own gate (`build_match_header_from_frames.py`).

TWO DECLARED BUCKETS, both named and bounded:

  plate   the vertical club plate's name box (x243..262, y338..445). The original
          draws that string with a rotated GDI font; this port draws the same
          BMFont through a rotated canvas transform — a different rasteriser.

  shadow  the three rects the original blits through `FUN_004b7f60` (the shadowed
          bitmap blit): the two 22x109 marking-line markers and the 48x64 opponent
          kit. That pass is the SAME un-ported one the knockout gates already
          bucket. What this session added to it (docs/re/mantoman_screen_re.md §7):
          `FUN_004b7f60` -> `FUN_005cbea0(0x10, 0x21, id, rect, bmp, 0,0,0, 0x100)`
          -> `FUN_005d66f0` (silhouette) / `FUN_005d6590` (tint) / `FUN_005d5220`
          (composite), and the effect measured on these frames is a PALETTE-DARKENING
          stamp offset right of the silhouette, applied once per overlapping stamp
          (index 85 -> 116 -> 115 -> 114; 255 -> 7 -> 247 -> 134), which is NOT the
          dilation model measured and rejected on 2026-07-28.

Both buckets are reported separately with their own pixel counts; neither may
touch anything outside its own rect.
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
PARITY = ROOT / "screenshots" / "parity-run-2026-07-16" / "orig"
WALK = ROOT / "screenshots" / "original-walkthrough-2026-07-02"

BODY_Y0 = 62
PLATE = (243, 338, 263, 446)  # x0, y0, x1, y1 (exclusive)
# the three FUN_004b7f60 (shadowed-blit) rects, at their witnessed positions
SHADOW = [
    (367, 306, 389, 415),  # D marker (22x109)
    (423, 323, 445, 432),  # M marker (22x109)
    (229, 283, 277, 347),  # opponent kit (48x64)
]

# The pointer's own rollover state, per case. The original repaints whatever the
# mouse is over (an opponent row in 059/061/063, the RETURN button in 064-067); a
# touch screen has no hover, so this port never draws it. Bounded to that widget.
ROLLOVER = {"assigned": (516, 404, 636, 437)}  # RETURN, where 064 parks the pointer

CASES = [
    ("bolton", PARITY / "66_mantoman_match.png"),
    ("manutd", WALK / "058_162622.png"),
    # 064 rather than 063: the same two committed pairs and the same selected row,
    # but with the pointer parked on RETURN instead of hovering an opponent row, so
    # no 192x16 row rollover is in the way (see the RE doc §5).
    ("assigned", WALK / "064_162633.png"),
]


def load(path: Path) -> np.ndarray:
    a = np.asarray(Image.open(path).convert("RGB"))
    if a.shape[0] != 480 or a.shape[1] not in (640, 641):
        raise SystemExit(f"{path}: unexpected size {a.shape}")
    return a[:, :640].astype(int)


def main() -> int:
    shot_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("/tmp")
    ok = True
    for key, ref_path in CASES:
        shot = shot_dir / f"mantoman_{key}.png"
        if not shot.exists():
            print(f"BAD  {key}: {shot} is missing")
            ok = False
            continue
        got = load(shot)
        want = load(ref_path)
        d = (got != want).any(axis=2)
        d[:BODY_Y0, :] = False
        plate = np.zeros_like(d)
        plate[PLATE[1] : PLATE[3], PLATE[0] : PLATE[2]] = True
        shadow = np.zeros_like(d)
        for x0, y0, x1, y1 in SHADOW:
            shadow[y0:y1, x0:x1] = True
        roll = np.zeros_like(d)
        if key in ROLLOVER:
            rx0, ry0, rx1, ry1 = ROLLOVER[key]
            roll[ry0:ry1, rx0:rx1] = True
        buckets = plate | shadow | roll
        body = int((d & ~buckets).sum())
        tag = "OK " if body == 0 else "BAD"
        print(
            f"{tag} {key}: {body} differing px in the body "
            f"(+{int((d & plate).sum())} plate, +{int((d & shadow).sum())} shadow-pass"
            f"{f', +{int((d & roll).sum())} rollover' if key in ROLLOVER else ''}) "
            f"vs {ref_path.name}"
        )
        if body:
            ys, xs = np.nonzero(d & ~buckets)
            print(f"     bbox x {xs.min()}..{xs.max()}  y {ys.min()}..{ys.max()}")
            ok = False
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
