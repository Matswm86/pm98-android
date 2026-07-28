#!/usr/bin/env python3
"""Bake the shadowed-blit colour tables MANAGER.EXE builds at startup.

    python3 tools/re/build_shadow_lut.py

Output: `app/data/shadow_lut.bin` (131,840 bytes)

    [0    .. 767]      the realised palette, 256 x RGB  (MANAGER.PAL + the 20
                       Windows statics -- the same table export_flags.flag_palette()
                       proved on the MINIBAND flags)
    [768  .. 66303]    table 0, RGB565 -> palette index, for screen parity 0
    [66304 .. 131839]  table 1, the dither partner, for screen parity 1

## What these are

`FUN_005d5220` (the composite half of the shadowed blit, reached through
`FUN_004b7f60` -> `FUN_005cbea0`) blends source over destination in 24-bit and then
re-quantises to a palette index through a byte table at `DAT_00675398`, indexed by

    RGB565 | (parity << 16)

where `parity` is the ordered-dither bit the routine carries in bit 16 of its index
register: seeded `(x0 + y0) & 1`, toggled once per pixel and once more per row, so it
is a checkerboard on ABSOLUTE screen coordinates. That is the SAME dither the
knockout kit-list bake already found empirically ("dithered on absolute screen
parity", `knockout_views_re.md`) -- this is its cause.

The two tables are not in the EXE's image (they are built at startup, and `.text`
holds no writer we could read the constants out of), so they are RECONSTRUCTED here
from the palette and VALIDATED against the frames:

    table0[c] = nearest palette entry to the 565 CELL CENTRE
                (r*8+4, g*4+2, b*8+4), ties -> highest index
    table1[c] = nearest palette entry to 2*centre - palette[table0[c]]
                -- the partner that makes the pair's MEAN land on the centre

Evidence: every one of the **751** shadow-band pixels of the two MAN-TO-MAN marking
markers in `screenshots/parity-run-2026-07-16/orig/66_mantoman_match.png`
(Bolton W. vs Aston Villa) is reproduced exactly by this pair -- 751/751, and the
same reconstruction with the ties broken low scores 750/751, which is what pins the
tie-break direction. See `docs/re/shadow_blit_re.md`.
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools" / "re"))
from export_flags import flag_palette  # noqa: E402

OUT = ROOT / "app" / "data" / "shadow_lut.bin"
CENTRE = np.array([4, 2, 4], dtype=np.int64)  # half a 565 cell in R,G,B


def nearest(pal: np.ndarray, c: np.ndarray) -> np.ndarray:
    """Nearest palette index per row of `c`, ties -> HIGHEST index."""
    d = ((c[:, None, :] - pal[None, :, :]) ** 2).sum(-1)  # n x 256
    best = d.min(1, keepdims=True)
    # argmax on the reversed hit mask picks the LAST True == the highest tied index
    return (len(pal) - 1) - (d == best)[:, ::-1].argmax(1)


def main() -> None:
    pal = np.array(flag_palette(), dtype=np.int64)  # 256 x 3
    k = np.arange(1 << 16)
    cells = np.stack([(k >> 11 & 31) << 3, (k >> 5 & 63) << 2, (k & 31) << 3], 1) + CENTRE

    t0 = np.empty(1 << 16, np.uint8)
    t1 = np.empty(1 << 16, np.uint8)
    step = 4096
    for i in range(0, 1 << 16, step):
        c = cells[i : i + step]
        a = nearest(pal, c)
        t0[i : i + step] = a
        t1[i : i + step] = nearest(pal, np.clip(2 * c - pal[a], 0, 255))

    OUT.parent.mkdir(parents=True, exist_ok=True)
    with OUT.open("wb") as f:
        f.write(pal.astype(np.uint8).tobytes())
        f.write(t0.tobytes())
        f.write(t1.tobytes())
    print(f"wrote {OUT} ({OUT.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
