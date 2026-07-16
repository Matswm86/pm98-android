#!/usr/bin/env python3
"""OFFERS SELECTION screen chrome, frame-baked from the live-witnessed original.

Source (ground truth, owned game frames — captured 2026-07-16 from MANAGER.EXE
under wine, Promanager League career start, manager "mwm"):
  screenshots/promanager-career-2026-07-16/03_offers_selection_empty.png
  screenshots/promanager-career-2026-07-16/04_offers_selection_name_typed.png
  screenshots/promanager-career-2026-07-16/05_offers_selection_offers_for_mwm.png
  screenshots/promanager-career-2026-07-16/06_offers_selection_club_detail_popup.png
  screenshots/promanager-career-2026-07-16/07_offers_selection_offer_accepted.png

Screen provenance: EXE string OFFERS SELECTION 0x25e5bc + "OFFERS FOR" 0x25e724 +
seleccionpro flecha art refs 0x25e60c/0x25e638; the popup labels are the shared
0x25e6c0 header block (INTIAL CASH / MEMBERS). See
docs/re/promanager_career_screens_re.md.

Output (app/art/screens/offers_selection/ unless noted):
  body.png             640x480 opaque resting state: frame 03 with slot row 1
                       restored to the empty chrome (witnessed rows 2-8 are
                       pixel-identical, asserted) and the panel title text
                       erased (the title re-centres with the manager name, so
                       it is drawn live).
  body_dim.png         body.png through the witnessed palette-dim LUT (the
                       popup-modal backdrop, frames 05->06).
  dim_lut.json         exact per-colour dim map from the 05/06 pair (popup
                       rect excluded). Matches alert/dim_lut.json on every
                       shared colour (asserted).
  offers_plate_off.png the OFFERS button plate, no-name state (frame 03)
  offers_plate_on.png  the OFFERS button plate, name-typed state (frame 04)
  offers_plate_off_r1.png  the row-2 no-name plate (frame 07 — the plate's
                       dither is screen-anchored, so each witnessed row bakes
                       its own art)
  slot_chip1.png       slot-1 number chip (blue, white '1'; frame 05)
  arrow_chip.png       the row arrow chip (frame 05; upper slot chip ==
                       every lower-panel arrow chip, asserted)
  offer_chip_01..10.png the red numbered chips of the OFFERS FOR rows
                       (frame 05; the red darkens down the list — baked
                       per-row, digits included)
  continue_on.png      the lit CONTINUE (frame 07; frames 03/04/05 bake the
                       washed disabled plate into body.png)
  popup.png            the club-detail popup box (frame 06) with the live
                       regions blanked to their witnessed flat fills: club /
                       division header texts, kit patch, the four value cells.
                       Labels (STADIUM/CAPACITY/MEMBERS/INTIAL CASH), the
                       per-row colour ramp and OK stay baked.
  ../../kits/offers/107.png  the witnessed Brighton & HA popup kit patch
                       (47x59; other clubs have no witnessed patch at this
                       size — the app documents its fallback).

Doctrine (pm98_stay_true_to_original): every PNG is real frame pixels; the only
painted regions are live-data cells blanked back to their own witnessed flat
fills so nothing is invented.
"""

from __future__ import annotations

import json
from collections import Counter, defaultdict
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
WIT = ROOT / "screenshots/promanager-career-2026-07-16"
OUT = ROOT / "app/art/screens/offers_selection"
KIT_OUT = ROOT / "app/art/kits/offers"

F = {n: WIT / f for n, f in {
    3: "03_offers_selection_empty.png",
    4: "04_offers_selection_name_typed.png",
    5: "05_offers_selection_offers_for_mwm.png",
    6: "06_offers_selection_club_detail_popup.png",
    7: "07_offers_selection_offer_accepted.png",
}.items()}

# ---- frame-measured geometry (probe session 2026-07-16) --------------------
NAVY = (30, 52, 98)
BLACK = (0, 0, 0)
TITLE_BLUE = (42, 95, 255)

# Upper slot table: 8 row bands y = 86 + 15*r, fill height 14.
UP_Y0, UP_PITCH, UP_H = 86, 15, 14
UP_MGR = (88, 204)         # cell interiors (x0, x1 inclusive)
UP_TEAM = (207, 341)
UP_ROW_BAND = (43, 597)    # bands identical across rows inside this span

