#!/usr/bin/env python3
"""Dump the JUG.PGF player-render per-kind tables from MANAGER.EXE (raw .data bytes)
and reconstruct the frame `base` offsets, validating against the real JUG.PGF count.

Every value is read straight from MANAGER.EXE .data via pe.PE — nothing inferred.
The `base` algorithm is the one in FUN_005a2830 (the one-time table initializer,
guarded by DAT_00674628):

    base[k] = running_total
    if mode[k] > 0:  running_total += fpd[k] * mode[k]

i.e. mode[k] is the literal stored-direction count; NEGATIVE mode kinds add 0 frames
(they are mirror-twins that reuse a positive kind's frames at render time, see
FUN_005a5460). The reconstructed total equals JUG.PGF's real header frameCount
(4211), which is the proof the model is complete and correct.

Usage:  python3 tools/re/dump_jug_kind_tables.py
"""
from __future__ import annotations

import struct
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from pe import PE  # noqa: E402

# VAs verified from FUN_005a5460 / FUN_005a50c0 / FUN_005a2830 disassembly.
VA_MODE = 0x6650E0  # DAT_006650e0  signed dir-count; sign = mirror flag
VA_FPD = 0x664FB8  # DAT_00664fb8  frames (phases) per direction
VA_SELFMAP = 0x665208  # DAT_00665208  next-state kind on animation loop-end
VA_FLAG = 0x665330  # DAT_00665330  per-kind sub-octant refine flag (indexed & 0x7f)
VA_THR8 = 0x6653E0  # DAT_006653e0  8 non-uniform octant thresholds (u16)
VA_THR12 = 0x665430  # DAT_00665430  12 uniform thresholds (u16) - unused: no |mode|==12
N_KINDS = 74  # tables are three parallel 0x128-byte (74*i32) blocks, back to back
JUG_PGF_FRAMES = 4211  # independently read from DATSIM.PKF LFGP bank @0x1547ea


def main() -> int:
    pe = PE()

    def i32s(va: int, n: int) -> list[int]:
        return list(struct.unpack_from(f"<{n}i", pe.read_va(va, 4 * n), 0))

    def u16s(va: int, n: int) -> list[int]:
        return list(struct.unpack_from(f"<{n}H", pe.read_va(va, 2 * n), 0))

    mode = i32s(VA_MODE, N_KINDS)
    fpd = i32s(VA_FPD, N_KINDS)
    selfmap = i32s(VA_SELFMAP, N_KINDS)
    flag = list(pe.read_va(VA_FLAG, N_KINDS))

    base, total = [], 0
    for k in range(N_KINDS):
        base.append(total)
        if mode[k] > 0:
            total += fpd[k] * mode[k]

    print(f"# JUG per-kind render tables (MANAGER.EXE .data, {N_KINDS} kinds 0..{N_KINDS-1})")
    print(f"{'k':>3} {'mode':>5} {'fpd':>4} {'base':>6} {'next':>5} {'flag':>4}  stored")
    for k in range(N_KINDS):
        m = mode[k]
        stored = m if m > 0 else f"(mirror of +{abs(m)})" if m < 0 else "-"
        print(f"{k:>3} {m:>5} {fpd[k]:>4} {base[k]:>6} {selfmap[k]:>5} {flag[k]:>4}  {stored}")

    print()
    print("octant thresholds DAT_006653e0 (u16):", u16s(VA_THR8, 8))
    print("12-way thresholds DAT_00665430 (u16):", u16s(VA_THR12, 12), "(unused: no |mode|==12)")
    print()
    print(f"reconstructed frame total = {total}   JUG.PGF header count = {JUG_PGF_FRAMES}")
    ok = total == JUG_PGF_FRAMES
    print("VALIDATION:", "PASS (exact)" if ok else "FAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
