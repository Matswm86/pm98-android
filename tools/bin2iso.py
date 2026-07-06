#!/usr/bin/env python3
"""Convert a raw MODE1/2352 CD .bin image to a 2048-byte/sector .iso.

Each 2352-byte sector: 12B sync + 3B address + 1B mode + 2048B user data
+ 288B EDC/ECC. We keep only the user data.
"""

import sys
from pathlib import Path

SECTOR_RAW = 2352
SECTOR_DATA = 2048
DATA_OFFSET = 16

SYNC = b"\x00\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\x00"


def main() -> None:
    src, dst = Path(sys.argv[1]), Path(sys.argv[2])
    size = src.stat().st_size
    if size % SECTOR_RAW:
        print(f"warning: {size} not a multiple of {SECTOR_RAW}", file=sys.stderr)
    n = size // SECTOR_RAW
    with src.open("rb") as f, dst.open("wb") as out:
        first = f.read(SECTOR_RAW)
        if first[:12] != SYNC:
            sys.exit(f"not a raw MODE1/2352 image (bad sync): {first[:16].hex()}")
        out.write(first[DATA_OFFSET : DATA_OFFSET + SECTOR_DATA])
        for _ in range(1, n):
            sector = f.read(SECTOR_RAW)
            out.write(sector[DATA_OFFSET : DATA_OFFSET + SECTOR_DATA])
    print(f"{dst}: {n} sectors -> {dst.stat().st_size} bytes")


if __name__ == "__main__":
    main()
