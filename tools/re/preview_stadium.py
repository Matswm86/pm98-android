#!/usr/bin/env python3
"""Compose the PM98 GROUND (ESTADIO) overview screen from the cracked ORIGINAL assets
at the coordinates reversed out of MANAGER.EXE (OnDraw FUN_0051a6e0; see
docs/re/stadium_screen_re.md). Faithful PIL mirror of app/scenes/StadiumScreen.gd for
this display-less box — render PNG and Read it as the fidelity gate.

The stadium picture is one of 12 pre-rendered ESTADIO<tier>.BMP scenes (320x240, half
res), chosen by capacity: tier = clamp(capacity*11//130000, 0, 11). It fills the 640x480
client rect (reversed CRect(0,0,640,480)) at 2x. The title GROUND (150,16), the info
panel (299,73,320,73) and the 2x2 action grid IMPROVE(298,407) / WORKS(484,407) /
MATCH DAY(298,442) / RETURN(488,442) are exact-reversed overlays drawn on top.
"""

from __future__ import annotations

import sys
from pathlib import Path

from fnt_to_bmfont import WINFONTS, Fnt
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "app" / "art"

C_TITLE = (245, 247, 255)
C_TEXT = (220, 230, 245)
C_DIM = (150, 175, 210)
C_HEAD = (170, 199, 235)
C_LABEL = (160, 160, 200)          # reversed FUN_00437020 -> (160,160,200)
C_PANEL = (33, 54, 97)
C_PANEL_HI = (70, 110, 165)
C_PANEL_LO = (18, 33, 66)
C_BTN = (46, 71, 120)
C_VAL = (245, 222, 120)

# Reversed rects (left,top,w,h) from FUN_0051a6e0.
PANEL_INFO = (299, 73, 320, 73)
LBL_IMPROVE = (298, 407, 152, 25)
LBL_WORKS = (484, 407, 132, 25)
LBL_MATCHDAY = (298, 442, 152, 25)
LBL_RETURN = (488, 442, 124, 25)

MAX_CAPACITY = 130000              # tier 11 threshold (130000/11 per tier)


def tier_for(capacity: int) -> int:
    return max(0, min(11, capacity * 11 // MAX_CAPACITY))


def load_font(name):
    return Fnt((WINFONTS / name).read_bytes())


def text(cv, fnt, s, x, y, col, right=False):
    widths, ims = [], []
    for ch in s:
        i = ord(ch) - fnt.first
        if 0 <= i < len(fnt.entries) - 1:
            w, im = fnt.glyph(i)
        else:
            w, im = (fnt.pix_height // 3,
                     Image.new("L", (max(1, fnt.pix_height // 3), fnt.pix_height), 0))
        widths.append(w)
        ims.append(im)
    total = sum(widths) + max(0, len(widths) - 1)
    if right:
        x -= total
    for w, im in zip(widths, ims):
        if w > 0:
            cv.paste(Image.new("RGB", (w, fnt.pix_height), col), (x, y), im)
        x += w + 1
    return total


def panel(cv, r, base=C_PANEL):
    x, y, w, h = r
    cv.paste(Image.new("RGB", (w, h), base), (x, y))
    cv.paste(Image.new("RGB", (w, 1), C_PANEL_HI), (x, y))
    cv.paste(Image.new("RGB", (1, h), C_PANEL_HI), (x, y))
    cv.paste(Image.new("RGB", (w, 1), C_PANEL_LO), (x, y + h - 1))
    cv.paste(Image.new("RGB", (1, h), C_PANEL_LO), (x + w - 1, y))


def button(cv, f, r, label, icon=None):
    panel(cv, r, C_BTN)
    x, y, w, h = r
    tx = x + 8
    if icon is not None:
        cv.paste(icon, (tx, y + (h - icon.height) // 2), icon)
        tx += icon.width + 6
    text(cv, f, label, tx, y + 6, C_LABEL)


def compose(out, capacity=24500, seated=18000, standing=6500, parking=900):
    tier = tier_for(capacity)
    cv = Image.new("RGB", (640, 480), (0, 0, 0))
    est = Image.open(ART / "screens" / "stadium" / f"estadio{tier}.png").convert("RGB")
    cv.paste(est.resize((640, 480), Image.NEAREST), (0, 0))          # half-res backdrop, 2x
    bar = Image.open(ART / "screens" / "barra0.png").convert("RGB")
    cv.paste(bar.resize((640, bar.height), Image.NEAREST), (0, 0))   # BARRA top chrome
    f14, f10, f8 = (load_font(n) for n in ("PROMAN14.FNT", "PROMAN10.FNT", "PROMAN8.FNT"))
    sd = ART / "screens" / "stadium"
    ic_works = Image.open(sd / "obras.png").convert("RGBA")
    ic_improve = Image.open(sd / "remodela.png").convert("RGBA")
    ic_match = Image.open(sd / "diapartido.png").convert("RGBA")

    club, manager, season = "Arsenal", "A. WENGER", "1997-98"
    ground = "Highbury"

    # Title in the BARRA bar + live chrome corners.
    text(cv, f14, "GROUND", 150, 13, C_TITLE)
    text(cv, f10, "Manager", 12, 10, C_TEXT)
    text(cv, f10, manager[:18], 12, 26, C_DIM)
    text(cv, f10, club[:18], 628, 10, C_TEXT, right=True)
    text(cv, f10, season, 628, 26, C_DIM, right=True)

    # Right info panel: ground name + the capacity readout that drives the tier.
    panel(cv, PANEL_INFO)
    ix, iy = PANEL_INFO[0] + 10, PANEL_INFO[1] + 6
    text(cv, f10, ground.upper(), ix, iy, C_HEAD)
    text(cv, f8, "CAPACITY", ix, iy + 18, C_DIM)
    text(cv, f8, f"{capacity:,}", PANEL_INFO[0] + PANEL_INFO[2] - 10, iy + 18, C_VAL, right=True)
    text(cv, f8, "SEATS", ix, iy + 32, C_DIM)
    text(cv, f8, f"{seated:,}", PANEL_INFO[0] + PANEL_INFO[2] // 2 - 6, iy + 32, C_TEXT, right=True)
    text(cv, f8, "CAR PARK", PANEL_INFO[0] + PANEL_INFO[2] // 2 + 6, iy + 32, C_DIM)
    text(cv, f8, f"{parking:,}", PANEL_INFO[0] + PANEL_INFO[2] - 10, iy + 32, C_TEXT, right=True)
    text(cv, f8, f"STAND.  {standing:,}", ix, iy + 46, C_DIM)
    text(cv, f8, f"TIER {tier}/11", PANEL_INFO[0] + PANEL_INFO[2] - 10, iy + 46, C_DIM, right=True)

    # 2x2 action grid (each button + its reversed icon).
    button(cv, f10, LBL_IMPROVE, "IMPROVE", ic_improve)
    button(cv, f10, LBL_WORKS, "WORKS", ic_works)
    button(cv, f10, LBL_MATCHDAY, "MATCH DAY", ic_match)
    button(cv, f10, LBL_RETURN, "RETURN")

    cv.save(out)
    print(f"wrote {out} (640x480) — GROUND tier {tier} from real assets")


if __name__ == "__main__":
    compose(sys.argv[1] if len(sys.argv) > 1 else "/tmp/pm98shots/stadium_preview.png")
