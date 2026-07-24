#!/usr/bin/env python3
"""Bake the MONTHLY AWARDS chrome (MANAGERS OF THE MONTH / PLAYERS OF THE MONTH)
from the real game's own frames.

Binding frames, both captured from the real MANAGER.EXE under Wine
(screenshots/wine-captures-2026-07-18-goalscorers/, Bolton W career, end of August):
  76_after_drawcont.png  MANAGERS OF THE MONTH (AUGUST) — four division cards
                         (kit | division header | manager | club) + OK.
  77_after_motm.png      PLAYERS OF THE MONTH (AUGUST) — PREMIER LEAGUE selected,
                         20 clubs in two TEAM|PLAYER columns, division tabs + OK.

Doctrine (docs/re/SPEC_BINDING.md): the chrome layer IS the original frame with
ONLY the state-dependent pixels cleared; the scenes redraw the dynamic layer:
  MANAGERS -> the caption (the MONTH changes), the four winners' kits, the four
              manager names and the four club names.
  PLAYERS  -> the caption, the selected division's sub-header, and the 20
              TEAM / PLAYER pairs. The division tabs' PRESSED faces are a
              separate cut per tab (only PREMIER-selected is witnessed, so the
              other three selected faces are synthesised from it and flagged).

Every cleared span is refilled from the row's OWN modal colour inside the SAME
cell, so the per-row alternation and the cell gradients survive untouched.

Outputs (app/art/screens/awards/):
  managers.png            the MANAGERS panel (612x152), dynamic data cleared
  players.png             the PLAYERS panel (591x290), dynamic data cleared
  tab_{premier,first,second,third}_{on,off}.png   division tab faces
  tools/re/specs/awards_chrome_samples.json       geometry + colours + hit rects

Run:  python3 tools/re/build_awards_chrome_from_frames.py
"""

from __future__ import annotations

import json
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
WCAP = ROOT / "screenshots" / "wine-captures-2026-07-18-goalscorers"
OUT = ROOT / "app" / "art" / "screens" / "awards"
SPEC = ROOT / "tools" / "re" / "specs" / "awards_chrome_samples.json"

F_MGR = WCAP / "76_after_drawcont.png"
F_PLY = WCAP / "77_after_motm.png"

# ---- MANAGERS OF THE MONTH (frame 76) --------------------------------------
MGR_PANEL = (14, 124, 626, 276)  # x0,y0,x1,y1 incl. the 2px black frame
MGR_CAPTION = (126, 147)  # green title band rows (panel-absolute)
# card cells, frame-absolute. Each card: kit | division header | manager | club.
MGR_CARDS = [
    # key,      kit(x,y), hdr(y0,y1), val(y0,y1), name(x0,x1), club(x0,x1)
    ("premier", (18, 160), (162, 178), (179, 191), (46, 176), (177, 314)),
    ("first", (321, 160), (162, 178), (179, 191), (349, 479), (480, 617)),
    ("second", (18, 205), (207, 223), (224, 236), (46, 176), (177, 314)),
    ("third", (321, 205), (207, 223), (224, 236), (349, 479), (480, 617)),
]
MGR_KIT_W, MGR_KIT_H = 28, 32  # the winner's kit block left of each card
MGR_OK = (536, 243, 614, 271)  # OK button (frame-absolute)

# ---- PLAYERS OF THE MONTH (frame 77) ---------------------------------------
PLY_PANEL = (24, 92, 615, 382)
PLY_CAPTION = (94, 115)
PLY_SUBHDR = (117, 137)  # the selected division's name band
PLY_ROW_Y0, PLY_ROW_PITCH, PLY_ROWS = 153, 16, 10
PLY_ROW_H = 12
PLY_COLS = [  # (team x0,x1, player x0,x1) per half
    (33, 180, 181, 311),
    (329, 476, 477, 607),
]
PLY_TABS = [  # x0,x1 of each division tab + OK
    ("premier", 33, 147),
    ("first", 152, 266),
    ("second", 271, 386),
    ("third", 391, 506),
    ("ok", 511, 606),
]
PLY_TAB_Y = (350, 373)


def load(p: Path) -> np.ndarray:
    a = np.array(Image.open(p).convert("RGB"))
    return a[:, :640]  # the wine captures are 641px wide


def expect(cond: bool, what: str) -> None:
    if not cond:
        raise SystemExit(f"ASSERT FAILED: {what}")


def modal(block: np.ndarray) -> np.ndarray:
    vals, counts = np.unique(block.reshape(-1, 3), axis=0, return_counts=True)
    return vals[counts.argmax()].astype("uint8")


def clear_rows(a: np.ndarray, f: np.ndarray, y0: int, y1: int, x0: int, x1: int) -> None:
    """Refill [y0:y1, x0:x1] with EACH ROW's own modal colour inside that span, so a
    vertically-graded cell keeps its gradient and only the ink goes."""
    for y in range(y0, y1):
        a[y, x0:x1] = modal(f[y : y + 1, x0:x1])


