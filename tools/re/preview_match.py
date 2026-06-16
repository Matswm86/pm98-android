#!/usr/bin/env python3
"""PIL mirror of MatchScreen.gd — the project's no-display fidelity gate.

Loads the EXACT exported atlases (app/art/match/*.png) and mirrors MatchScreen's
projection + layout math so a match-view frame can be eyeballed locally before the
real Godot screenshot CI runs. Keep the constants here in lockstep with
MatchScreen.gd. Usage: preview_match.py [minute] [out.png]
"""
from __future__ import annotations

import math
import sys
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "app" / "art" / "match"
W, H = 640, 480
FAR_Y, NEAR_Y = 116.0, 470.0
FAR_HALF, NEAR_HALF = 196.0, 300.0
CENTER_X = 320.0
FAR_SCALE, NEAR_SCALE = 0.62, 1.18
TEAM_SHIFT = 0.34
SPRITE_W, SPRITE_H = 26, 52
DIRS, ANIM_ROWS = 8, 3
DIR_ANGLE = [0.0, 45.0, 90.0, 135.0, 180.0, 225.0, 270.0, 315.0]

# a tiny synthetic timeline: home goal @23, away goal @58, plus phases
LINES = [
    {"minute": 0, "side": -1, "text": "KICK OFF"},
    {"minute": 12, "side": 0, "text": "Corner taken by Smith"},
    {"minute": 23, "side": 0, "text": "Goal by Wright (HOME)", "goal": True},
    {"minute": 45, "side": -1, "text": "HALF TIME"},
    {"minute": 58, "side": 1, "text": "Goal by Cole (AWAY)", "goal": True},
    {"minute": 77, "side": 0, "text": "Shot saved by keeper"},
    {"minute": 90, "side": -1, "text": "FULL TIME"},
]


def lerp(a, b, t):
    return a + (b - a) * t


def project(l, w):
    y = lerp(FAR_Y, NEAR_Y, w)
    half = lerp(FAR_HALF, NEAR_HALF, w)
    x = CENTER_X + (l - 0.5) * half * 2.0
    s = lerp(FAR_SCALE, NEAR_SCALE, w)
    return x, y, s


def build_keys():
    keys = [{"m": 0.0, "l": 0.5, "w": 0.5, "goal": False}]
    for ln in LINES:
        side = ln.get("side", -1)
        mn = float(ln["minute"])
        if side == -1:
            keys.append({"m": mn, "l": 0.5, "w": 0.5, "goal": False})
            continue
        ar = side == 0
        g = ln.get("goal", False)
        if g:
            l, w = (0.95 if ar else 0.05), 0.5
        elif ln["text"].startswith("Corner"):
            l, w = (0.90 if ar else 0.10), (0.12 if int(mn) % 2 == 0 else 0.88)
        else:
            l, w = (0.70 if ar else 0.30), 0.36 + 0.28 * (int(mn) % 2)
        keys.append({"m": mn, "l": l, "w": w, "goal": g})
        if g:
            keys.append({"m": mn + 1.0, "l": 0.5, "w": 0.5, "goal": False})
    keys.sort(key=lambda k: k["m"])
    return keys


def ball_at(keys, minute):
    prev = keys[0]
    for k in keys:
        if k["m"] > minute:
            span = max(0.001, k["m"] - prev["m"])
            t = max(0.0, min(1.0, (minute - prev["m"]) / span))
            te = t * t * (3 - 2 * t)
            return lerp(prev["l"], k["l"], te), lerp(prev["w"], k["w"], te)
        prev = k
    return prev["l"], prev["w"]


def formation():
    rows = [
        [0.06, [0.5]],
        [0.24, [0.16, 0.38, 0.62, 0.84]],
        [0.44, [0.16, 0.38, 0.62, 0.84]],
        [0.64, [0.36, 0.64]],
    ]
    slots = []
    for side in range(2):
        for base_l, ws in rows:
            for w in ws:
                slots.append({"side": side, "l": base_l if side == 0 else 1 - base_l, "w": w})
    return slots


def dir_col(angle):
    def wrap(a):
        while a > 180:
            a -= 360
        while a < -180:
            a += 360
        return a
    return min(range(DIRS), key=lambda c: abs(wrap(angle - DIR_ANGLE[c])))


