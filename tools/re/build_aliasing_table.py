#!/usr/bin/env python3
"""Transcribe MANAGER.EXE's `dat\\aliasing.dat` GENERATOR, instruction for instruction.

`FUN_005d60a0` — the `flags & 0x20` arm of the shadowed blit, i.e. the on-sprite EDGE pass
six sessions failed to model — rewrites every non-zero mask byte as
`DAT_006b5890[code] * 2 + 1`, where `code` is a 13-bit neighbourhood pattern. s88 named the
table's source: the graphics-init at `0x5c9762..0x5c9a02` reads `dat\\aliasing.dat` into it
if that file exists, and otherwise COMPUTES the 8,192 bytes and writes the file out as a
cache. This is that computation, transcribed.

    python3 tools/re/build_aliasing_table.py [--letras PATH] [--out PATH]

The generator, read at `0x5c97e3..0x5c99ad`:

1. load `letras.bmp` into an 8-bit surface (pixels `p`, stride `W`, height `H`);
2. thirteen neighbour offsets, in the order the code stores them —
   `[0, W-1, -1, -2, -1-W, -W, -2W, 1-W, 1, 2, W+1, W, 2W]`;
3. 8,192 accumulator pairs, `sum = 0` and **`count = 1`** (not 0 — the +1 is why an unseen
   code yields 0 rather than a divide fault);
4. for each of `(H-4)*W - 4` pixels from `p + 2*(W+1)`:
   build `code = Σ_k (p[i + offs[k]] >= 0x80) << k`, then FOUR times:
   `sum[code] += d; count[code] += 1; sum[code ^ 0x1fff] += 0xff - d; count[...] += 1`,
   where `d = p[i]`, re-mapping `code` between rounds through
   `T(c) = (c & 1) | ((c >> 3) & 0x3fe) | ((c & 0xe) << 9)` — a 13-bit rotation, which is
   what makes the table symmetric under the sprite being rotated a quarter turn;
5. `table[c] = sum[c] // count[c]` for all 8,192 codes, then write the file.

MEASURED, and it decides everything downstream: **`letras.bmp` ships in NEITHER
`pm98.iso` NOR `Premier_Manager_98.rar`** — not loose, and not in any of the six PKF
containers (`--check-sources` re-runs that search). The generator's own load test is
`0x5c9832 je 0x5c99af`, which on failure SKIPS the whole computation and jumps straight to
the file WRITE, so a shipped install writes 8,192 bytes of untouched `.bss`. What the table
holds at runtime is therefore a question about the live process, not about the sources, and
`m5_rsp_capture.py` reads it (`<out>.aliasing.bin`).
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
GAME = REPO / "extracted" / "Premier Manager 98"
ISO = Path("/home/mats/backup/Div/premier manager 98.iso")
RAR = Path("/home/mats/backup/Div/Premier_Manager_98.rar")

TABLE_SIZE = 0x2000  # 8192 = 2**13, the code is 13 bits (s88 recorded 12; it is 13)


def remap(c: int) -> int:
    """`T` at 0x5c995f..0x5c9977 — the quarter-turn rotation of the 13-bit code."""
    return (c & 1) | ((c >> 3) & 0x3FE) | ((c & 0xE) << 9)


def offsets(w: int) -> list[int]:
    """The thirteen neighbour offsets, in the generator's own storage order
    (`[esp+0x48]` .. `[esp+0x78]`), which is the order bit k is taken from."""
    return [0, w - 1, -1, -2, -1 - w, -w, -2 * w, 1 - w, 1, 2, w + 1, w, 2 * w]


def build(pixels: bytes, w: int, h: int) -> bytes:
    """The generator body, 0x5c9838..0x5c99ad. `pixels` is one byte per sample."""
    offs = offsets(w)
    total = (h - 4) * w - 4
    if total <= 0:
        raise ValueError(f"surface {w}x{h} is too small: (H-4)*W-4 = {total}")
    sums = [0] * TABLE_SIZE
    counts = [1] * TABLE_SIZE  # the +1 is the original's own init, not a guard
    start = 2 * (w + 1)
    for i in range(start, start + total):
        code = 0
        for k, off in enumerate(offs):
            j = i + off
            if 0 <= j < len(pixels) and pixels[j] >= 0x80:
                code |= 1 << k
        d = pixels[i]
        c = code
        for _ in range(4):
            sums[c] += d
            counts[c] += 1
            inv = c ^ 0x1FFF
            sums[inv] += 0xFF - d
            counts[inv] += 1
            c = remap(c)
    return bytes((sums[c] // counts[c]) & 0xFF for c in range(TABLE_SIZE))


def load_bmp8(path: Path) -> tuple[bytes, int, int]:
    """Minimal 8-bit BMP reader — enough for the one file this generator eats."""
    import struct

    d = path.read_bytes()
    if d[:2] != b"BM":
        raise ValueError(f"{path} is not a BMP")
    off = struct.unpack_from("<I", d, 10)[0]
    w, h = struct.unpack_from("<ii", d, 18)
    bpp = struct.unpack_from("<H", d, 28)[0]
    if bpp != 8:
        raise ValueError(f"{path} is {bpp}bpp; the generator wants an 8-bit surface")
    stride = (w + 3) & ~3
    rows = [d[off + r * stride : off + r * stride + stride] for r in range(abs(h))]
    if h > 0:
        rows.reverse()  # bottom-up DIB
    return b"".join(rows), stride, abs(h)


def check_sources() -> int:
    """Re-run the `letras.bmp` search over BOTH sources. Returns the number of hits."""
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    from pkf_unpack import files_of  # noqa: PLC0415 — optional dependency of this mode

    hits = 0
    loose = list(GAME.rglob("letras*")) + list(GAME.rglob("LETRAS*"))
    print(f"loose files in {GAME.name}: {loose or 'none'}")
    hits += len(loose)
    for pkf in ("IMG.PKF", "RECURSOS.PKF", "DAT.PKF", "DATSIM.PKF", "RC_DBASE.PKF",
                "MUSICAS.PKF"):
        p = GAME / pkf
        if not p.exists():
            print(f"  {pkf}: NOT PRESENT")
            continue
        names = [n for n, _o, _s in files_of(p.read_bytes())]
        found = [n for n in names if "LETR" in n.upper()]
        print(f"  {pkf}: {len(names)} entries, LETR* -> {found or 'none'}")
        hits += len(found)
    for src in (ISO, RAR):
        if not src.exists():
            print(f"  {src.name}: NOT PRESENT on this box")
            continue
        blob = src.read_bytes()
        n = blob.count(b"letras") + blob.count(b"LETRAS")
        # Both ISO hits are inside MANAGER.EXE's own string table (the literal is
        # immediately followed by `dat\aliasing.dat`), i.e. the reference, not the file.
        embedded = blob.count(b"letras.bmp\x00\x00dat\\aliasing.dat")
        print(f"  {src.name}: {n} raw 'letras' hits, {embedded} of them the EXE literal")
        hits += n - embedded
    return hits


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--letras", type=Path, default=None,
                    help="path to letras.bmp (absent from both shipped sources)")
    ap.add_argument("--out", type=Path, default=None, help="write the 8192-byte table here")
    ap.add_argument("--check-sources", action="store_true",
                    help="re-run the letras.bmp search over the ISO, the RAR and every PKF")
    args = ap.parse_args()

    if args.check_sources:
        hits = check_sources()
        print(f"\nletras.bmp present in the sources: {'YES' if hits else 'NO'} ({hits} hits)")
        return

    if args.letras is None:
        print("no --letras given, and letras.bmp is in neither source "
              "(run --check-sources). The shipped generator takes its load-failure branch "
              "at 0x5c9832 and writes 8,192 untouched .bss bytes.")
        table = bytes(TABLE_SIZE)
    else:
        pixels, w, h = load_bmp8(args.letras)
        print(f"{args.letras.name}: {w}x{h} (stride {w}), {len(pixels):,} bytes")
        table = build(pixels, w, h)
    print(f"table: {len(table)} bytes, {sum(1 for b in table if b)} non-zero, "
          f"{len(set(table))} distinct")
    if args.out:
        args.out.write_bytes(table)
        print(f"wrote {args.out}")


if __name__ == "__main__":
    main()
