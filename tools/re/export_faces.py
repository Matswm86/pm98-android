#!/usr/bin/env python3
"""Export Premier Manager 98 player faces (mugshots) from the original archives to PNG.

Two photo banks, both keyed by a global player-photo id `J96NNNNN` (96 == the 1996
data season; NNNNN == the 5-digit player id == EQUIPOS's `photoId`, decoded in
`docs/re/faces_re.md`):

  * `DBDAT/BIGFOTO/EQ96<DDNN>.PKF` -- the big 124x182 profile photos, one PKF per
    club (DDNN == the club crest code, same as MINIESC/BIGFOTO; 72 clubs have a
    bank). These are standard "BM" Windows DIBs that carry a JUNK embedded palette
    (random noise), so the colours come from whatever palette is REALISED.
  * `DBDAT/MINIFOTO.PKF` -- the 32x32 squad-list thumbnails (690), a CUSTOM mini
    format: a 26-byte "BM"-tagged stub header whose width/height/bpp fields are
    GARBAGE, followed by 1024 bytes of raw 8-bit indices at offset 26, stored
    BOTTOM-UP. (Pillow misparses the stub and yields an all-zero frame, so the mini
    is decoded by hand here.)

THE REALISED PALETTE IS `MANAGER.PAL` + THE WINDOWS STATICS, NOT THE SHARED VGA TABLE
at `DAT.PKF +0x5ca`. Both banks were exported through the VGA table because the doc's
own check -- "garbage under embedded, a clean photo under VGA" -- compared the embedded
palette against VGA and never asked the third question. Measured 2026-08-02 on the FICHA
card's 32x32 photo block in the walkthrough's own frames (079/081/084, rect (130,68)
32x32):

    colours in the block that are NOT in the shared VGA table      5
    colours in the block that are NOT in MANAGER.PAL + statics     0

and re-indexing the exported `mini/8432.png` through MANAGER.PAL takes it from **138
wrong px of 1024 to 0**. This is the same defect `export_flags.flag_palette` documents
for the MINIBAND flags and s90 found again in the RIDIESC kit bank; 21 of the 256
entries differ, and every sampled face uses at least one of them.

Generic fallback: `IMG.PKF::FOTO_GENERAL.BMP` -- the silhouette the original shows
for any player whose photoId has no bank entry. Exported to `_generic.png`.

Output (id-named so the runtime resolves `res://art/faces/<photoId>.png`):
  app/art/faces/<id>.png         big profile photos      (~612 ids)
  app/art/faces/mini/<id>.png    32x32 squad thumbnails   (~690 ids)
  app/art/faces/_generic.png     silhouette fallback
  app/data/face_index.json       {"big":[...ids], "mini":[...ids]}  manifest

Usage:
  export_faces.py            # export everything to app/art/faces/
  export_faces.py --english  # only the English-pyramid clubs (codes 0301-0392)
"""

from __future__ import annotations

import io
import json
import sys
from pathlib import Path

import export_art as ea
from export_flags import flag_palette
from PIL import Image, ImageFile
from pkf_unpack import GAME, files_of

ImageFile.LOAD_TRUNCATED_IMAGES = True  # PCF5 DIBs omit a few trailing pad bytes

ROOT = Path(__file__).resolve().parent.parent.parent
FACES = ROOT / "app" / "art" / "faces"
MINI_DIR = FACES / "mini"
MANIFEST = ROOT / "app" / "data" / "face_index.json"
BIGFOTO = GAME / "DBDAT" / "BIGFOTO"


def realised_palette() -> list[int]:
    """MANAGER.PAL + the 20 Windows statics, flat RGB -- the palette the running game
    shows these banks in. `export_flags.flag_palette` proved the table on the MINIBAND
    flags; the module docstring records the FICHA-card measurement that pins it here."""
    return [v for rgb in flag_palette() for v in rgb]


def photo_id(entry_name: str) -> int:
    """`J9601851.BMP` -> 1851 (drop the J and the 96 season prefix; last 5 digits)."""
    return int(entry_name[1:].split(".")[0]) % 100000


def export_big(english_only: bool) -> set[int]:
    """Full-frame profile photo under the REALISED palette (the embedded one is junk;
    see the module docstring for why it is not the shared VGA table either). Saved as an
    indexed (P-mode) PNG -- lossless and ~2.4x smaller than RGB, since the source is
    already 256-colour."""
    pal = realised_palette()
    ids: set[int] = set()
    for pkf in sorted(BIGFOTO.glob("EQ96*.PKF")):
        code = pkf.stem[4:]  # EQ960301 -> 0301
        if english_only and not ("0301" <= code <= "0392"):
            continue
        buf = pkf.read_bytes()
        for name, off, size in files_of(buf):
            raw = bytearray(buf[off : off + size])
            if raw[:2] == b"DM":
                raw[0] = ord("B")
            im = Image.open(io.BytesIO(bytes(raw)))
            im.load()
            im = im.convert("P")
            im.putpalette(pal)
            pid = photo_id(name)
            im.save(FACES / f"{pid}.png", optimize=True)
            ids.add(pid)
    return ids


def export_mini() -> set[int]:
    """Hand-decode the 32x32 bottom-up raw-index minis (Pillow can't parse the stub)."""
    pal = realised_palette()
    buf = (GAME / "DBDAT" / "MINIFOTO.PKF").read_bytes()
    ids: set[int] = set()
    for name, off, size in files_of(buf):
        raw = buf[off : off + size]
        data = raw[26 : 26 + 1024]
        if len(data) < 1024:
            continue
        im = Image.frombytes("P", (32, 32), data).transpose(Image.FLIP_TOP_BOTTOM)
        im.putpalette(pal)
        pid = photo_id(name)
        im.save(MINI_DIR / f"{pid}.png", optimize=True)
        ids.add(pid)
    return ids


def export_generic() -> None:
    img = ea.render("IMG.PKF", "FOTO_GENERAL.BMP", force_vga=True, transparent=True)
    img.save(FACES / "_generic.png")


def main() -> None:
    english_only = "--english" in sys.argv[1:]
    FACES.mkdir(parents=True, exist_ok=True)
    MINI_DIR.mkdir(parents=True, exist_ok=True)
    big = export_big(english_only)
    mini = export_mini()
    export_generic()
    MANIFEST.write_text(
        json.dumps(
            {
                "note": "Player-face banks keyed by EQUIPOS photoId (J96NNNNN -> NNNNN). "
                "big = 124x182 profile photos; mini = 32x32 squad thumbnails; both "
                "under the shared VGA palette. Runtime: res://art/faces/<id>.png and "
                "res://art/faces/mini/<id>.png, _generic.png fallback. See "
                "docs/re/faces_re.md.",
                "big": sorted(big),
                "mini": sorted(mini),
            },
            indent=1,
        )
    )
    print(
        f"faces: {len(big)} big, {len(mini)} mini "
        f"({'English only' if english_only else 'all clubs'}) -> {FACES}"
    )
    print(f"manifest -> {MANIFEST}")


if __name__ == "__main__":
    main()
