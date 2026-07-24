#!/usr/bin/env python3
"""Analyze the Z2-stopped dartwatch capture over clk 630-660 for t1.i10 (Bolton #30
Gunnlaugsson): does silicon's b0040 target (heading 0x34 / committed 0x64) and the
ball+0x114 predicted-trajectory ladder DIFFER at clk 639, or is the fork one tick later?

Row layouts (m5_rsp_capture.py):
  pl row  = [team, idx, x, y, 0x13c, 0x17c, 0x180, 0x34, 0x64, 0x68, 0x6c, 0x54, 0x58]
  ball    = [x, y, z, vx, vy, vz, face34, carrier40, recv4c, own54, +0x58, N5c,
             traj[0..47] (16 vec3 stride 12 @ ball+0x114), seg74, seg78, seg7c]
Usage: analyze_b0040_fork.py <capture.jsonl>
"""

import json
import sys

SEED0 = 0xEA0D2A8D
I34, I64, I68, I6C = 7, 8, 9, 10  # pl-row indices


def orbit(n):
    idx = {}
    s = SEED0
    for i in range(1, n + 1):
        s = (s * 214013 + 2531011) & 0xFFFFFFFF
        idx.setdefault(s, i)
    return idx


def main():
    cap = sys.argv[1]
    idx = orbit(200000)
    rows = []
    with open(cap) as fh:
        for ln in fh:
            ln = ln.strip()
            if not ln:
                continue
            d = json.loads(ln)
            if not isinstance(d, dict) or "pl" not in d:
                continue
            clk = d.get("clk", -1)
            if not (630 <= clk <= 660):
                continue
            t110 = next((r for r in d["pl"] if r[0] == 1 and r[1] == 10), None)
            if t110 is None:
                continue
            o = idx.get(d.get("seed"), None)
            rows.append((clk, o, d.get("stop"), t110, d.get("ball")))
    rows.sort(key=lambda r: (r[0], r[1] if r[1] is not None else 1 << 62, r[2]))

    print(f"# {len(rows)} Z2 stops with t1.i10 in clk 630-660")
    print(
        "# clk  ord   stop   x        y         0x34   0x64   0x68  0x6c   | ball xy / traj slot0..2"
    )
    for clk, o, stop, r, ball in rows:
        x, y = r[2], r[3]
        f34, f64, f68, f6c = r[I34], r[I64], r[I68], r[I6C]
        s = f"{clk:4d}  {str(o):>5} {stop:6}  {x:8d} {y:9d}  {f34:5d} {f64:6d} {f68:5d} {f6c:5d}"
        if ball and len(ball) >= 63:
            bx, by = ball[0], ball[1]
            traj = ball[12:60]
            slots = " ".join(f"({traj[3 * k]},{traj[3 * k + 1]})" for k in range(3))
            segs = ball[60:63]
            s += f"  | b=({bx},{by}) seg={segs} m0..2={slots}"
        print(s)

    # per-clk 0x34/0x64 summary (last stop per clk = settled end-of-tick)
    print("\n# per-clk settled t1.i10 (last stop): 0x34 (heading) / 0x64 (committed)")
    seen = {}
    for clk, o, stop, r, ball in rows:
        seen[clk] = (r[I34], r[I64], r[I68])
    prev34 = None
    for clk in sorted(seen):
        f34, f64, f68 = seen[clk]
        d = "" if prev34 is None else f"  d0x34={f34 - prev34:+d}"
        print(f"  clk {clk}: 0x34={f34} (0x{f34:x}) 0x64={f64} (0x{f64:x}) 0x68={f68}{d}")
        prev34 = f34


if __name__ == "__main__":
    main()
