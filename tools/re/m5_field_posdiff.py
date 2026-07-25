#!/usr/bin/env python3
"""WIDE per-field differ: port tick dump vs a Z2 silicon capture, phase-tolerant.

Usage: m5_field_posdiff.py <port_posdump.txt> <capture.jsonl> [clk_lo] [clk_hi]
Env:   PM98_CLK_TOL (default 2) — ticks of sampling phase to allow (see s55).
       PM98_FIELDS         — comma-separated subset of the field names below.

WHY (s56). `m5_seq_posdiff.py` closed the s55 sampling-phase artefact but checks player
`x`/`y` and nothing else: velocity, orientation, the mover state and the gate inputs are
all IN the capture (`m5_rsp_capture.py` `players_row()` / `ball_row()`) and were simply
never diffed. A trajectory can hold identical positions for a window while its velocity or
its facing has already forked, so "22/22 players PASS" on x/y alone is a weaker claim than
it reads. This differ checks the WHOLE row.

THE TEST. Same phase tolerance as s55, but applied to the row rather than a coordinate: a
capture row `(clk, player, fields...)` PASSES iff the port holds **every checked field of
that player simultaneously** at some clk in `[clk - TOL, clk + TOL]`. Matching each field
at a different instant would be meaningless, so the window is chosen once per row. When a
row fails, the fields that differ at the nearest instant are named, so a fork is reported
as "t1.i10 forks on yaw+0x64 at clk N", not just "something differs".

NOT COMPARED, and why:
  * player `+0x184` — a team-header POINTER in silicon, a Dictionary in the port;
  * ball `+0x40` / `+0x4c` — carrier / receiver POINTERS, same reason;
  * the ball's 48-int predicted-trajectory tail and its three bounce-segment lengths: the
    port does not dump them (they are the s51 capture tail). Widening to those needs the
    dumper extended again.

Port dump: `diag_m5_dart209.gd` (PM98_TICK_CAP / PM98_CLK_LO / PM98_CLK_HI), s56 wide rows.
Dump a WIDER clk range than the capture window — the +/-TOL lookup needs the neighbours.
"""

import json
import os
import sys
from pathlib import Path

CLK_TOL = int(os.environ.get("PM98_CLK_TOL", "2"))

# name -> (silicon players_row index, port PL column index)
PLAYER_FIELDS = {
    "x": (2, 2),
    "y": (3, 3),
    "sub13c": (4, 4),
    "orient17c": (5, 5),
    "orient180": (6, 6),
    "face34": (7, 8),
    "yaw64": (8, 9),
    "spd68": (9, 10),
    "curve6c": (10, 11),
    "p54": (11, 12),
    "p58": (12, 13),
    "lock5c": (14, 14),
    "team2b8": (15, 15),
    "onpitch2bc": (16, 16),
    "guard2d7": (17, 17),
    "p2d8": (18, 18),
}
# name -> (silicon ball_row index, port BALL column index)
BALL_FIELDS = {
    "x": (0, 0),
    "y": (1, 1),
    "z": (2, 2),
    "vx": (3, 3),
    "vy": (4, 4),
    "vz": (5, 5),
    "face34": (6, 6),
    "own54": (9, 7),
    "b58": (10, 8),
    "n5c": (11, 9),
}
# Columns the port prints as unsigned hex (`%x` of a masked i32).
HEX_PORT_COLS = {5, 6}


def _s32(v: int) -> int:
    return v - (1 << 32) if v >= (1 << 31) else v


def load_port(path: str) -> tuple[dict, dict]:
    """clk -> {(team, idx): [cols...]}, and clk -> [ball cols...]."""
    players: dict = {}
    ball: dict = {}
    clk = None
    for ln in Path(path).read_text(errors="ignore").splitlines():
        if ln.startswith("clk="):
            clk = int(ln.split("clk=")[1].split()[0])
            players[clk] = {}
        elif clk is None:
            continue
        elif ln.startswith("   PL "):
            f = ln.split()[1:]
            cols = [int(v, 16) if i in HEX_PORT_COLS else int(v) for i, v in enumerate(f)]
            for i in HEX_PORT_COLS:
                cols[i] = _s32(cols[i])
            players[clk][(cols[0], cols[1])] = cols
        elif ln.startswith("   BALL "):
            ball[clk] = [int(v) for v in ln.split()[1:]]
    return players, ball


def load_silicon(path: str) -> tuple[dict, dict]:
    players: dict = {}
    ball: dict = {}
    for ln in Path(path).read_text().splitlines():
        ln = ln.strip()
        if not ln:
            continue
        try:
            d = json.loads(ln)
        except ValueError:
            continue
        if not isinstance(d, dict) or "pl" not in d:
            continue
        players[d["clk"]] = {(r[0], r[1]): r for r in d["pl"]}
        if "ball" in d:
            ball[d["clk"]] = d["ball"]
    return players, ball


