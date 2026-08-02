#!/usr/bin/env python3
"""Run the `0x20` EDGE pass on the GROUP DRAW's RIDIESC kits, against witnessed pixels only.

This is the oracle s88 named: the European Cup group-draw frame carries four kits whose
residual is 33 px of 221, and — uniquely among the kit-bearing screens — it carries a
**witnessed destination** for them. Five of the six group boxes are EMPTY and their row
bands are pixel-identical to each other (s88, 0 px), so the pixels UNDER group A's kit are
readable straight off group C's band. Everywhere else the backdrop beneath a kit is a wall
paste, which is why s85 could only score 39 of 449 px: there was nothing to blend toward.

    python3 tools/re/probe_groupdraw_kit_edge.py <aliasing.bin>

`aliasing.bin` is `DAT_006b5890` read out of the running original (`m5_rsp_capture.py`
writes it beside its trace). Nothing here is fitted: the pass has no free parameter once the
table is known — `mask = 0xff where the sprite is opaque`, then each byte becomes
`table[code] * 2 + 1` for the 13-bit neighbourhood code, then `FUN_005d5220` blends
`dst + ((src - dst) * (mask + 1)) >> 8` and re-quantises through `DAT_00675398`.

It prints, per kit cell: the pixels the PLAIN blit gets wrong, and the pixels the EDGE pass
gets wrong. If the second number is not smaller, the model is wrong and says so.
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
FRAME = (ROOT / "tools" / "re" / "refs" / "cupdraw-rounds-2026-08-01"
         / "manutd_s1_eurocup_groups_1_8_final.png")
LUT = ROOT / "app" / "data" / "shadow_lut.bin"
RIDI = ROOT / "app" / "art" / "kits" / "ridi"

# s88's measured geometry: boxes at x 326/483 and y 55/180/305, 149x121; four rows on a
# 25-px pitch; the RIDIESC kit is 17x20 at box-local (7, row+2).
BOX_A = (326, 55)
BOX_EMPTY = (326, 180)  # group C — the empty widget, i.e. what is under A's kits
KIT_W, KIT_H = 17, 20
KIT_LOCAL = (7, 2)   # box-local x, ROW-local y (build_groupdraw_chrome_from_frame.KIT_AT)
ROW_Y0 = 20          # box-local y of row 0
ROW_PITCH = 25
ROWS = 4


def edge_values(opaque: np.ndarray, table: bytes) -> np.ndarray:
    """`FUN_005d66f0` + `FUN_005d60a0`. Returns the classified mask, sprite-shaped."""
    h, w = opaque.shape
    stride = (w + 3) & ~3
    flat = np.zeros(h * stride, dtype=np.int32)
    buf = flat.reshape(h, stride)
    buf[:, :w] = np.where(opaque, 0xFF, 0)
    offs = [2 * stride, stride, stride + 1, 2, 1, 1 - stride, -2 * stride,
            -stride, -1 - stride, -2, -1, stride - 1]
    start = 2 * (stride + 1)
    count = (h - 4) * stride - 4
    out = flat.copy()
    for k in range(count):
        i = start + k
        if flat[i] == 0:
            continue
        ch = ((count - k) >> 8) & 0xFF
        code = 0
        for off in offs:
            j = i + off
            code = (code << 1) | (1 if 0 <= j < flat.size and flat[j] > ch else 0)
        code = (code << 1) | 1
        out[i] = (table[code] * 2 + 1) & 0xFF
    return out.reshape(h, stride)[:, :w]


def _lut():
    b = LUT.read_bytes()
    pal = np.frombuffer(b[:768], dtype=np.uint8).reshape(256, 3).astype(int)
    t0 = np.frombuffer(b[768:768 + 65536], dtype=np.uint8).astype(int)
    t1 = np.frombuffer(b[768 + 65536:768 + 131072], dtype=np.uint8).astype(int)
    return pal, [t0, t1]


def blend(dst: int, src: int, wt: int) -> int:
    t = ((src - dst) * wt) & 0xFFFF
    b = (t >> 8) & 0xFF
    return (dst + (b - 256 if b >= 128 else b)) & 0xFF


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    table = Path(sys.argv[1]).read_bytes()
    if len(table) != 0x2000:
        print(f"table is {len(table)} bytes, want 8192")
        return 2
    if not FRAME.exists():
        print(f"[MISS] {FRAME}")
        return 2
    frame = np.asarray(Image.open(FRAME).convert("RGB")).astype(int)
    pal, tab = _lut()

    def quant(rgb, parity: int) -> int:
        r, g, b = (int(max(0, min(255, round(v)))) for v in rgb)
        return tab[parity][((r >> 3) << 11) | ((g >> 2) << 5) | (b >> 3)]

    sprites = []
    for f in sorted(RIDI.glob("*.png")):
        a = np.asarray(Image.open(f).convert("RGBA")).astype(int)
        if a.shape[0] < KIT_H or a.shape[1] < KIT_W:
            continue
        sprites.append((f.stem, a[:KIT_H, :KIT_W]))
    if not sprites:
        print(f"[MISS] no RIDIESC sprites under {RIDI}")
        return 2

    tot_plain = tot_edge = tot_px = 0
    for row in range(ROWS):
        ax = BOX_A[0] + KIT_LOCAL[0]
        ay = BOX_A[1] + ROW_Y0 + row * ROW_PITCH + KIT_LOCAL[1]
        ex = BOX_EMPTY[0] + KIT_LOCAL[0]
        ey = BOX_EMPTY[1] + ROW_Y0 + row * ROW_PITCH + KIT_LOCAL[1]
        want = frame[ay:ay + KIT_H, ax:ax + KIT_W]
        dest = frame[ey:ey + KIT_H, ex:ex + KIT_W]

        # Which club's kit is in this cell — matched on the frame, not assumed. Score
        # every sprite by plain-blit mismatches and take the best; a wrong sprite cannot
        # win, because the interior is where a kit differs most from another kit.
        best = None
        for name, spr in sprites:
            op = spr[..., 3] > 0
            plain = np.where(op[..., None], spr[..., :3], dest)
            miss = int(((np.abs(plain - want).max(axis=2) > 0)).sum())
            if best is None or miss < best[0]:
                best = (miss, name, spr, op)
        plain_miss, name, spr, op = best

        vals = edge_values(op, table)
        pred = dest.copy()
        for y in range(KIT_H):
            for x in range(KIT_W):
                if not op[y, x]:
                    continue
                wt = int(vals[y, x]) + 1
                got = [blend(int(dest[y, x, c]), int(spr[y, x, c]), wt) for c in range(3)]
                par = (ax + x + ay + y) & 1
                pred[y, x] = pal[quant(got, par)]
        edge_miss = int((np.abs(pred - want).max(axis=2) > 0).sum())
        n_op = int(op.sum())
        tot_plain += plain_miss
        tot_edge += edge_miss
        tot_px += n_op
        print(f"row {row}: kit {name:>6}  opaque {n_op:3d} px   "
              f"plain blit wrong {plain_miss:3d}   edge pass wrong {edge_miss:3d}")

    print(f"\nTOTAL over {ROWS} kits, {tot_px} opaque px")
    print(f"  plain blit wrong : {tot_plain}")
    print(f"  edge pass wrong  : {tot_edge}")
    print("  VERDICT          : "
          + ("the edge pass IMPROVES the render" if tot_edge < tot_plain
             else "the edge pass does NOT improve the render — model rejected"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
