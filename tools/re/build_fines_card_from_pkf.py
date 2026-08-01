#!/usr/bin/env python3
"""Export the FINES (MULTAS) card straight out of RECURSOS.PKF.

This card is one of the few screens in the port whose art needs NO frame bake: every
pixel it draws is a whole file in the original archive, and MANAGER.EXE blits each of
them at a literal coordinate. So the "chrome" here is the game's own BMPs, 1:1, and
the only thing the port composes is where they go -- which is read out of the binary
(`docs/re/fines_re.md`).

Entries, by (folder id, name) -- names alone are ambiguous, RECURSOS holds seven
`FONDO.BMP`s and the folder id is the type-2 record's third u32:

    MULTAS (17)   FONDO.BMP     418x316  the panel  (== FUN_00549d40's own rect size)
    MULTAS (17)   MULTA.GIF     the gavel/fine sprite blitted at panel (0,0)
    ESTADIO (10)  EQUIPAM_0.BMP  40x26   floodlights      (== the icon rect size)
    ESTADIO (10)  EQUIPAM_2.BMP  40x26   changing rooms
    ESTADIO (10)  EQUIPAM_3.BMP  40x26   score board
    ESTADIO (10)  EQUIPAM_4.BMP  40x26   access
    ESTADIO (10)  EXTRAS_0.BMP   40x26   medical equipment

The two size agreements (418x316 panel vs the binary's `CRect` size, 40x26 icon vs the
binary's icon rect) are the cross-check that the right entries were picked -- neither
number was chosen here, both fall out of the archive and the disassembly independently.

Usage: build_fines_card_from_pkf.py [outdir]     (default app/art/screens/fines)
"""
from __future__ import annotations

import io
import json
import struct
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))

import pkf_image  # noqa: E402
import pkf_unpack  # noqa: E402
from export_art import riff_palette  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
GAME = ROOT / "extracted" / "Premier Manager 98"
OUT = ROOT / "app/art/screens/fines"

# (folder id, entry name, output stem, expected size or None)
WANT = [
    (17, "FONDO.BMP", "panel", (418, 316)),
    (10, "EQUIPAM_0.BMP", "icon_floodlights", (40, 26)),
    (10, "EQUIPAM_2.BMP", "icon_changing_rooms", (40, 26)),
    (10, "EQUIPAM_3.BMP", "icon_score_board", (40, 26)),
    (10, "EQUIPAM_4.BMP", "icon_access", (40, 26)),
    (10, "EXTRAS_0.BMP", "icon_medical", (40, 26)),
]

# Geometry, panel-relative, read out of MANAGER.EXE -- see docs/re/fines_re.md.
GEOMETRY = {
    "panel_origin": [111, 82],          # FUN_00436fb0(0x6f,0x52)  @0x549e0d
    "panel_size": [418, 316],           # FUN_00436fb0(0x1a2,0x13c) @0x549e02
    "row_y": [78, 122, 166, 210, 254],  # 0x4e then +0x2c per drawn row
    "icon_origin_x": 19,                # FUN_00436fb0(0x13, y)     @0x54a0a6
    "icon_size": [40, 26],              # FUN_00436fb0(0x28,0x1a)   @0x54a090
    "text_origin_x": 71,                # FUN_00436fb0(0x47, y-8)
    "text_size": [345, 42],             # FUN_00436fb0(0x159,0x2a)
    "text_dy": -8,
    "ok_origin": [336, 284],            # FUN_00436fb0(0x150,0x11c) @0x549f0d
    "ok_size": [74, 25],                # FUN_00436fb0(0x4a,0x19)   @0x549f03
    "title_font": "ProMan14",           # FUN_005beae0(s_ProMan14)  @0x549e9b
    "row_font": "ProMan8",              # FUN_005beae0(s_ProMan8)   in FUN_00549fe0
}


def entries(buf: bytes) -> list[dict]:
    return [r for r in pkf_unpack.parse(buf) if isinstance(r, dict) and r.get("type") == 2]


def payload(buf: bytes, recs: list[dict], folder: int, name: str) -> bytes:
    for r in recs:
        off, size, fid = r["u32s"]
        if fid == folder and r["name"] == name:
            return buf[off : off + size]
    raise KeyError(f"{name!r} not in RECURSOS folder {folder}")


def main() -> int:
    out = Path(sys.argv[1]) if len(sys.argv) > 1 else OUT
    out.mkdir(parents=True, exist_ok=True)
    buf = (GAME / "RECURSOS.PKF").read_bytes()
    recs = entries(buf)
    pal = riff_palette("MANAGER.PAL")

    for folder, name, stem, expect in WANT:
        raw = payload(buf, recs, folder, name)
        idx = pkf_image.dib_indices(raw)
        img = pkf_image.rgba(idx, pal, transparent=False)
        if expect is not None and img.size != expect:
            print(f"FAIL {name}: {img.size} != {expect}")
            return 1
        img.save(out / f"{stem}.png")
        print(f"  {name:<16} -> {stem}.png  {img.size}")

    gif = payload(buf, recs, 17, "MULTA.GIF")
    sprite = Image.open(io.BytesIO(gif)).convert("RGBA")
    sprite.save(out / "multa.png")
    print(f"  MULTA.GIF        -> multa.png  {sprite.size}")

    (out / "fines.json").write_text(json.dumps(GEOMETRY, indent=2) + "\n")
    print(f"  geometry         -> fines.json")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
