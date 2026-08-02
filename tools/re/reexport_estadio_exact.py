#!/usr/bin/env python3
"""Re-export the 12 GROUND stadium tiles through the EXACT decode path, and verify.

Usage: reexport_estadio_exact.py [--apply]

WHY (s92). The shipped `estadio<N>.png` came from `export_art.render()`'s Pillow path,
which honours the DIB's `bfOffBits` (1078) although the archive strips the 1024-byte
palette — so the rows were read 1024 bytes late. `fix_estadio_wrap.py` (s55) undid the
misregistration as a PERMUTATION of the decoded pixels, which put the tile at 99.17%
against the real render but could not restore the 640 px (rows 2/238/239 edges) whose
content the late read never decoded at all: those destination rows held the DIB's own
black scanlines, and the real content was provably nowhere in the decoded buffer. It IS
in the file: `pkf_image.dib_indices()` decodes from offset 54 and is correct at every
size (the module's own warning says to route ESTADIO through `--exact`).

Palette: the REALISED table (MANAGER.PAL + the 20 Windows statics), which is what the
running game paints in (docs/re/realised_palette_re.md) and what the s91 sweep already
moved these twelve tiles onto.

THE TWO-ROW SHIFT, measured not assumed: the exact decode lands the pixel grid two rows
EARLY against the real render (`np.roll(a, 2)` scores 99.17% — every row 2..239 exact —
and rolling anything else scores ~20%). Its two bottom rows are file-tail bytes, not
image. The true rows 0-1 are pure BLACK on every one of the eleven witnesses across all
five witnessed tiers, so the tile is reconstructed as [2 black scanlines] + [decode rows
0..237], which the verification below then holds to 100.00% per witness.

Verification: every real GROUND capture in the tree with a known client origin — five
capacity tiers across eleven frames. The tier-4 witness decided the original transform;
here it must land at 100.00% (the 639-px black edge gone), and every other witnessed
tier at 100% too.
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import export_art  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "app" / "art" / "screens" / "stadium"
SHOTS = ROOT / "screenshots"
PANEL = (299, 146)
W, H = 320, 240

# (capture, client origin, expected tile index) — the witnesses the ground agent
# identified: user captures at (641,196), wine captures at (0,0), refs at (0,0).
WITNESSES = [
    (SHOTS / "user-captures-2026-07-23-ground-squad-transfer/01_07-52-40.png", (641, 196), 4),
    (SHOTS / "user-captures-2026-07-23-ground-squad-transfer/07_07-54-30.png", (641, 196), 4),
    (SHOTS / "original-walkthrough-2026-07-02/172_154930.png", (0, 0), 4),
    (SHOTS / "wine-captures-2026-07-23-renew-ground-villa/31_ground.png", (0, 0), 3),
    (SHOTS / "wine-captures-2026-07-19-economics/s11_ground.png", (0, 0), 3),
    (SHOTS / "wine-captures-2026-07-28-lowdiv/39_ground_first.png", (0, 0), 2),
    (SHOTS / "wine-captures-2026-07-19-lowerdiv/w5_ground.png", (0, 0), 2),
    (ROOT / "tools/re/refs/lowdiv-2026-07-28/10_ground_birmingham_first.png", (0, 0), 2),
    (SHOTS / "parity-run-2026-07-16/orig/21_ground_improve.png", (0, 0), 1),
    (SHOTS / "wine-captures-2026-07-28-lowdiv/25_ground.png", (0, 0), 0),
    (ROOT / "tools/re/refs/lowdiv-2026-07-28/06_ground_barnet_third.png", (0, 0), 0),
]


def verify(tiles: dict[int, np.ndarray]) -> bool:
    all_exact = True
    for path, (cx, cy), tier in WITNESSES:
        if not path.exists():
            print(f"  witness MISSING: {path.relative_to(ROOT)}")
            continue
        full = np.asarray(Image.open(path).convert("RGB"))
        ox, oy = cx + PANEL[0], cy + PANEL[1]
        ref = full[oy : oy + H, ox : ox + W]
        d = np.abs(tiles[tier].astype(int) - ref.astype(int)).max(axis=2)
        exact = 100 * float((d == 0).mean())
        gt8 = 100 * float((d > 8).mean())
        flag = "" if gt8 == 0.0 else "   <-- NOT EXACT"
        print(f"  estadio{tier} vs {path.name:32} exact {exact:6.2f}%  >8 {gt8:5.2f}%{flag}")
        if gt8 > 0.0:
            all_exact = False
    return all_exact


def main() -> None:
    apply = "--apply" in sys.argv
    tiles: dict[int, np.ndarray] = {}
    for i in range(12):
        img = export_art.render(
            "RECURSOS.PKF", f"ESTADIO{i}.BMP", force_vga=True, exact=True
        ).convert("RGB")
        a = np.asarray(img)
        if a.shape != (H, W, 3):
            sys.exit(f"ESTADIO{i}: unexpected shape {a.shape}")
        # the two-row shift (see the docstring): 2 black scanlines + decode rows 0..237
        tiles[i] = np.vstack([np.zeros((2, W, 3), np.uint8), a[: H - 2]])
    ok = verify(tiles)
    if apply:
        for i, a in tiles.items():
            Image.fromarray(a).save(ART / f"estadio{i}.png")
        print(f"\nAPPLIED: 12 tiles re-exported through the exact path -> {ART.relative_to(ROOT)}")
    else:
        print("\nDRY RUN — re-run with --apply to write the tiles")
    if not ok:
        sys.exit(1)


if __name__ == "__main__":
    main()
