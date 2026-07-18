#!/usr/bin/env python3
"""Bake the PM98 OFFERS (map browse) screen chrome.

BINDING SOURCES (docs/re/offers_map_re.md; ALL frames 641px wide, crop
[:, :640]):
  screenshots/original-walkthrough-2026-07-02/
    098_164709.png  England + Premier League selected, empty list -> THE base
    099_164711.png  Second Division selected (button state donor)
    100_164712.png  Blackpool list: scroll slider + enabled down arrow + the
                    pressed-row black ring (Brabin)
  screenshots/wine-captures-2026-07-18-goalscorers/
    44_offers_map.png  Bolton career: donor for the SOLID Man Utd kit cell
                       (098 washes it as the managed club)

The left column (map / tabs / strip / kit panel) is pixel-identical to the
PRESEASON chrome (match 1.000) — OffersScreen reuses that machinery; this bake
keeps it in the frame so the resting state is 0px.

Output (app/art/screens/offers/):
  chrome.png       640x480 from 098: barra text interiors blanked (transfer
                   §C2 recipe), managed-club kit cell restored SOLID from 44
                   (the scene draws the checker wash on the LIVE managed club)
  btn_prem_sel / btn_prem_off / btn_first_off / btn_second_sel /
  btn_second_off / btn_third_off .png   division button faces (witnessed);
                   First/Third SELECTED faces are synthesized at draw time
                   (red-glow face + gold label) — documented, un-witnessed
  scroll_up_off / scroll_dn_on / scroll_dn_off / scroll_slider .png
  offers_chrome.json  geometry + sampled inks
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
RD = ROOT / "screenshots" / "original-walkthrough-2026-07-02"
WD = ROOT / "screenshots" / "wine-captures-2026-07-18-goalscorers"
OUT_DIR = ROOT / "app" / "art" / "screens" / "offers"

W, H = 640, 480

# barra live-text blanks (build_transfer_chrome_from_frames.py §C2 recipe)
MGR_BAND_FILL = (180, 200, 220)
CLUB_BAND_FILL = (80, 100, 120)
RP_TOP_FILL = (127, 159, 85)
RP_BOT_FILL = (85, 95, 0)
WHITE = (255, 255, 255)
BLANK_MGR = (0, 15, 108, 30)
BLANK_CLUB = (0, 33, 108, 48)
BLANK_CREST = (112, 14, 140, 47)
BLANK_SHEET_WD = (447, 17, 521, 26)
BLANK_SHEET_DAY = (447, 28, 521, 35)
BLANK_SHEET_MON = (447, 37, 521, 46)
BLANK_SHEET_YR = (447, 48, 521, 55)
BLANK_RP_TOP = (541, 15, 616, 30)
BLANK_RP_BOT = (541, 33, 624, 48)

# the managed club's kit cell — 098 (asdf/Man Utd) washes Man Utd at grid
# row 2 i=3 (kit blit x108,y405; witness diff y407..436 x108..131); restored
# from 44 (Bolton career) where it is solid. 44's own washed cell is Bolton at
# row 1 i=4 (x139,y368) — cut into the kits/washed bank for the live wash.
MU_CELL = (106, 403, 134, 439)
BOLTON_WASHED = (139, 368, 163, 400)   # 24x32 kit blit rect in 44

# division buttons: faces x362..479, tops y345/375/405/435, h 28 (witnessed
# inner-change zones y349..367/y409..427 x366..475 + border margins)
BTN_X0, BTN_X1 = 362, 480
BTN_TOPS = [345, 375, 405, 435]
BTN_H = 28

# right-list scrollbar column (x615..630); rows measured on 100:
# up arrow y105..120, slider y121..260 (借 borders), track plain y261..310,
# down arrow y311..326. Track for the slider formula = y121..310 (190 rows):
# floor(190*14/19) == the witnessed 140-row slider.
SB_X0, SB_X1 = 615, 630
UP_ROWS = (105, 121)
SLIDER_ROWS = (121, 261)
DN_ROWS = (311, 327)


def fill(a: np.ndarray, rgb, x0: int, y0: int, x1: int, y1: int) -> None:
    a[y0:y1, x0:x1] = np.array(rgb, dtype=a.dtype)


def main() -> int:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    a098 = np.array(Image.open(RD / "098_164709.png").convert("RGB"))[:, :W]
    a099 = np.array(Image.open(RD / "099_164711.png").convert("RGB"))[:, :W]
    a100 = np.array(Image.open(RD / "100_164712.png").convert("RGB"))[:, :W]
    a44 = np.array(Image.open(WD / "44_offers_map.png").convert("RGB"))[:, :W]

    # ---- chrome ------------------------------------------------------------
    chrome = a098.copy()
    x0, y0, x1, y1 = MU_CELL
    chrome[y0:y1, x0:x1] = a44[y0:y1, x0:x1]
    # witness-true washed Bolton kit -> the shared kits/washed bank (24x32)
    bx0, by0, bx1, by1 = BOLTON_WASHED
    Image.fromarray(a44[by0:by1, bx0:bx1]).save(
        ROOT / "app" / "art" / "kits" / "washed" / "59.png")
    fill(chrome, MGR_BAND_FILL, *BLANK_MGR)
    fill(chrome, CLUB_BAND_FILL, *BLANK_CLUB)
    fill(chrome, WHITE, *BLANK_CREST)
    for r in (BLANK_SHEET_WD, BLANK_SHEET_DAY, BLANK_SHEET_MON, BLANK_SHEET_YR):
        fill(chrome, WHITE, *r)
    fill(chrome, RP_TOP_FILL, *BLANK_RP_TOP)
    fill(chrome, RP_BOT_FILL, *BLANK_RP_BOT)
    Image.fromarray(chrome).save(OUT_DIR / "chrome.png")

    # ---- division button faces --------------------------------------------
    def btn(a: np.ndarray, i: int) -> np.ndarray:
        t = BTN_TOPS[i]
        return a[t:t + BTN_H, BTN_X0:BTN_X1]

    Image.fromarray(btn(a098, 0)).save(OUT_DIR / "btn_prem_sel.png")
    Image.fromarray(btn(a099, 0)).save(OUT_DIR / "btn_prem_off.png")
    Image.fromarray(btn(a098, 1)).save(OUT_DIR / "btn_first_off.png")
    Image.fromarray(btn(a099, 2)).save(OUT_DIR / "btn_second_sel.png")
    Image.fromarray(btn(a098, 2)).save(OUT_DIR / "btn_second_off.png")
    Image.fromarray(btn(a098, 3)).save(OUT_DIR / "btn_third_off.png")
    # sanity: the two selected faces really carry the red glow
    for nm in ("btn_prem_sel", "btn_second_sel"):
        f = np.array(Image.open(OUT_DIR / f"{nm}.png"))
        assert ((f[:, :, 0] > 150) & (f[:, :, 1] < 90)).sum() > 150, f"{nm}: no red glow"

    # First/Third SELECTED faces are UN-witnessed -> synthesized: the witnessed
    # Premier glow face with its label inpainted (per-row median of non-label
    # pixels), then the off-face's label glyphs stamped gold. Documented in
    # offers_map_re.md as pattern-derived.
    prem_sel = btn(a098, 0).copy()
    prem_off = btn(a099, 0)
    lab = prem_off.astype(int).sum(axis=2) > 420      # light label pixels
    glow = prem_sel.copy()
    for y in range(glow.shape[0]):
        good = glow[y][~lab[y]]
        if len(good):
            med = np.median(good, axis=0).astype(np.uint8)
            glow[y][lab[y]] = med
    for src_i, nm in ((1, "btn_first_sel"), (3, "btn_third_sel")):
        off = btn(a098, src_i)
        mask = off.astype(int).sum(axis=2) > 420
        mask[:4] = False
        mask[24:] = False          # keep the plated bevel rows un-stamped
        mask[:, :4] = False
        mask[:, 114:] = False
        sel = glow.copy()
        sel[mask] = (255, 223, 0)
        Image.fromarray(sel).save(OUT_DIR / f"{nm}.png")

    # the DIVISION-BUTTON-FREE backdrop (foreign country, witness 45): the
    # buttons zone cut from the wine capture
    a45 = np.array(Image.open(WD / "45_offers_country.png").convert("RGB"))[:, :W]
    Image.fromarray(a45[340:468, 358:484]).save(OUT_DIR / "no_buttons_bg.png")

    # ---- the populated-row strip (100 row 1, Preece) -----------------------
    # A populated row carries its own furniture the empty grid lacks: the
    # x562 name/AV separator, the camrol cell frame (x587..611 black edges)
    # and its border row treatment. Cut one row (y105..120) and clear the
    # dynamic ink (number/name/stars/AV digits) to the 240 fill; the camrol
    # cell is left as-is — the per-player camrol sprite covers it 1:1.
    strip = a100[105:121, 342:615].copy()
    for (cx0, cx1) in ((1, 37), (37, 143), (143, 220), (221, 245)):
        strip[1:13, cx0:cx1] = (240, 240, 240)
    Image.fromarray(strip).save(OUT_DIR / "row_strip.png")

    # ---- witnessed camrol cells (the ROL mini-pitch per posFine) -----------
    # The icons/camrol bank matched fine 9 100.0% but its fine-7/13 sprites
    # carry a plain dot where THIS list renders the outlined dot at a slightly
    # different anchor. Cut the witnessed cells (25x14 at x587) per fine from
    # BOTH list frames; a fine seen twice must cut identically (assert).
    import json as _json

    db = _json.loads((ROOT / "app" / "data" / "game_db.json").read_text())
    cam_dir = OUT_DIR / "camrol"
    cam_dir.mkdir(exist_ok=True)
    seen: dict[int, np.ndarray] = {}
    for frame, cid in ((a100, 82), (np.array(Image.open(
            WD / "46_offers_club.png").convert("RGB"))[:, :W], 1000)):
        club = next(c for c in db["clubs"] if c["id"] == cid)
        players = list(reversed(club["players"]))[:14]
        for i, p in enumerate(players):
            pf = int(p.get("posFine") or 0)
            if pf <= 0:
                continue
            cell = frame[105 + i * 16:119 + i * 16, 587:612]
            if pf in seen:
                assert (seen[pf] == cell).all(), f"camrol fine {pf} differs between rows"
            else:
                seen[pf] = cell
                Image.fromarray(cell).save(cam_dir / f"{pf:02d}.png")
    print(f"witnessed camrol fines: {sorted(seen)}")

    # ---- witnessed NON-NATIONAL number-cell flags (20x14 at x360, row top) --
    # 46: Anderson(r2)/Giovanni(r3)/Rivaldo(r13) = Brazil code 10 (all three
    # cut identically — asserted), Ciric(r12, top y281) = Yugoslavia code 58.
    a46 = np.array(Image.open(WD / "46_offers_club.png").convert("RGB"))[:, :W]
    fdir = OUT_DIR / "flag_mid"
    fdir.mkdir(exist_ok=True)
    br = a46[121:135, 360:380]
    assert (a46[137:151, 360:380] == br).all(), "Giovanni Brazil cut differs"
    assert (a46[297:311, 360:380] == br).all(), "Rivaldo Brazil cut differs"
    Image.fromarray(br).save(fdir / "10.png")
    Image.fromarray(a46[281:295, 360:380]).save(fdir / "58.png")

    # ---- the witnessed enlarged Spain flag plaque (45: border+flag, marker
    # (61,245) -> plaque (52,240)-(83,261)) ---------------------------------
    bdir = OUT_DIR / "flag_big"
    bdir.mkdir(exist_ok=True)
    Image.fromarray(a45[240:262, 52:84]).save(bdir / "22.png")

    # ---- scroll sprites ----------------------------------------------------
    Image.fromarray(a100[UP_ROWS[0]:UP_ROWS[1], SB_X0:SB_X1 + 1]).save(OUT_DIR / "scroll_up_off.png")
    Image.fromarray(a100[SLIDER_ROWS[0]:SLIDER_ROWS[1], SB_X0:SB_X1 + 1]).save(OUT_DIR / "scroll_slider.png")
    Image.fromarray(a100[DN_ROWS[0]:DN_ROWS[1], SB_X0:SB_X1 + 1]).save(OUT_DIR / "scroll_dn_on.png")
    Image.fromarray(a098[DN_ROWS[0]:DN_ROWS[1], SB_X0:SB_X1 + 1]).save(OUT_DIR / "scroll_dn_off.png")

    meta = {
        "row_box_x": [342, 586],
        "row_y0": 105,
        "row_pitch": 16,
        "n_rows": 14,
        "camrol_x": 587,
        "scroll_x": [SB_X0, SB_X1],
        "scroll_up_y": UP_ROWS[0],
        "scroll_dn_y": DN_ROWS[0],
        "scroll_track_y": [SLIDER_ROWS[0], 311],
        "title_cx": 485,
        "title_ink_y": 83,
        "btn_x": [BTN_X0, BTN_X1],
        "btn_tops": BTN_TOPS,
        "btn_h": BTN_H,
        "press_ring": "2px black rect on (342, row_top-1, 245, 16)",
        "inks": {
            "title_navy": [0, 0, 160],
            "num_navy": [0, 0, 128],
            "name_black": [0, 0, 0],
            "av_red": [212, 63, 0],
            "row_fill": [240, 240, 240],
            "row_border": [128, 128, 128],
            "label_under_grid": [120, 120, 160],
        },
        # row-1 witnessed ink anchors (100: "9 Preece"): number digit-centring
        # CX 354 (single "9" ink x351..356, "19" x350..359), name ink-left
        # x380, stars left-anchored x488 pitch 13, AV right ink edge 581.
        "num_cx": 354,
        "name_x": 380,
        "stars_x": 488,
        "av_right": 581,
    }
    (OUT_DIR / "offers_chrome.json").write_text(json.dumps(meta, indent=1))
    print(f"wrote {OUT_DIR}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
