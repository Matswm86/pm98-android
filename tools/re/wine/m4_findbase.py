#!/usr/bin/env python3
"""Locate the live MANAGER.EXE match-struct base with ZERO winedbg breakpoints.

The perturbation caveat on the M4 reference (handoff-pm98-m4-wine-oracle) is that
the base was grabbed by breaking on the outer step 0x5983f0 and the breakpoints were
held through minutes 0-21. This scanner removes winedbg entirely: it reads
/proc/<lpid>/mem directly and finds the match object by its vtable pointer at
offset 0, disambiguated by the fixed scale field +0x19ac == 14400 (a 90-min match).

Usage: m4_findbase.py <lpid> [vtable_hex] [scale_expected]
Prints the base VA in hex (0x...) on success; nonzero exit on no/ambiguous match.

vtable default 0x6390e0, scale default 14400 -- both from the Villa/Bolton reference;
the main EXE loads at a fixed base under wine (no ASLR), so the vtable VA is stable.
"""
import struct
import sys
from pathlib import Path

VTABLE = 0x6390E0
SCALE_OFF, SCALE_VAL = 0x19AC, 14400
PHASE_OFF, DISP_OFF = 0x448, 0x1A38


def rw_regions(lpid: int):
    for line in Path(f"/proc/{lpid}/maps").read_text().splitlines():
        parts = line.split()
        addr, perms = parts[0], parts[1]
        start, end = (int(x, 16) for x in addr.split("-"))
        if start < (1 << 32) and perms.startswith("rw"):
            yield start, end


def main() -> None:
    lpid = int(sys.argv[1])
    vtable = int(sys.argv[2], 16) if len(sys.argv) > 2 else VTABLE
    scale_val = int(sys.argv[3]) if len(sys.argv) > 3 else SCALE_VAL
    needle = struct.pack("<I", vtable)
    hits = []
    with open(f"/proc/{lpid}/mem", "rb", buffering=0) as mem:
        def u32(a: int):
            mem.seek(a)
            b = mem.read(4)
            return struct.unpack("<I", b)[0] if len(b) == 4 else None

        for start, end in rw_regions(lpid):
            mem.seek(start)
            try:
                data = mem.read(end - start)
            except OSError:
                continue
            i = data.find(needle)
            while i != -1:
                base = start + i
                if u32(base + SCALE_OFF) == scale_val:
                    hits.append((base, u32(base + PHASE_OFF), u32(base + DISP_OFF)))
                i = data.find(needle, i + 1)
    if not hits:
        print("no match-struct base found (vtable+scale)", file=sys.stderr)
        sys.exit(1)
    for base, phase, disp in hits:
        print(f"# candidate base=0x{base:08x} phase={phase} disp={disp}", file=sys.stderr)
    print(f"0x{hits[0][0]:08x}")


if __name__ == "__main__":
    main()
