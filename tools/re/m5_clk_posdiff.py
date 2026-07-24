#!/usr/bin/env python3
"""Per-CLOCK full-roster differ: port tick dump vs a Z2-stopped silicon capture.

Usage: m5_clk_posdiff.py <port_posdump.txt> <dartwatch.jsonl> [clk_lo] [clk_hi]

WHY (s54): `m5_sparse_posdiff.py` / `m5_orbit_posdiff.py` align by LCG draw ORDINAL. Inside one
tick the sim moves players several times between draws, so an ordinal-aligned pair can name two
different instants of the same tick and report a fork whose two printed coordinates are equal
(seen on the s53 capture at clk 630: four "forking" players, identical x/y on both sides).

A Z2-stopped dartwatch capture carries several stops per clk, and the LAST stop of a clk is the
settled end-of-tick roster — the same instant the port dump records. Comparing those is exact and
needs no skew model, so this differ reports the first clk at which any player's (x, y) differs.

Port dump: `diag_m5_dart209.gd` (PM98_TICK_CAP / PM98_CLK_LO / PM98_CLK_HI).
"""

import json
import sys
from pathlib import Path


def load_port(path: str) -> dict:
    out: dict = {}
    clk = None
    for ln in Path(path).read_text(errors="ignore").splitlines():
        if ln.startswith("clk="):
            clk = int(ln.split("clk=")[1].split()[0])
            out[clk] = {}
        elif ln.startswith("   PL ") and clk is not None:
            f = ln.split()
            out[clk][(int(f[1]), int(f[2]))] = (int(f[3]), int(f[4]))
    return out


def load_silicon(path: str) -> dict:
    """clk -> roster from the LAST stop of that clk (settled end of tick)."""
    out: dict = {}
    for ln in Path(path).read_text().splitlines():
        ln = ln.strip()
        if not ln:
            continue
        d = json.loads(ln)
        if not isinstance(d, dict) or "pl" not in d:
            continue
        out[d["clk"]] = {(r[0], r[1]): (r[2], r[3]) for r in d["pl"]}
    return out


def main() -> None:
    port = load_port(sys.argv[1])
    sil = load_silicon(sys.argv[2])
    lo = int(sys.argv[3]) if len(sys.argv) > 3 else min(sil)
    hi = int(sys.argv[4]) if len(sys.argv) > 4 else max(sil)
    clks = [c for c in sorted(sil) if lo <= c <= hi and c in port]
    print(f"# comparing {len(clks)} clks in [{lo}, {hi}] (settled end-of-tick roster)")
    first = None
    for c in clks:
        bad = [k for k in sil[c] if k in port[c] and sil[c][k] != port[c][k]]
        tag = "OK " if not bad else f"FORK {len(bad)}: {sorted(bad)[:6]}"
        print(f"  clk {c}: {tag}")
        if bad and first is None:
            first = c
            for k in sorted(bad)[:6]:
                print(f"      {k}: silicon={sil[c][k]} port={port[c][k]}")
    print(
        f"\nFIRST FORK clk = {first}"
        if first
        else f"\nNO FORK in [{lo}, {hi}] — {len(clks)} clks match"
    )


if __name__ == "__main__":
    main()
