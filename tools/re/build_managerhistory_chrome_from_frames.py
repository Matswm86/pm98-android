#!/usr/bin/env python3
"""MANAGER HISTORY screen chrome, frame-baked from the live-witnessed original.

Source (ground truth, owned game frames — captured 2026-07-16 from MANAGER.EXE
under wine, Promanager League, manager "mwm" at Brighton & HA, week 1):
  screenshots/promanager-career-2026-07-16/15_manager_history.png   TOTAL off
  screenshots/promanager-career-2026-07-16/16_manager_history_total_on.png

Screen provenance: EXE string block 0x25b674 (MANAGER HISTORY + historial\\flecha.bmp
+ POSITION/INTERCONT./SUPERCUP/COCA COLA CUP/COMPETITION) shared with the
OFFERS SELECTION header block 0x25e6e0 (PUBLIC/DIRECTORS/OBJ./POS./DIVISION).
See docs/re/promanager_career_screens_re.md.

Output:
  app/art/screens/managerhistory/body.png      640x480 opaque, drawn 1:1 at (0,0)
  app/art/screens/managerhistory/total_on.png  the lit TOTAL button (drawn at 508,314)

Doctrine (pm98_stay_true_to_original): the PNGs are the real frames' pixels. The ONLY
regions painted over are the ones the app must render live from Career state, blanked
back to their own baked flat fills so nothing is invented:
  - the manager-name plaque interior (light blue)      -> app draws the manager name
  - spell row 1's six cells (per-column flat fills)    -> app draws the spell rows
  - the 9x6 lower-table number cells (lavender)        -> app draws PLA..GA values
The POSITION column cells are witnessed EMPTY (week-1 zero state) and carry no baked
digits — nothing to blank. Everything else (title bar, pitch plaque, ball, both table
grids + headers + competition labels, scrollbar, red arrow, TOTAL-off plate, RETURN)
is baked pixel-exact.
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
F15 = ROOT / "screenshots/promanager-career-2026-07-16/15_manager_history.png"
F16 = ROOT / "screenshots/promanager-career-2026-07-16/16_manager_history_total_on.png"
OUT = ROOT / "app/art/screens/managerhistory"

# Upper spells table (frame coords): 13 data rows, y = 96 + 15*r, fill height 14.
ROWS = 13
ROW_Y0 = 96
ROW_PITCH = 15
ROW_H = 14
# Cell interiors (x0, x1 inclusive) with their witnessed flat fills.
UPPER_CELLS = [
    ((20, 117), (0, 0, 128)),      # TEAM (navy)
    ((119, 201), (80, 100, 120)),  # DIVISION
    ((203, 243), (60, 80, 100)),   # POS.
    ((245, 285), (30, 52, 98)),    # OBJ.
    ((287, 369), (80, 100, 120)),  # DIRECTORS
    ((371, 453), (60, 80, 100)),   # PUBLIC
]

# Lower competition table: 9 rows, y = 334 + 15*r, fill height 14. The data columns
# alternate fills (witnessed: PLA/DR/GF light lavender, WIN/LOS/GA darker).
LOW_ROWS = 9
LOW_Y0 = 334
LOW_LIGHT = (204, 204, 255)
LOW_DARK = (180, 180, 220)
LOW_CELLS = [
    ((149, 183), LOW_LIGHT), ((185, 219), LOW_DARK), ((221, 255), LOW_LIGHT),
    ((257, 291), LOW_DARK), ((293, 337), LOW_LIGHT), ((339, 383), LOW_DARK),
]
# POSITION column (385..469) is witnessed empty — baked as-is.

PLAQUE = ((366, 21), (516, 36))
PLAQUE_FILL = (200, 220, 240)

TOTAL_RECT = (508, 314, 612, 343)   # PIL crop box for the lit TOTAL plate (frame 16)


def blank(im: Image.Image, x0: int, y0: int, x1: int, y1: int, col) -> None:
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            im.putpixel((x, y), col)


def main() -> None:
    im = Image.open(F15).convert("RGB").crop((0, 0, 640, 480))
    # Manager-name plaque interior (erase the witnessed "mwm").
    (px0, py0), (px1, py1) = PLAQUE
    blank(im, px0, py0, px1, py1, PLAQUE_FILL)
    # Spell row 1 (the only witnessed filled row) back to each column's flat fill.
    y0 = ROW_Y0
    for (x0, x1), col in UPPER_CELLS:
        blank(im, x0, y0, x1, y0 + ROW_H - 1, col)
    # Lower-table number cells (baked zeros are DATA -> the app draws live values).
    for r in range(LOW_ROWS):
        ry = LOW_Y0 + r * ROW_PITCH
        for (x0, x1), fill in LOW_CELLS:
            blank(im, x0, ry, x1, ry + ROW_H - 1, fill)
    OUT.mkdir(parents=True, exist_ok=True)
    im.save(OUT / "body.png")
    print(f"wrote {OUT.relative_to(ROOT)}/body.png (640x480) from {F15.name}")

    im16 = Image.open(F16).convert("RGB")
    im16.crop(TOTAL_RECT).save(OUT / "total_on.png")
    print(f"wrote {OUT.relative_to(ROOT)}/total_on.png "
          f"({TOTAL_RECT[2]-TOTAL_RECT[0]}x{TOTAL_RECT[3]-TOTAL_RECT[1]}) from {F16.name}")


if __name__ == "__main__":
    main()
