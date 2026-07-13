#!/usr/bin/env python3
"""Hub top-edge DROPDOWN BAR + OPTIONS panel chrome from the 2026-07-12 wine captures.

Original behaviour (captured live, screenshots/wine-captures-2026-07-12/):
hovering the top edge of the MANAGER MENU hub slides a full-width bar down from
the top (hub_dropdown_bar.png / _2.png — byte-identical bar region in both):
PREMIER 98 logo left, a MONITOR icon (opens the MATCH OPTIONS modal —
dropdown_matchoptions_*.png) and a HEADPHONES icon (opens the OPTIONS panel —
dropdown_options_panel.png: MUSIC + SOUND FX volume sliders each with an
X-box + OFF label, TRANSITIONS ON/OFF X-boxes, OK). The captured state matches
the written MANAGER.INI (MUSIC: OFF / SOUND: OFF / TRANSITIONS: ON), which
pins the semantics: X in the slider-row box = channel OFF; X in ON = transitions on.

Outputs:
  app/art/screens/dropdown/bar.png          (0,0) 640x41
  app/art/screens/dropdown/options_box.png  (136,124) 367x220
  app/art/screens/dropdown/box_checked.png / box_empty.png   (the X-box states)
  app/data/dropdown_chrome_samples.json     widget rects + fills (frame-measured)
"""
from __future__ import annotations

import json
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
CAP = ROOT / "screenshots/wine-captures-2026-07-12"
ART = ROOT / "app/art/screens/dropdown"
BAR_F = CAP / "hub_dropdown_bar.png"
BAR_F2 = CAP / "hub_dropdown_bar_2.png"
OPT_F = CAP / "dropdown_options_panel.png"

BAR = (0, 0, 640, 41)
BOX = (136, 124, 367, 220)


def region(arr, x, y, w, h):
    return arr[y:y + h, x:x + w]


def bounds(mask, x0, y0):
    ys, xs = np.where(mask)
    return [int(xs.min() + x0), int(ys.min() + y0),
            int(xs.max() - xs.min() + 1), int(ys.max() - ys.min() + 1)]


def main() -> None:
    bar_img = Image.open(BAR_F).convert("RGB")
    a = np.asarray(bar_img, dtype=int)
    b = np.asarray(Image.open(BAR_F2).convert("RGB"), dtype=int)
    diff = int((np.abs(a[0:41] - b[0:41]).sum(axis=2) > 12).sum())
    if diff != 0:
        raise SystemExit(f"bar region differs between the two captures ({diff} px) — cursor?")
    ART.mkdir(parents=True, exist_ok=True)
    bar_img.crop((0, 0, 640, 41)).save(ART / "bar.png")
    print("wrote bar.png (640x41), cross-frame diff 0")

    # icon hit rects: the two icon clusters right of x 500 within the bar are the
    # only bright (non-pattern) pixels there
    bright = (a[0:41, 500:640] > 90).any(axis=2)
    cols = np.where(bright.sum(axis=0) > 2)[0] + 500
    # split into two clusters on the largest gap
    gaps = np.where(np.diff(cols) > 4)[0]
    split = cols[gaps[0]] if len(gaps) else cols[len(cols) // 2]
    mon_cols = cols[cols <= split]
    hp_cols = cols[cols > split]
    mon = bounds(bright[:, mon_cols.min() - 500:mon_cols.max() - 500 + 1],
                 int(mon_cols.min()), 0)
    hp = bounds(bright[:, hp_cols.min() - 500:hp_cols.max() - 500 + 1],
                int(hp_cols.min()), 0)
    print("monitor icon", mon, "headphones icon", hp)

    o = np.asarray(Image.open(OPT_F).convert("RGB"), dtype=int)
    Image.open(OPT_F).convert("RGB").crop(
        (BOX[0], BOX[1], BOX[0] + BOX[2], BOX[1] + BOX[3])).save(ART / "options_box.png")
    print("wrote options_box.png")

    # sliders: red gradient runs (witnessed full = volume 100)
    red = (o[:, :, 0] > 130) & (o[:, :, 1] < 90) & (o[:, :, 2] < 90)
    sliders = []
    for y0, y1 in [(195, 210), (236, 251)]:
        m = red[y0:y1, BOX[0]:BOX[0] + BOX[2]]
        sliders.append(bounds(m, BOX[0], y0))
    print("sliders", sliders)

    # X-boxes: light-grey bordered squares. Locate the four: two right of the
    # sliders (rows ~same as sliders), two on the TRANSITIONS row (~288..306).
    grey = (o > 150).all(axis=2)
    boxes = {}
    for name, (sx, sy, sw, sh) in [
        ("music_box", (383, 200, 48, 30)),
        ("sfx_box", (383, 241, 48, 30)),
    ]:
        m = grey[sy:sy + sh, sx:sx + sw]
        if not m.any():
            raise SystemExit(f"{name}: no light box found in ({sx},{sy},{sw},{sh})")
        boxes[name] = bounds(m, sx, sy)
    # the TRANSITIONS pair: same 13x13 X-box widget as the slider rows (ON box
    # carries the witnessed red X; OFF box is the witnessed empty state); the
    # ON/OFF labels sit beneath (rows 308+), outside these rects
    boxes["trans_on_box"] = [310, 287, 13, 13]
    boxes["trans_off_box"] = [360, 287, 13, 13]
    print("boxes", boxes)

    # X-box state patches from the TRANSITIONS pair (witnessed: ON checked, OFF empty)
    for src, out in [("trans_on_box", "box_checked.png"), ("trans_off_box", "box_empty.png")]:
        x, y, w, h = boxes[src]
        Image.open(OPT_F).convert("RGB").crop((x, y, x + w, y + h)).save(ART / out)
    cw, ch = boxes["trans_on_box"][2], boxes["trans_on_box"][3]
    ew, eh = boxes["trans_off_box"][2], boxes["trans_off_box"][3]
    print(f"wrote box_checked.png ({cw}x{ch}) + box_empty.png ({ew}x{eh})")

    # OK button: red glyph cluster bottom-right of the box (rows 318-345)
    okm = red[318:345, 420:520]
    ok = bounds(okm, 420, 318)
    print("ok label", ok)

    # slider trough fill for volume truncation (pixel right above slider 1 start)
    trough = [int(v) for v in o[sliders[0][1] - 2, sliders[0][0] + 4]]

    meta = {
        "bar_rect": list(BAR), "box_rect": list(BOX),
        "monitor_icon": mon, "headphones_icon": hp,
        "music_slider": sliders[0], "sfx_slider": sliders[1],
        **boxes, "ok_label": ok, "trough_fill": trough,
        "frames": [BAR_F.name, BAR_F2.name, OPT_F.name],
    }
    out = ROOT / "app/data/dropdown_chrome_samples.json"
    out.write_text(json.dumps(meta, indent=1) + "\n")
    print(f"wrote {out.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
