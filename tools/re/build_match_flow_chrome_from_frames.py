#!/usr/bin/env python3
"""Bake the CAREER MATCH-PRESENTATION static chrome (MATCH OPTIONS modal +
RESULT-mode HALF/FULL TIME + BRIEF-mode) from the real game's own frames.

Binding frames (all captured from the real MANAGER.EXE under Wine):
  MATCH OPTIONS : screenshots/wine-captures-2026-07-12/dropdown_matchoptions_match.png
                  (the MATCH tab; RESULTS selected red, LINE-UPS ON, CANCEL/OK).
                  Reversed row rects corroborated in docs/re/match_view_re.md
                  (FUN_004e2630: WATCH/HIGHLIGHTS/BRIEF/RESULTS 98x25 @ y100,
                  panel-local x {5,109,214,317}).
  RESULT (FULL) : screenshots/wine-captures-2026-07-12/match_result_fulltime.png
                  (Man Utd 1-2 Bolton, Old Trafford; STATISTICS x2 + stadium
                  panel + MAN OF THE MATCH + CONTINUE).
  RESULT (HALF) : screenshots/wine-captures-2026-07-12/match_result_halftime_oldtrafford.png
                  (HALF TIME title; manager-side TACTICS/LINE-UP buttons).
  BRIEF         : screenshots/original-walkthrough-2026-07-02/073_162649.png
                  (F.C. Barcelona 0-0 Manchester Utd, KICK OFF: clock, kits
                  scoreline, possession bar, empty EVENTS feed, in-match
                  LINE-UP/TACTICS/MAN-TO-MAN/STATISTICS + KICK OFF + EXIT).

Doctrine (docs/re/SPEC_BINDING.md): every baked pixel traces to a frame. The
chrome layer IS the original frame with ONLY the state-dependent data pixels
cleared to a resting look; the scenes redraw the dynamic layer on top:
  MATCH OPTIONS -> nothing dynamic (all labels static): the whole modal is cut.
  RESULT        -> club names, scores, the real GOAL rows, and the Career-known
                   stadium CAPACITY/ATTENDANCE. BOOKINGS / TOTAL FOULS /
                   POSSESSION% / MAN-OF-THE-MATCH / attendance-money /
                   sponsor lines are NOT produced by the instant-result stat
                   engine -> they stay the original chrome with an honest
                   empty/absent state (never fabricated; see match_flow_re.md).
  BRIEF         -> clock, half/state label, names, score, and the goal-only
                   EVENTS feed (Kick Off + real Goal lines). Possession is a gap.

The header band (y0..61) of the RESULT frames is repainted by the screen via
PMChrome.draw_match_header + the HALF/FULL TIME title sprite cut here (the same
recomposition the LINE-UP / VIEW RIVAL / FIXTURES rollouts proved 0px).

Outputs (app/art/screens/matchflow/):
  mo_modal.png            the MATCH OPTIONS modal (cut verbatim)
  title_halftime.png / title_fulltime.png   barra title sprites
  result_ft.png           FULL TIME body (y61..479), dynamic data cleared
  result_ht.png           HALF TIME body (y61..479), dynamic data cleared
  brief.png               BRIEF body (whole frame), dynamic data cleared
  tools/re/specs/match_flow_chrome_samples.json   geometry + colours + hit-rects

Every measured invariant is asserted so a bad crop or a regenerated capture
fails loudly instead of baking garbage.  Run:  python3 tools/re/build_match_flow_chrome_from_frames.py
"""

from __future__ import annotations

import json
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
WCAP = ROOT / "screenshots" / "wine-captures-2026-07-12"
WALK = ROOT / "screenshots" / "original-walkthrough-2026-07-02"
ART = ROOT / "app" / "art" / "screens" / "matchflow"
SPECS = Path(__file__).resolve().parent / "specs"

F_MO = WCAP / "dropdown_matchoptions_match.png"
F_FT = WCAP / "match_result_fulltime.png"
F_HT = WCAP / "match_result_halftime_oldtrafford.png"
F_BRIEF = WALK / "073_162649.png"


