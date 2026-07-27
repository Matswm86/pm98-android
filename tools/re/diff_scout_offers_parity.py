#!/usr/bin/env python3
"""Compare SCOUT/OFFERS GL shots vs witnesses with per-state masks.

Render the shots first:
  PM98_SHOT_DIR=/tmp/pm98shots ~/godot462 --path app -s tests/shot_scout_verify.gd
  PM98_SHOT_DIR=/tmp/pm98shots ~/godot462 --path app -s tests/shot_offers_verify.gd
  PM98_SHOT_DIR=/tmp/pm98shots python3 tools/re/diff_scout_offers_parity.py

Masks (documented in docs/re/scout_screen_re.md + offers_map_re.md):
  barra (live career text, y<62) -- every state;
  bold list-name faces + club title + years digit glyphs + money faces +
  strip/dropdown texts -- the original's bold/outlined rasters are absent from
  the extracted .fnt bank (the goalscorers residual class, #11 follow-up);
  kit panel on non-baked states -- nano-kit fallback (the game's own art,
  positions exact; panel13 patches exist only for the frame-013 Premier set);
  stars column (offers) -- the rating mapping is un-RE'd (FICHA precedent);
  DOOR (2026-07-26) -- the two recessed segments of the bottom bar, where this
  port prints the label for the OURS panel. That is port-only surface and the
  ONLY such surface on this screen; `tools/re/diff_scout_bar_parity.py` bounds
  it (the original draws nothing there in any witness, and the band overlaps
  none of its controls). It is a DECLARED bucket, not a hidden mask.
All chrome, sprites, digit grammar, scroll geometry, row furniture, flags,
camrols, LEDs, dims and layouts verify to 0px (2026-07-18)."""
import os
import sys
import numpy as np
from PIL import Image

SH = os.environ.get("PM98_SHOT_DIR", "/tmp/pm98shots")
import pathlib
ROOT = pathlib.Path(__file__).resolve().parents[2]
WD = str(ROOT / "screenshots/wine-captures-2026-07-18-goalscorers")
RD = str(ROOT / "screenshots/original-walkthrough-2026-07-02")

BARRA = (0, 0, 640, 62)

def load(p):
    return np.array(Image.open(p).convert("RGB"))[:, :640]

def diff(shot, wit, masks, tag):
    a = load(f"{SH}/{shot}")
    b = load(wit)
    d = np.any(a != b, axis=2)
    for (x0, y0, x1, y1) in masks:
        d[y0:y1, x0:x1] = False
    n = int(d.sum())
    print(f"{tag}: {n} px diff")
    if n:
        ys, xs = np.where(d)
        # cluster report
        print(f"   bbox x{xs.min()}..{xs.max()} y{ys.min()}..{ys.max()}")
        rows = {}
        for y, x in zip(ys, xs):
            rows.setdefault(y // 16 * 16, []).append(x)
        for ry in sorted(rows)[:12]:
            xs2 = rows[ry]
            print(f"   band y{ry}: x{min(xs2)}..{max(xs2)} n={len(xs2)}")
        # save diff overlay
        ov = b.copy(); ov[d] = (255, 0, 255)
        Image.fromarray(ov).save(f"{SH}/diff_{shot}")
    return n

total = 0
# ---- SCOUT ----
# Face-level masks (documented, insurance-modal precedent — the original's
# strip/dropdown/money faces are rasters the app's .fnt bank lacks):
STRIP_NAME = (62, 88, 141, 110)     # white outlined name on the plate
STRIP_WAGE = (242, 88, 302, 110)    # white outlined wage value
DROP_TEXT = (132, 131, 255, 147)    # dropdown value interior
MONEY = (280, 297, 424, 424)        # FEE + WAGE cell interiors (list)
NAMECOL = (44, 297, 158, 424)       # bold list-name face (goalscorers residual class)
YEARS1 = (424, 297, 447, 424)       # years digit glyphs (same bold face; "1"s + fills verified)
YEARS2 = (453, 297, 468, 424)
# The DECLARED port-only band: the bottom bar's two recessed segments, x40..449 y445..456
# inclusive (ScoutScreen.EXTRA_SEG_A / EXTRA_SEG_B). Bounded by diff_scout_bar_parity.py.
DOOR = (40, 445, 450, 457)
total += diff("shot_scout_noscout.png", f"{WD}/43_scout.png", [BARRA], "scout noscout vs 43")
total += diff("shot_scout_idle.png", f"{WD}/61_scout_with_scout.png",
              [BARRA, STRIP_NAME, STRIP_WAGE, DOOR], "scout idle vs 61")
total += diff("shot_scout_premier.png", f"{WD}/63_premier_checked.png",
              [BARRA, STRIP_NAME, STRIP_WAGE, DOOR], "scout premier vs 63")
total += diff("shot_scout_position.png", f"{WD}/67_pos_enabled.png",
              [BARRA, STRIP_NAME, STRIP_WAGE, DROP_TEXT, DOOR], "scout position vs 67")
total += diff("shot_scout_searching.png", f"{WD}/68_results3.png",
              [BARRA, STRIP_NAME, STRIP_WAGE, DROP_TEXT, DOOR], "scout searching vs 68")
total += diff("shot_scout_results.png", f"{WD}/81_scout_found2.png",
              [BARRA, STRIP_NAME, STRIP_WAGE, DROP_TEXT, MONEY, NAMECOL, YEARS1, YEARS2, DOOR],
              "scout results vs 81")

# ---- OFFERS ----
STARS_COL = (485, 100, 560, 335)
# The kit panel used to be masked WHOLE. It is now masked CELL BY CELL: the panel's
# chrome, its country title and the picked-club label are gated at 0 px (2026-07-27 --
# the grid order was alphabetical where the original uses the ARCHIVE's own record
# order, and both texts were the wrong font/pen). What stays masked is the 20 kit
# SPRITE rects, where the original casts a grey shadow/bevel around each nano kit that
# this port does not draw -- the same un-reversed pass as the knockout 48x64 bevel
# (offers_map_re.md "The kit panel", knockout_views_re.md "The outline pass").
def _kit_cells():
    out = []
    for i in range(20):
        c = i % 10
        x = 13 - 1 + (c * 95) // 3
        y = [368, 405][i // 10] - 2
        out.append((x, y, x + 26, y + 36))
    return out

KIT_CELLS = _kit_cells()
KIT_PANEL = (10, 338, 328, 464)     # England panel only -- its own open question below
STRIP_TXT = (60, 306, 280, 325)     # strip country name (outlined face)
ONAMES = (375, 104, 484, 332)       # bold list-name face (same residual class)
OTITLE = (420, 78, 550, 96)         # club title (same bold family)
total += diff("shot_offers_resting.png", f"{WD}/44_offers_map.png", [BARRA], "offers resting vs 44")
total += diff("shot_offers_spain.png", f"{WD}/45_offers_country.png",
              [BARRA, STRIP_TXT] + KIT_CELLS, "offers spain vs 45 (kit sprites masked)")
total += diff("shot_offers_barca.png", f"{WD}/46_offers_club.png",
              [BARRA, STARS_COL, ONAMES, OTITLE] + KIT_CELLS, "offers barca vs 46 (kit sprites masked)")
total += diff("shot_offers_blackpool.png", f"{RD}/100_164712.png",
              [BARRA, STARS_COL, (8, 336, 330, 470), ONAMES, OTITLE], "offers blackpool vs 100 (kit panel masked)")
print(f"\nTOTAL: {total}")
raise SystemExit(0 if total == 0 else 1)
