#!/usr/bin/env python3
"""Export the game's OWN application icon out of MANAGER.EXE's resource section.

The Android launcher icon had been left at Godot's default. The faithful source is the
icon Windows itself drew for MANAGER.EXE: the PE `.rsrc` directory holds four RT_ICON
entries (16x16 and 32x32, each at 4bpp and 8bpp) plus one RT_GROUP_ICON. The 32x32 8bpp
entry is the largest and is the one exported here -- it is a football.

Nothing is redrawn and nothing is added. Only the LEGACY launcher icon is exported:
Android's adaptive icon needs a background LAYER that the original simply does not have,
and inventing a plate colour for it would be exactly the kind of guess this port refuses
(the title screen is a gradient, not a flat backdrop -- there is no honest pixel to
sample). Launchers mask a legacy icon themselves, so nothing is lost but the choice.

Outputs (nearest-neighbour, integer scale -- the pixels stay crisp):
  app/art/icons/app_icon.png      32x32   native, exactly the .rsrc bitmap
  app/art/icons/app_icon_192.png  192x192 6x

Usage: python3 tools/re/export_exe_icon.py
"""

from __future__ import annotations

import struct
from pathlib import Path

from PIL import Image

REPO = Path(__file__).resolve().parents[2]
EXE = REPO / "extracted" / "Premier Manager 98" / "MANAGER.EXE"
OUT = REPO / "app" / "art" / "icons"

RT_ICON = 3


def sections(d: bytes) -> list[tuple[str, int, int, int, int]]:
    pe = struct.unpack_from("<I", d, 0x3C)[0]
    nsec = struct.unpack_from("<H", d, pe + 6)[0]
    optsz = struct.unpack_from("<H", d, pe + 20)[0]
    base = struct.unpack_from("<I", d, pe + 24 + 28)[0]
    out = []
    for i in range(nsec):
        o = pe + 24 + optsz + i * 40
        name = d[o : o + 8].rstrip(b"\0").decode()
        vs, va, rs, ptr = struct.unpack_from("<IIII", d, o + 8)
        out.append((name, va + base, vs, ptr, rs))
    return out


def resource_entries(d: bytes, rsrc_va: int, rsrc_ptr: int, image_base: int):
    """Walk the three-level PE resource tree; yield (type, name, lang, rva, size)."""
    rsrc_rva = rsrc_va - image_base

    def walk(off: int, path: tuple[int, ...] = ()):
        ncnt, icnt = struct.unpack_from("<HH", d, off + 12)
        for i in range(ncnt + icnt):
            nameid, doff = struct.unpack_from("<II", d, off + 16 + i * 8)
            if doff & 0x80000000:
                yield from walk(rsrc_ptr + (doff & 0x7FFFFFFF), path + (nameid,))
            else:
                drva, dsize = struct.unpack_from("<II", d, rsrc_ptr + doff)
                yield path + (nameid,), drva, dsize

    for path, drva, dsize in walk(rsrc_ptr):
        yield path, rsrc_ptr + (drva - rsrc_rva), dsize


def icon_to_image(blob: bytes) -> Image.Image:
    """A RT_ICON entry is a BITMAPINFOHEADER + palette + XOR bits + AND mask."""
    hdr_size, width, height2, planes, bpp = struct.unpack_from("<IiiHH", blob, 0)
    height = height2 // 2
    ncolors = 1 << bpp
    pal_off = hdr_size
    pal = []
    for i in range(ncolors):
        b, g, r, _ = blob[pal_off + i * 4 : pal_off + i * 4 + 4]
        pal.append((r, g, b))
    xor_off = pal_off + ncolors * 4
    row_bits = width * bpp
    xor_stride = ((row_bits + 31) // 32) * 4
    and_stride = ((width + 31) // 32) * 4
    and_off = xor_off + xor_stride * height
    img = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    px = img.load()
    for y in range(height):
        row = blob[xor_off + y * xor_stride : xor_off + (y + 1) * xor_stride]
        arow = blob[and_off + y * and_stride : and_off + (y + 1) * and_stride]
        for x in range(width):
            if bpp == 8:
                idx = row[x]
            elif bpp == 4:
                idx = (row[x // 2] >> 4) if x % 2 == 0 else (row[x // 2] & 0xF)
            else:
                raise SystemExit(f"unhandled bpp {bpp}")
            transparent = (arow[x // 8] >> (7 - x % 8)) & 1
            r, g, b = pal[idx]
            px[x, height - 1 - y] = (r, g, b, 0 if transparent else 255)
    return img


def main() -> None:
    d = EXE.read_bytes()
    secs = sections(d)
    rsrc = next(s for s in secs if s[0] == ".rsrc")
    base = 0x400000
    best = None
    for path, off, size in resource_entries(d, rsrc[1], rsrc[3], base):
        if (path[0] & 0xFFFF) != RT_ICON:
            continue
        blob = d[off : off + size]
        w, h2, _, bpp = struct.unpack_from("<iiHH", blob, 4)
        if best is None or (w, bpp) > (best[0], best[1]):
            best = (w, bpp, blob)
    if best is None:
        raise SystemExit("no RT_ICON in MANAGER.EXE")
    w, bpp, blob = best
    icon = icon_to_image(blob)
    assert icon.size == (32, 32), icon.size
    OUT.mkdir(parents=True, exist_ok=True)
    icon.save(OUT / "app_icon.png")
    icon.resize((192, 192), Image.NEAREST).save(OUT / "app_icon_192.png")

    print(f"exported MANAGER.EXE icon {w}x{w} @{bpp}bpp -> app/art/icons/app_icon*.png")


if __name__ == "__main__":
    main()
