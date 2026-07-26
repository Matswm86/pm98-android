#!/usr/bin/env python3
"""Re-prove the BRACKET layout's chrome/content split, so the build can bake it verbatim.

    python3 tools/re/verify_bracket_split.py

The bracket (4-tie knockout rounds) is the next layout to build in `KnockoutScreen`. Before
baking one panel strip per column set and repeating it four times, this checks the claim that
makes that legal: **outside six content rects plus the column set's own value boxes, every
witnessed bracket panel is byte-identical to every other one.**

Witnesses (tools/re/refs/knockout-2026-07-26/):
  European columns  02/03 euro QTR, 10 Cup Winner's QTR, 11 U.E.F.A. QTR   -> 16 panels
  domestic columns  08 F.A. Cup QTR, 12 Coca-Cola QTR                      -> 8 panels

It also re-checks the three facts the build depends on and that the older half of
`docs/re/knockout_views_re.md` gets wrong:

  * the flags are `app/art/flags/dbcard/<code>.png` at (83, T+7) / (385, T+7), 0 px;
  * the leg-1 score ink is (180,200,220) with an (160,180,200) blend, NOT white;
  * `app/art/screens/knockout/desktop.png` already covers every inter-panel gap.

It does NOT check the kits: the 47x59 blit is MINIESC plus the un-reversed outline pass and
cannot be reproduced yet (288 px of 1661, 173 of them on the silhouette edge). Those eight
rects are a declared bucket for the build's own parity gate.
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
REFS = ROOT / "tools/re/refs/knockout-2026-07-26"
FLAGS = ROOT / "app/art/flags/dbcard"
DESKTOP = ROOT / "app/art/screens/knockout/desktop.png"

TOPS = (113, 193, 273, 353)
PANEL_X = (20, 477)
# Content rects, panel-relative: (x0, dy0, x1, dy1), inclusive.
CONTENT = [
    (22, 2, 81, 69),        # left kit column (white outside the blit)
    (416, 2, 475, 69),      # right kit column
    (83, 7, 112, 26),       # left flag
    (385, 7, 414, 26),      # right flag
    (114, 7, 247, 26),      # home name bar
    (250, 7, 383, 26),      # away name bar
]
BOXES = {
    "euro": [(83, 48, 175, 61), (193, 48, 283, 61), (310, 48, 414, 61)],
    "dom": [(135, 48, 227, 61), (271, 48, 361, 61)],
}
FAMILIES = {
    "euro": ["02_euroleague_qtrfinals_UNPLAYED_1998-01.png",
             "03_euroleague_qtrfinals_LEG1_PLAYED_1998-03-14.png",
             "10_cwc_qtr_bracket_UNPLAYED_probe0116.png",
             "11_uefa_qtr_bracket_UNPLAYED_probe0116.png"],
    "dom": ["08_facup_qtrfinals_DOMESTIC_bracket_unplayed_1999-03-04.png",
            "12_cocacola_qtr_bracket_DOMESTIC_probe0116.png"],
}
GAPS = [(185, 192), (265, 272), (345, 352), (425, 432)]
# (frame, panel top, side, expected dbcard flag code) — read off the euro QTR frame.
FLAG_CELLS = [
    ("03_euroleague_qtrfinals_LEG1_PLAYED_1998-03-14.png", 113, 83, 2),    # Germany
    ("03_euroleague_qtrfinals_LEG1_PLAYED_1998-03-14.png", 113, 385, 30),  # England
    ("03_euroleague_qtrfinals_LEG1_PLAYED_1998-03-14.png", 193, 83, 26),   # Greece
    ("03_euroleague_qtrfinals_LEG1_PLAYED_1998-03-14.png", 273, 83, 22),   # Spain
]
SCORE_INK = {(180, 200, 220), (160, 180, 200)}
BOX_GROUND = (80, 100, 120)


def _load(p: Path) -> np.ndarray:
    return np.asarray(Image.open(p).convert("RGB"), dtype=int)[:480, :640]


def _mask(fam: str) -> np.ndarray:
    m = np.zeros((72, PANEL_X[1] - PANEL_X[0] + 1), dtype=bool)
    for x0, dy0, x1, dy1 in CONTENT + BOXES[fam]:
        m[dy0:dy1 + 1, x0 - PANEL_X[0]:x1 - PANEL_X[0] + 1] = True
    return m


def split() -> bool:
    ok = True
    for fam, frames in FAMILIES.items():
        m = _mask(fam)
        base = None
        n = 0
        worst = 0
        for name in frames:
            im = _load(REFS / name)
            for top in TOPS:
                p = im[top:top + 72, PANEL_X[0]:PANEL_X[1] + 1]
                n += 1
                if base is None:
                    base = p
                    continue
                d = int((np.any(base != p, axis=2) & ~m).sum())
                worst = max(worst, d)
                if d:
                    ok = False
                    print(f"   FAIL {fam} {name} top {top}: {d} static px differ")
        print(f"   {fam:5s}: {n} panels over {len(frames)} frames, worst static diff {worst}")
    return ok


def flags() -> bool:
    ok = True
    for name, top, x, code in FLAG_CELLS:
        f = FLAGS / f"{code}.png"
        if not f.exists():
            print(f"   FAIL flag {code} missing")
            ok = False
            continue
        a = _load(REFS / name)[top + 7:top + 27, x:x + 30]
        b = np.asarray(Image.open(f).convert("RGB"), dtype=int)
        d = int((np.abs(a - b).max(axis=2) > 0).sum())
        print(f"   flag {code:3d} at ({x}, T+7) in {name[:2]} top {top}: {d} px differ")
        ok = ok and d == 0
    return ok


def score_ink() -> bool:
    im = _load(REFS / "03_euroleague_qtrfinals_LEG1_PLAYED_1998-03-14.png")
    seen: set[tuple[int, int, int]] = set()
    for top in TOPS:
        seg = im[top + 48:top + 62, 83:176]
        m = np.any(seg != BOX_GROUND, axis=2)
        seen |= {tuple(int(v) for v in px) for px in seg[m]}
    extra = seen - SCORE_INK
    print(f"   leg-1 score ink over 4 panels: {sorted(seen)}")
    if extra:
        print(f"   FAIL unexpected ink {sorted(extra)}")
    if (255, 255, 255) in seen:
        print("   FAIL white ink present — the old doc's claim")
    return not extra


def desktop() -> bool:
    if not DESKTOP.exists():
        print(f"   FAIL {DESKTOP} missing")
        return False
    dk = _load(DESKTOP)
    ok = True
    for name in FAMILIES["euro"][:1] + FAMILIES["dom"][:1]:
        im = _load(REFS / name)
        for y0, y1 in GAPS:
            d = int(np.any(dk[y0:y1 + 1, 0:500] != im[y0:y1 + 1, 0:500], axis=2).sum())
            if d:
                print(f"   FAIL {name} gap y{y0}..{y1}: {d} px differ from desktop.png")
                ok = False
        print(f"   {name[:2]}: all {len(GAPS)} inter-panel gaps match desktop.png")
    return ok


def main() -> int:
    print("1. the chrome/content split")
    a = split()
    print("2. the flags blit exactly")
    b = flags()
    print("3. the leg-1 score ink")
    c = score_ink()
    print("4. desktop.png covers the gaps")
    d = desktop()
    good = a and b and c and d
    print("\nPASS" if good else "\nFAILURES ABOVE")
    return 0 if good else 1


if __name__ == "__main__":
    sys.exit(main())
