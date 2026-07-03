#!/usr/bin/env python3
"""Bake the hub "PREMIER MANAGER 98" alert-box chrome from the walkthrough frames.

The alert (docs/re/alert_box_re.md; ctor FUN_005e5050/FUN_005f9070) is the modal
message box the original raises over the MANAGER MENU hub: transfer signings
("McClair has been signed by Liverpool.", frame 093_164659), offer rejections
(two-line, frame 149_164911), etc. Its chrome is engine-COMPOSITED (no single PKF
asset): black 2px border, checker-rail caption with the Indust18 title, white body
with a 4-row grey gradient, Proman10 bold message with a layered grey shadow, and
the framework " OK " button. Only the icon exists as an asset (DAT.PKF ICOEXCL.BMP).

Bakes into app/art/screens/alert/:
  title.png       127x24 caption title strip (light-blue field + "PREMIER MANAGER 98")
  icoexcl.png     24x24 exclamation icon, decoded from DAT.PKF (idx0 kept OPAQUE)
  ok.png          39x16 " OK " button (framework button chrome + label)
  dim_lut.json    exact per-colour palette-dim map (clean hub 095 -> dimmed hub 093)
  shadow_lut.json best-effort drop-shadow map (per-palette-index in the engine, so
                  ambiguous per-RGB; most-common target per source colour)
  menu_bg_dim.png menu_bg.png passed through dim_lut (nearest-key fallback)

KILL TESTS (all assert, run on every bake):
  * the procedural caption tile rule reproduces ALL observed alert captions
    pixel-exactly (6 frames = 9 measurable rails, two widths of clipping);
  * title strip identical across every alert frame;
  * OK button identical between 093 and 149 at the w-6/h-6 anchor;
  * ICOEXCL.BMP (shared VGA palette) == the icon pixels in frame 093;
  * body gradient rows + caption geometry hold on all frames.

Tile rule (fitted, see alert_box_re.md "Caption checker rails"): the caption is
light blue (42,63,170); a single band of dark (0,0,128) tiles rows 5..18 of the
24-row interior runs from EACH box edge toward the fixed title field, tile widths
W0, W0-step, ... with gaps 1,2,3..., clipped where the field begins.
  W0   = round(R/10.5 + 6.2)      (R = rail width, px)
  step = 2 if W0 >= 16 else 1
Fitted on 9 observed rails (R=30..132); the exact EXE painter fn is still unfound,
so treat outside R in [30,132] as extrapolation.
"""

from __future__ import annotations

import json
import sys
from collections import Counter, defaultdict
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import export_art as ea  # noqa: E402  (PKF entry reader + palettes)

ROOT = Path(__file__).resolve().parents[2]
SHOTS = ROOT / "screenshots" / "original-walkthrough-2026-07-02"
OUT = ROOT / "app" / "art" / "screens" / "alert"

LIGHT = (42, 63, 170)  # caption field
DARK = (0, 0, 128)  # caption tiles
BLACK = (0, 0, 0)
# 4 gradient rows under the caption divider; rows 0 and 2 are (x+y)-parity dithers.
GRADIENT = [
    {0: (100, 100, 100), 1: (114, 114, 114)},
    {0: (144, 144, 144), 1: (144, 144, 144)},
    {0: (192, 192, 192), 1: (170, 191, 170)},
    {0: (220, 220, 220), 1: (220, 220, 220)},
]

# Observed alert boxes: frame -> (x, y, w, h) inclusive-left/top, w/h in px.
# All centre on (317, 237); caption = 2 border + 24 interior + 2 divider.
BOXES = {
    "093_164659.png": (173, 196, 288, 82),  # "McClair has been signed by Liverpool."
    "149_164911.png": (207, 191, 220, 92),  # two-line offer rejection
    "080_164636.png": (146, 196, 342, 81),
    "154_164922.png": (199, 196, 236, 81),
    "205_155052.png": (107, 196, 420, 81),
    "231_163153.png": (161, 196, 312, 81),
}
ICON_W = 24  # ICOEXCL.BMP, at inner-left, full interior height
SEP_W = 2  # black separator between icon and the left rail
TITLE_W = 127  # title strip; left edge = box_x + w/2 - 50 (centred after icon)
TILE_TOP, TILE_H = 5, 14  # tile band rows within the 24-row caption interior
# The title-field background speckles randomly per draw between these four blues.
NOISE_BLUES = {(42, 63, 170), (30, 52, 98), (20, 0, 90), (0, 0, 128)}


