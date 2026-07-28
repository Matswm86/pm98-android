#!/usr/bin/env python3
"""Bake the RESULTS -> <cup> KNOCKOUT views' static chrome out of real MANAGER.EXE frames.

Doctrine, as everywhere in this repo: static pixels are the ORIGINAL's own, cut verbatim
from a live frame; every cell a career fills is redrawn by `app/scenes/KnockoutScreen.gd`.

The original does not have "a knockout screen" -- it switches presentation with the size of
the round and the column set with the competition (`docs/re/knockout_views_re.md`). This
baker covers the LIST forms, which is where every round of nine ties or more lands.

## Why the competition band is cut whole, per competition

The band (trophy + white name plate + phase paginator) is NOT placed by a rule this port
can state: measured over eight frames its outer box is x69..365 for EURO. LEAGUE in the
list layouts, x28..324 for the same competition in the bracket layouts, and x71..428 for
F.A. Cup / Coca-Cola / U.E.F.A. / Cup Winner's in BOTH -- three placements that no width of
the name, the label or the panel accounts for. Rather than invent the rule, each witnessed
(competition, layout family) pair is cut verbatim as a full-width strip; the only thing the
app redraws inside it is the phase label and the two arrow buttons, whose positions are
recorded per strip in `bands.json`.

Sources (all under tools/re/refs/, because screenshots/ is gitignored)
  knockout-2026-07-26/06_euroleague_round1_played.png    compact list, EUROPEAN, 15 ties
  knockout-2026-07-26/01_facup_r2_PLAYED_1997-12-14.png  compact list, DOMESTIC, scrolled
  knockout-2026-07-26/09_comp_cwc.png                    kit list, EUROPEAN, 8 ties, drawn
  knockout-2026-07-26/01_uefa_1_8finals_leg1_played_1997-12-07.png
                                                         kit list, EUROPEAN, leg 1 played
  knockout-2026-07-26/13_cocacola_r4_KITLIST_PLAYED_1997-12-01.png
                                                         kit list, DOMESTIC, played
  knockout-2026-07-26/09_comp_*.png                      one frame per competition
  euroleague-group-2026-07-26/01_results_premier_empty_body.png   the RESULTS desktop

Outputs -> app/art/screens/knockout/
  desktop.png            640x480, the RESULTS screen with no competition body on it
  band_<comp>_<fam>.png  the competition band strip, phase-label plate blanked
  bands.json             per strip: its origin, its label plate and its two arrow buttons
  pager_*.png            the four arrow-button faces (left/right x enabled/disabled)
  list_hdr_euro.png      compact-list panel top: border + gradient band + the column titles
  list_hdr_dom.png       ... with RES. / REPLAY instead
  scroll_col.png         the scrollbar column (arrows + trough) with the thumb painted out
  scroll_thumb_tile.png  one row of the thumb bitmap, tiled to the computed length
  kitlist_hdr_<set>.png  the KIT LIST panel top (border + title band + the column titles);
                         its panel is x6..493 -- WIDER than the compact list's x6..477,
                         because a round this small never scrolls and the scrollbar column
                         is simply part of the panel
  kitlist_row_<set>.png  one 30-row KIT LIST unit: the black rule, the 22-row content band
                         and the 6 white rows + rule that separate it from the next. Cut
                         from a witnessed row with its content rects blanked; legal because
                         the layout does NOT alternate its row grounds (every one of the 24
                         witnessed rows carries the same five grounds) and the three
                         witnessed frames -- two competitions, two careers, both column
                         sets -- are byte-identical outside those rects
  kitlist_foot_<set>.png the panel tail under the last row (10 white rows + the 2-row
                         bottom border)
  kitwell_kl_*_p<0|1>.png the kit wells' outline pass, voted per ABSOLUTE SCREEN
                         PARITY -- the pass is dithered exactly like the pager arrows
  bracket_panel_euro.png one 458x72 BRACKET panel strip, European columns, the six content
                         rects blanked (tools/re/verify_bracket_split.py proves 16 panels
                         over 4 frames are byte-identical outside them)
  bracket_panel_dom.png  ... domestic columns (RES. / REPLAY at their own x positions --
                         NOT the European slots minus one; 8 panels over 2 frames)
  band_euro_cards.png    the CARDS-family band (semifinal cards AND the final share it:
  band_cocacola_cards.png  the euro final band differs from the euro semis band in the
                         label pixels ONLY, 292 px, measured 2026-07-27). The euro cards
                         band is byte-identical to the euro BRACKET band outside the plate
                         and arrows (0 px); the cocacola cards band is NOT (its own strip,
                         trophy lower, plate at (336,87)). F.A. Cup / U.E.F.A. / Cup
                         Winner's semifinals were never photographed, so those comps have
                         no cards band and fall back to the SORTEO -- an honest gap.
  cards_body.png         the two SEMIFINAL cards, x0..499 y120..427, cut from the witnessed
                         Coca-Cola frame -- legal for BOTH column sets because the euro and
                         cocacola cards frames are byte-identical below the band outside
                         the content rects (measured 2026-07-27: only the venue texts, club
                         rows and band tail differ across 3 frames / 2 competitions / 2
                         careers). Venue texts blanked to the row's black, club bars to
                         their per-card grounds, score boxes to their per-card grounds.
  final_body_euro.png    the FINAL view's body (trophy + RESULTS card + WINNER band),
                         x0..499 y120..427 from the witnessed euro final. The card + winner
                         band chrome is byte-identical to 09_comp_charity's outside the
                         content rects (0 px, measured 2026-07-27), so the redraw grammar
                         is CompResultScreen's witnessed one. Only the euro final is
                         witnessed -- the other competitions' final bodies (their trophies)
                         are honest gaps that fall back to the SORTEO.
"""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
REFS = ROOT / "tools/re/refs/knockout-2026-07-26"
WALL = ROOT / "tools/re/refs/euroleague-group-2026-07-26/01_results_premier_empty_body.png"
OUT = ROOT / "app/art/screens/knockout"

