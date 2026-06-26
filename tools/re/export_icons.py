#!/usr/bin/env python3
"""Bake the PM98 management-UI icon sprites from RECURSOS.PKF into the Godot art tree.

These are the `RECURSOS\\iconos\\*` sprites the reversed management screens name
(camrol role pitch-icons, finance ledger arrows, list scroll buttons, scout/offers):
small Windows OS/2-core DIBs (`BM`, 12-byte BITMAPCOREHEADER, 8 bpp) that *omit*
their palette (`bfOffBits == 0`) — so PIL can't open them. We decode them directly
(bottom-up rows, 4-byte stride) and colour them with the external RIFF MANAGER.PAL,
index 0 = transparent (the universal PCF5 sprite convention).

The iconic one is `CAMROL01..18.BMP`: an 18-frame set of tiny top-down pitch
diagrams with a white dot at the player's role position. Frame N = the player's
fine-position code (`posFine`, decoded in docs/re/positions_re.md): camrol01 = GK,
camrol09 = central striker (the deepest-in-attack dot), defenders left, etc. The
fine-code -> dot-x progression was verified against the POS_WEIGHT semantics.

Run from anywhere (paths are resolved from this file). Reads the originals out of
the gitignored `extracted/` tree; writes committable derived PNGs under
`app/art/icons/` (consistent with menu_bg.png / barra0.png / the match atlases).

Usage:
  export_icons.py            # bake the full set into app/art/icons/
  export_icons.py --sheet P  # also write a contact sheet to P for eyeballing
"""
from __future__ import annotations

import struct
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import export_art as ea  # noqa: E402  (shared PKF entry reader + RIFF palette)

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "app" / "art" / "icons"
PAL_NAME = "MANAGER.PAL"

# name -> output subpath (under app/art/icons). camrol baked as camrol/camrolNN.png.
CAMROL = [(f"CAMROL{i:02d}.BMP", f"camrol/camrol{i:02d}.png") for i in range(1, 19)]
EXTRAS = [
    ("FLECHAGREEN.BMP", "fin_up.png"),     # income / positive ledger row marker
    ("FLECHARED.BMP", "fin_down.png"),     # expense / negative ledger row marker
    ("ARROWUPON.BMP", "scroll_up_on.png"),
    ("ARROWUPOFF.BMP", "scroll_up_off.png"),
    ("ARROWDOWNON.BMP", "scroll_down_on.png"),
    ("ARROWDOWNOFF.BMP", "scroll_down_off.png"),
    ("SECRETARIO.BMP", "scout.png"),       # transfer SCOUT button glyph (magnifier)
    ("OFERTAS.BMP", "offers.png"),         # transfer OFFERS button glyph (money bag)
]


def decode_dib(raw: bytes, pal: list[int]) -> Image.Image:
    """OS/2-core (12) or info (40) DIB, 8 bpp, idx0 transparent, external palette.

    Handles the PCF5 quirk where bfOffBits == 0 and the palette is omitted: pixels
    start immediately after the 14-byte file header + the DIB header.
    """
    hsz = struct.unpack_from("<I", raw, 14)[0]
    if hsz == 12:
        w, h = struct.unpack_from("<HH", raw, 18)
        top_down = False
    else:
        w, h, _planes, bpp = struct.unpack_from("<iiHH", raw, 18)
        if bpp != 8:
            raise ValueError(f"unexpected bpp {bpp}")
        top_down = h < 0
        h = abs(h)
    stride = ((w + 3) // 4) * 4
    pix = raw[14 + hsz:]
    rows = [pix[y * stride:y * stride + w] for y in range(h)]
    if not top_down:
        rows = rows[::-1]
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = img.load()
    for y, row in enumerate(rows):
        for x in range(min(w, len(row))):
            idx = row[x]
            if idx == 0:
                continue
            px[x, y] = (pal[idx * 3], pal[idx * 3 + 1], pal[idx * 3 + 2], 255)
    return img


def bake(pal: list[int]) -> list[tuple[str, Image.Image]]:
    baked: list[tuple[str, Image.Image]] = []
    for name, rel in CAMROL + EXTRAS:
        try:
            img = decode_dib(ea._entry("RECURSOS.PKF", name), pal)
        except Exception as exc:  # noqa: BLE001 - report-and-continue cracker
            print(f"  FAIL {name}: {exc}")
            continue
        dst = OUT / rel
        dst.parent.mkdir(parents=True, exist_ok=True)
        img.save(dst)
        baked.append((rel, img))
    return baked


def contact_sheet(baked: list[tuple[str, Image.Image]], path: Path) -> None:
    from PIL import ImageDraw
    cell, cols, scale, pad, label = 88, 9, 4, 8, 14
    cw, ch = cell + pad, cell + pad + label
    rows = (len(baked) + cols - 1) // cols
    sh = Image.new("RGB", (cols * cw, rows * ch), (200, 205, 215))
    dr = ImageDraw.Draw(sh)
    for k, (rel, im) in enumerate(baked):
        x, y = (k % cols) * cw + pad, (k // cols) * ch + pad
        t = im.resize((im.width * scale, im.height * scale), Image.NEAREST)
        sh.paste(t.convert("RGB"), (x, y), t)
        dr.text((x, y + cell + 1), f"{Path(rel).stem} {im.width}x{im.height}", fill=(20, 20, 30))
    path.parent.mkdir(parents=True, exist_ok=True)
    sh.save(path)
    print(f"wrote contact sheet {path}")


def main() -> None:
    pal = ea.riff_palette(PAL_NAME)
    baked = bake(pal)
    print(f"baked {len(baked)} icons -> {OUT}")
    if "--sheet" in sys.argv:
        contact_sheet(baked, Path(sys.argv[sys.argv.index("--sheet") + 1]))


if __name__ == "__main__":
    main()
