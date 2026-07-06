#!/usr/bin/env python3
"""Bake the VIEW RIVAL (VERRIVAL) screen BODY chrome from the real game's frames.

Entry-flow doctrine (build_lineup_chrome_from_frames.py): the body chrome IS the
binding frame with every career/state-dependent pixel cleared to a resting look;
RivalScreen draws the dynamic layer (rows, stars, role texts, AV, camrol, right
panel, pitch markers) on top with the game's own PROMAN fonts + RECURSOS art.

Binding frame:
  015_162415  run 2, Mon 4 Aug — at F.C. Barcelona (RATING view, assistant
              A. Leigh 4*): rival XI table, TEAM RATING 87, big pitch with
              Barcelona's 21 bright markers + MU's 3-5-2 ghost (dim) markers.
Witness frames:
  048_162548  run 2 — asserted a pixel-exact DUPLICATE of 015 (same visit).
  151_154848  run 1 — at Juventus, Fri 1 Aug: second club (names/AVs/rating/kit
              and BOTH marker sets differ; run-1 own tactic = 4-4-2). Everything
              asserted static between 015 and 151 stays in chrome.
  152_154852  run 1 — 151 with RETURN caught HOT (ignored beyond the dup check).

Frame-decoded facts this bake rests on (all asserted below):
- The table is the LINE-UP/TACTICS squad-table control at x+2: border cols
  x9-10/x472-473, top y82-83, bottom y284-285, column header band y84..101
  STATIC across frames/runs. 11 fixed row boxes, 16px pitch, top sep at
  y102+16i: [sep | 12px 240-grey fill | sep | 2px white], grey box borders
  x31/x439, white margins x11..30 / x440..471.
- Row cells = the LINE-UP RATING grammar shifted +2px: shirt N. GDI-centred in
  [35,+17) (navy), name left x69 (black), STARJUGON strip x174+14j glyph top
  fill+1 (halves=(AV+1) div 10, odd half = STARJUGON-OFF), fine-role LONG name
  right-aligned to x351 (ink 100,120,140), AV GDI-centred [353,+22) (210,0,0),
  CAMROL 25x14 at x376 (black backing sep..sep), POS word GDI-centred [403,+34).
  All ProMan8 @11, ink top = fill+3.
- Right panel: PARAMETERS (492,85,134,21) nude + RATING (492,109,134,21) ACTIVE
  plates both walked (RATING-active in every rival frame; the flip is un-walked
  -> tactics-board doctrine: label-cleared plates + redrawn labels); red arrow
  patch zone x479..491 beside the active toggle. Club plate (481,155,154,18):
  white band, club name ProMan8 black GDI-centred. TEAM RATING strip
  (481,173,154,32): NANOESC 24x32 kit at (485,174) WITH the engine shadow pass
  (SELECCION/header precedent -> walked club cut as a frame patch), star cells
  x516+15j y186..204 (walked = 4 full + nude 5th; noise-dither bg -> per-cell
  patches, un-walked counts fall back to plain glyphs), value ProMan10 @10
  (160,160,200) right-aligned. COMPUTER band + TACTICS/RETURN + team-attr grid
  + ASSISTANT panel furniture all static (chrome); the assistant NAME BAND
  interior (117,147,187) holds the dynamic name (white) + STARPARON stars.
- Pitch: TACTICAS CAMPO.BMP 278x167 blitted 1:1 at (196,300); marker layer
  origin (206,305), 258x154. BRIGHT = the rival XI: DVERDE disc at mk1 +
  AVERDE arrow at mk2 per slot (16x16, discs first, arrows on top — the GK
  witness has BOTH at the same spot with the arrow covering), ProMan8 shirt
  digits per the tactics-board rules BUT in WHITE on both marker kinds (the
  scouting screen's own ink — 014's green/black is the tactics board's; window
  16/13, glyph top sprite row 2, frame-verified on all 21 markers). Barcelona's slot layout is the club's OWN
  tactic (matches NO stock formation) -> the walked marker list is emitted to
  the samples JSON for the parity shot; live rivals use the app's
  Tactics.auto_pick model (documented).
- GHOST (dim) = YOUR OWN team's markers mirrored to the other half:
  (0xf2 - x, 0x8a - y) = (242-mk.x, 138-mk.y) for BOTH phases of every own
  slot (disc at mk1-mirror, HORIZONTALLY FLIPPED arrow at mk2-mirror), with
  the own shirt digits, drawn through the engine's positional NOISE dither
  (multi-valued per colour — no LUT reproduces it). Doctrine: the walked
  own-state (run-2 MU 3-5-2, shirts 1,2,3,21,6,8,7,10,9,11,20) ships as 22
  verbatim 16x16 patches; un-walked own states fall back to a majority-vote
  dim LUT (documented approximation). Patches whose box overlaps a bright
  marker are flagged POISONED (they embed rival pixels) and excluded from
  live reuse.

Outputs: app/art/screens/rival/ + tools/re/specs/rival_chrome_samples.json
(mirrored to app/data/).

Run from anywhere:  python3 tools/re/build_rival_chrome_from_frames.py
"""

from __future__ import annotations

import json
import sys
from collections import defaultdict
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import export_art as ea  # noqa: E402
import pkf_unpack as pk  # noqa: E402
from export_icons import decode_dib  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
FRAMES = ROOT / "screenshots" / "original-walkthrough-2026-07-02"
if not FRAMES.exists():
    FRAMES = ROOT / "tools" / "re" / "refs" / "walkthrough-2026-07-02"
