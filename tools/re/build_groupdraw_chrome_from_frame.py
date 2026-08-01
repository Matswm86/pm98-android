#!/usr/bin/env python3
"""Bake the SORTEO screen's THIRD panel form -- the EUROPEAN CUP **GROUP DRAW** -- from
the real game's own frame.

Binding frame (banked s87, driven under Wine from a Manchester Utd. career):

  tools/re/refs/cupdraw-rounds-2026-08-01/manutd_s1_eurocup_groups_1_8_final.png
      European Cup, round plate `1/8 FINAL`, the draw MID-REVEAL: GROUP A carries its
      four clubs and groups B..F are still empty. The bottom-left tie card is entirely
      blank, leg plates included.

That single frame is enough because the widget repeats six times and five of the six are
EMPTY: measured here, the five empty boxes' ROW BANDS are pixel-identical to each other
(0 differing px), and their headers differ from each other only in the letter glyph. So
group C's row band IS the empty-row widget, verbatim, and it is what group A's populated
band is cleared with.

Doctrine (docs/re/SPEC_BINDING.md): the chrome layer IS the original frame with ONLY the
state-dependent pixels cleared. Cleared here, and why (all frame-absolute):

  picture window (31,76) 260x144   the competition strip + drum backdrop + drum frame,
                                   redrawn from the game's own art by the scene
  title plate    (44,34)-(288,58)   "EUROPEAN CUP" (proman14, white, centred)
  ROUND plate    (44,232)-(288,254) "1/8 FINAL"    (proman14, (255,223,0), centred)
  GROUPS plate   (334,23)-(622,49)  the word GROUPS (proman12, BLACK on flat white)
  box headers    the `<letter>` cell at box-local (117,4), six of them
  group A rows   (328,75)-(473,174) <- group C's own row band, verbatim

NOT cleared, and that is a finding: the two LEG PLATES bottom-left are BLANK on this
frame. The list/grid chromes had to recover those pixels by union because every witnessed
frame of those forms inks them; this frame witnesses the bare plate directly.

Outputs:
  app/art/screens/cupdraw/chrome_groups.png        the 640x480 screen, dynamics cleared
  tools/re/specs/cupdraw_groups_samples.json       geometry + colours, for the scene

Run: python3 tools/re/build_groupdraw_chrome_from_frame.py
"""

from __future__ import annotations

import json
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
FRAME = ROOT / "tools/re/refs/cupdraw-rounds-2026-08-01/manutd_s1_eurocup_groups_1_8_final.png"
OUT = ROOT / "app" / "art" / "screens" / "cupdraw"
SPEC = ROOT / "tools" / "re" / "specs" / "cupdraw_groups_samples.json"

# ---- geometry, every number measured off the frame (tools/re/probe_groupdraw_frame.py)
PICTURE = (31, 76, 260, 144)  # cleared to black; the scene redraws strip+drum
TITLE_SPAN = (44, 34, 288, 58)
ROUND_SPAN = (44, 232, 288, 254)

# The GROUPS header plate: black border rows y21-22 / y49-50, flat white interior.
PLATE_WHITE = (334, 23, 622, 49)  # x0, y0, x1, y1 (exclusive)
PLATE_SUM = 955  # proman12 pen = (955 - advance) / 2 -> 441 for "GROUPS"
PLATE_TOP = 30  # pen top
C_PLATE_INK = (0, 0, 0)

# Six group boxes, 2 columns x 3 rows. Each box is 149x121 with a 2-px black border.
BOX_X = (326, 483)
BOX_Y = (55, 180, 305)
BOX_W, BOX_H = 149, 121
# Box-local: interior starts at +2. Header band rows 2..17, then a 2-px rule, then four
# 24-px rows on a 25-px pitch.
HDR_TEXT = (26, 4)  # box-local pen of the word "GROUP"  (proman12)
HDR_LETTER = (117, 4)  # box-local pen of the group letter  (proman12)
C_HDR_TEXT = (100, 130, 10)
C_HDR_LETTER = (255, 255, 255)
ROW_Y0 = 20  # box-local y of row 0
ROW_PITCH = 25
ROW_H = 24
ROWS = 4
KIT_CELL = (2, 28)  # box-local x span of the kit cell; local 28 is a black rule
KIT_AT = (7, 2)  # box-local x, row-local y of the 17x20 RIDIESC kit
NAME_SUM = 177  # box-local: pen = box_x + (177 - advance) / 2, integer-truncated
NAME_TOP = 1  # pen top inside the row band
# The MINIBAND flag, and a measurement that is NOT explained and is not invented away:
# this screen blits the sprite's rows 1..9 ONLY. Its row 0 lands nowhere -- at (406, row+13)
# the frame carries flat row background across all fourteen columns, on all four rows of
# group A, while rows 1..9 sit at (406, row+14) and reproduce the port's own mini_%03d art
# to within the un-reversed 1-px edge pass (8..11 px of 140). Recorded as measured.
FLAG_AT = (80, 14)  # box-local x, row-local y of the flag's ROW 1
FLAG_SRC_ROW0 = 1  # the first sprite row this screen draws
FLAG_ROWS = 9
# Row bands alternate exactly as the GRID form's do, and the ink follows the band.
C_ROW_BG = [(200, 220, 240), (160, 180, 200)]
C_ROW_INK = [(100, 120, 140), (60, 80, 100)]
C_KIT_BG = (100, 120, 140)


