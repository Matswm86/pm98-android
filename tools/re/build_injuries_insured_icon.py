#!/usr/bin/env python3
"""Cut the INSURED-row document icon out of the real game frame.

`FUN_00543960`'s insured branch blits a small document sprite before it prints the
policy group and the payout percentage:

    00543b09  mov  dword ptr [esp+0x28], 0x1cb    ; x = 459 (row-relative)
    00543b11  mov  dword ptr [esp+0x2c], 5        ; y = 5
    00543b19  call 0x4b7f40                       ; ... -> 0x4b7f60, the blit

Row-relative x is offset by the row widget's origin at screen x=28, so the sprite
lands at screen x=487, row_top+5 — which is exactly where it sits in the only frame
that witnesses it: Giggs on Group 1 with a 7-week dislocated wrist,

    screenshots/wine-captures-2026-07-24-cadence-season-store/07_injuries_row_insured_giggs.png

whose row borders are y261/y278, so the sprite occupies x487..494 x y266..275.
Its four colours are the row palette's own ((100,100,100) rule, (255,255,255) paper,
(192,192,192) shade) over the (180,200,220) cell fill, which becomes transparent.

    python3 tools/re/build_injuries_insured_icon.py
    -> app/art/screens/injuries/insured_doc.png   (8x10 RGBA)
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SRC = (
    ROOT
    / "screenshots"
    / "wine-captures-2026-07-24-cadence-season-store"
    / "07_injuries_row_insured_giggs.png"
)
OUT = ROOT / "app" / "art" / "screens" / "injuries" / "insured_doc.png"

# The witnessed sprite box, and the cell fill it sits on.
BOX = (487, 266, 495, 276)  # left, top, right, bottom (exclusive)
CELL_FILL = (180, 200, 220)


def main() -> None:
    if not SRC.exists():
        raise SystemExit(f"missing witness frame: {SRC}")
    frame = Image.open(SRC).convert("RGB")
    crop = frame.crop(BOX)
    w, h = crop.size
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    kept = 0
    for y in range(h):
        for x in range(w):
            px = crop.getpixel((x, y))
            if px == CELL_FILL:
                continue  # cell background -> transparent
            out.putpixel((x, y), (*px, 255))
            kept += 1
    OUT.parent.mkdir(parents=True, exist_ok=True)
    out.save(OUT)
    print(f"wrote {OUT.relative_to(ROOT)}  {w}x{h}, {kept} opaque px")


if __name__ == "__main__":
    main()
