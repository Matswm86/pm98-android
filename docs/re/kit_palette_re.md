# The per-club KIT RECOLOUR — reversed end to end (closes the A8 "kit ramps" gap)

Status: **BUILT 2026-07-28.** Every number below is read out of `MANAGER.EXE` or the shipped
data files. Where the port diverges it says so in one place (§8).

Evidence: `tools/re/export_jug_bank.py` (the bake + its own hard validations),
`app/scripts/JugKit.gd` (the port), `app/tests/test_jug_render.gd` (the gate),
`tools/re/refs/kit-2026-07-28/` (the rendered proof).

Method: Ghidra 12.1.2 headless (`~/ghidra-projects/pm98`, `DecompileAt.java`) on
`FUN_005b63e0` / `FUN_005a2830` / `FUN_005a5460` / `FUN_005d34a0` / `FUN_005caae0`, plus
`objdump -M intel -b pei-i386` on `FUN_005923f0` (whose stack frame Ghidra cannot recover),
plus the extracted `DATSIM.PKF` / `DAT.PKF`.

## 0. The headline

**PM98 never bakes a coloured player sprite.** `JUG.PGF` stays 8-bit PALETTE INDICES from disk
to screen; immediately before each blit the engine remaps every pixel through a **256-byte
LUT** (`FUN_005d34a0`, a plain per-pixel `xlat` into the scratch page `matchctx+0x1a4c`) and
then draws that page as a textured quad. The kit, the skin, the hair and the shirt number are
all just entries in that LUT.

The earlier port baked ONE colouring chosen off the art's own histogram (a tinted shirt and a
neutral shorts/socks ramp). That is now gone.

## 1. `matchctx+0x1a5c` — the palette table (five 256-byte blocks)

`FUN_005923f0` allocates a 2 KB buffer and 256-aligns it (`+0x1a5c = align256(+0x1a54 + 0xff)`),
then fills five blocks with five `rep movsd` runs of `0x40` dwords each (0x592f5e-0x592fcf):

| block | source | actor |
|---|---|---|
| `+0x000` | `DatSim\paletas\p96a0000.dat` | team 0 outfield |
| `+0x200` | `DatSim\paletas\p96a0000.dat` | team 1 outfield |
| `+0x400` | `palarb` | the referee |
| `+0x500` / `+0x600` | `pallin` | keepers 1 / 2 (overwritten per team, §2) |

Both team blocks therefore START as `P96A0000.DAT`, a full 256-entry identity-ish remap that
already carries a default skin ramp at 1..8 and a default hair ramp at 0x15..0x18. That is why
an un-personalised player still renders correctly: the fallback is the game's own.

`FUN_005a2830` points each actor at his block: `player+0x2dc = [matchctx+0x1a5c] + ti*0x200 +
(slot == 0 ? 0x100 : 0)` — **slot 0 is the goalkeeper**, and he reads the `palpor` strip.

## 2. `FUN_005b63e0` — the team's kit, once per side at match load

Filename: `"DatSim\paletas\P96A"` + `("000" + "%ld" of the club key)` **last four characters**
(`FUN_005e5c50(buf, -4)`; the literal `"000"` is `DAT_00665844`, the format `"%ld"` is
`DAT_00652f00`) + `".DAT"`. The key is `lineup+0x790`, the club's EQ96 code — the same key the
function uses two lines later for `DBDat\MiniEsc\EQ96####` and `DBDat\RidiEsc\EQ96####`. When
the path does not resolve (`FUN_005ec1d0` returns 0) it falls back to `P96A0000.DAT`.

**829 P96A and 829 P96B files exist, 192 bytes each**, plus the 256-byte `P96A0000.DAT`. Their
layout, from the code that consumes them:

| bytes | consumer | meaning |
|---|---|---|
| `[0..127]` | copied to `team+0x216`, then to `player+0x2e0` | the **16x8 shirt pattern grid**; each cell is a palette RAMP BASE index |
| `[128..175]` | the `0x30`-iteration loop at L174-181 | 48 LUT entries, written over palette slots **9..56** |
| `[176]` | `team+0x2c6` -> `team+0x2d6` | the kit **class colour** |
| `[177..191]` | — | zero in every file |

The copy loop's own arithmetic: `dest[8 + (i+1)] = src[(i & 0xf) + (i >> 4)*0x10]` for
`i = 0..0x2f`, and `(i & 0xf) + (i >> 4)*0x10 == i`, so it is `LUT[9 + i] = ramp[128 + i]`.

