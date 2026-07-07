#!/usr/bin/env python3
"""Poll the live MANAGER.EXE match struct + BALL/CARRIER trajectory to a JSONL timeline.

Usage: m5_poll_traj.py <lpid> <match_base_hex> <out.jsonl>

Superset of m4_poll.py (the M4 oracle reference poller): it keeps every match-scalar
field m4 tracked, and ADDS the ball kinematics and the ball CONTROLLER (carrier) so the
M5-divergence disambiguation has the REAL per-tick carrier downfield trajectory to diff
against the port CSV (scratchpad m5_tick_trace.csv). See
docs/re/M5_DIVERGENCE1_OPENPLAY_TRACE.md and the s21 findings doc.

Offsets (all verified this session against frame0_struct_import.json + keeper_advance
decompile, base = the match struct returned by m4_findbase.py):
  BALL is EMBEDDED at match_base + 0x1610 (frame0: ball _va - match_base == 0x1610).
    ball.x = +0x1614  ball.y = +0x1618  ball.z = +0x161c   (keeper_advance reads 0x1614/8)
    ball.vx= +0x1630  ball.vy= +0x1634  ball.vz= +0x1638
    ball.controller = +0x1650  (ball+0x40; a VA -> the carrying player struct, or 0)
  CARRIER (if controller != 0), read at *(controller):
    x = +0x4  y = +0x8  z = +0xc  slot = +0x2bc (0..10; 0 == GK) team = +0x2b8  act = +0x40
  match scalars (m4): +0x448 phase | +0x450 clk | +0x19a0 half | +0x19a8 banked
    | +0x19ac scale | +0x478/+0x798 team scores | +0x1a38 disp | seed @0x006d3184

Writes one JSON line whenever ANY tracked field changes (~200 Hz sampler). Because the
carrier x/y is now tracked, every displacement of the ball-holder emits a row -> a dense
downfield trajectory. Exits like m4_poll (process gone, or 90 s quiescent after half>=1).
"""
import json
import struct
import sys
import time

FIELDS = {
    "phase": 0x448, "clk": 0x450, "over": 0x454, "half": 0x19A0,
    "banked": 0x19A8, "scale": 0x19AC, "sc0c": 0x19B0, "sc1c": 0x19B4,
    "sc0": 0x478, "sc1": 0x798, "disp": 0x1A38,
}
# ball fields, relative to match_base (ball embedded at +0x1610)
BALL = {
    "bx": 0x1614, "by": 0x1618, "bz": 0x161C,
    "bvx": 0x1630, "bvy": 0x1634, "bvz": 0x1638,
}
BALL_CTRL_OFF = 0x1650          # match_base+0x1650 == ball+0x40 controller VA
CARRIER = {"cx": 0x4, "cy": 0x8, "cz": 0xC, "cslot": 0x2BC, "cteam": 0x2B8, "cact": 0x40}
SEED_VA = 0x006D3184


def main() -> None:
    lpid, base, out = int(sys.argv[1]), int(sys.argv[2], 16), sys.argv[3]
    mem = open(f"/proc/{lpid}/mem", "rb", buffering=0)
    fo = open(out, "a", buffering=1)

    def u32(addr: int) -> int:
        mem.seek(addr)
        return struct.unpack("<I", mem.read(4))[0]

    def s32(addr: int) -> int:
        v = u32(addr)
        return v - 2**32 if v >= 2**31 else v

    last = None
    t0 = time.time()
    last_change = t0
    seen_h2 = False
    n = 0
    while True:
        try:
            snap = {k: u32(base + off) for k, off in FIELDS.items()}
            snap["seed"] = u32(SEED_VA)
            for k, off in BALL.items():
                snap[k] = s32(base + off)
            ctrl = u32(base + BALL_CTRL_OFF)
            snap["ctrl"] = ctrl
            if ctrl:
                for k, off in CARRIER.items():
                    snap[k] = s32(ctrl + off)
            else:
                for k in CARRIER:
                    snap[k] = None
        except (OSError, struct.error):
            fo.write(json.dumps({"t": time.time() - t0, "event": "process_gone"}) + "\n")
            break
        n += 1
        if snap != last:
            rec = {"t": round(time.time() - t0, 4), **snap}
            fo.write(json.dumps(rec) + "\n")
            last = snap
            last_change = time.time()
            if snap["half"] >= 1:
                seen_h2 = True
        if seen_h2 and time.time() - last_change > 90:
            fo.write(json.dumps({"t": time.time() - t0, "event": "quiescent_after_h2"}) + "\n")
            break
        time.sleep(0.005)
    fo.write(json.dumps({"event": "polls", "n": n}) + "\n")
    fo.close()


if __name__ == "__main__":
    main()
