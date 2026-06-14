#!/usr/bin/env python3
"""Extract audio from Premier Manager 98.

MUSICAS.PKF is a concatenation of ScreamTracker 3 (.s3m) modules - the game music.
Each module has the 'SCRM' magic at module+0x2C; the module starts 0x2C before it.
We carve start-to-next-start (trailing bytes are ignored by S3M players). 8 modules,
two titled "dinamic" (Dinamic Multimedia). These are plain tracker modules, NOT
LZ-packed - consistent with the rest of PM98's assets being unpacked.

Other audio (characterise / extend here):
  - COMENT.PKF  : Barry Davies match commentary (sound bank; same PKF header family).
  - SONIDOS/*.RAW : raw PCM sound effects.
  - SFX/*.PKF   : ambience / crowd.

Output: assets/audio/music/track_#.s3m
"""
from __future__ import annotations

import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
GAME = ROOT / "extracted" / "Premier Manager 98"
OUT = ROOT / "assets" / "audio" / "music"


def carve_s3m() -> int:
    d = (GAME / "MUSICAS.PKF").read_bytes()
    scrm = [m for m in range(len(d) - 4) if d[m:m + 4] == b"SCRM"]
    starts = [s - 0x2C for s in scrm if s - 0x2C >= 0]
    OUT.mkdir(parents=True, exist_ok=True)
    for k, st in enumerate(starts):
        end = starts[k + 1] if k + 1 < len(starts) else len(d)
        (OUT / f"track_{k}.s3m").write_bytes(d[st:end])
    return len(starts)


def main() -> None:
    n = carve_s3m()
    print(f"music: {n} S3M modules -> {OUT.relative_to(ROOT)}/")
    # quick characterisation of the rest (no extraction yet)
    for rel in ["SFX/COMENT.PKF", "SFX/AMBIENTE.PKF"]:
        p = GAME / rel
        if p.exists():
            head = p.read_bytes()[:16].hex(" ")
            print(f"  {rel}: {p.stat().st_size} B, hdr {head}")
    snd = GAME / "SONIDOS"
    if snd.exists():
        raws = list(snd.glob("*.RAW")) + list(snd.glob("*.raw"))
        print(f"  SONIDOS: {len(raws)} RAW PCM files")


if __name__ == "__main__":
    main()
