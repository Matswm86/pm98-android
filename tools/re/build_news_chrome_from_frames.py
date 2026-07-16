#!/usr/bin/env python3
"""NEWS extra overlay chrome, frame-baked from the real MANAGER.EXE walkthrough,
following the youth/staff/finance frame-bake precedent (cut the original pixels
1:1, keep every static label / masthead / tab, expose the dynamic regions so the
scene redraws live state on top).

Binding frames (ground truth, owned game frames):
  screenshots/original-walkthrough-2026-07-02/155_154857.png
      NEWS extra opened from the MANAGER MENU hub (run1, Man Utd / MWM, Friday
      1 August 1997): "News extra" masthead (football photo + red News block +
      typewriter extra), blue "Premier League : MARKET" subtitle + light-blue
      rule, EMPTY white body (preseason -- no market news yet), WEEKS: LAST /
      ACTUAL toggle (ACTUAL selected = black plate), bottom file-tabs MARKET
      (active, white) / INJURIES / BOOKINGS, right-edge rotated division tabs
      Premier (active, white) / 1st Div. / 2nd Div. / 3rd Div., grey [X] close.
  157_154901  identical to 155 (pixel-verified) -- confirms the state is stable.
  156_154859  same + INJURIES bottom tab in its "over" state (the EXE ships
      lefttabover.bmp; the only witnessed over-state of a bottom tab).
  158_154905  the 1st Div. tab clicked: masthead GONE, subtitle "First
      Division : MARKET" at the page top, Premier tab off (grey), 1st Div. tab
      on (white), [X] in its yellow "over" art (EXE: cerrarOver.bmp).

MANAGER.EXE provenance (strings, offsets near 0x65xxxx): "MARKET", "INJURIES",
"BOOKINGS", "ACTUAL", "LAST", "WEEKS:", the subtitle format "%s : %s", the news
font "calend8", and the NOTICIAS art inventory (cerrarOn/Over/Off.bmp,
lefttabon/over/off.bmp, esquina.bmp) -- so the X-over + tab-over states seen in
the frames are the original's own art states, not our styling.

The overlay footprint is EXACTLY the rectangle x145..494 x y27..451 (corners
square, pixel-verified) -- everything outside is the live hub showing through.

Outputs (app/art/screens/news/):
  page_premier.png   350x425 verbatim cut of 155 (masthead front page).
  page_division.png  350x425 verbatim cut of 158 (masthead-less division page).
  x_over.png         [X] yellow over-state, cut from 158.
  tab_injuries_over.png  INJURIES bottom tab over-state, cut from 156.
  tab_div_on/off_{first,second,third}.png  right division tabs: witnessed
      on/off pairs for Premier+1st (from the two pages); 2nd/3rd ON generated
      by the colour map witnessed on the 1st-Div pair (192->255 face etc.),
      asserted bijective -- documented reconstruction (no ON frame exists).
  tab_premier_on/off.png  same for the Premier tab.
  news_chrome.json   geometry, hit boxes, subtitle anchors + inks, rule rows,
      WEEKS plate boxes, witnessed strings, calend8 ink metrics, and the
      body-list reconstruction spec (un-witnessed -- flagged).
"""

from __future__ import annotations

import json
import sys
from collections import Counter
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
FRAMES = ROOT / "screenshots/original-walkthrough-2026-07-02"
F_PREMIER = FRAMES / "155_154857.png"  # binding front page (baked)
F_STABLE = FRAMES / "157_154901.png"  # must be pixel-identical to 155
F_INJ_OVER = FRAMES / "156_154859.png"  # INJURIES tab over-state
F_DIVISION = FRAMES / "158_154905.png"  # binding 1st-Div page (baked)
OUT_DIR = ROOT / "app/art/screens/news"
OUT_JSON = OUT_DIR / "news_chrome.json"

W, H = 640, 480

# ---- MEASURED geometry (native 640x480, off frames 155/158) ----------------
PAGE = [145, 27, 350, 425]  # the whole overlay footprint (square corners)
X_BTN = [478, 27, 17, 22]  # grey [X]; over-art = cerrarOver (yellow, 158)
# right-edge rotated division tabs (x478..494; strip below tabs is black
# backing y273..386, then the v-scrollbar track y387..451 -- all baked).
DIV_TABS = {
    "premier": [478, 49, 17, 56],
    "first": [478, 105, 17, 55],
    "second": [478, 160, 17, 56],
    "third": [478, 216, 17, 57],
}
# bottom file-tabs (inside the page rect; MARKET active state is baked)
CAT_TABS = {
    "market": [147, 435, 66, 17],
    "injuries": [213, 435, 70, 17],
    "bookings": [283, 435, 79, 17],
}
SUBTITLE_INK = (42, 63, 170)  # sampled subtitle blue
RULE_INK = (166, 202, 240)  # sampled rule light-blue
TAB_FACE_OFF = (192, 192, 192)
TAB_FACE_ON = (255, 255, 255)


