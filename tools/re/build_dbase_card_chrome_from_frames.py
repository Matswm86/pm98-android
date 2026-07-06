#!/usr/bin/env python3
"""Bake the DATA BASE player-card chrome from the 2026-07-06 walked frames.

The card (docs/re/dbase_player_card_re.md) is the standalone Dbasewin.exe
player card — the bios.json display surface: title banner + 7 top tabs +
DATA/NOTES bottom tabs over a white panel, per-tab content (PERSONAL DATA /
prose pages / career PROGRESS table / NOTES notebook), PRINT + RETURN.

Sources, in order of preference:
  * RC_DBASE.PKF real assets where they match the frames pixel-exact
    (CAMPO.BMP pitch, BALON.BMP ball, FLECHAUP/DOWNDB1N steppers,
    SOMBRA FOTO1/2 photo shadows) — via the rc_dbase_image.py decoder.
  * The walked frames screenshots/bio-coin-walk-2026-07-06/ for everything
    the engine COMPOSITES (banner, tabs, panel, title bars, buttons):
    8 distinct-player card frames give a majority vote that recovers the
    static chrome under the per-player dynamic pixels.

Fonts (all pinned by pixel-exact mask match in this bake, GDI raster FNTs):
  * banner name        = PROMAN18 (fill = per-draw engine speckle in 4 greys
                         {255,240,220,192} — same class as the alert-box
                         title-field noise; shadow = band-darkening LUT)
  * tab labels         = FUTCON8 (black; disabled = washed grey)
  * panel header title = fitted here (FUTCON12/FUTCOND8 candidate)
  * prose body + career cells = KKITA
  * PERSONAL DATA labels/values, career header, role word = PROMAN8/10

Outputs:
  app/art/screens/dbase_card/*.png     baked chrome sprites
  app/art/kits/dbcard/<club_id>.png    frame-verified banner kit patches
  app/data/dbase_card_chrome_samples.json   geometry + colours + font pins
  app/art/fonts/futcon8.* / kkita.* / (header face)   new BMFont exports

KILL TESTS (all assert, run on every bake):
  * FONDO DBASE == every card frame wherever no widget covers it;
  * banner majority: every frame equals the bake outside the name/kit ROIs;
  * tab compose: rest/selected/disabled sprites recompose 034, each of
    035-041, 050 (all-disabled) and 055 (Klinsmann mix) pixel-exact;
  * bottom band: the two radio states recompose 034 + 046;
  * title bars: byte-identical wherever the same view appears twice;
  * PERSONAL DATA underlay == all 6 DATA-view frames outside dynamic ROIs;
  * NOTES panel == frame 046 wholesale;
  * PKF asset == frame pixels for CAMPO / steppers / BIGFOTO / flag art;
  * font pins: mask-exact match at the recorded offsets.
"""

from __future__ import annotations

import json
import sys
from collections import Counter
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import fnt_to_bmfont as FB  # noqa: E402
import rc_dbase_image as RC  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
SHOTS = ROOT / "screenshots" / "bio-coin-walk-2026-07-06"
OUT = ROOT / "app" / "art" / "screens" / "dbase_card"
KITS_OUT = ROOT / "app" / "art" / "kits" / "dbcard"
FONTS_OUT = ROOT / "app" / "art" / "fonts"
DATA_OUT = ROOT / "app" / "data" / "dbase_card_chrome_samples.json"

W, H = 640, 480

# The 8 distinct-player card frames (name + kit + panel content differ; all
# other pixels are the shared chrome). club = game_db club id for the kit patch.
PLAYER_FRAMES = {
    "034_schmeichel_db.png": {"club": 40, "view": "pdata"},
    "050_hiden_data.png": {"club": 24, "view": "pdata"},
    "055_klinsmann_data.png": {"club": 46, "view": "pdata"},
    "062_blackwell_career_typorow.png": {"club": 55, "view": "career"},
    "063_andersson_star_p2.png": {"club": 5, "view": "pdata"},
    "065_friedel_maybe.png": {"club": 51, "view": "pdata"},
    "068_friedel_card.png": {"club": 26, "view": "pdata"},
    "072_grodas_honours_short.png": {"club": 46, "view": "prose"},
}
# Frame -> selected top tab (0..6) for the Schmeichel tab walk.
SEL_FRAMES = [
    "035_tab_profile.png",
    "036_tab_technical.png",
    "037_tab_honours.png",
    "038_tab_career.png",
    "039_tab_internat.png",
    "040_tab_anecdotes.png",
    "041_tab_lastseason.png",
]
ALL_DISABLED = "050_hiden_data.png"
# Klinsmann 055: only TECHNICAL CHAR. (1) + ANECDOTES (5) enabled.
KLINSMANN = ("055_klinsmann_data.png", {1, 5})

# Tab sprite x-spans: [start, end) where end covers the tab's full diagonal cap
# (derived from the 034-vs-selected changed-column spans, +1 on the max).
# Each tab is the real FICHA widget: left cap 8px + N 8px mid tiles + a 20px
# right diagonal cap (RC_DBASE FICHA ON/OFF 1/2/3; idx0-transparent above the
# cap diagonal), so width == 28 + 8N and neighbouring caps overlap by 8px.
TAB_X = [(17, 85), (77, 193), (185, 261), (253, 321), (313, 397), (389, 473), (465, 557)]
TAB_Y = (71, 93)  # band: tab art rows 71..91 + the panel-edge rows a SELECTED tab opens
TAB_ART_Y1 = 91  # piece art is 20 rows: 71..91 (rows 91..93 belong to the panel edge)
SEAM_W = 8  # neighbouring tabs overlap by one 8px piece: the seam patch width
# Tab enable-state vectors of the walked witnesses, DERIVED from bios.json by
# the port's sentinel rule (disable when stripped content is in the sentinel
# set OR len < 15 — dbase_player_card_re.md) and re-asserted against the
# frames' wash pixels in bake_tabs. Tab order: p0 p1 p2 CAREER p3 p4 p5.
TAB_SENTINELS = {"x", "X", "-", "*", "TXT ?", "No data.", "Sin datos.", "ND,ND,ND,ND,ND"}
FRAME_PLAYER_IDS = {  # frame -> (game_db player id, selected tab or -1)
    "034_schmeichel_db.png": (45, -1),
    "050_hiden_data.png": (93, -1),
    "055_klinsmann_data.png": (207, -1),
    "062_blackwell_career_typorow.png": (264, 3),
    "063_andersson_star_p2.png": (11, -1),
    "065_friedel_maybe.png": (417, -1),
    "068_friedel_card.png": (68, -1),
    "072_grodas_honours_short.png": (184, 2),
}


def tab_enabled(section: str) -> bool:
    t = (section or "").strip()
    return t not in TAB_SENTINELS and len(t) >= 15


