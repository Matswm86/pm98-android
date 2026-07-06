#!/usr/bin/env python3
"""Bake the LINE-UP (ALINEACION) screen BODY chrome from the real game's frames.

Entry-flow doctrine (build_tactics_chrome_from_frames.py): the body chrome IS the
binding frame with every squad/state-dependent pixel cleared to a resting look;
LineupScreen draws the dynamic layer (rows, stars, role texts, AV, camrol, section
bands, scrollbar, right-panel state) on top with the game's own PROMAN fonts + art.

Binding frame:
  155_162931  Man Utd (home) vs Sao Paulo, Wed 6 Aug — RATING view, Solskjaer
              SELECTED (2px black row frame + white pitch markers + name band +
              attr values), Beckham INJURED ("+ 7 WEEKS 82|99" row, gold tint),
              UNDO shown (no TRAINING/INJURIES/STATISTICS).
Witness frames:
  003_162345  run 2, Mon 4 Aug — NO selection: nude attr buttons, empty name band,
              TEAM RATING 84 (4 stars), TRAINING/INJURIES/STATISTICS plate.
  160_162940  run 2 — post-swap, no selection, UNDO; RETURN caught HOT (ignored).
  128_154751  run 1 — PARAMETERS view: numeric columns + separators, PARAM-active
              plate + red arrow at PARAMETERS (run-1 palette == run-2, asserted).
  131_154800  run 1 — Sheringham selected + TRAINING/INJURIES/STATISTICS (the
              UNDO trigger is a pending XI change / forced injury change, NOT
              mere selection — 131 selects with T/I/S still shown).

Frame-decoded facts this bake rests on (all asserted below):
- Table: border cols x7-8 / x463-464, top y67-68, bottom y465-466; the column
  header band y69..86 is STATIC across modes/frames/runs (stays in chrome).
- Rows: 16px units (sep, 12px fill, sep, 2px white); XI fill tops y88+16i,
  SUBSTITUTES white band y263..285 (23px, ball icon + label), subs y287+16j,
  RESERVES band y366..387 (22px), reserves y389+16k.
- Row tint = the FORMATION SLOT's band (FUN_004fe2d0, same rule as TACTICS —
  155 walks the same 3-5-2 as tactics 014; row classes match exactly).
  gk (255,255,170) def (220,250,210) mid (204,204,255) fwd (255,191,170);
  subs UNIFORM (212,223,255), reserves UNIFORM (180,200,220); sep colours
  XI (128,128,128) / subs (120,120,160) / reserves (100,120,140).
- Card icons: FICHATIT (XI) / FICHACONV (subs) / FICHANOCONV (reserves) at the
  row's left, baked into the row templates.
- INJURED row (Beckham): gold tint, 1px BLACK frame, stars/role zone replaced
  by [cross box | count box | WEEKS box | FI | MO] cells; count/FI/MO digits
  dynamic, cross + box furniture static (cleared digits only). The box label
  ("WEEKS"/"DAYS" — both strings live at 0x661504) is drawn at runtime.
- SELECTED row (Solskjaer): 2px black frame at x28-29/x437-438, y fill-2..+13;
  the row content is the normal template underneath.
- RATING rows: STARJUGON strip (14px pitch, x172+14j, glyph top fill+1; odd
  half = STARJUGON-OFF — same glyph pair as the TACTICS board), fine-role
  SHORT name right-aligned to the x349 sep (ink 100,120,140), AV red
  cell-centred in [350,371), CAMROL 25x14 at x374, POS word on the tint.
- PARAMETERS rows (128): sep cols x173..323 step 25 + value cells, inks
  EN (150,0,0) SP/ST/AG/GU (100,100,140) FI (42,95,170) MO (80,110,5).
- Right panel: toggle plates both walked (155 RATING-on / 128 PARAM-on) + the
  red arrow beside the ACTIVE toggle; TEAM RATING strip (noise-dither fill —
  STAREQON stars frame-cut with a consistency alpha: the glyph core is the
  RECURSOS sprite, its dim ring is an engine shadow pass, so the sprite is
  cut from the frames where all instances agree); name band (black, white
  text); 2x3 attr buttons (nude plate from 003; values pale-blue + STARPARON
  stars are dynamic); CAMPO mini-pitch + DVERDE/AVERDE markers (DBLANCO/
  ABLANCO when selected); UNDO (chrome) vs T/I/S (plate from 003).
- Scrollbar: white track x438..462, ARROWUP/DOWN sprites, 14px thumb.

Outputs: app/art/screens/lineup/ + app/art/icons/lineup/ +
tools/re/specs/lineup_chrome_samples.json (mirrored to app/data/).

Run from anywhere:  python3 tools/re/build_lineup_chrome_from_frames.py
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import contextlib

import export_art as ea  # noqa: E402
import export_icons as ei  # noqa: E402
import pkf_unpack as pk  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
FRAMES = ROOT / "screenshots" / "original-walkthrough-2026-07-02"
if not FRAMES.exists():
    FRAMES = ROOT / "tools" / "re" / "refs" / "walkthrough-2026-07-02"
ART = ROOT / "app" / "art" / "screens" / "lineup"
ICONS = ROOT / "app" / "art" / "icons" / "lineup"
SPECS = Path(__file__).resolve().parent / "specs"
RECURSOS = ROOT / "extracted" / "Premier Manager 98" / "RECURSOS.PKF"

F155, F003, F160, F128, F131 = (
    "155_162931.png",
    "003_162345.png",
    "160_162940.png",
    "128_154751.png",
    "131_154800.png",
)

BODY_Y0 = 62
ROW_X0, ROW_X1 = 9, 438  # row template cut (card icon .. right border col)
XI_Y0, SUB_Y0, RES_Y0 = 88, 287, 389
BAND1, BAND2 = (263, 286), (366, 388)
TINTS = {
    "gk": (255, 255, 170),
    "def": (220, 250, 210),
    "mid": (204, 204, 255),
    "fwd": (255, 191, 170),
    "inj": (212, 191, 85),
    "sub": (212, 223, 255),
    "res": (180, 200, 220),
}
ROW_CLASS = ["gk", "def", "def", "def", "mid", "mid", "inj", "mid", "fwd", "mid", "fwd"]
SEL_ROW = 10
STAR_X0, STAR_PITCH = 172, 14
NAME_X = 67
NUM_SEPS = [173, 198, 223, 248, 273, 298, 323]
INJ_COUNT = (199, 223)  # count digits cell (bg 85,63,0, yellow ink)
INJ_WEEKS = (224, 298)  # label cell (bg 170,127,0, black ink)
INJ_FI = (299, 323)
INJ_MO = (324, 349)
AV_CELL = (350, 371)
CAMROL_X = 374
POS_CELL = (400, 437)
CAMPO_XY = (478, 248)
ATTR_BLOCK = (477, 168, 636, 247)
STRIP = (478, 119, 634, 150)
NAME_BAND = (479, 150, 636, 171)
TIS_RECT = (474, 348, 636, 442)
# plate cuts include the 2px white active-surround bottom rows: the 155vs128
# flip state spans y91..92 (param bottom) and y114..115 (rating bottom) — a
# 68:91/92:115 cut leaves rows 91/115 stuck in the 155 chrome state.
TOGGLE_PARAM = (477, 68, 634, 92)
TOGGLE_RATING = (477, 92, 634, 116)
ARROW_ZONE = (464, 68, 478, 116)


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


def save_rgba_arr(a: np.ndarray, p: Path) -> None:
    p.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(a.astype("uint8"), "RGBA").save(p)
    print(f"  {p.relative_to(ROOT)}  {a.shape[1]}x{a.shape[0]} (rgba)")


def save_rgba(im: Image.Image, p: Path) -> None:
    p.parent.mkdir(parents=True, exist_ok=True)
    im.save(p)
    print(f"  {p.relative_to(ROOT)}  {im.size[0]}x{im.size[1]}")


def recursos_sprites() -> dict:
    """Decode the ALINEACION-dir sprite cluster (around the 152x92 CAMPO.BMP)
    plus the STAR glyph family, with the game palette."""
    buf = RECURSOS.read_bytes()
    pal = ea.riff_palette("MANAGER.PAL")
    names = list(pk.files_of(buf))
    small_i = next(
        i
        for i, (n, o, s) in enumerate(names)
        if str(n).upper() == "CAMPO.BMP" and 12000 < s < 16000
    )
    out = {}
    for j in range(max(0, small_i - 25), min(len(names), small_i + 25)):
        n, o, s = names[j]
        u = str(n).upper()
        if u.endswith(".BMP") and u not in out:
            with contextlib.suppress(Exception):
                out[u] = ei.decode_dib(buf[o : o + s], pal)
    for i, (n, o, s) in enumerate(names):
        u = str(n).upper()
        if "STAR" in u and u not in out:
            out[u] = ei.decode_dib(buf[o : o + s], pal)
    return out


def find_exact(img: np.ndarray, spr: np.ndarray, zone: tuple) -> list:
    """All (x,y) where the RGBA sprite's opaque pixels match the frame exactly."""
    x0, y0, x1, y1 = zone
    al = spr[:, :, 3] > 0
    hh, ww = spr.shape[:2]
    hits = []
    for oy in range(y0, y1):
        for ox in range(x0, x1):
            win = img[oy : oy + hh, ox : ox + ww]
            if win.shape[:2] != (hh, ww):
                continue
            if np.array_equal(win[al], spr[:, :, :3][al]):
                hits.append((ox, oy))
    return hits


