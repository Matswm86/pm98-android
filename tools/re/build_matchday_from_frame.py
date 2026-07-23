#!/usr/bin/env python3
"""Bake the GROUND MATCH DAY left panel (matchday.png) from the owner's native frame 06.

Binding frame: screenshots/user-captures-2026-07-23-ground-squad-transfer/06_07-53-55.png
(the real MANAGER.EXE GROUND -> MATCH DAY sub-screen, Man Utd). The owner frames are native
640x480 at desktop offset (641,196), scale 1.0 EXACT -> crop (641,196,1281,676) is a
pixel-perfect native frame (handoff-pm98-ground-tabs-transfer-banner-2026-07-23).

Output: app/art/screens/stadium/matchday.png (640x480 RGBA). Only the LEFT MATCH DAY panel
is painted (opaque); the rest is transparent so the shared BARRA header, the right
CAPACITY/scene panel, and the IMPROVE/WORKS/MATCH DAY/RETURN action grid (all baked into
chrome.png / drawn live by StadiumScreen) show through unchanged -- same convention as
improvements.png / carpark.png.

DYNAMIC cells are BLANKED here (filled with the locally-sampled panel background) and redrawn
live by StadiumScreen._draw_matchday from the real Career model:
  - HOME team name  (next home fixture -- managed club)
  - AWAY team name  (next home fixture -- opponent)
  - TICKET PRICE value (Career.ticket_price, via the PRICES ladder)
  - PRICE OF BOARD value (Career.board_price, via the PRICES ladder)
Ground name + league (on the ticket) and the sponsor-board season offer + ACCEPT stay BAKED
(witnessed Man Utd: Old Trafford / Premier League / offer £1,120,000). StadiumScreen covers
them for a non-witnessed club (ground/league) or once the offer is taken / for a club with no
witnessed offer (honest gap -- the offer is conditional per docs/re/finance_constants.md).

Invent nothing: every kept pixel comes from the frame; every blank is a flat fill of the
color sampled right next to the text it removes. Re-run after re-capturing frame 06.
"""
from __future__ import annotations

from pathlib import Path

from PIL import Image

REPO = Path(__file__).resolve().parents[2]
SRC = REPO / "screenshots/user-captures-2026-07-23-ground-squad-transfer/06_07-53-55.png"
OUT = REPO / "app/art/screens/stadium/matchday.png"

# Native crop of the owner desktop capture (scale 1.0 at offset 641,196).
CROP = (641, 196, 641 + 640, 196 + 480)

# The left MATCH DAY panel rectangle (black border in, white body). Everything else -> alpha 0.
PANEL = (10, 67, 282, 466)  # x0, y0, x1, y1 (exclusive)

# Dynamic cells blanked here -> (x0, y0, x1, y1, fill RGB). Fills are the panel-bg colours
# sampled adjacent to each removed glyph run (see build note / native measurements).
BLANK = [
    (22, 191, 234, 209, (180, 200, 220)),   # HOME team line (above the home/away underline)
    (22, 212, 234, 229, (180, 200, 220)),   # AWAY team line (below the underline)
    (120, 237, 218, 253, (120, 140, 160)),  # TICKET PRICE value (between the ticket arrows)
    (78, 334, 207, 349, (160, 190, 40)),    # PRICE OF BOARD value (between the olive arrows)
]


def main() -> None:
    if not SRC.exists():
        raise SystemExit(f"missing binding frame: {SRC}")
    frame = Image.open(SRC).convert("RGB").crop(CROP)
    if frame.size != (640, 480):
        raise SystemExit(f"unexpected native size {frame.size}")

    px = frame.load()
    for x0, y0, x1, y1, fill in BLANK:
        for y in range(y0, y1):
            for x in range(x0, x1):
                px[x, y] = fill

    out = Image.new("RGBA", (640, 480), (0, 0, 0, 0))
    op = out.load()
    x0, y0, x1, y1 = PANEL
    for y in range(y0, y1):
        for x in range(x0, x1):
            r, g, b = frame.getpixel((x, y))
            op[x, y] = (r, g, b, 255)

    OUT.parent.mkdir(parents=True, exist_ok=True)
    out.save(OUT)
    print(f"wrote {OUT} ({out.size}, panel {PANEL})")


if __name__ == "__main__":
    main()
