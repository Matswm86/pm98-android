#!/usr/bin/env python3
"""Bake JUG.PGF into the app in the ENGINE'S OWN frame layout (resolves AUDIT A7).

This REPLACES `export_match_art.py`'s `player_base.png` / `player_kit.png` pair, which
baked a stylised `[3 phase x 8 dir]` grid — the TRANSPOSE of the real bank and only ~24 of
its 4211 frames. Nothing here is chosen by hand:

  * the three per-kind tables come out of MANAGER.EXE `.data`
    (`DAT_00664fb8` fpd, `DAT_006650e0` mode, `DAT_00665208` next-state,
     `DAT_00665330` sub-octant refine flag),
  * `base[]` is rebuilt by `FUN_005a2830`'s own algorithm and the reconstructed total is
    checked against JUG.PGF's real header frame count (4211) — a mismatch is a hard error,
  * every frame's pixels, size and anchor are the `.PGF`'s own
    (header `[h0, H, ax, ay, W, h5]`, see `docs/re/jug_render_spec.md` §1).

The base/kit SPLIT follows the art's own per-band histogram (see SHIRT_IDX / GREEN_IDX
below). **Recorded GAP, deliberately not claimed:** the original recolours through its own
per-club ramps `DatSim\\paletas\\P96A####.DAT` / `P96B####.DAT` (829 of each, 192 bytes =
64 RGB entries; plus one 256-byte `P96A0000.DAT` index remap). Which palette slots those 64
entries land in is NOT reversed, so they are not used and the kit is a two-colour stand-in.

Output (`app/art/match/`):
  jug_base.png    — all 4211 frames: PALETA colours, with the green placeholder ramps
                    (shorts/socks) rendered as a neutral ramp
  jug_kit.png     — the same 4211 rects, SHIRT pixels as a luma the view tints per club
  jug_bank.json   — {kinds:[{mode,fpd,base,next,flag}], frames:[{x,y,w,h,ax,ay}],
                     thresholds8, thresholds12, tilt_pos, tilt_neg, atlas, z_num/z_den/x_den}

Usage:  python3 tools/re/pkf_unpack.py --extract /tmp/datsim_out DATSIM.PKF
        python3 tools/re/export_jug_bank.py
"""

from __future__ import annotations

import json
import struct
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from pe import PE  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "app" / "art" / "match"
DATSIM = Path("/tmp/datsim_out/DATSIM.PKF")

# VAs verified from FUN_005a5460 / FUN_005a50c0 / FUN_005a2830 (dump_jug_kind_tables.py).
VA_MODE = 0x6650E0
VA_FPD = 0x664FB8
VA_NEXT = 0x665208
VA_FLAG = 0x665330
VA_THR8 = 0x6653E0
VA_THR12 = 0x665430
# The two per-octant tilt tables the sub-octant refine block indexes (FUN_005a5460:222-230).
VA_TILT_POS = 0x6653F0
VA_TILT_NEG = 0x665410
N_KINDS = 74
JUG_FRAMES = 4211

# Sprite world scale, read off the draw: a frame's z span is (ay-H .. ay) * 0x1b333 / 0x30
# and its x span (-ax .. W-ax) * scale, both /0x1a on the way into world coords.
Z_NUM, Z_DEN = 0x1B333, 0x30
X_DEN = 0x1A

# PALETA.ACT's two PLACEHOLDER families, which the original's per-team LUT is what recolours:
#   * SHIRT_IDX — the saturated VGA entries (128,0,0)/(0,128,0)/(0,0,128)/... They dominate the
#     TOP band of every frame (a per-band histogram over the first 400 frames puts 1,3,4,5,6,9
#     there at 2-3k px each), i.e. the shirt.
#   * GREEN_IDX — the three green ramps 10..36, which dominate the MID band (15..19) and the
#     LOW band (25..33), i.e. shorts and socks.
# The app tints the shirt to the club colour and renders the green ramps as a NEUTRAL ramp on
# the base layer, which is what the original's default kit shows in the capture.
# ⛔ RECORDED GAP: which palette slots the per-club `P96A####.DAT` / `P96B####.DAT` ramps
# actually write is NOT reversed, so this split is read off the art's own histogram, not off
# the loader. It is a two-colour approximation of a three-garment recolour.
SHIRT_IDX = {1, 2, 3, 4, 5, 6, 9}
GREEN_IDX = set(range(10, 37))


def _kit_luma(rgb):
    r, g, b = rgb
    luma = min(255, int(0.30 * r + 0.59 * g + 0.11 * b) + 60)
    return (luma, luma, luma)


def _neutral(rgb):
    """A green placeholder ramp entry -> the same step of a neutral white ramp."""
    r, g, b = rgb
    luma = int(0.30 * r + 0.59 * g + 0.11 * b)
    # the ramps span luma ~5..75; stretch to a readable 70..245 so the shading survives
    v = int(70 + (min(luma, 75) / 75.0) * 175)
    return (v, v, v)


