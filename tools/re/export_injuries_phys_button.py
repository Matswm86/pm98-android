#!/usr/bin/env python3
"""Export the INJURIES screen's PHYS. treatment button from RECURSOS.PKF.

`MANAGER.EXE` loads `recursos\\iconos\\lesionados\\boton{off,on}.bmp` (VA 0x65d71c /
0x65d6f4) for the PHYS. column of an injured row — the "+ sign" of the 2026-07-24
owner report. OFF is a grey cross on a dark bevel, ON the same button with a RED
cross; the row renderer `FUN_00543307` picks between them on `player[+0x6b]`.

Both are 21x18 BITMAPCOREHEADER DIBs (the OS/2 12-byte header flavour — see
`pkf_image.dib_indices`, which learned that variant for this export) under the shared
VGA palette. Placement is asserted, not guessed: BOTONOFF matches the real frame
`wine-captures-2026-07-24-cadence-season-store/07_injuries_row_insured_giggs.png` at
**(28, 261)** with SAD 0 — i.e. x 28, y = row_top - 1 for the MID row at 262.

The same run also pins two header sprites at SAD 0 on that frame, which is how the
blue "H" badge was identified: `HOSPITAL.BMP` 14x12 at (390, 88) and `SEMANAS.BMP`
12x11 at (364, 78).
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from pkf_image import dib_indices, entries, entry_bytes_at, rgba, vga_palette  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "app/art/screens/injuries"
FRAME = (
    ROOT
    / "screenshots/wine-captures-2026-07-24-cadence-season-store"
    / "07_injuries_row_insured_giggs.png"
)
HALF_FRAME = ROOT / "screenshots/wine-captures-2026-07-24-role-training-staff" / "39_injuries.png"
HALF_AT = (220 + 14 * 4, 449)  # the 5th cell of E. Wragg's 4.5-star strip
# The LESIONADOS folder's own entries (names repeat across folders in RECURSOS.PKF,
# so pick by file offset band, not by name).
BAND = (0x455000, 0x458000)
WANT = {
    "BOTONOFF.BMP": ("phys_off.png", (28, 261)),
    "BOTONON.BMP": ("phys_on.png", None),  # no witnessed frame has a treated row
    "HOSPITAL.BMP": ("hdr_hospital.png", (390, 88)),
    "SEMANAS.BMP": ("hdr_semanas.png", (364, 78)),
}


def main() -> int:
    frame = np.asarray(Image.open(FRAME).convert("RGB")).astype(int)
    pal = vga_palette()
    OUT.mkdir(parents=True, exist_ok=True)
    rc = 0
    for i, (name, off, _size) in enumerate(entries("RECURSOS.PKF")):
        if name not in WANT or not (BAND[0] <= off <= BAND[1]):
            continue
        out_name, at = WANT[name]
        idx = dib_indices(entry_bytes_at("RECURSOS.PKF", i))
        img = rgba(idx, pal, transparent=False)
        img.save(OUT / out_name)
        note = ""
        if at is not None:
            a = np.asarray(img.convert("RGB")).astype(int)
            h, w, _ = a.shape
            sad = int(np.abs(frame[at[1] : at[1] + h, at[0] : at[0] + w] - a).sum())
            note = f", frame SAD at {at} = {sad}"
            if sad:
                rc = 1
        print(f"  wrote {out_name} ({img.width}x{img.height}){note}")

    # --- the PHYSIOTHERAPIST band's HALF star ---------------------------------
    # The band shows the physio's rating in half-star steps (his quality byte / 2), so a
    # 4.5-star man draws four full stars and a half. `phys_star.png` (the full glyph,
    # 14x14, SAD 0 at x220 y449 on the band, pitch 14) was already cut; the half comes
    # from the fifth cell of the SAME witnessed strip — E. Wragg at 4.5 stars in
    # `wine-captures-2026-07-24-role-training-staff/39_injuries.png`.
    band = np.asarray(Image.open(HALF_FRAME).convert("RGB"))
    half = band[HALF_AT[1] : HALF_AT[1] + 14, HALF_AT[0] : HALF_AT[0] + 14]
    Image.fromarray(half, "RGB").save(OUT / "phys_star_half.png")
    print(f"  wrote phys_star_half.png (14x14) from {HALF_FRAME.name} at {HALF_AT}")

    print("OK" if rc == 0 else "FAIL: a sprite did not land on its witnessed position")
    return rc


if __name__ == "__main__":
    sys.exit(main())
