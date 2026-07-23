#!/usr/bin/env python3
"""Bake the CAR PARK IMPROVEMENTS panel (owner frame 2026-07-23, native 640x480 at
desktop offset 641,196) into app/art/screens/stadium/carpark.png. Keeps the frame's
quadrant art + 'Level'/'1 2 3 4' labels + rotated NE/NW/SE/SW labels + PER LEVEL panel
(SPACES 500 / PRICE / WEEKS 7) verbatim, and BLANKS the dynamic cells the app redraws:
the 16 level-box interiors and the works triangle (StadiumScreen draws box fills + the
triangle from Career.car_park_levels / the in-progress work). Transparent outside the
left-panel body so it composites over chrome.png + improvements.png (shared title/tabs).
"""
from PIL import Image
import sys, pathlib

SRC = pathlib.Path.home()/"MWM-AI/projects/pm98-android/screenshots/user-captures-2026-07-23-ground-squad-transfer/09_07-54-47.png"
OUT = pathlib.Path.home()/"MWM-AI/projects/pm98-android/app/art/screens/stadium/carpark.png"
X0, Y0 = 641, 196                 # native game origin in the desktop capture

# left-panel body opaque window (below the shared IMPROVEMENTS title + 4 tabs)
BODY = (12, 156, 282, 446)        # design x0,y0,x1,y1

# 16 level boxes (11x11), origins per quadrant; interior 9x9 at +1 blanked to white
BOX_ORIGINS = ([(83,202),(97,202),(111,202),(125,202)]      # NE
             + [(208,202),(222,202),(236,202),(250,202)]    # NW
             + [(83,299),(97,299),(111,299),(125,299)]      # SE
             + [(208,299),(222,299),(236,299),(250,299)])   # SW
TRIANGLE = (91, 227, 123, 256)    # works triangle bbox -> white

def main():
    im = Image.open(SRC).convert("RGB").crop((X0, Y0, X0+640, Y0+480))
    px = im.load()
    # blank box interiors (keep the black outline)
    for (bx, by) in BOX_ORIGINS:
        for x in range(bx+1, bx+10):
            for y in range(by+1, by+10):
                px[x, y] = (255, 255, 255)
    # blank the works triangle
    for x in range(TRIANGLE[0], TRIANGLE[2]):
        for y in range(TRIANGLE[1], TRIANGLE[3]):
            px[x, y] = (255, 255, 255)
    out = Image.new("RGBA", (640, 480), (0, 0, 0, 0))
    body = im.crop(BODY).convert("RGBA")
    out.paste(body, (BODY[0], BODY[1]))
    out.save(OUT)
    print("wrote", OUT, out.size)

if __name__ == "__main__":
    main()
