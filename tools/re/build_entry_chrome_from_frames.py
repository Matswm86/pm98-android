#!/usr/bin/env python3
"""Bake the career-entry-flow STATIC CHROME from the real game's own frames.

Same doctrine as build_menu_bg_from_ref.py: these screens' look is engine-COMPOSITED
at runtime (fondo + barra + widget furniture + fonts); no single PKF asset holds it,
and rebuilding the furniture procedurally drifts (owner: "IT NEEDS TO BE EXACT").
The walkthrough PNGs (screenshots/original-walkthrough-2026-07-02, 641x480 captures
of the real game — rightmost column is a capture artifact, cropped) are pixel-exact:
PKF sprites SAD-match them at 0.0 (PUN10 @ (79,65) etc.). So the chrome layer IS the
original frame, with ONLY the state-dependent pixels cleared to their resting look;
the screens draw the dynamic layer (digits, labels, kits, picks) on top with the
game's own PROMAN fonts.

Outputs (under app/art/):
  screens/nivel/chrome.png       453x415  frame 003 dialog crop (93,32)-(546,447)
  screens/nivel/load_modal.png   360x276  frame 005 modal crop (140,102)-(500,378)
  screens/seleccion/chrome.png   640x480  frame 008 verbatim, ONLY the caret erased
                                          (resting = slot 1 active-empty, all baked)
  screens/seleccion/row1_degap.png        frame 011 rows 104..121 (slot 1 without
                                          its outline — the exposed true background)
  screens/seleccion/player_cell.png       digit-free PLAYER number cell
  screens/seleccion/panel_ball.png        gold panel-title ball (237,272) 21x30
  screens/seleccion/plaque_sel/unsel.png  division-plaque interior state textures
  screens/seleccion/continue_on.png       solid CONTINUE (frame 012; disabled = washed)
  screens/pretemp/chrome.png     640x480  frame 013 verbatim (== frame 016)
  screens/pretemp/riv_*.png               rival-slot state textures (digit-free)
  screens/pretemp/div_chip.png            label-less division button chip
  screens/pretemp/delete_on.png           solid DELETE (frame 008's identical chip)
  screens/pretemp/title_band.png          textless barra band (row-median inpaint)
  kits/panel/<id>.png            24x32    frame-008-rendered Premier panel kits
  kits/panel13/<id>.png          24x32    frame-013-rendered (pretemp dither phase)
  kits/washed/<id>.png           24x32    frame-proven washed (taken) kit (Man Utd)
  tools/re/specs/entry_chrome_samples.json   sampled colours the screens draw with

Every measured invariant is asserted against the frames so a regenerated walkthrough
or a bad crop fails loudly instead of baking garbage.

Run from anywhere:  python3 tools/re/build_entry_chrome_from_frames.py
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
ART = ROOT / "app" / "art" / "screens"
SPECS = Path(__file__).resolve().parent / "specs"

F003 = "003_154332.png"  # nivel dialog, settled
F005 = "005_154338.png"  # nivel + LOAD GAME modal (all rows empty)
F008 = "008_154345.png"  # seleccion, fresh (slot 1 active-empty)
F011 = "011_154354.png"  # seleccion, slot 1 filled MWM/Man Utd, slot 2 active
F012 = "012_154356.png"  # seleccion, slot 1 filled -> CONTINUE bright
F013 = "013_154358.png"  # preseason, fresh (== frame 016 pixel-exact)


def load(name: str) -> np.ndarray:
    a = np.asarray(Image.open(FRAMES / name).convert("RGB"))
    if a.shape[0] != 480 or a.shape[1] not in (640, 641):
        raise SystemExit(f"{name}: unexpected size {a.shape}")
    return a[:, :640].copy()  # 641st column = capture artifact


def save(a: np.ndarray, rel: str) -> None:
    p = ART / rel
    p.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(a.astype("uint8")).save(p)
    print(f"  {p.relative_to(ROOT)}  {a.shape[1]}x{a.shape[0]}")


def row_median_inpaint(
    a: np.ndarray, x0: int, y0: int, x1: int, y1: int, margin: int = 10, thresh: int = 40
) -> None:
    """Erase minority-colour text inside a chip: per row, fill pixels that deviate
    from the row's margin-median by > thresh with that median (keeps the chip's
    horizontal gradient / grid texture rows intact)."""
    for y in range(y0, y1):
        row = a[y, x0:x1].astype(int)
        med = np.median(np.concatenate([row[:margin], row[-margin:]]), axis=0)
        mask = np.abs(row - med).mean(axis=1) > thresh
        row[mask] = med
        a[y, x0:x1] = row


def expect(cond: bool, what: str) -> None:
    if not cond:
        raise SystemExit(f"frame invariant FAILED: {what}")


# --------------------------------------------------------------------------- nivel


def build_nivel() -> None:
    f03 = load(F003)
    f05 = load(F005)
    # dialog rect reversed from MANAGER.EXE (id 1034) + verified by frame diff
    expect(
        tuple(f03[42, 320]) == (255, 255, 255) or f03[42, 100:540].max() > 200,
        "003 title strip present",
    )
    save(f03[32:447, 93:546], "nivel/chrome.png")

    # LOAD modal: bbox measured via diff(005,003) == x 140..499 y 102..377
    d = np.abs(f05.astype(int) - f03.astype(int)).mean(axis=2) > 8
    ys, xs = np.where(d)
    expect(
        (xs.min(), xs.max(), ys.min(), ys.max()) == (140, 499, 102, 377),
        f"modal bbox drifted: {xs.min()},{xs.max()},{ys.min()},{ys.max()}",
    )
    save(f05[102:378, 140:500], "nivel/load_modal.png")


# ----------------------------------------------------------------------- seleccion

# slot grid, frame-measured (scan y=110/128, col x=200): badge fill x 23..43,
# name bar x 45..148 (140,160,180), club bar x 150..307 (160,160,200); black
# 1px frame; row-1 fill y 107..118, pitch 16; right column = +312.
SLOT_Y0 = 107
PITCH = 16
COLX = 312  # right-column offset
GOLD_BAR = (212, 191, 0)
LAV_BAR = (160, 160, 200)


def build_seleccion() -> dict:
    f08 = load(F008)
    f12 = load(F012)
    expect(tuple(f08[110, 150]) == GOLD_BAR, "008 slot-1 club bar gold")
    expect(tuple(f08[128, 150]) == LAV_BAR, "008 slot-2 club bar lavender")
    expect(tuple(f08[110 + 2 * PITCH, 150]) == LAV_BAR, "008 slot-3 club bar lavender")

    a = f08.copy()

    # Chrome keeps the slot grid BAKED exactly as frame 008 (slot 1 active-empty IS
    # the resting state, original digit rasters and all). When the active outline
    # leaves slot 1, its white rows must become BACKGROUND — the true pixels exist
    # in frame 011 (slot 1 filled there): cut rows 104..121 x 14..314 as the
    # "degap" strip (the fill/badge inside get redrawn per state anyway).
    f11 = load(F011)
    save(f11[104:122, 14:315], "seleccion/row1_degap.png")

    # -- PLAYER bar: cut a digit-free number-cell texture (flat dark-red fill,
    # black frame x 251-252/292) for redraws when the active slot moves; the
    # chrome keeps the baked '1'. Erase only the text CARET from the name field
    # (the screen's LineEdit paints its own).
    cell = f08[67:92, 251:293].copy()
    for y in range(2, 24):
        marg = np.concatenate([cell[y, 3:8], cell[y, 34:40]]).astype(int)
        cell[y, 2:41] = np.median(marg, axis=0)
    save(cell, "seleccion/player_cell.png")
    nf = a[68:91, 293:489].astype(int)
    nf[np.abs(nf - 0).mean(axis=2) > 40] = (0, 0, 0)
    a[68:91, 293:489] = nf

    # -- kit panel. Frame-measured structure: black outer border (150,276)-(490,406),
    # white margin, then a GOLD FRAME RECT x 158..480 / y 291..383 (single-pixel
    # lines). The panel-title composition (gold rules + ball + division name) SITS ON
    # the top gold line with white padding gaps, and the picked club's name sits in
    # the white margin BELOW the bottom line (frame 010). Chrome bakes the COMPLETE
    # gold rect (the segments hidden by title/ball are tiled from the line's own
    # visible pixels); the screen draws ball+title with white padding over it.
    white = tuple(int(v) for v in f08[398, 160])
    expect(min(white) > 235, f"panel white sample {white}")
    gold_rect = (158, 291, 480, 383)
    # frame-check the gold rect: heavy gold rows/cols exactly there
    gm = (
        (np.abs(f08[:, :, 0] - 212) < 50) & (np.abs(f08[:, :, 1] - 170) < 60) & (f08[:, :, 2] < 120)
    )
    gm[:276] = gm[407:] = False
    gm[:, :150] = gm[:, 491:] = False
    ys_g, xs_g = np.where(gm)
    expect(
        xs_g.min() == 158 and xs_g.max() == 480 and ys_g.max() == 383,
        f"panel gold frame drifted: {xs_g.min()},{xs_g.max()},{ys_g.max()}",
    )
    rule_col = tuple(int(v) for v in np.median(f08[291, 165:220].astype(int), axis=0))
    # ball sprite: exact extent SAD-anchored at (237,272) 21px wide, plus the faint
    # shadow rows through y301 (parity diff caught them at x241..253 y300..301)
    save(f08[272:302, 237:258], "seleccion/panel_ball.png")
    title_probe = f08[278:290, 260:420].astype(int)
    tm = np.abs(title_probe - white).mean(axis=2) > 40
    title_col = (
        tuple(int(v) for v in np.median(title_probe[tm], axis=0)) if tm.any() else (223, 191, 0)
    )
    # The panel stays BAKED (resting = Premier division, and GameDB's alphabetical
    # club order == the frame's kit order — verified: Man Utd at cell 13 both ways).
    # Interactive repaints redraw white fill + gold rect + ball/title/kits from the
    # sampled geometry above.

    # -- plaques stay BAKED (the resting screen really is Premier-selected, and the
    # baked labels ARE the DB league names). For the interactive re-select the screen
    # swaps plaque INTERIORS (the rails+fill between the black borders, 122x21 at
    # plaque+(3,1)) and redraws labels. The selected interior is premier's red dither
    # with the yellow label tiled out from its own clean left strip (keeps dither
    # phase: strip x 16..39, width 24 — text starts at x 43, frame-measured); the
    # unselected interior is First Division's, text row-median-inpainted.
    # the yellow label (incl its dark outline) occupies rows 300..305 (abs) in the
    # text span x 43..128; replace those row segments WHOLESALE with clean rows of
    # matching glow brightness (all even offsets, keeping the dither phase):
    # the glow profile is 128,128,150,150,170,210,210,[text band],210?,170,170,150,128,128
    # (frame-measured: label pixels x 23..128, rows 297..308 incl cap-height/descenders)
    sel_int = f08[292:313, 16:138].copy()
    tx0, tx1 = 23 - 16, 129 - 16
    for dst in range(297, 309):
        sel_int[dst - 292, tx0:tx1] = sel_int[dst - 292 - 2, tx0:tx1]
    unsel_int = a[330:351, 16:138].copy()
    ui = unsel_int.copy()
    row_median_inpaint(ui, 0, 0, 122, 21, margin=10)
    unsel_int = ui
    save(sel_int, "seleccion/plaque_sel.png")
    save(unsel_int, "seleccion/plaque_unsel.png")

    save(a, "seleccion/chrome.png")

    # -- enabled CONTINUE overlay (frame 012; slot 1 filled). PM98 renders DISABLED
    # buttons WASHED toward the background (008 CONTINUE mean 136 vs enabled 39);
    # the chrome bakes the washed resting state, this overlay is the solid one.
    # The chip FURNITURE (bevel shadow) extends past the widget rect (diff proved
    # x506..622 y425..454), so cut x 506..622 / y 425..454 inclusive.
    save(f12[425:455, 506:623], "seleccion/continue_on.png")
    expect(
        f12[427:452, 508:620].astype(int).mean() < f08[427:452, 508:620].astype(int).mean() - 30,
        "012 CONTINUE solid (darker) vs 008 washed",
    )
    # -- enabled DELETE (for pretemp, whose 013 bake is the washed state; seleccion's
    # own DELETE is baked enabled — mean 26.9 in every seleccion frame); same +2 grow
    save(f08[425:455, 346:462], "pretemp/delete_on.png")

    return {
        "slot": {
            "y0": SLOT_Y0,
            "pitch": PITCH,
            "col_dx": COLX,
            "badge": [23, 44],
            "name": [45, 149],
            "club": [150, 308],
            "gold_bar": list(GOLD_BAR),
            "gold_name_bar": [212, 159, 0],
            "lav_bar": list(LAV_BAR),
            "name_bar": [140, 160, 180],
            "badge_fill": [128, 128, 128],
            "badge_digit": [192, 192, 192],
            "badge_active_fill": [85, 0, 0],
            "badge_active_digit": [255, 223, 0],
            "filled_badge_fill": [0, 0, 0],
            "filled_badge_digit": [255, 255, 255],
        },
        "panel": {
            "gold_rect": list(gold_rect),
            "white": list(white),
            "rule_color": list(rule_col),
            "title_color": list(title_col),
        },
    }


# ------------------------------------------------------------------------- pretemp

RIV_X, RIV_W, BADGE_W = 377, 228, 24
ROW_Y = (78, 136, 194, 252)


def build_pretemp() -> dict:
    f13 = load(F013)
    a = f13.copy()

    # rival slots: header y+0..14 (h15), bars y+17..30 and y+33..46 (h14),
    # badge x 605..629 y+0..48 (h49) — reversed + frame-measured.
    bx0, bx1 = RIV_X + RIV_W, RIV_X + RIV_W + BADGE_W

    # digit colours sampled BEFORE inpaint (digit is vertically centred in the
    # 49px badge -> probe rows y+16..y+34)
    def digit_sample(slot: int) -> tuple:
        y = ROW_Y[slot]
        reg = f13[y + 16 : y + 34, bx0 + 5 : bx1 - 4].astype(int).reshape(-1, 3)
        return tuple(int(v) for v in reg[reg.sum(axis=1).argmax()])

    on_digit = digit_sample(0)
    off_digit = digit_sample(1)
    # Chrome keeps the badges BAKED (the resting screen is slot-1-active with the
    # original digit rasters). For interactive redraws (active slot moves as rivals
    # fill), cut digit-free state textures from a COPY: digits occupy rows
    # y+16..y+33; replace them with the badge's own clean rows 14 above (even
    # offset preserves the dither phase of the washed badge).
    b = f13.copy()
    for i in range(4):
        y = ROW_Y[i]
        for dy in range(16, 34):
            b[y + dy, bx0 + 1 : bx1 - 1] = b[y + dy - 14, bx0 + 1 : bx1 - 1]
    save(b[ROW_Y[0] : ROW_Y[0] + 49, bx0:bx1], "pretemp/riv_badge_on.png")
    save(b[ROW_Y[1] : ROW_Y[1] + 49, bx0:bx1], "pretemp/riv_badge_off.png")
    save(f13[ROW_Y[0] : ROW_Y[0] + 15, RIV_X : RIV_X + RIV_W], "pretemp/riv_head_on.png")
    save(f13[ROW_Y[1] : ROW_Y[1] + 15, RIV_X : RIV_X + RIV_W], "pretemp/riv_head_off.png")
    save(f13[ROW_Y[0] + 17 : ROW_Y[0] + 31, RIV_X : RIV_X + RIV_W], "pretemp/riv_bar_on.png")
    save(f13[ROW_Y[1] + 17 : ROW_Y[1] + 31, RIV_X : RIV_X + RIV_W], "pretemp/riv_bar_off.png")

    # kit panel (8,336,321x130) stays BAKED (resting = ENGLAND + the Premier kits,
    # which is exactly what the screen's data draws). Interactive repaints (country/
    # division change) redraw white + title + kits with these samples.
    white = tuple(int(v) for v in f13[344, 20])
    expect(min(white) > 235, f"pretemp panel white sample {white}")
    title_probe = f13[340:356, 100:240].astype(int)
    tm = np.abs(title_probe - white).mean(axis=2) > 40
    title_col = (
        tuple(int(v) for v in np.median(title_probe[tm], axis=0)) if tm.any() else (0, 64, 192)
    )

    # division buttons stay BAKED (resting = PREMIER selected, original label
    # rasters). Cut a clean label-less chip (FIRST with its label inpainted) for
    # the interactive re-select redraw.
    chip = f13[370:395, 503:615].copy()
    ch = np.zeros((25, 112, 3), dtype=chip.dtype)
    ch[:] = chip
    row_median_inpaint(ch, 4, 4, 108, 21, margin=6)
    save(ch, "pretemp/div_chip.png")
    # PREMIER's selected style: find its red inner border row (reddish, low G/B)
    preg = f13[370:395, 383:495].astype(int)
    rm = (preg[:, :, 0] > 120) & (preg[:, :, 1] < 70) & (preg[:, :, 2] < 70)
    expect(rm.any(), "PREMIER red selection border present")
    ys_r, xs_r = np.where(rm)
    sel_border = tuple(int(v) for v in np.median(preg[rm], axis=0))
    sel_border_inset = [int(xs_r.min()), int(ys_r.min()), int(xs_r.max()), int(ys_r.max())]
    txt = preg[6:19, 20:92].reshape(-1, 3)
    sel_text = tuple(int(v) for v in txt[txt.sum(axis=1).argmax()])
    utxt = f13[376:390, 520:600].astype(int).reshape(-1, 3)
    unsel_text = tuple(int(v) for v in utxt[utxt.sum(axis=1).argmax()])

    # frame-rendered PANEL KIT patches: the original kit blit composes a soft
    # shadow that is NOT a plain palette blit (idx0 cells render dimmed greys; no
    # single-offset dim rule reproduces it) and whose dither phase depends on the
    # blit x-parity — so bake a patch PER SCREEN, per Premier club, straight from
    # each frame's own panel. All 20 cells SAD-0.0-verified against the NANOESC
    # art: seleccion (frame 008) x 167+31c y 308/345; preseason (frame 013)
    # x 13+floor(c*95/3) y 368/405. Non-Premier clubs fall back to the transparent
    # NANOESC art (shadowless — no frame shows their panels yet). 013's MANCHESTER
    # UTD cell is skipped: it renders WASHED there (the club was taken), so the
    # screen's nano+checker path handles it instead.
    dbj = json.loads((ROOT / "app" / "data" / "game_db.json").read_text(encoding="utf-8"))
    prem = sorted(
        [c for c in dbj["clubs"] if c.get("leagueId") == dbj["leagues"][0]["id"]],
        key=lambda c: c["name"],
    )
    expect(len(prem) == 20, f"premier club count {len(prem)}")
    f08_ref = load(F008)
    for sub, frame_px, xs, ys, skip in (
        ("panel", f08_ref, [167 + 31 * c for c in range(10)], (308, 345), ()),
        ("panel13", f13, [13 + (c * 95) // 3 for c in range(10)], (368, 405), ("MANCHESTER UTD.",)),
    ):
        d = ROOT / "app" / "art" / "kits" / sub
        d.mkdir(parents=True, exist_ok=True)
        for i, club in enumerate(prem):
            if club["name"] in skip:
                continue
            x = xs[i % 10]
            y = ys[0] if i < 10 else ys[1]
            Image.fromarray(frame_px[y : y + 32, x : x + 24].astype("uint8")).save(
                d / f"{club['id']}.png"
            )
    print("  app/art/kits/panel/ + panel13/  frame-rendered Premier kit patches")
    # the WASHED (taken-club) kit render, frame-proven only for MANCHESTER UTD.
    # (013's cell x108 y405 == 011's x260 y345 pixel-for-pixel — the wash is
    # position-independent at equal parity). Other clubs' washed cells fall back
    # to the screens' nano+checker approximation until a frame shows them.
    washed_dir = ROOT / "app" / "art" / "kits" / "washed"
    washed_dir.mkdir(parents=True, exist_ok=True)
    manu = next(c for c in prem if c["name"] == "MANCHESTER UTD.")
    Image.fromarray(f13[405:437, 108:132].astype("uint8")).save(washed_dir / f"{manu['id']}.png")
    print("  app/art/kits/washed/  frame-rendered washed kit (MANCHESTER UTD.)")

    # textless barra title band (for repainting "Preseason for <club>" with any
    # club): the barra gradient is horizontal per row, so row-median inpaint of the
    # white title text is exact. Cut x 110..560 y 12..48.
    band = f13[12:48, 110:560].copy()
    row_median_inpaint(band, 0, 0, 450, 36, margin=16, thresh=35)
    save(band, "pretemp/title_band.png")

    # tab styles for the SWITCHED states (resting EUROPE-active / SA-inactive is
    # baked; no walkthrough frame shows the S.AMERICA tab active — approximation
    # documented in pretemporada_screen_re.md)
    tab_red = tuple(int(v) for v in f13[130, 10])  # EUROPE active bar fill
    tab_grey_txt = tuple(
        int(v) for v in np.max(f13[200:290, 5:22].astype(int).reshape(-1, 3), axis=0)
    )

    save(a, "pretemp/chrome.png")
    return {
        "rival": {
            "x": RIV_X,
            "w": RIV_W,
            "badge_w": BADGE_W,
            "rows": list(ROW_Y),
            "digit_on": list(on_digit),
            "digit_off": list(off_digit),
        },
        "panel": {
            "interior": [10, 338, 327, 464],
            "white": list(white),
            "title_color": list(title_col),
        },
        "divbtn": {
            "sel_border": list(sel_border),
            "sel_border_inset": sel_border_inset,
            "sel_text": list(sel_text),
            "unsel_text": list(unsel_text),
        },
        "tab": {"active_fill": list(tab_red), "inactive_text": list(tab_grey_txt)},
    }


def _pyify(v):
    if isinstance(v, dict):
        return {k: _pyify(x) for k, x in v.items()}
    if isinstance(v, (list, tuple)):
        return [_pyify(x) for x in v]
    return int(v) if isinstance(v, np.integer) else v


def main() -> None:
    build_nivel()
    samples = _pyify({"seleccion": build_seleccion(), "pretemp": build_pretemp()})
    SPECS.mkdir(parents=True, exist_ok=True)
    out = SPECS / "entry_chrome_samples.json"
    out.write_text(json.dumps(samples, indent=1) + "\n")
    print(f"  {out.relative_to(ROOT)}")
    # ship the samples with the app too (screens read the colours from here)
    app_out = ROOT / "app" / "data" / "entry_chrome_samples.json"
    app_out.write_text(json.dumps(samples, indent=1) + "\n")
    print(f"  {app_out.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
