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
  bracket_panel_euro.png one 458x72 BRACKET panel strip, European columns, the six content
                         rects blanked (tools/re/verify_bracket_split.py proves 16 panels
                         over 4 frames are byte-identical outside them)
  bracket_panel_dom.png  ... domestic columns (RES. / REPLAY at their own x positions --
                         NOT the European slots minus one; 8 panels over 2 frames)
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
LIST_HDR_Y = (125, 153)     # panel top border + the gradient title band + its underline

BAND_Y = (64, 124)          # the strip the competition band paints into, list family
BAND_X = (0, 503)           # full width up to the rail, so exposed desktop comes along

# The phase-label plate and the two arrow buttons inside each band, measured per frame.
# `plate` is the label plate's interior (blanked here, redrawn by the app);
# `left` / `right` are the arrow buttons' top-left corners.
BANDS = {
    ("euro", "list"): {"frame": "06_euroleague_round1_played.png",
                       "plate": (254, 88, 338, 108), "left": (230, 88), "right": (340, 88)},
    ("facup", "list"): {"frame": "03_facup_r3_drawn_UNPLAYED_1997-12-20.png",
                        "plate": (315, 88, 399, 108), "left": (291, 88), "right": (401, 88)},
    ("cocacola", "list"): {"frame": "09_comp_cocacola.png",
                           "plate": (315, 88, 399, 108), "left": (291, 88), "right": (401, 88)},
    ("uefa", "list"): {"frame": "09_comp_uefa.png",
                       "plate": (315, 88, 399, 108), "left": (291, 88), "right": (401, 88)},
    ("cwc", "list"): {"frame": "09_comp_cwc.png",
                      "plate": (315, 88, 399, 108), "left": (291, 88), "right": (401, 88)},
    # The BRACKET family sits one band lower (the panel starts at y113, not 125) and the
    # euro plate one row lower still than everyone else's -- both measured, not derived
    # (docs/re/knockout_views_re.md "The bracket, re-measured 2026-07-26").
    ("euro", "bracket"): {"frame": "02_euroleague_qtrfinals_UNPLAYED_1998-01.png",
                          "plate": (213, 79, 297, 99), "left": (189, 79), "right": (299, 79)},
    ("facup", "bracket"): {"frame": "08_facup_qtrfinals_DOMESTIC_bracket_unplayed_1999-03-04.png",
                           "plate": (315, 78, 399, 98), "left": (291, 78), "right": (401, 78)},
    ("cocacola", "bracket"): {"frame": "12_cocacola_qtr_bracket_DOMESTIC_probe0116.png",
                              "plate": (315, 78, 399, 98), "left": (291, 78), "right": (401, 78)},
    ("uefa", "bracket"): {"frame": "11_uefa_qtr_bracket_UNPLAYED_probe0116.png",
                          "plate": (315, 78, 399, 98), "left": (291, 78), "right": (401, 78)},
    ("cwc", "bracket"): {"frame": "10_cwc_qtr_bracket_UNPLAYED_probe0116.png",
                         "plate": (315, 78, 399, 98), "left": (291, 78), "right": (401, 78)},
}
PLATE_BG = (180, 200, 220)

# ---- the BRACKET panel strip (docs/re/knockout_views_re.md, re-measured 2026-07-26) ----
# Four panels at T = 113/193/273/353, each x20..477. One strip per column set is cut from
# one witnessed UNPLAYED panel and repeated four times -- legal because
# verify_bracket_split.py proves 20 panels over 6 frames byte-identical outside the six
# content rects below. The rects are blanked to the ground the app draws over: kits to the
# panel's white, flags + name bars to the bar ground (flags are 30x20 blits that cover
# their cell exactly, so the blank never shows).
BRACKET_X = (20, 477)
BRACKET_SRC = {"euro": ("02_euroleague_qtrfinals_UNPLAYED_1998-01.png", 113),
               "dom": ("08_facup_qtrfinals_DOMESTIC_bracket_unplayed_1999-03-04.png", 113)}
BRACKET_KITS = [(22, 2, 81, 69), (416, 2, 475, 69)]              # -> white
BRACKET_BARS = [(83, 7, 112, 26), (385, 7, 414, 26),             # flags
                (114, 7, 247, 26), (250, 7, 383, 26)]            # name bars -> bar ground
BRACKET_WHITE = (255, 255, 255)
BRACKET_BAR_BG = (180, 200, 220)

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
    "facup": 118, "cocacola": 145, "charity": 172,
    "euro": 209, "cwc": 236, "uefa": 263, "supercup": 290, "intercont": 317,
}
COMP_FRAME = {
    "facup": "09_comp_facup.png", "cocacola": "09_comp_cocacola.png",
    "charity": "09_comp_charity.png", "euro": "09_comp_euro.png",
    "cwc": "09_comp_cwc.png", "uefa": "09_comp_uefa.png",
    "supercup": "09_comp_supercup.png", "intercont": "09_comp_intercont.png",
}

# The scrollbar column, present only when the list is longer than the panel.
SCROLL_X = (478, 493)
SCROLL_Y = (125, 410)
THUMB_TROUGH = (172, 394)   # the trough's interior, measured on 01_facup_r2
THUMB_ROW_Y = 250           # a row safely inside the thumb bitmap

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
    desk.paste(cut(comps["facup"], (CHIP_X[0], CHIP_TOP["cocacola"],
                                    CHIP_X[1], CHIP_TOP["intercont"] + CHIP_H - 1)),
               (CHIP_X[0], CHIP_TOP["cocacola"]))
    desk.paste(cut(comps["uefa"], (CHIP_X[0], CHIP_TOP["facup"],
                                   CHIP_X[1], CHIP_TOP["facup"] + CHIP_H - 1)),
               (CHIP_X[0], CHIP_TOP["facup"]))
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
        y1 = 112 if fam == "bracket" else BAND_Y[1]
        cut(im, (BAND_X[0], BAND_Y[0], BAND_X[1], y1)).save(
            OUT / f"band_{comp}_{fam}.png")
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

    # -- the two compact-list header bands.
    cut(list_euro, (PANEL_X[0], LIST_HDR_Y[0], PANEL_X[1], LIST_HDR_Y[1])).save(
        OUT / "list_hdr_euro.png")
    cut(list_dom, (PANEL_X[0], LIST_HDR_Y[0], PANEL_X[1], LIST_HDR_Y[1])).save(
        OUT / "list_hdr_dom.png")
    print("list_hdr_euro.png + list_hdr_dom.png <- two witnessed panel tops")

    # -- the scrollbar: the column with the thumb painted out, plus one row of the thumb.
    col = cut(list_dom, (SCROLL_X[0], SCROLL_Y[0], SCROLL_X[1], SCROLL_Y[1]))
    trough_row = col.crop((0, THUMB_TROUGH[1] - SCROLL_Y[0] + 4,
                           col.width, THUMB_TROUGH[1] - SCROLL_Y[0] + 5))
    for y in range(THUMB_TROUGH[0] - SCROLL_Y[0], THUMB_TROUGH[1] - SCROLL_Y[0] + 1):
        col.paste(trough_row, (0, y))
    col.save(OUT / "scroll_col.png")
    cut(list_dom, (SCROLL_X[0], THUMB_ROW_Y, SCROLL_X[1], THUMB_ROW_Y)).save(
        OUT / "scroll_thumb_tile.png")
    print("scroll_col.png + scroll_thumb_tile.png <- the F.A. Cup R2 frame")


if __name__ == "__main__":
    main()
