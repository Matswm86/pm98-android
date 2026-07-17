#!/usr/bin/env python3
"""Bake the PRE-MATCH XI-vs-XI PHOTO ROLL chrome + the BRIEF FULL-TIME state
from the real game's own frames (charter #5, the career match-flow chain).

Binding frames (all real MANAGER.EXE captures):
  ROLL empty    : parity-run-2026-07-16/orig/61_prematch.png   (row 1 landed,
                  away name mid-slide; rows 2..11 + header still background)
  ROLL complete : parity-run-2026-07-16/orig/63_kickoff.png    (Aston Villa v
                  Bolton W: 11 rows + kits + title band + manager row)
  ROLL complete : original-walkthrough-2026-07-02/055_162612.png (F.C.
                  Barcelona v Manchester Utd. — the second complete witness;
                  same chrome, different data -> cross-validation + inpaint)
  ROLL rolling  : original-walkthrough-2026-07-02/054_162610.png (row 2's
                  photo mid-flight below its slot — the animation witness)
  BRIEF FT      : parity-run-2026-07-16/orig/68_brief_later.png (90:00 FULL
                  TIME: KICK OFF + doors + STATISTICS gone, CONTINUE in the
                  EXIT slot)

Decoded structure (all measured here, asserted below):
  - 11 rows, band top y = 84 + 36*i, band height 32 (row pitch 36).
  - The band is NOT opaque chrome: it is the background art darkened by the
    original's ordered-dither translucency. So the band cannot be cut as an
    x-shiftable strip — instead we LEARN the per-parity colour mapping
    (bg colour -> band colour, keyed by (x+y)%2) from every clean band pixel
    of the complete witness and APPLY it to the clean background, which
    reconstructs any band pixel (including under text ink) exactly.
  - Photos: the 32x32 MINIFOTO drawn NATIVE at x284 (home) / x324 (away),
    y = band top (Schmeichel cell == art/faces/mini/3371.png at 98%+).
    Missing photo -> the black-bust placeholder (cut here).
  - Text (all proman14): home surname right-end x255, away surname left x386,
    ink top band_top+10; shirt numbers centred x40.5 / x597.5, pale blue;
    title band ink y23..33 (home club right-end x276, away left x364);
    manager row ink y57..68 (home right-end x249, away left x390), pale.

Outputs (app/art/screens/matchflow/):
  prematch_bg.png     empty state: bg + row-1 band cleaned (mount state)
  prematch_full.png   complete state: 11 clean bands + title strip (the
                      screen blits row/header strips from it as rows land)
  roll_sil.png        the 32x32 black-bust photo placeholder
  brief_ft.png        BRIEF at FULL TIME (brief.png + o68 button zones)
  tools/re/specs/prematch_roll_samples.json  geometry + colours + anchors

Every invariant is asserted so a regenerated capture fails loudly.
Run:  python3 tools/re/build_prematch_roll_from_frames.py
"""

from __future__ import annotations

import json
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
PARITY = ROOT / "screenshots" / "parity-run-2026-07-16" / "orig"
WALK = ROOT / "screenshots" / "original-walkthrough-2026-07-02"
ART = ROOT / "app" / "art" / "screens" / "matchflow"
SPECS = Path(__file__).resolve().parent / "specs"

F_EMPTY = PARITY / "61_prematch.png"  # row 1 only
F_EMPTY2 = WALK / "054_162610.png"  # row 1 + row-2 photo mid-flight
F_EMPTY3 = PARITY / "74_wk1_match.png"  # row 1 only (wk1: Jones|Branagan)
F_FULL_A = PARITY / "63_kickoff.png"  # complete witness A (Villa/Bolton)
F_FULL_B = WALK / "055_162612.png"  # complete witness B (Barca/ManU)
F_FT = PARITY / "68_brief_later.png"  # BRIEF at FULL TIME
WIT17 = ROOT / "screenshots" / "wine-captures-2026-07-17-matchflow"
F_RUN = WIT17 / "brief_running_exit_only.png"  # BRIEF running: EXIT only
F_ALERT = WIT17 / "brief_exit_leave_championship_alert.png"  # Yes/No alert
F_BRIEF = ART / "brief.png"  # existing baked BRIEF resting chrome
F_MINI_SCHMEICHEL = ROOT / "app" / "art" / "faces" / "mini" / "3371.png"

