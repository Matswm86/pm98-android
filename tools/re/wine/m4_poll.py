#!/usr/bin/env python3
"""Poll the live MANAGER.EXE match struct to a JSONL timeline (the M4 oracle reference).

Usage: m4_poll.py <lpid> <match_base_hex> <out.jsonl>

Reads at ~200 Hz; writes one JSON line whenever any tracked field changes.
Tracked (offsets per docs/re/MATCH_TICK_DRIVER_MAP.md / run_outer_oracle.sh):
  +0x448 phase | +0x450 segment clock | +0x454 over-counter | +0x19a0 half
  +0x19a8 banked clock | +0x19ac scale | +0x19b0/+0x19b4 score copies
  +0x478/+0x798 team scores | +0x1a38 dispatch code | seed @0x006d3184
Raw 0x1a18..0x1a58 window is logged as hex on every change (event-queue forensics).
Exits when the process dies or after 90 s with no change once half>=1 was seen.
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
SEED_VA = 0x006D3184


def main() -> None:
    lpid, base, out = int(sys.argv[1]), int(sys.argv[2], 16), sys.argv[3]
    mem = open(f"/proc/{lpid}/mem", "rb", buffering=0)
    fo = open(out, "a", buffering=1)

    def u32(addr: int) -> int:
        mem.seek(addr)
        return struct.unpack("<I", mem.read(4))[0]

    last = None
    t0 = time.time()
    last_change = t0
    seen_h2 = False
    n = 0
    while True:
        try:
            snap = {k: u32(base + off) for k, off in FIELDS.items()}
            snap["seed"] = u32(SEED_VA)
            mem.seek(base + 0x1A18)
            qraw = mem.read(0x40).hex()
        except (OSError, struct.error):
            fo.write(json.dumps({"t": time.time() - t0, "event": "process_gone"}) + "\n")
            break
        n += 1
        if snap != last:
            rec = {"t": round(time.time() - t0, 4), **snap, "q": qraw}
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
