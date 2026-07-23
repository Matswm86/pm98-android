"""Dump a function's disassembly from a start VA until a terminating ret/int3 run.

Usage: python fdump.py 0x587400 [max_bytes]
"""

from __future__ import annotations

import sys

from pe import PE


def dump(pe: PE, start: int, max_bytes: int = 0x400) -> None:
    code = pe.read_va(start, max_bytes)
    last_was_ret = False
    for insn in pe.md.disasm(code, start):
        # annotate absolute call/jmp targets and data refs
        note = ""
        if insn.mnemonic in ("call", "jmp") and insn.op_str.startswith("0x"):
            note = ""
        print(f"  {insn.address:#010x}: {insn.bytes.hex():<20} {insn.mnemonic} {insn.op_str}{note}")
        if insn.mnemonic == "ret" or insn.mnemonic.startswith("ret"):
            # keep going a little in case of padding then next func; stop after ret+pad
            last_was_ret = True
        elif last_was_ret and insn.mnemonic in ("int3", "nop"):
            continue
        elif last_was_ret:
            break


if __name__ == "__main__":
    pe = PE()
    start = int(sys.argv[1], 0)
    n = int(sys.argv[2], 0) if len(sys.argv) > 2 else 0x400
    dump(pe, start, n)
