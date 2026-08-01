#!/usr/bin/env python3
"""The 1-px KIT RIM, attacked from the other end: stop guessing the PASS and recover the
COLOUR the original wrote.

Run it against a rendered set of EURO GROUP parity shots:

    DISPLAY=:8 PM98_SHOT_DIR=<dir> ~/godot462 --rendering-driver opengl3 --path app \\
        --script res://tests/shot_euroleague_parity.gd
    python3 tools/re/probe_kit_rim_invert.py <dir>

`probe_kit_rim_models.py` scores candidate passes. This one does two things that do not
depend on having the right pass at all, and both are new on 2026-08-01 (s85).

## 1. LUT INVERSION — the original's own 24-bit colour, recovered

s84 established that the rim colours are each other's dither PARTNERS in `DAT_00675398`.
That is not just a clue about the mechanism, it is an INVERSE: the LUT is indexed by
`RGB565 | (parity << 16)`, so a run of pixels that shows palette entry A at parity 0 and
palette entry B at parity 1 was written as ONE 24-bit colour, and the set of colours that
could have produced that pair is `cells(table0, A) & cells(table1, B)`.

The witness is group A's cell row y=2, x=9..12: the port paints a flat `(44,44,44)` and the
frame alternates `(70,40,80)` / `(46,69,82)` with x. Alternating output from a constant
input at alternating parity is exactly what the dithered LUT does. Inverted, the
intersection is **2 cells** — the original wrote **(56, 52, 64..72)** there.

That is the shape of answer any future model has to hit, and it is a measurement of the
ORIGINAL, not a score of one of our guesses.

## 2. THE MINIESC DOWNSCALE — KILLED

`MINIESC.PKF` entries are 3100 bytes and `NANOESC.PKF`'s are 796; both carry the same
28-byte header, so the payloads are 3072 = **48x64** and 768 = **24x32**. That makes MINIESC
the 48x64 kit bank the MAN-TO-MAN blit is already documented against, and a 2:1 box
downscale of it lands exactly on the NANOESC cell — which would explain a rim that hugs the
silhouette one pixel inside it, re-quantised through the parity LUT, without any pass at all.

Scored over all 476 MINIESC entries against group A's frame cell, best match:
**521 differing px of 768**, against the port's plain NANOESC blit at **66**. The screen does
not draw a downscaled MINIESC. Killed, and recorded so it is not re-tried.

## What is still true, and what is still open

The rim is ON the sprite (415 of 449 px inside the exported sprite's own opaque mask) and it
goes through the shadow blit's quantiser. Four models are now dead: toward-chrome,
toward-black, toward-white (`probe_kit_rim_models.py`) and the MINIESC downscale (here).
The pass itself stays UNLOCATED, and the position-constant bakes stay while the
club-dependent remainder stays a declared bucket.

One caveat worth carrying, because it makes one of those scores weaker than it looks: the
`toward-chrome` model was fed `app/art/screens/euroleague/chrome.png`, whose pixels UNDER the
kit's own silhouette are a wall paste (s83's "406 never bare"), i.e. a guess exactly where
the rim lives. Re-scored here against the WITNESSED destination — the two-witness backdrop
the six frames' six different leaders give — only 39 of the 449 residual px have a witnessed
destination at all, and 35 of those fit an edge alpha, but the fitted weights are scattered
across the whole 0..256 range (209, 212, 66, 47, 136, 82, ...) rather than clustered. That is
what a free parameter absorbing noise looks like, so it is reported, not claimed.
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools" / "re"))
from pkf_unpack import files_of  # noqa: E402

REFS = ROOT / "tools" / "re" / "refs" / "euro-competitions-2026-07-25"
DB = ROOT / "extracted" / "Premier Manager 98" / "DBDAT"
LUT = ROOT / "app" / "data" / "shadow_lut.bin"
FRAMES = {
    "A": "10_euroleague_group_A.png", "B": "11_euroleague_group_B.png",
    "C": "12_euroleague_group_C.png", "D": "13_euroleague_group_D.png",
    "E": "14_euroleague_group_E.png", "F": "15_euroleague_group_F.png",
}
LEADER = (75, 178, 24, 32)          # the group leader's kit cell, screen coords


def _lut():
    b = LUT.read_bytes()
    pal = np.frombuffer(b[:768], dtype=np.uint8).reshape(256, 3).astype(int)
    t0 = np.frombuffer(b[768:768 + 65536], dtype=np.uint8).astype(int)
    t1 = np.frombuffer(b[768 + 65536:768 + 131072], dtype=np.uint8).astype(int)
    return pal, [t0, t1]


def _cell_rgb(c: int) -> tuple[int, int, int]:
    """The RGB565 bucket's own 24-bit representative (low bits zero, as the index drops them)."""
    return (((c >> 11) & 0x1f) << 3, ((c >> 5) & 0x3f) << 2, (c & 0x1f) << 3)


