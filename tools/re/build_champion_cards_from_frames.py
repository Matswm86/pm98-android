#!/usr/bin/env python3
"""Bake the CAMPEON (champion card) chrome for EVERY competition whose card has
actually been witnessed, from the original's own frames.

The card is one shared layout -- five competitions matched the taught
`champion_card` pixel signature at 0.99-1.00 -- but the TITLE PLATE, the TROPHY
render and the backdrop behind them are per-competition art. `CharityShieldScreen`
already draws this layout; it only ever had the Charity Shield's chrome, so every
other trophy had no card at all.

Binding frames (all 641x480 captures, cropped to the game's native 640x480; the
outer panel, the RUNNER-UP label and the OK button are pixel-identical across all
six, verified before baking):

  charity_shield    screenshots/parity-run-2026-07-16/orig/70_after_ft.png
                    (already baked by build_seasonflow_chrome_from_frames.py ->
                     shield.png; re-baked here so all six come off one tool)
  intercontinental  screenshots/refrun-manutd-1997-98/named/p0273_champion_card.png
  coca_cola         screenshots/refrun-manutd-1997-98/named/p0581_champion_card.png
  uefa_cup          screenshots/refrun-manutd-1997-98/named/p0643_champion_card.png
  fa_cup            screenshots/refrun-manutd-1997-98/named/p0651_champion_card.png
  supercup          screenshots/wine-captures-2026-07-25-euro-competitions/
                    11_european_supercup_champion_card.png

NOT witnessed, therefore NOT baked and NOT invented: PREMIER LEAGUE CHAMPION,
EUROPEAN CUP CHAMPION and CUP WINNER'S CUP CHAMPION. Those three raise no card
until their frame is captured -- the trophy still appears on every other sheet
that lists it.

Blanking method is the shield bake's: the card's mottle is horizontally streaked
with no clean tile period, so each dynamic zone is refilled by CYCLING THE SAME
ROW's pixels from a text/kit/trophy-free x-range, which keeps the streaks
continuous. Only the baked text/kit extents are cleared; the live scene redraws
club names, manager names and both kits on top.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "app/art/screens/seasonflow"

W, H = 640, 480

FRAMES = {
    "charity_shield": "screenshots/parity-run-2026-07-16/orig/70_after_ft.png",
    "intercontinental": "screenshots/refrun-manutd-1997-98/named/p0273_champion_card.png",
    "coca_cola": "screenshots/refrun-manutd-1997-98/named/p0581_champion_card.png",
    "uefa_cup": "screenshots/refrun-manutd-1997-98/named/p0643_champion_card.png",
    "fa_cup": "screenshots/refrun-manutd-1997-98/named/p0651_champion_card.png",
    "supercup": (
        "screenshots/wine-captures-2026-07-25-euro-competitions/"
        "11_european_supercup_champion_card.png"
    ),
}

# Output file per competition. charity_shield keeps its historic name so the
# already-shipped CharityShieldScreen path is unchanged.
OUT_NAME = {
    "charity_shield": "shield.png",
    "intercontinental": "card_intercontinental.png",
    "coca_cola": "card_coca_cola.png",
    "uefa_cup": "card_uefa_cup.png",
    "fa_cup": "card_fa_cup.png",
    "supercup": "card_supercup.png",
}

# (zone, same-row clean source x-range) -- identical to the shield bake, because
# the layout is identical. The winner kit overlaps the title-band rows, where
# x335..420 carries title glyphs, so those rows source from the band's own
# glyph-free columns (title text starts x258 on every card).
ZONES = [
    ((60, 108, 140, 146), (150, 250)),   # winner kit, title-band rows
    ((60, 146, 140, 232), (335, 420)),   # winner kit, card rows
    ((140, 146, 332, 188), (335, 420)),  # winner club + manager lines
    ((60, 240, 140, 340), (335, 420)),   # runner-up kit box
    ((140, 267, 340, 320), (335, 420)),  # runner-up club + manager
]

# Pixel ranges that MUST be byte-identical across every frame before baking --
# proof that the six really are one layout and the zones transfer.
INVARIANTS = [
    ("ok_button", (84, 338, 144, 364)),
    ("panel_left_edge", (60, 100, 66, 370)),
]


def load(rel: str) -> np.ndarray:
    p = ROOT / rel
    if not p.exists():
        raise FileNotFoundError(p)
    return np.array(Image.open(p).convert("RGB").crop((0, 0, W, H)))


def patch_rows(a: np.ndarray, src_x: tuple, zone: tuple) -> None:
    sx0, sx1 = src_x
    x0, y0, x1, y1 = zone
    sw = sx1 - sx0
    for y in range(y0, y1):
        row = a[y, sx0:sx1].copy()
        for x in range(x0, x1, sw):
            w = min(sw, x1 - x)
            a[y, x : x + w] = row[:w]


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    raw = {}
    for key, rel in FRAMES.items():
        try:
            raw[key] = load(rel)
        except FileNotFoundError as exc:
            print(f"ERROR: binding frame missing: {exc}", file=sys.stderr)
            return 1

    # Prove the layout really is shared before transferring the zones.
    base = raw["charity_shield"]
    for name, (x0, y0, x1, y1) in INVARIANTS:
        for key, a in raw.items():
            diff = int((a[y0:y1, x0:x1] != base[y0:y1, x0:x1]).any(axis=2).sum())
            if diff:
                print(
                    f"ERROR: {key} differs from the shield card in {name} "
                    f"({diff} px) -- the zones cannot be transferred",
                    file=sys.stderr,
                )
                return 1

    spec = {
        "_source": "build_champion_cards_from_frames.py",
        "binding_frames": FRAMES,
        "zones": [list(z) for z, _src in ZONES],
        "cards": {},
    }
    for key, a in raw.items():
        img = a.copy()
        for zone, src in ZONES:
            patch_rows(img, src, zone)
        out = OUT / OUT_NAME[key]
        Image.fromarray(img).save(out)
        spec["cards"][key] = OUT_NAME[key]
        print(f"  {out.relative_to(ROOT)}  ({out.stat().st_size} bytes)")

    (OUT / "champion_cards.json").write_text(json.dumps(spec, indent=2))
    print(f"  {(OUT / 'champion_cards.json').relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
