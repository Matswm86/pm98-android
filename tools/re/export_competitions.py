#!/usr/bin/env python3
r"""Bake the PM98 competition BIG-logo art from IMG.PKF into the Godot art tree.

These are the `img\premier\copas\* BIG.BMP` trophy/emblem sprites the CupScreen names:
large `DM` entries (the "BM" magic patched to "DM") drawn with the SHARED 256-colour VGA
palette at DAT.PKF+0x5ca, index 0 = transparent. Same path export_art.py proved on the
crests + the European trophies already in app/art/screens/cup/.

Each logo is rendered, then trimmed to its alpha bounding box so it sits content-tight
(CupScreen.gd scales by HEIGHT into a fixed 150px band, so a tight crop centres cleanly).

The European set (ligacamp/uefa/recopa/supercopa/intercont) + cocacola + charity were
baked + hand-curated by an earlier session and are LEFT ALONE: this script writes only the
domestic + Italian/Spanish emblems that were still missing (the generic `trophy.png`
placeholder stood in for the real F.A. Cup until now). Pass --force to re-bake everything
(writes the full MAP, including the curated ones).

Run from anywhere (paths resolve from this file). Reads the gitignored `extracted/` tree;
writes committable derived PNGs under `app/art/screens/cup/`.

Usage:
  export_competitions.py              # bake the missing emblems (skip ones already present)
  export_competitions.py --force      # (re)bake the full MAP, overwriting existing PNGs
  export_competitions.py --sheet P    # also write a labelled contact sheet to P
"""
from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
import export_art as ea  # noqa: E402  (shared PKF entry reader + DM/VGA renderer)

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "app" / "art" / "screens" / "cup"
PKF = "IMG.PKF"

# IMG.PKF entry name -> output filename under app/art/screens/cup/.
# The European/misc set the prior session curated is included for provenance but only
# (re)written under --force; the bare-name run bakes the domestic + IT/ES emblems that
# the CupScreen routing still lacked authentic art for.
MAP: list[tuple[str, str]] = [
    # --- English domestic (newly baked) ---
    ("FACUP BIG.BMP", "facup.png"),         # the real F.A. Cup trophy (was generic trophy.png)
    ("LEAGUE BIG.BMP", "league.png"),       # the English league championship trophy
    # --- Spanish / Italian domestic (newly baked; art ready for those career flows) ---
    ("COPAREY BIG.BMP", "coparey.png"),     # Copa del Rey
    ("ESCUDETTO BIG.BMP", "escudetto.png"),  # Serie A scudetto shield
    ("COPA_ITALIA BIG.BMP", "copaitalia.png"),  # Coppa Italia
    # --- already curated (only rewritten with --force) ---
    ("COCACOLA BIG.BMP", "cocacola.png"),
    ("CHARITY BIG.BMP", "charity.png"),
    ("LIGACAMPEONES BIG.B", "ligacamp.png"),
    ("UEFA BIG.BMP", "uefa.png"),
    ("RECOPA BIG.BMP", "recopa.png"),
    ("SUPERCOPA_EUROPA BI", "supercopa.png"),
    ("INTERCONTINENTAL BI", "intercont.png"),
]
CURATED = {"cocacola.png", "charity.png", "ligacamp.png", "uefa.png",
           "recopa.png", "supercopa.png", "intercont.png"}


def keep_largest_blob(img: Image.Image) -> Image.Image:
    """Zero out every opaque pixel not in the largest 8-connected component.

    A few of the BIG bitmaps carry a detached registration/edge stray (ESCUDETTO has a
    ~16px sliver to the right of the shield; COPA_ITALIA a small blob to the left of the
    trophy). The real emblem is always the single dominant blob, so we flood-fill the
    alpha mask and keep only the biggest one before the bbox trim.
    """
    w, h = img.size
    a = img.getchannel("A").load()
    seen = bytearray(w * h)
    best: list[int] = []
    for sy in range(h):
        for sx in range(w):
            if seen[sy * w + sx] or a[sx, sy] == 0:
                continue
            stack = [(sx, sy)]
            seen[sy * w + sx] = 1
            comp: list[int] = []
            while stack:
                x, y = stack.pop()
                comp.append(y * w + x)
                for dx in (-1, 0, 1):
                    for dy in (-1, 0, 1):
                        nx, ny = x + dx, y + dy
                        if 0 <= nx < w and 0 <= ny < h and not seen[ny * w + nx] and a[nx, ny] > 0:
                            seen[ny * w + nx] = 1
                            stack.append((nx, ny))
            if len(comp) > len(best):
                best = comp
    keep = set(best)
    px = img.load()
    for i in range(w * h):
        if i not in keep:
            px[i % w, i // w] = (0, 0, 0, 0)
    return img


def bake(force: bool) -> list[tuple[str, Image.Image]]:
    OUT.mkdir(parents=True, exist_ok=True)
    baked: list[tuple[str, Image.Image]] = []
    for name, rel in MAP:
        dst = OUT / rel
        if rel in CURATED and not force:
            print(f"  skip {rel} (curated; --force to rebake)")
            continue
        if dst.exists() and not force:
            print(f"  skip {rel} (exists; --force to overwrite)")
            continue
        try:
            img = ea.render(PKF, name, force_vga=True, transparent=True).convert("RGBA")
        except Exception as exc:  # noqa: BLE001 - report-and-continue cracker
            print(f"  FAIL {name}: {exc}")
            continue
        img = keep_largest_blob(img)         # drop detached registration/edge strays
        bbox = img.getbbox()                 # trim transparent margin -> content-tight
        if bbox:
            img = img.crop(bbox)
        img.save(dst)
        baked.append((rel, img))
        print(f"  wrote {rel} {img.size}")
    return baked


def contact_sheet(baked: list[tuple[str, Image.Image]], path: Path) -> None:
    if not baked:
        return
    cellw, cellh, pad, label = 170, 260, 6, 14
    cols = len(baked)
    sh = Image.new("RGB", (cols * cellw, cellh), (190, 195, 205))
    dr = ImageDraw.Draw(sh)
    for i, (rel, im) in enumerate(baked):
        sc = min((cellw - 20) / im.width, (cellh - 40) / im.height)
        t = im.resize((int(im.width * sc), int(im.height * sc)), Image.NEAREST)
        x = i * cellw + (cellw - t.width) // 2
        sh.paste(t.convert("RGB"), (x, pad), t)
        dr.text((i * cellw + pad, cellh - 22), f"{Path(rel).stem} {im.size}", fill=(10, 10, 30))
    path.parent.mkdir(parents=True, exist_ok=True)
    sh.save(path)
    print(f"wrote contact sheet {path}")


def main() -> None:
    force = "--force" in sys.argv
    baked = bake(force)
    print(f"baked {len(baked)} competition logos -> {OUT}")
    if "--sheet" in sys.argv:
        contact_sheet(baked, Path(sys.argv[sys.argv.index("--sheet") + 1]))


if __name__ == "__main__":
    main()
