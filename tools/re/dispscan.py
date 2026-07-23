"""Scan .text for instructions touching a given struct displacement.

Linear capstone sweep over the whole .text section (data-in-code produces noise;
cross-check any hit with fdump.py). Filters keep the output usable:

    python dispscan.py 0x9a                 # any insn with a [reg+0x9a] operand
    python dispscan.py 0x1c --write         # writes only (memory is operand 0)
    python dispscan.py 0x70 --mn fld,fstp   # restrict to given mnemonics

Used to find the writers of the transfer/offer struct fields that the accept test
(FUN_005889c0) and the negotiation steppers read.
"""

from __future__ import annotations

import argparse

from capstone import CS_OP_MEM, x86_const
from pe import PE


def sweep_text(pe: PE):
    """Linear sweep of the whole .text, restarting one byte on after any
    undecodable byte (capstone's disasm() otherwise stops at the first bad byte,
    which silently truncated earlier scans well before the 0x58xxxx range)."""
    text = next(s for s in pe.sections if s.name == ".text")
    code = pe.data[text.foff : text.foff + text.size]
    pos = 0
    while pos < len(code):
        n = 0
        for insn in pe.md.disasm(code[pos:], text.vma + pos):
            yield insn
            n += insn.size
        pos += n + 1


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("disp", help="displacement, e.g. 0x9a")
    ap.add_argument("--write", action="store_true", help="only when memory is operand 0")
    ap.add_argument("--mn", default="", help="comma-separated mnemonic whitelist")
    ap.add_argument("--base", default="", help="only this base register (e.g. esi)")
    args = ap.parse_args()

    disp = int(args.disp, 0)
    mns = {m.strip() for m in args.mn.split(",") if m.strip()}

    pe = PE()
    for insn in sweep_text(pe):
        if mns and insn.mnemonic not in mns:
            continue
        for i, op in enumerate(insn.operands):
            if op.type != CS_OP_MEM or op.mem.disp != disp:
                continue
            if op.mem.base == 0 or op.mem.base == x86_const.X86_REG_ESP:
                continue  # stack frames / absolutes are not struct fields
            if args.write and i != 0:
                continue
            if args.base and insn.reg_name(op.mem.base) != args.base:
                continue
            print(f"  {insn.address:#010x}: {insn.mnemonic} {insn.op_str}")
            break


if __name__ == "__main__":
    main()
