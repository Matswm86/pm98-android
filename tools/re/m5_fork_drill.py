#!/usr/bin/env python3
"""Drill one player's port-vs-silicon (x,y) + silicon mover state around a fork clk.
Usage: fork_drill.py <port_posdump> <oracle_s47.jsonl> <team> <idx> <clk_lo> <clk_hi>
Oracle pl row: [team,idx,x,y,13c,17c,180,face34,yaw64,spd68,cur6c,p54,p58]; also 'ball'."""
import json, sys
port, orc, team, idx, lo, hi = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4]), int(sys.argv[5]), int(sys.argv[6])
# port: clk -> (x,y) for this player
pp = {}
clk = None
for ln in open(port):
    if ln.startswith("clk="):
        clk = int(ln.split("clk=")[1].split()[0])
    elif ln.startswith("   PL ") and clk is not None:
        f = ln.split()
        if int(f[1]) == team and int(f[2]) == idx:
            pp[clk] = (int(f[3]), int(f[4]))
# oracle: clk -> list of (x,y,face,yaw,spd,cur) samples for this player (multiple per clk)
oc = {}
ob = {}
for ln in open(orc):
    try: d = json.loads(ln)
    except: continue
    if "pl" not in d or "clk" not in d: continue
    c = d["clk"]
    for r in d["pl"]:
        if r[0] == team and r[1] == idx:
            oc.setdefault(c, []).append((r[2], r[3], r[7], r[8], r[9], r[10]))
    if "ball" in d:
        ob.setdefault(c, []).append(tuple(d["ball"][:6]))
print(f"=== t{team}.i{idx} clk {lo}-{hi} : port(x,y) vs silicon(x,y,face,yaw,spd,cur) ===")
for c in range(lo, hi+1):
    p = pp.get(c)
    o = oc.get(c, [])
    # dedup consecutive identical oracle (x,y)
    seen = []
    for s in o:
        if not seen or seen[-1][:2] != s[:2]:
            seen.append(s)
    match = "MATCH" if (p and seen and any(p == s[:2] for s in seen)) else ("--" if not seen else "FORK")
    otxt = " | ".join(f"({s[0]},{s[1]}) f{s[2]:04x} y{s[3]:04x} sp{s[4]} cu{s[5]}" for s in seen[:3])
    print(f"clk {c:3d} port={p} sil=[{otxt}]  {match}")
