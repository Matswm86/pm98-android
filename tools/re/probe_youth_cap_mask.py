#!/usr/bin/env python3
"""Is the YOUTH SCOUT's SEARCH CAPABILITY mask a per-scout accident, or a star ladder?

s85 filed this as "per scout, not per rating" on two samples read as the same rating with
different masks. This re-reads the STARS off the pixels instead of off the prose, because
the scout bar draws a HALF star as half a glyph and a glance calls it a whole one -- the
2026-08-01 s86 drive's own scout reads "2 stars" to the eye and is 1.5 in the bitmap.

For every YOUTH TEAM frame it finds, this prints:
  * the scout's rating, counted as (full glyphs, half glyph?) off the star bar;
  * the six SEARCH CAPABILITY values, read as YES/NO off the value cells' INK COLOUR
    (the YES ink is the red C_YES below, the NO ink is the plate's dark blue);
  * the six LED states, read off the lamp body: BRIGHT (available) vs PINK HATCHED
    (unavailable).
It asserts nothing. It tabulates, so that a ladder -- if there is one -- is read off a
table of measurements rather than argued from two remembered numbers.

Usage: tools/re/probe_youth_cap_mask.py [extra_frame.png ...]
"""
from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

REPO = Path(__file__).resolve().parents[2]

# Frames that show a YOUTH TEAM screen with a scout hired. Each is (label, path).
FRAMES = [
    ("s85 J. Casson", REPO / "tools/re/refs/youth-caps-2026-08-01/b9_01_youth_before.png"),
    ("s84 C. Dewhurst",
     REPO / "screenshots/wine-captures-2026-08-01-b9-sign-drive/probe_0028_04_youth_after.png"),
    ("walkthrough P. Mitchell",
     REPO / "screenshots/original-walkthrough-2026-07-02/047_164509.png"),
]

# The six capability rows, in the order FUN_00575d90 ORs them (crit +0x10 .. +0x24).
CAPS = ["HANDLING", "DRIBBLING", "TACKLING", "HEADING", "PASSING", "SHOOTING"]
# EVERY span below was measured off the frames themselves (a red-ink and gold-pixel scan
# over `047_164509.png`, the all-six-YES witness, cross-checked against a two-YES one), not
# taken from the port's own layout constants -- the point of the probe is to read the
# ORIGINAL, so reading it through the port's numbers would be circular.
#   value cells   left  x107..127   right x232..252   rows y127 / y140 / y153 (pitch 13)
#   LED lamps     left  x26..43     right x153..168   rows y171 / y189 / y207 (pitch 18)
VALUE_X = {"L": (105, 130), "R": (230, 255)}
VALUE_Y0, VALUE_DY = 126, 13
VALUE_SLOT = {"HANDLING": ("L", 0), "DRIBBLING": ("L", 1), "TACKLING": ("L", 2),
              "PASSING": ("R", 0), "HEADING": ("R", 1), "SHOOTING": ("R", 2)}
LED_X = {"L": (26, 44), "R": (153, 169)}
LED_Y0, LED_DY = 170, 18
LED_SLOT = {"HANDLING": ("L", 0), "DRIBBLING": ("L", 1), "TACKLING": ("L", 2),
            "PASSING": ("R", 0), "HEADING": ("R", 1), "SHOOTING": ("R", 2)}
# The scout's star bar: gold glyphs on a ~11.5 px pitch from x250. A FULL glyph is a five
# column diamond (1,3,5,3,1); a HALF is the left half of one, so counting glyphs is not
# enough -- the run WIDTH is what separates 1.5 from 2.0, and that difference is the whole
# reason this probe exists.
STAR_SPAN = (240, 70, 320, 100)
C_STAR = (255, 223, 0)          # the gold the star glyph is drawn in
C_YES = (206, 0, 0)             # the value cell's YES ink


def near(px: np.ndarray, rgb, tol=60) -> np.ndarray:
    return (np.abs(px - np.array(rgb)).sum(-1) < tol)