ART = ROOT / "app" / "art" / "screens" / "rival"
SPECS = Path(__file__).resolve().parent / "specs"
RECURSOS = ROOT / "extracted" / "Premier Manager 98" / "RECURSOS.PKF"
FONTS = ROOT / "app" / "art" / "fonts"

F015, F048, F151, F152 = (
    "015_162415.png",
    "048_162548.png",
    "151_154848.png",
    "152_154852.png",
)

BODY_Y0 = 62
ROW_Y0 = 102  # first row's top sep
ROW_PITCH = 16
ROW_X0, ROW_X1 = 11, 471  # template cut (inside the table border cols)
FILL = (240, 240, 240)
NUM_CELL = (35, 17)
NAME_X = 69
STAR_X0, STAR_PITCH = 174, 14
ROLE_RIGHT = 351
AV_CELL = (353, 22)
CAMROL_X = 376
POS_CELL = (403, 34)
# frame 015 row truth (top..bottom): fine role id (positions_re 1-based), POS word, AV
ROW_FINE = [1, 2, 5, 15, 5, 3, 16, 7, 9, 13, 17]
ROW_POS = ["GOAL", "DEF", "DEF", "MID", "DEF", "DEF", "MID", "MID", "FOR", "MID", "MID"]
ROW_AV = [83, 87, 84, 89, 85, 89, 89, 84, 88, 91, 90]

TOGGLE_PARAM = (492, 85, 626, 106)
TOGGLE_RATING = (492, 109, 626, 130)
ARROW_X0, ARROW_X1 = 479, 492
CLUB_PLATE = (481, 155, 635, 173)
STRIP = (481, 173, 635, 205)
KIT_XY = (485, 174)
STRIP_CELL_X0, STRIP_CELL_PITCH = 516, 15
STRIP_CELL_Y0, STRIP_CELL_Y1 = 186, 204
STRIP_VAL_ZONE = (598, 190, 626, 201)
ASSIST_BAND_BG = (117, 147, 187)
CAMPO_XY = (196, 300)
MARK_XY = (206, 305)
MIRROR = (0xF2, 0x8A)  # 242, 138

# bright marker positions in 015 (top-left, abs), from tolerant DVERDE/AVERDE
# template match (digit occlusion allowed); re-verified pixel-exact below.
DISCS_015 = [
    (300, 320),
    (233, 338),
    (271, 338),
    (230, 373),
    (257, 373),
    (284, 377),
    (319, 378),
    (279, 406),
    (234, 419),
    (300, 426),
    (206, 373),
]
ARROWS_015 = [
    (362, 327),
    (414, 340),
    (304, 342),
    (206, 373),
    (411, 373),
    (447, 373),
    (301, 377),
    (343, 377),
    (413, 401),
    (389, 413),
    (335, 433),
]
# own (ghost) walked state: run-2 MU 3-5-2, slot shirts from frame 014 (GK first)
GHOST_FORMATION = "3-5-2"
GHOST_NUMS = [1, 2, 3, 21, 6, 8, 7, 10, 9, 11, 20]


def load_frame(name: str) -> np.ndarray:
    a = np.asarray(Image.open(FRAMES / name).convert("RGB"))
    if a.shape[0] != 480 or a.shape[1] not in (640, 641):
        raise SystemExit(f"{name}: unexpected size {a.shape}")
    return a[:, :640].astype(int)


def expect(cond: bool, what: str) -> None:
    if not cond:
        raise SystemExit(f"frame invariant FAILED: {what}")


def save(a: np.ndarray, p: Path) -> None:
    p.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(a.astype("uint8")).save(p)
    print(f"  {p.relative_to(ROOT)}  {a.shape[1]}x{a.shape[0]}")


def save_rgba(im: Image.Image, p: Path) -> None:
    p.parent.mkdir(parents=True, exist_ok=True)
    im.save(p)
    print(f"  {p.relative_to(ROOT)}  {im.size[0]}x{im.size[1]}")


def recursos() -> dict:
    """Decode the TACTICAS big-pitch cluster + the star sprite families."""
    buf = RECURSOS.read_bytes()
    pal = ea.riff_palette("MANAGER.PAL")
    names = list(pk.files_of(buf))
    big_i = next(
        i for i, (n, o, s) in enumerate(names) if str(n).upper() == "CAMPO.BMP" and s == 46786
    )
    out = {}
    for j in range(big_i - 4, big_i + 4):
        n, o, s = names[j]
        u = str(n).upper()
        if u.endswith(".BMP") and u not in out:
            out[u] = decode_dib(buf[o : o + s], pal)
    for i, (n, o, s) in enumerate(names):
        u = str(n).upper()
        if "STAR" in u and u not in out:
            out[u] = decode_dib(buf[o : o + s], pal)
    return out


def patch_palette(arr: np.ndarray) -> np.ndarray:
    """One palette index decodes (192,227,192) under MANAGER.PAL but renders
    (192,220,192) on the walked screens (lineup/tactics precedent)."""
    rgb = arr[:, :, :3]
    m = (rgb == np.array([192, 227, 192])).all(axis=2)
    arr[m, 1] = 220
    return arr