def load(p: Path) -> np.ndarray:
    a = np.asarray(Image.open(p).convert("RGB"))
    if a.shape[0] != 480 or a.shape[1] not in (640, 641):
        raise SystemExit(f"{p.name}: unexpected size {a.shape}")
    return a[:, :640].copy()  # 641st column = capture artifact


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


def band_row_fill(a: np.ndarray, y0: int, y1: int, x0: int, x1: int, is_band) -> None:
    """Reconstruct a horizontally-uniform band: replace [y0:y1, x0:x1] with each
    row's median band colour (sampled across the whole band width x0s..x1s)."""
    for y in range(y0, y1):
        row = a[y]
        mask = is_band(row)
        cols = np.where(mask)[0]
        cols = cols[(cols >= 30) & (cols <= 610)]
        if len(cols) < 20:
            continue
        med = np.median(row[cols], axis=0).astype("uint8")
        a[y, x0:x1] = med


def main() -> None:
    spec: dict = {}

    # ======================= MATCH OPTIONS ====================================
    mo = load(F_MO)
    # The modal is a light-framed panel over the hub. Cut its bounding box from
    # the bright outer frame (>185 on all channels) inside the modal window.
    bright = (mo[:, :, 0] > 185) & (mo[:, :, 1] > 185) & (mo[:, :, 2] > 185)
    win = np.zeros_like(bright)
    win[112:374, 98:544] = bright[112:374, 98:544]
    ys, xs = np.where(win)
    mx0, mx1, my0, my1 = int(xs.min()), int(xs.max()), int(ys.min()), int(ys.max())
    expect(
        430 <= mx1 - mx0 <= 448 and 250 <= my1 - my0 <= 264,
        f"MO modal bbox {mx0},{my0}..{mx1},{my1}",
    )
    save(mo[my0 : my1 + 1, mx0 : mx1 + 1], "mo_modal.png")
    # The GRAPHICS / CAMERAS / SOUND tabs are the SAME modal with different panel
    # content. Cut each at the IDENTICAL bbox (so all four register pixel-exact) from
    # its own live capture. The tab row's active-tab highlight is baked-in per capture,
    # so switching the sprite gives the correct active-tab colour for free.
    for tab in ("graphics", "cameras", "sound"):
        ta = load(WCAP / f"dropdown_matchoptions_{tab}.png")
        # confirm this capture's modal sits at the same box before cutting.
        tb = (ta[:, :, 0] > 185) & (ta[:, :, 1] > 185) & (ta[:, :, 2] > 185)
        tw = np.zeros_like(tb)
        tw[112:374, 98:544] = tb[112:374, 98:544]
        tys, txs = np.where(tw)
        expect(
            abs(int(txs.min()) - mx0) <= 1
            and abs(int(txs.max()) - mx1) <= 1
            and abs(int(tys.min()) - my0) <= 1
            and abs(int(tys.max()) - my1) <= 1,
            f"MO {tab} modal bbox drift {int(txs.min())},{int(tys.min())}..{int(txs.max())},{int(tys.max())}",
        )
        save(ta[my0 : my1 + 1, mx0 : mx1 + 1], f"mo_modal_{tab}.png")
    # Hit-rects (frame-measured, modal-local). Row y-spans: view 279..297,
    # tab 312..330, bottom 342..370. View buttons x {WATCH,HIGHLIGHTS,BRIEF,
    # RESULTS}; bottom CANCEL/OK.
    spec["match_options"] = {
        "binding_frame": F_MO.name,
        "modal_xy": [mx0, my0],
        "modal_wh": [mx1 - mx0 + 1, my1 - my0 + 1],
        # absolute-frame hit rects (x,y,w,h)
        "view_row_y": [279, 297],
        "view_btns": {  # measured left/right edges -> x,w
            "watch": [116, 97],
            "highlights": [220, 97],
            "brief": [325, 97],
            "results": [428, 97],
        },
        "bottom_row_y": [342, 370],
        "bottom_btns": {
            "lineups": [109, 103],
            "on": [216, 46],
            "cancel": [323, 102],
            "ok": [430, 102],
        },
        # tab row (MATCH/GRAPHICS/CAMERAS/SOUND): same four columns as the view row,
        # y 312..330 (bake note). Switching the sprite shows each tab's real panel.
        "tab_row_y": [312, 330],
        "tab_btns": {
            "match": [116, 97],
            "graphics": [220, 97],
            "cameras": [325, 97],
            "sound": [428, 97],
        },
        "tab_panels": {
            "match": "mo_modal.png",
            "graphics": "mo_modal_graphics.png",
            "cameras": "mo_modal_cameras.png",
            "sound": "mo_modal_sound.png",
        },
        # Per-tab controls — frame-measured from the tab captures (the RE FUN_004e2630
        # never reversed these sub-rects, so the capture pixels are the source). Every
        # one configures the ABSENT 3D/positional engine or its (un-built) match audio,
        # so all are honest no-ops at runtime: the dialog tracks + persists the choice
        # exactly like the original's MANAGER.INI, but there is no 3D view/match-audio
        # for it to change. Rects are absolute-frame (x,y,w,h), centred on the label.
        "graphics_controls": {
            "sky": [191, 190, 44, 20],
            "boards": [191, 230, 44, 20],
            "shadows": [191, 270, 44, 20],
            "pitch_high": [418, 193, 48, 23],
            "pitch_med": [464, 193, 48, 23],
            "pitch_low": [418, 226, 48, 23],
            "pitch_min": [464, 226, 48, 23],
            "stadium_high": [398, 266, 46, 22],
            "stadium_med": [446, 266, 44, 22],
            "stadium_low": [492, 266, 40, 22],
        },
        "camera_controls": {"auto": [122, 270, 46, 20], "free": [178, 270, 60, 20]},
        "sound_controls": {
            "fx": [181, 281, 44, 20],
            "ambient": [299, 281, 44, 20],
            "comments": [427, 281, 44, 20],
        },
        "note": (
            "Reversed FUN_004e2630 view-row rects (98x25 @ y100, panel-local "
            "x 5/109/214/317) corroborate; frame is the pixel source. Only "
            "WATCH/BRIEF/RESULTS are buildable (HIGHLIGHTS = 3D .p3d absent). "
            "The GRAPHICS/CAMERAS/SOUND sub-controls are frame-measured (not "
            "in the RE) and honest no-ops (their 3D/audio target is absent)."
        ),
    }

    # ======================= RESULT titles ====================================
    # Barra chrome-gradient titles "HALF TIME" / "FULL TIME" (frame sprites, like
    # header/title_lineup.png). Glyph bbox in the barra, excluding the calendar
    # sheet (x>=440). Anchor recorded for PMChrome-less overlay by the screen.
    for frame, name in [(load(F_FT), "fulltime"), (load(F_HT), "halftime")]:
        # glyph edge = the dark chrome outline/shadow (<70) in the title zone
        # (x 160..430 excludes the name plaques left + calendar sheet right).
        dark = frame[12:48, 160:430].max(axis=2) < 70
        ys, xs = np.where(dark)
        tx0, tx1 = 160 + int(xs.min()) - 4, 160 + int(xs.max()) + 4
        ty0, ty1 = 13, 12 + int(ys.max()) + 2
        expect(220 <= tx0 <= 260 and 340 <= tx1 <= 380, f"title {name} bbox x {tx0}..{tx1}")
        save(frame[ty0 : ty1 + 1, tx0 : tx1 + 1], f"title_{name}.png")
        spec.setdefault("result_titles", {})[name] = {"xy": [tx0, ty0]}

    # ======================= RESULT body (FULL TIME) ==========================
    ft = load(F_FT)
    spec["result"] = _bake_result(ft, "result_ft.png", full=True)
    ht = load(F_HT)
    _bake_result(ht, "result_ht.png", full=False)

    # ======================= BRIEF body =======================================
    spec["brief"] = _bake_brief()

    # ======================= SPECS ============================================
    SPECS.mkdir(parents=True, exist_ok=True)
    out = SPECS / "match_flow_chrome_samples.json"
    out.write_text(json.dumps(spec, indent=1) + "\n")
    print(f"  {out.relative_to(ROOT)}")


