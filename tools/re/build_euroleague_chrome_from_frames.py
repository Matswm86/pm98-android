#!/usr/bin/env python3
"""Bake the EURO. LEAGUE group screen's static chrome out of the real MANAGER.EXE frames.

Doctrine (same as every other screen in this repo): the static pixels are the ORIGINAL's
own, cut verbatim from a live frame; every cell the career fills is blanked to its
frame-sampled flat colour and redrawn by `app/scenes/EuroGroupScreen.gd`.

Sources
  tools/re/refs/euro-competitions-2026-07-25/1[0-5]_euroleague_group_[A-F].png
      six live GROUP frames (Bolton W career, wk22, one per group) -- the button lit
      faces and the `GROUP <letter>` header plates are cut from these, one per letter,
      so all six states are witnessed rather than synthesised.
  tools/re/refs/euroleague-group-2026-07-26/01_results_premier_empty_body.png
      the same RESULTS screen with an EMPTY body -- the desktop the results-row kits are
      blitted onto. Proven the right source: the wallpaper band y330..430 is 0-px
      identical to every group frame, across two different careers. (`screenshots/` is
      gitignored, so every frame the BUILD reads lives under refs/ as well.)

Outputs -> app/art/screens/euroleague/
  chrome.png            640x480 RGBA, the whole screen with every dynamic cell blanked
  hdr_group_<A-F>.png   the black header plate's `GROUP <letter>` text (it is CENTRED, so
                        the word shifts by a pixel between letters -- measured, not assumed)
  btn_lit_<A-F>.png     the 89x23 lit face of each GROUP button
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
REFS = ROOT / "tools/re/refs/euro-competitions-2026-07-25"
WALL = ROOT / "tools/re/refs/euroleague-group-2026-07-26/01_results_premier_empty_body.png"
OUT = ROOT / "app/art/screens/euroleague"

LETTERS = "ABCDEF"
FRAMES = {L: REFS / f"{10 + i}_euroleague_group_{L}.png" for i, L in enumerate(LETTERS)}

# ---------------------------------------------------------------- measured geometry
# All spans are inclusive pixel columns/rows read off the frames (see
# docs/re/euro_league_screen_re.md "Geometry banked 2026-07-25").
HDR_Y = (180, 207)  # the black GROUP header band
HDR_KIT = (75, 180, 23, 28)  # x, y, w, h -- the group leader's kit blit
HDR_TEXT = (100, 183, 101, 24)  # x, y, w, h -- `GROUP <letter>`

ROW_TOPS = (209, 224, 239, 254)  # four table rows, pitch 15, height 14
ROW_H = 14
CLUB_CELL = (95, 198)  # x span of the club-name + flag cell
NUM_CELLS = [
    (200, 220),
    (222, 236),
    (238, 252),
    (254, 268),
    (270, 284),
    (286, 300),
    (302, 316),
]  # PTS P W D L GF GA
BG_CLUB = ((200, 220, 240), (160, 180, 200))  # light row / dark row
BG_NUM = ((100, 120, 140), (80, 100, 120))
BG_PTS = (20, 0, 90)

RES_TOPS = (278, 300)  # two results rows, pitch 22, bar height 13
RES_BAR_H = 13
BAR_HOME = (97, 179)
BAR_AWAY = (216, 300)
BOXES = ((181, 196), (199, 214))
KIT_W, KIT_H = 17, 20
KIT_X = (80, 301)  # left kit / right kit
KIT_TOPS = (274, 296)

BTN_X = (358, 446)  # six GROUP buttons, 89x23 pitched 24
BTN_TOPS = (183, 207, 231, 255, 279, 303)

# The ROUND paginator plate: `Round %u` (.data 0x6545d8) in proman10, black, centred on
# x0+x1+1 = 829. The PHASE plate beside it stays baked -- the original prints the same
# `1/8 FINALS` across the whole group phase (REFRUN R3), so it is not a dynamic cell.
ROUND_PLATE = (372, 119, 456, 139)
BG_ROUND = (170, 191, 170)


def fill(im: Image.Image, x0: int, y0: int, x1: int, y1: int, col: tuple) -> None:
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            im.putpixel((x, y), col)


def paste_from(dst: Image.Image, src: Image.Image, x: int, y: int, w: int, h: int) -> None:
    dst.paste(src.crop((x, y, x + w, y + h)), (x, y))


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    frames = {L: Image.open(p).convert("RGB") for L, p in FRAMES.items()}
    wall = Image.open(WALL).convert("RGB")
    base = frames["A"].copy()

    # -- the group leader's kit and the header text are per-group: clear the kit to the
    #    desktop, and let the per-letter plate cover the text.
    x, y, w, h = HDR_KIT
    paste_from(base, wall, x, y, w, h)

    fill(base, ROUND_PLATE[0], ROUND_PLATE[1], ROUND_PLATE[2], ROUND_PLATE[3], BG_ROUND)

    # -- table: the frame, the column heads and the four position plates are static; the
    #    club cell and the seven number cells are not.
    for i, top in enumerate(ROW_TOPS):
        dark = i % 2
        fill(base, CLUB_CELL[0], top, CLUB_CELL[1], top + ROW_H - 1, BG_CLUB[dark])
        for j, (cx0, cx1) in enumerate(NUM_CELLS):
            fill(base, cx0, top, cx1, top + ROW_H - 1, BG_PTS if j == 0 else BG_NUM[dark])

    # -- results rows: the white club bars and the black score boxes are drawn on every
    #    round (an UNPLAYED round keeps them and only drops the goal digits -- witnessed
    #    2026-07-26, frame 03_group_A_round5_unplayed.png), so they stay baked; only the
    #    names, the digits and the kits come off.
    for top in RES_TOPS:
        fill(base, BAR_HOME[0], top, BAR_HOME[1], top + RES_BAR_H - 1, (255, 255, 255))
        fill(base, BAR_AWAY[0], top, BAR_AWAY[1], top + RES_BAR_H - 1, (255, 255, 255))
        for bx0, bx1 in BOXES:
            fill(base, bx0, top, bx1, top + RES_BAR_H - 1, (0, 0, 0))
    for ky in KIT_TOPS:
        for kx in KIT_X:
            paste_from(base, wall, kx, ky, KIT_W, KIT_H)

    # -- the six GROUP buttons, all UNLIT: each button's unlit face is cut from a frame
    #    whose selected group is a DIFFERENT letter, so every face is the original's own.
    for i, L in enumerate(LETTERS):
        src = frames["B" if L == "A" else "A"]
        paste_from(base, src, BTN_X[0], BTN_TOPS[i], BTN_X[1] - BTN_X[0] + 1, 23)

    base.convert("RGBA").save(OUT / "chrome.png")
    print("chrome.png <- 6 group frames + the empty-body desktop")

    for i, L in enumerate(LETTERS):
        f = frames[L]
        hx, hy, hw, hh = HDR_TEXT
        f.crop((hx, hy, hx + hw, hy + hh)).save(OUT / f"hdr_group_{L}.png")
        f.crop((BTN_X[0], BTN_TOPS[i], BTN_X[1] + 1, BTN_TOPS[i] + 23)).save(
            OUT / f"btn_lit_{L}.png"
        )
    print("hdr_group_A..F.png + btn_lit_A..F.png <- one witnessed frame each")


if __name__ == "__main__":
    main()
