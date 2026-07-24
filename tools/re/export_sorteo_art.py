#!/usr/bin/env python3
"""Export the SORTEO (cup-draw) screen's art from IMG.PKF -> app/art/screens/cupdraw/.

The set is not a guess: MANAGER.EXE names every file this screen loads, in one
contiguous string block at 0x255670-0x255aa4 (`img\\sorteo\\...`), and each of them
is a real IMG.PKF entry:

    0x2559d0  img\\sorteo\\frames\\fondo.bmp              188x144  the drum + table backdrop
    0x2558c0  img\\sorteo\\frames\\Bombo00..11.bmp          92x92   the drum, 12 rotation frames
    0x2557f2  img\\sorteo\\frames\\Bola0..3.bmp             24x20   the drawn ball
    0x255712  img\\sorteo\\frames\\Mano0..7.bmp            <=185x76 the hand reaching in
    0x255670  img\\sorteo\\flecha {azul,verde} {izda,dcha}.bmp      tie-detail arrows
    0x255a94  img\\stop0.bmp                              15x14   the FINISH button's STOP sign
    0x2559ec  img\\copas\\ligacampeones sorteo.bmp          72x144  European Cup strip
    0x255a10  img\\copas\\uefa sorteo.bmp                   72x144  U.E.F.A. Cup strip
    0x255a2c  img\\copas\\recopa sorteo.bmp                 72x144  Cup Winners' Cup strip
    0x255a48  img\\premier\\copas\\cocacola sorteo.bmp       72x144  Coca-Cola Cup strip
    0x255a70  img\\premier\\copas\\facup sorteo.bmp          72x144  F.A. Cup strip

Two more `* SORTEO.BMP` strips ship in IMG.PKF but are NOT in this screen's loader
block -- CHARITY and SUPERCOPA_EUROPA. They are exported too (same 72x144 cut, real
art) and used for the single-tie finals; INTERCONTINENTAL has no SORTEO strip at all,
so that competition keeps its old presentation rather than borrowing someone else's art.

Palette: MANAGER.PAL (the RIFF `PAL ` in DAT.PKF), NOT the shared VGA table. Measured,
not assumed -- the two differ at 20 indices and only MANAGER.PAL reproduces the real
frame (VGA renders index 111 as (24,24,16) where the game shows (10,15,0), which is
1232 of the picture's pixels).

Decode goes through `pkf_image.dib_indices` (rows at offset 54); the old Pillow path
mis-registers these by 1024 bytes -- see that module's docstring.

Verification (tools/re/diff_cupdraw_parity.py, and re-asserted at the end of this
script): black window at (31,76) 260x144, competition strip at (31,76), fondo at
(103,76), both index-0 transparent, then the drum blitted OPAQUE (index 0 -> black)
at (136,76) reproduces `74_after_wk4.png` at 100.0000% exact pixels.

Run:  python3 tools/re/export_sorteo_art.py
"""

from __future__ import annotations

from pathlib import Path

import numpy as np
import pkf_image
from PIL import Image
from pkf_unpack import GAME, files_of

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "app" / "art" / "screens" / "cupdraw"
FRAME = ROOT / "screenshots" / "wine-captures-2026-07-18-goalscorers" / "74_after_wk4.png"

