#!/usr/bin/env python3
"""s54: read the live FUN_005b0040 bisection trace and diff it against the port.

Usage: m5_b0040_trace_solve.py <b0040trace.jsonl> [port_iter_dump.txt] [clk_lo] [clk_hi]

The capture (tools/re/wine/m5_rsp_b0040trace.py) records, per b0040 call for one player:
  ev=enter   the inputs (pos, ball pos/vel/face, curve terms P+0x70/0x3a8/0x3ac, clamp box)
  ev=iter    every bisection iteration: lead_in (EBX), nd (ECX), lead_out (EAX)
  ev=post    the PRE-clamp accumulator [ESP+0x28..0x30]
  ev=target  the CLAMPED point actually handed to FUN_005a89c0

`port_iter_dump.txt` is the stdout of
  PM98_CLK_LO=636 PM98_CLK_HI=646 godot --headless --path app \
      --script res://tests/diag_m5_t1i10_b0040iter.gd
Its per-iteration lines carry `lead_in=` and `nd=`, and its `lead0=/lead_final=/pre=` line
carries the port's ladder endpoints, so the two ladders line up iteration for iteration.

Everything printed is measured; nothing is modelled here.
"""

import json
import re
import sys
from pathlib import Path


def load_live(path: str) -> list:
    calls: dict = {}
    for ln in Path(path).read_text().splitlines():
        ln = ln.strip()
        if not ln:
            continue
        d = json.loads(ln)
        ev = d.get("ev")
        if ev is None:
            continue
        c = calls.setdefault(d["call"], {"iters": []})
        if ev == "enter":
            c.update(d)
        elif ev == "iter":
            c["iters"].append(d)
        elif ev == "post":
            c["preclamp"] = d["preclamp"]
            c["niter"] = d["iters"]
        elif ev == "target":
            c["target"] = d["target"]
    return [calls[k] for k in sorted(calls)]


def load_port(path: str) -> dict:
    """clk -> {'iters': [(lead_in, nd)], 'lead_final': int, 'pre': [x,y,z]}"""
    out: dict = {}
    clk = None
    for ln in Path(path).read_text().splitlines():
        m = re.match(r"=== clk (\d+)", ln.strip())
        if m:
            clk = int(m.group(1))
            out[clk] = {"iters": []}
            continue
        if clk is None:
            continue
        m = re.search(
            r"lead0=(-?\d+) lead_final=(-?\d+) kiters=(\d+) pre=\[(-?\d+), (-?\d+), (-?\d+)\]", ln
        )
        if m:
            out[clk]["lead0"] = int(m.group(1))
            out[clk]["lead_final"] = int(m.group(2))
            out[clk]["kiters"] = int(m.group(3))
            out[clk]["pre"] = [int(m.group(4)), int(m.group(5)), int(m.group(6))]
            continue
        m = re.search(r"k=\s*(\d+) lead_in=(-?\d+).*? nd=(-?\d+)", ln)
        if m:
            out[clk]["iters"].append((int(m.group(2)), int(m.group(3))))
    return out


def main() -> None:
    live = load_live(sys.argv[1])
    port = load_port(sys.argv[2]) if len(sys.argv) > 2 else {}
    lo = int(sys.argv[3]) if len(sys.argv) > 3 else -1
    hi = int(sys.argv[4]) if len(sys.argv) > 4 else 1 << 30
    total = len(live)
    live = [c for c in live if lo <= c.get("clk", -1) <= hi]
    print(f"# {total} live FUN_005b0040 calls captured; {len(live)} shown (clk {lo}..{hi})")
    for c in live:
        clk = c.get("clk")
        cr = None
        if "p70" in c:
            cr = (c["p70"] * c["p3ac"]) // 15000 + c["p3a8"]
        print(f"\n=== live clk {clk}  call {c.get('call')} ===")
        print(
            f"  pos={c.get('pos')} ball={c.get('ball_pos')} vel={c.get('ball_vel')} face={c.get('ball_face')}"
        )
        print(
            f"  P+0x70={c.get('p70')} P+0x3ac={c.get('p3ac')} P+0x3a8={c.get('p3a8')} -> curve_rate={cr}"
        )
        print(
            f"  P+0x2bc={c.get('p2bc')} P+0x6c={c.get('p6c')} ball+0x40={c.get('ball_40')} "
            f"ball+0x4c={c.get('ball_4c')} ball+0x74={c.get('ball_74')} "
            f"ball+0xb0={c.get('ball_b0')} ball+0xbc={c.get('ball_bc')}"
        )
        print(f"  clamp box={c.get('clamp')}")
        print(f"  iters={c.get('niter')} preclamp={c.get('preclamp')} target={c.get('target')}")
        pit = port.get(clk, {}).get("iters", [])
        print(
            "   k | live lead_in        nd            lead_out | port lead_in        nd            | same"
        )
        for i, it in enumerate(c["iters"]):
            pl, pn = pit[i] if i < len(pit) else ("-", "-")
            same = "yes" if (pl, pn) == (it["lead_in"], it["nd"]) else "NO"
            print(
                f"  {i + 1:2d} | {it['lead_in']:>14} {it['nd']:>14} {it['lead_out']:>14} |"
                f" {str(pl):>14} {str(pn):>14} | {same}"
            )
        if clk in port:
            print(
                f"  port: kiters={port[clk].get('kiters')} lead_final={port[clk].get('lead_final')} "
                f"pre={port[clk].get('pre')}"
            )


if __name__ == "__main__":
    main()
