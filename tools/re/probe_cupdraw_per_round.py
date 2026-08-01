#!/usr/bin/env python3
"""Does the CUP DRAW chrome vary PER ROUND, once the animated parts are taken out?

The question has been open since s81 and unanswerable until s85's drive banked four rounds
of the SAME competition from the SAME career. A raw diff between them leaves tens of
thousands of pixels, but almost all of it is content rather than chrome: the MATCHES panel
holds different ties, the round plate holds a different word, and the picture box holds the
SORTEO drum, which is ANIMATED -- two captures of the same round land on different drum
frames, so a raw diff cannot tell a per-round difference from a per-frame one.

So the animated region is MEASURED rather than guessed. The reference run banked several
frames of one Coca-Cola round (`p0125` / `p0131` / `p0133`); the union of the pixels that
differ ACROSS THOSE is, by construction, everything that moves without the round changing.
Mask that union, mask the round plate (whose text is the axis itself), mask the MATCHES
panel (whose content is the draw), and whatever is left is chrome that varies with the
ROUND and nothing else.

Usage: tools/re/probe_cupdraw_per_round.py
"""
from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

REPO = Path(__file__).resolve().parents[2]
ROUNDS = REPO / "tools/re/refs/cupdraw-rounds-2026-08-01"
REFRUN = REPO / "tools/re/refs/refrun-manutd-1997-98"

# The four Coca-Cola Cup frames, one career, in ladder order (README.md of ROUNDS).
COCA = [
    ("ROUND 2", "keep_0019_cup_draw.png"),
    ("ROUND 3", "keep_0049_cup_draw.png"),
    ("ROUND 4", "keep_0076_cup_draw.png"),
    ("QTR. FINALS", "keep_0111_cup_draw.png"),
]
# Same-round frames -> the ANIMATED union. p0125/p0131/p0133 are one Coca-Cola ROUND 3.
SAME_ROUND = ["p0125_cup_draw.png", "p0131_cup_draw.png", "p0133_cup_draw.png"]

# The spans that are CONTENT, not chrome, and are masked by name rather than by
# measurement: the round plate (build_cupdraw_chrome_from_frames.ROUND_SPAN), the whole
# MATCHES panel (whose rows carry the drawn ties), and the PICTURE BOX, which holds the
# sorteo drum and is animated end to end -- the same-round union below proves the drum
# moves, and a union taken from ANOTHER career cannot cover this career's ball positions,
# so the box goes in whole rather than leaving a residue that has to be excused.
ROUND_SPAN = (44, 232, 288, 254)          # x0, y0, x1, y1 inclusive
MATCHES_PANEL = (330, 20, 623, 425)
PICTURE_BOX = (27, 70, 300, 226)
# The bottom-left pair. NOT masked -- this is the axis under test, reported separately.
LEG_PLATES = (14, 405, 112, 466)
# The FINISH / CONTINUE strip. The mouse pointer sits here in several captures (the drive
# leaves it where it last clicked), so a residue here is the CURSOR, and it is named
# rather than masked: a mask would hide a real difference in the same pixels.
BUTTON_STRIP = (345, 438, 625, 466)


def load(p: Path) -> np.ndarray:
    """The frame as RGB ints, normalised to the game's own 640x480.

    The reference-run captures are 641 px wide -- one extra column, and it is on the
    RIGHT: cropping `[:, :640]` puts the static title band at **0 differing px** against a
    640-wide capture of the same screen, while cropping `[:, 1:]` puts it at 3,642. So the
    crop is measured, not assumed, and nothing is rescaled (a resample would invent
    subpixel ink and quietly poison every diff below).
    """
    a = np.asarray(Image.open(p).convert("RGB")).astype(int)
    return a[:, :640] if a.shape[1] > 640 else a


def box_mask(shape, box) -> np.ndarray:
    m = np.zeros(shape[:2], bool)
    x0, y0, x1, y1 = box
    m[y0:y1 + 1, x0:x1 + 1] = True
    return m


def main() -> int:
    missing = [f for _, f in COCA if not (ROUNDS / f).exists()]
    if missing:
        print(f"missing round frames: {missing}", file=sys.stderr)
        return 2

    # 1. the ANIMATED union, measured off frames of ONE round.
    same = [load(REFRUN / f) for f in SAME_ROUND if (REFRUN / f).exists()]
    if len(same) < 2:
        print(f"need >= 2 same-round frames in {REFRUN}", file=sys.stderr)
        return 2
    animated = np.zeros(same[0].shape[:2], bool)
    for other in same[1:]:
        animated |= np.abs(other - same[0]).sum(2) > 0
    print(f"animated union over {len(same)} same-round frames: {animated.sum()} px "
          f"(the drum, the hand, the filling MATCHES rows)")

    frames = {name: load(ROUNDS / f) for name, f in COCA}
    shape = next(iter(frames.values())).shape
    mask = (animated | box_mask(shape, ROUND_SPAN) | box_mask(shape, MATCHES_PANEL)
            | box_mask(shape, PICTURE_BOX))
    legs = box_mask(shape, LEG_PLATES)
    buttons = box_mask(shape, BUTTON_STRIP)
    print(f"masked total: {mask.sum()} px of {shape[0] * shape[1]}\n")

    # EVERY pair, not just against round 2 -- "round 2 differs from the other three" and
    # "all four differ from each other" are different findings and only the full matrix
    # separates them.
    print(f"{'pair':29s} {'LEG plates':>11s} {'buttons':>8s} {'ELSEWHERE':>10s}")
    unexplained = 0
    leg_pairs: list[tuple[str, str, int]] = []
    for i, (a_name, _) in enumerate(COCA):
        for b_name, _ in COCA[i + 1:]:
            d = (np.abs(frames[b_name] - frames[a_name]).sum(2) > 0) & ~mask
            n_leg = int((d & legs).sum())
            n_btn = int((d & buttons).sum())
            rest = d & ~legs & ~buttons
            n_rest = int(rest.sum())
            unexplained = max(unexplained, n_rest)
            line = f"{a_name:12s} vs {b_name:12s} {n_leg:11d} {n_btn:8d} {n_rest:10d}"
            if n_rest:
                ys, xs = np.nonzero(rest)
                line += f"   bbox x{xs.min()}..{xs.max()} y{ys.min()}..{ys.max()}"
            print(line)
            leg_pairs.append((a_name, b_name, n_leg))

    print()
    if unexplained == 0:
        print("VERDICT: the cup draw has exactly ONE per-round axis, and it is the "
              "bottom-left LEG PLATES. Outside them, four rounds of one competition are "
              "pixel-identical once the round plate, the MATCHES panel and the animated "
              "drum are taken out; the button-strip column is the mouse pointer the drive "
              "left behind.")
        differing = [(a, b) for a, b, n in leg_pairs if n]
        same_pairs = [(a, b) for a, b, n in leg_pairs if not n]
        print(f"  leg plates DIFFER on: {differing}")
        print(f"  leg plates MATCH on:  {same_pairs}")
        print("  i.e. ROUND 2 alone carries 1ST LEG / 2ND LEG; ROUND 3, ROUND 4 and "
              "QTR. FINALS all carry MATCH / REPLAY. The switch is the TIE FORM, and "
              "`CupDrawScreen.setup(..., legs)` already takes it.")
    else:
        print("VERDICT: something outside the leg plates and the button strip DOES vary "
              "per round -- inspect the bbox above before modelling it.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