# Entry ordinals in IMG.PKF directory order. Names REPEAT across folders (there are two
# SORTEO.BMP and several FONDO.BMP), so the index is the unambiguous handle; the name is
# asserted against the index below so a different IMG.PKF can never silently shift them.
ENTRIES: list[tuple[int, str, str]] = [
    # index, expected PKF name, output stem
    (257, "FONDO.BMP", "fondo"),
    (266, "STOP0.BMP", "stop0"),
    (209, "FACUP SORTEO.BMP", "sorteo_facup"),
    (204, "COCACOLA SORTEO.BMP", "sorteo_cocacola"),
    (58, "LIGACAMPEONES SORTE", "sorteo_european_cup"),
    (94, "UEFA SORTEO.BMP", "sorteo_uefa"),
    (75, "RECOPA SORTEO.BMP", "sorteo_cup_winners"),
    (199, "CHARITY SORTEO.BMP", "sorteo_charity"),
    (88, "SUPERCOPA_EUROPA SO", "sorteo_supercup"),
    (235, "FLECHA AZUL DCHA.BM", "flecha_azul_dcha"),
    (236, "FLECHA AZUL IZDA.BM", "flecha_azul_izda"),
    (237, "FLECHA VERDE DCHA.B", "flecha_verde_dcha"),
    (238, "FLECHA VERDE IZDA.B", "flecha_verde_izda"),
]
ENTRIES += [(240 + i, f"BOLA{i}.BMP", f"bola{i}") for i in range(4)]
ENTRIES += [(244 + i, f"BOMBO{i:02d}.BMP", f"bombo{i:02d}") for i in range(12)]
ENTRIES += [(258 + i, f"MANO{i}.BMP", f"mano{i}") for i in range(8)]

PICTURE = (31, 76)  # the draw screen's picture window, screen-absolute
STRIP_AT = (31, 76)
FONDO_AT = (103, 76)
BOMBO_AT = (136, 76)


def main() -> None:
    ents = list(files_of((GAME / "IMG.PKF").read_bytes()))
    pal = pkf_image.riff_palette("MANAGER.PAL")
    OUT.mkdir(parents=True, exist_ok=True)
    idxs: dict[str, np.ndarray] = {}
    for index, want, stem in ENTRIES:
        name = ents[index][0]
        if name != want:
            raise SystemExit(f"IMG.PKF entry {index} is {name!r}, expected {want!r}")
        idx = pkf_image.dib_indices(pkf_image.entry_bytes_at("IMG.PKF", index))
        idxs[stem] = idx
        pkf_image.rgba(idx, pal, transparent=True).save(OUT / f"{stem}.png")
        print(f"  {stem:22} {idx.shape[1]}x{idx.shape[0]}  <- IMG.PKF[{index}] {name}")

    # The drum is blitted OPAQUE (its index-0 pixels land as black, measured on the real
    # frame), so ship an opaque copy the scene can draw without a per-pixel rule.
    for i in range(12):
        pkf_image.rgba(idxs[f"bombo{i:02d}"], pal, transparent=False).save(
            OUT / f"bombo{i:02d}_opaque.png"
        )

    _assert_parity(idxs, pal)
    print(f"\n{len(ENTRIES) + 12} files -> {OUT.relative_to(ROOT)}")


def _assert_parity(idxs: dict[str, np.ndarray], pal: list[int]) -> None:
    """Re-prove the composite against the real frame, so a bad export cannot ship."""
    if not FRAME.exists():
        print("  parity SKIPPED — no witness frame")
        return
    palA = np.asarray(pal, dtype=np.int16).reshape(256, 3)
    fr = np.asarray(Image.open(FRAME).convert("RGB")).astype(np.int16)
    can = np.zeros((144, 260, 3), np.int16)
    for stem, (x, y), opaque in (
        ("sorteo_cocacola", (0, 0), False),
        ("fondo", (FONDO_AT[0] - PICTURE[0], 0), False),
        ("bombo08", (BOMBO_AT[0] - PICTURE[0], 0), True),
    ):
        a = idxs[stem]
        h, w = a.shape
        if opaque:
            can[y : y + h, x : x + w] = palA[a]
        else:
            m = a != 0
            can[y : y + h, x : x + w][m] = palA[a][m]
    sub = fr[PICTURE[1] : PICTURE[1] + 144, PICTURE[0] : PICTURE[0] + 260]
    exact = float((can == sub).all(axis=2).mean())
    print(f"  picture vs {FRAME.name}: {100 * exact:.4f}% exact")
    if exact < 1.0:
        raise SystemExit("ASSERT FAILED: the SORTEO picture no longer matches the real frame")


if __name__ == "__main__":
    main()
