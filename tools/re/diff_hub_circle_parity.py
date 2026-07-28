"""Parity gate for the MANAGER MENU hub's central club CIRCLE.

    python3 tools/re/diff_hub_circle_parity.py

The circle was a shipped, user-visible defect until 2026-07-28: `menu_bg.png` had one
career's six bars baked into it plus two flat `(108,120,150)` blocks where the kits go,
and a hand-cut `circle_home.png` overlay repainted it for the other arrangement. It had
stopped being reproducible from its own baker, the rim was broken and the bars ran outside
the ring. It is now composed from the game's own pixels, and this gate holds it there.

Three checks, all against REAL MANAGER.EXE frames:

1. **The bars.** `menu_bg.png` (whose circle interior is `RECURSOS.PKF` `FONDO3.BMP`) plus
   `hub/circle_bars_{top,bot}.png` must reproduce each witness inside the twelve bar rects.
   Text is excluded: the port draws its own captions over these pixels, and the club name's
   own soft drop shadow (`shadow_blit_re.md`) bleeds several pixels past the glyphs. The
   chip and manager bars are held to **0 px**; the two club bars carry that shadow bleed and
   are held to a recorded ceiling rather than pretended away.
2. **The circle interior is FONDO3's own.** Every pixel of the widget rect in `menu_bg.png`
   must equal the rendered `FONDO3.BMP`, i.e. nothing is baked in there any more.
3. **The nation flags.** The 30x20 BANDERAS sprites the port draws at (308,143) / (308,355)
   must reproduce the walkthrough witness `001_160008.png` (Man Utd vs F.C. Barcelona) at
   **0 px** — the only frame in the corpus whose two clubs' nations differ.

Re-bake with `python3 tools/re/build_menu_bg_from_ref.py`.
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools" / "re"))

import pkf_image as pi  # noqa: E402

MENU_BG = ROOT / "app" / "art" / "screens" / "menu_bg.png"
BARS_TOP = ROOT / "app" / "art" / "screens" / "hub" / "circle_bars_top.png"
BARS_BOT = ROOT / "app" / "art" / "screens" / "hub" / "circle_bars_bot.png"
FLAGS = ROOT / "app" / "art" / "flags"
W_TOP = ROOT / "tools" / "re" / "refs" / "menuprincipal_ma_6.png"
W_BOT = ROOT / "screenshots" / "parity-run-2026-07-16" / "orig" / "73_hub_wk1.png"
W_FLAGS = ROOT / "screenshots" / "original-walkthrough-2026-07-02" / "001_160008.png"

WIDGET = (220, 173, 205, 173)
# (name, frame rect) widget-relative — FUN_00549240's own literals.
FRAMES = [
    ("chip_t", (75, 0, 52, 16)),
    ("mgr_t", (29, 21, 145, 25)),
    ("club_t", (8, 52, 189, 23)),
    ("club_b", (8, 98, 189, 23)),
    ("mgr_b", (29, 127, 145, 25)),
    ("chip_b", (75, 157, 52, 16)),
]
# The club bars are the only two the proman12 club name's drop shadow reaches. Measured
# 2026-07-28: 560 / 229 px (player-home frame) and 238 / 120 px (player-away frame).
SHADOW_CEILING = 600
# The witness's own flags: TOP = Spain (F.C. Barcelona, the HOME side), BOT = England.
FLAG_CASES = [("TOP", (308, 143), 22), ("BOT", (308, 355), 30)]


def _load(p: Path) -> np.ndarray:
    return np.asarray(Image.open(p).convert("RGB"), dtype=int)[:, :640]


def main() -> int:
    ok = True
    wx, wy, ww, wh = WIDGET
    bg = _load(MENU_BG)

    # --- 2. the circle interior is FONDO3's own ------------------------------
    fondo = np.asarray(
        pi.render("RECURSOS.PKF", "FONDO3.BMP", palette="MANAGER.PAL", transparent=False)
        .convert("RGB"),
        dtype=int,
    )
    d = int((np.abs(bg[wy:wy + wh, wx:wx + ww] - fondo[wy:wy + wh, wx:wx + ww]).max(axis=2) > 0).sum())
    print(f"menu_bg circle interior vs RECURSOS FONDO3.BMP : {d} px differ")
    if d:
        print("  FAIL: something is baked into the circle again")
        ok = False

    # --- 1. the bars ---------------------------------------------------------
    for tag, patch_p, wit_p in (("top", BARS_TOP, W_TOP), ("bot", BARS_BOT, W_BOT)):
        patch = np.asarray(Image.open(patch_p).convert("RGBA"), dtype=int)
        wit = _load(wit_p)
        comp = bg.copy()
        m = patch[..., 3] > 0
        comp[wy:wy + wh, wx:wx + ww][m] = patch[..., :3][m]
        print(f"{patch_p.name} composited vs {wit_p.name}")
        for name, (rx, ry, rw, rh) in FRAMES:
            a = comp[wy + ry:wy + ry + rh, wx + rx:wx + rx + rw]
            b = wit[wy + ry:wy + ry + rh, wx + rx:wx + rx + rw]
            ink = (b.min(axis=2) >= 200) | (b.max(axis=2) <= 25)
            bad = int(((np.abs(a - b).max(axis=2) > 0) & ~ink).sum())
            cap = SHADOW_CEILING if name.startswith("club") else 0
            verdict = "OK" if bad <= cap else "FAIL"
            note = " (club-name shadow bleed)" if name.startswith("club") else ""
            print(f"  {name:7s} {bad:4d} / {int((~ink).sum()):5d} non-ink px differ"
                  f"  [{verdict} <= {cap}]{note}")
            if bad > cap:
                ok = False

    # --- 3. the nation flags -------------------------------------------------
    wit = _load(W_FLAGS)
    print(f"flags vs {W_FLAGS.name} (Man Utd vs F.C. Barcelona)")
    for label, (x, y), code in FLAG_CASES:
        p = FLAGS / f"flag_{code:03d}.png"
        if not p.exists():
            print(f"  FAIL: {p.name} missing")
            ok = False
            continue
        a = np.asarray(Image.open(p).convert("RGBA"), dtype=int)
        if a.shape[:2] != (20, 30):
            print(f"  FAIL: {p.name} is {a.shape[1]}x{a.shape[0]}, expected 30x20")
            ok = False
            continue
        t = wit[y:y + 20, x:x + 30]
        opaque = a[..., 3] > 0
        bad = int((np.abs(a[..., :3] - t).max(axis=2) > 0)[opaque].sum())
        print(f"  {label} {p.name} at ({x},{y}) : {bad} / {int(opaque.sum())} px differ")
        if bad:
            ok = False

    print("PASS" if ok else "FAILURES ABOVE")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