# ------------------------------------------------------------------ measured geometry
# Every span is an inclusive pixel row/column read off the frames named above; the
# derivations are in docs/re/knockout_views_re.md "Geometry banked 2026-07-26".

PANEL_X = (6, 477)
LIST_HDR_Y = (125, 153)  # panel top border + the gradient title band + its underline

BAND_Y = (64, 124)  # the strip the competition band paints into, list family
BAND_X = (0, 503)  # full width up to the rail, so exposed desktop comes along

# The phase-label plate and the two arrow buttons inside each band, measured per frame.
# `plate` is the label plate's interior (blanked here, redrawn by the app);
# `left` / `right` are the arrow buttons' top-left corners.
BANDS = {
    ("euro", "list"): {
        "frame": "06_euroleague_round1_played.png",
        "plate": (254, 88, 338, 108),
        "left": (230, 88),
        "right": (340, 88),
    },
    ("facup", "list"): {
        "frame": "03_facup_r3_drawn_UNPLAYED_1997-12-20.png",
        "plate": (315, 88, 399, 108),
        "left": (291, 88),
        "right": (401, 88),
    },
    ("cocacola", "list"): {
        "frame": "09_comp_cocacola.png",
        "plate": (315, 88, 399, 108),
        "left": (291, 88),
        "right": (401, 88),
    },
    ("uefa", "list"): {
        "frame": "09_comp_uefa.png",
        "plate": (315, 88, 399, 108),
        "left": (291, 88),
        "right": (401, 88),
    },
    ("cwc", "list"): {
        "frame": "09_comp_cwc.png",
        "plate": (315, 88, 399, 108),
        "left": (291, 88),
        "right": (401, 88),
    },
    # The BRACKET family sits one band lower (the panel starts at y113, not 125) and the
    # euro plate one row lower still than everyone else's -- both measured, not derived
    # (docs/re/knockout_views_re.md "The bracket, re-measured 2026-07-26").
    ("euro", "bracket"): {
        "frame": "02_euroleague_qtrfinals_UNPLAYED_1998-01.png",
        "plate": (213, 79, 297, 99),
        "left": (189, 79),
        "right": (299, 79),
    },
    ("facup", "bracket"): {
        "frame": "08_facup_qtrfinals_DOMESTIC_bracket_unplayed_1999-03-04.png",
        "plate": (315, 78, 399, 98),
        "left": (291, 78),
        "right": (401, 78),
    },
    ("cocacola", "bracket"): {
        "frame": "12_cocacola_qtr_bracket_DOMESTIC_probe0116.png",
        "plate": (315, 78, 399, 98),
        "left": (291, 78),
        "right": (401, 78),
    },
    ("uefa", "bracket"): {
        "frame": "11_uefa_qtr_bracket_UNPLAYED_probe0116.png",
        "plate": (315, 78, 399, 98),
        "left": (291, 78),
        "right": (401, 78),
    },
    ("cwc", "bracket"): {
        "frame": "10_cwc_qtr_bracket_UNPLAYED_probe0116.png",
        "plate": (315, 78, 399, 98),
        "left": (291, 78),
        "right": (401, 78),
    },
    # The CARDS family (semifinal cards + the final -- the euro final band differs from the
    # euro semis band in the 292 label pixels only). Euro: plate + arrows at the euro
    # BRACKET positions (byte-identical outside them, 0 px). Cocacola: its own strip --
    # plate interior (336,87)..(420,107), arrows left_on at (312,87) / right_off_p1 at
    # (422,87), both EXACT matches of the already-baked pager faces. The strip runs to
    # y119: the cocacola trophy bottom reaches y117 where the euro band stops at y110.
    ("euro", "cards"): {
        "frame": "09_euroleague_semifinals_DRAWN_unplayed_1999-03-27.png",
        "plate": (213, 79, 297, 99),
        "left": (189, 79),
        "right": (299, 79),
    },
    ("cocacola", "cards"): {
        "frame": "06_cocacola_semifinals_drawn_1998-01-10.png",
        "plate": (336, 87, 420, 107),
        "left": (312, 87),
        "right": (422, 87),
    },
}
PLATE_BG = (180, 200, 220)

