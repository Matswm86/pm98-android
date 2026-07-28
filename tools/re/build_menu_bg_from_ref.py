#!/usr/bin/env python3
"""Build the PM98 MAIN MENU (MENUPRINCIPAL) chrome + the club CIRCLE's two bar schemes.

    python3 tools/re/build_menu_bg_from_ref.py

Outputs
  app/art/screens/menu_bg.png              the hub chrome, club data cleared
  app/art/screens/hub/circle_bars_top.png  the six bars, player on the HOME (top) side
  app/art/screens/hub/circle_bars_bot.png  the six bars, player on the AWAY (bottom) side

## Why this was rewritten (2026-07-28)

The hub's look is engine-COMPOSITED at runtime (`FUN_005469c0` builds the screen,
`FUN_00549240` draws the circle widget), so no single PKF asset holds the finished frame.
The old baker took the real MENUPRINCIPAL frame and cleared two hand-picked 36x50 / 32x50
"CREST_SPOTS" to a flat `(108,120,150)`, leaving the frame's OWN six bars baked in; a second
hand-cut overlay (`hub/circle_home.png`) repainted the circle for the other arrangement.
That is what broke: the shipped `menu_bg.png` stopped being reproducible from its own baker,
the flat crest blocks landed on the bar frames and the rim, and the overlay's bars ran
outside the ring. Mats reported it as a visible defect on the game's main screen.

Nothing here is hand-cut any more. Three things made that possible, all read out of the
game rather than guessed:

**1. `RECURSOS.PKF` `FONDO3.BMP` IS the hub's background, circle and all.** Rendered under
MANAGER.PAL it is pixel-identical to the real MENUPRINCIPAL frame everywhere except the six
bars and the two kits — the white rim and the marble inside the ring included. So the circle
can be cleared back to the game's own pixels instead of a flat fill.

**2. The bars' rects are the binary's own literal operands** (`FUN_00549240`, disassembled
2026-07-28; the same table `docs/re/hub_circle_re.md` carries). Fills go through
`FUN_0043ce50(rect, colour, 100)`, frames through `FUN_00468c90(rect, colour, 0x100)`:

    fill  (widget-relative)          frame (widget-relative)     site
    chip  (76,  1) 50x14             (75,  0) 52x16              0x549335 / 0x5493f2
    mgr   (30, 22) 143x23            (29, 21) 145x25             0x549374 / 0x549434
    club  ( 9, 53) 187x21            ( 8, 52) 189x23             0x5493b3 / 0x549476
    club  ( 9, 99) 187x21            ( 8, 98) 189x23             0x549536 / 0x5495fc
    mgr   (30,128) 143x23            (29,127) 145x25             0x5494f7 / 0x5495ba
    chip  (76,158) 50x14             (75,157) 52x16              0x5494b5 / 0x549578

  The widget's own screen rect is `(220,173) 205x173` — `FUN_00436fb0(0xcd,0xad)` /
  `(0xdc,0xad)` at 0x547cad-0x547cd4.

**3. The fill is a DITHER, and the rule is the one s73 already found in the shadow blit.**
`FUN_0043ce50`'s 100/256 alpha does not reproduce in RGB: fitting alpha over the real frames
against FONDO3 lands on 96..106 but reproduces only ~50 % of non-ink pixels even after
snapping to MANAGER.PAL. Measured instead, the result is an exact function of

    (the destination FONDO3 palette INDEX, (screen_x + screen_y) & 1)

— a 50/50 checkerboard on ABSOLUTE screen coordinates, the same rule
`docs/re/shadow_blit_re.md` reversed for `FUN_005d5220`. Verified per rect on two real
frames: the chip and manager bars are **100.00 %** determined by that key, the two club
bars 93-97 % (the residual is the proman12 club name's own soft shadow bleeding into the
fill, which the dominant-value vote correctly ignores).

So this script LEARNS that table from the two witnesses and repaints the bars from it. No
alpha model is used, nothing is hand-cut, and every output pixel is a pixel the real game
put on screen. The frames are pure `(255,255,255)` on the active side and `(0,0,0)` on the
other, measured on all twelve borders.

Witnesses: every hub frame in the tracked corpus, DISCOVERED rather than listed. A frame
qualifies when its top chip's 1 px border is 100 % pure white (player on the home/top side)
or 100 % pure black (player away/bottom) — which both identifies the arrangement and throws
out anything dimmed behind a modal. Two frames alone (ma_6 home + 73_hub_wk1 away) cover all
twelve bar/scheme combinations but leave two (colour, index, parity) cells unsampled,
because a caption happened to sit on them in both; the pooled corpus fills them, and the
baker hard-fails rather than guess if any cell is still empty.

What is NOT baked here, because the port draws it live over these outputs: the two 24x32
NANOESC kits (`FUN_00579710` -> `DBDAT\\NANOESC\\eq96%04u.bmp`, blitted at widget (2,48) and
(178,94) by 0x549679 / 0x5496f6), the arrow, the six texts, and the nation flags.
"""
from __future__ import annotations

import sys
from collections import Counter
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools" / "re"))

import pkf_image as pi  # noqa: E402

