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
OUT_STAR_FULL = OUT_DIR / "star_full.png"
OUT_STAR_HALF = OUT_DIR / "star_half.png"
OUT_JSON = OUT_DIR / "transfer_chrome.json"

W, H = 640, 480

# ---- panel interior base fill (measured: uniform light-grey) --------------
PANEL_FILL = (240, 240, 240)

# ---- blank regions (design coords) ----------------------------------------
# A: the KEEPER band-header text on the column-header row (x8..230); keeps the
#    AV/MO/CLUB FEE/WAGE/YEARS labels at x>=230. B: the whole list body below the
#    column headers down to the panel's bottom border.
BLANK_A = (8, 72, 230, 88)  # x0,y0,x1,y1
# right edge stops at 473 so the frame's list SCROLLBAR (gold up/down arrows +
# thumb at x479..486, y96..422) survives as inert baked art — the [3,5,5,5]=18
# capped list always fits the panel, so it never actually scrolls.
BLANK_B = (8, 88, 473, 432)

# ---- the [+] row expand-box sprite ----------------------------------------
PLUS_BOX = (5, 91, 32, 105)  # x0,y0,x1,y1 -> 27x14 cut from the frame
# Gold star strip, measured off frame 097 (2026-07-23): lit stars only, NO dim
# placeholders -- a 3-star row simply stops after three. Runs on every walked row are
# x156/170/184/198 (pitch 14), each 12px wide and 9px tall; an odd half-star is the
# 5px stub at x198 on the AV-69 rows. Both cut 1:1 so the scene blits the real
# STARJUGON art instead of drawing vector polygons.
STAR_FULL_BOX = (156, 159, 168, 168)  # 12x9, row slot_y=156
STAR_HALF_BOX = (198, 94, 203, 103)  # 5x9, the half stub on row slot_y=92

# ---- barra live-text blanks (the stale-career fix, audit §C2) --------------
# Frame 097's barra bakes the WALKTHROUGH career's text ("asdf" / Manchester
# Utd. / Saturday 23 August 1997 / Premier Week 3), so every app career showed
# that stale identity (parity run app/33). Blank ONLY the text interiors (band
# fills measured flat) + the crest box; TransferScreen redraws the live values
# at the ink anchors measured off this same frame. Borders/bevels/spiral/
# trophy stay 1:1.
MGR_BAND_FILL = (180, 200, 220)
CLUB_BAND_FILL = (80, 100, 120)
RP_TOP_FILL = (127, 159, 85)
RP_BOT_FILL = (85, 95, 0)
WHITE = (255, 255, 255)
BLANK_MGR = (0, 15, 108, 30)  # "asdf" band interior (borders y14/y30 stay)
BLANK_CLUB = (0, 33, 108, 48)  # "Manchester Utd." band interior
BLANK_CREST = (112, 14, 140, 47)  # kit-sprite box interior (white)
BLANK_SHEET_WD = (447, 17, 521, 26)  # "Saturday"
BLANK_SHEET_DAY = (447, 28, 521, 35)  # "23"
BLANK_SHEET_MON = (447, 37, 521, 46)  # "August"
BLANK_SHEET_YR = (447, 48, 521, 55)  # "1997"
BLANK_RP_TOP = (541, 15, 616, 30)  # "Premier" (trophy pixels start x616)
BLANK_RP_BOT = (541, 33, 624, 48)  # "Week 3" (trophy pixels start x624)


def fill(a: np.ndarray, rgb, x0: int, y0: int, x1: int, y1: int) -> None:
    a[y0:y1, x0:x1] = np.array(rgb, dtype=a.dtype)


