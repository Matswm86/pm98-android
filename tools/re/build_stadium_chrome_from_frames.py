#!/usr/bin/env python3
"""Bake the PM98 GROUND (ESTADIO) overview chrome 1:1 from the ORIGINAL-game frame.

Binding frame: screenshots/original-walkthrough-2026-07-02/172_154930.png — the real
MANAGER.EXE GROUND overview (default "WORK IN PROGRESS" state, Man Utd / Old Trafford).
This is the *body* chrome only; the shared BARRA header is drawn procedurally by
PMChrome.draw_header (same as every other career screen), and the marble background by
PMChrome.draw_bg, so the output is an RGBA 640x480 where ONLY the two panels + the four
action buttons are opaque (cut pixel-exact from the frame) and everything else is
transparent (marble/barra show through).

Dynamic, club-specific cells are BLANKED (filled with the frame-sampled flat background
of that cell) so StadiumScreen.gd can redraw them from the real Career model:
  * the ground-name text in the green header  (club.stadium)
  * the CAPACITY / CAR PARK / PITCH value cells (capacity from Career; car-park + pitch
    are uncaptured in game_db.json -> honest gaps, left blank)
  * the TOTAL IMPROVEMENTS money cell          (Career.works cost, £0 default)
The Old-Trafford stadium picture stays baked but is always fully covered in-app by the
opaque 320x240 estadio<tier> tile drawn at (299,148); no tier bleed is possible.

All rects were measured off the frame pixel grid (see docs/re/stadium_screen_re.md).
Run:  python3 tools/re/build_stadium_chrome_from_frames.py
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
FRAME = ROOT / "screenshots" / "original-walkthrough-2026-07-02" / "172_154930.png"
OUT_DIR = ROOT / "app" / "art" / "screens" / "stadium"

# ---- opaque regions cut from the frame (left, top, right, bottom), inclusive-ish -------
# Left "WORK IN PROGRESS" panel: white outer border x12, black inner border x281-282,
# top white border y69-72, bottom black border y465-466.
LEFT_PANEL = (12, 68, 283, 467)
# Right panel: green ground-name header + CAPACITY/CAR PARK/PITCH table + the stadium
# picture (black-framed). Left border x296-298, right border x619-620, top y65,
# picture bottom border y388-389.
RIGHT_PANEL = (296, 65, 621, 391)
# The 2x2 action grid (cut per-button so no marble sneaks between the columns).
BUTTONS = [
    (296, 404, 453, 436),   # IMPROVE  (roadwork-barrier icon + gold label)
    (480, 404, 624, 436),   # WORKS    (warning-triangle icon + gold label)
    (296, 437, 453, 470),   # MATCH DAY (disabled/washed in the frame)
    (480, 437, 624, 470),   # RETURN
]

# ---- dynamic cells to blank (left, top, right, bottom, fill-rgb) ------------------------
# Green header interior (0,95,0); value cells are a 3-step vertical gradient; footer bar
# behind "£0" is flat (220,220,220). Colours sampled from the frame.
BLANKS = [
    (306, 73, 614, 91, (0, 95, 0)),        # ground-name text band
    (410, 94, 618, 109, (100, 120, 140)),  # CAPACITY value cell
    (410, 111, 618, 126, (80, 100, 120)),  # CAR PARK value cell
    (410, 128, 618, 143, (60, 80, 100)),   # PITCH value cell
    (243, 452, 279, 465, (220, 220, 220)), # TOTAL IMPROVEMENTS money cell
]


def main() -> None:
    frame = Image.open(FRAME).convert("RGB")
    out = Image.new("RGBA", (640, 480), (0, 0, 0, 0))

    for (x0, y0, x1, y1) in [LEFT_PANEL, RIGHT_PANEL, *BUTTONS]:
        region = frame.crop((x0, y0, x1, y1)).convert("RGBA")
        out.paste(region, (x0, y0))

    for (x0, y0, x1, y1, rgb) in BLANKS:
        out.paste(Image.new("RGBA", (x1 - x0, y1 - y0), (*rgb, 255)), (x0, y0))

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    dst = OUT_DIR / "chrome.png"
    out.save(dst)
    print(f"wrote {dst.relative_to(ROOT)} (640x480 RGBA, {sum(1 for _ in BLANKS)} cells blanked)")


if __name__ == "__main__":
    main()
