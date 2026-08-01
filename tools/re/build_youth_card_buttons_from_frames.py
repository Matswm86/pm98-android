#!/usr/bin/env python3
"""Cut the YOUTH PLAYER card's button row from the original's own frames.

The card is `FUN_005274d0` — a YOUTH TEAM roster row opens it where a senior squad row
opens `FUN_00526a60`. Same FICHA chrome, different buttons. The four rects below are the
decompiled `FUN_00436fb0(w,h)` / `FUN_00436fb0(x,y)` pairs shifted by the card origin
(76,58), and they land pixel-exact on the witness: every crop is one clean plate with a
single dominant ink and no bleed into its neighbours.

WITNESS  `screenshots/refrun-manutd-1997-98/novel/p0771_UNKNOWN.png` — the reference-run
Man Utd career, 20 October 1998, youth player Darren SPINDLE. It holds TRAINING, SACK and
CANCEL ENABLED and PROMOTE DISABLED, which is exactly what the binary predicts for a
youngster still short of his BASE (`FUN_005274d0` greys PROMOTE unless all four CORE4 live
bytes equal their BASE twins).

Witnessed inks: TRAINING (0,255,0) green, SACK (166,202,240) light blue, CANCEL (255,0,0)
red — and CANCEL's red is the `FUN_00437020(0xff,0,0)` the decompile names for it, while
disabled PROMOTE's (255,223,85) is the washed form of its `FUN_00437020(0xff,0xdf,0)`.

RECONSTRUCTED (declared, not witnessed — no frame we hold shows them):
  * `promote_on`   — the enabled PROMOTE. Built from the witnessed ENABLED plate grammar
                     (identical across all three enabled buttons) 9-sliced to 114 px, with
                     the disabled button's own glyph mask stamped in the binary's own gold.
  * `training_off` — the disabled TRAINING. Built from the witnessed DISABLED plate
                     (PROMOTE's) 9-sliced to 84 px, with TRAINING's glyph mask in the
                     disabled ink. The engine's "greyed" pass is a palette remap, not RGB
                     arithmetic (0->128 but 80->160 and 128->192 is not one curve), so it
                     cannot be derived — a live capture of either state replaces this.
"""
from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
WITNESS = ROOT / "screenshots/refrun-manutd-1997-98/novel/p0771_UNKNOWN.png"
OUT = ROOT / "app/art/screens/youth_card"

# native rects = card-local (FUN_005274d0) + CARD_POS(76,58)
RECTS = {
    "training_on": (128, 387, 84, 25),
    "sack_on": (219, 387, 84, 25),
    "promote_off": (310, 387, 114, 25),
    "cancel_on": (446, 387, 106, 25),
}
INK = {
    "training_on": (0, 255, 0),
    "sack_on": (166, 202, 240),
    "cancel_on": (255, 0, 0),
}
PROMOTE_GOLD = (255, 223, 0)      # FUN_00437020(0xff,0xdf,0)
# A disabled label is not one ink: the witnessed PROMOTE renders its glyphs as a
# TWO-COLOUR (x+y)-parity dither, 156 px of (255,223,85) against 142 px of (255,255,170).
# That is the same washed-dither grammar the SCOUT screen's hire-gated widgets use. Both
# colours together are the glyph; masking on either alone gives a half-glyph.
DISABLED_INKS = ((255, 223, 85), (255, 255, 170))
CAP = 8                           # 9-slice cap width: past the bevel, into the flat fill


def as_frame(im: Image.Image) -> Image.Image:
    im = im.convert("RGB")
    return im.crop((0, 0, 640, im.height)) if im.width == 641 else im


def stretch(plate: Image.Image, w: int) -> Image.Image:
    """9-slice a button plate to `w` px: keep both caps, tile the middle column."""
    h = plate.height
    if w == plate.width:
        return plate.copy()
    out = Image.new("RGB", (w, h))
    out.paste(plate.crop((0, 0, CAP, h)), (0, 0))
    out.paste(plate.crop((plate.width - CAP, 0, plate.width, h)), (w - CAP, 0))
    mid = plate.crop((CAP, 0, CAP + 1, h))
    for x in range(CAP, w - CAP):
        out.paste(mid, (x, 0))
    return out


def glyph_mask(btn: Image.Image, inks) -> list[tuple[int, int]]:
    """Every pixel of the label, over one ink or a tuple of them (the disabled dither)."""
    want = {inks} if isinstance(inks[0], int) else set(inks)
    px = btn.load()
    return [(x, y) for y in range(btn.height) for x in range(btn.width)
            if px[x, y] in want]


def blank(plate: Image.Image, inks) -> Image.Image:
    """The plate with its label erased, so another label can be stamped on it."""
    out = plate.copy()
    px = out.load()
    # the flat fill is the plate's own most common colour outside the bevel caps
    from collections import Counter
    c = Counter(px[x, y] for y in range(4, out.height - 4)
                for x in range(CAP + 4, out.width - CAP - 4))
    fill = c.most_common(1)[0][0]
    for x, y in glyph_mask(out, inks):
        px[x, y] = fill
    return out


def stamp(plate: Image.Image, mask: list[tuple[int, int]], src_w: int, inks) -> Image.Image:
    """Centre `mask` (measured on a `src_w`-wide plate) onto `plate` and ink it.

    One ink paints solid; a pair paints the (x+y)-parity dither the disabled state uses.
    """
    out = plate.copy()
    px = out.load()
    dx = (out.width - src_w) // 2
    solid = isinstance(inks[0], int)
    for x, y in mask:
        nx = x + dx
        if 0 <= nx < out.width and 0 <= y < out.height:
            px[nx, y] = inks if solid else inks[(nx + y) & 1]
    return out


def main() -> int:
    if not WITNESS.exists():
        print(f"missing witness {WITNESS}", file=sys.stderr)
        return 1
    OUT.mkdir(parents=True, exist_ok=True)
    frame = as_frame(Image.open(WITNESS))
    cuts = {}
    for name, (x, y, w, h) in RECTS.items():
        btn = frame.crop((x, y, x + w, y + h))
        cuts[name] = btn
        btn.save(OUT / f"{name}.png")
        print(f"cut {name}.png  {w}x{h} from p0771 @({x},{y})")

    # --- promote_on: enabled plate grammar at 114px + PROMOTE's glyphs in solid gold ---
    enabled_blank = blank(cuts["training_on"], INK["training_on"])
    promote_glyphs = glyph_mask(cuts["promote_off"], DISABLED_INKS)
    promote_on = stamp(stretch(enabled_blank, RECTS["promote_off"][2]),
                       promote_glyphs, RECTS["promote_off"][2], PROMOTE_GOLD)
    promote_on.save(OUT / "promote_on.png")
    print(f"built promote_on.png (RECONSTRUCTION, {len(promote_glyphs)} glyph px)")

    # --- training_off: disabled plate at 84px + TRAINING's glyphs in the washed dither ---
    disabled_blank = blank(cuts["promote_off"], DISABLED_INKS)
    training_glyphs = glyph_mask(cuts["training_on"], INK["training_on"])
    training_off = stamp(stretch(disabled_blank, RECTS["training_on"][2]),
                         training_glyphs, RECTS["training_on"][2], DISABLED_INKS)
    training_off.save(OUT / "training_off.png")
    print(f"built training_off.png (RECONSTRUCTION, {len(training_glyphs)} glyph px)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
