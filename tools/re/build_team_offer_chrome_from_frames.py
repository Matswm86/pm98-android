#!/usr/bin/env python3
"""Bake the TEAM OFFER card STATIC CHROME from the real game's own frames.

Same doctrine as build_entry_chrome_from_frames.py (owner: "IT NEEDS TO BE EXACT"):
the card is engine-composited at runtime and no single PKF asset holds it, so the
chrome layer IS the original frame with the player/offer-dependent pixels cleared
to a resting look; TeamOfferScreen draws the dynamic layer (name, values, stars,
flags, offer rows, button states) on top with the game's own PROMAN fonts + art.

Binding frames (run-3, screenshots/original-walkthrough-2026-07-02, 641x480 —
rightmost column is a capture artifact, cropped):
  086_164647  Thornley card, row-1 REFUSE solid, "Free if relegated" checked   BASE
  087_164648  row-1 ACCEPT pressed (red inner outline)
  088_164650  row-1 ACCEPT settled
  089_164652  OK pressed (red inner outline)
  090_164654  McClair card (BIGFOTO photo present)
  091_164656  row-1 REFUSE pressed
  150_164913  Clegg card — ALL FOUR clauses washed (the model-true resting state)

Outputs (under app/art/screens/teamoffer/):
  chrome.png        443x469  frame 086 modal crop (98,5)-(541,474), every
                             player/offer-dependent field cleared to resting:
                             empty offer rows + washed answer chips, all clauses
                             washed (150's pixels), value strips/cells emptied
  btn_refuse_on.png 91x17    row-1 solid REFUSE chip (086)
  btn_accept_on.png 91x17    row-1 solid ACCEPT chip (088)
  btn_refuse_pr.png 91x17    pressed REFUSE (091: red inner outline)
  btn_accept_pr.png 91x17    pressed ACCEPT (087)
  ok_pr.png         91x29    pressed OK chip (089)
  clause_on.png     114x11   checked+active "Free if relegated" row (086)
  photo_block.png            the BIGFOTO block cut from 090 (frame border only,
                             interior cleared — the screen blits the face art in)
  tools/re/specs/team_offer_chrome_samples.json  sampled colours + rects
  (mirrored to app/data/team_offer_chrome_samples.json)

Every measured invariant is asserted against the frames so a regenerated
walkthrough or a bad crop fails loudly instead of baking garbage.

Run from anywhere:  python3 tools/re/build_team_offer_chrome_from_frames.py
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
ART = ROOT / "app" / "art" / "screens" / "teamoffer"
SPECS = Path(__file__).resolve().parent / "specs"

F086 = "086_164647.png"
F087 = "087_164648.png"
F088 = "088_164650.png"
F089 = "089_164652.png"
F090 = "090_164654.png"
F091 = "091_164656.png"
F150 = "150_164913.png"

# The modal rect on screen (black frame incl.): x 98..540, y 5..473 inclusive.
MODAL = (98, 5, 541, 474)

# Answer-chip zone for offer row 0: x 446..536; the SOLID chip renders y 370..382
# (black double frame) + drop-shadow rows y 383..385 that darken the washed chip
# below (frame truth: chip-1's rim reads (100,114) under the solid vs the clean
# (128,128) rim everywhere else). The pressed red outline extends y 368..384
# (diff(087,086)), so the state-texture window is y 368..386. The WASHED chip is a
# 14-row period [128,128 | 160 | interior x7 | 160 | 128,128] starting at
# y 370+14i for row i (chips 2-4 periods pixel-identical, asserted).
CHIP = (446, 368, 537, 386)  # x0,y0,x1,y1 exclusive; state-texture window
ROW_PITCH = 14
N_ROWS = 5
WASH2_Y = 398  # chip-2's washed period start (clean environment, y 398..411)
# offer-list interior (the 240,240,240 row strips between the grey separators).
# x starts AFTER the scroll rail/arrow column (the lit UP arrow spans x114..127
# at row-0 height and is static rail furniture that must stay baked).
LIST_X0, LIST_X1 = 129, 446
ROW0_Y0, ROW0_Y1 = 370, 383
# OK chip (diff(089,088) bbox == pressed extent)
OK = (446, 442, 537, 471)
# clause row 1 (diff(150,086) bbox: checkbox + label wash)
CLAUSE = (327, 244, 441, 255)
# skill strip: 6 all-black chip rows (11 rows each), star glyph grid
SKILL_Y0, SKILL_PITCH = 144, 13
STAR_X0, STAR_PITCH = 426, 14


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


def dither_inpaint(
    a: np.ndarray, x0: int, y0: int, x1: int, y1: int, mx0: int, mx1: int, thresh: int = 40
) -> None:
    """Erase text/art from a 2-tone-dithered strip without breaking the checker
    phase: per row, compute the even-x and odd-x medians of the clean margin
    [mx0,mx1), then replace every pixel deviating > thresh from its own parity's
    median with that median. (PM98 washes bands with per-pixel checkers; a plain
    median fill leaves a lattice ghost.)"""
    for y in range(y0, y1):
        row = a[y].astype(int)
        marg = np.arange(mx0, mx1)
        med = {p: np.median(row[marg[marg % 2 == p]], axis=0) for p in (0, 1)}
        for x in range(x0, x1):
            pm = med[x % 2]
            if np.abs(row[x] - pm).mean() > thresh:
                a[y, x] = pm


def fill(a: np.ndarray, x0: int, y0: int, x1: int, y1: int, rgb: tuple) -> None:
    a[y0:y1, x0:x1] = rgb


def erase_to_white(a: np.ndarray, x0: int, y0: int, x1: int, y1: int, tag: str) -> tuple:
    """White-fill the bbox of the non-white art inside a card-white region;
    returns the measured bbox (asserts something was there)."""
    reg = a[y0:y1, x0:x1]
    m = reg.min(axis=2) < 200
    ys, xs = np.where(m)
    expect(ys.size > 0, f"{tag}: nothing to erase in ({x0},{y0})-({x1},{y1})")
    bb = (x0 + int(xs.min()), y0 + int(ys.min()), x0 + int(xs.max()) + 1, y0 + int(ys.max()) + 1)
    fill(a, bb[0], bb[1], bb[2], bb[3], (255, 255, 255))
    return bb


def cut(a: np.ndarray, r: tuple) -> np.ndarray:
    return a[r[1] : r[3], r[0] : r[2]].copy()


def shift(r: tuple, dy: int) -> tuple:
    return (r[0], r[1] + dy, r[2], r[3] + dy)


def main() -> None:
    f086 = load(F086)
    f087 = load(F087)
    f088 = load(F088)
    f089 = load(F089)
    f090 = load(F090)
    f091 = load(F091)
    f150 = load(F150)

    # ---- frame invariants ---------------------------------------------------
    expect(tuple(f086[8, 300]) == (17, 127, 43), "086 TEAM OFFER green band")
    expect(tuple(f086[240, 100]) == (255, 255, 255), "086 card white body")
    d = np.abs(f087.astype(int) - f086.astype(int)).mean(axis=2) > 8
    ys, xs = np.where(d)
    expect(
        (xs.min(), xs.max(), ys.min(), ys.max()) == (446, 536, 368, 384),
        f"answer-chip rect drifted: {xs.min()},{xs.max()},{ys.min()},{ys.max()}",
    )
    d = np.abs(f089.astype(int) - f088.astype(int)).mean(axis=2) > 8
    ys, xs = np.where(d)
    expect(
        (xs.min(), xs.max(), ys.min(), ys.max()) == (446, 536, 442, 470),
        f"OK rect drifted: {xs.min()},{xs.max()},{ys.min()},{ys.max()}",
    )
    d = np.abs(f150.astype(int) - f086.astype(int)).mean(axis=2) > 8
    d[:, : CLAUSE[0]] = False
    d[: CLAUSE[1] - 4], d[CLAUSE[3] + 4 :] = False, False
    ys, xs = np.where(d)
    expect(
        xs.min() >= 327 and xs.max() <= 440 and ys.min() >= 244 and ys.max() <= 254,
        f"clause-1 rect drifted: {xs.min()},{xs.max()},{ys.min()},{ys.max()}",
    )
    # washed answer chips: the 14-row periods of rows 2..4 (clean environment,
    # no solid-chip shadow above) are pixel-identical to each other (086)
    per2 = f086[WASH2_Y : WASH2_Y + ROW_PITCH, CHIP[0] : CHIP[2]]
    for i in (1, 2):
        y = WASH2_Y + ROW_PITCH * i
        expect(
            np.array_equal(per2, f086[y : y + ROW_PITCH, CHIP[0] : CHIP[2]]),
            f"washed chip period row {2 + i} != row 2",
        )

    # ---- state textures -----------------------------------------------------
    save(cut(f086, CHIP), "btn_refuse_on.png")
    save(cut(f088, CHIP), "btn_accept_on.png")
    save(cut(f091, CHIP), "btn_refuse_pr.png")
    save(cut(f087, CHIP), "btn_accept_pr.png")
    save(cut(f089, OK), "ok_pr.png")
    save(cut(f086, CLAUSE), "clause_on.png")

    # photo block (090; Thornley's 086 has none — photo-less IS the resting bake).
    # diff(090,086) left of the name text gives the block extent (x 106..140,
    # y 39..73); clear the interior so the screen can blit any BIGFOTO face into
    # it (the original downscales the 124x182 BIGFOTO to the 33x33 interior with
    # an unknown kernel — the screen's NEAREST fit is a documented approximation).
    d = np.abs(f090.astype(int) - f086.astype(int)).mean(axis=2) > 8
    d[:, 150:] = False
    d[74:] = False
    ys, xs = np.where(d)
    pb = (int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1)
    photo = cut(f090, pb)
    # interior = everything inside the 1px border; cleared to black resting
    photo[1:-1, 1:-1] = (0, 0, 0)
    save(photo, "photo_block.png")

    # ---- sampled colours (for the dynamic text layer) ------------------------
    def px(y, x):
        return [int(v) for v in f086[y, x]]

    # skill strip: 6 all-black chip rows at y 144+13i (11 rows tall, frame-mapped),
    # star glyphs (11x8 windows) at x 426+14j, y chip+1. Frame truth: halves =
    # value div 10 (17 -> half star, 70 -> 3.5, 64 -> 3, 67 -> 3, 53 -> 2.5,
    # 47 -> 2 in 086; 090's HEADING 79 -> 3.5 confirms). Cut a full star (HEADING
    # star 1) + the half glyph (HANDLING) and SAD-0-assert them at every position
    # the frame values imply.
    star = cut(f086, (426, 184, 437, 192))  # HEADING (chip y183) star 1
    half = cut(f086, (426, 145, 437, 153))  # HANDLING (chip y144) half glyph
    stars_by_row = {0: (0, 1), 1: (3, 1), 2: (3, 0), 3: (3, 0), 4: (2, 1), 5: (2, 0)}
    for i, (fulls, halfs) in stars_by_row.items():
        gy = SKILL_Y0 + SKILL_PITCH * i + 1
        for j in range(fulls):
            gx = STAR_X0 + STAR_PITCH * j
            expect(
                np.array_equal(star, f086[gy : gy + 8, gx : gx + 11]),
                f"full star mismatch row {i} pos {j}",
            )
        if halfs:
            gx = STAR_X0 + STAR_PITCH * fulls
            expect(
                np.array_equal(half, f086[gy : gy + 8, gx : gx + 11]),
                f"half star mismatch row {i}",
            )
    save(star, "star_full.png")
    save(half, "star_half.png")

    # the dynamic layer's own art is the game's own art: the NAT-band flag and
    # the offer-row flag ARE the MINIBAND minis (SAD 0.0), the ROLE icon IS the
    # exported camrol sprite (SAD 0.0) — asserted so a bad export fails loudly
    mini30 = np.asarray(
        Image.open(ROOT / "app" / "art" / "flags" / "mini_030.png").convert("RGB")
    ).astype(int)
    expect(np.array_equal(mini30, f086[125:135, 117:131]), "NAT-band flag != mini_030")
    expect(np.array_equal(mini30, f086[371:381, 134:148]), "offer-row flag != mini_030")
    cam18 = np.asarray(
        Image.open(ROOT / "app" / "art" / "icons" / "camrol" / "camrol18.png").convert("RGB")
    ).astype(int)
    expect(np.array_equal(cam18, f086[140:154, 158:183]), "ROLE icon != camrol18")

    # frame-rendered FICHA kit patch (kit render ≠ palette blit — the panel-kit
    # precedent): Man Utd is the only club any TEAM OFFER frame shows; the
    # screen falls back to scaled NANOESC art for the rest (documented).
    dbj = json.loads((ROOT / "app" / "data" / "game_db.json").read_text(encoding="utf-8"))
    manu = next(
        c for lg in dbj["leagues"] for c in dbj["clubs"]
        if c.get("name") == "MANCHESTER UTD."
    )
    kit_dir = ROOT / "app" / "art" / "kits" / "ficha"
    kit_dir.mkdir(parents=True, exist_ok=True)
    # 24x33 at (112,181): covers the chrome's whole kit-erase scan window, so
    # the patch restores every pixel the erase could have whitened (the kit's
    # shadow tail reaches y213)
    Image.fromarray(f086[181:214, 112:136].astype("uint8")).save(kit_dir / f"{manu['id']}.png")
    print("  app/art/kits/ficha/  frame-rendered FICHA kit patch (MANCHESTER UTD.)")

    samples = {
        "modal": list(MODAL),
        "chip": list(CHIP),
        "row_pitch": ROW_PITCH,
        "n_rows": N_ROWS,
        "list_x": [LIST_X0, LIST_X1],
        "row0_y": [ROW0_Y0, ROW0_Y1],
        "ok": list(OK),
        "clause": list(CLAUSE),
        "clause_rows_y": [244, 262, 288, 314],
        "skill": {"y0": SKILL_Y0, "pitch": SKILL_PITCH, "star_x0": STAR_X0,
                  "star_pitch": STAR_PITCH, "chip_x": [425, 498], "val_x": [500, 527]},
        "photo_block": list(pb),
        "name_text": px(52, 160),          # white
        "posword_text": px(76, 185),       # black
        # text colours = the darkest pixel of each glyph region (bg is lighter)
        "rating_text": [
            int(v) for v in min(f086[101:118, 484:521].reshape(-1, 3), key=lambda p: p.sum())
        ],
        "fee_text": [
            int(v) for v in f086[250:259, 193:292].reshape(-1, 3).max(axis=0)
        ],                                  # brightest = the gold digits
        "years_digit": [200, 230, 60],
        "left_digit": [42, 191, 85],
        "club_text": [
            int(v) for v in min(f086[371:381, 155:300].reshape(-1, 3), key=lambda p: p.sum())
        ],
        "amount_text": [
            int(v) for v in min(f086[371:381, 350:432].reshape(-1, 3), key=lambda p: p.sum())
        ],
        "flag_xy": [134, 371],
        "nat_flag_xy": [117, 125],
        "mini_flag": [14, 10],
        "kit_bbox_cut": [112, 181, 136, 214],
    }
    return_finish(f086, f150, samples)


def return_finish(f086: np.ndarray, f150: np.ndarray, samples: dict) -> None:
    a = f086.copy()

    # ---- clear the dynamic fields to resting --------------------------------
    # name band "Ben THORNLEY" (dark-blue bar y46..64; text sits x126..430, flat zone)
    row_median_inpaint(a, 126, 46, 430, 65, margin=14)
    # position word "MIDFIELDER" (black on pure card white; scan stops at x330
    # so the stat panel's left edge never enters the bbox)
    pw = erase_to_white(a, 140, 68, 330, 85, "posword")
    # AGE / WEIGHT / HEIGHT value strips
    row_median_inpaint(a, 117, 97, 177, 109, margin=6)
    row_median_inpaint(a, 182, 97, 242, 109, margin=6)
    row_median_inpaint(a, 247, 97, 327, 109, margin=6)
    # club kit art (on card white, left of the grey club-name bar). Erased FIRST:
    # its collar rows poke into the STATUS band, and the band inpaint below
    # repairs the overlap rows with the band's own dither.
    kb = erase_to_white(a, 104, 181, 135, 214, "kit")
    # NATIONALITY (flag at x117..130 + name, band x116..228) / KIND (x234..327)
    # value bands, rows 124..135: 2-tone washed dither — parity-median rebuild
    # from each band's clean text-free margin
    dither_inpaint(a, 117, 124, 227, 136, 210, 226)
    dither_inpaint(a, 235, 124, 326, 136, 236, 252)
    # ROLE row (y140..153): camrol icon (25x14 at (158,140), SAD 0.0 == the
    # exported camrol18 sprite) + fine-role word, both on the teal band. The
    # pixels UNDER the icon are unseen in every frame — extending the teal
    # dither there is the documented assumption; the screen always draws a
    # camrol sprite on top at (158,140).
    dither_inpaint(a, 158, 140, 311, 154, 312, 325)
    # STATUS (x116..238) / INSURANCE (darker slate, x241..327) value bands,
    # rows 171..182
    dither_inpaint(a, 117, 171, 237, 183, 120, 160)
    dither_inpaint(a, 242, 171, 326, 183, 243, 262)
    # club name (grey 220 bar)
    row_median_inpaint(a, 137, 186, 327, 200, margin=6)
    samples["posword_bbox"] = list(pw)
    samples["role_icon_xy"] = [158, 140]
    samples["kit_bbox"] = list(kb)
    # six stat value cells (pale green) + RATING box
    for i in range(6):
        y = 76 + i * 10
        row_median_inpaint(a, 449, y, 471, y + 9, margin=3)
    row_median_inpaint(a, 482, 100, 522, 119, margin=4)
    # skill strip (chips at y 144+13i, 11 rows): star glyphs sit on pure black
    # chip interiors x 425..498; the value digits on card white x 500..526
    for i in range(6):
        y = SKILL_Y0 + i * SKILL_PITCH
        fill(a, 425, y, 498, y + 11, (0, 0, 0))
        fill(a, 500, y, 527, y + 11, (255, 255, 255))
    # CONTRACT values: CLUB FEE / YEARLY WAGE bar interiors (dithered). BOTH
    # bars end at x300 in every frame — the earlier x335 "fee bar" reading was
    # the checked clause's red box in the mask, not the bar.
    dither_inpaint(a, 158, 249, 298, 260, 160, 172)
    dither_inpaint(a, 157, 280, 298, 290, 160, 172)
    # YEARS / LEFT boxes: FLAT interiors (no dither; frame-truth 086+150), the
    # digit centred in the box (YEARS interior x156..211, digit x180..186 in
    # both frames). Measure each interior run on a digit-free row and flat-fill.
    for seed_x, col in ((195, (80, 110, 5)), (275, (42, 95, 85))):
        row = a[312]
        x0 = seed_x
        while x0 > 150 and tuple(row[x0 - 1]) == col:
            x0 -= 1
        x1 = seed_x
        while x1 < 340 and tuple(row[x1 + 1]) == col:
            x1 += 1
        expect(30 <= x1 - x0 <= 60, f"contract box run {x0}..{x1} implausible")
        fill(a, x0, 311, x1 + 1, 323, col)
    # clause row 1 -> the washed resting pixels from 150 (Clegg: no clauses)
    a[CLAUSE[1] : CLAUSE[3], CLAUSE[0] : CLAUSE[2]] = cut(f150, CLAUSE)
    # offer row 0 -> row 1's empty list strip (exact same dither phase every 14
    # rows), and the solid REFUSE chip -> a washed chip: copy chip-2's clean
    # 14-row period up by 28 (even shift keeps phase), then restore chip-1's rim
    # rows y 384..385 (darkened by the solid chip's drop shadow in 086) from
    # chip-2's clean rim.
    a[ROW0_Y0:ROW0_Y1, LIST_X0:LIST_X1] = f086[
        ROW0_Y0 + ROW_PITCH : ROW0_Y1 + ROW_PITCH, LIST_X0:LIST_X1
    ]
    a[370:384, CHIP[0] : CHIP[2]] = f086[WASH2_Y : WASH2_Y + ROW_PITCH, CHIP[0] : CHIP[2]]
    a[384:386, CHIP[0] : CHIP[2]] = f086[WASH2_Y + ROW_PITCH : WASH2_Y + ROW_PITCH + 2, CHIP[0] : CHIP[2]]

    save(cut(a, MODAL), "chrome.png")

    SPECS.mkdir(parents=True, exist_ok=True)
    out = SPECS / "team_offer_chrome_samples.json"
    out.write_text(json.dumps(samples, indent=1) + "\n")
    print(f"  {out.relative_to(ROOT)}")
    app_out = ROOT / "app" / "data" / "team_offer_chrome_samples.json"
    app_out.write_text(json.dumps(samples, indent=1) + "\n")
    print(f"  {app_out.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
