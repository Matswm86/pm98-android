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

## Every call site, read — and the 0x20 arm (2026-08-02, s88)

Status: the 74 sites are ENUMERATED with their arguments, `THR = 0x21` is confirmed as the
value of exactly the two sites this leaf was reversed from, and the **other arm of
`FUN_005cbea0` is identified**. The 1-px on-sprite kit edge is no longer "unlocated": it is
the `flags = 0x20` arm, and what is left is one runtime-built table.

`Evidence:` `tools/re/probe_shadow_sites.py`, `app/scripts/PMShadow.gd`,
`extracted/Premier Manager 98/MANAGER.EXE` @0x5cbea0, @0x5d60a0, @0x5c0607, @0x5c0688,
@0x5c0d50.

### 1. The arguments, all 74 sites

`probe_shadow_sites.py` byte-scans `.text` for `E8 rel32` targeting the thunk `0x4b7f60` or
the core `0x5cbea0`, then decodes each caller FORWARDS with capstone from every start in a
192-byte window and keeps the longest decode that lands exactly on the call — an image whose
linear sweep desynchronises cannot be walked backwards, but a stream that hits the call on an
instruction boundary is in sync with it by construction. **65 of 74 push all three leading
arguments as immediates, in SEVENTEEN distinct triples:**

| (flags, thr, cap) | sites | | (flags, thr, cap) | sites |
|---|---|---|---|---|
| `(0x10, 0x40, 0xff)` | 23 | | `(0x10, 0x20, 0xff)` | 2 |
| `(0x10, 0x00, 0x00)` | 11 | | `(0x10, 0x50, 0xff)` | 2 |
| `(0x20, 0x21, 0x5a)` | 9 | | `(0x20, 0x40, 0x80)` | 1 |
| `(0x20, 0x21, 0x63)` | 4 | | `(0x20, 0x30, 0xff)` | 1 |
| `(0x10, 0x30, 0xff)` | 4 | | `(0x10, 0x21, 0x63)` | 1 |
| `(0x10, 0x32, 0x64)` | 4 | | `(0x10, 0x21, 0x84)` | 1 |
| | | | `(0x10, 0x40, 0x80)` | 1 |
| | | | `(0x20, 0x00, 0x00)` | 1 |

The remaining 9 push registers or memory. The two sites `PMShadow` was written from are
`0x50f9e3` (`0x10, 0x21, 0x63` — the man-to-man markers) and `0x50fba1`
(`0x10, 0x21, 0x84` — the 48x64 kit); **no other site shares their thr**, and the modal
value is `0x40`. So "THR is the same at every witnessed site" was true of the two that had
been looked at and false of the image.

### 2. `flags` selects between TWO passes, and only one of them is modelled

`FUN_005cbea0`'s own branch, from the decompile:

```
if ((param_1 & 0x20) == 0) {
    if ((param_1 & 0x10) != 0) { FUN_005d66f0(scratch, alpha); ... }      // <- the SPREAD arm
} else {
    FUN_005d66f0(scratch, 0x100);
    if (...) FUN_005d60a0(alpha);                                          // <- the EDGE arm
}
... if thr != 0: FUN_005d6590(scratch, thr, cap, alpha)                    // the IIR spread
... FUN_005d5220(dest, rect, scratch, src, ...)                            // the composite
```

`PMShadow` implements the `0x10` path. **Sixteen of the 74 sites are `0x20`**, and `0x20`
runs `FUN_005d60a0` — which is not a spread at all:

* it walks the mask and, for every NON-ZERO byte, builds a **12-bit neighbourhood code** from
  twelve comparisons of `(alpha >> 8)` against the bytes at offsets
  `+2s, +s, +s+1, +2, +1, +1-s, -2s, -s, -1-s, -2, -1, +s-1` (s = stride), with bit 0 forced
  to 1;
* and replaces the byte with **`DAT_006b5890[code] * 2 + 1`**.

That is an EDGE / outline classifier, not a decay — which is exactly the shape of the
residual the port has been failing to reproduce for six sessions: a partial alpha ON the
sprite's own top/left edge, blending the sprite toward the DESTINATION, where a spread can
only ever write outside the silhouette and only ever toward black.

### 3. The kit widget is a 0x20 site — read, not inferred

s87 located `0x5c0688` as a shadow call inside the RIDIESC picture widget's paint. Its flags
word is not an immediate, so the enumeration above lists it as unresolved; the disassembly
resolves it:

```
0x5c05eb  mov edx,[esi+0x70]                 ; the widget's list index
0x5c05e8  mov eax,[esi+0x74]                 ; its item index
0x5c05fa  mov edx,[esi+edx*8+0x360]          ; the record array  (FUN_005c0d50's own +0x360)
0x5c0601  lea edi,[eax+eax*8]                ; 37 * eax ...
0x5c0604  lea eax,[eax+edi*4]                ; ... i.e. the 0x94 record stride
0x5c0607  mov di,WORD PTR [edx+eax*4+0x90]   ; record +0x90
...
0x5c0685  push edi                           ; -> param_1 = flags
0x5c0688  call 0x5cbea0
```

and `FUN_005c0d50(bank, list, 0x20, 0x32, item)` is the setter that put `0x20` at record
`+0x90` and `0x32` at `+0x92`, on all 90 RIDIESC-bank fetches. **So every RIDIESC kit blit in
the game runs the EDGE arm with flags 0x20**, which is why fitting spread models to it never
converged.

The same reading names what `+0x64` / `+0x66` are: they are the two bytes the paint pushes as
`param_2` / `param_3`, i.e. this widget's own **thr and cap**, per widget rather than per
call site.

### 4. What is left, precisely

`DAT_006b5890` is at VA 0x6b5890. `.data` is VA 0x652000..0x6dc508 with only 0x15000 raw
bytes, so anything above 0x667000 is uninitialised — **the LUT is built at runtime**, and the
next step is to find the code that writes it, not to cut it out of the file. After that the
0x20 arm is a direct transcription and the group-draw kits/flags
(`docs/re/cupdraw_screen_re.md`, 33 px of 221 per kit, 8..11 of 140 per flag) are the ready
made oracle for it, together with the EURO GROUP leader cell s84/s85 measured.

## The 0x20 arm, RUN — the table is out of the running original (2026-08-02, s89)

`Evidence:` `extracted/Premier Manager 98/MANAGER.EXE` @0x5cbea0, @0x5d60a0,
@0x5c9762..0x5c9a02; `tools/re/build_aliasing_table.py`, `tools/re/probe_kit_edge_pass.py`,
`tools/re/probe_groupdraw_kit_edge.py`, `tools/re/refs/aliasing-2026-08-02/`.

s88 left this "one runtime-built table away". The table is now in hand, and two of s88's
numbers are corrected on the way.

### 1. The code is THIRTEEN bits, and the table is 8,192 entries — not twelve and 4,096

`FUN_005d60a0` makes **twelve** comparisons and then executes `stc; rcl ebx,1`, so bit 0 is
hardwired to 1 (the centre pixel is known non-zero — the loop only enters on a non-zero
byte). The code is 13 bits, `DAT_006b5890` is `0x2000` bytes, and the generator's own
`mov edx, 0x2000` accumulator init says the same. The offsets, MSB first:

    bit12 2W  bit11 W  bit10 W+1  bit9 2  bit8 1  bit7 1-W  bit6 -2W
    bit5  -W  bit4 -1-W  bit3 -2  bit2 -1  bit1 W-1  bit0 = 1

`W` is the mask surface's STRIDE (`[esi+0x1c]`), the walk starts at `pixels + 2*(W+1)` and
runs `(H-4)*W - 4` bytes. One quirk, transcribed rather than tidied away: the neighbour test
is `cmp ch, byte [edi+off]`, and `ch` is the LOOP COUNTER's own high byte, not a constant.
For a 0/255 mask it is only ever 0..2, so it is exactly "the neighbour is non-zero", but a
faithful port keeps it.

### 2. `FUN_005cbea0`'s argument map, corrected

The probe's `(flags, thr, cap)` triples are the first three pushes, and only `flags` was
right about what it does:

```
if (flags & 3)  FUN_005d6820(src, flags & 3)                 # rotate/flip
if (flags & 0x20) { FUN_005d66f0(mask, src, 0x100)           # silhouette at full alpha
                    FUN_005d60a0(mask, arg1 ? 0x100 : alpha) }  # THE EDGE PASS
else if (flags & 0x10) FUN_005d66f0(mask, src, arg1 ? 0x100 : alpha)
if (arg1) FUN_005d6590(mask, mask, arg1, arg2, alpha)        # THE SPREAD, in place
```

So `arg1` is the SPREAD's threshold and gates whether the spread runs at all; `arg2` is its
cap; the alpha is a LATER argument (`[esp+0xe8]`). A `0x20` site with `arg1 != 0` runs BOTH
passes, edge first. `FUN_005d60a0`'s own tail scale is skipped whenever its parameter is
`0x100`, which is exactly the case at every site that also spreads.

### 3. Where the table comes from — and why it is not in either source

The graphics-init at `0x5c9762` is guarded by a run-once byte at `0x6b7920`. It looks for
`dat\aliasing.dat` (`FUN_005ec1d0`), reads 8,192 bytes straight into `DAT_006b5890` if it is
there, and otherwise loads **`letras.bmp`** and computes them:

* thirteen offsets in the SAME order as the classifier's bits, `[0, W-1, -1, -2, -1-W, -W,
  -2W, 1-W, 1, 2, W+1, W, 2W]` — the two readings agree bit for bit, which is the strongest
  cross-check either of them has;
* 8,192 `(sum, count)` pairs with **`count` initialised to 1**;
* per pixel, `code = Σ_k (p[i+offs[k]] >= 0x80) << k`, then FOUR rounds of
  `sum[c] += d; count[c] += 1; sum[c ^ 0x1fff] += 0xff - d; count[c ^ 0x1fff] += 1`, with
  `c` re-mapped between rounds by `T(c) = (c & 1) | ((c >> 3) & 0x3fe) | ((c & 0xe) << 9)`;
* `table[c] = sum[c] // count[c]`, then the file is written out as a cache.

**Neither `letras.bmp` nor `dat\aliasing.dat` ships** — measured over the install, all six
PKFs, `pm98.iso` and `Premier_Manager_98.rar` (`build_aliasing_table.py --check-sources`).
The ISO's two `letras` hits are MANAGER.EXE's own string literal. And the running game does
not write the cache either: after a full boot + career + match nav, `dat/` is still empty.

### 4. So it was read out of the process, and it is provably the generator's own output

`m5_rsp_capture.py` now dumps `0x6b5890..+0x2000` and the guard over the RSP stub it already
holds. Guard `1`, table 3,921 non-zero of 8,192, 223 distinct. Three structural predictions
of the transcription all hold — **rotation invariance at 0 violations in 8,192**, the
`count = 1` signature (616 complementary pairs summing to exactly 127, i.e. `255//2` and
`0//2`), and monotonicity in popcount from 1.0 at zero bits to **253 at thirteen**. The
bytes and the full argument are in `tools/re/refs/aliasing-2026-08-02/`.

**253, not 255, is the finding.** Every fully-enclosed pixel of every `0x20`-blitted sprite
is nudged 2/256 toward the destination — which is the one thing a spread can never do, is
where s84 measured 415 of 449 residual pixels to be, and is exactly the magnitude that flips
a pixel through the `DAT_00675398` dither.

### 5. What it scores, said plainly

`probe_groupdraw_kit_edge.py` runs the pass on the GROUP DRAW's four RIDIESC kits — the only
kit oracle with a WITNESSED destination, because five of the six group boxes are empty and
their row bands are pixel-identical, so the pixels under group A's kits are readable off
group C's. With no free parameter it takes the four kits from **396 wrong pixels to 349**.
Directionally right; not closed. Two things are still open and neither is the table:

* ~~determinism across boots is unverified~~ — **CONFIRMED the same session on THREE
  independent boots**, one of them a fully isolated instance (copied wineprefix, own
  wineserver, own X display, own boot and career): all three dump the same 8,192 bytes,
  same sha256. WHERE the generator's input comes from is
  still not reversed — `letras.bmp` is in neither source and the load plainly succeeds;
* the probe picks each row's kit by best match rather than by club, and NO sprite in
  `app/art/kits/ridi` gets those cells under 74 px even with the pass applied. The
  geometry is not the suspect — the probe's constants are the port's own
  (`CupDrawScreen.GBOX_Y[0] = 55`, `GROW_Y0 = 20`, `GROW_PITCH = 25`,
  `GKIT_AT = (7, 2)`), and `PMChrome.ridi_kit` loads `art/kits/ridi/<club_id>.png`
  verbatim with no recolour. So the open question is the SPRITE: which club id each
  group-A row carries, and whether the port's RIDIESC bank even covers the European
  clubs this draw shows. Score the pass against the PORT's own render of that screen,
  with the club ids it actually feeds, before drawing any conclusion about the pass.

## The 0x20 arm, SHIPPED — 0 px, and it was hiding a palette bug (2026-08-02, s90)

`Evidence:` `tools/re/probe_groupdraw_edge_render.py`, `tools/re/diff_cupdraw_parity.py`,
`app/scripts/PMShadow.gd`, `app/scenes/CupDrawScreen.gd`, `tools/re/build_match_header_from_frames.py`,
`extracted/Premier Manager 98/MANAGER.EXE` @0x5cbea0, @0x5d60a0, @0x5d6590, @0x5c0688.

§5 above asked for exactly one thing before any conclusion: *score the pass against the
PORT's own render of that screen, with the club ids it actually feeds.* Done, and the answer
is a close — but only after the render-diff turned up a defect that had nothing to do with
the pass and was inflating every number in §5.

### 1. The sprite was never the suspect it looked like

