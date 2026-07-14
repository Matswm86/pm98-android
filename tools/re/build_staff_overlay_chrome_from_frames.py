#!/usr/bin/env python3
"""Frame-bake the CLUB PERSONNEL hire-overlay chrome (docs/re/staff_re.md).

The hire overlay is a modal dialog over the CLUB PERSONNEL screen. Two witnessed
layouts (owned game frames, run1 15:47, screenshots/original-walkthrough-2026-07-02/):

  * SINGLE-ROLE  (7 categories): a CURRENT-<role> box + a "<ROLE>s AVAILABLE" pool
    list with green SIGN buttons + an 8-category right rail + OK.  Frames:
      PHYSIOTHERAPIST 108 · PSYCHOLOGIST 110 · ASSISTANT_MANAGER 113 · SCOUT 114 ·
      YOUTH_TEAM_MANAGER 115 · YOUTH_TEAM_SCOUT 117 · GROUNDSMAN 119.
  * TRAINERS  (frame 100): a CURRENT TRAINING STAFF 6-skill list + a STAFF AVAILABLE
    pool filtered by a 6-button skill picker + the same right rail + OK.

The per-role CURRENT/AVAILABLE header wording is IRREGULAR in the original ("CURRENT
YOUTH TEAM SCOUT" / "SCOUTS YOUTH TEAM AVAILABLE"; "GROUNDSMEN AVAILABLE") and cannot
be derived by rule, so it is BAKED from each category's own frame -- never generated.
Each single-role plate = a fully-neutral base (rail de-highlighted, career-dynamic
zones blanked to their local background) with that category's baked header strips +
its baked active-red rail button composited back on.  The scene redraws only the
CAREER-dynamic data (current holder, candidate rows, £amounts).  Every border, panel,
purple strip, WAGE label, money icon, SIGN and OK button is frame pixels; nothing invented.

  python3 tools/re/build_staff_overlay_chrome_from_frames.py
"""
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
FRAMES = ROOT / "screenshots" / "original-walkthrough-2026-07-02"
OUT = ROOT / "app" / "art" / "screens" / "staff"
OUT.mkdir(parents=True, exist_ok=True)

# Dialog outer crop (screen coords): outer bevel to outer bevel, purple strip to bottom
# black frame.  Same box in both layouts (the dialog does not move).
DLG = (67, 63, 525, 352)   # x, y, w, h  -> plate drawn at (67, 63)

# Sampled inks (RGB), verified in frame 113.
WHITE = (255, 255, 255)
LBLUE = (200, 220, 240)    # CURRENT header bar fill
NAVY = (0, 0, 128)         # <ROLE>s AVAILABLE bar fill
GREY = (220, 220, 220)     # candidate name-bar fill

# Right rail geometry (8 category buttons), screen coords.
RAIL = {"x": 452, "w": 123, "y0": 104, "pitch": 30, "h": 22}
RAIL_CATS = ["TRAINERS", "PHYSIOTHERAPIST", "PSYCHOLOGIST", "ASSISTANT_MANAGER",
             "SCOUT", "YOUTH_TEAM_MANAGER", "YOUTH_TEAM_SCOUT", "GROUNDSMAN"]

# Single-role category -> (frame, active rail index). The frame's own baked header +
# active-red button are correct for that category.
CAT_FRAME = {
    "PHYSIOTHERAPIST": ("108_154711.png", 1),
    "PSYCHOLOGIST": ("110_154717.png", 2),
    "ASSISTANT_MANAGER": ("113_154722.png", 3),
    "SCOUT": ("114_154724.png", 4),
    "YOUTH_TEAM_MANAGER": ("115_154726.png", 5),
    "YOUTH_TEAM_SCOUT": ("117_154729.png", 6),
    "GROUNDSMAN": ("119_154733.png", 7),
}

# Header text strips (screen coords) baked per category (bar + its role wording).
HDR_CURRENT = (90, 111, 418, 132)     # CURRENT <role>
HDR_AVAIL = (90, 262, 418, 282)       # <role>s AVAILABLE


def _rail_box(i, pad=3):
    x, y = RAIL["x"], RAIL["y0"] + i * RAIL["pitch"]
    return (x - pad, y - pad, x + RAIL["w"] + pad, y + RAIL["h"] + pad)


def _fill(px, rect, col):
    x, y, w, h = rect
    for yy in range(y, y + h):
        for xx in range(x, x + w):
            px[xx, yy] = col


def _neutral_base():
    """Frame 113 with a FULLY neutral rail (ASS. MANAGER active-red + SCOUT hover-border
    de-highlighted from the clean frame-100 rail band) and every career-dynamic zone
    blanked.  Header strips are blanked too; each plate re-bakes its own."""
    im = Image.open(FRAMES / "113_154722.png").convert("RGB")
    clean = Image.open(FRAMES / "100_154657.png").convert("RGB")
    im.paste(clean.crop((446, 191, 580, 252)), (446, 191))   # neutralise i3 red + i4 hover
    px = im.load()
    _fill(px, (93, 113, 322, 17), LBLUE)     # CURRENT header text
    _fill(px, (116, 151, 271, 18), WHITE)    # current holder line (name + stars)
    _fill(px, (215, 206, 150, 15), WHITE)    # current £wage
    _fill(px, (93, 264, 322, 15), NAVY)      # AVAILABLE header text
    for r in range(3):
        ry = 300 + r * 27
        _fill(px, (176, ry, 168, 16), GREY)  # candidate name bar
        _fill(px, (344, ry, 66, 16), WHITE)  # candidate £wage
    return im


def build_single():
    base = _neutral_base()
    for cat, (frame, k) in CAT_FRAME.items():
        f = Image.open(FRAMES / frame).convert("RGB")
        plate = base.copy()
        plate.paste(f.crop(HDR_CURRENT), (HDR_CURRENT[0], HDR_CURRENT[1]))   # CURRENT <role>
        plate.paste(f.crop(HDR_AVAIL), (HDR_AVAIL[0], HDR_AVAIL[1]))         # <role>s AVAILABLE
        plate.paste(f.crop(_rail_box(k)), (_rail_box(k)[0], _rail_box(k)[1]))  # active-red button
        plate.crop((DLG[0], DLG[1], DLG[0] + DLG[2], DLG[1] + DLG[3])).save(
            OUT / ("overlay_%s.png" % cat.lower()))
    return {
        "dialog": list(DLG),
        "cats": RAIL_CATS,                     # rail order (index 0 = TRAINERS)
        "rail": RAIL,
        "plates": {c: "overlay_%s.png" % c.lower() for c in CAT_FRAME},
        "holder": {"box": [115, 150, 273, 20], "name_x": 122, "name_y": 151,
                   "stars_right": 382, "stars_y": 152, "wage_center": 242, "wage_y": 206},
        "rows": {"first_y": 301, "pitch": 27, "name_x": 189, "name_y": 302,
                 "stars_right": 342, "wage_right": 404,
                 "sign": [[95, 300, 88, 17], [95, 327, 88, 17], [95, 354, 88, 17]]},
        "ok": [478, 360, 90, 28],
    }


def main():
    spec = {"single": build_single()}
    (OUT / "overlay_chrome.json").write_text(json.dumps(spec, indent=1))
    print("wrote", len(CAT_FRAME), "single-role plates + overlay_chrome.json")


if __name__ == "__main__":
    main()
