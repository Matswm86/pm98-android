#!/usr/bin/env python3
"""Bake the RESULTS screen chrome from the original walkthrough frame.

Binding frame: screenshots/original-walkthrough-2026-07-02/038_154452.png — the ONLY
RESULTS capture set (038-043 differ solely in the right-rail hover/press animations:
039 = Intercont glow tick, 040-042 = RETURN ball-roll, 043 = RETURN pressed). 038 is
the resting state and the sole pixel source here; every other RESULTS state is either
recomposed from 038/band.png cuts or an honest, documented approximation
(docs/re/results_screen_re.md).

Writes app/art/screens/results/:
  chrome.png          640x480 frame 038 with the 9 fixture rows and the MATCHES-ON
                      date inset cleared to their sampled plate colours (the baked
                      original pairings are the ORIGINAL game's fixture list, not the
                      app career's, so the scene always restamps rows from live data)
  hdr_names.png       band.png cut — textless manager/club plate interiors
  hdr_kit.png         band.png cut — empty header kit panel
  hdr_cal.png         band.png cut — textless calendar plaque
  hdr_status.png      band.png cut — textless status plaque
  title_patch.png     the white competition band interior, letters inpainted white
  title_caps.png      PROMAN18 A-Z0-9.'- glyph cells, PM98 fill rule (see below)
  date_digits.png     PROMAN14 0-9/ glyph cells: '1789/' cut EXACTLY from the frame
                      date "9/8/1997"; '023456' synthesized with the fitted fill rule
  arrow_left_off.png / arrow_right_on.png    real frame cuts (the two captured states)
  arrow_left_on.png / arrow_right_off.png    mirrors of the opposite captured plate
plus app/data/results_chrome_samples.json (glyph-cell metrics + sampled colours).

Fitted PM98 "gradient text" fill (single-witness, measured on 038):
  glyph interior       -> bright ink            (date (180,210,50), title (42,95,170))
  glyph 4-edge pixels  -> (x+y) odd  -> mid ink (date (160,190,40), title (75,109,172))
                          (x+y) even -> dim ink (date (127,159,85), title (42,95,170))
  1px 4-ring around    -> halo                  (date (20,20,60),  title (240,240,240))
Residual vs the captured witness is printed (and quoted in the RE doc); the exact-cut
'1789/' cells carry the true fill, so only never-captured digits use the model.

Also recomposes the frame-038 state (chrome + header redraw + row/date stamps) in
numpy and prints the pixel diff vs the raw frame — the build-time parity number.

Deterministic; every cut is asserted against sampled landmark colours so a moved
frame or a bad crop fails loudly instead of baking garbage.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
FRAME = ROOT / "screenshots/original-walkthrough-2026-07-02/038_154452.png"
BAND = ROOT / "app/art/screens/header/band.png"
FONTS = ROOT / "app/art/fonts"
OUT = ROOT / "app/art/screens/results"
SPEC = ROOT / "app/data/results_chrome_samples.json"

# ---- geometry (all measured on frame 038; see docs/re/results_screen_re.md) ----
ROW_Y0, ROW_PITCH, N_ROWS, ROW_H = 154, 23, 9, 22
KIT_HOME = (16, 44)      # x span of the home kit cell (exclusive end)
NAME_HOME = (45, 213)
SCORE_H = (214, 247)
SCORE_A = (249, 282)
NAME_AWAY = (283, 455)
KIT_AWAY = (456, 484)
BORDER_COLS = [14, 15, 44, 213, 247, 248, 282, 455, 484, 485]

C_ROW_BG = [(200, 220, 240), (160, 180, 200)]     # light / washed row plate
C_SCORE_BG = [(120, 140, 160), (100, 120, 140)]
C_KIT_BG = [(180, 200, 220), (140, 160, 180)]

DATE_CLEAR = (342, 128, 456, 151)   # x0,y0,x1,y1 (exclusive) — inset interior
DATE_STRIP = (443, 455)             # glyph-free interior columns (clean base witness)
DATE_CELL_Y, DATE_CELL_H = 129, 20
DATE_PEN0 = 352                     # "9/8/1997" pen origin (witness)
DATE_INKS = {"bright": (180, 210, 50), "mid": (160, 190, 40),
             "dim": (127, 159, 85), "halo": (20, 20, 60), "bg": (0, 0, 50)}

TITLE_PATCH = (104, 86, 422, 109)   # white band interior (right of the trophy)
TITLE_LINE_Y = 88                   # glyph bbox top of "PREMIER LEAGUE" (witness)
TITLE_S = 511                       # GDI centring span: px=(S-adv)/2 -> witness x=143
TITLE_INKS = {"bright": (42, 95, 170), "mid": (75, 109, 172),
              "dim": (42, 95, 170), "halo": (240, 240, 240), "bg": (255, 255, 255)}

ARROW_L = (308, 127, 27, 25)        # x,y,w,h — cut windows, symmetric margins around
ARROW_R = (459, 127, 27, 25)        # the 19x17 grid squares at (312,131)/(463,131)

HDR_CUTS = {                        # band.png -> textless header patches (x0,y0,x1,y1)
    "hdr_names": (2, 10, 107, 48),
    "hdr_kit": (106, 6, 141, 52),
    "hdr_cal": (448, 13, 521, 58),
    "hdr_status": (536, 10, 628, 50),
}


def die(msg: str) -> None:
    sys.exit(f"FATAL: {msg}")


def load_frame() -> np.ndarray:
    a = np.asarray(Image.open(FRAME).convert("RGB"))
    if a.shape[0] != 480 or a.shape[1] not in (640, 641):
        die(f"frame is {a.shape}, want 480x640/641")
    return a[:, :640].copy()


# ---- BMFont (the proven WINFONTS exports) ---------------------------------------
def load_bmfont(name: str):
    txt = (FONTS / f"{name}.fnt").read_text()
    chars = {}
    for m in re.finditer(
            r"char id=(\d+)\s+x=(\d+)\s+y=(\d+)\s+width=(\d+)\s+height=(\d+)"
            r"\s+xoffset=(-?\d+)\s+yoffset=(-?\d+)\s+xadvance=(\d+)", txt):
        cid, x, y, w, h, xo, yo, xa = map(int, m.groups())
        chars[chr(cid)] = (x, y, w, h, xo, yo, xa)
    atlas = np.asarray(Image.open(FONTS / f"{name}.png").convert("RGBA"))
    return chars, atlas


def raster_mask(s: str, chars, atlas):
    """1bpp line raster; canvas row 0 = line-box top (yoffset included)."""
    pen, parts = 0, []
    for ch in s:
        c = chars.get(ch)
        if c is None:
            die(f"glyph {ch!r} missing from font")
        x, y, w, h, xo, yo, xa = c
        parts.append((pen + xo, yo, atlas[y:y + h, x:x + w, 3] > 128))
        pen += xa
    W = max(p + g.shape[1] for p, _, g in parts)
    H = max(q + g.shape[0] for _, q, g in parts)
    img = np.zeros((H, W), bool)
    for p, q, g in parts:
        img[q:q + g.shape[0], p:p + g.shape[1]] |= g
    return img, pen


def fill_glyph(mask: np.ndarray, inks: dict, phase: int = 0) -> np.ndarray:
    """The fitted PM98 gradient-text fill (module docstring) -> RGBA.

    `phase` = parity of (absolute_x + absolute_y) at the raster's (0,0), so the
    checkered edge lands on the same screen-parity the original renderer used.
    """
    h, w = mask.shape
    pad = np.zeros((h + 2, w + 2), bool)
    pad[1:-1, 1:-1] = mask
    inner = (pad[1:-1, 1:-1] & pad[2:, 1:-1] & pad[:-2, 1:-1]
             & pad[1:-1, 2:] & pad[1:-1, :-2])
    ring = ((pad[2:, 1:-1] | pad[:-2, 1:-1] | pad[1:-1, 2:] | pad[1:-1, :-2])
            & ~pad[1:-1, 1:-1])
    out = np.zeros((h, w, 4), np.uint8)
    yy, xx = np.mgrid[0:h, 0:w]
    odd = (xx + yy + phase) % 2 == 1
    edge = mask & ~inner
    for m, col in [(ring, inks["halo"]), (edge & odd, inks["mid"]),
                   (edge & ~odd, inks["dim"]), (inner, inks["bright"])]:
        out[m, :3] = col
        out[m, 3] = 255
    return out


def main() -> None:
    fr = load_frame().astype(np.int16)
    band = np.asarray(Image.open(BAND).convert("RGB")).astype(np.int16)
    if band.shape != (62, 640, 3):
        die(f"band.png is {band.shape}, want 62x640")
    OUT.mkdir(parents=True, exist_ok=True)

    def mode_of(region: np.ndarray) -> tuple:
        flat = region.reshape(-1, 3)
        vals, counts = np.unique(flat, axis=0, return_counts=True)
        return tuple(int(v) for v in vals[counts.argmax()])

    # ---- landmark assertions -----------------------------------------------------
    for i in range(N_ROWS):
        y0 = ROW_Y0 + ROW_PITCH * i
        for xc in BORDER_COLS:
            if fr[y0 + 3:y0 + ROW_H - 3, xc].max() > 60:
                die(f"row {i}: border col x={xc} not black")
        if mode_of(fr[y0:y0 + ROW_H, slice(*NAME_HOME)]) != C_ROW_BG[i % 2]:
            die(f"row {i}: name-cell bg != {C_ROW_BG[i % 2]}")
        if mode_of(fr[y0:y0 + ROW_H, slice(*SCORE_H)]) != C_SCORE_BG[i % 2]:
            die(f"row {i}: score-cell bg != {C_SCORE_BG[i % 2]}")
        if mode_of(fr[y0:y0 + ROW_H, slice(*KIT_HOME)]) != C_KIT_BG[i % 2]:
            die(f"row {i}: kit-cell bg != {C_KIT_BG[i % 2]}")

    # the glyph-free right strip of the date inset proves the clean base texture;
    # each row is 2-periodic in x (the inset's dot dither), so the clear tiles it
    # with the ABSOLUTE-x parity preserved
    strip = fr[DATE_CLEAR[1]:DATE_CLEAR[3], DATE_STRIP[0]:DATE_STRIP[1]]
    for y in range(strip.shape[0]):
        row = strip[y]
        if not np.array_equal(row[:-2], row[2:]):
            die(f"date inset base row {y} is not 2-periodic")
    strip_pair = [(tuple(int(v) for v in strip[y, 0]),
                   tuple(int(v) for v in strip[y, 1])) for y in range(strip.shape[0])]

    # ---- chrome: clear rows + date inset ------------------------------------------
    chrome = fr.copy()
    for i in range(N_ROWS):
        y0 = ROW_Y0 + ROW_PITCH * i
        for span, col in [(KIT_HOME, C_KIT_BG[i % 2]), (NAME_HOME, C_ROW_BG[i % 2]),
                          (SCORE_H, C_SCORE_BG[i % 2]), (SCORE_A, C_SCORE_BG[i % 2]),
                          (NAME_AWAY, C_ROW_BG[i % 2]), (KIT_AWAY, C_KIT_BG[i % 2])]:
            chrome[y0:y0 + ROW_H, span[0]:span[1]] = col
    x0, y0, x1, y1 = DATE_CLEAR
    for y in range(y0, y1):                       # tile the 2-periodic base pattern
        pair = strip_pair[y - y0]
        for x in range(x0, x1):
            chrome[y, x] = pair[(x - DATE_STRIP[0]) % 2]
    Image.fromarray(chrome.astype(np.uint8)).save(OUT / "chrome.png")

    # ---- header patches from band.png ---------------------------------------------
    for name, (cx0, cy0, cx1, cy1) in HDR_CUTS.items():
        Image.fromarray(band[cy0:cy1, cx0:cx1].astype(np.uint8)).save(
            OUT / f"{name}.png")

    # ---- title band patch (letters inpainted) --------------------------------------
    tx0, ty0, tx1, ty1 = TITLE_PATCH
    tp = fr[ty0:ty1, tx0:tx1].copy()
    letters = np.abs(tp - np.array((255, 255, 255))).sum(axis=2) > 12
    tp[letters] = (255, 255, 255)
    if np.abs(tp - np.array((255, 255, 255))).sum() != 0:
        die("title patch not uniform white after inpaint")
    Image.fromarray(tp.astype(np.uint8)).save(OUT / "title_patch.png")

    # ---- glyph strips ---------------------------------------------------------------
    spec: dict = {"frame": FRAME.name,
                  "row_bg": C_ROW_BG, "score_bg": C_SCORE_BG, "kit_bg": C_KIT_BG}

    # DATE (PROMAN14 native 15px): exact cells for '9/8/1' + '7', model for the rest.
    ch14, at14 = load_bmfont("proman14")
    witness = "9/8/1997"
    wmask, _ = raster_mask(witness, ch14, at14)
    gy, gx = np.nonzero(wmask)
    y_line = 132 - gy.min()                       # abs line-box top of the witness
    date_y0 = DATE_CELL_Y
    if not (date_y0 <= y_line and y_line + wmask.shape[0] <= date_y0 + DATE_CELL_H):
        die("date witness line box escapes the cell rows")
    # per-character pen positions of every witness occurrence (the checkered fill is
    # phase-locked to screen parity, so a cell only restamps exactly at pens of the
    # SAME parity — bake one cell per (char, pen-parity))
    occ: dict = {}
    pen = DATE_PEN0
    for c in witness:
        occ.setdefault(c, {})[pen % 2] = pen
        pen += ch14[c][6]

    def date_model_cell(c: str, adv: int, parity: int) -> np.ndarray:
        m, _ = raster_mask(c, ch14, at14)
        g = fill_glyph(m, DATE_INKS, phase=(parity + y_line) % 2)
        cell = np.zeros((DATE_CELL_H, adv, 4), np.uint8)
        cell[..., :3] = DATE_INKS["bg"]
        cell[..., 3] = 255
        yoff = y_line - date_y0
        xo = ch14[c][4]
        gh, gw = g.shape[:2]
        if yoff + gh > DATE_CELL_H:
            die(f"date glyph {c!r} escapes its cell")
        sub = cell[yoff:yoff + gh, xo:min(xo + gw, adv)]
        gsub = g[:sub.shape[0], :sub.shape[1]]
        on = gsub[..., 3] > 0
        sub[on] = gsub[on]
        return cell

    cells = {}
    strip_imgs = []
    xcur = 0
    for c in "0123456789/":
        adv = ch14[c][6]
        cells[c] = {"adv": adv, "w": adv}
        for parity in (0, 1):
            if c in occ and parity in occ[c]:      # exact frame cut, its own columns
                px = occ[c][parity]
                cell = fr[date_y0:date_y0 + DATE_CELL_H, px:px + adv].astype(np.uint8)
                cell = np.dstack([cell, np.full(cell.shape[:2], 255, np.uint8)])
                src = "frame"
            elif c in occ:                         # captured in the other parity only
                px = next(iter(occ[c].values()))
                cell = fr[date_y0:date_y0 + DATE_CELL_H, px:px + adv].astype(np.uint8)
                cell = np.dstack([cell, np.full(cell.shape[:2], 255, np.uint8)])
                src = "frame-otherparity"
            else:                                  # fitted-model synthesis
                cell = date_model_cell(c, adv, parity)
                src = "model"
            cells[c][f"p{parity}"] = {"x": xcur, "src": src}
            strip_imgs.append(cell)
            xcur += adv
    date_strip = np.concatenate(strip_imgs, axis=1)
    Image.fromarray(date_strip).save(OUT / "date_digits.png")
    spec["date"] = {"y": date_y0, "h": DATE_CELL_H, "cx": 396, "cells": cells,
                    "clear": list(DATE_CLEAR)}

    # model residual vs the captured witness (quoted in the RE doc)
    resid, rtot = 0, 0
    for c, parities in occ.items():
        for parity, px in parities.items():
            mc = date_model_cell(c, ch14[c][6], parity)
            ref = fr[date_y0:date_y0 + DATE_CELL_H, px:px + mc.shape[1]]
            resid += int(np.count_nonzero(
                np.abs(ref - mc[..., :3].astype(np.int16)).sum(axis=2) > 12))
            rtot += mc.shape[0] * mc.shape[1]
    print(f"date fill-model residual vs witness cells: {resid} of {rtot} px")

    # TITLE (PROMAN18 native 19px): all-model cells (the premier title stays baked).
    ch18, at18 = load_bmfont("proman18")
    tmask, tadv = raster_mask("PREMIER LEAGUE", ch18, at18)
    tgy, _tgx = np.nonzero(tmask)
    title_y_line = TITLE_LINE_Y - tgy.min()
    tcells, timgs, xcur = {}, [], 0
    cell_h = ty1 - ty0
    for c in "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.'- ":
        x, y, w, h, xo, yo, xa = ch18.get(c, (0, 0, 0, 0, 0, 0, 6))
        cell = np.zeros((cell_h, max(xa, 1), 4), np.uint8)
        cell[..., :3] = TITLE_INKS["bg"]
        cell[..., 3] = 255
        if c.strip():
            m, _ = raster_mask(c, ch18, at18)
            g = fill_glyph(m, TITLE_INKS)
            yoff = title_y_line - ty0
            gh, gw = g.shape[:2]
            gw = min(gw, cell.shape[1] - min(xo, 0))
            sub = cell[yoff:yoff + gh, max(xo, 0):max(xo, 0) + gw]
            gsub = g[:sub.shape[0], :sub.shape[1]]
            on = gsub[..., 3] > 0
            sub[on] = gsub[on]
        tcells[c] = {"x": xcur, "w": cell.shape[1], "adv": xa}
        timgs.append(cell)
        xcur += cell.shape[1]
    Image.fromarray(np.concatenate(timgs, axis=1)).save(OUT / "title_caps.png")
    spec["title"] = {"y": ty0, "h": cell_h, "S": TITLE_S, "cells": tcells,
                     "patch_xy": [tx0, ty0]}

    # title model residual vs the captured "PREMIER LEAGUE"
    tg = fill_glyph(tmask, TITLE_INKS)
    ref = fr[title_y_line:title_y_line + tg.shape[0], 143 - _tgx.min():143 - _tgx.min() + tg.shape[1]]
    on = tg[..., 3] > 0
    tres = int(np.count_nonzero(
        np.abs(ref[on] - tg[..., :3][on].astype(np.int16)).sum(axis=1) > 12))
    print(f"title fill-model residual vs witness: {tres} of {int(on.sum())} px")

    # ---- arrow state sprites ---------------------------------------------------------
    for (x, y, w, h), grid, gcol in [(ARROW_L, (312, 131), (80, 80, 120)),
                                     (ARROW_R, (463, 131), (128, 128, 128))]:
        if tuple(int(v) for v in fr[grid[1], grid[0]]) != gcol:
            die(f"arrow grid landmark at {grid} != {gcol}")
    lx, ly, lw, lh = ARROW_L
    rx, ry, rw, rh = ARROW_R
    left = fr[ly:ly + lh, lx:lx + lw].astype(np.uint8)
    right = fr[ry:ry + rh, rx:rx + rw].astype(np.uint8)
    Image.fromarray(left).save(OUT / "arrow_left_off.png")
    Image.fromarray(right).save(OUT / "arrow_right_on.png")
    Image.fromarray(np.ascontiguousarray(right[:, ::-1])).save(OUT / "arrow_left_on.png")
    Image.fromarray(np.ascontiguousarray(left[:, ::-1])).save(OUT / "arrow_right_off.png")
    spec["arrows"] = {"left": list(ARROW_L), "right": list(ARROW_R)}

    SPEC.write_text(json.dumps(spec, indent=1))

    # ---- build-time parity: recompose the frame-038 state -----------------------------
    comp = chrome.copy()

    def paste_rgba(img: np.ndarray, x: int, y: int) -> None:
        h, w = img.shape[:2]
        on = img[..., 3] > 128
        comp[y:y + h, x:x + w][on] = img[..., :3][on]

    def paste_rgb(img: np.ndarray, x: int, y: int) -> None:
        comp[y:y + img.shape[0], x:x + img.shape[1]] = img

    def stamp_text(font, s, S, y, ink, size_native=True):
        chs, at = font
        m, adv = raster_mask(s, chs, at)
        px = (S - adv) // 2
        sub = comp[y:y + m.shape[0], px:px + m.shape[1]]
        sub[m[:sub.shape[0], :sub.shape[1]]] = ink

    ch8 = load_bmfont("proman8")
    ch12c = load_bmfont("calend12")
    for name, (cx0, cy0, _, _) in HDR_CUTS.items():
        paste_rgb(band[HDR_CUTS[name][1]:HDR_CUTS[name][3],
                       HDR_CUTS[name][0]:HDR_CUTS[name][2]], cx0, cy0)
    stamp_text(ch8, "MWM", 107, 17, (0, 0, 0))
    stamp_text(ch8, "Manchester Utd.", 108, 35, (255, 255, 255))
    mu = np.asarray(Image.open(ROOT / "app/art/kits/header/40.png").convert("RGBA"))
    paste_rgba(mu, 108, 8)
    for s, y, ink in [("Friday", 15, (0, 0, 0)), ("1", 26, (255, 0, 0)),
                      ("August", 35, (0, 0, 0)), ("1997", 46, (42, 95, 170))]:
        stamp_text(ch8, s, 968, y, ink)
    stamp_text(ch12c, "Preseason", 1163, 14, (0, 0, 0))
    stamp_text(ch12c, "Preparation", 1163, 32, (255, 255, 255))

    # rows: the original matchday-1 pairings (ids from app/data/game_db.json)
    pairs = [(68, 48), (38, 56), (53, 49), (39, 63), (43, 46), (57, 45),
             (44, 52), (54, 59), (51, 42)]
    db = json.loads((ROOT / "app/data/game_db.json").read_text())
    names = {int(c["id"]): c["name"] for c in db["clubs"]}
    ch10 = load_bmfont("proman10")
    inks = [(100, 120, 140), (120, 140, 160)]
    for i, (h_id, a_id) in enumerate(pairs):
        ry0 = ROW_Y0 + ROW_PITCH * i
        for cid, x in [(h_id, 21), (a_id, 461)]:
            kit = np.asarray(Image.open(
                ROOT / f"app/art/kits/ridi/{cid}.png").convert("RGBA"))
            paste_rgba(kit, x, ry0 + 1)
        for nm, right, x in [(names[h_id], True, 207), (names[a_id], False, 288)]:
            m, adv = raster_mask(nm, ch10[0], ch10[1])
            px = x - adv if right else x
            sub = comp[ry0 + 6:ry0 + 6 + m.shape[0], px:px + m.shape[1]]
            sub[m[:sub.shape[0], :sub.shape[1]]] = inks[i % 2]
    # date: parity-matched cells at the witness pens
    pen = DATE_PEN0
    for c in witness:
        cinfo = cells[c]
        cx = cinfo[f"p{pen % 2}"]["x"]
        cell = date_strip[:, cx:cx + cinfo["w"]]
        paste_rgba(cell, pen, date_y0)
        pen += cinfo["adv"]

    diff = np.abs(comp - fr).sum(axis=2) > 12
    zones = {"header y<62": diff[:62].sum(), "title band": diff[80:114, 60:430].sum(),
             "matches band": diff[120:154].sum(),
             "rows": diff[154:362, :486].sum(), "rest": 0}
    zones["rest"] = int(diff.sum() - sum(int(v) for v in zones.values()))
    print("recomposition parity vs frame 038 (px |d|>12):", int(diff.sum()), zones)
    dm = (diff * 255).astype(np.uint8)
    Image.fromarray(dm).save("/tmp/results_parity_mask.png")
    print("wrote", OUT, "and", SPEC)


if __name__ == "__main__":
    main()
