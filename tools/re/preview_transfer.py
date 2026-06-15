#!/usr/bin/env python3
"""Compose the PM98 TRANSFER MARKET (FICHAR) screen from the cracked ORIGINAL
assets at the coordinates reversed out of MANAGER.EXE (FUN_00532a50;
docs/re/transfer_screen_re.md). Faithful preview of app/scenes/TransferScreen.gd
on this display-less box (PIL render). The buyable list mirrors
TransferMarket.gd's market() valuation for the chosen division.
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
C_SECTION = (120, 140, 160)
C_NAME = (255, 255, 255)
C_FEE = (250, 219, 115)
C_KEY = (255, 222, 0)
C_BTN = (40, 70, 120)
C_BTN_HI = (70, 110, 165)
C_RETURN = (207, 162, 165)

PANEL = (8, 48, 490, 387)
HDR_Y = 52
ROW0_Y = 70
ROW_H = 16
COLS = [
    ("", 12, False), ("NAME", 26, False), ("AGE", 168, True), ("AB", 200, True),
    ("CLUB FEE", 318, True), ("YR WAGE", 408, True), ("CLUB", 414, False),
]
BANK_BOX = (512, 48, 120, 44)
BTN_CURRENT = (512, 286, 120, 25)
BTN_SCOUT = (512, 323, 120, 25)
BTN_OFFERS = (512, 360, 120, 25)
BTN_RETURN = (512, 440, 120, 25)

# TransferMarket.gd constants (mirrored for the preview valuation).
TIER_FEE = {1: 915000.0, 2: 320000.0, 3: 110000.0, 4: 45000.0}
CA_PIVOT = 50.0
CA_POW = 4.0
KEY_PREMIUM = 1.6
MIN_FEE = 25000
WAGE_BASE = {1: 4000, 2: 1500, 3: 700, 4: 400}
SEASON_WEEKS = 52


def age_factor(age):
    if age <= 0:
        return 1.0
    if age <= 20:
        return 0.85
    if age <= 23:
        return 0.95
    if age <= 28:
        return 1.0
    if age <= 30:
        return 0.80
    if age <= 32:
        return 0.55
    return 0.35


def round_fee(v, tier):
    step = 50000 if tier <= 2 else 5000
    return max(MIN_FEE, int(round(v / step)) * step)


def value_of(p, tier):
    attrs = p.get("attrs") or {}
    ca = float(attrs.get("CA", 45))
    age = int(p.get("age", 26))
    raw = TIER_FEE[tier] * (ca / CA_PIVOT) ** CA_POW * age_factor(age)
    return round_fee(raw, tier)


def player_wage(attrs, base):
    ca = float(attrs.get("CA", 45))
    mult = max(0.4, ca / 55.0) ** 1.6
    return int(round(base * mult / 100.0)) * 100


def wage_yearly(p, tier):
    return player_wage(p.get("attrs") or {}, WAGE_BASE[tier]) * SEASON_WEEKS


def fmt_money(v):
    neg = v < 0
    return f"{'-' if neg else ''}£{abs(v):,}"


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


def cell(canvas, r, base, hi, lo):
    x, y, w, h = r
    canvas.paste(Image.new("RGB", (w, h), base), (x, y))
    canvas.paste(Image.new("RGB", (w, 1), hi), (x, y))
    canvas.paste(Image.new("RGB", (1, h), hi), (x, y))
    canvas.paste(Image.new("RGB", (w, 1), lo), (x, y + h - 1))
    canvas.paste(Image.new("RGB", (1, h), lo), (x + w - 1, y))


KEEP_CAP = 5


def nav_btn(cv, f, r, label, col):
    cell(cv, r, C_BTN, C_BTN_HI, C_CELL_LO)
    text(cv, f, label, r[0] + 10, r[1] + 8, col)


def build_market(db, my_id, tier):
    """Every buyable player across the other clubs, dearest first."""
    names = {c["id"]: c["name"] for c in db["clubs"]}
    out = []
    for c in db["clubs"]:
        if c["id"] == my_id or c.get("leagueId") != "eng_prem":
            continue
        for p in c.get("players", []):
            if int(p.get("id", -1)) < 0:
                continue
            attrs = p.get("attrs") or {}
            out.append({
                "name": p.get("name", "?"), "isGK": bool(p.get("isGK")),
                "ca": int(attrs.get("CA", 0)), "age": int(p.get("age", 0)),
                "club_name": names.get(c["id"], "?"),
                "fee": value_of(p, tier), "wage": wage_yearly(p, tier),
                "key": int(attrs.get("CA", 0)) >= 70,
            })
    out.sort(key=lambda r: r["fee"], reverse=True)
    return out


def sections(rows):
    gks = [r for r in rows if r["isGK"]][:KEEP_CAP]
    outs = [r for r in rows if not r["isGK"]]
    return [("KEEPERS", gks), ("OUTFIELD", outs)]


def compose(out, club_name=None):
    db = json.loads((ROOT / "app" / "data" / "game_db.json").read_text())
    prem = [c for c in db["clubs"] if c.get("leagueId") == "eng_prem"]
    me = next((c for c in prem if c["name"] == club_name), None) if club_name else None
    if me is None:
        me = next(c for c in prem if len(c.get("players", [])) >= 14)
    market = build_market(db, me["id"], 1)

    cv = (
        Image.open(ART / "screens" / "fondo_marble.png")
        .convert("RGB")
        .resize((640, 480), Image.NEAREST)
    )
    bar = Image.open(ART / "screens" / "barra0.png").convert("RGB")
    cv.paste(bar.resize((640, bar.height), Image.NEAREST), (0, 0))
    f14, f12, f10, f8 = (load_font(n) for n in
        ("PROMAN14.FNT", "PROMAN12.FNT", "PROMAN10.FNT", "PROMAN8.FNT"))

    text(cv, f14, "TRANSFER MARKET", 150, 13, C_TITLE)
    text(cv, f12, "Manager", 12, 10, C_TEXT)
    text(cv, f12, "A. FERGUSON", 12, 26, C_DIM)
    text(cv, f12, me["name"][:18], 500, 10, C_TEXT, right=True)
    text(cv, f12, "1997-98", 500, 26, C_DIM, right=True)

    for code, x, right in COLS:
        if code:
            text(cv, f8, code, x, HDR_Y, C_HEAD, right=right)

    y, row = ROW0_Y, 0
    for name, players in sections(market):
        if not players:
            continue
        if y + ROW_H > PANEL[1] + PANEL[3]:
            break
        text(cv, f8, name, COLS[1][1], y + 2, C_SECTION)
        y += ROW_H
        for r in players:
            if y + ROW_H > PANEL[1] + PANEL[3]:
                text(cv, f8, "...more (bid via the menu)", COLS[1][1], y + 2, C_DIM)
                break
            cv.paste(
                Image.new("RGB", (PANEL[2], ROW_H - 1), C_ROW_A if row % 2 == 0 else C_ROW_B),
                (PANEL[0], y),
            )
            if r["key"]:
                text(cv, f8, "*", 12, y + 2, C_KEY)
            text(cv, f8, r["name"][:16], COLS[1][1], y + 2, C_NAME)
            text(cv, f8, str(r["age"]), COLS[2][1], y + 2, C_TEXT, right=True)
            text(cv, f8, str(r["ca"]), COLS[3][1], y + 2, C_TEXT, right=True)
            text(cv, f8, fmt_money(r["fee"]), COLS[4][1], y + 2, C_FEE, right=True)
            text(cv, f8, fmt_money(r["wage"]), COLS[5][1], y + 2, C_TEXT, right=True)
            text(cv, f8, r["club_name"][:12], COLS[6][1], y + 2, C_DIM)
            y += ROW_H
            row += 1
        else:
            continue
        break

    cell(cv, BANK_BOX, C_CELL, C_CELL_HI, C_CELL_LO)
    text(cv, f10, "BANK", BANK_BOX[0] + 8, BANK_BOX[1] + 6, C_HEAD)
    text(cv, f12, fmt_money(8_000_000), BANK_BOX[0] + BANK_BOX[2] - 8, BANK_BOX[1] + 24,
         C_FEE, right=True)
    nav_btn(cv, f8, BTN_CURRENT, "CURRENT OFFERS", C_HEAD)
    nav_btn(cv, f10, BTN_SCOUT, "SCOUT", C_TEXT)
    nav_btn(cv, f10, BTN_OFFERS, "OFFERS", C_TEXT)
    nav_btn(cv, f10, BTN_RETURN, "RETURN", C_RETURN)
    text(cv, f8, "Transfer window: OPEN   -   3 offers left this week",
         PANEL[0] + 4, PANEL[1] + PANEL[3] + 6, C_DIM)

    cv.save(out)
    print(f"wrote {out} (640x480) - {me['name']} TRANSFER MARKET from real assets")


if __name__ == "__main__":
    compose(sys.argv[1] if len(sys.argv) > 1 else "/tmp/pm98shots/transfer_preview.png")
