#!/usr/bin/env python3
"""Bake the PLAYER INFORMATION (FICHA) card STATIC CHROME from the real game's
own frames.

Same doctrine as build_make_offer_chrome_from_frames.py (owner: "IT NEEDS TO BE
EXACT"): the chrome layer IS the original frame with the player/state-dependent
pixels cleared to a resting look; PlayerInfoScreen draws the dynamic layer
(name, photo, values, stars, flags, contract figures, clause boxes + labels +
sub-lines, pressed ring) on top with the game's own PROMAN fonts + art.
Full RE: docs/re/ficha_card_re.md.

Binding frames (run-1, screenshots/original-walkthrough-2026-07-02, 641x480,
the card pops over SQUAD MANAGEMENT which palette-dims under it — the SAME
dim LUT the hub alert uses, verified 081-vs-082 with 0 unknown colours):
  079_154615  Van der Gouw card, OK unpressed                        BASE
  080/081     same card, OK HELD (red ring) — 081 has the coin at "i"
  084/085     Solskjaer card, OK held; 084-vs-085 differ ONLY in the coin
Card states across the pair: 081 = Free-if-relegated + Matches-to-renew(20)
checked (black box + red fill) with the "Matches played: 0" sub-line, Scoring/
House washed (grey); 084 = Free + Scoring-bonus(£5,000) checked with the
"Goals: 0" sub-line, Matches/House washed.

Card black frame (76,58)-(563,420) inclusive — the same 488px-wide card as
MAKE-OFFER, 10px lower and 20px shorter; every shared top-section element sits
at the make-offer design coords +9 in y (verified pixel-identical at dy=+9,
92% exact over the identity zone, the rest being player-dependent ink).

Outputs (under app/art/screens/ficha/):
  chrome.png        488x363  frame-079 card crop, every player/state field
                    cleared to resting (coin baked as-is; parity excludes it)
  ok_pr.png         the held-OK cut (081: 2px red ring outside the border)
  app/art/kits/ficha/40.png  frame-rendered 32x37 FICHA kit patch (MAN UTD) —
                    the 32x37 CARD slot (make-offer 82.png precedent); the
                    24x33 TEAM OFFER slot cut moves to art/screens/teamoffer/
  tools/re/specs/ficha_chrome_samples.json (+ app/data mirror)

Checkboxes are NOT cut: the checked mark is a flat 7x7 (255,31,0) square inside
a 1px white rim inside the 11x11 box border (black when active, grey 144 when
washed) — PlayerInfoScreen draws them as rects; this script asserts the exact
pattern in both frames so a wrong redraw fails the bake, and the parity suite
pins the composed result.

Every measured invariant is asserted so a regenerated walkthrough or bad crop
fails loudly instead of baking garbage.

Run from anywhere:  python3 tools/re/build_ficha_chrome_from_frames.py
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
ART = ROOT / "app" / "art" / "screens" / "ficha"
SPECS = Path(__file__).resolve().parent / "specs"

F079 = "079_154615.png"
F081 = "081_154619.png"
F084 = "084_154626.png"

# The card modal on screen: black frame x76..563, y58..420 inclusive.
CARD = (76, 58, 564, 421)
COIN = (84, 65, 124, 105)  # animated info coin; baked as-is, parity-excluded

FIELD = (220, 220, 220)  # contract-panel grey field
WASHED = (144, 144, 144)  # washed clause grey (box border + label ink)
CHECK_RED = (255, 31, 0)  # checked clause fill

# clause checkbox rows (11x11 boxes at x351): Free / Matches / Scoring / House
CB_X = 351
CB_YS = [273, 287, 316, 345]
LABEL_X = 366  # clause label ink-left
SUB_Y = {1: 300, 2: 330}  # sub-line ink-top rows (Matches played / Goals)

# contract-side geometry (screen coords, inclusive-exclusive rects)
FEE_BAR = (180, 278, 325, 290)  # orange (212,63,0), gold value centred x252
WAGE_BAR = (180, 308, 325, 320)  # blue (42,63,170), pale value centred x252
YEARS_INT = (180, 340, 236, 352)  # olive (80,110,5) interior, digit cx 207.5
LEFT_INT = (276, 340, 312, 352)  # teal (42,95,85) interior, digit cx 293.5
PANEL = (136, 257, 557, 361)  # black border incl. the CONTRACT strip x136..158

# buttons (card-local rects from FUN_00526a60 + card origin (76,58)):
# RENEW (85,325)104x25 / TRANSFER (196,..) / SACK (307,..) / OK (429,..,52x25)
BTNS = {
    "renew": (161, 383, 265, 408),
    "transfer": (272, 383, 376, 408),
    "sack": (383, 383, 487, 408),
    "ok": (505, 383, 557, 408),
}
OK_PR = (503, 381, 559, 410)  # 2px red ring outside the OK border (081/084)

# top-section dynamic zones (make-offer coords +9; inks re-measured on 081)
PHOTO = (130, 68, 162, 100)  # borderless 32x32 BIGFOTO block, on card white
NAME_INPAINT = (170, 77, 520, 90)  # name ink y79..87 on the solid navy bar
POSWORD_ZONE = (170, 95, 360, 112)  # ink y101..107, centred x245.5
VAL_STRIPS = [(141, 126, 201, 138), (206, 126, 266, 138), (271, 126, 331, 138)]
NAT_STRIP = (141, 153, 251, 165)  # incl. the 14x10 mini flag at (141,154)
KIND_STRIP = (258, 153, 351, 165)
CAMROL = (182, 169, 207, 183)  # 25x14 sprite cell
ROLE_BAND = (208, 169, 351, 183)  # teal, word centred x279
STATUS_STRIP = (141, 200, 238, 212)
INSUR_FILL = (264, 200, 352, 212)  # flat steel right of the white divider
KIT = (140, 211, 172, 248)  # 32x37 frame kit patch window
CLUBNAME_BAR = (158, 217, 352, 229)  # grey 220 bar, ink-left x162
STAT_CELL_X = (472, 496)
STAT_Y0, STAT_PITCH = 105, 10  # six pale-green cells, digits centred x484
RATING_FILL = (506, 130, 544, 147)  # grey box interior, navy digits cx 525
SKILL_Y0, SKILL_PITCH = 173, 13
CHIP_X = (448, 522)  # black star chips
STAR_X0, STAR_PITCH = 450, 14
SKILL_VAL_X = (524, 545)  # values on card white, centred x535
CLAUSE_WIPE = (346, 272, 556, 360)  # everything below the CLAUSES: header


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
    reg = a[y0:y1, x0:x1]
    ys, xs = np.where(reg.min(axis=2) < 200)
    expect(ys.size > 0, f"{tag}: nothing to erase in ({x0},{y0})-({x1},{y1})")
    bb = (x0 + int(xs.min()), y0 + int(ys.min()), x0 + int(xs.max()) + 1, y0 + int(ys.max()) + 1)
    fill(a, bb, (255, 255, 255))
    return bb


def checkbox_state(f: np.ndarray, row: int) -> str:
    """Classify a clause checkbox in a frame: 'checked' (black 11x11 border, WHITE
    9x9 interior with a 7x7 solid (255,31,0) core) / 'washed' (grey-144 border,
    FIELD-grey 220 interior)."""
    y = CB_YS[row]
    top = f[y, CB_X : CB_X + 11]
    interior = f[y + 1 : y + 10, CB_X + 1 : CB_X + 10]
    if (top == 0).all():
        core = interior[1:8, 1:8]
        expect(
            (core == CHECK_RED).all(axis=2).all(),
            f"checked box row {row}: core not solid (255,31,0)",
        )
        rim = interior.copy()
        rim[1:8, 1:8] = 255
        expect((rim == 255).all(), f"checked box row {row}: rim not white")
        return "checked"
    expect((top == WASHED[0]).all(), f"box row {row}: border neither black nor grey144")
    expect(
        (interior == np.array(FIELD)).all(),
        f"washed box row {row}: interior not field grey 220",
    )
    return "washed"


def main() -> None:
    f79 = load(F079)
    f81 = load(F081)
    f84 = load(F084)

    # ---- frame invariants ------------------------------------------------------
    # card frame + panel
    expect(tuple(f79[58, 300]) == (0, 0, 0), "079 card top frame not black")
    expect(tuple(f79[240, 563]) == (0, 0, 0), "079 card right frame not black")
    expect(tuple(f79[84, 300]) == (0, 0, 128), "079 name bar navy")
    expect(tuple(f79[257, 300]) == (0, 0, 0), "079 panel top border")
    expect(tuple(f79[300, 556]) == (0, 0, 0), "079 panel right border")
    expect(tuple(f79[283, 170]) == FIELD, "079 panel field not grey 220")
    expect(tuple(f79[283, 200]) == (212, 63, 0), "079 CLUB FEE bar orange")
    expect(tuple(f79[313, 200]) == (42, 63, 170), "079 YEARLY WAGE bar blue")
    expect(tuple(f79[346, 190]) == (80, 110, 5), "079 YEARS box olive")
    expect(tuple(f79[346, 280]) == (42, 95, 85), "079 LEFT box teal")
    # the CLAUSES: header is pure navy and static
    hdr = f79[263:270, 407:462]
    expect(((hdr == (0, 0, 128)).all(axis=2)).sum() > 150, "079 CLAUSES: header not navy")
    # buttons: black borders at the FUN_00526a60 rects
    for k, (x0, y0, x1, y1) in BTNS.items():
        expect((f79[y0, x0:x1] == 0).all(), f"079 {k} top border not black")
        expect((f79[y1 - 1, x0:x1] == 0).all(), f"079 {k} bottom border not black")
    # OK ring: ABSENT in 079, present + pure red in 081 and 084
    expect(tuple(f79[381, 530]) != (255, 0, 0), "079 should have NO OK ring")
    for f, nm in ((f81, "081"), (f84, "084")):
        expect(tuple(f[381, 530]) == (255, 0, 0), f"{nm} OK ring top row not red")
        expect(tuple(f[409, 530]) == (255, 0, 0), f"{nm} OK ring bottom row not red")
    ring81 = cut(f81, OK_PR)
    expect(np.array_equal(ring81, cut(f84, OK_PR)), "081/084 OK-ring cuts differ")

    # chrome stability: 081 and 084 agree outside the dynamic zones + coin
    d = np.abs(f81.astype(int) - f84.astype(int)).sum(axis=2) > 0
    d[COIN[1] : COIN[3], COIN[0] : COIN[2]] = False
    ys, _xs = np.where(d)
    expect(ys.max() < 336, f"081-vs-084 chrome drift below y=336 (max y{ys.max()})")

    # clause states per frame (asserts the exact box pattern both ways)
    expect(
        [checkbox_state(f81, i) for i in range(4)] == ["checked", "checked", "washed", "washed"],
        "081 clause states",
    )
    expect(
        [checkbox_state(f84, i) for i in range(4)] == ["checked", "washed", "checked", "washed"],
        "084 clause states",
    )
    # washed label ink is grey 144 (081 Scoring / House), active ink black (Free)
    expect(
        (f81[347:354, 366:448] == WASHED).all(axis=2).sum() > 150, "081 House label not washed grey"
    )
    expect((f81[275:284, 366:465] == 0).all(axis=2).sum() > 200, "081 Free label not black")

    # the dynamic layer's own art IS the game's own art — assert SAD 0.0
    mini27 = np.asarray(Image.open(ROOT / "app" / "art" / "flags" / "mini_027.png").convert("RGB"))
    expect(
        np.array_equal(mini27, f81[154:164, 141:155]),
        "NAT flag != mini_027 (HOLLAND) at (141,154)",
    )
    mini44 = np.asarray(Image.open(ROOT / "app" / "art" / "flags" / "mini_044.png").convert("RGB"))
    expect(
        np.array_equal(mini44, f84[154:164, 141:155]),
        "NAT flag != mini_044 (NORWAY) at (141,154)",
    )
    cam01 = np.asarray(
        Image.open(ROOT / "app" / "art" / "icons" / "camrol" / "camrol01.png").convert("RGB")
    )
    expect(np.array_equal(cam01, f81[169:183, 182:207]), "081 ROLE icon != camrol01 (KEEPER)")
    cam09 = np.asarray(
        Image.open(ROOT / "app" / "art" / "icons" / "camrol" / "camrol09.png").convert("RGB")
    )
    expect(np.array_equal(cam09, f84[169:183, 182:207]), "084 ROLE icon != camrol09 (C.FORWARD)")
    star = np.asarray(
        Image.open(ROOT / "app" / "art" / "screens" / "teamoffer" / "star_full.png").convert("RGB")
    )
    half = np.asarray(
        Image.open(ROOT / "app" / "art" / "screens" / "teamoffer" / "star_half.png").convert("RGB")
    )
    # halves = (value+1) div 10 (the rule fitting ALL star observations to date):
    # VdG PO77 -> 3 full + half; PA21/RM23/RG19/EN19/TI25 -> 1 full each
    for i, (fulls, halfs) in {
        0: (3, 1),
        1: (1, 0),
        2: (1, 0),
        3: (1, 0),
        4: (1, 0),
        5: (1, 0),
    }.items():
        gy = SKILL_Y0 + SKILL_PITCH * i + 1
        for j in range(fulls):
            gx = STAR_X0 + STAR_PITCH * j
            expect(
                np.array_equal(star, f81[gy : gy + 8, gx : gx + 11]),
                f"081 full star mismatch row {i} pos {j}",
            )
        if halfs:
            gx = STAR_X0 + STAR_PITCH * fulls
            expect(np.array_equal(half, f81[gy : gy + 8, gx : gx + 11]), f"081 half star row {i}")

    # ---- state cuts -------------------------------------------------------------
    save(ring81, "ok_pr.png")

    # frame-rendered FICHA kit patch: MAN UTD at the 32x37 CARD slot (the same slot
    # the make-offer bake cut Blackpool 82.png from; the TEAM OFFER 24x33 slot cut
    # lives in art/screens/teamoffer/ — see build_team_offer_chrome_from_frames.py)
    kit_dir = ROOT / "app" / "art" / "kits" / "ficha"
    kit_dir.mkdir(parents=True, exist_ok=True)
    Image.fromarray(cut(f81, KIT).astype("uint8")).save(kit_dir / "40.png")
    print("  app/art/kits/ficha/40.png  frame-rendered FICHA kit patch (MAN UTD, 32x37)")

    # ---- clear the dynamic fields to resting -------------------------------------
    a = f79.copy()
    # photo block (borderless, on card white left of the navy bar)
    fill(a, PHOTO, (255, 255, 255))
    # name text on the solid navy zone (fade ramp x528+ holds no text in any frame)
    row_median_inpaint(a, *NAME_INPAINT, margin=14)
    # position word (pure card white)
    pw = erase_to_white(a, *POSWORD_ZONE, "posword")
    # AGE / WEIGHT / HEIGHT value strips
    for r in VAL_STRIPS:
        row_median_inpaint(a, *r, margin=5)
    # NATIONALITY / KIND (flat grey 128). The mini flag occupies the strip's LEFT
    # margin — a naive margin-median там mixes flag colours into every replaced
    # pixel (the 084 NORWAY smear caught by the first parity run) — so the flag
    # zone is flat-filled first and the text inpaint samples right of it.
    fill(a, (NAT_STRIP[0], NAT_STRIP[1], 156, NAT_STRIP[3]), (128, 128, 128))
    row_median_inpaint(a, 156, NAT_STRIP[1], NAT_STRIP[2], NAT_STRIP[3], margin=4)
    row_median_inpaint(a, *KIND_STRIP, margin=4)
    # ROLE: sprite cell backing + the word on the teal band
    fill(a, CAMROL, (140, 170, 30))
    row_median_inpaint(a, *ROLE_BAND, margin=4)
    # STATUS / INSURANCE
    row_median_inpaint(a, *STATUS_STRIP, margin=4)
    fill(a, INSUR_FILL, (59, 85, 130))
    # kit art (card white) + club name (flat grey bar, ink from x162)
    fill(a, KIT, (255, 255, 255))
    fill(a, CLUBNAME_BAR, FIELD)
    # stat value cells + RATING digits
    for i in range(6):
        y = STAT_Y0 + i * STAT_PITCH
        row_median_inpaint(a, STAT_CELL_X[0], y, STAT_CELL_X[1], y + 9, margin=3)
    fill(a, RATING_FILL, FIELD)
    # skill chips (stars on pure black) + values (card white)
    for i in range(6):
        y = SKILL_Y0 + i * SKILL_PITCH
        fill(a, (CHIP_X[0], y, CHIP_X[1], y + 11), (0, 0, 0))
        fill(a, (SKILL_VAL_X[0], y, SKILL_VAL_X[1], y + 11), (255, 255, 255))
    # contract figures (flat bar/box fills)
    fill(a, FEE_BAR, (212, 63, 0))
    fill(a, WAGE_BAR, (42, 63, 170))
    fill(a, YEARS_INT, (80, 110, 5))
    fill(a, LEFT_INT, (42, 95, 85))
    # the whole clause zone below the CLAUSES: header — boxes, labels, sub-lines
    # are ALL state (PlayerInfoScreen redraws every combination, incl. the
    # never-walked Free-washed resting look, extrapolated widget doctrine)
    fill(a, CLAUSE_WIPE, FIELD)

    save(cut(a, CARD), "chrome.png")

    # ---- pre-baked dim of the management background --------------------------------
    # The card palette-dims the WHOLE host screen through the alert dim LUT
    # (081-vs-082: every squad-screen colour maps through alert/dim_lut.json with
    # zero unknowns). PMChrome.draw_bg swaps to this texture under set_dim, the
    # MenuScreen menu_bg_dim precedent — no per-pixel runtime pass.
    lut = {
        tuple(int(v) for v in k.split(",")): tuple(int(v) for v in vv.split(","))
        for k, vv in json.loads(
            (ROOT / "app" / "art" / "screens" / "alert" / "dim_lut.json").read_text()
        ).items()
    }
    bg = np.asarray(
        Image.open(ROOT / "app" / "art" / "screens" / "management_bg.png").convert("RGB")
    )
    flat = bg.reshape(-1, 3)
    dimmed = np.empty_like(flat)
    cache: dict = {}
    miss = 0
    for i, px in enumerate(map(tuple, flat)):
        r = cache.get(px)
        if r is None:
            r = lut.get(px)
            if r is None:  # colours outside the captured LUT: the fitted multiply
                r = (int(px[0] * 0.63), int(px[1] * 0.63), int(px[2] * 0.65))
                miss += 1
            cache[px] = r
        dimmed[i] = r
    save(dimmed.reshape(bg.shape), "management_bg_dim.png")
    print(f"    dim LUT misses: {miss} unique colours (fitted-multiply fallback)")

    samples = {
        "card": list(CARD),
        "coin": list(COIN),
        "photo": list(PHOTO),
        "name_xy": [171, 77],
        "posword_bbox": list(pw),
        "posword_cx": 245.5,
        "val_y": 127,
        "val_cx": {"age": 171.0, "weight": 236.5, "height": 301.5},
        "nat_flag_xy": [141, 154],
        "nat_cx": 204.0,
        "kind_cx": 304.0,
        "ident_y": 154,
        "camrol_xy": [182, 169],
        "role_cx": 279.0,
        "role_y": 171,
        "status_cx": 200.5,
        "insur_cx": 307.5,
        "status_y": 201,
        "kit_rect": list(KIT),
        "clubname_xy": [162, 218],
        "stat_cx": 484.0,
        "stat_y0": 104,
        "stat_pitch": STAT_PITCH,
        "rating_c": [525, 131],
        "skill": {
            "y0": SKILL_Y0,
            "pitch": SKILL_PITCH,
            "chip_x": list(CHIP_X),
            "star_x0": STAR_X0,
            "star_pitch": STAR_PITCH,
            "val_cx": 535.0,
        },
        "fee_bar": list(FEE_BAR),
        "wage_bar": list(WAGE_BAR),
        "years_int": list(YEARS_INT),
        "left_int": list(LEFT_INT),
        "money_cx": 252.0,
        "fee_val_y": 279,
        "wage_val_y": 309,
        "years_c": [207.5, 341],
        "left_c": [293.5, 341],
        "checkbox_x": CB_X,
        "checkbox_ys": CB_YS,
        "label_x": LABEL_X,
        "sub_y": {str(k): v for k, v in SUB_Y.items()},
        "buttons": {k: list(v) for k, v in BTNS.items()},
        "ok_pr_rect": list(OK_PR),
        "colors": {
            "field": list(FIELD),
            "washed": list(WASHED),
            "check_red": list(CHECK_RED),
            "money_gold": [255, 223, 0],
            "wage_pale": [180, 200, 220],
            "years_digit": [200, 230, 60],
            "left_digit": [42, 191, 85],
            "rating_navy": [59, 85, 130],
        },
    }
    SPECS.mkdir(parents=True, exist_ok=True)
    out = SPECS / "ficha_chrome_samples.json"
    out.write_text(json.dumps(samples, indent=1) + "\n")
    print(f"  {out.relative_to(ROOT)}")
    app_out = ROOT / "app" / "data" / "ficha_chrome_samples.json"
    app_out.write_text(json.dumps(samples, indent=1) + "\n")
    print(f"  {app_out.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
