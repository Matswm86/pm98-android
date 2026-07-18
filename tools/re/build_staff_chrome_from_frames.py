#!/usr/bin/env python3
"""CLUB PERSONNEL (EMPLEADOS / staff) screen chrome, frame-baked from the real
MANAGER.EXE walkthrough, following the PreseasonScreen / Directiva / Finance
frame-bake precedent (cut the original pixels 1:1, keep every static label /
portrait / button, expose the dynamic staff-value cells so the scene redraws
live values on top).

Binding frame (ground truth, owned game frames):
  screenshots/original-walkthrough-2026-07-02/121_154736.png
      the clean CLUB PERSONNEL screen (run1 15:47:36, Man Utd / MWM, preseason).
      Layout: TRAINING STAFF panel = 2 cols x 3 rows of skill trainers
      (HANDLING / PASSING / DRIBBLING / HEADING / TACKLING / SHOOTING), each a
      blue skill label over a colour-coded name bar (name + gold half-stars) with
      a red WAGE / £amount block; below it seven role cards laid out MIRRORED
      left/right with the role portrait on the OUTER edge —
        left  col: PHYSIOTHERAPIST, ASSISTANT MANAGER, YOUTH TEAM MANAGER, GROUNDSMAN
        right col: PSYCHOLOGIST,    SCOUT,             YOUTH TEAM SCOUT
      (left cards: name-bar left / WAGE right; right cards mirror it) plus the
      SIGN / SACK / RETURN buttons. Hire overlay witnessed in frames 113-120
      (per-role candidate list) — see docs/re/staff_re.md.

Outputs:
  app/art/screens/staff/personnel_body.png   640x(480-BODY_Y), drawn 1:1 at (0,BODY_Y)
  app/art/screens/staff/personnel_chrome.json geometry (measured slot rects),
                                              frame-sampled inks, and the WITNESSED
                                              reference staff (13 slots) transcribed
                                              from frame 121 (source, not invented).
  app/art/screens/staff/_debug_slots.png      debug: measured rects boxed on the frame

Doctrine (pm98_stay_true_to_original): the PNG is the real frame's pixels below the
barra. The header (club/manager plaque + CLUB PERSONNEL title + calendar + phase
band) is NOT baked — PMChrome.draw_header draws it live over the top, so it tracks
the real career. Slot rects are MEASURED off the frame (cross-checked against a
structural colour-bar auto-detector, see detect_bars); the scene draws each slot's
{name, half-stars, wage} from the personnel data at these rects, blanking the baked
cell first when live data replaces the witnessed reference.
"""

from __future__ import annotations

import json
import os
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
FRAME = ROOT / "screenshots/original-walkthrough-2026-07-02/121_154736.png"
OUT_DIR = ROOT / "app/art/screens/staff"
OUT_PNG = OUT_DIR / "personnel_body.png"
OUT_JSON = OUT_DIR / "personnel_chrome.json"
DEBUG_PNG = OUT_DIR / "_debug_slots.png"

W, H = 640, 480
BODY_Y = 58  # bake below the header barra (PMChrome draws y0..~56)


# ---- MEASURED slot geometry (native 640x480, off frame 121) ----------------
# Each slot: bar rect [x,y,w,h] (the colour name bar), kind (train/role), mirror
# (right role cards draw WAGE left / name-bar right), and the WAGE block anchors.
# Training rows share y 113/148/183; role rows y 252/316/378/440. Left bars x37
# (training) / x88 (role cards, portrait occupies x0..80); right bars x349
# (training) / x415 (role cards). Bar height 14.
def _row(x, y, w, kind, mirror):
    return {"bar": [x, y, w, 14], "kind": kind, "mirror": mirror}