# The active name-entry cell (frames 03/04/07): black, overwrites the row's
# separators (y84..85 above, y100 below).
ENTRY = (88, 84, 204, 100)          # x0, y0, x1, y1 inclusive
PLATE = (206, 85, 343, 99)          # OFFERS plate (covers TEAM cell + borders)

# Slot chips (frame 05, row 1).
SLOT_CHIP = (45, 86, 67, 99)
ARROW = (70, 86, 85, 99)

# Lower OFFERS FOR panel: 10 rows y = 265 + 15*r, fill height 14.
LOW_Y0, LOW_PITCH, LOW_H = 265, 15, 14
LOW_CHIP = (104, 126)
LOW_ARROW = (129, 144)
PANEL_TITLE_ERASE = (142, 228, 535, 246)   # interior right of the bar decoration

# CONTINUE lit (frame 07 vs 03 diff bbox).
CONT = (508, 440, 622, 467)

# Popup (frame 06): box incl. 2px borders.
POPUP = (148, 174, 491, 305)
POP_CLUB = (150, 176, 334, 193)     # header interiors
POP_DIV = (337, 176, 489, 193)
POP_CLUB_FILL = (212, 63, 0)
POP_DIV_FILL = (212, 191, 0)
KIT = (157, 205, 203, 263)          # witnessed Brighton kit patch
POP_VAL_X = (337, 484)              # value-cell interiors, one per row
POP_VAL_ROWS = [(199, 213), (216, 230), (233, 247), (250, 264)]
POP_VAL_FILLS = [(100, 120, 140), (80, 100, 120), (60, 80, 100), (40, 60, 80)]


def rect(im: Image.Image, x0: int, y0: int, x1: int, y1: int, col) -> None:
    px = im.load()
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            px[x, y] = col


def crop(im: Image.Image, box) -> Image.Image:
    x0, y0, x1, y1 = box
    return im.crop((x0, y0, x1 + 1, y1 + 1))


