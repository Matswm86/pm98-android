#!/usr/bin/env python3
"""Compose the PM98 LINE-UP (ALINEACIÓN) screen from the cracked ORIGINAL assets at
the EXACT coordinates reversed out of MANAGER.EXE (see docs/re/lineup_screen_re.md).
This is a faithful preview of the in-app Godot screen (app/scenes/LineupScreen.gd):
same FONDO/BARRA chrome, PROMAN font, the squad-list column x's, and the CAMPO
mini-pitch with the 11 XI kit markers placed by the engine's own mapping
    marker = pitch.origin + (tac_x*148/318, tac_y*88/198).
Used to verify fidelity on this display-less box (PIL render, not in-engine capture).
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
C_SECTION = (128, 128, 128)
C_NAME = (255, 255, 255)

# --- reversed layout (mirror of LineupScreen.gd) ---------------------------
COLS = [
    ("N.", 25, "_num"),
    ("PLAYER", 63, "_name"),
    ("EN", 166, "EN"),
    ("SP", 191, "VE"),
    ("ST", 216, "RE"),
    ("AG", 240, "AG"),
    ("QU", 266, "CA"),
    ("FI", 293, "TI"),
    ("MO", 317, "RM"),
    ("AV", 342, "_avg"),
    ("ROL", 364, "_rol"),
    ("POS", 394, "_pos"),
]
AVG_KEYS = ["VE", "RE", "AG", "CA", "RM", "RG", "PA", "TI"]
ROW_X, ROW_W, ROW_H, XI_Y0 = 21, 411, 16, 17
SUBS_HDR_Y, SUBS_Y0, MAX_SUBS = 204, 220, 5
CAMPO_POS = (480, 250)
MARK_ORIGIN = (482, 252)
MARK_W, MARK_H, TAC_W, TAC_H = 148.0, 88.0, 318.0, 198.0
FORMS = {"5-3-2": [5, 3, 2], "4-4-2": [4, 4, 2], "4-3-3": [4, 3, 3], "3-5-2": [3, 5, 2]}
KIT_SRC = (0, 0, 31, 64)
_KIT_CACHE: dict[int, Image.Image | None] = {}


def load_font(name: str) -> Fnt:
    return Fnt((WINFONTS / name).read_bytes())


def text(canvas, fnt, s, x, y, col, right=False, center=False):
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
    elif center:
        x -= total // 2
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


def kit(cid):
    if cid not in _KIT_CACHE:
        p = ROOT / "app" / "art" / "kits" / f"{cid}.png"
        _KIT_CACHE[cid] = Image.open(p).convert("RGBA").crop(KIT_SRC) if p.exists() else None
    return _KIT_CACHE[cid]


def draw_kit_centered(canvas, cid, cx, cy, box_w, box_h):
    im = kit(cid)
    if im is None:
        canvas.paste(Image.new("RGB", (10, 12), C_TITLE), (int(cx - 5), int(cy - 6)))
        return
    s = min(box_w / im.width, box_h / im.height)
    w, h = max(1, round(im.width * s)), max(1, round(im.height * s))
    im2 = im.resize((w, h), Image.NEAREST)
    canvas.paste(im2, (int(cx - w / 2), int(cy - h / 2)), im2)


def avg_of(p):
    a = p.get("attrs") or {}
    vals = [a[k] for k in AVG_KEYS if k in a]
    return round(sum(vals) / len(vals)) if vals else 0


def slot_positions(form):
    lines = FORMS.get(form, FORMS["4-4-2"])
    cols = {"GK": 20.0, "DEF": 90.0, "MID": 175.0, "FWD": 262.0}
    out = [(cols["GK"], TAC_H * 0.5)]
    for role, n in (("DEF", lines[0]), ("MID", lines[1]), ("FWD", lines[2])):
        for k in range(n):
            t = (k + 0.5) / n
            y = TAC_H * 0.16 + (TAC_H * 0.84 - TAC_H * 0.16) * t
            out.append((cols[role], y))
    return out


def mark_center(tac):
    return (MARK_ORIGIN[0] + tac[0] * MARK_W / TAC_W, MARK_ORIGIN[1] + tac[1] * MARK_H / TAC_H)


def pick_xi(club, form="4-4-2"):
    lines = FORMS[form]
    players = club.get("players", [])
    gks = sorted(
        (p for p in players if p.get("isGK")),
        key=lambda p: -(p.get("attrs", {}) or {}).get("PO", 0),
    )
    outs = sorted((p for p in players if not p.get("isGK")), key=lambda p: -avg_of(p))
    xi = [gks[0]] if gks else []
    xi += outs[: sum(lines)]
    return xi


def compose(out, club_name=None):
    db = json.loads((ROOT / "app" / "data" / "game_db.json").read_text())
    prem = [c for c in db["clubs"] if c.get("leagueId") == "eng_prem"]
    club = next((c for c in prem if c["name"] == club_name), None) if club_name else None
    if club is None:
        club = next(c for c in prem if len(c.get("players", [])) >= 14)
    form = "4-4-2"
    xi = pick_xi(club, form)
    xi_ids = {p["id"] for p in xi}

    cv = (
        Image.open(ART / "screens" / "fondo_marble.png")
        .convert("RGB")
        .resize((640, 480), Image.NEAREST)
    )
    bar = Image.open(ART / "screens" / "barra0.png").convert("RGB")
    cv.paste(bar.resize((640, bar.height), Image.NEAREST), (0, 0))
    f24, f12, f10, f8 = (
        load_font(n) for n in ("PROMAN24.FNT", "PROMAN12.FNT", "PROMAN10.FNT", "PROMAN8.FNT")
    )

    text(cv, f24, "LINE-UP", 176, 14, C_TITLE, center=True)
    text(cv, f12, "Manager", 12, 10, C_TEXT)
    text(cv, f12, "A. FERGUSON", 12, 26, C_DIM)
    text(cv, f12, club["name"][:18], 628, 10, C_TEXT, right=True)
    text(cv, f12, "Premier", 628, 26, C_DIM, right=True)

    for code, x, _ in COLS:
        text(cv, f8, code, x, 56, C_HEAD)

    roles = ["GK"] + ["DEF"] * FORMS[form][0] + ["MID"] * FORMS[form][1] + ["FWD"] * FORMS[form][2]

    def row(y, alt, p, number, rol):
        cv.paste(Image.new("RGB", (ROW_W, ROW_H - 1), C_ROW_A if alt else C_ROW_B), (ROW_X, y))
        a = p.get("attrs") or {}
        ty = y + 3
        for code, x, key in COLS:
            if key == "_num":
                text(cv, f8, str(number), x + 18, ty, C_TEXT, right=True)
            elif key == "_name":
                text(cv, f8, str(p.get("name", "?"))[:14], x, ty, C_NAME)
            elif key == "_avg":
                text(cv, f8, str(avg_of(p)), x + 18, ty, C_TEXT, right=True)
            elif key == "_rol":
                text(cv, f8, rol, x, ty, C_DIM)
            elif key == "_pos":
                text(cv, f8, "GK" if p.get("isGK") else "OUT", x, ty, C_DIM)
            else:
                v = a.get(key)
                text(cv, f8, str(int(v)) if v is not None else "-", x + 18, ty, C_TEXT, right=True)

    for i, p in enumerate(xi):
        row(XI_Y0 + 14 + i * ROW_H, i % 2 == 0, p, i + 1, roles[i] if i < len(roles) else "")

    rest = sorted((p for p in club["players"] if p["id"] not in xi_ids), key=lambda p: -avg_of(p))
    text(cv, f8, "SUBSTITUTES", ROW_X, SUBS_HDR_Y, C_SECTION)
    bench = rest[:MAX_SUBS]
    for j, p in enumerate(bench):
        row(SUBS_Y0 + 14 + j * ROW_H, j % 2 == 0, p, 12 + j, "GK" if p.get("isGK") else "OUT")
    res_hdr_y = SUBS_Y0 + 14 + len(bench) * ROW_H + 6
    text(cv, f8, "RESERVES", ROW_X, res_hdr_y, C_SECTION)
    ry0 = res_hdr_y + 16
    maxr = (480 - 10 - ry0) // ROW_H
    for j, p in enumerate(rest[MAX_SUBS : MAX_SUBS + maxr]):
        row(ry0 + j * ROW_H, j % 2 == 0, p, MAX_SUBS + 12 + j, "GK" if p.get("isGK") else "OUT")

    # Right: panel header + CAMPO mini-pitch + XI markers.
    cell(cv, 476, 119, 156, 22, C_CELL, C_CELL_HI, C_CELL_LO)
    text(cv, f10, form, 476 + 78, 122, C_TITLE, center=True)
    campo = Image.open(ART / "screens" / "campo.png").convert("RGB")
    cv.paste(campo, CAMPO_POS)
    pos = slot_positions(form)
    for i, _p in enumerate(xi[: len(pos)]):
        cx, cy = mark_center(pos[i])
        draw_kit_centered(cv, club["id"], cx, cy, 11, 14)
        text(cv, f8, str(i + 1), int(cx), int(cy + 6), C_NAME, center=True)

    cv.save(out)
    print(f"wrote {out} (640x480) — {club['name']} {form} from real assets")


if __name__ == "__main__":
    compose(sys.argv[1] if len(sys.argv) > 1 else "/tmp/pm98shots/lineup_preview.png")
