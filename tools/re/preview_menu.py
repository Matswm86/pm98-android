#!/usr/bin/env python3
"""Compose the PM98 MAIN MENU (MENUPRINCIPAL) screen from the cracked ORIGINAL
assets at the coordinates reversed out of MANAGER.EXE (FUN_005469c0;
docs/re/menu_screen_re.md).

The management hub: 12 picture icons (each with an on/off/gris state in the EXE)
laid in two vertical bands of 3 rows per side, around a central club panel + a
four-button control bar (EXIT / SAVE GAME / NEWS / CONTINUE). The grey label
slots come from RECURSOS\\...\\menuprincipal\\trozo_fondo.bmp (640x158), blitted
per band and mirrored for the right column (the menu is left-right symmetric;
trozo's left slot at x63-207 maps under the mirror to x433-577, exactly the
reversed right-label x range). Icons use the shared VGA palette (DAT.PKF+0x5ca),
index 0 transparent.

Two outputs:
  * `--bake OUT.png`  writes the STATIC 640x480 chrome (trozo + icons + captions
    + control buttons) -- this is app/art/screens/menu_bg.png, blitted whole by
    MenuScreen.gd, the same way fondo_marble.png is.
  * default          writes a full PREVIEW (chrome + a sample dynamic centre
    panel) to verify fidelity on this display-less box (the PIL render IS the
    fidelity gate; MenuScreen.gd mirrors these coordinates exactly).
"""
from __future__ import annotations

import sys
from pathlib import Path

from export_art import render
from fnt_to_bmfont import WINFONTS, Fnt
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "app" / "art"

W, H = 640, 480

# ---- reversed geometry (MANAGER.EXE FUN_005469c0) -------------------------
# Each icon: (RECURSOS entry, pos(x,y), size(w,h), caption, group). pos/size are
# the two FUN_00436fb0(x,y) points; rect = (x, y, x+w, y+h). FICHA's x is a
# register (its left-column siblings are x=6/7/10 -> 7). Captions confirmed inline
# in .data: FIXTURES/OPPONENT/STAFF/FINANCE/BOARD ROOM; the rest use the game's
# own English vocabulary (LEAGUE TABLES/LINE-UP/TACTICS/SIGN PLAYER/STADIUM).
GREEN = (200, 230, 60)    # FUN_00437020(0xc8,0xe6,0x3c) top-left group
BLUE = (127, 191, 255)    # (0x7f,0xbf,0xff) top-right group
PEACH = (255, 191, 170)   # (0xff,0xbf,0xaa) bottom-left group
GOLD = (255, 223, 85)     # (0xff,0xdf,0x55) bottom-right group

ICONS = [
    # name        pos        size       caption        colour  cap-rect(l,t,r,b)
    ("MARCA", (7, 71), (86, 60), "RESULTS", GREEN, (93, 86, 189, 110)),
    ("CLASI", (206, 93), (87, 72), "LEAGUE TABLE", GREEN, (102, 130, 206, 154)),
    ("CALEN", (10, 147), (77, 66), "FIXTURES", GREEN, (87, 174, 198, 198)),
    ("ALINE", (535, 70), (93, 61), "LINE-UP", BLUE, (440, 84, 535, 108)),
    ("TACTI", (345, 101), (93, 63), "TACTICS", BLUE, (438, 129, 524, 153)),
    ("RIVAL", (536, 151), (85, 60), "OPPONENT", BLUE, (433, 173, 536, 197)),
    ("FICHA", (7, 327), (85, 76), "SIGN PLAYER", PEACH, (85, 345, 176, 369)),
    ("VENDE", (184, 353), (101, 78), "SELL PLAYER", PEACH, (88, 387, 184, 411)),
    ("EMPLE", (6, 403), (72, 62), "STAFF", PEACH, (78, 431, 182, 455)),
    ("CAJA", (559, 328), (78, 80), "FINANCE", GOLD, (450, 346, 559, 370)),
    ("DECIS", (361, 370), (86, 61), "BOARD ROOM", GOLD, (441, 388, 555, 412)),
    ("ESTAD", (543, 415), (95, 61), "STADIUM", GOLD, (447, 430, 556, 454)),
]

# Centre control bar: (label, pos(x,y), size(w,h)). y=255, reversed.
CONTROLS = [
    ("EXIT", (6, 255), (79, 27)),
    ("SAVE GAME", (92, 255), (114, 27)),
    ("NEWS", (437, 255), (95, 27)),
    ("CONTINUE", (540, 255), (95, 27)),
]
# The four side panels flanking the centre (FUN_004b7f40 CRects).
PANELS = [(0, 215, 214, 248), (428, 215, 634, 248),
          (0, 289, 218, 322), (426, 289, 634, 322)]

TROZO_Y = (63, 321)        # top + bottom band placement of trozo_fondo (640x158)

