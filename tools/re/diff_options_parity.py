"""Parity gate for the hub OPTIONS modal after the THREE UP FRONT row was added.

    python3 tools/re/diff_options_parity.py

The OPTIONS panel is the one screen in this port that deliberately carries a pixel the
original does not: the port-side switch for the MANAGER_HACK.EXE cheat
(`docs/re/hack_three_forwards.md`). This script exists so that concession stays *bounded
and declared* instead of quietly eroding the render-diff standard. It checks three things:

1. the baked chrome `app/art/screens/dropdown/options_box.png` is still byte-identical to
   the live MANAGER.EXE capture it was cut from, everywhere OUTSIDE the declared band;
2. the declared band overlaps none of the original's own controls, so nothing witnessed is
   hidden behind the new row;
3. the band's area in the ORIGINAL frame carries no label ink and no OK-plate red — i.e.
   the row is drawn over empty box interior, not over something the original put there.

What it does NOT prove: that the *live* Godot render matches the capture. That is
`app/tests/test_options_panel.gd`'s job (rect containment + wiring); a full live-render
diff of this modal has never been built for it.
"""

from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
WITNESS = ROOT / "screenshots" / "wine-captures-2026-07-12" / "dropdown_options_panel.png"
BAKED = ROOT / "app" / "art" / "screens" / "dropdown" / "options_box.png"

# Mirrors of the OptionsPanel.gd constants (design space, 640x480).
BOX = (136, 124, 367, 220)          # x, y, w, h
CHEAT_BAND = (146, 318, 280, 22)
CONTROLS = {
    "R_MUSIC_SLIDER": (329, 195, 77, 15),
    "R_SFX_SLIDER": (329, 236, 77, 15),
    "R_MUSIC_BOX": (393, 207, 13, 13),
    "R_SFX_BOX": (393, 248, 13, 13),
    "R_TRANS_ON": (310, 287, 13, 13),
    "R_TRANS_OFF": (360, 287, 13, 13),
    "R_OK": (432, 320, 46, 22),
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
    print(f"  outside the THREE UP FRONT band : {outside} px differ")
    if outside:
        ok = False

    print(f"  declared band {CHEAT_BAND} = {cw * ch} px of port-only surface")
    for name, r in CONTROLS.items():
        if _overlaps(r, CHEAT_BAND):
            print(f"  FAIL: band overlaps {name} {r}")
            ok = False
    if all(not _overlaps(r, CHEAT_BAND) for r in CONTROLS.values()):
        print("  band overlaps none of the original's controls")

    band = cap[cy:cy + ch, cx:cx + cw]
    label_px = int((np.abs(band - np.array(C_LABEL)).max(axis=2) <= 8).sum())
    red_px = int(((band[..., 0] > 140) & (band[..., 1] < 80) & (band[..., 2] < 80)).sum())
    print(f"  original content under the band  : {label_px} label-ink px, {red_px} red px")
    if label_px or red_px:
        print("  FAIL: the band would cover pixels the original actually draws")
        ok = False

    print("PASS" if ok else "FAILURES ABOVE")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
