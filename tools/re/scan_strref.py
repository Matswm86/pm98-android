#!/usr/bin/env python3
"""Find .text sites that reference given .rdata string VAs (push imm32 / mov imm32 /
lea / cmp). Used to locate the CLUB FEE / YEARLY WAGE / VALUE renderers -> the
value/wage getter (the real formula)."""
from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from capstone import x86  # noqa: E402
from pe import PE  # noqa: E402

TARGETS = {int(a, 16) for a in sys.argv[1:]} or {0x65B7C0, 0x65BE64, 0x65B66C}
pe = PE()
text = next(s for s in pe.sections if s.name == ".text")

hits = []
for ins in pe.disasm_va(text.vma, text.size):
    for op in ins.operands:
        if op.type == x86.X86_OP_IMM and op.imm in TARGETS:
            hits.append((ins.address, op.imm, ins.mnemonic, ins.op_str))
        elif op.type == x86.X86_OP_MEM and op.mem.disp in TARGETS and op.mem.base == 0 and op.mem.index == 0:
            hits.append((ins.address, op.mem.disp, ins.mnemonic, ins.op_str))

for va, tgt, mn, ops in hits:
    print(f"  {va:#08x}  ->{tgt:#x}  {mn} {ops}")
print(f"# {len(hits)} refs to {[hex(t) for t in TARGETS]}")
