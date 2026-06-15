#!/usr/bin/env python3
"""Compose the PM98 BOARD OF DIRECTORS (DIRECTIVA) screen from the cracked ORIGINAL
assets at the coordinates reversed out of MANAGER.EXE (FUN_0050c350 + the bar widget
FUN_0050b580; docs/re/directiva_screen_re.md). Faithful PIL mirror of
app/scenes/DirectivaScreen.gd for this display-less box — render PNG and Read it as
the fidelity gate. The three confidence values are sample/derived (see RE doc).
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
C_TRACK = (18, 28, 51)
C_GOOD = (92, 199, 115)
C_MID = (235, 199, 77)
C_BAD = (217, 87, 77)
C_BTN = (46, 71, 120)

R_MANAGER = (47, 107, 251, 42)
BAR_RATING = (349, 107, 256, 42)
BAR_SUPPORT = (311, 162, 294, 57)
BAR_DIRECT = (6, 156, 291, 64)
PANEL_MSG = (16, 263, 364, 122)
PANEL_INFO = (388, 263, 237, 102)
LBL_INFO = (355, 433, 132, 25)
LBL_RETURN = (515, 433, 112, 25)


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


def meter_color(v):
    return C_GOOD if v >= 60 else (C_MID if v >= 35 else C_BAD)


def meter(cv, f10, f8, box, title, value, icon):
    panel(cv, box)
    x, y, w, h = box
    ix = x + 6
    inner_x = ix
    if icon is not None:
        iy = y + (h - icon.height) // 2
        cv.paste(icon, (ix, iy), icon)
        inner_x = ix + icon.width + 8
    text(cv, f10, title, inner_x, y + 6, C_HEAD)
    tx = inner_x
    tw = x + w - inner_x - 10
    ty = y + h - 18
    cv.paste(Image.new("RGB", (tw, 10), C_TRACK), (tx, ty))
    fw = int(tw * (value / 100.0))
    if fw > 0:
        cv.paste(Image.new("RGB", (fw, 10), meter_color(value)), (tx, ty))
    text(cv, f8, f"{value}%", tx + tw, ty - 11, C_TEXT, right=True)


def wrap(cv, fnt, s, x, y, w, col):
    if not s:
        return
    lh = fnt.pix_height + 2
    line = ""
    for word in s.split():
        probe = word if not line else line + " " + word
        if text_width(fnt, probe) > w and line:
            text(cv, fnt, line, x, y, col)
            y += lh
            line = word
        else:
            line = probe
    if line:
        text(cv, fnt, line, x, y, col)


def text_width(fnt, s):
    total = 0
    for ch in s:
        i = ord(ch) - fnt.first
        if 0 <= i < len(fnt.entries) - 1:
            total += fnt.glyph(i)[0] + 1
        else:
            total += fnt.pix_height // 3 + 1
    return total


def fmt_money(v):
    return f"{'-' if v < 0 else ''}£{abs(v):,}"


def compose(out, directors=72, supporters=58, rating=64):
    cv = (Image.open(ART / "screens" / "fondo_marble.png").convert("RGB")
          .resize((640, 480), Image.NEAREST))
    bar = Image.open(ART / "screens" / "barra0.png").convert("RGB")
    cv.paste(bar.resize((640, bar.height), Image.NEAREST), (0, 0))
    f14, f10, f8 = (load_font(n) for n in ("PROMAN14.FNT", "PROMAN10.FNT", "PROMAN8.FNT"))
    d = ART / "screens" / "directiva"
    ic_direct = Image.open(d / "directiva.png").convert("RGBA")
    ic_public = Image.open(d / "publico.png").convert("RGBA")
    ic_info = Image.open(d / "infomanager.png").convert("RGBA")

    club, manager, season, cash = "Arsenal", "A. WENGER", "1997-98", 4_250_000
    objective = "Finish in the top 5 and reach the cup quarter-finals."
    record, position = "8-3-2", "3rd"

    text(cv, f14, "BOARD OF DIRECTORS", 150, 13, C_TITLE)
    text(cv, f10, "Manager", 12, 10, C_TEXT)
    text(cv, f10, manager[:18], 12, 26, C_DIM)
    text(cv, f10, club[:18], 628, 10, C_TEXT, right=True)
    text(cv, f10, season, 628, 26, C_DIM, right=True)

    panel(cv, R_MANAGER)
    text(cv, f10, "MANAGER", R_MANAGER[0] + 10, R_MANAGER[1] + 6, C_TITLE)
    text(cv, f10, manager[:22], R_MANAGER[0] + 10, R_MANAGER[1] + 22, C_DIM)

    meter(cv, f10, f8, BAR_RATING, "MANAGER RATING", rating, None)
    meter(cv, f10, f8, BAR_SUPPORT, "SUPPORTERS CONFIDENCE", supporters, ic_public)
    meter(cv, f10, f8, BAR_DIRECT, "DIRECTORS CONFIDENCE", directors, ic_direct)

    panel(cv, PANEL_MSG)
    text(cv, f10, "THE BOARD EXPECTS", PANEL_MSG[0] + 10, PANEL_MSG[1] + 8, C_HEAD)
    wrap(cv, f10, objective, PANEL_MSG[0] + 10, PANEL_MSG[1] + 30, PANEL_MSG[2] - 20, C_TEXT)

    panel(cv, PANEL_INFO)
    text(cv, f10, "YOUR RECORD", PANEL_INFO[0] + 10, PANEL_INFO[1] + 8, C_HEAD)
    text(cv, f10, f"Position: {position}", PANEL_INFO[0] + 10, PANEL_INFO[1] + 32, C_TEXT)
    text(cv, f10, f"Record: {record}", PANEL_INFO[0] + 10, PANEL_INFO[1] + 50, C_TEXT)
    text(cv, f10, f"Bank: {fmt_money(cash)}", PANEL_INFO[0] + 10, PANEL_INFO[1] + 68, C_TEXT)

    panel(cv, LBL_INFO, C_BTN)
    info_x = LBL_INFO[0] + 8
    cv.paste(ic_info, (info_x, LBL_INFO[1] + (LBL_INFO[3] - ic_info.height) // 2), ic_info)
    info_x += ic_info.width + 6
    text(cv, f10, "MANAGER INFO", info_x, LBL_INFO[1] + 6, C_LABEL)
    panel(cv, LBL_RETURN, C_BTN)
    text(cv, f10, "RETURN", LBL_RETURN[0] + LBL_RETURN[2] // 2 - 24, LBL_RETURN[1] + 6, C_LABEL)

    cv.save(out)
    print(f"wrote {out} (640x480) — BOARD OF DIRECTORS from real assets")


if __name__ == "__main__":
    compose(sys.argv[1] if len(sys.argv) > 1 else "/tmp/pm98shots/directiva_preview.png")
