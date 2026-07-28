# MAN-TO-MAN MARKINGS — reverse-engineering record

Status: **BUILT 2026-07-28** (`app/scenes/ManToManScreen.gd`), gated by
`tools/re/diff_mantoman_parity.py` against the real frames.
Evidence: `screenshots/parity-run-2026-07-16/orig/66_mantoman_match.png`,
`screenshots/original-walkthrough-2026-07-02/058_162622.png` …
`067_162639.png` (ten frames, the whole interaction walked),
`extracted/Premier Manager 98/MANAGER.EXE`,
`extracted/Premier Manager 98/RECURSOS.PKF`.

Method: Ghidra 12.1.2 headless (`~/ghidra-projects/pm98`, `DecompileAt.java`) plus
capstone linear disassembly through `tools/re/pe.py`. Every address below was read
out of the binary in this session; every pixel figure was measured on the frames.

## 1. The class

| thing | address |
|---|---|
| screen vtable | `0x62eb28` (0x120 long, slot 0x118 = init, 0x11c = the shared `run` 0x4fa810) |
| constructor | `FUN_0050e1a0` (`operator_new(0x100c8)`) |
| **init / layout** | **`FUN_0050e980`** (2345 B) |
| erase-background | `FUN_00510700` — `FUN_005cc600` over the three panel rects |
| help topic | `INFOFUT\if5pamar.htm` (`0x65a630`), stored at `this+0xccc` |

Sub-widget classes, in construction order (each a 0x120 vtable whose slot **+0x10c is
the draw override**):

| object | count | vtable | draw | what |
|---|---|---|---|---|
| `this+0x1978` | 1 | `0x62ec48` | `FUN_0050fee0` | MAIN list panel (its own column headers) |
| `this+0x3bcc` | 10 (stride `0x418`) | `0x62ed60` | `FUN_005100a0` | MY outfield rows |
| `this+0x64bc` | 10 | `0x62ee80` | `FUN_0050fc40` | OPPONENT rows |
| `this+0x8dac` | 10 | `0x62efa0` | `FUN_005103c0` | the green "PLAYER N." assignment cells |
| `this+0xb69c` | 1 | `0x62f0c0` | `FUN_0050f720` | the PITCH panel |
| `this+0xba90` | 1 | (base) | — | DEFENDING marking-line TRACK |
| `this+0xbe84` | 1 | (base) | — | MIDFIELDING marking-line TRACK |
| `this+0xc278` | 1 | `0x62f1d8` | `FUN_0050f970` | the **D** marker (id 200) |
| `this+0xc66c` | 1 | `0x62f1d8` | `FUN_0050f970` | the **M** marker (id 201) |
| `this+0xca60` | 10 | (base) | — | the grey "assigned" boxes (FLECHAS sprite) |
| `this+0xf350` | 1 | `0x62f2f0` | `FUN_0050fae0` | OPPONENT panel (kit + vertical club plate) |