# --- RESULT bake ------------------------------------------------------------

# scoreband + panels geometry (frame-measured, asserted below)
SB_Y = (66, 108)  # blue scoreline band rows
BAND_FILL = (42, 63, 170)  # uniform scoreband blue (name rows)
BOX_FILL = (0, 0, 128)  # score-box navy interior
# Score boxes frame-measured off the 3 witnessed FT read-outs (all identical:
# match_result_fulltime.png + results_mode_fulltime_readout + readout_fulltime_thedell):
# left white border x266..319 / navy 267..318; right x320..373 / navy 321..372; the two
# share the middle divider. White top border y78, navy 79..112, bottom border y113.
# (The old (246,320)/(339,375) @ y66 over-painted navy up over the name bar + left into
# the band -- the charter #6a "score-box overdraw" bug.)
BOX_L = (266, 319)  # left score box (x span, incl white border)
BOX_R = (320, 373)  # right score box
BOX_Y = (78, 113)  # box y-span (incl white top/bottom borders)
NAME_H = (36, 265)  # home-name clear zone (band, left of left box)
NAME_A = (374, 585)  # away-name clear zone (band, right of right box)
POSS = (30, 612, 116, 140)  # possession band x0,x1,y0,y1
POSS_PILL = (270, 368)  # [POSSESSION] pill x-span kept intact
COLS = {  # cell columns (x span); scrollbar to the right of each
    "hb": (19, 144),
    "hg": (169, 289),
    "ab": (332, 457),
    "ag": (482, 602),
}
ROW_Y0, ROW_PITCH, ROW_H, N_ROWS = 172, 16, 12, 7
FOULS_Y = (300, 316)
STAD = (14, 292, 348, 445)  # stadium panel frame bbox (black frame)
STAD_ICON_X = 76  # keep the car icon left of this x
STAD_BODY_BG = (42, 95, 170)  # flat blue panel-row bg
MOTM = (325, 350, 604, 420)  # motm panel x0,y0,x1,y1