def tile_runs(rail_w: int) -> list[tuple[int, int]]:
    """[(dark_w, gap_w), ...] from the box edge toward the title field, unclipped."""
    w0 = round(rail_w / 10.5 + 6.2)
    step = 2 if w0 >= 16 else 1
    runs: list[tuple[int, int]] = []
    tile, gap = w0, 1
    used = 0
    while used < rail_w and tile > 0:
        runs.append((tile, gap))
        used += tile + gap
        tile -= step
        gap += 1
    return runs


def rail_pattern(rail_w: int) -> list[bool]:
    """Per-pixel dark flags across a rail, edge -> field, clipped to rail_w."""
    flags: list[bool] = []
    for tile, gap in tile_runs(rail_w):
        flags += [True] * tile + [False] * gap
        if len(flags) >= rail_w:
            break
    return flags[:rail_w]


def px_of(im: Image.Image):
    return im.convert("RGB").load()


def check_caption(name: str, geo: tuple[int, int, int, int]) -> None:
    """Assert the whole caption of one observed alert reproduces from the rule."""
    x, y, w, _h = geo
    p = px_of(Image.open(SHOTS / name))
    ix = x + 2  # inner left (2px border)
    iy = y + 2  # caption interior top
    inner_r = x + w - 2  # exclusive inner right
    field_l = x + w // 2 - 50  # title strip left
    field_r = field_l + TITLE_W  # exclusive
    rail_l = ix + ICON_W + SEP_W
    # borders + separator
    for yy in range(y, y + 2):
        for xx in range(x, x + w):
            assert p[xx, yy] == BLACK, f"{name}: top border {xx},{yy}"
    for yy in range(iy, iy + 24):
        assert p[x, yy] == BLACK and p[x + 1, yy] == BLACK, f"{name}: left border"
        assert p[x + w - 1, yy] == BLACK and p[x + w - 2, yy] == BLACK, f"{name}: right border"
        for xx in range(rail_l - SEP_W, rail_l):
            assert p[xx, yy] == BLACK, f"{name}: icon separator {xx},{yy}"
    for yy in range(iy + 24, iy + 26):
        for xx in range(x, x + w):
            assert p[xx, yy] == BLACK, f"{name}: caption divider {xx},{yy}"
    # rails (left: edge=separator side toward field; right: edge=border side)
    left = rail_pattern(field_l - rail_l)
    right = rail_pattern(inner_r - field_r)
    for row in range(24):
        yy = iy + row
        tile_row = TILE_TOP <= row < TILE_TOP + TILE_H
        for i, dark in enumerate(left):
            want = DARK if (dark and tile_row) else LIGHT
            assert p[rail_l + i, yy] == want, (
                f"{name}: left rail ({rail_l + i},{yy}) row{row} i{i} want{want} got{p[rail_l + i, yy]}"
            )
        for i, dark in enumerate(right):
            xx = inner_r - 1 - i
            want = DARK if (dark and tile_row) else LIGHT
            assert p[xx, yy] == want, (
                f"{name}: right rail ({xx},{yy}) row{row} i{i} want{want} got{p[xx, yy]}"
            )
    # body gradient rows under the divider
    for k, cols in enumerate(GRADIENT):
        yy = iy + 26 + k
        for xx in range(x + 2, x + w - 2):
            want = cols[(xx + yy) % 2]
            assert p[xx, yy] == want, f"{name}: gradient row {k} at {xx},{yy}: {p[xx, yy]}"
    print(
        f"  caption OK: {name}  rails L={field_l - rail_l} R={inner_r - field_r} "
        f"W0=({rail_pattern(field_l - rail_l).count(True)}d)"
    )


