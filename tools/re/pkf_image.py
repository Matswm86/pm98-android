#!/usr/bin/env python3
"""Render a PCF5 indexed bitmap from a .PKF to PNG, in real colours.

The image entries (IMG/RECURSOS/...) are Windows DIBs with the file-header magic
changed from "BM" to "DM" (Dinamic) and NO embedded palette: the real colours
come from a 256-colour palette held outside the entry -- either the shared VGA
table stored as 4-byte entries R,G,B,0 (VGA-DAC order, NOT BMP RGBQUAD B,G,R,0)
at DAT.PKF offset 0x5ca, or one of the RIFF `PAL ` files in DAT.PKF
(MANAGER.PAL / MENU.PAL / DBASE.PAL). Index 0 is the transparent background.
(Verified by ground truth: the PL trophy crown is gold and Man Utd/Arsenal kits
red, Blackburn/Chelsea blue, only under R,G,B order; B,G,R swaps red<->blue.)

## The 1024-byte misregistration (solved 2026-07-24) -- READ THIS BEFORE EXPORTING

The DIB file header still DECLARES a palette: `bfOffBits` is 1078 (14 byte file
header + 40 byte BITMAPINFOHEADER + 1024 byte RGBQUAD table) and `bfSize` is
exactly 1024 bytes MORE than the entry actually stores. The 1024 palette bytes
were STRIPPED when the archive was built; the pixel rows begin at offset **54**.
Pillow honours `bfOffBits`, so it starts reading 1024 bytes too late and every
such image comes out rotated by 1024 bytes -- `1024 // stride` rows plus
`1024 % stride` columns.

That is invisible whenever `stride` divides 1024 and the rotation lands back on
itself (a 32x32 crest wraps 32 whole rows = identity, which is why the crests,
kits and small icons always looked right), and glaring otherwise: it is the
documented `estadio<N>.png` seam that `fix_estadio_wrap.py` corrects
empirically at 320x240 (1024 = 3 rows + 64 columns).

`dib_indices()` below parses the header itself and reads the rows from offset 54,
so it is correct for every size. Ground truth: the SORTEO (cup-draw) picture --
`COCACOLA SORTEO.BMP` + `sorteo/frames/FONDO.BMP` + `BOMBO08.BMP` composited
over black at the offsets in `docs/re/cupdraw_screen_re.md` -- reproduces the
real MANAGER.EXE frame `74_after_wk4.png` at **100.0000% exact pixels** under
MANAGER.PAL, and the F.A. Cup frame `10_fa_cup_draw_round1.png` at 99.9973%.
Under the old Pillow path the same composite scored 96.24%.

Art exported before this fix was produced by the wrapped path. Re-exporting any
of it is safe but must be render-diffed against a real frame before it ships;
`fix_estadio_wrap.py` corrects ALREADY-EXPORTED tiles and must NOT be re-run on
tiles re-exported through `dib_indices()`.

Usage: pkf_image.py <PKF> <ENTRY_NAME> <out.png> [scale]
  e.g. pkf_image.py IMG.PKF "LEAGUE BIG.BMP" docs/img/pl-trophy.png 2
"""

from __future__ import annotations

import struct
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageFile
from pkf_unpack import GAME, files_of

ImageFile.LOAD_TRUNCATED_IMAGES = True  # PCF5 DIBs omit a few trailing pad bytes
PAL_OFFSET = 0x5CA
PIXELS_AT = 54  # 14 (file header) + 40 (BITMAPINFOHEADER); the 1024 pal bytes are stripped


def vga_palette() -> list[int]:
    b = (GAME / "DAT.PKF").read_bytes()[PAL_OFFSET : PAL_OFFSET + 1024]
    pal: list[int] = []
    for i in range(256):
        pal += [b[i * 4], b[i * 4 + 1], b[i * 4 + 2]]  # stored R,G,B,0 (VGA-DAC order)
    return pal


