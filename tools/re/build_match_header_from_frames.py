#!/usr/bin/env python3
"""Bake the shared MATCH-CONTEXT BARRA/HEADER (the y<62 band above every
management/tactics screen in a fixture week) from the real game's own frames.

Same doctrine as build_tactics_chrome_from_frames.py (owner: "IT NEEDS TO BE
EXACT"): the static furniture IS the original frame with every state-dependent
pixel reconstructed from cross-frame evidence; the screens draw the dynamic
layer (club names, kits, calendar date, status plaques, screen title) on top
with the game's own fonts + PKF art. Nothing is invented: every reconstruction
below is either witnessed by a frame that shows the pixel uncovered, or is an
exact re-render with a decoded WINFONTS face asserted XOR=0 against the frame.

Binding frame (committed, drives the tactics_014 full-frame parity pair):
  014_162413  TACTICS, F.C. Barcelona / Manchester Utd., Monday 4 August 1997
Witness frames (local walkthrough set; recomposed pixel-exact below):
  015_162415  VIEW RIVAL          same fixture/date        (title sprite)
  155_162931  LINE-UP             Manchester Utd. / Sao Paulo, Wednesday 6
  138_154814  TACTICS (run 1)     Juventus / Manchester Utd., Friday 1
  128_154751  LINE-UP (run 1)     Juventus / Manchester Utd., Friday 1
  058_162622  MAN-TO-MAN MARKINGS manager mode: MWM / Manchester Utd. + NANO kit

Frame-decoded facts this bake rests on (all asserted below):
- The header family = every walkthrough frame whose top band differs from 014
  on <13% of pixels (61 frames, both runs). Outside the declared dynamic zones
  ALL of them are pixel-identical: the furniture (barra gradient + blocks, the
  two name plaques, the kit panel, the calendar sheet, the two green status
  plaques, the ball) never moves. 040_162531 carries the mouse cursor in-band
  and is dropped.
- Name plaques: flat faces (180,200,220) top / (80,100,120) bottom spanning
  x0..107 (the kit panel's black border sits at x108); text is PROMAN8.FNT
  (XOR=0: 'F.C. Barcelona', 'Manchester Utd.', 'Sao Paulo', 'MWM',
  'Juventus'), black ink on the top plaque, white on the bottom, GDI-centred:
  px = (S - text_extent) // 2 with S=107 (top) / S=108 (bottom) — the unique
  S fitting every walked origin (widths 27..98). No clipping.
- Kit panel: fixture mode blits the club's RIDIESC.PKF 17x20 kit 1:1 at
  (116,10) home / (116,30) away — SAD 0.0, no shadow pass. Manager mode (058)
  blits the NANOESC 24x32 kit at (114,15) WITH the soft shadow pass known from
  the SELECCION panel kits, so the walked club is cut as a frame patch.
- Calendar sheet: flat white; four PROMAN8 lines (weekday black, day red
  (255,0,0), month black, year blue (42,95,170)), each GDI-centred:
  px = (968 - extent)//2 — S=968 is the UNIQUE fit over all eight walked
  strings (Monday/Wednesday/Friday/4/6/1/August/1997).
- Status plaques: flat faces (127,159,85) top / (85,95,0) bottom; text is the
  Result face (CALEND12.FNT, exported as calend12), black on top / white on
  bottom, GDI-centred px = (1163 - extent)//2 ('Preseason'/'Preparation',
  XOR=0; S in {1163,1164} — only two walked strings, 1163 recorded). The ball
  sprite overlaps the plaques' right ends and stays baked in the band (no
  walked text reaches it).
- Screen title: the big chrome-gradient face is NOT a 1-bpp WINFONTS render
  (no FNT matches; the glyphs carry a multi-colour gradient + outline), so
  titles are cut as frame sprites over the reconstructed band — the exact
  precedent of the PRESEASON title_band bake. TACTICS is additionally
  witnessed identical between run 1 (138) and run 2 (014).

Un-walked reconstructions (documented, invisible in every walked state):
- The kit-panel core (x116..132, y15..46) is covered by a kit in EVERY family
  frame under both layouts; it is filled with the panel face colour. The panel
  never renders empty in-game, so any error hides under a kit.
- Status/name/calendar text for values no frame shows re-render with the
  asserted fonts + centring rules; the rules are only proven on the walked
  strings.

Outputs:
  app/art/screens/header/band.png                640x62 static furniture
  app/art/screens/header/title_{tactics,viewrival,lineup,mtm}.png + offsets
  app/art/screens/header/header_samples.json     anchors/rules/colours
  app/art/kits/ridi/<club_id>.png                RIDIESC 17x20 fixture kits
  app/art/kits/header/40.png                     058 manager-mode NANO patch
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import pkf_unpack as pk  # noqa: E402
from export_art import vga_palette  # noqa: E402
from export_icons import decode_dib  # noqa: E402
from fnt_to_bmfont import WINFONTS, Fnt  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
FRAMES = ROOT / "screenshots" / "original-walkthrough-2026-07-02"
OUT = ROOT / "app" / "art" / "screens" / "header"
KITS_RIDI = ROOT / "app" / "art" / "kits" / "ridi"
KITS_HDR = ROOT / "app" / "art" / "kits" / "header"
DBDAT = ROOT / "extracted" / "Premier Manager 98" / "DBDAT"

F014 = "014_162413.png"
BAND_H = 62
CURSOR_FRAME = "040_162531.png"

# dynamic zones (x0,y0,x1,y1 exclusive) — everything outside is asserted static
TITLE_ZONE = (168, 14, 432, 44)
KIT_ZONE = (108, 8, 143, 52)
NAME_TOP_FACE = (0, 15, 108, 29)  # plate face x0..107; border col x108 excluded
NAME_BOT_FACE = (0, 32, 108, 48)
CAL_SHEET = (449, 14, 517, 55)  # sheet interior: below the spiral binding
# (black bits end y12), left of the black
# right-edge fold pixels (x>=520)
STAT_TOP_FACE = (549, 15, 611, 29)
STAT_BOT_FACE = (549, 32, 611, 48)
DYN_ZONES = [
    TITLE_ZONE,
    KIT_ZONE,
    NAME_TOP_FACE,
    NAME_BOT_FACE,
    CAL_SHEET,
    STAT_TOP_FACE,
    STAT_BOT_FACE,
]

C_NAME_TOP = (180, 200, 220)
C_NAME_BOT = (80, 100, 120)
C_STAT_TOP = (127, 159, 85)
C_STAT_BOT = (85, 95, 0)
C_SHEET = (255, 255, 255)
C_RED = (255, 0, 0)
C_BLUE = (42, 95, 170)
C_BLACK = (0, 0, 0)
C_WHITE = (255, 255, 255)

CAL_S = 968  # GDI centre: px = (S - extent)//2; unique fit, 8 walked strings
STAT_S = 1163  # same rule; S in {1163,1164} on the two walked strings

# fixture kit blit (RIDIESC 17x20, 1:1, no shadow — SAD 0.0 on 014)
RIDI_XY_HOME = (116, 10)
RIDI_XY_AWAY = (116, 30)
NANO_XY = (114, 15)  # manager-mode NANOESC anchor inside the 058 panel patch

# witness frame states: frame -> (top name, bottom name, weekday, day, title key)
WITNESS = {
    "014_162413.png": ("F.C. Barcelona", "Manchester Utd.", "Monday", "4", "tactics"),
    "015_162415.png": ("F.C. Barcelona", "Manchester Utd.", "Monday", "4", "viewrival"),
    "155_162931.png": ("Manchester Utd.", "Sao Paulo", "Wednesday", "6", "lineup"),
    "138_154814.png": ("Juventus", "Manchester Utd.", "Friday", "1", "tactics"),
    "128_154751.png": ("Juventus", "Manchester Utd.", "Friday", "1", "lineup"),
    "058_162622.png": ("MWM", "Manchester Utd.", "Monday", "4", "mtm"),
}
# frame -> (home club id or None, away/own club id) for the kit blits
WITNESS_KITS = {
    "014_162413.png": (1000, 40),
    "015_162415.png": (1000, 40),
    "155_162931.png": (40, 1301),
    "138_154814.png": (1021, 40),
    "128_154751.png": (1021, 40),
    "058_162622.png": (None, 40),  # manager mode: single NANO patch
}
MONTH_YEAR = ("August", "1997")  # constant across the walked family
STATUS = ("Preseason", "Preparation")


def load_frame(name: str) -> np.ndarray:
    a = np.asarray(Image.open(FRAMES / name).convert("RGB"))
    if a.shape[0] != 480 or a.shape[1] not in (640, 641):
        raise SystemExit(f"{name}: unexpected size {a.shape}")
    return a[:, :640].astype(int)


def expect(cond: bool, what: str) -> None:
    if not cond:
        raise SystemExit(f"frame invariant FAILED: {what}")


def save(a: np.ndarray, p: Path) -> None:
    p.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(a.astype("uint8")).save(p)
    print(f"  {p.relative_to(ROOT)}  {a.shape[1]}x{a.shape[0]}")


def in_zones(x: int, y: int) -> bool:
    return any(x0 <= x < x1 and y0 <= y < y1 for x0, y0, x1, y1 in DYN_ZONES)


# ---- 1-bpp WINFONTS rendering (GDI TextOut semantics: advance == width) ----

_FNT_CACHE: dict[str, Fnt] = {}


def fnt(name: str) -> Fnt:
    if name not in _FNT_CACHE:
        _FNT_CACHE[name] = Fnt((WINFONTS / name).read_bytes())
    return _FNT_CACHE[name]


def render_text(f: Fnt, text: str) -> np.ndarray:
    """bool canvas (pix_height x sum-of-widths), glyph origin at each advance."""
    widths = []
    for c in text:
        i = ord(c) - f.first
        widths.append(f.entries[i][0] if 0 <= i < len(f.entries) - 1 else 0)
    canvas = np.zeros((f.pix_height, max(sum(widths), 1)), bool)
    x = 0
    for c, w in zip(text, widths):
        i = ord(c) - f.first
        if w and 0 <= i < len(f.entries) - 1:
            _, im = f.glyph(i)
            canvas[:, x : x + w] |= (np.asarray(im) > 0)[:, :w]
        x += w
    return canvas


def text_width(f: Fnt, text: str) -> int:
    return sum(
        f.entries[ord(c) - f.first][0] for c in text if 0 <= ord(c) - f.first < len(f.entries) - 1
    )


def blit_text(a: np.ndarray, f: Fnt, text: str, x: int, y: int, ink, clip=None) -> None:
    """Paint glyph pixels (canvas row 0 at y) with ink, clipped to clip=(x0,x1)."""
    r = render_text(f, text)
    for yy, xx in zip(*np.where(r)):
        px, py = x + int(xx), y + int(yy)
        if clip is not None and not (clip[0] <= px < clip[1]):
            continue
        if 0 <= px < a.shape[1] and 0 <= py < a.shape[0]:
            a[py, px] = ink


def mask_of(a: np.ndarray, rect, rgb, tol=0) -> np.ndarray:
    """Bool mask (band coords) of pixels within rect matching rgb exactly."""
    m = np.zeros(a.shape[:2], bool)
    x0, y0, x1, y1 = rect
    reg = a[y0:y1, x0:x1]
    m[y0:y1, x0:x1] = np.abs(reg - np.array(rgb)).sum(axis=2) <= tol
    return m


# ---- kit banks -------------------------------------------------------------


def pkf_entries(path: Path) -> dict:
    buf = path.read_bytes()
    return buf, {e["name"]: e for e in pk.parse(buf) if e.get("type") == 2}


def club_kit_codes() -> dict[int, str]:
    """game_db club id -> EQ96 code. English via the verified crest_codes map;
    foreign clubs via exact name match against the EQUIPOS index records."""
    cc = json.loads((ROOT / "assets" / "crest_codes.json").read_text())
    db = json.loads((ROOT / "app" / "data" / "game_db.json").read_text())
    out = {int(k): v for k, v in cc["english"].items()}
    by_name = {}
    for r in cc["allRecords"]:
        by_name.setdefault(r["name"], r["code"])
    misses = []
    for c in db["clubs"]:
        cid = int(c["id"])
        if cid in out:
            continue
        code = by_name.get(str(c.get("name", "")))
        if code:
            out[cid] = code
        else:
            misses.append(str(c.get("name", "")))
    if misses:
        print(
            f"  (no EQ96 name match for {len(misses)} clubs — no ridi kit exported:"
            f" {misses[:6]}{'...' if len(misses) > 6 else ''})"
        )
    return out


def main() -> None:
    f014 = load_frame(F014)
    band14 = f014[:BAND_H].copy()

    # ---- family: every frame whose top band is 014 modulo the dynamic zones --
    family: dict[str, np.ndarray] = {}
    for p in sorted(FRAMES.glob("*.png")):
        a = np.asarray(Image.open(p).convert("RGB"))
        if a.shape[0] != 480 or a.shape[1] not in (640, 641):
            continue
        top = a[:BAND_H, :640].astype(int)
        frac = (np.abs(top - band14).mean(axis=2) > 8).mean()
        if frac < 0.13 and p.name not in (F014, CURSOR_FRAME):
            family[p.name] = top
    print(f"header family: {len(family)} frames + binding {F014}")
    expect(len(family) >= 50, f"family too small ({len(family)}) — scan drifted")
    for w in WITNESS:
        expect(w == F014 or w in family, f"witness {w} not in family")

    # ---- static assert: identical everywhere outside the dynamic zones ------
    stat_mask = np.ones((BAND_H, 640), bool)
    for x0, y0, x1, y1 in DYN_ZONES:
        stat_mask[y0:y1, x0:x1] = False
    for n, top in family.items():
        bad = (top != band14).any(axis=2) & stat_mask
        expect(
            not bad.any(),
            f"{n}: {int(bad.sum())} static px differ, first at "
            f"{tuple(np.argwhere(bad)[0][::-1]) if bad.any() else None}",
        )
    print("  static furniture identical across the family outside dynamic zones")

    band = band14.copy()
    frames_all = {F014: band14, **family}

    # ---- title zone: cluster-majority reconstruction ------------------------
    tx0, ty0, tx1, ty1 = TITLE_ZONE
    # The barra under the titles is an x-dithered gradient. A plain per-frame
    # mode lets a large title bloc (18 LINE-UP frames) out-vote the barra, so
    # the estimator is per-pixel majority over the DISTINCT TITLES (frames
    # clustered by title-zone equality; one title, one vote). Any residual
    # pixel every walked title inks identically is unwitnessed — it cannot
    # affect parity (each walked title's sprite recomposes its frame exactly)
    # and is reported below.
    zclusters: list[dict] = []
    for n, top in frames_all.items():
        z = top[ty0:ty1, tx0:tx1]
        for c in zclusters:
            if (c["z"] == z).all():
                c["names"].append(n)
                break
        else:
            zclusters.append({"z": z, "names": [n]})
    Z = np.stack([c["z"] for c in zclusters])
    zpk = (Z[..., 0] << 16) | (Z[..., 1] << 8) | Z[..., 2]
    n_thin = 0
    for y in range(ty1 - ty0):
        for x in range(tx1 - tx0):
            vals, counts = np.unique(zpk[:, y, x], return_counts=True)
            k = counts.argmax()
            if int(counts[k]) <= len(zclusters) // 2:
                n_thin += 1
            v = int(vals[k])
            band[ty0 + y, tx0 + x] = (v >> 16 & 255, v >> 8 & 255, v & 255)
    print(
        f"  title zone: {len(zclusters)} title clusters, cluster-majority "
        f"band; {n_thin} px below a strict majority (reported, parity-safe)"
    )

    # ---- kit panel: background from witness frames whose kit blits provably
    # do NOT cover the pixel (transparent sprite holes included); the residue
    # covered under every walked layout gets the panel face (never visible).
    kx0, ky0, kx1, ky1 = KIT_ZONE
    codes = club_kit_codes()
    ridi_buf, ridi_ents = pkf_entries(DBDAT / "RIDIESC.PKF")
    pal = vga_palette()

    def ridi_kit(cid: int) -> np.ndarray | None:
        code = codes.get(cid)
        e = ridi_ents.get(f"EQ96{code}.BMP") if code else None
        if e is None:
            return None
        off, size, _f = e["u32s"]
        return np.asarray(decode_dib(ridi_buf[off : off + size], pal)).astype(int)

    # 058 shows the panel in its MANAGER state (different furniture: no
    # fixture border box), so the band carries the FIXTURE panel and manager
    # mode overlays its whole panel zone as a frame patch cut below.
    cover = {}  # fixture frame -> bool mask of pixels its kit blit may touch
    for fr, (home, away) in WITNESS_KITS.items():
        if home is None:
            continue
        c = np.zeros((BAND_H, 640), bool)
        for cid, xy in ((home, RIDI_XY_HOME), (away, RIDI_XY_AWAY)):
            k = ridi_kit(cid)
            expect(k is not None, f"no ridi kit for club {cid}")
            c[xy[1] : xy[1] + k.shape[0], xy[0] : xy[0] + k.shape[1]] |= k[..., 3] > 0
        cover[fr] = c

    n_core = 0
    for y in range(ky0, ky1):
        for x in range(kx0, kx1):
            vals = {tuple(frames_all[fr][y, x]) for fr in cover if not cover[fr][y, x]}
            if vals:
                expect(len(vals) == 1, f"kit panel px ({x},{y}): witnesses disagree {vals}")
                band[y, x] = np.array(vals.pop())
            else:
                n_core += 1
                band[y, x] = (140, 140, 180)  # panel face (witnessed neighbours)
    print(
        f"  kit panel: fixture-witness-reconstructed; {n_core} never-visible "
        f"core px filled with the face colour"
    )

    # ---- fonts + fitted text rules ------------------------------------------
    f_pm8 = fnt("PROMAN8.FNT")
    f_res = fnt("CALEND12.FNT")  # face 'Result' — the exported calend12

    def text_mask(frame: str, rect, ink) -> np.ndarray:
        return mask_of(frames_all[frame], rect, ink)

    # fit the name-plaque centring sum S (px = (S - extent)//2) over all witnesses
    def fit_names(face_rect, ink_of):
        obs = []
        for fr, (topn, botn, *_rest) in WITNESS.items():
            s = topn if face_rect is NAME_TOP_FACE else botn
            m = text_mask(fr, face_rect, ink_of)
            ys, xs = np.where(m)
            expect(ys.size > 0, f"{fr}: empty name mask")
            r = render_text(f_pm8, s)
            origin = int(xs.min()) - int(np.where(r.any(axis=0))[0].min())
            gy = int(ys.min()) - int(np.where(r.any(axis=1))[0].min())
            # the mask must BE the render at that origin (no clipping)
            pred = np.zeros_like(m)
            for yy, xx in zip(*np.where(r)):
                pred[gy + int(yy), origin + int(xx)] = True
            expect((pred == m).all(), f"{fr}: name '{s}' render != mask")
            obs.append((fr, s, m, origin, gy))
        cands = None
        for _fr, s, _m, origin, _gy in obs:
            w = text_width(f_pm8, s)
            ok = {S for S in range(80, 140) if (S - w) // 2 == origin}
            cands = ok if cands is None else (cands & ok)
        expect(bool(cands), "name centring: no S fits all origins")
        return sorted(cands)[0], obs

    top_S, top_obs = fit_names(NAME_TOP_FACE, C_BLACK)
    bot_S, bot_obs = fit_names(NAME_BOT_FACE, C_WHITE)
    print(f"  name centring: top S={top_S}, bottom S={bot_S} (px=(S-extent)//2)")

    # name text rows (glyph canvas top): constant across witnesses
    def glyph_top(obs):
        tops = {gy for _fr, _s, _m, _o, gy in obs}
        expect(len(tops) == 1, f"name glyph top varies: {tops}")
        return tops.pop()

    top_y = glyph_top(top_obs)
    bot_y = glyph_top(bot_obs)

    # erase the 014 name texts (flat faces under them)
    for rect, ink, face_c in (
        (NAME_TOP_FACE, C_BLACK, C_NAME_TOP),
        (NAME_BOT_FACE, C_WHITE, C_NAME_BOT),
    ):
        m = text_mask(F014, rect, ink)
        band[m] = face_c

    # ---- calendar: erase the four PROMAN8 lines, assert render == mask ------
    cal_lines = []  # (key, colour, glyph_top_y)
    wd, dd = WITNESS[F014][2], WITNESS[F014][3]
    for key, s, col in (
        ("weekday", wd, C_BLACK),
        ("day", dd, C_RED),
        ("month", MONTH_YEAR[0], C_BLACK),
        ("year", MONTH_YEAR[1], C_BLUE),
    ):
        m = text_mask(F014, CAL_SHEET, col)
        if key in ("weekday", "month"):  # two black lines share the colour: split by row
            ys = np.where(m.any(axis=1))[0]
            groups = np.split(ys, np.where(np.diff(ys) > 2)[0] + 1)
            expect(len(groups) == 2, f"calendar black rows: {len(groups)} groups")
            g = groups[0] if key == "weekday" else groups[1]
            mm = np.zeros_like(m)
            mm[g.min() : g.max() + 1] = m[g.min() : g.max() + 1]
            m = mm
        r = render_text(f_pm8, s)
        px = (CAL_S - text_width(f_pm8, s)) // 2
        ys, xs = np.where(m)
        gy = int(ys.min()) - int(np.where(r.any(axis=1))[0].min())
        pred = np.zeros_like(m)
        for yy, xx in zip(*np.where(r)):
            pred[gy + int(yy), px + int(xx)] = True
        expect((pred == m).all(), f"calendar {key} '{s}': render != frame mask")
        band[m] = C_SHEET
        cal_lines.append((key, col, gy))
    print(
        f"  calendar lines XOR=0 (PROMAN8, px=({CAL_S}-extent)//2): "
        f"{[(k, y) for k, _c, y in cal_lines]}"
    )

    # ---- status plaques: erase Result-face texts ----------------------------
    stat_rows = []
    for rect, s, ink, face_c in (
        (STAT_TOP_FACE, STATUS[0], C_BLACK, C_STAT_TOP),
        (STAT_BOT_FACE, STATUS[1], C_WHITE, C_STAT_BOT),
    ):
        m = text_mask(F014, rect, ink)
        r = render_text(f_res, s)
        px = (STAT_S - text_width(f_res, s)) // 2
        ys, xs = np.where(m)
        gy = int(ys.min()) - int(np.where(r.any(axis=1))[0].min())
        pred = np.zeros_like(m)
        for yy, xx in zip(*np.where(r)):
            pred[gy + int(yy), px + int(xx)] = True
        expect((pred == m).all(), f"status '{s}': render != frame mask")
        # pred==mask above already proves no ball pixel leaked into the mask;
        # 'Preparation' ends at x609, the ball's leftmost pixels sit at x>=612.
        expect(int(np.where(m.any(axis=0))[0].max()) <= 609, f"status '{s}' reaches the ball zone")
        band[m] = face_c
        stat_rows.append(gy)
    print(f"  status texts XOR=0 (Result face, px=({STAT_S}-extent)//2), rows {stat_rows}")

    # ---- kits: RIDIESC fixture blits (assert SAD 0), 058 NANO patch ---------
    def assert_ridi(frame: str, cid: int, xy) -> None:
        k = ridi_kit(cid)
        expect(k is not None, f"no ridi kit for club {cid}")
        op = k[..., 3] > 0
        reg = frames_all[frame][xy[1] : xy[1] + k.shape[0], xy[0] : xy[0] + k.shape[1]]
        sad = int((np.abs(reg - k[..., :3]).sum(axis=2) * op).sum())
        expect(sad == 0, f"{frame}: ridi kit {cid} at {xy} SAD={sad}")

    for fr, (home, away) in WITNESS_KITS.items():
        if home is not None:
            assert_ridi(fr, home, RIDI_XY_HOME)
            assert_ridi(fr, away, RIDI_XY_AWAY)
    print("  RIDIESC fixture kits SAD=0 on all fixture witnesses")

    # export ridi kits for every mapped club
    KITS_RIDI.mkdir(parents=True, exist_ok=True)
    n_exp = 0
    for cid, code in sorted(codes.items()):
        e = ridi_ents.get(f"EQ96{code}.BMP")
        if e is None:
            continue
        off, size, _f = e["u32s"]
        decode_dib(ridi_buf[off : off + size], pal).save(KITS_RIDI / f"{cid}.png")
        n_exp += 1
    print(f"  exported {n_exp} RIDIESC kits -> app/art/kits/ridi/")

    # 058 manager-mode panel patch: the WHOLE kit zone in its manager state
    # (different panel furniture + NANO kit with the engine's shadow pass)
    px0, py0, px1, py1 = kx0, ky0, kx1, ky1
    patch = frames_all["058_162622.png"][py0:py1, px0:px1]
    save(patch, KITS_HDR / "40.png")

    # ---- title sprites over the reconstructed band --------------------------
    titles = {}
    for fr, (_t, _b, _wd, _dd, key) in WITNESS.items():
        if key in titles:
            # same title from another frame: assert the pixels agree (run1 vs run2)
            other = titles[key]["frame"]
            z = frames_all[fr][ty0:ty1, tx0:tx1]
            zo = frames_all[other][ty0:ty1, tx0:tx1]
            expect((z == zo).all(), f"title '{key}': {fr} differs from {other}")
            continue
        z = frames_all[fr][ty0:ty1, tx0:tx1]
        diff = (z != band[ty0:ty1, tx0:tx1]).any(axis=2)
        ys, xs = np.where(diff)
        expect(ys.size > 0, f"{fr}: empty title sprite")
        x0s, x1s = int(xs.min()), int(xs.max()) + 1
        y0s, y1s = int(ys.min()), int(ys.max()) + 1
        rgba = np.zeros((y1s - y0s, x1s - x0s, 4), np.uint8)
        rgba[..., :3] = z[y0s:y1s, x0s:x1s]
        rgba[..., 3] = diff[y0s:y1s, x0s:x1s] * 255
        p = OUT / f"title_{key}.png"
        p.parent.mkdir(parents=True, exist_ok=True)
        Image.fromarray(rgba).save(p)
        titles[key] = {"frame": fr, "x": tx0 + x0s, "y": ty0 + y0s, "w": x1s - x0s, "h": y1s - y0s}
        print(f"  {p.relative_to(ROOT)}  {x1s - x0s}x{y1s - y0s} at ({tx0 + x0s},{ty0 + y0s})")

    # ---- master recompose: every witness frame, pixel-exact -----------------
    def compose(fr: str) -> np.ndarray:
        topn, botn, wd_, dd_, key = WITNESS[fr]
        home, away = WITNESS_KITS[fr]
        a = band.copy()
        # names
        for s, S, gy, ink in ((topn, top_S, top_y, C_BLACK), (botn, bot_S, bot_y, C_WHITE)):
            blit_text(a, f_pm8, s, (S - text_width(f_pm8, s)) // 2, gy, ink, clip=(0, 108))
        # kits
        if home is not None:
            for cid, xy in ((home, RIDI_XY_HOME), (away, RIDI_XY_AWAY)):
                k = ridi_kit(cid)
                op = k[..., 3] > 0
                reg = a[xy[1] : xy[1] + k.shape[0], xy[0] : xy[0] + k.shape[1]]
                reg[op] = k[..., :3][op]
        else:
            a[py0:py1, px0:px1] = patch
        # calendar
        for (keyc, col, gy), s in zip(cal_lines, (wd_, dd_, *MONTH_YEAR)):
            blit_text(a, f_pm8, s, (CAL_S - text_width(f_pm8, s)) // 2, gy, col)
        # status
        for s, gy, ink in ((STATUS[0], stat_rows[0], C_BLACK), (STATUS[1], stat_rows[1], C_WHITE)):
            blit_text(a, f_res, s, (STAT_S - text_width(f_res, s)) // 2, gy, ink)
        # title sprite
        t = titles[key]
        spr = np.asarray(Image.open(OUT / f"title_{key}.png")).astype(int)
        op = spr[..., 3] > 0
        reg = a[t["y"] : t["y"] + t["h"], t["x"] : t["x"] + t["w"]]
        reg[op] = spr[..., :3][op]
        return a

    for fr in WITNESS:
        rec = compose(fr)
        d = (rec != frames_all[fr][:BAND_H]).any(axis=2)
        if d.any():
            pts = np.argwhere(d)
            print(
                f"  recompose {fr}: {int(d.sum())}px differ, "
                f"x{pts[:, 1].min()}..{pts[:, 1].max()} "
                f"y{pts[:, 0].min()}..{pts[:, 0].max()}; first "
                f"{[tuple(p[::-1]) for p in pts[:6]]}"
            )
        expect(not d.any(), f"recompose {fr} not pixel-exact")
    print(f"  recompose PIXEL-EXACT on all {len(WITNESS)} witness frames")

    save(band, OUT / "band.png")

    # ---- samples/anchors json ------------------------------------------------
    meta = {
        "band": "band.png",
        "bandH": BAND_H,
        "names": {
            "font": "proman8",
            "top": {
                "centreS": top_S,
                "glyphTopY": top_y,
                "ink": list(C_BLACK),
                "face": list(C_NAME_TOP),
            },
            "bottom": {
                "centreS": bot_S,
                "glyphTopY": bot_y,
                "ink": list(C_WHITE),
                "face": list(C_NAME_BOT),
            },
        },
        "calendar": {
            "font": "proman8",
            "centreS": CAL_S,
            "lines": [{"key": k, "ink": list(c), "glyphTopY": y} for k, c, y in cal_lines],
        },
        "status": {
            "font": "calend12",
            "centreS": STAT_S,
            "top": {"glyphTopY": stat_rows[0], "ink": list(C_BLACK)},
            "bottom": {"glyphTopY": stat_rows[1], "ink": list(C_WHITE)},
        },
        "kits": {
            "fixture": {"bank": "ridi", "home": list(RIDI_XY_HOME), "away": list(RIDI_XY_AWAY)},
            "manager": {
                "patch": "kits/header/40.png",
                "xy": [KIT_ZONE[0], KIT_ZONE[1]],
                "nanoAnchor": list(NANO_XY),
            },
        },
        "titles": {k: {kk: v[kk] for kk in ("x", "y", "w", "h")} for k, v in titles.items()},
        "witnesses": {fr: list(st) for fr, st in WITNESS.items()},
    }
    p = OUT / "header_samples.json"
    p.write_text(json.dumps(meta, indent=1) + "\n")
    print(f"  {p.relative_to(ROOT)}")
    print("BAKE OK — all asserts passed")


if __name__ == "__main__":
    main()