# --- STADIUM panel, measured by DIFFING the two witnessed FULL TIME frames --
# (match_result_fulltime.png = Old Trafford 55,300 / 19,355 / 35% / £145,162 /
#  31% / £6,750  vs  15_fulltime.png = The Dell 15,200 / 12,160 / 80% / £91,200
#  / 86% / £18,750). Pixels that differ between the two are the DATA; everything
# else — the arrow chevrons, all five row LABELS, the sub-cell boundaries and the
# stadium sprite — is static chrome and must survive the bake. The previous bake
# row-medianed the whole label area away, which is the reported "stadium image
# truncated and wrong" (only blank rows + a floating sprite were left).
#
# Panel interior x16..286; chevron zone x16..33; body x34..286, with a right
# sub-cell x216..286 on the two %-carrying rows.
# The LABEL ink is dark, the VALUE ink is white — so the value spans are the white
# ink runs, identical in both frames: cap 109.., att 128.. (+ the % at 236..264),
# attmoney 177.. (the "£" is part of the value), boards % 236..264, sponsor 177...
STAD_ROWS = [
    # key,        y0,  y1,  value_x, sub_x (None = no right sub-cell)
    ("name", 351, 375, 84, None),
    ("cap", 375, 390, 105, None),
    ("att", 392, 407, 124, 216),
    ("attmoney", 409, 424, 173, None),
    ("boards", 426, 441, 287, 216),  # label only; the % lives in the sub-cell
    ("sponsor", 443, 458, 173, None),
]
STAD_X1 = 287  # first column of the white right border
# MAN OF THE MATCH: 32x32 mugshot cell + the 4-row-period blue name band.
MOTM_PHOTO = (312, 370, 344, 402)  # x0,y0,x1,y1
MOTM_BAND_Y = (370, 402)
MOTM_TEXT = (346, 378, 549, 392)  # the name text block inside the band


def _is_scoreband(row: np.ndarray) -> np.ndarray:
    return (row[:, 2] > 120) & (row[:, 0] < 110) & (row[:, 1] < 120)


