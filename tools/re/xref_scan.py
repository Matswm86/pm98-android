"""Find 4-byte little-endian absolute references to target VAs across the image.

Usage: python xref_scan.py 0x662c04 0x662b24 ...
Prints every file offset whose 4 bytes equal the target VA, with the containing
section and (for .text hits) the disassembled instruction that embeds it.
"""

from __future__ import annotations

import struct
import sys

from pe import PE


def find_le32(pe: PE, target: int) -> list[int]:
    needle = struct.pack("<I", target)
    hits = []
    start = 0
    while True:
        i = pe.data.find(needle, start)
        if i < 0:
            break
        hits.append(i)
        start = i + 1
    return hits


def insn_at_foff(pe: PE, foff: int):
    """Disassemble a small window ending near foff to find the instruction
    whose bytes include the immediate at foff. Returns (va, mnemonic, opstr) or None."""
    try:
        va = pe.foff_to_va(foff)
    except ValueError:
        return None
    # back up to catch the instruction start (immediates sit at insn end)
    for back in range(1, 12):
        base_va = va - back
        for insn in pe.disasm_va(base_va, back + 6):
            if insn.address <= va < insn.address + insn.size:
                return (insn.address, insn.mnemonic, insn.op_str)
            if insn.address > va:
                break
    return None


def main() -> None:
    pe = PE()
    for arg in sys.argv[1:]:
        target = int(arg, 0)
        hits = find_le32(pe, target)
        print(f"\n=== xrefs to {target:#x}  ({len(hits)} raw hit(s)) ===")
        for foff in hits:
            sec = pe.sec_for_foff(foff)
            secname = sec.name if sec else "?"
            if secname == ".text":
                r = insn_at_foff(pe, foff)
                if r:
                    va, mn, ops = r
                    print(f"  foff {foff:#08x}  .text  @{va:#010x}: {mn} {ops}")
                else:
                    print(f"  foff {foff:#08x}  .text  (no insn decoded)")
            else:
                va = pe.foff_to_va(foff)
                print(f"  foff {foff:#08x}  {secname}  VA {va:#010x} (data ptr)")


if __name__ == "__main__":
    main()
