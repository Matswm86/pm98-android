#!/usr/bin/env python3
"""PIL mirror of app/scenes/TitleScreen.gd -- the fidelity gate for the PM98 TITLE /
front-door screen (this box has no display for an in-engine capture, so we render the
exact same layout with Pillow and eyeball it against the original art).

Draws FONDO7 (the reversed PREMIER\\SININFO\\FONDO7 title, already in app/art) with the
four reversed hit rects outlined and the EXIT pill that TitleScreen paints over the
salir control. Mirrors TitleScreen.HITS exactly.

    python3 tools/re/preview_title.py            # -> /tmp/pm98_title_preview.png
    python3 tools/re/preview_title.py out.png
"""
from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent.parent
BG = ROOT / "app" / "art" / "screens" / "title" / "fondo7.png"

# Must match TitleScreen.HITS (640x480 design space).
HITS = {
    "DATA BASE": (350, 119, 285, 35),
    "MANAGER LEAGUE": (350, 177, 285, 35),
    "PRO-MANAGER LEAGUE": (350, 235, 285, 35),
    "EXIT": (552, 431, 73, 35),
}


def main() -> None:
    out = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("/tmp/pm98_title_preview.png")
    im = Image.open(BG).convert("RGB")
    assert im.size == (640, 480), f"FONDO7 must be 640x480, got {im.size}"
    d = ImageDraw.Draw(im, "RGBA")
    for name, (x, y, w, h) in HITS.items():
        if name == "EXIT":
            d.rectangle([x, y, x + w - 1, y + h - 1], fill=(13, 26, 90, 200), outline=(232, 240, 255))
            d.text((x + 22, y + 12), "EXIT", fill=(232, 240, 255))
        else:
            d.rectangle([x, y, x + w - 1, y + h - 1], outline=(255, 60, 60))
    out.parent.mkdir(parents=True, exist_ok=True)
    im.save(out)
    print(f"wrote {out} ({im.width}x{im.height})")


if __name__ == "__main__":
    main()
