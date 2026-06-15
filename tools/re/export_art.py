#!/usr/bin/env python3
"""Crack + export Premier Manager 98 art from the original .PKF archives to PNG.

Builds on the reversed PCF5 container (pkf_unpack) + image format (pkf_image). The
game stores two bitmap kinds:

  * "DM" entries  -- Dinamic DIBs (the "BM" magic patched to "DM"), drawn with the
    SHARED 256-colour VGA palette at DAT.PKF+0x5ca. Index 0 = transparent. These are
    crests, trophies, icons, sprites. (Same path pkf_image.py proved on the trophy.)
  * "BM" entries  -- standard / OS/2-core Windows DIBs used for full screens
    (FONDO*, ESTADIO*, CAMPO, BARRA*). Many OMIT their palette (bfOffBits points
    straight past the header), so their real colours come from an external RIFF
    palette in DAT.PKF (MANAGER.PAL / MENU.PAL / DBASE.PAL). Index 0 is a real colour
    (opaque background), NOT transparent.

Palette choice is the one judgement call (the per-screen palette is selected by code
in MANAGER.EXE). Default: DM -> shared VGA; BM-without-palette -> --pal (MANAGER.PAL
by default). Override per run while identifying a screen.

Usage:
  export_art.py list  <PKF>                      # names + sizes + magic
  export_art.py dump  <PKF> OUTDIR [--pal NAME] [--vga] [--transparent]
  export_art.py one   <PKF> "<ENTRY>" out.png [--pal NAME] [--vga] [--scale N]
  export_art.py sheet <PKF> sheet.png [--pal NAME] [--cols N] [--cell PX]  # montage
"""
from __future__ import annotations

import io
import struct
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFile
from pkf_unpack import GAME, files_of

ImageFile.LOAD_TRUNCATED_IMAGES = True  # PCF5 DIBs omit a few trailing pad bytes
VGA_OFFSET = 0x5CA


def vga_palette() -> list[int]:
    b = (GAME / "DAT.PKF").read_bytes()[VGA_OFFSET : VGA_OFFSET + 1024]
    pal: list[int] = []
    for i in range(256):
        pal += [b[i * 4 + 2], b[i * 4 + 1], b[i * 4]]  # stored B,G,R,0
    return pal


def riff_palette(name: str) -> list[int]:
    """Parse a Microsoft RIFF 'PAL ' file (DAT.PKF) -> flat RGB list of 256."""
    for n, off, size in files_of((GAME / "DAT.PKF").read_bytes()):
        if n == name:
            d = (GAME / "DAT.PKF").read_bytes()[off : off + size]
            i = d.find(b"data")
            ver, cnt = struct.unpack_from("<HH", d, i + 8)
            base = i + 12
            pal: list[int] = []
            for k in range(256):
                if k < cnt:
                    pal += [d[base + k * 4], d[base + k * 4 + 1], d[base + k * 4 + 2]]
                else:
                    pal += [0, 0, 0]
            return pal
    raise KeyError(f"palette {name!r} not in DAT.PKF")


def _entry(pkf: str, name: str) -> bytes:
    buf = (GAME / pkf).read_bytes()
    for n, off, size in files_of(buf):
        if n == name:
            return buf[off : off + size]
    raise KeyError(f"{name!r} not in {pkf}")


def _has_palette(im: Image.Image) -> bool:
    pal = im.getpalette()
    return bool(pal) and any(v != 0 for v in pal[3:])  # ignore index 0