def read_stars(a: np.ndarray) -> str:
    """Count star glyphs by GOLD COLUMNS: a full glyph is a wide run, a half is ~half."""
    x0, y0, x1, y1 = STAR_SPAN
    box = a[y0:y1, x0:x1]
    r, g, b = box[..., 0], box[..., 1], box[..., 2]
    gold = (r > 180) & (g > 140) & (b < 130)
    cols = gold.sum(0)
    runs, cur = [], 0
    for c in cols:
        if c > 0:
            cur += 1
        elif cur:
            runs.append(cur)
            cur = 0
    if cur:
        runs.append(cur)
    if not runs:
        return "0 (no gold found)"
    # Run WIDTH cannot separate a half star from a full one: the half glyph measures 4
    # columns against the full glyph's 5. AREA can -- the full diamond is 13 gold px
    # (1+3+5+3+1) and the half is 8. So the rating is total gold AREA over the area of one
    # full glyph, taken as the largest single-glyph area in the bar, rounded to the half.
    areas, cur = [], 0
    for c in cols:
        if c > 0:
            cur += int(c)
        elif cur:
            areas.append(cur)
            cur = 0
    if cur:
        areas.append(cur)
    # Classify each glyph by its own area against the bar's fattest glyph: the half star is
    # 8 px where the full one is 13, i.e. ~62%, and the glyph's own width varies by a pixel
    # with the plate behind it, so the split sits at 75%.
    unit = max(areas)
    full = sum(1 for x in areas if x > unit * 0.75)
    half = len(areas) - full
    return f"{full + 0.5 * half:.1f}  (areas={areas}, unit={unit})"


def read_values(a: np.ndarray) -> dict:
    out = {}
    for cap in CAPS:
        col, row = VALUE_SLOT[cap]
        cx0, cx1 = VALUE_X[col]
        y = VALUE_Y0 + row * VALUE_DY
        cell = a[y:y + VALUE_DY, cx0:cx1]
        r, g, b = cell[..., 0], cell[..., 1], cell[..., 2]
        out[cap] = "YES" if int(((r > 140) & (g < 80) & (b < 80)).sum()) > 6 else "NO"
    return out


def read_leds(a: np.ndarray) -> dict:
    """Lamp state by SATURATION: the available lamp is a saturated red, the unavailable
    one is the pink hatched art -- far lower saturation at a similar brightness."""
    out = {}
    for cap in CAPS:
        col, row = LED_SLOT[cap]
        cx0, cx1 = LED_X[col]
        y = LED_Y0 + row * LED_DY
        cell = a[y:y + 12, cx0:cx1].reshape(-1, 3)
        if cell.size == 0:
            out[cap] = "?"
            continue
        sat = (cell.max(1) - cell.min(1))
        out[cap] = "BRIGHT" if float(sat.mean()) > 45 else "hatched"
    return out


def main(argv: list[str]) -> int:
    frames = list(FRAMES) + [(Path(p).name, Path(p)) for p in argv]
    rows = []
    for label, path in frames:
        if not path.exists():
            print(f"  (missing: {path})")
            continue
        a = np.asarray(Image.open(path).convert("RGB")).astype(int)
        if a.shape[1] > 640:
            a = a[:, :640]
        vals = read_values(a)
        leds = read_leds(a)
        yes = [c for c in CAPS if vals[c] == "YES"]
        bright = [c for c in CAPS if leds[c] == "BRIGHT"]
        rows.append((label, read_stars(a), yes, bright))

    print(f"{'frame':26s} {'stars':22s} {'YES values':38s} available LEDs")
    for label, stars, yes, bright in rows:
        print(f"{label:26s} {stars:22s} {str(yes):38s} {bright}")
    print()
    print("Read the table, do not read a conclusion into it: the question is whether the "
          "count of YES values is a function of the star rating alone.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
