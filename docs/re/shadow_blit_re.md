# The shadowed bitmap blit — `FUN_004b7f60`

Status: **BUILT 2026-07-28.** Reversed leaf for leaf out of `MANAGER.EXE`, ported as
`app/scripts/PMShadow.gd`, and gated live on the MAN-TO-MAN marking markers at
**0 differing px outside the D/M letter box**.
Evidence: `tools/re/diff_mantoman_parity.py`,
`tools/re/build_shadow_lut.py`, `app/tests/test_shadow_blit.gd`,
`screenshots/parity-run-2026-07-16/orig/66_mantoman_match.png`,
`screenshots/original-walkthrough-2026-07-02/058_162622.png`.

This is the pass every kit-bearing screen in the port had been bucketing since
2026-07-27 as "the un-reversed outline/bevel pass". It is not an outline and not a
bevel: it is a **soft drop shadow**, spread from the sprite's own silhouette and
alpha-composited under it, and it is **one pass, not three**.

## 1. The call

Every site goes through `FUN_004b7f60`, an 11-argument thunk that inserts a zero and
tail-calls

```
FUN_005cbea0(flags, thr, cap, l, t, r, b, bmp, 0, dx, dy, alpha)
```

The two MAN-TO-MAN sites (disassembled 2026-07-28) both push `flags = 0x10`,
`thr = 0x21`, `alpha = 0x100`, `dx = dy = 0`, and differ only in `cap`:

| site | what it draws | `cap` |
|---|---|---|
| `FUN_0050f970` @0x50f9e3 | the two 22x109 marking-line markers (`linead`/`lineam`) | `0x63` |
| `FUN_0050fae0` @0x50fba1 | the 48x64 opponent kit | `0x84` |

With `flags = 0x10` and a non-zero `thr`, `FUN_005cbea0` takes exactly one path
(`0x5cbf5a` → `0x5cbf84` → `0x5cbfaf`), and the two 76-byte stack objects its two
`FUN_005c9210` constructors build are the scratch surfaces:

```
local_a4.FUN_005d66f0(bmp, 0x100)                      # silhouette
local_a4.FUN_005d6590(local_a4, thr, cap, 0x100)       # spread, IN PLACE
dest.FUN_005d5220(&rect, local_a4, (0,0), bmp, (0,0))  # composite
```

## 2. `FUN_005d66f0` — the silhouette

Ensures the scratch matches the source's `width`/`height` (`FUN_005c9a30(w, h, 8, …)`),
then walks `height * stride / 4` dwords and writes `0xff` for every **non-zero** source
byte and `0x00` for every zero one — four bytes at a time, which is why it covers the
row PADDING as well as the picture. With `alpha = 0x100` the scaling tail
(`param_3 != 0x100`) is skipped, so the scratch is a flat 0/255 mask of "this pixel is
not palette index 0".

## 3. `FUN_005d6590` — the spread

Called with `param_1 == param_2` (in place). It walks the scratch **linearly** — from
byte `stride + 1` for `(height - 1) * stride - 1` bytes — so it runs off the end of one
row straight into the next, which is exactly what puts a shadow tail at the LEFT edge
of the row below a sprite whose silhouette reaches its right edge.

At each byte:

```
s = buf[i]                                   # read before the write
if s < 0xf0:                                 # i.e. outside the silhouette
    avg = (buf[i-stride] + 2*buf[i-stride-1] + buf[i-1]) >> 2    # up, up-left x2, left
    d   = avg - thr
    if avg >= thr and d != 0 and s < d:
        buf[i] = min(d, cap)
```

The three neighbours are read from the routine's own **output**, so it is an IIR
filter: the value decays by `thr` per step and the shadow reaches about
`cap / thr` pixels down and to the right. The up-left weight of 2 is what tilts it
diagonally. `cap` is the only thing that differs between call sites, and it is the
shadow's darkness.

The decompiler shows the threshold as a rolling byte (`bVar8 = (byte)(iVar7 >> 8)`);
following the CONCAT chain, that register only ever holds `param_3`, so it is the
constant `thr` on every iteration.

### The padding question

The spread's linear walk touches the row-padding bytes, so their content is part of
the answer. Measured both ways on `linead.bmp` and `lineam.bmp` (stride 24, width 22,
so two pad bytes per row): **the file's own pad bytes and zeroed pad bytes produce an
identical mask**, so the port zero-fills, which is what a freshly created surface
holds and what a Godot `Image` gives. Recorded rather than assumed.

## 4. `FUN_005d5220` — the composite

Per destination pixel, with `a` = the mask byte:

* `a == 0` — leave the destination.
* `a == 0xff` — copy the source byte (this is the sprite itself; the port draws it
  with an ordinary blit).
* otherwise — blend, with `w = a + 1`:

```
blended_ch = dst_ch + (int8)((((src_ch - dst_ch) * w) & 0xffff) >> 8)      # per channel
index      = (blended_r & 0xf8) << 8 | (blended_g & 0xfc) << 3 | (blended_b & 0xf8) >> 3
dest       = DAT_00675398[ (parity << 16) | index ]
```

