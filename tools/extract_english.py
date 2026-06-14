#!/usr/bin/env python3
"""Extract the 92 English-league club squads from EQUIPOS.PKF.

The English records (Copyright-marker records idx 38-129: Premier + Div 1/2/3)
use an EXTENDED per-player layout, NOT the compact Spanish/Italian one:

    [career history: |SEASON|CLUB|pos|apps| ... repeated]
    [u16 len][shortname cipher]      e.g. "BECKHAM"
    [u16 len][fullname  cipher]      e.g. "DAVID ROBERT BECKHAM"
    [short field block ~6-14 bytes]
    [u16 birthYear]                  1940-1985  (anchor)
    [flag byte >=0x80]
    [u16 len][birthplace cipher]     e.g. "GLADSAXE" (Schmeichel)
    [u16 len][prev club  cipher]     e.g. "BRONDBY H"
    [u16 len][nationality cipher]    e.g. "DENMARK"
    [bio prose, cipher English]      (long for stars, absent for youth/fringe)

This differs from the Spanish compact record `[year][flag][media][10 attrs][01]`
where the 10 attributes sit at Y+4. For English records Y+4 is the *birthplace*
string; the attribute row instead sits in a per-player block (`6c 6b` season marker
+ 10 attrs VE..PO + 0x01) after the player's bio. We pair each birth-year anchor
with the attribute block that follows it. Cross-validated: names + birth years
exact for the real 97-98 squads (full Man Utd incl. Beckham/Scholes/Giggs/Keane),
and the goalkeeping (PO) attribute separates keepers from outfielders cleanly -
Schmeichel 91, Seaman 92, James 84, Van der Gouw 77, vs outfielders 8-21. ~94% of
players get an attribute row (the rest, mostly the last player in sparse Div-3
records, fall back to `attrs: null`).

Output: assets/squads_english.json
"""

from __future__ import annotations

import json
import struct
from pathlib import Path

GAME = Path(__file__).resolve().parent.parent / "extracted" / "Premier Manager 98"
OUT = Path(__file__).resolve().parent.parent / "assets" / "squads_english.json"
COPY = b"Copyright (c)1996 Dinamic Multimedia"
MM = b"Dinamic Multimedia"

# English clubs are the contiguous run of Copyright records between Italy Serie A
# and Borussia Dortmund (the first continental dense record). Derived, not guessed:
# idx 38 = Blackburn (gap jumps 2 KB -> 71 KB), idx 130 = Borussia D (gap back to
# ~1.5 KB). 92 clubs == Premier(20)+Div1(24)+Div2(24)+Div3(24).
ENG_FIRST, ENG_LAST = 38, 129

_FWD = {L: (L if L % 2 == 0 else L + 2) for L in range(26)}
C2 = {c: chr(65 + L) for L, c in _FWD.items()}
C2[1] = " "
ACCENT = {
    0x80: "Á",
    0x86: "Ç",
    0x88: "É",
    0x8C: "Í",
    0x8E: "Ï",
    0x90: "Ñ",
    0x92: "Ó",
    0x9B: "Ú",
    0x9D: "Ö",
    0x84: "Ü",
    0xCB: "ª",
}
SEP = "\x1f"  # 0x4d, the legal/common name separator


def ch(b: int) -> str:
    if b == 0x4D:
        return SEP
    if b == 0x4F:
        return "."
    if b >= 0x80:
        return ACCENT.get(b & 0xDF, "+")
    return C2.get(b & 0x1F, "?")


def isstr(b: int) -> bool:
    return b <= 0x5F or b >= 0x80


