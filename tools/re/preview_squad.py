#!/usr/bin/env python3
"""Compose the PM98 SQUAD MANAGEMENT (PLANTILLA) screen from the cracked ORIGINAL
assets at the coordinates reversed out of MANAGER.EXE (docs/re/squad_screen_re.md).
Faithful preview of app/scenes/SquadScreen.gd on this display-less box (PIL render).
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

from fnt_to_bmfont import WINFONTS, Fnt
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "app" / "art"

C_TITLE = (232, 240, 255)
C_TEXT = (220, 230, 245)
C_DIM = (150, 175, 210)
C_HEAD = (170, 199, 235)
C_CELL = (40, 70, 120)
C_CELL_HI = (70, 110, 165)
C_CELL_LO = (20, 40, 80)
C_ROW_A = (28, 44, 78)
C_ROW_B = (22, 36, 66)
C_SECTION = (255, 223, 0)
C_NAME = (255, 255, 255)
C_BTN = (40, 110, 70)
C_BTN_HI = (70, 150, 100)

COLS = [
    ("N.", 12, "_num"),
    ("PLAYER", 38, "_name"),
    ("AGE", 168, "_age"),
    ("EN", 198, "EN"),
    ("SP", 224, "VE"),
    ("ST", 250, "RE"),
    ("AG", 276, "AG"),
    ("QU", 302, "CA"),
    ("FI", 328, "TI"),
    ("MO", 354, "RM"),
    ("AV", 386, "_avg"),
    ("POS", 420, "_pos"),
]
AVG_KEYS = ["VE", "RE", "AG", "CA", "RM", "RG", "PA", "TI"]
PANEL = (8, 48, 508, 421)
HDR_Y, ROW0_Y, ROW_H = 52, 70, 16
YOUTH_BTN = (523, 360, 112, 25)


def load_font(name):
    return Fnt((WINFONTS / name).read_bytes())


def text(canvas, fnt, s, x, y, col, right=False):
    widths, ims = [], []
    for ch in s:
        i = ord(ch) - fnt.first
        if 0 <= i < len(fnt.entries) - 1:
            w, im = fnt.glyph(i)
        else:
            w, im = (
                fnt.pix_height // 3,
                Image.new("L", (max(1, fnt.pix_height // 3), fnt.pix_height), 0),
            )
        widths.append(w)
        ims.append(im)
    total = sum(widths) + max(0, len(widths) - 1)
    if right:
        x -= total
    for w, im in zip(widths, ims):
        if w > 0:
            canvas.paste(Image.new("RGB", (w, fnt.pix_height), col), (x, y), im)
        x += w + 1
    return total


def cell(canvas, x, y, w, h, base, hi, lo):
    canvas.paste(Image.new("RGB", (w, h), base), (x, y))
    canvas.paste(Image.new("RGB", (w, 1), hi), (x, y))
    canvas.paste(Image.new("RGB", (1, h), hi), (x, y))
    canvas.paste(Image.new("RGB", (w, 1), lo), (x, y + h - 1))
    canvas.paste(Image.new("RGB", (1, h), lo), (x + w - 1, y))


def avg_of(p):
    a = p.get("attrs") or {}
    vals = [a[k] for k in AVG_KEYS if k in a]
    return round(sum(vals) / len(vals)) if vals else 0


def sections(club):
    gks = sorted((p for p in club["players"] if p.get("isGK")), key=lambda p: -avg_of(p))
    outs = sorted((p for p in club["players"] if not p.get("isGK")), key=lambda p: -avg_of(p))
    return [("GOALKEEPERS", gks), ("OUTFIELD", outs)]


def compose(out, club_name=None):
    db = json.loads((ROOT / "app" / "data" / "game_db.json").read_text())
    prem = [c for c in db["clubs"] if c.get("leagueId") == "eng_prem"]
    club = next((c for c in prem if c["name"] == club_name), None) if club_name else None
    if club is None:
        club = next(c for c in prem if len(c.get("players", [])) >= 14)

    cv = (
        Image.open(ART / "screens" / "fondo_marble.png")
        .convert("RGB")
        .resize((640, 480), Image.NEAREST)
    )
    bar = Image.open(ART / "screens" / "barra0.png").convert("RGB")
    cv.paste(bar.resize((640, bar.height), Image.NEAREST), (0, 0))
    f14, f12, f10, f8 = (
        load_font(n) for n in ("PROMAN14.FNT", "PROMAN12.FNT", "PROMAN10.FNT", "PROMAN8.FNT")
    )

    text(cv, f14, "SQUAD MANAGEMENT", 150, 13, C_TITLE)
    text(cv, f12, "Manager", 12, 10, C_TEXT)
    text(cv, f12, "A. FERGUSON", 12, 26, C_DIM)
    text(cv, f12, club["name"][:18], 628, 10, C_TEXT, right=True)

    for code, x, _ in COLS:
        if code in ("PLAYER", "N."):
            text(cv, f8, code, x, HDR_Y, C_HEAD)
        else:
            text(cv, f8, code, x + 18, HDR_Y, C_HEAD, right=True)

    y, row, number = ROW0_Y, 0, 1
    for sec, players in sections(club):
        text(cv, f8, sec, COLS[1][1], y + 2, C_SECTION)
        y += ROW_H
        for p in players:
            if y + ROW_H > PANEL[1] + PANEL[3]:
                break
            cv.paste(
                Image.new("RGB", (PANEL[2], ROW_H - 1), C_ROW_A if row % 2 == 0 else C_ROW_B),
                (PANEL[0], y),
            )
            a = p.get("attrs") or {}
            ty = y + 3
            for code, x, key in COLS:
                if key == "_num":
                    text(cv, f8, str(number), x + 16, ty, C_TEXT, right=True)
                elif key == "_name":
                    text(cv, f8, str(p.get("name", "?"))[:16], x, ty, C_NAME)
                elif key == "_age":
                    text(cv, f8, str(p.get("age", "")), x + 18, ty, C_TEXT, right=True)
                elif key == "_avg":
                    text(cv, f8, str(avg_of(p)), x + 18, ty, C_TEXT, right=True)
                elif key == "_pos":
                    text(cv, f8, "GK" if p.get("isGK") else "OUT", x, ty, C_DIM)
                else:
                    v = a.get(key)
                    text(
                        cv,
                        f8,
                        str(int(v)) if v is not None else "-",
                        x + 18,
                        ty,
                        C_TEXT,
                        right=True,
                    )
            y += ROW_H
            row += 1
            number += 1

    n = sum(1 for p in club["players"] if p.get("id", -1) >= 0)
    cell(cv, 523, 60, 112, 40, C_CELL, C_CELL_HI, C_CELL_LO)
    text(cv, f10, "SQUAD", 529, 64, C_HEAD)
    text(cv, f12, f"{n} players", 631, 78, C_TEXT, right=True)
    cell(cv, *YOUTH_BTN, C_BTN, C_BTN_HI, C_CELL_LO)
    text(cv, f10, "YOUTH TEAM", YOUTH_BTN[0] + 10, YOUTH_BTN[1] + 6, (235, 255, 240))
    cell(cv, 523, 440, 112, 25, C_CELL, C_CELL_HI, C_CELL_LO)
    text(cv, f10, "RETURN", 529, 446, C_TEXT)

    cv.save(out)
    print(f"wrote {out} (640x480) — {club['name']} SQUAD from real assets")


if __name__ == "__main__":
    compose(sys.argv[1] if len(sys.argv) > 1 else "/tmp/pm98shots/squad_preview.png")