C_PANEL = (44, 60, 92)
C_PANEL_HI = (78, 104, 150)
C_PANEL_LO = (20, 30, 56)
C_BTN = (40, 70, 120)
C_BTN_HI = (96, 132, 190)
C_BTN_LO = (16, 28, 56)
C_CTRL_TXT = (255, 255, 255)
C_TITLE = (232, 240, 255)
C_DIM = (150, 175, 210)
C_CASH = (250, 219, 115)


def load_font(name: str) -> Fnt:
    return Fnt((WINFONTS / name).read_bytes())


def text(cv, fnt, s, x, y, col, center_w=0, right=False):
    """Blit BMFont glyphs; center_w>0 centres in that width, right right-aligns."""
    widths, ims = [], []
    for ch in s:
        i = ord(ch) - fnt.first
        if 0 <= i < len(fnt.entries) - 1:
            w, im = fnt.glyph(i)
        else:
            w = fnt.pix_height // 3
            im = Image.new("L", (max(1, w), fnt.pix_height), 0)
        widths.append(w)
        ims.append(im)
    total = sum(widths) + max(0, len(widths) - 1)
    if center_w:
        x += (center_w - total) // 2
    elif right:
        x -= total
    for w, im in zip(widths, ims):
        if w > 0:
            cv.paste(Image.new("RGB", (w, fnt.pix_height), col), (x, y), im)
        x += w + 1
    return total


def cell(cv, r, base, hi, lo):
    x, y, w, h = r
    cv.paste(Image.new("RGB", (w, h), base), (x, y))
    cv.paste(Image.new("RGB", (w, 1), hi), (x, y))
    cv.paste(Image.new("RGB", (1, h), hi), (x, y))
    cv.paste(Image.new("RGB", (w, 1), lo), (x, y + h - 1))
    cv.paste(Image.new("RGB", (1, h), lo), (x + w - 1, y))


def chrome() -> Image.Image:
    """The static 640x480 menu chrome: trozo bands + icons + captions + controls."""
    cv = Image.new("RGB", (W, H), (16, 20, 36))
    trozo = render("RECURSOS.PKF", "TROZO_FONDO.BMP", force_vga=True, transparent=True)
    mirror = trozo.transpose(Image.FLIP_LEFT_RIGHT)
    for y in TROZO_Y:
        cv.paste(trozo, (0, y), trozo)
        cv.paste(mirror, (0, y), mirror)
    # side panels around the centre
    for p in PANELS:
        cell(cv, (p[0], p[1], p[2] - p[0], p[3] - p[1]), C_PANEL, C_PANEL_HI, C_PANEL_LO)
    # icons (OFF / active state) at the reversed coordinates
    for name, pos, size, _cap, _col, _cr in ICONS:
        im = render("RECURSOS.PKF", f"{name}OFF.BMP", force_vga=True,
                    transparent=True).resize(size, Image.NEAREST)
        cv.paste(im, pos, im)
    # captions centred in their reversed label rects (ProMan12)
    f12 = load_font("PROMAN12.FNT")
    for _name, _pos, _size, cap, col, cr in ICONS:
        text(cv, f12, cap, cr[0], cr[1] + 5, col, center_w=cr[2] - cr[0])
    # control bar
    f10 = load_font("PROMAN10.FNT")
    for label, pos, size in CONTROLS:
        cell(cv, (pos[0], pos[1], size[0], size[1]), C_BTN, C_BTN_HI, C_BTN_LO)
        text(cv, f10, label, pos[0], pos[1] + 8, C_CTRL_TXT, center_w=size[0])
    return cv


def centre_panel(cv, club, manager, season, cash, position):
    """Dynamic centre block (drawn by MenuScreen.gd in-engine; sample here)."""
    f14 = load_font("PROMAN14.FNT")
    f12 = load_font("PROMAN12.FNT")
    cx0, cx1 = 214, 426
    text(cv, f14, club[:20], cx0, 222, C_TITLE, center_w=cx1 - cx0)
    text(cv, f12, manager[:22], cx0, 240, C_DIM, center_w=cx1 - cx0)
    text(cv, f12, season, cx0, 290, C_DIM, center_w=cx1 - cx0)
    text(cv, f12, "£%s   -   %s" % (f"{cash:,}", position), cx0, 306, C_CASH,
         center_w=cx1 - cx0)


def main():
    args = sys.argv[1:]
    if args and args[0] == "--bake":
        out = Path(args[1]) if len(args) > 1 else ART / "screens" / "menu_bg.png"
        out.parent.mkdir(parents=True, exist_ok=True)
        chrome().save(out)
        print(f"baked {out} (640x480) - MENUPRINCIPAL chrome from real assets")
        return
    out = Path(args[0]) if args else Path("/tmp/pm98shots/menu_preview.png")
    out.parent.mkdir(parents=True, exist_ok=True)
    cv = chrome()
    centre_panel(cv, "MANCHESTER UTD.", "A. FERGUSON", "1997-98", 8_000_000, "1st")
    cv.save(out)
    print(f"wrote {out} (640x480) - MENUPRINCIPAL preview from real assets")


if __name__ == "__main__":
    main()
