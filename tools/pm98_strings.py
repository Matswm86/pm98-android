#!/usr/bin/env python3
"""Solved decoder for PM98 (Dinamic) `.30` string tables -> plain English.

Container: magic 'DMLT' + u32 + u32(count), then a stream of [u16 len][len bytes].
Cipher: pair-swapped alphabet with A=0:
    forward L->code = L if L even else L+2   (A=0,B=3,C=2,D=5,E=4,...,Z=27)
Each stored byte is masked with 0x1f before lookup; the first byte of every
record additionally carries a +0x20 "start" flag (already removed by the mask).
Code 1 = space.  A few country labels use punctuation codes handled ad hoc.
"""
from __future__ import annotations
import json
import struct
import sys
from pathlib import Path

GAME = Path(__file__).resolve().parent.parent / "extracted" / "Premier Manager 98"

# code (0..27) -> letter, plus space
_FWD = {L: (L if L % 2 == 0 else L + 2) for L in range(26)}
CODE2CH = {code: chr(ord("A") + L) for L, code in _FWD.items()}
CODE2CH[1] = " "      # word separator
CODE2CH[26] = "'"     # apostrophe (rare)


def _ch(b: int) -> str:
    return CODE2CH.get(b & 0x1F, f"<{b:02x}>")


def parse_records(path: Path):
    buf = path.read_bytes()
    assert buf[:4] == b"DMLT", f"bad magic in {path.name}"
    count = struct.unpack_from("<I", buf, 8)[0]
    off, recs = 12, []
    while off + 2 <= len(buf):
        ln = struct.unpack_from("<H", buf, off)[0]
        if ln == 0 or off + 2 + ln > len(buf):
            break
        recs.append(buf[off + 2 : off + 2 + ln])
        off += 2 + ln
    return count, recs


def decode_table(path: Path):
    count, recs = parse_records(path)
    return [("".join(_ch(b) for b in r)).strip() for r in recs]


if __name__ == "__main__":
    out = {}
    for key, fn in (("countries", "DBDAT/PAISES.30"),
                    ("first_names", "DBDAT/NOMBRES.30"),
                    ("surnames", "DBDAT/APELLIDO.30")):
        vals = decode_table(GAME / fn)
        out[key] = vals
        print(f"=== {key} ({len(vals)}) ===")
        print(", ".join(vals[:60]))
        print()
    dst = Path(__file__).resolve().parent.parent / "assets" / "strings.json"
    dst.write_text(json.dumps(out, indent=2, ensure_ascii=False))
    print(f"wrote {dst}")