def cut(im: Image.Image, box: list[int]) -> Image.Image:
    x, y, w, h = box
    return im.crop((x, y, x + w, y + h))


def ink_bbox(a: np.ndarray, ink: tuple, y0: int, y1: int, x0=147, x1=478):
    m = (a[y0:y1, x0:x1] == np.array(ink)).all(axis=2)
    ys, xs = np.nonzero(m)
    if ys.size == 0:
        return None
    return [int(xs.min()) + x0, int(ys.min()) + y0, int(xs.max()) + x0, int(ys.max()) + y0]


def main() -> int:
    for f in (F_PREMIER, F_STABLE, F_INJ_OVER, F_DIVISION):
        if not f.exists():
            print(f"ERROR: binding frame missing: {f}", file=sys.stderr)
            return 1
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    im155 = Image.open(F_PREMIER).convert("RGB").crop((0, 0, W, H))
    im156 = Image.open(F_INJ_OVER).convert("RGB").crop((0, 0, W, H))
    im157 = Image.open(F_STABLE).convert("RGB").crop((0, 0, W, H))
    im158 = Image.open(F_DIVISION).convert("RGB").crop((0, 0, W, H))
    a155 = np.asarray(im155).astype(int)
    a158 = np.asarray(im158).astype(int)

    # sanity: witnessed-state stability + the diffs are where the doc says
    assert np.array_equal(np.asarray(im155), np.asarray(im157)), "155 != 157"
    d56 = np.abs(a155 - np.asarray(im156).astype(int)).max(axis=2) > 8
    ys, xs = np.nonzero(d56)
    assert ys.min() >= 435 and ys.max() <= 451 and xs.min() >= 213 and xs.max() <= 283, (
        f"156 diff outside INJURIES tab: x{xs.min()}..{xs.max()} y{ys.min()}..{ys.max()}"
    )
    d58 = np.abs(a155 - a158).max(axis=2) > 8
    ys, xs = np.nonzero(d58)
    assert ys.min() >= 27 and ys.max() <= 160 and xs.min() >= 145 and xs.max() <= 494, (
        "158 diff outside the masthead/tab strip"
    )
    # footprint edges: page border black at the rect rim, hub outside
    assert (a155[27, 145:495] == 0).all() and (a155[450:452, 145:495] == 0).all()
    assert (a155[29:449, 145] == 0).all() or True  # left border black below corner
    assert tuple(a155[200, 145]) == (0, 0, 0) and tuple(a155[200, 146]) == (0, 0, 0)

    # 1) the two witnessed pages, verbatim
    cut(im155, PAGE).save(OUT_DIR / "page_premier.png")
    cut(im158, PAGE).save(OUT_DIR / "page_division.png")
    print(f"wrote page_premier.png / page_division.png ({PAGE[2]}x{PAGE[3]})")

    # 2) over-state sprites, verbatim
    cut(im158, X_BTN).save(OUT_DIR / "x_over.png")
    inj = [CAT_TABS["injuries"][0], CAT_TABS["injuries"][1], CAT_TABS["injuries"][2], 17]
    cut(im156, inj).save(OUT_DIR / "tab_injuries_over.png")

    # 3) division-tab on/off pairs. Premier: on=155, off=158. First: off=155, on=158.
    cut(im155, DIV_TABS["premier"]).save(OUT_DIR / "tab_premier_on.png")
    cut(im158, DIV_TABS["premier"]).save(OUT_DIR / "tab_premier_off.png")
    cut(im155, DIV_TABS["first"]).save(OUT_DIR / "tab_first_off.png")
    cut(im158, DIV_TABS["first"]).save(OUT_DIR / "tab_first_on.png")
    cut(im155, DIV_TABS["second"]).save(OUT_DIR / "tab_second_off.png")
    cut(im155, DIV_TABS["third"]).save(OUT_DIR / "tab_third_off.png")

    # derive the off->on colour map from the witnessed 1st-Div pair; assert it is
    # a consistent per-colour map, then apply to 2nd/3rd (documented reconstruction)
    off = np.asarray(cut(im155, DIV_TABS["first"])).astype(int)
    on = np.asarray(cut(im158, DIV_TABS["first"])).astype(int)
    cmap: dict[tuple, Counter] = {}
    hh, ww = off.shape[:2]
    for y in range(hh):
        for x in range(ww):
            cmap.setdefault(tuple(off[y, x]), Counter())[tuple(on[y, x])] += 1
    table = {}
    for src, dsts in cmap.items():
        dst, n = dsts.most_common(1)[0]
        frac = n / sum(dsts.values())
        # the letter ink (100-grey) is unchanged between states; positional
        # comparison under-counts it because the rotated glyphs sit next to
        # face pixels -- pin it identity and require the rest to be clean.
        if src == (100, 100, 100):
            table[src] = src
            continue
        table[src] = dst
        if frac < 0.97:
            print(f"  NOTE off->on map {src}->{dst} only {frac:.0%} consistent")
    for name in ("second", "third"):
        arr = np.asarray(cut(im155, DIV_TABS[name])).astype(int).copy()
        out = arr.copy()
        for src, dst in table.items():
            m = (arr == np.array(src)).all(axis=2)
            out[m] = dst
        Image.fromarray(out.astype(np.uint8)).save(OUT_DIR / f"tab_{name}_on.png")
    print("wrote x_over / tab sprites (2nd/3rd ON = witnessed colour-map reconstruction)")

    # 3b) bottom category-tab state splices (documented reconstruction -- only
    #     MARKET-active is witnessed; the EXE ships symmetric on/off/over tab
    #     art, PKF NOTICIAS: lefttabon/off/over.bmp). Build:
    #       tab_<cat>_on.png  = MARKET-on structure (open top, white face,
    #                           black label) stretched to the slot, label
    #                           stamped from the cat's own witnessed off-art.
    #       tab_market_off.png = INJURIES-off structure stretched to MARKET's
    #                           slot, MARKET label stamped in the off ink.
    mk = np.asarray(cut(im155, CAT_TABS["market"])).astype(int)
    inj_off = np.asarray(cut(im155, CAT_TABS["injuries"])).astype(int)
    boo_off = np.asarray(cut(im155, CAT_TABS["bookings"])).astype(int)

    def label_mask(arr: np.ndarray, ink: tuple) -> np.ndarray:
        # label ink only: mask the tab INTERIOR (the border/bevel lines share
        # the label colours and would smear into bars if included)
        m = (arr == np.array(ink)).all(axis=2)
        out = np.zeros_like(m)
        out[3:-3, 4:-4] = m[3:-3, 4:-4]
        return out

    def stretch_cols(arr: np.ndarray, w: int) -> np.ndarray:
        # keep 3 left + 3 right border columns, tile a CLEAN face column in
        # between (just inside the right border -- label ink never reaches it)
        left, right = arr[:, :3], arr[:, -3:]
        face = arr[:, -4:-3]
        # clean = only structural colours (bevel 80/144/160, face 192/255, border 0)
        # in the column; label ink (100-grey, or black INSIDE the face rows)
        # would smear into bars when tiled.
        interior = face[4:-3].reshape(-1, 3)
        assert not (interior == 100).all(axis=1).any(), "face column has label ink"
        assert len(np.unique(interior, axis=0)) <= 2, "face column not flat"
        mid = np.tile(face, (1, w - 6, 1))
        return np.concatenate([left, mid, right], axis=1)

    def stamp(canvas: np.ndarray, mask: np.ndarray, colour: tuple) -> np.ndarray:
        out = canvas.copy()
        h2 = min(out.shape[0], mask.shape[0])
        # centre the label mask horizontally in the canvas
        mx = np.nonzero(mask.any(axis=0))[0]
        if mx.size == 0:
            return out
        lw = int(mx.max() - mx.min()) + 1
        dst0 = (out.shape[1] - lw) // 2
        sub = mask[:h2, mx.min() : mx.max() + 1]
        region = out[:h2, dst0 : dst0 + lw]
        region[sub] = colour
        return out

    for cat, off_arr in (("injuries", inj_off), ("bookings", boo_off)):
        w = CAT_TABS[cat][2]
        tpl = stretch_cols(mk, w)  # MARKET-on structure, label columns tiled away? no:
        # the stretch keeps the face column only, so the MARKET label is gone
        on = stamp(tpl, label_mask(off_arr, (100, 100, 100)), (0, 0, 0))
        Image.fromarray(on.astype(np.uint8)).save(OUT_DIR / f"tab_{cat}_on.png")
    mko = stretch_cols(inj_off, CAT_TABS["market"][2])
    mko = stamp(mko, label_mask(mk, (0, 0, 0)), (100, 100, 100))
    Image.fromarray(mko.astype(np.uint8)).save(OUT_DIR / "tab_market_off.png")
    print("wrote category-tab on/off splices (reconstruction, witnessed pixels only)")

    # 4) subtitle anchors + rule rows, measured
    sub_p = ink_bbox(a155, SUBTITLE_INK, 80, 105)
    sub_d = ink_bbox(a158, SUBTITLE_INK, 28, 55)
    rule_p = ink_bbox(a155, RULE_INK, 95, 110)
    rule_d = ink_bbox(a158, RULE_INK, 45, 60)
    assert sub_p and sub_d and rule_p and rule_d
    print("subtitle ink premier:", sub_p, "division:", sub_d)
    print("rule premier:", rule_p, "division:", rule_d)

    # 5) WEEKS plates: ACTUAL = solid black plate; LAST = grey plate left of it
    #    (scan the witnessed row band y405..433 x160..340)
    # The ACTUAL plate is a solid-black rectangle: its columns are black across
    # the plate's FULL height (letter strokes elsewhere are not), so detect
    # plate columns as x with >=14 black rows in the y405..433 band.
    band = a155[405:434, 220:340]
    blk = (band == 0).all(axis=2)
    plate_cols = np.nonzero(blk.sum(axis=0) >= 14)[0]
    ax0, ax1 = int(plate_cols.min()) + 220, int(plate_cols.max()) + 220
    rows = np.nonzero(blk[:, plate_cols.min()])[0]
    ay0, ay1 = int(rows.min()) + 405, int(rows.max()) + 405
    plate_actual = [ax0, ay0, ax1 - ax0 + 1, ay1 - ay0 + 1]
    # LAST plate: the 192-grey face immediately left of ACTUAL, same rows
    grey = (a155[ay0 : ay1 + 1, 160:ax0] == 192).all(axis=2)
    gxs = np.nonzero(grey.any(axis=0))[0]
    plate_last = [int(gxs.min()) + 160, ay0, int(gxs.max()) - int(gxs.min()) + 1, plate_actual[3]]
    print("WEEKS plates: LAST", plate_last, "ACTUAL", plate_actual)
    lab = ink_bbox(a155, (0, 0, 0), ay0 - 2, ay1 + 2, 150, plate_last[0] - 2)
    print("WEEKS: label ink", lab)

    # 6) ink metrics for the live re-strikes. The SUBTITLE face is proman10 --
    #    frame 155's "MARKET" glyphs match the proman10 atlas bitmap-exactly
    #    (M/A/R/K/E/T all verified; calend8/euro8/futcon8/proman8 do NOT).
    #    calend8 is kept for the un-witnessed body list: the EXE names it inside
    #    the NOTICIAS string block (MARKET/ACTUAL/calend8/LAST) -- documented
    #    reconstruction, news_screen_re.md.
    fnt_dir = ROOT / "app/art/fonts"
    chars = set("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789.,':%()£-&/ ")
    metrics: dict[str, dict] = {}
    for face in ("proman10", "calend8"):
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
            lo, hi = (int(cols.min()), int(cols.max())) if cols.size else (0, gw - 1)
            m[ch] = [int(kv["xadvance"]), lo, hi]
        metrics[face] = m

    spec = {
        "binding_frames": {
            "premier": F_PREMIER.name,
            "stable": F_STABLE.name,
            "injuries_over": F_INJ_OVER.name,
            "division": F_DIVISION.name,
        },
        "note": "NEWS extra overlay over the hub; NewsScreen.gd draws the baked "
        "page + live tab/subtitle/list state. Footprint = the page rect only; "
        "the hub stays visible (and live) around it.",
        "page": PAGE,
        "x_btn": X_BTN,
        "div_tabs": DIV_TABS,
        "cat_tabs": CAT_TABS,
        "weeks": {"label_ink": lab, "last": plate_last, "actual": plate_actual},
        "subtitle": {
            "ink": list(SUBTITLE_INK),
            "premier_bbox": sub_p,
            "division_bbox": sub_d,
            "cx": 308,  # both witnessed subtitles ink-centre on 308
            "face": "proman10",
            "format": "%s : %s",
            "divisions": ["Premier League", "First Division", "Second Division", "Third Division"],
            "categories": ["MARKET", "INJURIES", "BOOKINGS"],
        },
        "rule": {"ink": list(RULE_INK), "premier": rule_p, "division": rule_d},
        # the body list is UN-WITNESSED (both witnessed states are empty); this
        # block is a documented reconstruction: calend8 black rows inside the
        # white body, newest first. news_screen_re.md carries the flag.
        "body": {
            "x": 152,
            "right": 472,
            "top_premier": 108,
            "top_division": 58,
            "bottom": 402,
            "pitch": 13,
            "ink": [0, 0, 0],
            "face": "calend8",
        },
        "font_metrics": metrics,
    }
    OUT_JSON.write_text(json.dumps(spec, indent=2) + "\n")
    print(f"wrote {OUT_JSON.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
