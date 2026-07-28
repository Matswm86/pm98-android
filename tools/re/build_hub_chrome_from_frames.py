#!/usr/bin/env python3
"""MANAGER MENU (hub) chrome, frame-baked from the live-witnessed originals.

Binding frames (owned game, captured live from MANAGER.EXE under wine):
  screenshots/parity-run-2026-07-16/orig/73_hub_wk1.png   hub, player AWAY (wk 1)
  ~/MWM-AI/data/pm98-refs/real-gallery/ma_6.png           hub, player HOME

The centre circle is STATE-STYLED in the original: the PLAYER's half draws
dark slate boxes with white text, the CPU half pale mottled boxes with black
text, and the whole stack is HOME-side-top (witnessed: orig/73 away = pale
top; ma_6 home = dark top; promanager 13 away = pale top). The box fills are
dithered mottles, so both arrangements ship as REAL pixels:
  menu_bg.png          the orig/73 frame (away arrangement) with ONLY the live
                       text/kit/arrow zones cleared
  hub/ident_block.png  the manager/club identity block cut from the cleared bg
                       (PMChrome.draw_header blits it on every screen)
  hub/arrow.png        the player-side pointer cut from orig/73

Clearing paint: box texts fall to same-COLUMN cycling from the box's own clean
fill rows (mottle is unstructured noise); the kits that straddle the bands are
then cleared by same-ROW cycling from spans the column pass just cleaned.

Doctrine (pm98_stay_true_to_original): the PNGs are the real frames' pixels;
the ONLY paint is cycling from witnessed clean spans.

After running this, refresh menu_bg_dim: python3 tools/re/build_alert_chrome_from_frames.py
"""

from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
F_AWAY = ROOT / "screenshots/parity-run-2026-07-16/orig/73_hub_wk1.png"
F_HOME = Path.home() / "MWM-AI/data/pm98-refs/real-gallery/ma_6.png"
OUT = ROOT / "app/art/screens"

# Pass 1 -- box interiors, same-column cycling: (zone x0,y0,x1,y1), (src rows).
COL_CLEARS = [
    ((297, 178, 345, 187), (175, 178)),  # top chip label    ("CPU" / "PL 1")
    ((252, 201, 391, 216), (197, 201)),  # top manager       (Jones / Luis Silva)
    ((230, 230, 427, 246), (226, 230)),  # top club          (Southampton / Manchester Utd.)
    ((230, 272, 427, 289), (289, 293)),  # bottom club       (Bolton W / Blackburn R.)
    ((252, 307, 391, 322), (302, 307)),  # bottom manager    (mwm / Hodgson)
    ((297, 335, 345, 343), (332, 335)),  # bottom chip label
]
# Pass 2 -- kit + arrow slots on cleaned ground, same-row cycling: (zone), (src cols).
# Kit zones hug the witnessed kit ink (x195-244 / x395-444): the row-cycled fill
# is approximate over the circle rim, and the live kit blit covers all but a
# 1-2px fringe of it (flagged approximation).
ROW_CLEARS = [
    ((195, 200, 245, 265), (250, 268)),  # top kit (straddles the top band)
    ((395, 255, 445, 310), (365, 385)),  # bottom kit
    ((236, 194, 248, 218), (210, 222)),  # arrow slot, top bar (home frames)
    ((236, 300, 248, 324), (224, 236)),  # arrow slot, bottom bar (rows 316+ at
    #                                      x<224 are the red quadrant -- source
    #                                      from the rim-adjacent circle texture)
]

# Identity block (top-left): frame rect + the two bar-text zones + the kit box.
IDENT_RECT = (0, 4, 154, 52)  # cut for ident_block.png
IDENT_CLEARS = [
    ((16, 15, 108, 30), (92, 108)),  # manager name bar ("mwm", dark ink)
    ((16, 33, 108, 47), (92, 108)),  # club bar ("Bolton W", white ink)
]
IDENT_KIT = (111, 13, 141, 48)  # kit box (black frame): interior flat-filled white

