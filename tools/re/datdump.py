"""Dump a data region as u32 words with string-pointer annotation.

Usage: python datdump.py 0x6622e8 72        # start, byte count
"""

from __future__ import annotations

import struct
import sys

from pe import PE


def main() -> None:
    pe = PE()
    start = int(sys.argv[1], 0)
    n = int(sys.argv[2], 0) if len(sys.argv) > 2 else 128
    raw = pe.read_va(start, n)
    for off in range(0, len(raw) - 3, 4):
        va = start + off
        w = struct.unpack_from("<I", raw, off)[0]
        anno = ""
        sec = pe.sec_for_va(w)
        if sec and sec.name in (".rdata", ".data"):
            s = pe.cstring_at_va(w, 48)
            if s and all(32 <= ord(c) < 127 for c in s[:1]):
                anno = f'  -> "{s}"'
        print(f"  {va:#010x}: {w:#010x}  ({w:>12}){anno}")


if __name__ == "__main__":
    main()
