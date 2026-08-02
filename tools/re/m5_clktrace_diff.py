#!/usr/bin/env python3
"""Compare the port's match against the original's, on a CLOCK-watchpoint trace.

    python3 tools/re/m5_clktrace_diff.py <clktrace.jsonl> <port_seedtrace.txt>

The M5 goal-2 frontier (port 26', reference 24', same team) sits in 2837 < clk < 8469, and
s87 named the blocker correctly: there is no per-frame reference past clk 2837 at all. A
full per-frame capture of that window is ~39,000 frames of 22 player rows over the RSP
stub, which s59's measured in-window rate puts at well over half a day.

`m5_rsp_capture.py PM98_CLK_TRACE=1` is the cheap half that runs first: it stays on the
CLOCK watchpoint for the whole window and banks one small row per write — clk, the LCG
seed, banked/half/phase/dispatch and the score. This reads that against the port's own
`PM98_SEEDTRACE` (`step clk banked half rng.state` per outer step).

WHAT THIS CAN AND CANNOT DECIDE — measured 2026-08-02, so no later session re-derives it:

* **The EVENT timeline is decidable and is the point.** The score is in every row, so the
  original's goal clocks come straight out of the trace. That is what turns "the reference
  scored at 24'" into a clock the expensive capture can be aimed at.
* **Per-tick seed equality is NOT a divergence test.** The clock is written SIX times per
  tick in this window and the tick carries ~33 rand() draws, so the trace samples under a
  fifth of the stream. Two identical streams sampled at points that do not coincide give
  different seeds, and "0 seeds in common at clk 2838" is therefore evidence of nothing.
  Reported below as a weak upper bound and labelled as one.
* **What it does show at the restart is structural and is real.** At clk 2837 the original
  writes the clock 65 times while the port takes 433 outer steps, and the goal-1 seed
  itself (0x40877acf) is in the intersection — the two agree at the goal and then pace the
  post-goal restart completely differently.

Localising goal 2 still needs the SEED watchpoint with its per-draw `ret0` call-site, which
is what `m5_rsp_capture.py` does without `PM98_CLK_TRACE`. This narrows the window it has
to cover; it does not replace it.
"""

from __future__ import annotations

import json
import sys
from collections import defaultdict
from pathlib import Path


def load_orig(path: Path) -> list[dict]:
    out = []
    for line in path.read_text().splitlines():
        if not line.startswith("{"):
            continue
        try:
            row = json.loads(line)
        except json.JSONDecodeError:  # a streamed jsonl can end mid-row
            continue
        if "f" in row:
            out.append(row)
    return out


def load_port(path: Path) -> list[tuple[int, int, int]]:
    out = []
    for line in path.read_text().splitlines():
        f = line.split()
        if len(f) == 5:  # the last line of a live trace can be short
            out.append((int(f[0]), int(f[1]), int(f[4])))
    return out


def goals(rows: list[dict]) -> list[tuple[int, tuple[int, int]]]:
    out = []
    prev = None
    for r in rows:
        sc = (int(r["sc"][0]), int(r["sc"][1]))
        if prev is not None and sc != prev:
            out.append((int(r["clk"]), sc))
        prev = sc
    return out


def main() -> int:
    if len(sys.argv) < 3:
        print(__doc__)
        return 2
    rows = load_orig(Path(sys.argv[1]))
    port = load_port(Path(sys.argv[2]))
    if not rows or not port:
        print(f"empty trace: original {len(rows)} rows, port {len(port)} steps")
        return 2

    lo, hi = rows[0]["clk"], rows[-1]["clk"]
    plo, phi = port[0][1], port[-1][1]
    print(f"original  clk {lo}..{hi}   {len(rows)} clock writes")
    print(f"port      clk {plo}..{phi}   {len(port)} outer steps\n")

    print("SCORE CHANGES — the original's own goal clocks:")
    og = goals(rows)
    for clk, sc in og:
        print(f"  clk {clk:5d}  {sc[0]}-{sc[1]}")
    if not og:
        print(f"  none yet in {lo}..{hi}")
    print()

    o_seeds: dict[int, set[int]] = defaultdict(set)
    o_writes: dict[int, int] = defaultdict(int)
    for r in rows:
        o_seeds[int(r["clk"])].add(int(r["seed"]))
        o_writes[int(r["clk"])] += 1
    p_seeds: dict[int, set[int]] = defaultdict(set)
    p_steps: dict[int, int] = defaultdict(int)
    for _t, clk, rng in port:
        p_seeds[clk].add(rng)
        p_steps[clk] += 1

    common = sorted(set(o_seeds) & set(p_seeds))
    if not common:
        print("no clk overlap between the two traces")
        return 1
    print(f"PACING, over the {len(common)} ticks both sides reach:")
    for c in common[:1] + [c for c in common[1:6]]:
        print(
            f"  clk {c:5d}  original {o_writes[c]:3d} clock writes / {len(o_seeds[c]):3d} distinct"
            f"   port {p_steps[c]:4d} steps / {len(p_seeds[c]):4d} distinct"
        )

    shared = [c for c in common if o_seeds[c] & p_seeds[c]]
    print(
        f"\nlast tick with ANY seed in common: {max(shared) if shared else 'none'}"
        "   (WEAK: the trace samples ~6 of a tick's ~33 draws — see the module docstring)"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
