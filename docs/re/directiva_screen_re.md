# BOARD OF DIRECTORS (DIRECTIVA) screen — reversed layout from MANAGER.EXE

640×480 px, lifted from the screen's `OnDraw` at **`FUN_0050c350`** (entry =
`sub esp,0x30` prologue at `0x50c350`, just before the `BOARD OF DIRECTORS`
title xref `0x50c3b3`). The per-row confidence/rating widget is built by
**`FUN_0050b580`** (loads `pico.bmp` into the bar, font ProMan10); the bottom
**ASK FOR LOAN** sub-dialog is a separate fn `FUN_0050bc50` (PAY OFF / AMOUNT /
YEARS spinners with `flechar16`/`flechal16` arrows) — NOT rebuilt here (the board
screen is display-only, loans stay in the text menu, same call as TRANSFER).

Decompiles: `docs/re/directiva/fn_0050c350_FUN_0050c350.c`,
`fn_0050b580_FUN_0050b580.c`, `fn_0050bc50_FUN_0050bc50.c`. Anchored on the
`recursos\iconos\directiva\*.bmp` + the inline label strings at `.data`
VA `0x65a354…0x65a45c`.

## Geometry helpers (same family as menu/finance/stadium)
- `FUN_00436fb0(x,y)` → a CPoint. **thiscall**, last push = `x`.
- Each labelled element emits TWO points: **pt#1 = size (w,h)**, **pt#2 = pos (x,y)**;
  `FUN_00436fd0(pos,size)` → `Rect(x, y, x+w, y+h)`.
- The confidence/rating bars take a **rect struct (l,t,r,b)** built on the stack and
  passed to `FUN_0050b580(this, &rect, label, value)` → creates the bar widget at
  that rect (`FUN_005c55b0`), value already divided by 100.
- `FUN_00437020(r,g,b)` set text colour (`r` = last push).
- `FUN_005c06d0(this, "...bmp", 0,0,0x32,0)` registers the PCF5 icon sprite (state
  0x32). Icon screen-rect is computed by `FUN_00437be0`+`FUN_004aa3e0` from the
  bar's stored rect (the icon hugs the left of its confidence box); the exact
  sprite-fit offset is NOT decoded — we place each icon at its box's left edge.

## Assets (RECURSOS.PKF, shared VGA palette, idx0 transparent — NOT MANAGER.PAL)
Render with `export_art.py one RECURSOS.PKF "<X>.BMP" out.png --vga`. MANAGER.PAL
scrambles these (verified: DIRECTIVA.BMP → two suited directors only under `--vga`).

| asset            | size  | role                                    |
|------------------|-------|-----------------------------------------|
| DIRECTIVA.BMP    | 62×64 | boardroom icon (DIRECTORS CONFIDENCE)   |
| PUBLICO.BMP      | 66×57 | crowd icon (SUPPORTERS CONFIDENCE)      |
| INFOMANAGER.BMP  | 13×17 | tiny manager icon (MANAGER INFO button) |
| PICO.BMP         |  7×13 | bar segment marker (inside each bar)    |

## Reversed rects (pos = top-left; bars given as l,t,r,b → Rect2(x,y,w,h))
- **Title** `BOARD OF DIRECTORS` pos(150,16) size(297,27) — ProMan14, white
  (`FUN_00436270(0xffffff)`), in the BARRA bar (same slot as every other screen).
- **MANAGER** caption box pos(47,107) size(251,42) — ProMan10, white. Top-left
  header for the manager panel (`s_MANAGER_00656ea0`).
- **MANAGER RATING** bar rect (349,107,605,149) → Rect2(349,107,256,42).
  value = `*(team+0x34)/100`.
- **SUPPORTERS CONFIDENCE** bar rect (311,162,605,219) → Rect2(311,162,294,57)
  + PUBLICO icon. value = `*(team+0x30)/100`.
- **DIRECTORS CONFIDENCE** bar rect (6,156,297,220) → Rect2(6,156,291,64)
  + DIRECTIVA icon. value = `*(team+0x2c)/100`.
- **Board-message panel** rect (16,263,380,385) → Rect2(16,263,364,122) — the board's
  objective/expectation text (`FUN_0050b5f0`, lower-left).
- **Manager-info panel** rect (388,263,625,365) → Rect2(388,263,237,102) — manager
  detail box (`FUN_0050ae90`, lower-right) + INFOFUT link `if5madec.htm`.
- **MANAGER INFO** label pos(355,433) size(132,25) + INFOMANAGER icon — colour
  (160,160,200) periwinkle (`FUN_00437020` builds 0x00c8a0a0 → bytes a0,a0,c8).
- **RETURN** pos(515,433) size(112,25) — colour (160,160,200).

## Confidence/rating VALUES (derived — original stores live stats we don't model)
The original reads three live club stats (`team+0x2c/0x30/0x34`, each `/100`):
directors confidence, supporters confidence, manager rating. The Career model has
no such stored stat, so the screen is fed values DERIVED from real career state
(position vs board objective + recent form), computed in `Main._board_panel()`:
- **directors** = how the league position tracks the board objective (`objective_pos`).
- **supporters** = recent-form points (last 5 results) blended with position.
- **rating** = league-position percentile blended with form.
All clamped 0..100, season-progress damped toward 50 early. This is an honest
performance proxy, NOT the original's hidden stat — flagged so it's never mistaken
for a reversed constant. Everything ELSE on the screen (rects, fonts, colours,
assets) is reversed exact.

## Build mapping (→ `app/scenes/DirectivaScreen.gd`)
Native 640×480, self-scaling via `draw_set_transform`, marble bezel behind the
letterboxed content (landscape). Loads FONDO marble + BARRA + the 4 VGA icons +
ProMan8/10/14. `setup(...)` feeds club/manager/season/cash chrome + the 3 derived
confidence values + objective text + W-D-L record. Display-only, tap-to-dismiss;
wired from MENUPRINCIPAL's `board` action (was a toast).