Geometry helpers as everywhere else in this tree: `FUN_00436fb0(x,y)` builds a point
(**pt#1 = SIZE, pt#2 = POS**), `FUN_00436fd0(pos,size)` builds the rect,
`FUN_00436240` is `CRect::CRect(l,t,r,b)`, `FUN_00436270(rgb)` the fill,
`FUN_00437020(r,g,b)` the ink, `FUN_005beae0(name)` the face, `FUN_005c06d0`/
`FUN_005c9f60`/`FUN_005c0d50` load a bitmap onto a widget.

## 2. Layout — every rect, from `FUN_0050e980`

Screen-absolute unless a parent is named. `i` = 0..9 (the row).

| element | rect | source |
|---|---|---|
| title `MAN-TO-MAN MARKINGS`, ProMan14 | `(150,16)-(447,43)` | `@0x50ea40` size (297,27), pos (150,16) |
| MAIN panel | `(23,82)-(511,268)` | `FUN_004f50c0` `{0x17,0x52,0x1ff,0x10c}` @0x50ea96 |
| OPPONENT panel | `(23,278)-(290,456)` | `FUN_004f50c0` `{0x17,0x116,0x122,0x1c8}` @0x50eeea |
| PITCH panel | `(319,278)-(511,456)` | size (192,178), pos (319,278) @0x50eaf8 |
| MY row `i` | `(32,102+16i)-(249,118+16i)` | panel-rel `(9,20+16i)` size (217,16) @0x50f17a |
| OPPONENT row `i` | `(31,287+16i)-(223,303+16i)` | opp-panel-rel `(8,9+16i)` size (192,16) @0x50f038 |
| assignment cell `i` | `(285,102+16i)-(502,118+16i)` | panel-rel `(262,20+16i)` size (217,16) @0x50f0cc |
| grey FLECHAS box `i` | `(248,103+16i)-(286,117+16i)` | panel-rel `(225,21+16i)` size (38,14) @0x50efad |
| RETURN | `(520,408)-(632,433)` | size (112,25), pos (520,408) @0x50ee2d, id **900** |
| DELETE | `(520,278)-(632,303)` | size (112,25), pos (520,278) @0x50ee96, id **906**, icon `seleccion\borra.bmp` |
| the three erased areas | the panels above | `FUN_00510700` |

Control ids: MY rows **100+i**, OPPONENT rows **120+i**, assignment cells **140+i**,
D **200**, M **201**, DELETE **906**, RETURN **900**.

### 2a. Cells inside a row (row-relative, from each draw override)

`FUN_005100a0` — MY row (217x16), face ProMan8:

| cell | row-rel rect | alignment |
|---|---|---|
| shirt number (`FUN_0058df10` of `player+0xf8`) | `(3,2)-(24,14)` | CENTRED |
| name (`player+4`) | `(34,2)-(151,14)` | LEFT (flag `0x20`) |
| CAMROL role sprite (`screen+0x3f8 + player[0x18]*0x4c`) | blit at `(151,1)` | 25x14, 1:1 |
| position (`PTR_DAT_00662d00[player+0x1c]`) | `(176,2)-(216,14)` | CENTRED |

`FUN_0050fc40` — OPPONENT row (192x16), face ProMan8: name `(8,2)-(125,14)` LEFT,
CAMROL blit at `(125,1)`, position `(150,2)-(190,14)` CENTRED.

`FUN_005103c0` — assignment cell (217x16), face ProMan8: position `(2,2)-(42,14)`
CENTRED, CAMROL blit at `(41,1)`, name `(66,2)-(183,14)` **RIGHT** (flag `0x40`),
shirt number `(190,2)-(211,14)` CENTRED. Nothing is drawn when the cell is empty
(`if (player != 0)`), which is why every witness shows blank green plates.

`FUN_0050fee0` — the MAIN panel's own headers: `N.` at `(16,2)-(45,21)`,
`PLAYER` at `(45,2)-(160,21)` LEFT, `PLAYER` at `(328,2)-(445,21)` **RIGHT**,
`N.` at `(450,2)-(479,21)`.

**The alignment rule, decoded here and reusable**: the widget's flag word at
`+0x144` selects it — bit `0x20` = left, bit `0x40` = right, neither = GDI-centred,
bit `0x08` = the shadowed face (`FUN_005da180` instead of `FUN_005d9d80`).
`FUN_004ca3c0` is only the shadow/plain switch; both take the same rect.

### 2b. Colours (binary value → the palette-realised pixel measured on the frames)

| element | `MANAGER.EXE` | frame |
|---|---|---|
| MY row, idle | `0xffdfd6` (`FUN_004ac740` @0x51015a) | `(212,223,255)` |
| MY row, selected | `0xceb6a5` | `(165,182,206)` |
| MY row border | `FUN_00437020(0x7b,0x79,0xa5)` | `(120,120,160)` |
| assignment cell | `0xadffd6` / `0xaddfad` | `(212,255,170)` |
| OPPONENT row, unmarked | `FUN_00437020(0x18,0x34,0x63)`, ink white | `(30,52,98)` |
| OPPONENT row, already marked | `FUN_00437020(0xa5,0xcb,0xf7)`, ink black | `(165,203,247)` |
| grey box | Windows static | `(160,160,164)` |

## 3. The pitch and the two marking lines

`FUN_0050f720` paints the pitch panel: black `(2,2)-(190,22)`, white
`(2,22)-(190,156)`, black `(2,156)-(190,176)`, then blits
`recursos\iconos\alineacion\campo.bmp` (152x92, already exported as
`app/art/screens/lineup/campo.png`) at panel-rel **(20,43)**, then draws
`DEFENDING MARKING LINE` in `(2,0)-(190,22)` and `MIDFIELDING MARKING LINE` in
`(2,156)-(190,178)`.

The two lines are **club fields**, scaled once at init (`@0x50eb53`-`0x50eb9b`):

```
v_def = club[0x25c] * 148 / 318      # unsigned divide-by-0x13e
v_mid = club[0x260] * 148 / 318
```

`docs/re/session_lineup_re.md` already records those two fields and their ctor
defaults — **79 and 198** — and that they feed the positional engine as
`lineup+0x8 = transform(club+0x25c)` / `lineup+0x4 = transform(club+0x260)`.
79 → 36 and 198 → 92, and the marker's **left edge is `12 + v` in panel
coordinates**, which is exactly where both witnesses put them (D at panel x48,
M at panel x104, measured).

The tracks are mutually bounded, which is how the original stops the lines
crossing:

* D track `this+0xba90` = pos (12,28) size (`v_mid`+22, 109) → D may travel `[12, 12+v_mid]`
* M track `this+0xbe84` = `CRect(v_def+13, 45, 184, 154)` → M may travel `[v_def+13, 162]`

Each marker is a **22x109** sprite plus its letter:

* `recursos\iconos\emparejamientos\linead.bmp` → D, letter drawn in `(0,0)-(19,13)`
* `recursos\iconos\emparejamientos\lineam.bmp` → M, letter drawn in `(0,93)-(19,106)`
* `recursos\iconos\emparejamientos\flechas.bmp` → the 38x14 grey-box sprite

All three live in `RECURSOS.PKF` and decode with `MANAGER.PAL` + index-0
transparency. Verified against the frames by `build_mantoman_chrome_from_frames.py`:
FLECHAS **0 differing px** on `061_162628`; LINEAD/LINEAM **0 px outside the letter
box** on `66_mantoman_match` (the 38/36 px inside it are the black `D` / `M` glyph,
which the original draws as text over the sprite).

## 4. The model

The assignment table is **`team+0x234 + 4*i`**, i = 0..9, read by the init's last
loop (`@0x50f1f1`-`0x50f25a`) — one entry per outfield lineup slot `2+i`:

* `0` (or anything outside 2..11) → no marking: the grey box is cleared and the
  assignment cell holds no player;
* `2..11` → the OPPONENT's lineup slot. The init then (a) flags that opponent row
  as already-marked, and (b) copies the opponent's player record into the
  assignment cell (`[widget+0x54]`).

`FUN_0057a2e0(team, n)` is the slot lookup: it walks the roster list at `team+0x24`
through `+0x100` and returns the record whose byte at `+0x19` equals `n`. The screen
only ever asks for **2..11**, so the goalkeeper (slot 1) is not listed — both
witnesses show ten rows a side.

`docs/re/session_lineup_re.md` already binds the other end: `rec+0x28` (the engine's
marking field) `= club+0x230 table entry - 1`, so an assignment of opponent slot `k`
reaches the positional engine as `k-1`.

## 5. The interaction, as walked

Frames `058_162622` → `067_162639` are one continuous session on
Manchester Utd. vs F.C. Barcelona and settle the whole flow:

1. `059` — the pointer rolls over an opponent row; the row repaints (rollover only).
2. `060` — tapping **9 Cole** selects MY row: its fill goes `(212,223,255)` →
   `(165,182,206)`; nothing else changes.
3. `061` — tapping **Guardiola** commits: Cole's grey box gets the FLECHAS sprite,
   his assignment cell fills with `MID · camrol · Guardiola · 4`, and Guardiola's
   opponent row flips to the light-blue already-marked state.
4. `062`/`063` — selecting **6 Pallister** clears the previous selection, and
   **Rivaldo** commits the second pair. Both marked opponents stay light blue.
5. `064`-`067` — the pointer sits on RETURN; only the button's own rollover
   animation changes.

No frame in the corpus moves either marking line, so their **rendered default** is
witnessed and their **travel** is taken from the two track rects above; the inverse
of the scale (pixel → `club[0x25c]`/`club[0x260]`) is `x * 318 / 148`, the only
inverse of the binary's own forward map. That inverse is flagged in
`ManToManScreen.gd` as the one derived (not directly witnessed) rule on this screen.

## 6. What the port ships

`ManToManScreen.gd` draws the baked body (`app/art/screens/mantoman/body.png`,
cut from `66_mantoman_match.png` by `tools/re/build_mantoman_chrome_from_frames.py`
with only the dynamic cells blanked) plus the live layer: the ten MY rows, the ten
opponent rows, the ten assignment cells, the grey boxes, the opponent kit and its
vertical club plate, and the two markers. The pitch under the markers is the game's
own `campo.bmp`, so a dragged line reveals original pixels, not a reconstruction.

Gate: `tools/re/diff_mantoman_parity.py` — three cases (`bolton` = the parity
witness, `manutd` = the walkthrough witness, `assigned` = frame `064_162633`, two
committed pairs) at **0 differing pixels over the whole body band**, outside three
named buckets: the rotated club plate (122 px, a rasteriser difference), the
`FUN_004b7f60` shadow pass (§7) and, on `assigned`, the pointer rollover the
original paints under the mouse and a touch screen has no equivalent for.

## 7. The shadowed blit — the pass the knockout gates also bucket

The two markers and the 48x64 opponent kit are blitted through **`FUN_004b7f60`**,
a thunk into `FUN_005cbea0(0x10, 0x21, id, l, t, r, b, bmp, 0, 0, 0, 0x100)`.
With `param_1 = 0x10` and `param_2 = 0x21` that call takes exactly one path:

```
FUN_005d66f0(bmp, 0x100)          # build the silhouette into a scratch bitmap
FUN_005d6590(scratch, 0x21, id, 0x100)   # tint it
FUN_005d5220(&rect, scratch, ..., bmp, ...)   # composite scratch, then the bitmap
```

**What it actually does, measured on these frames** (and this is new — the
2026-07-28 note said only "it needs the pass's code"): it is a **palette-darkening
stamp offset to the RIGHT of the silhouette**, and the darkening is applied once
per overlapping stamp, walking a per-index ramp:

| under the shadow | 1 stamp | 2 stamps | 3 stamps |
|---|---|---|---|
| index 85 (100,130,10) | 116 | 115 | 114 |
| index 255 (white) | 7 (192,192,192) | 247 (160,160,164) | 134 (144,144,144) |

That is **not** the dilation model measured and REJECTED on 2026-07-28 (union
kernel `0<=dx,dy<=3`, which painted 1988 px the original leaves white). Porting
`FUN_005d66f0` / `FUN_005d6590` closes this bucket here AND the same bucket in
`diff_knockout_parity.py` and `OffersScreen` — it is one pass, not three.


## The vertical club plate is NINETEEN columns wide — and that was the whole kit residual

Recorded 2026-07-28 (s78). The plate's panel-relative box reads `(220,35)-(239,167)`, which
looks like twenty columns and was baked as `x243..x262`. **The pixels say nineteen.** On a
plain plate row well clear of the kit (`y = 430`) both witnesses have `(0,0,0)` at
`x243..x261` and the panel's own white at `x262`; at every row the kit covers, `x262` is the
panel or the kit's drop shadow on it, never plate black.

That single extra column is `kit-local x = 33`, and it was the ENTIRE residual the shadow-pass
bucket had been carrying against the 48x64 kit:

| | before | after |
|---|---|---|
| kit rect (`229,283` 48x64), both careers | 15 px | **0 px** |
| shadow-pass bucket | 50 / 51 px | **36 px** (the D and M letter glyphs, unchanged) |
| plate bucket | 122 / 123 px | **19 px** |

Two carried claims die with it: that the residual was "the 48x64 MINIESC bank is missing
content" (the bank is correct — the PNGs are already transparent in that column), and that
"the original paints pure black and the port has transparent" (the reverse: the port's baked
body was black and the original's panel is white there). `PLATE` / `PLATE_TEXT` in
`build_mantoman_chrome_from_frames.py` now end at `x261`, with the measurement in the comment.
`ManToManScreen.PLATE_TEXT` is untouched — it is a centring box for the rotated name, and its
width is not used for the x pen.
