#!/usr/bin/env python3
"""Gather full attrs+age for the anchor clubs and the 2 witnessed wages, to test
a derive-and-VALIDATE wage formula (not a blind fit)."""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(ROOT / "tools" / "re"))
import pkf_unpack as P  # noqa: E402
from equipos_parse import ATTR_NAMES, parse_club_tactic  # noqa: E402

GAME = ROOT / "extracted" / "Premier Manager 98"
YEAR = 1997  # season start
buf = (GAME / "DBDAT" / "EQUIPOS.PKF").read_bytes()

clubs = {}
for fname, off, size in P.files_of(buf):
    dbc_id = int(fname.upper().removeprefix("EQ96").removesuffix(".DBC"))
    r = parse_club_tactic(buf[off : off + size], dbc_id, collect=True)
    clubs[r["name"]] = r

WITNESS = {"Ward": 15000, "Frandsen": 175000}  # yearly £, insurance modal frames 35-38


def show(club):
    rec = clubs[club]
    print(f"\n## {club} ({len(rec['players'])} players)")
    print(f"  {'name':16} {'VE RE AG AG CA RM RG PA TI EN PO':32} core4 age  witnessYr")
    for p in rec["players"]:
        a = p["attrs"]
        core4 = a[0] + a[1] + a[2] + a[3]
        age = YEAR - p["year"] if p["year"] else 0
        w = WITNESS.get(p["name"], "")
        print(f"  {p['name']:16} {' '.join(f'{x:2}' for x in a):32} {core4:5} {age:3}  {w}")


for c in ("Bolton W", "Arsenal", "Aston Villa"):
    show(c)