**Two wraps are load-bearing and neither may be replaced by a clamp**: the product is
truncated to 16 bits before the shift, and the sum lands in a byte, so `255 + 123` is
`122`, not a saturated `255`. That single detail is what makes the `cap = 0x84` stamp
come out as the frames' `(128,128,128)` / `(114,114,114)` instead of a pale grey —
clamping it costs 124 px on the MAN-TO-MAN kit alone.

Outside the silhouette the source byte is always index 0, so **every shadow pixel is
the destination blended toward palette black**. That is why a caller can draw its
background, lay the overlay on it and then blit the sprite normally.

## 5. `DAT_00675398` — the dither pair, and where "screen parity" comes from

The lookup is indexed by `RGB565 | (parity << 16)`, i.e. it is **two 64 KB tables**.
`parity` is the routine's own ordered-dither bit: seeded `(x0 + y0) & 1` from the
destination rect's top-left, XORed once per pixel and once more per row
(`uVar18 ^= 0x10000` in the pixel loop, `uVar18 ^= uVar12` at the row end), so

```
parity(X, Y) = (X + Y + 1) & 1      # ABSOLUTE screen coordinates
```

That is the cause of the rule the kit-list bake had already found empirically — "the
outline pass is dithered on absolute screen parity", `knockout_views_re.md`, where
wells at odd x agreed pixel for pixel and a well at even x disagreed at 222 of 616
positions. It is not a property of the sprite; it is this bit.

Both tables are built at startup and are not constants in the image (`.text` holds no
writer whose operands we could read), so they are **reconstructed** by
`tools/re/build_shadow_lut.py` and validated against the frames:

```
centre    = (r5*8 + 4, g6*4 + 2, b5*8 + 4)        # the 565 cell's own centre
table0[c] = nearest palette entry to centre        , ties -> HIGHEST index
table1[c] = nearest palette entry to 2*centre - palette[table0[c]]
```

i.e. table 1 is the partner that puts the PAIR'S MEAN on the cell centre — an ordinary
half-tone pair. The palette is the realised one (MANAGER.PAL plus the 20 Windows
statics, the same table `export_flags.flag_palette()` proved on the MINIBAND flags).

**Evidence.** Every shadow-band pixel of the two marking markers in
`66_mantoman_match.png` was inverted back to (565, parity) → observed index: **751
observations, 751 reproduced**. The same reconstruction with ties broken LOW scores
750/751, which is what pins the tie-break direction; a plain nearest-palette lookup
with no dither scores 428/751, and the best single-bias fit scores 683/751.

## 6. What it closes, and what it does not

`tools/re/diff_mantoman_parity.py`, three cases over two careers:

| | before | after |
|---|---|---|
| D marker (22x109) | 322 px | **20 px** — the D letter the original draws as TEXT over the sprite |
| M marker (22x109) | 335 px | **16 px** — same, the M letter |
| 48x64 opponent kit | 287 px | **56 px** |
| bucket total | 944 / 947 | **92 / 94** |

The markers are exact. ~~The kit's remaining 56 px are **not** the shadow pass: they are
pixels the original paints pure black and the port's `art/kits/<id>.png` has as
transparent, i.e. the 48x64 MINIESC bank is missing content the original's sprite
carries.~~ — **WRONG, and closed the same day (s78).** It was never 56 px (15,
re-measured), the original was never the one painting black (the PORT was), and the bank
was never missing content: the vertical club plate is NINETEEN columns of black
(x243..x261) and `build_mantoman_chrome_from_frames.py` filled x262 as well — kit-local
x=33, the exact column of the residual. `diff_mantoman_parity.py` reports the kit rect at
**0 px on both careers**, which is what this table's "56" row should read.

## 7. Using it

```gdscript
PMShadow.for_sprite(cache_key, background_texture, background_origin,
                    sprite_texture, screen_position, PMShadow.CAP_KIT)
```

returns a cached `Texture2D` to draw **between** the background and the sprite.
`background_origin` is where the background texture's own (0,0) sits on the 640x480
screen — the dither parity is resolved in screen space and may not be handed a
panel-local frame.

~~The screens that currently BAKE this pass from frames instead (`KnockoutScreen`'s
`kitwell_under_L/over_L` and `icon_under/over_sf*`, `PMChrome.panel_kit`'s per-screen
banks) are still on their bakes; moving them onto this module is a separate pass, one
gate at a time, and is listed in `REMAINING.md`.~~ — **DO NOT. Measured 2026-08-01: those
screens do not use this pass.** `FindRefsTo` lists all 53 call sites of the `FUN_004b7f60`
thunk and **none** of them is in the knockout drawers' range — the `AGGR.` / `FINALIST`
drawers sit at 0x46cd3f / 0x46f521 / 0x490a6c, and the nearest shadow-blit sites are
0x4b29c0 and 0x4fe616. The s78 EuroGroupScreen experiment had already found this
empirically (wiring `PMShadow` under its kits made the gate WORSE, 864 → 1048 px over six
frames — `euro_league_screen_re.md`); the call graph is the reason. Whatever draws the
48x64 / 24x32 kit ring on those screens is a **different, still unlocated** pass, and the
position-constant bakes stay.