def rdstr(d: bytes, p: int, maxlen: int = 40):
    """Read a [u16 len][cipher] string at p; None if not a plausible name/word."""
    if p + 2 > len(d):
        return None
    ln = struct.unpack_from("<H", d, p)[0]
    if not (2 <= ln <= maxlen) or p + 2 + ln > len(d):
        return None
    raw = d[p + 2 : p + 2 + ln]
    if not all(isstr(b) for b in raw):
        return None
    if sum(b == 0x00 for b in raw) > 0.45 * ln:
        return None
    txt = "".join(ch(b) for b in raw)
    if "?" in txt or "+" in txt:
        return None
    if sum(c.isalpha() or c == " " for c in txt) < 0.6 * len(txt):
        return None
    return txt.strip(), p + 2 + ln


def record_offsets(d: bytes):
    out, i = [], 0
    while True:
        j = d.find(COPY, i)
        if j < 0:
            break
        out.append(j)
        i = j + 1
    return out


def header(d: bytes, off: int):
    """name / stadium / fullName / manager from the record header."""
    e = d.find(MM, off, off + 80)
    if e < 0:
        return [], off
    p = e + len(MM) + 6
    strings = []
    while len(strings) < 4:
        r = rdstr(d, p, 40)
        if not r:
            break
        strings.append(r[0])
        p = r[1]
    return strings, p


def find_anchors(d: bytes, lo: int, hi: int):
    """Candidate birth-year anchors for the EXTENDED English record: a u16 year in
    1940-1985 followed by a flag byte >=0x80. The real filter is name_before()
    succeeding (a length-prefixed short+full name ending just before the anchor) -
    coincidental u16s in bio/career text don't have a clean name in front of them."""
    out = []
    for Y in range(lo, hi - 6):
        year = struct.unpack_from("<H", d, Y)[0]
        if not (1940 <= year <= 1985):
            continue
        if d[Y + 2] < 0x80:
            continue
        out.append(Y)
    return out


ATTR_NAMES = ["VE", "RE", "AG", "CA", "RM", "RG", "PA", "TI", "EN", "PO"]


def find_attr_blocks(d: bytes, lo: int, hi: int):
    """Per-player attribute rows. Each is a `6c 6b` (season) marker followed by the
    10 attribute bytes (VE RE AG CA RM RG PA TI EN PO, all 1-99) then a terminator:
    `0x01` + a record-id byte for normal players, or `0x00` for the LAST player in a
    record (no id - the next club's Copyright marker follows). One block per player,
    after the player's bio. Validated: senior GKs (Schmeichel PO=91, Van der Gouw 77,
    Seaman 92) vs outfielders (PO 8-21); youth GKs PO 80-85; Beckham (last in Man Utd,
    0x00 term) = [90,85,85,90,86,95,90,88,72,11]. Same VE..PO order as the Spanish row."""
    out = []
    i = lo
    while True:
        j = d.find(b"\x6c\x6b", i, hi)
        if j < 0:
            break
        w = list(d[j + 2 : j + 12])
        term = d[j + 12] if j + 12 < len(d) else 0xFF
        # 0x01 = normal player (record-id byte follows). 0x00 = LAST player in the
        # record - only legitimate when the block abuts the next club's marker (hi);
        # accepting 0x00 anywhere lets stray bio-text `6c 6b` runs false-positive.
        if len(w) == 10 and all(1 <= b <= 99 for b in w):
            if term == 0x01 or (term == 0x00 and j + 13 >= hi - 1):
                out.append((j, w))
        i = j + 2
    return out


def name_before(d: bytes, lo: int, Y: int):
    """Forward-parse [u16 len][short][u16 len][full] ending just before the small
    field block that precedes the birth year Y. Several header alignments can fit;
    pick the one with the most total name text (the real, full name - spurious
    alignments start mid-name and are shorter)."""
    best = None
    best_len = -1
    for h in range(max(lo, Y - 90), Y):
        s = rdstr(d, h, 22)
        if not s:
            continue
        f = rdstr(d, s[1], 48)
        if f and 2 <= Y - f[1] <= 18:
            tot = len(s[0]) + len(f[0])
            if tot > best_len:
                best, best_len = (h, s[0], f[0]), tot
        elif 2 <= Y - s[1] <= 18:
            if len(s[0]) > best_len:
                best, best_len = (h, "", s[0]), len(s[0])
    return best


