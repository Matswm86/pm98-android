#!/usr/bin/env python3
"""ANCHORED per-field differ: port tick dump vs a Z2 silicon capture, ZERO tolerance.

Usage: m5_anchor_posdiff.py <port_posdump.txt> <capture.jsonl> [clk_lo] [clk_hi]
Env:   PM98_ANCHOR  (default 0x5910fd) — the once-per-tick silicon stop to sample at.
       PM98_FIELDS  — comma-separated subset of the field names below.
       PM98_OFFSET  (default -1) — port clk == silicon clk + OFFSET.

WHY (s57). `m5_seq_posdiff.py` (s55) and `m5_field_posdiff.py` (s56) both index the
silicon by clk alone:

    players[d["clk"]] = {(r[0], r[1]): r for r in d["pl"]}

Every pl-bearing stop of that tick overwrites the previous one, so the row that survives
is whichever stop happened to be LAST — and the stop count varies with what the tick did
(3 on a quiet tick in this capture, up to 9 on an eventful one). The sampling instant
therefore moves around INSIDE the tick from clk to clk. That is what the +/-TOL phase
tolerance was compensating for, and it is why s55 needed TOL=2 and why s56 read
`orient17c` / `curve6c` / `lock5c` / `guard2d7` and the ball's possession state as forks:
at a mid-tick stop some players have already been advanced and others have not.

THE FIX. Sample the silicon at ONE fixed stop per tick. `ret0 0x5910fd` is the return of
the `call 0x5ec240` (RNG state READ, not a draw) inside FUN_005910c0 — the replay-record
snapshot. Per `docs/re/MATCH_TICK_DRIVER_MAP.md` step 4 it runs AFTER the +0x450 clock
bump (step "open-play clock", `Pm98Driver.gd` L107-112) and BEFORE the movement core
(step 6), so it is the START of silicon tick N == the END of tick N-1. The port dumps at
the END of its tick, after the same bump. Hence PORT clk N-1 == SILICON clk N, and every
field can be compared with ZERO tolerance.

The anchor is verified, not assumed: the differ aborts if the chosen stop does not appear
exactly once per tick over the window.

NOT COMPARED, and why: player `+0x184` (a team-header POINTER in silicon, a Dictionary in
the port) and ball `+0x40` / `+0x4c` (carrier / receiver pointers, same reason).
"""

import json
import os
import sys
from pathlib import Path

ANCHOR = os.environ.get("PM98_ANCHOR", "0x5910fd")
OFFSET = int(os.environ.get("PM98_OFFSET", "-1"))

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
# The s51 capture tail: ball+0x114..0x1d4 (48 i32) then ball+0x74/0x78/0x7c. Silicon
# indices 12..62 of ball_row(); the port prints them as its own BTRAJ line, index 0..50.
TRAJ_FIELDS = {
    **{f"traj{k}": (12 + k, k) for k in range(48)},
    **{f"seglen{k}": (60 + k, 48 + k) for k in range(3)},
}
HEX_PORT_COLS = {5, 6}


def _s32(v: int) -> int:
    return v - (1 << 32) if v >= (1 << 31) else v


def load_port(path: str) -> tuple[dict, dict, dict, dict]:
    """clk -> {(team, idx): PL cols}, clk -> BALL cols, clk -> BTRAJ cols, clk -> rng."""
    players: dict = {}
    ball: dict = {}
    traj: dict = {}
    rng: dict = {}
    clk = None
    for ln in Path(path).read_text(errors="ignore").splitlines():
        if ln.startswith("clk="):
            clk = int(ln.split("clk=")[1].split()[0])
            players[clk] = {}
            if "rng=" in ln:
                rng[clk] = int(ln.split("rng=")[1].split()[0])
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
        elif ln.startswith("   BTRAJ "):
            traj[clk] = [int(v) for v in ln.split()[1:]]
    return players, ball, traj, rng


def load_silicon(path: str) -> tuple[dict, dict, dict, dict]:
    """Same, sampled ONLY at the anchor stop. Also returns clk -> anchor LCG state."""
    players: dict = {}
    ball: dict = {}
    seeds: dict = {}
    hits: dict = {}
    for ln in Path(path).read_text().splitlines():
        ln = ln.strip()
        if not ln:
            continue
        try:
            d = json.loads(ln)
        except ValueError:
            continue
        if not isinstance(d, dict) or "clk" not in d:
            continue
        if d.get("ret0") != ANCHOR:
            continue
        hits[d["clk"]] = hits.get(d["clk"], 0) + 1
        if "seed" in d:
            seeds[d["clk"]] = int(d["seed"])
        if "pl" in d:
            players[d["clk"]] = {(r[0], r[1]): r for r in d["pl"]}
        if "ball" in d:
            ball[d["clk"]] = d["ball"]
    return players, ball, seeds, hits


def _report(label: str, rows: list) -> int:
    """rows = [(clk, key, [bad field strings])]. Returns the failure count."""
    bad = [r for r in rows if r[2]]
    if not bad:
        print(f"  {label:<10} {len(rows):4d} rows  EXACT")
        return 0
    print(f"  {label:<10} {len(rows):4d} rows  {len(bad)} MISMATCH, first @clk {bad[0][0]}")
    for clk, key, fields in bad[:4]:
        print(f"        clk {clk} {key}: " + "; ".join(fields[:6]))
    return len(bad)


