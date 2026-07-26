#!/usr/bin/env python3
"""Bake the SCOUT screen's OURS "EXTRA SEARCH FILTERS" panel from REAL frames.

Mats 2026-07-26: the first version of this panel was procedurally drawn in an
invented navy/yellow palette — "NOT that AI slope image you used! REDO!". This
bake replaces it: EVERY pixel of ours_panel.png is either cut verbatim from an
owned-game frame or a flat fill in a colour sampled from one. The scene renders
only live values (title, four labels, thresholds, sort state, notes) in the
game's own BMFonts over this plate.

BINDING SOURCES:
  screenshots/original-walkthrough-2026-07-02/100_154657.png
      the CLUB PERSONNEL trainers dialog — the game's own control-form modal:
      * the white plate ground + the dialog's header-band (CURRENT TRAINING
        STAFF bar, text blanked to its own fill) for the panel title;
      * the six skill buttons HANDLING/PASSING/DRIBBLING/HEADING/TACKLING/
        SHOOTING cut VERBATIM (the exact six labels the six filters need);
        DRIBBLING (selected glow) + HEADING (focus ring) are de-highlighted
        with build_staff_overlay_chrome_from_frames.py's own neutralise
        technique, keeping each button's real wording;
      * the label-free neutral plate (HANDLING with its cyan zapped) as the
        face for the panel's own NAME / SORT BY / CLEAR / CLOSE controls —
        their wording is rendered live in the plates' own cyan (85,223,255).
  screenshots/wine-captures-2026-07-18-goalscorers/61_scout_with_scout.png
      the SCOUT screen's own pale-blue criteria fields: the wide dropdown
      field (x131..255, y131..146) and the small spinner field (x35..83,
      y177..192), both cut with their own borders. The wide field is width-
      extended by tiling its interior column (flat fill + 1 px borders, so
      the stretch is pixel-lossless).
  screenshots/wine-captures-2026-07-18-goalscorers/67_pos_enabled.png
      the enabled spinner arrows (the same cut build_scout_chrome uses).

Output: app/art/screens/scout/ours_panel.png (458x289, drawn at (67,63) — the
dialog's own witnessed screen position).

  python3 tools/re/build_scout_ours_from_frames.py
"""
from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
FR100 = ROOT / "screenshots" / "original-walkthrough-2026-07-02" / "100_154657.png"
FR61 = ROOT / "screenshots" / "wine-captures-2026-07-18-goalscorers" / "61_scout_with_scout.png"
FR67 = ROOT / "screenshots" / "wine-captures-2026-07-18-goalscorers" / "67_pos_enabled.png"
OUT = ROOT / "app" / "art" / "screens" / "scout" / "ours_panel.png"

P_W, P_H = 458, 289          # the staff dialog's own plate size (DLG w/h)
WHITE = (255, 255, 255)      # the dialog's plate ground
BLACK = (0, 0, 0)
LBLUE = (200, 220, 240)      # the header band's own fill

# frame-100 cuts (screen coords). The header band is a FLAT (200,220,240) fill
# (measured abs x90..342, y108..122 — no border, blue text on the fill), so it
# is synthesized at panel width rather than cut: a flat fill is lossless.
BAND_AT_RECT = (24, 10, 434, 25)     # panel-relative x0,y0,x1,y1
TR_BTN = [(112, 338), (212, 338), (312, 338), (112, 370), (212, 370), (312, 370)]
BTN_W, BTN_H = 82, 26
# frame-61 cuts
FIELD_WIDE = (131, 131, 256, 147)    # 125x16 incl border
FIELD_SMALL = (35, 177, 84, 193)     # 49x16 incl border
# frame-67 cuts (build_scout_chrome_from_frames.py's own arrow coords)
ARROW_L = (115, 131, 131, 147)
ARROW_R = (256, 131, 272, 147)

# panel-relative layout (the scene's OURS_* consts mirror these + (67,63))
NAME_PLATE = (24, 40)
NAME_FIELD = (116, 45)
NAME_FIELD_W = 220
ROW_YS = [78, 112, 146]              # attr plate tops; spinners sit at +5
COL_PLATE_X = [24, 240]
COL_ARROW_L = [112, 328]
COL_FIELD_X = [130, 346]
COL_ARROW_R = [181, 397]
SORT_PLATE = (24, 184)
SORT_ARROW_L = (112, 189)
SORT_FIELD = (130, 189)
SORT_ARROW_R = (257, 189)
CLEAR_AT = (264, 246)
CLOSE_AT = (356, 246)


