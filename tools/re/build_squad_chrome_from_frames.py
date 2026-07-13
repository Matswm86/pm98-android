#!/usr/bin/env python3
"""Bake the SQUAD MANAGEMENT (PLANTILLA) STATIC CHROME from the real game's own
walkthrough frame.

Binding frame: 077_154612.png (run 1, 15:46:12) — the hub PLAYERS click lands on
SQUAD MANAGEMENT (Man Utd, fresh career Fri 1 Aug 1997). Witnesses 079/081/084
(the FICHA card opens over this screen) and 082 (card dismissed, screen clean
again) confirm the chrome is static behind the modal.

Doctrine (RivalScreen / LineupScreen header-rollout precedent): the shared SILVER
header band (y0..61) is NOT baked here — SquadScreen paints it live via
PMChrome.draw_match_header (band.png + the manager/club plaque + crest + spiral
calendar sheet + the green Preseason/Preparation bands), the SAME header the
LINE-UP and VIEW RIVAL screens were validated 0px against. Only the SQUAD
MANAGEMENT *title sprite* is cut here (draw_match_header has no "squad" title
slot and PMChrome is out of edit scope), composited onto band.png so it blits
seamlessly over the live header.

The BODY chrome (y62..479) IS the frame verbatim: the blue-marble FONDO, the
white boxed table panel with its column-header row (N° KEEPERS AV MO LOAN WAGE
YEARS — the codes in their own value colours), the per-section scrollbar, and the
YOUTH TEAM + RETURN buttons. The PLAYER-ROW grid is CLEARED to the panel white so
SquadScreen redraws every row live from the Career roster (the row cells + the
real PROMAN fonts + the frame-sampled column colours). This mirrors the frame's
own per-cell boxes: grey-128 border, grey-240 fill, 16px pitch (the current
screen already drew these correctly — only the surrounding chrome was invented).

Outputs (app/art/screens/squad/):
  chrome.png       640x418 body (y62..479), player-row grid cleared to white,
                   scrollbar + column-header row + buttons kept verbatim.
  title_squad.png  the SQUAD MANAGEMENT title glyphs over band.png (seamless).
  tools/re/specs/squad_chrome_samples.json  sampled geometry + colours.

Every measured invariant is asserted so a bad crop / re-capture fails loudly.

Run from anywhere:  python3 tools/re/build_squad_chrome_from_frames.py
"""

from __future__ import annotations

import json
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
FRAMES = ROOT / "screenshots" / "original-walkthrough-2026-07-02"
if not FRAMES.exists():
    FRAMES = ROOT / "tools" / "re" / "refs" / "walkthrough-2026-07-02"
ART = ROOT / "app" / "art" / "screens" / "squad"
HDR = ROOT / "app" / "art" / "screens" / "header"
SPECS = Path(__file__).resolve().parent / "specs"

F = "077_154612.png"          # SQUAD MANAGEMENT, binding (run 1)
WITNESS_CLEAN = "082_154621.png"   # card dismissed: chrome clean again

BODY_Y0 = 62                  # header band height (draw_match_header owns y0..61)

# --- frame-measured geometry (all asserted below) ---------------------------
PANEL = (10, 74, 513, 466)    # white table panel x0,y0,x1,y1 (inclusive edges)
HDR_ROW = (74, 91)            # column-header row (codes baked; y band)
ROW0_Y = 92                   # first player-row band TOP border (grey 128)
ROW_PITCH = 16               # band pitch (14px band + 2px white gap)
CLEAR = (11, 92, 510, 466)    # player-row grid region cleared to white
SCROLL_X = (492, 509)         # per-section scrollbar column (kept verbatim)
YOUTH_BTN = (521, 357, 636, 382)   # baked button rect x0,y0,x1,y1
RETURN_BTN = (527, 436, 628, 465)

