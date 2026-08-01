#!/usr/bin/env python3
"""Bake the manager-mode BARRA panel's club-independent FURNITURE.

The barra's manager-mode panel (35x44 at 108,8) had shipped as `app/art/kits/header/40.png`
-- a verbatim cut of MANCHESTER UTD's panel, kit and furniture together -- with every other
club falling back to a bare NANOESC kit at the panel's nano anchor. That fallback is the
single biggest parity bucket in the port: 649 px per frame on the EURO GROUP gate alone, and
the same bucket appears on the RESULTS and KNOCKOUT gates.

The gap was recorded as un-closable because "no frame in the corpus shows that panel with
any other club's kit". That is no longer true -- the six EURO GROUP frames
(`refs/euro-competitions-2026-07-25`) are a **BOLTON W** career in the same manager mode.
Two careers with two different kits occlude DIFFERENT pixels of the same panel, so between
them they witness all but the 417 px both kits cover.

Two measurements make this a derivation rather than a guess:

  1. **The panel's kit half IS the club's own NANOESC kit**, blitted at the panel-local
     anchor (6,7) = screen (114,15), which is the anchor `PMChrome.HDR_MGR_NANO_XY` already
     carried for the fallback: Man Utd's exported `art/kits/nano/40.png` reproduces his
     panel's kit region at **0 of 419 opaque px**.
  2. Rebuilt as furniture + the club's own nano kit, the composite reproduces **Man Utd's
     panel at 0 px** and **Bolton's at 14 px** -- and those 14 are pixels neither exported
     sprite covers, i.e. the same un-reversed 1-px rim the group leader's kit cell carries
     (`docs/re/euro_league_screen_re.md`). They are declared, not painted.

Output: `app/art/kits/header/panel.png` -- RGBA, transparent exactly where both careers'
kits occlude it, so the club's own kit is what fills it.

Usage: python3 tools/re/build_manager_panel_from_frames.py
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
REFS = ROOT / "tools/re/refs/euro-competitions-2026-07-25"
OUT = ROOT / "app/art/kits/header/panel.png"

PANEL = (108, 8, 35, 44)  # x, y, w, h -- PMChrome.HDR_MGR_PATCH_XY + the cut size
NANO_LOCAL = (6, 7)  # HDR_MGR_NANO_XY (114,15) - the panel origin

# The two careers, each with the witness that shows its panel un-rebuilt.
MAN_UTD = 40  # app/art/kits/header/40.png IS his panel, cut from 058
BOLTON = 59  # the six EURO GROUP frames are a Bolton W career


def main() -> int:
    px, py, pw, ph = PANEL
    mu = Image.open(ROOT / "app/art/kits/header/40.png").convert("RGBA")
    if mu.size != (pw, ph):
        print(f"FAIL: 40.png is {mu.size}, expected {(pw, ph)}")
        return 1
    frames = [
        Image.open(REFS / f"{10 + i}_euroleague_group_{L}.png")
        .convert("RGB")
        .crop((0, 0, 640, 480))
        for i, L in enumerate("ABCDEF")
    ]
    for f in frames[1:]:
        n = sum(
            1
            for y in range(ph)
            for x in range(pw)
            if f.getpixel((px + x, py + y)) != frames[0].getpixel((px + x, py + y))
        )
        if n:
            print(f"FAIL: the six euro frames are one career and must agree; {n} px differ")
            return 1
    bolton = frames[0]

    nanos = {
        cid: Image.open(ROOT / f"app/art/kits/nano/{cid}.png").convert("RGBA")
        for cid in (MAN_UTD, BOLTON)
    }

    def covers(cid: int, lx: int, ly: int) -> bool:
        n = nanos[cid]
        x, y = lx - NANO_LOCAL[0], ly - NANO_LOCAL[1]
        return 0 <= x < n.width and 0 <= y < n.height and n.getpixel((x, y))[3] != 0

    # Assert (1): the panel's kit half is the club's own NANOESC sprite.
    bad = sum(
        1
        for y in range(nanos[MAN_UTD].height)
        for x in range(nanos[MAN_UTD].width)
        if nanos[MAN_UTD].getpixel((x, y))[3]
        and 0 <= x + NANO_LOCAL[0] < pw
        and 0 <= y + NANO_LOCAL[1] < ph
        and mu.getpixel((x + NANO_LOCAL[0], y + NANO_LOCAL[1]))[:3]
        != nanos[MAN_UTD].getpixel((x, y))[:3]
    )
    if bad:
        print(f"FAIL: Man Utd's nano kit does not reproduce his panel ({bad} px)")
        return 1

    furn = Image.new("RGBA", (pw, ph), (0, 0, 0, 0))
    occluded = 0
    for y in range(ph):
        for x in range(pw):
            if not covers(MAN_UTD, x, y):
                furn.putpixel((x, y), mu.getpixel((x, y)))
            elif not covers(BOLTON, x, y):
                furn.putpixel((x, y), (*bolton.getpixel((px + x, py + y)), 255))
            else:
                occluded += 1

    residual = {}
    for cid, want in ((MAN_UTD, mu), (BOLTON, None)):
        comp = furn.copy()
        comp.alpha_composite(nanos[cid], dest=NANO_LOCAL)
        n = 0
        for y in range(ph):
            for x in range(pw):
                c = comp.getpixel((x, y))
                if c[3] == 0:
                    continue
                ref = want.getpixel((x, y))[:3] if want else bolton.getpixel((px + x, py + y))
                if c[:3] != ref:
                    n += 1
        residual[cid] = n
    if residual[MAN_UTD]:
        print(f"FAIL: the rebuild does not reproduce its own source panel ({residual[MAN_UTD]} px)")
        return 1

    OUT.parent.mkdir(parents=True, exist_ok=True)
    furn.save(OUT)
    print(
        f"{OUT.relative_to(ROOT)} <- 2 careers: {pw * ph - occluded} witnessed, "
        f"{occluded} occluded by both kits"
    )
    print(
        f"  rebuild vs its witnesses: Man Utd {residual[MAN_UTD]} px, "
        f"Bolton W {residual[BOLTON]} px (the un-reversed 1-px kit rim)"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
