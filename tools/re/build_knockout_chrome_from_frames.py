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
}
PLATE_BG = (180, 200, 220)

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

    # -- the rail, one per competition, from that competition's own band frame.
    for (comp, _fam), spec in BANDS.items():
        cut(frame(spec["frame"]), RAIL_RECT).save(OUT / f"rail_{comp}.png")
    print(f"rail_*.png <- {len(BANDS)} witnessed competition frames")

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

    # -- the competition bands, cut whole with the label plate blanked.
    meta = {}
    for (comp, fam), spec in BANDS.items():
        im = frame(spec["frame"]).copy()
        px0, py0, px1, py1 = spec["plate"]
        for y in range(py0, py1 + 1):
            for x in range(px0, px1 + 1):
                im.putpixel((x, y), PLATE_BG)
        cut(im, (BAND_X[0], BAND_Y[0], BAND_X[1], BAND_Y[1])).save(
            OUT / f"band_{comp}_{fam}.png")
        meta[f"{comp}_{fam}"] = {
            "origin": [BAND_X[0], BAND_Y[0]],
            "plate": list(spec["plate"]),
            "left": list(spec["left"]),
            "right": list(spec["right"]),
        }
    (OUT / "bands.json").write_text(json.dumps(meta, indent=1, sort_keys=True) + "\n")
    print(f"band_*.png + bands.json <- {len(BANDS)} witnessed (competition, layout) pairs")

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
