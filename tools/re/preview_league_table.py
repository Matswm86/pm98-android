#!/usr/bin/env python3
"""Compose the PM98 LEAGUE TABLES screen from the cracked ORIGINAL assets, with a
real computed standings table. This is a faithful preview of the in-app Godot screen
(same background, BARRA chrome, PROMAN font and beveled cell scheme), used to verify
fidelity against the original screenshot before/while wiring the engine UI.

All chrome is real game art (RECURSOS FONDO/BARRA + WINFONTS PROMAN). Layout + the
beveled stat cells are reconstructed to match the original LEAGUE TABLES screen.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

from PIL import Image
from fnt_to_bmfont import WINFONTS, Fnt

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "app" / "art"

# Palette-accurate colours lifted from the original screen.
C_TITLE = (232, 240, 255)
C_TEXT = (220, 230, 245)
C_DIM = (150, 175, 210)
C_CELL = (40, 70, 120)      # blue stat cell
C_CELL_HI = (70, 110, 165)  # top-left bevel
C_CELL_LO = (20, 40, 80)    # bottom-right bevel
C_PTS = (150, 40, 30)       # points cell (red)
C_PTS_HI = (200, 80, 60)
C_ROW_A = (28, 44, 78)
C_ROW_B = (22, 36, 66)
C_PROMO = (40, 110, 70)
C_RELEG = (130, 45, 40)


def load_font(name: str) -> Fnt:
    return Fnt((WINFONTS / name).read_bytes())


def text(canvas: Image.Image, fnt: Fnt, s: str, x: int, y: int, col, right=False):
    widths, ims = [], []
    for ch in s:
        i = ord(ch) - fnt.first
        if 0 <= i < len(fnt.entries) - 1:
            w, im = fnt.glyph(i)
        else:
            w, im = fnt.pix_height // 3, Image.new("L", (max(1, fnt.pix_height // 3), fnt.pix_height), 0)
        widths.append(w)
        ims.append(im)
    total = sum(widths) + max(0, len(widths) - 1)
    if right:
        x -= total
    solid = Image.new("RGB", (1, 1), col)
    for w, im in zip(widths, ims):
        if w > 0:
            tile = Image.new("RGB", (w, fnt.pix_height), col)
            canvas.paste(tile, (x, y), im)
        x += w + 1
    return total


def cell(canvas, x, y, w, h, base, hi, lo):
    canvas.paste(Image.new("RGB", (w, h), base), (x, y))
    canvas.paste(Image.new("RGB", (w, 1), hi), (x, y))
    canvas.paste(Image.new("RGB", (1, h), hi), (x, y))
    canvas.paste(Image.new("RGB", (w, 1), lo), (x, y + h - 1))
    canvas.paste(Image.new("RGB", (1, h), lo), (x + w - 1, y))


def background() -> Image.Image:
    bg = Image.open(ART / "screens" / "fondo_blue.png").convert("RGB")
    return bg.resize((640, 480), Image.NEAREST)


def standings(seed: int = 7):
    db = json.loads((ROOT / "app" / "data" / "game_db.json").read_text())
    prem = [c for c in db["clubs"] if c.get("leagueId") == "eng_prem"]
    ATK = {"CA": 0.28, "RM": 0.18, "TI": 0.16, "RG": 0.16, "PA": 0.12, "VE": 0.10}
    DEF = {"EN": 0.34, "CA": 0.24, "AG": 0.18, "RE": 0.12, "VE": 0.12}

    def rating(c):
        outs = []
        gk = 52
        for p in c.get("players", []):
            a = p.get("attrs") or {}
            if not a:
                continue
            if p.get("isGK"):
                gk = max(gk, a.get("PO", 0))
            else:
                atk = sum(a.get(k, 0) * w for k, w in ATK.items())
                dfn = sum(a.get(k, 0) * w for k, w in DEF.items())
                outs.append((atk, dfn, 0.5 * atk + 0.5 * dfn))
        outs.sort(key=lambda t: -t[2])
        xi = outs[:10] or [(50, 50, 50)]
        return (sum(t[0] for t in xi) / len(xi), sum(t[1] for t in xi) / len(xi), gk)

    rng = __import__("random").Random(seed)
    tbl = {c["id"]: {"name": c["name"], "P": 0, "W": 0, "D": 0, "L": 0, "GF": 0, "GA": 0, "Pts": 0}
           for c in prem}
    R = {c["id"]: rating(c) for c in prem}
    ids = [c["id"] for c in prem]
    for h in ids:  # single round-robin = a real half-season table (~19 games)
        for a in ids:
            if h == a:
                continue
            ga = R[h][0] - (0.65 * R[a][1] + 0.35 * R[a][2]) + 6
            gd = R[a][0] - (0.65 * R[h][1] + 0.35 * R[h][2])
            hg = max(0, round(1.4 + ga * 0.03 + rng.uniform(-1, 1)))
            ag = max(0, round(1.1 + gd * 0.03 + rng.uniform(-1, 1)))
            for cid, gf, gaa in ((h, hg, ag), (a, ag, hg)):
                t = tbl[cid]
                t["P"] += 1
                t["GF"] += gf
                t["GA"] += gaa
                t["Pts"] += 3 if gf > gaa else (1 if gf == gaa else 0)
                t["W"] += gf > gaa
                t["D"] += gf == gaa
                t["L"] += gf < gaa
    rows = sorted(tbl.values(), key=lambda r: (-r["Pts"], -(r["GF"] - r["GA"]), -r["GF"], r["name"]))
    return rows


def compose(out: str):
    cv = background()
    bar = Image.open(ART / "screens" / "barra0.png").convert("RGB")
    cv.paste(bar.resize((640, bar.height), Image.NEAREST), (0, 0))
    f24 = load_font("PROMAN24.FNT")
    f18 = load_font("PROMAN18.FNT")
    f12 = load_font("PROMAN12.FNT")

    text(cv, f24, "LEAGUE TABLES", 215, 14, C_TITLE)
    text(cv, f12, "Manager", 12, 10, C_TEXT)
    text(cv, f12, "MANCHESTER UTD.", 12, 26, C_DIM)
    text(cv, f12, "Premier", 560, 10, C_TEXT)
    text(cv, f12, "Week 19", 560, 26, C_DIM)

    # Panel header
    text(cv, f18, "PREMIER LEAGUE", 16, 70, C_TITLE)
    text(cv, f12, "1997-98", 470, 76, C_DIM)

    # Column headers
    cols = [("P", 348), ("W", 380), ("D", 412), ("L", 444), ("GF", 480), ("GA", 516), ("PTS", 560)]
    hy = 96
    text(cv, f12, "POS", 16, hy, C_DIM)
    text(cv, f12, "TEAM", 60, hy, C_DIM)
    for label, x in cols:
        text(cv, f12, label, x, hy, C_DIM, right=True)

    rows = standings()
    n = len(rows)
    y0, rh = 112, 17
    for i, r in enumerate(rows):
        y = y0 + i * rh
        cv.paste(Image.new("RGB", (612, rh - 1), C_ROW_A if i % 2 == 0 else C_ROW_B), (14, y))
        # zone tag
        if i < 5:
            cv.paste(Image.new("RGB", (3, rh - 1), C_PROMO), (14, y))
        elif i >= n - 3:
            cv.paste(Image.new("RGB", (3, rh - 1), C_RELEG), (14, y))
        text(cv, f12, str(i + 1), 36, y + 2, C_TEXT, right=True)
        text(cv, f12, r["name"][:18], 60, y + 2, C_TEXT)
        for (key, x), val in zip([("P", 348), ("W", 380), ("D", 412), ("L", 444),
                                  ("GF", 480), ("GA", 516)], [r["P"], r["W"], r["D"], r["L"], r["GF"], r["GA"]]):
            cell(cv, x - 26, y + 1, 24, rh - 3, C_CELL, C_CELL_HI, C_CELL_LO)
            text(cv, f12, str(val), x - 4, y + 2, C_TEXT, right=True)
        cell(cv, 560 - 28, y + 1, 28, rh - 3, C_PTS, C_PTS_HI, C_CELL_LO)
        text(cv, f12, str(r["Pts"]), 560 - 4, y + 2, (255, 235, 220), right=True)

    # RETURN button (green) bottom-right
    cell(cv, 548, 452, 84, 22, C_PROMO, (70, 150, 100), (20, 60, 40))
    text(cv, f12, "RETURN", 560, 457, (235, 255, 240))

    cv.save(out)
    print(f"wrote {out} (640x480) from real assets + live table")


if __name__ == "__main__":
    compose(sys.argv[1] if len(sys.argv) > 1 else "/tmp/pm98shots/league_preview.png")