def main() -> int:
    port_pl, port_ball, port_traj, port_rng = load_port(sys.argv[1])
    sil_pl, sil_ball, sil_seed, hits = load_silicon(sys.argv[2])
    if not hits:
        print(f"FAIL: anchor stop {ANCHOR} never appears in {sys.argv[2]}")
        return 2
    lo = int(sys.argv[3]) if len(sys.argv) > 3 else min(hits)
    hi = int(sys.argv[4]) if len(sys.argv) > 4 else max(hits)

    dupes = [c for c in range(lo, hi + 1) if hits.get(c, 0) > 1]
    missing = [c for c in range(lo, hi + 1) if hits.get(c, 0) == 0]
    print(f"# anchor {ANCHOR}, port clk == silicon clk {OFFSET:+d}, clk [{lo}, {hi}]")
    if dupes or missing:
        print(
            f"FAIL: anchor is not once-per-tick -- {len(dupes)} tick(s) with >1 stop, "
            f"{len(missing)} with none (first {(dupes + missing)[:5]}). Pick another stop."
        )
        return 2
    print(f"# anchor verified once-per-tick over {hi - lo + 1} ticks")

    want = os.environ.get("PM98_FIELDS")
    pf, bf, tf = PLAYER_FIELDS, BALL_FIELDS, TRAJ_FIELDS
    if want:
        keep = {w.strip() for w in want.split(",")}
        pf = {k: v for k, v in PLAYER_FIELDS.items() if k in keep}
        bf = {k: v for k, v in BALL_FIELDS.items() if k in keep}
        tf = {k: v for k, v in TRAJ_FIELDS.items() if k in keep}

    # Older captures carry SHORTER rows (the s45/s47 `players_row` was 13 columns, the s53
    # tail took it to 19; the ball tail arrived in s51). Narrow the comparison to the words
    # the capture actually holds, and SAY which ones dropped out -- silently comparing fewer
    # fields on an old capture would inflate the claim.
    def _fit(fields: dict, rows, label: str) -> dict:
        width = min((len(r) for r in rows), default=0)
        keep = {k: v for k, v in fields.items() if v[0] < width}
        if len(keep) < len(fields):
            dropped = sorted(set(fields) - set(keep))
            head = ", ".join(dropped[:6]) + (" ..." if len(dropped) > 6 else "")
            print(
                f"# {label}: capture row is {width} words -> {len(dropped)} field(s) not in it: {head}"
            )
        return keep

    pf = _fit(pf, [r for c in sil_pl for r in sil_pl[c].values()], "players")
    bf = _fit(bf, list(sil_ball.values()), "ball")
    tf = _fit(tf, list(sil_ball.values()), "ball tail")

    fails = 0
    words = 0  # every scalar actually compared, so the verdict cannot overstate the run

    # --- RNG lockstep: the anchor stop's LCG state vs the port's end-of-tick state ---
    rng_rows = []
    for clk in range(lo, hi + 1):
        s = sil_seed.get(clk)
        q = port_rng.get(clk + OFFSET)
        if s is None or q is None:
            continue
        rng_rows.append((clk, "rng", [] if s == q else [f"lcg: silicon {s} port {q}"]))
    if rng_rows:
        fails += _report("RNG", rng_rows)
        words += len(rng_rows)
    else:
        print("  RNG        (port dump predates the s57 `rng=` column)")

    # --- players ---
    for key in sorted({k for c in sil_pl for k in sil_pl[c]}):
        rows = []
        for clk in range(lo, hi + 1):
            row = sil_pl.get(clk, {}).get(key)
            pr = port_pl.get(clk + OFFSET, {}).get(key)
            if row is None or pr is None:
                continue
            rows.append(
                (
                    clk,
                    key,
                    [
                        f"{n}: silicon {row[si]} port {pr[pi]}"
                        for n, (si, pi) in pf.items()
                        if row[si] != pr[pi]
                    ],
                )
            )
        if rows:
            fails += _report(f"t{key[0]}.i{key[1]}", rows)
            words += len(rows) * len(pf)

    # --- ball: the 10 scalar fields, then the 51-word trajectory tail ---
    for label, fields, portside in (("BALL", bf, port_ball), ("BTRAJ", tf, port_traj)):
        rows = []
        for clk in range(lo, hi + 1):
            s = sil_ball.get(clk)
            q = portside.get(clk + OFFSET)
            if s is None or q is None:
                continue
            rows.append(
                (
                    clk,
                    label,
                    [
                        f"{n}: silicon {s[si]} port {q[pi]}"
                        for n, (si, pi) in fields.items()
                        if s[si] != q[pi]
                    ],
                )
            )
        if rows:
            fails += _report(label, rows)
            words += len(rows) * len(fields)
        elif label == "BTRAJ":
            print("  BTRAJ      (port dump predates the s57 BTRAJ line)")

    print(
        f"\nRESULT: byte-exact -- {words} words compared over clk [{lo}, {hi}], 0 mismatches "
        f"({len(pf)} player field(s) x {max((len(v) for v in sil_pl.values()), default=0)} "
        f"players, {len(bf)} ball, {len(tf)} ball-tail, plus the per-tick LCG state)."
        if fails == 0
        else f"\nRESULT: {fails} mismatching row(s) -- see the first ones above."
    )
    return 0 if fails == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
