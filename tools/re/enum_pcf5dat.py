#!/usr/bin/env python3
"""Honest enumeration attempt for PCF5DAT.PKF (the 314MB PC Futbol 5 engine-data
container that ships ONLY on the premier manager 98.iso, NOT in the .rar tree).

PCF5DAT.PKF does NOT begin with a PM98 PKF directory record (first byte is 0x00,
tag&7==0 == "corrupt start" for pkf_unpack). This tool's job is to find out whether
the PM98 PKF directory grammar (pkf_unpack.parse) describes PCF5DAT *anywhere* in the
file, and to report the result FACTUALLY — including "not enumerable with current
tooling" if that is the truth. It never invents a member list.

Strategy:
  A. parse() from offset 0 and report where/why it stops.
  B. numpy-scan the whole file for plausible type-2 FILE-record headers
     (tag&7==2, in-bounds non-zero payload off/size, printable de-obfuscated name),
     then from the densest candidate offsets walk the real parse() chain and keep the
     longest clean run (a real directory would yield thousands of contiguous entries).
  C. Print the verdict: enumerable (with member sample) or GAP (with evidence).

Usage: python3 tools/re/enum_pcf5dat.py /path/to/PCF5DAT.PKF
Reuses pkf_unpack.parse / deobf_name — does not modify pkf_unpack.
"""
from __future__ import annotations

import struct
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
from pkf_unpack import deobf_name, parse  # noqa: E402


def printable_name(buf: bytes, p: int) -> str | None:
    nm = deobf_name(buf[p : p + 20])
    z = nm.find(b"\x00")
    s = nm[: z if z >= 0 else 20]
    if len(s) >= 2 and all(32 <= c < 127 for c in s):
        return s.decode("latin1")
    return None


def walk_len(buf: bytes, start: int, cap: int = 200000):
    """Walk parse() from `start`; return (n_records, ended_clean, last_at, names)."""
    n = 0
    names = []
    ended = False
    # parse() always starts at pos 0; use a zero-copy memoryview window (NOT buf[start:],
    # which would copy ~300MB per call and OOM the box).
    mv = memoryview(buf)[start:]
    for r in parse(mv, max_records=cap):
        if "err" in r:
            return n, False, r["at"] + start, names
        n += 1
        if r.get("type") in (1, 2) and len(names) < 16:
            names.append(r["name"])
        if r.get("end"):
            ended = True
            return n, True, r["at"] + start, names
    return n, ended, start, names


def main():
    fn = sys.argv[1] if len(sys.argv) > 1 else None
    if not fn or not Path(fn).exists():
        raise SystemExit("usage: enum_pcf5dat.py /path/to/PCF5DAT.PKF")
    buf = Path(fn).read_bytes()
    n = len(buf)
    print(f"# PCF5DAT enumeration — {fn}")
    print(f"size = {n:,} bytes")
    print(f"first16 = {buf[:16].hex(' ')}")

    # --- A. parse from offset 0 ---
    first = next(iter(parse(buf, max_records=4)), None)
    nrec0, clean0, last0, names0 = walk_len(buf, 0, cap=50)
    print(f"\n[A] parse@0: first_record={first}")
    print(f"    walked {nrec0} record(s) then {'END' if clean0 else 'STOP'} @ {last0:#x}; names={names0}")

    # --- B. memory-capped chunked scan for type-2 FILE-record headers ---
    # Process the file in windows so peak RAM stays ~tens of MB (8GB box w/ earlyoom).
    CHUNK = 8 << 20            # 8 MiB window
    OVER = 64                  # overlap so a record straddling a boundary is still seen
    seeds = []                 # in-bounds, printable-named type-2 candidate offsets
    total_t2 = total_valid = 0
    for base in range(0, n, CHUNK):
        end = min(n, base + CHUNK + OVER)
        a = np.frombuffer(buf, dtype=np.uint8, count=end - base, offset=base)
        m = len(a) - 37
        if m <= 0:
            break
        loc = np.nonzero((a[:m] & 7) == 2)[0]      # local positions, small per chunk
        total_t2 += len(loc)
        if not len(loc):
            continue
        def u32(o):
            return (a[loc + o].astype(np.uint32) | (a[loc + o + 1].astype(np.uint32) << 8)
                    | (a[loc + o + 2].astype(np.uint32) << 16) | (a[loc + o + 3].astype(np.uint32) << 24))
        off, size = u32(25), u32(29)
        gabs = base + loc.astype(np.uint64)
        good = ((size > 0) & (size < 60_000_000) & (off < n)
                & (off.astype(np.uint64) + size.astype(np.uint64) <= n))
        gv = loc[good]
        total_valid += len(gv)
        for q in gv:
            ap = base + int(q)
            if ap + 1 in range(n) and printable_name(buf, ap + 1) is not None:
                seeds.append(ap)
        del a, loc
    # dedup + cap seed count (printable-named valid type-2 are the only chains worth walking)
    seeds = sorted(set(seeds))
    print(f"\n[B] positions tag&7==2: {total_t2:,}; in-bounds payload triple: {total_valid:,}; "
          f"printable-named seeds: {len(seeds):,}")

    best = []
    if seeds:
        step = max(1, len(seeds) // 4000)
        sample = seeds[::step]
        print(f"    walking {len(sample)} sampled chains...")
        for s in sample:
            nrec, clean, last, names = walk_len(buf, s, cap=200000)
            if nrec >= 8:
                best.append((nrec, clean, s, last, names))
        best.sort(reverse=True)

    print("\n[C] verdict:")
    if best and best[0][0] >= 100:
        nrec, clean, s, last, names = best[0]
        print(f"    DIRECTORY-LIKE chain found @ {s:#x}: {nrec} records, "
              f"{'clean END' if clean else 'stops'} @ {last:#x}")
        print(f"    first names: {names}")
        print("    -> PARTIAL/ENUMERABLE: a member directory exists at a nonzero offset.")
    else:
        topn = best[0][0] if best else 0
        print(f"    No directory-like chain (best clean run = {topn} records).")
        print("    -> GAP: PCF5DAT.PKF does NOT follow the PM98 PKF directory grammar that")
        print("       pkf_unpack.parse implements. Not enumerable with current tooling.")
        print("       (Likely the older PC Futbol 5 container variant; would need its own")
        print("        directory format reversed from the PCF5/MANAGER seek logic.)")


if __name__ == "__main__":
    main()