def render(pkf: str, name: str, pal_name: str = "MANAGER.PAL",
           force_vga: bool = False, transparent: bool | None = None,
           scale: int = 1) -> Image.Image:
    raw = bytearray(_entry(pkf, name))
    is_dm = raw[:2] == b"DM"
    if is_dm:
        raw[0] = ord("B")
    im = Image.open(io.BytesIO(bytes(raw)))
    im.load()
    im = im.convert("P")
    # Palette: DM -> shared VGA; BM -> embedded if present else external RIFF.
    if is_dm or force_vga:
        im.putpalette(vga_palette())
    elif not _has_palette(im):
        im.putpalette(riff_palette(pal_name))
    rgba = im.convert("RGBA")
    # Sprites (DM) treat index 0 as transparent; screen backgrounds keep it.
    if transparent if transparent is not None else is_dm:
        idx = im.tobytes()
        alpha = Image.frombytes("L", im.size, bytes(0 if v == 0 else 255 for v in idx))
        rgba.putalpha(alpha)
    if scale > 1:
        rgba = rgba.resize((rgba.width * scale, rgba.height * scale), Image.NEAREST)
    return rgba


# ---- commands ------------------------------------------------------------

def cmd_list(pkf: str) -> None:
    buf = (GAME / pkf).read_bytes()
    for name, off, size in files_of(buf):
        print(f"  {name:<28} {size:>9}  {bytes(buf[off:off+2])!r}")


def cmd_dump(pkf: str, outdir: str, pal: str, vga: bool, transparent: bool | None) -> None:
    out = Path(outdir)
    out.mkdir(parents=True, exist_ok=True)
    buf = (GAME / pkf).read_bytes()
    ok = bad = 0
    seen: dict[str, int] = {}
    for name, _off, _size in files_of(buf):
        safe = name.replace("\\", "_").replace("/", "_").strip() or "entry"
        seen[safe] = seen.get(safe, 0) + 1
        if seen[safe] > 1:
            safe = f"{safe}~{seen[safe]}"
        try:
            img = render(pkf, name, pal, vga, transparent)
            img.save(out / (Path(safe).stem + ".png"))
            ok += 1
        except Exception as e:  # noqa: BLE001 - report-and-continue cracker
            bad += 1
            print(f"  FAIL {name}: {e}")
    print(f"{pkf}: {ok} ok, {bad} failed -> {out}")


def cmd_sheet(pkf: str, out: str, pal: str, cols: int, cell: int) -> None:
    buf = (GAME / pkf).read_bytes()
    names = [n for n, _o, _s in files_of(buf)]
    thumbs = []
    for name in names:
        try:
            im = render(pkf, name, pal).convert("RGBA")
            im.thumbnail((cell, cell))
            thumbs.append((name, im))
        except Exception:  # noqa: BLE001
            pass
    rows = (len(thumbs) + cols - 1) // cols
    pad, label = 6, 12
    cw, ch = cell + pad, cell + pad + label
    sheet = Image.new("RGB", (cols * cw, rows * ch), (20, 30, 45))
    dr = ImageDraw.Draw(sheet)
    for i, (name, im) in enumerate(thumbs):
        x, y = (i % cols) * cw + pad, (i // cols) * ch + pad
        sheet.paste(im, (x, y), im)
        dr.text((x, y + cell + 1), name[:16], fill=(200, 220, 240))
    Path(out).parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out)
    print(f"wrote {out} ({len(thumbs)} thumbs, {sheet.width}x{sheet.height})")


def main() -> None:
    a = sys.argv[1:]
    if not a:
        print(__doc__)
        raise SystemExit(2)

    def opt(flag, default=None):
        return a[a.index(flag) + 1] if flag in a else default

    pal = opt("--pal", "MANAGER.PAL")
    vga = "--vga" in a
    transparent = True if "--transparent" in a else (False if "--opaque" in a else None)
    cmd = a[0]
    if cmd == "list":
        cmd_list(a[1])
    elif cmd == "dump":
        cmd_dump(a[1], a[2], pal, vga, transparent)
    elif cmd == "one":
        img = render(a[1], a[2], pal, vga, transparent, int(opt("--scale", "1")))
        Path(a[3]).parent.mkdir(parents=True, exist_ok=True)
        img.save(a[3])
        print(f"wrote {a[3]} ({img.width}x{img.height})")
    elif cmd == "sheet":
        cmd_sheet(a[1], a[2], pal, int(opt("--cols", "10")), int(opt("--cell", "80")))
    else:
        print(__doc__)
        raise SystemExit(2)


if __name__ == "__main__":
    main()
