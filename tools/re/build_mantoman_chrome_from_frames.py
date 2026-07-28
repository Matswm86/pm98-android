#!/usr/bin/env python3
"""Bake the MAN-TO-MAN MARKINGS body chrome + its three sprites from the originals.

    python3 tools/re/build_mantoman_chrome_from_frames.py

Outputs (all under app/art/screens/mantoman/):
    body.png     640x418  the real frame's y62..479 band, dynamic cells blanked
    body.json    the geometry this bake asserts, for the scene to read back
    linead.png   22x109   RECURSOS.PKF  recursos\\iconos\\emparejamientos\\linead.bmp
    lineam.png   22x109   RECURSOS.PKF  ...\\lineam.bmp
    flechas.png  38x14    RECURSOS.PKF  ...\\flechas.bmp

Binding frame: `screenshots/parity-run-2026-07-16/orig/66_mantoman_match.png`
(Bolton W. vs Aston Villa, in-match door). Cross-witness:
`screenshots/original-walkthrough-2026-07-02/058_162622.png` (Manchester Utd. vs
F.C. Barcelona) — a different career, a different pair of clubs. The bake REFUSES
to run unless the two agree pixel-for-pixel everywhere outside the dynamic cells,
so what ships is chrome both careers produced.

Everything blanked here is redrawn live by ManToManScreen.gd; nothing is invented:

  * the ten MY rows / ten OPPONENT rows lose only their interior fill (the borders
    are chrome), because the scene repaints the fill anyway to show selection;
  * the 48x64 opponent kit and the vertical club plate's name box are dynamic;
  * the PITCH interior is rebuilt as the original itself builds it in
    `FUN_0050f720` — flat white, then `campo.bmp` at panel-relative (20,43) — so the
    two marking-line markers can travel over ORIGINAL pixels instead of a patch.
    The rebuild is asserted equal to the frame outside the two marker rects.

Geometry source: docs/re/mantoman_screen_re.md (all of it read out of
MANAGER.EXE `FUN_0050e980` + the four draw overrides).
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import export_art as ea  # noqa: E402
from pkf_image import dib_indices, entries, entry_bytes_at, rgba  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
PARITY = ROOT / "screenshots" / "parity-run-2026-07-16" / "orig" / "66_mantoman_match.png"
WALK = ROOT / "screenshots" / "original-walkthrough-2026-07-02" / "058_162622.png"
CAMPO = ROOT / "app" / "art" / "screens" / "lineup" / "campo.png"
OUT = ROOT / "app" / "art" / "screens" / "mantoman"

BODY_Y0 = 62  # the shared barra owns y0..61 (PMChrome.draw_match_header)

# --- panels (MANAGER.EXE FUN_0050e980 / FUN_00510700) ------------------------
MAIN = (23, 82, 511, 268)
OPP = (23, 278, 290, 456)
PITCH = (319, 278, 511, 456)

# --- rows (screen-absolute; i = 0..9) ----------------------------------------
MY_ROW = (32, 102, 217, 16)  # x, y0, w, h   -> panel-rel (9, 20+16i) size 217x16
OPP_ROW = (31, 287, 192, 16)  # -> opp-panel-rel (8, 9+16i) size 192x16
CELL_ROW = (285, 102, 217, 16)  # -> panel-rel (262, 20+16i) size 217x16
GREY_ROW = (248, 103, 38, 14)  # -> panel-rel (225, 21+16i) size 38x14
ROW_PITCH = 16

MY_FILL = (212, 223, 255)
OPP_FILL = (30, 52, 98)
CELL_FILL = (212, 255, 170)

# --- the opponent panel's kit + vertical club plate --------------------------
KIT_XY = (229, 283)  # opp-panel-rel (206,5); 48x64 MINIESC (kit 45 = SAD 0 here)
KIT_WH = (48, 64)
PLATE = (243, 313, 262, 445)  # opp-panel-rel (220,35)-(239,167)
PLATE_TEXT = (243, 338, 262, 445)  # opp-panel-rel (220,60)-(239,167)

# --- the pitch (FUN_0050f720) ------------------------------------------------
PITCH_WHITE = (321, 300, 509, 434)  # panel-rel (2,22)-(190,156)
CAMPO_XY = (339, 321)  # panel-rel (20,43)
# the two markers at their witnessed default (club 0x25c=79 -> 36, 0x260=198 -> 92)
MARK_D = (319 + 12 + 36, 278 + 28, 22, 109)
MARK_M = (319 + 12 + 92, 278 + 45, 22, 109)

SPRITES = {
    "LINEAD.BMP": "linead.png",
    "LINEAM.BMP": "lineam.png",
    "FLECHAS.BMP": "flechas.png",
}


def load(path: Path) -> np.ndarray:
    a = np.asarray(Image.open(path).convert("RGB"))
    if a.shape[0] != 480 or a.shape[1] not in (640, 641):
        raise SystemExit(f"{path.name}: unexpected size {a.shape}")
    return a[:, :640].astype(int)


def dynamic_mask() -> np.ndarray:
    """True where the two witnesses are allowed to differ (career-specific pixels)."""
    m = np.zeros((480, 640), bool)
    for i in range(10):
        x, y, w, h = MY_ROW
        m[y + ROW_PITCH * i : y + ROW_PITCH * i + h, x : x + w] = True
        x, y, w, h = OPP_ROW
        m[y + ROW_PITCH * i : y + ROW_PITCH * i + h, x : x + w] = True
        x, y, w, h = CELL_ROW
        m[y + ROW_PITCH * i : y + ROW_PITCH * i + h, x : x + w] = True
    m[KIT_XY[1] : KIT_XY[1] + KIT_WH[1], KIT_XY[0] : KIT_XY[0] + KIT_WH[0]] = True
    m[PLATE_TEXT[1] : PLATE_TEXT[3] + 1, PLATE_TEXT[0] : PLATE_TEXT[2] + 1] = True
    m[0:BODY_Y0, :] = True  # the barra is its own bake
    return m


def rebuild_pitch(body: np.ndarray) -> np.ndarray:
    """Repaint the pitch interior the way FUN_0050f720 does, markers removed."""
    campo = np.asarray(Image.open(CAMPO).convert("RGB")).astype(int)
    if campo.shape[:2] != (92, 152):
        raise SystemExit(f"campo.png is {campo.shape[:2]}, expected (92, 152)")
    out = body.copy()
    x0, y0, x1, y1 = PITCH_WHITE
    out[y0:y1, x0:x1] = (255, 255, 255)
    cx, cy = CAMPO_XY
    out[cy : cy + 92, cx : cx + 152] = campo
    return out


def bake_sprites() -> dict[str, tuple[int, int]]:
    pal = ea.riff_palette("MANAGER.PAL")
    sizes: dict[str, tuple[int, int]] = {}
    for i, (name, _off, _size) in enumerate(entries("RECURSOS.PKF")):
        if name not in SPRITES:
            continue
        img = rgba(dib_indices(entry_bytes_at("RECURSOS.PKF", i)), pal, transparent=True)
        img.save(OUT / SPRITES[name])
        sizes[SPRITES[name]] = img.size
        print(f"  wrote {SPRITES[name]} ({img.width}x{img.height})")
    missing = set(SPRITES.values()) - set(sizes)
    if missing:
        raise SystemExit(f"RECURSOS.PKF is missing {sorted(missing)}")
    return sizes


def check_sprites(frame: np.ndarray, assigned: np.ndarray) -> int:
    """The sprites must reproduce the frames where the original blits them."""
    rc = 0
    for png, (x, y, w, h), tag in (
        ("linead.png", MARK_D, "D marker"),
        ("lineam.png", MARK_M, "M marker"),
    ):
        a = np.asarray(Image.open(OUT / png).convert("RGBA")).astype(int)
        op = a[:, :, 3] > 0
        sub = frame[y : y + h, x : x + w]
        bad = ((sub != a[:, :, :3]).any(axis=2)) & op
        # the D / M letter is TEXT the original draws over the sprite (see the RE doc)
        letter = np.zeros_like(bad)
        if png == "linead.png":
            letter[0:13, 0:19] = True
        else:
            letter[93:106, 0:19] = True
        outside = int((bad & ~letter).sum())
        print(
            f"  {tag}: {outside} differing px outside the letter box "
            f"({int((bad & letter).sum())} inside it = the glyph)"
        )
        rc |= 1 if outside else 0
    a = np.asarray(Image.open(OUT / "flechas.png").convert("RGBA")).astype(int)
    op = a[:, :, 3] > 0
    gx, gy, gw, gh = GREY_ROW
    sub = assigned[gy + ROW_PITCH * 7 : gy + ROW_PITCH * 7 + gh, gx : gx + gw]
    n = int((((sub != a[:, :, :3]).any(axis=2)) & op).sum())
    print(f"  FLECHAS on 061_162628 row 7: {n} differing px")
    rc |= 1 if n else 0
    return rc


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    parity = load(PARITY)
    walk = load(WALK)

    mask = dynamic_mask()
    diff = (parity != walk).any(axis=2) & ~mask
    if diff.any():
        ys, xs = np.nonzero(diff)
        raise SystemExit(
            f"the two witnesses disagree on {int(diff.sum())} chrome px "
            f"(x {xs.min()}..{xs.max()}, y {ys.min()}..{ys.max()}) — refusing to bake"
        )
    print(f"  chrome agrees on both witnesses ({int((~mask).sum())} px compared)")

    body = rebuild_pitch(parity)
    # the rebuild must be the frame everywhere except where the markers sit
    mk = np.zeros((480, 640), bool)
    for x, y, w, h in (MARK_D, MARK_M):
        mk[y : y + h, x : x + w] = True
    px0, py0, px1, py1 = PITCH_WHITE
    zone = np.zeros((480, 640), bool)
    zone[py0:py1, px0:px1] = True
    resid = ((body != parity).any(axis=2)) & zone & ~mk
    print(f"  pitch rebuild: {int(resid.sum())} px differ from the frame outside the markers")
    if resid.any():
        return 1

    # blank the dynamic cells to their own fills
    for i in range(10):
        x, y, w, h = MY_ROW
        body[y + ROW_PITCH * i + 2 : y + ROW_PITCH * i + h - 2, x + 2 : x + w - 2] = MY_FILL
        x, y, w, h = OPP_ROW
        body[y + ROW_PITCH * i + 2 : y + ROW_PITCH * i + h - 2, x + 2 : x + w - 2] = OPP_FILL
        x, y, w, h = CELL_ROW
        body[y + ROW_PITCH * i + 2 : y + ROW_PITCH * i + h - 2, x + 2 : x + w - 2] = CELL_FILL
    # the kit sits ON the panel (white) and, below y313, on the club plate (black):
    # blank it back to whichever of the two the original has under it.
    kx, ky = KIT_XY
    body[ky : ky + KIT_WH[1], kx : kx + KIT_WH[0]] = (255, 255, 255)
    py0, px0, px1 = PLATE[1], PLATE[0], PLATE[2]
    body[py0 : ky + KIT_WH[1], px0 : px1 + 1] = (0, 0, 0)
    body[PLATE_TEXT[1] : PLATE_TEXT[3] + 1, PLATE_TEXT[0] : PLATE_TEXT[2] + 1] = (0, 0, 0)

    Image.fromarray(body[BODY_Y0:, :].astype(np.uint8)).save(OUT / "body.png")
    print(f"  wrote body.png (640x{480 - BODY_Y0})")

    sizes = bake_sprites()
    assigned = load(ROOT / "screenshots" / "original-walkthrough-2026-07-02" / "061_162628.png")
    rc = check_sprites(parity, assigned)

    (OUT / "body.json").write_text(
        json.dumps(
            {
                "binding_frame": str(PARITY.relative_to(ROOT)),
                "cross_witness": str(WALK.relative_to(ROOT)),
                "body_y0": BODY_Y0,
                "panels": {"main": MAIN, "opponent": OPP, "pitch": PITCH},
                "rows": {
                    "my": MY_ROW,
                    "opponent": OPP_ROW,
                    "cell": CELL_ROW,
                    "grey": GREY_ROW,
                    "pitch_step": ROW_PITCH,
                },
                "fills": {"my": MY_FILL, "opponent": OPP_FILL, "cell": CELL_FILL},
                "kit": {"xy": KIT_XY, "wh": KIT_WH},
                "plate": {"box": PLATE, "text": PLATE_TEXT},
                "pitch_paint": {"white": PITCH_WHITE, "campo_xy": CAMPO_XY},
                "markers": {"d": MARK_D, "m": MARK_M},
                "sprites": {k: list(v) for k, v in sizes.items()},
            },
            indent=2,
        )
        + "\n"
    )
    print("  wrote body.json")
    return rc


if __name__ == "__main__":
    sys.exit(main())
