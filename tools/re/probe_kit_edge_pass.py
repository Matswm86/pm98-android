#!/usr/bin/env python3
"""Score the `flags & 0x20` EDGE pass against the 1-px kit residual, with the REAL table.

Six sessions fitted models to these pixels and killed four of them. s88 identified the pass
(`FUN_005cbea0`'s `0x20` arm -> `FUN_005d60a0`) and named the one thing still missing: the
8,192-entry classifier table `DAT_006b5890`, which is `.bss` and therefore cannot be read
out of the image at all. s89 read it out of the RUNNING original over the winedbg RSP stub
(`m5_rsp_capture.py` writes `<out>.aliasing.bin`), so the pass can finally be RUN instead of
guessed at.

    python3 tools/re/probe_kit_edge_pass.py <shot_dir> <aliasing.bin>

`shot_dir` is a rendered set of EURO GROUP parity shots:

    DISPLAY=:1 PM98_SHOT_DIR=<dir> ~/godot4 --rendering-driver opengl3 --path app \\
        --script res://tests/shot_euroleague_parity.gd

## The pass, transcribed from `FUN_005d60a0` (0x5d60a0..0x5d61d6)

The mask is `0xff` wherever the sprite's palette index is non-zero (`FUN_005d66f0` at alpha
0x100), `stride = (w + 3) & ~3` bytes a row. Then, over `(H-4)*W - 4` bytes starting at
`2*(W+1)`, every NON-ZERO byte is replaced by `table[code] * 2 + 1`, where `code` is 13 bits
built MSB-first from these offsets and a hardwired 1 in bit 0:

    bit12 2W   bit11 W   bit10 W+1   bit9 2   bit8 1   bit7 1-W   bit6 -2W
    bit5  -W   bit4 -1-W bit3 -2     bit2 -1  bit1 W-1 bit0 1 (stc)

which is exactly the offset ORDER the generator at 0x5c98e9 stores, so the two agree bit for
bit. A zero byte is left alone: the pass writes only INSIDE the silhouette, which is what a
spread can never do and what makes it the only candidate that matches where the residual is
(415 of 449 px inside the sprite's own opaque mask, s84).

## What this probe reports

For every residual pixel it asks one question with NO free parameter: **does the edge pass
mark this pixel at all** — i.e. is its classified value below 0xff, so the composite blends
it toward the destination? A pass that does not even mark the right PIXELS cannot be the
explanation whatever its arithmetic. It then reports how many of the marked pixels the
pass's own weight reproduces exactly, through the same `DAT_00675398` dither the rest of the
blit uses.
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
REFS = ROOT / "tools" / "re" / "refs" / "euro-competitions-2026-07-25"
CHROME = ROOT / "app" / "art" / "screens" / "euroleague" / "chrome.png"
LUT = ROOT / "app" / "data" / "shadow_lut.bin"
FRAMES = {
    "A": "10_euroleague_group_A.png", "B": "11_euroleague_group_B.png",
    "C": "12_euroleague_group_C.png", "D": "13_euroleague_group_D.png",
    "E": "14_euroleague_group_E.png", "F": "15_euroleague_group_F.png",
}
LEADER = (75, 178, 24, 32)  # the group leader's NANOESC kit cell


def edge_mask(opaque: np.ndarray, table: bytes) -> np.ndarray:
    """`FUN_005d66f0` + `FUN_005d60a0`, byte for byte. Returns the mask surface
    (h, stride) with 0 outside the silhouette and the classified value inside."""
    h, w = opaque.shape
    stride = (w + 3) & ~3
    buf = np.zeros((h, stride), dtype=np.int32)
    buf[:, :w] = np.where(opaque, 0xFF, 0)
    flat = buf.reshape(-1)
    offs = [2 * stride, stride, stride + 1, 2, 1, 1 - stride, -2 * stride,
            -stride, -1 - stride, -2, -1, stride - 1]
    start = 2 * (stride + 1)
    count = (h - 4) * stride - 4
    out = flat.copy()
    for k in range(count):
        i = start + k
        if flat[i] == 0:
            continue
        # `cmp ch, byte[edi+off]` — ch is the loop counter's own high byte, which for a
        # 0/255 mask is only ever 0..2 and so is exactly "the neighbour is non-zero".
        ch = ((count - k) >> 8) & 0xFF
        code = 0
        for off in offs:
            j = i + off
            code = (code << 1) | (1 if 0 <= j < flat.size and flat[j] > ch else 0)
        code = (code << 1) | 1
        out[i] = (table[code] * 2 + 1) & 0xFF
    return out.reshape(h, stride)


def _lut() -> tuple[np.ndarray, list[np.ndarray]]:
    b = LUT.read_bytes()
    pal = np.frombuffer(b[:768], dtype=np.uint8).reshape(256, 3).astype(int)
    t0 = np.frombuffer(b[768:768 + 65536], dtype=np.uint8).astype(int)
    t1 = np.frombuffer(b[768 + 65536:768 + 131072], dtype=np.uint8).astype(int)
    return pal, [t0, t1]


def blend(dst: int, src: int, wt: int) -> int:
    """`FUN_005d5220`'s per-channel `dst + ((src - dst) * wt) >> 8`, in the original's
    own 16-bit-wrap arithmetic (the same one `PMShadow._blend` ships)."""
    t = ((src - dst) * wt) & 0xFFFF
    b = (t >> 8) & 0xFF
    return (dst + (b - 256 if b >= 128 else b)) & 0xFF


def main() -> int:
    if len(sys.argv) < 3:
        print(__doc__)
        return 2
    shots, table_path = Path(sys.argv[1]), Path(sys.argv[2])
    table = table_path.read_bytes()
    if len(table) != 0x2000:
        print(f"{table_path} is {len(table)} bytes, want 8192")
        return 2
    pal, tab = _lut()

    def quant(rgb, parity: int) -> int:
        r, g, b = (int(max(0, min(255, round(v)))) for v in rgb)
        return tab[parity][((r >> 3) << 11) | ((g >> 2) << 5) | (b >> 3)]

    chrome = np.asarray(Image.open(CHROME).convert("RGB")).astype(int)[:480, :640]
    kx, ky, kw, kh = LEADER
    kits = ROOT / "app" / "art" / "kits" / "nano"
    total = marked = exact = unmarked_flat = 0
    marked_total = 0

    for letter, name in FRAMES.items():
        sp, fp = shots / f"euro_group_{letter}.png", REFS / name
        if not sp.exists() or not fp.exists():
            print(f"[MISS] {sp} / {fp}")
            return 2
        shot = np.asarray(Image.open(sp).convert("RGB")).astype(int)[:480, :640]
        frame = np.asarray(Image.open(fp).convert("RGB")).astype(int)[:480, :640]
        diff = (np.abs(shot - frame).max(axis=2) > 0)[ky:ky + kh, kx:kx + kw]

        cell = shot[ky:ky + kh, kx:kx + kw]
        opaque = None
        for f in sorted(kits.glob("*.png")):
            a = np.asarray(Image.open(f).convert("RGBA")).astype(int)[:kh, :kw]
            op = a[..., 3] > 0
            if not ((np.abs(a[..., :3] - cell).max(2) > 0) & op).sum():
                opaque = op
                break
        if opaque is None:
            print(f"[{letter}] no NANOESC sprite matches the cell — skipped")
            continue

        m = edge_mask(opaque, table)[:, :kw]
        inside = opaque & (m > 0)
        part = inside & (m < 0xFF)
        marked_total += int(part.sum())
        for y, x in zip(*np.nonzero(diff)):
            total += 1
            if not part[y, x]:
                unmarked_flat += 1
                continue
            marked += 1
            wt = int(m[y, x]) + 1
            src = shot[ky + y, kx + x]
            dst = chrome[ky + y, kx + x]
            got = [blend(int(dst[c]), int(src[c]), wt) for c in range(3)]
            par = (kx + x + ky + y) & 1
            if tuple(pal[quant(got, par)]) == tuple(frame[ky + y, kx + x]):
                exact += 1
        print(f"[{letter}] residual {int(diff.sum()):3d} px, "
              f"edge-marked {int(part.sum()):3d} px in the cell")

    print(f"\nresidual pixels        : {total}")
    print(f"  the edge pass MARKS  : {marked}  ({100 * marked / max(1, total):.1f}%)")
    print(f"  it leaves untouched  : {unmarked_flat}")
    print(f"  reproduced EXACTLY   : {exact}")
    print(f"edge-marked pixels total (all six cells): {marked_total}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
