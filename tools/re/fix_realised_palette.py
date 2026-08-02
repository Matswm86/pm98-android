#!/usr/bin/env python3
"""Re-colour already-exported art that was decoded through the WRONG palette table.

`export_art.render` decoded every `DM` sprite and every `force_vga=True` caller through the
shared VGA table at `DAT.PKF +0x5CA`. `docs/re/realised_palette_re.md` established that
MANAGER.EXE paints in MANAGER.PAL + the 20 Windows statics instead, and
`probe_realised_palette_witness.py` decides it corpus-wide with no free parameter:
**0 VGA pixels against 12,919,661 realised ones over all 1,752 original captures.** The rule
in `render()` is fixed; this tool fixes the art that rule already produced.

It is a pure colour remap of the 21 differing entries, and that is EXACTLY equivalent to a
re-decode, for two reasons that are checked rather than assumed:

* none of the 21 VGA colours appears anywhere in the realised table, so a pixel carrying one
  can only have come from that index (asserted at startup);
* on the 7 files of `app/art/screens/cup/` that are plain exporter output, a forced
  re-export through the fixed `render()` is **byte-identical** to this remap. The other 4
  in that bank are curated by hand — which is the reason this tool exists at all: re-running
  every exporter would discard curation, and several of them need original frames that are
  not all in the tree.

Deliberately NOT swept (both settled in `realised_palette_re.md` §4):

* `app/art/faces/dbcard/` — Dbasewin's own rendering under its own realised palette. It uses
  none of the 21 indices, so this tool would not touch it even if pointed at it.
* anything that uses no affected index — a no-op either way.

    fix_realised_palette.py                 report what would change (default: dry run)
    fix_realised_palette.py --write         apply it
    fix_realised_palette.py --write PATH..  restrict to given files/dirs
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import export_art as ea  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "app/art"


def remap_table() -> dict[tuple[int, int, int], tuple[int, int, int]]:
    """{wrong VGA colour: realised colour} for the entries where the two tables differ."""
    v = ea.vga_palette()
    r = ea.realised_palette()
    vga = [(v[i * 3], v[i * 3 + 1], v[i * 3 + 2]) for i in range(256)]
    real = [(r[i * 3], r[i * 3 + 1], r[i * 3 + 2]) for i in range(256)]
    bad = [i for i in range(256) if vga[i] != real[i]]
    clash = {i: vga[i] for i in bad if vga[i] in set(real)}
    if clash:
        raise SystemExit(f"ambiguous: VGA colours also present in the realised table: {clash}")
    return {vga[i]: real[i] for i in bad}


def fix(path: Path, table: dict, write: bool) -> int:
    """-> number of pixels remapped in `path` (0 if it does not use an affected index)."""
    im = Image.open(path)
    mode = im.mode
    if mode == "P":
        # Remap the palette itself, so an indexed PNG stays indexed and byte-comparable.
        pal = im.getpalette() or []
        n = 0
        idx = np.array(im)
        for i in range(len(pal) // 3):
            c = (pal[i * 3], pal[i * 3 + 1], pal[i * 3 + 2])
            if c in table:
                hits = int((idx == i).sum())
                if hits:
                    n += hits
                    pal[i * 3 : i * 3 + 3] = list(table[c])
        if n and write:
            im.putpalette(pal)
            im.save(path)
        return n

    a = np.array(im.convert("RGBA"))
    out = a.copy()
    n = 0
    for c, d in table.items():
        m = (a[..., 0] == c[0]) & (a[..., 1] == c[1]) & (a[..., 2] == c[2])
        hits = int(m.sum())
        if hits:
            n += hits
            out[m, 0], out[m, 1], out[m, 2] = d
    if n and write:
        Image.fromarray(out, "RGBA").save(path)
    return n


def main() -> int:
    args = sys.argv[1:]
    write = "--write" in args
    targets = [Path(a) for a in args if not a.startswith("--")] or [ART]
    files: list[Path] = []
    for t in targets:
        files += sorted(t.rglob("*.png")) if t.is_dir() else [t]

    table = remap_table()
    print(
        f"{len(table)} wrong colours -> realised; {len(files)} PNGs; "
        f"{'WRITING' if write else 'dry run'}\n"
    )
    total = 0
    touched = 0
    for f in files:
        n = fix(f, table, write)
        if n:
            touched += 1
            total += n
            print(f"  {f.relative_to(ROOT)}  {n} px")
    print(f"\n{touched} files, {total} px")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