def invert(pal, tab, rgb0, rgb1) -> list[tuple[int, int, int]]:
    """Which 24-bit colours quantise to `rgb0` at parity 0 AND `rgb1` at parity 1?"""
    def idx(rgb):
        return [i for i in range(256) if tuple(pal[i]) == tuple(rgb)]

    def cells(t, ids):
        out = set()
        for i in ids:
            out |= set(np.nonzero(t == i)[0].tolist())
        return out

    a = cells(tab[0], idx(rgb0))
    b = cells(tab[1], idx(rgb1))
    return [_cell_rgb(c) for c in sorted(a & b)]


def downscale_kill(pal, tab, frame_cell, port_cell) -> None:
    kx, ky, kw, kh = LEADER
    buf = (DB / "MINIESC.PKF").read_bytes()
    best = None
    for name, off, size in files_of(buf):
        raw = buf[off:off + size]
        if len(raw) < 3072:
            continue
        # 48x64 8-bit indices, BMP bottom-up
        idx = np.frombuffer(raw[-3072:], dtype=np.uint8).reshape(64, 48)[::-1]
        small = pal[idx].reshape(kh, 2, kw, 2, 3).mean(axis=(1, 3))
        q = np.zeros((kh, kw, 3), int)
        for y in range(kh):
            for x in range(kw):
                r, g, b = (int(max(0, min(255, round(v)))) for v in small[y, x])
                par = (kx + x + ky + y) & 1
                q[y, x] = pal[tab[par][((r >> 3) << 11) | ((g >> 2) << 5) | (b >> 3)]]
        d = int((np.abs(q - frame_cell).max(2) > 0).sum())
        if best is None or d < best[0]:
            best = (d, name)
    port = int((np.abs(port_cell - frame_cell).max(2) > 0).sum())
    print(f"\n== MINIESC 2:1 downscale (KILL TEST) ==")
    print(f"  best of 476 entries: {best[1]}  {best[0]} differing px of {kw * kh}")
    print(f"  the port's plain NANOESC blit: {port} px")
    print("  -> KILLED" if best[0] > port else "  -> SURVIVES (re-open the model)")


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    shots = Path(sys.argv[1])
    pal, tab = _lut()
    kx, ky, kw, kh = LEADER

    sp = shots / "euro_group_A.png"
    fp = REFS / FRAMES["A"]
    if not sp.exists() or not fp.exists():
        print(f"[MISS] {sp} / {fp}")
        return 2
    port = np.asarray(Image.open(sp).convert("RGB")).astype(int)[ky:ky + kh, kx:kx + kw]
    frame = np.asarray(Image.open(fp).convert("RGB")).astype(int)[ky:ky + kh, kx:kx + kw]

    print("== LUT inversion: what the ORIGINAL wrote ==")
    for rgb0, rgb1, where in (((70, 40, 80), (46, 69, 82), "group A cell y=2, x=9..12"),
                              ((59, 85, 130), (42, 63, 170), "the two rim colours of s84")):
        cand = invert(pal, tab, rgb0, rgb1)
        rng = ""
        if cand:
            a = np.array(cand)
            rng = (f"  r{a[:, 0].min()}..{a[:, 0].max()}"
                   f" g{a[:, 1].min()}..{a[:, 1].max()}"
                   f" b{a[:, 2].min()}..{a[:, 2].max()}")
        print(f"  par0={rgb0} par1={rgb1}  ({where})")
        print(f"    {len(cand)} candidate 24-bit colours{rng}")
        if cand and len(cand) <= 6:
            print(f"    {cand}")

    downscale_kill(pal, tab, frame, port)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
