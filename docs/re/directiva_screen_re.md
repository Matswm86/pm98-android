# BOARD OF DIRECTORS (DIRECTIVA) screen — frame-baked, reversed from MANAGER.EXE

640×480, lifted from the screen's `OnDraw` **`FUN_0050c350`** (`sub esp,0x30` prologue at
`0x50c350`, just before the `BOARD OF DIRECTORS` title xref `0x50c3b3`). Every value/rect
below is cross-checked against the **captured ground-truth frame**
`screenshots/original-walkthrough-2026-07-02/167_154921.png` (run1 15:49:21; Man Utd /
manager "MWM", preseason 1 Aug 1997) — the only clean BOARD OF DIRECTORS frame in the
walkthrough (siblings 168_154923 / 169_154924 are the same screen).

Decompiles: `docs/re/directiva/fn_0050c350_FUN_0050c350.c` and the widget fns
`fn_0050b580` (confidence/rating bar), `fn_0050b5f0` (**APPLY FOR LOAN**), `fn_0050ae90`
(**BONUS**), shared box builder `fn_005c55b0`, live-stats gate `fn_0057d210`. Label strings
at `.data` VA `0x65a30c…0x65a470`.

## ⚠ Correction (2026-07-13) — the invention seed is fixed
A prior revision of THIS doc mislabelled `FUN_0050b5f0` as *"the board's objective/
expectation text (lower-left)"*. That was **wrong** and is what seeded the invented
"THE BOARD EXPECTS / YOUR RECORD" panels (SPEC_BINDING §6). The decompile is unambiguous:
- `FUN_0050b5f0` draws **`s_APPLY_FOR_LOAN_0065a380`** ("APPLY FOR LOAN") + up to 4 loan
  slots, each with a gold **`s_PAY_OFF_0065a378`** ("PAY OFF") button when that slot holds
  an active loan (`FUN_0057fe80`). It is a loan form, not objective prose.
- `FUN_0050ae90` draws **`s_BONUS_0065a34c`** ("BONUS") with two money rows ("Win bonus" /
  "for Champion"), each flanked by `RECURSOS\ICONOS\flechal16.bmp` / `flechar16.bmp`
  ◄ ► spinners + an OK, reading team fields `+0x1f8`/`+0x1fc`.
There is **no** objective/expectation text field on this screen. The frame confirms both
panels verbatim.

## Element geometry (reversed = decompile; verified pixel-exact against frame 167)
`FUN_00436fb0(x,y)`→CPoint; each element emits **size(w,h)** then **pos(x,y)**;
`FUN_00436fd0(pos,size)`→Rect(x,y,x+w,y+h). `FUN_00437020(r,g,b)`/`FUN_00436270(rgb)` set
text colour.

| element | reversed rect | source |
|---|---|---|
| Title `BOARD OF DIRECTORS` | pos(150,16) size(297,27), white | barra, ProMan14 |
| `MANAGER` caption + navy name box | pos(47,107) size(251,42) | `s_MANAGER`, ProMan10 |
| `MANAGER RATING` bar | (349,107,605,149) | `FUN_0050b580`, value `*(team+0x34)/100` |
| `SUPPORTERS CONFIDENCE` bar + PUBLICO icon | (311,162,605,219) | value `*(team+0x30)/100` |
| `DIRECTORS CONFIDENCE` bar + DIRECTIVA icon | (6,156,297,220) | value `*(team+0x2c)/100` |
| `APPLY FOR LOAN` panel | (16,263,380,385) | `FUN_0050b5f0` (lower-left) |
| `BONUS` panel | (388,263,625,365) | `FUN_0050ae90` (lower-right) |
| `MANAGER INFO` label + INFOMANAGER icon | pos(355,433) size(132,25) | gated by `DAT_0066b1e4` |
| `RETURN` (globe + text) | pos(515,433) size(112,25) | always |

**MANAGER INFO is build-gated** (`if (DAT_0066b1e4 != 0)` at `0x50c40b`). In the captured
build (and frame 167) `DAT_0066b1e4 == 0`, so the button is **absent** — the app omits it
too. Do not add it back without a frame that shows it.

## The confidence/rating meter (frame-measured)
Each bar (below its black label) is a **white** strip carrying `value` square blocks
(15×17 on an 18px pitch — the `pico.bmp` 7×13 segment cadence), coloured **red→brown by
block index** (frame: `#FF0000,#D20000,#D43F00,#D43F00,#AA3F00,…`), then a **light-blue
(166,202,240) left-pointing value tab** holding the value **number** in navy (0,0,128).
Frame 167 reads RATING 5 / DIRECTORS 3 / SUPPORTERS 3.

The two figure icons (`recursos\iconos\directiva\direct.bmp` = two suited directors;
`…\public.bmp` = crowd) sit at the **left** of the DIRECTORS / SUPPORTERS bars; blocks
start just right of the icon.

## Confidence VALUES = honest proxy (flagged gap, not a reversed constant)
The original reads three stored club stats (`team+0x2c/0x30/0x34`, each `/100`). The Career
model keeps no such stat, so the meters are fed a **derived performance proxy** computed in
`Main._board_panel()` (league position vs board objective + recent form, damped toward the
mid early in the season) — an honest gap, NOT the hidden original stat. Likewise the loan
rows and bonus amounts are **unmodelled**, so the baked form stays empty / £0 (the witnessed
no-loan/no-bonus state). Everything ELSE (backdrop, label bars, icons, loan form, bonus
panel + spinners + OK, RETURN) is reversed/frame exact.

## Build mapping (frame-baked, precedent = PreseasonScreen)
- `tools/re/build_directiva_chrome_from_frames.py` bakes frame 167 (cropped y≥44, below the
  barra) into **`app/art/screens/directiva/body.png`** (640×436). It paints over ONLY the
  live fields — the MANAGER name box (→navy), each meter's block strip (→white) and value-tab
  digit (→light-blue) — so nothing dynamic is baked; and clears the header calendar/plaque
  bleed from the top strip.
- `app/scenes/DirectivaScreen.gd` draws `PMChrome.draw_bg` → `body.png` at (0,44) →
  `PMChrome.draw_header` (barra) → live: the MANAGER name + the three meters (blocks + value)
  over the blanked baked fields. Parity vs frame 167: static baked regions **100% pixel-exact**
  (loan/bonus/return/labels/icons/backdrop MAD 0.00); only the live name+meter pixels differ.
- Display-only; `RETURN` (hit rect 515,433,112,25) dismisses. Wired from MENUPRINCIPAL's
  `board` action via `Main._show_directiva_screen`.

## WIRING (not owned here — flag for Main.gd)
`Main._show_directiva_screen` calls `setup(c.club_name, "", …)` — passing `""` for the
manager arg — so the MANAGER name box and the header's manager line render **empty**. The
frame shows the manager name ("MWM") in both. Fix: pass the career manager name as the
`manager` arg (as the other screens already do for `PMChrome.draw_header`).