def split_name(short_txt: str, full_txt: str):
    short_txt = short_txt.replace(SEP, " ").strip()
    if SEP in full_txt:
        legal, _, common = full_txt.partition(SEP)
        legal, common = legal.strip(), common.strip()
    else:
        legal, common = full_txt.strip(), short_txt
    display = common or short_txt or legal
    return display, legal


def parse_club(d: bytes, off: int, end: int):
    strings, num_off = header(d, off)
    anchors = find_anchors(d, num_off, end)
    attr_blocks = find_attr_blocks(d, num_off, end)
    players = []
    prev_end = num_off
    seen = set()
    for k, Y in enumerate(anchors):
        nb = name_before(d, prev_end, Y)
        prev_end = Y + 3
        if not nb:
            continue
        display, legal = split_name(nb[1], nb[2])
        if not display or len(display) < 2:
            continue
        year = struct.unpack_from("<H", d, Y)[0]
        key = (display, year)
        if key in seen:
            continue
        seen.add(key)
        # the player's attribute row is the attr block between this anchor and the
        # next one (it follows the player's bio, before the next player's record).
        nxt = anchors[k + 1] if k + 1 < len(anchors) else end
        row = next((w for j, w in attr_blocks if Y < j < nxt), None)
        players.append(
            {
                "name": display,
                "legalName": legal,
                "birthYear": year,
                "age": 1998 - year,
                "isGK": bool(row) and row[9] > 50,
                "attrs": dict(zip(ATTR_NAMES, row)) if row else None,
            }
        )
    return strings, players


def main():
    d = (GAME / "DBDAT/EQUIPOS.PKF").read_bytes()
    offs = record_offsets(d)
    clubs = []
    for n in range(ENG_FIRST, ENG_LAST + 1):
        off = offs[n]
        end = offs[n + 1] if n + 1 < len(offs) else len(d)
        strings, players = parse_club(d, off, end)
        clubs.append(
            {
                "idx": n,
                "name": strings[0] if strings else "?",
                "stadium": strings[1] if len(strings) > 1 else "",
                "fullName": strings[2] if len(strings) > 2 else "",
                "manager": strings[3] if len(strings) > 3 else "",
                "players": players,
            }
        )
    tot = sum(len(c["players"]) for c in clubs)
    wattr = sum(1 for c in clubs for p in c["players"] if p["attrs"])
    OUT.write_text(
        json.dumps(
            {
                "note": "92 English-league club squads (Premier + Div 1/2/3) from "
                "EQUIPOS.PKF, extended-layout records. Per player: name, legalName, "
                "birthYear, age, isGK, and attrs (VE RE AG CA RM RG PA TI EN PO, each "
                "1-99; see docs/FORMATS.md). ~94% of players carry an attribute row; "
                "the rest (mostly the last player in sparse Div-3 records) have "
                "attrs: null. Cross-validated vs the real 97-98 squads: full Man Utd "
                "incl. Beckham/Scholes/Giggs/Keane, and GK ratings (Schmeichel PO=91, "
                "Seaman 92, James 84) vs outfielders (PO 8-21).",
                "clubs": clubs,
            },
            indent=2,
            ensure_ascii=False,
        )
    )
    print(f"English: {len(clubs)} clubs, {tot} players, {wattr} with attrs -> {OUT}")
    # spot-check
    for c in clubs:
        if c["name"].startswith("MANCHESTER UTD"):
            print(f"  Man Utd: {len(c['players'])} players")
            for star in ["SCHMEICHEL", "BECKHAM", "SCHOLES", "GIGGS", "KEANE"]:
                hit = next((p for p in c["players"] if star in p["name"]), None)
                po = hit["attrs"]["PO"] if hit and hit["attrs"] else None
                print(
                    f"    {star}: {'OK ' + repr(hit['name']) + f' PO={po}' if hit else 'MISSING'}"
                )


if __name__ == "__main__":
    main()