**The change strip.** `if (param_2 == 1 && *(char*)(matchctx + 0x742) == *(char*)(team + 0x2c6))`
the whole load re-runs against `P96B<key>.DAT`. `matchctx+0x742` is not a separate field: the
team headers are at `matchctx + 0x46c + ti*0x320`, so `0x46c + 0x2d6 == 0x742` **is team 0's own
class byte**. The away side wears its change strip exactly when its first-choice class collides
with the home side's.

**The number ink.** `bVar1 = matchctx[0x1e69 + class*4]`, and `matchctx+0x1e68` is the match
palette: `FUN_005923f0` @0x592d8e `rep movsd`s 256 dwords from the RIFF `PAL ` chunk's 0x18
into it, so `+0x1e69 + class*4` is that entry's **GREEN** byte. Then
`team+0x2d8 = (green > 100) ? 0x67 : 0x7f` — a dark grey number on a light kit, white on a dark
one.

**The keeper strip.** A `do/while` draws `n = (rand()*8) >> 15` and re-rolls while
`DAT_006657b0[n]` (that strip's class colour) equals the team's own class, or — for the away
side — either of `matchctx+0x742` / `+0x743` (the home kit's and home keeper's classes). The
winner loads `DatSim\paletas\palpor<n>.DAT`, a full 256-byte LUT, into `+ti*0x200 + 0x100`.
`DAT_006657b0 = [0x65, 0x92, 0x8c, 0xbc, 0xb0, 0xaa, 0x80, 0x86]`.

## 3. The match palette is one of FIVE

`FUN_005923f0` draws `matchctx+0x1980 = (rand()*5) >> 15` and loads `Dat\simul<n>.pal`
(`Dat\simulpcf6.pal` on the 3D path). **`SIMUL0.PAL`'s 256 entries are byte-identical to
`DATSIM\PALETA.ACT`**; `SIMUL1..4` differ only in the grass ramps 10..36 — they are the five
pitch conditions. The bake ships all five and validates the SIMUL0/PALETA.ACT identity on every
run.

The palette's colour bands are what make the pattern grid work: `0x80..0x85` red,
`0x86..0x8b` yellow, `0x8c..0x91` blue, `0x92..0x97` green, … — **six-entry ramps on a
six-multiple grid**, bright first.

## 4. `FUN_005a2830` — the player's own copy

* `player+0x2d4 = (slot != 0)` — the shirt-pattern pass runs for outfielders only.
* `player+0x2d5 = 1` — the skin/hair pass always runs.
* `0x20` dwords (**128 bytes**) copied `team+0x216 -> player+0x2e0`: his own pattern grid.
* **The shirt number**, out of `matchctx+0x2550` — the surface loaded from `DatSim\NumCam.bmp`,
  which is **8 x 480 8-bit = sixty 8x8 glyphs**, indexed `pixels + (number-1)*0x40`, the number
  being `lineup rec+0x42` clamped to 1..0x3c. Two passes, both writing into the pattern grid:
  1. L165-186 — the inner **6x6** of the glyph (`glyph[9 + col + row*8]`), stamped at pattern
     offset `0x1a` with companions `-2 / 0 / -0x11 / +0xf`, in the kit's **class colour**: the
     patch that clears the stripes behind the number.
  2. L200-215 — the **full 8x8** glyph at pattern offset `8`, in the contrast **ink**.
  Offset 8 is column 8 of a 16-wide grid, i.e. the **back** of the shirt.
* **Skin**: `DAT_006653a8` = `[72..79, 88..95, 80..87]`, three 8-entry ramps, picked by
  `rec+0x2c - 1`. Palette 72..79 is a light ramp, 88..95 a dark one, 80..87 a mid brown.
* **Hair**: `DAT_00665380`, 4 bytes a row, picked by `rec+0x30 - 1`. Row 1 is the **bald** case:
  it flattens the skin ramp (`skin[7] = skin[6] = skin[5]`) and redirects to row `skin + 6`,
  which is why rows 6/7/8 repeat the three skin tones.

**`.DBC +0x16` and `+0x17` are therefore SKIN TONE and HAIR COLOUR.** Both were carried as
"semantics un-RE'd" in `session_lineup_re.md` and both are now resolved by construction: the
9,547-player database uses `+0x16 ∈ {1,2,3}` (exactly the three skin ramps) and
`+0x17 ∈ {1..6}` (exactly the six non-redirect hair rows). Nothing else in the game reads them.

## 5. `FUN_005a5460` — the LUT, per draw

```
if (player+0x2d5) {                      // skin + hair
    LUT[0x01..0x04] = player+0x360..0x363     // skin[0..3]
    LUT[0x05..0x08] = player+0x364..0x367     // skin[4..7]
    LUT[0x15..0x18] = player+0x368..0x36b     // hair[0..3]
}
if (player+0x2d4) {                      // the shirt
    for col in 0..15:
      colM = mirrored ? ((col & 8) - (col & 7)) + 7 : col
      for row in 0..7:
        cell = pattern[row*16 + col]
        for shade in 0..5:
          idx = JUGCAM[(row + (frame.h5*16 + colM)*8)*6 + shade]
          if (idx) LUT[idx] = ramp(cell, shade)
}
FUN_005d34a0(frame, scratch = matchctx+0x1a4c, LUT)   // remap
FUN_005cc670(quad, scratch, ...)                      // draw
```

`ramp(base, s)` = `DAT_006654b0[s]` when `base == 0x7f` (white), `DAT_006654a8[s]` when
`base == 0x67` (grey), else `base + 5 - s`. The two tables are
`[113,115,119,122,124,127]` and `[96,99,100,101,102,103]` — points on the linear grey band,
which is why white and grey need their own rows instead of a six-step colour band.

The mirror maps each half of the grid onto itself (`0..7 <-> 7..0`, `8..15 <-> 15..8`), and it
applies to the **JUGCAM column only** — the pattern cell is read at the unmirrored column, so a
mirrored sprite still wears the same design.

## 6. `JUGCAM.IND` — CLOSED, and it is not a camera table

The name misled the earlier spec (`jug_render_spec.md` §5 listed "JUGCAM.IND's record layout
and its consumer" as an open gap). Its one consumer is the loop above, and the index arithmetic
gives the layout with no ambiguity:

**72 maps x 16 columns x 8 rows x 6 shades = 55,296 bytes — the file's exact size.**

Each byte is *the palette index in the sprite that this (map, column, row, shade) cell paints*.
Zero means "this cell has no pixels in this map".

`matchctx+0x1a64` is the buffer: `MANAGER.EXE` @0x592a62 loads `datsim\jugcam.ind` and
@0x592d1b stores its data pointer there.

## 7. `.PGF` header `h5` — CLOSED

`FUN_005caae0` binds the on-disk header `[h0, h1, h2, h3, h4, h5]` to the 0x4c-byte frame slot:
`h0` -> the surface WIDTH, `h1` -> its height, `h2`/`h3` -> the anchor pair at `+0x38`/`+0x3c`,
`h4` -> the SOURCE row stride the copy advances by, and **`h5` -> slot `+0x10`**, which
`FUN_005a5460` uses as the JUGCAM map index. Across JUG.PGF's 4211 frames `h5` spans **exactly
0..71** — the 72 maps.

That also corrects a second thing the old bake had wrong: **`h0`, not `h4`, is the frame's
visible width.** `h0 <= h4` in every frame and the columns past `h0` are blank in all 4211 (both
checked, and both are hard failures in the exporter). The billboard's world width is built from
`slot+0x14` = `h0`, so baking at `h4` made every padded frame slightly too wide.

## 8. The port, and its one declared divergence

`app/scripts/JugKit.gd` ports §2, §4 and §5 as written. `JugRender.composite` is
`FUN_005d34a0` plus the palette, cached on (frame, LUT) — a running player cycles 14 phases per
direction, so steady-state redraws are cache hits.

**DECLARED DIVERGENCE — the keeper strip's draw.** The re-roll RULE is the binary's, but the
number fed into it comes from the DISPLAY LCG (`FUN_005ec250`, seeded by the whole
title -> match load sequence), a stream this port does not reproduce. The port seeds it from the
fixture's own club ids instead, so a given fixture always dresses its keepers the same way.
Nothing else here is derived, fitted or chosen.

## 9. Proof

`tools/re/refs/kit-2026-07-28/` — the real app under Xvfb + GL
(`PM98_LIVEWATCH_SHOT=1`), Manchester Utd. vs Liverpool: United in red shirts, white shorts and
red/black socks; Liverpool in their CHANGE strip (both clubs' first-choice class collides, so
`FUN_005b63e0`'s P96B branch fires) with black shorts and red socks; per-player skin and hair;
and the shirt number on the back of each shirt.