def _row_hits(sil_row: list, port_rows: dict, clk: int, fields: dict, key=None) -> list:
    """Offsets in [-TOL, +TOL] at which the port matches EVERY checked field."""
    out = []
    for d in range(-CLK_TOL, CLK_TOL + 1):
        pr = port_rows.get(clk + d)
        if pr is not None and key is not None:
            pr = pr.get(key)
        if pr is None:
            continue
        if all(sil_row[si] == pr[pi] for si, pi in fields.values()):
            out.append(d)
    return out


def _best_diff(sil_row: list, port_rows: dict, clk: int, fields: dict, key=None) -> tuple:
    """The offset in [-TOL, +TOL] with the FEWEST differing fields, and those fields.

    Reporting the diff at offset 0 would name whatever the sampling phase happens to
    misalign; the nearest-matching instant names the field that actually forked.
    """
    best = (None, None, 1 << 30)
    for d in range(-CLK_TOL, CLK_TOL + 1):
        pr = port_rows.get(clk + d)
        if pr is not None and key is not None:
            pr = pr.get(key)
        if pr is None:
            continue
        bad = [
            f"{name}: silicon {sil_row[si]} port {pr[pi]}"
            for name, (si, pi) in fields.items()
            if sil_row[si] != pr[pi]
        ]
        if len(bad) < best[2]:
            best = (d, bad, len(bad))
    if best[0] is None:
        return 0, ["<no port row in window>"]
    return best[0], best[1]


def main() -> None:
    port_pl, port_ball = load_port(sys.argv[1])
    sil_pl, sil_ball = load_silicon(sys.argv[2])
    lo = int(sys.argv[3]) if len(sys.argv) > 3 else min(sil_pl)
    hi = int(sys.argv[4]) if len(sys.argv) > 4 else max(sil_pl)

    want = os.environ.get("PM98_FIELDS")
    pfields = PLAYER_FIELDS
    bfields = BALL_FIELDS
    if want:
        keep = {w.strip() for w in want.split(",")}
        pfields = {k: v for k, v in PLAYER_FIELDS.items() if k in keep}
        bfields = {k: v for k, v in BALL_FIELDS.items() if k in keep}

    print(f"# WIDE field diff over clk [{lo}, {hi}], TOL={CLK_TOL}")
    print(f"# player fields: {', '.join(pfields)}")
    print(f"# ball fields:   {', '.join(bfields)}")
    first_fail = None

    for key in sorted({k for c in sil_pl for k in sil_pl[c]}):
        checked = 0
        phases: set = set()
        fail = None
        for clk in range(lo, hi + 1):
            row = sil_pl.get(clk, {}).get(key)
            if row is None:
                continue
            checked += 1
            hits = _row_hits(row, port_pl, clk, pfields, key)
            if not hits:
                off, bad = _best_diff(row, port_pl, clk, pfields, key)
                fail = (clk, bad, off)
                break
            phases.add(min(hits, key=abs))
        if fail is None:
            span = f"phase {min(phases):+d}..{max(phases):+d}" if phases else "phase -"
            print(f"  t{key[0]}.i{key[1]:<3} {checked:4d} rows  PASS  {span}")
        else:
            print(
                f"  t{key[0]}.i{key[1]:<3} {checked:4d} rows  FAIL @clk {fail[0]}"
                f" (nearest instant {fail[2]:+d}, {len(fail[1])} field(s) differ)"
            )
            for line in fail[1][:6]:
                print(f"        {line}")
            if first_fail is None or fail[0] < first_fail[0]:
                first_fail = (fail[0], f"t{key[0]}.i{key[1]}")

    if sil_ball and port_ball:
        checked = 0
        fail = None
        phases = set()
        for clk in range(lo, hi + 1):
            row = sil_ball.get(clk)
            if row is None:
                continue
            checked += 1
            hits = _row_hits(row, port_ball, clk, bfields)
            if not hits:
                off, bad = _best_diff(row, port_ball, clk, bfields)
                fail = (clk, bad, off)
                break
            phases.add(min(hits, key=abs))
        if fail is None:
            span = f"phase {min(phases):+d}..{max(phases):+d}" if phases else "phase -"
            print(f"  BALL     {checked:4d} rows  PASS  {span}")
        else:
            print(
                f"  BALL     {checked:4d} rows  FAIL @clk {fail[0]}"
                f" (nearest instant {fail[2]:+d}, {len(fail[1])} field(s) differ)"
            )
            for line in fail[1][:8]:
                print(f"        {line}")
            if first_fail is None or fail[0] < first_fail[0]:
                first_fail = (fail[0], "BALL")
    else:
        print("  BALL     (no ball rows on one side — port dump predates the s56 BALL line)")

    print(
        f"\nFIRST WIDE FORK: clk {first_fail[0]} on {first_fail[1]}"
        if first_fail
        else f"\nNO WIDE FORK in [{lo}, {hi}] — every checked field holds"
    )


if __name__ == "__main__":
    main()
