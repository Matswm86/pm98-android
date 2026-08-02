#!/usr/bin/env python3
"""Pixel-diff the CupDrawScreen (SORTEO) parity shots against their binding frames.

Usage:  python3 tools/re/diff_cupdraw_parity.py <shot_dir> [--heatmap out_prefix]

Four shots, four real MANAGER.EXE frames -- BOTH panel forms (REFRUN R8):

  the >16-tie LIST form
    cupdraw_74.png  vs  wine-captures-2026-07-18-goalscorers/74_after_wk4.png
                        Coca-Cola Cup ROUND 2, 4 of 25 ties, the 4th mid-draw
    cupdraw_10.png  vs  promanager-career-2026-07-16/10_fa_cup_draw_round1.png
                        F.A. Cup ROUND 1, 4 of 40 ties, MATCH / REPLAY plates

  the GROUP form (s88)
    cupdraw_groups.png vs refs/cupdraw-rounds-2026-08-01/manutd_s1_eurocup_groups_1_8_final.png
                        European Cup 1/8 FINAL, the group draw mid-reveal: GROUP A's four
                        clubs landed, B..F still empty

  the <=16-tie GRID form
    cupdraw_133.png vs  refs/refrun-manutd-1997-98/p0133_cup_draw.png
                        Coca-Cola Cup ROUND 3, all 16 ties, the manager's own tie on
                        row 1 (dark plate, his club in bright yellow)
    cupdraw_747.png vs  refs/refrun-manutd-1997-98/p0747_cup_draw.png
                        U.E.F.A. Cup 1/16 FINAL, row 5 selected and the tie-detail card
                        filled in (F.C. Barcelona / Van Gaal v Karlsruher)

The whole screen is engine-composited (baked chrome + the redrawn dynamic layer), so the
diff is against the FULL 640x480 frame. Excluded rects are listed with a reason each and
counted separately; exit 0 iff the post-exclusion differing fraction is under THRESH.
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
CASES = [
    (
        "cupdraw_74.png",
        ROOT / "screenshots" / "wine-captures-2026-07-18-goalscorers" / "74_after_wk4.png",
    ),
    (
        "cupdraw_10.png",
        ROOT / "screenshots" / "promanager-career-2026-07-16" / "10_fa_cup_draw_round1.png",
    ),
    (
        "cupdraw_133.png",
        ROOT / "tools" / "re" / "refs" / "refrun-manutd-1997-98" / "p0133_cup_draw.png",
    ),
    (
        "cupdraw_747.png",
        ROOT / "tools" / "re" / "refs" / "refrun-manutd-1997-98" / "p0747_cup_draw.png",
    ),
    (
        "cupdraw_groups.png",
        ROOT
        / "tools"
        / "re"
        / "refs"
        / "cupdraw-rounds-2026-08-01"
        / "manutd_s1_eurocup_groups_1_8_final.png",
    ),
    (
        "cupdraw_semis_cc.png",
        ROOT
        / "tools"
        / "re"
        / "refs"
        / "cupdraw-semifinals-2026-08-02"
        / "cocacola_semifinals_2leg.png",
    ),
    (
        "cupdraw_semis_fa.png",
        ROOT
        / "tools"
        / "re"
        / "refs"
        / "cupdraw-semifinals-2026-08-02"
        / "facup_semifinals_match_replay.png",
    ),
]
THRESH = 0.004  # <0.4% of the 640x480 frame after the documented exclusions

# Excluded rects [x0,y0,x1,y1], each a documented un-witnessed or animated region:
#  - CONTINUE's ball ANIMATES and its lit/unlit rule is un-reversed (74 dark, 75 green),
#    so the chrome bakes frame 74's phase and frame 10's own phase differs.
EXCLUDE = [
    (489, 436, 614, 470),  # CONTINUE button: animated ball + un-witnessed lit state
]

# The two GRID shots carry two extra exclusions, each a DATA gap rather than a geometry
# one, so they are named per-case instead of globally:
#  - the kit cells and the tie card's two kit panels: the shot feeds club names only, so
#    no kit is drawn at all, and the original's hi-res panel kit bank is un-extracted
#    anyway (the same gap CompResultScreen and CharityShieldScreen already carry);
#  - the DRUM. p0133 and p0747 hold a drum image that is byte-identical to each other and
#    matches NONE of the twelve exported BOMBO frames (nearest is BOMBO00 at 2709 px),
#    while p0125 is BOMBO03 and p0445 is BOMBO06 at ZERO. So the drum has at least one
#    state beyond the twelve stills -- a lead for the parked drum hunt, recorded in
#    docs/re/cupdraw_screen_re.md, not something this change can resolve.
GRID_EXCLUDE = [
    (136, 76, 228, 168),  # the drum: a state none of the twelve BOMBO frames holds
    (334, 51, 355, 419),  # home kit cells   -- no kit art fed to the shot
    (601, 51, 622, 419),  # away kit cells
    (33, 320, 110, 386),  # tie card, home kit panel
    (236, 320, 287, 386),  # tie card, away kit panel
]


# The GROUP form carried ONE exclusion bucket -- the un-reversed 1-px on-sprite KIT EDGE
# pass -- over group A's four RIDIESC kits and four MINIBAND flags, 433 px in all. It is
# reversed now (`PMShadow.edge_blit`, the `flags = 0x20` arm of `FUN_005cbea0`: the
# `FUN_005d60a0` edge classifier over the table read out of the running original, then the
# same IIR spread the 0x10 arm uses, at this site's thr 0x20 / cap 0x80), and two defects it
# was hiding came out with it:
#
#     port render, kits + flags, before      433 px
#     ridi bank re-baked against MANAGER.PAL 382   (21 of 256 VGA entries are wrong for a
#                                                   realised sprite; 91 of 476 kits use one)
#     + the 0x20 edge pass on the kits        37   (all four kits at 0)
#     + the same pass on the flags             4
#
# So the four KIT rects are gone from this list. What is left is the flags' own 4 px, and
# its cause is named rather than budgeted: this screen draws the MINIBAND sprite from ROW 1
# and its row 0 lands nowhere (measured in `build_groupdraw_chrome_from_frame.py`, and still
# unexplained), so the pass's top row is computed over a destination that is not on screen.
GROUPS_EXCLUDE = [
    (406, 89, 420, 98),  # group A row 0 flag (14x9 MINIBAND, rows 1..9)
    (406, 114, 420, 123),  # row 1
    (406, 139, 420, 148),  # row 2
    (406, 164, 420, 173),  # row 3
]

# The SEMIFINAL form (s92) carries ONE residual, on the F.A. frame only: two pixels of
# the Newcastle Utd NANOESC kit's edge pass — (349,162) and (337,164), the port's dither
# gray (114) where the frame holds (128). The Python replica of the leaf reproduces the
# same two pixels, so this is a real un-reversed corner of the 13-bit edge classifier on
# this one sprite, not a port bug: 2 px over the form's eight witnessed kit cells (the
# other seven land at 0). Same class as the GROUPS form's flag ROW 0 above — recorded,
# not tuned away.
SEMIS_FA_EXCLUDE = [
    (337, 162, 350, 165),  # Newcastle kit, two edge-classifier px
]


def load(p: Path) -> np.ndarray:
    return np.asarray(Image.open(p).convert("RGB"))[:480, :640]


def report(shot: Path, frame: Path, heat: str | None) -> float:
    a, b = load(shot), load(frame)
    d = (a != b).any(axis=2)
    raw = float(d.mean())
    m = d.copy()
    rects = list(EXCLUDE)
    if shot.name in ("cupdraw_133.png", "cupdraw_747.png"):
        rects += GRID_EXCLUDE
    if shot.name == "cupdraw_groups.png":
        rects += GROUPS_EXCLUDE
    if shot.name == "cupdraw_semis_fa.png":
        rects += SEMIS_FA_EXCLUDE
    for x0, y0, x1, y1 in rects:
        m[y0:y1, x0:x1] = False
    net = float(m.mean())
    print(f"{shot.name} vs {frame.name}")
    print(f"  raw      {d.sum():6d} px  {100 * raw:6.3f}%")
    print(f"  excluded {m.sum():6d} px  {100 * net:6.3f}%   (threshold {100 * THRESH:.1f}%)")
    if m.any():
        ys, xs = np.where(m)
        print(f"  bbox     x {xs.min()}..{xs.max()}  y {ys.min()}..{ys.max()}")
        # coarse 32px buckets, so drift is locatable
        buckets: dict[tuple[int, int], int] = {}
        for y, x in zip(ys.tolist(), xs.tolist()):
            k = (x // 32 * 32, y // 32 * 32)
            buckets[k] = buckets.get(k, 0) + 1
        top = sorted(buckets.items(), key=lambda kv: -kv[1])[:8]
        for (bx, by), n in top:
            print(f"    x{bx:3d} y{by:3d}  {n:5d}")
    if heat:
        Image.fromarray((m * 255).astype(np.uint8)).save(f"{heat}_{shot.stem}.png")
    return net


def main() -> None:
    if len(sys.argv) < 2:
        print(__doc__)
        raise SystemExit(2)
    shot_dir = Path(sys.argv[1])
    heat = None
    if "--heatmap" in sys.argv:
        heat = sys.argv[sys.argv.index("--heatmap") + 1]
    worst = 0.0
    for shot_name, frame in CASES:
        shot = shot_dir / shot_name
        if not shot.exists():
            print(f"MISSING {shot}")
            raise SystemExit(2)
        worst = max(worst, report(shot, frame, heat))
        print()
    print(f"worst {100 * worst:.3f}%  -> {'PASS' if worst < THRESH else 'FAIL'}")
    raise SystemExit(0 if worst < THRESH else 1)


if __name__ == "__main__":
    main()
