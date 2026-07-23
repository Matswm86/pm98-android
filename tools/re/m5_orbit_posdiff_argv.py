#!/usr/bin/env python3
"""Orbit-aligned positional differ: port tick dump vs RSP dartwatch capture.

Alignment is by LCG draw ordinal (orbit index from frame0 seed), immune to clk-label
skew: port tick T covers draws (O_{T-1}, O_T] (cumulative draws= lists in the diag
dump); an oracle sample row's ordinal is the orbit index of its post-draw seed. Port
end-of-tick state matches if ANY oracle sample with ordinal in [O_T, O_{T+1}] shows the
same (x, y) for that player.
"""

import json
import re
import sys

import sys
SEED0 = 0xEA0D2A8D
PORT = sys.argv[1]
ORC = sys.argv[2]


def orbit(n: int) -> dict:
    idx = {}
    s = SEED0
    for i in range(1, n + 1):
        s = (s * 214013 + 2531011) & 0xFFFFFFFF
        idx.setdefault(s, i)
    return idx


def load_port():
    ticks = []  # [(clk, ndraws, {pk:(x,y)})]
    clk = None
    nd = 0
    cur = {}
    for ln in open(PORT):
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
    return ticks


def load_oracle(idx):
    samples = []  # (ordinal, {pk:(x,y)})
    for ln in open(ORC):
        d = json.loads(ln)
        if "pl" not in d or "seed" not in d:
            continue
        o = idx.get(d["seed"])
        if o is None:
            continue
        smp = {(r[0], r[1]): (r[2], r[3]) for r in d["pl"]}
        samples.append((o, smp, d["clk"]))
    samples.sort(key=lambda t: t[0])
    return samples


def main():
    idx = orbit(3000)
    ticks = load_port()
    samples = load_oracle(idx)
    print(f"port ticks={len(ticks)} oracle samples={len(samples)} (orbit-indexed)")

    # cumulative ordinals per tick
    O = []
    tot = 0
    for clk, nd, cur in ticks:
        tot += nd
        O.append(tot)

    players = sorted({k for _, _, cur in ticks for k in cur})
    fork = {}
    fork_port = {}
    for pk in players:
        for ti, (clk, nd, cur) in enumerate(ticks):
            pv = cur.get(pk)
            if pv is None or ti + 1 >= len(ticks):
                continue
            lo, hi = O[ti], O[ti + 1]
            cands = [s for o, s, _ in samples if lo <= o <= hi]
            if not cands:
                continue
            if any(s.get(pk) == pv for s in cands):
                continue
            fork[pk] = (clk, ti)
            fork_port[pk] = pv
            break

    if not fork:
        print("NO FORKS — port end-of-tick (x,y) always visible in oracle samples")
        return
    print("\nfork onsets (port clk labels):")
    for pk, (clk, ti) in sorted(fork.items(), key=lambda kv: kv[1][1]):
        print(f"  t{pk[0]}.i{pk[1]}: port clk {clk} (tick #{ti})  port_pos={fork_port[pk]}")

    # context: earliest forker trace
    first_pk, (fclk, fti) = min(fork.items(), key=lambda kv: kv[1][1])
    print(f"\ntrace for earliest forker {first_pk} around tick {fti}:")
    for ti in range(max(0, fti - 5), min(len(ticks), fti + 5)):
        clk, nd, cur = ticks[ti]
        pv = cur.get(first_pk)
        lo = O[ti - 1] if ti else 0
        hi = O[ti]
        obs = []
        for o, s, oclk in samples:
            if lo < o <= hi and first_pk in s:
                if not obs or obs[-1][1] != s[first_pk]:
                    obs.append((o, s[first_pk], oclk))
        print(f"  tick {ti} clk {clk} draws({lo},{hi}] port={pv}")
        for o, xy, oclk in obs:
            print(f"        ord {o} oclk {oclk} oracle={xy}")


if __name__ == "__main__":
    main()