def _is_cyan(c) -> bool:
    r, g, b = c[:3]
    return g > 150 and b > 200 and r < 160   # the plates' label ink (85,223,255)


def neutral_plate(im: Image.Image) -> Image.Image:
    """HANDLING's plate with its cyan wording zapped to the plate's own black."""
    x, y = TR_BTN[0]
    t = im.crop((x, y, x + BTN_W, y + BTN_H)).copy()
    tp = t.load()
    for yy in range(BTN_H):
        for xx in range(BTN_W):
            if _is_cyan(tp[xx, yy]):
                tp[xx, yy] = BLACK
    return t


def own_label_plate(im: Image.Image, tmpl: Image.Image, i: int) -> Image.Image:
    """Button i's plate de-highlighted: the neutral template with button i's OWN
    cyan wording restored (the staff baker's _neutralise_button, as a copy)."""
    x, y = TR_BTN[i]
    src = im.crop((x, y, x + BTN_W, y + BTN_H))
    sp = src.load()
    out = tmpl.copy()
    op = out.load()
    for yy in range(BTN_H):
        for xx in range(BTN_W):
            if _is_cyan(sp[xx, yy]):
                op[xx, yy] = sp[xx, yy]
    return out


def stretch_field(f: Image.Image, w: int) -> Image.Image:
    """Widen a bordered flat field by tiling one interior column (lossless: the
    interior is a flat fill between 1 px borders)."""
    if w <= f.width:
        return f
    out = Image.new("RGB", (w, f.height))
    keep_l, keep_r = 3, 3
    out.paste(f.crop((0, 0, keep_l, f.height)), (0, 0))
    col = f.crop((keep_l, 0, keep_l + 1, f.height))
    for x in range(keep_l, w - keep_r):
        out.paste(col, (x, 0))
    out.paste(f.crop((f.width - keep_r, 0, f.width, f.height)), (w - keep_r, 0))
    return out


def main() -> int:
    f100 = Image.open(FR100).convert("RGB")
    f61 = Image.open(FR61).convert("RGB")
    f67 = Image.open(FR67).convert("RGB")

    panel = Image.new("RGB", (P_W, P_H), WHITE)
    px = panel.load()
    for yy in range(P_H):                      # the dialog family's 2px black frame
        for xx in range(P_W):
            if xx < 2 or xx >= P_W - 2 or yy < 2 or yy >= P_H - 2:
                px[xx, yy] = BLACK

    # header band: the dialog's own flat (200,220,240) title fill, panel-wide
    for yy in range(BAND_AT_RECT[1], BAND_AT_RECT[3]):
        for xx in range(BAND_AT_RECT[0], BAND_AT_RECT[2]):
            px[xx, yy] = LBLUE

    # plates
    tmpl = neutral_plate(f100)
    for at in (NAME_PLATE, SORT_PLATE, CLEAR_AT, CLOSE_AT):
        panel.paste(tmpl, at)
    # the six skill plates verbatim (DRIBBLING glow + HEADING ring de-highlighted)
    plates = [f100.crop((x, y, x + BTN_W, y + BTN_H)) for (x, y) in TR_BTN]
    plates[2] = own_label_plate(f100, tmpl, 2)
    plates[3] = own_label_plate(f100, tmpl, 3)
    order = [0, 1, 2, 3, 4, 5]   # HANDLING PASSING / DRIBBLING HEADING / TACKLING SHOOTING
    for i, pi in enumerate(order):
        panel.paste(plates[pi], (COL_PLATE_X[i % 2], ROW_YS[i // 2]))

    # fields + arrows
    wide = f61.crop(FIELD_WIDE)
    small = f61.crop(FIELD_SMALL)
    al = f67.crop(ARROW_L)
    ar = f67.crop(ARROW_R)
    panel.paste(stretch_field(wide, NAME_FIELD_W), NAME_FIELD)
    for i in range(6):
        c, r = i % 2, i // 2
        y = ROW_YS[r] + 5
        panel.paste(al, (COL_ARROW_L[c], y))
        panel.paste(small, (COL_FIELD_X[c], y))
        panel.paste(ar, (COL_ARROW_R[c], y))
    panel.paste(al, SORT_ARROW_L)
    panel.paste(wide, SORT_FIELD)
    panel.paste(ar, SORT_ARROW_R)

    panel.save(OUT)
    print("wrote", OUT, panel.size)
    return 0


if __name__ == "__main__":
    sys.exit(main())
