#!/usr/bin/env python3
"""Reverse-engineer the Dinamic PM98 `.30` string-table format.

Header (observed): magic 'DMLT', uint32 A, uint32 count, uint16 B.
Body hypothesis: repeated records of [len:u8][00][len encoded bytes].
We brute-force the per-char transform (add / sub / xor) and score by how
alphabetic the decoded output is, then dump the winning decode.
"""
from __future__ import annotations
import struct
import sys
from pathlib import Path

GAME = Path(__file__).resolve().parent.parent / "extracted" / "Premier Manager 98"


def parse_header(buf: bytes):
    assert buf[:4] == b"DMLT", f"bad magic {buf[:4]!r}"
    a, count = struct.unpack_from("<II", buf, 4)
    return {"a": a, "count": count, "body_off": 12}


def read_records(buf: bytes, off: int):
    """Records are [uint16 len][len bytes], streamed from body_off."""
    recs = []
    n = len(buf)
    while off + 2 <= n:
        ln = struct.unpack_from("<H", buf, off)[0]
        start = off + 2
        end = start + ln
        if ln == 0 or end > n:
            break
        recs.append(buf[start:end])
        off = end
    return recs, off


def score(text: str) -> float:
    if not text:
        return 0.0
    ok = sum(c.isalpha() or c in " '.-" for c in text)
    return ok / len(text)


def decode_transform(rec: bytes, mode: str, k: int) -> str:
    out = []
    for x in rec:
        if mode == "add":
            v = (x + k) & 0xFF
        elif mode == "sub":
            v = (k - x) & 0xFF
        else:
            v = x ^ k
        out.append(chr(v))
    return "".join(out)


def main(path: Path):
    buf = path.read_bytes()
    hdr = parse_header(buf)
    recs, end = read_records(buf, hdr["body_off"])
    print(f"\n=== {path.name} ===")
    print(f"header: {hdr}  file={len(buf)}B  parsed_records={len(recs)} (stopped at {end})")
    # brute force transform on first ~40 records
    sample = recs[:40]
    best = None
    for mode in ("add", "sub", "xor"):
        for k in range(256):
            s = sum(score(decode_transform(r, mode, k)) for r in sample) / max(1, len(sample))
            if best is None or s > best[0]:
                best = (s, mode, k)
    s, mode, k = best
    print(f"best transform: {mode} k={k} (0x{k:02x}) score={s:.3f}")
    print("first 30 decoded:")
    for i, r in enumerate(recs[:30]):
        print(f"  [{i:3d}] {decode_transform(r, mode, k)!r}")
    return hdr, recs, (mode, k)


if __name__ == "__main__":
    targets = sys.argv[1:] or ["DBDAT/PAISES.30", "DBDAT/NOMBRES.30", "DBDAT/APELLIDO.30"]
    for t in targets:
        main(GAME / t)
