#!/usr/bin/env python3
"""Bake the PM98 TRANSFER MARKET (FICHAR) screen chrome from the real walkthrough
frame, following the PreseasonScreen / FinanceScreen frame-bake precedent
(tools/re/build_finance_chrome_from_frames.py): cut the original pixels 1:1 and
blank ONLY the dynamic list body so the scene can redraw the live buyable rows on
top — nothing about the panel, the AV/MO/CLUB FEE/WAGE/YEARS column headers, the
scrollbar, the CURRENT OFFERS / SCOUT / OFFERS / RETURN nav buttons (with their
magnifier / money-bag / coin icons), the bottom status bar or the stadium
background is hand-invented.

Binding frame: screenshots/original-walkthrough-2026-07-02/097_164707.png
  == the real TRANSFER MARKET (FICHAR) screen, reached hub -> TRANSFERS (frame
  093 shows the "TRANSFER MARKET" hub region holding TRANSFERS/PLAYERS/STAFF).
  Man Utd, Saturday 23 August 1997, Premier / Week 3. The list shows the four
  RED-... no: BLUE position bands KEEPER / DEFENDER / MIDFIELDER / FORWARD
  (SINGULAR), capped [3,5,5,5], each row: [+] expand box | (nat. flag) | Name |
  gold stars | AV(red) | MO(blue) | CLUB FEE(red) | WAGE(dark-red) | YEARS|LEFT
  (two navy cells, yellow when final-year). This replaces the earlier invented
  layout (PLAYER/RATING/AV/MO/AGE/CLUB FEE/WAGE/CLUB columns, RED plural band
  names, a fabricated BANK box + "Window: OPEN / N offers left" text, a bottom
  strip naming the top target, club crest instead of the [+] box).

Outputs:
  app/art/screens/transfer/chrome.png          - 640x480 chrome, list body blanked
  app/art/screens/transfer/plus.png            - the [+] row expand-box sprite (cut)
  app/art/screens/transfer/transfer_chrome.json - sampled inks + overlay anchors

The frame is 641x480 (1px capture artefact); we crop to the game's native 640x480.

Blanking method = flat panel-fill: the list interior is a uniform light-grey
(240,240,240) in the frame (measured across every empty keeper slot + inter-row
gap), so we clear the body to that exact colour. The scene redraws the band
headers + filled rows over it. The column-header strip (AV..YEARS at x230..470)
and everything outside the body is kept 1:1.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
FRAME = ROOT / "screenshots/original-walkthrough-2026-07-02/097_164707.png"
OUT_DIR = ROOT / "app/art/screens/transfer"
OUT_PNG = OUT_DIR / "chrome.png"
OUT_PLUS = OUT_DIR / "plus.png"
OUT_JSON = OUT_DIR / "transfer_chrome.json"

W, H = 640, 480

# ---- panel interior base fill (measured: uniform light-grey) --------------
PANEL_FILL = (240, 240, 240)

# ---- blank regions (design coords) ----------------------------------------
# A: the KEEPER band-header text on the column-header row (x8..230); keeps the
#    AV/MO/CLUB FEE/WAGE/YEARS labels at x>=230. B: the whole list body below the
#    column headers down to the panel's bottom border.
BLANK_A = (8, 72, 230, 88)     # x0,y0,x1,y1
# right edge stops at 473 so the frame's list SCROLLBAR (gold up/down arrows +
# thumb at x479..486, y96..422) survives as inert baked art — the [3,5,5,5]=18
# capped list always fits the panel, so it never actually scrolls.
BLANK_B = (8, 88, 473, 432)

# ---- the [+] row expand-box sprite ----------------------------------------
PLUS_BOX = (5, 91, 32, 105)    # x0,y0,x1,y1 -> 27x14 cut from the frame


def fill(a: np.ndarray, rgb, x0: int, y0: int, x1: int, y1: int) -> None:
    a[y0:y1, x0:x1] = np.array(rgb, dtype=a.dtype)


def main() -> int:
    if not FRAME.exists():
        print(f"ERROR: binding frame missing: {FRAME}", file=sys.stderr)
        return 1
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    im = Image.open(FRAME).convert("RGB").crop((0, 0, W, H))   # 641 -> 640
    a = np.array(im)

    def C(x: int, y: int):
        return tuple(int(v) for v in a[y, x])

    # inks sampled BEFORE blanking (measured off known glyph strokes on frame 097).
    samples = {
        "band_navy": [0, 0, 128],          # KEEPER/DEFENDER/... header text C(50,81)
        "av_orange": [212, 63, 0],         # AV orange-red (dom-ink C(236,96))
        "mo_blue": [75, 109, 172],         # MO value blue (dom-ink C(261,96))
        "fee_red": [210, 0, 0],            # CLUB FEE bright red (dom-ink)
        "wage_darkred": [150, 0, 0],       # WAGE dark maroon (dom-ink C(367,95))
        "years_navy": [42, 63, 170],       # YEARS / LEFT cell digit
        "years_final_yellow": [255, 255, 90],  # LEFT==1 cell highlight
        "name_black": [0, 0, 0],
        "row_sep": [176, 176, 176],
        "panel_fill": list(PANEL_FILL),
    }

    # cut the [+] expand-box sprite BEFORE blanking clears it.
    plus = im.crop(PLUS_BOX)
    plus.save(OUT_PLUS)

    # blank the KEEPER header text + the whole list body to the panel fill.
    fill(a, PANEL_FILL, *BLANK_A)
    fill(a, PANEL_FILL, *BLANK_B)

    Image.fromarray(a).save(OUT_PNG)

    spec = {
        "binding_frame": FRAME.name,
        "note": "TRANSFER MARKET (FICHAR); list body redrawn by TransferScreen.gd "
                "from Career.market() rows. AV=CA (real); CLUB FEE/WAGE = the "
                "valuation model (accepted approximation, TransferMarket.gd); "
                "MO + YEARS|LEFT + nationality flag = honest gaps (morale is an "
                "un-RE'd dynamic save value per audit B7; buyable-player contract "
                "years + flagCode are not in the market row).",
        "size": [W, H],
        "samples": samples,
        "anchors": {
            # band header text (navy), ink-left x + header-row-top y per band
            "band_x": 50,
            "bands": [
                {"key": "GK", "label": "KEEPER", "hdr_y": 72, "cap": 3,
                 "slot_y": [92, 108, 124]},
                {"key": "DF", "label": "DEFENDER", "hdr_y": 140, "cap": 5,
                 "slot_y": [156, 172, 188, 204, 220]},
                {"key": "MF", "label": "MIDFIELDER", "hdr_y": 236, "cap": 5,
                 "slot_y": [252, 268, 284, 300, 316]},
                {"key": "FW", "label": "FORWARD", "hdr_y": 332, "cap": 5,
                 "slot_y": [348, 364, 380, 396, 412]},
            ],
            "row_h": 16,
            "row_content_h": 13,
            "plus_xy": [5, 91],            # blit plus.png here (+ slot row-top delta)
            "flag_x": 34,                  # nat. flag left (if flagCode present)
            "name_x": 60,                  # name ink-left
            "stars_x": 156,
            "av_right": 250,
            "mo_center": 267,
            "fee_right": 337,
            "wage_right": 404,
            "years1_center": 432,
            "years2_center": 457,
            "row_left": 8, "row_right": 495,
            # nav button hit rects (baked art; scene only hit-tests)
            "btn_current": [496, 287, 128, 21],
            "btn_scout": [496, 324, 128, 21],
            "btn_offers": [496, 361, 128, 21],
            "btn_return": [496, 441, 128, 21],
        },
    }
    OUT_JSON.write_text(json.dumps(spec, indent=2))
    print(f"wrote {OUT_PNG} ({OUT_PNG.stat().st_size} bytes)")
    print(f"wrote {OUT_PLUS} ({plus.size[0]}x{plus.size[1]})")
    print(f"wrote {OUT_JSON}")
    print("samples:", json.dumps(samples))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
