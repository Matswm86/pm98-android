#!/usr/bin/env python3
"""Dump a wine process's memory for the M4 oracle reference.

Modes:
  full <lpid> <outdir>          - dump EVERY readable+writable region below 4GiB
                                  (32-bit PE address space) to <outdir>/regions/,
                                  one file per region named <start>-<end>.bin,
                                  plus maps.txt. This is the offline source of
                                  truth for the M5 initial-struct loader.
  read <lpid> <hexaddr> <len>   - hexdump <len> bytes at <hexaddr> to stdout.

The process should be stopped (winedbg at a breakpoint) for a consistent snapshot.
"""
import sys
from pathlib import Path


def regions(lpid: int):
    for line in Path(f"/proc/{lpid}/maps").read_text().splitlines():
        parts = line.split()
        addr, perms = parts[0], parts[1]
        start, end = (int(x, 16) for x in addr.split("-"))
        yield start, end, perms, parts[5] if len(parts) > 5 else ""


def dump_full(lpid: int, outdir: Path) -> None:
    rdir = outdir / "regions"
    rdir.mkdir(parents=True, exist_ok=True)
    (outdir / "maps.txt").write_text(Path(f"/proc/{lpid}/maps").read_text())
    total = 0
    kept = 0
    with open(f"/proc/{lpid}/mem", "rb", buffering=0) as mem:
        for start, end, perms, name in regions(lpid):
            if start >= 1 << 32:          # 32-bit PE space only
                continue
            if not perms.startswith("rw"):  # writable state (heap, .data, stacks)
                continue
            mem.seek(start)
            try:
                data = mem.read(end - start)
            except OSError:
                continue
            (rdir / f"{start:08x}-{end:08x}.bin").write_bytes(data)
            total += len(data)
            kept += 1
    print(f"dumped {kept} regions, {total/1e6:.1f} MB -> {rdir}")


def read_at(lpid: int, addr: int, n: int) -> None:
    with open(f"/proc/{lpid}/mem", "rb", buffering=0) as mem:
        mem.seek(addr)
        data = mem.read(n)
    for off in range(0, len(data), 16):
        row = data[off:off + 16]
        print(f"{addr+off:08x}  {' '.join(f'{b:02x}' for b in row)}")


if __name__ == "__main__":
    if sys.argv[1] == "full":
        dump_full(int(sys.argv[2]), Path(sys.argv[3]))
    elif sys.argv[1] == "read":
        read_at(int(sys.argv[2]), int(sys.argv[3], 16), int(sys.argv[4]))
    else:
        sys.exit(__doc__)
