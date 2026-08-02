#!/usr/bin/env python3
"""Score `FUN_005cbea0`'s `0x20` arm against the PORT'S OWN RENDER of the group draw.

    python3 tools/re/probe_groupdraw_edge_render.py <shot_dir> [aliasing.bin]

s89 scored the edge pass against a BEST-MATCH sprite picked by pixel distance, got
396 -> 349, and could not call it either way because "no sprite in `app/art/kits/ridi`
gets those cells under 74 px even WITH the model" — i.e. the probe's own sprite
identification was the suspect. This probe removes that degree of freedom entirely:

* the sprite is not matched, it is LOOKED UP. `Main.gd`'s CUPDRAW shot feeds group A
  as club ids 1076 / 1003 / 1223 / 1147 (Sporting Port., Real Madrid C.F., Anorthosis,
  W.Lodz — the four names printed on the frame), and `PMChrome.ridi_kit` loads
  `art/kits/ridi/<club_id>.png`. This probe reads the same four files.
* the baseline is not a re-blit, it is the port's own `cupdraw_groups.png`, the shot
  `diff_cupdraw_parity.py` already grades. So "does the pass help" is asked of the
  exact pixels the app puts on screen, and the answer transfers without a second model.

The pass, transcribed from `FUN_005cbea0` (docs/re/shadow_blit_re.md §"the 0x20 arm"):

    FUN_005d66f0(scratch, 0x100)          silhouette -> flat 0/255
    FUN_005d60a0(scratch, alpha)          EDGE: byte <- table[13-bit code] * 2 + 1
    if thr: FUN_005d6590(scratch, thr, cap)   the IIR spread, on the SAME scratch
    FUN_005d5220(dest, scratch, src)      composite + parity re-quantise

`thr` / `cap` are pushed as REGISTERS at this site (`0x5c0688`, the RIDIESC picture
widget's own blit — the flags word is `FUN_005c0d50`'s `param_4` at record `+0x90`), so
they cannot be read off the call the way the other 65 sites can. They are not fitted
either: the candidate set is the enumerated `0x20` triples from `probe_shadow_sites.py`
and the frame decides between them.
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
FRAME = (
    ROOT
    / "tools"
    / "re"
    / "refs"
    / "cupdraw-rounds-2026-08-01"
    / "manutd_s1_eurocup_groups_1_8_final.png"
)
TABLE = ROOT / "tools" / "re" / "refs" / "aliasing-2026-08-02" / "aliasing.bin"
LUT = ROOT / "app" / "data" / "shadow_lut.bin"
RIDI = ROOT / "app" / "art" / "kits" / "ridi"

# Main.gd's CUPDRAW shot, verbatim: group A's four clubs top to bottom, and the 17x20
# kit's screen origin per row (BOX_X[0] + 7, BOX_Y[0] + 20 + row*25 + 2).
CLUBS = [1076, 1003, 1223, 1147]
KIT_XY = [(333, 77), (333, 102), (333, 127), (333, 152)]
KIT_W, KIT_H = 17, 20
EMPTY_DY = 125  # group C sits one box row below group A (BOX_Y 180 - 55), and its row
# band is the empty widget verbatim — s88 measured the five empty boxes identical at 0 px.

# The thr/cap bytes the immediate-pushing sites attest, in the combinations worth asking
# about. `(0, 0)` is the edge with the spread switched off — the same question as "does the
# spread belong at this site at all". `(0x20, 0x80)` is the answer: **0 px on all four
# kits**, against 10 for its nearest neighbour on either axis and 250+ two steps away. The
# neighbours are kept in the list so the margin is visible in the output rather than
# asserted in a comment.
CANDIDATES = [
    (0x00, 0x00),
    (0x21, 0x5A),
    (0x21, 0x63),
    (0x30, 0xFF),
    (0x40, 0x80),
    (0x21, 0x80),
    (0x1F, 0x80),
    (0x20, 0x84),
    (0x20, 0x80),  # <- 0 px
]


def lut() -> tuple[np.ndarray, list[np.ndarray]]:
    b = LUT.read_bytes()
    pal = np.frombuffer(b[:768], dtype=np.uint8).reshape(256, 3).astype(int)
    t0 = np.frombuffer(b[768 : 768 + 65536], dtype=np.uint8).astype(int)
    t1 = np.frombuffer(b[768 + 65536 : 768 + 131072], dtype=np.uint8).astype(int)
    return pal, [t0, t1]


def silhouette(opaque: np.ndarray) -> tuple[np.ndarray, int]:
    """`FUN_005d66f0` with alpha 0x100: a flat 0/255 mask on the padded surface."""
    h, w = opaque.shape
    stride = (w + 3) & ~3
    buf = np.zeros(h * stride, dtype=np.int32)
    buf.reshape(h, stride)[:, :w] = np.where(opaque, 0xFF, 0)
    return buf, stride


def edge(buf: np.ndarray, stride: int, h: int, table: bytes) -> np.ndarray:
    """`FUN_005d60a0`: every NON-ZERO byte becomes `table[13-bit code] * 2 + 1`.

    The neighbour test is `cmp ch, byte [edi+off]` and `ch` is the loop counter's own
    high byte — kept as measured rather than tidied to a constant, per s89.
    """
    offs = [
        2 * stride,
        stride,
        stride + 1,
        2,
        1,
        1 - stride,
        -2 * stride,
        -stride,
        -1 - stride,
        -2,
        -1,
        stride - 1,
    ]
    start = 2 * (stride + 1)
    count = (h - 4) * stride - 4
    out = buf.copy()
    for k in range(count):
        i = start + k
        if buf[i] == 0:
            continue
        ch = ((count - k) >> 8) & 0xFF
        code = 0
        for off in offs:
            j = i + off
            code = (code << 1) | (1 if 0 <= j < buf.size and buf[j] > ch else 0)
        out[i] = (table[(code << 1) | 1] * 2 + 1) & 0xFF
    return out


def spread(buf: np.ndarray, stride: int, h: int, thr: int, cap: int) -> np.ndarray:
    """`FUN_005d6590`: the IIR decay down-and-right, in place, only where it wins."""
    out = buf.copy()
    i = stride + 1
    last = i + (h - 1) * stride - 1
    while i < last:
        s = int(out[i])
        if s < 0xF0:
            avg = (int(out[i - stride]) + 2 * int(out[i - stride - 1]) + int(out[i - 1])) >> 2
            if avg >= thr:
                d = avg - thr
                if d != 0 and s < d:
                    out[i] = cap if cap < d else d
        i += 1
    return out


def composite(
    dst: np.ndarray,
    src: np.ndarray,
    opaque: np.ndarray,
    mask: np.ndarray,
    stride: int,
    xy: tuple[int, int],
    pal,
    tab,
) -> np.ndarray:
    """`FUN_005d5220`: mask 0 keeps dst, 0xff copies src, between blends + re-quantises.

    Outside the silhouette the source byte is palette index 0, i.e. BLACK — the same
    assumption `PMShadow.overlay` is validated on at 751/751.
    """
    h, w = opaque.shape
    out = dst.copy()
    for y in range(h):
        for x in range(w):
            a = int(mask[y * stride + x])
            if a == 0:
                continue
            s = src[y, x] if opaque[y, x] else np.zeros(3, dtype=int)
            if a == 0xFF:
                out[y, x] = s
                continue
            wt = a + 1
            got = []
            for c in range(3):
                d = int(dst[y, x, c])
                t = ((int(s[c]) - d) * wt) & 0xFFFF
                b = (t >> 8) & 0xFF
                got.append((d + (b - 256 if b >= 128 else b)) & 0xFF)
            k = ((got[0] & 0xF8) << 8) | ((got[1] & 0xFC) << 3) | ((got[2] & 0xF8) >> 3)
            par = 1 if ((xy[0] + x + xy[1] + y + 1) & 1) else 0
            out[y, x] = pal[tab[par][k]]
    return out


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    shot = Path(sys.argv[1]) / "cupdraw_groups.png"
    table = Path(sys.argv[2] if len(sys.argv) > 2 else TABLE).read_bytes()
    if len(table) != 0x2000:
        print(f"table is {len(table)} bytes, want 8192")
        return 2
    for p in (shot, FRAME):
        if not p.exists():
            print(f"[MISS] {p}")
            return 2

    want = np.asarray(Image.open(FRAME).convert("RGB"))[:480, :640].astype(int)
    port = np.asarray(Image.open(shot).convert("RGB"))[:480, :640].astype(int)
    pal, tab = lut()

    cells = []
    for cid, (x, y) in zip(CLUBS, KIT_XY, strict=True):
        spr = np.asarray(Image.open(RIDI / f"{cid}.png").convert("RGBA")).astype(int)
        cells.append((cid, (x, y), spr[:KIT_H, :KIT_W]))

    base = 0
    for _cid, (x, y), _spr in cells:
        d = (port[y : y + KIT_H, x : x + KIT_W] != want[y : y + KIT_H, x : x + KIT_W]).any(axis=2)
        base += int(d.sum())
    # NOTE what this line means AFTER the pass shipped. It is the port's render AS IT
    # STANDS, so it reads 0 now that `CupDrawScreen._group_kit` applies the pass — it was
    # 345 when the screen blitted the sprite plainly (and 396 before the `ridi` bank was
    # re-baked against MANAGER.PAL). The rows below stay the useful part: they are the
    # OFFLINE model re-derived from the binary, so a 0 there is an independent check that
    # the shipped `PMShadow.edge_blit` still reproduces the real frame.
    print(f"port render, as it stands : {base} wrong px over {len(cells)} kit cells")
    print("  (345 before the pass shipped; 396 before the palette re-bake)\n")

    best = None
    for thr, cap in CANDIDATES:
        tot = 0
        per = []
        for cid, (x, y), spr in cells:
            op = spr[..., 3] > 0
            buf, stride = silhouette(op)
            buf = edge(buf, stride, KIT_H, table)
            if thr:
                buf = spread(buf, stride, KIT_H, thr, cap)
            # The DESTINATION — what the blit lands on — is the empty row widget, and
            # the port's own render carries it verbatim in group C, whose row band s88
            # measured pixel-identical to the other four empties at 0 px. Reading it
            # from the port (not the frame) keeps the whole comparison one-sided.
            dst = port[y + EMPTY_DY : y + EMPTY_DY + KIT_H, x : x + KIT_W].copy()
            got = composite(dst, spr[..., :3], op, buf, stride, (x, y), pal, tab)
            n = int((got != want[y : y + KIT_H, x : x + KIT_W]).any(axis=2).sum())
            per.append(f"{cid}:{n}")
            tot += n
        flag = "  <-- best" if best is None or tot < best[0] else ""
        if best is None or tot < best[0]:
            best = (tot, thr, cap)
        print(f"edge + spread(thr={thr:#04x}, cap={cap:#04x}) : {tot:4d}   " + " ".join(per) + flag)

    assert best is not None
    print(
        f"\nbest {best[0]} px at thr={best[1]:#04x} cap={best[2]:#04x}, against {base} with no pass"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
