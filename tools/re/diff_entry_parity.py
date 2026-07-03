#!/usr/bin/env python3
"""Pixel-diff the entry-flow parity shots against the original walkthrough frames.

Usage:  python3 tools/re/diff_entry_parity.py <shot_dir> [heatmap_dir]

Prints per-pair: differing-pixel count/fraction, mean abs diff, and the top
mismatch clusters (bboxes) so the drift is locatable. Known-acceptable regions
(the LineEdit caret cell in seleccion; nothing else) are excluded explicitly.
Exit 0 iff every pair is under its threshold.
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
FRAMES = ROOT / "screenshots" / "original-walkthrough-2026-07-02"
if not FRAMES.exists():  # full capture set is local-only; binding frames are committed
    FRAMES = ROOT / "tools" / "re" / "refs" / "walkthrough-2026-07-02"

# (shot, frame, roi [x0,y0,x1,y1] or None, excluded rects, max differing fraction).
# The nivel pairs scope to the DIALOG rect: the backdrop is the title screen's own
# parity story (it animates; the walkthrough caught it mid-state).
PAIRS = [
    ("nivel_003.png", "003_154332.png", (93, 32, 546, 447), [], 0.0001),
    ("nivel_005.png", "005_154338.png", (93, 32, 546, 447), [], 0.0001),
    ("seleccion_008.png", "008_154345.png", None, [(293, 67, 490, 92)], 0.0001),
    # 011 exclusions: the LineEdit caret cell, and the CONTINUE ball icon — the
    # SEGUIR ball ANIMATES on the enabled button (011 and 012 caught different
    # rotation frames; the overlay bakes 012's).
    (
        "seleccion_011.png",
        "011_154354.png",
        None,
        [(293, 67, 490, 92), (519, 429, 542, 449)],
        0.001,
    ),
    ("pretemp_013.png", "013_154358.png", None, [], 0.0001),
    ("pretemp_015.png", "015_154401.png", None, [], 0.0005),
    # TEAM OFFER card (run-3 frames). ROI = the modal rect (the hub behind is
    # its own parity story). Exclusions, all documented in team_offer_re.md:
    # WEIGHT/HEIGHT value strips (metric shown per the 2026-06-26 user call;
    # the original converts to imperial). The RATING box is INCLUDED as of the
    # morale decode: (VE+RE+AG+CA+FI+MO)/6 gives Thornley 79 = the frame
    # (FUN_00581e60, docs/re/morale_re.md).
    (
        "teamoffer_086.png",
        "086_164647.png",
        (98, 5, 541, 474),
        [(182, 97, 242, 109), (247, 97, 327, 109)],
        0.0001,
    ),
    (
        "teamoffer_088.png",
        "088_164650.png",
        (98, 5, 541, 474),
        [(182, 97, 242, 109), (247, 97, 327, 109)],
        0.0001,
    ),
    # MAKE-OFFER card (run-3 frames). ROI = the card frame (the OFFERS browse
    # screen behind is its own parity story). Exclusions, all documented in
    # make_offer_re.md: the animated info coin, WEIGHT/HEIGHT value strips
    # (metric per the 2026-06-26 user call). RATING box INCLUDED as of the
    # morale decode ((VE+RE+AG+CA+FI+MO)/6 gives Taylor 85 = the frame).
    (
        "makeoffer_101.png",
        "101_164714.png",
        (76, 48, 564, 431),
        [(83, 56, 123, 96), (206, 117, 266, 129), (271, 117, 331, 129)],
        0.0001,
    ),
    (
        "makeoffer_113.png",
        "113_164736.png",
        (76, 48, 564, 431),
        [(83, 56, 123, 96), (206, 117, 266, 129), (271, 117, 331, 129)],
        0.0001,
    ),
    # TACTICS board (run-2 frame 014), FULL FRAME: body from the tacticas bake
    # + the shared barra/header from the match-header bake (band + PROMAN8/
    # Result texts + RIDIESC kits + baked TACTICS title sprite). AV values are
    # injected frame-true in the shot (formula un-RE'd — documented in
    # tacticas_screen_re.md); everything else renders from game_db + baked art.
    (
        "tactics_014.png",
        "014_162413.png",
        None,
        [],
        0.0001,
    ),
    # LINE-UP / VIEW RIVAL match-header rollout (run-2 frames 155/015). ROI = the
    # 62px header band only: both screens' BODY parity stories are separate (the
    # tables keep the app's reconstructed metrics; documented in match_header_re.md).
    (
        "lineup_155.png",
        "155_162931.png",
        (0, 0, 640, 62),
        [],
        0.0001,
    ),
    (
        "rival_015.png",
        "015_162415.png",
        (0, 0, 640, 62),
        [],
        0.0001,
    ),
    # Hub ALERT BOX (run-3 frames; docs/re/alert_box_re.md). ROI = the box rect
    # only: the hub behind is the menu-bg parity story + the palette dim, and the
    # +5,+5 drop-shadow band is a per-palette-index remap two RGB frames cannot
    # disambiguate (approximated in-app; excluded here). The caption's title
    # field carries per-draw random speckle in 4 blues (random per instance in
    # the original), so mismatches inside the title strip where BOTH sides show
    # one of those blues are tolerated (NOISE_ZONES below).
    (
        "alert_093.png",
        "093_164659.png",
        (173, 196, 461, 278),
        [],
        0.0001,
    ),
    (
        "alert_149.png",
        "149_164911.png",
        (207, 191, 427, 283),
        [],
        0.0001,
    ),
    # FICHA / PLAYER INFORMATION card (run-1 frames; docs/re/ficha_card_re.md).
    # ROI = the card frame (the SQUAD MANAGEMENT screen behind palette-dims —
    # SquadScreen's own story). Exclusions, all documented in ficha_card_re.md:
    # the animated info coin, the BIGFOTO block (downscale kernel un-RE'd),
    # WEIGHT/HEIGHT value strips (metric per the 2026-06-26 user call). RATING
    # box INCLUDED as of the morale decode: (VE+RE+AG+CA+FI+MO)/6 gives VdG 80
    # and Solskjaer 82 = the frames (FUN_00581e60, docs/re/morale_re.md).
    (
        "ficha_081.png",
        "081_154619.png",
        (76, 58, 564, 421),
        [(84, 65, 124, 105), (130, 68, 162, 100), (206, 126, 331, 138)],
        0.0001,
    ),
    (
        "ficha_084.png",
        "084_154626.png",
        (76, 58, 564, 421),
        [(84, 65, 124, 105), (130, 68, 162, 100), (206, 126, 331, 138)],
        0.0001,
    ),
]

# The caption title-field speckle blues (see build_alert_chrome_from_frames.py).
NOISE_BLUES = {(42, 63, 170), (30, 52, 98), (20, 0, 90), (0, 0, 128)}
# shot -> title-strip rect [x0,y0,x1,y1] where blue<->blue mismatches don't count.
NOISE_ZONES = {
    "alert_093.png": (267, 198, 394, 222),
    "alert_149.png": (267, 193, 394, 217),
}
# The message's soft drop-shadow halo: the original dithers a direction-weighted
# falloff through this grey ramp (alert_box_re.md "Message shadow" — the exact
# per-offset stencil is un-reversed; the app approximates it with 3 double-stamped
# diagonal layers). Within the body text zone, mismatches where BOTH sides are
# halo greys / white are tolerated up to HALO_CAP px; message INK (black) and
# everything else stay strict.
HALO_GREYS = {
    (255, 255, 255),
    (240, 240, 240),
    (220, 220, 220),
    (192, 192, 192),
    (160, 160, 164),
    (144, 144, 144),
    (170, 191, 170),
    (192, 220, 192),
    (255, 251, 240),
    (215, 190, 220),
}
HALO_ZONES = {  # shot -> body text zone [x0,y0,x1,y1]
    "alert_093.png": (175, 224, 459, 250),
    "alert_149.png": (209, 219, 425, 255),
}
HALO_CAP = 1500


def clusters(mask: np.ndarray, max_out: int = 8) -> list[str]:
    """Greedy row/col cluster summary of the mismatch mask (no scipy dependency)."""
    out = []
    m = mask.copy()
    for _ in range(max_out):
        ys, xs = np.where(m)
        if ys.size == 0:
            break
        y0, x0 = ys[0], xs[0]
        # flood a loose box around the first mismatch
        y1, x1 = y0, x0
        for _ in range(60):
            grown = False
            ys2, xs2 = np.where(m[max(0, y0 - 4) : y1 + 5, max(0, x0 - 4) : x1 + 5])
            if ys2.size:
                ny0 = max(0, y0 - 4) + ys2.min()
                ny1 = max(0, y0 - 4) + ys2.max()
                nx0 = max(0, x0 - 4) + xs2.min()
                nx1 = max(0, x0 - 4) + xs2.max()
                if (ny0, ny1, nx0, nx1) != (y0, y1, x0, x1):
                    y0, y1, x0, x1 = ny0, ny1, nx0, nx1
                    grown = True
            if not grown:
                break
        n = int(m[y0 : y1 + 1, x0 : x1 + 1].sum())
        out.append(f"x{x0}..{x1} y{y0}..{y1} ({n}px)")
        m[y0 : y1 + 1, x0 : x1 + 1] = False
    return out


def main() -> int:
    shot_dir = Path(sys.argv[1])
    heat_dir = Path(sys.argv[2]) if len(sys.argv) > 2 else None
    ok = True
    for shot, frame, roi, excl, thresh in PAIRS:
        sp = shot_dir / shot
        if not sp.exists():
            print(f"{shot}: MISSING")
            ok = False
            continue
        a = np.asarray(Image.open(sp).convert("RGB")).astype(int)
        f = np.asarray(Image.open(FRAMES / frame).convert("RGB")).astype(int)[:, :640]
        if a.shape != f.shape:
            print(f"{shot}: size {a.shape} vs frame {f.shape}")
            ok = False
            continue
        d = np.abs(a - f).mean(axis=2)
        mask = d > 8
        for x0, y0, x1, y1 in excl:
            mask[y0:y1, x0:x1] = False
        if shot in NOISE_ZONES:
            x0, y0, x1, y1 = NOISE_ZONES[shot]
            for yy, xx in zip(*np.where(mask[y0:y1, x0:x1])):
                if (
                    tuple(a[y0 + yy, x0 + xx]) in NOISE_BLUES
                    and tuple(f[y0 + yy, x0 + xx]) in NOISE_BLUES
                ):
                    mask[y0 + yy, x0 + xx] = False
        if shot in HALO_ZONES:
            x0, y0, x1, y1 = HALO_ZONES[shot]
            tolerated = 0
            for yy, xx in zip(*np.where(mask[y0:y1, x0:x1])):
                if (
                    tuple(a[y0 + yy, x0 + xx]) in HALO_GREYS
                    and tuple(f[y0 + yy, x0 + xx]) in HALO_GREYS
                ):
                    mask[y0 + yy, x0 + xx] = False
                    tolerated += 1
            print(f"     {shot}: {tolerated}px shadow-halo tolerated (cap {HALO_CAP})")
            if tolerated > HALO_CAP:
                ok = False
                print(f"[FAIL] {shot}: halo tolerance exceeded")
        if roi is not None:
            roi_mask = np.zeros_like(mask)
            roi_mask[roi[1] : roi[3], roi[0] : roi[2]] = True
            mask &= roi_mask
        frac = mask.mean()
        status = "PASS" if frac <= thresh else "FAIL"
        if frac > thresh:
            ok = False
        print(
            f"[{status}] {shot} vs {frame}: {int(mask.sum())}px ({frac:.4f}) "
            f"mean-diff {d[mask].mean():.1f}"
            if mask.any()
            else f"[{status}] {shot} vs {frame}: 0px — pixel-exact"
        )
        if mask.any():
            for c in clusters(mask):
                print(f"     {c}")
        if heat_dir and mask.any():
            heat_dir.mkdir(parents=True, exist_ok=True)
            hm = np.zeros((*mask.shape, 3), dtype=np.uint8)
            hm[..., 0] = np.clip(d * 3, 0, 255)
            hm[mask] = [255, 40, 40]
            base = (a * 0.35).astype(np.uint8)
            base[mask] = [255, 40, 40]
            Image.fromarray(base).save(heat_dir / f"heat_{shot}")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
