#!/usr/bin/env python3
"""YOUTH TEAM screen chrome, frame-baked from the real MANAGER.EXE walkthrough,
following the staff/finance/directiva frame-bake precedent (cut the original
pixels 1:1, keep every static label / portrait / button, expose the dynamic
value regions so the scene redraws live values on top).

Binding frames (ground truth, owned game frames):
  screenshots/original-walkthrough-2026-07-02/087_154632.png
      fresh YOUTH TEAM, run1 (Man Utd / MWM, Friday 1 August 1997): NO staff
      hired.  SCOUT name bar empty, SEARCH CAPABILITY all NO, all six LEDs in
      the dark "disabled" state, SEARCH plaque with the pale DISABLED lettering,
      PLAYERS FOUND = "You need to hire a scout to search youth players.",
      MANAGER name bar empty, no player count, empty 11-row roster,
      PARAMETERS selected (red-glow plaque) / RATING unselected.
  088_154633  same + WHITE held ring around the RATING plaque.
  089_154635  same + WHITE held ring around RETURN.
  047_164509  run3 ("asdf", Sunday 10 August 1997): scout P. Mitchell (5 gold
      stars on the purple bar), all capabilities YES (red), LEDs now in the
      brighter "available" state with DRIBBLING / PASSING / SHOOTING toggled
      LIT, SEARCH plaque with the yellow ENABLED lettering, PLAYERS FOUND =
      "The scout is now searching for players with selected capabilities.",
      youth manager G. Keeping (3.5 stars) + "3 PLAYERS", RATING selected.
  048_164510  same + held ring around SEARCH.

Outputs (app/art/screens/youth/):
  youth_body.png        640x(480-BODY_Y) baked body from frame 087, with ONLY
                        the live-value ink removed: the six SEARCH CAPABILITY
                        value cells are re-striped from the track's own clean
                        columns, and the PLAYERS FOUND interior is whited (the
                        hire-a-scout message is a live state, drawn by the scene).
  led_avail.png         "available" (scout hired, unselected) LED, cut from 047.
  led_lit.png           selected/lit LED, cut from 047 (DRIBBLING).
  search_on.png         ENABLED Search plaque (yellow lettering), cut from 047.
  plaq_param_off.png    PARAMETERS unselected plaque, cut from 047.
  plaq_rating_on.png    RATING selected (red-glow) plaque, cut from 047.
  star_full.png / star_half.png  gold star cells cut from 047's scout/manager bars.
  youth_chrome.json     geometry, frame-sampled inks, verbatim witnessed
                        messages, value-face ink metrics (proman8 atlas), and
                        the witnessed run-3 fixture for the parity oracle.

Doctrine (pm98_stay_true_to_original): the PNG is the real frame's pixels below
the barra; PMChrome.draw_header draws the header live. The 087 body IS the
authentic empty state, so almost nothing is blanked — only ink that a live
value can REPLACE (NO -> YES, the found-panel message) is lifted out.
Un-witnessed surfaces are NOT invented here: the filled roster-row rendering,
the filled PLAYERS FOUND list and the bottom-right skill-tile behaviour stay
honest gaps documented in docs/re/youth_re.md.
"""

from __future__ import annotations

import json
import os
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
FRAMES = ROOT / "screenshots/original-walkthrough-2026-07-02"
F_EMPTY = FRAMES / "087_154632.png"  # binding empty state (baked)
F_LIVE = FRAMES / "047_164509.png"  # binding staffed/searching state (sprites)
F_SEARCH_HELD = FRAMES / "048_164510.png"
F_RATING_HELD = FRAMES / "088_154633.png"
F_RETURN_HELD = FRAMES / "089_154635.png"
OUT_DIR = ROOT / "app/art/screens/youth"
OUT_JSON = OUT_DIR / "youth_chrome.json"
DEBUG_PNG = OUT_DIR / "_debug_rects.png"

W, H = 640, 480
BODY_Y = 58  # bake below the header barra (PMChrome draws y0..~56)

