#!/usr/bin/env python3
"""Bake the PM98 GROUND -> IMPROVEMENTS left panel 1:1 from the ORIGINAL-game frame.

Binding frame: screenshots/original-walkthrough-2026-07-02/173_154935.png — the real
MANAGER.EXE GROUND overview after pressing IMPROVE (Man Utd / Old Trafford, "SEATS"
category active). This is the SEATS-category IMPROVEMENTS state; CAR PARK / FACILITIES /
SERVICES tab contents are NOT witnessed and are an honest gap (StadiumScreen leaves those
tabs inert rather than fabricating their offer lists).

The IMPROVE view shares the RIGHT ground panel + green header + 2x2 action grid with the
default WORK IN PROGRESS view (already baked into stadium/chrome.png); ONLY the LEFT panel
differs. So this bakes JUST the left panel (same x12..283 bbox as the WORKS panel) into an
RGBA 640x480 overlay that is opaque only there and transparent elsewhere. StadiumScreen
draws chrome.png first, then draws THIS overlay on top of the left panel when the IMPROVE
view is active — covering the WORK IN PROGRESS panel underneath.

The three SEATS offer cards carry a fixed seat increment + a fixed build time that are
witnessed IDENTICAL for two independent clubs (Man Utd frame 173 and Bolton W parity/21):
  +4,000 seats / 20 weeks   +8,000 seats / 35 weeks   +12,000 seats / 50 weeks
so seats + weeks are game constants and stay BAKED. The GBP price is club-specific and is
un-RE'd for the general case (only witnessed for Man Utd + Bolton), so each of the three
price cells is BLANKED with the card's flat background (212,223,255) and StadiumScreen
redraws the witnessed price for the managed club (or an honest gap for un-witnessed clubs).

All rects measured off the frame pixel grid (see docs/re/stadium_screen_re.md, IMPROVE view).
Run:  python3 tools/re/build_improvements_chrome_from_frames.py
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
FRAME = ROOT / "screenshots" / "original-walkthrough-2026-07-02" / "173_154935.png"
OUT_DIR = ROOT / "app" / "art" / "screens" / "stadium"

# Left IMPROVEMENTS panel: same outer bbox as the WORK IN PROGRESS panel (white outer
# border x12, black inner border x281-282, top y69-72, bottom y465-466).
LEFT_PANEL = (12, 68, 283, 467)

# The three GBP price cells (card bg = 212,223,255). Measured red-ink (150,0,0) extents:
# card1 x60..141 y255..263, card2 x60..141 y315..323, card3 x60..147 y375..383. Padded.
CARD_BG = (212, 223, 255)
PRICE_CELLS = [
    (58, 253, 152, 266),
    (58, 313, 152, 326),
    (58, 373, 152, 386),
]


def main() -> None:
    frame = Image.open(FRAME).convert("RGB")
    out = Image.new("RGBA", (640, 480), (0, 0, 0, 0))

    x0, y0, x1, y1 = LEFT_PANEL
    out.paste(frame.crop((x0, y0, x1, y1)).convert("RGBA"), (x0, y0))

    for (cx0, cy0, cx1, cy1) in PRICE_CELLS:
        out.paste(Image.new("RGBA", (cx1 - cx0, cy1 - cy0), (*CARD_BG, 255)), (cx0, cy0))

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    dst = OUT_DIR / "improvements.png"
    out.save(dst)
    print(f"wrote {dst.relative_to(ROOT)} (640x480 RGBA, {len(PRICE_CELLS)} price cells blanked)")


if __name__ == "__main__":
    main()
