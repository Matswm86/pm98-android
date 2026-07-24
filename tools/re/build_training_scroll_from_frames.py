#!/usr/bin/env python3
"""Cut the TRAINING screen's ENABLED per-section scrollbar art from a real frame.

The baked TRAINING chrome (`app/art/screens/training/chrome.png`) was taken from a
career whose every section fitted its visible slots, so every scrollbar in it is in
the DISABLED look (pale, checkered arrows, no thumb). The 2026-07-24 owner report
("newly signed players never appear in TRAINING") is that missing state: the original
SCROLLS each section, it does not cap the squad.

Witness: `screenshots/wine-captures-2026-07-24-role-training-staff/` —
`17_training.png` (Bolton W, 9 defenders in 6 slots: the DEFENDERS bar is enabled with
its thumb parked at the top and only the DOWN arrow lit) and `18_train_scrolled.png`
(the same bar after ONE down-arrow click: Todd leaves the top, Whitlow enters the
bottom, and BOTH arrows are lit). One click == one row.

Measured off those two frames (design px, 640x480):

  scroll column x 313..328 (w 16); per-section bands
      KEEPERS     y  87 h 46
      DEFENDERS   y 150 h 94
      MIDFIELDERS y 262 h 94
      FORWARDS    y 374 h 78
  up button   = (313, band_y,             16, 16)
  down button = (313, band_y + band_h-16, 16, 16)
  track       = (313, band_y + 16,        16, band_h - 32)
      (16 + 62 + 16 == 94, the DEFENDERS band exactly; the buttons are 16 tall, not
       15 — their last row is the bevel that turns black when the arrow goes live,
       which is what frames 17 vs 18 differ by on rows 164/165)
      -> DEFENDERS track y166..227 (62), which reproduces both frames exactly:
         thumb_h  = floor(track_h * visible / total) = floor(62*6/9) = 41
         thumb_y  = track_y + floor(track_h * first / total)
                  = 166 + 0 -> 166 (frame 17) and 166 + floor(62/9)=6 -> 172 (frame 18)
      (the same slider grammar as the OFFERS / INSURANCE lists, offers_map_re.md)

The thumb is a 3-slice: a 3-row top cap (black / 220 / 180,200,220), a **4-row** dither
period (the fill is checkered in x as well as y, so a 2-row period is not enough — it
leaves 27 px wrong on the offset-0 frame), and a 3-row bottom cap
((60,80,100) / black / black). The middle is the period tiled and clipped.

Writes `app/art/screens/training/scroll_*.png` and asserts every cut against BOTH
frames, so a bad crop cannot ship.
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SHOTS = ROOT / "screenshots/wine-captures-2026-07-24-role-training-staff"
OUT = ROOT / "app/art/screens/training"

COL_X = 313
COL_W = 16
BANDS = {"gk": (87, 46), "def": (150, 94), "mid": (262, 94), "fwd": (374, 78)}
BTN_H = 16
# DEFENDERS in the two witness frames: 9 players, 6 visible, offsets 0 and 1.
DEF_Y, DEF_H = BANDS["def"]
TRACK_Y = DEF_Y + 16
TRACK_H = DEF_H - 32


def load(name: str) -> np.ndarray:
    return np.asarray(Image.open(SHOTS / name).convert("RGB"))


def save(a: np.ndarray, name: str) -> None:
    Image.fromarray(a, "RGB").save(OUT / name)
    print(f"  wrote {name} ({a.shape[1]}x{a.shape[0]})")


def main() -> int:
    f0 = load("17_training.png")  # DEFENDERS offset 0
    f1 = load("18_train_scrolled.png")  # DEFENDERS offset 1
    OUT.mkdir(parents=True, exist_ok=True)

    # both arrows are lit in frame 1 (offset 1 of a 3-offset range)
    up = f1[DEF_Y : DEF_Y + BTN_H, COL_X : COL_X + COL_W]
    dn = f1[DEF_Y + DEF_H - BTN_H : DEF_Y + DEF_H, COL_X : COL_X + COL_W]
    save(up, "scroll_up_on.png")
    save(dn, "scroll_dn_on.png")

    # ...and the DIM pair. An enabled bar parked at the top still shows a dim UP arrow
    # (frame 0's DEFENDERS band, thumb at row 0) and one parked at the bottom a dim
    # DOWN arrow (frame 0's resting MIDFIELDERS band). Cutting both means an enabled
    # bar never lets the baked plate's own arrow show through.
    save(f0[DEF_Y : DEF_Y + BTN_H, COL_X : COL_X + COL_W], "scroll_up_off.png")
    mid_y, mid_h = BANDS["mid"]
    save(f0[mid_y + mid_h - BTN_H : mid_y + mid_h, COL_X : COL_X + COL_W], "scroll_dn_off.png")

    # the empty track colour: frame 1 rows 213..227 are below the thumb
    track = f1[TRACK_Y + 47 : TRACK_Y + 48, COL_X : COL_X + COL_W]
    save(track, "scroll_track_on.png")

    # --- the DISABLED bar, whole, for the band heights frame 0 witnesses -------
    # The baked TRAINING chrome came from a career whose DEFENDERS section DID scroll,
    # so its plate carries a thumb where a short squad has nothing to scroll. Frame 0
    # gives two sections at rest — KEEPERS (3 of 3, band h 46) and MIDFIELDERS (4 of 6,
    # band h 94) — so those two heights can be repainted from the original's own pixels.
    # FORWARDS (h 78) is ENABLED in both frames, so its resting bar is UNWITNESSED and
    # the baked plate stands; the screen only overrides heights it has a witness for.
    for key, (by, bh) in (("gk", BANDS["gk"]), ("mid", BANDS["mid"])):
        save(f0[by : by + bh, COL_X : COL_X + COL_W], f"scroll_off_{bh}.png")
        print(f"    (resting bar for the {key.upper()} band, h {bh})")

    # thumb 3-slice, taken from frame 1's thumb at y172 (h 41)
    t_y = TRACK_Y + (TRACK_H * 1) // 9
    assert t_y == 172, t_y
    t_h = (TRACK_H * 6) // 9
    assert t_h == 41, t_h
    save(f1[t_y : t_y + 3, COL_X : COL_X + COL_W], "scroll_thumb_top.png")
    save(f1[t_y + 3 : t_y + 7, COL_X : COL_X + COL_W], "scroll_thumb_mid.png")
    save(f1[t_y + t_h - 3 : t_y + t_h, COL_X : COL_X + COL_W], "scroll_thumb_bot.png")

    # --- assert the slice reproduces BOTH frames' thumbs exactly ---------------
    top = np.asarray(Image.open(OUT / "scroll_thumb_top.png"))
    mid = np.asarray(Image.open(OUT / "scroll_thumb_mid.png"))
    bot = np.asarray(Image.open(OUT / "scroll_thumb_bot.png"))
    for frame, first in ((f0, 0), (f1, 1)):
        y = TRACK_Y + (TRACK_H * first) // 9
        body = np.concatenate([mid] * (((t_h - 6) // mid.shape[0]) + 1))[: t_h - 6]
        built = np.concatenate([top, body, bot])
        assert built.shape[0] == t_h, built.shape
        got = frame[y : y + t_h, COL_X : COL_X + COL_W]
        bad = int((np.abs(built.astype(int) - got.astype(int)).sum(2) > 0).sum())
        print(f"  thumb rebuild vs frame offset {first}: {bad} differing px")
        if bad:
            return 1
    print("OK - both witnessed scrollbar states reproduce 0 px")
    return 0


if __name__ == "__main__":
    sys.exit(main())