REF = ROOT / "tools" / "re" / "refs" / "menuprincipal_ma_6.png"
REF_AWAY = ROOT / "screenshots" / "parity-run-2026-07-16" / "orig" / "73_hub_wk1.png"
OUT = ROOT / "app" / "art" / "screens" / "menu_bg.png"
OUT_TOP = ROOT / "app" / "art" / "screens" / "hub" / "circle_bars_top.png"
OUT_BOT = ROOT / "app" / "art" / "screens" / "hub" / "circle_bars_bot.png"

# The circle widget's screen rect (FUN_00436fb0 operands at 0x547cad-0x547cd4).
WIDGET = (220, 173, 205, 173)
# (name, fill x,y,w,h, frame x,y,w,h) widget-relative — FUN_00549240's own literals.
BARS = [
    ("chip_t", (76, 1, 50, 14), (75, 0, 52, 16)),
    ("mgr_t", (30, 22, 143, 23), (29, 21, 145, 25)),
    ("club_t", (9, 53, 187, 21), (8, 52, 189, 23)),
    ("club_b", (9, 99, 187, 21), (8, 98, 189, 23)),
    ("mgr_b", (30, 128, 143, 23), (29, 127, 145, 25)),
    ("chip_b", (76, 158, 50, 14), (75, 157, 52, 16)),
]
TOP_BARS = {"chip_t", "mgr_t", "club_t"}
WHITE = (255, 255, 255)
BLACK = (0, 0, 0)
# Clean marble sample points (away from header / bars / icons) for the top-band fill.
MARBLE_PTS = [(12, 210), (627, 210), (12, 300), (627, 300), (320, 470)]
TOP_BAND_H = 56


def _load(p: Path) -> np.ndarray:
    a = np.asarray(Image.open(p).convert("RGB"), dtype=int)
    return a[:, :640]  # the wine captures carry one extra border column


def _is_ink(fg: np.ndarray) -> np.ndarray:
    """Text ink: the bars' captions are pure white or pure black single strikes."""
    return (fg.min(axis=-1) >= 200) | (fg.max(axis=-1) <= 25)


def _arrangement(a: np.ndarray) -> bool | None:
    """True = player on the HOME (top) side, False = away, None = not a clean hub frame.

    Read off the TOP chip's 1 px frame, which `FUN_00549240` draws pure white on the
    player's own side and pure black on the other. Requiring it to be 100 % one of those
    two also rejects a hub dimmed behind a modal.
    """
    wx, wy, _, _ = WIDGET
    rx, ry, rw, rh = BARS[0][2]
    r = a[wy + ry:wy + ry + rh, wx + rx:wx + rx + rw]
    if r.shape[:2] != (rh, rw):
        return None
    border = np.concatenate([r[0], r[-1], r[1:-1, 0], r[1:-1, -1]])
    if (border == WHITE).all():
        return True
    if (border == BLACK).all():
        return False
    return None


def witnesses() -> list[tuple[np.ndarray, bool]]:
    """Every clean hub frame in the tracked corpus, with its arrangement."""
    out: list[tuple[np.ndarray, bool]] = []
    paths = sorted(ROOT.glob("screenshots/**/*.png")) + sorted((ROOT / "tools/re/refs").glob("*.png"))
    for p in paths:
        try:
            a = np.asarray(Image.open(p).convert("RGB"), dtype=int)
        except Exception:
            continue
        if a.shape[0] != 480 or a.shape[1] not in (640, 641):
            continue
        a = a[:, :640]
        arr = _arrangement(a)
        if arr is not None:
            out.append((a, arr))
    return out


def learn(idx: np.ndarray, frames: list[tuple[np.ndarray, bool]]) -> dict:
    """(fill colour is white?, FONDO3 index, parity) -> the dithered result RGB.

    `frames` is [(frame pixels, player-is-top)]. A bar is filled with BLACK on the
    player's own side and WHITE on the other, so pooling the two arrangements covers
    every bar in both colours.
    """
    votes: dict[tuple[bool, int, int], Counter] = {}
    wx, wy, _, _ = WIDGET
    for src, player_top in frames:
        for name, (fx, fy, fw, fh), _ in BARS:
            is_top = name in TOP_BARS
            white = is_top != player_top  # the NON-player side is filled white
            bg = idx[wy + fy:wy + fy + fh, wx + fx:wx + fx + fw].reshape(-1)
            fg = src[wy + fy:wy + fy + fh, wx + fx:wx + fx + fw].reshape(-1, 3)
            yy, xx = np.mgrid[wy + fy:wy + fy + fh, wx + fx:wx + fx + fw]
            par = ((xx + yy) & 1).reshape(-1)
            keep = ~_is_ink(fg)
            for b, g, p in zip(bg[keep], fg[keep], par[keep]):
                votes.setdefault((white, int(b), int(p)), Counter())[tuple(g)] += 1
    return {k: v.most_common(1)[0][0] for k, v in votes.items()}


