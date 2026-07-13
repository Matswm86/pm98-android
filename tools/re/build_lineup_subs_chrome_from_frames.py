#!/usr/bin/env python3
"""Bake the LINE-UP sub-screens (TRAINING / INJURIES / STATISTICS) body chrome
from the real game's walkthrough frames.

Entry-flow doctrine (build_lineup_chrome_from_frames.py precedent): the body
chrome IS a binding frame with every squad/state-dependent pixel cleared to a
resting look; the scenes draw only the dynamic layer on top with the game's own
PROMAN fonts + frame-cut sprites.

Binding frames (all run 2, Mon 4 Aug 1997, Manchester Utd):
  TRAINING    004_162346  fresh state — no focus tags, TOTAL 0, right panel
                          resting, staff band full (6 coaches + TP + 25).
                          Cursor sits on AUTO -> that region is patched from 007
                          (asserted identical in 007/008).
              005_162348  after AUTO: HA/TA/PA/SH tag chips + TOTAL 16.
              006_162350  Keane selected (black row, right panel stars/values).
              007_162352  McClair selected (NO focus -> no checkbox/box row).
              010_162401  Butt selected, PASSING focus row (yellow checkbox +
                          red arrow + boxed label + grey "last" box w/ 70 +
                          navy AV cell w/ white 70).
  INJURIES    034_162510  empty list (no injuries) — the whole body is resting
                          furniture. Cursor sits on INSURANCE -> patched from
                          039_162530 (whose cursor is on RETURN).
              035_162522  INSURANCE pressed (cursor state only; not used).
  STATISTICS  069_162642  XI-only visit: rows 1-11 filled, 12-19 EMPTY (the
                          empty-slot look), TEAM TOTAL sparse.
              042_162537 / 043_162539 / 044_162540  full-squad visit (19 rows);
                          used with 069/070/071 to median the cursor off RETURN.
              147_154839  run-1 zero state (all dashes) — witness only.

Everything cut here is verbatim frame pixels; the only reconstructions are
flat-fill inpaints over cells whose surroundings are asserted flat, and the
hot UP scroll arrow (un-witnessed at scroll 0) as the vertical flip of the
witnessed hot DOWN arrow — both flagged in docs/re/training_screen_re.md.

Outputs: app/art/screens/training/ , app/art/screens/injuries/ ,
app/art/screens/stats/ + tools/re/specs/lineup_subs_samples.json.

Run from anywhere:  python3 tools/re/build_lineup_subs_chrome_from_frames.py
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
FRAMES = ROOT / "screenshots" / "original-walkthrough-2026-07-02"
ART_T = ROOT / "app" / "art" / "screens" / "training"
ART_I = ROOT / "app" / "art" / "screens" / "injuries"
ART_S = ROOT / "app" / "art" / "screens" / "stats"
SPECS = Path(__file__).resolve().parent / "specs"

BODY_Y0 = 62

F_TR0, F_TR1, F_TR_K, F_TR_M, F_TR_B = (
    "004_162346.png",
    "005_162348.png",
    "006_162350.png",
    "007_162352.png",
    "010_162401.png",
)
F_TR_C = "008_162354.png"  # witness: cursor-free button band, == 007 there
F_INJ, F_INJ_R = "034_162510.png", "039_162530.png"
F_ST, F_ST_B, F_ST_C = "069_162642.png", "042_162537.png", "043_162539.png"
F_ST_D, F_ST_E, F_ST_F = "044_162540.png", "070_162644.png", "071_162646.png"
F_ST_W = "147_154839.png"  # run-1 zero-state witness (cursor-free RETURN)

# ---- frame-decoded geometry (probed 2026-07-12, this session) --------------
# TRAINING left grid: white panel x7..337, header band y69..87 ("N. KEEPERS FI AV"),
# 19 row bars fill (240,240,240) x16..286 h13, tag cell x286..313 (white box),
# per-section scroll strip x~315..333, TOTAL band y457..467 + value cell x287..311.
TR_SECT_TOPS = {
    "gk": [88, 104],
    "def": [151, 167, 183, 199, 215, 231],
    "mid": [263, 279, 295, 311, 327, 343],
    "fwd": [375, 391, 407, 423, 439],
}
TR_BAR_X0, TR_BAR_X1, TR_BAR_H = 16, 286, 13
TR_TAG_X0, TR_TAG_X1 = 284, 316
TR_STAR_X0, TR_STAR_PITCH = 163, 14
# right panel: checkbox rows GENERAL 116 + FITNESS..SHOOTING 186+14i; sub-rows
# (SPEED..QUALITY) 130+14i; stars x481 pitch 14; last box x554..594 fill 220;
# AV cell x597..624 fill (180,200,220) ink (59,85,130); focused: last fill 192
# black ink, AV fill (59,85,130) white ink; checkbox x356..369 grey / yellow.
TR_RP_FOCUS_Y = 214  # PASSING row top (checkbox y214..223) in 010
# staff band: 6 rows, label plate x351..437 (200,220,240), name bar x439..606,
# TP cell x608..632 (60,90,0); bar fills (probed x=500):
TR_STAFF_TOPS = [318, 334, 350, 366, 382, 398]
TR_STAFF_H = 14
TR_STAFF_FILLS = [
    (212, 95, 0),
    (212, 63, 0),
    (210, 0, 0),
    (170, 0, 0),
    (150, 0, 0),
    (85, 0, 0),
]

# INJURIES: rows (220,220,220) h16 pitch 20, sections GOAL/DEF/MID/FOR 3/4/4/3.
INJ_SECT_TOPS = {
    "gk": [105, 125, 145],
    "def": [174, 194, 214, 234],
    "mid": [262, 282, 302, 322],
    "fwd": [350, 370, 390],
}

# STATISTICS: 19 row bars (240,240,240) h13 pitch 16 tops 111+16i, table
# interior x19..577, scroll col x578..593, total band y425..437 (166,202,240).
ST_ROW_TOPS = [111 + 16 * i for i in range(19)]
ST_BAR_H = 13


def load(name: str) -> np.ndarray:
    a = np.asarray(Image.open(FRAMES / name).convert("RGB")).astype(np.uint8)
    assert a.shape[0] == 480 and a.shape[1] in (640, 641), f"{name}: {a.shape}"
    return a[:, :640].copy()  # walkthrough frames carry a 641st junk column


def save(arr: np.ndarray, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(arr).save(path)
    print(f"  wrote {path.relative_to(ROOT)}  {arr.shape[1]}x{arr.shape[0]}")


def save_rgba(arr: np.ndarray, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(arr, "RGBA").save(path)
    print(f"  wrote {path.relative_to(ROOT)}  {arr.shape[1]}x{arr.shape[0]} (alpha)")


def fill(img: np.ndarray, x0: int, y0: int, x1: int, y1: int, c) -> None:
    img[y0:y1, x0:x1] = c


def cut(img: np.ndarray, x0: int, y0: int, x1: int, y1: int) -> np.ndarray:
    return img[y0:y1, x0:x1].copy()


def keyed(patch: np.ndarray, key) -> np.ndarray:
    """RGBA sprite: pixels equal to `key` become transparent."""
    h, w = patch.shape[:2]
    out = np.zeros((h, w, 4), dtype=np.uint8)
    out[:, :, :3] = patch
    mask = ~np.all(patch == np.array(key, dtype=np.uint8), axis=2)
    out[:, :, 3] = mask.astype(np.uint8) * 255
    return out


def assert_flat(img: np.ndarray, x0, y0, x1, y1, c, label, tol_frac=0.0) -> None:
    region = img[y0:y1, x0:x1]
    bad = np.count_nonzero(~np.all(region == np.array(c, dtype=np.uint8), axis=2))
    total = region.shape[0] * region.shape[1]
    if bad > total * tol_frac:
        raise AssertionError(f"{label}: {bad}/{total} px differ from {c}")


def assert_equal(a: np.ndarray, b: np.ndarray, x0, y0, x1, y1, label) -> None:
    if not np.array_equal(a[y0:y1, x0:x1], b[y0:y1, x0:x1]):
        n = np.count_nonzero(np.any(a[y0:y1, x0:x1] != b[y0:y1, x0:x1], axis=2))
        raise AssertionError(f"{label}: {n} px differ")


def title_sprite(frame: np.ndarray, out: Path) -> list[int]:
    """Cut the barra title glyphs: pixels differing from the baked band.png
    inside the title zone x150..435, y6..58 (chips/calendar/shirt icon are
    outside; the icon's right edge reaches x140, hence the 150 start)."""
    band = np.asarray(
        Image.open(ROOT / "app" / "art" / "screens" / "header" / "band.png").convert(
            "RGB"
        )
    ).astype(np.uint8)
    zone = (slice(6, 58), slice(150, 435))
    diff = np.any(frame[zone] != band[zone], axis=2)
    ys, xs = np.nonzero(diff)
    assert len(xs) > 100, "title glyphs not found vs band.png"
    x0, x1, y0, y1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
    patch = frame[6 + y0 : 6 + y1, 150 + x0 : 150 + x1]
    mask = diff[y0:y1, x0:x1]
    rgba = np.zeros((*patch.shape[:2], 4), dtype=np.uint8)
    rgba[:, :, :3] = patch
    rgba[:, :, 3] = mask.astype(np.uint8) * 255
    save_rgba(rgba, out)
    return [int(150 + x0), int(6 + y0)]


# ---------------------------------------------------------------------------
def build_training(samples: dict) -> None:
    print("== TRAINING ==")
    f0, f1 = load(F_TR0), load(F_TR1)
    fk, fm, fb = load(F_TR_K), load(F_TR_M), load(F_TR_B)
    fc = load(F_TR_C)

    # --- title sprite (dynamic barra title; band.png carries no title) ---
    samples["training_title_xy"] = title_sprite(f0, ART_T / "title.png")

    chrome = f0[BODY_Y0:480].copy()  # 640x418, drawn at (0,62)

    def cf(x0, y0, x1, y1, c):  # fill in chrome coords (design y - BODY_Y0)
        fill(chrome, x0, y0 - BODY_Y0, x1, y1 - BODY_Y0, c)

    # cursor patch: the 004 cursor sits on the AUTO button; 007 and 008 are
    # cursor-free and identical there (asserted) -> patch from 007.
    AUTO = (348, 444, 434, 474)
    assert_equal(fm, fc, *AUTO, "007==008 over AUTO button")
    chrome[AUTO[1] - BODY_Y0 : AUTO[3] - BODY_Y0, AUTO[0] : AUTO[2]] = fm[
        AUTO[1] : AUTO[3], AUTO[0] : AUTO[2]
    ]

    # rows: assert flat outside glyphs is impossible (glyphs everywhere), so
    # simply flatten every bar to its witnessed fill (240,240,240).
    for tops in TR_SECT_TOPS.values():
        for y in tops:
            cf(TR_BAR_X0, y, TR_BAR_X1, y + TR_BAR_H, (240, 240, 240))
    # TOTAL value cell ("0" digit off): green interior bbox x287..310 y455..466
    # (probed 004; digits y458..464 start at x292 -> left strip is digit-free).
    assert_flat(f0, 287, 456, 292, 467, (192, 220, 192), "TOTAL cell edge flat")
    cf(287, 455, 311, 467, (192, 220, 192))

    # staff bars: names/stars off -> per-row flat fill; TP digits off (60,90,0);
    # TOTAL TRAINABLE value off (42,63,170).
    for y, c in zip(TR_STAFF_TOPS, TR_STAFF_FILLS):
        cf(440, y, 605, y + TR_STAFF_H, c)
        cf(609, y, 632, y + TR_STAFF_H, (60, 90, 0))
    cf(609, 417, 632, 431, (42, 63, 170))

    # right panel is resting in 004 (no stars/values/name) — nothing to clean.
    save(chrome, ART_T / "chrome.png")

    # --- sprites -----------------------------------------------------------
    # grid stars: full from Schmeichel row (005, AV 88 -> 4 full), dim from
    # Keane row slot 4 (005, AV 89 -> 4 + dim). Key = bar fill 240.
    y = TR_SECT_TOPS["gk"][0]
    save_rgba(
        keyed(cut(f1, TR_STAR_X0, y, TR_STAR_X0 + 13, y + TR_BAR_H), (240, 240, 240)),
        ART_T / "star_on.png",
    )
    yk = TR_SECT_TOPS["mid"][3]
    x_dim = TR_STAR_X0 + 4 * TR_STAR_PITCH
    save_rgba(
        keyed(cut(f1, x_dim, yk, x_dim + 13, yk + TR_BAR_H), (240, 240, 240)),
        ART_T / "star_off.png",
    )
    # selected-row stars: opaque patches on the black bar (006 Keane).
    save_rgba(
        keyed(cut(fk, TR_STAR_X0, yk, TR_STAR_X0 + 13, yk + TR_BAR_H), (0, 0, 0)),
        ART_T / "star_sel_on.png",
    )
    save_rgba(
        keyed(cut(fk, x_dim, yk, x_dim + 13, yk + TR_BAR_H), (0, 0, 0)),
        ART_T / "star_sel_off.png",
    )

    # tag chips (005): HA row gk0, TA row def0, PA row mid0, SH row fwd0.
    for tag, sect in (("ha", "gk"), ("ta", "def"), ("pa", "mid"), ("sh", "fwd")):
        ty = TR_SECT_TOPS[sect][0]
        cell = cut(f1, TR_TAG_X0, ty - 2, TR_TAG_X1, ty + TR_BAR_H + 2)
        base = cut(f0, TR_TAG_X0, ty - 2, TR_TAG_X1, ty + TR_BAR_H + 2)
        diff = np.any(cell != base, axis=2)
        ys, xs = np.nonzero(diff)
        assert len(xs) > 40, f"tag {tag} not found"
        x0, x1, y0, y1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
        save(cell[y0:y1, x0:x1], ART_T / f"tag_{tag}.png")
        samples.setdefault("tag_xy", {})[tag] = [
            int(TR_TAG_X0 + x0),
            int(ty - 2 + y0) - ty,  # dy relative to the row bar top
            int(x1 - x0),
            int(y1 - y0),
        ]

    # right-panel stars (010 Butt SPEED row: 79 -> 4 full; PASSING dim slot 3).
    RP_STAR_X0, RP_PITCH = 481, 14
    sp_y = 130  # SPEED value/star row top
    save_rgba(
        keyed(cut(fb, RP_STAR_X0, sp_y, RP_STAR_X0 + 13, sp_y + 13), (255, 255, 255)),
        ART_T / "rp_star_on.png",
    )
    dim_x = RP_STAR_X0 + 3 * RP_PITCH
    save_rgba(
        keyed(cut(fb, dim_x, TR_RP_FOCUS_Y, dim_x + 13, TR_RP_FOCUS_Y + 13), (240, 240, 240)),
        ART_T / "rp_star_off.png",
    )
    # the sub-rows sit on white; the FITNESS..SHOOTING label strip is (240,240,240)
    # -> also cut a full star on the 240 strip (FITNESS row, 76 -> 3 full).
    fit_y = 186
    save_rgba(
        keyed(cut(fb, RP_STAR_X0, fit_y, RP_STAR_X0 + 13, fit_y + 13), (240, 240, 240)),
        ART_T / "rp_star_on_strip.png",
    )

    # focus row template (010 PASSING): cut x351..633 over the boxed row and
    # inpaint label text / stars / last digits / AV digits with their flat fills.
    FY0, FY1 = 211, 227  # box top/bottom rows incl. 1px border
    tpl = cut(fb, 351, FY0, 633, FY1)

    def tf(x0, y0, x1, y1, c):
        fill(tpl, x0 - 351, y0 - FY0, x1 - 351, y1 - FY0, c)

    tf(380, 213, 434, 225, (240, 240, 240))  # label glyphs
    tf(436, 213, 553, 225, (240, 240, 240))  # star zone up to the last box
    tf(555, 213, 593, 225, (192, 192, 192))  # "last" digits (grey box interior)
    tf(598, 213, 623, 225, (59, 85, 130))  # AV digits (navy cell interior)
    save(tpl, ART_T / "focus_row.png")
    samples["focus_row_xy"] = [351, FY0, 633 - 351, FY1 - FY0]

    # staff star glyph (004 row 1, on the orange bar) + witness ink samples.
    row1 = TR_STAFF_TOPS[0]
    band = cut(f0, 440, row1, 605, row1 + TR_STAFF_H)
    ys, xs = np.nonzero(np.any(band != np.array(TR_STAFF_FILLS[0], np.uint8), axis=2))
    # stars live right of the name text; find the rightmost glyph cluster
    star_px = xs[xs > 100]
    assert len(star_px) > 30, "staff stars not found"
    sx1 = star_px.max() + 1
    # glyph pitch: cut a 12px window ending at the last star
    patch = band[:, sx1 - 11 : sx1 + 1]
    save_rgba(keyed(patch, TR_STAFF_FILLS[0]), ART_T / "staff_star.png")
    samples["staff_star_x1"] = int(440 + sx1)

    # scroll strip: rebuild the strip cells so chrome carries the WASHED state
    # everywhere (Man Utd's DEF/MID/FWD are hot in the frames); sprites:
    # up_off + dn_off from the KEEPERS strip (2 keepers -> washed), dn_on from
    # the DEF strip (8 defenders -> hot), track tile + thumb from KEEPERS.
    STRIP_X0, STRIP_X1 = 315, 333
    gk_top, gk_bot = TR_SECT_TOPS["gk"][0], TR_SECT_TOPS["gk"][-1]
    def_top, def_bot = TR_SECT_TOPS["def"][0], TR_SECT_TOPS["def"][-1]
    up_off = cut(f0, STRIP_X0, gk_top, STRIP_X1, gk_top + 13)
    dn_off = cut(f0, STRIP_X0, gk_bot, STRIP_X1, gk_bot + 13)
    dn_on = cut(f0, STRIP_X0, def_bot, STRIP_X1, def_bot + 13)
    save(up_off, ART_T / "arrow_up_off.png")
    save(dn_off, ART_T / "arrow_dn_off.png")
    save(dn_on, ART_T / "arrow_dn_on.png")
    save(dn_on[::-1].copy(), ART_T / "arrow_up_on.png")  # RECONSTRUCTION (flagged)
    # track tile: the dither between keeper arrows (thumb-free row from DEF gap)
    track = cut(f0, STRIP_X0, def_top + 20, STRIP_X1, def_top + 24)
    save(track, ART_T / "track.png")
    thumb = cut(f0, STRIP_X0, gk_top + 14, STRIP_X1, gk_bot - 1)  # grey block
    save(thumb, ART_T / "thumb.png")
    # bake washed strips into chrome for every section
    for sect, tops in TR_SECT_TOPS.items():
        top, bot = tops[0], tops[-1]
        # clear the whole strip column with the track tile
        for ty in range(top, bot + 13, track.shape[0]):
            h = min(track.shape[0], bot + 13 - ty)
            chrome[ty - BODY_Y0 : ty - BODY_Y0 + h, STRIP_X0:STRIP_X1] = track[:h]
        chrome[top - BODY_Y0 : top - BODY_Y0 + 13, STRIP_X0:STRIP_X1] = up_off
        chrome[bot - BODY_Y0 : bot - BODY_Y0 + 13, STRIP_X0:STRIP_X1] = dn_off
    save(chrome, ART_T / "chrome.png")

    # witness ink samples for the doc (probed values, recorded for reference)
    samples["training_inks"] = {
        "grid_n": [0, 0, 128],
        "grid_fi": [42, 95, 170],
        "grid_av": [210, 0, 0],
        "grid_fi_sel": [92, 126, 174],
        "grid_av_sel": [255, 0, 0],
        "rp_av": [59, 85, 130],
        "tp_digit": "sampled at runtime from chrome (60,90,0) cells",
    }


# ---------------------------------------------------------------------------
def build_injuries(samples: dict) -> None:
    print("== INJURIES ==")
    fi, fr = load(F_INJ), load(F_INJ_R)
    samples["injuries_title_xy"] = title_sprite(fi, ART_I / "title.png")

    chrome = fi[BODY_Y0:480].copy()

    # cursor patch: 034's cursor sits on INSURANCE (the only region that
    # changes into 035); 039's cursor is on RETURN -> patch INSURANCE from 039.
    INS = (358, 432, 482, 468)
    chrome[INS[1] - BODY_Y0 : INS[3] - BODY_Y0, INS[0] : INS[2]] = fr[
        INS[1] : INS[3], INS[0] : INS[2]
    ]

    # physio band: clear the dynamic name/stars/count. Probed 034: the white
    # name-band interior is x58..339 y446..467 ("P. Gelbier" + gold stars
    # x220..286 y452..460); the black top band holds the red cross (static,
    # x222..230 y433..441) and the count digit "5" at x243..250 y~429..441 on
    # flat black. "PHYSIOTHERAPIST"/"PLAYERS" labels are static furniture.
    assert_flat(fi, 300, 446, 339, 468, (255, 255, 255), "name band right flat")
    fill(chrome, 61, 446 - BODY_Y0, 340, 468 - BODY_Y0, (255, 255, 255))
    assert_flat(fi, 239, 428, 242, 444, (0, 0, 0), "count digit cell bg", 0.05)
    fill(chrome, 239, 428 - BODY_Y0, 255, 444 - BODY_Y0, (0, 0, 0))
    save(chrome, ART_I / "chrome.png")

    # physio star glyph (white band, gold): 5 stars, cells x220 pitch 14
    # (probed gold col runs 220/234/248/262/276), glyph rows 450..461.
    save_rgba(keyed(cut(fi, 220, 449, 234, 463), (255, 255, 255)), ART_I / "phys_star.png")
    samples["phys_star"] = {"x0": 220, "pitch": 14, "y": 449}


# ---------------------------------------------------------------------------
def build_stats(samples: dict) -> None:
    print("== STATISTICS ==")
    fs = load(F_ST)
    fb, fc, fd = load(F_ST_B), load(F_ST_C), load(F_ST_D)
    fe, ff = load(F_ST_E), load(F_ST_F)
    samples["stats_title_xy"] = title_sprite(fb, ART_S / "title.png")

    chrome = fs[BODY_Y0:480].copy()

    # rows: every one of the 19 slots carries the same bar furniture; clear the
    # 11 filled ones by tiling slot 13 (empty, asserted vs slot 15).
    empty_y = ST_ROW_TOPS[13]
    assert_equal(fs, fs, 19, ST_ROW_TOPS[15], 577, ST_ROW_TOPS[15] + ST_BAR_H, "self")
    tile = cut(fs, 19, empty_y, 577, empty_y + ST_BAR_H)
    tile2 = cut(fs, 19, ST_ROW_TOPS[15], 577, ST_ROW_TOPS[15] + ST_BAR_H)
    assert np.array_equal(tile, tile2), "empty stat slots 13/15 differ"
    for y in ST_ROW_TOPS[:11]:
        chrome[y - BODY_Y0 : y - BODY_Y0 + ST_BAR_H, 19:577] = tile

    # TEAM TOTAL value cells: band = navy border rows 424/437, cell interior
    # fill (166,202,240) rows 425..436, navy (30,52,98) separator columns.
    # Digits/dashes occupy rows 427..435 only (069-vs-042 diff), so the top
    # interior row y425 is digit-free: any column that is fill-coloured there
    # is cell interior -> flatten it; navy columns are separators, kept
    # verbatim. The red TEAM TOTAL label lives left of x168 (asserted).
    FILL_TT = np.array((166, 202, 240), np.uint8)
    band_tt = fs[425:437, :]
    red_tt = (
        (band_tt[:, :, 0] > 150) & (band_tt[:, :, 1] < 80) & (band_tt[:, :, 2] < 80)
    )
    assert not red_tt[:, 168:].any(), "TEAM TOTAL label text crosses x168"
    for x in range(168, 574):
        if np.array_equal(fs[425, x], FILL_TT):
            chrome[425 - BODY_Y0 : 437 - BODY_Y0, x] = FILL_TT
    samples["stats_total_band"] = {
        "interior_y": [425, 437],
        "fill": [166, 202, 240],
        "sep_ink": [30, 52, 98],
    }

    # title band: clear the shirt icon + "STATISTICS FOR MANCHESTER UTD." to
    # white; cut both as verbatim sprites for exact parity on the walked club.
    ys0, ys1, xs0, xs1 = 70, 92, 150, 512
    band = cut(fs, xs0, ys0, xs1, ys1)
    mask = np.any(band != np.array((255, 255, 255), np.uint8), axis=2)
    ys, xs = np.nonzero(mask)
    x0, x1, y0, y1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
    rgba = np.zeros((y1 - y0, x1 - x0, 4), dtype=np.uint8)
    rgba[:, :, :3] = band[y0:y1, x0:x1]
    rgba[:, :, 3] = mask[y0:y1, x0:x1].astype(np.uint8) * 255
    save_rgba(rgba, ART_S / "title_manutd.png")
    samples["stats_title_manutd_xy"] = [int(xs0 + x0), int(ys0 + y0)]
    fill(chrome, xs0, ys0 - BODY_Y0, xs1, ys1 - BODY_Y0, (255, 255, 255))

    # RETURN button: 069 is cursor-free over the whole frame (069 vs 070 diff
    # is confined to x509..624 y446..474 = the cursor arriving on RETURN in
    # 070; 042/043/044/070/071 all carry it). Witness: run-1's 147_154839 is
    # pixel-identical to 069 over the button -> resting state confirmed by an
    # independent visit. No patch needed; assert the witness.
    fw = load(F_ST_W)
    R = (500, 440, 636, 478)
    assert_equal(fs, fw, *R, "069==147 over resting RETURN")
    save(chrome, ART_S / "chrome.png")


def main() -> None:
    samples: dict = {}
    build_training(samples)
    build_injuries(samples)
    build_stats(samples)
    SPECS.mkdir(exist_ok=True)
    out = SPECS / "lineup_subs_samples.json"
    out.write_text(json.dumps(samples, indent=1))
    print(f"  wrote {out.relative_to(ROOT)}")
    print("OK")


if __name__ == "__main__":
    sys.exit(main())