# ---- MEASURED geometry (native 640x480, off frames 087/047) ----------------
# Scout panel. The purple name bar; the 5 star cells sit ON the bar's right end
# (pitch 11, first cell x248, ink rows y86..94 -> star cells y85..95).
SCOUT_BAR = [138, 84, 167, 12]  # flat (110,80,120)
SCOUT_NAME_XY = [141, 87]  # white name ink rows y87..94 in 047
SCOUT_STARS = {"x0": 248, "y": 85, "pitch": 11, "max": 5}

# SEARCH CAPABILITY value cells (YES/NO ink lives here; ink boxes measured off
# the 047-vs-087 diff: x107..128 / x232..253, rows y127..134 / 140..147 / 153..160).
# Cell rects pad the ink by 2px inside the striped track; the blanking re-stripe
# is sampled from the track's own clean columns (see STRIPE_SRC).
CAP_ROWS = [126, 139, 152]  # cell top per row (ink top -1)
CAP_CELL_H = 10
CAP_CELLS = {
    "left": [105, 26],  # x, w  (HANDLING / DRIBBLING / TACKLING)
    "right": [230, 26],  # x, w (PASSING / HEADING / SHOOTING)
}
STRIPE_SRC = {"left": [101, 4], "right": [226, 4]}  # clean columns inside each track
CAP_ORDER = ["HANDLING", "PASSING", "DRIBBLING", "HEADING", "TACKLING", "SHOOTING"]
# capability values are INK-CENTRED per cell (staff-wage doctrine): frame ink boxes
# NO x110..124 / YES x107..127 share cx 117 (left col); NO x235..249 / YES
# x232..252 share cx 242 (right col).
CAP_VALUE_CX = {"left": 117, "right": 242}
CAP_INK = {"yes": [210, 0, 0], "no": [0, 0, 0]}

# LED slots (toggle lamps under the capability tracks). Uniform slot boxes; the
# lit sprite is TALLER than the dim art (bleeds 1-2px past the dim border), so
# the box takes the union: rows y168/186/204 (+15), left x24..48 / right x149..173.
LED_ROWS = [168, 186, 204]
LED_COLS = {"left": 24, "right": 149}
LED_W, LED_H = 25, 16
# order matches CAP_ORDER: left col rows = HANDLING/DRIBBLING/TACKLING,
# right col rows = PASSING/HEADING/SHOOTING.

# Buttons (plaque bboxes probed off 087; sprite cuts pad by 1px).
SEARCH_BTN = [240, 185, 76, 37]  # disabled art baked; enabled art = sprite
PARAM_BTN = [491, 264, 134, 21]  # PARAMETERS plaque (baked = selected)
RATING_BTN = [491, 288, 134, 21]  # RATING plaque (baked = unselected)
RETURN_BTN = [515, 428, 112, 25]
# held/press rings, verbatim from frames 048 (search) / 088 (rating) / 089 (return):
# a rectangle 2px OUTSIDE the plaque bbox. 048's ring is sampled below; 088/089 white.
RING_PAD = 2

# PLAYERS FOUND panel: white interior (messages are live states drawn by the scene).
PF_INTERIOR = [326, 102, 302, 117]  # x,y,w,h  (white bbox y101..219 x325..628, -1 pad)
# verbatim witnessed messages. Layout decoded from the ink boxes: LINE 1 is
# ink-centred on cx 476 (087 x392..560 and 047 x344..608 both centre 476), LINE 2
# is LEFT-aligned to line 1's ink start (087 both lines start x392; 047 both
# x344 — 047's line 2 centre would be 431.5, so the lines are NOT each centred).
PF_MSG_NO_SCOUT = ["You need to hire a scout", "to search youth players."]
PF_MSG_SEARCHING = ["The scout is now searching for players", "with selected capabilities."]
PF_MSG_ANCHOR = {"cx": 476, "line1_top": 145, "line2_top": 165}

# Manager panel: blue name bar + stars on the bar + the "N PLAYERS" count on the
# black MANAGER bar to the right (light-blue ink, left edge x376 witnessed).
MGR_BAR = [180, 245, 167, 12]  # flat (42,95,170)
MGR_NAME_XY = [183, 248]
MGR_STARS = {"x0": 290, "y": 246, "pitch": 11, "max": 5}
COUNT_XY = [376, 248]
COUNT_INK = [166, 202, 240]

