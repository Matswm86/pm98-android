#!/usr/bin/env python3
"""Does the game's LCG advance while it sits IDLE, with no input at all?

This is the kill test for candidate 3 of `docs/re/M5_S90_GOAL2_NOT_REPRODUCIBLE.md`: *"the
banked reference is one sample of a family rather than a fixed target, because
`autoresume.py`'s KICK OFF click timing feeds the RNG."* If the stream advances on its own
while nothing is happening, then how long a capture pauses at a segment boundary changes
every draw after it, and comparing a fresh run against `capture2` past that boundary is
comparing against one sample — which retires the goal-2 item rather than localising it.

The RNG is `FUN_005ec250`, a plain LCG on `DAT_006d3184`
(`seed = seed * 0x015a4e35 + 0x269ec3`, returning `(seed >> 16) & 0x7fff`), with
`0x5ec230` / `0x5ec240` as its setter and getter. Because it is an LCG, the number of draws
between two observed seeds is recoverable exactly, not just "it moved": stepping the
recurrence forward until it matches gives the draw COUNT.

    m5_idle_seed_poll.py <rsp_port> [samples] [gap_seconds]

⚠ The winedbg stub takes ONE connection for its whole life, so this holds a single socket
and polls inside it. A second client — including a second run of this tool — gets nothing.
"""

from __future__ import annotations

import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from m5_gdbrsp_seedwatch import SEED_VA, Rsp  # noqa: E402

MUL = 0x015A4E35
ADD = 0x269EC3
MASK = 0xFFFFFFFF
# A run of the sim is ~33 draws a tick; a minute of idling at 62 fps could not plausibly
# exceed this, and an unbounded search would hang on a seed that was SET rather than drawn.
MAX_DRAWS = 20_000_000


def draws_between(a: int, b: int) -> int | None:
    """How many LCG steps take `a` to `b`, or None if `b` is not downstream within the cap."""
    s = a
    for n in range(1, MAX_DRAWS + 1):
        s = (s * MUL + ADD) & MASK
        if s == b:
            return n
    return None


def main() -> int:
    port = int(sys.argv[1])
    samples = int(sys.argv[2]) if len(sys.argv) > 2 else 6
    gap = float(sys.argv[3]) if len(sys.argv) > 3 else 5.0

    r = Rsp(port)
    r.cmd("?")

    def cont() -> None:
        p = "vCont;c"
        r.s.sendall(f"${p}#{sum(p.encode()) % 256:02x}".encode())

    def interrupt() -> None:
        r.s.sendall(b"\x03")
        r.wait_stop()

    def seed_now() -> int:
        raw = r.cmd(f"m{SEED_VA:x},4")
        return int.from_bytes(bytes.fromhex(raw), "little")

    prev = None
    prev_t = None
    moved = 0
    for i in range(samples):
        if i:
            interrupt()
        seed = seed_now()
        now = time.time()
        if prev is None:
            print(f"[{i}] seed {seed:#010x}")
        else:
            dt = now - prev_t
            if seed == prev:
                print(f"[{i}] seed {seed:#010x}   +{dt:5.1f}s   NO CHANGE")
            else:
                moved += 1
                n = draws_between(prev, seed)
                rate = f"{n / dt:,.0f} draws/s" if n else "count > cap"
                print(
                    f"[{i}] seed {seed:#010x}   +{dt:5.1f}s   MOVED  "
                    f"{n if n else '?'} draws   {rate}"
                )
        prev, prev_t = seed, now
        if i < samples - 1:
            cont()  # let the game run, untouched, for the gap
            time.sleep(gap)
    r.cmd("D", timeout=5)

    print()
    if moved:
        print(
            f"VERDICT: the LCG advances with NO input ({moved}/{samples - 1} intervals). "
            "Pause length changes the stream, so a capture's click timing is part of its "
            "result. Candidate 3 CONFIRMED."
        )
    else:
        print(
            f"VERDICT: the LCG did NOT move over {samples - 1} idle intervals. Idling does "
            "not consume the stream on this screen; candidate 3 is not supported here."
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