def riff_palette(name: str = "MANAGER.PAL") -> list[int]:
    """Parse a Microsoft RIFF 'PAL ' file out of DAT.PKF -> flat RGB list of 256."""
    buf = (GAME / "DAT.PKF").read_bytes()
    for n, off, size in files_of(buf):
        if n == name:
            d = buf[off : off + size]
            i = d.find(b"data")
            _ver, cnt = struct.unpack_from("<HH", d, i + 8)
            base = i + 12
            pal: list[int] = []
            for k in range(256):
                if k < cnt:
                    pal += [d[base + k * 4], d[base + k * 4 + 1], d[base + k * 4 + 2]]
                else:
                    pal += [0, 0, 0]
            return pal
    raise KeyError(f"palette {name!r} not in DAT.PKF")


def entries(pkf: str) -> list[tuple[str, int, int]]:
    return list(files_of((GAME / pkf).read_bytes()))


def entry_bytes(pkf: str, name: str, ordinal: int = 0) -> bytes:
    """Raw bytes of an entry. Names REPEAT inside a .PKF (each folder has its own
    FONDO.BMP / BALON.BMP), so `ordinal` picks the n-th entry with that name."""
    buf = (GAME / pkf).read_bytes()
    hit = 0
    for n, off, size in files_of(buf):
        if n == name:
            if hit == ordinal:
                return buf[off : off + size]
            hit += 1
    raise KeyError(f"{name!r}[{ordinal}] not found in {pkf}")


def entry_bytes_at(pkf: str, index: int) -> bytes:
    """Raw bytes of the `index`-th entry, in directory order."""
    buf = (GAME / pkf).read_bytes()
    n, off, size = list(files_of(buf))[index]
    return buf[off : off + size]


def dib_indices(raw: bytes) -> np.ndarray:
    """Palette indices of a PCF5 DIB, decoded from the header (see module docstring).

    Two header flavours occur in the archives, told apart by the DWORD at offset 14
    (`biSize`):

    * **40 = BITMAPINFOHEADER.** Rows start at byte 54 -- NOT at the header's
      `bfOffBits`, which still points past a 1024-byte palette that the archive does
      not store. This is the 1024-byte misregistration the module docstring documents.
    * **12 = BITMAPCOREHEADER** (OS/2, u16 width/height). `bfOffBits` is a truthful
      26 = 14 + 12 and no palette is declared, so the rows really do start there.
      RECURSOS' small UI sprites (LESIONADOS\\BOTONON/BOTONOFF/HOSPITAL/SEGURO, ...)
      are all of this kind; decoding them at 54 shears them by 28 bytes.

    Rows are bottom-up and padded to a 4-byte stride. A few entries omit their last
    pad bytes; those are zero-filled.
    """
    (bisize,) = struct.unpack_from("<I", raw, 14)
    if bisize == 12:
        w, h, _planes, bpp = struct.unpack_from("<HHHH", raw, 18)
        pixels_at = 26
    else:
        w, h, _planes, bpp = struct.unpack_from("<iiHH", raw, 18)
        pixels_at = PIXELS_AT
    if bpp != 8:
        raise ValueError(f"expected 8bpp, got {bpp}")
    flip = h > 0 if bisize != 12 else True  # core-header heights are unsigned/bottom-up
    h = abs(h)
    stride = ((w * bpp + 31) // 32) * 4
    px = raw[pixels_at : pixels_at + stride * h]
    if len(px) < stride * h:
        px = px + bytes(stride * h - len(px))
    a = np.frombuffer(px, dtype=np.uint8).reshape(h, stride)[:, :w]
    return a[::-1] if flip else a


def rgba(idx: np.ndarray, palette: list[int], transparent: bool = True) -> Image.Image:
    pal = np.asarray(palette, dtype=np.uint8).reshape(256, 3)
    out = np.dstack([pal[idx], np.full(idx.shape, 255, np.uint8)])
    if transparent:
        out[..., 3] = np.where(idx == 0, 0, 255)
    return Image.fromarray(out, "RGBA")


def render(pkf: str, name: str, scale: int = 1, ordinal: int = 0,
           palette: str = "vga", transparent: bool = True) -> Image.Image:
    """One entry as RGBA. `palette` is "vga" or a RIFF name such as "MANAGER.PAL"."""
    idx = dib_indices(entry_bytes(pkf, name, ordinal))
    pal = vga_palette() if palette == "vga" else riff_palette(palette)
    img = rgba(idx, pal, transparent)
    if scale > 1:
        img = img.resize((img.width * scale, img.height * scale), Image.NEAREST)
    return img


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
