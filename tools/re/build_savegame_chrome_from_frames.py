#!/usr/bin/env python3
"""Bake the PM98 SAVE GAME dialog chrome from the live wine witnesses
(2026-07-18 run; frame-bake precedent: build_insurance_chrome_from_frames.py).

BINDING SOURCES (screenshots/wine-captures-2026-07-18-goalscorers/):
  50_hub4.png        the hub beneath (diff reference; the ONLY out-of-card
                     diffs vs 51 are the hub's own animated stadium + the
                     card-covered captions -> the dialog does NOT dim the hub)
  51_savegame.png    fresh SAVE GAME dialog, all 10 slots empty -> THE chrome
  52_slot1.png       slot 1 tapped: the whole row (both cells) turns BLACK
  53_slot1_typed.png "wk3" typed: white thin glyphs (y147..153) CENTRED in the
                     GAME cell
  55_save_cancelled.png  CANCEL -> hub restored (stadium anim frame differs)

WITNESSED STRUCTURE (design 640x480):
  card x140..499, y102..377 (2px black border + 5px white margin);
  title band y104..124 (150,0,0) "SAVE GAME";
  header row y127..142 (GAME / PLAYER navy labels, static);
  TEN slots: top border y143, pitch 16, fill h12 at y144+16k;
    GAME cell x148..349 fill (0,0,160) | split x350 | PLAYER x351..488 fill
    (75,109,172) | border x489;
  info strip y307..369 (steel boxes, static) + SAVE / CANCEL buttons at right.

Output (app/art/screens/savegame/):
  dialog.png            360x276 card verbatim (51)
  savegame_chrome.json  geometry + inks
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
CAP = ROOT / "screenshots/wine-captures-2026-07-18-goalscorers"
OUT_DIR = ROOT / "app/art/screens/savegame"
W, H = 640, 480

CARD = (140, 102, 500, 378)      # x0,y0,x1,y1 exclusive
ROW0_Y, ROW_PITCH, ROW_FILL_H, N_SLOTS = 144, 16, 12, 10
GAME_CELL = (148, 350)           # x0, x1 exclusive
PLAYER_CELL = (351, 489)


def load(name):
    return np.array(Image.open(CAP / name).convert("RGB"))[:H, :W]


def main() -> int:
    for f in ("50_hub4.png", "51_savegame.png", "52_slot1.png",
              "53_slot1_typed.png", "55_save_cancelled.png"):
        if not (CAP / f).exists():
            print(f"ERROR: binding source missing: {CAP / f}", file=sys.stderr)
            return 1
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    f50, f51, f52, f53 = (load(n) for n in
        ("50_hub4.png", "51_savegame.png", "52_slot1.png", "53_slot1_typed.png"))

    x0, y0, x1, y1 = CARD
    # ---- witness assertions ----------------------------------------------
    # 10 slot rows with the witnessed fills
    for k in range(N_SLOTS):
        ry = ROW0_Y + ROW_PITCH * k
        assert tuple(f51[ry + 4, 200]) == (0, 0, 160), f"GAME fill @slot {k}"
        assert tuple(f51[ry + 4, 400]) == (75, 109, 172), f"PLAYER fill @slot {k}"
    # armed slot 1 = both cells black (52), diff confined to the row
    d = np.abs(f52.astype(int) - f51.astype(int)).sum(axis=2)
    ys, xs = np.nonzero(d)
    assert ys.min() >= ROW0_Y and ys.max() <= ROW0_Y + ROW_FILL_H - 1, "armed row y"
    assert xs.min() >= GAME_CELL[0] and xs.max() <= PLAYER_CELL[1] - 1, "armed row x"
    assert tuple(f52[ROW0_Y + 5, 300]) == (0, 0, 0), "armed fill black"
    # typed glyphs centred in the GAME cell (53): white, y147..153
    d3 = np.abs(f53.astype(int) - f52.astype(int)).sum(axis=2)
    ys3, xs3 = np.nonzero(d3)
    assert 145 <= ys3.min() and ys3.max() <= 155, "typed glyph rows"
    cx = (xs3.min() + xs3.max()) / 2.0
    assert abs(cx - (GAME_CELL[0] + GAME_CELL[1] - 1) / 2.0) < 4, "typed centred"

    # ---- card chrome (verbatim 51) ---------------------------------------
    Image.fromarray(f51[y0:y1, x0:x1]).save(OUT_DIR / "dialog.png")
    print(f"wrote dialog.png {x1 - x0}x{y1 - y0}")

    # out-of-card 50-vs-51 diffs must be the animated stadium / covered
    # captions only (documented; proves NO dim layer)
    dd = np.abs(f51.astype(int) - f50.astype(int)).sum(axis=2)
    m = np.zeros_like(dd, dtype=bool)
    m[y0:y1, x0:x1] = True
    out = np.where(~m, dd, 0)
    ys4, xs4 = np.nonzero(out > 0)
    assert xs4.min() >= 140, "unexpected out-of-card diff at left"
    print(f"out-of-card diff px (hub stadium anim + covered captions): {(out > 0).sum()}")

    spec = {
        "binding_sources": {
            "chrome": "wine-captures-2026-07-18-goalscorers/51_savegame.png",
            "armed": "52_slot1.png", "typed": "53_slot1_typed.png",
            "hub_ref": "50_hub4.png", "cancel": "55_save_cancelled.png",
        },
        "card": list(CARD),
        "slots": {"row0_y": ROW0_Y, "pitch": ROW_PITCH, "fill_h": ROW_FILL_H,
                  "n": N_SLOTS, "game_cell": list(GAME_CELL),
                  "player_cell": list(PLAYER_CELL)},
        "buttons": {"save": [377, 306, 113, 25], "cancel": [377, 346, 113, 25]},
        "inks": {"game_fill": [0, 0, 160], "player_fill": [75, 109, 172],
                 "armed_fill": [0, 0, 0], "text": [255, 255, 255]},
        "notes": "hub beneath stays UNDIMMED (50-vs-51 out-of-card diffs = the "
                 "hub's own animated stadium + captions covered by the card); "
                 "populated-slot text rendering is unwitnessed (wine could not "
                 "save) -> white centred per-cell, the typed-name grammar.",
    }
    (OUT_DIR / "savegame_chrome.json").write_text(json.dumps(spec, indent=1))
    print("wrote savegame_chrome.json")
    return 0


if __name__ == "__main__":
    sys.exit(main())
