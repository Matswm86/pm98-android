#!/usr/bin/env python3
"""TEAM TACTICS modal parity: the app's render vs the ORIGINAL's own frames.

    DISPLAY=:1 PM98_SHOT_DIR=/tmp/pm98shots ~/godot462 --rendering-driver opengl3 \
        --path app --script res://tests/shot_teamtactics.gd
    PM98_SHOT_DIR=/tmp/pm98shots python3 tools/re/diff_teamtactics_parity.py

Two witnessed states, compared over the whole modal (57,95) 526x303:
  shot_teamtactics_resting.png  vs orig/25_team_tactics.png  (fresh Bolton = the
                                   .DBC lever defaults 45/50/MIXED/MEDIUM/ZONAL/
                                   SHORT/OWN)
  shot_teamtactics_mantoman.png vs orig/26_mantoman.png      (MARKING toggled —
                                   the 74-px witness)

CHROME (everything except the four 41x21 value plates) must be 0 px — ticks
included: the EQWINX blit positions are byte-verified, so a misplaced tick FAILS.
The four value plates are the DECLARED app-font bucket (the scout MONEY
precedent): the original's bold value raster is absent from the extracted .fnt
bank, so the app renders the digits in its own face inside the plate, in the
plate's own census-verified ink. Bounded here: every differing pixel must be
INSIDE a plate, and each plate must contain ink pixels (the value did render).
"""

import os
import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
WD = ROOT / "screenshots" / "parity-run-2026-07-16" / "orig"
SH = Path(os.environ.get("PM98_SHOT_DIR", "/tmp/pm98shots"))

MX, MY, MW, MH = 57, 95, 526, 303
PLATES = {  # design coords, 41x21 each (the eqwin sprite module)
    "passing": (116, 276), "long_ball": (227, 276),
    "counter_yes": (116, 330), "counter_no": (227, 330),
}


def load(p: Path) -> np.ndarray:
    return np.array(Image.open(p).convert("RGB"))[:, :640].astype(int)


def check(shot: str, ref: str) -> int:
    a = load(SH / shot)[MY:MY + MH, MX:MX + MW]
    b = load(WD / ref)[MY:MY + MH, MX:MX + MW]
    d = np.abs(a - b).sum(2) > 0
    plate_mask = np.zeros_like(d)
    for px, py in PLATES.values():
        plate_mask[py - MY:py - MY + 21, px - MX:px - MX + 41] = True
    chrome_bad = int((d & ~plate_mask).sum())
    plate_px = int((d & plate_mask).sum())
    print(f"{shot} vs {ref}: chrome {chrome_bad} px (must be 0), "
          f"plates {plate_px} px (declared app-font bucket)")
    if chrome_bad:
        ys, xs = np.where(d & ~plate_mask)
        print(f"  chrome bbox x{xs.min() + MX}..{xs.max() + MX} "
              f"y{ys.min() + MY}..{ys.max() + MY}")
    # each plate must show a rendered value: >= 20 non-black px in the shot
    for name, (px, py) in PLATES.items():
        region = a[py - MY:py - MY + 21, px - MX:px - MX + 41]
        ink = int((region.sum(2) > 0).sum())
        if ink < 20:
            print(f"  FAIL: {name} plate empty in the shot ({ink} ink px)")
            chrome_bad += 1
    return chrome_bad


def main() -> int:
    bad = check("shot_teamtactics_resting.png", "25_team_tactics.png")
    bad += check("shot_teamtactics_mantoman.png", "26_mantoman.png")
    print("PASS" if bad == 0 else "FAIL")
    return 0 if bad == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