# ---- the SEMIFINAL cards body (docs/re/knockout_views_re.md, measured 2026-07-27) ----
# One strip serves both column sets: the euro (04/09) and cocacola (06) cards frames are
# byte-identical below y119 outside the content rects (2 competitions, 2 careers). Cut
# from the cocacola frame because it is fully UNPLAYED (every score box empty).
CARDS_SRC = "06_cocacola_semifinals_drawn_1998-01-10.png"
CARDS_STRIP = (0, 120, 499, 427)
# The two cards' content rects, absolute frame coords. Venue rows are black grounds with
# the venue name left-aligned at pen x33/x291 (leftmost ink identical across all three
# witnessed frames); the static venue icon left of the text is chrome and stays.
CARDS_VENUE_TXT = [
    (33, 190, 227, 208),
    (291, 190, 485, 208),
    (33, 282, 227, 300),
    (291, 282, 485, 300),
]
CARDS_BAR_ROWS = [(209, 228), (231, 250), (301, 320), (323, 342)]
CARDS_SF1_BAR = (12, 188)
CARDS_SF1_BOX = (191, 226)
CARDS_SF2_BAR = (270, 446)
CARDS_SF2_BOX = (449, 484)
CARDS_SF1_BAR_BG = (200, 220, 240)
CARDS_SF1_BOX_BG = (42, 63, 170)
CARDS_SF2_BAR_BG = (192, 220, 192)
CARDS_SF2_BOX_BG = (80, 110, 5)

# ---- the FINAL body (euro only -- the one witnessed final) --------------------------
FINAL_SRC = "05_euroleague_final_UNDECIDED_1998-04-25.png"
FINAL_STRIP = (0, 120, 499, 427)
# Content rects, all blanked to the ground the ring around them proves: the kit wells and
# flag boxes sit on white / inside black borders the 30x20 dbcard flag covers exactly; the
# STADIUM value line ("Das Antas", ink (17,90,34), bbox x201..283 y241..249) sits on the
# card's white; the club-name bars are (200,220,240) rows y267..286 / y298..317 with ink
# (80,100,120) only. Score boxes, WINNER bar and laurel are empty in the witness already.
FINAL_WHITE = [
    (146, 158, 193, 217),
    (306, 158, 353, 217),  # kit wells
    (199, 163, 228, 182),
    (270, 163, 299, 182),  # flag boxes
    (150, 238, 355, 252),
]  # stadium value line
FINAL_BARS = [(150, 267, 304, 286), (150, 298, 304, 317)]  # club-name bar interiors
FINAL_BAR_BG = (200, 220, 240)

# ---- the BRACKET panel strip (docs/re/knockout_views_re.md, re-measured 2026-07-26) ----
# Four panels at T = 113/193/273/353, each x20..477. One strip per column set is cut from
# one witnessed UNPLAYED panel and repeated four times -- legal because
# verify_bracket_split.py proves 20 panels over 6 frames byte-identical outside the six
# content rects below. The rects are blanked to the ground the app draws over: kits to the
# panel's white, flags + name bars to the bar ground (flags are 30x20 blits that cover
# their cell exactly, so the blank never shows).
BRACKET_X = (20, 477)
BRACKET_SRC = {
    "euro": ("02_euroleague_qtrfinals_UNPLAYED_1998-01.png", 113),
    "dom": ("08_facup_qtrfinals_DOMESTIC_bracket_unplayed_1999-03-04.png", 113),
}
BRACKET_KITS = [(22, 2, 81, 69), (416, 2, 475, 69)]  # -> white
BRACKET_BARS = [
    (83, 7, 112, 26),
    (385, 7, 414, 26),  # flags
    (114, 7, 247, 26),
    (250, 7, 383, 26),
]  # name bars -> bar ground
BRACKET_WHITE = (255, 255, 255)
BRACKET_BAR_BG = (180, 200, 220)

