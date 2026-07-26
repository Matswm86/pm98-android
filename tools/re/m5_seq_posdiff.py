#!/usr/bin/env python3
"""SUPERSEDED BY s57 -- use tools/re/m5_anchor_posdiff.py. Kept for history.

This differ indexes the silicon by clk alone, so the row it keeps is whichever pl-bearing
stop happened to be LAST in that tick, and the stop count varies with what the tick did
(1-9 per tick in s55b_partial.jsonl). The sampling instant therefore moves around INSIDE
the tick -- which is exactly what the PM98_CLK_TOL tolerance below compensates for. Sampled
at ONE fixed stop per tick (`ret0 0x5910fd`) the port is byte-exact to the silicon over
clk 1-823 at ZERO tolerance. See docs/re/M5_S57_SAMPLING_ANCHOR.md.

Sampling-phase-TOLERANT per-player position differ: port tick dump vs a Z2 capture.

Usage: m5_seq_posdiff.py <port_posdump.txt> <capture.jsonl> [clk_lo] [clk_hi]
Env:   PM98_CLK_TOL (default 2) — how many ticks of sampling phase to allow.

WHY (s55). `m5_clk_posdiff.py` assumes "the LAST stop of a clk is the settled end-of-tick
roster". That is FALSE for any player the sim moves AFTER the tick's last RNG draw: the Z2
seed-watch only stops ON a draw, so such a player is read PRE-move and its row carries the
previous tick's position. The s55 capture shows the signature directly — t1.i8/i9/i10 report
`port[clk=N] == silicon[clk=N+1]` from clk 587, and on a clk that happens to carry extra draws
(clk 592: 11 stops vs the usual 6-9) silicon takes a DOUBLE step and re-aligns. Those are
phantom forks: the trajectories are identical, the sampling phase is not. The per-clk differ
reported 3 "forks" at clk 587 on exactly that artefact.

THE TEST HERE. A capture row (clk, player, pos) PASSES iff the port has that player at that
EXACT position at some clk in [clk - TOL, clk + TOL]. Nothing is collapsed, nothing is aligned:
each sampled instant is checked on its own against the port's own per-clk position, so a
one-tick sampling phase costs nothing and a real fork — a coordinate the port never holds in
that neighbourhood — still fails. Reported per player: the pass count, the worst signed phase
offset actually used, and the first failing (clk, pos).

Limits, stated so this is not over-claimed:
  * TOL ticks of slack means a fork that resolves within TOL ticks is invisible. Keep TOL small
    (2 is the observed sampling phase plus one double-step re-align) and re-check a suspicious
    window at TOL=0/1.
  * A stationary player passes trivially — it holds one coordinate for the whole window, so its
    PASS carries almost no information. Read the moving players.
  * Players only. The ball is in the capture's `ball` row and is NOT checked here.

Port dump: `diag_m5_dart209.gd` (PM98_TICK_CAP / PM98_CLK_LO / PM98_CLK_HI). Dump a WIDER clk
range than the capture window — the ±TOL lookup needs the neighbouring ticks to exist.
"""

import os
import sys

from m5_clk_posdiff import load_port, load_silicon

CLK_TOL = int(os.environ.get("PM98_CLK_TOL", "2"))


def main() -> None:
    port = load_port(sys.argv[1])
    sil = load_silicon(sys.argv[2])
    lo = int(sys.argv[3]) if len(sys.argv) > 3 else min(sil)
    hi = int(sys.argv[4]) if len(sys.argv) > 4 else max(sil)

    print(f"# phase-tolerant position diff over clk [{lo}, {hi}], TOL={CLK_TOL} ticks")
    keys = sorted({k for c in sil for k in sil[c]})
    first_fail = None
    for key in keys:
        checked = moving = 0
        phases: set = set()
        fail = None
        prev = None
        for clk in range(lo, hi + 1):
            pos = sil.get(clk, {}).get(key)
            if pos is None:
                continue
            checked += 1
            if prev is not None and pos != prev:
                moving += 1
            prev = pos
            hit = [d for d in range(-CLK_TOL, CLK_TOL + 1) if port.get(clk + d, {}).get(key) == pos]
            if not hit:
                fail = (clk, pos, port.get(clk, {}).get(key))
                break
            phases.add(min(hit, key=abs))
        tag = f"{checked:4d} rows ({moving:3d} moves)"
        if fail is None:
            span = f"phase {min(phases):+d}..{max(phases):+d}" if phases else "phase -"
            print(f"  t{key[0]}.i{key[1]:<3} {tag}  PASS  {span}")
        else:
            print(
                f"  t{key[0]}.i{key[1]:<3} {tag}  FAIL @clk {fail[0]}: "
                f"silicon {fail[1]}, port {fail[2]} (and nothing within ±{CLK_TOL})"
            )
            if first_fail is None or fail[0] < first_fail[0]:
                first_fail = (fail[0], key)
    print(
        f"\nFIRST REAL FORK: clk {first_fail[0]} on t{first_fail[1][0]}.i{first_fail[1][1]}"
        if first_fail
        else f"\nNO FORK in [{lo}, {hi}] — all {len(keys)} players hold every captured position"
    )


if __name__ == "__main__":
    main()
