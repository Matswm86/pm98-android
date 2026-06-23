#!/usr/bin/env python3
"""Extract team records + full squads from EQUIPOS.PKF (PC Fútbol / PM98 engine).

Writes two files:
  assets/squads_laliga.json  - the 20 SIG-indexed Spanish Primera 97-98 squads
                               (533 players, fully verified vs reality).
  assets/teams_all.json      - ALL 476 detailed team records found via the
                               Copyright marker; 281 with dense squads = 5654 players.

Per-player record (forward-parsed, verified vs the real Barcelona 97-98 squad):
    [3-byte player header]
    [u16 len][shortname  cipher]    e.g. "FIGO" / "V+TOR BA+A"
    [u16 len][fullname   cipher]    e.g. "LUIS FILIPE MADEIRA CAEIRO<sep>FIGO"
    [variable padding + 6 field bytes]
    [u16 birthYear][flag][media? u8][10 attrs u8][01 terminator]

attrs (always at Y+4..Y+13): VE RE AG CA RM RG PA TI EN PO  (see docs/FORMATS.md).
media (Y+3) is present only when flag >= 0xA0; for 0x80-0x9f flags Y+3 is a pad
and media is null (derive in-engine). Cipher: ch(b)=alphabet[b&0x1f]; 0x41/0x01=
space, 0x4f='.', 0x4d=<sep>, b>=0x80 accented (see ACCENT). Robust anchor:
birthYear u16 in 1950-1983 immediately followed by the squad flag byte >=0x80.
"""

from __future__ import annotations

import json
import struct
from pathlib import Path

GAME = Path(__file__).resolve().parent.parent / "extracted" / "Premier Manager 98"
OUT = Path(__file__).resolve().parent.parent / "assets" / "squads_laliga.json"
OUT_ALL = Path(__file__).resolve().parent.parent / "assets" / "teams_all.json"
SIG = bytes.fromhex("9a919abe5f68")
MM = b"Dinamic Multimedia"
COPY = b"Copyright (c)1996 Dinamic Multimedia"  # marks every detailed team record
ATTR_NAMES = ["VE", "RE", "AG", "CA", "RM", "RG", "PA", "TI", "EN", "PO"]
# Demarcación byte three bytes before the birth-year anchor: 0=GK 1=DF 2=MF 3=FW.
# Same field as the English extended records (see docs/re/positions_re.md); clean 0-3
# partition that reproduces a real squad's keepers/defence/midfield/attack (Barcelona).
POS_NAMES = {0: "GK", 1: "DF", 2: "MF", 3: "FW"}

_FWD = {L: (L if L % 2 == 0 else L + 2) for L in range(26)}
C2 = {c: chr(65 + L) for L, c in _FWD.items()}
C2[1] = " "
# accented letters: byte = 0x80 | (0x20 word-start flag) | accent-code; clear bit5
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
SEP = "\x1f"  # marker for 0x4d, the legal-name / common-name separator


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
    """Read a [u16 len][cipher] string at p; None if not a plausible name."""
    if p + 2 > len(d):
        return None
    ln = struct.unpack_from("<H", d, p)[0]
    if not (2 <= ln <= maxlen) or p + 2 + ln > len(d):
        return None
    raw = d[p + 2 : p + 2 + ln]
    if not all(isstr(b) for b in raw):
        return None
    if sum(b == 0x00 for b in raw) > 0.45 * ln:  # reject null-padding garbage
        return None
    txt = "".join(ch(b) for b in raw)
    if "?" in txt or "+" in txt:  # unmapped codes/accents = field-byte misreads
        return None
    if sum(c.isalpha() or c == " " for c in txt) < 0.6 * len(txt):
        return None
    return txt.strip(), p + 2 + ln


def index_offsets(d: bytes):
    out, i = [], 0
    while True:
        j = d.find(SIG, i)
        if j < 0:
            break
        out.append(
            (struct.unpack_from("<I", d, j - 1 + 26)[0], struct.unpack_from("<I", d, j - 1 + 30)[0])
        )
        i = j + 1
    return out


def team_strings(d: bytes, off: int):
    """Team name/stadium/fullname/manager + offset where the numeric block begins."""
    e = d.find(MM, off, off + 80)
    if e < 0:
        return None, off
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
    """Validated birth-year anchors: year 1950-83, flag>=0x80, sane media+attrs."""
    out = []
    for Y in range(lo, hi - 14):
        year = struct.unpack_from("<H", d, Y)[0]
        if not (1950 <= year <= 1983):
            continue
        if d[Y + 2] < 0x80:  # squad flag byte
            continue
        slot = d[Y + 3]  # media (0xa0+ flag) or pad (0x8c flag)
        attrs = d[Y + 4 : Y + 14]
        if slot > 99 or any(a > 99 for a in attrs) or not any(attrs):
            continue
        if d[Y + 14] not in (0x00, 0x01):  # terminator
            continue
        out.append(Y)
    return out


