#!/usr/bin/env python3
"""Classify a wine MANAGER.EXE window snapshot for the season drive.

Prints one line: <label> <ahash>

Labels come from probe pixels proven by the existing harness (nav_kickoff.sh's
alert test: (200,230) is pure white under the modal alert and dark green on the
bare hub). Everything else is reported as `screen` plus a 64-bit average hash,
so the driver can tell "a screen I have already banked" from "a screen never
seen before" without inventing a name for it.
"""
import sys
from PIL import Image

HUB_GREEN = (50, 70, 0)
WHITE = (255, 255, 255)


def ahash(im: Image.Image) -> str:
    g = im.convert("L").resize((8, 8), Image.BILINEAR)
    px = list(g.getdata())
    avg = sum(px) / len(px)
    bits = 0
    for i, p in enumerate(px):
        if p >= avg:
            bits |= 1 << i
    return f"{bits:016x}"


def main() -> int:
    im = Image.open(sys.argv[1]).convert("RGB")
    w, h = im.size
    probe = im.getpixel((min(200, w - 1), min(230, h - 1)))
    label = "screen"
    if probe == HUB_GREEN:
        label = "hub"
    elif probe == WHITE:
        label = "alert"
    print(f"{label} {ahash(im)} {w}x{h}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