def main() -> None:
    im = {n: Image.open(p).convert("RGB") for n, p in F.items()}
    p3, p5, p6 = im[3].load(), im[5].load(), im[6].load()

    # ---- assertions: the decode this bake rests on -------------------------
    # entry cell is solid black (so the app can draw it as a flat rect)
    for y in range(ENTRY[1], ENTRY[3] + 1):
        for x in range(ENTRY[0], ENTRY[2] + 1):
            assert p3[x, y] == BLACK, f"entry cell not black at {x},{y}"
    # upper slot rows 2..8 are pixel-identical (x43..597)
    band2 = [p3[x, 101 + dy] for dy in range(UP_H) for x in range(UP_ROW_BAND[0], UP_ROW_BAND[1] + 1)]
    for r in range(2, 8):
        y0 = 101 + UP_PITCH * (r - 1)
        band = [p3[x, y0 + dy] for dy in range(UP_H) for x in range(UP_ROW_BAND[0], UP_ROW_BAND[1] + 1)]
        assert band == band2, f"upper row {r + 1} differs from row 2"
    # lower panel rows all identical when empty
    lb = [p3[x, 280 + dy] for dy in range(LOW_H) for x in range(102, 538)]
    for r in range(10):
        y0 = LOW_Y0 + LOW_PITCH * r
        band = [p3[x, y0 + dy] for dy in range(LOW_H) for x in range(102, 538)]
        assert band == lb, f"lower row {r + 1} differs"
    # one arrow chip: upper slot arrow == every filled lower-row arrow (frame 05)
    ar = [p5[x, ARROW[1] + dy] for dy in range(UP_H) for x in range(ARROW[0], ARROW[2] + 1)]
    for r in range(10):
        y0 = LOW_Y0 + LOW_PITCH * r
        low = [p5[x, y0 + dy] for dy in range(UP_H) for x in range(LOW_ARROW[0], LOW_ARROW[1] + 1)]
        assert low == ar, f"lower arrow {r + 1} differs from the slot arrow"

    # ---- dim LUT from the 05/06 pair (popup excluded, padded) --------------
    pairs: dict[tuple, Counter] = defaultdict(Counter)
    for y in range(480):
        for x in range(641):
            if POPUP[0] - 4 <= x <= POPUP[2] + 4 and POPUP[1] - 4 <= y <= POPUP[3] + 4:
                continue
            pairs[p5[x, y]][p6[x, y]] += 1
    lut: dict[str, str] = {}
    for src, c in pairs.items():
        assert len(c) == 1, f"dim LUT ambiguous for {src}: {c.most_common(3)}"
        dst = c.most_common(1)[0][0]
        lut[f"{src[0]},{src[1]},{src[2]}"] = f"{dst[0]},{dst[1]},{dst[2]}"
    # sanity: agrees with the alert dim LUT on every shared colour
    alert = json.loads((ROOT / "app/art/screens/alert/dim_lut.json").read_text())
    for k, v in lut.items():
        assert alert.get(k, v) == v, f"dim LUT contradicts alert LUT at {k}"

    OUT.mkdir(parents=True, exist_ok=True)
    KIT_OUT.mkdir(parents=True, exist_ok=True)
    (OUT / "dim_lut.json").write_text(json.dumps(lut, indent=0, sort_keys=True) + "\n")
    print(f"wrote dim_lut.json ({len(lut)} colours)")

    # ---- body: frame 03 with slot row 1 emptied + panel title erased -------
    body = im[3].copy().crop((0, 0, 640, 480))
    # entry cell region back to empty-row chrome: black separators + navy cell
    rect(body, ENTRY[0], 84, ENTRY[2], 85, BLACK)
    rect(body, ENTRY[0], 86, ENTRY[2], 99, NAVY)
    rect(body, ENTRY[0], 100, ENTRY[2], 100, BLACK)
    # OFFERS plate region back to chrome: separator row + border cols + navy cell
    rect(body, PLATE[0], 85, PLATE[2], 85, BLACK)
    rect(body, PLATE[0], 86, PLATE[0], 99, BLACK)          # x206 border col
    rect(body, UP_TEAM[0], 86, UP_TEAM[1], 99, NAVY)
    rect(body, 342, 86, 343, 99, BLACK)
    rect(body, *PANEL_TITLE_ERASE, TITLE_BLUE)
    body.save(OUT / "body.png")
    print("wrote body.png (640x480)")

    # body_dim: body through the LUT (every body colour must be witnessed-dimmable
    # or the resting fills just painted, which appear in frame 05 too)
    dim_map = {tuple(map(int, k.split(","))): tuple(map(int, v.split(","))) for k, v in lut.items()}
    bd = body.copy()
    pb = bd.load()
    miss: Counter = Counter()
    for y in range(480):
        for x in range(640):
            c = pb[x, y]
            if c in dim_map:
                pb[x, y] = dim_map[c]
            else:
                miss[c] += 1
                pb[x, y] = (round(c[0] * 0.63), round(c[1] * 0.63), round(c[2] * 0.65))
    if miss:
        print(f"body_dim: {sum(miss.values())}px fell back to the fitted multiply "
              f"({len(miss)} colours: {miss.most_common(5)})")
    bd.save(OUT / "body_dim.png")
    print("wrote body_dim.png")

    # ---- sprites ------------------------------------------------------------
    crop(im[3], PLATE).save(OUT / "offers_plate_off.png")
    crop(im[4], PLATE).save(OUT / "offers_plate_on.png")
    crop(im[7], (PLATE[0], 100, PLATE[2], 114)).save(OUT / "offers_plate_off_r1.png")
    crop(im[5], SLOT_CHIP).save(OUT / "slot_chip1.png")
    crop(im[5], ARROW).save(OUT / "arrow_chip.png")
    for r in range(10):
        y0 = LOW_Y0 + LOW_PITCH * r
        crop(im[5], (LOW_CHIP[0], y0, LOW_CHIP[1], y0 + LOW_H - 1)).save(
            OUT / f"offer_chip_{r + 1:02d}.png")
    crop(im[7], CONT).save(OUT / "continue_on.png")
    print("wrote plates, chips, arrow, continue_on")

    # ---- popup ---------------------------------------------------------------
    pop = crop(im[6], POPUP)
    ox, oy = POPUP[0], POPUP[1]

    def prect(box, col):
        rect(pop, box[0] - ox, box[1] - oy, box[2] - ox, box[3] - oy, col)

    prect(POP_CLUB, POP_CLUB_FILL)
    prect(POP_DIV, POP_DIV_FILL)
    prect(KIT, (255, 255, 255))
    for (y0, y1), fill in zip(POP_VAL_ROWS, POP_VAL_FILLS):
        prect((POP_VAL_X[0], y0, POP_VAL_X[1], y1), fill)
    pop.save(OUT / "popup.png")
    print(f"wrote popup.png ({pop.size[0]}x{pop.size[1]})")

    crop(im[6], KIT).save(KIT_OUT / "107.png")
    print("wrote ../kits/offers/107.png (witnessed Brighton & HA patch)")


if __name__ == "__main__":
    main()