# ---- decoded geometry (design space 640x480) ------------------------------
ROWS = 11
ROW0_Y = 84  # row 1 band top
ROW_PITCH = 36
BAND_H = 32
CELL_W = 32  # MINIFOTO native
CELL_HOME_X = 284
CELL_AWAY_X = 324
TITLE_Y0, TITLE_Y1 = 13, 46  # title strip rows (y13..45)
MGR_Y0, MGR_Y1 = 47, 69  # manager text rows (bg only, text live)
HDR_KIT_W = 84  # kit corner zones x0..83 / x556..639

# ink zones inside a band (live-drawn at runtime; cleared in the bakes)
NUM_HOME = (5, 76)  # shirt number zone (centred x40.5)
NAME_HOME = (150, 262)  # surname right-end x255
NAME_AWAY = (380, 530)  # surname left x386
NUM_AWAY = (570, 630)  # number zone (centred x597.5)
CELLS = (CELL_HOME_X, CELL_AWAY_X + CELL_W)  # photo cells + centre gap

# BRIEF button rects (MatchScreen.BTN, padded 3px) — at FULL TIME the o68
# frame shows these zones with the buttons REMOVED (and CONTINUE in the EXIT
# slot); brief_ft.png = brief.png with exactly these zones taken from o68.
FT_PATCH = [
    (495, 227, 133, 33),
    (495, 283, 133, 33),
    (495, 339, 133, 33),
    (495, 393, 133, 30),
    (14, 393, 133, 30),
    (262, 442, 156, 30),
    (508, 442, 120, 30),
]


def load(p: Path) -> np.ndarray:
    a = np.asarray(Image.open(p).convert("RGB"))
    if a.shape[0] != 480 or a.shape[1] not in (640, 641):
        raise SystemExit(f"{p.name}: unexpected size {a.shape}")
    return a[:, :640].astype(np.int32)


def save(a: np.ndarray, rel: str) -> None:
    p = ART / rel
    p.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(a.astype("uint8")).save(p)
    print(f"  wrote {p.relative_to(ROOT)}")


def band_rows(i: int) -> tuple[int, int]:
    y0 = ROW0_Y + ROW_PITCH * i
    return y0, y0 + BAND_H


def ink_mask_band(full: np.ndarray, i: int) -> np.ndarray:
    """640-wide bool mask of live-data pixels (text ink + photo cells) inside
    band i of a complete witness: everything the runtime redraws."""
    y0, y1 = band_rows(i)
    m = np.zeros((BAND_H, 640), bool)
    for x0, x1 in (NUM_HOME, NAME_HOME, NAME_AWAY, NUM_AWAY):
        z = full[y0:y1, x0:x1]
        white = (z > 160).all(axis=2)  # name ink + tints
        pale = np.zeros(z.shape[:2], bool)  # number ink
        for c in ((85, 159, 255), (85, 127, 255), (85, 95, 255), (42, 127, 255)):
            pale |= np.abs(z - np.array(c)).sum(axis=2) < 40
        grow = white | pale
        # grow 1px to catch anti-alias/dither fringe
        g = grow.copy()
        g[1:] |= grow[:-1]
        g[:-1] |= grow[1:]
        gg = g.copy()
        gg[:, 1:] |= g[:, :-1]
        gg[:, :-1] |= g[:, 1:]
        m[:, x0:x1] |= gg
    m[:, CELLS[0] : CELLS[1]] = True  # photo cells + gap
    return m