def _rowmed(
    a: np.ndarray,
    f: np.ndarray,
    y0: int,
    y1: int,
    xa: int,
    xb: int,
    sx0: int,
    sx1: int,
    keep: tuple | None = None,
) -> None:
    """Fill [y0:y1, xa:xb] with each row's MEDIAN colour sampled from a clean span
    [sx0:sx1] of that row -> reconstructs a horizontal element's background and
    removes the text/data on top of it. `keep` protects an x-span (e.g. a pill)."""
    for y in range(y0, y1):
        med = np.median(f[y, sx0:sx1], axis=0).astype("uint8")
        if keep is None:
            a[y, xa:xb] = med
        else:
            a[y, xa : keep[0]] = med
            a[y, keep[1] : xb] = med


def _modal(block: np.ndarray) -> np.ndarray:
    """The most common colour in `block` — the flat background of a panel cell,
    with the text ink outvoted."""
    vals, counts = np.unique(block.reshape(-1, 3), axis=0, return_counts=True)
    return vals[counts.argmax()].astype("uint8")


def _bake_result(f: np.ndarray, out: str, full: bool) -> dict:
    # --- invariants -------------------------------------------------------
    expect(bool(_is_scoreband(f[88])[230]), "scoreband blue at (230,88)")
    expect(px(f, 305, 92)[2] > 100 and px(f, 305, 92)[0] < 40, "left score box navy")
    expect(abs(px(f, 540, 210)[1] - 223) < 30 and px(f, 540, 210)[0] > 140, "away GOALS green cell")
    expect(px(f, 80, 210)[2] > 200 and px(f, 80, 210)[0] > 150, "bookings light-blue cell")

    a = f.copy()

    # 1) clear home/away NAMES on the flat band
    a[72:107, NAME_H[0] : NAME_H[1]] = np.array(BAND_FILL, dtype="uint8")
    a[72:107, NAME_A[0] : NAME_A[1]] = np.array(BAND_FILL, dtype="uint8")

    # 2) clear the two SCORE digits (box interiors -> flat navy, keep white border)
    a[BOX_Y[0] + 2 : BOX_Y[1] - 1, BOX_L[0] + 2 : BOX_L[1] - 1] = np.array(BOX_FILL, dtype="uint8")
    a[BOX_Y[0] + 2 : BOX_Y[1] - 1, BOX_R[0] + 2 : BOX_R[1] - 1] = np.array(BOX_FILL, dtype="uint8")

    # 3) GOALS + BOOKINGS cells: copy an empty cell (row 5) over every data row so
    #    the real goals / honest-empty bookings redraw clean.
    for cx0, cx1 in COLS.values():
        ey = ROW_Y0 + ROW_PITCH * 5
        empty_cell = f[ey : ey + ROW_H, cx0:cx1].copy()
        for r in range(N_ROWS):
            ry = ROW_Y0 + ROW_PITCH * r
            a[ry : ry + ROW_H, cx0:cx1] = empty_cell

    # The POSSESSION %, TOTAL FOULS, the STADIUM money/sponsor lines and MAN OF THE
    # MATCH are club-specific data the instant-result stat engine does NOT produce
    # -> cleared to an honest resting state (never fabricated). CAPACITY / ATTENDANCE
    # + the ground name are Career-known and redrawn by the screen; the rest blank.

    # POSSESSION: empty-bar grey (keep the [POSSESSION] pill), marble either side.
    empty = np.array([196, 202, 212], dtype="uint8")
    a[122:135, 126 : POSS_PILL[0]] = empty
    a[122:135, POSS_PILL[1] : 568] = empty
    _rowmed(a, f, POSS[2], POSS[3], 82, 126, 40, 78)  # marble left of the bar
    _rowmed(a, f, POSS[2], POSS[3], 568, 610, 596, 610)  # marble right of the bar

    # STADIUM body: clear ONLY the per-row VALUE spans (measured by frame-diff, see
    # STAD_ROWS). The chevrons, the five labels, the sub-cell boundaries and the
    # stadium sprite are static chrome and stay. Each cleared span is filled with the
    # row's own background sampled from a clean column INSIDE the same sub-cell, so a
    # row that carries a right sub-cell keeps its boundary.
    for key, y0, y1, vx, sub in STAD_ROWS:
        if key == "name":
            a[y0:y1, vx:STAD_X1] = np.array([255, 255, 255], dtype="uint8")
            continue
        # main cell: value_x .. (sub_x or right border). Each sub-cell is ONE flat
        # colour across the whole row band, so its modal colour is exact.
        main_x1 = sub if sub is not None else STAD_X1
        if vx < main_x1:
            a[y0:y1, vx:main_x1] = _modal(f[y0:y1, 34:main_x1])
        # right sub-cell (the % cells): always data, cleared whole
        if sub is not None:
            a[y0:y1, sub:STAD_X1] = _modal(f[y0:y1, sub:STAD_X1])

    # MAN OF THE MATCH (full time): clear the 32x32 mugshot cell to black and lift the
    # name text off the blue band. The band has a 4-row vertical period, so each
    # cleared row is copied from a text-free row of the SAME parity — the flat
    # (0,0,160) rectangle the old bake stamped destroyed the band, the panel frame and
    # the photo cell alike (the reported "man of the match" defect).
    if full:
        a[MOTM_PHOTO[1] : MOTM_PHOTO[3], MOTM_PHOTO[0] : MOTM_PHOTO[2]] = 0
        tx0, ty0, tx1, ty1 = MOTM_TEXT
        for y in range(ty0, ty1):
            src = 396 + ((y - 396) % 4)
            a[y, tx0:tx1] = f[src, tx0:tx1]

    save(a, out)
    return {
        "binding_frame": F_FT.name if full else F_HT.name,
        "scoreband_y": list(SB_Y),
        "box_l": list(BOX_L),
        "box_r": list(BOX_R),
        "name_home": list(NAME_H),
        "name_away": list(NAME_A),
        "band_fill": list(BAND_FILL),
        "box_fill": list(BOX_FILL),
        "poss": list(POSS),
        "poss_pill": list(POSS_PILL),
        "cols": {k: list(v) for k, v in COLS.items()},
        "row_y0": ROW_Y0,
        "row_pitch": ROW_PITCH,
        "row_h": ROW_H,
        "n_rows": N_ROWS,
        "fouls_y": list(FOULS_Y),
        "colors": {
            "scoreband": list(BAND_FILL),
            "box": list(BOX_FILL),
            "cell_green": list(px(f, 540, 210)),
            "cell_blue": list(px(f, 80, 210)),
            "stadium_row": list(STAD_BODY_BG),
        },
        # scoreband kit anchors (home top-left / away top-right, club escudo overlay)
        "kit_home_xy": [6, 60],
        "kit_away_xy": [590, 60],
        "kit_wh": [46, 52],
        # continue button (full time) hit rect
        "continue": [479, 439, 112, 25],
        # stadium panel: the five row VALUE anchors the screen draws into (the
        # labels + chevrons are static chrome and are NOT cleared).
        "stadium_panel": list(STAD),
        "stadium_icon_x": STAD_ICON_X,
        "stadium_body_bg": list(STAD_BODY_BG),
        "stadium_rows": [
            {"key": k, "y0": y0, "y1": y1, "value_x": vx, "sub_x": sub}
            for (k, y0, y1, vx, sub) in STAD_ROWS
        ],
        "stadium_right_x": STAD_X1,
        "motm_panel": list(MOTM),
        "motm_photo": list(MOTM_PHOTO),
        "motm_band_y": list(MOTM_BAND_Y),
        "motm_text": list(MOTM_TEXT),
    }


