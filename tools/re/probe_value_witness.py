#!/usr/bin/env python3
"""Decode the transfer-market witnessed players from EQUIPOS and print their FULL
raw record next to the source-witnessed CLUB FEE + WAGE (from the two 1997-08
TRANSFER MARKET screens: Man Utd wk2 + Barnsley wk1). Tests stored-vs-computed:
if a single stored field orders players by fee/wage, fees are stored; if not,
they are computed from attrs+age+years."""
from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(ROOT / "tools" / "re"))
import pkf_unpack as P  # noqa: E402
from equipos_parse import parse_club_tactic  # noqa: E402

GAME = ROOT / "extracted" / "Premier Manager 98"
YEAR = 1997
buf = (GAME / "DBDAT" / "EQUIPOS.PKF").read_bytes()

# name -> (fee£, wage£, AV, years) from the two source screens
W = {
    "Leese": (100000, 35000, 68, 1), "Grof": (75000, 25000, 66, 2),
    "Fulton": (150000, 5000, 64, 4), "Jobling": (25000, 10000, 54, 3),
    "Pecorari": (350000, 5000, 66, 4), "Watson": (50000, 5000, 47, 4),
    "Rivera": (150000, 20000, 67, 4), "Elias": (9500000, 500000, 80, 3),
    "Marcelle": (650000, 175000, 78, 1), "Berger": (11000000, 1000000, 88, 3),
    "Spiteri": (150000, 25000, 78, 3), "Fursth": (100000, 35000, 67, 2),
    "Urzaiz": (1500000, 175000, 79, 4), "Vega": (1000000, 25000, 72, 4),
    "Alberto": (650000, 100000, 74, 2), "Macak": (250000, 15000, 69, 4),
    "Charles": (300000, 35000, 71, 4),
    "Mora": (1500000, 125000, 75, 2), "Friedel": (750000, 150000, 70, 1),
    "Kadijevic": (150000, 30000, 73, 1), "Sevela": (125000, 5000, 63, 4),
    "Villarroya": (500000, 90000, 74, 4), "Carragher": (75000, 5000, 57, 4),
    "Roberts": (1500000, 125000, 78, 1), "Van Blerk": (90000, 25000, 68, 3),
    "Verbeeck": (250000, 15000, 67, 4), "Scholes": (8500000, 575000, 81, 4),
    "Rickers": (50000, 5000, 53, 4), "O'Brien": (25000, 15000, 66, 2),
    "Gojkovic": (850000, 35000, 71, 4), "Maniero": (1500000, 250000, 77, 1),
    "Lilley": (300000, 35000, 69, 4), "Bridges": (200000, 5000, 64, 3),
    "Wilson": (5000, 5000, 59, 1), "Martindale": (25000, 10000, 54, 4),
}
want = {k.lower(): k for k in W}

rows = []
for fname, off, size in P.files_of(buf):
    try:
        dbc_id = int(fname.upper().removeprefix("EQ96").removesuffix(".DBC"))
        r = parse_club_tactic(buf[off : off + size], dbc_id, collect=True)
    except Exception:
        continue
    club = r["name"]
    for p in r["players"]:
        nm = p["name"].strip().lower()
        if nm in want:
            a = p["attrs"]
            core4 = a[0] + a[1] + a[2] + a[3]
            allsum = sum(a)
            age = YEAR - p["year"] if p["year"] else 0
            fee, wage, av, yrs = W[want[nm]]
            rows.append((want[nm], club, a, core4, allsum, age,
                         p.get("b1a"), p.get("b16"), p.get("b17"),
                         p.get("fine"), p.get("band"), fee, wage, av, yrs))

rows.sort(key=lambda x: x[11])  # by fee
print(f"matched {len(rows)}/{len(W)} witnesses\n")
hdr = ("name", "club", "attrs(VE RE AG CA RM RG PA TI EN PO)", "c4", "cAV",
       "Σ", "age", "b1a", "b16", "b17", "fine", "bd", "FEE", "WAGE", "AVscr", "y")
print(f"{hdr[0]:11}{hdr[1]:13}{hdr[2]:34} {hdr[3]:>3} {hdr[4]:>3} {hdr[5]:>3} "
      f"{hdr[6]:>3} {hdr[7]:>4} {hdr[8]:>4} {hdr[9]:>4} {hdr[10]:>4} {hdr[11]:>3} "
      f"{hdr[12]:>9} {hdr[13]:>8} {hdr[14]:>5} {hdr[15]:>2}")
for (nm, club, a, c4, s, age, b1a, b16, b17, fine, band, fee, wage, av, yrs) in rows:
    attrs = " ".join(f"{x:2}" for x in a)
    print(f"{nm:11}{club[:12]:13}{attrs:34} {c4:3} {c4//4:3} {s:3} {age:3} "
          f"{b1a if b1a is not None else -1:4} {b16 if b16 is not None else -1:4} "
          f"{b17 if b17 is not None else -1:4} {fine:4} {band:2} {fee:9} {wage:8} {av:5} {yrs:2}")
