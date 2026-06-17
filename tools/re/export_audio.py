#!/usr/bin/env python3
"""Extract PM98's original audio and convert it to Godot-playable Ogg Vorbis.

PM98 (the PCF5 engine) ships three audio sources, all owned/copyrighted and so
NOT committed (`extracted/` is gitignored). This tool reads them at build time and
writes the converted `.ogg` assets into `app/audio/` (which ARE committed, exactly
like the kit PNGs from map_crests.py): CI then only regenerates the `.import` files.

Sources (verified by tools/re/pkf_unpack + the EXE string table):
  * MUSICAS.PKF  -> 8x ScreamTracker-3 `.S3M` modules. MANAGER.EXE references
    `musicas\\dinamic0.s3m`..`dinamic5.s3m` as the in-game music; DINAMIC0 is the
    front-end theme. (DINABASE/DINABAS2 are the longer DB-editor themes, unused here.)
    Rendered with ffmpeg's libopenmpt demuxer.
  * SONIDOS/*.RAW   -> headerless unsigned-8-bit mono PCM @ 11025 Hz UI sounds
    (SELEC8 = select/confirm, PASA8 = navigate). The trailing "8" = 8-bit.
  * SFX/AMBIENTE.PKF -> headerless u8/11025 mono match SFX (Spanish names):
    SILBATO=whistle, SILBATOF=final whistle, GOL=goal roar, AMARIL=yellow-card
    reaction, ROJAL=red-card reaction, FONDO=crowd ambience bed, ENTRADA=tackle,
    POSTE=woodwork. Sample rate verified by duration sanity (whistle 0.63s @ 11025).

Run from the repo with `extracted/Premier Manager 98/` present and ffmpeg installed:
    python3 tools/re/export_audio.py
"""

from __future__ import annotations

import subprocess
import sys
import tempfile
from pathlib import Path

from pkf_unpack import files_of  # tool-local

ROOT = Path(__file__).resolve().parent.parent.parent
GAME = ROOT / "extracted" / "Premier Manager 98"
OUT = ROOT / "app" / "audio"

RAW_RATE = 11025  # u8 mono PCM rate for SONIDOS + AMBIENTE (verified by duration)

# music: archive-member -> (out relpath, ffmpeg args). S3M via libopenmpt demuxer.
MUSIC = [
    ("MUSICAS.PKF", "DINAMIC0.S3M", "music/menu.ogg", ["-ac", "2", "-ar", "22050", "-q:a", "3"]),
]

# u8/11025 mono raw -> ogg. (archive | None for loose file, member, out relpath)
SFX = [
    (None, "SONIDOS/SELEC8.RAW", "sfx/select.ogg"),
    (None, "SONIDOS/PASA8.RAW", "sfx/nav.ogg"),
    ("SFX/AMBIENTE.PKF", "SILBATO", "sfx/whistle.ogg"),
    ("SFX/AMBIENTE.PKF", "SILBATOF", "sfx/whistle_final.ogg"),
    ("SFX/AMBIENTE.PKF", "GOL", "sfx/goal.ogg"),
    ("SFX/AMBIENTE.PKF", "AMARIL", "sfx/card_yellow.ogg"),
    ("SFX/AMBIENTE.PKF", "ROJAL", "sfx/card_red.ogg"),
    ("SFX/AMBIENTE.PKF", "FONDO", "sfx/crowd.ogg"),
    ("SFX/AMBIENTE.PKF", "ENTRADA", "sfx/tackle.ogg"),
    ("SFX/AMBIENTE.PKF", "POSTE", "sfx/post.ogg"),
]


def _member(archive: str, name: str) -> bytes:
    buf = (GAME / archive).read_bytes()
    for n, off, size in files_of(buf):
        if n == name or n == name + ".BMP" or n.split(".")[0] == name:
            return buf[off : off + size]
    raise KeyError(f"{name} not in {archive}")


def _ffmpeg(args: list[str], dst: Path) -> None:
    dst.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", *args, str(dst)], check=True)


def main() -> None:
    if not GAME.exists():
        print(f"!! {GAME} not present (extracted/ is gitignored); cannot export.", file=sys.stderr)
        sys.exit(1)

    with tempfile.TemporaryDirectory() as td:
        tmp = Path(td)
        for archive, member, rel, args in MUSIC:
            src = tmp / member
            src.write_bytes(_member(archive, member))
            _ffmpeg(["-i", str(src), *args], OUT / rel)
            print(f"  music {rel}  ({(OUT / rel).stat().st_size // 1024} KB)")

        for archive, member, rel in SFX:
            if archive is None:
                data = (GAME / member).read_bytes()
            else:
                data = _member(archive, member)
            src = tmp / (rel.replace("/", "_") + ".raw")
            src.write_bytes(data)
            _ffmpeg(
                ["-f", "u8", "-ar", str(RAW_RATE), "-ac", "1", "-i", str(src), "-q:a", "3"],
                OUT / rel,
            )
            print(f"  sfx   {rel}  ({(OUT / rel).stat().st_size // 1024} KB)")

    total = sum(p.stat().st_size for p in OUT.rglob("*.ogg"))
    print(f"wrote {len(MUSIC) + len(SFX)} oggs -> {OUT.relative_to(ROOT)}  ({total // 1024} KB total)")


if __name__ == "__main__":
    main()
