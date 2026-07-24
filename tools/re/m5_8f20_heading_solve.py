#!/usr/bin/env python3
"""M5 s52: back-solve the heading the REAL engine APPLIED to t1.i10, per tick, from the
live s51 capture, using the disassembled rules of FUN_005a8f20 (the steering apply).

FUN_005a8f20(P, heading), verbatim from the decompile (docs/re/move/fn_005a8f20_FUN_005a8f20.c):

    d      = (short)(heading - *(u16*)(P+0x34))          # face delta, 16-bit wrap
    ad     = |d|
    steps  = trunc((ad - 0x100) / 0x400) + 1
    if steps < 2:  *(u16*)(P+0x34)  = heading            # SNAP  (ad < 0x500)
    else:          *(u16*)(P+0x34) += (+0x400 if d > 0 else -0x400)
    if ad < 0x1555:
        *(u16*)(P+0x64) = heading                        # COMMIT the yaw
        P+0x68 ramps toward P+0x6c, clamped +/-0x106
    else:
        P+0x68 = max(0, P+0x68 - 0x1ca)                  # DECAY

Nothing downstream re-clamps or re-picks a target, so those three observed fields
(0x34 / 0x64 / 0x68) determine `heading` EXACTLY on every tick that snapped or committed,
and bound it on the rest. That is what this prints -- so the port's applied heading can be
compared against silicon's without another wine capture.

Usage: m5_8f20_heading_solve.py <capture.jsonl>
"""

import json
import sys

I34, I64, I68 = 7, 8, 9  # pl-row indices (see m5_rsp_capture.py / m5_b0040_live_heading.py)
CLK_LO, CLK_HI = 629, 660
TEAM, IDX = 1, 10


def s16(v):
    v &= 0xFFFF
    return v - 0x10000 if v >= 0x8000 else v


def settled(cap):
    """Last stop per clk = the settled end-of-tick state."""
    out = {}
    with open(cap) as fh:
        for ln in fh:
            ln = ln.strip()
            if not ln:
                continue
            d = json.loads(ln)
            if not isinstance(d, dict) or "pl" not in d:
                continue
            clk = d.get("clk", -1)
            if not (CLK_LO <= clk <= CLK_HI):
                continue
            r = next((r for r in d["pl"] if r[0] == TEAM and r[1] == IDX), None)
            if r is not None:
                out[clk] = (r[I34] & 0xFFFF, r[I64] & 0xFFFF, r[I68])
    return out


def main():
    st = settled(sys.argv[1])
    clks = sorted(st)
    print("# t1.i10 -- heading APPLIED by the real FUN_005a8f20, back-solved per tick.")
    print("# 'tick c-1 -> c' means the tick whose pre-state is clk c-1 and post-state is clk c.")
    print("# clk | face_pre -> face | yaw  spd  | applied heading")
    exact = {}
    for c in clks[1:]:
        f0, y0, s0 = st[c - 1]
        f1, y1, s1 = st[c]
        why, hdg = [], None
        step = s16(f1 - f0)
        if step == 0x400 or step == -0x400:
            slew = "slew%+d" % step
        else:
            slew = "SNAP"
            hdg = f1  # steps<2 wrote heading straight into 0x34
            why.append("snap")
        if y1 != y0:
            if hdg is not None and hdg != y1:
                why.append("!! snap/commit disagree (%d vs %d)" % (hdg, y1))
            hdg = y1  # ad<0x1555 wrote heading straight into 0x64
            why.append("commit")
        decayed = s1 < s0
        rng = ""
        if hdg is None:
            # bounded only: sign of d from the slew, magnitude from the commit/decay branch
            lo_ad = 0x1555 if decayed else 0x500
            if step > 0:
                rng = "in [face+%d, face+0x7fff] = [%d..%d] mod 2^16" % (
                    lo_ad, (f0 + lo_ad) & 0xFFFF, (f0 + 0x7FFF) & 0xFFFF)
            else:
                rng = "in [face-0x8000, face-%d] = [%d..%d] mod 2^16" % (
                    lo_ad, (f0 - 0x8000) & 0xFFFF, (f0 - lo_ad) & 0xFFFF)
        else:
            exact[c] = hdg
        print("%4d | %6d -> %5d %-9s | %5d %4d %s | %s%s"
              % (c, f0, f1, slew, y1, s1, "DECAY" if decayed else "ramp ",
                 ("heading = %d  (%s)" % (hdg, "+".join(why))) if hdg is not None
                 else "heading " + rng, ""))

    print("\n# EXACT applied headings: %s" % ", ".join("clk %d: %d" % kv for kv in sorted(exact.items())))

    # Forward-replay check: feed the piecewise-constant heading implied above back through the
    # 8f20 rules and require it to reproduce the captured 0x34/0x64/0x68 ladder tick for tick.
    print("\n# forward replay of FUN_005a8f20 with heading = 9258 (<=clk 639) then 765 / 763 / 762:")
    face, yaw, spd = st[clks[0]]
    curve = 6457  # P+0x6c, from the port at the same tick (diag_m5_t1i10_apply.gd)
    bad = 0
    for c in clks[1:]:
        hdg = 9258 if c <= 639 else (765 if c <= 647 else (763 if c <= 655 else 762))
        d = s16(hdg - face)
        ad = abs(d)
        xq = ad - 0x100
        steps = (xq + (0x3FF if xq < 0 else 0)) // 0x400 + 1
        face = hdg & 0xFFFF if steps < 2 else (face + (0x400 if d > 0 else -0x400)) & 0xFFFF
        if ad < 0x1555:
            yaw = hdg & 0xFFFF
            if spd < curve:
                spd = min(curve, spd + 0x106)
            elif spd > curve:
                spd = max(curve, spd - 0x106)
        else:
            spd = max(0, spd - 0x1CA)
        want = st[c]
        ok = (face, yaw, spd) == want
        bad += 0 if ok else 1
        if not ok:
            print("  clk %d MISMATCH replay=(%d,%d,%d) capture=(%d,%d,%d)"
                  % (c, face, yaw, spd, *want))
    print("  -> %s (%d mismatching ticks over clk %d-%d)"
          % ("EXACT MATCH" if bad == 0 else "DIVERGES", bad, clks[1], clks[-1]))


if __name__ == "__main__":
    main()
