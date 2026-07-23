#!/usr/bin/env python3
"""Skew-aware positional differ: port tick dump vs a free-run (periodic) silicon capture.

Usage: m5_skewaware_posdiff.py <port_posdump.txt> <oracle_freerun.jsonl>
                               [max_ord] [clk_lo] [skew_ticks]

WHY THIS EXISTS (s49): m5_sparse_posdiff.py reports the first *disagreement* as the first
fork. That is wrong, and it cost s48 a false conclusion ("clk 636, players t1.i9 + t1.i10").
m5_freerun_poll.py's atomicity guard re-reads the seed and the clock after the roster and
keeps the sample only if neither moved -- but positions are NOT part of that guard, and the
sim moves players several times between two LCG draws. So a free-run sample can carry
positions up to about one movement step away from the instant its seed ordinal names.

That skew is measured, not assumed. Comparing the two independent silicon captures
(oracle_dartwatch_s47a_300_588.jsonl, which is Z2-stopped and therefore instant-exact,
against oracle_freerun_s48d_0_760.jsonl) over their 130 common ordinals gives 5 of 2860
player-samples disagreeing -- and in every one of those 5 the free-run value is *verbatim*
the dartwatch value at ordinal +-1 (t1.i4/i5/i6/i7 at ord 1625 appear at 1626-1627; t0.i0 at
ord 1642 appears at 1641). Transient, both directions, exact. Sampling phase, not divergence.

So a disagreement is only evidence of a port bug when the silicon value does NOT appear in
the port's own trajectory near that tick. This differ classifies every exactly-aligned
sample as:

  MATCH  port state at the aligned ordinal equals the silicon sample exactly
  SKEW   every disagreeing player's silicon value appears verbatim at a port tick within
         +-skew_ticks -- same trajectory, different sampling instant
  FORK   at least one disagreeing player's silicon value appears nowhere in that window --
         the port is on a different trajectory

Only FORK is a port bug. Real forks are persistent and their delta grows; a lone isolated
FORK surrounded by MATCHes deserves a wider skew window before you believe it.
"""

import json
import re
import sys

SEED0 = 0xEA0D2A8D


def orbit(n: int) -> dict:
    """post-draw seed value -> draw ordinal from frame0."""
    idx = {}
    s = SEED0
    for i in range(1, n + 1):
        s = (s * 214013 + 2531011) & 0xFFFFFFFF
        idx.setdefault(s, i)
    return idx


def load_port(path: str) -> list:
    """[(clk, cumulative_draw_ordinal, {(team, idx): (x, y)})] in tick order."""
    ticks = []
    clk = None
    nd = 0
    cur = {}
    with open(path) as fh:
        for ln in fh:
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


def load_silicon(path: str, idx: dict, clk_lo: int) -> list:
    """[(ordinal, clk, {(team, idx): (x, y)})] for orbit-mappable samples, ordinal order."""
    out = []
    with open(path) as fh:
        for ln in fh:
            d = json.loads(ln)
            if "pl" not in d or "seed" not in d or d.get("clk", -1) < clk_lo:
                continue
            o = idx.get(d["seed"])
            if o is None:
                continue
            out.append((o, d["clk"], {(r[0], r[1]): (r[2], r[3]) for r in d["pl"]}))
    out.sort()
    return out


def main() -> None:
    port_path, orc_path = sys.argv[1], sys.argv[2]
    max_ord = int(sys.argv[3]) if len(sys.argv) > 3 else 20000
    clk_lo = int(sys.argv[4]) if len(sys.argv) > 4 else 0
    skew = int(sys.argv[5]) if len(sys.argv) > 5 else 3

    idx = orbit(max_ord)
    ticks = load_port(port_path)
    # only ticks that actually carry a roster can serve as comparison points
    order = [(clk, o, cur) for clk, o, cur in ticks if cur]
    at_ord = {o: i for i, (clk, o, cur) in enumerate(order)}
    print(f"port ticks={len(ticks)} with-roster={len(order)} skew_window=+-{skew} ticks")

    n_match = n_skew = 0
    forks = []
    skews = []
    aligned_clks = []
    onset = {}
    fork_count = {}
    for o, sclk, smp in load_silicon(orc_path, idx, clk_lo):
        i = at_ord.get(o)
        if i is None:
            continue  # mid-tick sample: no end-of-tick port state to compare against
        pclk, pcur = order[i][0], order[i][2]
        aligned_clks.append(sclk)
        bad = [k for k, xy in smp.items() if k in pcur and pcur[k] != xy]
        if not bad:
            n_match += 1
            continue
        lo, hi = max(0, i - skew), min(len(order), i + skew + 1)
        unexplained = [k for k in bad if not any(order[j][2].get(k) == smp[k] for j in range(lo, hi))]
        if not unexplained:
            n_skew += 1
            skews.append((o, sclk, bad))
            continue
        forks.append((o, sclk, pclk, unexplained, smp, pcur))
        for k in unexplained:
            onset.setdefault(k, sclk)
            fork_count[k] = fork_count.get(k, 0) + 1

    total = n_match + n_skew + len(forks)
    if not total:
        print("NO EXACT ALIGNMENTS -- sampling too sparse; capture denser near the target clk")
        return
    print(
        f"exactly-aligned={total} clk {min(aligned_clks)}..{max(aligned_clks)}  "
        f"MATCH={n_match}  SKEW={n_skew}  FORK={len(forks)}"
    )
    if skews:
        shown = ", ".join(
            f"clk {c} ({','.join(f't{k[0]}.i{k[1]}' for k in b)})" for _, c, b in skews[:5]
        )
        print(f"  skew-explained samples: {shown}")
    if not forks:
        print(f"\nNO FORKS up to clk {max(aligned_clks)} -- port == silicon (skew aside)")
        return

    o, sclk, pclk, unexplained, smp, pcur = forks[0]
    print(f"\nFIRST FORK ord={o} clk={sclk} (port tick clk={pclk})")
    for k in unexplained:
        sv, pv = smp[k], pcur[k]
        print(
            f"  t{k[0]}.i{k[1]}: silicon={sv} port={pv} "
            f"delta={(pv[0] - sv[0], pv[1] - sv[1])}"
        )
    print("\nper-player fork onset (earliest unexplained disagreement):")
    for k in sorted(onset, key=lambda k: (onset[k], k)):
        print(f"  t{k[0]}.i{k[1]}: from clk {onset[k]}  ({fork_count[k]} forking samples)")


if __name__ == "__main__":
    main()