def render(minute, out):
    img = Image.new("RGBA", (W, H), (15, 26, 18, 255))
    d = ImageDraw.Draw(img)
    d.rectangle([0, 28, W, FAR_Y], fill=(77, 133, 220))
    bands = 11
    for i in range(bands):
        w0, w1 = i / bands, (i + 1) / bands
        yA, yB = lerp(FAR_Y, NEAR_Y, w0), lerp(FAR_Y, NEAR_Y, w1)
        hA, hB = lerp(FAR_HALF, NEAR_HALF, w0), lerp(FAR_HALF, NEAR_HALF, w1)
        col = (46, 133, 51) if i % 2 == 0 else (41, 117, 46)
        d.polygon([(CENTER_X - hA, yA), (CENTER_X + hA, yA),
                   (CENTER_X + hB, yB), (CENTER_X - hB, yB)], fill=col)
    # markings
    line = (235, 245, 235)
    for a, b in [((0, 0), (1, 0)), ((1, 0), (1, 1)), ((1, 1), (0, 1)), ((0, 1), (0, 0)), ((0.5, 0), (0.5, 1))]:
        x0, y0, _ = project(*a)
        x1, y1, _ = project(*b)
        d.line([(x0, y0), (x1, y1)], fill=line, width=2)
    cx, cy, _ = project(0.5, 0.5)
    d.ellipse([cx - 54, cy - 26, cx + 54, cy + 26], outline=line, width=2)

    keys = build_keys()
    bl, bw = ball_at(keys, minute)
    slots = formation()
    ball_shift = (bl - 0.5) * TEAM_SHIFT
    poss = 0 if bl >= 0.5 else 1
    carrier, best = -1, 9
    for i, s in enumerate(slots):
        if s["side"] != poss:
            continue
        dd = abs((s["l"] + ball_shift) - bl) + abs(s["w"] - bw)
        if dd < best:
            best, carrier = dd, i

    ph = Image.open(ART / "player_home.png").convert("RGBA")
    pa = Image.open(ART / "player_away.png").convert("RGBA")
    ball = Image.open(ART / "ball.png").convert("RGBA")
    draws = []
    for i, s in enumerate(slots):
        side = s["side"]
        sign = 1 if side == 0 else -1
        l = s["l"] + ball_shift + 0.012 * math.sin(minute * 0.8 + i * 1.7)
        w = s["w"] + 0.02 * math.sin(minute * 0.9 + i * 1.7 * 1.3)
        is_carrier = i == carrier
        if is_carrier:
            l = lerp(l, bl - 0.02 * sign, 0.8)
            w = lerp(w, bw, 0.8)
        l = max(0.02, min(0.98, l))
        w = max(0.04, min(0.98, w))
        x, y, sc = project(l, w)
        if is_carrier:
            fx, fy, _ = project(0.98 if side == 0 else 0.02, 0.5)
        else:
            fx, fy, _ = project(bl, bw)
        ang = math.degrees(math.atan2(fy - y, fx - x))
        col = dir_col(ang)
        anim = (int(minute * 4) + i) % ANIM_ROWS
        draws.append((y, side, x, sc, col, anim, is_carrier))
    draws.sort(key=lambda t: t[0])
    for y, side, x, sc, col, anim, is_carrier in draws:
        atlas = ph if side == 0 else pa
        cell = atlas.crop((col * SPRITE_W, anim * SPRITE_H, (col + 1) * SPRITE_W, (anim + 1) * SPRITE_H))
        dw, dh = int(SPRITE_W * sc), int(SPRITE_H * sc)
        cell = cell.resize((dw, dh), Image.NEAREST)
        d.ellipse([x - 7 * sc, y - 3 * sc, x + 7 * sc, y + 3 * sc], fill=(0, 0, 0, 70))
        img.alpha_composite(cell, (int(x - dw / 2), int(y - dh)))
    bx, by, bsc = project(bl, bw)
    bs = int(11 * bsc)
    ball2 = ball.resize((bs, bs), Image.NEAREST)
    img.alpha_composite(ball2, (int(bx - bs / 2), int(by - bs)))

    # scoreboard
    hg = sum(1 for ln in LINES if ln.get("goal") and ln["side"] == 0 and ln["minute"] <= minute)
    ag = sum(1 for ln in LINES if ln.get("goal") and ln["side"] == 1 and ln["minute"] <= minute)
    d.rectangle([0, 0, W, 26], fill=(20, 30, 60))
    d.text((14, 7), "HOME", fill=(255, 212, 77))
    d.text((W - 50, 7), "AWAY", fill=(255, 212, 77))
    d.text((CENTER_X - 14, 5), f"{hg} : {ag}", fill=(255, 255, 255))
    img.convert("RGB").save(out)
    print(f"wrote {out} @minute {minute}  score {hg}:{ag} ball=({bl:.2f},{bw:.2f}) carrier#{carrier}")


if __name__ == "__main__":
    mn = float(sys.argv[1]) if len(sys.argv) > 1 else 30.0
    out = sys.argv[2] if len(sys.argv) > 2 else "/tmp/pgf/match_preview.png"
    render(mn, out)
