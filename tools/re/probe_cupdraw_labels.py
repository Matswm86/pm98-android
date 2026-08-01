#!/usr/bin/env python3
"""Read every banked SORTEO frame's COMPETITION title, ROUND plate and LEG plates by shape.

This exists because a corpus table written by eye went wrong. Three of the s87 frames in
`tools/re/refs/cupdraw-rounds-2026-08-01/` were filed under the wrong names -- the file
called `manutd_s1_eurocup_qtr_finals.png` is an **F.A. Cup ROUND 4** draw, the one called
`manutd_s1_facup_round3.png` is the **European Cup QTR. FINALS**, and `..._facup_round4.png`
is F.A. Cup ROUND 3 -- and the README's per-round leg-plate table was keyed on those names.
Nothing in the repo could have caught it, because nothing READ the plates.

This does. Each plate is cropped to its ink mask and XOR'd against the same string rendered
from the port's own BMFont metrics (`tools/re/pmfont_py.py`); a candidate that scores 0 drew
it and anything else is reported as unresolved rather than guessed at.

    python3 tools/re/probe_cupdraw_labels.py [dir ...]

Output is a markdown table, so the refs README can be regenerated from it rather than
maintained by hand.
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
sys.path.insert(0, str(HERE))
from pmfont_py import text_mask  # noqa: E402

DEFAULT_DIRS = [ROOT / "tools/re/refs/cupdraw-rounds-2026-08-01"]

# The three text fields of the SORTEO's left panel, with the span and ink each one uses
# (docs/re/cupdraw_screen_re.md).
TITLE = ((44, 34, 288, 58), (255, 255, 255), "proman14")
ROUND = ((44, 232, 288, 254), (255, 223, 0), "proman14")
LEGS = (
    ((26, 410, 90, 426), (255, 255, 0), "proman10"),
    ((26, 437, 90, 453), (255, 255, 0), "proman10"),
)

# Every string MANAGER.EXE carries for these plates, as the EXE spells them. The uppercase
# ROUND set is the SHARED block at VA 0x652ab0 (`SEMIFINALS` / `QTR. FINALS` / `1/8 FINAL` /
# `1/16 FINAL`) plus each competition's own (`COCA-COLA CUP`'s at 0x652ffc: `FINAL` /
# `QTR FINALS` / `ROUND 4..1`). Both spellings of the quarter-final are offered so the
# frames decide which one the screen actually uses -- they say `QTR. FINALS`, with the dot.
# The U.E.F.A. Cup title is offered in both of the EXE's spellings for the same reason, and
# the frames use BOTH: `p0747_cup_draw.png` (1/16 FINAL) reads `U.E.F.A. CUP` and
# `manutd_s2_uefa_1_32_finals.png` (1/32 FINALS) reads `UEFA CUP`, each at 0 px. What
# selects between them is not reversed; it is reported, not guessed.
TITLES = [
    "European Cup",
    "EUROPEAN CUP",
    "Coca-Cola Cup",
    "COCA-COLA CUP",
    "F.A. Cup",
    "U.E.F.A. Cup",
    "U.E.F.A. CUP",
    "UEFA Cup",
    "UEFA CUP",
    "Cup Winners' Cup",
    "EUROPEAN SUPERCUP",
]
ROUNDS = [
    "ROUND 1",
    "ROUND 2",
    "ROUND 3",
    "ROUND 4",
    "ROUND 5",
    "QTR. FINALS",
    "QTR FINALS",
    "QUARTER FINALS",
    "SEMIFINALS",
    "SEMIFINAL 1",
    "SEMIFINAL 2",
    "FINAL",
    "1/8 FINAL",
    "1/8 FINALS",
    "1/16 FINAL",
    "1/16 FINALS",
    "1/32 FINALS",
]
LEGWORDS = ["1ST LEG", "2ND LEG", "MATCH", "REPLAY"]


def read(a: np.ndarray, field: tuple, cands: list[str]) -> str:
    (x0, y0, x1, y1), ink, face = field
    sub = a[y0:y1, x0:x1]
    m = (sub == np.array(ink)).all(axis=2)
    if not m.any():
        return "(blank)"
    ys, xs = np.nonzero(m.any(1))[0], np.nonzero(m.any(0))[0]
    tm = m[ys.min() : ys.max() + 1, xs.min() : xs.max() + 1]
    best: list[tuple[int, str]] = []
    for s in cands:
        r = text_mask(face, s)
        if r.shape != tm.shape:
            continue
        best.append((int((r ^ tm).sum()), s))
    best.sort()
    if best and best[0][0] == 0:
        return best[0][1]
    return f"UNRESOLVED {tm.shape}" + (f" (nearest {best[0][1]} at {best[0][0]})" if best else "")


def main() -> None:
    dirs = [Path(p) for p in sys.argv[1:]] or DEFAULT_DIRS
    rows = []
    for d in dirs:
        for p in sorted(d.glob("*.png")):
            a = np.asarray(Image.open(p).convert("RGB"))[:480, :640]
            if a.shape[:2] != (480, 640):
                continue
            rows.append(
                (
                    p.name,
                    read(a, TITLE, TITLES),
                    read(a, ROUND, ROUNDS),
                    read(a, LEGS[0], LEGWORDS),
                    read(a, LEGS[1], LEGWORDS),
                )
            )
    print("| frame | competition | round plate | leg 1 | leg 2 |")
    print("|---|---|---|---|---|")
    for r in rows:
        print(f"| `{r[0]}` | {r[1]} | `{r[2]}` | {r[3]} | {r[4]} |")
    bad = [r for r in rows if any(str(v).startswith("UNRESOLVED") for v in r[1:])]
    print(f"\n{len(rows)} frames, {len(bad)} with an unresolved field")
    raise SystemExit(1 if bad else 0)


if __name__ == "__main__":
    main()
