#!/usr/bin/env python3
"""Decode PM98 / PC Fútbol 5 `DMLT` string tables (DBDAT/*.30).

These hold the football-database text pools the DATA BASE program (`Dbasewin.exe`)
reads: country names (PAISES.30), player first names (NOMBRES.30) and surnames
(APELLIDO.30). They are NOT plain ASCII — each is a `DMLT`-magic container with an
obfuscated payload.

Container format (verified against all three .30 files in this install)::

    off 0   "DMLT"            magic
    off 4   u32   payload_len (bytes after the 12-byte header)
    off 8   u32   count       number of records
    off 12  records: repeated [u16 len_le][len obfuscated bytes]

Per-byte cipher: **plain = raw XOR 0x61** (XOR with 'a'). Derived from known plaintext
GERMANY / Adrian / "REP. OF IRELAND" and cross-checked byte-for-byte against the repo's
existing `assets/country_codes.json` (which documents the same XOR 0x61); it is also the
only transform that decodes the accented bytes (e.g. raw 0xb0 -> 0xd1 'Ñ') correctly.
Record 0 of PAISES is the "XXX" no-country sentinel.

NOTE: `assets/strings.json` already holds all three pools, but UPPERCASED. The real bytes
are mixed-case (e.g. "Adrian", "Abel"); this tool preserves the original casing.

Usage:
    python3 dmlt_decode.py PAISES.30 [--json out.json]
    python3 dmlt_decode.py            # decode all three DBDAT tables, print counts
"""
from __future__ import annotations

import json
import struct
import sys
from pathlib import Path

DBDAT = Path(__file__).resolve().parents[2] / "extracted" / "Premier Manager 98" / "DBDAT"
TABLES = ("PAISES.30", "NOMBRES.30", "APELLIDO.30")


def decode_record(raw: bytes) -> str:
    return bytes(b ^ 0x61 for b in raw).decode("cp1252", "replace")


def read_dmlt(path: Path) -> list[str]:
    data = path.read_bytes()
    if data[:4] != b"DMLT":
        raise ValueError(f"{path.name}: not a DMLT table (magic={data[:4]!r})")
    _payload_len, count = struct.unpack_from("<II", data, 4)
    recs: list[str] = []
    off = 12
    while len(recs) < count:
        (ln,) = struct.unpack_from("<H", data, off)
        off += 2
        recs.append(decode_record(data[off : off + ln]))
        off += ln
    if off != len(data):
        print(f"  warn: {path.name} consumed {off}/{len(data)} bytes", file=sys.stderr)
    return recs


def main(argv: list[str]) -> int:
    args = [a for a in argv if not a.startswith("--")]
    json_out = None
    if "--json" in argv:
        json_out = Path(argv[argv.index("--json") + 1])

    if args:
        p = Path(args[0])
        if not p.exists():
            p = DBDAT / args[0]
        recs = read_dmlt(p)
        print(f"{p.name}: {len(recs)} records")
        for i, r in enumerate(recs):
            print(f"{i:4} {r}")
        if json_out:
            json_out.write_text(json.dumps(recs, ensure_ascii=False, indent=0))
            print(f"-> {json_out}", file=sys.stderr)
        return 0

    out: dict[str, list[str]] = {}
    for name in TABLES:
        recs = read_dmlt(DBDAT / name)
        out[name] = recs
        print(f"{name}: {len(recs)} records  e.g. {recs[1:6]}")
    if json_out:
        json_out.write_text(json.dumps(out, ensure_ascii=False, indent=0))
        print(f"-> {json_out}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
