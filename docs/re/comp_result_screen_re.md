# RESULTS → CHARITY SHIELD / INTERCONTINENTAL CUP — the single-match competition screen

The screen MANAGER.EXE raises from the RESULTS competition rail for a competition that is
**one match**. It replaces `Main._show_one_off_final`'s invented `CupScreen` overlay for
both. Scene `app/scenes/CompResultScreen.gd`, chrome
`tools/re/build_compresult_chrome_from_frames.py`, render check
`app/tests/shot_comp_result.gd`, wiring test `app/tests/test_comp_result.gd`.

## The two are ONE screen — from the binary, not by analogy

| competition | builder | size |
|---|---|---|
| CHARITY SHIELD | `FUN_004717a0` | 1107 bytes |
| INTERCONTINENTAL CUP | `FUN_0048daf0` | 1107 bytes |

A byte diff of the two function bodies gives **158 differing bytes in 48 runs**. Every run
but two is the tail of an `e8 rel32` call displacement, and each of those differs by exactly
`0x1c350` — the distance between the two entry points (`0x48daf0 − 0x4717a0`). The two
non-displacement differences are single `push imm32` operands:

```
+0xa3   push 0x653fc0 'CHARITY SHIELD'                 vs  0x6543b4 'INTERCONTINENTAL CUP'
+0x239  push 0x653f94 img\premier\copas\charity big.bmp vs 0x654390 img\copas\intercontinental big.bmp
```

So the Intercontinental Cup screen **is** the Charity Shield screen with the title string
and the trophy bitmap swapped. Confirmed live afterwards — both frames carry the same
title plate, RESULT plate, match panel, STADIUM caption, two club rows with score cells,
WINNER band and laurel.

Reached in the original by: hub → **RESULTS** → the right-hand competition rail.
`FUN_00470050` (the WINNER band with `img\resultados\final\laurel.bmp` +
`balon.bmp` + ` (on penalties)`) is shared by both and by the other competition screens.

The **EUROPEAN SUPERCUP** is the same family but a **different builder** (`0x4a1820`, whose
body does not match at all): its panel carries `1ST LEG MATCH` and `2ND LEG MATCH` blocks.
Captured (`09_comp_supercup.png`) but **not built** — it also needs the app's supercup
model changed from one neutral match to a two-legged tie.

## Binding frames

Live drive of the original this session (Bolton W, Manager League, Sat 4 October 1997),
`screenshots/wine-captures-2026-07-25-euro-competitions/`:

| frame | state |
|---|---|
| `09_comp_charity.png` | CHARITY SHIELD, **played**: Manchester Utd. 1 Chelsea 0 at Wembley, WINNER Manchester Utd. with its kit in the laurel |
| `09_comp_intercont.png` | INTERCONTINENTAL CUP, **un-played**: Borussia D. v Cruzeiro at Tokyo, both score cells empty, WINNER band empty, laurel empty |

The un-played frame is what makes the bake honest: the WINNER plate and the laurel well are
copied from it, so their empty state is the original's own pixels, not a synthesised fill.

## Geometry (design px, measured off the frame pixel grid)

The only long black runs in the panel column are the plate borders — columns x137/138 and
x362/363, rows 84/85, 109/110, 155/156, 265/266, 287/288, 296/297, 318/319, 334/335.

| element | rect | notes |
|---|---|---|
| title plate | x137..363, y84..110 | baked per competition |
| RESULT plate | x165..344, y127..146 | baked |
| match panel | x137..363, y155..335 | white interior |
| home kit / away kit | (146,158) 48x60 / (306,158) 48x60 | the non-white blobs either side of the flags |
| home flag / away flag | (199,163) 30x20 / (270,163) 30x20 | inside the black boxes x198..229 / x269..300, y162..183 |
| STADIUM caption | ink x203..282, y227..235 | baked |
| stadium name | centre **243**, y240 | Wembley x209..276, Tokyo x219..265 — same centre |
| home / away row | y265..288 / y296..319 | name cell x150..305 fill (200,220,240), score cell x306..344 fill (42,63,170) |
| club name | pen x**155**, left | both witnessed names start there |
| score digits | cell x306 w39 → centre **325** | witnessed 1 at x320..328 and 0 at x318..331 |
| WINNER club name | pen x**65**, y382 | ink x65..219, y383..395 |
| laurel kit well | (408,342) 32x44 | |

Inks, sampled: club row `(80,100,120)`, score `(255,255,255)`, stadium name `(17,90,34)`,
WINNER name `(42,63,170)`.

Fixed venues, from the frames: the Charity Shield is at **Wembley**, the Intercontinental
Cup at **Tokyo**.

## Verification

* `app/tests/test_comp_result.gd` — asset load, per-competition chrome swap, the un-played
  state, the three measured cell centres, RETURN. ALL PASS.
* `app/tests/shot_comp_result.gd` — renders both screens with the witnessed fixtures so the
  output sits next to `09_comp_{charity,intercont}.png`. Eyeballed: title, RESULT plate,
  trophy, flags, stadium, rows, rail chip and WINNER band all land on the original's.

## HONEST GAPS (flagged, never invented)

* **The kit figures.** The original's 48x60 panel kit bank is not in `IMG.PKF`,
  `RECURSOS.PKF` or `DAT.PKF` (a full size census of all three found no 48x60 entry), so the
  app's own kit art is scaled into the measured well — the same documented approximation
  `CharityShieldScreen` already carries. Everything else in the panel is the frame's pixels
  or a frame-measured redraw.
* **The EUROPEAN SUPERCUP** screen (above).
* The competition **rail is baked, not live** — as on `ResultsScreen`. Both screens are
  reached from the app's hub COMPETITIONS chooser instead.
