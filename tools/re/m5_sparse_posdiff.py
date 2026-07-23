#!/usr/bin/env python3
"""Sparse-sample positional differ: port tick dump vs a free-run (periodic) silicon capture.

Usage: m5_sparse_posdiff.py <port_posdump.txt> <oracle.jsonl> [max_ord] [clk_lo]

m5_orbit_posdiff.py aligns by LCG draw ordinal but assumes an oracle row for EVERY draw
(the Z2 dartwatch capture): it walks PORT ticks and asks whether any oracle sample in the
tick's draw window matches, so a window that is empty or straddles a boundary reports a
phantom fork. m5_freerun_poll.py trades that density for stability (periodic sampling),
which breaks that assumption.

This differ inverts the direction and only compares where the comparison is exact. The
port dump records END-OF-TICK positions plus the cumulative draw count O_T per tick, so a
silicon sample is directly comparable iff its draw ordinal equals some O_T exactly --
then both sides describe the same instant. Mid-tick samples are skipped, not guessed at
(positions move several times within one clk, which is why clk-label alignment fails).

Reports the first ordinal where an exactly-aligned comparison disagrees.
"""

import json
import re
import sys

SEED0 = 0xEA0D2A8D
PORT = sys.argv[1]
ORC = sys.argv[2]
MAX_ORD = int(sys.argv[3]) if len(sys.argv) > 3 else 20000
CLK_LO = int(sys.argv[4]) if len(sys.argv) > 4 else 0


def orbit(n: int) -> dict:
    """post-draw seed value -> draw ordinal from frame0."""
    idx = {}
    s = SEED0
    for i in range(1, n + 1):
        s = (s * 214013 + 2531011) & 0xFFFFFFFF
        idx.setdefault(s, i)
    return idx


def load_port():
    """[(clk, cumulative_ordinal, {(team, idx): (x, y)})] in tick order."""
    ticks = []
    clk = None
    nd = 0
    cur = {}
    with open(PORT) as fh:
        port_lines = fh.readlines()
    for ln in port_lines:
        if ln.startswith("clk="):
            if clk is not None:
                ticks.append((clk, nd, cur))
            clk = int(ln.split("clk=")[1].split()[0])
            m = re.search(r"draws=\[(.*)\]", ln)
            nd = 0 if not m or not m.group(1).strip() else m.group(1).count('"') // 2
            cur = {}
        elif ln.startswith("   PL ") and clk is not None:
            f = ln.split()
            cur[(int(f[1]), int(f[2]))] = (int(f[3]), int(f[4]))
    if clk is not None:
        ticks.append((clk, nd, cur))
    out = []
    tot = 0
    for clk, nd, cur in ticks:
        tot += nd
        out.append((clk, tot, cur))
    return out


def main():
    idx = orbit(MAX_ORD)
    ticks = load_port()
    by_ord = {o: (clk, cur) for clk, o, cur in ticks if cur}
    print(f"port ticks={len(ticks)} (ordinals {ticks[0][1]}..{ticks[-1][1]})")

    aligned, forks = [], []
    n_samples = n_mapped = 0
    with open(ORC) as fh:
        orc_lines = fh.readlines()
    for ln in orc_lines:
        d = json.loads(ln)
        if "pl" not in d or "seed" not in d or d.get("clk", -1) < CLK_LO:
            continue
        n_samples += 1
        o = idx.get(d["seed"])
        if o is None:
            continue
        n_mapped += 1
        hit = by_ord.get(o)
        if hit is None:
            continue  # mid-tick sample: no end-of-tick port state to compare against
        pclk, pcur = hit
        smp = {(r[0], r[1]): (r[2], r[3]) for r in d["pl"]}
        bad = [pk for pk, xy in smp.items() if pk in pcur and pcur[pk] != xy]
        aligned.append((o, d["clk"], pclk, bad, smp, pcur))
        if bad:
            forks.append((o, d["clk"], bad))

    print(f"oracle samples={n_samples} orbit-mapped={n_mapped} exactly-aligned={len(aligned)}")
    if not aligned:
        print("NO EXACT ALIGNMENTS — sampling too sparse; capture denser near the target clk")
        return
    ok = len(aligned) - len(forks)
    lo = min(a[1] for a in aligned)
    hi = max(a[1] for a in aligned)
    print(f"aligned clk span {lo}..{hi}; MATCH {ok}/{len(aligned)}\n")

    if not forks:
        print(f"NO FORKS at any exactly-aligned point up to clk {hi} — port == silicon")
        return
    print(f"first {min(10, len(forks))} forking ordinals:")
    for o, clk, bad in forks[:10]:
        print(f"  ord {o} clk {clk}: {len(bad)} players {bad[:6]}")
    o, clk, bad, smp, pcur = (*forks[0][:2], forks[0][2], None, None)
    for a in aligned:
        if a[0] == forks[0][0]:
            smp, pcur = a[4], a[5]
    print(f"\nFIRST FORK ord={o} clk={clk}")
    for pk in bad[:8]:
        print(f"  t{pk[0]}.i{pk[1]}: silicon={smp[pk]}  port={pcur[pk]}")


if __name__ == "__main__":
    main()