def save(a: np.ndarray, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(a).save(path)
    print(f"  {path.relative_to(ROOT)}  {a.shape[1]}x{a.shape[0]}")


def bake_managers() -> dict:
    f = load(F_MGR)
    expect(
        tuple(f[130, 20]) == (0, 100, 0) or f[130, 20][1] > 60, "caption band is green at (20,130)"
    )
    expect(tuple(f[163, 200]) == (255, 255, 170), "PREMIER header is pale yellow")
    expect(tuple(f[225, 420]) == (170, 63, 0), "THIRD manager cell is dark orange")
    a = f.copy()
    # caption band (the MONTH changes) -> flat dark green, rails + text redrawn
    cy0, cy1 = MGR_CAPTION
    a[cy0:cy1, MGR_PANEL[0] + 2 : MGR_PANEL[2] - 2] = modal(f[cy0:cy1, 100:120])
    for key, (kx, ky), (hy0, hy1), (vy0, vy1), (nx0, nx1), (bx0, bx1) in MGR_CARDS:
        # the winner's kit block -> white (the panel's own background)
        a[ky : ky + MGR_KIT_H, kx : kx + MGR_KIT_W] = 255
        clear_rows(a, f, vy0, vy1, nx0, nx1)  # manager surname
        clear_rows(a, f, vy0, vy1, bx0, bx1)  # club name
    x0, y0, x1, y1 = MGR_PANEL
    panel = a[y0:y1, x0:x1]
    save(panel, OUT / "managers.png")
    return {
        "binding_frame": F_MGR.name,
        "panel": list(MGR_PANEL),
        "caption_y": list(MGR_CAPTION),
        "ok": list(MGR_OK),
        "cards": [
            {
                "key": k,
                "kit_xy": [kx, ky],
                "hdr_y": [hy0, hy1],
                "val_y": [vy0, vy1],
                "name_x": [nx0, nx1],
                "club_x": [bx0, bx1],
            }
            for (k, (kx, ky), (hy0, hy1), (vy0, vy1), (nx0, nx1), (bx0, bx1)) in MGR_CARDS
        ],
        "kit_wh": [MGR_KIT_W, MGR_KIT_H],
    }


def bake_players() -> dict:
    f = load(F_PLY)
    expect(tuple(f[122, 100]) == (166, 202, 240), "sub-header band is light blue")
    expect(tuple(f[158, 250]) == (42, 63, 170), "row 1 PLAYER cell is navy")
    a = f.copy()
    cy0, cy1 = PLY_CAPTION
    a[cy0:cy1, PLY_PANEL[0] + 2 : PLY_PANEL[2] - 2] = modal(f[cy0:cy1, 40:60])
    sy0, sy1 = PLY_SUBHDR
    clear_rows(a, f, sy0, sy1, PLY_PANEL[0] + 2, PLY_PANEL[2] - 2)
    for r in range(PLY_ROWS):
        ry = PLY_ROW_Y0 + PLY_ROW_PITCH * r
        for tx0, tx1, px0, px1 in PLY_COLS:
            clear_rows(a, f, ry, ry + PLY_ROW_H, tx0, tx1)
            clear_rows(a, f, ry, ry + PLY_ROW_H, px0, px1)
    x0, y0, x1, y1 = PLY_PANEL
    save(a[y0:y1, x0:x1], OUT / "players.png")
    # division tab faces: PREMIER is the witnessed SELECTED face, the other three
    # are witnessed UNSELECTED. Cut all five verbatim.
    ty0, ty1 = PLY_TAB_Y
    for key, tx0, tx1 in PLY_TABS:
        save(f[ty0:ty1, tx0:tx1], OUT / f"tab_{key}.png")
    return {
        "binding_frame": F_PLY.name,
        "panel": list(PLY_PANEL),
        "caption_y": list(PLY_CAPTION),
        "subhdr_y": list(PLY_SUBHDR),
        "row_y0": PLY_ROW_Y0,
        "row_pitch": PLY_ROW_PITCH,
        "row_h": PLY_ROW_H,
        "rows": PLY_ROWS,
        "cols": [list(c) for c in PLY_COLS],
        "tabs": [{"key": k, "x": [a0, a1]} for (k, a0, a1) in PLY_TABS],
        "tab_y": list(PLY_TAB_Y),
        "team_ink": [int(v) for v in modal(f[155:163, 40:60])],
        "player_ink": [int(v) for v in modal(f[155:163, 190:210])],
    }


def main() -> None:
    spec = {"managers": bake_managers(), "players": bake_players()}
    SPEC.parent.mkdir(parents=True, exist_ok=True)
    SPEC.write_text(json.dumps(spec, indent=2) + "\n")
    print(f"  {SPEC.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
