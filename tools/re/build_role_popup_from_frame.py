#!/usr/bin/env python3
"""Bake the TACTICS ROLE popup's chrome from the real game's own frame.

The popup MANAGER.EXE raises when the POS-column arrow of an XI row is clicked
(`FUN_0056a1d0`): a striped navy title bar carrying the player's surname, then the
FULL 18-entry fine-role list (the LONG name table at 0x662db0) — each row a camrol
pitch icon plus the role name in Euro8 — over a (75,109,172) item background.

The colour rule is the whole point, and it is binary-exact:

    cl = player[+0x1d]           # his NATURAL role
    if cl < 0x12:  item[cl].ink = 0x0000dfff   ->  RGB(255,223,0)  GOLD
    for i in 1..5:
        al = player[+0x1d + i]   # his five ALTERNATIVE roles
        if al < 0x12:  item[al].ink = 0x00ffffff -> RGB(255,255,255) WHITE
    (every other row keeps the default black ink)

Witness `screenshots/wine-captures-2026-07-24-role-training-staff/13_pos_arrow.png`
(Bolton W, week 1, Bergsson): RIGHT BACK gold, INSIDE CENTRE LEFT + INSIDE CENTRE
RIGHT white, the other 15 black — which is exactly what EQUIPOS.PKF stores for him
(`posFine` 2, `posAlts` [5, 6]). `15_role_applied.png` shows the pick applied: the
row's ROLE cell and camrol both change, POS does not.

Geometry measured off that frame (design px):
    popup      (220, 87) 200x277
    title bar  y 89..109, striped pattern row-invariant in the body; the surname is
               white, ink rows 96..103, ink-centred on x 319
    items      i at y 112+14i, background band 12 rows + a 2-row black separator;
               camrol + borders left of x 246, name ink left x 251, ink top 114+14i

This writes `app/art/screens/tactics/rolepopup_chrome.png` with the surname and all
18 role names blanked (title rows refilled from the bar's own pattern row, item text
refilled with the item background), plus `rolepopup.json` holding the geometry. It
asserts the blanking touched only the text bands.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "screenshots/wine-captures-2026-07-24-role-training-staff/13_pos_arrow.png"
OUT_DIR = ROOT / "app/art/screens/tactics"

POPUP = (220, 87, 200, 277)  # x, y, w, h
TITLE_INK_Y = (96, 104)  # [lo, hi)
TITLE_PATTERN_Y = 93  # a body row with no glyph on it
TITLE_CX = 319
ITEM_Y0 = 112
ITEM_PITCH = 14
ITEM_H = 12
ITEM_TEXT_X = 251
ITEM_INK_DY = 2  # ink top = item band top + 2
TEXT_BLANK_X0 = 246  # right of the camrol cell and its black divider
N_ITEMS = 18
BG = (75, 109, 172)


def main() -> int:
    frame = np.asarray(Image.open(SRC).convert("RGB")).copy()
    x, y, w, h = POPUP
    pop = frame[y : y + h, x : x + w].copy()

    # --- blank the surname: refill from the title bar's own pattern row --------
    pat = pop[TITLE_PATTERN_Y - y].copy()
    touched = 0
    for row in range(TITLE_INK_Y[0] - y, TITLE_INK_Y[1] - y):
        touched += int((pop[row] != pat).any(1).sum())
        pop[row] = pat

    # --- blank every role name, keeping camrol + borders ----------------------
    x0 = TEXT_BLANK_X0 - x
    x1 = w - 2  # the popup's own right black border
    for i in range(N_ITEMS):
        top = ITEM_Y0 + ITEM_PITCH * i - y
        band = pop[top : top + ITEM_H, x0:x1]
        touched += int((band != np.array(BG)).any(2).sum())
        band[:] = BG

    # --- assert nothing outside those bands moved -----------------------------
    diff = (pop != frame[y : y + h, x : x + w]).any(2)
    mask = np.zeros_like(diff)
    mask[TITLE_INK_Y[0] - y : TITLE_INK_Y[1] - y, :] = True
    for i in range(N_ITEMS):
        top = ITEM_Y0 + ITEM_PITCH * i - y
        mask[top : top + ITEM_H, x0:x1] = True
    stray = int((diff & ~mask).sum())
    if stray:
        print(f"FAIL: {stray} px changed outside the text bands")
        return 1

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    Image.fromarray(pop, "RGB").save(OUT_DIR / "rolepopup_chrome.png")
    spec = {
        "popup": list(POPUP),
        "title_cx": TITLE_CX,
        "title_ink_y": TITLE_INK_Y[0],
        "item_y0": ITEM_Y0,
        "item_pitch": ITEM_PITCH,
        "item_h": ITEM_H,
        "item_text_x": ITEM_TEXT_X,
        "item_ink_dy": ITEM_INK_DY,
        "n_items": N_ITEMS,
        "ink_natural": [255, 223, 0],
        "ink_alternate": [255, 255, 255],
        "ink_other": [0, 0, 0],
        "witness": "13_pos_arrow.png (Bergsson: RIGHT BACK gold, ICL+ICR white)",
    }
    (OUT_DIR / "rolepopup.json").write_text(json.dumps(spec, indent=2))
    print(f"wrote rolepopup_chrome.png ({w}x{h}); blanked {touched} text px, 0 stray")
    return 0


if __name__ == "__main__":
    sys.exit(main())
