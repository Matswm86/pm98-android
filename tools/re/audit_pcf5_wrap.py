#!/usr/bin/env python3
"""Which exported art was actually damaged by the 1024-byte PCF5 misregistration?

`pkf_image.dib_indices` was fixed on 2026-07-24 (see that module's docstring): every
40-byte-BITMAPINFOHEADER entry declares a palette the archive strips, so the old Pillow
path read the rows 1024 bytes late and the image came out rotated by `1024 // stride`
rows + `1024 % stride` columns. The handoff left "re-export everything and render-diff"
as an open sweep. This script scopes it honestly instead of re-exporting blind: for
every entry in every .PKF it computes the rotation the OLD path would have produced and
reports only those where it is NOT the identity.

    rows, cols = divmod(1024, stride)          # stride = 4-byte-padded row width
    damaged  <=>  (rows % height, cols) != (0, 0)

A second class is reported separately: **BITMAPCOREHEADER** entries (the 12-byte OS/2
header, `biSize == 12`). They declare no palette and their rows really do start at
`bfOffBits` = 26, so **Pillow always read them correctly** — but the 2026-07-24
`dib_indices` did not (it assumed 54 unconditionally and sheared them by 28 bytes) until
it learned the variant for the LESIONADOS button export. So the two paths are damaged on
DISJOINT sets:

| entry kind | old Pillow path (`export_art.py`) | `dib_indices` before 2026-07-24 | now |
|---|---|---|---|
| BITMAPINFOHEADER, stride divides 1024 | correct | correct | correct |
| BITMAPINFOHEADER, otherwise           | **rotated** | correct | correct |
| BITMAPCOREHEADER                      | correct | **sheared** | correct |

Only the middle row is a shipped-art problem, and only for art exported through the old
Pillow path. Pass `--check-app` to cross-reference those names against the exported PNGs
under `app/art/`, which is what scopes the re-export sweep.

Usage: python3 tools/re/audit_pcf5_wrap.py [--check-app] [PKF ...]
"""

from __future__ import annotations

import struct
import sys
from collections import Counter
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from pkf_unpack import GAME, files_of  # noqa: E402

PKFS = ["IMG.PKF", "RECURSOS.PKF", "DAT.PKF", "RC_DBASE.PKF", "DATSIM.PKF"]


def main() -> int:
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    check_app = "--check-app" in sys.argv
    names = args or PKFS
    app_art = set()
    if check_app:
        for f in (Path(__file__).resolve().parents[2] / "app/art").rglob("*.png"):
            app_art.add(f.stem.upper())
    grand = Counter()
    rotated_names: set[str] = set()
    for pkf in names:
        path = GAME / pkf
        if not path.exists():
            print(f"{pkf}: not present, skipped")
            continue
        buf = path.read_bytes()
        tally = Counter()
        worst: list[tuple[str, int, int, int, int]] = []
        for name, off, size in files_of(buf):
            raw = buf[off : off + size]
            if len(raw) < 30 or raw[:2] not in (b"BM", b"DM"):
                tally["not-a-dib"] += 1
                continue
            (bisize,) = struct.unpack_from("<I", raw, 14)
            if bisize == 12:
                w, h, _pl, bpp = struct.unpack_from("<HHHH", raw, 18)
                if bpp == 8:
                    tally["core-header (Pillow OK; dib_indices pre-fix sheared)"] += 1
                    worst.append((name, w, h, -1, -1))
                else:
                    tally["not-8bpp"] += 1
                continue
            w, h, _pl, bpp = struct.unpack_from("<iiHH", raw, 18)
            if bpp != 8 or w <= 0 or h == 0:
                tally["not-8bpp"] += 1
                continue
            stride = ((w * 8 + 31) // 32) * 4
            rows, cols = divmod(1024, stride)
            if cols == 0 and rows % abs(h) == 0:
                tally["identity (was already correct)"] += 1
            else:
                tally["ROTATED by the old Pillow path"] += 1
                worst.append((name, w, abs(h), rows % abs(h), cols))
        print(f"\n{pkf}: {sum(tally.values())} entries")
        for k, v in tally.most_common():
            print(f"   {v:6d}  {k}")
        grand.update(tally)
        rotated_names.update(n for n, w, h, r, c in worst if r >= 0)
        bad = [x for x in worst if x[3] != 0 or x[4] != 0]
        for name, w, h, r, c in bad[:20]:
            if r < 0:
                print(f"     core-header {name}  {w}x{h}")
            else:
                print(f"     ROTATED {name}  {w}x{h}  by {r} rows + {c} cols")
        if len(bad) > 20:
            print(f"     ... and {len(bad) - 20} more")
    print("\nTOTAL")
    for k, v in grand.most_common():
        print(f"   {v:6d}  {k}")
    if check_app:
        hits = sorted(n for n in rotated_names if Path(n).stem.upper() in app_art)
        print(f"\nROTATED entries whose name also exists under app/art/: {len(hits)}")
        for h in hits:
            print(f"   {h}")
        if not hits:
            print("   (none — no shipped PNG is named after a rotated entry)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
