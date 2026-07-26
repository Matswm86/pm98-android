#!/usr/bin/env python3
"""Parity gate for the SCOUT screen's bottom bar — the original's rollover readout, and
the one port-only label this screen carries.

    DISPLAY=:1 PM98_SHOT_DIR=<dir> ~/godot462 --rendering-driver opengl3 \
        --path app -s tests/shot_scout_verify.gd
    PM98_SHOT_DIR=<dir> python3 tools/re/diff_scout_bar_parity.py

Two sessions recorded that bar as inert furniture whose behaviour was un-witnessed, and the
port bound its own overlay-opening tap to it on that basis. It is NOT inert: three frames in
`screenshots/refrun-manutd-1997-98/novel/` show the original using it as a per-row ROLLOVER
readout — the held row's ridi kit, full name and club. This gate checks both halves of what
the port now does there.

A. THE ORIGINAL'S READOUT, render-diffed. `shot_scout_rollover.png` holds list row 2 with
   Joseba Etxeberria of Athletic Club, exactly the witness p0279 state, and the whole bar
   body (x11..500, y438..463) plus the held row's 2 px black frame must be 0 px against that
   frame. The witness list is a different search, so the row INTERIORS are not comparable
   and are not compared; the frame ring and the bar are.

B. THE PORT-ONLY LABEL, bounded the way `diff_options_parity.py` bounds the THREE UP FRONT
   row on the OPTIONS modal:
     1. it lives inside the two recessed segments and nowhere else;
     2. the segments overlap none of the original's own controls on this screen;
     3. in EVERY witness frame that carries this bar, those segments hold either the
        original's own readout or nothing at all — so the label never covers a pixel the
        original draws. It is drawn only in the empty state and yields on the first press.

Run `diff_scout_offers_parity.py` alongside this: it proves the other six witnessed states
are still 0 px with the label declared as a single bucket.
"""

from __future__ import annotations

import os
import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SH = Path(os.environ.get("PM98_SHOT_DIR", "/tmp/pm98shots"))
NOVEL = ROOT / "screenshots" / "refrun-manutd-1997-98" / "novel"
GOAL = ROOT / "screenshots" / "wine-captures-2026-07-18-goalscorers"

# Mirrors of the ScoutScreen constants (design space, 640x480).
BAR = (11, 438, 490, 26)            # the whole bar body, x,y,w,h
SEG_A = (40, 445, 246, 12)
SEG_B = (287, 445, 163, 12)
ROW_Y0, ROW_PITCH, ROW_X0, ROW_X1 = 297, 16, 33, 473
# The original's own controls on this screen (scout_chrome.json geometry).
CONTROLS = {
    "LED_POS": (114, 113, 22, 13), "LED_AGE": (17, 158, 22, 13),
    "LED_ROLE": (114, 158, 22, 13), "LED_QUALITY": (17, 204, 22, 13),
    "LED_PRICE": (114, 204, 22, 13),
    "LED_PREM": (284, 140, 22, 13), "LED_DIV1": (367, 140, 22, 13),
    "LED_DIV2": (450, 140, 22, 13), "LED_DIV3": (533, 140, 22, 13),
    "LED_EU": (284, 167, 22, 13), "LED_NONEU": (284, 194, 22, 13),
    "LED_NOTEAM": (284, 221, 22, 13),
    "DROP_POS": (131, 131, 125, 16), "DROP_ROLE": (131, 176, 125, 16),
    "SPIN_AGE": (35, 176, 50, 16), "SPIN_QUALITY": (35, 222, 50, 16),
    "SPIN_PRICE": (131, 222, 125, 16),
    "BTN_SEARCH": (518, 211, 100, 26), "BTN_RETURN": (517, 437, 110, 28),
    "LIST": (33, 297, 441, 128), "HEADERS": (53, 286, 418, 7),
}
# Every committed frame of this screen. The three `novel/` ones carry the readout; the six
# goalscorers ones are the parity witnesses and carry it empty.
WITNESSES = [
    (NOVEL / "p0241_UNKNOWN.png", "Milan"),
    (NOVEL / "p0279_UNKNOWN.png", "Athletic Club"),
    (NOVEL / "p0283_UNKNOWN.png", "Lazio"),
    (NOVEL / "p0245_UNKNOWN.png", ""),
    (GOAL / "43_scout.png", ""),
    (GOAL / "61_scout_with_scout.png", ""),
    (GOAL / "63_premier_checked.png", ""),
    (GOAL / "67_pos_enabled.png", ""),
    (GOAL / "68_results3.png", ""),
    (GOAL / "81_scout_found2.png", ""),
]
GROUND = (220, 220, 220)            # the segments' own empty interior


