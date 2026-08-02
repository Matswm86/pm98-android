#!/usr/bin/env python3
"""Bake the SEMIFINAL cup-draw chrome (`app/art/screens/cupdraw/chrome_semis.png`).

The panel's FOURTH form, witnessed s91 (`tools/re/refs/cupdraw-semifinals-2026-08-02/`):
a 2-tie round paints no MATCHES list and no 16-band grid — the right panel is the
stadium backdrop with a black `SEMIFINAL 1` / `SEMIFINAL 2` plate over each tie's own
GRID-form row. Full derivation: docs/re/cupdraw_screen_re.md §"THE SEMIFINAL FORM".

Construction, all measured on both frames (they agree outside the dynamic areas):
  * base = the LIST chrome (`chrome.png`) — the left bezel, MATCHES plate and both
    buttons are identical on the semifinal frames (FINISH 0 px; CONTINUE is the
    animated ball, excluded by the parity gate as everywhere else);
  * the right panel x332..623 y51..419 is copied from the Coca-Cola frame — backdrop,
    both plates WITH their text (the two strings never change: they are the EXE's own
    plates at 0x653ecc/0x653ec0, drawn only when the round has exactly two ties), the
    tie rows' black borders and column separators;
  * the DYNAMIC areas — the four kit cells and four name cells — are cleared to their
    flat widget tones (140,160,180) / (160,180,200), which is what an un-landed club
    shows (the GRID form paints its bands before any club lands, p0125/p0445).

The bake is cross-checked: built from the F.A. Cup frame instead, the result must be
byte-identical (the two frames differ only inside the cleared areas + the button zone).
"""

from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
REFS = ROOT / "tools" / "re" / "refs" / "cupdraw-semifinals-2026-08-02"
OUT = ROOT / "app" / "art" / "screens" / "cupdraw" / "chrome_semis.png"

# the replaced right panel
PANEL = (332, 51, 624, 420)  # x0, y0, x1(excl), y1(excl)
# The ROUND plate, WITH its text: a 2-tie round's plate always reads `SEMIFINALS`, and
# the EXE's plate text carries its own dithered drop shadow — drawing plain yellow over
# a cleared plate leaves the shadow behind (37 px). Baked from the frame like the two
# tie plates; the two frames are pixel-identical here.
ROUND_PLATE = (94, 234, 227, 252)
# tie row interiors (y0..y1 incl) and the four cell column spans (x0..x1 incl)
ROWS_Y = [(155, 187), (307, 339)]
KIT_CELLS = [(334, 359), (596, 621)]
NAME_CELLS = [(361, 476), (479, 594)]
C_KIT_BG = (140, 160, 180)
C_ROW_BG = (160, 180, 200)


def load(p: Path) -> np.ndarray:
    return np.asarray(Image.open(p).convert("RGB"))[:480, :640].copy()


def bake(frame: np.ndarray, chrome: np.ndarray) -> np.ndarray:
    out = chrome.copy()
    x0, y0, x1, y1 = PANEL
    out[y0:y1, x0:x1] = frame[y0:y1, x0:x1]
    x0, y0, x1, y1 = ROUND_PLATE
    out[y0:y1, x0:x1] = frame[y0:y1, x0:x1]
    for ry0, ry1 in ROWS_Y:
        for cx0, cx1 in KIT_CELLS:
            out[ry0 : ry1 + 1, cx0 : cx1 + 1] = C_KIT_BG
        for cx0, cx1 in NAME_CELLS:
            out[ry0 : ry1 + 1, cx0 : cx1 + 1] = C_ROW_BG
    return out


def main() -> None:
    chrome = load(ROOT / "app" / "art" / "screens" / "cupdraw" / "chrome.png")
    f1 = load(REFS / "cocacola_semifinals_2leg.png")
    f2 = load(REFS / "facup_semifinals_match_replay.png")
    a = bake(f1, chrome)
    b = bake(f2, chrome)
    d = (a != b).any(axis=2)
    if d.any():
        ys, xs = np.where(d)
        raise SystemExit(
            f"cross-check FAILED: {d.sum()} px differ between the two frames' bakes "
            f"(x {xs.min()}..{xs.max()} y {ys.min()}..{ys.max()})"
        )
    Image.fromarray(a).save(OUT)
    print(f"wrote {OUT.relative_to(ROOT)} — cross-check vs the F.A. Cup frame: 0 px")


if __name__ == "__main__":
    main()