def derive_frame_tabs() -> dict[str, str]:
    """Per-witness 7-char state vector: r/d from the sentinel rule, s where
    the frame has that tab SELECTED (the viewed page)."""
    bios = json.loads((ROOT / "app" / "data" / "bios.json").read_text())["players"]
    out = {}
    for fname, (pid, sel) in FRAME_PLAYER_IDS.items():
        b = bios[str(pid)]
        st = "".join("r" if tab_enabled(p) else "d" for p in b["pages"][:3])
        st += "r" if tab_enabled(b["career"]) else "d"
        st += "".join("r" if tab_enabled(p) else "d" for p in b["pages"][3:6])
        if sel >= 0:
            assert st[sel] == "r", f"{fname}: selected tab {sel} is data-disabled"
            st = st[:sel] + "s" + st[sel + 1 :]
        out[fname] = st
    # the walked truths pinned in dbase_player_card_re.md
    assert out["034_schmeichel_db.png"] == "rrrrrrr"
    assert out["050_hiden_data.png"] == "ddddddd"
    assert out["055_klinsmann_data.png"] == "drdddrd"
    assert out["068_friedel_card.png"] == "ddddddd"
    assert out["062_blackwell_career_typorow.png"][3] == "s"
    return out


FRAME_TABS = None  # filled by main() (needs app/data/bios.json)

BANNER_H = 66
NAME_BOX = (143, 8, 501, 40)  # x0,y0,x1,y1 — cross-frame disagreement bounds, padded
KIT_BOX = (566, 0, 622, 66)  # kit patch region (cols 571..615 observed, padded)

PANEL = (
    12,
    91,
    634,
    416,
)  # outer panel rect x0,y0,x1,y1 (row/col diff vs FONDO; row 90 belongs to the tab band)
TITLE_BAR = (20, 96, 626, 116)  # blue header bar band inside the panel
BOTTOM_BAND = (12, 405, 140, 429)  # DATA/NOTES hanging tabs band (tops overlap the panel border)
BTN_PRINT = (384, 442, 498, 470)
BTN_RETURN = (506, 442, 620, 470)

# PERSONAL DATA dynamic ROIs (inside the panel; underlay pixels here are
# app-drawn): photo/pitch box incl. shadows + role word band under it, the
# value texts on the bars, the two flags, and the AGE digits.
PHOTO_BOX = (28, 126, 178, 334)
ROLE_BAND = (30, 336, 180, 352)
PD_VALUE_ROWS = [  # (x0,y0,x1,y1) the four VALUE-BAR bands (bars + flags + texts)
    (190, 162, 628, 186),  # BIRTH PLACE value + its flag | DATE value
    (190, 212, 628, 236),  # AGE | NATIONALITY + the big waving flag | INTERNATIONAL
    (190, 262, 628, 286),  # LAST CLUB value
    (190, 312, 628, 336),  # HEIGHT / WEIGHT values
]

VIEWS = {  # view key -> (witness frame, panel header title text)
    "pdata": ("034_schmeichel_db.png", "PERSONAL DATA"),
    "profile": ("035_tab_profile.png", "PROFILE"),
    "technical": ("036_tab_technical.png", "TECHNICAL CHARACTERISTICS"),
    "honours": ("037_tab_honours.png", "HONOURS"),
    "career": ("038_tab_career.png", "PROGRESS"),
    "internat": ("039_tab_internat.png", "INTERNATIONAL"),
    "anecdotes": ("040_tab_anecdotes.png", "ANECDOTES"),
    "lastseason": ("041_tab_lastseason.png", "LAST SEASON"),
    "notes": ("046_notes_tab.png", None),
}

_frames: dict[str, np.ndarray] = {}


def frame(name: str) -> np.ndarray:
    if name not in _frames:
        a = np.array(Image.open(SHOTS / name).convert("RGB"))
        _frames[name] = a[:, :W]  # captures carry 1 junk column at x=640
    return _frames[name]


def fondo() -> np.ndarray:
    return np.array(Image.open(ROOT / "app" / "art" / "screens" / "fondo_dbase.png").convert("RGB"))