def main() -> int:
    if not FRAME.exists():
        print(f"ERROR: binding frame missing: {FRAME}", file=sys.stderr)
        return 1
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    im = Image.open(FRAME).convert("RGB").crop((0, 0, W, H))  # 641 -> 640
    a = np.array(im)

    def C(x: int, y: int):
        return tuple(int(v) for v in a[y, x])

    # inks sampled BEFORE blanking (measured off known glyph strokes on frame 097).
    samples = {
        "band_navy": [0, 0, 128],  # KEEPER/DEFENDER/... header text C(50,81)
        "av_orange": [212, 63, 0],  # AV orange-red (dom-ink C(236,96))
        "mo_blue": [75, 109, 172],  # MO value blue (dom-ink C(261,96))
        "fee_red": [210, 0, 0],  # CLUB FEE bright red (dom-ink)
        "wage_darkred": [150, 0, 0],  # WAGE dark maroon (dom-ink C(367,95))
        "years_navy": [42, 63, 170],  # YEARS / LEFT cell digit
        "years_final_yellow": [255, 255, 170],  # LEFT==1 cell fill (re-sampled 07-23)
        "years_final_red": [255, 31, 0],  # its digit ink
        "name_black": [0, 0, 0],
        "row_sep": [176, 176, 176],
        "panel_fill": list(PANEL_FILL),
    }

    # cut the [+] expand-box sprite BEFORE blanking clears it.
    plus = im.crop(PLUS_BOX)
    plus.save(OUT_PLUS)

    # cut the gold star sprites (also before blanking).
    star_full = im.crop(STAR_FULL_BOX)
    star_full.save(OUT_STAR_FULL)
    star_half = im.crop(STAR_HALF_BOX)
    star_half.save(OUT_STAR_HALF)

    # blank the KEEPER header text + the whole list body to the panel fill.
    fill(a, PANEL_FILL, *BLANK_A)
    fill(a, PANEL_FILL, *BLANK_B)

    # blank the barra's career-specific text (the stale "asdf"/Man Utd fix).
    fill(a, MGR_BAND_FILL, *BLANK_MGR)
    fill(a, CLUB_BAND_FILL, *BLANK_CLUB)
    fill(a, WHITE, *BLANK_CREST)
    for r in (BLANK_SHEET_WD, BLANK_SHEET_DAY, BLANK_SHEET_MON, BLANK_SHEET_YR):
        fill(a, WHITE, *r)
    fill(a, RP_TOP_FILL, *BLANK_RP_TOP)
    fill(a, RP_BOT_FILL, *BLANK_RP_BOT)

    Image.fromarray(a).save(OUT_PNG)

    spec = {
        "binding_frame": FRAME.name,
        "note": "TRANSFER MARKET (FICHAR); list body redrawn by TransferScreen.gd from Career.market() rows. Every value cell is source-backed since 2026-07-23: AV = core4>>2 (FUN_00534570), stars = halves (AV+1) div 10 on the frame-cut STARJUGON art, MO = displayed morale (FUN_00582db0), CLUB FEE/WAGE = the RE'd lookup tables (FUN_00576cd0 x5000), YEARS|LEFT = the rolled contract term (rec+0x18/+0x19), flag = player byte +0x1a.",
        "size": [W, H],
        "samples": samples,
        "anchors": {
            # band header text (navy), ink-left x + header-row-top y per band
            "band_x": 50,
            "bands": [
                {"key": "GK", "label": "KEEPER", "hdr_y": 72, "cap": 3, "slot_y": [92, 108, 124]},
                {
                    "key": "DF",
                    "label": "DEFENDER",
                    "hdr_y": 140,
                    "cap": 5,
                    "slot_y": [156, 172, 188, 204, 220],
                },
                {
                    "key": "MF",
                    "label": "MIDFIELDER",
                    "hdr_y": 236,
                    "cap": 5,
                    "slot_y": [252, 268, 284, 300, 316],
                },
                {
                    "key": "FW",
                    "label": "FORWARD",
                    "hdr_y": 332,
                    "cap": 5,
                    "slot_y": [348, 364, 380, 396, 412],
                },
            ],
            "row_h": 16,
            "row_content_h": 13,
            "plus_xy": [5, 91],  # blit plus.png here (+ slot row-top delta)
            "flag_x": 34,  # nat. flag left (if flagCode present)
            "name_x": 60,  # name ink-left
            "stars_x": 156,
            "av_right": 250,
            "mo_center": 267,
            "fee_right": 337,
            "wage_right": 404,
            "years1_center": 432,
            "years2_center": 457,
            "row_left": 8,
            "row_right": 495,
            # nav button hit rects (baked art; scene only hit-tests)
            "btn_current": [496, 287, 128, 21],
            "btn_scout": [496, 324, 128, 21],
            "btn_offers": [496, 361, 128, 21],
            "btn_return": [496, 441, 128, 21],
            # live barra text anchors (ink centers/rows measured off frame 097;
            # the text interiors are blanked so the scene draws the LIVE career)
            "barra": {
                "mgr_cx": 52,
                "mgr_y": 15,
                "mgr_band": list(BLANK_MGR),
                "club_cx": 52,
                "club_y": 33,
                "club_band": list(BLANK_CLUB),
                "crest_box": list(BLANK_CREST),
                "sheet_cx": 483,
                "sheet_wd_y": 17,
                "sheet_day_y": 28,
                "sheet_mon_y": 37,
                "sheet_yr_y": 48,
                "band_cx": 580,
                "band1_y": 15,
                "band2_y": 33,
            },
        },
    }
    OUT_JSON.write_text(json.dumps(spec, indent=2))
    print(f"wrote {OUT_PNG} ({OUT_PNG.stat().st_size} bytes)")
    print(f"wrote {OUT_PLUS} ({plus.size[0]}x{plus.size[1]})")
    print(f"wrote {OUT_STAR_FULL} ({star_full.size[0]}x{star_full.size[1]})")
    print(f"wrote {OUT_STAR_HALF} ({star_half.size[0]}x{star_half.size[1]})")
    print(f"wrote {OUT_JSON}")
    print("samples:", json.dumps(samples))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
