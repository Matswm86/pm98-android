#!/usr/bin/env python3
"""Bake the career-entry-flow art (NIVEL dialog + PRESEASON screen) from the PKFs.

Sources + palette calls per docs/re/nivel_screen_re.md and
docs/re/pretemporada_screen_re.md:

  * NIVELES dialog art lives in RECURSOS.PKF under two folders with DUPLICATE file
    names elsewhere in the archive (several FONDO.BMP etc.), so entries are selected
    by FOLDER ID, not by name: NIVELES=18 (Entrenador/Manager/fondo/ok),
    PREMIER\\ICONOS\\NIVELES=34 (Presidente/total re-skins), root ICONOS=2 (carga).
    All NIVELES BMPs carry a JUNK embedded palette -> force MENU.PAL (verified
    against walkthrough frame 003; MANAGER/DBASE/VGA render noise).
  * Preseason: EUROPA/SUDAMERICA maps in RECURSOS.PKF OFERTAS folder (embedded
    palette junk -> force MANAGER.PAL, verified vs frame 013), HOJA_CALENDARIO +
    pretemporada aux sprites in IMG.PKF (PRETEMP=22, PRETEMPORADA=23), and the
    seleccion BORRA delete glyph.

Sprites (idx0 transparent): ok, carga, hoja, borra, over, x. Screens/panels opaque.

Run from anywhere:  python3 tools/re/export_entry_flow.py [--sheet PATH]
"""

from __future__ import annotations

import io
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import export_art as ea  # noqa: E402
from pkf_unpack import GAME, parse  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]

# (pkf, folder_id, entry, out_rel, palette, transparent)
JOBS = [
    ("RECURSOS.PKF", 18, "FONDO.BMP", "app/art/screens/nivel/fondo.png", "MENU.PAL", False),
    (
        "RECURSOS.PKF",
        18,
        "ENTRENADOR0.BMP",
        "app/art/screens/nivel/entrenador0.png",
        "MENU.PAL",
        False,
    ),
    (
        "RECURSOS.PKF",
        18,
        "ENTRENADOR1.BMP",
        "app/art/screens/nivel/entrenador1.png",
        "MENU.PAL",
        False,
    ),
    ("RECURSOS.PKF", 18, "MANAGER0.BMP", "app/art/screens/nivel/manager0.png", "MENU.PAL", False),
    ("RECURSOS.PKF", 18, "MANAGER1.BMP", "app/art/screens/nivel/manager1.png", "MENU.PAL", False),
    (
        "RECURSOS.PKF",
        34,
        "PRESIDENTE0.BMP",
        "app/art/screens/nivel/presidente0.png",
        "MENU.PAL",
        False,
    ),
    (
        "RECURSOS.PKF",
        34,
        "PRESIDENTE1.BMP",
        "app/art/screens/nivel/presidente1.png",
        "MENU.PAL",
        False,
    ),
    ("RECURSOS.PKF", 34, "TOTAL0.BMP", "app/art/screens/nivel/total0.png", "MENU.PAL", False),
    ("RECURSOS.PKF", 34, "TOTAL1.BMP", "app/art/screens/nivel/total1.png", "MENU.PAL", False),
    ("RECURSOS.PKF", 18, "OK.BMP", "app/art/screens/nivel/ok.png", "MENU.PAL", True),
    ("RECURSOS.PKF", 2, "CARGA.BMP", "app/art/icons/carga.png", "MANAGER.PAL", True),
    # preseason
    (
        "RECURSOS.PKF",
        None,
        "EUROPA.BMP",
        "app/art/screens/pretemp/europa.png",
        "MANAGER.PAL",
        False,
    ),
    (
        "RECURSOS.PKF",
        None,
        "SUDAMERICA.BMP",
        "app/art/screens/pretemp/sudamerica.png",
        "MANAGER.PAL",
        False,
    ),
    (
        "IMG.PKF",
        22,
        "HOJA_CALENDARIO.BMP",
        "app/art/screens/pretemp/hoja_calendario.png",
        "MANAGER.PAL",
        True,
    ),
    # IMG.PKF PRETEMPORADA aux DM sprites (AZULBARRAS/OVER/X) decode to empty under
    # both the VGA and RIFF palettes (pixel data reads as all idx-0 — undecoded DM
    # variant); they are hover/fill textures the walkthrough frames show as flat
    # fills, so the screens draw those procedurally instead. Revisit if the DM
    # variant gets cracked.
    ("RECURSOS.PKF", None, "BORRA.BMP", "app/art/icons/borra.png", "MANAGER.PAL", True),
]


def entry_by_folder(pkf: str, folder_id: int | None, name: str) -> bytes:
    buf = (GAME / pkf).read_bytes()
    for r in parse(buf):
        if r.get("type") == 2 and r["name"] == name:
            off, size, fid = r["u32s"]
            if folder_id is None or fid == folder_id:
                return buf[off : off + size]
        if r.get("end"):
            break
    raise KeyError(f"{name} (folder {folder_id}) not in {pkf}")


def render(raw: bytes, pal_name: str, transparent: bool) -> Image.Image:
    raw = bytearray(raw)
    is_dm = raw[:2] == b"DM"
    if is_dm:
        raw[0] = ord("B")
    import struct

    hdr_size = struct.unpack_from("<I", raw, 14)[0]
    bf_off = struct.unpack_from("<I", raw, 10)[0]
    if hdr_size == 12 and bf_off == 26:
        # PCF5 palette-less OS/2-core DIB (Pillow mis-reads it): hand-decode with the
        # external RIFF palette, idx0 transparent (export_icons' proven path).
        import export_icons as ei

        return ei.decode_dib(bytes(raw), ea.riff_palette(pal_name))
    im = Image.open(io.BytesIO(bytes(raw)))
    im.load()
    im = im.convert("P")
    # DM sprites use the SHARED VGA palette; BM screens here carry junk embedded
    # palettes -> force the named external RIFF pal (verified vs frames 003/013).
    im.putpalette(ea.vga_palette() if is_dm else ea.riff_palette(pal_name))
    rgba = im.convert("RGBA")
    if transparent:
        idx = im.tobytes()
        alpha = Image.frombytes("L", im.size, bytes(0 if v == 0 else 255 for v in idx))
        rgba.putalpha(alpha)
    return rgba


def main() -> None:
    baked: list[tuple[str, Image.Image]] = []
    for pkf, fid, name, rel, pal, transparent in JOBS:
        try:
            img = render(entry_by_folder(pkf, fid, name), pal, transparent)
        except Exception as exc:  # noqa: BLE001 - report-and-continue cracker
            print(f"  FAIL {pkf}:{name}: {exc}")
            continue
        dst = ROOT / rel
        dst.parent.mkdir(parents=True, exist_ok=True)
        img.save(dst)
        baked.append((rel, img))
        print(f"  {rel}  {img.width}x{img.height}")
    print(f"baked {len(baked)} entry-flow assets")
    if "--sheet" in sys.argv:
        import export_icons as ei

        ei.contact_sheet(baked, Path(sys.argv[sys.argv.index("--sheet") + 1]))


if __name__ == "__main__":
    main()