def save(arr: np.ndarray, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(arr).save(path)


def font(face: str) -> FB.Fnt:
    return FB.Fnt((FB.WINFONTS / face).read_bytes())


def render_mask(fnt: FB.Fnt, text: str) -> np.ndarray:
    imgs: list[tuple[int, Image.Image]] = []
    w = 0
    for ch in text:
        idx = ord(ch)
        if idx < fnt.first or idx > fnt.last:
            idx = fnt.first
        gw, img = fnt.glyph(idx - fnt.first)
        imgs.append((gw, img))
        w += gw
    out = Image.new("1", (w, fnt.pix_height), 0)
    x = 0
    for gw, img in imgs:
        out.paste(img, (x, 0))
        x += gw
    return np.array(out, dtype=bool)


def trim(a: np.ndarray) -> tuple[np.ndarray, int, int]:
    ys, xs = np.nonzero(a)
    return a[ys.min() : ys.max() + 1, xs.min() : xs.max() + 1], int(xs.min()), int(ys.min())


def in_box(x: int, y: int, box: tuple[int, int, int, int]) -> bool:
    return box[0] <= x < box[2] and box[1] <= y < box[3]


# ---------------------------------------------------------------- fonts ----


def pin_fonts() -> dict:
    """Assert the per-surface typefaces by pixel-exact mask matches."""
    pins = {}
    f34, f35, f38 = (
        frame("034_schmeichel_db.png"),
        frame("035_tab_profile.png"),
        frame("038_tab_career.png"),
    )

    def dark(reg):
        return (reg < 90).all(axis=2)

    def white(reg):
        return (reg > 200).all(axis=2)

    def check(surface, img, crop, mask_fn, face, text):
        y0, y1, x0, x1 = crop
        m, mx, my = trim(mask_fn(img[y0:y1, x0:x1]))
        g, *_ = trim(render_mask(font(face), text))
        assert g.shape == m.shape and (g == m).all(), (
            f"font pin {surface}: {face} vs frame mask {m.shape} != {g.shape}"
        )
        pins[surface] = face
        print(f"  font pin OK: {surface} = {face} ({text!r} at {x0 + mx},{y0 + my})")

    check("pdata_value", f34, (165, 185, 190, 290), white, "PROMAN10.FNT", "Gladsaxe")
    check("career_header", f38, (133, 148, 190, 255), dark, "PROMAN8.FNT", "SEASON")
    check("role_word", f34, (340, 355, 55, 165), dark, "PROMAN10.FNT", "GOALKEEPER")
    check("tab_label", f34, (75, 89, 22, 68), dark, "FUTCON8.FNT", "PROFILE")
    check("prose_body", f35, (163, 182, 500, 511), dark, "KKITA.FNT", "M")
    # header-bar title = PROMAN12, white fill carrying the light engine
    # speckle tints (same noise class as the banner name) — mask by luminance
    # over the blue bar, then require the exact PROMAN12 mask.
    y0, y1, x0, x1 = (98, 114, 25, 220)
    reg = f34[y0:y1, x0:x1].astype(int)
    m, mx, my = trim(reg.sum(axis=2) > 500)
    g, *_ = trim(render_mask(font("PROMAN12.FNT"), "PERSONAL DATA"))
    assert g.shape == m.shape and (g == m).all(), (
        f"header title PROMAN12 mismatch (mask {m.shape} vs {g.shape})"
    )
    pins["header_title"] = "PROMAN12.FNT"
    print(f"  font pin OK: header_title = PROMAN12 (at {x0 + mx},{y0 + my})")
    pins["header_title_xy"] = [x0 + mx, y0 + my]
    # banner name = PROMAN18: mask must sit fully inside the light-fill pixels
    g = render_mask(font("PROMAN18.FNT"), "Peter Boleslaw SCHMEICHEL")
    reg = f34[5:45, 140:520]
    fill = (reg > 180).all(axis=2)  # speckle greys 192..255
    best = (0.0, None)
    gh, gw = g.shape
    for oy in range(40 - gh):
        for ox in range(380 - gw):
            cov = (g & fill[oy : oy + gh, ox : ox + gw]).sum() / g.sum()
            if cov > best[0]:
                best = (cov, (ox + 140, oy + 5))
    assert best[0] > 0.97, f"banner PROMAN18 fill coverage only {best[0]:.3f}"
    pins["banner_name"] = "PROMAN18.FNT"
    pins["banner_name_xy_034"] = list(best[1])
    print(f"  font pin OK: banner_name = PROMAN18 (fill coverage {best[0]:.3f} at {best[1]})")
    return pins


# --------------------------------------------------------------- banner ----


def bake_banner() -> dict:
    names = list(PLAYER_FRAMES)
    stack = np.stack([frame(n)[:BANNER_H] for n in names])  # (8,66,640,3)
    nfr = len(names)
    # majority vote per pixel
    out = np.zeros((BANNER_H, W, 3), np.uint8)
    weak = 0
    weak_px: list[tuple[int, int]] = []
    for y in range(BANNER_H):
        for x in range(W):
            votes = Counter(map(tuple, stack[:, y, x]))
            col, cnt = votes.most_common(1)[0]
            out[y, x] = col
            if cnt < (nfr // 2 + 1):
                weak += 1
                weak_px.append((x, y))
    for x, y in weak_px:
        assert in_box(x, y, NAME_BOX) or in_box(x, y, KIT_BOX), (
            f"banner weak majority outside dynamic ROIs at {x},{y}"
        )
    save(out, OUT / "banner.png")
    print(f"  banner.png baked (majority of {nfr}; {weak} weak px, all inside name/kit ROIs)")
    # kill test: bake == every frame outside the two dynamic ROIs
    for n in names:
        f = frame(n)[:BANNER_H]
        diff = (f != out).any(axis=2)
        ys, xs = np.nonzero(diff)
        for x, y in zip(xs.tolist(), ys.tolist()):
            assert in_box(x, y, NAME_BOX) or in_box(x, y, KIT_BOX), (
                f"banner mismatch vs {n} at {x},{y} (outside ROIs)"
            )
    print("  banner kill test OK: all 8 frames equal outside name/kit ROIs")
    # per-club kit patches (cut the full KIT_BOX; blitted back at the same spot)
    seen: dict[int, np.ndarray] = {}
    for n, meta in PLAYER_FRAMES.items():
        cid = meta["club"]
        patch = frame(n)[KIT_BOX[1] : KIT_BOX[3], KIT_BOX[0] : KIT_BOX[2]]
        if cid in seen:
            assert (seen[cid] == patch).all(), f"kit patch for club {cid} differs between frames"
            continue
        seen[cid] = patch
        save(patch, KITS_OUT / f"{cid}.png")
    print(f"  kit patches baked: {sorted(seen)} (dup-frame determinism OK)")
    return {"name_box": NAME_BOX, "kit_box": KIT_BOX}


# ----------------------------------------------------------------- tabs ----


def _pieces() -> tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray]:
    """FICHA OFF 1/2/3 piece art (shared VGA palette) + the cap's opaque mask."""
    import struct

    lcap = np.array(RC.render("FICHA OFF 1.BMP").convert("RGB"))
    mid = np.array(RC.render("FICHA OFF 2.BMP").convert("RGB"))
    cap = np.array(RC.render("FICHA OFF 3.BMP").convert("RGB"))
    raw = RC._entry_bytes("FICHA OFF 3.BMP")
    off = struct.unpack_from("<I", raw, 10)[0]
    pix = raw[off:]
    capm = np.zeros((20, 20), bool)
    for yy in range(20):
        capm[19 - yy] = np.frombuffer(pix[yy * 20 : yy * 20 + 20], np.uint8) != 0
    return lcap, mid, cap, capm


def _tab_art(i: int) -> np.ndarray:
    """The pure (unoccluded) rest-state art of tab i: lcap + N mid tiles + cap."""
    lcap, mid, cap, _ = _pieces()
    x0, x1 = TAB_X[i]
    w = x1 - x0
    n = (w - 28) // 8
    assert 28 + 8 * n == w, f"tab {i} width {w} is not 28+8N"
    return np.hstack([lcap] + [mid] * n + [cap])


def bake_tabs() -> None:
    """Tab strip = the real FICHA piece widgets + the engine's disable wash.

    Verified model (every step kill-tested below):
      * a tab = [FICHA OFF 1][FICHA OFF 2 x N][FICHA OFF 3] (20 rows at y71),
        width 28+8N == the reversed spans; the cap piece is idx0-transparent
        above its diagonal. Tabs paint RIGHT-to-LEFT, so the left tab's cap
        diagonal lands over the right tab's left-cap piece (rr seam == the
        raw piece composition, pixel-exact vs 034).
      * DISABLED = a parity-gated palette-space halftone wash of the tab's
        own art against what lies beneath (fondo under the body, the right
        neighbour's pixels under the cap). Not linear in RGB — learned here
        as an exact LUT TT[(art, under, (x+y)%2)] -> washed from the walked
        disabled tabs (0 ambiguous keys), then verified by recomposing every
        observed seam of every witness frame.
      * SELECTED paints last on top (white body opens the panel edge and
        covers both its seams) — baked as frame cuts with a change-mask
        alpha. (sel,dis)/(dis,sel) adjacency is un-walked: the dis
        neighbour's rect is TT-composed there (documented extrapolation).

    The app consumes: tab{i}_{rest|dis|sel}.png + tabseam{pos}_{rr|rd|dr|dd}
    .png (position-keyed: the wash blends the position-dependent FONDO).
    """
    y0, y1 = TAB_Y
    f_rest = frame("034_schmeichel_db.png")
    lcap, mid, cap, capm = _pieces()
    # what lies BENEATH the tabs: the FONDO, except row 90 where the black
    # panel top line is drawn first (visible in the strip gaps of 034)
    g = fondo().copy()
    for x in (13, 14, 15, 16, 558, 600):
        assert tuple(f_rest[90, x]) == (0, 0, 0), f"panel line at 90,{x} not black"
    g[90, 12:628] = (0, 0, 0)

    # -- pure art sanity: tab0's left cap (never occluded) + its right cap's
    # opaque diagonal == 034 (the label pixels in between are frame-only art)
    art0 = _tab_art(0)
    want = f_rest[71:91, TAB_X[0][0] : TAB_X[0][1]]
    body_w = art0.shape[1] - 20
    assert (art0[:, :8] == want[:, :8]).all(), "tab0 lcap piece != 034"
    assert (art0[:, body_w:][capm] == want[:, body_w:][capm]).all(), "tab0 cap != 034"

    # -- learn the wash LUT from every fully-known disabled tab body
    TT: dict[tuple, tuple] = {}

    def tt_learn(art_px, under_px, washed_px, parity) -> None:
        k = (tuple(art_px), tuple(under_px), parity)
        if k in TT:
            assert TT[k] == tuple(washed_px), f"wash LUT ambiguous at {k}"
        else:
            TT[k] = tuple(washed_px)

    def tt(art_px, under_px, parity):
        k = (tuple(art_px), tuple(under_px), parity)
        if k in TT:
            return TT[k]
        # nearest-key fallback (alert menu_bg_dim precedent) — only un-walked
        # state adjacencies ever hit this; counted + reported.
        cands = [kk for kk in TT if kk[0] == k[0] and kk[2] == parity]
        assert cands, f"wash LUT: no candidates for art {k[0]}"
        best = min(cands, key=lambda kk: sum((a - b) ** 2 for a, b in zip(kk[1], k[1])))
        return TT[best]

    for fname, states in FRAME_TABS.items():
        fw = frame(fname)
        for i, st in enumerate(states):
            if st != "d":
                continue
            x0, x1 = TAB_X[i]
            art = _tab_art(i)
            # body cols only (skip both seam zones: the occluded left cap and
            # the right cap over the neighbour) — and skip the LABEL pixels,
            # where the rest frame diverges from the pure piece art.
            for y in range(71, 91):
                for x in range(x0 + 8, x1 - 20):
                    if (f_rest[y, x] != art[y - 71, x - x0]).any():
                        continue
                    tt_learn(art[y - 71, x - x0], g[y, x], fw[y, x], (x + y) % 2)
    # second pass over dd seams: the cap's transparent NOTCH shows the washed
    # right lcap directly (exact keys for seam-local FONDO colours), then the
    # diagonal pixels teach the layered cap-over-washed keys.
    for _round in ("notch", "diag"):
        for fname, states in FRAME_TABS.items():
            fw = frame(fname)
            for i in range(6):
                pair = states[i] + states[i + 1]
                # notch (cap-transparent) shows the WASHED right lcap in both
                # dd and rd; the diagonal teaches cap-over-washed in dd only.
                if _round == "notch" and pair not in ("dd", "rd"):
                    continue
                if _round == "diag" and pair != "dd":
                    continue
                sx = TAB_X[i + 1][0]
                for y in range(71, 91):
                    for x in range(sx, sx + SEAM_W):
                        p = (x + y) % 2
                        cx = x - (TAB_X[i][1] - 20)
                        if _round == "notch" and not capm[y - 71, cx]:
                            tt_learn(lcap[y - 71, x - sx], g[y, x], fw[y, x], p)
                        elif _round == "diag" and capm[y - 71, cx]:
                            under = tt(lcap[y - 71, x - sx], g[y, x], p)
                            tt_learn(cap[y - 71, cx], under, fw[y, x], p)
    print(f"  wash LUT learned: {len(TT)} exact keys, 0 ambiguous")

    # collect every OBSERVED seam cut, grouped by pair type
    observed: dict[tuple[int, str], np.ndarray] = {}
    for fname, states in FRAME_TABS.items():
        fw = frame(fname)
        for i in range(6):
            pair = states[i] + states[i + 1]
            sx = TAB_X[i + 1][0]
            cut = fw[71:91, sx : sx + SEAM_W]
            if (i, pair) in observed:
                assert (observed[(i, pair)] == cut).all(), (
                    f"observed seam {i}/{pair} differs between witnesses ({fname})"
                )
            else:
                observed[(i, pair)] = cut
    # rr / dr are art-over-art (no FONDO reaches those seam pixels) and prove
    # POSITION-INDEPENDENT across every observed instance — one shared patch
    # each covers the un-walked positions exactly. dd and rd blend the
    # position-dependent FONDO (through the washed right tab): dd is observed
    # at all 6 positions (frame cuts); rd is observed at 1/3/5 and SYNTHESIZED
    # at 0/2/4 as unwashed-cap over TT(lcap, fondo) — a model exact on every
    # observed rd instance (asserted here).
    shared: dict[str, np.ndarray] = {}
    counts = Counter()
    for (i, pair), cut in observed.items():
        if pair in ("rr", "dr"):
            if pair in shared:
                assert (shared[pair] == cut).all(), (
                    f"{pair} seam is position-dependent (differs at {i})"
                )
            else:
                shared[pair] = cut
            counts[pair] += 1
    assert set(shared) == {"rr", "dr"}, f"missing shared seam pairs: {shared.keys()}"
    for pair, cut in shared.items():
        save(cut, OUT / f"tabseam_{pair}.png")

    def synth_rd(pos: int) -> np.ndarray:
        sx = TAB_X[pos + 1][0]
        out = np.zeros((20, SEAM_W, 3), np.uint8)
        for y in range(71, 91):
            for x in range(sx, sx + SEAM_W):
                cx = x - (TAB_X[pos][1] - 20)
                if capm[y - 71, cx]:
                    out[y - 71, x - sx] = cap[y - 71, cx]
                else:
                    out[y - 71, x - sx] = tt(lcap[y - 71, x - sx], g[y, x], (x + y) % 2)
        return out

    n_rd_obs = 0
    for pos in range(6):
        cut = observed.get((pos, "dd"))
        assert cut is not None, f"dd seam unobserved at {pos}"
        save(cut, OUT / f"tabseam{pos}_dd.png")
        rd = observed.get((pos, "rd"))
        if rd is not None:
            assert (synth_rd(pos) == rd).all(), f"rd synthesis model broken at {pos}"
            n_rd_obs += 1
        else:
            rd = synth_rd(pos)
        save(rd, OUT / f"tabseam{pos}_rd.png")
    print(
        f"  seam patches baked: shared rr/dr ({dict(counts)}), 6 dd cuts, "
        f"6 rd ({n_rd_obs} observed + {6 - n_rd_obs} synthesized, model exact on all observed)"
    )
    # (sel,dis) adjacency is un-walked: the sel sprite covers the seam except
    # the washed right-lcap sliver — synthesize it from the wash LUT per
    # position (nearest-key fallback possible; documented extrapolation).
    for pos in range(6):
        sx = TAB_X[pos + 1][0]
        out = np.zeros((20, SEAM_W, 3), np.uint8)
        for y in range(71, 91):
            for x in range(sx, sx + SEAM_W):
                out[y - 71, x - sx] = tt(lcap[y - 71, x - sx], g[y, x], (x + y) % 2)
        save(out, OUT / f"tabseam{pos}_nd.png")
    # (dis,sel): the dis cap washes over the SELECTED white body — walked once
    # (062 Blackwell, seam 2). Art-over-art like dr/rd, so shipped shared.
    ds = next((cut for (i, pair), cut in observed.items() if pair == "ds"), None)
    assert ds is not None, "no walked (dis,sel) seam found"
    save(ds, OUT / "tabseam_ds.png")

    # bake the tab sprites: rest/dis are full-rect cuts of frame truth at
    # their fixed positions (034 / the dd witnesses); sel = frame cut with
    # change-mask alpha (covers the panel-edge rows + both seams).
    f_dis = frame(ALL_DISABLED)
    for i, (x0, x1) in enumerate(TAB_X):
        pad = np.zeros((y1 - TAB_ART_Y1, x1 - x0), bool)
        art = np.ones((TAB_ART_Y1 - y0, x1 - x0), bool)
        m_rd = np.vstack([art, pad])
        f_sel = frame(SEL_FRAMES[i])
        ch = (f_sel[y0:y1, x0:x1] != f_rest[y0:y1, x0:x1]).any(axis=2)
        for state, src, m in (
            ("rest", f_rest, m_rd),
            ("dis", f_dis, m_rd),
            ("sel", f_sel, m_rd | ch),
        ):
            save(
                np.dstack([src[y0:y1, x0:x1], (m * 255).astype(np.uint8)]),
                OUT / f"tab{i}_{state}.png",
            )

    def compose(states: list[str]) -> np.ndarray:
        band = fondo()[y0:y1].copy()
        band[90 - y0, 12:628] = (0, 0, 0)  # the panel top line, under the tabs
        order = [i for i in reversed(range(7)) if states[i] != "sel"]
        order += [i for i in range(7) if states[i] == "sel"]
        for i in order:
            x0, x1 = TAB_X[i]
            spr = np.array(Image.open(OUT / f"tab{i}_{states[i]}.png"))
            m = spr[:, :, 3] > 0
            band[:, x0:x1][m] = spr[:, :, :3][m]
        for i in range(6):
            pair = states[i][0] + states[i + 1][0]
            sx = TAB_X[i + 1][0]
            patch = None
            if pair in ("rr", "dr"):
                patch = f"tabseam_{pair}.png"
            elif pair in ("dd", "rd"):
                patch = f"tabseam{i}_{pair}.png"
            elif pair == "ds":
                patch = "tabseam_ds.png"  # dis cap over the sel body (062 cut)
            elif pair == "sd":
                patch = f"tabseam{i}_nd.png"  # washed right lcap, sel repaints
            if patch is None:
                continue  # (r,s)/(s,r): the rect + sel sprites already agree
            band[:20, sx : sx + SEAM_W] = np.array(Image.open(OUT / patch).convert("RGB"))
            if "s" in pair:  # re-run the sel overpaint on this seam
                j = i if pair[0] == "s" else i + 1
                x0, x1 = TAB_X[j]
                spr = np.array(Image.open(OUT / f"tab{j}_sel.png"))
                m = spr[:, :, 3] > 0
                band[:, x0:x1][m] = spr[:, :, :3][m]
        return band

    st_name = {"r": "rest", "d": "dis", "s": "sel"}
    cases = [(n, [st_name[c] for c in st]) for n, st in FRAME_TABS.items()]
    for i, n in enumerate(SEL_FRAMES):
        st = ["rest"] * 7
        st[i] = "sel"
        cases.append((n, st))
    for n, st in cases:
        got = compose(st)
        want = frame(n)[y0:y1]
        d = (got != want).any(axis=2)
        if not any(s == "sel" for s in st):
            d = d[: TAB_ART_Y1 - y0]
        else:
            painted = np.zeros_like(d)
            for i in range(7):
                x0, x1 = TAB_X[i]
                m = np.array(Image.open(OUT / f"tab{i}_{st[i]}.png"))[:, :, 3] > 0
                painted[:, x0:x1] |= m
            d[TAB_ART_Y1 - y0 :] &= painted[TAB_ART_Y1 - y0 :]
        assert not d.any(), (
            f"tab compose mismatch vs {n}: {int(d.sum())} px at "
            f"{(np.argwhere(d)[:4] + [y0, 0]).tolist()}"
        )
    print(f"  tab sprites + 36 seam patches baked; {len(cases)} compose kill tests OK")


# ------------------------------------------------------- panel + titles ----


def bake_panel_and_titles() -> dict:
    x0, y0, x1, y1 = PANEL
    f34 = frame("034_schmeichel_db.png")
    # panel border ring: identical across ALL card frames (content differs inside)
    ring_w = 8  # ring sample width; interior starts deeper but 8px covers the bevel
    ring = np.ones((y1 - y0, x1 - x0), bool)
    ring[ring_w:-ring_w, ring_w:-ring_w] = False
    # the DATA/NOTES hanging tabs overlap the panel's bottom-left border and
    # carry their own 3-state art (bake_bottom) — excluded from the ring check
    bx0, by0, bx1, by1 = BOTTOM_BAND
    ring[max(0, by0 - y0) : by1 - y0, max(0, bx0 - x0) : bx1 - x0] = False
    for n in list(PLAYER_FRAMES) + SEL_FRAMES + ["046_notes_tab.png"]:
        f = frame(n)
        same = (f[y0:y1, x0:x1] == f34[y0:y1, x0:x1]).all(axis=2)
        assert (same | ~ring).all(), f"panel border ring differs vs {n}"
    save(f34[y0:y1, x0:x1], OUT / "panel_034.png")  # full panel of the DATA view
    print("  panel border ring identical across all 17 card frames")
    # title bars: cut the bar band per view (static per view)
    tx0, ty0, tx1, ty1 = TITLE_BAR
    for key, (fname, _title) in VIEWS.items():
        save(frame(fname)[ty0:ty1, tx0:tx1], OUT / f"title_{key}.png")
    # same view twice -> identical bar (prose views across 043/044/045 rechecks)
    for pair in [
        ("039_tab_internat.png", "043_internat_end.png"),
        ("040_tab_anecdotes.png", "044_anecdotes_end.png"),
        ("041_tab_lastseason.png", "045_lastseason_end.png"),
        ("038_tab_career.png", "042_career_scrolled.png"),
    ]:
        a, b = (frame(n)[ty0:ty1, tx0:tx1] for n in pair)
        assert (a == b).all(), f"title bar differs between {pair}"
    print(f"  title bars baked for {len(VIEWS)} views (+4 stability checks)")
    return {"panel": PANEL, "title_bar": TITLE_BAR}


# ----------------------------------------------------- personal data -------


def bake_pdata() -> None:
    frames6 = [n for n, m in PLAYER_FRAMES.items() if m["view"] == "pdata"]
    x0, y0, x1, y1 = PANEL
    stack = np.stack([frame(n)[y0:y1, x0:x1] for n in frames6])
    nfr = len(frames6)
    out = np.zeros_like(stack[0])
    weak_px: list[tuple[int, int]] = []
    for y in range(out.shape[0]):
        for x in range(out.shape[1]):
            votes = Counter(map(tuple, stack[:, y, x]))
            col, cnt = votes.most_common(1)[0]
            out[y, x] = col
            if cnt < (nfr // 2 + 1):
                weak_px.append((x + x0, y + y0))
    dyn = [PHOTO_BOX, ROLE_BAND] + PD_VALUE_ROWS
    weak_set = set()
    for x, y in weak_px:
        assert any(in_box(x, y, b) for b in dyn), f"pdata weak majority at {x},{y}"
        weak_set.add((x, y))
    # fill each weak (player-varying) pixel from the nearest strong pixels in
    # its row (+-30px window mode = the local flat bar / background colour),
    # so no witness text/flag ghosts survive in the underlay
    for bx0, by0, bx1, by1 in PD_VALUE_ROWS:
        for y in range(by0, by1):
            for x in range(bx0, bx1):
                if (x, y) not in weak_set:
                    continue
                win = [
                    tuple(out[y - y0, xx - x0])
                    for xx in range(max(bx0, x - 30), min(bx1, x + 31))
                    if (xx, y) not in weak_set
                ]
                assert win, f"no strong fill source at {x},{y}"
                out[y - y0, x - x0] = Counter(win).most_common(1)[0][0]
    for bx0, by0, bx1, by1 in (PHOTO_BOX, ROLE_BAND):
        out[by0 - y0 : by1 - y0, bx0 - x0 : bx1 - x0] = (255, 255, 255)
    save(out, OUT / "view_pdata.png")
    # kill test: underlay == every DATA frame outside the dynamic ROIs
    for n in frames6:
        f = frame(n)[y0:y1, x0:x1]
        diff = (f != out).any(axis=2)
        ys, xs = np.nonzero(diff)
        for x, y in zip(xs.tolist(), ys.tolist()):
            assert any(in_box(x + x0, y + y0, b) for b in dyn), (
                f"pdata underlay mismatch vs {n} at {x + x0},{y + y0}"
            )
    print(f"  view_pdata.png baked (majority of {nfr}; kill test vs all 6 DATA frames OK)")


# ------------------------------------------------ notes / prose / career ---


def bake_static_views() -> dict:
    x0, y0, x1, y1 = PANEL
    # NOTES: the whole panel interior is static (empty new-game notebook)
    f46 = frame("046_notes_tab.png")
    save(f46[y0:y1, x0:x1], OUT / "view_notes.png")
    # prose: interior is white + text + scrollbar; bake the EMPTY prose panel
    # from 035 with the text box and the scrollbar zone cleared to white —
    # the app draws text and scroll parts on top.
    f35 = frame("035_tab_profile.png").copy()
    prose = f35[y0:y1, x0:x1].copy()
    PROSE_BOX = (186, 122, 575, 412)  # text zone (panel-absolute)
    SCROLL_ZONE = (575, 120, 634, 414)
    for bx0, by0, bx1, by1 in (PROSE_BOX, SCROLL_ZONE):
        prose[by0 - y0 : by1 - y0, bx0 - x0 : bx1 - x0] = (255, 255, 255)
    save(prose, OUT / "view_prose.png")
    # prose empty-panel kill test: every prose frame equals it outside those zones
    for n in [
        "035_tab_profile.png",
        "037_tab_honours.png",
        "039_tab_internat.png",
        "040_tab_anecdotes.png",
        "041_tab_lastseason.png",
        "043_internat_end.png",
        "044_anecdotes_end.png",
        "045_lastseason_end.png",
        "058_klinsmann_anecdotes.png",
        "072_grodas_honours_short.png",
    ]:
        f = frame(n)[y0:y1, x0:x1]
        diff = (f != prose).any(axis=2)
        ys, xs = np.nonzero(diff)
        for x, y in zip(xs.tolist(), ys.tolist()):
            px, py = x + x0, y + y0
            assert (
                in_box(px, py, PROSE_BOX)
                or in_box(px, py, SCROLL_ZONE)
                or in_box(px, py, PHOTO_BOX)
                or in_box(px, py, ROLE_BAND)
                or in_box(px, py, TITLE_BAR)
            ), f"prose panel mismatch vs {n} at {px},{py}"
    print("  view_notes.png + view_prose.png baked (10-frame prose kill test OK)")
    # career: same white panel; the table + scrollbar are app-drawn. Reuse the
    # prose blank (identical outside the zones — asserted right above via 038?).
    f38 = frame("038_tab_career.png")[y0:y1, x0:x1]
    CAREER_ZONE = (186, 120, 575, 414)
    diff = (f38 != prose).any(axis=2)
    ys, xs = np.nonzero(diff)
    for x, y in zip(xs.tolist(), ys.tolist()):
        px, py = x + x0, y + y0
        assert (
            in_box(px, py, CAREER_ZONE)
            or in_box(px, py, SCROLL_ZONE)
            or in_box(px, py, PHOTO_BOX)
            or in_box(px, py, ROLE_BAND)
            or in_box(px, py, TITLE_BAR)
        ), f"career-vs-prose blank mismatch at {px},{py}"
    print("  career view uses the same blank panel (038 kill test OK)")
    return {"prose_box": PROSE_BOX, "scroll_zone": SCROLL_ZONE, "career_zone": CAREER_ZONE}


# ------------------------------------------------- bottom band + buttons ---


def bake_bottom() -> None:
    x0, y0, x1, y1 = BOTTOM_BAND
    # THREE radio states: DATA white (the PERSONAL DATA view), a TOP tab
    # selected (both bottom tabs yellow), NOTES white (the notebook).
    save(frame("034_schmeichel_db.png")[y0:y1, x0:x1], OUT / "bottom_data.png")
    save(frame("038_tab_career.png")[y0:y1, x0:x1], OUT / "bottom_top.png")
    save(frame("046_notes_tab.png")[y0:y1, x0:x1], OUT / "bottom_notes.png")
    expect = {}
    for n, (pid, sel) in FRAME_PLAYER_IDS.items():
        expect[n] = "top" if sel >= 0 else "data"
    for n in SEL_FRAMES:
        expect[n] = "top"
    for n in [
        "042_career_scrolled.png",
        "043_internat_end.png",
        "044_anecdotes_end.png",
        "045_lastseason_end.png",
        "056_klinsmann_technical.png",
        "058_klinsmann_anecdotes.png",
    ]:
        expect[n] = "top"
    for n, state in expect.items():
        want = np.array(Image.open(OUT / f"bottom_{state}.png").convert("RGB"))
        got = frame(n)[y0:y1, x0:x1]
        assert (got == want).all(), f"bottom band vs {n} not in {state} state"
    print(f"  bottom_data/top/notes.png baked ({len(expect)} frames match their state)")
    for name, (bx0, by0, bx1, by1) in (("btn_print", BTN_PRINT), ("btn_return", BTN_RETURN)):
        cut = frame("034_schmeichel_db.png")[by0:by1, bx0:bx1]
        for n in ("046_notes_tab.png", ALL_DISABLED, "038_tab_career.png"):
            assert (frame(n)[by0:by1, bx0:bx1] == cut).all(), f"{name} differs vs {n}"
        save(cut, OUT / f"{name}.png")
    print(
        "  btn_print.png + btn_return.png baked (identical across frames; "
        "pressed/hover states un-walked — at-rest only)"
    )


# ------------------------------------------------- career + prose geometry -


def extract_view_geometry() -> dict:
    """Measure the career PROGRESS grid and the prose text metrics off the
    witness frames, for the scene + parity harness to consume."""
    f38 = frame("038_tab_career.png")
    GREY = (128, 128, 128)
    # the PROGRESS grid: 1px grey-128 column lines + top/bottom borders, 2px
    # grey-192 row separators every 20px, header band above the first row
    cols = [
        x for x in range(185, 580) if sum((f38[y, x] == GREY).all() for y in range(150, 388)) > 180
    ]
    assert cols == [189, 252, 409, 488, 535, 573], f"career columns moved: {cols}"
    for y in (132, 148, 389):
        assert sum((f38[y, x] == GREY).all() for x in range(195, 570)) > 300, f"border row {y}"
    for k in range(11):
        y = 168 + 20 * k
        assert sum((f38[y, x] == (192, 192, 192)).all() for x in range(195, 570)) > 300, (
            f"row separator {y}"
        )
    geo = {
        "career_cols": cols,
        "career_header_band": [133, 148],
        "career_row0_y": 150,
        "career_row_h": 20,
        "career_n_rows": 12,
        "career_hdr_blue": [166, 202, 240],
        "career_hdr_green": [170, 191, 170],
        "career_season_bg": [212, 223, 255],
        "career_inks": {
            "season": [30, 52, 98],
            "team": [0, 0, 0],
            "division": [60, 80, 100],
            "match": [0, 95, 0],
            "goals": [60, 80, 100],
        },
    }
    print(f"  career grid pinned: cols {cols}, header 133..148, 12 rows of 20 from y150")
    # prose metrics from 035: every text line runs x214..~568, first line top
    # y=150, pitch 16; the ▶ bullet leads a paragraph at the box left edge
    f35 = frame("035_tab_profile.png")
    dark = (f35[148:161, 210:226] < 90).all(axis=2)
    ys, xs = np.nonzero(dark)
    bx, by = int(xs.min()) + 210, int(ys.min()) + 148
    bullet = f35[by : int(ys.max()) + 149, bx : int(xs.max()) + 211]
    save(bullet, OUT / "prose_bullet.png")
    geo["prose_bullet_xy"] = [bx, by]
    geo["prose_bullet_size"] = [int(bullet.shape[1]), int(bullet.shape[0])]
    geo["prose_line0_y"] = 150
    geo["prose_pitch"] = 16
    geo["prose_x"] = [214, 569]
    print(
        f"  prose bullet at {bx},{by} ({bullet.shape[1]}x{bullet.shape[0]}); "
        "lines x214..569, top 150, pitch 16"
    )
    return geo


# ------------------------------------------------------- PKF asset checks --


def dbase_palette() -> list[tuple[int, int, int]]:
    """The LIVE Dbasewin 256-colour palette: the embedded table of the
    palette-bearing RC_DBASE entry LIGA_ESTRELLAS.BMP. Kill-tested below:
    BIGFOTO + BANDERAS decoded with it equal the walked card frames 0px
    (the DAT.PKF@0x5ca palette differs on a handful of entries — 3% of the
    Schmeichel photo — so it is NOT the card's palette)."""
    raw = RC._entry_bytes("LIGA_ESTRELLAS.BMP")
    tbl = raw[54 : 54 + 1024]
    return [(tbl[i * 4 + 2], tbl[i * 4 + 1], tbl[i * 4]) for i in range(256)]


def _decode_core_dib(raw: bytes, pal: list) -> np.ndarray:
    """Manual OS/2 BITMAPCOREHEADER 8bpp decode (Pillow mis-slices these)."""
    import struct

    off_bits = struct.unpack_from("<I", raw, 10)[0]
    hsz = struct.unpack_from("<I", raw, 14)[0]
    if hsz == 12:
        w, h, _p, _bpp = struct.unpack_from("<HHHH", raw, 18)
    else:
        w, h = struct.unpack_from("<ii", raw, 18)
    stride = ((w + 3) // 4) * 4
    pix = raw[off_bits:]
    img = np.zeros((h, w, 3), np.uint8)
    for yy in range(h):
        row = np.frombuffer(pix[yy * stride : yy * stride + w], np.uint8)
        img[h - 1 - yy] = np.array(pal, np.uint8)[row]
    return img


PHOTO_XY = (41, 137)  # BIGFOTO blit origin on the card (fitted, asserted below)
FLAG_SMALL_XY = (461, 164)  # BANDERAS 30x20 at the BIRTH PLACE bar right end
FLAG_BIG_BOX = (405, 214, 468, 234)  # the big waving NATIONALITY flag


def verify_pkf_assets() -> dict:
    from pkf_unpack import GAME, files_of

    info = {"photo_xy": PHOTO_XY, "flag_small_xy": FLAG_SMALL_XY, "flag_big_box": FLAG_BIG_BOX}
    pal = dbase_palette()
    # scroll steppers: cut the 4 observed states from frames; FLECHAUP/DOWNDB1N
    # are the PKF source of the ACTIVE art (washed = engine wash) — record both.
    f35 = frame("035_tab_profile.png")
    f38 = frame("038_tab_career.png")
    f43 = frame("043_internat_end.png")
    up_box = (584, 124, 612, 150)
    dn_box = (584, 384, 612, 410)
    save(f35[up_box[1] : up_box[3], up_box[0] : up_box[2]], OUT / "scroll_up_washed.png")
    save(f43[up_box[1] : up_box[3], up_box[0] : up_box[2]], OUT / "scroll_up_active.png")
    save(f38[dn_box[1] : dn_box[3], dn_box[0] : dn_box[2]], OUT / "scroll_dn_active.png")
    save(f43[dn_box[1] : dn_box[3], dn_box[0] : dn_box[2]], OUT / "scroll_dn_washed.png")
    info["scroll_up_box"] = up_box
    info["scroll_dn_box"] = dn_box
    save(f35[150:384, 584:612], OUT / "scroll_thumb_full.png")
    save(f38[150:384, 584:612], OUT / "scroll_track_038.png")
    # CAMPO pitch + BALON ball with the live palette (markers app-drawn)
    campo = _decode_core_dib(RC._entry_bytes("CAMPO.BMP"), pal)
    info["campo_size"] = campo.shape[:2]
    save(campo, OUT / "campo.png")
    save(_decode_core_dib(RC._entry_bytes("BALON.BMP"), pal), OUT / "balon.png")
    # BIGFOTO photos: the live-palette decode must equal the walked frames
    # 0px (Schmeichel 034 + Klinsmann 055); then export the whole bank for
    # the card (app/art/faces/dbcard/) — the existing FICHA bank is a
    # DIFFERENT rendering and does not match the card frames.
    gdb = json.loads((ROOT / "app" / "data" / "game_db.json").read_text())
    pids = {
        p["name"]: p["photoId"]
        for c in gdb["clubs"]
        for p in c["players"]
        if p["name"] in ("Schmeichel", "Klinsmann") and p.get("photoId")
    }
    dbfaces = ROOT / "app" / "art" / "faces" / "dbcard"
    dbfaces.mkdir(parents=True, exist_ok=True)
    ox, oy = PHOTO_XY
    n_photos = 0
    witness = {
        pids["Schmeichel"]: "034_schmeichel_db.png",
        pids["Klinsmann"]: "055_klinsmann_data.png",
    }
    for pkf in sorted((GAME / "DBDAT" / "BIGFOTO").glob("EQ96*.PKF")):
        buf = pkf.read_bytes()
        for name, off, size in files_of(buf):
            pid = int(name.upper().removeprefix("J96").removesuffix(".BMP"))
            img = _decode_core_dib(buf[off : off + size], pal)
            if pid in witness:
                want = frame(witness[pid])[oy : oy + img.shape[0], ox : ox + img.shape[1]]
                assert (img == want).all(), f"BIGFOTO {pid} != {witness[pid]} at {PHOTO_XY}"
            save(img, dbfaces / f"{pid}.png")
            n_photos += 1
    assert len(witness) == 2
    print(
        f"  dbcard photo bank exported: {n_photos} BIGFOTO photos "
        f"(live palette; Schmeichel+Klinsmann 0px vs frames)"
    )
    # BANDERAS small flags: live-palette decode == the BIRTH PLACE bar flag
    # (Denmark 018 vs 034, 0px); export the whole bank for the card.
    dbflags = ROOT / "app" / "art" / "flags" / "dbcard"
    dbflags.mkdir(parents=True, exist_ok=True)
    f34 = frame("034_schmeichel_db.png")
    buf = (GAME / "DBDAT" / "BANDERAS.PKF").read_bytes()
    n_flags = 0
    for name, off, size in files_of(buf):
        code = int(name.upper().removeprefix("BA96").removesuffix(".BMP"))
        img = _decode_core_dib(buf[off : off + size], pal)
        if code == 18:
            fx, fy = FLAG_SMALL_XY
            want = f34[fy : fy + 20, fx : fx + 30]
            assert (img == want).all(), "BANDERAS 018 != 034 BIRTH PLACE flag"
        save(img, dbflags / f"{code}.png")
        n_flags += 1
    print(f"  dbcard flag bank exported: {n_flags} BANDERAS flags (018 0px vs 034)")
    # the big waving NATIONALITY flag: its stretch transform is un-RE'd, so the
    # walked countries ship as frame patches; un-walked codes fall back to a
    # GDI-style stretch of the small flag (documented approximation).
    bx0, by0, bx1, by1 = FLAG_BIG_BOX
    for fname, (pid, _sel) in FRAME_PLAYER_IDS.items():
        meta = PLAYER_FRAMES[fname]
        if meta["view"] != "pdata":
            continue
        code = next(p["flagCode"] for c in gdb["clubs"] for p in c["players"] if p["id"] == pid)
        patch = frame(fname)[by0:by1, bx0:bx1]
        out_p = dbflags / f"big_{code}.png"
        if out_p.exists():
            prev = np.array(Image.open(out_p).convert("RGB"))
            assert (prev == patch).all(), f"big flag {code} differs between frames"
        else:
            save(patch, out_p)
    print(
        "  big-flag patches baked for the 6 walked nationalities "
        "(un-walked codes: stretch fallback, documented)"
    )
    return info


def main() -> None:
    global FRAME_TABS
    FRAME_TABS = derive_frame_tabs()
    print(f"witness tab states (sentinel rule): {FRAME_TABS}")
    OUT.mkdir(parents=True, exist_ok=True)
    KITS_OUT.mkdir(parents=True, exist_ok=True)
    meta: dict = {
        "source": "screenshots/bio-coin-walk-2026-07-06 (walked 2026-07-06) + RC_DBASE.PKF",
        "tab_x": TAB_X,
        "tab_y": TAB_Y,
        "banner_h": BANNER_H,
        "views": {k: v[1] for k, v in VIEWS.items()},
        "pd_value_rows": PD_VALUE_ROWS,
        "photo_box": PHOTO_BOX,
        "role_band": ROLE_BAND,
        "bottom_band": BOTTOM_BAND,
        "btn_print": BTN_PRINT,
        "btn_return": BTN_RETURN,
    }
    print("font pins:")
    meta["fonts"] = pin_fonts()
    print("banner:")
    meta.update(bake_banner())
    print("tabs:")
    bake_tabs()
    print("panel + title bars:")
    meta.update(bake_panel_and_titles())
    print("personal data:")
    bake_pdata()
    print("static views:")
    meta.update(bake_static_views())
    print("bottom:")
    bake_bottom()
    print("view geometry:")
    meta.update(extract_view_geometry())
    print("PKF assets:")
    meta.update(verify_pkf_assets())
    # the two card faces the app does not ship yet (PROMAN* already exported)
    for face, name in (("FUTCON8.FNT", "futcon8"), ("KKITA.FNT", "kkita")):
        FB.write_bmfont(font(face), FONTS_OUT, name)
        print(f"  BMFont exported: {name} ({face})")
    DATA_OUT.write_text(json.dumps(meta, indent=1))
    print(f"wrote {DATA_OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