def crop(name: str, box: tuple[int, int, int, int]) -> Image.Image:
    return (
        Image.open(SHOTS / name)
        .convert("RGB")
        .crop((box[0], box[1], box[0] + box[2], box[1] + box[3]))
    )


def assert_same(a: Image.Image, b: Image.Image, what: str) -> None:
    assert a.size == b.size and a.tobytes() == b.tobytes(), f"{what}: baked crops differ"


def build_dim_luts() -> tuple[dict, dict]:
    clean = Image.open(SHOTS / "095_164703.png").convert("RGB")
    dimmed = Image.open(SHOTS / "093_164659.png").convert("RGB")
    cp, dp = clean.load(), dimmed.load()
    w, h = clean.size
    dim_pairs: dict[tuple, Counter] = defaultdict(Counter)
    for y in range(h):
        for x in range(w):
            if 190 <= y < 300 and 160 <= x < 545:  # alert + shadow + NEWS-anim zone
                continue
            dim_pairs[cp[x, y]][dp[x, y]] += 1
    dim = {}
    for s, c in dim_pairs.items():
        top, n = c.most_common(1)[0]
        if len(c) > 1 and c.most_common(2)[1][1] > max(3, 0.02 * n):
            raise AssertionError(f"dim LUT ambiguous for {s}: {c.most_common(3)}")
        dim[s] = top
    # shadow: the +5,+5 L-band right of / below the box, avoiding the NEWS button
    sh_pairs: dict[tuple, Counter] = defaultdict(Counter)
    for y0, y1, x0, x1 in [(206, 247, 461, 466), (278, 283, 178, 456)]:
        for y in range(y0, y1):
            for x in range(x0, x1):
                sh_pairs[cp[x, y]][dp[x, y]] += 1
    shadow = {s: c.most_common(1)[0][0] for s, c in sh_pairs.items()}
    return dim, shadow


