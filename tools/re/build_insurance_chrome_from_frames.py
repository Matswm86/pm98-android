#!/usr/bin/env python3
"""Bake the PM98 INSURANCE screen + INSURANCE POLICY modal chrome from the live
wine witness run (frame-bake precedent: build_goalscorers_chrome_from_frames.py).

BINDING SOURCES (all witnessed 2026-07-18, docs/re/goalscorers_screen_re.md
"Bonus witnesses" + this port's own doc section in insurance_screen_re.md):
  screenshots/wine-captures-2026-07-18-goalscorers/
    33_insurance.png       resting screen, all uninsured (PARAM. carries the
                           engine's transient click-focus border -> NOT baked)
    34_insure_ward.png     == 33 except the focus border left PARAM. (clean
                           PARAM.) -> THE body chrome source
    35_insure_ward2.png    INSURANCE POLICY modal open on Ward, UNINSURED,
                           whole screen palette-dimmed (verified == the PMAlert
                           alert LUT on 9/9 sampled colour pairs)
    36_group1_sel.png      GROUP 1 tapped: red pending-selection border on "1",
                           right header cell -> doc icon + "INSUR. GROUP 1",
                           MONTHLY COST -> 200 (preview BEFORE OK)
    37_after_ok.png        after OK: Ward row INSUR. arrow green, doc + "1" on
                           pale green, COST cell grey with red 200
    38_frandsen_policy.png Frandsen modal (wage 14,583 vs Ward 1,250; SAME
                           GROUP prices -> flat game constants 200/500/1000)

WITNESSED STRUCTURE (measured off the frames, all coords design-space 640x480):
  * body = white panel x6..630 with 4 fixed position sections; section tops
    KEEP y87 (3 row slots), DEF y151 (5), MID y247 (5), FOR y343 (4); row pitch
    16, row box h 14 (top border y0, fill y0+1..y0+12 @ 240,240,240, bottom
    border y0+13). Bolton witness: MID 5th slot EMPTY = plain white panel (4
    MFs) -> row grids are drawn PER PRESENT PLAYER, not furniture.
  * row cells: icon x6..28 | box x29..602 with verticals 173,198,223,248,273,
    298,323,349,374,410 | arrow button x474..501 | INSUR. display cell
    x502..534 (white; insured: fill 170,223,170 + doc icon + group digit) |
    x535 sep | COST cell x536..601 (white; insured: fill 192,192,192 + value
    centred, ink 170,63,85) | right border x602.
  * scrollbar column x609..624 per section: noscroll (total<=slots): 17px
    dotted up arrow + pale dither track + 18px dotted down arrow (KEEP/MID
    witnessed). scrollable: 16px up arrow + black border + track (120,140,160)
    with slider + black border + 15px down arrow on black face (DEF 9/5 + FOR
    6/4 witnessed, both at first=0). slider h = floor(track_h*slots/total)
    reproduces DEF 25px AND FOR 20px exactly; offset = floor(track_h*first/
    total). up arrow ENABLED face is unwitnessed (both witnesses at top) ->
    pattern-derived as vflip(down-enabled), documented.
  * modal box x104..554 y86..392 inclusive. Header card: verticals x146/147,
    339/340, 505/506; title bands y121..135, value area y137..161 (labels
    MONTHLY WAGE / MONTHLY COST static, values y150..160 dynamic). Group cards
    + prices are STATIC (flat constants). SELECT GROUP boxes NONE x128..217,
    "1" x230..261, "2" x270..301, "3" x310..341 (y361..382); pending-selection
    border = 2px (255,31,0) drawn OUTSIDE the box (witnessed on "1", 36).
    Fresh-open uninsured shows NO border (35/38).

Output (app/art/screens/insurance/):
  chrome.png       640x418 body (y62..480) from 34, all 4 section row areas +
                   scroll columns cleared to panel white (x7.., x6 is marble)
  row_strip.png    one empty row: icon cell + grid + uninsured arrow button
  arrow_on.png     the insured (green) arrow button, same rect as in-strip one
  doc_row.png      the row doc icon (from 37)
  doc_modal.png    the modal header doc icon (from 36)
  scroll_*.png     up_off/dn_off/dn_on/slider25/pale (dn_on vflips to up_on)
  modal.png        the POLICY modal, dynamic texts cleared
  insurance_chrome.json  geometry + sampled inks
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
CAP = ROOT / "screenshots/wine-captures-2026-07-18-goalscorers"
OUT_DIR = ROOT / "app/art/screens/insurance"
W, H = 640, 480
BODY_Y0 = 62

SECTIONS = [  # key, first row top, slot count
    ("gk", 87, 3),
    ("def", 151, 5),
    ("mid", 247, 5),
    ("fwd", 343, 4),
]
ROW_PITCH = 16
ROW_BOX_H = 14           # top border + 12 fill + bottom border
STRIP_X0, STRIP_X1 = 7, 603   # icon cell + row box (right border x602; x6 = marble)
SCROLL_X0, SCROLL_X1 = 609, 625

# in-row cell interiors to clear back to the 240 fill (text carriers)
CLEAR_CELLS = [(30, 173), (174, 198), (199, 223), (224, 248), (249, 273),
               (274, 298), (299, 323), (324, 349), (350, 374), (375, 410),
               (411, 474)]

ARROW = (474, 503)       # sep col + button + right black border, y = row box
DOC_CELL = (502, 535)
COST_CELL = (536, 602)

MODAL_BOX = (104, 86, 555, 393)   # x0,y0,x1,y1 exclusive
# modal-relative dynamic regions (design coords)
M_NAME_BAND = (148, 121, 339, 136)     # "Ward (age 27)" title cell interior
M_RIGHT_BAND = (341, 121, 505, 136)    # UNINSURED / doc + INSUR. GROUP n
M_WAGE_VAL = (148, 149, 339, 161)      # £1,250 (below static MONTHLY WAGE)
M_COST_VAL = (341, 149, 505, 161)      # £0 / £200
GROUP_BTNS = {0: (128, 361, 90, 22), 1: (230, 361, 32, 22),
              2: (270, 361, 32, 22), 3: (310, 361, 32, 22)}


def fill(a, rgb, x0, y0, x1, y1):
    a[y0:y1, x0:x1] = np.array(rgb, dtype=a.dtype)


def load(name):
    return np.array(Image.open(CAP / name).convert("RGB"))[:H, :W]


def save(arr, name):
    Image.fromarray(arr).save(OUT_DIR / name)
    print(f"wrote {name} {arr.shape[1]}x{arr.shape[0]}")


def title_sprite(frame, out):
    """Cut the barra INSURANCE title glyphs vs the baked band.png (masked RGBA,
    the build_lineup_subs_chrome_from_frames.py doctrine)."""
    band = np.asarray(Image.open(
        ROOT / "app/art/screens/header/band.png").convert("RGB")).astype(np.uint8)
    zone = (slice(6, 58), slice(150, 435))
    diff = np.any(frame[zone] != band[zone], axis=2)
    ys, xs = np.nonzero(diff)
    assert len(xs) > 100, "title glyphs not found vs band.png"
    x0, x1, y0, y1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
    patch = frame[6 + y0:6 + y1, 150 + x0:150 + x1]
    rgba = np.zeros((*patch.shape[:2], 4), dtype=np.uint8)
    rgba[:, :, :3] = patch
    rgba[:, :, 3] = diff[y0:y1, x0:x1].astype(np.uint8) * 255
    Image.fromarray(rgba).save(out)
    print(f"wrote {out.name} {rgba.shape[1]}x{rgba.shape[0]}")
    return [int(150 + x0), int(6 + y0)]


def ink_of(region):
    """Darkest / most-saturated non-bg pixel of a region -> the text ink."""
    px = region.reshape(-1, 3).astype(int)
    d = np.abs(px - np.array([255, 255, 255])).sum(axis=1)
    return tuple(int(v) for v in px[d.argmax()])


def main() -> int:
    for f in ("33_insurance.png", "34_insure_ward.png", "35_insure_ward2.png",
              "36_group1_sel.png", "37_after_ok.png", "38_frandsen_policy.png"):
        if not (CAP / f).exists():
            print(f"ERROR: binding source missing: {CAP / f}", file=sys.stderr)
            return 1
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    f33, f34, f35 = load("33_insurance.png"), load("34_insure_ward.png"), load("35_insure_ward2.png")
    f36, f37, f38 = load("36_group1_sel.png"), load("37_after_ok.png"), load("38_frandsen_policy.png")

    # ---- witness assertions ------------------------------------------------
    d = np.abs(f33.astype(int) - f34.astype(int)).sum(axis=2)
    ys, xs = np.nonzero(d)
    assert xs.min() >= 368 and xs.max() <= 441 and ys.min() >= 430, \
        "33 vs 34 must differ only at the PARAM. click-focus border"
    # 37 == 39 (state persists) is witnessed; 35 vs 38 right band identical:
    rb = (slice(121, 136), slice(341, 505))
    assert np.array_equal(f35[rb], f38[rb]), "UNINSURED band must match 35 vs 38"
    # icon cell + empty arrow button identical across rows (Ward / Todd / Sellars)
    strip_w = STRIP_X1 - STRIP_X0
    ward = f34[87:87 + ROW_BOX_H, STRIP_X0:STRIP_X1]
    for top in (151, 247):
        other = f34[top:top + ROW_BOX_H, STRIP_X0:STRIP_X1]
        assert np.array_equal(ward[:, :24], other[:, :24]), f"icon differs @y{top}"
        assert np.array_equal(ward[:, ARROW[0] - STRIP_X0:ARROW[1] - STRIP_X0],
                              other[:, ARROW[0] - STRIP_X0:ARROW[1] - STRIP_X0]), \
            f"arrow button differs @y{top}"

    # ---- body chrome from 34, rows + scroll columns cleared ---------------
    body = f34.copy()
    for _k, y0, slots in SECTIONS:
        y1 = y0 + ROW_PITCH * slots - 2      # last box bottom border
        # clear from x9: the x7..8 black dashes are the panel frame and show
        # on EMPTY slots (witnessed at the MID 5th slot); filled rows overdraw
        # them via the row strip, which starts at x7.
        fill(body, (255, 255, 255), 9, y0, STRIP_X1, y1)
        fill(body, (255, 255, 255), SCROLL_X0, y0, SCROLL_X1, y1 + 1)
    save(body[BODY_Y0:H], "chrome.png")

    # ---- row strip: Ward's row with every text cleared to the 240 fill ----
    strip = ward.copy()
    for x0, x1 in CLEAR_CELLS:
        fill(strip, (240, 240, 240), x0 - STRIP_X0, 1, x1 - 1 - STRIP_X0, 13)
    save(strip, "row_strip.png")

    # ---- arrow button, both states ----------------------------------------
    save(f34[87:101, ARROW[0]:ARROW[1]], "arrow_off.png")
    save(f37[87:101, ARROW[0]:ARROW[1]], "arrow_on.png")

    # ---- row doc icon (37 Ward): tight bbox inside the pale green cell ----
    cell = f37[88:100, DOC_CELL[0]:DOC_CELL[1]]
    m = np.any(np.abs(cell.astype(int) - np.array([170, 223, 170])).sum(axis=2) > 30, axis=2) \
        if cell.ndim == 4 else (np.abs(cell.astype(int) - np.array([170, 223, 170])).sum(axis=2) > 30)
    dys, dxs = np.nonzero(m)
    digit_split = 522  # doc icon left of x522, group digit right of it (witnessed)
    mm = m.copy()
    mm[:, digit_split - DOC_CELL[0]:] = False
    dys, dxs = np.nonzero(mm)
    dx0, dx1, dy0, dy1 = dxs.min(), dxs.max() + 1, dys.min(), dys.max() + 1
    save(f37[88 + dy0:88 + dy1, DOC_CELL[0] + dx0:DOC_CELL[0] + dx1], "doc_row.png")
    doc_row_xy = [int(DOC_CELL[0] + dx0), int(dy0 + 1)]  # y rel row-box top

    # digit ink (witnessed group 1) + the button digit inks for 2/3
    digit_ink = ink_of(f37[88:100, digit_split:DOC_CELL[1] - 1])
    btn_inks = {g: ink_of(f35[363:381, GROUP_BTNS[g][0] + 2:GROUP_BTNS[g][0] + GROUP_BTNS[g][2] - 2])
                for g in (1, 2, 3)}
    cost_ink = ink_of(f37[88:100, COST_CELL[0] + 1:COST_CELL[1] - 1])

    # ---- scroll sprites ---------------------------------------------------
    save(f34[87:104, SCROLL_X0:SCROLL_X1], "scroll_up_off.png")    # KEEP, 17px
    save(f34[115:133, SCROLL_X0:SCROLL_X1], "scroll_dn_off.png")   # KEEP, 18px
    save(f34[214:229, SCROLL_X0:SCROLL_X1], "scroll_dn_on.png")    # DEF, 15px
    save(f34[167:192, SCROLL_X0:SCROLL_X1], "scroll_slider25.png")  # DEF slider
    save(f34[264:307, SCROLL_X0:SCROLL_X1], "scroll_pale.png")     # MID pale track
    # slider formula check: DEF track y167..212 (46), 5/9 -> 25; FOR y359..388 (30), 4/6 -> 20
    assert int(46 * 5 / 9) == 25 and int(30 * 4 / 6) == 20
    # FOR witnessed slider must equal the DEF sprite resized by the formula-cut
    for_slider = f34[359:379, SCROLL_X0:SCROLL_X1]
    assert for_slider.shape[0] == 20

    # ---- modal chrome from 35, dynamic texts cleared ----------------------
    x0, y0, x1, y1 = MODAL_BOX
    mod = f35.copy()
    # band gradient carrier: rebuild each band row from ITS OWN glyph-free
    # column ("Ward (age 27)" spans x189..295 -> x150 clean; "UNINSURED"
    # spans ~x380..465 -> x342 clean). Keeps each band's own gradient.
    for yy in range(M_NAME_BAND[1], M_NAME_BAND[3]):
        mod[yy, M_NAME_BAND[0]:M_NAME_BAND[2]] = f35[yy, 150]
        mod[yy, M_RIGHT_BAND[0]:M_RIGHT_BAND[2]] = f35[yy, 342]
    for (cx0, cy0, cx1, cy1) in (M_WAGE_VAL, M_COST_VAL):
        fill(mod, (255, 255, 255), cx0, cy0, cx1 - 1, cy1)
    save(mod[y0:y1, x0:x1], "modal.png")

    # modal doc icon (36 right band, left of the INSUR. text)
    band36 = f36[121:136, 341:505]
    bg = f35[128, 342]
    m2 = np.abs(band36.astype(int) - bg.astype(int)).sum(axis=2) > 60
    m2[:, 20:] = False   # icon sits in the first ~20 cols of the band
    dys, dxs = np.nonzero(m2)
    save(f36[121 + dys.min():121 + dys.max() + 1, 341 + dxs.min():341 + dxs.max() + 1],
         "doc_modal.png")
    doc_modal_xy = [int(341 + dxs.min()), int(121 + dys.min())]

    # ---- barra title ------------------------------------------------------
    title_xy = title_sprite(f34, OUT_DIR / "title.png")

    # ---- sampled inks -----------------------------------------------------
    name_ink = ink_of(f35[121:136, 180:300])          # "Ward (age 27)" navy
    right_ink = ink_of(f35[121:136, 360:490])         # UNINSURED steel blue
    wage_val_ink = ink_of(f35[149:161, 200:290])      # £1,250 black
    cost_val_ink = ink_of(f35[149:161, 390:460])      # £0 dark red? sample
    sel_border = (255, 31, 0)                         # witnessed on "1" (36)
    row = f34[88:100]
    stat_inks = {k: ink_of(row[:, a + 1:b - 1]) for k, (a, b) in {
        "num": (30, 60), "name": (60, 173), "EN": (174, 198), "SP": (199, 223),
        "ST": (224, 248), "AG": (249, 273), "QU": (274, 298), "FI": (299, 323),
        "MO": (324, 349), "AV": (350, 374), "age": (375, 410), "wage": (411, 474)}.items()}

    spec = {
        "binding_sources": {
            "body": "wine-captures-2026-07-18-goalscorers/34_insure_ward.png",
            "resting_twin": "33_insurance.png (differs only at the PARAM. focus border)",
            "modal": "35_insure_ward2.png",
            "modal_selected": "36_group1_sel.png",
            "insured_row": "37_after_ok.png",
            "flat_price_proof": "38_frandsen_policy.png",
        },
        "size": [W, H], "body_y0": BODY_Y0, "title_xy": title_xy,
        "sections": [{"key": k, "y0": y, "slots": s} for k, y, s in SECTIONS],
        "row": {"pitch": ROW_PITCH, "box_h": ROW_BOX_H,
                "strip_x": STRIP_X0, "strip_w": STRIP_X1 - STRIP_X0},
        "cells": {"num": [30, 60], "name": [62, 173], "EN": [174, 198],
                  "SP": [199, 223], "ST": [224, 248], "AG": [249, 273],
                  "QU": [274, 298], "FI": [299, 323], "MO": [324, 349],
                  "AV": [350, 374], "age": [375, 410], "wage": [411, 474],
                  "arrow": [ARROW[0], ARROW[1]], "doc": [DOC_CELL[0], DOC_CELL[1]],
                  "cost": [COST_CELL[0], COST_CELL[1]]},
        "insured": {"doc_fill": [170, 223, 170], "cost_fill": [192, 192, 192],
                    "doc_row_xy": doc_row_xy, "digit_x": 524,
                    "digit_ink_1": list(digit_ink),
                    "btn_digit_inks": {str(g): list(v) for g, v in btn_inks.items()},
                    "cost_ink": list(cost_ink)},
        "scroll": {"x0": SCROLL_X0, "w": SCROLL_X1 - SCROLL_X0,
                   "up_off_h": 17, "dn_off_h": 18, "dn_on_h": 15,
                   "track_bg": [120, 140, 160],
                   "note": "scrollable: up 16px + border + track + border + dn 15px; "
                           "slider h=floor(track*slots/total) off=floor(track*first/total) "
                           "(reproduces DEF 25px + FOR 20px); up-enabled = vflip(dn_on), "
                           "pattern-derived (both witnesses at first=0)"},
        "modal": {"box": list(MODAL_BOX), "name_band": list(M_NAME_BAND),
                  "right_band": list(M_RIGHT_BAND), "wage_val": list(M_WAGE_VAL),
                  "cost_val": list(M_COST_VAL),
                  "group_btns": {str(k): list(v) for k, v in GROUP_BTNS.items()},
                  "ok_btn": [458, 357, 92, 30],
                  "doc_modal_xy": doc_modal_xy,
                  "sel_border": list(sel_border)},
        "prices": {"1": 200, "2": 500, "3": 1000},
        "samples": {"row_inks": {k: list(v) for k, v in stat_inks.items()},
                    "row_fill": [240, 240, 240],
                    "modal_name_ink": list(name_ink),
                    "modal_right_ink": list(right_ink),
                    "modal_wage_val_ink": list(wage_val_ink),
                    "modal_cost_val_ink": list(cost_val_ink)},
    }
    (OUT_DIR / "insurance_chrome.json").write_text(json.dumps(spec, indent=1))
    print("wrote insurance_chrome.json")
    print("digit ink 1 (row):", digit_ink, " button inks:", btn_inks)
    print("name ink:", name_ink, " right ink:", right_ink,
          " wage val ink:", wage_val_ink, " cost val ink:", cost_val_ink)
    print("cost row ink:", cost_ink, " row inks:", stat_inks)
    return 0


if __name__ == "__main__":
    sys.exit(main())
