#!/usr/bin/env python3
"""Probe: which EQUIPOS field (if any) is the per-player wage/value?

Source-truth test. The FINANCE screen witnessed three fresh-club week-1 wage
bills (export_club_economy.py provenance, walkthrough finance frames):
    Arsenal 232,692 / Aston Villa 129,326 / Bolton 39,903   (per week)
If an EQUIPOS player field F, summed over a club's VALID squad, satisfies
    sum(F) * k = anchor   for the SAME k across all three clubs,
that field IS the wage source. Never invent: report the residual honestly.
"""
from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(ROOT / "tools" / "re"))
import pkf_unpack as P  # noqa: E402
from equipos_parse import parse_club_tactic  # noqa: E402

GAME = ROOT / "extracted" / "Premier Manager 98"
ANCHORS = {"Arsenal": 232692, "Aston Villa": 129326, "Bolton W.": 39903}

buf = (GAME / "DBDAT" / "EQUIPOS.PKF").read_bytes()
entries = list(P.files_of(buf))

clubs = {}
for fname, off, size in entries:
    dbc_id = int(fname.upper().removeprefix("EQ96").removesuffix(".DBC"))
    r = parse_club_tactic(buf[off : off + size], dbc_id, collect=True)
    clubs[r["name"]] = r

# resolve anchor club names (EQUIPOS uses short forms)
print("# name resolution")
for want in ANCHORS:
    hits = [n for n in clubs if want.split()[0].lower() in n.lower()]
    print(f"  {want!r:16} -> {hits}")

# pick exact records
NAME_MAP = {}
for want in ANCHORS:
    cand = [n for n in clubs if want.split()[0].lower() in n.lower()]
    NAME_MAP[want] = cand

print("\n# available English-club names sample")
print("  ", [n for n in clubs if any(x in n for x in ("Arsenal", "Villa", "Bolton"))])


def squad_ints(rec):
    """Return per-player candidate integers over the VALID squad."""
    rows = []
    for p in rec["players"]:
        b16, b17, b1a = p["b16"], p["b17"], p["b1a"]
        attrs = p["attrs"]  # VE RE AG CA RM RG PA TI EN PO
        ca = attrs[3]
        rows.append(
            {
                "name": p["name"],
                "u16_16": b16 | (b17 << 8),  # struct +0x16 u16
                "b16": b16,
                "b17": b17,
                "b1a": b1a,
                "ca": ca,
                "ve": attrs[0],
                "sum_attr": sum(attrs),
            }
        )
    return rows


def resolve(want):
    for n in NAME_MAP[want]:
        return clubs[n], n
    return None, None


print("\n# candidate-field sums per anchor club")
data = {}
for want, anchor in ANCHORS.items():
    rec, n = resolve(want)
    if rec is None:
        print(f"  {want}: NOT FOUND")
        continue
    rows = squad_ints(rec)
    agg = {
        "u16_16": sum(r["u16_16"] for r in rows),
        "b16": sum(r["b16"] for r in rows),
        "b17": sum(r["b17"] for r in rows),
        "b1a": sum(r["b1a"] for r in rows),
        "ca": sum(r["ca"] for r in rows),
        "sum_attr": sum(r["sum_attr"] for r in rows),
        "nplayers": len(rows),
    }
    data[want] = (anchor, agg, rows)
    print(f"\n  {want} (record {n!r}, {agg['nplayers']} players) anchor={anchor:,}/wk")
    for k, v in agg.items():
        if k == "nplayers":
            continue
        ratio = anchor / v if v else 0
        print(f"    sum({k:9}) = {v:8,}   anchor/sum = {ratio:10.3f}")

print("\n# same-k test: for each candidate, is anchor/sum constant across clubs?")
cands = ["u16_16", "b16", "b17", "b1a", "ca", "sum_attr"]
for c in cands:
    ks = []
    for want in ANCHORS:
        if want not in data:
            continue
        anchor, agg, _ = data[want]
        s = agg[c]
        ks.append(anchor / s if s else 0)
    if len(ks) == 3:
        spread = (max(ks) - min(ks)) / (sum(ks) / 3) if sum(ks) else 9
        flag = "  <== CONSTANT k (WAGE SOURCE?)" if spread < 0.05 else ""
        print(f"  {c:9}: k = {[round(x,3) for x in ks]}  spread={spread:.3f}{flag}")

# dump Arsenal per-player candidate table for eyeballing
print("\n# Arsenal per-player raw candidates (first 25)")
rec, _ = resolve("Arsenal")
if rec:
    for r in squad_ints(rec)[:25]:
        print(f"  {r['name']:16} u16_16={r['u16_16']:6}  b16={r['b16']:3} b17={r['b17']:3} "
              f"b1a={r['b1a']:3} CA={r['ca']:3} VE={r['ve']:3}")
