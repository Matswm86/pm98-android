#!/usr/bin/env python3
"""Parse the detailed team records in EQUIPOS.PKF (PC Fútbol / PM98 engine).

Index: 38-byte entries marked by SIG, each carrying a u32 dataOffset (+26) and
u32 size (+30). Each record's data block begins with the ASCII header
"Copyright (c)1996 Dinamic Multimedia" + 1 flag byte + 5 header bytes, then a
run of length-prefixed strings [u16 len][cipher bytes] (name, stadium, full
name, manager, ...), then a numeric block (founding year, capacity, finances).

Cipher: alphabet[b & 0x1f] (pair-swapped, A=0); 0x41=space, 0x4f='.', b>=0x80 are
accented letters (rendered '+').  See docs/FORMATS.md.
"""
from __future__ import annotations
import json
import struct
from pathlib import Path

GAME = Path(__file__).resolve().parent.parent / "extracted" / "Premier Manager 98"
SIG = bytes.fromhex("9a919abe5f68")
MM = b"Dinamic Multimedia"

_FWD = {L: (L if L % 2 == 0 else L + 2) for L in range(26)}
C2 = {c: chr(65 + L) for L, c in _FWD.items()}
C2[1] = " "


def ch(b: int) -> str:
    if b == 0x4F:
        return "."
    if b >= 0x80:
        return "+"
    return C2.get(b & 0x1F, "?")


def _is_strbyte(b: int) -> bool:
    return b in (0x41, 0x4F) or b <= 0x1B or 0x20 <= b <= 0x3B or b >= 0x80


def read_string(d: bytes, p: int):
    """Return (text, next_p) if a valid [u16 len][cipher] string is at p, else None."""
    if p + 2 > len(d):
        return None
    ln = struct.unpack_from("<H", d, p)[0]
    if not (2 <= ln <= 60):
        return None
    if not all(_is_strbyte(d[p + 2 + k]) for k in range(ln)):
        return None
    return "".join(ch(d[p + 2 + k]) for k in range(ln)).strip(), p + 2 + ln


def index_offsets(d: bytes):
    out, i = [], 0
    while True:
        j = d.find(SIG, i)
        if j < 0:
            break
        out.append((struct.unpack_from("<I", d, j - 1 + 26)[0],
                    struct.unpack_from("<I", d, j - 1 + 30)[0]))
        i = j + 1
    return out


def parse_record(d: bytes, off: int):
    e = d.find(MM, off, off + 80)
    if e < 0:
        return None
    p = e + len(MM) + 6  # flag(1) + header(5)
    strings = []
    while len(strings) < 8:
        r = read_string(d, p)
        if not r:
            break
        strings.append(r[0])
        p = r[1]
    nums = [struct.unpack_from("<H", d, p + k)[0] for k in range(0, 32, 2)]
    return {"strings": strings, "num_off": p - off, "nums": nums}


def main():
    d = (GAME / "DBDAT/EQUIPOS.PKF").read_bytes()
    teams = []
    for n, (off, sz) in enumerate(index_offsets(d)):
        rec = parse_record(d, off)
        if not rec:
            continue
        nums = rec["nums"]
        years = [v for v in nums if 1850 <= v <= 1998]
        caps = [v for v in nums if 3000 <= v <= 130000]
        teams.append({"n": n, "off": off, **rec, "years": years, "caps": caps})
        print(f"{n:2d} {' / '.join(rec['strings'])[:70]}")
        print(f"     nums@{rec['num_off']}: {nums[:14]}")
        print(f"     yearLike={years}  capLike={caps[:6]}")
    return teams


if __name__ == "__main__":
    main()
