#!/usr/bin/env python3
"""PGF sprite decoder — Premier Manager 98 / PC Futbol 5 DATSIM match sprites.

Format (CRACKED, this session — walks all 4211 JUG.PGF frames landing EXACTLY on
EOF, which is the proof):

    file header:  char[4] "LFGP"  +  u32 frameCount
    per frame:    char[4] "-FGP"  +  i32[6] header  +  W*H raw indexed bytes

    the 6 i32 header fields are (verified against COFLECHA/COROJA/JUG):
      [0] hdr0     a width-ish logical value (<= W); role still loose
      [1] H        bitmap height           (datalen == W*H exactly -> RAW, no RLE)
      [2] anchorX  signed hotspot X offset (place sprite at cursor.x + anchorX)
      [3] hdr3     anchorY-ish / reference height
      [4] W        bitmap width
      [5] hdr5     per-frame tag (0..71, mostly 0); not load-bearing for the blit

    pixels: 1 byte per pixel, palette index into the 256-colour match palette.
            index 0 == transparent (the ubiquitous 0x00 padding around each shape).

Palette: PALETA.ACT (Adobe colour table, 256*3 raw RGB) is the base match palette.
Per-team kit recolour uses the PAL*.DAT range-swap tables (PALPOR* keepers etc.);
not applied here — base palette is enough to verify geometry + read the art.

Usage:
  pgf_decode.py info  <file.PGF>                 # header + per-frame dims
  pgf_decode.py sheet <file.PGF> out.png [--pal PALETA.ACT] [--cols N] [--scale S]
  pgf_decode.py frames <file.PGF> outdir [--pal ...] [--max N]   # one PNG per frame
"""
from __future__ import annotations

import struct
import sys
from pathlib import Path

from PIL import Image

FILE_MAGIC = b"LFGP"
FRAME_MAGIC = b"-FGP"
HDR = struct.Struct("<6i")


def parse(buf: bytes):
    """Yield (index, hdr_tuple, W, H, anchorX, pixels_bytes)."""
    assert buf[:4] == FILE_MAGIC, f"bad magic {buf[:4]!r}"
    count = struct.unpack("<I", buf[4:8])[0]
    off = 8
    for i in range(count):
        if buf[off : off + 4] != FRAME_MAGIC:
            raise ValueError(f"frame {i}: bad marker {buf[off:off+4]!r} @0x{off:x}")
        h = HDR.unpack(buf[off + 4 : off + 28])
        W, H = h[4], h[1]
        px = buf[off + 28 : off + 28 + W * H]
        if len(px) != W * H:
            raise ValueError(f"frame {i}: short pixels {len(px)} != {W*H}")
        yield i, h, W, H, h[2], px
        off += 28 + W * H


def load_palette(path: Path | None) -> list[tuple[int, int, int]]:
    if path and path.exists():
        raw = path.read_bytes()
        return [(raw[i], raw[i + 1], raw[i + 2]) for i in range(0, 768, 3)]
    # fallback: grayscale ramp
    return [(v, v, v) for v in range(256)]


def to_image(W, H, px, pal, bg=(255, 0, 255)) -> Image.Image:
    """RGBA image; index 0 -> transparent."""
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    pixels = img.load()
    for y in range(H):
        row = y * W
        for x in range(W):
            idx = px[row + x]
            if idx == 0:
                continue
            r, g, b = pal[idx]
            pixels[x, y] = (r, g, b, 255)
    return img


def cmd_info(args):
    buf = Path(args[0]).read_bytes()
    n = 0
    wmin = hmin = 1 << 30
    wmax = hmax = 0
    for i, h, W, H, ax, px in parse(buf):
        if i < 16:
            print(f"  f{i:<4} W={W:<3} H={H:<3} anchorX={ax:<4} hdr=({h[0]},{h[3]},{h[5]})")
        n += 1
        wmin, wmax = min(wmin, W), max(wmax, W)
        hmin, hmax = min(hmin, H), max(hmax, H)
    print(f"{Path(args[0]).name}: {n} frames  W[{wmin}..{wmax}] H[{hmin}..{hmax}]")


def cmd_sheet(args):
    src = Path(args[0])
    out = Path(args[1])
    pal = load_palette(_opt_path(args, "--pal"))
    cols = int(_opt(args, "--cols", "16"))
    scale = int(_opt(args, "--scale", "2"))
    start = int(_opt(args, "--start", "0"))
    maxn = int(_opt(args, "--max", "256"))
    buf = src.read_bytes()
    frames = [(W, H, px) for i, h, W, H, ax, px in parse(buf) if start <= i < start + maxn]
    if not frames:
        print("no frames")
        return
    cw = max(W for W, H, _ in frames)
    ch = max(H for _, H, _ in frames)
    rows = (len(frames) + cols - 1) // cols
    pad = 2
    sheet = Image.new("RGBA", (cols * (cw + pad), rows * (ch + pad)), (40, 40, 50, 255))
    for k, (W, H, px) in enumerate(frames):
        cx = (k % cols) * (cw + pad)
        cy = (k // cols) * (ch + pad)
        sub = to_image(W, H, px, pal)
        sheet.alpha_composite(sub, (cx + (cw - W) // 2, cy + (ch - H) // 2))
    if scale != 1:
        sheet = sheet.resize((sheet.width * scale, sheet.height * scale), Image.NEAREST)
    sheet.convert("RGB").save(out)
    print(f"wrote {out} ({len(frames)} frames, {cols}x{rows}, cell {cw}x{ch}, scale {scale})")


def cmd_frames(args):
    src = Path(args[0])
    outdir = Path(args[1])
    outdir.mkdir(parents=True, exist_ok=True)
    pal = load_palette(_opt_path(args, "--pal"))
    maxn = int(_opt(args, "--max", "10000"))
    buf = src.read_bytes()
    for i, h, W, H, ax, px in parse(buf):
        if i >= maxn:
            break
        to_image(W, H, px, pal).save(outdir / f"{src.stem}_{i:04d}.png")
    print(f"wrote frames to {outdir}")


def _opt(args, key, default):
    return args[args.index(key) + 1] if key in args else default


def _opt_path(args, key):
    v = _opt(args, key, None)
    return Path(v) if v else None


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        return
    cmd, rest = sys.argv[1], sys.argv[2:]
    {"info": cmd_info, "sheet": cmd_sheet, "frames": cmd_frames}[cmd](rest)


if __name__ == "__main__":
    main()
