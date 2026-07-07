#!/usr/bin/env python3
"""Per-frame seed trace while winedbg holds a breakpoint on the outer step 0x5983f0.

Usage: m4_seedtrace.py <lpid> <match_base_hex> <fifo> <frames> <out.csv>

Each round: send "cont" to the winedbg FIFO, wait for winedbg to log the next
"Stopped on breakpoint" (wine suspends threads via the wineserver, so /proc
thread states stay 'S' -- the log is the only reliable stop signal), then read
seed @0x006d3184, match clock +0x450, phase +0x448, half +0x19a0 via /proc/mem.
Row N is therefore the state at the ENTRY of outer frame N (frame 0 = the row
written before the first cont).

Usage: m4_seedtrace.py <lpid> <match_base_hex> <fifo> <frames> <out.csv> <wdbg.log>
"""
import struct
import sys
import time

SEED_VA = 0x006D3184


def stops(log: str) -> int:
    with open(log, errors="replace") as f:
        return f.read().count("Stopped on breakpoint")


def main() -> None:
    lpid, base = int(sys.argv[1]), int(sys.argv[2], 16)
    fifo, frames, out, log = sys.argv[3], int(sys.argv[4]), sys.argv[5], sys.argv[6]
    mem = open(f"/proc/{lpid}/mem", "rb", buffering=0)
    base_stops = stops(log)

    def u32(addr: int) -> int:
        mem.seek(addr)
        return struct.unpack("<I", mem.read(4))[0]

    def row(n: int, fo) -> None:
        fo.write(f"{n},{u32(SEED_VA)},{u32(base+0x450)},{u32(base+0x448)},{u32(base+0x19A0)}\n")

    with open(out, "w") as fo:
        fo.write("frame,seed,clk,phase,half\n")
        row(0, fo)
        for n in range(1, frames + 1):
            with open(fifo, "w") as f:
                f.write("cont\n")
            deadline = time.time() + 10
            while stops(log) < base_stops + n:
                if time.time() > deadline:
                    print(f"frame {n}: no stop within 10s", file=sys.stderr)
                    sys.exit(1)
                time.sleep(0.002)
            row(n, fo)
    print(f"traced {frames} frames -> {out}")


if __name__ == "__main__":
    main()
