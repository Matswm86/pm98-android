#!/usr/bin/env python3
"""Decide the M5 clk-9 candidate (engage-early vs wrong-marked-man) from a wide capture.

Usage: m5_clk9_analyze.py <clk9_timeline.jsonl> [clk_lo] [clk_hi]

Input is the s29 m5_poll_traj.py output (q60 blob + burst `pl` player tables while
clk <= 24). For each clk in [clk_lo, clk_hi] (default 5..15) it prints, from the FIRST
and LAST row of that clk:
  ctrl  = ball+0x40 carrier VA   (resolved to team.idx/id when it lands in a player array)
  recv  = ball+0x4c receiver VA  (the b1500 press operand)
  p9 mk = the Bolton (team1) id-9 unit's marked man (+0x150), resolved the same way.

Decision rule (M5_DIVERGENCE_CLK9_EXTRA_DRAW.md):
  candidate 1 (engage 1 tick early): at clk 9 the reference already has ctrl != 0
    (the receiver engaged; the port only engages at clk 10) -> press arm never reached.
  candidate 2 (wrong marked man): ctrl == 0 at clk 9 (same as port) but p9's mk != the
    receiver p14 -> press compare false.
Also verifies run fidelity: seed0, clk coverage (every clk present in the window), and
the first-goal clk (sc0 0->1; the reference goal is clk 2837).
"""

import json
import sys


def main() -> None:
    path = sys.argv[1]
    lo = int(sys.argv[2]) if len(sys.argv) > 2 else 5
    hi = int(sys.argv[3]) if len(sys.argv) > 3 else 15

    teams = None
    rows_by_clk = {}
    seed0 = None
    goal_clk = None
    prev_sc0 = 0
    clks_seen = []
    for line in open(path):
        try:
            r = json.loads(line)
        except json.JSONDecodeError:
            continue
        if r.get("event") == "teams":
            teams = r
            continue
        if "clk" not in r:
            continue
        c = r["clk"]
        if not clks_seen or clks_seen[-1] != c:
            clks_seen.append(c)
        if seed0 is None and r.get("phase") != 2:
            seed0 = r["seed"]
        if r.get("sc0", 0) > prev_sc0 and goal_clk is None:
            goal_clk = c
        prev_sc0 = max(prev_sc0, r.get("sc0", 0))
        if lo <= c <= hi:
            rows_by_clk.setdefault(c, []).append(r)

    def resolve(va: int) -> str:
        if not va:
            return "0"
        if teams:
            for tkey, ti in (("t0", 0), ("t1", 1)):
                arr = int(teams[tkey][0], 16)
                cnt = teams[tkey][1]
                stride = teams["stride"]
                if arr <= va < arr + cnt * stride and (va - arr) % stride == 0:
                    return f"t{ti}.i{(va - arr) // stride}"
        return hex(va)

    # fidelity
    print(f"seed0={seed0:#010x}" if seed0 is not None else "seed0=?", end="  ")
    print(f"first_goal_clk={goal_clk}", end="  ")
    window = [c for c in range(lo, hi + 1)]
    missing = [c for c in window if c not in rows_by_clk]
    print(f"clk {lo}..{hi} coverage: {'FULL' if not missing else f'MISSING {missing}'}")

    for c in window:
        rows = rows_by_clk.get(c, [])
        if not rows:
            print(f"clk {c:3d}: NO ROWS")
            continue
        for tag, r in (("first", rows[0]), ("last", rows[-1])):
            ctrl, recv = r.get("ctrl", 0), r.get("recv", 0)
            mk9 = None
            for p in r.get("pl", []):
                # p = [team, idx, slot, id, act, mk, x, y]
                if p[0] == 1 and p[3] == 9:
                    mk9 = p[5]
            m = f"p9.mk={resolve(mk9)}" if mk9 is not None else "p9.mk=?"
            print(
                f"clk {c:3d} {tag:5s} seed={r['seed']:10d} "
                f"ctrl={resolve(ctrl):8s} recv={resolve(recv):8s} {m} "
                f"ball=({r['bx']},{r['by']},{r['bz']}) rows={len(rows)}"
            )

    # per-clk seed table for LCG-distance work
    print("\nper-clk end seeds (clk: seed at last row):")
    for c in window:
        rows = rows_by_clk.get(c, [])
        if rows:
            print(f"  {c}: {rows[-1]['seed']}")


if __name__ == "__main__":
    main()