def load() -> np.ndarray:
    return np.array(Image.open(FRAME).convert("RGB"))[:, :640]


def expect(cond: bool, what: str) -> None:
    if not cond:
        raise SystemExit(f"ASSERT FAILED: {what}")


def box(a: np.ndarray, col: int, row: int) -> np.ndarray:
    return a[BOX_Y[row] : BOX_Y[row] + BOX_H, BOX_X[col] : BOX_X[col] + BOX_W]


def main() -> None:
    a = load()
    expect(a.shape[:2] == (480, 640), f"frame is 640x480, got {a.shape}")

    # ---- 1. the frame's own invariants, asserted before anything is cleared -----
    boxes = [(c, r) for r in range(3) for c in range(2)]
    empty = [(c, r) for (c, r) in boxes if (c, r) != (0, 0)]
    ref = box(a, *empty[0])
    for c, r in empty[1:]:
        d = (box(a, c, r) != ref).any(axis=2)
        expect(
            d[ROW_Y0:].sum() == 0, f"empty box ({c},{r}) row band differs by {d[ROW_Y0:].sum()} px"
        )
    dA = (box(a, 0, 0) != ref).any(axis=2)
    expect(dA[ROW_Y0:].sum() > 0, "group A's row band is populated")
    print(f"five empty boxes agree on the row band at 0 px; group A differs by {dA[ROW_Y0:].sum()}")

    # the four row bands alternate two backgrounds, and the kit cell is one flat tone
    for k in range(ROWS):
        y = ROW_Y0 + k * ROW_PITCH
        band = ref[y : y + ROW_H, KIT_CELL[1] : BOX_W - 2]
        vals, counts = np.unique(band.reshape(-1, 3), axis=0, return_counts=True)
        got = tuple(int(v) for v in vals[counts.argmax()])
        expect(got == C_ROW_BG[k % 2], f"row {k} background is {C_ROW_BG[k % 2]}, measured {got}")
        kit = ref[y : y + ROW_H, KIT_CELL[0] : KIT_CELL[1]]
        expect((kit == np.array(C_KIT_BG)).all(), f"row {k} kit cell is flat {C_KIT_BG}")
    print(f"row bands alternate {C_ROW_BG[0]} / {C_ROW_BG[1]}; the kit cell is flat {C_KIT_BG}")

    out = a.copy()

    # ---- 2. the picture window: the game clears it to black ---------------------
    x, y, w, h = PICTURE
    out[y : y + h, x : x + w] = 0

    # ---- 3. group A's rows <- the empty widget, verbatim ------------------------
    out[BOX_Y[0] + ROW_Y0 : BOX_Y[0] + BOX_H, BOX_X[0] : BOX_X[0] + BOX_W] = ref[ROW_Y0:]

    # ---- 4. the GROUPS plate: black ink on flat white --------------------------
    x0, y0, x1, y1 = PLATE_WHITE
    cell = out[y0:y1, x0:x1]
    ink = (cell == np.array(C_PLATE_INK)).all(axis=2)
    expect(ink.sum() > 0, "the GROUPS plate carries black ink")
    cell[ink] = (255, 255, 255)
    print(f"GROUPS plate: {int(ink.sum())} ink px cleared to flat white")

    # ---- 5. the six header letters ---------------------------------------------
    # The word GROUP is the same in every box and never changes, so it STAYS -- the same
    # standing the green MATCHES header has in the list bake. Only the per-box LETTER is
    # content, and its ink is pure white, so the plate under it is recoverable: the six
    # boxes carry the identical gradient, so at a pixel one of the letters does not ink,
    # that box's value IS the plate. A pixel every one of the six inks (the shared left
    # stem of B/D/E/F etc.) borrows the nearest non-ink pixel of the SAME plate row, which
    # is the dither's own texture rather than a flattening modal.
    lx0, ly0 = HDR_LETTER
    lw, lh = 22, 14
    stack = np.stack([box(a, c, r)[ly0 : ly0 + lh, lx0 : lx0 + lw] for c, r in boxes])
    white = (stack == np.array(C_HDR_LETTER)).all(axis=3)  # (6, lh, lw)
    plate = np.zeros((lh, lw, 3), dtype=np.uint8)
    borrowed = 0
    for yy in range(lh):
        free_any = np.where(~white[:, yy, :].all(axis=0))[0]  # cols some box leaves bare
        for xx in range(lw):
            src = np.where(~white[:, yy, xx])[0]
            if src.size:
                vals, counts = np.unique(stack[src, yy, xx, :], axis=0, return_counts=True)
                expect(counts.max() == counts.sum(), f"letter cell ({xx},{yy}) plate disagrees")
                plate[yy, xx] = vals[0]
            else:
                expect(free_any.size > 0, f"letter cell row {yy} is inked by all six everywhere")
                nx = int(free_any[np.abs(free_any - xx).argmin()])
                src = np.where(~white[:, yy, nx])[0]
                plate[yy, xx] = stack[src[0], yy, nx]
                borrowed += 1
    cleared = 0
    for c, r in boxes:
        dst = out[
            BOX_Y[r] + ly0 : BOX_Y[r] + ly0 + lh,
            BOX_X[c] + lx0 : BOX_X[c] + lx0 + lw,
        ]
        cleared += int((dst != plate).any(axis=2).sum())
        dst[:] = plate
    print(f"six header letters: {cleared} px cleared; {borrowed} plate px borrowed in-row")

    # ---- 6. the title and ROUND plates -----------------------------------------
    # These two plates are the LEFT panel's, shared with the list and grid forms, and that
    # bake already recovered them from TWO frames whose titles ink different pixels
    # (`build_cupdraw_chrome_from_frames.py`, clear_by_union). A single frame cannot beat
    # that -- borrowing in-row from one frame leaves a readable ghost of "EUROPEAN CUP" --
    # so the two spans are taken from the existing chrome rather than re-derived. Asserted
    # below: outside these plates, the picture and the right panel, this frame and that
    # chrome are the SAME pixels, which is what makes the transplant legitimate.
    grid = np.array(Image.open(OUT / "chrome_grid.png").convert("RGB"))[:, :640]
    same = (a == grid).all(axis=2)
    mask = np.ones(same.shape, dtype=bool)
    px, py, pw, ph = PICTURE
    mask[py : py + ph, px : px + pw] = False
    for x0, y0, x1, y1 in (TITLE_SPAN, ROUND_SPAN):
        mask[y0:y1, x0:x1] = False
    mask[:, 326:] = False  # the right panel is a different form
    mask[410:455, 20:95] = False  # the leg plates: blank here, inked there
    n_left = int((~same & mask).sum())
    expect(n_left == 0, f"frame and chrome_grid differ by {n_left} px outside the dynamics")
    # UNION, not transplant: this frame's own pixels stay everywhere it does NOT ink, and
    # only its text pixels are taken from the other bake. Wholesale transplanting cost 96 px
    # -- the other bake's own recovery is an approximation exactly where its frames inked.
    for span, colours in ((TITLE_SPAN, ((255, 255, 255),)), (ROUND_SPAN, ((255, 223, 0),))):
        x0, y0, x1, y1 = span
        sub = out[y0:y1, x0:x1]
        ink = np.zeros(sub.shape[:2], dtype=bool)
        for col in colours:
            ink |= (sub == np.array(col)).all(axis=2)
        sub[ink] = grid[y0:y1, x0:x1][ink]
        print(f"plate {span}: {int(ink.sum())} ink px taken from chrome_grid")
    print(f"the rest of the left panel matches chrome_grid at {n_left} px")

    OUT.mkdir(parents=True, exist_ok=True)
    Image.fromarray(out).save(OUT / "chrome_groups.png")
    print(f"wrote {OUT / 'chrome_groups.png'}")

    spec = {
        "_source": str(FRAME.relative_to(ROOT)),
        "picture": PICTURE,
        "title_span": TITLE_SPAN,
        "round_span": ROUND_SPAN,
        "plate_white": PLATE_WHITE,
        "plate_sum": PLATE_SUM,
        "plate_top": PLATE_TOP,
        "box_x": BOX_X,
        "box_y": BOX_Y,
        "box_w": BOX_W,
        "box_h": BOX_H,
        "hdr_text": HDR_TEXT,
        "hdr_letter": HDR_LETTER,
        "row_y0": ROW_Y0,
        "row_pitch": ROW_PITCH,
        "row_h": ROW_H,
        "rows": ROWS,
        "kit_cell": KIT_CELL,
        "kit_at": KIT_AT,
        "name_sum": NAME_SUM,
        "name_top": NAME_TOP,
        "flag_at": FLAG_AT,
        "flag_src_row0": FLAG_SRC_ROW0,
        "flag_rows": FLAG_ROWS,
        "c_row_bg": C_ROW_BG,
        "c_row_ink": C_ROW_INK,
        "c_kit_bg": C_KIT_BG,
        "c_hdr_text": C_HDR_TEXT,
        "c_hdr_letter": C_HDR_LETTER,
        "c_plate_ink": C_PLATE_INK,
    }
    SPEC.parent.mkdir(parents=True, exist_ok=True)
    SPEC.write_text(json.dumps(spec, indent=1) + "\n")
    print(f"wrote {SPEC}")


if __name__ == "__main__":
    main()
