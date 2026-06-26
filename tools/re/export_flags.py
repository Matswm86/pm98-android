#!/usr/bin/env python3
"""Bake the PM98 nationality FLAG art + the country-code table the FICHA uses.

Two decoded game assets, both under DBDAT/ (owned game files):

  * BANDERAS.PKF  — 127 waving-flag bitmaps `BA9600NN` (index NN = the country code).
    Each is an OS/2 BITMAPCOREHEADER DIB (12-byte header, "BM" magic), 30x20, 8bpp,
    bottom-up, rows padded to a 4-byte stride, with an EMPTY embedded palette: the
    colours come from the shared 256-colour VGA palette (DAT.PKF +0x5CA, 4-byte
    R,G,B,0 VGA-DAC order), exactly like the IMG/RECURSOS DIBs in pkf_image.py.
    (Pillow mis-decodes the OS/2-core 8bpp form, so we unpack the rows by hand.)

  * PAISES.30 — the country-NAME table, parallel to the flag index. A `DMLT` header
    (u32, u32 count=128) then `count` length-prefixed (u16) strings, each XOR 0x61
    ('a'): e.g. `$/&- /%`^0x61 == "ENGLAND". Entry 0 == "XXX" == the blank `X`
    placeholder flag; ENGLAND == 30, DENMARK == 18 (Schmeichel), COSTA MARFIL == 113
    (the Bakayoko FICHA reference), NORWAY == 44 (Berg), HOLLAND == 27 (Van der Gouw).

Outputs:
  * app/art/flags/flag_NNN.png  (one per BANDERAS entry, real VGA colours)
  * assets/country_codes.json   (the authoritative PAISES decode: byCode + byName)

Run from the project root:  python3 tools/re/export_flags.py
"""

from __future__ import annotations

import json
import struct
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import pkf_unpack as P  # noqa: E402  (local tool, after sys.path tweak)

ROOT = Path(__file__).resolve().parents[2]
GAME = ROOT / "extracted" / "Premier Manager 98"
PAL_OFFSET = 0x5CA
NAME_XOR = 0x61


def vga_palette() -> list[tuple[int, int, int]]:
    """The shared 256-colour VGA palette (DAT.PKF +0x5CA, stored R,G,B,0)."""
    b = (GAME / "DAT.PKF").read_bytes()[PAL_OFFSET : PAL_OFFSET + 1024]
    return [(b[i * 4], b[i * 4 + 1], b[i * 4 + 2]) for i in range(256)]


def decode_os2_bmp(raw: bytes, pal: list[tuple[int, int, int]]) -> Image.Image:
    """Decode one OS/2 BITMAPCOREHEADER 8bpp DIB with an external palette."""
    dataoff = struct.unpack_from("<I", raw, 10)[0]
    w, h = struct.unpack_from("<HH", raw, 18)
    bpp = struct.unpack_from("<H", raw, 24)[0]
    if bpp != 8:
        raise ValueError(f"unexpected bpp {bpp} (want 8)")
    stride = ((w * bpp + 31) // 32) * 4  # rows padded to a 4-byte boundary
    px = raw[dataoff:]
    im = Image.new("RGB", (w, h))
    out = im.load()
    for y in range(h):
        row = px[(h - 1 - y) * stride : (h - 1 - y) * stride + w]  # bottom-up
        for x in range(min(w, len(row))):
            out[x, y] = pal[row[x]]
    return im


def country_table() -> list[str]:
    """PAISES.30 -> the ordered country names (index == flag code)."""
    b = (GAME / "DBDAT" / "PAISES.30").read_bytes()
    magic, _u1, count = struct.unpack_from("<4sII", b, 0)
    if magic != b"DMLT":
        raise ValueError(f"PAISES.30 bad magic {magic!r}")
    names: list[str] = []
    pos = 12
    for _ in range(count):
        (ln,) = struct.unpack_from("<H", b, pos)
        pos += 2
        names.append(bytes(c ^ NAME_XOR for c in b[pos : pos + ln]).decode("latin1"))
        pos += ln
    return names


def main() -> None:
    pal = vga_palette()
    names = country_table()

    # --- flags ---
    buf = (GAME / "DBDAT" / "BANDERAS.PKF").read_bytes()
    flags_dir = ROOT / "app" / "art" / "flags"
    flags_dir.mkdir(parents=True, exist_ok=True)
    for old in flags_dir.glob("flag_*.png"):
        old.unlink()
    n = 0
    for i, (_name, off, size) in enumerate(P.files_of(buf)):
        im = decode_os2_bmp(buf[off : off + size], pal)
        im.save(flags_dir / f"flag_{i:03d}.png")
        n += 1

    # --- country-code table ---
    by_code = {str(i): names[i] for i in range(len(names))}
    by_name = {names[i].upper(): i for i in range(len(names)) if names[i] != "XXX"}
    out = ROOT / "assets" / "country_codes.json"
    out.write_text(
        json.dumps(
            {
                "source": "DBDAT/PAISES.30 (XOR 0x61) parallel to DBDAT/BANDERAS.PKF BA9600NN; "
                "index == flag code (0 == 'XXX' blank placeholder).",
                "count": len(names),
                "byCode": by_code,
                "byName": by_name,
            },
            ensure_ascii=False,
            indent=1,
        ),
        encoding="utf-8",
    )

    # --- validation against known anchors (real player nationalities) ---
    anchors = {"ENGLAND": 30, "DENMARK": 18, "NORWAY": 44, "HOLLAND": 27, "COSTA MARFIL": 113}
    bad = [k for k, v in anchors.items() if by_name.get(k) != v]
    print(f"flags: wrote {n} PNGs -> {flags_dir.relative_to(ROOT)}")
    print(f"countries: {len(names)} entries -> {out.relative_to(ROOT)}")
    print(f"anchors {'OK' if not bad else 'MISMATCH: ' + str(bad)}: " + ", ".join(
        f"{k}={by_name.get(k)}" for k in anchors))
    if bad:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