def main() -> None:
    f155 = load_frame(F155)
    f003 = load_frame(F003)
    f160 = load_frame(F160)
    f128 = load_frame(F128)
    f131 = load_frame(F131)
    spr = recursos_sprites()

    def A(nm):  # RGBA array of a decoded sprite
        return np.asarray(spr[nm].convert("RGBA")).astype(int)

    samples: dict = {}

    # ---- geometry invariants ------------------------------------------------
    for x in (7, 8, 463, 464):
        expect(tuple(f155[200, x]) == (0, 0, 0), f"table border col x{x}")
    for y in (67, 68, 465, 466):
        expect(tuple(f155[y, 200]) == (0, 0, 0), f"table border row y{y}")
    for g, tag in ((f003, "003"), (f160, "160"), (f128, "128"), (f131, "131")):
        expect(
            np.array_equal(f155[69:87, 9:463], g[69:87, 9:463]),
            f"column header band differs vs {tag}",
        )
    expect(
        np.array_equal(
            f003[TIS_RECT[1] : TIS_RECT[3], TIS_RECT[0] : TIS_RECT[2]],
            f128[TIS_RECT[1] : TIS_RECT[3], TIS_RECT[0] : TIS_RECT[2]],
        ),
        "T/I/S block differs 003 vs 128 (run palettes)",
    )
    for i, cls in enumerate(ROW_CLASS):
        expect(tuple(f155[XI_Y0 + 16 * i + 5, 150]) == TINTS[cls], f"XI row {i} tint != {cls}")
    for j in range(5):
        expect(tuple(f155[SUB_Y0 + 16 * j + 5, 155]) == TINTS["sub"], f"sub row {j} tint")
    for k in range(4):
        expect(tuple(f155[RES_Y0 + 16 * k + 5, 155]) == TINTS["res"], f"res row {k} tint")
    sy = XI_Y0 + 16 * SEL_ROW
    for yy in (sy - 2, sy - 1, sy + 12, sy + 13):
        expect(tuple(f155[yy, 200]) == (0, 0, 0), f"selected frame row y{yy}")
    for xx in (28, 29, 437, 438):
        expect(tuple(f155[sy + 5, xx]) == (0, 0, 0), f"selected frame col x{xx}")
    iy = XI_Y0 + 16 * 6
    for yy in (iy - 1, iy + 12):
        expect(tuple(f155[yy, 160]) == (0, 0, 0), f"injured frame row y{yy}")

    # ---- row star glyphs: STARJUGON pair, shared with the TACTICS board ------
    sj = np.asarray(
        Image.open(ROOT / "app/art/screens/tacticas/star_full.png").convert("RGBA")
    ).astype(int)
    sjo = np.asarray(
        Image.open(ROOT / "app/art/screens/tacticas/star_off.png").convert("RGBA")
    ).astype(int)
    expect(
        find_exact(f155, sj, (STAR_X0, XI_Y0 + 17, STAR_X0 + 2, XI_Y0 + 18))
        == [(STAR_X0, XI_Y0 + 17)],
        "row-1 star 0 is not STARJUGON at (172, fill+1)",
    )
    expect(
        find_exact(
            f155,
            sjo,
            (STAR_X0 + 4 * STAR_PITCH, XI_Y0 + 1, STAR_X0 + 4 * STAR_PITCH + 2, XI_Y0 + 2),
        )
        == [(STAR_X0 + 4 * STAR_PITCH, XI_Y0 + 1)],
        "row-0 (AV 89) half is not STARJUGON-OFF at cell 4",
    )

    # ---- attr-button star glyphs: STARPARON pair ------------------------------
    pa, po = A("STARPARON.BMP"), A("STARPARON-OFF.BMP")
    hits = find_exact(f155, pa, (478, 180, 636, 196))
    expect(len(hits) >= 3, f"STARPARON not on the attr buttons ({hits})")
    ys = {y for _, y in hits}
    expect(ys == {183}, f"attr star glyph top {ys} != 183")
    xs = sorted(x for x, _ in hits)
    expect(xs[0] == 557 and xs[1] - xs[0] == 10, f"attr star anchor/pitch {xs}")
    off_hits = find_exact(f155, po, (478, 180, 636, 196))
    expect((587, 183) in off_hits, "PASSING 72 half is not STARPARON-OFF")
    # left-column button (HANDLING 11): a lone half at the left anchor x479
    lh = find_exact(f155, po, (478, 180, 556, 196))
    expect((479, 183) in lh, f"HANDLING 11 lone half not at x479 ({lh})")
    samples["attr_star"] = {"x0": {"left": 479, "right": 557}, "pitch": 10, "dy": 12}

    # ---- TEAM RATING strip stars: POSITION-DETERMINISTIC per-cell patches ------
    # The strip fill is a noise dither, but the star blit is deterministic given
    # its position: the SAME cell renders pixel-identically across frames
    # (155 vs 003 cells 0..2: 0px). So the bake cuts per-cell PATCHES:
    #   full[j] j=0..3 (from 003, TEAM RATING 84 = 4 full stars),
    #   half[3] (from 155, 77 = 3 full + odd half), nude[4] (both frames).
    # Un-walked cells (full[4], half[!=3], nude[0..3]) reuse the nearest walked
    # patch — an in-band approximation only visible at un-walked ratings.
    EQX0, EQPITCH, EQY0, EQY1 = 512, 15, 133, 150
    for j in range(3):
        x = EQX0 + j * EQPITCH
        expect(
            np.array_equal(f155[EQY0:EQY1, x : x + EQPITCH], f003[EQY0:EQY1, x : x + EQPITCH]),
            f"strip star cell {j} not deterministic across frames",
        )
    nx = EQX0 + 4 * EQPITCH
    expect(
        np.array_equal(f155[EQY0:EQY1, nx : nx + EQPITCH], f003[EQY0:EQY1, nx : nx + EQPITCH]),
        "nude star cell 4 differs between 155 and 003",
    )
    full_patches = [
        f003[EQY0:EQY1, EQX0 + j * EQPITCH : EQX0 + (j + 1) * EQPITCH] for j in range(4)
    ]
    half_patch = f155[EQY0:EQY1, EQX0 + 3 * EQPITCH : EQX0 + 4 * EQPITCH]
    nude_patch = f155[EQY0:EQY1, nx : nx + EQPITCH]
    samples["strip_star"] = {"x0": EQX0, "pitch": EQPITCH, "y0": EQY0, "y1": EQY1}

    # ---- strip value ("77"/"84") ink + cell ------------------------------------
    # the value differs 155 vs 003 inside the strip right end; ink = the pale
    # (160,160,200) family, GDI-right/centred — record the diff bbox as the cell
    vz = (
        np.abs(
            f155[STRIP[1] : STRIP[3], 590 : STRIP[2]] - f003[STRIP[1] : STRIP[3], 590 : STRIP[2]]
        ).sum(axis=2)
        > 0
    )
    ys2, xs2 = np.where(vz)
    val_bbox = (
        590 + int(xs2.min()),
        STRIP[1] + int(ys2.min()),
        590 + int(xs2.max()),
        STRIP[1] + int(ys2.max()),
    )
    print(f"  strip value diff bbox {val_bbox}")
    samples["strip_value"] = {"bbox": list(val_bbox)}

    # ---- clean pitch + markers -------------------------------------------------
    campo = np.asarray(spr["CAMPO.BMP"].convert("RGB")).astype(int)
    ch, cw = campo.shape[:2]
    expect((ch, cw) == (92, 152), f"small campo {cw}x{ch}")
    cx, cy = CAMPO_XY
    pit155 = f155[cy : cy + ch, cx : cx + cw]
    # The pitch composite (decoded from 155/156/131 + the DAT_00660240 table):
    #   1. clean CAMPO
    #   2. movement arrows (AVERDE) then discs (DVERDE) for every XI slot, at
    #      (4 + raw_x*148//318, 3 + raw_y*88//198) — the RAW design-space
    #      coords, fields [4..7] of the slot row (NOT the 258x154 pre-scale)
    #   3. the SELECTED player's coverage-ZONE overlay: rect from fields [0..3]
    #      as (x0,y0,w,h) through the same mapping, applied as a per-colour
    #      dim LUT over everything under it (campo + green markers)
    #   4. the selected player's own markers in WHITE (DBLANCO/ABLANCO), drawn
    #      AFTER the zone (undimmed — 155/156 witness)
    # The bake PROVES the model by recomposing 155's pitch to 0px.
    forms = json.loads((ROOT / "app" / "data" / "formations.json").read_text())
    rec = next(r for r in forms["formations"] if r["name"] == "3-5-2")

    def mkmap(x, y):
        return (4 + x * 148 // 318, 3 + y * 88 // 198)

    dv, av, db, ab = A("DVERDE.BMP"), A("AVERDE.BMP"), A("DBLANCO.BMP"), A("ABLANCO.BMP")
    # one palette index decodes (192,227,192) under MANAGER.PAL but the walked
    # screen palette renders it (192,220,192) — 4 witness px in 155, marker
    # shadow ring only. Patch the sprites (and campo) to the frame truth.
    for s_arr in (dv, av, db, ab):
        m = (s_arr[:, :, :3] == np.array([192, 227, 192])).all(axis=2)
        s_arr[m, 1] = 220
    mm = (campo == np.array([192, 227, 192])).all(axis=2)
    campo[mm] = (192, 220, 192)

    def blit(dst, spr_a, x, y, lut=None):
        al = spr_a[:, :, 3] > 0
        hh2, ww2 = spr_a.shape[:2]
        x1, y1 = min(x + ww2, cw), min(y + hh2, ch)
        for yy in range(max(0, y), y1):
            for xx in range(max(0, x), x1):
                if al[yy - y, xx - x]:
                    dst[yy, xx] = spr_a[yy - y, xx - x, :3]

    # zone LUT: harvest witnessed (undimmed -> dimmed) pairs from 155+156+131
    def compose_greens(form_rec, sel_slot):
        img = campo.copy()
        slots = form_rec["slots"]
        gk = int(form_rec.get("gk_slot", 10))
        order = [gk] + [i for i in range(len(slots)) if i != gk]
        for si in order:
            raw = slots[si]["raw"]
            if si == sel_slot:
                continue
            m1 = mkmap(raw[4], raw[5])
            m2 = mkmap(raw[6], raw[7])
            if m2 != m1:
                blit(img, av, m2[0], m2[1])
        for si in order:
            raw = slots[si]["raw"]
            if si == sel_slot:
                continue
            m1 = mkmap(raw[4], raw[5])
            blit(img, dv, m1[0], m1[1])
        return img

    def zone_rect(raw):
        x0, y0 = mkmap(raw[0], raw[1])
        x1, y1 = mkmap(raw[0] + raw[2], raw[1] + raw[3])
        return (x0, y0, min(x1, cw), min(y1, ch))

    # The zone dim is a positional NOISE dither (the same source colour dims to
    # 2+ palette levels ~50/50 — same speckle family as the alert-title noise),
    # so no colour LUT can reproduce it. Doctrine: bake the walked zones as
    # verbatim PATCHES (they depend only on formation+slot — markers are slot
    # art, not player art — so a patch is exact for ANY career in that state),
    # plus a majority-vote LUT for un-walked zones (documented approximation).
    rec442 = next(r for r in forms["formations"] if r["name"] == "4-4-2")
    f156 = load_frame("156_162933.png")
    witnesses = [
        ("352_9", f155, rec, 9),
        ("352_5", f156, rec, 5),
        ("442_6", f131, rec442, 6),
    ]
    from collections import defaultdict

    votes: dict = defaultdict(lambda: defaultdict(int))
    zone_patches = {}
    for tag, frame, frec, sel in witnesses:
        base = compose_greens(frec, sel)
        zr = zone_rect(frec["slots"][sel]["raw"])
        px, py = CAMPO_XY
        pit = frame[py : py + ch, px : px + cw]
        # the base must equal the frame OUTSIDE the zone (markers proven)
        out = np.abs(base - pit).sum(axis=2) > 0
        out[zr[1] : zr[3], zr[0] : zr[2]] = False
        expect(
            int(out.sum()) == 0, f"{tag}: green composite differs outside zone ({int(out.sum())}px)"
        )
        zone_patches[tag] = pit[zr[1] : zr[3], zr[0] : zr[2]].copy()
        raw = frec["slots"][sel]["raw"]
        wcov = np.zeros((ch, cw), bool)
        for spr_a, (mx, my) in ((ab, mkmap(raw[6], raw[7])), (db, mkmap(raw[4], raw[5]))):
            al = spr_a[:, :, 3] > 0
            hh2, ww2 = spr_a.shape[:2]
            wcov[my : min(my + hh2, ch), mx : min(mx + ww2, cw)] |= al[
                : min(hh2, ch - my), : min(ww2, cw - mx)
            ]
        for yy in range(zr[1], zr[3]):
            for xx in range(zr[0], zr[2]):
                if not wcov[yy, xx]:
                    votes[tuple(base[yy, xx])][tuple(pit[yy, xx])] += 1
    maj_lut = {k: max(vs.items(), key=lambda kv: kv[1])[0] for k, vs in votes.items()}
    print(f"  zone majority LUT: {len(maj_lut)} colours (approx for un-walked zones)")

    # recomposition proof: base + walked patch + white markers == frame 155
    comp = compose_greens(rec, 9)
    zr = zone_rect(rec["slots"][9]["raw"])
    comp[zr[1] : zr[3], zr[0] : zr[2]] = zone_patches["352_9"]
    raw9 = rec["slots"][9]["raw"]
    m2 = mkmap(raw9[6], raw9[7])
    blit(comp, ab, m2[0], m2[1])
    m1 = mkmap(raw9[4], raw9[5])
    blit(comp, db, m1[0], m1[1])
    bad = int((np.abs(comp - pit155).sum(axis=2) > 0).sum())
    print(f"  pitch recomposition vs 155: {bad}px mismatch")
    expect(bad == 0, "pitch recomposition failed")
    for tag, patch in zone_patches.items():
        save(patch, ART / f"zone_{tag}.png")
    samples["campo_xy"] = list(CAMPO_XY)
    samples["mk_map"] = {"dx": 4, "dy": 3, "num_x": 148, "den_x": 318, "num_y": 88, "den_y": 198}
    samples["zone_patches"] = {
        t: list(zone_rect(fr["slots"][s]["raw"])) for t, _f, fr, s in witnesses
    }
    samples["zone_lut"] = {",".join(map(str, k)): list(v) for k, v in maj_lut.items()}

    # ---- toggle plates + the red active-arrow ----------------------------------
    tg = (
        np.abs(
            f155[TOGGLE_PARAM[1] : TOGGLE_RATING[3], 464:640]
            - f128[TOGGLE_PARAM[1] : TOGGLE_RATING[3], 464:640]
        ).sum(axis=2)
        > 0
    )
    ys4, xs4 = np.where(tg)
    print(
        f"  toggle-zone 155vs128 bbox x{464 + xs4.min()}..{464 + xs4.max()} y{68 + ys4.min()}..{68 + ys4.max()}"
    )
    plate_param_on = f128[TOGGLE_PARAM[1] : TOGGLE_PARAM[3], TOGGLE_PARAM[0] : TOGGLE_PARAM[2]]
    plate_rating_off = f128[
        TOGGLE_RATING[1] : TOGGLE_RATING[3], TOGGLE_RATING[0] : TOGGLE_RATING[2]
    ]

    # arrow: red pixels beside the active toggle
    def arrow_bbox(img, y0, y1):
        z = img[y0:y1, ARROW_ZONE[0] : ARROW_ZONE[2]]
        red = (z[:, :, 0] > 60) & (z[:, :, 1] < 40) & (z[:, :, 2] < 40)
        ys, xs = np.where(red)
        expect(ys.size > 0, "no red arrow found")
        return (
            ARROW_ZONE[0] + int(xs.min()),
            y0 + int(ys.min()),
            ARROW_ZONE[0] + int(xs.max()) + 1,
            y0 + int(ys.max()) + 1,
        )

    ab155 = arrow_bbox(f155, TOGGLE_RATING[1], TOGGLE_RATING[3])
    ab128 = arrow_bbox(f128, TOGGLE_PARAM[1], TOGGLE_PARAM[3])
    print(f"  arrow bbox 155(RATING)={ab155} 128(PARAM)={ab128}")
    # cut generous arrow patches (marble behind differs per spot -> per-spot patch)
    AW = (ARROW_ZONE[0], ARROW_ZONE[2])
    arrow_at_rating = f155[TOGGLE_RATING[1] : TOGGLE_RATING[3], AW[0] : AW[1]]
    arrow_at_param = f128[TOGGLE_PARAM[1] : TOGGLE_PARAM[3], AW[0] : AW[1]]
    nude_at_rating = f128[TOGGLE_RATING[1] : TOGGLE_RATING[3], AW[0] : AW[1]]
    nude_at_param = f155[TOGGLE_PARAM[1] : TOGGLE_PARAM[3], AW[0] : AW[1]]
    samples["toggle"] = {
        "param": list(TOGGLE_PARAM),
        "rating": list(TOGGLE_RATING),
        "arrow_w": AW[1] - AW[0],
    }

    # ---- chrome body -------------------------------------------------------------
    a = f155.copy()
    # 1. table interior (rows + bands + the selection-frame overflow col x438)
    #    -> white. The scrollbar column x439..462 is STATIC across every walked
    #    frame (arrows + thumb + track never change) and stays in chrome.
    a[87:465, 9:439] = (255, 255, 255)
    # 2. pitch -> clean campo
    a[cy : cy + ch, cx : cx + cw] = campo
    # 3. attr block <- 003 nude buttons
    x0, y0, x1, y1 = ATTR_BLOCK
    a[y0:y1, x0:x1] = f003[y0:y1, x0:x1]
    # 4. strip: erase star cells to the (approximated) nude base — the runtime
    # re-covers every cell up to the drawn rating with the exact walked patches
    for j in range(5):
        x = EQX0 + j * EQPITCH
        a[EQY0:EQY1, x : x + EQPITCH] = nude_patch
    vx0, vy0, vx1, vy1 = val_bbox
    # value zone: prefer 155-nude, else 003-nude, else row-median in-band fill
    zz = a[vy0 : vy1 + 1, vx0 : vx1 + 1]
    d155 = f155[vy0 : vy1 + 1, vx0 : vx1 + 1]
    d003 = f003[vy0 : vy1 + 1, vx0 : vx1 + 1]
    def ink(z):
        return (
            (np.abs(z - np.array([160, 160, 200])).sum(axis=2) < 150) & (z.sum(axis=2) > 330)
        )
    m155, m003 = ink(d155), ink(d003)
    zz[:] = d155
    zz[m155] = d003[m155]
    both = m155 & m003
    if both.any():
        med = np.median(d155[~m155].reshape(-1, 3), axis=0)
        zz[both] = med
    a[vy0 : vy1 + 1, vx0 : vx1 + 1] = zz
    # 5. name band interior -> black (erase the white glyphs)
    nb = a[NAME_BAND[1] + 5 : NAME_BAND[3] - 3, NAME_BAND[0] + 3 : NAME_BAND[2] - 3]
    white = nb.min(axis=2) > 150
    nb[white] = (0, 0, 0)
    a[NAME_BAND[1] + 5 : NAME_BAND[3] - 3, NAME_BAND[0] + 3 : NAME_BAND[2] - 3] = nb
    save(a[BODY_Y0:480], ART / "chrome.png")

    # ---- plates -------------------------------------------------------------------
    save(f003[TIS_RECT[1] : TIS_RECT[3], TIS_RECT[0] : TIS_RECT[2]], ART / "plate_tis.png")
    save(plate_param_on, ART / "plate_param_on.png")
    save(plate_rating_off, ART / "plate_rating_off.png")
    save(arrow_at_rating, ART / "arrow_at_rating.png")
    save(arrow_at_param, ART / "arrow_at_param.png")
    save(nude_at_rating, ART / "arrow_off_rating.png")
    save(nude_at_param, ART / "arrow_off_param.png")
    samples["tis_rect"] = list(TIS_RECT)

    # ---- section bands ---------------------------------------------------------
    save(f155[BAND1[0] : BAND1[1], 9:437], ART / "band_subs.png")
    save(f155[BAND2[0] : BAND2[1], 9:437], ART / "band_res.png")
    samples["bands"] = {"subs_h": BAND1[1] - BAND1[0], "res_h": BAND2[1] - BAND2[0]}

    # ---- scrollbar: static in chrome; patches for un-walked scroll states -------
    # The walked scrollbar never changes (scroll 0 everywhere): the DOWN box is
    # ARROWDOWNOFF verbatim at (443,434); the UP box is a composed at-limit look
    # no RECURSOS sprite reproduces (frame-cut patch). The thumb + track are cut
    # so the runtime can move the thumb for deep squads (documented, un-walked).
    dn_off = A("ARROWDOWNOFF.BMP")
    dh = find_exact(f155, dn_off, (440, 430, 448, 438))
    expect((443, 434) in dh, f"ARROWDOWNOFF not at (443,434) ({dh})")
    for nm, out in (
        ("ARROWUPOFF.BMP", "arrow_up_off"),
        ("ARROWUPON.BMP", "arrow_up_on"),
        ("ARROWDOWNOFF.BMP", "arrow_down_off"),
        ("ARROWDOWNON.BMP", "arrow_down_on"),
    ):
        save_rgba(spr[nm], ICONS / f"{out}.png")
    save(f155[388:404, 443:459], ART / "scroll_up_limit.png")
    save(f155[405:421, 439:462], ART / "scroll_thumb_strip.png")
    save(f155[422:433, 439:462], ART / "scroll_track_strip.png")
    samples["scroll"] = {"up_xy": [443, 388], "down_xy": [443, 434], "thumb_strip_xy": [439, 405]}

    # ---- row templates -----------------------------------------------------------
    def clear(row, x0, x1, y0, y1, bg):
        reg = row[y0:y1, x0 - ROW_X0 : x1 - ROW_X0]
        m = (reg != np.array(bg)).any(axis=2)
        reg[m] = bg
        row[y0:y1, x0 - ROW_X0 : x1 - ROW_X0] = reg
        return int(m.sum())

    def cut_row(frame, fill_top, cls):
        row = frame[fill_top - 1 : fill_top + 13, ROW_X0:ROW_X1].copy()
        tint = TINTS[cls]
        clear(row, 31, 49, 1, 13, tint)  # number
        clear(row, 50, 172, 1, 13, tint)  # name
        if cls == "inj":
            # keep cross + box furniture; clear the dynamic digits
            clear(row, INJ_COUNT[0] + 1, INJ_COUNT[1], 2, 12, (85, 63, 0))
            clear(row, INJ_WEEKS[0] + 1, INJ_WEEKS[1], 2, 12, (170, 127, 0))
            clear(row, INJ_FI[0] + 1, INJ_FI[1], 1, 13, tint)
            clear(row, INJ_MO[0] + 1, INJ_MO[1], 1, 13, tint)
        else:
            clear(row, 171, 349, 1, 13, tint)  # stars + role text
        clear(row, AV_CELL[0] + 1, AV_CELL[1], 1, 13, tint)  # AV
        row[0:14, CAMROL_X - ROW_X0 : CAMROL_X + 25 - ROW_X0] = (0, 0, 0)  # camrol backing
        clear(row, POS_CELL[0], POS_CELL[1], 1, 13, tint)  # POS word
        return row

    templates = {}
    for i, cls in enumerate(ROW_CLASS):
        y = XI_Y0 + 16 * i
        frame = f155.copy()
        if i == SEL_ROW:
            # strip the 2px selection frame back to the normal row border first
            frame[y - 2 : y, 28:439] = f155[y - 2 : y, 28:439] * 0 + np.array([255, 255, 255])
            frame[y + 12 : y + 14, 28:439] = (255, 255, 255)
            frame[y - 1, 29:438] = (128, 128, 128)
            frame[y + 12, 29:438] = (128, 128, 128)
            frame[y - 1 : y + 13, 28] = (255, 255, 255)
            frame[y - 1 : y + 13, 29] = (128, 128, 128)
            frame[y - 1 : y + 13, 437] = (128, 128, 128)
            frame[y - 1 : y + 13, 438] = (255, 255, 255)
            # interior border cols got painted black too; restore fill edges
            frame[y : y + 12, 30] = f155[y : y + 12, 30]
        row = cut_row(frame, y, cls)
        templates.setdefault(cls, []).append((i, row))
    for j in range(5):
        row = cut_row(f155, SUB_Y0 + 16 * j, "sub")
        templates.setdefault("sub", []).append((100 + j, row))
    for k in range(4):
        row = cut_row(f155, RES_Y0 + 16 * k, "res")
        templates.setdefault("res", []).append((200 + k, row))

    for cls, rows in templates.items():
        base_i, base = rows[0]
        for i, other in rows[1:]:
            if not np.array_equal(base, other):
                nbad = int((base != other).any(axis=2).sum())
                ys6, xs6 = np.where((base != other).any(axis=2))
                print(
                    f"  row template {cls}: row {i} differs from {base_i} by {nbad}px "
                    f"x{xs6.min()}..{xs6.max()} y{ys6.min()}..{ys6.max()}"
                )
                expect(False, f"row template {cls} not uniform")
        save(base, ART / f"row_{cls}.png")

    # cross-tint furniture identity (excluding the tier card icons + inj furniture)
    ref = None
    for cls in ("def", "mid", "fwd"):
        t = templates[cls][0][1].copy()
        t[(t == np.array(TINTS[cls])).all(axis=2)] = (0, 255, 255)
        if ref is None:
            ref = t
        else:
            expect(np.array_equal(ref, t), f"row furniture differs across tints ({cls})")

    # ---- numeric (PARAMETERS) view constants from 128 ---------------------------
    # sep colours per tier
    samples["numeric"] = {
        "seps": NUM_SEPS,
        "cells": [
            [174, 198],
            [199, 223],
            [224, 248],
            [249, 273],
            [274, 298],
            [299, 323],
            [324, 349],
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
        "sep_ink": {"xi": [128, 128, 128], "sub": [120, 120, 160], "res": [100, 120, 140]},
    }
    for sx in NUM_SEPS:
        expect(tuple(f128[XI_Y0 + 16 + 5, sx]) == (128, 128, 128), f"128 sep col x{sx}")

    # ---- attr-button star SHADOW (engine pass: glyph mask shifted +1,+1, the
    # uncovered pixels dimmed per the underlying button colour) ------------------
    # Witnesses: every 155 star instance over the 003-nude plate. The bake
    # harvests the dim LUT, then PROVES the model by recomposing all six
    # buttons' star strips to 0px vs 155.
    # The star glyphs on the blue buttons carry an engine SHADOW pass rendered
    # through the same positional noise dither as the coverage zone — no colour
    # or parity LUT reproduces it (measured: multi-valued per colour AND per
    # Bayer phase). Doctrine: the walked star strips are cut VERBATIM per
    # button (they depend only on the halves count at that button position);
    # the runtime blits a strip when the drawn halves equal the walked count
    # and falls back to plain glyphs (documented approximation) otherwise.
    # Walked signatures (Solskjaer 155): PO 11->1, PA 72->7, RM 84->8,
    # RG 81->8, EN 66->6, TI 79->8 halves.
    ATTR_SIG = [1, 7, 8, 8, 6, 8]
    ATTR_XY = [(479, 183), (557, 183), (479, 208), (557, 208), (479, 233), (557, 233)]
    for i, (x, y) in enumerate(ATTR_XY):
        save(f155[y : y + 12, x : x + 53], ART / f"attr_stars_{i}.png")
    plate_nude = f003[168:247, 477:636].copy()
    save(plate_nude, ART / "attr_plate.png")
    samples["attr_sig"] = ATTR_SIG
    samples["attr_strip_xy"] = [[x, y] for x, y in ATTR_XY]
    samples["attr_plate_xy"] = [477, 168]

    # ---- star sprites out --------------------------------------------------------
    save(campo, ART / "campo.png")
    save_rgba(spr["STARPARON.BMP"], ART / "star_paron_on.png")
    save_rgba(spr["STARPARON-OFF.BMP"], ART / "star_paron_off.png")
    for j, patch in enumerate(full_patches):
        save(patch, ART / f"star_eq_full_{j}.png")
    save(half_patch, ART / "star_eq_half.png")
    save(nude_patch, ART / "star_eq_nude.png")
    for nm, arr in (
        ("DVERDE.BMP", dv),
        ("AVERDE.BMP", av),
        ("DBLANCO.BMP", db),
        ("ABLANCO.BMP", ab),
    ):
        save_rgba_arr(arr, ICONS / (nm.lower().replace(".bmp", "") + ".png"))

    # ---- samples ------------------------------------------------------------------
    samples.update(
        {
            "body_y0": BODY_Y0,
            "xi_y0": XI_Y0,
            "row_pitch": 16,
            "row_x": [ROW_X0, ROW_X1],
            "tints": {k: list(v) for k, v in TINTS.items()},
            "star_x0": STAR_X0,
            "star_pitch": STAR_PITCH,
            "num_cell": [31, 49],
            "name_x": NAME_X,
            "role_right": 349,
            "role_ink": [100, 120, 140],
            "av_cell": list(AV_CELL),
            "av_ink": [210, 0, 0],
            "camrol_x": CAMROL_X,
            "pos_cell": list(POS_CELL),
            "num_ink": [0, 0, 128],
            "name_ink": [0, 0, 0],
            "inj": {
                "count_cell": list(INJ_COUNT),
                "count_ink": [255, 255, 0],
                "weeks_cell": list(INJ_WEEKS),
                "weeks_ink": [0, 0, 0],
                "fi_cell": list(INJ_FI),
                "fi_ink": [0, 0, 128],
                "mo_cell": list(INJ_MO),
                "mo_ink": [80, 110, 5],
            },
            "strip": list(STRIP),
            "name_band": list(NAME_BAND),
            "attr_rows_y": ATTR_ROWS_Y if (ATTR_ROWS_Y := [171, 196, 221]) else [],
            "attr_cols": [[481, 556], [558, 633]],
            "band1_y": BAND1[0],
            "band2_y": BAND2[0],
            "sub_y0": SUB_Y0,
            "res_y0": RES_Y0,
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
    out = SPECS / "lineup_chrome_samples.json"
    out.write_text(json.dumps(samples, indent=1) + "\n")
    print(f"  {out.relative_to(ROOT)}")
    app_out = ROOT / "app" / "data" / "lineup_chrome_samples.json"
    app_out.write_text(json.dumps(samples, indent=1) + "\n")
    print(f"  {app_out.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
