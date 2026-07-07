#!/usr/bin/env python3
"""Drive a WATCH match to FULL TIME by clicking KICK OFF at each segment pause.

WATCH mode plays the 2D sim in ~20-min segments, pausing at the events board; the
KICK OFF button (320,457) resumes, half-time takes a few clicks. This watches the
live match struct and clicks whenever the segment clock is frozen, until the
full-time dispatch code (+0x1a38 == 10). No winedbg -- pure /proc/mem + xdotool.

Usage: autoresume.py <lpid> <base_hex> <out.log> [win_id] [max_secs]

Reconstructed 2026-07-07 for the clean (breakpoint-free) M4 re-drive; the original
was written inline in the M4 session and not committed.
"""
import struct
import subprocess
import sys
import time

CLK, PHASE, HALF, DISP = 0x450, 0x448, 0x19A0, 0x1A38
KICKOFF_XY = (320, 457)
CENTER_XY = (320, 240)
STALL = 4.0          # seconds of frozen clock before we treat it as a pause
FT_DISP = 10


def main() -> None:
    lpid, base, log = int(sys.argv[1]), int(sys.argv[2], 16), sys.argv[3]
    win = sys.argv[4] if len(sys.argv) > 4 else _win_id()
    max_secs = float(sys.argv[5]) if len(sys.argv) > 5 else 1800.0
    mem = open(f"/proc/{lpid}/mem", "rb", buffering=0)
    lf = open(log, "a", buffering=1)

    def u32(off: int) -> int:
        mem.seek(base + off)
        return struct.unpack("<I", mem.read(4))[0]

    def click(xy, n=1):
        for _ in range(n):
            subprocess.run(["xdotool", "mousemove", "--window", win,
                            str(xy[0]), str(xy[1]), "click", "1"], check=False)
            time.sleep(0.4)

    def emit(msg: str):
        lf.write(f"{round(time.time()-t0,1)} {msg}\n")

    t0 = time.time()
    last_clk = u32(CLK)
    last_change = t0
    clicks = 0
    stall_rounds = 0
    while True:
        if time.time() - t0 > max_secs:
            emit(f"TIMEOUT after {max_secs}s clk={u32(CLK)} half={u32(HALF)} disp={u32(DISP)}")
            break
        try:
            clk, phase, half, disp = u32(CLK), u32(PHASE), u32(HALF), u32(DISP)
        except (OSError, struct.error):
            emit("process_gone")
            break
        if disp == FT_DISP:
            emit(f"FULL TIME disp=10 clk={clk} half={half} clicks={clicks}")
            break
        if clk != last_clk:
            last_clk = clk
            last_change = time.time()
            stall_rounds = 0
        elif time.time() - last_change > STALL:
            # frozen clock -> segment/half-time pause; resume with the KICK OFF button ONLY.
            # (A center-pitch nudge opens the 2D player/sub overlay and traps the driver --
            #  observed 2026-07-07, do NOT reintroduce it.)
            click(KICKOFF_XY)
            clicks += 1
            stall_rounds += 1
            emit(f"resume click #{clicks} (frozen at clk={clk} phase={phase} half={half})")
            last_change = time.time()
        time.sleep(0.25)
    lf.write("done\n")
    lf.close()


def _win_id() -> str:
    out = subprocess.run(["xdotool", "search", "--name", "pm98 - Wine desktop"],
                         capture_output=True, text=True, check=False)
    return out.stdout.split()[0]


if __name__ == "__main__":
    main()
