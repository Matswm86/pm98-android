#!/usr/bin/env python3
"""Click KICK OFF whenever an RSP capture's output file stops growing.

`autoresume.py` reads the live match struct through `/proc/<lpid>/mem`, which is
Yama-blocked at `ptrace_scope=1` on this box, and the RSP stub takes exactly ONE
connection — the capture already holds it. So a WATCH segment pause during a capture
had no driver at all: the run just sat there (s59 stalled at clk 2837 for exactly this
reason, and was stopped by hand).

The capture's own streamed jsonl is the signal that needs no second connection. Rows
land continuously while the match plays and stop dead when the events board goes up, so
"file mtime older than STALL seconds" is the pause, and the KICK OFF button (320,457)
is the resume. The KICK OFF button ONLY — a centre-pitch nudge opens the modal
player/substitution overlay and traps the driver (observed 2026-07-07).

Point it at the capture's PROGRESS LOG, not its jsonl: the run-up phase writes no rows
at all (it only banks `runup_done`), so a jsonl watcher spends the whole ~50-minute
run-up believing the match is paused and clicking into a live game. The log gets a line
every 200 stops in both phases, which is the heartbeat that actually covers the run.

Usage: resume_watchdog.py <progress.log> <log> [stall_secs] [max_secs]
Env: DISPLAY, PM98_DESKTOP (the window is "<PM98_DESKTOP> - Wine desktop").
"""

import os
import subprocess
import sys
import time
from pathlib import Path

KICKOFF_XY = (320, 457)


def _win_id() -> str:
    name = f"{os.environ.get('PM98_DESKTOP', 'pm98')} - Wine desktop"
    out = subprocess.run(
        ["xdotool", "search", "--name", name], capture_output=True, text=True, check=False
    )
    ids = out.stdout.split()
    if not ids:
        raise SystemExit(f"no window named {name!r} on DISPLAY={os.environ.get('DISPLAY')}")
    return ids[0]


def main() -> None:
    out = Path(sys.argv[1])
    log = open(sys.argv[2], "a", buffering=1)  # noqa: SIM115 — long-lived progress log
    stall = float(sys.argv[3]) if len(sys.argv) > 3 else 60.0
    max_secs = float(sys.argv[4]) if len(sys.argv) > 4 else 86400.0
    win = _win_id()
    t0 = time.time()
    clicks = 0

    def emit(msg: str) -> None:
        log.write(f"{round(time.time() - t0, 1)} {msg}\n")

    emit(f"watching {out} win={win} stall={stall}s")
    while time.time() - t0 < max_secs:
        time.sleep(5.0)
        if not out.exists():
            continue
        age = time.time() - out.stat().st_mtime
        if age < stall:
            continue
        subprocess.run(
            [
                "xdotool",
                "mousemove",
                "--window",
                win,
                str(KICKOFF_XY[0]),
                str(KICKOFF_XY[1]),
                "click",
                "1",
            ],
            check=False,
        )
        clicks += 1
        emit(f"resume click #{clicks} (output idle {round(age, 1)}s, size={out.stat().st_size})")
        # Give the board dismissal time to land before the next idle test, or a single
        # pause turns into a click storm that can walk off the KICK OFF button.
        time.sleep(stall)
    emit(f"exit after {clicks} clicks")


if __name__ == "__main__":
    main()
