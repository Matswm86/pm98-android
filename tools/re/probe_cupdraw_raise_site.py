#!/usr/bin/env python3
"""Read whether the CUP DRAW screen's RAISE site tests the MANAGER's club.

Five career drives have failed to bank a SEMIFINAL / FINAL cup draw, and every one of them
was planned around "the draw only appears for a round your own club is still in". That
sentence is the PORT's own gate -- `Career._queue_cup_draw`'s comment says so plainly
("DECLARED OURS: no frame shows what the original does for a non-participant"). The refs
README restated it as if it were a fact about the original. It has never been read.

This reads it. The CUP DRAW screen's code range is `0x4da000..0x4db000` (s87, found from
`GROUPS` at .rdata VA 0x6570f8 whose only xref is 0x4da6a4). The question is whether the
site that RAISES that screen tests the human manager's club at all.

Method, all measurement, no inference:

1. byte-scan the whole `.text` for `E8 rel32` and `E9 rel32` whose TARGET lands in the
   screen's range -- those targets are the range's entry points;
2. for each entry point, list its CALLERS;
3. decode every caller's basic block leading up to the call and report the comparisons in
   it, with special attention to the club-identity idioms this image uses:
   `club+0x5c != 0xffff` (the human-managed-club test `FUN_0057d2d0` gates news on) and the
   0x26ae / 0x26de / 0x26e4 club-id sentinels the s85 sweep named.

    python3 tools/re/probe_cupdraw_raise_site.py

Prints the entry points, their callers, and a VERDICT line per caller: whether a
manager's-club test is present in the block that decides the call.
"""

from __future__ import annotations

import argparse
import struct
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from pe import PE  # noqa: E402

CUPDRAW_LO = 0x4DA000
CUPDRAW_HI = 0x4DB000

# The club-identity idioms this image is known to use, each one read off a prior session
# rather than guessed: FUN_0057d2d0's human-managed test, and the three club-id sentinels
# the s85 `[reg+0x10]` sweep enumerated.
MANAGED_CLUB_TEST = 0x5C  # club record + 0x5c, compared against 0xffff
CLUB_SENTINELS = (0x26AE, 0x26DE, 0x26E4)


def scan_calls(pe: PE) -> dict[int, list[int]]:
    """Return {target_va: [caller_va, ...]} for every E8/E9 rel32 landing in the range."""
    sec = next(s for s in pe.sections if s.name == ".text")
    data = pe.data[sec.foff : sec.foff + sec.size]
    out: dict[int, list[int]] = {}
    for i in range(len(data) - 5):
        op = data[i]
        if op not in (0xE8, 0xE9):
            continue
        rel = struct.unpack_from("<i", data, i + 1)[0]
        site = sec.vma + i
        target = site + 5 + rel
        if CUPDRAW_LO <= target < CUPDRAW_HI:
            out.setdefault(target, []).append(site)
    return out


def block_before(pe: PE, call_va: int, window: int = 0x180):
    """Decode forwards from `window` bytes back, keeping the instructions that actually
    reach `call_va`. A backwards byte walk cannot work on this image (s88): the linear
    sweep desynchronises. Forward-decode from several starts and keep the longest run
    that lands exactly on the call."""
    best: list = []
    for back in range(window, 3, -1):
        start = call_va - back
        try:
            insns = list(pe.disasm_va(start, back + 8))
        except ValueError:
            continue
        run = []
        for ins in insns:
            if ins.address > call_va:
                break
            run.append(ins)
            if ins.address == call_va:
                if len(run) > len(best):
                    best = run
                break
    return best


def describe(pe: PE, insns) -> tuple[list[str], list[str]]:
    """Return (rendered lines, hits) where hits name club-identity idioms found."""
    lines, hits = [], []
    for ins in insns:
        lines.append(f"    {ins.address:#010x}  {ins.mnemonic:<7} {ins.op_str}")
        text = ins.op_str
        if ins.mnemonic in ("cmp", "test", "mov", "movzx", "movsx"):
            if "+ 0x5c]" in text:
                hits.append(f"{ins.address:#x}: touches +0x5c ({text})")
            for sent in CLUB_SENTINELS:
                if f"{sent:#x}" in text:
                    hits.append(f"{ins.address:#x}: club sentinel {sent:#x} ({text})")
    return lines, hits


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--exe", type=Path, default=None)
    args = ap.parse_args()
    pe = PE(args.exe) if args.exe else PE()

    print(f"CUP DRAW screen range {CUPDRAW_LO:#x}..{CUPDRAW_HI:#x}")
    targets = scan_calls(pe)
    if not targets:
        print("NO call/jmp targets land in the range -- the screen is reached another way.")
        return

    print(f"\n{len(targets)} entry point(s) called from outside:")
    for tgt in sorted(targets):
        callers = sorted(set(targets[tgt]))
        outside = [c for c in callers if not (CUPDRAW_LO <= c < CUPDRAW_HI)]
        print(f"\n  entry {tgt:#010x}: {len(callers)} site(s), "
              f"{len(outside)} from OUTSIDE the range")
        for c in outside:
            print(f"    caller {c:#010x}")

    print("\n=== blocks leading to each OUTSIDE caller ===")
    verdicts = []
    for tgt in sorted(targets):
        for c in sorted(set(targets[tgt])):
            if CUPDRAW_LO <= c < CUPDRAW_HI:
                continue
            print(f"\n-- caller {c:#010x} -> entry {tgt:#010x}")
            insns = block_before(pe, c)
            lines, hits = describe(pe, insns)
            print("\n".join(lines[-40:]))
            if hits:
                print("  CLUB-IDENTITY IDIOMS:")
                for h in hits:
                    print(f"    {h}")
            verdicts.append((c, tgt, bool(hits)))

    print("\n=== VERDICT ===")
    for c, tgt, hit in verdicts:
        print(f"  {c:#010x} -> {tgt:#010x}: "
              f"{'club test PRESENT in the decoded block' if hit else 'no club test in the decoded block'}")


if __name__ == "__main__":
    main()
