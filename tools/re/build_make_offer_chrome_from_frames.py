#!/usr/bin/env python3
"""Bake the MAKE-OFFER card STATIC CHROME from the real game's own frames.

Same doctrine as build_team_offer_chrome_from_frames.py (owner: "IT NEEDS TO BE
EXACT"): the card is engine-composited at runtime, so the chrome layer IS the
original frame with the player/state-dependent pixels cleared to a resting look;
MakeOfferScreen draws the dynamic layer (name, values, stars, flags, stepper
values, checkbox marks, pressed ring) on top with the game's own PROMAN fonts +
art. Full RE: docs/re/make_offer_re.md.

Binding frames (run-3, screenshots/original-walkthrough-2026-07-02, 641x480):
  101_164714  Taylor card fresh (offer 5,000 / fee 3,000,000 / wage 5,000 /
              years 1, nothing checked)                                  BASE
  113_164736  Scoring bonus CHECKED: red X + stepper active (£5,000)
  118_164746  OFFER pressed (2px red ring outside the button border)
plus the owner's McKinlay capture screenshots/transfer-offers-2026-07-02/
make_offer_card.png (capture→design dx=+2 dy=+12): the washed Scoring-bonus
label (MF player) + the BIGFOTO photo block.

Outputs (under app/art/screens/makeoffer/):
  chrome.png          488x383  frame-101 card crop (76,48)-(564,431), every
                      player/state field cleared to resting
  check_on.png        9x9      the red X (113 Scoring-bonus interior)
  spin_l_on/r_on.png  14x14    ENABLED stepper arrows (113 scoring, black tris;
                      the washed grey-tri arrows stay baked in the chrome)
  offer_pr.png                 the pressed-OFFER cut (118: red ring + button)
  scoring_washed.png           the washed "Scoring bonus" label strip (McKinlay)
  app/art/kits/ficha/82.png    frame-rendered FICHA kit patch (BLACKPOOL)

The BIGFOTO photo is a BORDERLESS 32x32 block at design (130,59) drawn over the
name bar's left end (McKinlay capture x128..159 y47..78; Taylor has no face art
in the bank and shows none) — no chrome asset, the screen NEAREST-fits the face.
  tools/re/specs/make_offer_chrome_samples.json (+ app/data mirror)

Every measured invariant is asserted so a regenerated walkthrough or bad crop
fails loudly instead of baking garbage.

Run from anywhere:  python3 tools/re/build_make_offer_chrome_from_frames.py
"""

from __future__ import annotations

import json
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
FRAMES = ROOT / "screenshots" / "original-walkthrough-2026-07-02"
if not FRAMES.exists():  # full capture set is local-only; binding frames are committed
    FRAMES = ROOT / "tools" / "re" / "refs" / "walkthrough-2026-07-02"
MCK = ROOT / "screenshots" / "transfer-offers-2026-07-02" / "make_offer_card.png"
if not MCK.exists():
    MCK = ROOT / "tools" / "re" / "refs" / "make_offer_card.png"
ART = ROOT / "app" / "art" / "screens" / "makeoffer"
SPECS = Path(__file__).resolve().parent / "specs"

F101 = "101_164714.png"
F113 = "113_164736.png"
F118 = "118_164746.png"

# The card modal on screen: black frame x76..563, y48..430 inclusive.
CARD = (76, 48, 564, 431)
# McKinlay capture -> design offset (ofertas_screen_re.md): design = capture + (2,12)
MCK_DX, MCK_DY = 2, 12