def digit_cells() -> tuple[dict, np.ndarray]:
    """ProMan8 digit glyph cells from the BMFont export (same source the app's
    marker composites read)."""
    cells = {}
    for line in (FONTS / "proman8.fnt").read_text().splitlines():
        if not line.startswith("char id="):
            continue
        kv = dict(p.split("=") for p in line.split()[1:])
        cid = int(kv["id"])
        if ord("0") <= cid <= ord("9"):
            cells[chr(cid)] = {
                "x": int(kv["x"]),
                "y": int(kv["y"]),
                "w": int(kv["width"]),
                "h": int(kv["height"]),
                "adv": int(kv["xadvance"]),
            }
    atlas = np.asarray(Image.open(FONTS / "proman8.png").convert("RGBA")).astype(int)
    return cells, atlas


def marker_composite(
    spr: np.ndarray, num: int, disc: bool, cells: dict, atlas: np.ndarray
) -> np.ndarray:
    """RGBA marker with the shirt digits composited per the tactics-board rules
    (TacticsBoardScreen._marker_tex): window 16 disc / 13 arrow, glyph top at
    sprite row 2, ink (17,90,34) disc / black arrow, GDI x=(win-adv)/2."""
    img = spr.copy()
    s = str(num)
    w = sum(cells[ch]["adv"] for ch in s)
    ink = (255, 255, 255)  # VIEW RIVAL paints WHITE digits on both kinds
    win = 16 if disc else 13
    x = int((win - w) / 2)
    for ch in s:
        c = cells[ch]
        for gy in range(c["h"]):
            for gx in range(c["w"]):
                if atlas[c["y"] + gy, c["x"] + gx, 3] > 0:
                    tx, ty = x + gx, 2 + gy
                    if 0 <= tx < win and ty < img.shape[0]:
                        img[ty, tx, :3] = ink
                        img[ty, tx, 3] = 255
        x += c["adv"]
    return img


def blit(dst: np.ndarray, spr: np.ndarray, x: int, y: int) -> None:
    al = spr[:, :, 3] > 0
    h, w = spr.shape[:2]
    y1, x1 = min(y + h, dst.shape[0]), min(x + w, dst.shape[1])
    for yy in range(max(0, y), y1):
        for xx in range(max(0, x), x1):
            if al[yy - y, xx - x]:
                dst[yy, xx] = spr[yy - y, xx - x, :3]


