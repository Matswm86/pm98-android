#!/usr/bin/env python3
"""Bake the TACTICS (TACTICAS) board STATIC CHROME from the real game's own frame.

Same doctrine as build_team_offer_chrome_from_frames.py / build_make_offer_chrome_
from_frames.py (owner: "IT NEEDS TO BE EXACT"): the screen is engine-composited at
runtime, so the chrome layer IS the original frame with every player/formation-
dependent pixel cleared to a resting look; TacticsBoardScreen draws the dynamic
layer (XI rows, pitch markers, formation title, PARAM./RATING state) on top with
the game's own PROMAN fonts + art.

Binding frame (the ONLY tactics-board frame in the walkthrough):
  014_162413  Man Utd, 3-5-2, RATING view (run 2)
Witness frame (star-rule + half-star glyph only; the rival screen shares the
row star strip):
  015_162415  F.C. Barcelona VIEW RIVAL — rows with AV 89/90/91 show a HALF star,
              rows with AV<=88 show exactly 4: halves = (AV+1) div 10, the same
              errata'd rule as the FICHA skill stars (make_offer_re.md).

Frame-decoded facts this bake rests on (all asserted below):
- XI table: 11 row strips, 14px tall, 16px pitch, tops y87+16i; panel border
  x7-8/x631-632, y67-68; header band y69..86 (STATIC, stays in chrome).
- Row tint = the FORMATION SLOT's band, NOT the player's POS (FUN_004fe2d0):
  row 0 GK yellow; slot mk1.x_raw<0x41 -> DEF green; elif mk2.x_raw<0x104 ->
  MID lavender; else FWD salmon. In formations.json's pre-scaled space (raw*
  258/318): DEF mk1.x<52, FWD mk2.x>=211. Frame 014: Pallister & Sheringham sit
  in MID slots (lavender) while their POS boxes read DEF/FOR.
- Stars: STARJUGON.BMP (14x12) at x173+14j, glyph top y88; count = halves//2 of
  (AV+1) div 10 (all 22 frame observations 014+015 fit; STARPARON is 10px and
  cannot produce the measured 12px gold runs).
- Pitch: recursos\\iconos\\tacticas\\CAMPO.BMP is a DEDICATED 278x167 bitmap
  blitted 1:1 at (177,305) — the tacticas_screen_re.md "152x92 stretched" claim
  was WRONG (erratum written). Markers: DVERDE/AVERDE 16x16 top-left-anchored at
  (187+mk.x, 310+mk.y) with formations.json's pre-scaled mk (1:1, no second
  scaling); every 014 arrow is the horizontal AVERDE; digits ProMan8 black at
  glyph-row y+4, string centred on x+7 (disc) / x+5 (arrow).
- The AV value itself is an UN-RE'D in-engine derivation (no stored byte: not
  attrs-mean, not media, not any <=4-attr weighted mean — exhaustive integer
  search over 22 frame samples). The screen renders an injected/approximated
  value; the formula stays an honest gap (see tacticas_screen_re.md).

Outputs (app/art/screens/tacticas/ + app/art/icons/tacticas/):
  chrome.png       640x418 frame body (y62..480) with the XI rows cleared to
                   panel white, the pitch marker layer restored to clean CAMPO,
                   the formation-title text cleared, buttons/skill-grid baked
  row_gk/def/mid/fwd.png  624x14 row templates (card icon + tinted strip + role
                   band + arrow cell + POS box furniture; text/stars/AV/camrol
                   cleared)
  title_bar.png    278x30 the TACTICS title bar, text-zone columns rebuilt by
                   MIRRORING (centre approx — for un-walked formation titles;
                   the chrome itself keeps the frame bar with only the glyph
                   pixels cleared)
  plate_active/inactive.png  72x23 toggle plates with labels inpainted out, for
                   the UN-WALKED flipped state (documented extrapolation)
  star_full.png    14x12 STARJUGON (SAD-0 vs frame rows)
  star_off.png     14x12 STARJUGON-OFF — the dimmed star that RENDERS THE ODD
                   HALF (015 witness; not a clipped half glyph)
  campo.png        278x167 clean tacticas pitch (decoded CAMPO.BMP, SAD-0 vs
                   frame outside the marker layer)
  dverde/averde/droja/aroja/fleul/fleur/fledl/fledr.png  marker sprites
  tools/re/specs/tactics_chrome_samples.json (mirrored to app/data/)

Run from anywhere:  python3 tools/re/build_tactics_chrome_from_frames.py
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import export_art as ea  # noqa: E402
import export_icons as ei  # noqa: E402
import pkf_unpack as pk  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
FRAMES = ROOT / "screenshots" / "original-walkthrough-2026-07-02"
if not FRAMES.exists():  # full capture set is local-only; binding frames are committed
    FRAMES = ROOT / "tools" / "re" / "refs" / "walkthrough-2026-07-02"
ART = ROOT / "app" / "art" / "screens" / "tacticas"
ICONS = ROOT / "app" / "art" / "icons" / "tacticas"
SPECS = Path(__file__).resolve().parent / "specs"
RECURSOS = ROOT / "extracted" / "Premier Manager 98" / "RECURSOS.PKF"

F014 = "014_162413.png"
F015 = "015_162415.png"

BODY_Y0 = 62  # chrome top: below the shared barra/header
ROW_Y0, ROW_H, ROW_PITCH = 87, 14, 16
ROW_X0, ROW_X1 = 8, 632  # card icon + strip, inside the panel border
TINTS = {  # frame-measured strip fills (palette-snapped)
    "gk": (255, 255, 170),
    "def": (220, 250, 210),
    "mid": (204, 204, 255),
    "fwd": (255, 191, 170),
}
# frame 014 row -> tint class (from the slot-band rule; asserted against pixels)
ROW_CLASS = ["gk", "def", "def", "def", "mid", "mid", "mid", "mid", "fwd", "mid", "fwd"]
STAR_X0, STAR_PITCH, STAR_Y = 172, 14, 89  # sprite box (gold runs start 1px right)
CAMPO_XY = (177, 305)
MARK_ORIGIN = (187, 310)
TITLE_BAR = (177, 275, 455, 305)  # x0,y0,x1,y1 exclusive
PARAM_BTN = (478, 286, 550, 309)
RATING_BTN = (558, 286, 630, 309)
# frame 014 slot -> shirt number (read off the discs; drives the marker asserts)
SLOT_SHIRT = {0: 2, 1: 3, 2: 21, 3: 6, 4: 8, 5: 7, 6: 10, 7: 9, 8: 11, 9: 20, 10: 1}


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


def tacticas_sprites() -> dict:
    """Decode the TACTICAS-dir sprites (the entries clustered around the big
    278x167 CAMPO.BMP; RECURSOS holds same-named 10x10 lineup variants in
    another dir) with the game palette."""
    buf = RECURSOS.read_bytes()
    pal = ea.riff_palette("MANAGER.PAL")
    names = list(pk.files_of(buf))
    big_i = next(
        i for i, (n, o, s) in enumerate(names) if str(n).upper() == "CAMPO.BMP" and s > 40000
    )
    want = {
        "CAMPO.BMP",
        "DVERDE.BMP",
        "AVERDE.BMP",
        "DROJA.BMP",
        "AROJA.BMP",
        "FLEUL.BMP",
        "FLEUR.BMP",
        "FLEDL.BMP",
        "FLEDR.BMP",
        "STARJUGON.BMP",
        "STARJUGON-OFF.BMP",
    }
    out = {}
    for j in range(big_i - 60, big_i + 60):
        if j < 0 or j >= len(names):
            continue
        n, o, s = names[j]
        u = str(n).upper()
        if u in want and u not in out:
            out[u] = ei.decode_dib(buf[o : o + s], pal)
    missing = want - set(out)
    expect(not missing, f"RECURSOS tacticas sprites missing: {missing}")
    return out


def replace_nonbg(a, x0, y0, x1, y1, bg, allowed, tag, max_extra=0) -> int:
    """Within the rect, set every pixel != bg to bg. Asserts the replaced pixels'
    colours are within `allowed` (+/-tolerance handled by exact palette pixels;
    max_extra tolerates a few anti-pattern pixels e.g. glyph shadows)."""
    reg = a[y0:y1, x0:x1]
    m = (reg != np.array(bg)).any(axis=2)
    bad = 0
    if m.any():
        cols = {tuple(c) for c in reg[m].reshape(-1, 3)}
        extra = cols - set(allowed)
        bad = len(extra)
        expect(bad <= max_extra, f"{tag}: unexpected colours {sorted(extra)[:6]}")
    reg[m] = bg
    a[y0:y1, x0:x1] = reg
    return int(m.sum())


def main() -> None:
    f014 = load_frame(F014)
    f015 = load_frame(F015)
    spr = tacticas_sprites()

    # ---- frame invariants: geometry --------------------------------------
    expect(tuple(f014[67, 300]) == (0, 0, 0), "table panel top border y67")
    expect(tuple(f014[100, 7]) == (0, 0, 0), "panel left border x7")
    expect(tuple(f014[100, 631]) == (0, 0, 0), "panel right border x631")
    for i, cls in enumerate(ROW_CLASS):
        y = ROW_Y0 + ROW_PITCH * i + 7
        expect(tuple(f014[y, 150]) == TINTS[cls], f"row {i} tint != {cls}")
        expect(tuple(f014[y + 8, 150]) == (255, 255, 255), f"row {i} gap not white")

    # ---- clean pitch: the dedicated 278x167 CAMPO.BMP, 1:1 at (177,305) ---
    campo = np.asarray(spr["CAMPO.BMP"].convert("RGB")).astype(int)
    expect(campo.shape[:2] == (167, 278), f"big CAMPO decode {campo.shape}")
    frm = f014[CAMPO_XY[1] : CAMPO_XY[1] + 167, CAMPO_XY[0] : CAMPO_XY[0] + 278]
    d = np.abs(frm - campo).sum(axis=2) > 0
    # every mismatch must lie under a marker sprite box (16x16 at mk1/mk2)
    forms = json.loads((ROOT / "app" / "data" / "formations.json").read_text())
    rec = next(r for r in forms["formations"] if r["name"] == "3-5-2")
    cover = np.zeros_like(d)
    for s in rec["slots"]:
        for mk in (s["mk1"], s["mk2"]):
            x = MARK_ORIGIN[0] + mk[0] - CAMPO_XY[0]
            y = MARK_ORIGIN[1] + mk[1] - CAMPO_XY[1]
            cover[y : y + 16, x : x + 16] = True
    stray = d & ~cover
    expect(int(stray.sum()) == 0, f"pitch mismatch outside markers: {int(stray.sum())}px")

    # ---- marker sprites: SAD-0 at 1:1 positions (digits excluded) ---------
    dverde = np.asarray(spr["DVERDE.BMP"]).astype(int)
    averde = np.asarray(spr["AVERDE.BMP"]).astype(int)
    for i, s in enumerate(rec["slots"]):
        for kind, mk, sp in (("disc", s["mk1"], dverde), ("arrow", s["mk2"], averde)):
            if kind == "arrow" and s["mk1"] == s["mk2"]:
                continue  # GK: no movement arrow
            X, Y = MARK_ORIGIN[0] + mk[0], MARK_ORIGIN[1] + mk[1]
            al = sp[:, :, 3] > 0
            win = f014[Y : Y + 16, X : X + 16]
            diff = (np.abs(win - sp[:, :, :3]).sum(axis=2) > 0) & al
            # residual = the shirt digits only (7px tall at y+4)
            ys, xs = np.where(diff)
            expect(
                ys.size > 0 and ys.min() >= 4 and ys.max() <= 10,
                f"slot {i} {kind}: residual not digit-shaped (y {ys.min()}..{ys.max()})",
            )

    # ---- star glyph: STARJUGON 14x12 at x173+14j, top y88 -----------------
    star = np.asarray(spr["STARJUGON.BMP"]).astype(int)
    expect(star.shape[:2] == (12, 14), f"STARJUGON {star.shape}")
    al = star[:, :, 3] > 0
    for i in range(11):
        y = STAR_Y + ROW_PITCH * i
        for j in range(4):  # every 014 row has exactly 4 full stars
            x = STAR_X0 + STAR_PITCH * j
            win = f014[y : y + 12, x : x + 14]
            expect(
                np.array_equal(win[al], star[al][:, :3])
                or np.array_equal(win[al], star[:, :, :3][al]),
                f"star mismatch row {i} pos {j}",
            )
        # and NO 5th star (all 014 AVs <= 88)
        x5 = STAR_X0 + STAR_PITCH * 4
        win = f014[y : y + 12, x5 : x5 + 14]
        expect(not np.array_equal(win[al], star[:, :, :3][al]), f"unexpected 5th star row {i}")
    # odd-half witness: 015 rival rows with AV 89/91/90 (halves=(AV+1)div10 odd)
    # show STARJUGON-OFF as the 5th glyph; rows with AV<=88 show nothing there.
    # PM98 renders the half-star as the DIMMED star, not a clipped half.
    star_off = np.asarray(spr["STARJUGON-OFF.BMP"]).astype(int)
    al_o = star_off[:, :, 3] > 0
    for i, has_off in (
        (0, False),
        (1, False),
        (2, False),
        (3, True),
        (4, False),
        (5, True),
        (6, True),
        (7, False),
        (8, False),
        (9, True),
        (10, True),
    ):
        y = 103 + 16 * i + 1
        win = f015[y : y + 12, 174 + 14 * 4 : 174 + 14 * 4 + 14]
        is_off = np.array_equal(win[al_o], star_off[:, :, :3][al_o])
        expect(is_off == has_off, f"015 row {i}: OFF-star presence != {has_off}")

    # ---- bake the sprites --------------------------------------------------
    save_rgba(spr["CAMPO.BMP"].convert("RGB"), ART / "campo.png")
    for nm in ("DVERDE", "AVERDE", "DROJA", "AROJA", "FLEUL", "FLEUR", "FLEDL", "FLEDR"):
        save_rgba(spr[f"{nm}.BMP"], ICONS / f"{nm.lower()}.png")
    save_rgba(spr["STARJUGON.BMP"], ART / "star_full.png")
    save_rgba(spr["STARJUGON-OFF.BMP"], ART / "star_off.png")

    # ---- row templates -----------------------------------------------------
    # dynamic zones (x ranges) cleared per row; colours asserted:
    ROLE_BAND = (402, 566)  # flat (140,160,180) interior; text greys
    samples = {}
    band_fill = (140, 160, 180)
    templates = {}

    def clear(row, x0, x1, y0, y1, bg):
        reg = row[y0:y1, x0 - ROW_X0 : x1 - ROW_X0]
        m = (reg != np.array(bg)).any(axis=2)
        reg[m] = bg
        row[y0:y1, x0 - ROW_X0 : x1 - ROW_X0] = reg
        return int(m.sum())

    for i, cls in enumerate(ROW_CLASS):
        y = ROW_Y0 + ROW_PITCH * i
        row = f014[y : y + ROW_H, ROW_X0:ROW_X1].copy()
        tint = TINTS[cls]

        # N. digits + name (navy ink on tint; descenders reach rel y12), stars, AV.
        # The AV clear starts at 350: x349 is a baked grey separator column.
        clear(row, 30, 55, 2, 13, tint)
        clear(row, 56, 170, 2, 13, tint)
        clear(row, 171, 234, 1, 13, tint)
        clear(row, 350, 371, 2, 13, tint)
        # camrol sprite cell: resting = black backing (the sprite covers it fully
        # at draw time; the border pixels around it are part of the furniture)
        row[1:13, 375 - ROW_X0 : 400 - ROW_X0] = (0, 0, 0)
        # ROLE band interior text
        reg = row[3:11, ROLE_BAND[0] - ROW_X0 : ROLE_BAND[1] - ROW_X0]
        reg[(reg != np.array(band_fill)).any(axis=2)] = band_fill
        row[3:11, ROLE_BAND[0] - ROW_X0 : ROLE_BAND[1] - ROW_X0] = reg
        # POS word (black on white box interior; x623 is the box's inner border)
        reg = row[2:12, 589 - ROW_X0 : 623 - ROW_X0]
        reg[(reg != np.array([255, 255, 255])).any(axis=2)] = (255, 255, 255)
        row[2:12, 589 - ROW_X0 : 623 - ROW_X0] = reg

        templates.setdefault(cls, []).append((i, row))

    for cls, rows in templates.items():
        base_i, base = rows[0]
        for i, other in rows[1:]:
            if not np.array_equal(base, other):
                nbad = int((base != other).any(axis=2).sum())
                expect(False, f"row template {cls}: row {i} differs from row {base_i} by {nbad}px")
        save(base, ART / f"row_{cls}.png")

    # cross-tint: the furniture must be identical once tint pixels are unified
    ref = None
    for cls, rows in templates.items():
        t = rows[0][1].copy()
        t[(t == np.array(TINTS[cls])).all(axis=2)] = (0, 255, 255)
        if ref is None:
            ref = t
        else:
            expect(np.array_equal(ref, t), f"row furniture differs across tints ({cls})")

    # ---- chrome body -------------------------------------------------------
    a = f014.copy()
    # rows -> panel white
    for i in range(11):
        y = ROW_Y0 + ROW_PITCH * i
        a[y : y + ROW_H, ROW_X0:ROW_X1] = (255, 255, 255)
    # pitch -> clean campo
    a[CAMPO_XY[1] : CAMPO_XY[1] + 167, CAMPO_XY[0] : CAMPO_XY[0] + 278] = campo
    # Title bar. The bar is a mirror-symmetric DITHERED GRADIENT the engine draws
    # (only 3 distinct column types; no clean period, no source bitmap found — the
    # IMG.PKF DEGRADADO masks are unrelated noise dithers). Two artefacts:
    #  1. chrome: clear ONLY the white GLYPH pixels of "TACTICS 3-5-2" (to the
    #     bar's dominant column colour). The screen repaints the identical text,
    #     so parity still verifies the text draw; every non-glyph pixel stays
    #     frame-true.
    #  2. title_bar.png: a fully cleared bar for OTHER formations — the text-zone
    #     columns are rebuilt by MIRRORING the clean right-side columns (exact
    #     where the pattern is symmetric; the centre segment run is a documented
    #     approximation for un-walked formation titles).
    x0, y0, x1, y1 = TITLE_BAR
    bar = a[y0:y1, x0:x1].copy()
    ink = (bar[:, :, 0] > 180) & (bar[:, :, 1] > 180) & (bar[:, :, 2] > 180)
    ys, xs = np.where(ink)
    expect(ys.size > 0, "title bar: no text ink found")
    tx0, tx1 = int(xs.min()), int(xs.max()) + 1
    # dominant interior colour (the B column type)
    interior = bar[3:-3, 6:60].reshape(-1, 3)
    vals, counts = np.unique(interior, axis=0, return_counts=True)
    bcol = vals[counts.argmax()]
    # 1) chrome: glyph pixels -> B colour
    chrome_bar = bar.copy()
    chrome_bar[ink] = bcol
    a[y0:y1, x0:x1] = chrome_bar
    # 2) title_bar.png: text-zone columns <- mirror of the clean right side
    clean_bar = bar.copy()
    wbar = clean_bar.shape[1]
    for x in range(tx0, tx1):
        clean_bar[:, x] = bar[:, wbar - 1 - x]
    # the mirror source of the leading text columns may itself be text (the text
    # is off-centre by a pixel); fall back to the B column for any leftover ink
    ink2 = (clean_bar[:, :, 0] > 180) & (clean_bar[:, :, 1] > 180) & (clean_bar[:, :, 2] > 180)
    clean_bar[ink2] = bcol
    save(clean_bar, ART / "title_bar.png")

    # PARAM./RATING plates for the un-walked flipped states: cut the observed
    # buttons, clear their labels by row-median inpaint (documented extrapolation)
    def plate(rect, out_name):
        x0, y0, x1, y1 = rect
        cut = a[y0:y1, x0:x1].copy()
        for yy in range(2, cut.shape[0] - 2):
            rowpx = cut[yy, 2:-2]
            med = np.median(np.concatenate([rowpx[:6], rowpx[-6:]]), axis=0)
            m = np.abs(rowpx - med).mean(axis=1) > 40
            rowpx[m] = med
            cut[yy, 2:-2] = rowpx
        save(cut, ART / out_name)
        return cut

    plate(PARAM_BTN, "plate_inactive.png")  # from PARAM. (inactive in 014)
    plate(RATING_BTN, "plate_active.png")  # from RATING (active red glow)

    save(a[BODY_Y0:480], ART / "chrome.png")

    # ---- samples json ------------------------------------------------------
    def ink_colour(x0, y0, x1, y1, pick="dark"):
        reg = f014[y0:y1, x0:x1].reshape(-1, 3)
        key = (lambda p: p.sum()) if pick == "dark" else (lambda p: -p.sum())
        return [int(v) for v in min(reg, key=key)]

    samples.update(
        {
            "body_y0": BODY_Y0,
            "row_y0": ROW_Y0,
            "row_h": ROW_H,
            "row_pitch": ROW_PITCH,
            "row_x": [ROW_X0, ROW_X1],
            "tints": {k: list(v) for k, v in TINTS.items()},
            "band_def_max_mk1x": 52,
            "band_fwd_min_mk2x": 211,
            "num_cx": 41,
            "num_y": 89,
            "name_x": 60,
            "name_y": 89,
            "star_x0": STAR_X0,
            "star_pitch": STAR_PITCH,
            "star_dy": STAR_Y - ROW_Y0,
            "av_right": 369,
            "av_y": 91 - ROW_Y0,
            "camrol_xy": [375, 0],
            "role_band": [402, 566],
            "role_y": 90 - ROW_Y0,
            "pos_box": [588, 630],
            "pos_y": 89 - ROW_Y0,
            "num_ink": ink_colour(33, 89, 50, 98),
            "name_ink": ink_colour(60, 89, 160, 98),
            "av_ink": [
                int(v)
                for v in max(
                    f014[91:98, 345:370].reshape(-1, 3), key=lambda p: int(p[0]) - int(p[2])
                )
            ],
            "role_ink": ink_colour(430, 90, 540, 98),
            "campo_xy": list(CAMPO_XY),
            "mark_origin": list(MARK_ORIGIN),
            "digit_y": 4,
            "disc_cx": 7,
            "arrow_cx": 5,
            "title_bar": list(TITLE_BAR),
            "param_btn": list(PARAM_BTN),
            "rating_btn": list(RATING_BTN),
            "frame_avs": {
                "SCHMEICHEL": 88,
                "GARY NEVILLE": 81,
                "IRWIN": 84,
                "BERG": 85,
                "PALLISTER": 81,
                "BUTT": 83,
                "BECKHAM": 87,
                "SHERINGHAM": 80,
                "COLE": 84,
                "GIGGS": 87,
                "SOLSKJAER": 85,
            },
            "slot_shirts_014": {str(k): v for k, v in SLOT_SHIRT.items()},
        }
    )
    SPECS.mkdir(parents=True, exist_ok=True)
    out = SPECS / "tactics_chrome_samples.json"
    out.write_text(json.dumps(samples, indent=1) + "\n")
    print(f"  {out.relative_to(ROOT)}")
    app_out = ROOT / "app" / "data" / "tactics_chrome_samples.json"
    app_out.write_text(json.dumps(samples, indent=1) + "\n")
    print(f"  {app_out.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