SLOTS = {
    # TRAINING STAFF grid (wage always to the RIGHT of the bar in this panel). Bar
    # extents measured off the pristine render (portrait-safe): L x64 / R x343, w177.
    "HANDLING": _row(64, 114, 177, "train", False),
    "PASSING": _row(343, 114, 177, "train", False),
    "DRIBBLING": _row(64, 149, 177, "train", False),
    "HEADING": _row(343, 149, 177, "train", False),
    "TACKLING": _row(64, 184, 177, "train", False),
    "SHOOTING": _row(343, 184, 177, "train", False),
    # role cards (mirror right col: WAGE left / name-bar right / portrait outer edge)
    "PHYSIOTHERAPIST": _row(80, 252, 137, "role", False),
    "PSYCHOLOGIST": _row(415, 252, 167, "role", True),
    "ASSISTANT_MANAGER": _row(80, 316, 137, "role", False),
    "SCOUT": _row(415, 316, 167, "role", True),
    "YOUTH_TEAM_MANAGER": _row(80, 378, 137, "role", False),
    "YOUTH_TEAM_SCOUT": _row(415, 378, 167, "role", True),
    "GROUNDSMAN": _row(80, 440, 137, "role", False),
}

# display label for the role bars (the black label bar is baked; this is the app id
# -> witnessed screen wording, for docs/hire-overlay reuse)
LABELS = {
    "HANDLING": "HANDLING",
    "PASSING": "PASSING",
    "DRIBBLING": "DRIBBLING",
    "HEADING": "HEADING",
    "TACKLING": "TACKLING",
    "SHOOTING": "SHOOTING",
    "PHYSIOTHERAPIST": "PHYSIOTHERAPIST",
    "PSYCHOLOGIST": "PSYCHOLOGIST",
    "ASSISTANT_MANAGER": "ASSISTANT MANAGER",
    "SCOUT": "SCOUT",
    "YOUTH_TEAM_MANAGER": "YOUTH TEAM MANAGER",
    "YOUTH_TEAM_SCOUT": "YOUTH TEAM SCOUT",
    "GROUNDSMAN": "GROUNDSMAN",
}

# WITNESSED reference staff, transcribed pixel-by-pixel from frame 121 (SOURCE — the
# real game's Man Utd backroom on 1 Aug 1997; NOT invented). stars 0..5 in 0.5 steps
# (gold half-star = .5). The default fixture + the parity oracle.
REF_STAFF = {
    "HANDLING": {"name": "A. Padmore", "stars": 3.0, "wage": 17000},
    "PASSING": {"name": "D. Gledhill", "stars": 4.5, "wage": 34000},
    "DRIBBLING": {"name": "S. Merrick", "stars": 5.0, "wage": 47000},
    "HEADING": {"name": "A. Mitchell", "stars": 3.0, "wage": 16000},
    # 3.5 + lowercase b re-verified vs frames 103/105/121 2026-07-18 (an earlier
    # transcription said 4.5 "O'Brian" — wrong; APELLIDO.30 row is "O'brian").
    "TACKLING": {"name": "T. O'brian", "stars": 3.5, "wage": 21000},
    "SHOOTING": {"name": "T. Alan", "stars": 4.5, "wage": 33000},
    "PHYSIOTHERAPIST": {"name": "P. Gelbier", "stars": 5.0, "wage": 45000},
    "PSYCHOLOGIST": {"name": "J. Bodin", "stars": 4.5, "wage": 15000},
    "ASSISTANT_MANAGER": {"name": "A. Leigh", "stars": 4.0, "wage": 16000},
    "SCOUT": {"name": "K. Hatch", "stars": 4.5, "wage": 45000},
    "YOUTH_TEAM_MANAGER": {"name": "D. Read", "stars": 3.5, "wage": 21000},
    "YOUTH_TEAM_SCOUT": {"name": "W. Sugar", "stars": 5.0, "wage": 36000},
    "GROUNDSMAN": {"name": "G. Debnam", "stars": 4.5, "wage": 4000},
}

# bottom-centre buttons + the RETURN control (measured off frame 121)
BUTTONS = {
    "sign": [355, 415, 130, 24],
    "sack": [355, 447, 130, 24],
    "return": [515, 439, 118, 24],
}

# frame-sampled inks
INK = {
    "name": [255, 255, 255],  # white staff name inside the colour bar
    "wage_label": [200, 0, 0],  # red "WAGE"
    "wage_amount": [0, 0, 0],  # black £amount
    "star_on": [255, 210, 40],  # gold star
}