`Main.gd`'s CUPDRAW shot already feeds group A as club ids **1076 / 1003 / 1223 / 1147** —
Sporting Port., Real Madrid C.F., Anorthosis, W.Lodz, the four names printed on the frame —
and `PMChrome.ridi_kit` loads `art/kits/ridi/<club_id>.png` for each. Scored against those
four files instead of a best match, the plain blit is wrong on **135 / 87 / 86 / 88** px,
which is the same 396 §5 reports: the best-match search had been picking the right sprites
all along.

Splitting that residual by the sprite's own alpha is what breaks it open:

| | on-sprite | off-sprite |
|---|---|---|
| Sporting Port. (1076) | **82** of 221 | 53 of 119 |
| the other three | 33 / 33 / 34 | 54 / 53 / 54 |

Two different faults, neither of them "no sprite gets under 74 px".

### 2. The off-sprite half is the SPREAD, at a site nobody had read as a 0x20 site

The ~54 px per cell outside the silhouette are a dithered drop shadow down and to the right,
which the port did not draw at all here. `0x5c0688` — the RIDIESC picture widget's own call
into `FUN_005cbea0`, whose flags word is `FUN_005c0d50`'s `param_4` at record `+0x90` — is
a `0x20` site, and `FUN_005cbea0` runs the `FUN_005d6590` spread AFTER the edge whenever
`thr != 0`. So this widget paints BOTH passes, and the group draw is the screen that shows
it: rim inside, shadow outside.

### 3. Sporting's extra 49 px were a PALETTE bug, and it is 91 kits wide

The port's `ridi/1076.png` renders its hoops `(66,104,44)`; the frame shows `(17,127,43)`.
Neither is a blend of the other — they are **palette index 120 in two different tables**.
The RIDIESC DIBs carry no colour table, so the colours come from whatever palette is
realised, and `build_match_header_from_frames.py` was decoding them through the shared VGA
table at `DAT.PKF +0x5CA`. That is the identical mistake `export_flags.flag_palette` had
already documented and fixed for the MINIBAND flags ("this used to use the shared VGA table
… and that is WRONG for the flags"), and nobody had asked the same question of the kits.

**21 of the 256 entries disagree between the two tables, and 91 of the 476 kits use one of
the 21.** Re-baked through `flag_palette()` (MANAGER.PAL + the Windows statics), Sporting's
on-sprite residual goes **82 -> 31** and the other three do not move, which is what a
palette fix should look like. The six fixture witnesses still assert SAD=0 either way —
none of clubs 1000 / 40 / 1301 / 1021 touches an affected index, so that gate never had an
opinion on this. The knockout kit lists (`uefa` 68 -> 56, `cwc` 64 -> 56) and the EURO
LEAGUE groups (B 107 -> 104, C 132 -> 114, F 117 -> 116) improved with it, and nothing
anywhere regressed.

### 4. The pass, scored against the port's own render

`probe_groupdraw_edge_render.py`, over group A's four kit cells (884 sprite px and 476
background px in all), reading its destination out of the port's own render of group C:

| | wrong px |
|---|---|
| port render, plain blit | 345 |
| edge only, no spread | 256 (on-sprite **131 -> 42**) |
| edge + spread(thr 0x21, cap 0x63) | 210 |
| edge + spread(thr 0x40, cap 0x80) | 178 |
| **edge + spread(thr 0x20, cap 0x80)** | **0** |

`thr` and `cap` are pushed as REGISTERS at `0x5c0688`, so unlike the 65 immediate-pushing
sites they cannot be read off the call, and they are not fitted either: the sweep is over
byte values the other sites attest (`thr` 0x20 at the two `(0x10, 0x20, 0xff)` sites, `cap`
0x80 at `(0x20, 0x40, 0x80)`), and the frame picks between them by a wide margin — 0 px
against 10 for the nearest neighbour on either axis and 250+ two steps away. The ORDER is
the decompile's, not a choice: edge first, spread second, and the spread reads the edge's
own output as its neighbours. Running them the other way round, or on separate masks,
scores 102 at best.

### 5. Shipped

`PMShadow.edge_mask` / `edge_blit` / `edge_texture` implement the arm; `app/data/aliasing.bin`
ships the table (sha256 `401e3411…0636`, the bytes read out of the running original);
`CupDrawScreen._group_kit` and `._group_flag` call it at thr 0x20 / cap 0x80. The MINIBAND
flags take the same pass and go **37 -> 4** px over the four rows.

`diff_cupdraw_parity.py`'s GROUPS exclusion list loses its four KIT rects entirely. The
whole 640x480 group-draw frame is now **5 raw px**, against 434 before: the flags' 4 and one
pre-existing stray at (189,114). The flags' 4 has a named cause and is not budget — this
screen draws the MINIBAND sprite from ROW 1 and its row 0 lands nowhere (measured in
`build_groupdraw_chrome_from_frame.py` and still unexplained), so the pass's top row is
computed over a destination that is not on screen.
