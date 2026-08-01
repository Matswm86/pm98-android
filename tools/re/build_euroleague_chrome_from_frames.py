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

# ---- the results-row kit-well OVERLAYS (2026-07-27) ---------------------------------
# The knockout build proved the kit outline/bevel pass is POSITION-CONSTANT (every kit
# in a bank shares one silhouette), so its result is baked verbatim per well, voted
# across the six witnessed group frames -- six DIFFERENT clubs per well. UNDER = ring
# pixels outside every silhouette where all six frames agree and differ from the
# wallpaper the chrome bakes there; OVER = on-sprite positions the pass provably
# overrides club-independently. The club ids per well are the frames' own (the same
# transcription shot_euroleague_parity.gd carries).
WELL_IDS = {
    ("res0", "h"): {
        "xy": (80, 274),
        "ids": {"A": 40, "B": 1050, "C": 1075, "D": 1060, "E": 1131, "F": 1104},
    },
    ("res0", "a"): {
        "xy": (301, 274),
        "ids": {"A": 1038, "B": 1106, "C": 1024, "D": 1021, "E": 44, "F": 1042},
    },
    ("res1", "h"): {
        "xy": (80, 296),
        "ids": {"A": 1135, "B": 1124, "C": 1172, "D": 1189, "E": 1278, "F": 1231},
    },
    ("res1", "a"): {
        "xy": (301, 296),
        "ids": {"A": 1223, "B": 1161, "C": 1274, "D": 1262, "E": 1193, "F": 1003},
    },
}


# ---- the group LEADER's kit, and what is BEHIND it (2026-08-01) ----------------------
# The leader kit sits on the LEFT END of the black GROUP header band, and that end is
# SLANTED -- the band's left edge walks left as y grows, so a straight wall paste over the
# whole kit rect deletes the part of the band the kit does not cover. That is the whole
# "solid block over the sprite's right half" residual euro_league_screen_re.md recorded
# (196-202 px of the cell), and it is a bake gap, not a blit pass: PMShadow was wired here
# in s78 and made the gate WORSE.
#
# It is recovered without inventing a pixel. Each of the six frames has a DIFFERENT leader,
# so a position one leader's kit covers another's leaves bare; take the colour every frame
# that leaves it bare agrees on. Measured over the 26x32 cell: 420 positions are witnessed
# this way and 6 are split (the frames disagree, so they stay on the wall paste); the
# remaining 406 are the silhouette every NANOESC kit shares, which the port draws a kit
# over at runtime exactly as the original does.
LEADER_IDS = {"A": 1135, "B": 1124, "C": 1024, "D": 1021, "E": 44, "F": 1003}
# The blit origin of that kit -- EuroGroupScreen.HDR_KIT_XY. It is NOT HDR_KIT's origin:
# the wall-paste rect starts two rows lower, so coverage has to be read in the SPRITE's
# own frame or every row is tested against the wrong row of the silhouette.
LEADER_KIT_XY = (75, 178)
LEADER_KIT_WH = (24, 32)


def fill(im: Image.Image, x0: int, y0: int, x1: int, y1: int, col: tuple) -> None:
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            im.putpixel((x, y), col)


def paste_from(dst: Image.Image, src: Image.Image, x: int, y: int, w: int, h: int) -> None:
    dst.paste(src.crop((x, y, x + w, y + h)), (x, y))


def _recover_leader_backdrop(base: Image.Image, frames: dict) -> None:
    """Put back the slanted end of the black header band the wall paste just deleted.

    Only positions at least one frame leaves bare AND all such frames agree on are
    written; everything else keeps the wall paste. Prints the three counts so a future
    frame set changing the balance is visible in the build log, not silent.
    """
    nanos = {L: Image.open(ROOT / f"app/art/kits/nano/{cid}.png").convert("RGBA")
             for L, cid in LEADER_IDS.items()}
    x, y = LEADER_KIT_XY
    w, h = LEADER_KIT_WH
    witnessed = split = covered = 0
    for dy in range(h):
        for dx in range(w):
            seen = set()
            for L in LETTERS:
                n = nanos[L]
                if dx < n.width and dy < n.height and n.getpixel((dx, dy))[3] != 0:
                    continue                      # this leader's kit covers it
                seen.add(frames[L].getpixel((x + dx, y + dy)))
            if not seen:
                covered += 1
            elif len(seen) > 1:
                split += 1
            else:
                witnessed += 1
                base.putpixel((x + dx, y + dy), seen.pop())
    print(f"  leader-kit backdrop: {witnessed} witnessed, {split} split (frames disagree), "
          f"{covered} never bare (the shared silhouette)")


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    frames = {L: Image.open(p).convert("RGB") for L, p in FRAMES.items()}
    wall = Image.open(WALL).convert("RGB")
    base = frames["A"].copy()

    # -- the group leader's kit and the header text are per-group: clear the kit to the
    #    desktop, and let the per-letter plate cover the text.
    x, y, w, h = HDR_KIT
    paste_from(base, wall, x, y, w, h)
    _recover_leader_backdrop(base, frames)

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

    # -- the kit-well outline-pass overlays (see the WELL_IDS block).
    for (row, side), spec in WELL_IDS.items():
        wx, wy = spec["xy"]
        cells = []
        for L, cid in spec["ids"].items():
            sp = Image.open(ROOT / f"app/art/kits/ridi/{cid}.png").convert("RGBA")
            sil, col = set(), {}
            for sy in range(sp.height):
                for sx in range(sp.width):
                    r, g, b, a = sp.getpixel((sx, sy))
                    if a >= 128:
                        sil.add((sx, sy))
                        col[(sx, sy)] = (r, g, b)
            cells.append((frames[L], sil, col))
        under = Image.new("RGBA", (KIT_W, KIT_H), (0, 0, 0, 0))
        over = Image.new("RGBA", (KIT_W, KIT_H), (0, 0, 0, 0))
        n_u = n_o = 0
        for ry in range(KIT_H):
            for rx in range(KIT_W):
                vals = {fr.getpixel((wx + rx, wy + ry)) for fr, _s, _c in cells}
                if len(vals) != 1:
                    continue
                c = vals.pop()
                covered = [((rx, ry) in sil, col.get((rx, ry))) for _f, sil, col in cells]
                if not any(cov for cov, _ in covered):
                    if c != wall.getpixel((wx + rx, wy + ry)):
                        under.putpixel((rx, ry), (*c, 255))
                        n_u += 1
                elif any(cov and sc != c for cov, sc in covered):
                    over.putpixel((rx, ry), (*c, 255))
                    n_o += 1
        under.save(OUT / f"well_under_{row}_{side}.png")
        over.save(OUT / f"well_over_{row}_{side}.png")
        print(
            f"well_under/over_{row}_{side}.png <- 6 witnessed cells ({n_u} under + {n_o} over px)"
        )

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