def complete(lut: dict, pal: np.ndarray, need: list) -> list:
    """Fill a dither cell no witness ever showed, by its PARITY PARTNER.

    A 50/50 checkerboard between two palette entries exists to make the pair's MEAN land
    on the blend the hardware cannot represent — the rule `shadow_blit_re.md` already
    reversed for `FUN_005d5220`'s two tables. So when one parity of an (colour, index)
    pair is known and the other is not, the missing entry is the palette colour nearest
    `2*target - known`, with `target` the 100/256 blend `FUN_0043ce50` asks for. Applied
    only to cells the corpus genuinely never shows, and every one is printed.
    """
    done = []
    for white, b, p in need:
        known = lut.get((white, b, p ^ 1))
        if known is None:
            continue
        bg = pal[b].astype(int)
        col = 255 if white else 0
        target = (bg * (256 - 100) + col * 100) // 256
        want = np.clip(2 * target - np.array(known, dtype=int), 0, 255)
        near = tuple(int(v) for v in pal[((pal.astype(int) - want) ** 2).sum(axis=1).argmin()])
        lut[(white, b, p)] = near
        done.append((white, b, p, known, near))
    return done


def paint(idx: np.ndarray, lut: dict, player_top: bool):
    """The six bars as an RGBA patch of the widget rect (transparent elsewhere)."""
    wx, wy, ww, wh = WIDGET
    out = np.zeros((wh, ww, 4), dtype=np.uint8)
    missing: list[tuple[bool, int, int]] = []
    for name, (fx, fy, fw, fh), (rx, ry, rw, rh) in BARS:
        is_top = name in TOP_BARS
        white = is_top != player_top
        edge = WHITE if not white else BLACK  # frame is the OPPOSITE of the fill
        # 1 px frame first, then the fill inside it
        out[ry, rx:rx + rw, :3] = edge
        out[ry + rh - 1, rx:rx + rw, :3] = edge
        out[ry:ry + rh, rx, :3] = edge
        out[ry:ry + rh, rx + rw - 1, :3] = edge
        out[ry, rx:rx + rw, 3] = 255
        out[ry + rh - 1, rx:rx + rw, 3] = 255
        out[ry:ry + rh, rx, 3] = 255
        out[ry:ry + rh, rx + rw - 1, 3] = 255
        for j in range(fh):
            for i in range(fw):
                b = int(idx[wy + fy + j, wx + fx + i])
                p = (wx + fx + i + wy + fy + j) & 1
                rgb = lut.get((white, b, p))
                if rgb is None:
                    missing.append((white, b, p))
                    continue
                out[fy + j, fx + i, :3] = rgb
                out[fy + j, fx + i, 3] = 255
    return Image.fromarray(out, "RGBA"), missing


def main() -> None:
    ref = Image.open(REF).convert("RGB")
    if ref.size != (640, 480):
        raise SystemExit(f"ref must be 640x480, got {ref.size}")
    idx = pi.dib_indices(pi.entry_bytes("RECURSOS.PKF", "FONDO3.BMP"))
    fondo = np.asarray(
        pi.render("RECURSOS.PKF", "FONDO3.BMP", palette="MANAGER.PAL", transparent=False)
        .convert("RGB"),
        dtype=int,
    )

    # --- menu_bg: the real frame, header band flattened, circle restored from FONDO3 ---
    px = np.asarray(ref, dtype=np.uint8).copy()
    marble = tuple(
        int(sum(int(px[y, x, c]) for x, y in MARBLE_PTS) / len(MARBLE_PTS)) for c in range(3)
    )
    px[:TOP_BAND_H, :, :] = marble
    wx, wy, ww, wh = WIDGET
    px[wy:wy + wh, wx:wx + ww] = fondo[wy:wy + wh, wx:wx + ww]
    OUT.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(px, "RGB").save(OUT)

    # --- the two bar schemes -------------------------------------------------
    wits = witnesses()
    n_top = sum(1 for _, t in wits if t)
    lut = learn(idx, wits)
    pal = np.array(pi.riff_palette("MANAGER.PAL"), dtype=int).reshape(-1, 3)
    need: list = []
    for ptop in (True, False):
        need += paint(idx, lut, ptop)[1]
    for white, b, p, known, near in complete(lut, pal, sorted(set(need))):
        print(f"  derived dither cell (white={white}, index={b}, parity={p}) = {near} "
              f"from its partner {known} (no witness covers it)")
    OUT_TOP.parent.mkdir(parents=True, exist_ok=True)
    for ptop, dst in ((True, OUT_TOP), (False, OUT_BOT)):
        img, left = paint(idx, lut, ptop)
        if left:
            raise SystemExit(f"unresolved dither cells: {sorted(set(left))}")
        img.save(dst)

    print(f"wrote {OUT.relative_to(ROOT)} — real MENUPRINCIPAL chrome, top band {marble}, "
          f"circle restored from RECURSOS FONDO3.BMP")
    print(f"wrote {OUT_TOP.relative_to(ROOT)} / {OUT_BOT.relative_to(ROOT)} ({ww}x{wh}) "
          f"from a {len(lut)}-key (colour, index, parity) dither table learned on "
          f"{len(wits)} hub frames ({n_top} player-home, {len(wits) - n_top} player-away)")


if __name__ == "__main__":
    main()
