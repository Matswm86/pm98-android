#!/usr/bin/env python3
"""Decisive test: a wage formula fit to the 2 witnessed per-player wages
(Ward core4=221->15000/yr, Frandsen core4=316->175000/yr, both age 27) is
cross-validated against the 3 witnessed club week-1 wage bills.

Anchors (yearly = weekly x 52):
  Bolton  39,903/wk -> 2,074,956/yr
  Villa  129,326/wk -> 6,724,952/yr
  Arsenal 232,692/wk -> 12,099,984/yr
If the per-player formula ALSO sums to these, it is the real curve (not a fit)."""
from __future__ import annotations

import math
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(ROOT / "tools" / "re"))
import pkf_unpack as P  # noqa: E402
from equipos_parse import parse_club_tactic  # noqa: E402

GAME = ROOT / "extracted" / "Premier Manager 98"
buf = (GAME / "DBDAT" / "EQUIPOS.PKF").read_bytes()
clubs = {}
for fname, off, size in P.files_of(buf):
    dbc_id = int(fname.upper().removeprefix("EQ96").removesuffix(".DBC"))
    r = parse_club_tactic(buf[off : off + size], dbc_id, collect=True)
    clubs[r["name"]] = r

ANCHOR_YR = {"Bolton W": 2_074_956, "Aston Villa": 6_724_952, "Arsenal": 12_099_984}


def core4(p):
    a = p["attrs"]
    return a[0] + a[1] + a[2] + a[3]


# --- exponential in core4 through the 2 witnessed points ---
c1, w1 = 221, 15000
c2, w2 = 316, 175000
B = (w2 / w1) ** (1 / (c2 - c1))
A = w1 / B**c1
print(f"# exp fit: w = {A:.4f} * {B:.6f}^core4   (per-point growth {100*(B-1):.2f}%)")
print(f"  check Ward={A*B**221:.0f} (15000) Frandsen={A*B**316:.0f} (175000)")

print("\n# club-bill cross-check (exp-in-core4)")
for club, anchor in ANCHOR_YR.items():
    s = sum(A * B ** core4(p) for p in clubs[club]["players"])
    print(f"  {club:12} predicted {s:12,.0f}  anchor {anchor:12,}  ratio {s/anchor:5.2f}")

# --- power law in core4 through the 2 points ---
p_exp = math.log(w2 / w1) / math.log(c2 / c1)
Ap = w1 / c1**p_exp
print(f"\n# power fit: w = {Ap:.4g} * core4^{p_exp:.3f}")
for club, anchor in ANCHOR_YR.items():
    s = sum(Ap * core4(p) ** p_exp for p in clubs[club]["players"])
    print(f"  {club:12} predicted {s:12,.0f}  anchor {anchor:12,}  ratio {s/anchor:5.2f}")

# --- report each club's core4 distribution so we can see the shape ---
print("\n# core4 lists")
for club in ANCHOR_YR:
    cs = sorted(core4(p) for p in clubs[club]["players"])
    print(f"  {club:12} n={len(cs):2} min {cs[0]} max {cs[-1]} mean {sum(cs)/len(cs):.0f}")