# Calendar sheet live-text zones (flat white -- the sheet body is pure white):
# "Saturday" / red day / "August" / blue year, all cx~483 (frame-measured).
SHEET_CLEARS = [
    (452, 14, 516, 26),
    (468, 27, 502, 36),
    (452, 36, 516, 44),
    (452, 45, 516, 55),
]
# League / week plaque band labels ("Premier" black, "Week 1" white): same-row
# cycling keeps each band row's gradient shade.
BAND_CLEARS = [
    ((546, 16, 608, 28), (609, 618)),  # top band label
    ((548, 34, 604, 46), (605, 614)),  # bottom band label
]

ARROW_RECT = (238, 302, 247, 322)  # the away-frame arrow (player side pointer)



def patch_rows(a: np.ndarray, src_x: tuple, zone: tuple) -> None:
    """Refill zone rows by cycling the same row's pixels from the clean src x-range."""
    sx0, sx1 = src_x
    x0, y0, x1, y1 = zone
    w = x1 - x0
    for y in range(y0, y1):
        strip = a[y, sx0:sx1]
        reps = int(np.ceil(w / strip.shape[0]))
        a[y, x0:x1] = np.tile(strip, (reps, 1))[:w]


def patch_cols(a: np.ndarray, src_y: tuple, zone: tuple) -> None:
    """Refill zone columns by cycling the same column's pixels from clean src rows."""
    sy0, sy1 = src_y
    x0, y0, x1, y1 = zone
    h = y1 - y0
    for x in range(x0, x1):
        strip = a[sy0:sy1, x]
        reps = int(np.ceil(h / strip.shape[0]))
        a[y0:y1, x] = np.tile(strip, (reps, 1))[:h]


def ring_fill(a: np.ndarray, zone: tuple) -> None:
    """Flat-fill a zone with its border ring's dominant colour (recessed kit box)."""
    x0, y0, x1, y1 = zone
    ring = np.concatenate([a[y0, x0:x1], a[y1 - 1, x0:x1], a[y0:y1, x0], a[y0:y1, x1 - 1]])
    colours, counts = np.unique(ring, axis=0, return_counts=True)
    a[y0 + 1 : y1 - 1, x0 + 1 : x1 - 1] = colours[counts.argmax()]


def clear_circle(a: np.ndarray) -> None:
    for zone, src in COL_CLEARS:
        patch_cols(a, src, zone)
    for zone, src in ROW_CLEARS:
        patch_rows(a, src, zone)


def save(a: np.ndarray, name: str) -> None:
    p = OUT / name
    Image.fromarray(a).save(p)
    print("wrote", name, p.stat().st_size)


def main() -> None:
    away = np.asarray(Image.open(F_AWAY).convert("RGB"))[:, 0:640].copy()
    home = np.asarray(Image.open(F_HOME).convert("RGB"))[:, 0:640].copy()

    # arrow sprite first (cleared afterwards)
    x0, y0, x1, y1 = ARROW_RECT
    save(away[y0:y1, x0:x1].copy(), "hub/arrow.png")

    clear_circle(away)
    clear_circle(home)
    for zone, src in IDENT_CLEARS:
        patch_rows(away, src, zone)
    ring_fill(away, IDENT_KIT)
    for x0, y0, x1, y1 in SHEET_CLEARS:
        away[y0:y1, x0:x1] = (255, 255, 255)
    for zone, src in BAND_CLEARS:
        patch_rows(away, src, zone)

    # NOT menu_bg.png any more, and NOT hub/circle_home.png: since 2026-07-28 the hub
    # background and the circle's two bar schemes are built by
    # tools/re/build_menu_bg_from_ref.py, which restores the circle interior from the
    # game's own RECURSOS FONDO3.BMP instead of baking one career's bars into it. This
    # script keeps only the ident block, which is unaffected.

    x0, y0, x1, y1 = IDENT_RECT
    save(away[y0:y1, x0:x1].copy(), "hub/ident_block.png")


if __name__ == "__main__":
    (OUT / "hub").mkdir(exist_ok=True)
    main()