# checkbox boxes: 11x11 black border, 9x9 white interior
CB_X = 351
CB_YS = [290, 306, 339, 372]  # Free / Matches / Scoring / House
# scoring stepper (active in 113): arrows 14x14 (incl 1px border), bar interior
SPIN_L = (372, 352, 386, 367)  # x0,y0,x1,y1 exclusive — left arrow button
SPIN_R = (506, 352, 520, 367)
SCOR_BAR = (388, 354, 504, 366)  # grey 128 interior
# matches stepper (always washed): same widget, smaller bar
MAT_BAR = (388, 320, 424, 332)
# value bars (interiors)
OFFER_BAR = (181, 271, 326, 283)
FEE_BAR = (181, 306, 326, 318)
WAGE_BAR = (181, 336, 326, 348)
YEARS_BAR = (181, 368, 237, 380)
# pressed-OFFER ring (118): 2px red ring outside the button black border
OFFER_PR = (403, 394, 552, 427)
# six stat value cells (pale green)
STAT_CELL_X = (472, 496)
STAT_Y0, STAT_PITCH = 96, 10
# skill strip chips
SKILL_Y0, SKILL_PITCH = 164, 13
CHIP_X = (448, 522)
STAR_X0, STAR_PITCH = 450, 14
SKILL_VAL_X = (524, 545)
# name bar (solid zone; the fade ramp starts x527 and holds no text in any frame)
NAME_BAR = (146, 66, 527, 85)
# info coin (animates; sits on the card corner — cleared to 101's own pixels, i.e.
# left as-is: the screen redraws nothing there and parity excludes it)
COIN = (83, 56, 123, 96)


def load(name: str) -> np.ndarray:
    a = np.asarray(Image.open(FRAMES / name).convert("RGB"))
    if a.shape[0] != 480 or a.shape[1] not in (640, 641):
        raise SystemExit(f"{name}: unexpected size {a.shape}")
    return a[:, :640].copy()


def save(a: np.ndarray, rel: str) -> None:
    p = ART / rel
    p.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(a.astype("uint8")).save(p)
    print(f"  {p.relative_to(ROOT)}  {a.shape[1]}x{a.shape[0]}")


def expect(cond: bool, what: str) -> None:
    if not cond:
        raise SystemExit(f"frame invariant FAILED: {what}")


def cut(a: np.ndarray, r: tuple) -> np.ndarray:
    return a[r[1] : r[3], r[0] : r[2]].copy()


def fill(a: np.ndarray, r: tuple, rgb: tuple) -> None:
    a[r[1] : r[3], r[0] : r[2]] = rgb


def row_median_inpaint(
    a: np.ndarray, x0: int, y0: int, x1: int, y1: int, margin: int = 10, thresh: int = 40
) -> None:
    """Erase minority-colour text inside a flat/graded strip: per row, fill pixels
    deviating from the row's margin-median by > thresh with that median."""
    for y in range(y0, y1):
        row = a[y, x0:x1].astype(int)
        med = np.median(np.concatenate([row[:margin], row[-margin:]]), axis=0)
        mask = np.abs(row - med).mean(axis=1) > thresh
        row[mask] = med
        a[y, x0:x1] = row


def erase_to_white(a: np.ndarray, x0: int, y0: int, x1: int, y1: int, tag: str) -> tuple:
    """White-fill the bbox of the non-white art inside a card-white region."""
    reg = a[y0:y1, x0:x1]
    ys, xs = np.where(reg.min(axis=2) < 200)
    expect(ys.size > 0, f"{tag}: nothing to erase in ({x0},{y0})-({x1},{y1})")
    bb = (x0 + int(xs.min()), y0 + int(ys.min()), x0 + int(xs.max()) + 1, y0 + int(ys.max()) + 1)
    fill(a, bb, (255, 255, 255))
    return bb