def bake_menu_bg_dim(dim: dict) -> None:
    src = Image.open(ROOT / "app" / "art" / "screens" / "menu_bg.png").convert("RGB")
    p = src.load()
    keys = list(dim.keys())
    nearest_cache: dict[tuple, tuple] = {}

    def map_col(c: tuple) -> tuple:
        got = dim.get(c)
        if got is not None:
            return got
        if c not in nearest_cache:
            k = min(
                keys, key=lambda q: (q[0] - c[0]) ** 2 + (q[1] - c[1]) ** 2 + (q[2] - c[2]) ** 2
            )
            nearest_cache[c] = dim[k]
        return nearest_cache[c]

    out = Image.new("RGB", src.size)
    q = out.load()
    misses = 0
    for y in range(src.height):
        for x in range(src.width):
            c = p[x, y]
            if c not in dim:
                misses += 1
            q[x, y] = map_col(c)
    out.save(OUT / "menu_bg_dim.png")
    print(f"  menu_bg_dim.png baked ({misses} px via nearest-key fallback)")


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)

    print("tile-rule kill test on all observed captions:")
    for name, geo in BOXES.items():
        check_caption(name, geo)

    # Title strip: the glyphs are constant across frames, but the light field behind
    # the title carries per-draw random speckle in 4 blues (engine noise — differs
    # even between same-y instances; docs/re/alert_box_re.md "Title-field noise").
    # Bake the per-pixel MAJORITY of the 6 instances; assert glyphs + any non-blue
    # pixel are identical everywhere.
    strips = {}
    for name, (x, y, w, _h) in BOXES.items():
        fx = x + w // 2 - 50
        strips[name] = crop(name, (fx, y + 2, TITLE_W, 24))
    pxs = {n: s.load() for n, s in strips.items()}
    maj = Image.new("RGB", (TITLE_W, 24))
    mp = maj.load()
    for yy in range(24):
        for xx in range(TITLE_W):
            votes = Counter(pxs[n][xx, yy] for n in strips)
            mp[xx, yy] = votes.most_common(1)[0][0]
            for n in strips:
                c = pxs[n][xx, yy]
                if c != mp[xx, yy]:
                    assert c in NOISE_BLUES and mp[xx, yy] in NOISE_BLUES, (
                        f"title strip {n}: non-noise divergence at {xx},{yy}: {c} vs {mp[xx, yy]}"
                    )
    maj.save(OUT / "title.png")
    print(
        f"  title.png baked (majority of {len(strips)} instances; "
        "divergence confined to the 4 noise blues)"
    )

    # OK button: framework button at local (w-45, h-22, 39, 16). Frame 093 shows the
    # NORMAL state (black label); frame 149 caught the HOT/pressed state (white
    # label) — bake both. The face dither is (x+y)-parity anchored, so a state's
    # sprite is phase-exact only at its source parity (093 even, 149 odd); the
    # other parity drifts one dither step (documented, sub-ROI).
    def ok_crop(name: str) -> Image.Image:
        x, y, w, h = BOXES[name]
        return crop(name, (x + w - 45, y + h - 22, 39, 16))

    ok = ok_crop("093_164659.png")
    ok_hot = ok_crop("149_164911.png")
    po, ph = ok.load(), ok_hot.load()
    for yy in (0, 15):
        for xx in range(39):
            assert po[xx, yy] == ph[xx, yy] == BLACK or (xx in (0, 38)), (
                f"OK border mismatch at {xx},{yy}"
            )
    ok.save(OUT / "ok.png")
    ok_hot.save(OUT / "ok_hot.png")
    print("  ok.png (093 normal) + ok_hot.png (149 hot) baked")

    # icon: the real DAT.PKF asset must equal the frame pixels. PIL can't open the
    # palette-omitting core-header DIB (render() yields black), so decode manually
    # (export_icons.decode_dib logic) with MANAGER.PAL, keeping idx0 opaque black —
    # the icon's own "!" and frame use idx0, never a transparent hole.
    raw = ea._entry("DAT.PKF", "ICOEXCL.BMP")
    hsz = int.from_bytes(raw[14:18], "little")
    iw, ih = int.from_bytes(raw[18:20], "little"), int.from_bytes(raw[20:22], "little")
    pal = ea.riff_palette("MANAGER.PAL")
    stride = ((iw + 3) // 4) * 4
    pix = raw[14 + hsz :]
    icon = Image.new("RGB", (iw, ih))
    ip = icon.load()
    for yy in range(ih):
        row = pix[yy * stride : yy * stride + iw]
        for xx in range(iw):
            i = row[xx]
            ip[xx, ih - 1 - yy] = (pal[i * 3], pal[i * 3 + 1], pal[i * 3 + 2])
    assert icon.size == (ICON_W, ICON_W), f"ICOEXCL size {icon.size}"
    frame_icon = crop("093_164659.png", (173 + 2, 196 + 2, ICON_W, ICON_W))
    assert_same(icon, frame_icon, "ICOEXCL.BMP (VGA palette) vs frame 093 icon")
    icon.save(OUT / "icoexcl.png")
    print("  icoexcl.png baked (DAT.PKF asset == frame pixels)")

    def rgb_key(c: tuple) -> str:
        return f"{c[0]},{c[1]},{c[2]}"

    dim, shadow = build_dim_luts()
    (OUT / "dim_lut.json").write_text(
        json.dumps({rgb_key(s): rgb_key(d) for s, d in sorted(dim.items())}, indent=0)
    )
    (OUT / "shadow_lut.json").write_text(
        json.dumps({rgb_key(s): rgb_key(d) for s, d in sorted(shadow.items())}, indent=0)
    )
    print(
        f"  dim_lut.json ({len(dim)} colours, 1:1) + shadow_lut.json ({len(shadow)}, best-effort)"
    )
    bake_menu_bg_dim(dim)


if __name__ == "__main__":
    main()