# --- BRIEF bake -------------------------------------------------------------

BR_CLOCK = (258, 372, 30, 100)  # LCD box x0,x1,y0,y1 (scene overpaints digits)
BR_STATE_Y = (68, 92)  # "KICK OFF"/"FIRST HALF" label band (below clock)
BR_BAND_Y = (99, 136)  # black scoreline band
BR_NAME_H = (76, 256)  # home name zone (black band, left of boxes)
BR_NAME_A = (382, 586)  # away name zone (black band, right of boxes)
BR_BOX_L = (258, 320)  # left score box
BR_BOX_R = (322, 380)  # right score box
BR_KIT_H = (8, 70, 82, 138)  # home kit x0,x1,y0,y1
BR_KIT_A = (585, 638, 82, 138)  # away kit
BR_EVENTS = (300, 488, 218, 435)  # events panel x0,x1,y0,y1


def _bake_brief() -> dict:
    f = load(F_BRIEF)
    # invariants: kickoff state (empty events, 0-0), clock at 00:00
    expect(f[350, 400, 0] > 210 and f[350, 400, 1] > 210, "BRIEF events body white")
    expect(f[108, 265, 2] > 100 and f[108, 265, 0] < 110, "BRIEF score box blue")
    black = np.array([8, 8, 12], dtype="uint8")
    a = f.copy()
    # scoreline band is BLACK: clear the home + away NAME text (dynamic) to black,
    # skipping the score boxes; the screen overlays names + scores + the clock digit
    # + the half/state label + the goal-only EVENTS feed.
    a[BR_BAND_Y[0] : BR_BAND_Y[1], BR_NAME_H[0] : BR_NAME_H[1]] = black
    a[BR_BAND_Y[0] : BR_BAND_Y[1], BR_NAME_A[0] : BR_NAME_A[1]] = black
    # clear the "KICK OFF" half/state label (dynamic, below the clock) to the blue bg
    bg = np.median(f[BR_STATE_Y[0] : BR_STATE_Y[1], 200:236].reshape(-1, 3), axis=0).astype("uint8")
    a[BR_STATE_Y[0] : BR_STATE_Y[1], 228:410] = bg
    # clear the frame-073 KITS (dynamic per match): the screen redraws the fixture's own
    # escudos, so the baked home/away kits MUST go -- else the wrong club's kit shows
    # around the redrawn one (the "Villa red" parity bug, orig/64 vs app). Reconstruct
    # the blue chrome above/below + the black scoreband beneath, per side from an adjacent
    # glyph-free span (same per-row median technique as the possession/stadium blanks).
    # generous bboxes: the frame-073 kits run x8..72 / x560..640, y89..149 (wider than
    # the BR_KIT_* label bboxes), so cover their full extent or a red sliver survives.
    for kx0, kx1, sx0, sx1 in [(8, 74, 90, 150), (560, 640, 480, 556)]:
        _rowmed(a, f, 80, BR_BAND_Y[0], kx0, kx1, sx0, sx1)  # blue chrome above band
        a[BR_BAND_Y[0] : BR_BAND_Y[1], kx0:kx1] = black  # black scoreband
        _rowmed(a, f, BR_BAND_Y[1], 150, kx0, kx1, sx0, sx1)  # blue chrome below band
    save(a, "brief.png")
    return {
        "binding_frame": F_BRIEF.name,
        "clock": list(BR_CLOCK),
        "state_y": list(BR_STATE_Y),
        "band_y": list(BR_BAND_Y),
        "name_home": list(BR_NAME_H),
        "name_away": list(BR_NAME_A),
        "box_l": list(BR_BOX_L),
        "box_r": list(BR_BOX_R),
        "kit_home": list(BR_KIT_H),
        "kit_away": list(BR_KIT_A),
        "events": list(BR_EVENTS),
        # right-column + bottom in-match buttons (frame-measured, x,y,w,h)
        "btn_lineup": [495, 227, 133, 33],
        "btn_tactics": [495, 283, 133, 33],
        "btn_mtm": [495, 339, 133, 33],
        "btn_stats_r": [495, 393, 133, 30],
        "btn_stats_l": [14, 393, 133, 30],
        "btn_kick": [262, 442, 156, 30],
        "btn_exit": [508, 442, 120, 30],
        "note": (
            "Frame 073 is KICK OFF (empty EVENTS, 0-0): the resting chrome is "
            "the frame with the club NAMES + state label cleared. The honest "
            "feed shows Kick Off + real Goal lines only; possession is a gap."
        ),
    }


if __name__ == "__main__":
    main()