def main() -> None:
    f015 = load_frame(F015)
    f048 = load_frame(F048)
    f151 = load_frame(F151)
    f152 = load_frame(F152)
    spr = recursos()
    cells, atlas = digit_cells()
    samples: dict = {}

    def A(nm: str) -> np.ndarray:
        return patch_palette(np.asarray(spr[nm].convert("RGBA")).astype(int))

    # ---- witness sanity -----------------------------------------------------
    expect(np.array_equal(f015, f048), "048 is not a pixel-exact duplicate of 015")
    d152 = np.abs(f152 - f151).sum(axis=2) > 0
    ys, xs = np.where(d152)
    expect(ys.min() >= 435 and xs.min() >= 500, "152 vs 151 differs outside RETURN")

    # ---- geometry invariants ------------------------------------------------
    for x in (9, 10, 472, 473):
        expect(tuple(f015[200, x]) == (0, 0, 0), f"table border col x{x}")
    for y in (82, 83, 284, 285):
        expect(tuple(f015[y, 200]) == (0, 0, 0), f"table border row y{y}")
    expect(
        np.array_equal(f015[84:102, 11:472], f151[84:102, 11:472]),
        "column header band differs 015 vs 151",
    )
    for i in range(11):
        sy = ROW_Y0 + ROW_PITCH * i
        expect(tuple(f015[sy, 200]) == (128, 128, 128), f"row {i} top sep y{sy}")
        expect(tuple(f015[sy + 13, 200]) == (128, 128, 128), f"row {i} bottom sep")
        expect(tuple(f015[sy + 5, 150]) == FILL, f"row {i} fill tint")
        for yy in (sy + 14, sy + 15):
            expect(tuple(f015[yy, 200]) == (255, 255, 255), f"row {i} gap white y{yy}")
        for xx in (31, 439):
            expect(tuple(f015[sy + 5, xx]) == (128, 128, 128), f"row {i} box border x{xx}")
        for xx in (376, 400):
            expect(tuple(f015[sy + 5, xx]) == (0, 0, 0), f"row {i} camrol col x{xx}")
        expect(tuple(f015[sy + 5, 351]) == (128, 128, 128), f"row {i} AV sep x351")

    # ---- static zones vs the second club (become chrome untouched) ----------
    STATIC = {
        "attr grid": (9, 297, 165, 388),
        "assistant panel": (8, 398, 189, 467),
        "toggles+arrow": (464, 68, 640, 131),
        "computer band": (482, 205, 634, 220),
        "tactics btn": (500, 390, 630, 425),
        "return btn": (500, 435, 630, 470),
        "left marble": (0, BODY_Y0, 9, 480),
        "bottom marble": (0, 468, 640, 480),
    }
    for tag, (x0, y0, x1, y1) in STATIC.items():
        expect(
            np.array_equal(f015[y0:y1, x0:x1], f151[y0:y1, x0:x1]),
            f"{tag} not static 015 vs 151",
        )

    # ---- row star glyphs (STARJUGON pair, halves=(AV+1) div 10) -------------
    sj = np.asarray(
        Image.open(ROOT / "app/art/screens/tacticas/star_full.png").convert("RGBA")
    ).astype(int)
    sjo = np.asarray(
        Image.open(ROOT / "app/art/screens/tacticas/star_off.png").convert("RGBA")
    ).astype(int)
    for i, av in enumerate(ROW_AV):
        fy = ROW_Y0 + ROW_PITCH * i + 2  # glyph top = fill+1
        halves = (av + 1) // 10
        for j in range(halves // 2):
            win = f015[fy : fy + 12, STAR_X0 + 14 * j : STAR_X0 + 14 * j + 14]
            al = sj[:, :, 3] > 0
            expect(np.array_equal(win[al], sj[:, :, :3][al]), f"row {i} star {j}")
        if halves % 2 == 1:
            x = STAR_X0 + 14 * (halves // 2)
            win = f015[fy : fy + 12, x : x + 14]
            al = sjo[:, :, 3] > 0
            expect(np.array_equal(win[al], sjo[:, :, :3][al]), f"row {i} half star")

    # ---- row camrol icons == camrolNN sprites for the frame's fine roles ----
    for i, fine in enumerate(ROW_FINE):
        sy = ROW_Y0 + ROW_PITCH * i
        cam = np.asarray(
            Image.open(ROOT / f"app/art/icons/camrol/camrol{fine:02d}.png").convert("RGBA")
        ).astype(int)
        al = cam[:, :, 3] > 0
        win = f015[sy : sy + cam.shape[0], CAMROL_X : CAMROL_X + cam.shape[1]]
        expect(
            np.array_equal(win[al], cam[:, :, :3][al]),
            f"row {i} camrol != camrol{fine:02d}",
        )

    # ---- row templates -------------------------------------------------------
    def clear(row: np.ndarray, x0: int, x1: int, y0: int, y1: int, bg) -> None:
        reg = row[y0:y1, x0 - ROW_X0 : x1 - ROW_X0]
        reg[(reg != np.array(bg)).any(axis=2)] = bg
        row[y0:y1, x0 - ROW_X0 : x1 - ROW_X0] = reg

    def cut_row(frame: np.ndarray, i: int) -> np.ndarray:
        sy = ROW_Y0 + ROW_PITCH * i
        row = frame[sy : sy + ROW_PITCH, ROW_X0:ROW_X1].copy()
        clear(row, 32, 51, 1, 13, FILL)  # shirt number
        clear(row, 52, 173, 1, 13, FILL)  # name
        clear(row, 173, 351, 1, 13, FILL)  # stars + role text
        clear(row, 352, 376, 1, 13, FILL)  # AV
        row[0:14, CAMROL_X - ROW_X0 : CAMROL_X + 25 - ROW_X0] = (0, 0, 0)  # camrol
        clear(row, 401, 439, 1, 13, FILL)  # POS word
        return row

    base = cut_row(f015, 0)
    for frame, tag in ((f015, "015"), (f151, "151")):
        for i in range(11):
            other = cut_row(frame, i)
            if not np.array_equal(base, other):
                ys2, xs2 = np.where((base != other).any(axis=2))
                expect(
                    False,
                    f"row template {tag}/{i} differs: x{xs2.min()}..{xs2.max()} "
                    f"y{ys2.min()}..{ys2.max()}",
                )
    save(base, ART / "row.png")

    # ---- toggles + arrow ------------------------------------------------------
    # both walked frames are RATING-active; the flip is un-walked -> tactics-board
    # doctrine: cut the plates, clear the labels (horizontal-neighbour inpaint),
    # redraw labels at runtime for the flipped state only.
    plate_param = f015[TOGGLE_PARAM[1] : TOGGLE_PARAM[3], TOGGLE_PARAM[0] : TOGGLE_PARAM[2]]
    plate_rating = f015[TOGGLE_RATING[1] : TOGGLE_RATING[3], TOGGLE_RATING[0] : TOGGLE_RATING[2]]

    def label_cleared(plate: np.ndarray, ink_test) -> np.ndarray:
        out = plate.copy()
        h, w = out.shape[:2]
        for y in range(h):
            x = 0
            while x < w:
                if ink_test(out[y, x]):
                    x0 = x
                    while x < w and ink_test(out[y, x]):
                        x += 1
                    lf = out[y, x0 - 1] if x0 > 0 else out[y, min(x, w - 1)]
                    rt = out[y, x] if x < w else lf
                    for xx in range(x0, x):
                        out[y, xx] = lf if (xx - x0) * 2 < (x - x0) else rt
                else:
                    x += 1
        return out

    pale = lambda c: abs(int(c[0]) - 160) < 50 and abs(int(c[1]) - 160) < 50 and c[2] > 170  # noqa: E731
    yellow = lambda c: c[0] > 200 and c[1] > 200 and c[2] < 90  # noqa: E731
    save(plate_param, ART / "plate_param_off.png")
    save(plate_rating, ART / "plate_rating_on.png")
    save(label_cleared(plate_param, pale), ART / "plate_off_nude.png")
    save(label_cleared(plate_rating, yellow), ART / "plate_on_nude.png")
    arrow_at_rating = f015[TOGGLE_RATING[1] : TOGGLE_RATING[3], ARROW_X0:ARROW_X1]
    arrow_off_param = f015[TOGGLE_PARAM[1] : TOGGLE_PARAM[3], ARROW_X0:ARROW_X1]
    reds = (
        (arrow_at_rating[:, :, 0] > 50)
        & (arrow_at_rating[:, :, 1] < 45)
        & (arrow_at_rating[:, :, 2] < 45)
    )
    expect(int(reds.sum()) > 20, f"no red arrow beside RATING ({int(reds.sum())}px)")
    save(arrow_at_rating, ART / "arrow_at_rating.png")
    save(arrow_off_param, ART / "arrow_off_param.png")
    # synthesized flip spots (un-walked): arrow glyph stamped onto the param
    # nude marble / rating marble reconstructed by inpainting the arrow away
    arrow_at_param = arrow_off_param.copy()
    arrow_at_param[reds] = arrow_at_rating[reds]
    save(arrow_at_param, ART / "arrow_at_param.png")
    save(
        label_cleared(arrow_at_rating, lambda c: c[0] > 50 and c[1] < 45 and c[2] < 45),
        ART / "arrow_off_rating.png",
    )
    samples["toggle"] = {
        "param": list(TOGGLE_PARAM),
        "rating": list(TOGGLE_RATING),
        "arrow_x": ARROW_X0,
        "arrow_w": ARROW_X1 - ARROW_X0,
        "label_ink_on": [255, 255, 0],
        "label_ink_off": [160, 160, 200],
    }

    # ---- club plate: clear the name text (black on the white band) ----------
    x0, y0, x1, y1 = CLUB_PLATE

    # the plate is a BLACK band; the club name is WHITE ink in rows y160..167
    # (frame-measured)
    TEXT_Y = (160, 168)

    def club_text_mask(f: np.ndarray) -> np.ndarray:
        band = f[y0:y1, x0:x1]
        white = (band == 255).all(axis=2)
        m = np.zeros_like(white)
        m[TEXT_Y[0] - y0 : TEXT_Y[1] - y0] = white[TEXT_Y[0] - y0 : TEXT_Y[1] - y0]
        return m

    mask15, mask151 = club_text_mask(f015), club_text_mask(f151)
    diffm = np.abs(f015[y0:y1, x0:x1] - f151[y0:y1, x0:x1]).sum(axis=2) > 0
    expect(
        bool((diffm & ~(mask15 | mask151)).sum() == 0), "club plate differs outside the text glyphs"
    )
    samples["club_plate"] = {"rect": list(CLUB_PLATE), "ink": [255, 255, 255]}

    # ---- TEAM RATING strip ----------------------------------------------------
    # star cells: both walked ratings (87/86) show the same 4 full + nude 5th
    for j in range(5):
        cx = STRIP_CELL_X0 + STRIP_CELL_PITCH * j
        expect(
            np.array_equal(
                f015[STRIP_CELL_Y0:STRIP_CELL_Y1, cx : cx + STRIP_CELL_PITCH],
                f151[STRIP_CELL_Y0:STRIP_CELL_Y1, cx : cx + STRIP_CELL_PITCH],
            ),
            f"strip star cell {j} differs 015 vs 151",
        )
        gold = (
            (f015[STRIP_CELL_Y0:STRIP_CELL_Y1, cx : cx + STRIP_CELL_PITCH, 0] > 200)
            & (f015[STRIP_CELL_Y0:STRIP_CELL_Y1, cx : cx + STRIP_CELL_PITCH, 1] > 150)
            & (f015[STRIP_CELL_Y0:STRIP_CELL_Y1, cx : cx + STRIP_CELL_PITCH, 2] < 120)
        )
        expect(bool(gold.any()) == (j < 4), f"strip cell {j} gold presence")
        if j < 4:
            save(
                f015[STRIP_CELL_Y0:STRIP_CELL_Y1, cx : cx + STRIP_CELL_PITCH],
                ART / f"strip_star_full_{j}.png",
            )
        else:
            nude_cell = f015[STRIP_CELL_Y0:STRIP_CELL_Y1, cx : cx + STRIP_CELL_PITCH]
            save(nude_cell, ART / "strip_star_nude.png")
    samples["strip_star"] = {
        "x0": STRIP_CELL_X0,
        "pitch": STRIP_CELL_PITCH,
        "y0": STRIP_CELL_Y0,
        "y1": STRIP_CELL_Y1,
    }
    # plain-glyph fallback for un-walked counts (STAREQON pair if present)
    for nm, out in (("STAREQON.BMP", "star_eq_on"), ("STAREQON-OFF.BMP", "star_eq_off")):
        if nm in spr:
            save_rgba(spr[nm], ART / f"{out}.png")

    # walked kit patch (engine shadow pass -> frame patch; live un-walked clubs
    # fall back to the shadowless NANOESC blit, header-bake precedent)
    kit = f015[KIT_XY[1] : STRIP[3], KIT_XY[0] : KIT_XY[0] + 24]
    save(kit, ART / "kit_1000.png")
    nano = np.asarray(Image.open(ROOT / "app/art/kits/nano/1000.png").convert("RGBA")).astype(int)
    al = nano[:31, :, 3] > 0
    bad = int((np.abs(kit[: al.shape[0]] - nano[: al.shape[0], :, :3]).sum(axis=2)[al] > 0).sum())
    print(f"  kit vs shadowless nano: {bad}px shadow-pass delta")
    expect(bad < 80, "strip kit is not the NANOESC sprite family")
    samples["kit"] = {"xy": list(KIT_XY), "walked_club": 1000}

    # value zone: noise bg -> fill from the OTHER frame where 015 has ink
    vx0, vy0, vx1, vy1 = STRIP_VAL_ZONE
    val_ink = lambda z: np.abs(z - np.array([160, 160, 200])).sum(axis=2) < 60  # noqa: E731
    z15 = f015[vy0:vy1, vx0:vx1].copy()
    z151 = f151[vy0:vy1, vx0:vx1]
    m15, m151 = val_ink(z15), val_ink(z151)
    z15[m15] = z151[m15]
    both = m15 & m151
    if both.any():
        med = np.median(z15[~m15].reshape(-1, 3), axis=0)
        z15[both] = med
    val_clear = z15
    samples["strip_value"] = {
        "zone": list(STRIP_VAL_ZONE),
        "right_x": 617,
        "y_top": 191,
        "ink": [160, 160, 200],
    }

    # ---- assistant name band ---------------------------------------------------
    # locate the flat steel-blue interior; clear the name + stars to it
    reg = f015[398:467, 8:189]
    bandm = (reg == np.array(ASSIST_BAND_BG)).all(axis=2)
    ys3, xs3 = np.where(bandm)
    bx0, bx1 = 8 + xs3.min(), 8 + xs3.max()
    by0, by1 = 398 + ys3.min(), 398 + ys3.max()
    print(f"  assistant band interior x{bx0}..{bx1} y{by0}..{by1}")
    # STARPARON stars on the band, wrapped in an engine noise-dither shadow
    # halo (the lineup attr-button precedent) -> tolerant locate, then cut the
    # walked 4-star strip VERBATIM; un-walked counts fall back to plain glyphs
    paron = np.asarray(
        Image.open(ROOT / "app/art/screens/lineup/star_paron_on.png").convert("RGBA")
    ).astype(int)
    pal_ = paron[:, :, 3] > 0
    hits = []
    for oy in range(by0, by1 - paron.shape[0] + 2):
        for ox in range(bx0, bx1 - paron.shape[1] + 2):
            win = f015[oy : oy + paron.shape[0], ox : ox + paron.shape[1]]
            if win.shape[:2] != paron.shape[:2]:
                continue
            bad = int((np.abs(win - paron[:, :, :3]).sum(axis=2)[pal_] > 0).sum())
            if bad <= 22:
                hits.append((ox, oy, bad))
    # keep the best hit per 11px column bucket
    hits.sort(key=lambda h: h[2])
    picked: list = []
    for h in hits:
        if all(abs(h[0] - p[0]) >= 6 for p in picked):
            picked.append(h)
    picked.sort()
    expect(len(picked) == 4, f"assistant stars != 4 shadowed STARPARON ({picked})")
    xs4 = [p[0] for p in picked]
    expect(
        all(xs4[j + 1] - xs4[j] == 11 for j in range(3)),
        f"assistant star pitch != 11 ({xs4})",
    )
    star_y = picked[0][1]
    (bx0 + 2, by0, bx1 - 1, by1 + 1)
    assist_strip = f015[by0 : by1 + 1, xs4[0] - 4 : xs4[0] + 44]
    save(assist_strip, ART / "assist_stars_4.png")
    samples["assist"] = {
        "band": [int(bx0), int(by0), int(bx1), int(by1)],
        "star_x0": int(xs4[0]),
        "star_y": int(star_y),
        "star_pitch": 11,
        "stars4_xy": [int(xs4[0] - 4), int(by0)],
        "walked_count": 4,
        "name_x": int(bx0) + 3,
        "name_ink": [255, 255, 255],
    }

    # ---- pitch: campo + ghosts + bright markers --------------------------------
    campo = patch_palette(np.asarray(spr["CAMPO.BMP"].convert("RGBA")).astype(int))[:, :, :3]
    ch, cw = campo.shape[:2]
    expect((ch, cw) == (167, 278), f"big campo {cw}x{ch}")
    dv, av = A("DVERDE.BMP"), A("AVERDE.BMP")
    avf = av[:, ::-1]  # ghost arrows render horizontally flipped

    forms = json.loads((ROOT / "app" / "data" / "formations.json").read_text())
    rec = next(r for r in forms["formations"] if r["name"] == GHOST_FORMATION)
    gk = int(rec.get("gk_slot", 10))
    order = [gk] + [i for i in range(len(rec["slots"])) if i != gk]
    ghost_boxes = []  # (mkx, mky, phase, slot_i)
    for oi, si in enumerate(order):
        s = rec["slots"][si]
        ghost_boxes.append((MIRROR[0] - s["mk1"][0], MIRROR[1] - s["mk1"][1], 1, oi))
        ghost_boxes.append((MIRROR[0] - s["mk2"][0], MIRROR[1] - s["mk2"][1], 2, oi))

    bright = [(x - MARK_XY[0], y - MARK_XY[1], True) for x, y in DISCS_015] + [
        (x - MARK_XY[0], y - MARK_XY[1], False) for x, y in ARROWS_015
    ]

    def overlaps_bright(gx: int, gy: int) -> bool:
        return any(abs(gx - bx) < 16 and abs(gy - by) < 16 for bx, by, _ in bright)

    # cut ghost patches (16x16 verbatim)
    ghost_meta = []
    for gx, gy, phase, oi in ghost_boxes:
        px, py = MARK_XY[0] + gx, MARK_XY[1] + gy
        patch = f015[py : py + 16, px : px + 16]
        tag = f"ghost_352_{oi}_{phase}"
        save(patch, ART / f"{tag}.png")
        ghost_meta.append(
            {
                "mk": [int(gx), int(gy)],
                "phase": phase,
                "slot": oi,
                "clean": not overlaps_bright(gx, gy),
                "tex": tag,
            }
        )

    # majority dim-LUT from the clean ghost boxes (documented approximation for
    # un-walked own states; the dim pass is a positional noise dither)
    votes: dict = defaultdict(lambda: defaultdict(int))
    for gx, gy, phase, oi in ghost_boxes:
        if overlaps_bright(gx, gy):
            continue
        s_arr = dv if phase == 1 else avf
        src = campo[
            gy + MARK_XY[1] - CAMPO_XY[1] : gy + MARK_XY[1] - CAMPO_XY[1] + 16,
            gx + MARK_XY[0] - CAMPO_XY[0] : gx + MARK_XY[0] - CAMPO_XY[0] + 16,
        ].copy()
        al2 = s_arr[:, :, 3] > 0
        src[al2[: src.shape[0], : src.shape[1]]] = s_arr[:, :, :3][al2][
            : src[al2[: src.shape[0], : src.shape[1]]].shape[0]
        ]
        obs = f015[MARK_XY[1] + gy : MARK_XY[1] + gy + 16, MARK_XY[0] + gx : MARK_XY[0] + gx + 16]
        for yy in range(min(16, src.shape[0])):
            for xx in range(min(16, src.shape[1])):
                votes[tuple(src[yy, xx])][tuple(obs[yy, xx])] += 1
    ghost_lut = {k: max(v.items(), key=lambda kv: kv[1])[0] for k, v in votes.items()}
    print(f"  ghost dim LUT: {len(ghost_lut)} colours (approx for un-walked own states)")

    # bright markers: derive each shirt digit, then PROVE the full recomposition
    comp = campo.copy()
    for gx, gy, phase, oi in ghost_boxes:
        px = MARK_XY[0] + gx - CAMPO_XY[0]
        py = MARK_XY[1] + gy - CAMPO_XY[1]
        comp[py : py + 16, px : px + 16] = f015[
            MARK_XY[1] + gy : MARK_XY[1] + gy + 16, MARK_XY[0] + gx : MARK_XY[0] + gx + 16
        ]

    def try_nums(mx: int, my: int, disc: bool) -> int:
        s_arr = dv if disc else av
        MARK_XY[0] + mx - CAMPO_XY[0]
        MARK_XY[1] + my - CAMPO_XY[1]
        frame_box = f015[
            MARK_XY[1] + my : MARK_XY[1] + my + 16, MARK_XY[0] + mx : MARK_XY[0] + mx + 16
        ]
        best = []
        for num in range(1, 12):
            m = marker_composite(s_arr, num, disc, cells, atlas)
            al2 = m[:, :, 3] > 0
            bad = int((np.abs(frame_box[: m.shape[0]] - m[:, :, :3]).sum(axis=2)[al2] > 0).sum())
            best.append((bad, num))
        best.sort()
        return best[0][1] if best[0][0] == 0 or best[0][0] < best[1][0] else -1

    markers = []
    # discs first, arrows on top (GK witness: both at (0,68), arrow covering)
    for mxa, mya in DISCS_015:
        mx, my = mxa - MARK_XY[0], mya - MARK_XY[1]
        num = try_nums(mx, my, True) if (mxa, mya) not in ARROWS_015 else -1
        markers.append({"kind": "disc", "mk": [mx, my], "num": num})
    for mxa, mya in ARROWS_015:
        mx, my = mxa - MARK_XY[0], mya - MARK_XY[1]
        num = try_nums(mx, my, False)
        expect(num > 0, f"arrow at ({mx},{my}): no digit fits")
        markers.append({"kind": "arrow", "mk": [mx, my], "num": num})
    # the GK disc digit is fully covered by its arrow — copy the arrow's number
    for m in markers:
        if m["num"] < 0:
            cover = next(a for a in markers if a["kind"] == "arrow" and a["mk"] == m["mk"])
            m["num"] = cover["num"]
    for m in markers:
        s_arr = dv if m["kind"] == "disc" else av
        tex = marker_composite(s_arr, m["num"], m["kind"] == "disc", cells, atlas)
        if m["kind"] == "arrow":
            blit(
                comp,
                tex,
                m["mk"][0] + MARK_XY[0] - CAMPO_XY[0],
                m["mk"][1] + MARK_XY[1] - CAMPO_XY[1],
            )
    # discs were blitted before arrows in the engine; replay in that order
    comp2 = campo.copy()
    for gx, gy, phase, oi in ghost_boxes:
        px = MARK_XY[0] + gx - CAMPO_XY[0]
        py = MARK_XY[1] + gy - CAMPO_XY[1]
        comp2[py : py + 16, px : px + 16] = f015[
            MARK_XY[1] + gy : MARK_XY[1] + gy + 16, MARK_XY[0] + gx : MARK_XY[0] + gx + 16
        ]
    for kind in ("disc", "arrow"):
        for m in markers:
            if m["kind"] != kind:
                continue
            s_arr = dv if kind == "disc" else av
            tex = marker_composite(s_arr, m["num"], kind == "disc", cells, atlas)
            blit(
                comp2,
                tex,
                m["mk"][0] + MARK_XY[0] - CAMPO_XY[0],
                m["mk"][1] + MARK_XY[1] - CAMPO_XY[1],
            )
    pit = f015[CAMPO_XY[1] : CAMPO_XY[1] + ch, CAMPO_XY[0] : CAMPO_XY[0] + cw]
    badm = np.abs(comp2 - pit).sum(axis=2) > 0
    if badm.any():
        ys5, xs5 = np.where(badm)
        print(
            f"  pitch recomposition mismatch {int(badm.sum())}px "
            f"x{xs5.min()}..{xs5.max()} y{ys5.min()}..{ys5.max()}"
        )
    expect(not badm.any(), "pitch recomposition failed")
    print(
        f"  pitch recomposition vs 015: 0px  ({len(markers)} bright markers, "
        f"{len(ghost_boxes)} ghost patches)"
    )
    save(campo, ART / "campo.png")
    samples["campo_xy"] = list(CAMPO_XY)
    samples["mark_xy"] = list(MARK_XY)
    samples["mirror"] = list(MIRROR)
    samples["rival_markers_015"] = markers
    samples["ghosts_352"] = {
        "formation": GHOST_FORMATION,
        "nums": GHOST_NUMS,
        "boxes": ghost_meta,
    }
    samples["ghost_lut"] = {",".join(map(str, k)): list(v) for k, v in ghost_lut.items()}
    samples["digit_ink"] = {"disc": [255, 255, 255], "arrow": [255, 255, 255]}
    samples["digit_win"] = {"disc": 16, "arrow": 13}

    # ---- chrome body -------------------------------------------------------------
    a = f015.copy()
    # 1. table rows region -> white (templates re-cover; header band stays)
    a[ROW_Y0 : ROW_Y0 + ROW_PITCH * 11, ROW_X0:ROW_X1] = (255, 255, 255)
    # 2. pitch -> clean campo
    a[CAMPO_XY[1] : CAMPO_XY[1] + ch, CAMPO_XY[0] : CAMPO_XY[0] + cw] = campo
    # 3. club plate text -> white
    band = a[y0:y1, x0:x1]
    band[mask15] = (0, 0, 0)
    a[y0:y1, x0:x1] = band
    # 4. strip star cells -> nude base (nearest-walked approximation, lineup
    #    doctrine); the runtime re-covers walked counts with the exact patches
    for j in range(5):
        cx = STRIP_CELL_X0 + STRIP_CELL_PITCH * j
        a[STRIP_CELL_Y0:STRIP_CELL_Y1, cx : cx + STRIP_CELL_PITCH] = nude_cell
    # 5. strip value -> other-frame fill
    a[vy0:vy1, vx0:vx1] = val_clear
    # 6. assistant band interior -> flat bg (name + stars redrawn at runtime)
    a[by0 : by1 + 1, bx0 : bx1 + 1] = ASSIST_BAND_BG
    save(a[BODY_Y0:480], ART / "chrome.png")

    # ---- samples -------------------------------------------------------------------
    samples.update(
        {
            "body_y0": BODY_Y0,
            "row_y0": ROW_Y0,
            "row_pitch": ROW_PITCH,
            "row_x": [ROW_X0, ROW_X1],
            "num_cell": list(NUM_CELL),
            "name_x": NAME_X,
            "star_x0": STAR_X0,
            "star_pitch": STAR_PITCH,
            "role_right": ROLE_RIGHT,
            "av_cell": list(AV_CELL),
            "camrol_x": CAMROL_X,
            "pos_cell": list(POS_CELL),
            "inks": {
                "num": [0, 0, 128],
                "name": [0, 0, 0],
                "role": [100, 120, 140],
                "av": [210, 0, 0],
                "pos": [0, 0, 0],
            },
            # PARAMETERS (numeric) view is UN-WALKED on this screen: cells centred
            # under the static header letters, lineup-128 inks (documented approx)
            "numeric": {
                "cells": [
                    [174, 25],
                    [199, 25],
                    [224, 25],
                    [249, 25],
                    [274, 25],
                    [301, 25],
                    [325, 25],
                ],
                "inks": [
                    [150, 0, 0],
                    [100, 100, 140],
                    [100, 100, 140],
                    [100, 100, 140],
                    [100, 100, 140],
                    [42, 95, 170],
                    [80, 110, 5],
                ],
            },
            "row_truth_015": {
                "fine": ROW_FINE,
                "pos": ROW_POS,
                "av": ROW_AV,
            },
        }
    )

    def _py(o):
        if isinstance(o, dict):
            return {k: _py(v) for k, v in o.items()}
        if isinstance(o, (list, tuple)):
            return [_py(v) for v in o]
        if isinstance(o, np.integer):
            return int(o)
        return o

    samples = _py(samples)
    SPECS.mkdir(parents=True, exist_ok=True)
    out = SPECS / "rival_chrome_samples.json"
    out.write_text(json.dumps(samples, indent=1) + "\n")
    print(f"  {out.relative_to(ROOT)}")
    app_out = ROOT / "app" / "data" / "rival_chrome_samples.json"
    app_out.write_text(json.dumps(samples, indent=1) + "\n")
    print(f"  {app_out.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
