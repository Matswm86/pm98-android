#!/usr/bin/env python3
"""Find where player+0x74 (the runtime WAGE float, morale_re.md) is WRITTEN.

Scans .text for any store whose memory operand is [reg + 0x74] (fstp/fst/mov),
and reports the VA + mnemonic. Then, for float stores, prints a window so we can
see whether core4 attr bytes (+0x9c..+0x9f) or FUN_00534570 feed it.
"""
from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from capstone import x86  # noqa: E402
from pe import PE  # noqa: E402

pe = PE()
text = next(s for s in pe.sections if s.name == ".text")

STORE_MNEMS = {"mov", "fstp", "fst", "fistp", "fist", "fiadd", "add", "and", "or"}
hits = []
for ins in pe.disasm_va(text.vma, text.size):
    if ins.mnemonic not in STORE_MNEMS:
        continue
    for op in ins.operands:
        if op.type == x86.X86_OP_MEM and op.mem.disp == 0x74 and op.mem.base != 0 and op.mem.index == 0:
            # write-position: for mov, must be dest (op[0]); for fstp/fst always store
            base = ins.reg_name(op.mem.base)
            if ins.mnemonic == "mov" and ins.operands[0].type != x86.X86_OP_MEM:
                continue
            hits.append((ins.address, ins.mnemonic, base, ins.op_str))
            break

print(f"# stores to [reg+0x74]: {len(hits)}")
floatw = [h for h in hits if h[1] in ("fstp", "fst")]
print(f"# float stores (fstp/fst) to [reg+0x74]: {len(floatw)}")
for va, mn, base, ops in floatw:
    print(f"  {va:#08x}  {mn:5} {ops}   (base {base})")

# For each float store, scan back up to 60 insns for core4 attr reads (+0x9c..0x9f)
# or a call to FUN_00534570 (0x534570).
print("\n# context around each float store to +0x74")
for va, mn, base, ops in floatw:
    start = va - 0x140
    core4 = False
    call534570 = False
    window = []
    for ins in pe.disasm_va(start, va - start + 8):
        window.append(ins)
    for ins in window:
        for op in ins.operands:
            if op.type == x86.X86_OP_MEM and op.mem.disp in (0x9c, 0x9d, 0x9e, 0x9f):
                core4 = True
        if ins.mnemonic == "call" and "0x534570" in ins.op_str:
            call534570 = True
    print(f"  store@{va:#x}: core4_read={core4} calls_534570={call534570}")