def pgf_frames(path: Path):
    """Decode an `LFGP` bank: per frame `[h0, H, ax, ay, W, h5]` + W*H 8-bit pixels."""
    b = path.read_bytes()
    if b[:4] != b"LFGP":
        raise SystemExit(f"{path}: not an LFGP bank")
    cnt = struct.unpack("<I", b[4:8])[0]
    off, out = 8, []
    for _ in range(cnt):
        h0, hh, ax, ay, ww, h5 = struct.unpack("<6i", b[off + 4 : off + 28])
        out.append(
            {
                "w": ww,
                "h": hh,
                "ax": ax,
                "ay": ay,
                "h0": h0,
                "h5": h5,
                "px": b[off + 28 : off + 28 + ww * hh],
            }
        )
        off += 28 + ww * hh
    if off != len(b):
        raise SystemExit(f"{path}: {off} bytes consumed of {len(b)} — layout wrong")
    return out


def kind_tables():
    pe = PE()

    def i32s(va, n):
        return list(struct.unpack_from(f"<{n}i", pe.read_va(va, 4 * n), 0))

    def u16s(va, n):
        return list(struct.unpack_from(f"<{n}H", pe.read_va(va, 2 * n), 0))

    mode = i32s(VA_MODE, N_KINDS)
    fpd = i32s(VA_FPD, N_KINDS)
    nxt = i32s(VA_NEXT, N_KINDS)
    flag = list(pe.read_va(VA_FLAG, N_KINDS))
    # FUN_005a2830: base[k] = running; if mode[k] > 0: running += fpd[k] * mode[k]
    base, run = [], 0
    for k in range(N_KINDS):
        base.append(run)
        if mode[k] > 0:
            run += fpd[k] * mode[k]
    if run != JUG_FRAMES:
        raise SystemExit(f"base[] total {run} != JUG.PGF {JUG_FRAMES} — table VAs wrong")
    return {
        "kinds": [
            {"mode": mode[k], "fpd": fpd[k], "base": base[k], "next": nxt[k], "flag": flag[k]}
            for k in range(N_KINDS)
        ],
        "thresholds8": u16s(VA_THR8, 8),
        "thresholds12": u16s(VA_THR12, 12),
        "tilt_pos": i32s(VA_TILT_POS, 8),
        "tilt_neg": i32s(VA_TILT_NEG, 8),
    }


def pack(frames, pad=1):
    """Shelf-pack every frame into one atlas; returns (Image, [rects]) in bank order."""
    order = sorted(range(len(frames)), key=lambda i: -frames[i]["h"])
    width = 1024
    x = y = row_h = 0
    rects = [None] * len(frames)
    for i in order:
        w, h = frames[i]["w"], frames[i]["h"]
        if x + w + pad > width:
            x, y, row_h = 0, y + row_h + pad, 0
        rects[i] = (x, y, w, h)
        x += w + pad
        row_h = max(row_h, h)
    height = y + row_h + pad
    return width, height, rects


def main() -> int:
    if not DATSIM.exists():
        raise SystemExit(
            "extract DATSIM first: "
            "python3 tools/re/pkf_unpack.py --extract /tmp/datsim_out DATSIM.PKF"
        )
    OUT.mkdir(parents=True, exist_ok=True)
    tables = kind_tables()
    frames = pgf_frames(DATSIM / "JUG.PGF")
    if len(frames) != JUG_FRAMES:
        raise SystemExit(f"JUG.PGF has {len(frames)} frames, expected {JUG_FRAMES}")

    raw = (DATSIM / "PALETA.ACT").read_bytes()
    pal = [(raw[i], raw[i + 1], raw[i + 2]) for i in range(0, 768, 3)]

    w, h, rects = pack(frames)
    base_img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    kit_img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    bp, kp = base_img.load(), kit_img.load()
    for fr, (rx, ry, fw, fh) in zip(frames, rects):
        src = fr["px"]
        for yy in range(fh):
            row = yy * fw
            for xx in range(fw):
                v = src[row + xx]
                if not v:
                    continue
                if v in SHIRT_IDX:
                    kp[rx + xx, ry + yy] = (*_kit_luma(pal[v]), 255)
                elif v in GREEN_IDX:
                    bp[rx + xx, ry + yy] = (*_neutral(pal[v]), 255)
                else:
                    bp[rx + xx, ry + yy] = (*pal[v], 255)
    base_img.save(OUT / "jug_base.png")
    kit_img.save(OUT / "jug_kit.png")

    bank = dict(tables)
    bank["frames"] = [
        {"x": r[0], "y": r[1], "w": r[2], "h": r[3], "ax": f["ax"], "ay": f["ay"]}
        for f, r in zip(frames, rects)
    ]
    bank["atlas"] = [w, h]
    bank["z_num"], bank["z_den"], bank["x_den"] = Z_NUM, Z_DEN, X_DEN
    (OUT / "jug_bank.json").write_text(json.dumps(bank, separators=(",", ":")))

    ramps = sum(1 for _ in DATSIM.glob("P96[AB][0-9][0-9][0-9][0-9].DAT"))
    print(f"jug_base.png / jug_kit.png {w}x{h}  frames={len(frames)}  kinds={N_KINDS}")
    print(f"unused per-club ramps present in DATSIM (recorded gap): {ramps}")
    print("VALIDATION: base[] total == JUG.PGF frame count == 4211  PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