# ---- the kit-well OVERLAYS: the outline/bevel pass, baked verbatim (2026-07-27) -----
# The s62 "un-reversed outline pass" turned out to be POSITION-CONSTANT: every MINIESC
# kit shares one silhouette, so the pass's result is the same pixels for every club --
# measured across all 16 witnessed bracket cells, the L column's outside-silhouette
# residual is 248 static px vs 9 club-varying, the R column's 211 vs 57. That makes it
# BAKEABLE, no rule needed: two layers per site, voted across every witnessed cell --
#   UNDER  every position outside ALL witnessed silhouettes where the frames agree on a
#          non-ground colour (the drop shadow + outer bevel ring);
#   OVER   every position where the frames agree AND at least one cell's sprite differs
#          there (the pass provably overrides club art at that position, and the result
#          is club-independent across 8-12 different kits).
# Applying them to unwitnessed clubs is the standing baked-chrome inference; clubs whose
# silhouette deviates from the shared one (e.g. Sporting Port.) keep a small residual,
# which is why the parity buckets stay declared.
# Cell inventories are transcribed off the frames (ids verified against each cell).
BRACKET_CELLS = {
    "L": {"win": (22, 2, 60, 68), "spr": (4, 6)},  # window x22..81, sprite at +({4},{6})
    "R": {"win": (416, 2, 60, 68), "spr": (7, 6)},  # window x416..475, sprite at (423,T+8)
}
BRACKET_TIES_IDS = {
    "03_euroleague_qtrfinals_LEG1_PLAYED_1998-03-14.png": [
        (1038, 40),
        (1189, 1000),
        (1003, 1042),
        (1024, 1076),
    ],
    "08_facup_qtrfinals_DOMESTIC_bracket_unplayed_1999-03-04.png": [
        (77, 45),
        (63, 40),
        (70, 46),
        (48, 57),
    ],
}
BRACKET_TOPS = [113, 193, 273, 353]
# The CARDS ridi icons: 17x20 windows at (13 / 271, bar_top), sprite at (0,0) in-window;
# grounds differ per card (SF1 (200,220,240) / SF2 (192,220,192)). 12 cells per side.
CARDS_ICON_FRAMES = {
    "06_cocacola_semifinals_drawn_1998-01-10.png": {
        "sf1": [80, 40, 40, 80],
        "sf2": [54, 66, 66, 54],
    },
    "04_euroleague_semifinals_LEG1_PLAYED_1998-04-04.png": {
        "sf1": [40, 1189, 1189, 40],
        "sf2": [1076, 1003, 1003, 1076],
    },
    "09_euroleague_semifinals_DRAWN_unplayed_1999-03-27.png": {
        "sf1": [1010, 1077, 1077, 1010],
        "sf2": [1104, 1058, 1058, 1104],
    },
}
CARDS_ICON_X = {"sf1": 13, "sf2": 271}
CARDS_ICON_TOPS = [209, 231, 301, 323]
CARDS_ICON_GROUND = {"sf1": (200, 220, 240), "sf2": (192, 220, 192)}

# The competition rail is cut WHOLE per competition, not composed. Its chips carry three
# witnessed states -- selected (a red plate), enabled (black plate, yellow text) and dimmed
# (drawn through to the wallpaper) -- and WHICH competitions are dimmed is a career state
# this port does not model, exactly as ResultsScreen records for its own rail. So the rail
# is the witness's, taken from the same frame as that competition's band.
RAIL_RECT = (500, 110, 639, 430)

# The chips themselves: x506..621, 29 px tall, pitched 27 with a 37 px gap before EURO.
# Only the hit test uses these now.
CHIP_X = (506, 621)
CHIP_H = 29
CHIP_TOP = {
    "facup": 118,
    "cocacola": 145,
    "charity": 172,
    "euro": 209,
    "cwc": 236,
    "uefa": 263,
    "supercup": 290,
    "intercont": 317,
}
COMP_FRAME = {
    "facup": "09_comp_facup.png",
    "cocacola": "09_comp_cocacola.png",
    "charity": "09_comp_charity.png",
    "euro": "09_comp_euro.png",
    "cwc": "09_comp_cwc.png",
    "uefa": "09_comp_uefa.png",
    "supercup": "09_comp_supercup.png",
    "intercont": "09_comp_intercont.png",
}

