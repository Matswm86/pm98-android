#!/usr/bin/env python3
"""Bake the LINE-UP row template for a SUSPENDED player, from the real frame.

The unavailable-player row is the same furniture for an injury and a ban — the gold
plate (212,191,85), a white icon cell, a dark count cell (85,63,0) with the number in
yellow, and a gold unit cell (170,127,0) whose label the screen draws in code. Measured
on both, the cells are at identical x:

    icon  x174..197 (white)   count x199..222 (dark)   unit x224..297 (gold)

Only two things differ:
  * the ICON — a red medical cross for an injury, **two yellow cards side by side** for
    a suspension;
  * the unit LABEL — `WEEKS` / `WEEK` for an injury, `MATCHES` / `MATCH` for a ban
    (drawn by LineupScreen, not baked).

So the ban row template is the injured row template with the icon cell replaced by the
original's own pixels. Nothing is redrawn or approximated.

Binding frame: the reference season played by hand 2026-07-25 — Manchester Utd. 1997-98,
`out/refrun-manutd-9798/play/p0349_UNKNOWN.png`, RESERVES row `2 Gary Neville`, banned
`2 MATCHES`. The LINE-UP row strip sits at (9, 420) there, the same 429x14 rect
`row_inj.png` was cut from at (9, 231) of its own frame.

Run:  python3 tools/re/build_lineup_ban_row_from_frame.py
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
FRAME = ROOT / "out" / "refrun-manutd-9798" / "play" / "p0349_UNKNOWN.png"
SRC = ROOT / "app" / "art" / "screens" / "lineup" / "row_inj.png"
OUT = ROOT / "app" / "art" / "screens" / "lineup" / "row_ban.png"

ROW_XY = (9, 420)          # the row strip's top-left in the binding frame
ICON_CELL = (174, 198)     # the white icon cell, frame x (right exclusive)


def main() -> None:
    if not FRAME.exists():
        raise SystemExit(f"binding frame missing: {FRAME}")
    row = Image.open(SRC).convert("RGB")
    frame = Image.open(FRAME).convert("RGB")
    x0, y0 = ROW_XY
    icon = frame.crop((ICON_CELL[0], y0, ICON_CELL[1], y0 + row.height))
    out = row.copy()
    out.paste(icon, (ICON_CELL[0] - x0, 0))
    out.save(OUT)
    print(f"wrote {OUT.relative_to(ROOT)} ({out.width}x{out.height}, "
          f"icon cell x{ICON_CELL[0]}..{ICON_CELL[1] - 1} taken from {FRAME.name})")


if __name__ == "__main__":
    main()
