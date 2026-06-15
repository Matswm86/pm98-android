#!/usr/bin/env python3
"""Convert a Windows 2.x raster .FNT (PM98 WINFONTS/) to an AngelCode BMFont
(.fnt + PNG atlas) that Godot 4 imports natively as a FontFile.

PM98 ships its UI type as classic GDI raster fonts: PROMAN8-24 (the game's own
face), EUROH*, MICRO*, RESULT, DIGITAL, CALEND*. Header is the documented Windows
FONT 2.0 struct; glyphs are 1-bpp, COLUMN-MAJOR: pixel(x,y) is bit (7-(x&7)) of
byte[glyphOffset + (x>>3)*pixHeight + y], MSB = leftmost. Verified by eye on
PROMAN (see --sample).

Atlas glyphs are white on transparent so the colour is set in Godot (modulate),
matching how the original re-tints the one font across screens.

Usage:
  fnt_to_bmfont.py <FONT.FNT> <out_dir> [name]   # writes <name>.fnt + <name>.png
  fnt_to_bmfont.py <FONT.FNT> --sample "TEXT" out.png
"""
from __future__ import annotations

import struct
import sys
from pathlib import Path

from PIL import Image

GAME = Path(__file__).resolve().parents[2] / "extracted" / "Premier Manager 98"
WINFONTS = GAME / "WINFONTS"


class Fnt:
    def __init__(self, data: bytes):
        self.d = data
        self.version = struct.unpack_from("<H", data, 0)[0]
        self.pix_height = struct.unpack_from("<H", data, 88)[0]
        self.ascent = struct.unpack_from("<H", data, 74)[0]
        self.first = data[95]
        self.last = data[96]
        self.face = self._face()
        # Char table: v2 entries are u16 width + u16 offset; v3 u16 + u32.
        self.wide_off = self.version >= 0x300
        self.entries: list[tuple[int, int]] = []
        pos = 118  # dfCharTable: after the 117-byte FONTINFO 2.0 header + dfReserved
        step = 6 if self.wide_off else 4
        for _c in range(self.first, self.last + 2):  # +1 sentinel
            w = struct.unpack_from("<H", data, pos)[0]
            if self.wide_off:
                off = struct.unpack_from("<I", data, pos + 2)[0]
            else:
                off = struct.unpack_from("<H", data, pos + 2)[0]
            self.entries.append((w, off))
            pos += step

    def _face(self) -> str:
        off = struct.unpack_from("<I", self.d, 105)[0]
        if 0 < off < len(self.d):
            end = self.d.find(b"\x00", off)
            return self.d[off:end].decode("latin1", "replace")
        return "FNT"

    def glyph(self, idx: int) -> tuple[int, Image.Image]:
        """(width, 1-bit-ish L image) for char code first+idx."""
        w, off = self.entries[idx]
        h = self.pix_height
        im = Image.new("L", (max(w, 1), h), 0)
        if w == 0:
            return w, im
        px = im.load()
        col_bytes = (w + 7) // 8
        for cb in range(col_bytes):
            for y in range(h):
                b = self.d[off + cb * h + y]
                for bit in range(8):
                    x = cb * 8 + bit
                    if x < w and (b & (0x80 >> bit)):
                        px[x, y] = 255
        return w, im


def build_atlas(fnt: Fnt, pad: int = 1):
    glyphs = []
    for i in range(fnt.last - fnt.first + 1):
        code = fnt.first + i
        w, im = fnt.glyph(i)
        glyphs.append((code, w, im))
    # Simple shelf packing into a near-square atlas.
    cols = 16
    cw = max(g[1] for g in glyphs) + pad
    ch = fnt.pix_height + pad
    rows = (len(glyphs) + cols - 1) // cols
    atlas = Image.new("RGBA", (cols * cw, rows * ch), (0, 0, 0, 0))
    meta = []
    for i, (code, w, im) in enumerate(glyphs):
        x, y = (i % cols) * cw, (i // cols) * ch
        rgba = Image.merge("RGBA", (im, im, im, im))  # white, alpha = coverage
        atlas.paste(rgba, (x, y))
        meta.append((code, x, y, max(w, 1), fnt.pix_height, w))
    return atlas, meta


def write_bmfont(fnt: Fnt, out_dir: Path, name: str) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    atlas, meta = build_atlas(fnt)
    png = f"{name}.png"
    atlas.save(out_dir / png)
    lines = [
        f'info face="{fnt.face}" size={fnt.pix_height} bold=0 italic=0 unicode=0 '
        f"stretchH=100 smooth=0 aa=1 padding=0,0,0,0 spacing=0,0",
        f"common lineHeight={fnt.pix_height} base={fnt.ascent} "
        f"scaleW={atlas.width} scaleH={atlas.height} pages=1 packed=0",
        f'page id=0 file="{png}"',
        f"chars count={len(meta)}",
    ]
    for code, x, y, w, h, adv in meta:
        lines.append(
            f"char id={code} x={x} y={y} width={w} height={h} "
            f"xoffset=0 yoffset=0 xadvance={adv} page=0 chnl=15"
        )
    (out_dir / f"{name}.fnt").write_text("\n".join(lines) + "\n")
    print(f"wrote {out_dir/name}.fnt + {png}  ({len(meta)} glyphs, "
          f"{atlas.width}x{atlas.height}, face={fnt.face!r}, h={fnt.pix_height})")


def sample(fnt: Fnt, text: str, out: str, scale: int = 3) -> None:
    widths = []
    ims = []
    for ch in text:
        i = ord(ch) - fnt.first
        if 0 <= i < len(fnt.entries) - 1:
            w, im = fnt.glyph(i)
        else:
            w, im = fnt.pix_height // 2, Image.new("L", (fnt.pix_height // 2, fnt.pix_height), 0)
        widths.append(w)
        ims.append(im)
    total = sum(widths) + len(widths)
    canvas = Image.new("RGB", (total, fnt.pix_height), (0, 30, 60))
    x = 0
    for w, im in zip(widths, ims):
        canvas.paste(Image.merge("RGB", (im, im, im)), (x, 0))
        x += w + 1
    canvas = canvas.resize((canvas.width * scale, canvas.height * scale), Image.NEAREST)
    canvas.save(out)
    print(f"wrote {out} ({canvas.width}x{canvas.height})")


def _resolve(p: str) -> Path:
    cand = Path(p)
    return cand if cand.exists() else WINFONTS / p


def main() -> None:
    a = sys.argv[1:]
    if not a:
        print(__doc__)
        raise SystemExit(2)
    fnt = Fnt(_resolve(a[0]).read_bytes())
    if "--sample" in a:
        sample(fnt, a[a.index("--sample") + 1], a[a.index("--sample") + 2])
        return
    out_dir = Path(a[1])
    name = a[2] if len(a) > 2 else Path(a[0]).stem.lower()
    write_bmfont(fnt, out_dir, name)


if __name__ == "__main__":
    main()
