#!/usr/bin/env python3
"""Bake the PM98 `channelTV` card from the original's own frames.

The original sells the broadcast rights to each HOME match and raises an
UNPROMPTED card over MANAGER MENU before the match is played
(docs/re/REFRUN_manutd_1997-98.md R6). The card is a bespoke art panel -- the
PREMIER MANAGER 98 / channelTV logo, a camera over a pitch, two lines of body
text and the fee -- not the standard alert box.

Binding frames (both 641x480 captures, cropped to the game's native 640x480):

  screenshots/refrun-manutd-1997-98/named/p0474_channel_tv.png
      Saturday 7 February 1998, hub "Premier / Week 27", fee £90,000
  screenshots/refrun-manutd-1997-98/named/p0032_channel_tv.png
      Sunday 3 August 1997, hub "Charity / Final", fee £187,500

Diffing the two INSIDE the panel leaves exactly two regions: the fee line at
y329..339 x262..375, and the OK button (captured in different states). Every
other pixel of the card is identical, which is what makes the fee the only
dynamic field and lets the whole panel be cut 1:1.

Output:
  app/art/screens/channeltv/card.png       - the panel, fee line blanked
  app/art/screens/channeltv/channeltv.json - the panel origin, fee anchor and OK rect
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "app/art/screens/channeltv"

W, H = 640, 480

F_MAIN = "screenshots/refrun-manutd-1997-98/named/p0474_channel_tv.png"
F_ALT = "screenshots/refrun-manutd-1997-98/named/p0032_channel_tv.png"

# The card panel, measured off p0474: the hub's flat (144,144,144) run ends at
# x=96 on row 250 and resumes at x=544; the panel's top border is row 102 and its
# bottom border row 374 (row 375 is already hub art again).
PANEL = (96, 102, 544, 375)          # x0, y0, x1, y1 (exclusive)

# The fee line -- the ONLY dynamic field. Blanked with the panel's own body
# colour, sampled from a glyph-free column of the same rows.
FEE_ZONE = (255, 326, 390, 342)      # x0, y0, x1, y1 (a little wider than the ink)
FEE_SRC_X = 240                      # glyph-free column on those rows

# The OK button, hit-tested by the scene (screen-absolute). Its lower rows carry the
# button's pressed/unpressed shading, which is why the two frames differ there.
OK_RECT = (463, 345, 541, 374)


def load(rel: str) -> np.ndarray:
    p = ROOT / rel
    if not p.exists():
        raise FileNotFoundError(p)
    return np.array(Image.open(p).convert("RGB").crop((0, 0, W, H)))


def main() -> int:
    try:
        a = load(F_MAIN)
        b = load(F_ALT)
    except FileNotFoundError as exc:
        print(f"ERROR: binding frame missing: {exc}", file=sys.stderr)
        return 1

    # Prove the panel really is static bar the fee and the OK button.
    x0, y0, x1, y1 = PANEL
    diff = (a[y0:y1, x0:x1] != b[y0:y1, x0:x1]).any(axis=2)
    ys, xs = np.nonzero(diff)
    fx0, fy0, fx1, fy1 = FEE_ZONE
    ox0, oy0, ox1, oy1 = OK_RECT
    stray = 0
    for y, x in zip(ys + y0, xs + x0):
        in_fee = fx0 <= x < fx1 and fy0 <= y < fy1
        in_ok = ox0 <= x < ox1 and oy0 <= y < oy1
        if not (in_fee or in_ok):
            stray += 1
    if stray:
        print(
            f"ERROR: {stray} px differ between the two channelTV frames OUTSIDE the "
            "fee line and the OK button -- the panel is not static, do not bake",
            file=sys.stderr,
        )
        return 1

    img = a.copy()
    for y in range(fy0, fy1):
        img[y, fx0:fx1] = img[y, FEE_SRC_X]

    OUT.mkdir(parents=True, exist_ok=True)
    panel = Image.fromarray(img[y0:y1, x0:x1])
    panel.save(OUT / "card.png")
    spec = {
        "_source": "build_channeltv_card_from_frames.py",
        "binding_frames": [F_MAIN, F_ALT],
        "panel": list(PANEL),
        "fee_zone": list(FEE_ZONE),
        "ok_rect": list(OK_RECT),
        "witnessed_fees": {
            "premier_league": 90000,
            "charity_shield": 187500,
            "european_cup": 375000,
        },
    }
    (OUT / "channeltv.json").write_text(json.dumps(spec, indent=2))
    print(f"  {(OUT / 'card.png').relative_to(ROOT)}  {panel.size}")
    print(f"  {(OUT / 'channeltv.json').relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
