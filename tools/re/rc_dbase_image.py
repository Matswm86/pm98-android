#!/usr/bin/env python3
"""Render a Premier Manager 98 DATA BASE bitmap (RC_DBASE.PKF) to PNG, in real colours.

The DATA BASE browser is the standalone MFC app `Dbasewin.exe` (the PC Fútbol 5
database engine reskinned for the Premier League). Its UI bitmaps live in
`RC_DBASE.PKF` (266 entries) — these are *real Windows BMPs* (magic "BM"), NOT the
"DM"-magic Dinamic DIBs that RECURSOS/IMG use, so they parse with the standard PKF
slice + a normal BMP reader. Two flavours occur:

  * Embedded-palette BMPs (BITMAPINFOHEADER, hsz=40, bfOffBits=1078): a complete
    256-colour DIB — render directly (e.g. BANDA DBASE_NEW.BMP, PANTALLA.BMP, the
    "_NEW"/"_BARSA" variants).
  * Palette-LESS 8bpp BMPs (OS/2 BITMAPCOREHEADER, hsz=12, bfOffBits=26): pixels only,
    no colour table. The whole DATA BASE screen is a single 256-colour mode, so these
    were authored against the ONE shared screen palette that the palette-bearing
    bitmaps carry. We fall back to the game's shared VGA palette (DAT.PKF @0x5ca,
    R,G,B,0 order — the same one pkf_image.py uses); verified identical to the
    embedded palette on FONDO DBASE.BMP.

The six 640x480 FONDO*.BMP are full-screen backgrounds (FONDO DBASE = the washed-blue
photo backdrop). BANDA DBASE* = the 640x54 "PC FÚTBOL"/LFP top banner. CLUB TITULO =
the 640x72 soccer-ball title bar. BOLA_* = 8x8 rating dots. See docs/re/database_screen_re.md.

Usage: rc_dbase_image.py <ENTRY_NAME> <out.png> [scale]
       rc_dbase_image.py --list
  e.g. rc_dbase_image.py "FONDO DBASE.BMP" /tmp/fondo.png
"""
from __future__ import annotations

import struct
import sys
from pathlib import Path

from PIL import Image
from pkf_unpack import GAME, files_of

PKF = "RC_DBASE.PKF"
PAL_OFFSET = 0x5CA  # shared VGA palette inside DAT.PKF (R,G,B,0)


def shared_vga_palette() -> list[int]:
    b = (GAME / "DAT.PKF").read_bytes()[PAL_OFFSET : PAL_OFFSET + 1024]
    return [v for i in range(256) for v in (b[i * 4], b[i * 4 + 1], b[i * 4 + 2])]


def _entry_bytes(name: str) -> bytes:
    buf = (GAME / PKF).read_bytes()
    for n, off, size in files_of(buf):
        if n == name:
            return buf[off : off + size]
    raise KeyError(f"{name!r} not found in {PKF}")


def _parse_bmp(raw: bytes):
    """Return (w, h, bpp, off_bits, embedded_palette|None)."""
    off_bits = struct.unpack_from("<I", raw, 10)[0]
    hsz = struct.unpack_from("<I", raw, 14)[0]
    if hsz == 12:  # OS/2 BITMAPCOREHEADER
        w, h, _planes, bpp = struct.unpack_from("<HHHH", raw, 18)
        ent = 3
    else:  # BITMAPINFOHEADER (and friends)
        w, h = struct.unpack_from("<ii", raw, 18)
        bpp = struct.unpack_from("<H", raw, 28)[0]
        ent = 4
    pal = None
    if off_bits > 14 + hsz:
        pb = raw[14 + hsz : off_bits]
        n = len(pb) // ent
        pal = [v for i in range(n) for v in (pb[i * ent + 2], pb[i * ent + 1], pb[i * ent])]
    return w, h, bpp, off_bits, pal


def render(name: str, scale: int = 1) -> Image.Image:
    raw = _entry_bytes(name)
    w, h, bpp, off_bits, pal = _parse_bmp(raw)
    if bpp != 8:
        # non-paletted (rare here) — let Pillow handle it directly
        import io

        im = Image.open(io.BytesIO(raw)).convert("RGB")
    else:
        row = (w + 3) // 4 * 4  # BMP rows are dword-aligned
        im = Image.frombytes("P", (w, h), raw[off_bits : off_bits + row * h], "raw", "P", row)
        im = im.transpose(Image.FLIP_TOP_BOTTOM)  # BMP is bottom-up
        p = pal if pal else shared_vga_palette()
        p = p[:768] + [0] * (768 - len(p[:768]))
        im.putpalette(p)
        im = im.convert("RGB")
    if scale > 1:
        im = im.resize((im.width * scale, im.height * scale), Image.NEAREST)
    return im


def main() -> None:
    if len(sys.argv) >= 2 and sys.argv[1] == "--list":
        buf = (GAME / PKF).read_bytes()
        for n, _off, size in files_of(buf):
            print(f"{size:8d}  {n}")
        return
    if len(sys.argv) < 3:
        print("usage: rc_dbase_image.py <ENTRY> <out.png> [scale]   (or --list)")
        raise SystemExit(2)
    name, out = sys.argv[1], sys.argv[2]
    scale = int(sys.argv[3]) if len(sys.argv) > 3 else 1
    img = render(name, scale)
    Path(out).parent.mkdir(parents=True, exist_ok=True)
    img.save(out)
    print(f"wrote {out} ({img.width}x{img.height})")


if __name__ == "__main__":
    main()