# Roster list: 11 rows, top y303, pitch 16, bar rows 12 tall (flat 240,240,240);
# folder icon baked at the row head. Column header inks are baked; these anchors
# are for the LIVE rows (filled roster is un-witnessed -> game faces under the
# baked headers, documented in youth_re.md). Header ink runs MEASURED off 087's
# baked band (y288..300): NAME x59..99 / SP cx187 / ST cx211.5 / AG cx237 /
# QU cx262 / AV cx287 / ROL cx312 / WAGE cx358.5 / YEARS cx418.5.
ROW0_Y = 303
ROW_PITCH = 16
ROW_H = 12
ROW_COUNT = 11
ROW_TEXT_X = 59  # row name left edge = the NAME header's own left edge
COL_CX = {
    "SP": 187,
    "ST": 211,
    "AG": 237,
    "QU": 262,
    "AV": 287,
    "ROL": 312,
    "WAGE": 358,
    "YEARS": 418,
}

INK = {
    "name": [255, 255, 255],
    "msg": [0, 0, 0],
    "count": COUNT_INK,
    "yes": CAP_INK["yes"],
    "no": CAP_INK["no"],
}


def cut(im: Image.Image, box: list[int]) -> Image.Image:
    x, y, w, h = box
    return im.crop((x, y, x + w, y + h))


