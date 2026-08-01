#!/usr/bin/env python3
"""Enumerate EVERY call site of the shadowed blit and read the arguments each one pushes.

`PMShadow` shipped `THR = 0x21` documented as "the same at every witnessed site". It was,
because only two sites had ever been looked at. s87 found a third (`0x4f4ee7`, a RIDI kit
blit) pushing `0x10, 0x40, 0xff` and corrected the note without correcting the constant.
This closes it by measurement: byte-scan `.text` for `E8 rel32` targeting the thunk
`FUN_004b7f60` or the core `FUN_005cbea0`, then walk BACKWARDS from each site over the
instruction forms these call sequences actually use and recover the three leading arguments.

`FUN_005cbea0(param_1 = flags, param_2 = thr, param_3 = cap, ...)` is `__cdecl`-ish with the
arguments pushed right to left, so the LAST push before the call is `param_1`, the one
before it `param_2` and the one before that `param_3`. A site whose three leading arguments
are not all immediates is reported as such rather than guessed at -- several push registers
or memory, and those are the ones whose ramp is data-driven.

    python3 tools/re/probe_shadow_sites.py [--exe PATH]

Prints one row per site and a summary of the DISTINCT (flags, thr, cap) triples, which is
the thing PMShadow needs: how many ramps the original actually has.
"""

from __future__ import annotations

import argparse
import struct
from collections import Counter
from pathlib import Path

from capstone import CS_ARCH_X86, CS_MODE_32, Cs

ROOT = Path(__file__).resolve().parents[2]
EXE = ROOT / "extracted" / "Premier Manager 98" / "MANAGER.EXE"
VA_BASE = 0x400C00  # file offset + VA_BASE = VA (docs/re/hub_circle_re.md)
THUNK = 0x4B7F60
CORE = 0x5CBEA0


def pushes_before(data: bytes, off: int, want: int) -> list[tuple[str, int | None]]:
    """The last `want` PUSH operands before the call at file offset `off`, nearest-first.

    A backwards byte walk cannot do this -- the instruction immediately before the call is
    usually `mov ecx, <reg>` and the pushes are interleaved with the stack-struct setup this
    blit's callers build. So decode FORWARDS with capstone from every start in a window and
    keep the LONGEST decode that lands exactly on the call instruction; a stream that hits
    the call on an instruction boundary is in sync with it by construction, which is what
    makes this safe on an image whose linear sweep desynchronises.
    """
    md = Cs(CS_ARCH_X86, CS_MODE_32)
    best: list = []
    for start in range(max(0, off - 192), off):
        seq = []
        ok = False
        for ins in md.disasm(data[start : off + 5], start):
            if ins.address == off:
                ok = ins.mnemonic == "call"
                break
            seq.append(ins)
        if ok and len(seq) > len(best):
            best = seq
    out: list[tuple[str, int | None]] = []
    for ins in reversed(best):
        if ins.mnemonic != "push":
            continue
        op = ins.op_str
        imm = None
        if op.startswith("0x"):
            try:
                imm = int(op, 16)
            except ValueError:
                imm = None
        elif op.isdigit():
            imm = int(op)
        out.append((f"push {op}", imm))
        if len(out) >= want:
            break
    return out


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--exe", type=Path, default=EXE)
    args = ap.parse_args()
    data = args.exe.read_bytes()

    sites: list[int] = []
    for i in range(len(data) - 5):
        if data[i] != 0xE8:
            continue
        rel = struct.unpack_from("<i", data, i + 1)[0]
        target = (i + 5) + rel + VA_BASE
        if target in (THUNK, CORE):
            sites.append(i)
    print(f"{len(sites)} call sites of the shadow blit (thunk 0x{THUNK:x} / core 0x{CORE:x})\n")

    triples: Counter = Counter()
    rows = []
    for off in sites:
        va = off + VA_BASE
        pushes = pushes_before(data, off, 3)
        imms = [p[1] for p in pushes]
        while len(imms) < 3:
            imms.append(None)
        flags, thr, cap = imms[0], imms[1], imms[2]
        key = (flags, thr, cap)
        triples[key] += 1
        rows.append((va, [p[0] for p in pushes], key))
    for va, texts, key in rows:
        pretty = ", ".join("?" if v is None else f"0x{v:x}" for v in key)
        print(
            f"  0x{va:06x}  flags/thr/cap = {pretty:22s}  ({'; '.join(reversed(texts)) or 'no decodable pushes'})"
        )

    print("\ndistinct (flags, thr, cap) triples, most common first:")
    for key, n in triples.most_common():
        pretty = ", ".join("?" if v is None else f"0x{v:x}" for v in key)
        print(f"  ({pretty})  x{n}")
    resolved = sum(n for k, n in triples.items() if all(v is not None for v in k))
    print(f"\n{resolved} of {len(sites)} sites push all three as immediates")


if __name__ == "__main__":
    main()
