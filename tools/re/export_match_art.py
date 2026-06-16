#!/usr/bin/env python3
"""Bake the PM98 DATSIM match sprites into the Godot app art tree.

Reads the originals out of DATSIM.PKF (extracted on the fly), decodes the cracked
PGF sprite format (see pgf_decode.py / docs/re/match_view_re.md), recolours the
player kit, and writes ready-to-use RGBA PNG atlases under app/art/match/:

  player_home.png / player_away.png  — [3 anim rows x 8 direction cols] run sheet,
        kit recoloured (home red / away blue) by luma-preserving hue shift of the
        green placeholder kit ramp (JUG.PGF base indices 16..42).
  ball.png    — a single clean on-ground football, idx0/bg keyed out.
  arrow.png   — the 8-angle COFLECHA selection arrow (active-player marker).

The pitch itself is drawn vectorially in MatchScreen.gd (clean broadcast pitch);
the exact DATSIM 3/4 tile-scroll camera is documented as the next refinement in
docs/re/match_view_re.md (same honesty as the STADIUM pre-render approach).
"""
from __future__ import annotations

import struct
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
PKF = ROOT / "tools" / "re" / "pkf_unpack.py"
OUT = ROOT / "app" / "art" / "match"
# extracted DATSIM dir (run pkf_unpack --extract first); default temp location
DATSIM = Path("/tmp/datsim_out/DATSIM.PKF")

CELL_W, CELL_H = 26, 52          # player cell (bottom-centre anchored)
DIRS = 8                          # frames 0..7 == 8 compass facings (W-pattern proof)
ANIM_ROWS = 3                     # groups 0,1,2 -> a 3-step run cycle


def load_pal(name="PALETA.ACT"):
    raw = (DATSIM / name).read_bytes()
    return [(raw[i], raw[i + 1], raw[i + 2]) for i in range(0, 768, 3)]


def pgf_frames(name):
    b = (DATSIM / name).read_bytes()
    assert b[:4] == b"LFGP"
    cnt = struct.unpack("<I", b[4:8])[0]
    off = 8
    out = []
    for _ in range(cnt):
        h = struct.unpack("<6i", b[off + 4 : off + 28])
        W, H = h[4], h[1]
        out.append((W, H, h[2], b[off + 28 : off + 28 + W * H]))
        off += 28 + W * H
    return out


# The JUG base kit is the green shading ramp (PALETA indices 16..42) plus a set of
# saturated VGA placeholder indices the original remaps via the team kit-LUT. We fold
# both into the kit so the shirt/shorts recolour solidly instead of speckling.
KIT_IDX = set(range(16, 43)) | {1, 2, 4, 5, 6, 9}


def _kit_luma(rgb):
    """Kit-ramp pixel -> a luma the match view tints per club (modulate x club colour)."""
    r, g, b = rgb
    luma = min(255, int(0.30 * r + 0.59 * g + 0.11 * b) + 60)   # lift so dark kit shades still read
    return (luma, luma, luma)


def player_layers(pal):
    """Split JUG into a true-colour BASE (skin/boots/detail) + a kit-LUMA layer, so the
    match view can tint the kit to each club's real colour at runtime (no shader)."""
    base = Image.new("RGBA", (CELL_W * DIRS, CELL_H * ANIM_ROWS), (0, 0, 0, 0))
    kit = Image.new("RGBA", (CELL_W * DIRS, CELL_H * ANIM_ROWS), (0, 0, 0, 0))
    bp, kp = base.load(), kit.load()
    fr = pgf_frames("JUG.PGF")
    for row in range(ANIM_ROWS):
        for d in range(DIRS):
            W, H, ax, px = fr[row * 8 + d]
            dst_x = d * CELL_W + (CELL_W - W) // 2
            dst_y = row * CELL_H + (CELL_H - H)          # bottom-align (feet on cell floor)
            for y in range(H):
                for x in range(W):
                    v = px[y * W + x]
                    if not v:
                        continue
                    if v in KIT_IDX:
                        kp[dst_x + x, dst_y + y] = (*_kit_luma(pal[v]), 255)
                    else:
                        bp[dst_x + x, dst_y + y] = (*pal[v], 255)
    pb, pk = OUT / "player_base.png", OUT / "player_kit.png"
    base.save(pb)
    kit.save(pk)
    return pb, pk


def ball_png(pal):
    b = (DATSIM / "BALON.RAW").read_bytes()
    bg = b[0]                                   # bg/transparent index (41 = dark green)
    # a clean mid-size on-ground ball lives around actual (0,128); crop 26x26
    cx, cy, s = 2, 130, 26
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    ip = img.load()
    for y in range(s):
        for x in range(s):
            v = b[(cy + y) * 256 + (cx + x)]
            if v != bg:
                ip[x, y] = (*pal[v], 255)
    p = OUT / "ball.png"
    img.save(p)
    return p


def arrow_png(pal):
    fr = pgf_frames("COFLECHA.PGF")
    cw = max(W for W, H, ax, px in fr)
    ch = max(H for W, H, ax, px in fr)
    sheet = Image.new("RGBA", (cw * len(fr), ch), (0, 0, 0, 0))
    for k, (W, H, ax, px) in enumerate(fr):
        cell = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        cp = cell.load()
        for y in range(H):
            for x in range(W):
                v = px[y * W + x]
                if v:
                    cp[x, y] = (*pal[v], 255)
        sheet.alpha_composite(cell, (k * cw + (cw - W) // 2, (ch - H) // 2))
    p = OUT / "arrow.png"
    sheet.save(p)
    return p


def main():
    if not DATSIM.exists():
        raise SystemExit(f"extract DATSIM first: python3 {PKF} --extract /tmp/datsim_out DATSIM.PKF")
    OUT.mkdir(parents=True, exist_ok=True)
    pal = load_pal()
    pb, pk = player_layers(pal)
    for f in (pb, pk, ball_png(pal), arrow_png(pal)):
        print("wrote", f.relative_to(ROOT), Image.open(f).size)


if __name__ == "__main__":
    main()
