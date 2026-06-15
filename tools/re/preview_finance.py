#!/usr/bin/env python3
"""Compose the PM98 FINANCES (CAJA — "INCOME + EXPENSES") screen from the cracked
ORIGINAL assets at the coordinates reversed out of MANAGER.EXE (FUN_00501c2a +
FUN_00502120; docs/re/finance_screen_re.md). Faithful preview of
app/scenes/FinanceScreen.gd on this display-less box (PIL render). The ledger
amounts mirror FinanceModel.gd's projection for the chosen club.
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
C_INCOME = (92, 199, 115)
C_EXPENSE = (217, 87, 77)
C_HDR_BAR = (40, 64, 107)

HDR_BAR = (21, 51, 592, 27)
LIST = (21, 78, 592, 323)
BOX_INCOME = (8, 415, 221, 50)
BOX_EXPENSE = (241, 415, 221, 50)
BOX_BALANCE = (470, 415, 162, 50)
ROW_H = 22

# FinanceModel.gd constants (mirrored for the preview).
CAP = {1: 35000, 2: 20000, 3: 10000, 4: 5000}
FILL = {1: 0.85, 2: 0.65, 3: 0.55, 4: 0.45}
TICKET = {1: 15, 2: 12, 3: 10, 4: 8}
BOARD = {1: 1200, 2: 600, 3: 300, 4: 150}
BOARDS = {1: 60, 2: 48, 3: 36, 4: 24}
TV = {1: 8_000_000, 2: 1_200_000, 3: 450_000, 4: 220_000}
SPONSOR = {1: 5_000_000, 2: 900_000, 3: 300_000, 4: 120_000}
HOME_GAMES = {1: 19, 2: 23, 3: 23, 4: 23}
WAGE_BASE = {1: 4000, 2: 1500, 3: 700, 4: 400}
SEASON_WEEKS = 52


def player_wage(attrs, base):
    ca = float(attrs.get("CA", 45))
    mult = max(0.4, ca / 55.0) ** 1.6
    return int(round(base * mult / 100.0)) * 100


def summary(club, tier):
    cap = int(club.get("capacity") or 0) or CAP[tier]
    att = round(cap * FILL[tier])
    gate = att * TICKET[tier] * HOME_GAMES[tier]
    boards = BOARD[tier] * BOARDS[tier]
    income = gate + boards + SPONSOR[tier] + TV[tier]
    wbase = WAGE_BASE[tier]
    weekly = sum(player_wage(p.get("attrs", {}), wbase) for p in club.get("players", []))
    wages = weekly * SEASON_WEEKS
    bonus = round(gate * 0.02)
    expense = wages + bonus
    return {
        "income_lines": [
            ["TICKETS", gate],
            ["SPONSOR BOARDS SOLD", boards],
            ["SPONSORSHIP MONEY", SPONSOR[tier]],
            ["TELEVISION", TV[tier]],
        ],
        "expense_lines": [["STAFF WAGES", wages], ["BONUS", bonus]],
        "total_income": income,
        "total_expense": expense,
        "season_balance": income - expense,
    }


def fmt_money(v):
    neg = v < 0
    s = f"{abs(v):,}"
    return f"{'-' if neg else ''}£{s}"


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


def section(cv, f10, f12, title, lines, mark, y0, row0):
    y, row = y0, row0
    text(cv, f10, title, LIST[0] + 8, y + 4, C_HEAD)
    y += ROW_H
    row += 1
    for label, amt in lines:
        if y + ROW_H > LIST[1] + LIST[3]:
            break
        cv.paste(
            Image.new("RGB", (LIST[2], ROW_H - 2), C_ROW_A if row % 2 == 0 else C_ROW_B),
            (LIST[0], y),
        )
        cv.paste(Image.new("RGB", (8, 8), mark), (LIST[0] + 12, y + ROW_H // 2 - 5))
        text(cv, f12, str(label), LIST[0] + 30, y + 4, C_TEXT)
        text(cv, f12, fmt_money(int(amt)), LIST[0] + LIST[2] - 16, y + 4, C_TEXT, right=True)
        y += ROW_H
        row += 1
    return y, row


def compose(out, club_name=None):
    db = json.loads((ROOT / "app" / "data" / "game_db.json").read_text())
    prem = [c for c in db["clubs"] if c.get("leagueId") == "eng_prem"]
    club = next((c for c in prem if c["name"] == club_name), None) if club_name else None
    if club is None:
        club = next(c for c in prem if len(c.get("players", [])) >= 14)
    sm = summary(club, 1)

    cv = (
        Image.open(ART / "screens" / "fondo_marble.png")
        .convert("RGB")
        .resize((640, 480), Image.NEAREST)
    )
    bar = Image.open(ART / "screens" / "barra0.png").convert("RGB")
    cv.paste(bar.resize((640, bar.height), Image.NEAREST), (0, 0))
    f14, f12, f10 = (load_font(n) for n in ("PROMAN14.FNT", "PROMAN12.FNT", "PROMAN10.FNT"))

    text(cv, f14, "FINANCES", 120, 13, C_TITLE)
    text(cv, f12, "Manager", 12, 10, C_TEXT)
    text(cv, f12, "A. FERGUSON", 12, 26, C_DIM)
    text(cv, f12, club["name"][:18], 628, 10, C_TEXT, right=True)
    text(cv, f12, "1997-98", 628, 26, C_DIM, right=True)

    cell(cv, HDR_BAR, C_HDR_BAR, C_CELL_HI, C_CELL_LO)
    text(cv, f10, "INCOME + EXPENSES", HDR_BAR[0] + 10, HDR_BAR[1] + 7, C_TITLE)
    text(
        cv, f10, "AMOUNT (season)", HDR_BAR[0] + HDR_BAR[2] - 12, HDR_BAR[1] + 7, C_HEAD, right=True
    )

    y, row = section(cv, f10, f12, "INCOME", sm["income_lines"], C_INCOME, LIST[1] + 6, 0)
    y += 6
    section(cv, f10, f12, "EXPENDITURE", sm["expense_lines"], C_EXPENSE, y, row + 1)

    inc, exp = sm["total_income"], sm["total_expense"]
    bal = sm["season_balance"]
    cell(cv, BOX_INCOME, C_CELL, C_CELL_HI, C_CELL_LO)
    text(cv, f10, "TOTAL INCOME", BOX_INCOME[0] + 10, BOX_INCOME[1] + 6, C_INCOME)
    text(
        cv,
        f14,
        fmt_money(inc),
        BOX_INCOME[0] + BOX_INCOME[2] - 12,
        BOX_INCOME[1] + 24,
        C_TEXT,
        right=True,
    )
    cell(cv, BOX_EXPENSE, C_CELL, C_CELL_HI, C_CELL_LO)
    text(cv, f10, "TOTAL EXPENSES", BOX_EXPENSE[0] + 10, BOX_EXPENSE[1] + 6, C_EXPENSE)
    text(
        cv,
        f14,
        fmt_money(exp),
        BOX_EXPENSE[0] + BOX_EXPENSE[2] - 12,
        BOX_EXPENSE[1] + 24,
        C_TEXT,
        right=True,
    )
    cell(cv, BOX_BALANCE, C_CELL, C_CELL_HI, C_CELL_LO)
    text(cv, f10, "BALANCE", BOX_BALANCE[0] + 10, BOX_BALANCE[1] + 6, C_HEAD)
    text(
        cv,
        f14,
        fmt_money(bal),
        BOX_BALANCE[0] + BOX_BALANCE[2] - 12,
        BOX_BALANCE[1] + 24,
        C_INCOME if bal >= 0 else C_EXPENSE,
        right=True,
    )

    cv.save(out)
    print(f"wrote {out} (640x480) — {club['name']} FINANCES from real assets")


if __name__ == "__main__":
    compose(sys.argv[1] if len(sys.argv) > 1 else "/tmp/pm98shots/finance_preview.png")
