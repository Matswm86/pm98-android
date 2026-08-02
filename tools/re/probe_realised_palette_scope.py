#!/usr/bin/env python3
"""Scope the realised-palette sweep: which PKF entries actually CARE which table is used.

`docs/re/realised_palette_re.md` established that every frame MANAGER.EXE paints is
MANAGER.PAL + the 20 Windows statics, while `export_art.render` still decodes every `DM`
sprite (and every `force_vga=True` caller) through the shared VGA table at `DAT.PKF +0x5CA`.
The two tables differ at 21 of 256 entries, so the rule is only WRONG where a sprite
actually uses one of those 21 — everywhere else the two decodes are byte-identical and the
question does not arise.

This tool answers "where does it arise", exhaustively, off the owned PKFs:

    probe_realised_palette_scope.py            every PKF, every entry
    probe_realised_palette_scope.py DAT.PKF    one PKF

Output is one row per entry that USES an affected index, with the count. An entry that
prints nothing is decided: both tables render it identically and it needs no witness.
"""

from __future__ import annotations

import sys
from collections import Counter
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import export_flags as EF  # noqa: E402
import pkf_image as PI  # noqa: E402
from pkf_unpack import GAME, files_of  # noqa: E402

PKFS = ("DAT.PKF", "IMG.PKF", "RECURSOS.PKF", "PCF5.DAT", "SONIDOS.PKF")


def affected_indices() -> list[int]:
    vga = EF.vga_palette()
    real = EF.flag_palette()
    return [i for i in range(256) if vga[i] != real[i]]


def scan(pkf: str, bad: set[int]) -> list[tuple[str, str, int, int, str]]:
    """-> [(pkf, entry, n_affected_px, n_px, kind)] for entries that use an affected index."""
    path = GAME / pkf
    if not path.exists():
        return []
    buf = path.read_bytes()
    rows = []
    for name, off, size in files_of(buf):
        raw = buf[off : off + size]
        if raw[:2] not in (b"DM", b"BM"):
            continue
        kind = raw[:2].decode()
        try:
            idx = PI.dib_indices(bytes(raw))
        except Exception:
            continue
        counts = Counter(idx.flatten().tolist())
        # index 0 is the sprite's own transparent key on a DM; it is never painted.
        hits = sum(c for v, c in counts.items() if v in bad and not (kind == "DM" and v == 0))
        if hits:
            rows.append((pkf, name, hits, int(idx.size), kind))
    return rows


def main() -> int:
    bad = set(affected_indices())
    print(f"{len(bad)} affected indices: {sorted(bad)}\n")
    targets = sys.argv[1:] or list(PKFS)
    total = 0
    for pkf in targets:
        rows = scan(pkf, bad)
        n = len(rows)
        total += n
        print(f"=== {pkf}: {n} entr{'y' if n == 1 else 'ies'} use an affected index")
        for _p, name, hits, size, kind in sorted(rows, key=lambda r: -r[2]):
            print(f"    {kind}  {name:<28} {hits:>7} / {size:<7} px")
    print(f"\ntotal: {total}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
