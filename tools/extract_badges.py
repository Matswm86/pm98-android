#!/usr/bin/env python3
"""Extract club crests from the low-entropy badge PKFs (NANOESC and friends).

Key finding (2026-06-14): the badge PKFs are NOT LZ/RLE-packed. They are plain
8-bit indexed bitmaps with a fixed per-badge stride, stored back-to-back after a
~0x248-byte container header. NANOESC ("nano escudos") = 501 crests of 24x33,
792 bytes each, starting at offset 0x248. Confirmed by rendering: every cell is a
consistently-aligned club shield (grayscale; real colours need the VGA palette,
which ships in DatSim/paletas/*.dat on the CD - not in the RAR install).

Stride was found empirically: row width 24 by horizontal autocorrelation, badge
height 33 rows by row-zero-count autocorrelation (peak 0.93). The other badge
resolutions (BIGESC/MINIESC/RIDIESC) are the same plain-indexed format at other
sizes - add them here once their stride is measured the same way.

Palette: the shared 256-colour VGA palette is an RGBQUAD (B,G,R,0) block at
DAT.PKF offset 0x5ca. Index 0 = (0,0,0) = transparent background. Confirmed by
render: crests come out in real team colours (red/white, blue/white stripes...).

Output: assets/badges/nano/badge_###.png (RGBA, transparent bg) + a contact sheet.
"""
from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
GAME = ROOT / "extracted" / "Premier Manager 98" / "DBDAT"
DAT = ROOT / "extracted" / "Premier Manager 98" / "DAT.PKF"
PAL_OFFSET = 0x5CA
OUT = ROOT / "assets" / "badges" / "nano"

# (file, width, height, header/start offset). Stride = w*h.
SPECS = {
    "nano": ("NANOESC.PKF", 24, 33, 0x248),
}


def load_palette() -> list[int]:
    b = DAT.read_bytes()[PAL_OFFSET:PAL_OFFSET + 1024]
    pal: list[int] = []
    for i in range(256):
        pal += [b[i * 4 + 2], b[i * 4 + 1], b[i * 4]]  # R,G,B from B,G,R,0
    return pal


def extract(name: str, fn: str, w: int, h: int, start: int, pal: list[int]) -> int:
    d = (GAME / fn).read_bytes()
    bs = w * h
    n = (len(d) - start) // bs
    OUT.mkdir(parents=True, exist_ok=True)
    cols = 20
    rows = (n + cols - 1) // cols
    sheet = Image.new("RGBA", (cols * (w + 1), rows * (h + 1)), (255, 255, 255, 255))
    for i in range(n):
        blk = d[start + i * bs: start + (i + 1) * bs]
        if len(blk) < bs:
            break
        idx = Image.frombytes("P", (w, h), blk)
        idx.putpalette(pal)
        rgba = idx.convert("RGBA")
        # index 0 -> transparent
        alpha = Image.frombytes("L", (w, h), bytes(0 if v == 0 else 255 for v in blk))
        rgba.putalpha(alpha)
        rgba.save(OUT / f"badge_{i:03d}.png")
        sheet.paste(rgba, ((i % cols) * (w + 1), (i // cols) * (h + 1)), rgba)
    sheet.save(OUT / "_contact_sheet.png")
    return n


def main() -> None:
    pal = load_palette()
    for name, (fn, w, h, start) in SPECS.items():
        n = extract(name, fn, w, h, start, pal)
        print(f"{name}: {n} colour badges {w}x{h} -> {OUT.relative_to(ROOT)}/")


if __name__ == "__main__":
    main()