def parse_squad(d: bytes, off: int, end: int):
    strings, num_off = team_strings(d, off)
    anchors = find_anchors(d, num_off, end)
    players = []
    prev_end = num_off

    def name_fields(lo, Y):
        """Forward-parse [u16][short][u16][full] with exact length prefixes, using
        the year anchor Y as oracle. Among all header alignments whose full name
        ends in the field-block window before Y, pick the one ending CLOSEST to Y
        (the real name ends right before the small field block)."""
        for h in range(lo, Y):
            s = rdstr(d, h, 20)
            if not s:
                continue
            f = rdstr(d, s[1], 50)  # two-field shape: short then full
            if f and 0 <= Y - f[1] <= 30:
                return (f[1], s[0], f[0])
            if 0 <= Y - s[1] <= 30:  # single-field fallback (no short)
                return (s[1], "", s[0])
        return None

    for Y in anchors:
        nf = name_fields(prev_end, Y)
        short = (0, 0, nf[1]) if nf else None
        full = (0, nf[0], nf[2]) if nf else None
        # attrs always at Y+4..Y+13; the media byte at Y+3 is present when the squad
        # flag is >=0xa0 (0xa0-0xc3 observed). For 0x80-0x9f flags (e.g. 0x8c) Y+3
        # is a 0x01 pad and media isn't stored here -> null (engine derives it).
        flag = d[Y + 2]
        media = d[Y + 3] if flag >= 0xA0 else None
        attrs = list(d[Y + 4 : Y + 14])
        year = struct.unpack_from("<H", d, Y)[0]
        full_txt = full[2] if full else ""
        short_txt = (short[2] if short else "").replace(SEP, " ").strip()
        # fullname field may pack "LEGAL<sep>COMMON"; split it
        if SEP in full_txt:
            legal, _, common = full_txt.partition(SEP)
            legal, common = legal.strip(), common.strip()
        else:
            legal, common = full_txt.strip(), short_txt
        display = common or short_txt or legal
        pos = POS_NAMES.get(d[Y - 3]) if Y - 3 >= 0 else None
        # Fine position byte at Y-12 (the in-memory player+0x18 the stat engine reads as
        # the scorer-roulette POS_WEIGHT index, loader FUN_00583bd0). Cross-validated to
        # a clean role partition (GK->1/w0, central striker->9/w35) in docs/re/positions_re.md.
        fine = d[Y - 12] if Y - 12 >= 0 and d[Y - 12] < 19 else None
        players.append(
            {
                "name": display,
                "legalName": legal,
                "birthYear": year,
                "age": 1998 - year,
                "media": media,
                "pos": pos,
                "posFine": fine,
                "attrs": dict(zip(ATTR_NAMES, attrs)),
                "isGK": pos == "GK" if pos else attrs[9] > 50,
            }
        )
        prev_end = Y + 15
    return strings, players


def record_offsets(d: bytes):
    """Every detailed team record starts with the Copyright marker (476 total)."""
    out, i = [], 0
    while True:
        j = d.find(COPY, i)
        if j < 0:
            break
        out.append(j)
        i = j + 1
    return out


def parse_record(d: bytes, off: int, end: int):
    strings, players = parse_squad(d, off, end)
    return {
        "name": strings[0] if strings else "?",
        "stadium": strings[1] if len(strings) > 1 else "",
        "fullName": strings[2] if len(strings) > 2 else "",
        "manager": strings[3] if len(strings) > 3 else "",
        "players": players,
    }


def main():
    d = (GAME / "DBDAT/EQUIPOS.PKF").read_bytes()
    offs = record_offsets(d)

    # --- all 476 detailed team records (headers always reliable) ---
    all_teams = []
    for n, off in enumerate(offs):
        end = offs[n + 1] if n + 1 < len(offs) else len(d)
        gap = end - off
        rec = parse_record(d, off, end)
        # squad is dense+complete only in the contiguous block (small gap)
        rec["idx"] = n
        rec["squadComplete"] = gap < 4000 and len(rec["players"]) >= 14
        all_teams.append(rec)
    complete = [t for t in all_teams if t["squadComplete"]]
    tot = sum(len(t["players"]) for t in complete)
    OUT_ALL.write_text(
        json.dumps(
            {
                "note": "All 476 detailed team records in EQUIPOS.PKF (found via the Copyright "
                "marker, not the 20-entry SIG index). Headers (name/stadium/fullName/"
                "manager) are reliable for ALL. squadComplete=True for the records with "
                "a dense inline squad (Spain Primera + Italy Serie A + most continental "
                "leagues). Player attrs (10 skills) are reliable everywhere; `media` is "
                "null for the 0x8c-flag player subtype (common in lower/foreign leagues) "
                "where it is not stored in the record — derive it in-engine. English-"
                "league clubs have reliable headers but SPARSE squads interleaved with "
                "English bio text (squadComplete=False) — their squad framing is TODO.",
                "teams": all_teams,
            },
            indent=2,
            ensure_ascii=False,
        )
    )
    print(
        f"ALL: {len(all_teams)} team records, {len(complete)} with complete squads "
        f"({tot} players) -> {OUT_ALL}"
    )

    # --- verified La Liga subset (the 20 SIG-indexed Primera records) ---
    laliga = []
    for n, (off, sz) in enumerate(index_offsets(d)):
        strings, players = parse_squad(d, off, off + sz)
        laliga.append(
            {
                "idx": n,
                "name": strings[0] if strings else "?",
                "stadium": strings[1] if len(strings) > 1 else "",
                "players": players,
            }
        )
    OUT.write_text(
        json.dumps(
            {"note": "20 Primera 97-98 squads from EQUIPOS.PKF", "teams": laliga},
            indent=2,
            ensure_ascii=False,
        )
    )
    lt = sum(len(t["players"]) for t in laliga)
    print(f"LaLiga: {len(laliga)} teams, {lt} players -> {OUT}")


if __name__ == "__main__":
    main()