def _load(p: Path) -> np.ndarray:
    return np.asarray(Image.open(p).convert("RGB"), dtype=int)[:480, :640]


def _overlaps(a, b) -> bool:
    return (a[0] < b[0] + b[2] and b[0] < a[0] + a[2]
            and a[1] < b[1] + b[3] and b[1] < a[1] + a[3])


def _ring(top: int) -> np.ndarray:
    """The held row's 2 px frame: x32..474, y (top-1)..(top+14) — border only."""
    m = np.zeros((480, 640), dtype=bool)
    x0, x1 = ROW_X0 - 1, ROW_X1 + 2
    m[top - 1:top + 1, x0:x1] = True
    m[top + 13:top + 15, x0:x1] = True
    m[top + 1:top + 13, x0:x0 + 2] = True
    m[top + 1:top + 13, x1 - 2:x1] = True
    return m


ROLLOVERS = [
    ("shot_scout_rollover.png", "p0279_UNKNOWN.png", 1, "Etxeberria / Athletic Club"),
    ("shot_scout_rollover_milan.png", "p0241_UNKNOWN.png", 1, "Kluivert / Milan"),
    ("shot_scout_rollover_lazio.png", "p0283_UNKNOWN.png", 3, "Nesta / Lazio"),
]


def part_a() -> bool:
    print("A. the original's readout, render-diffed against all three witnesses")
    ok = True
    bx, by, bw, bh = BAR
    for shot_name, wit_name, row, tag in ROLLOVERS:
        shot = SH / shot_name
        if not shot.exists():
            print(f"   FAIL: {shot} missing — render shot_scout_verify.gd first")
            ok = False
            continue
        a, b = _load(shot), _load(NOVEL / wit_name)
        d = np.any(a != b, axis=2)
        bar = int(d[by:by + bh, bx:bx + bw].sum())
        ring = int((d & _ring(ROW_Y0 + row * ROW_PITCH)).sum())
        print(f"   {wit_name} ({tag}, row {row + 1} held)")
        print(f"      bar body {BAR} : {bar} px differ")
        print(f"      the held row's frame        : {ring} px differ")
        if bar:
            ys, xs = np.where(d[by:by + bh, bx:bx + bw])
            print(f"      bar bbox x{bx + xs.min()}..{bx + xs.max()} "
                  f"y{by + ys.min()}..{by + ys.max()}")
            ov = b.copy()
            ov[d] = (255, 0, 255)
            Image.fromarray(ov.astype(np.uint8)).save(SH / f"diff_{shot_name}")
        ok = ok and bar == 0 and ring == 0
    return ok


def part_b() -> bool:
    ok = True
    print("\nB. the port-only label, bounded")
    for name, r in CONTROLS.items():
        if _overlaps(r, SEG_A) or _overlaps(r, SEG_B):
            print(f"   FAIL: a bar segment overlaps {name} {r}")
            ok = False
    if ok:
        print(f"   the two segments {SEG_A} + {SEG_B} overlap none of the "
              f"{len(CONTROLS)} original controls")
    for p, club in WITNESSES:
        if not p.exists():
            print(f"   FAIL: witness {p} missing")
            ok = False
            continue
        im = _load(p)
        cells = []
        for tag, (x, y, w, h) in (("A", SEG_A), ("B", SEG_B)):
            seg = im[y:y + h, x:x + w]
            ink = int(np.any(seg != GROUND, axis=2).sum())
            cells.append(f"{tag}={'empty' if ink == 0 else str(ink) + 'px ink'}")
        used = club != ""
        inked = "empty" not in cells[0] or "empty" not in cells[1]
        state = "READOUT" if used else "blank"
        if inked != used:
            print(f"   FAIL: {p.name} is recorded as {state} but reads {', '.join(cells)}")
            ok = False
        else:
            print(f"   {p.name:26s} {state:8s} {', '.join(cells)}")
    print("   -> every witness holds either the original's own readout or nothing, so the "
          "label\n      (drawn only in the blank state) covers no pixel the original draws")
    return ok


def main() -> int:
    a = part_a()
    b = part_b()
    print("\nPASS" if a and b else "\nFAILURES ABOVE")
    return 0 if a and b else 1


if __name__ == "__main__":
    sys.exit(main())