def detect_bars(a: np.ndarray) -> list[tuple[int, int, int, int]]:
    """Structural cross-check: dense (fill>=0.45, >=90px) coloured horizontal blocks
    per column. Prints so a geometry drift vs the measured SLOTS is visible."""
    mx = a.max(axis=2)
    mn = a.min(axis=2)
    colored = ((mx - mn) > 45) & (mx > 70)
    out = []
    for cx0, cx1 in ((76, 320), (334, 596)):
        cur = None
        for y in range(70, 472):
            seg = colored[y, cx0:cx1]
            idx = np.nonzero(seg)[0]
            wide = (
                idx.size
                and (idx.max() - idx.min() >= 90)
                and seg[idx.min() : idx.max() + 1].mean() >= 0.45
            )
            if wide:
                lo, hi = cx0 + int(idx.min()), cx0 + int(idx.max()) + 1
                if cur and y - cur[3] <= 1:
                    cur = [min(cur[0], lo), cur[1], max(cur[2], hi), y]
                else:
                    if cur:
                        out.append(tuple(cur))
                    cur = [lo, y, hi, y]
            elif cur:
                out.append(tuple(cur))
                cur = None
        if cur:
            out.append(tuple(cur))
    return [b for b in out if b[3] - b[1] >= 5]


def main() -> int:
    if not FRAME.exists():
        print(f"ERROR: binding frame missing: {FRAME}", file=sys.stderr)
        return 1
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    im = Image.open(FRAME).convert("RGB").crop((0, 0, W, H))
    a = np.array(im, dtype=np.int16)

    print("structural bar cross-check (x0,y0,x1,y1):")
    for b in detect_bars(a):
        print(f"  {b}  col@left={tuple(int(v) for v in a[(b[1] + b[3]) // 2, b[0] + 3])}")

    # build the JSON slot table with measured rects + per-slot bar colour + anchors
    slots = {}
    for key, s in SLOTS.items():
        bx, by, bw, bh = s["bar"]
        # representative bar colour for the live-overlay repaint: mean of the bar's
        # top strip excluding the white name text, gold stars and near-black shadow
        # (the bars are top-bright / bottom-dark; the top strip reads the hue best)
        patch = a[by + 1 : by + 5, bx + 2 : bx + bw - 2].reshape(-1, 3)
        pr, pg, pb = patch[:, 0], patch[:, 1], patch[:, 2]
        gold = (pr > 190) & (pg > 150) & (pb < 100)
        white = patch.sum(axis=1) > 640
        black = patch.sum(axis=1) < 60
        keep = ~(gold | white | black)
        sel = patch[keep] if keep.any() else patch
        bar_color = [int(round(v)) for v in sel.mean(axis=0)]
        # The red "WAGE" label is baked static; the scene only redraws the £amount.
        # Frame-121 value bboxes (all 13 measured 2026-07-16): the amounts are CENTERED
        # in their cell, NOT right-aligned — e.g. role-L £45,000 x241..291 / £16,000
        # x242..289 / £4,000 x245..287 all share cx≈266 while their right edges differ;
        # trainer-R glyph runs (£34,000 x541..591, £16,000 x542..589) share cx≈566.
        # Every wage face is the SAME game font (proman8 @ native 11pt): the frame's
        # per-row ink profile matches our render row-for-row. wage_cell = the rect to
        # blank for vacant/overdraw; it must NOT touch the baked cell underline (the
        # 2px black rule at trainer y132/... and role y270..271 — value rows only).
        if s["kind"] == "train":
            wage_top = by + 8  # value rows by+8..by+15
            if bx >= 320:  # trainer right column
                wage_cx = 566
                wage_cell = [522, by + 6, 86, 12]
            else:  # trainer left column
                wage_cx = 287
                wage_cell = [242, by + 6, 87, 12]
        else:
            row = (by - 252) // 62  # role rows: cells y250 + 63*row
            cell_y = 250 + 63 * row
            wage_top = cell_y + 11
            # blank the VALUE rows only (cell_y+10..+19): the red WAGE label is baked
            # in the same white cell above the amount (rows cell_y..+9) and the vacant
            # original keeps it (frame 115), as does the underline at cell_y+20..21.
            if s["mirror"]:  # role right column
                wage_cx = 374
                wage_cell = [336, cell_y + 10, 78, 10]
            else:  # role left column
                wage_cx = 266
                wage_cell = [218, cell_y + 10, 91, 10]
        slots[key] = {
            "label": LABELS[key],
            "kind": s["kind"],
            "mirror": s["mirror"],
            "bar": [bx, by, bw, bh],
            "bar_color": bar_color,
            "name_x": bx + 6,
            "name_y": by,
            "stars_right": bx + bw - 4,
            "stars_y": by + 1,
            "wage_cx": wage_cx,
            "wage_top": wage_top,
            "wage_cell": wage_cell,
        }

    # Wage-face ink metrics: the original centres each amount's INK box (not the
    # advance box) in its cell — frame 121: £45,000 ink x241..291 centre 266.0,
    # £16,000 ink x242..289 centre 265.5, same cx. proman8's glyph cells carry
    # per-char blank columns (e.g. '£' inks at col 2), so the scene needs the real
    # ink insets per char: {ch: [xadvance, ink_lo, ink_hi]} measured off the atlas.
    fnt_dir = ROOT / "app/art/fonts"
    atlas = np.array(Image.open(fnt_dir / "proman8.png").convert("L"))
    metrics = {}
    for line in (fnt_dir / "proman8.fnt").read_text().splitlines():
        if not line.startswith("char id="):
            continue
        kv = dict(p.split("=") for p in line.split() if "=" in p)
        ch = chr(int(kv["id"]))
        if ch not in "£,0123456789":
            continue
        gx, gy = int(kv["x"]), int(kv["y"])
        gw, gh = int(kv["width"]), int(kv["height"])
        cell = atlas[gy : gy + gh, gx : gx + gw]
        cols = np.where(cell.max(axis=0) > 0)[0]
        ink_lo, ink_hi = (int(cols.min()), int(cols.max())) if cols.size else (0, gw - 1)
        metrics[ch] = [int(kv["xadvance"]), ink_lo, ink_hi]
    print("wage-face ink metrics:", metrics)

    body = im.crop((0, BODY_Y, W, H))
    body.save(OUT_PNG)
    print(f"wrote {OUT_PNG.relative_to(ROOT)} ({body.width}x{body.height}) from {FRAME.name}")

    # optional debug overlay (PM98_STAFF_DEBUG=1) — kept OUT of the shipped art/ dir
    if os.environ.get("PM98_STAFF_DEBUG"):
        dbg = im.copy()
        dd = ImageDraw.Draw(dbg)
        for key, s in slots.items():
            bx, by, bw, bh = s["bar"]
            dd.rectangle([bx, by, bx + bw, by + bh], outline=(0, 255, 0))
            wc = s["wage_cell"]
            dd.rectangle([wc[0], wc[1], wc[0] + wc[2], wc[1] + wc[3]], outline=(255, 0, 255))
            dd.text((bx, by - 9), key[:5], fill=(255, 255, 0))
        for name, (x, y, w, h) in BUTTONS.items():
            dd.rectangle([x, y, x + w, y + h], outline=(0, 200, 255))
        dbg.save(DEBUG_PNG)
        print(f"wrote {DEBUG_PNG.relative_to(ROOT)} (debug)")

    spec = {
        "binding_frame": FRAME.name,
        "note": "CLUB PERSONNEL; PMChrome.draw_header draws the barra live; "
        "StaffScreen.gd draws 13 staff value cells over personnel_body.png "
        "at these rects.",
        "size": [W, H],
        "body_y": BODY_Y,
        "slots": slots,
        "slot_order": list(SLOTS.keys()),
        "buttons": BUTTONS,
        "ink": INK,
        "ref_staff": REF_STAFF,
        "wage_font_metrics": metrics,
    }
    OUT_JSON.write_text(json.dumps(spec, indent=2) + "\n")
    print(f"wrote {OUT_JSON.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