def main() -> int:
    for f in (F_EMPTY, F_LIVE, F_SEARCH_HELD, F_RATING_HELD, F_RETURN_HELD):
        if not f.exists():
            print(f"ERROR: binding frame missing: {f}", file=sys.stderr)
            return 1
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    im87 = Image.open(F_EMPTY).convert("RGB").crop((0, 0, W, H))
    im47 = Image.open(F_LIVE).convert("RGB").crop((0, 0, W, H))
    a87 = np.array(im87, dtype=np.int16)
    a48 = np.array(Image.open(F_SEARCH_HELD).convert("RGB").crop((0, 0, W, H)), dtype=np.int16)

    # sanity: the anchors still hold on the real frames
    assert tuple(a87[88, 200]) == (110, 80, 120), "scout bar moved"
    assert tuple(a87[251, 300]) == (42, 95, 170), "manager bar moved"
    assert (a87[150, 330:340] == 255).all(), "players-found interior not white"

    body = a87.copy()

    # 1) re-stripe the six capability value cells (lift the baked "NO" ink; the
    #    scene redraws NO/YES live). The striped track pattern is constant along
    #    x, so each cell row copies the track's own clean column block.
    for side, (cx, cw) in CAP_CELLS.items():
        sx, sw = STRIPE_SRC[side]
        for top in CAP_ROWS:
            clean = body[top : top + CAP_CELL_H, sx : sx + sw]
            assert len(np.unique(clean.reshape(-1, 3), axis=0)) <= 3, "stripe src has ink"
            reps = int(np.ceil(cw / sw))
            body[top : top + CAP_CELL_H, cx : cx + cw] = np.tile(clean, (1, reps, 1))[:, :cw]

    # 2) white out the PLAYERS FOUND interior (the message is a live state)
    px, py, pw, ph = PF_INTERIOR
    body[py : py + ph, px : px + pw] = 255

    body_im = Image.fromarray(body.astype(np.uint8)).crop((0, BODY_Y, W, H))
    body_im.save(OUT_DIR / "youth_body.png")
    print(f"wrote youth_body.png ({body_im.width}x{body_im.height}) from {F_EMPTY.name}")

    # 3) sprites cut verbatim from the live frame
    led_avail = cut(im47, [LED_COLS["left"], LED_ROWS[0], LED_W, LED_H])  # HANDLING avail
    led_lit = cut(im47, [LED_COLS["left"], LED_ROWS[1], LED_W, LED_H])  # DRIBBLING lit
    led_avail.save(OUT_DIR / "led_avail.png")
    led_lit.save(OUT_DIR / "led_lit.png")
    cut(im47, SEARCH_BTN).save(OUT_DIR / "search_on.png")
    cut(im47, PARAM_BTN).save(OUT_DIR / "plaq_param_off.png")
    cut(im47, RATING_BTN).save(OUT_DIR / "plaq_rating_on.png")
    # Star cells: the ORIGINAL alternates TWO star sprites along the row (cells
    # 1/3/5 = variant A, cells 2/4 = variant B — pixel-verified on frame 047's
    # scout row AND manager row; a uniform sprite diffs on every even cell).
    # Cut both variants per bar colour + the manager row's half star.
    sx, sy, pitch = SCOUT_STARS["x0"], SCOUT_STARS["y"], SCOUT_STARS["pitch"]
    cut(im47, [sx, sy, pitch, 11]).save(OUT_DIR / "star_a_purple.png")
    cut(im47, [sx + pitch, sy, pitch, 11]).save(OUT_DIR / "star_b_purple.png")
    mx, my = MGR_STARS["x0"], MGR_STARS["y"]
    cut(im47, [mx, my, pitch, 11]).save(OUT_DIR / "star_a_blue.png")
    cut(im47, [mx + pitch, my, pitch, 11]).save(OUT_DIR / "star_b_blue.png")
    # The HALF glyphs are NOT cut here any more: there are four of them (two parities x
    # two bar colours) and each has its own witness frame.
    # -> tools/re/build_youth_star_halves_from_frames.py

    # 4) held-state ring sprites, cut VERBATIM at the exact frame-diff bounds
    #    (048 vs 047 = red ring on SEARCH; 088/089 vs 087 = white rings on
    #    RATING / RETURN). Sprites carry the ring + the identical interior, so
    #    overdraw reproduces the frame exactly.
    im48 = Image.open(F_SEARCH_HELD).convert("RGB").crop((0, 0, W, H))
    im88 = Image.open(F_RATING_HELD).convert("RGB").crop((0, 0, W, H))
    im89 = Image.open(F_RETURN_HELD).convert("RGB").crop((0, 0, W, H))
    ring_boxes = {
        "search_held": [247, 189, 65, 29],  # 048 diff y189..217 x247..311
        "rating_held": [489, 286, 138, 25],  # 088 diff y286..310 x489..626
        "return_held": [513, 426, 116, 29],  # 089 diff y426..454 x513..628
    }
    cut(im48, ring_boxes["search_held"]).save(OUT_DIR / "search_held.png")
    cut(im88, ring_boxes["rating_held"]).save(OUT_DIR / "rating_held.png")
    cut(im89, ring_boxes["return_held"]).save(OUT_DIR / "return_held.png")
    print("wrote led/search/plaque/star/ring sprites (cut from frames)")

    d = np.abs(a48 - np.array(im47, dtype=np.int16)).max(axis=2) > 12
    d[:BODY_Y] = False
    ys, xs = np.nonzero(d)
    print(f"SEARCH held ring check: box y{ys.min()}..{ys.max()} x{xs.min()}..{xs.max()}")

    # 5) ink metrics off the game-font atlases (staff precedent), for the text
    #    the live layer redraws. proman8 @ native 11 = values/names/count face
    #    (the frame's 7x7 'N' matches its atlas bitmap exactly); proman10 @
    #    native 10 = the PLAYERS FOUND message face (frame 'e' 6x7 matches its
    #    atlas; proman8's lowercase does NOT match the message glyphs).
    fnt_dir = ROOT / "app/art/fonts"
    chars = set("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789.' ")
    metrics: dict[str, dict] = {}
    for face in ("proman8", "proman10"):
        atlas = np.array(Image.open(fnt_dir / f"{face}.png").convert("L"))
        m = {}
        for line in (fnt_dir / f"{face}.fnt").read_text().splitlines():
            if not line.startswith("char id="):
                continue
            kv = dict(p.split("=") for p in line.split() if "=" in p)
            ch = chr(int(kv["id"]))
            if ch not in chars:
                continue
            gx, gy = int(kv["x"]), int(kv["y"])
            gw, gh = int(kv["width"]), int(kv["height"])
            cell = atlas[gy : gy + gh, gx : gx + gw]
            cols = np.where(cell.max(axis=0) > 0)[0]
            ink_lo, ink_hi = (int(cols.min()), int(cols.max())) if cols.size else (0, gw - 1)
            m[ch] = [int(kv["xadvance"]), ink_lo, ink_hi]
        metrics[face] = m

    if os.environ.get("PM98_YOUTH_DEBUG"):
        dbg = im87.copy()
        dd = ImageDraw.Draw(dbg)
        for r in (SCOUT_BAR, MGR_BAR, SEARCH_BTN, PARAM_BTN, RATING_BTN, RETURN_BTN, PF_INTERIOR):
            dd.rectangle([r[0], r[1], r[0] + r[2], r[1] + r[3]], outline=(0, 255, 0))
        for side, (cx, cw) in CAP_CELLS.items():
            for top in CAP_ROWS:
                dd.rectangle([cx, top, cx + cw, top + CAP_CELL_H], outline=(255, 0, 255))
        for col in LED_COLS.values():
            for row in LED_ROWS:
                dd.rectangle([col, row, col + LED_W, row + LED_H], outline=(0, 200, 255))
        dbg.save(DEBUG_PNG)
        print(f"wrote {DEBUG_PNG.name} (debug)")

    spec = {
        "binding_frames": {
            "empty": F_EMPTY.name,
            "live": F_LIVE.name,
            "search_held": F_SEARCH_HELD.name,
            "rating_held": F_RATING_HELD.name,
            "return_held": F_RETURN_HELD.name,
        },
        "note": "YOUTH TEAM; PMChrome.draw_header draws the barra live; "
        "YouthScreen.gd draws the live layers over youth_body.png.",
        "size": [W, H],
        "body_y": BODY_Y,
        "scout_bar": SCOUT_BAR,
        "scout_name_xy": SCOUT_NAME_XY,
        "scout_stars": SCOUT_STARS,
        "cap_order": CAP_ORDER,
        "cap_rows": CAP_ROWS,
        "cap_cells": CAP_CELLS,
        "cap_cell_h": CAP_CELL_H,
        "cap_value_cx": CAP_VALUE_CX,
        "led_rows": LED_ROWS,
        "led_cols": LED_COLS,
        "led_size": [LED_W, LED_H],
        "buttons": {
            "search": SEARCH_BTN,
            "parameters": PARAM_BTN,
            "rating": RATING_BTN,
            "return": RETURN_BTN,
        },
        "ring": {"pad": RING_PAD, "boxes": ring_boxes, "white": [255, 255, 255]},
        "pf_interior": PF_INTERIOR,
        "pf_msg_no_scout": PF_MSG_NO_SCOUT,
        "pf_msg_searching": PF_MSG_SEARCHING,
        "pf_msg_anchor": PF_MSG_ANCHOR,
        "mgr_bar": MGR_BAR,
        "mgr_name_xy": MGR_NAME_XY,
        "mgr_stars": MGR_STARS,
        "count_xy": COUNT_XY,
        "rows": {
            "y0": ROW0_Y,
            "pitch": ROW_PITCH,
            "h": ROW_H,
            "count": ROW_COUNT,
            "text_x": ROW_TEXT_X,
            "col_cx": COL_CX,
        },
        "ink": INK,
        "font_metrics": metrics,
        # the witnessed run-3 state, transcribed from frame 047 (SOURCE, not
        # invented) — the parity oracle's fixture.
        "ref_live_state": {
            "scout": {"name": "P. Mitchell", "stars": 5.0},
            "manager": {"name": "G. Keeping", "stars": 3.5},
            "player_count": 3,
            "capabilities_yes": True,
            "leds_lit": ["DRIBBLING", "PASSING", "SHOOTING"],
            "mode": "rating",
            "searching": True,
        },
    }
    OUT_JSON.write_text(json.dumps(spec, indent=2) + "\n")
    print(f"wrote {OUT_JSON.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
