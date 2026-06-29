#!/usr/bin/env python3
"""Extract the per-team .DBC files from DBDAT/EQUIPOS.PKF (PM98 / PC Futbol engine).

VERIFIED 2026-06-29 (session 3): EQUIPOS.PKF is a STANDARD PKF container (same
directory format as DAT/IMG/RECURSOS, parsed by tools/re/pkf_unpack.py), NOT the
"20-entry SIG index + Copyright-marker scan + nested blocks" the older notes
(FORMATS.md s3 / tools/parse_equipos.py) inferred before the PKF format was cracked.

The directory enumerates 476 FILE entries named `EQ960<id>.DBC`, each a contiguous,
in-bounds slice = ONE team's full record. Proven this session:
  - 476 entries, ALL 476 begin with "Copyright (c)1996 Dinamic Multimedia",
  - exactly 476 Copyright markers in the whole blob (one per entry, no nesting),
  - 461/475 directory-contiguous (a few type-4 seeks pad the header region).
So a team is an ISOLATED byte range keyed by its game id; no marker-scanning or
anchor-finding needed. Canonical id map (cross-checked vs tools/extract_divisions.py):
the EQ960<id> number IS the game's internal team id; entry position 38 == EQ960301
== the first English club, i.e. english_id == 301 + (position - 38).

Usage:
  dbc_extract.py --list                 # position, id, size, offset for all 476
  dbc_extract.py --extract OUT [ID...]  # write EQ960<id>.DBC files to OUT/
  dbc_extract.py --extract OUT          # ...all of them
"""
from __future__ import annotations

import sys
from pathlib import Path

import pkf_unpack as P

REPO = Path(__file__).resolve().parents[2]
CANDIDATES = [
    REPO / ".wineprefix/drive_c/PM98/DBDAT/EQUIPOS.PKF",
    REPO / "extracted/Premier Manager 98/DBDAT/EQUIPOS.PKF",
    REPO / "extracted/Premier Manager 98/EQUIPOS.PKF",
]
COPYRIGHT = b"Copyright (c)1996 Dinamic Multimedia"


def find_pkf() -> Path:
    for c in CANDIDATES:
        if c.exists():
            return c
    sys.exit(f"EQUIPOS.PKF not found; looked in:\n  " + "\n  ".join(map(str, CANDIDATES)))


def entries(buf: bytes):
    """Yield (position, id_str, name, off, size) for every team .DBC, in directory order."""
    for pos, (name, off, size) in enumerate(P.files_of(buf)):
        # EQ960<id>.DBC -> id is the digits between the "EQ96" prefix and ".DBC"
        stem = name.upper().removeprefix("EQ96").removesuffix(".DBC")
        yield pos, stem, name, off, size


def cmd_list(buf: bytes) -> None:
    n = ok = 0
    for pos, tid, name, off, size in entries(buf):
        n += 1
        valid = buf[off : off + len(COPYRIGHT)] == COPYRIGHT and off + size <= len(buf)
        ok += valid
        print(f"  pos={pos:>3}  id={tid:<6}  size={size:>7}  off={off:>9}  "
              f"{'OK' if valid else 'BAD'}  {name}")
    print(f"\n{ok}/{n} entries valid (Copyright marker + in-bounds).")


def cmd_extract(buf: bytes, out: Path, ids: list[str]) -> None:
    out.mkdir(parents=True, exist_ok=True)
    want = {i.lstrip("0") or "0" for i in ids} if ids else None
    n = 0
    for pos, tid, name, off, size in entries(buf):
        if want is not None and (tid.lstrip("0") or "0") not in want:
            continue
        (out / name).write_bytes(buf[off : off + size])
        n += 1
    print(f"extracted {n} .DBC file(s) to {out}")


def main() -> None:
    args = sys.argv[1:]
    if not args or args[0] not in ("--list", "--extract"):
        sys.exit(__doc__)
    buf = find_pkf().read_bytes()
    if args[0] == "--list":
        cmd_list(buf)
    else:
        if len(args) < 2:
            sys.exit("--extract needs an output directory")
        cmd_extract(buf, Path(args[1]), args[2:])


if __name__ == "__main__":
    main()
