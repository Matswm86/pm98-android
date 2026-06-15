#!/usr/bin/env python3
"""Render a PCF5 indexed bitmap from a .PKF to PNG, in real colours.

The image entries (IMG/RECURSOS/...) are Windows DIBs with the file-header magic
changed from "BM" to "DM" (Dinamic) and an EMPTY embedded palette: the real colours
come from the shared 256-colour VGA palette stored as RGBQUAD (B,G,R,0) at
DAT.PKF offset 0x5ca (same palette extract_badges.py uses for the crests). Index 0
is the transparent background.

So rendering = locate the entry (tools/re/pkf_unpack), patch "DM"->"BM" so Pillow
parses the DIB, re-apply the shared VGA palette, make index 0 transparent.

Usage: pkf_image.py <PKF> <ENTRY_NAME> <out.png> [scale]
  e.g. pkf_image.py IMG.PKF "LEAGUE BIG.BMP" docs/img/pl-trophy.png 2
"""
from __future__ import annotations

import io
import sys
from pathlib import Path

from PIL import Image, ImageFile

from pkf_unpack import GAME, files_of

ImageFile.LOAD_TRUNCATED_IMAGES = True   # PCF5 DIBs omit a few trailing pad bytes
PAL_OFFSET = 0x5CA


def vga_palette() -> list[int]:
    b = (GAME / "DAT.PKF").read_bytes()[PAL_OFFSET : PAL_OFFSET + 1024]
    pal: list[int] = []
    for i in range(256):
        pal += [b[i * 4 + 2], b[i * 4 + 1], b[i * 4]]   # B,G,R,0 -> R,G,B
    return pal


def entry_bytes(pkf: str, name: str) -> bytes:
    buf = (GAME / pkf).read_bytes()
    for n, off, size in files_of(buf):
        if n == name:
            return buf[off : off + size]
    raise KeyError(f"{name!r} not found in {pkf}")


def render(pkf: str, name: str, scale: int = 1) -> Image.Image:
    raw = bytearray(entry_bytes(pkf, name))
    if raw[:2] == b"DM":
        raw[0] = ord("B")          # DM -> BM: now a valid Windows BMP/DIB
    im = Image.open(io.BytesIO(bytes(raw)))
    im.load()
    im = im.convert("P")
    im.putpalette(vga_palette())
    rgba = im.convert("RGBA")
    # index 0 = transparent background
    idx = im.tobytes()
    alpha = Image.frombytes("L", im.size, bytes(0 if v == 0 else 255 for v in idx))
    rgba.putalpha(alpha)
    if scale > 1:
        rgba = rgba.resize((rgba.width * scale, rgba.height * scale), Image.NEAREST)
    return rgba


def main() -> None:
    if len(sys.argv) < 4:
        print("usage: pkf_image.py <PKF> <ENTRY> <out.png> [scale]")
        raise SystemExit(2)
    pkf, name, out = sys.argv[1], sys.argv[2], sys.argv[3]
    scale = int(sys.argv[4]) if len(sys.argv) > 4 else 1
    img = render(pkf, name, scale)
    Path(out).parent.mkdir(parents=True, exist_ok=True)
    img.save(out)
    print(f"wrote {out} ({img.width}x{img.height})")


if __name__ == "__main__":
    main()
