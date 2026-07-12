#!/usr/bin/env python3
"""PRESEASON picker state chrome from the 2026-07-12 wine captures.

Sources (real MANAGER.EXE frames, captured live under this repo's .wineprefix —
see docs/re/pretemporada_screen_re.md "Home/away + stadium line"):
  screenshots/wine-captures-2026-07-12/pretemp_samerica_tab_active.png
      first-ever capture of the S.AMERICA tab active: real tab strips + the
      SUDAMERICA map WITH its runtime flag markers drawn.
  screenshots/wine-captures-2026-07-12/pretemp_slot4_wimbledon_selhurst_away_skipwashed.png
      4/4 rival slots full: SKIP washed (disabled), CONTINUE hot.

Outputs:
  app/art/screens/pretemp/tab_eu_off.png / tab_sa_on.png   (3,78)/(3,190) 21x112
  app/art/screens/pretemp/sudamerica_flags.png             (27,80) 300x220
  app/art/screens/pretemp/skip_off.png                     (501,331) 116x30
  app/art/screens/pretemp/continue_hot.png                 (501,438) 116x30
  app/data/pretemp_flag_markers_sa.json                    SAD-matched markers

Marker identity is resolved structurally: detect the 16x12 black-bordered
marker rects, then SAD-match each 14x10 interior against the S.American PAISES
flags (app/art/flags/flag_<code>.png) — do NOT hand-guess countries (same
doctrine as the EUROPA build).
"""

from __future__ import annotations

import json
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
CAP = ROOT / "screenshots/wine-captures-2026-07-12"
ART = ROOT / "app/art/screens/pretemp"
SA_FRAME = CAP / "pretemp_samerica_tab_active.png"
FULL_FRAME = CAP / "pretemp_slot4_wimbledon_selhurst_away_skipwashed.png"

# S.American PAISES codes present in the game DB (game_db clubs / country_codes.json)
SA_CODES = {
    3: "ARGENTINA",
    8: "BOLIVIA",
    10: "BRAZIL",
    14: "CHILE",
    16: "COLOMBIA",
    57: "URUGUAY",
    59: "PERU",
    64: "PARAGUAY",
    72: "VENEZUELA",
    89: "ECUADOR",
}
MAP_XY = (27, 80)
MAP_WH = (300, 220)
MARKER_WH = (14, 10)  # inner flag size; border rect is 16x12 (measured off the frame)


def cut(img: Image.Image, x: int, y: int, w: int, h: int, out: Path) -> None:
    img.crop((x, y, x + w, y + h)).save(out)
    print(f"wrote {out.relative_to(ROOT)} ({w}x{h})")


def _border_rects(arr: np.ndarray) -> list[tuple[int, int]]:
    """Marker candidates: 20x15 rects whose 1px perimeter is near-black and whose
    interior is not (the map flags all carry the 1px black border)."""
    dark = arr.sum(axis=2) < 150
    h, w = dark.shape
    hits: list[tuple[int, int]] = []
    for y in range(h - 12):
        for x in range(w - 16):
            if not (dark[y, x] and dark[y, x + 15] and dark[y + 11, x] and dark[y + 11, x + 15]):
                continue
            if not (
                dark[y, x : x + 16].all()
                and dark[y + 11, x : x + 16].all()
                and dark[y : y + 12, x].all()
                and dark[y : y + 12, x + 15].all()
            ):
                continue
            if dark[y + 1 : y + 11, x + 1 : x + 15].mean() > 0.5:
                continue  # solid dark block, not a flag
            hits.append((x, y))
    # de-dupe near-identical origins (border detector fires on 1px shifts)
    dedup: list[tuple[int, int]] = []
    for x, y in hits:
        if all(abs(x - a) + abs(y - b) > 4 for a, b in dedup):
            dedup.append((x, y))
    return dedup


def match_markers(map_img: Image.Image) -> list[dict]:
    arr = np.asarray(map_img.convert("RGB"), dtype=np.int16)
    fw, fh = MARKER_WH
    rects = _border_rects(arr)
    print(f"  {len(rects)} bordered marker rects detected")
    flags = {}
    for code, name in sorted(SA_CODES.items()):
        fp = ROOT / f"app/art/flags/flag_{code:03d}.png"
        if fp.exists():
            flags[code] = np.asarray(
                Image.open(fp).convert("RGB").resize(MARKER_WH, Image.NEAREST), dtype=np.int16
            )
        else:
            print(f"  flag_{code:03d} ({name}): MISSING flag art")
    # score every (rect, flag) pair on the interior patch, assign greedily best-first
    pairs = []
    for x, y in rects:
        patch = arr[y + 1 : y + 11, x + 1 : x + 15]
        for code, fl in flags.items():
            err = float(np.abs(patch - fl).sum()) / (fw * fh * 3 * 255.0)
            pairs.append((err, x, y, code))
    pairs.sort()
    used_r: set[tuple[int, int]] = set()
    used_c: set[int] = set()
    found: list[dict] = []
    for err, x, y, code in pairs:
        if (x, y) in used_r or code in used_c:
            continue
        used_r.add((x, y))
        used_c.add(code)
        found.append(
            {
                "code": code,
                "name": SA_CODES[code],
                "x": int(x + 1 + MAP_XY[0]),
                "y": int(y + 1 + MAP_XY[1]),
                "err": round(err, 4),
            }
        )
    found.sort(key=lambda m: m["name"])
    for m in found:
        print(f"  {m['name']:11s} code {m['code']:3d} abs ({m['x']},{m['y']}) err {m['err']}")
    if len(found) != len(rects):
        print(f"  WARNING: {len(rects)} rects but {len(found)} assigned")
    return found


def main() -> None:
    sa = Image.open(SA_FRAME).convert("RGB")
    full = Image.open(FULL_FRAME).convert("RGB")
    ART.mkdir(parents=True, exist_ok=True)

    # tab strips (widget rects R_TAB_EU/R_TAB_SA from the reversed creation fn)
    cut(sa, 3, 78, 21, 112, ART / "tab_eu_off.png")
    cut(sa, 3, 190, 21, 112, ART / "tab_sa_on.png")
    # the SA map with its runtime flags baked (as the EUROPA chrome bakes its 47)
    cut(sa, *MAP_XY, *MAP_WH, ART / "sudamerica_flags.png")
    # button states: rects grown -2,-2,+4,+5 for the bevel shadow (delete_on doctrine)
    cut(full, 501, 331, 116, 30, ART / "skip_off.png")
    cut(full, 501, 438, 116, 30, ART / "continue_hot.png")

    print("SAD-matching S.American flag markers:")
    markers = match_markers(
        sa.crop((MAP_XY[0], MAP_XY[1], MAP_XY[0] + MAP_WH[0], MAP_XY[1] + MAP_WH[1]))
    )
    out = ROOT / "app/data/pretemp_flag_markers_sa.json"
    out.write_text(json.dumps({"markers": markers}, indent=1) + "\n")
    print(f"wrote {out.relative_to(ROOT)} ({len(markers)} markers)")


if __name__ == "__main__":
    main()
