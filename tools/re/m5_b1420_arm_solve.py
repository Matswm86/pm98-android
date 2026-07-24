#!/usr/bin/env python3
"""s53: read a m5_rsp_capture jsonl and print, per clk, which FUN_005b1420 arm the LIVE
engine took for one player — plus the FUN_005a8f20 once-per-tick guard.

FUN_005b1420(p) (docs/re/move/fn_005b1420_FUN_005b1420.c), in order:
  freeze  <- gs+0x2ee != 0  AND  *(m+0x468)+0xfa0 == 0  AND  p+0x5c != 0   -> no leaf
  B0040   <- p == *(gs+0x204)  AND  *(ball+0x40) == 0
  B1500   <- ball+0x54 != p+0x2b8
  B1C80   <- otherwise
and FUN_005a8f20 no-ops entirely when p+0x2d7 is already 1 (the per-tick prologue
FUN_005a4600 clears it), so a steer that ran earlier in the tick keeps b0040's out.

Row layout written by m5_rsp_capture.py (s53):
  0 team  1 idx  2 x  3 y  4 +0x13c  5 +0x17c  6 +0x180  7 0x34  8 0x64  9 0x68
  10 0x6c  11 0x54  12 0x58  13 +0x184(hdr)  14 +0x5c  15 +0x2b8  16 +0x2bc
  17 +0x2d7  18 +0x2d8
Ball row: 0 x 1 y 2 z 3 vx 4 vy 5 vz 6 face 7 carrier(+0x40) 8 +0x4c 9 +0x54 ...

Usage: m5_b1420_arm_solve.py <capture.jsonl> [team] [idx]
"""

import json
import sys

P_HDR, P_LOCK, P_TEAM, P_ONPITCH, P_GUARD = 13, 14, 15, 16, 17
B_CARRIER, B_OWNER = 7, 9


def main() -> None:
    path = sys.argv[1]
    team = int(sys.argv[2]) if len(sys.argv) > 2 else 1
    idx = int(sys.argv[3]) if len(sys.argv) > 3 else 10

    per_clk: dict[int, list[dict]] = {}
    with open(path) as fh:
        for line in fh:
            d = json.loads(line)
            if "pl" not in d or "gs" not in d:
                continue
            per_clk.setdefault(d["clk"], []).append(d)

    print(f"# FUN_005b1420 arm for t{team}.i{idx}, from {path}")
    print("# gs204 = *(gs+0x204) designate resolved to [team,idx]; guard = p+0x2d7 per stop")
    print("# arm  = the leaf b1420 would dispatch with THESE field values")
    print("# pos  = the player's live (x,y) — cross-check vs specs/b0040_m5_live_heading.txt")
    print(
        "# clk | 0x34   0x64   0x68 | gs204        | guard | carrier | own/team | 2ee fa0 "
        "| arm   | pos"
    )
    for clk in sorted(per_clk):
        stops = per_clk[clk]
        rows = []
        for d in stops:
            p = next((r for r in d["pl"] if r[0] == team and r[1] == idx), None)
            if p is None:
                continue
            rows.append((p, d))
        if not rows:
            continue
        p0, d0 = rows[0]
        gs = d0["gs"][team]
        desig = gs[2][2]  # resolved +0x204
        freeze_flag = gs[3]
        sub = d0.get("sub_fa0")
        ball = d0["ball"]
        carrier = ball[B_CARRIER]
        guards = "".join(str(r[0][P_GUARD]) for r in rows)

        freeze = bool(freeze_flag) and sub == 0 and bool(p0[P_LOCK])
        if freeze:
            arm = "FREEZE"
        elif desig == [team, idx] and carrier == 0:
            arm = "B0040"
        elif ball[B_OWNER] != p0[P_TEAM]:
            arm = "B1500"
        else:
            arm = "B1C80"
        print(
            f"  {clk} | {p0[7]:5d} {p0[8]:5d} {p0[9]:6d} | {str(desig):12s} |  {guards:5s}"
            f"| {carrier:#010x} | {ball[B_OWNER]}/{p0[P_TEAM]} "
            f"| {freeze_flag:3d} {sub} | {arm:6s}| ({p0[2]}, {p0[3]})"
        )

    # designate history for BOTH teams — a mid-window move is the s52 hypothesis.
    print("\n# +0x1fc / +0x200 / +0x204 designations per team, first stop of each clk")
    for clk in sorted(per_clk):
        d = per_clk[clk][0]
        cells = " | ".join(f"t{t}: {g[2]}" for t, g in enumerate(d["gs"]))
        print(f"  {clk} | {cells}")


if __name__ == "__main__":
    main()