# ---- the KIT LIST (layout 2), measured 2026-07-28 on three frames -------------------
# Every span below is an inclusive pixel row/column read off
#   09_comp_cwc.png                              European, 8 ties, all cells empty
#   01_uefa_1_8finals_leg1_played_1997-12-07.png European, 8 ties, 1ST LEG filled
#   13_cocacola_r4_KITLIST_PLAYED_1997-12-01.png DOMESTIC, 8 ties, RES. filled + winners
# and reproduced in docs/re/knockout_views_re.md "The kit list, as built".
KL_PANEL_X = (6, 493)  # WIDER than the compact list: this layout never scrolls
KL_HDR_Y = (125, 153)  # border + title band + the white gap + the first row rule
KL_ROW_Y = (154, 183)  # one unit: 22 content rows, the rule, 6 white rows, the next rule
KL_ROW_H = 22
KL_PITCH = 30
KL_FOOT_Y = (386, 398)  # the rule under the last row, 10 white rows, the 2-row border
# Cells, inclusive x spans, in draw order: kit L, home, away, kit R, then the score cells.
KL_CELLS = {
    "euro": [(15, 42), (44, 164), (167, 287), (289, 316), (319, 372), (374, 427), (429, 482)],
    "dom": [(15, 42), (44, 192), (195, 342), (344, 371), (374, 427), (429, 482)],
}
KL_WELL_BG = (140, 160, 180)
KL_NAME_BG = (100, 120, 140)
KL_SCORE_BG = (120, 120, 160)
KL_LAST_BG = (100, 100, 140)
KL_SRC = {
    "euro": ("09_comp_cwc.png", 154),
    "dom": ("13_cocacola_r4_KITLIST_PLAYED_1997-12-01.png", 154),
}
KL_HDR_SRC = {"euro": "09_comp_cwc.png", "dom": "13_cocacola_r4_KITLIST_PLAYED_1997-12-01.png"}
# The 17x20 ridi kit sits at (+5, +1) inside its 28x22 well -- the unique best offset on
# all 48 witnessed cells (each reproduces ~188/221 opaque px; the residual is the same
# outline pass the bracket and the cards carry, voted into overlays below).
KL_SPR = (5, 1)
KL_TOPS = [154 + KL_PITCH * i for i in range(8)]
KL_CELL_IDS = {
    "01_uefa_1_8finals_leg1_played_1997-12-07.png": (
        "euro",
        [
            (1027, 1062),
            (1260, 1107),
            (1112, 1071),
            (1058, 1051),
            (1047, 1147),
            (1001, 1023),
            (57, 1103),
            (1141, 1032),
        ],
    ),
    "09_comp_cwc.png": (
        "euro",
        [
            (1171, 1125),
            (1138, 1033),
            (1101, 1144),
            (1188, 1270),
            (1015, 1068),
            (1080, 49),
            (1048, 1105),
            (1224, 1199),
        ],
    ),
    "13_cocacola_r4_KITLIST_PLAYED_1997-12-01.png": (
        "dom",
        [(63, 60), (76, 66), (53, 61), (75, 71), (80, 56), (46, 47), (40, 41), (54, 83)],
    ),
}

# The scrollbar column, present only when the list is longer than the panel.
SCROLL_X = (478, 493)
SCROLL_Y = (125, 410)
THUMB_TROUGH = (172, 394)  # the trough's interior, measured on 01_facup_r2
THUMB_ROW_Y = 250  # a row safely inside the thumb bitmap

# The empty-body RESULTS frame still carries the MATCHES ON band's right end at x478..509,
# which no knockout layout covers. Patch it from a 16-row list frame, where that column is
# bare wallpaper.
DESK_PATCH = (478, 118, 509, 186)
# It also carries a 6 px-wide fragment at x14..19, y125..177 that every LIST panel covers
# (panel x6..477) but the narrower BRACKET panel (x20..477) exposes. Both bracket witnesses
# show plain wallpaper there (frames 02/03/08 byte-identical over x0..19, y113..185), so it
# is patched from the euro QTR frame.
DESK_LEFT = (14, 125, 19, 177)
# The division chips are all UNLIT on a knockout view -- none of the four divisions is what
# the body is showing -- so they come from a knockout frame, not from the league RESULTS
# frame the desktop is otherwise cut from (where PREMIER LEAGUE is lit).
DESK_DIVS = (0, 428, 503, 470)


def cut(im: Image.Image, box: tuple[int, int, int, int]) -> Image.Image:
    """Inclusive-span crop, so the numbers in this file read like the measurements."""
    x0, y0, x1, y1 = box
    return im.crop((x0, y0, x1 + 1, y1 + 1))


def frame(name: str) -> Image.Image:
    return Image.open(REFS / name).convert("RGB").crop((0, 0, 640, 480))


def _sprite_maps(png: Path, ox: int, oy: int) -> tuple[set, dict]:
    """A sprite's opaque positions + colours, keyed by in-window coordinates."""
    sp = Image.open(png).convert("RGBA")
    sil: set = set()
    col: dict = {}
    for sy in range(sp.height):
        for sx in range(sp.width):
            r, g, b, a = sp.getpixel((sx, sy))
            if a >= 128:
                sil.add((ox + sx, oy + sy))
                col[(ox + sx, oy + sy)] = (r, g, b)
    return sil, col