# cell x-spans (border scan) — the screen redraws rows into these
CELLS = {
    "no": (16, 46), "name": (46, 273), "av": (273, 298), "mo": (298, 323),
    "loan": (323, 359), "wage": (359, 429), "y1": (429, 454), "y2": (454, 479),
}
# frame-sampled inks
INKS = {
    "no": (0, 0, 128), "section": (0, 0, 190), "av": (212, 63, 0),
    "mo": (75, 109, 172), "loan": (100, 130, 10), "wage": (150, 0, 0),
    "years": (42, 63, 170), "expire_txt": (255, 31, 0),
    "expire_bg": (255, 255, 170), "cell_bg": (240, 240, 240),
    "cell_brd": (128, 128, 128), "panel_white": (255, 255, 255),
}
# title glyph cut (SQUAD MANAGEMENT — grey emboss between plaque and cal sheet)
TITLE_ZONE = (186, 16, 408, 44)    # x0,y0,x1,y1 search window


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


def px(a: np.ndarray, x: int, y: int) -> tuple:
    return tuple(int(v) for v in a[y, x])


def main() -> None:
    f = load(F)
    band = np.asarray(Image.open(HDR / "band.png").convert("RGB"))
    expect(band.shape == (62, 640, 3), f"band.png is 640x62 (got {band.shape})")

    # --- witness: 082 chrome identical to 077 outside the player rows + header
    # (the two frames differ only where the modal / row cursor state changed).
    clean = load(WITNESS_CLEAN)
    same = (f[BODY_Y0:466, 514:640] == clean[BODY_Y0:466, 514:640]).all()
    expect(same, "082 witness: right-margin marble + buttons identical to 077")

    # --- panel invariants ----------------------------------------------------
    x0, y0, x1, y1 = PANEL
    for (xx, yy) in [(x0 + 2, 120), (x1 - 2, 120), (250, y0 + 2), (250, y1 - 2)]:
        expect(px(f, xx, yy) == (255, 255, 255), f"panel white at ({xx},{yy})")
    expect(px(f, 250, y1 + 1)[0] < 40, "panel bottom black border")

    # --- column-header row: codes in their value colours ---------------------
    expect(px(f, 283, 83) == INKS["av"], "AV code red in header row")
    expect(px(f, 308, 83)[2] > 130 and px(f, 308, 83)[0] < 130, "MO code blue")
    expect(px(f, 30, 83) == INKS["no"] or px(f, 27, 83) == INKS["no"], "N code navy")

    # --- player-row band: grey-128 border, grey-240 fill, white gap ----------
    expect(px(f, 290, ROW0_Y) == INKS["cell_brd"], "row0 top border grey128")
    expect(px(f, 250, ROW0_Y + 3) == INKS["cell_bg"], "row0 fill grey240")
    expect(px(f, 250, ROW0_Y + 14) == (255, 255, 255), "2px white gap after band")
    # vertical cell separators at the measured x-boundaries
    for bx in (CELLS["av"][0], CELLS["mo"][0], CELLS["loan"][0],
               CELLS["wage"][0], CELLS["y1"][0], CELLS["y2"][0], CELLS["y2"][1]):
        col = f[ROW0_Y + 4, bx - 1:bx + 2].astype(int)
        got = (np.abs(col - 128) < 24).all(axis=1).any()
        expect(got, f"cell separator near x={bx}")
    # frame values present: AV red + WAGE dark-red + navy years on the Schmeichel row
    expect(px(f, 283, 99) == INKS["av"], "AV digit red")
    expect(px(f, 400, 104) == INKS["wage"], "WAGE digit dark-red")
    yrs = f[95:105, 430:479].reshape(-1, 3).astype(int)
    navy = yrs[(yrs[:, 2] > 90) & (yrs[:, 0] < 90) & (yrs[:, 1] < 90)]
    med = tuple(int(v) for v in np.median(navy, axis=0))
    expect(med == INKS["years"], f"YEARS navy {med}")
    # expiring yellow cell (Van der Gouw LEFT year)
    yl = f[110:122, 454:479]
    ym = (yl[:, :, 0] > 230) & (yl[:, :, 1] > 230) & (yl[:, :, 2] < 190) & (yl[:, :, 2] > 120)
    expect(ym.any(), "expiring yellow LEFT-year cell present")

    # --- buttons + scrollbar exist -------------------------------------------
    dark = (f[:, :, 0] < 60) & (f[:, :, 1] < 60) & (f[:, :, 2] < 90)
    for nm, (bx0, by0, bx1, by1) in [("YOUTH", YOUTH_BTN), ("RETURN", RETURN_BTN)]:
        expect(dark[by0:by1, bx0:bx1].mean() > 0.3, f"{nm} dark button body present")
    gold = (f[:, :, 0] > 200) & (f[:, :, 1] > 150) & (f[:, :, 2] < 120)
    expect(gold[YOUTH_BTN[1]:YOUTH_BTN[3], YOUTH_BTN[0]:YOUTH_BTN[2]].any(),
           "YOUTH TEAM gold text present")

    # ============================ TITLE SPRITE ================================
    # "SQUAD MANAGEMENT" as an OPAQUE strip whose background IS band.png — so it
    # blits seamlessly over the live draw_match_header band AND covers band.png's
    # own faint title GHOST (a cluster-majority residual of the sibling titles,
    # x254..344; a transparent sprite let it show through the letter gaps and
    # doubled the title). The ghost band-region is horizontally interpolated out,
    # then the frame's real grey-emboss glyphs are painted on top.
    tx0, ty0, tx1, ty1 = TITLE_ZONE
    strip = band[ty0:ty1, tx0:tx1].astype(np.float64).copy()   # bg == band.png
    # confirm + erase the band ghost (measured x254..344; interpolate x252..346)
    gz = band[23:34, 254:345].mean(axis=2)
    expect((gz > 188).sum() > 300, "band.png title ghost present (to be covered)")
    g0, g1 = 252 - tx0, 346 - tx0
    left = strip[:, g0 - 1][:, None, :]
    right = strip[:, g1][:, None, :]
    span = g1 - g0
    for i in range(span):
        t = (i + 1) / (span + 1)
        strip[:, g0 + i] = left[:, 0, :] * (1 - t) + right[:, 0, :] * t
    strip = strip.astype(np.uint8)
    # paint the frame's real glyphs (white body + dark emboss shadow)
    zone = f[ty0:ty1, tx0:tx1].astype(int)
    r, g, b = zone[:, :, 0], zone[:, :, 1], zone[:, :, 2]
    bright = zone.mean(axis=2)
    grey = (np.abs(r - g) < 26) & (np.abs(g - b) < 40)
    mask = (bright > 190) | ((bright < 78) & grey)          # white body OR dark shadow
    expect(mask.sum() > 1500, f"title glyph mask too small ({int(mask.sum())})")
    strip[mask] = f[ty0:ty1, tx0:tx1][mask]
    save(strip, "title_squad.png")
    title_anchor = [tx0, ty0]

    # ============================ BODY CHROME =================================
    body = f.copy()
    # clear the player-row grid to panel white (the screen redraws every row)
    cx0, cy0, cx1, cy1 = CLEAR
    body[cy0:cy1, cx0:cx1] = (255, 255, 255)
    # re-paste the per-section scrollbar verbatim over the cleared strip
    sx0, sx1 = SCROLL_X
    body[cy0:cy1, sx0:sx1] = f[cy0:cy1, sx0:sx1]
    save(body[BODY_Y0:480], "chrome.png")

    # ============================ SPECS =======================================
    spec = {
        "binding_frame": F, "witness_clean": WITNESS_CLEAN,
        "body_y0": BODY_Y0, "panel": list(PANEL), "hdr_row": list(HDR_ROW),
        "row0_y": ROW0_Y, "row_pitch": ROW_PITCH, "clear_rect": list(CLEAR),
        "scroll_x": list(SCROLL_X),
        "youth_btn": list(YOUTH_BTN), "return_btn": list(RETURN_BTN),
        "cells": {k: list(v) for k, v in CELLS.items()},
        "inks": {k: list(v) for k, v in INKS.items()},
        "title_anchor": title_anchor,
    }
    SPECS.mkdir(parents=True, exist_ok=True)
    out = SPECS / "squad_chrome_samples.json"
    out.write_text(json.dumps(spec, indent=1) + "\n")
    print(f"  {out.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
