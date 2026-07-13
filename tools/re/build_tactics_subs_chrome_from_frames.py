#!/usr/bin/env python3
"""Bake the TACTICS *sub-screen* chrome (PREDEF. TACTICS + TEAM TACTICS).

Two sub-screens hang off the TACTICS board (docs/re/tacticas_screen_re.md,
TacticsBoardScreen.gd — parity-locked, NOT touched here):

  1. PREDEF. TACTICS — the 10-formation picker (FUN_0056f4c0). **FRAME-TRUE**:
     the picker IS walked in run-1, so its whole static modal is cut verbatim
     from the frame, exactly like every other chrome bake in this repo.
       binding  140_154820  Man Utd board, picker open, NO selection (resting)
       witness  142_154825  the "3-5-2" cell selected (blue-grey bevel + white
                            text) — proves the dynamic selection layer
     Names/grid order (5x2) match the source table DAT_00660240 / Tactics.
     FORMATION_ORDER exactly: 3-4-3 3-5-2 4-3-3 4-4-2 5-3-2 / 5-4-1 4-2-4
     5-2-3 4-5-1 3-3-3-1.

  2. TEAM TACTICS — the ATTACK|DEFENCE modal (FUN_0056ea15, board button
     equipo.bmp). **UN-WALKED**: it appears in NO walkthrough frame (run-1/2/3
     scanned; APP_VS_SPEC_AUDIT B6 lists PREDEFINED + MAN-TO-MAN but never a
     team-tactics/attack-defence modal) and FUN_0056ea15 is not disassembled.
     So it CANNOT be frame-baked. What IS source-true is its ART: RECURSOS holds
     the complete EQWIN* ("EQuipo WINdow") cluster + the modal's exact label set
     lives contiguously in MANAGER.EXE at 0x25ff3c..0x260014:
       TEAM TACTICS / ATTACK / DEFENCE
       ATTACKING PLAY / SPECULATIVE PLAY / MIXED PLAY  (mentality, EQWINAZUL1-3)
       PASSING <-> LONG BALL   (EQWINTOQUE / EQWINLARGO slider ends)
       COUNTER ATTACK
       TACKLING  SOFT / MEDIUM / AGGRESSIVE   (EQWINDIB1, 3 shoe icons)
       MARKING   ZONAL / MAN TO MAN           (EQWINDIB2, 1-vs-2 player icons)
       CLEARANCES SHORT / LONG                (EQWINDIB3)
       PRESSURISE FROM... OWN / MIDFIELD / OPPONENT (EQWINDIB4, 3 pitch zones)
     This bake DECODES those pieces verbatim (SAD-0 palette). TeamTacticsScreen
     composes them; the piece ART is source-exact, but the assembled window
     GEOMETRY is a documented reconstruction (NOT MEASURED — no frame binds it).
     The strip->control assignment is inferred from icon semantics (documented).

Outputs (app/art/screens/tactics/):
  predef_chrome.png     the whole PREDEF modal, frame-cut from 140 (resting)
  eqwin_attack.png      EQWINATAQUE 198x47   ATTACK header (blue)
  eqwin_defence.png     EQWINDEFENSA 198x47  DEFENCE header (orange)
  eqwin_row_tackle.png  EQWINDIB1 192x17     TACKLING row (3 shoe icons+boxes)
  eqwin_row_marking.png EQWINDIB2 156x17     MARKING row (1/2 player icons+boxes)
  eqwin_row_clear.png   EQWINDIB3 156x16     CLEARANCES row
  eqwin_row_press.png   EQWINDIB4 188x17     PRESSURISE row (3 pitch zones)
  eqwin_ment{1,2,3}.png EQWINAZUL1-3 45x18   mentality option tiles (blue)
  eqwin_pass_short.png  EQWINTOQUE 41x21     PASSING (touch) slider end
  eqwin_pass_long.png   EQWINLARGO 41x21     LONG BALL slider end
  eqwin_peak.png        EQWINPICOS 18x18     slider peak marker
  eqwin_step.png        EQWINBOTON 20x17     +/- stepper button
  eqwin_close.png       EQWINX 9x7           window close X
  eqwin_arrow.png       EQWINFLECHA1 6x11    slider pointer
  equipo_icon.png       EQUIPO 26x15         the board's TEAM TACTICS button icon
  predefwin_campo.png   PREDEFWINCAMPO 80x75 the picker thumbnail pitch
  predefwin_jug.png     PREDEFWINJUG 8x7     outfield dot
  predefwin_por.png     PREDEFWINPOR 8x7     keeper dot
  tools/re/specs/tactics_subs_chrome_samples.json (mirrored to app/data/)

Run from anywhere:  python3 tools/re/build_tactics_subs_chrome_from_frames.py
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
if not FRAMES.exists():
    FRAMES = ROOT / "tools" / "re" / "refs" / "walkthrough-2026-07-02"
ART = ROOT / "app" / "art" / "screens" / "tactics"
SPECS = Path(__file__).resolve().parent / "specs"
RECURSOS = ROOT / "extracted" / "Premier Manager 98" / "RECURSOS.PKF"

F_PRED = "140_154820.png"  # picker open, resting (no selection)
F_SEL = "142_154825.png"  # "3-5-2" selected — the dynamic layer witness

# PREDEF grid (frame-measured, 640x480). Columns step 80px; row-0 labels sit
# ABOVE the thumbnails, row-1 labels BELOW them.
COL_CX = [167, 247, 327, 407, 487]
THUMB_ROW_Y = [213, 297]  # thumbnail top per grid row
LABEL_ROW_Y = [195, 354]  # label band top per grid row (row0 above, row1 below)
LABEL_H = 13
NAMES = ["3-4-3", "3-5-2", "4-3-3", "4-4-2", "5-3-2", "5-4-1", "4-2-4", "5-2-3", "4-5-1", "3-3-3-1"]


def load_frame(name: str) -> np.ndarray:
    a = np.asarray(Image.open(FRAMES / name).convert("RGB"))
    if a.shape[0] != 480 or a.shape[1] not in (640, 641):
        raise SystemExit(f"{name}: unexpected size {a.shape}")
    return a[:, :640].astype(int)


def expect(cond: bool, what: str) -> None:
    if not cond:
        raise SystemExit(f"invariant FAILED: {what}")


def save(a: np.ndarray, p: Path) -> None:
    p.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(a.astype("uint8")).save(p)
    print(f"  {p.relative_to(ROOT)}  {a.shape[1]}x{a.shape[0]}")


def save_im(im: Image.Image, p: Path) -> None:
    p.parent.mkdir(parents=True, exist_ok=True)
    im.save(p)
    print(f"  {p.relative_to(ROOT)}  {im.size[0]}x{im.size[1]}")


def detect_predef_modal(a: np.ndarray) -> tuple[int, int, int, int]:
    """Tight modal rect (x0,y0,x1,y1 exclusive). Anchor on the unambiguous maroon
    title bar (x-extent + top), then walk the bright silver body down to where it
    gives way to the dark dimmed board."""
    red = (a[:, :, 0] > 110) & (a[:, :, 1] < 75) & (a[:, :, 2] < 75)
    trows = np.where(red[150:200].sum(axis=1) > 150)[0]
    expect(trows.size >= 8, "PREDEF maroon title bar not located")
    ty0 = 150 + int(trows.min())
    ty1 = 150 + int(trows.max())
    tcols = np.where(red[ty0 : ty1 + 1].sum(axis=0) > (ty1 - ty0) // 2)[0]
    x0 = int(tcols.min())
    x1 = int(tcols.max()) + 1
    y0 = ty0 - 2  # thin bevel above the maroon
    # bright silver body fraction, per row, inside the modal width
    bright = (
        (a[:, :, 0] > 150)
        & (a[:, :, 1] > 150)
        & (a[:, :, 2] > 155)
        & (np.abs(a[:, :, 0] - a[:, :, 1]) < 30)
    )
    frac = bright[:, x0 + 8 : x1 - 8].mean(axis=1)
    y1 = ty1
    for y in range(ty1 + 1, 430):
        if frac[y] > 0.30:
            y1 = y
    return x0, y0, x1, y1 + 2


def main() -> None:
    ART.mkdir(parents=True, exist_ok=True)
    samples: dict = {}

    # ================= 1. PREDEF picker (FRAME-TRUE) =====================
    a = load_frame(F_PRED)
    b = load_frame(F_SEL)

    x0, y0, x1, y1 = detect_predef_modal(a)
    print(f"PREDEF modal detected rect: ({x0},{y0})..({x1},{y1})  {x1 - x0}x{y1 - y0}")
    # geometry sanity vs the disasm body size (0x1c3 x 0xfa = 451x250) and the
    # frame measurements (maroon title y160..180; 5x2 green grid).
    expect(440 <= x1 - x0 <= 460, f"PREDEF modal width {x1 - x0} not ~451")
    expect(235 <= y1 - y0 <= 255, f"PREDEF modal height {y1 - y0} not ~250")
    # maroon title bar present near the top of the modal
    red = (a[:, :, 0] > 110) & (a[:, :, 1] < 75) & (a[:, :, 2] < 75)
    title_rows = np.where(red[y0 : y0 + 30, x0:x1].sum(axis=1) > 100)[0]
    expect(title_rows.size >= 8, "PREDEF maroon title bar not found at modal top")
    # white "PREDEFINED TACTICS" glyphs live on the maroon
    tband = a[y0 + int(title_rows.min()) : y0 + int(title_rows.max()) + 1, x0:x1]
    white = (tband[:, :, 0] > 200) & (tband[:, :, 1] > 200) & (tband[:, :, 2] > 200)
    expect(int(white.sum()) > 150, "PREDEF title text glyphs not found")
    # ten green thumbnail pitches present at the grid cells
    grn = (a[:, :, 1] > 90) & (a[:, :, 1] > a[:, :, 0] + 15) & (a[:, :, 1] > a[:, :, 2] + 15)
    for gi, ty in enumerate(THUMB_ROW_Y):
        for cx in COL_CX:
            cell = grn[ty : ty + 45, cx - 28 : cx + 28]
            expect(int(cell.sum()) > 300, f"PREDEF thumbnail missing row{gi} cx{cx}")

    # the modal is cut verbatim -> chrome (the screen draws its own dim backdrop
    # and the dynamic selection layer on top).
    modal = a[y0:y1, x0:x1].copy()
    save(modal, ART / "predef_chrome.png")

    # dynamic selection witness: 142 - 140 differs ONLY over the "3-5-2" label
    # (row0, col1), where the resting black text becomes a blue-grey bevel box
    # with WHITE text. Record the rule + the box colour.
    d = np.abs(a - b).sum(axis=2)
    yy, xx = np.where(d > 50)
    sel_bbox = (int(xx.min()), int(yy.min()), int(xx.max()) + 1, int(yy.max()) + 1)
    # it must sit on the 3-5-2 column/row
    expect(
        COL_CX[1] - 45 < (sel_bbox[0] + sel_bbox[2]) / 2 < COL_CX[1] + 45,
        f"selection witness not over the 3-5-2 column ({sel_bbox})",
    )
    expect(
        LABEL_ROW_Y[0] - 6 < sel_bbox[1] < LABEL_ROW_Y[0] + 10,
        f"selection witness not on the row-0 label band ({sel_bbox})",
    )
    # selected (142): WHITE glyph text on a blue-grey bevel box.
    # resting  (140): BLACK glyph text on the silver body, no blue-grey box.
    sel_a = a[sel_bbox[1] : sel_bbox[3], sel_bbox[0] : sel_bbox[2]].reshape(-1, 3)
    sel_b = b[sel_bbox[1] : sel_bbox[3], sel_bbox[0] : sel_bbox[2]].reshape(-1, 3)
    white_b = ((sel_b > 200).all(axis=1)).sum()
    black_a = ((sel_a < 60).all(axis=1)).sum()
    expect(white_b > 20, f"selection witness: no white text in 142 ({white_b})")
    expect(black_a > 20, f"selection witness: no black text in 140 ({black_a})")
    # dominant bevel fill of the selection box (in 142, off the white glyphs)
    fillpx = sel_b[(sel_b < 200).any(axis=1)]
    vals, counts = np.unique(fillpx, axis=0, return_counts=True)
    sel_fill = [int(v) for v in vals[counts.argmax()]]
    expect(
        sel_fill[2] > sel_fill[0] and sel_fill[2] > sel_fill[1],
        f"selection fill not blue-ish ({sel_fill})",
    )
    print(f"PREDEF selection fill (frame 142): {sel_fill}  bbox {sel_bbox}")

    # PREDEF sample geometry, expressed in the CHROME's own space (origin x0,y0).
    def rel(rx: int, ry: int, w: int, h: int) -> list[int]:
        return [rx - x0, ry - y0, w, h]

    cells = []
    for k, nm in enumerate(NAMES):
        gi = 0 if k < 5 else 1
        cx = COL_CX[k % 5]
        thumb_y = THUMB_ROW_Y[gi]
        label_y = LABEL_ROW_Y[gi]
        # hit cell spans the label + the thumbnail (a comfortable 80x88 box)
        top = min(label_y, thumb_y) - 2
        bot = max(label_y + LABEL_H, thumb_y + 50) + 2
        cells.append(
            {
                "name": nm,
                "cell": rel(cx - 40, top, 80, bot - top),
                "label": rel(cx - 40, label_y - 1, 80, LABEL_H + 2),
            }
        )

    # CANCEL button: the dark bevelled button under the grid (frame-measured).
    cancel = rel(272, 378, 113, 24)

    samples["predef"] = {
        "modal_rect": [x0, y0, x1 - x0, y1 - y0],
        "chrome_size": [x1 - x0, y1 - y0],
        "col_cx": [c - x0 for c in COL_CX],
        "thumb_row_y": [t - y0 for t in THUMB_ROW_Y],
        "label_row_y": [t - y0 for t in LABEL_ROW_Y],
        "label_h": LABEL_H,
        "cells": cells,
        "cancel": cancel,
        "sel_fill": sel_fill,
        "sel_text": [255, 255, 255],
        "sel_witness_bbox": [
            sel_bbox[0] - x0,
            sel_bbox[1] - y0,
            sel_bbox[2] - sel_bbox[0],
            sel_bbox[3] - sel_bbox[1],
        ],
        "names": NAMES,
    }

    # ================= 2. TEAM TACTICS art (SOURCE-TRUE, un-walked) ======
    buf = RECURSOS.read_bytes()
    pal = ea.riff_palette("MANAGER.PAL")
    names = list(pk.files_of(buf))
    # the EQWIN cluster + predefwin pieces live contiguously past offset ~5.8M
    # (there are same-named decoys earlier in the archive — pick the cluster copy)
    want = {
        "EQWINATAQUE.BMP": ("eqwin_attack.png", (198, 47)),
        "EQWINDEFENSA.BMP": ("eqwin_defence.png", (198, 47)),
        "EQWINDIB1.BMP": ("eqwin_row_tackle.png", (192, 17)),
        "EQWINDIB2.BMP": ("eqwin_row_marking.png", (156, 17)),
        "EQWINDIB3.BMP": ("eqwin_row_clear.png", (156, 16)),
        "EQWINDIB4.BMP": ("eqwin_row_press.png", (188, 17)),
        "EQWINAZUL1.BMP": ("eqwin_ment1.png", (45, 18)),
        "EQWINAZUL2.BMP": ("eqwin_ment2.png", (45, 18)),
        "EQWINAZUL3.BMP": ("eqwin_ment3.png", (44, 18)),
        "EQWINTOQUE.BMP": ("eqwin_pass_short.png", (41, 21)),
        "EQWINLARGO.BMP": ("eqwin_pass_long.png", (41, 21)),
        "EQWINPICOS.BMP": ("eqwin_peak.png", (18, 18)),
        "EQWINBOTON.BMP": ("eqwin_step.png", (20, 17)),
        "EQWINX.BMP": ("eqwin_close.png", (9, 7)),
        "EQWINFLECHA1.BMP": ("eqwin_arrow.png", (6, 11)),
        "EQUIPO.BMP": ("equipo_icon.png", (26, 15)),
        "PREDEFWINCAMPO.BMP": ("predefwin_campo.png", (80, 75)),
        "PREDEFWINJUG.BMP": ("predefwin_jug.png", (8, 7)),
        "PREDEFWINPOR.BMP": ("predefwin_por.png", (8, 7)),
    }
    got: dict = {}
    for n, o, s in names:
        u = str(n).upper()
        if u in want and o > 5_800_000 and u not in got:
            im = ei.decode_dib(buf[o : o + s], pal)
            out_name, exp_size = want[u]
            expect(im.size == exp_size, f"{u}: decoded {im.size} != {exp_size}")
            save_im(im, ART / out_name)
            got[u] = im.size
    missing = set(want) - set(got)
    expect(not missing, f"RECURSOS EQWIN/PREDEFWIN pieces missing: {missing}")

    # Each option strip carries its own baked EMPTY checkboxes (white square,
    # dark border) to the RIGHT of each option icon; TeamTacticsScreen paints a
    # tick into the SELECTED option's box. Centres measured off the decoded art
    # (source-true) and self-verified below (each centre must be near-white).
    boxes = {  # strip file -> [checkbox centre x within the strip]
        "eqwin_row_tackle.png": [31, 100, 180],  # SOFT / MEDIUM / AGGRESSIVE
        "eqwin_row_marking.png": [35, 145],  # ZONAL / MAN TO MAN
        "eqwin_row_clear.png": [31, 143],  # SHORT / LONG
        "eqwin_row_press.png": [34, 105, 177],  # OWN / MIDFIELD / OPPONENT
    }
    ment_box_cx = 34  # checkbox centre within each 45px EQWINAZUL mentality tile
    for fn, cxs in boxes.items():
        im = Image.open(ART / fn).convert("RGB")
        arr = np.asarray(im).astype(int)
        for cx in cxs:
            px = arr[im.size[1] // 2, cx]
            expect((px > 200).all(), f"{fn} checkbox centre x{cx} not white ({tuple(px)})")
    for i in (1, 2, 3):
        im = Image.open(ART / f"eqwin_ment{i}.png").convert("RGB")
        arr = np.asarray(im).astype(int)
        px = arr[im.size[1] // 2, ment_box_cx]
        expect((px > 200).all(), f"eqwin_ment{i} checkbox centre not white ({tuple(px)})")

    samples["team_tactics"] = {
        "SOURCE_NOTE": "UN-WALKED modal (no walkthrough frame; FUN_0056ea15 not "
        "disassembled). Piece ART is source-exact (RECURSOS EQWIN "
        "cluster); the assembled window GEOMETRY is a documented "
        "reconstruction, NOT frame-verified.",
        "labels_va": {
            "TEAM TACTICS": "0x25faa4",
            "ATTACK": "0x26000c",
            "DEFENCE": "0x260004",
            "ATTACKING PLAY": "0x25fff4",
            "SPECULATIVE PLAY": "0x25ffe0",
            "MIXED PLAY": "0x25ffd4",
            "PASSING": "0x25ffcc",
            "LONG BALL": "0x25ffc0",
            "COUNTER ATTACK": "0x260014",
            "TACKLING": "0x25ffb4",
            "SOFT": "0x25ff84",
            "MEDIUM": "0x25ff7c",
            "AGGRESSIVE": "0x25ff70",
            "MARKING": "0x25ffac",
            "ZONAL": "0x25ff68",
            "MAN TO MAN": "0x25ff5c",
            "CLEARANCES": "0x25ffa0",
            "SHORT": "0x25ff54",
            "LONG": "0x25ff4c",
            "PRESSURISE FROM...": "0x25ff8c",
            "OWN": "0x25ff48",
            "MIDFIELD": "0x25ff3c",
            "OPPONENT": "0x25c5a0",
        },
        "art": {k: list(v) for k, v in got.items()},
        "row_map_inferred": {
            "eqwin_row_tackle.png": "TACKLING (SOFT/MEDIUM/AGGRESSIVE) - 3 shoe icons",
            "eqwin_row_marking.png": "MARKING (ZONAL/MAN TO MAN) - 1-vs-2 player icons",
            "eqwin_row_clear.png": "CLEARANCES (SHORT/LONG)",
            "eqwin_row_press.png": "PRESSURISE FROM... (OWN/MIDFIELD/OPPONENT) - 3 zones",
            "eqwin_ment{1,2,3}.png": "mentality ATTACKING/SPECULATIVE/MIXED - blue tiles",
        },
        "checkbox_cx": {
            "eqwin_row_tackle.png": boxes["eqwin_row_tackle.png"],
            "eqwin_row_marking.png": boxes["eqwin_row_marking.png"],
            "eqwin_row_clear.png": boxes["eqwin_row_clear.png"],
            "eqwin_row_press.png": boxes["eqwin_row_press.png"],
            "mentality_tile": ment_box_cx,
        },
    }

    SPECS.mkdir(parents=True, exist_ok=True)
    out = SPECS / "tactics_subs_chrome_samples.json"
    out.write_text(json.dumps(samples, indent=1) + "\n")
    print(f"  {out.relative_to(ROOT)}")
    app_out = ROOT / "app" / "data" / "tactics_subs_chrome_samples.json"
    app_out.write_text(json.dumps(samples, indent=1) + "\n")
    print(f"  {app_out.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