def main() -> None:
    e1 = load(F_EMPTY)
    e2 = load(F_EMPTY2)
    e3 = load(F_EMPTY3)
    full_a = load(F_FULL_A)
    full_b = load(F_FULL_B)
    ft = load(F_FT)
    brief = load(F_BRIEF)

    # The clean background: per-pixel median of the three row-1-only witnesses.
    # Each carries its own transients (the away-name slide at the right edge,
    # a row-2 photo mid-flight at differing spots) — never at the same pixel in
    # two frames, so the median is the pure art everywhere below/above row 1.
    bg = np.median(np.stack([e1, e2, e3]), axis=0).astype(np.int32)

    # ---- sanity: same background art across runs --------------------------
    assert np.abs(full_b[477:480, 100:500] - bg[477:480, 100:500]).sum() == 0, (
        "background art differs between runs"
    )
    assert np.abs(e2[200:400, 30:250] - bg[200:400, 30:250]).sum() == 0, (
        "rolling witness background differs (rows 4..9 zone should be clean bg)"
    )

    # ---- sanity: photo cell is the native 32x32 MINIFOTO ------------------
    mini = (
        np.asarray(Image.open(F_MINI_SCHMEICHEL).convert("RGB")).astype(np.int32)
        if F_MINI_SCHMEICHEL.exists()
        else None
    )
    if mini is not None:
        cell = full_b[84:116, CELL_AWAY_X : CELL_AWAY_X + 32]
        eq = (np.abs(cell - mini).sum(axis=2) == 0).mean()
        assert eq > 0.95, f"Schmeichel cell vs mini/3371: only {eq:.1%} equal"

    # ---- learn the band translucency LUT ----------------------------------
    # pairs (bg colour -> band colour) keyed by (x+y)%2, trained on every
    # complete-witness band pixel that is NOT live data in EITHER witness.
    # Bands 1..10 only: at band 0 (row 1) the background is banded in every
    # witness, so no clean (bg -> band) pair exists there.
    luts = [dict(), dict()]  # parity -> {bg_rgb: {band_rgb: count}}
    for i in range(1, ROWS):
        y0, y1 = band_rows(i)
        mask = ink_mask_band(full_a, i) | ink_mask_band(full_b, i)
        for wit in (full_a, full_b):
            zb = bg[y0:y1]
            zw = wit[y0:y1]
            ys, xs = np.where(~mask)
            for y, x in zip(ys, xs):
                par = (x + (y0 + y)) & 1
                k = tuple(zb[y, x])
                v = tuple(zw[y, x])
                luts[par].setdefault(k, {}).setdefault(v, 0)
                luts[par][k][v] += 1
    lut = [{k: max(v.items(), key=lambda kv: kv[1])[0] for k, v in luts[p].items()} for p in (0, 1)]

    # cross-validate: LUT(bg) must reproduce witness band pixels ~exactly
    miss = tot = 0
    unseen = 0
    for i in range(1, ROWS):
        y0, y1 = band_rows(i)
        mask = ink_mask_band(full_a, i) | ink_mask_band(full_b, i)
        ys, xs = np.where(~mask)
        for y, x in zip(ys, xs):
            par = (x + (y0 + y)) & 1
            k = tuple(bg[y0 + y, x])
            got = lut[par].get(k)
            if got is None:
                unseen += 1
                continue
            tot += 1
            if got != tuple(full_a[y0 + y, x]):
                miss += 1
    err = miss / max(tot, 1)
    print(f"  band LUT: {tot} px validated, mismatch {err:.3%}, unseen {unseen}")
    assert err < 0.01, f"band LUT mismatch too high: {err:.2%}"

    def synth_band(i: int) -> np.ndarray:
        """Reconstruct band i as a clean (ink-free) strip from the background."""
        y0, y1 = band_rows(i)
        out = full_a[y0:y1].copy()
        # replace live-data pixels with LUT-mapped background
        mask = ink_mask_band(full_a, i)
        ys, xs = np.where(mask)
        for y, x in zip(ys, xs):
            par = (x + (y0 + y)) & 1
            k = tuple(bg[y0 + y, x])
            v = lut[par].get(k)
            if v is None:  # unseen colour: witness-B fallback
                mb = ink_mask_band(full_b, i)
                v = tuple(full_b[y0 + y, x]) if not mb[y, x] else tuple(bg[y0 + y, x])
            out[y, x] = v
        return out

    def stitch_band0() -> np.ndarray:
        """Row 1's clean band: no clean bg exists there, so stitch across the
        three DIFFERENT-fixture row-1 witnesses (o63 Bosnich|Branagan, w55
        Hesp|Schmeichel, o74 Jones|Branagan) — a pixel inked in one is clean
        in another; the photo cells (always covered at runtime) go black."""
        # e1 (o61) row 1: home name settled, away name still mid-slide at the
        # RIGHT EDGE -> its x386..560 away zone is CLEAN band (fills the
        # Branagan-vs-Schmeichel glyph-intersection holes); only x560+ dirty.
        wits = [full_a, full_b, e1, e3]
        masks = [ink_mask_band(w, 0) for w in wits]
        masks[2][:, 560:640] = True  # e1 slide zone
        masks[3][:, NAME_AWAY[0] : 640] = True  # e3 away name mid-slide too
        y0, y1 = band_rows(0)
        out = wits[0][y0:y1].copy()
        holes = 0
        for y in range(BAND_H):
            for x in range(640):
                if not masks[0][y, x]:
                    continue
                if CELLS[0] <= x < CELLS[1]:
                    out[y, x] = (0, 0, 0)
                    continue
                for w, m in zip(wits[1:], masks[1:]):
                    if not m[y, x]:
                        out[y, x] = w[y0 + y, x]
                        break
                else:
                    # true hole: nearest clean row in the same column (o63)
                    holes += 1
                    col = np.where(~masks[0][:, x])[0]
                    if col.size:
                        out[y, x] = wits[0][y0 + col[np.abs(col - y).argmin()], x]
        print(f"  band0 stitch: {holes} inpainted holes")
        assert holes < 900, f"band0 stitch holes too high: {holes}"
        return out

    # ---- prematch_bg.png: the empty/mount state ---------------------------
    # The witnessed roll OPENS on ~0.9s of CLEAN fondo (matchday_flow_witness_re
    # §4; row 1 is NOT pre-landed), but no pixel-true clean frame of the row-1
    # zone exists (the fondo still is a lossy video frame). Reconstruct it by
    # INVERTING the band LUT (band colour -> bg colour, majority vote from the
    # bands-1..10 training pairs) over the stitched clean band 0.
    inv = [dict(), dict()]
    for p in (0, 1):
        acc: dict = {}
        for k, votes in luts[p].items():
            for v, n in votes.items():
                acc.setdefault(v, {}).setdefault(k, 0)
                acc[v][k] += n
        inv[p] = {v: max(c.items(), key=lambda kv: kv[1])[0] for v, c in acc.items()}
    band0 = stitch_band0()
    y0 = band_rows(0)[0]
    row1_bg = band0.copy()
    inv_miss = 0
    for y in range(BAND_H):
        for x in range(640):
            par = (x + (y0 + y)) & 1
            v = inv[par].get(tuple(band0[y, x]))
            if v is None:
                inv_miss += 1
                v = tuple(bg[min(y0 + BAND_H + 4 + y, 479), x])  # nearest clean art
            row1_bg[y, x] = v
    print(f"  row1 inverse-LUT: {inv_miss} unseen px (filled from nearby art)")
    # tolerance cross-check vs the lossy fondo frame (video-derived, mean err ~9)
    fondo_p = WIT17 / "roll_first_frame_clean_fondo.png"
    if fondo_p.exists():
        fondo = load(fondo_p)
        err_f = np.abs(row1_bg - fondo[y0 : y0 + BAND_H]).mean()
        print(f"  row1 vs lossy fondo mean err: {err_f:.1f} (lossy floor ~9)")
        assert err_f < 20, f"row1 reconstruction too far from the fondo witness: {err_f:.1f}"
    empty = bg.copy()
    empty[y0 : y0 + BAND_H] = row1_bg
    save(empty, "prematch_bg.png")

    # ---- prematch_full.png: the complete state ----------------------------
    fullc = empty.copy()
    fullc[y0 : y0 + BAND_H] = band0  # row 1's clean BAND (the stitch)
    for i in range(1, ROWS):
        ya, yb = band_rows(i)
        fullc[ya:yb] = synth_band(i)
    # title strip: flat navy per row + the two yellow arrows. The strip runs
    # the full width (it continues under the corner kits). Rebuild each row
    # from the median of a clean span (right of the away name in BOTH
    # witnesses is not clean — "Manchester Utd." runs to x516 — so use the
    # span between the home-name zone and the arrows plus a far-right sliver),
    # then copy the arrow zone verbatim from witness A.
    strip = full_a[TITLE_Y0:TITLE_Y1]
    strip_b = full_b[TITLE_Y0:TITLE_Y1]
    sb = np.zeros_like(strip)
    clean_span = list(range(530, 556))
    for y in range(TITLE_Y1 - TITLE_Y0):
        row_a = strip[y, clean_span]
        row_b = strip_b[y, clean_span]
        med_a = np.median(row_a, axis=0)
        med_b = np.median(row_b, axis=0)
        assert np.abs(med_a - med_b).sum() < 12, (
            f"title strip row {y}: witnesses disagree {med_a} vs {med_b}"
        )
        sb[y, :] = med_a
    sb[:, 296:343] = strip[:, 296:343]  # the yellow ◄► arrows
    fullc[TITLE_Y0:TITLE_Y1] = sb
    save(fullc, "prematch_full.png")

    # ---- roll_sil.png: the black-bust placeholder -------------------------
    # Witness B's home side (F.C. Barcelona) has no photos: every row shows
    # the same placeholder (rows agree 100%). Cut it from row 1 (Hesp).
    sil = full_b[84:116, CELL_HOME_X : CELL_HOME_X + 32]
    sil2 = full_b[120:152, CELL_HOME_X : CELL_HOME_X + 32]
    eq = (np.abs(sil - sil2).sum(axis=2) == 0).mean()
    assert eq > 0.99, f"silhouette rows disagree: {eq:.1%}"
    save(sil, "roll_sil.png")

    # ---- brief_ft.png: BRIEF at FULL TIME ---------------------------------
    ftimg = brief.copy()
    for x, y, w, h in FT_PATCH:
        x0, y0 = max(0, x - 3), max(0, y - 3)
        x1, y1 = min(640, x + w + 3), min(480, y + h + 3)
        ftimg[y0:y1, x0:x1] = ft[y0:y1, x0:x1]
    # assert: outside the patches + known data zones, brief_ft == o68
    diff = np.abs(ftimg - ft).sum(axis=2) > 40
    data_zones = [
        (258, 18, 114, 82),  # clock LCD + digits
        (0, 60, 640, 92),  # state label + scoreline band + kits (y60..151, kits run to y149)
        (14, 180, 612, 30),  # possession row (pcts + bar arrow)
        (150, 230, 340, 210),  # events panel (header+body+scroll)
        (0, 0, 210, 16),  # F1 banner top-left antialias fringe
    ]
    for x, y, w, h in data_zones:
        diff[y : y + h, x : x + w] = False
    resid = int(diff.sum())
    print(f"  brief_ft vs o68 residual (non-data, non-patch): {resid} px")
    assert resid < 300, f"brief_ft residual too high: {resid}"
    save(ftimg, "brief_ft.png")

    # ---- brief_running.png: RUNNING state (witness §5: EXIT only) ----------
    # brief.png with the door/KICK OFF/left-STATISTICS zones taken from the
    # 07-17 running still (all vanished); the EXIT slot keeps the baked EXIT.
    runf = load(F_RUN)
    runimg = brief.copy()
    for x, y, w, h in FT_PATCH[:-1]:  # every button zone EXCEPT the EXIT slot
        x0, ya = max(0, x - 3), max(0, y - 3)
        x1, yb = min(640, x + w + 3), min(480, y + h + 3)
        runimg[ya:yb, x0:x1] = runf[ya:yb, x0:x1]
    diff_r = np.abs(runimg - runf).sum(axis=2) > 40
    for x, y, w, h in data_zones:
        diff_r[y : y + h, x : x + w] = False
    diff_r[439:475, 505:631] = False  # EXIT slot (kept baked; witness has it too)
    resid_r = int(diff_r.sum())
    print(f"  brief_running vs witness residual: {resid_r} px")
    assert resid_r < 300, f"brief_running residual too high: {resid_r}"
    save(runimg, "brief_running.png")

    # ---- alert Yes/No button sprites (leave-championship confirm, §6) ------
    # Cut the two framework cells from the witnessed alert still. Cells sit on
    # the box's bottom row; locate them by their 1px near-black outer frame.
    # Measured off the witness: box x161..472 y..277; the No cell sits EXACTLY
    # at the framework OK anchor (w-45, h-22, 39x16) and Yes left of it at
    # (w-94, h-22, 44x16) with a 4px gap. PMAlert blits these at those anchors.
    alert = load(F_ALERT)
    yes_r = (380, 256, 44, 16)
    no_r = (428, 256, 39, 16)
    for (x, y, w, h), name in ((yes_r, "yes"), (no_r, "no")):
        cell = alert[y : y + h, x : x + w]
        # frame: near-black outer columns; body: the framework grey ramp
        assert (cell[:, 0] < 60).all() and (cell[:, -1] < 60).all(), (
            f"alert {name} cut misaligned (no black frame columns)"
        )
        p = ROOT / "app" / "art" / "screens" / "alert" / f"{name}.png"
        Image.fromarray(cell.astype("uint8")).save(p)
        print(f"  wrote {p.relative_to(ROOT)}")

    # ---- spec --------------------------------------------------------------
    spec = {
        "_source": {
            "empty": str(F_EMPTY.relative_to(ROOT)),
            "full_a": str(F_FULL_A.relative_to(ROOT)),
            "full_b": str(F_FULL_B.relative_to(ROOT)),
            "empty2": str(F_EMPTY2.relative_to(ROOT)),
            "empty3": str(F_EMPTY3.relative_to(ROOT)),
            "ft": str(F_FT.relative_to(ROOT)),
        },
        "rows": ROWS,
        "row0_y": ROW0_Y,
        "row_pitch": ROW_PITCH,
        "band_h": BAND_H,
        "cell": {"w": CELL_W, "home_x": CELL_HOME_X, "away_x": CELL_AWAY_X},
        "text": {
            "font": "proman14",
            "name_ink_top_off": 10,
            "home_name_right": 255,
            "away_name_left": 386,
            "home_num_cx": 40.5,
            "away_num_cx": 597.5,
            "num_color": [85, 143, 255],
            "title_ink": [23, 33],
            "title_home_right": 276,
            "title_away_left": 364,
            "mgr_ink": [57, 68],
            "mgr_home_right": 249,
            "mgr_away_left": 390,
            "mgr_color": [105, 137, 181],
        },
        "title_strip": [TITLE_Y0, TITLE_Y1],
        "hdr_kit_w": HDR_KIT_W,
        # both complete witnesses draw an identical (deterministic) 1px black
        # frame around the 74x34 photo-pair block: x283..356, band_top-1..+33
        "cell_outline": {"x": 283, "w": 74, "y_off": -1, "h": 34, "color": [0, 0, 0]},
        "band_lut_mismatch": round(err, 5),
    }
    SPECS.mkdir(parents=True, exist_ok=True)
    out = SPECS / "prematch_roll_samples.json"
    out.write_text(json.dumps(spec, indent=1) + "\n")
    print(f"  wrote {out.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
