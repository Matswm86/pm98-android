#!/usr/bin/env python3
"""Test candidate models for the un-reversed 1-px KIT RIM, and print what each scores.

The rim is the last visual residual on the kit-bearing screens: the EURO GROUP gate reads
99 / 107 / 132 / 110 / 103 / 117 px and the fourteen knockout cases 14 px, and all of it is
this. s78 proved empirically and s83 proved from the call graph that it is NOT the
`FUN_004b7f60` shadow pass. What it IS has stayed unlocated, and the point of this probe is
that the models get KILLED by measurement instead of being left untried.

Run it against a rendered set of EURO GROUP parity shots:

    DISPLAY=:1 PM98_SHOT_DIR=<dir> ~/godot462 --rendering-driver opengl3 --path app \\
        --script res://tests/shot_euroleague_parity.gd
    python3 tools/re/probe_kit_rim_models.py <dir>

## What is established (2026-08-01)

* **The residual is ON the sprite, not beside it.** Over the six frames, **415 of the 449
  px are inside** the exported NANOESC sprite's own opaque mask (group A alone: 60 of 66).
  So it is not a drop shadow, an outline, or a halo: it recolours pixels the sprite covers.

* **It comes out of the shadow blit's own quantiser.** The rim colours are palette entries
  that appear as the LUT's **dither PARTNERS** for a shared RGB565 cell -- e.g. palette 13
  `(59,85,130)` and palette 10 `(42,63,170)` are `table0[c]` / `table1[c]` for 27 cells,
  and both occur in the rim of the same sprite at different screen parities. So whatever
  draws the rim writes 24-bit colour and re-quantises it through `DAT_00675398`, the same
  path `FUN_005d5220` uses -- it is not a palette error, a wrong kit bank, or an export bug.

## What is KILLED

Every model below is scored per residual pixel as "does SOME weight w reproduce the
original colour, given the port's own colour, the destination chrome, and the absolute
screen parity". A model that cannot even be fitted per-pixel with a free weight is dead.

| model | score |
|---|---|
| sprite blended toward the DESTINATION chrome (an edge alpha) | 179 / 449 |
| sprite blended toward BLACK (the drop-shadow direction)      | 264 / 449 |
| sprite blended toward WHITE (a lightening pass)              |  58 / 449 |
| sprite blended toward one of its own 8 neighbours (a smear)  | 396 / 449 |

The first three are killed outright. The fourth is NOT evidence and is printed only so it
is not mistaken for a result: "any of eight neighbours at any of 65 weights" is a large
enough hypothesis space that 88 % is what noise looks like, and the exact-neighbour test
next to it (49 / 449) is the honest version of the same idea.

So the pass stays UNLOCATED, and the position-constant bakes stay while the
club-dependent remainder stays a declared bucket.
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
REFS = ROOT / "tools" / "re" / "refs" / "euro-competitions-2026-07-25"
CHROME = ROOT / "app" / "art" / "screens" / "euroleague" / "chrome.png"
LUT = ROOT / "app" / "data" / "shadow_lut.bin"
FRAMES = {
    "A": "10_euroleague_group_A.png", "B": "11_euroleague_group_B.png",
    "C": "12_euroleague_group_C.png", "D": "13_euroleague_group_D.png",
    "E": "14_euroleague_group_E.png", "F": "15_euroleague_group_F.png",
}
LEADER = (75, 178, 24, 32)          # the group leader's NANOESC kit cell


def _lut() -> tuple[np.ndarray, list[np.ndarray]]:
    b = LUT.read_bytes()
    pal = np.frombuffer(b[:768], dtype=np.uint8).reshape(256, 3).astype(int)
    t0 = np.frombuffer(b[768:768 + 65536], dtype=np.uint8).astype(int)
    t1 = np.frombuffer(b[768 + 65536:768 + 131072], dtype=np.uint8).astype(int)
    return pal, [t0, t1]


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    shots = Path(sys.argv[1])
    pal, tab = _lut()

    def quant(rgb, parity: int) -> int:
        r, g, b = (int(max(0, min(255, round(v)))) for v in rgb)
        return tab[parity][((r >> 3) << 11) | ((g >> 2) << 5) | (b >> 3)]

    chrome = np.asarray(Image.open(CHROME).convert("RGB")).astype(int)[:480, :640]
    kx, ky, kw, kh = LEADER
    models = {"toward-chrome": 0, "toward-black": 0, "toward-white": 0,
              "neighbour-smear": 0, "neighbour-exact": 0}
    total = on_sprite = 0
    kits = ROOT / "app" / "art" / "kits" / "nano"

    for letter, name in FRAMES.items():
        sp = shots / f"euro_group_{letter}.png"
        fp = REFS / name
        if not sp.exists() or not fp.exists():
            print(f"[MISS] {sp.name} / {fp.name}")
            return 2
        shot = np.asarray(Image.open(sp).convert("RGB")).astype(int)[:480, :640]
        frame = np.asarray(Image.open(fp).convert("RGB")).astype(int)[:480, :640]
        diff = (np.abs(shot - frame).max(axis=2) > 0)[ky:ky + kh, kx:kx + kw]

        # which NANOESC sprite is in this cell -- matched, not assumed
        cell = shot[ky:ky + kh, kx:kx + kw]
        mask = None
        for f in sorted(kits.glob("*.png")):
            a = np.asarray(Image.open(f).convert("RGBA")).astype(int)[:kh, :kw]
            op = a[..., 3] > 0
            if not ((np.abs(a[..., :3] - cell).max(2) > 0) & op).sum():
                mask = op
                break

        for y, x in zip(*np.nonzero(diff)):
            total += 1
            if mask is not None and mask[y, x]:
                on_sprite += 1
            src = shot[ky + y, kx + x]
            want = tuple(frame[ky + y, kx + x])
            par = (kx + x + ky + y) & 1
            for label, target in (("toward-chrome", chrome[ky + y, kx + x]),
                                  ("toward-black", np.zeros(3, int)),
                                  ("toward-white", np.full(3, 255))):
                for i in range(0, 257, 2):
                    if tuple(pal[quant(src * (1 - i / 256) + target * (i / 256), par)]) == want:
                        models[label] += 1
                        break
            hit = exact = False
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    if dx == dy == 0:
                        continue
                    nb = shot[ky + y + dy, kx + x + dx]
                    if tuple(nb) == want:
                        exact = True
                    for i in range(0, 257, 4):
                        if tuple(pal[quant(src * (1 - i / 256) + nb * (i / 256), par)]) == want:
                            hit = True
                            break
                    if hit:
                        break
                if hit:
                    break
            models["neighbour-smear"] += hit
            models["neighbour-exact"] += exact

    print(f"leader-cell residual over six frames: {total} px, {on_sprite} of them ON the sprite")
    for k, v in models.items():
        verdict = "" if k.startswith("neighbour") else ("  <- KILLED" if v < total else "")
        print(f"  {k:16s} {v}/{total}{verdict}")
    print("neighbour-* are printed for completeness, not as evidence — see the docstring.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