def main() -> None:
    f101 = load(F101)
    f113 = load(F113)
    f118 = load(F118)
    mck = np.asarray(Image.open(MCK).convert("RGB")).copy()

    # ---- frame invariants ----------------------------------------------------
    expect(tuple(f101[49, 100]) == (0, 0, 0), "101 card top frame not black")
    expect(tuple(f101[240, 100]) == (255, 255, 255), "101 card white body")
    expect(tuple(f101[75, 200]) == (0, 0, 128), "101 name bar navy")
    expect(tuple(f101[277, 200]) == (210, 0, 0), "101 CLUB OFFER bar red")
    expect(tuple(f101[306, 200]) == (212, 63, 0), "101 CLUB FEE bar orange")
    expect(tuple(f101[341, 200]) == (42, 63, 170), "101 YEARLY WAGE bar blue")
    expect(tuple(f101[373, 200]) == (80, 110, 5), "101 YEARS box olive")
    # checkboxes: 9x9 white interiors, all UNchecked in 101
    for cy in CB_YS:
        interior = f101[cy + 1 : cy + 10, CB_X + 1 : CB_X + 10]
        expect((interior == 255).all(), f"101 checkbox y{cy} not clean white")
    # 113: scoring X + active stepper; everything above the clause zone that isn't
    # the coin or the offer/wage values matches 101
    xmark = cut(f113, (CB_X + 1, CB_YS[2] + 1, CB_X + 10, CB_YS[2] + 10))
    expect((xmark == [255, 0, 0]).all(axis=2).sum() >= 12, "113 scoring X not red")
    d = np.abs(f118.astype(int) - f101.astype(int)).mean(axis=2) > 8
    d[:, : OFFER_PR[0]] = False
    d[: OFFER_PR[1]], d[OFFER_PR[3] :] = False, False
    ys, xs = np.where(d)
    expect(
        xs.min() >= OFFER_PR[0]
        and xs.max() < OFFER_PR[2]
        and ys.min() >= OFFER_PR[1]
        and ys.max() < OFFER_PR[3],
        f"118 pressed-ring bbox drifted: x{xs.min()}..{xs.max()} y{ys.min()}..{ys.max()}",
    )
    expect(tuple(f118[397, 470]) == (255, 0, 0), "118 ring row not red")

    # McKinlay offset check: the Free-if-relegated checkbox border sits at
    # design (351,290) -> capture (349,278); its interior is white in both.
    for r in (
        mck[278 + 1 : 278 + 10, 349 + 1 : 349 + 10],
        mck[290 - MCK_DY + 1 : 290 - MCK_DY + 10, CB_X - MCK_DX + 1 : CB_X - MCK_DX + 10],
    ):
        expect((r == 255).all(), "mck checkbox alignment (dx+2,dy+12) broken")
    expect(tuple(mck[277 - 12, 351 - 2]) != (0, 0, 0), "mck sanity")

    # the dynamic layer's own art IS the game's own art — assert SAD 0.0
    mini30 = np.asarray(Image.open(ROOT / "app" / "art" / "flags" / "mini_030.png").convert("RGB"))
    expect(np.array_equal(mini30, f101[145:155, 141:155]), "NAT flag != mini_030 at (141,145)")
    cam12 = np.asarray(
        Image.open(ROOT / "app" / "art" / "icons" / "camrol" / "camrol12.png").convert("RGB")
    )
    expect(np.array_equal(cam12, f101[160:174, 182:207]), "ROLE icon != camrol12 at (182,160)")
    star = np.asarray(
        Image.open(ROOT / "app" / "art" / "screens" / "teamoffer" / "star_full.png").convert("RGB")
    )
    half = np.asarray(
        Image.open(ROOT / "app" / "art" / "screens" / "teamoffer" / "star_half.png").convert("RGB")
    )
    # halves = (value+1) div 10 — the rule fitting ALL 18 star observations across
    # 101 + team-offer 086/090 (090's HEADING 79 shows 4 FULL stars, killing the
    # earlier div-10 reading): PO19->1 full, PA79->4 full, RM75/RG75/TI73->3+half,
    # EN57->2+half
    stars_by_row = {0: (1, 0), 1: (4, 0), 2: (3, 1), 3: (3, 1), 4: (2, 1), 5: (3, 1)}
    for i, (fulls, halfs) in stars_by_row.items():
        gy = SKILL_Y0 + SKILL_PITCH * i + 1
        for j in range(fulls):
            gx = STAR_X0 + STAR_PITCH * j
            expect(
                np.array_equal(star, f101[gy : gy + 8, gx : gx + 11]),
                f"full star mismatch row {i} pos {j}",
            )
        if halfs:
            gx = STAR_X0 + STAR_PITCH * fulls
            expect(
                np.array_equal(half, f101[gy : gy + 8, gx : gx + 11]),
                f"half star mismatch row {i}",
            )

    # ---- state cuts -----------------------------------------------------------
    save(xmark, "check_on.png")
    save(cut(f113, SPIN_L), "spin_l_on.png")
    save(cut(f113, SPIN_R), "spin_r_on.png")
    save(cut(f118, OFFER_PR), "offer_pr.png")

    # washed "Scoring bonus" label strip from McKinlay (design coords of the
    # active label bbox in 101, + the checkbox border which also washes)
    lbl = (CB_X, CB_YS[2], 449, CB_YS[2] + 11)  # box + label, design
    save(
        cut(mck, (lbl[0] - MCK_DX, lbl[1] - MCK_DY, lbl[2] - MCK_DX, lbl[3] - MCK_DY)),
        "scoring_washed.png",
    )

    # photo rect from McKinlay: a borderless 32x32 face block over the name bar's
    # left end — assert its extent (dark photo pixels; the card is white at x127)
    ys, xs = np.where(mck[46:81, 120:166].min(axis=2) < 130)
    pb_cap = (120 + int(xs.min()), 46 + int(ys.min()), 128 + 32, 47 + 32)
    expect(pb_cap[:2] == (128, 47), f"mck photo origin drifted: {pb_cap}")
    expect((mck[47:79, 127].min(axis=1) > 200).all(), "mck photo not borderless on white")
    pb_design = (pb_cap[0] + MCK_DX, pb_cap[1] + MCK_DY, pb_cap[2] + MCK_DX, pb_cap[3] + MCK_DY)

    # frame-rendered FICHA kit patch: BLACKPOOL is the only club a make-offer
    # frame shows at this kit slot (panel-kit precedent, TEAM OFFER's Man Utd cut)
    dbj = json.loads((ROOT / "app" / "data" / "game_db.json").read_text(encoding="utf-8"))
    bpool = next(c for c in dbj["clubs"] if c.get("name") == "BLACKPOOL")
    kit_dir = ROOT / "app" / "art" / "kits" / "ficha"
    kit_dir.mkdir(parents=True, exist_ok=True)
    KIT = (140, 202, 172, 239)
    Image.fromarray(cut(f101, KIT).astype("uint8")).save(kit_dir / f"{bpool['id']}.png")
    print(f"  app/art/kits/ficha/{bpool['id']}.png  frame-rendered FICHA kit patch (BLACKPOOL)")

    # ---- clear the dynamic fields to resting -----------------------------------
    a = f101.copy()
    # name text on the navy bar (solid zone; fade ramp holds no text)
    row_median_inpaint(a, NAME_BAR[0], NAME_BAR[1], NAME_BAR[2], NAME_BAR[3], margin=14)
    # position word (pure card white)
    pw = erase_to_white(a, 150, 88, 350, 104, "posword")
    # AGE / WEIGHT / HEIGHT value strips (flat colour fills + white digits)
    row_median_inpaint(a, 141, 117, 201, 129, margin=5)
    row_median_inpaint(a, 206, 117, 266, 129, margin=5)
    row_median_inpaint(a, 271, 117, 331, 129, margin=5)
    # NATIONALITY value strip: flag + country (flat grey 128); KIND
    row_median_inpaint(a, 141, 144, 251, 156, margin=4)
    row_median_inpaint(a, 258, 144, 351, 156, margin=4)
    # ROLE: camrol sprite cell + the role word on the teal band
    fill(a, (182, 160, 207, 174), (140, 170, 30))  # olive backing under the sprite
    row_median_inpaint(a, 208, 160, 351, 174, margin=4)
    # STATUS / INSURANCE value strips: STATUS flat slate; the INSURANCE value
    # area is flat steel (59,85,130) right of its white divider at x261..263
    row_median_inpaint(a, 141, 191, 238, 203, margin=4)
    fill(a, (264, 191, 352, 203), (59, 85, 130))
    # kit art (on card white) + club name (flat grey bar; text ink starts x162)
    fill(a, KIT, (255, 255, 255))
    fill(a, (158, 208, 352, 220), (220, 220, 220))
    # six stat value cells + RATING digits (flat grey box 505..544 x 120..138)
    for i in range(6):
        y = STAT_Y0 + i * STAT_PITCH
        row_median_inpaint(a, STAT_CELL_X[0], y, STAT_CELL_X[1], y + 9, margin=3)
    fill(a, (506, 121, 544, 138), (220, 220, 220))
    # skill chips: stars on pure black; values on card white
    for i in range(6):
        y = SKILL_Y0 + i * SKILL_PITCH
        fill(a, (CHIP_X[0], y, CHIP_X[1], y + 11), (0, 0, 0))
        fill(a, (SKILL_VAL_X[0], y, SKILL_VAL_X[1], y + 11), (255, 255, 255))
    # bar values (flat fills)
    fill(a, OFFER_BAR, (210, 0, 0))
    fill(a, FEE_BAR, (212, 63, 0))
    fill(a, WAGE_BAR, (42, 63, 170))
    fill(a, YEARS_BAR, (80, 110, 5))
    # (checkboxes unchecked, steppers washed, buttons unpressed in 101 already)

    save(cut(a, CARD), "chrome.png")

    samples = {
        "card": list(CARD),
        "coin": list(COIN),
        "name_bar": list(NAME_BAR),
        "posword_bbox": list(pw),
        "photo_block_design": list(pb_design),
        "value_strips": {
            "age": [141, 117, 201, 129],
            "weight": [206, 117, 266, 129],
            "height": [271, 117, 331, 129],
        },
        "nat_flag_xy": [141, 145],
        "nat_box": [140, 144, 251, 156],
        "kind_box": [257, 144, 351, 156],
        "role_icon_xy": [182, 160],
        "role_band": [207, 160, 351, 174],
        "status_box": [140, 191, 238, 203],
        "insurance_box": [241, 191, 351, 203],
        "kit_rect": list(KIT),
        "clubname_xy": [176, 209],
        "stat_cells": {"x": list(STAT_CELL_X), "y0": STAT_Y0, "pitch": STAT_PITCH},
        "rating_box": [505, 120, 545, 139],
        "skill": {
            "y0": SKILL_Y0,
            "pitch": SKILL_PITCH,
            "chip_x": list(CHIP_X),
            "star_x0": STAR_X0,
            "star_pitch": STAR_PITCH,
            "val_x": list(SKILL_VAL_X),
        },
        "bars": {
            "offer": list(OFFER_BAR),
            "fee": list(FEE_BAR),
            "wage": list(WAGE_BAR),
            "years": list(YEARS_BAR),
        },
        "arrows": {
            "offer_l": [164, 270, 179, 284],
            "offer_r": [327, 270, 342, 284],
            "wage_l": [164, 335, 179, 349],
            "wage_r": [327, 335, 342, 349],
            "years_l": [164, 367, 179, 381],
            "years_r": [238, 367, 253, 381],
            "scoring_l": list(SPIN_L),
            "scoring_r": list(SPIN_R),
        },
        "scoring_bar": list(SCOR_BAR),
        "matches_bar": list(MAT_BAR),
        "checkbox_x": CB_X,
        "checkbox_ys": CB_YS,
        "buttons": {
            "cancel": [140, 396, 244, 425],
            "loan": [253, 396, 397, 425],
            "offer": [405, 396, 551, 425],
        },
        "offer_pr_rect": list(OFFER_PR),
        "colors": {
            "money_gold": [255, 223, 0],
            "wage_pale": [180, 200, 220],
            "years_pale": [200, 230, 60],
            "rating_navy": [59, 85, 130],
            "value_white": [255, 255, 255],
            "black": [0, 0, 0],
        },
    }
    SPECS.mkdir(parents=True, exist_ok=True)
    out = SPECS / "make_offer_chrome_samples.json"
    out.write_text(json.dumps(samples, indent=1) + "\n")
    print(f"  {out.relative_to(ROOT)}")
    app_out = ROOT / "app" / "data" / "make_offer_chrome_samples.json"
    app_out.write_text(json.dumps(samples, indent=1) + "\n")
    print(f"  {app_out.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
