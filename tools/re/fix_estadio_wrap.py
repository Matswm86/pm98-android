#!/usr/bin/env python3
"""Un-wrap the 12 GROUND stadium tiles: undo the export's column/row misregistration.

⚠ OBSOLETE FOR THE SHIPPED TILES (s92). `tools/re/reexport_estadio_exact.py` re-exported
all twelve through `pkf_image.dib_indices()` (the exact path), which restores the 640 px
the unwrap PERMUTATION could never recover (rows 2/238/239 — the 0.83% black edge), and
verifies 100.00% against eleven real renders across five tiers. The shipped tiles are NOT
wrapped any more, so running this with --apply would corrupt them; --apply now refuses.
Kept for the s55 measurement record.

Usage: fix_estadio_wrap.py [--apply] [--verify]

FINDING (s55, from the owner's 2026-07-23 GROUND captures). Every
`app/art/screens/stadium/estadio<N>.png` carries a hard vertical SEAM at column 255->256 that
the real game does not show. Measured as the per-column mean |RGB gap|, that column is the
maximum in ALL 12 tiles at z = 13.1 to 15.3 sigma above each tile's own mean gap; the real
GROUND panel's worst column is only z = 3.4, and not there. The same seam is in the source
`RECURSOS.PKF ESTADIO<N>.BMP`, so it is a PCF5 DIB decode artefact, not a bad crop of ours.

THE TRANSFORM, solved not guessed. Ground truth is
`screenshots/user-captures-2026-07-23-ground-squad-transfer/01_07-52-40.png` — the real
MANAGER.EXE GROUND screen for Man Utd / Old Trafford (tier 4), captured at 1:1 with the game's
client area at (641, 196). Template-matching 12 patches spread across the panel into the tile
located every one of them at ZERO differing pixels, and they agree on a single mapping:

    panel(bx, by)  <-  tile[(by + (2 if bx < 64 else 1)) % 240][(bx + 256) % 320]

i.e. the columns are rotated by 256 AND the row offset steps by one across that wrap — the
signature of a flat-buffer misregistration, not a clean column roll. Applying it and drawing at
(299, 146):

    transform                         drawn at      exact px    >8 px
    solved mapping (this fix)         (299, 146)      98.2%       0.8%
    flat roll -256                    (299, 146)      83.3%      15.9%   <- right 256 cols only
    column roll +64                   (299, 145)      83.1%      16.1%
    none (what ships today)           (299, 148)       0.5%      96.5%

The 83% variants fix columns 64..319 (0.8% differing) and leave columns 0..63 wrong (80%
differing); only the two-row mapping fixes both. Note the y: the tile is drawn at **146**, not
the 148 in `StadiumScreen.SCENE_BOX` and the RE doc — corrected alongside this.

SCOPE, stated so it is not over-claimed: tier 4 is the only tile with a real render to check
against, and it lands at 98.2%. The other 11 are corrected by the same mapping on the strength
of the shared seam signature (identical column, same z band) — they are NOT independently
render-verified. Capture a GROUND screen for a club in another capacity tier to close that.

The capture's frames 01-12 all show a pixel-identical panel (0.0% between them), so the picture
is static — no animation is being mistaken for an offset.
"""

import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "app" / "art" / "screens" / "stadium"
REF = ROOT / "screenshots" / "user-captures-2026-07-23-ground-squad-transfer" / "01_07-52-40.png"
REF_CLIENT = (641, 196)  # the wine window's client area inside the 1920x1080 capture
PANEL = (299, 146)  # where MANAGER.EXE draws the tile, solved above
W, H = 320, 240


def unwrap(tile: np.ndarray) -> np.ndarray:
    bx = np.arange(W)[None, :].repeat(H, 0)
    by = np.arange(H)[:, None].repeat(W, 1)
    return tile[(by + np.where(bx < 64, 2, 1)) % H, (bx + 256) % W]


def seam_z(a: np.ndarray) -> tuple[int, float]:
    """Column with the largest mean |RGB gap| to its right neighbour, and its z-score."""
    gap = np.abs(np.diff(a.astype(int), axis=1)).sum(axis=2).mean(axis=0)
    k = int(np.argmax(gap))
    return k, float((gap[k] - gap.mean()) / gap.std())


def verify(tile4: np.ndarray) -> None:
    if not REF.exists():
        print(f"  verify SKIPPED — no reference at {REF}")
        return
    full = np.asarray(Image.open(REF).convert("RGB"), dtype=int)
    ox, oy = REF_CLIENT[0] + PANEL[0], REF_CLIENT[1] + PANEL[1]
    ref = full[oy : oy + H, ox : ox + W]
    for name, img in (("as shipped", tile4), ("unwrapped", unwrap(tile4))):
        d = np.abs(img.astype(int) - ref).max(axis=2)
        print(
            f"  tier 4 {name:11} vs real render: exact {100 * (d == 0).mean():5.2f}%  "
            f">8 {100 * (d > 8).mean():5.2f}%"
        )


def main() -> None:
    apply = "--apply" in sys.argv
    if apply:
        sys.exit("REFUSED: the shipped tiles come from reexport_estadio_exact.py (s92) "
                 "and are not wrapped — applying the unwrap would corrupt them.")
    tiles = sorted(ART.glob("estadio*.png"), key=lambda p: int(p.stem[7:]))
    if not tiles:
        sys.exit(f"no estadio tiles under {ART}")
    for p in tiles:
        im = Image.open(p).convert("RGB")
        if im.size != (W, H):
            print(f"  {p.name}: SKIP — {im.size}, expected ({W}, {H})")
            continue
        a = np.asarray(im)
        k, z = seam_z(a)
        fixed = unwrap(a)
        k2, z2 = seam_z(fixed)
        print(f"  {p.name:15} seam x={k:3d} z={z:5.1f}  ->  x={k2:3d} z={z2:5.1f}")
        if p.stem == "estadio4" and ("--verify" in sys.argv or not apply):
            verify(a)
        if apply:
            Image.fromarray(fixed).save(p)
    print(f"\n{'APPLIED' if apply else 'DRY RUN'} to {len(tiles)} tiles")
    if not apply:
        print("re-run with --apply to write them")


if __name__ == "__main__":
    main()