def _overlay_vote(cells: list, ww: int, wh: int, ground: tuple) -> tuple:
    """Vote the outline pass across witnessed cells (see the OVERLAYS header block).

    cells: (frame, win_x, win_y, silhouette, sprite_colours) per witnessed cell.
    Returns (under RGBA, over RGBA, n_under, n_over).
    """
    under = Image.new("RGBA", (ww, wh), (0, 0, 0, 0))
    over = Image.new("RGBA", (ww, wh), (0, 0, 0, 0))
    n_under = n_over = 0
    for ry in range(wh):
        for rx in range(ww):
            vals = {fr.getpixel((wx + rx, wy + ry)) for fr, wx, wy, _s, _c in cells}
            if len(vals) != 1:
                continue  # club-varying -> stays the sprite's own (bucketed residual)
            c = vals.pop()
            covered = [((rx, ry) in sil, col.get((rx, ry))) for _f, _x, _y, sil, col in cells]
            if not any(cov for cov, _ in covered):
                if c != ground:
                    under.putpixel((rx, ry), (*c, 255))
                    n_under += 1
            elif any(cov and sc != c for cov, sc in covered):
                over.putpixel((rx, ry), (*c, 255))
                n_over += 1
    return under, over, n_under, n_over


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    comps = {k: frame(v) for k, v in COMP_FRAME.items()}
    list_euro = frame("06_euroleague_round1_played.png")
    list_dom = frame("01_facup_r2_PLAYED_1997-12-14.png")
    no_scroll = frame("05_euroleague_round2_undrawn.png")

    # -- the desktop: the RESULTS screen with no competition body on it.
    desk = Image.open(WALL).convert("RGB").crop((0, 0, 640, 480))
    desk.paste(cut(no_scroll, DESK_PATCH), (DESK_PATCH[0], DESK_PATCH[1]))
    desk.paste(cut(no_scroll, DESK_DIVS), (DESK_DIVS[0], DESK_DIVS[1]))
    euro_qtr = frame("02_euroleague_qtrfinals_UNPLAYED_1998-01.png")
    desk.paste(cut(euro_qtr, DESK_LEFT), (DESK_LEFT[0], DESK_LEFT[1]))
    # An all-unlit rail: F.A. Cup's unlit face comes from the U.E.F.A. frame, the rest from
    # the F.A. Cup frame -- so every chip is the original's own, in its unlit state.
    desk.paste(
        cut(
            comps["facup"],
            (CHIP_X[0], CHIP_TOP["cocacola"], CHIP_X[1], CHIP_TOP["intercont"] + CHIP_H - 1),
        ),
        (CHIP_X[0], CHIP_TOP["cocacola"]),
    )
    desk.paste(
        cut(
            comps["uefa"], (CHIP_X[0], CHIP_TOP["facup"], CHIP_X[1], CHIP_TOP["facup"] + CHIP_H - 1)
        ),
        (CHIP_X[0], CHIP_TOP["facup"]),
    )
    desk.convert("RGBA").save(OUT / "desktop.png")
    print("desktop.png <- the empty-body RESULTS frame + an all-unlit rail")

    # -- the rail, one per competition, from that competition's LIST-family frame. The
    #    bracket witnesses carry the same rails 0 px (frames 08/10/11/12, checked
    #    2026-07-26) EXCEPT the euro pair 02/03: by March that career's cwc/uefa/supercup
    #    chips have changed lit-state. WHICH chips are lit is career state this port does
    #    not model, so the euro-bracket parity case buckets the rail rather than cutting
    #    a second, equally-arbitrary rail state.
    rails = 0
    for (comp, fam), spec in BANDS.items():
        if fam != "list":
            continue
        cut(frame(spec["frame"]), RAIL_RECT).save(OUT / f"rail_{comp}.png")
        rails += 1
    print(f"rail_*.png <- {rails} witnessed competition frames")

    # -- the arrow buttons, both states. The QTR FINALS frame has the left one ENABLED and
    #    the right DISABLED; a ROUND 1 frame has it the other way round, so all four faces
    #    are the original's own rather than a mirror of one another.
    qtr = frame("02_euroleague_qtrfinals_UNPLAYED_1998-01.png")
    # The DISABLED faces carry a two-colour checkerboard whose phase follows the button's
    # ABSOLUTE screen parity: the same disabled right arrow differs in 76 px between
    # (299,79) and (401,88), every one of them a symmetric swap of one of five colour
    # pairs. So both parities are cut from real frames rather than generated. The ENABLED
    # faces are not dithered -- the enabled left arrow is 0 px different between those same
    # two parities -- so one cut serves both (the enabled RIGHT arrow has no odd-parity
    # witness; it is the same sprite mirrored, and is taken to be dither-free like its
    # twin. That is the one inference in this file.)
    facup_r3 = frame("03_facup_r3_drawn_UNPLAYED_1997-12-20.png")
    cut(qtr, (189, 79, 211, 99)).save(OUT / "pager_left_on.png")
    cut(list_euro, (340, 88, 362, 108)).save(OUT / "pager_right_on.png")
    cut(list_euro, (230, 88, 252, 108)).save(OUT / "pager_left_off_p0.png")
    cut(comps["facup"], (291, 88, 313, 108)).save(OUT / "pager_left_off_p1.png")
    cut(qtr, (299, 79, 321, 99)).save(OUT / "pager_right_off_p0.png")
    cut(facup_r3, (401, 88, 423, 108)).save(OUT / "pager_right_off_p1.png")
    print("pager_*.png <- QTR FINALS + ROUND 1 + F.A. Cup frames, both dither parities")

    # -- the competition bands, cut whole with the label plate blanked. The bracket
    #    family's strip stops at y112 -- its panel starts at 113 where the list's starts
    #    at 125.
    meta = {}
    for (comp, fam), spec in BANDS.items():
        im = frame(spec["frame"]).copy()
        px0, py0, px1, py1 = spec["plate"]
        for y in range(py0, py1 + 1):
            for x in range(px0, px1 + 1):
                im.putpixel((x, y), PLATE_BG)
        y1 = 112 if fam == "bracket" else (119 if fam == "cards" else BAND_Y[1])
        cut(im, (BAND_X[0], BAND_Y[0], BAND_X[1], y1)).save(OUT / f"band_{comp}_{fam}.png")
        meta[f"{comp}_{fam}"] = {
            "origin": [BAND_X[0], BAND_Y[0]],
            "plate": list(spec["plate"]),
            "left": list(spec["left"]),
            "right": list(spec["right"]),
        }
    (OUT / "bands.json").write_text(json.dumps(meta, indent=1, sort_keys=True) + "\n")
    print(f"band_*.png + bands.json <- {len(BANDS)} witnessed (competition, layout) pairs")

    # -- the BRACKET panel strips, one per column set, content blanked.
    for fam, (src, top) in BRACKET_SRC.items():
        strip = cut(frame(src), (BRACKET_X[0], top, BRACKET_X[1], top + 71))
        for x0, dy0, x1, dy1 in BRACKET_KITS:
            for y in range(dy0, dy1 + 1):
                for x in range(x0 - BRACKET_X[0], x1 - BRACKET_X[0] + 1):
                    strip.putpixel((x, y), BRACKET_WHITE)
        for x0, dy0, x1, dy1 in BRACKET_BARS:
            for y in range(dy0, dy1 + 1):
                for x in range(x0 - BRACKET_X[0], x1 - BRACKET_X[0] + 1):
                    strip.putpixel((x, y), BRACKET_BAR_BG)
        strip.save(OUT / f"bracket_panel_{fam}.png")
    print("bracket_panel_euro.png + bracket_panel_dom.png <- two witnessed UNPLAYED panels")

    # -- the kit-well outline-pass overlays (see the OVERLAYS header block).
    for side, spec in BRACKET_CELLS.items():
        wx0, wy0, ww, wh = spec["win"]
        ox, oy = spec["spr"]
        cells = []
        for fname, ties in BRACKET_TIES_IDS.items():
            fr = frame(fname)
            for i, pair in enumerate(ties):
                cid = pair[0] if side == "L" else pair[1]
                sil, col = _sprite_maps(ROOT / f"app/art/kits/{cid}.png", ox, oy)
                cells.append((fr, wx0, BRACKET_TOPS[i] + wy0, sil, col))
        under, over, nu, no = _overlay_vote(cells, ww, wh, BRACKET_WHITE)
        under.save(OUT / f"kitwell_under_{side}.png")
        over.save(OUT / f"kitwell_over_{side}.png")
        print(
            f"kitwell_under/over_{side}.png <- {len(cells)} witnessed cells "
            f"({nu} under + {no} over px)"
        )
    for card, ground in CARDS_ICON_GROUND.items():
        cells = []
        for fname, sides in CARDS_ICON_FRAMES.items():
            fr = frame(fname)
            for i, cid in enumerate(sides[card]):
                sil, col = _sprite_maps(ROOT / f"app/art/kits/ridi/{cid}.png", 0, 0)
                cells.append((fr, CARDS_ICON_X[card], CARDS_ICON_TOPS[i], sil, col))
        under, over, nu, no = _overlay_vote(cells, 17, 20, ground)
        under.save(OUT / f"icon_under_{card}.png")
        over.save(OUT / f"icon_over_{card}.png")
        print(
            f"icon_under/over_{card}.png <- {len(cells)} witnessed cells "
            f"({nu} under + {no} over px)"
        )

    # -- the SEMIFINAL cards body, one strip for both column sets (see the header).
    cards = frame(CARDS_SRC).copy()
    for x0, y0, x1, y1 in CARDS_VENUE_TXT:
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                cards.putpixel((x, y), (0, 0, 0))
    for ry0, ry1 in CARDS_BAR_ROWS:
        for bar, bar_bg, box, box_bg in [
            (CARDS_SF1_BAR, CARDS_SF1_BAR_BG, CARDS_SF1_BOX, CARDS_SF1_BOX_BG),
            (CARDS_SF2_BAR, CARDS_SF2_BAR_BG, CARDS_SF2_BOX, CARDS_SF2_BOX_BG),
        ]:
            for y in range(ry0, ry1 + 1):
                for x in range(bar[0], bar[1] + 1):
                    cards.putpixel((x, y), bar_bg)
                for x in range(box[0], box[1] + 1):
                    cards.putpixel((x, y), box_bg)
    cut(cards, CARDS_STRIP).save(OUT / "cards_body.png")
    print("cards_body.png <- the witnessed Coca-Cola SEMIFINALS frame, content blanked")

    # -- the FINAL body, euro only (the one witnessed final).
    fin = frame(FINAL_SRC).copy()
    for x0, y0, x1, y1 in FINAL_WHITE:
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                fin.putpixel((x, y), (255, 255, 255))
    for x0, y0, x1, y1 in FINAL_BARS:
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                fin.putpixel((x, y), FINAL_BAR_BG)
    cut(fin, FINAL_STRIP).save(OUT / "final_body_euro.png")
    print("final_body_euro.png <- the witnessed euro FINAL frame, content blanked")

    # -- the two compact-list header bands.
    cut(list_euro, (PANEL_X[0], LIST_HDR_Y[0], PANEL_X[1], LIST_HDR_Y[1])).save(
        OUT / "list_hdr_euro.png"
    )
    cut(list_dom, (PANEL_X[0], LIST_HDR_Y[0], PANEL_X[1], LIST_HDR_Y[1])).save(
        OUT / "list_hdr_dom.png"
    )
    print("list_hdr_euro.png + list_hdr_dom.png <- two witnessed panel tops")

    # -- the KIT LIST: panel top, one repeating row unit, the foot, and the well overlays.
    for cset, src in KL_HDR_SRC.items():
        cut(frame(src), (KL_PANEL_X[0], KL_HDR_Y[0], KL_PANEL_X[1], KL_HDR_Y[1])).save(
            OUT / f"kitlist_hdr_{cset}.png"
        )
    print("kitlist_hdr_euro.png + kitlist_hdr_dom.png <- the two witnessed panel tops")
    for cset, (src, top) in KL_SRC.items():
        row = cut(frame(src), (KL_PANEL_X[0], top, KL_PANEL_X[1], top + KL_PITCH - 1))
        cells = KL_CELLS[cset]
        for j, (x0, x1) in enumerate(cells):
            bg = KL_WELL_BG if j in (0, 3) else KL_NAME_BG
            if j > 3:
                bg = KL_LAST_BG if j == len(cells) - 1 else KL_SCORE_BG
            for y in range(KL_ROW_H):
                for x in range(x0 - KL_PANEL_X[0], x1 - KL_PANEL_X[0] + 1):
                    row.putpixel((x, y), bg)
        row.save(OUT / f"kitlist_row_{cset}.png")
        cut(frame(src), (KL_PANEL_X[0], KL_FOOT_Y[0], KL_PANEL_X[1], KL_FOOT_Y[1])).save(
            OUT / f"kitlist_foot_{cset}.png"
        )
    print("kitlist_row_*.png + kitlist_foot_*.png <- one witnessed row unit + the tail")
    # The pass is DITHERED against absolute screen parity -- the same rule the paginator
    # arrows carry. Proof: the left well (x15) and the EUROPEAN right well (x289) are both
    # odd and agree pixel for pixel across all three frames, while the DOMESTIC right well
    # (x344, even) disagrees with them at 222 of the well's 616 positions. So the overlay
    # is voted per parity, not per side, and every cell of a parity votes together.
    buckets: dict[int, list] = {}
    for fname, (cset, ties) in KL_CELL_IDS.items():
        fr = frame(fname)
        for slot, which in ((0, 0), (3, 1)):
            wx0 = KL_CELLS[cset][slot][0]
            for i, pair in enumerate(ties):
                sil, col = _sprite_maps(ROOT / f"app/art/kits/ridi/{pair[which]}.png", *KL_SPR)
                buckets.setdefault((wx0 + KL_TOPS[i]) & 1, []).append(
                    (fr, wx0, KL_TOPS[i], sil, col)
                )
    for par, cells in sorted(buckets.items()):
        under, over, nu, no = _overlay_vote(cells, 28, KL_ROW_H, KL_WELL_BG)
        under.save(OUT / f"kitwell_kl_under_p{par}.png")
        over.save(OUT / f"kitwell_kl_over_p{par}.png")
        print(
            f"kitwell_kl_under/over_p{par}.png <- {len(cells)} witnessed cells "
            f"({nu} under + {no} over px)"
        )

    # -- the scrollbar: the column with the thumb painted out, plus one row of the thumb.
    col = cut(list_dom, (SCROLL_X[0], SCROLL_Y[0], SCROLL_X[1], SCROLL_Y[1]))
    trough_row = col.crop(
        (0, THUMB_TROUGH[1] - SCROLL_Y[0] + 4, col.width, THUMB_TROUGH[1] - SCROLL_Y[0] + 5)
    )
    for y in range(THUMB_TROUGH[0] - SCROLL_Y[0], THUMB_TROUGH[1] - SCROLL_Y[0] + 1):
        col.paste(trough_row, (0, y))
    col.save(OUT / "scroll_col.png")
    cut(list_dom, (SCROLL_X[0], THUMB_ROW_Y, SCROLL_X[1], THUMB_ROW_Y)).save(
        OUT / "scroll_thumb_tile.png"
    )
    print("scroll_col.png + scroll_thumb_tile.png <- the F.A. Cup R2 frame")


if __name__ == "__main__":
    main()
