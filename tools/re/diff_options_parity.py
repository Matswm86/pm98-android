"""Parity gate for the hub OPTIONS modal after the two cheat rows were added.

    python3 tools/re/diff_options_parity.py

The OPTIONS panel is the one screen in this port that deliberately carries pixels the
original does not: the port-side switches for the two MANAGER_HACK.EXE cheats,
UNSACKABLE (`docs/re/hack_unsackable.md`) and THREE UP FRONT
(`docs/re/hack_three_forwards.md`). This script exists so that concession stays *bounded
and declared* instead of quietly eroding the render-diff standard. It checks three things:

1. the baked chrome `app/art/screens/dropdown/options_box.png` is still byte-identical to
   the live MANAGER.EXE capture it was cut from, everywhere OUTSIDE the declared band;
2. the declared band overlaps none of the original's own controls, so nothing witnessed is
   hidden behind the new row;
3. the band's area in the ORIGINAL frame carries no label ink and no OK-plate red — i.e.
   the row is drawn over empty box interior, not over something the original put there.

4. **the LIVE Godot render** of the modal, banked at
   `tools/re/refs/options-2026-07-28/options_witness_state.png`, against the same capture
   — outside the band, and in the capture's own MANAGER.INI state (MUSIC: OFF /
   SOUND: OFF / TRANSITIONS: ON, volumes 100), which `Main._options_shot` forces for that
   one frame. Added 2026-07-28: until then this file could only diff the BAKED chrome, and
   said so. Re-bank the frame with
   `DISPLAY=:N PM98_OPTIONS_SHOT=1 PM98_SHOT_DIR=... godot462 --path app --rendering-driver opengl3`.
"""

from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
WITNESS = ROOT / "screenshots" / "wine-captures-2026-07-12" / "dropdown_options_panel.png"
BAKED = ROOT / "app" / "art" / "screens" / "dropdown" / "options_box.png"
LIVE = ROOT / "tools" / "re" / "refs" / "options-2026-07-28" / "options_witness_state.png"

# Mirrors of the OptionsPanel.gd constants (design space, 640x480).
BOX = (136, 124, 367, 220)          # x, y, w, h
CHEAT_BAND = (138, 315, 288, 29)    # two rows: UNSACKABLE (y315) + THREE UP FRONT (y331)
CONTROLS = {
    "R_MUSIC_SLIDER": (329, 195, 77, 15),
    "R_SFX_SLIDER": (329, 236, 77, 15),
    "R_MUSIC_BOX": (393, 207, 13, 13),
    "R_SFX_BOX": (393, 248, 13, 13),
    "R_TRANS_ON": (310, 287, 13, 13),
    "R_TRANS_OFF": (360, 287, 13, 13),
    "R_OK": (432, 320, 46, 22),
}
# The two cheat rows' own boxes must land INSIDE the declared band (they are the pixels
# the band exists to cover). Checked here as well as in test_options_panel.gd so the gate
# fails if a row is nudged out of the band it declares.
CHEAT_BOXES = {
    "R_UNSACK_ON": (310, 315, 13, 13),
    "R_UNSACK_OFF": (360, 315, 13, 13),
    "R_CHEAT_ON": (310, 331, 13, 13),
    "R_CHEAT_OFF": (360, 331, 13, 13),
}
C_LABEL = (255, 223, 0)             # the modal's own label ink


def _overlaps(a: tuple[int, int, int, int], b: tuple[int, int, int, int]) -> bool:
    return (
        a[0] < b[0] + b[2] and b[0] < a[0] + a[2]
        and a[1] < b[1] + b[3] and b[1] < a[1] + a[3]
    )


def main() -> int:
    cap = np.asarray(Image.open(WITNESS).convert("RGB"), dtype=int)
    box = np.asarray(Image.open(BAKED).convert("RGB"), dtype=int)
    bx, by, bw, bh = BOX
    crop = cap[by:by + bh, bx:bx + bw]
    if crop.shape != box.shape:
        print(f"FAIL: capture crop {crop.shape} != baked {box.shape}")
        return 1

    ok = True
    diff = np.abs(crop - box).max(axis=2) > 0
    # blank the declared band before counting, then count it separately
    cx, cy, cw, ch = CHEAT_BAND
    mask = np.zeros(diff.shape, dtype=bool)
    mask[cy - by:cy - by + ch, cx - bx:cx - bx + cw] = True
    outside = int((diff & ~mask).sum())
    print(f"baked chrome vs {WITNESS.name}")
    print(f"  outside the declared cheat band     : {outside} px differ")
    if outside:
        ok = False

    print(f"  declared band {CHEAT_BAND} = {cw * ch} px of port-only surface")
    for name, r in CONTROLS.items():
        if _overlaps(r, CHEAT_BAND):
            print(f"  FAIL: band overlaps {name} {r}")
            ok = False
    if all(not _overlaps(r, CHEAT_BAND) for r in CONTROLS.values()):
        print("  band overlaps none of the original's controls")
    for name, r in CHEAT_BOXES.items():
        inside = (
            r[0] >= cx and r[1] >= cy
            and r[0] + r[2] <= cx + cw and r[1] + r[3] <= cy + ch
        )
        if not inside:
            print(f"  FAIL: {name} {r} falls outside the declared band")
            ok = False
    print(f"  all {len(CHEAT_BOXES)} cheat X-boxes sit inside the band")

    # 4. the LIVE render, in the capture's own MANAGER.INI state.
    if LIVE.exists():
        live = np.asarray(Image.open(LIVE).convert("RGB"), dtype=int)
        # The wine capture is 641 px wide (the desktop's own border column); only the BOX
        # crop has to line up, so require the frame to be big enough for it, not identical.
        if live.shape[0] < by + bh or live.shape[1] < bx + bw:
            print(f"  FAIL: live frame {live.shape[:2]} is too small for BOX {BOX}")
            ok = False
        else:
            lcrop = live[by:by + bh, bx:bx + bw]
            ldiff = np.abs(crop - lcrop).max(axis=2) > 0
            l_out = int((ldiff & ~mask).sum())
            l_in = int((ldiff & mask).sum())
            print(f"  LIVE render {LIVE.name}")
            print(f"    outside the band : {l_out} px differ")
            print(f"    inside the band  : {l_in} px = the two cheat rows themselves")
            if l_out:
                ok = False
    else:
        print(f"  (no live frame at {LIVE.relative_to(ROOT)} — live diff skipped)")
        ok = False

    band = cap[cy:cy + ch, cx:cx + cw]
    label_px = int((np.abs(band - np.array(C_LABEL)).max(axis=2) <= 8).sum())
    red_px = int(((band[..., 0] > 140) & (band[..., 1] < 80) & (band[..., 2] < 80)).sum())
    # WHITE too: the modal's ON/OFF captions are white, not label-gold, and leaving them
    # out of this test is exactly what let the first two-row layout draw through the
    # TRANSITIONS captions at rows 308..314 (found 2026-07-28 by looking at the render).
    white_px = int((band.min(axis=2) >= 170).sum())
    print(f"  original content under the band  : {label_px} label-ink px, {red_px} red px,"
          f" {white_px} white px")
    if label_px or red_px or white_px:
        print("  FAIL: the band would cover pixels the original actually draws")
        ok = False

    print("PASS" if ok else "FAILURES ABOVE")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
