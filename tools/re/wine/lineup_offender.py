#!/usr/bin/env python3
"""Find the unavailable player in the ORIGINAL's LINE-UP screen.

The original refuses to advance the week while a banned or injured man is in the
XI ("The initial line-up is not correct."). That gate is what stopped the
2026-07-25 career drive; getting past it is the only way a full season finishes.

Row geometry measured from a live frame this session (640x480 window):
  XI rows          y = 94 + 16*i, i = 0..10
  SUBSTITUTES rows y = 294 + 16*i
An unavailable row is drawn on a gold plate (212,191,85) instead of the normal
pale alternating fill, with a black status band ("1 MATCH" / injury weeks)
around x=250.

Prints the y of the first flagged XI row, or -1.
"""
import sys
from PIL import Image

XI_Y0, ROW_H, XI_N = 94, 16, 11
GOLD = (212, 191, 85)


def flagged(im, y: int) -> bool:
    bg = im.getpixel((60, y))
    band = im.getpixel((250, y))
    if bg == GOLD:
        return True
    # black status band is never present on an available row
    return sum(band) < 120


def main() -> int:
    im = Image.open(sys.argv[1]).convert("RGB")
    for i in range(XI_N):
        y = XI_Y0 + ROW_H * i
        if flagged(im, y):
            print(y)
            return 0
    print(-1)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
