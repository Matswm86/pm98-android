#!/usr/bin/env python3
"""M5 seed-lockstep diff: port per-step seed trace vs the wine oracle's polled timeline.

The port side (PM98_SEEDTRACE from tests/run_match_from_struct.gd) logs the rng state at
EVERY outer-step boundary: "step clk banked half seed". The oracle side (capture2/
timeline.jsonl from m4_poll.py) sampled (clk, banked, half, seed) off /proc/<pid>/mem every
few wall-seconds while MANAGER.EXE played the reference match. If the port is in rng
lockstep, every polled oracle seed must appear at some port step boundary with the same
(clk, banked) coordinates. The first oracle row whose seed the port never produced brackets
the divergence to a (clk, seed) window between the last matching poll and that row.

Usage:
  m5_seedtrace_diff.py <port_trace.txt> [oracle_timeline.jsonl]
"""

import json
import sys
from pathlib import Path

DEFAULT_ORACLE = Path.home() / "MWM-AI/data/pm98-m4-oracle/capture2/timeline.jsonl"


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    trace_path = Path(sys.argv[1])
    oracle_path = Path(sys.argv[2]) if len(sys.argv) > 2 else DEFAULT_ORACLE

    # port: seed -> (step, clk, banked, half). LCG states are unique across one match's
    # ~1e5 draws (2^32 period), so seed alone keys a step boundary.
    port: dict[int, tuple[int, int, int, int]] = {}
    for line in trace_path.read_text().splitlines():
        parts = line.split()
        if len(parts) != 5:
            continue
        step, clk, banked, half, seed = (int(x) for x in parts)
        port.setdefault(seed, (step, clk, banked, half))

    rows = 0
    matched = 0
    coord_mismatch: list[dict] = []
    last_match: dict | None = None
    first_miss: dict | None = None
    with oracle_path.open() as f:
        for line in f:
            try:
                r = json.loads(line)
            except json.JSONDecodeError:
                continue
            if "seed" not in r:          # event rows (e.g. process_gone)
                continue
            rows += 1
            seed = int(r["seed"])
            hit = port.get(seed)
            if hit is None:
                if first_miss is None:
                    first_miss = r
                continue
            step, clk, banked, half = hit
            if clk != int(r["clk"]) or banked != int(r["banked"]):
                coord_mismatch.append({"oracle": r, "port": hit})
            else:
                matched += 1
                if first_miss is None:
                    last_match = r

    print(f"oracle rows        = {rows}")
    print(f"seed+coord matched = {matched}")
    print(f"seed hit, coord != = {len(coord_mismatch)}")
    if last_match is not None:
        print(f"last match before first miss: t={last_match['t']} clk={last_match['clk']} "
              f"banked={last_match['banked']} half={last_match['half']} seed={last_match['seed']}")
    if first_miss is not None:
        print(f"FIRST MISS: t={first_miss['t']} clk={first_miss['clk']} "
              f"banked={first_miss['banked']} half={first_miss['half']} seed={first_miss['seed']}")
        print("-> divergence window: (last-match clk, first-miss clk] above")
    else:
        print("NO MISSES -- port covers every polled oracle seed (lockstep holds "
              "for the polled span)")
    for cm in coord_mismatch[:5]:
        o, p = cm["oracle"], cm["port"]
        print(f"  coord mismatch: oracle clk={o['clk']} banked={o['banked']} "
              f"vs port step={p[0]} clk={p[1]} banked={p[2]} (seed={o['seed']})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
