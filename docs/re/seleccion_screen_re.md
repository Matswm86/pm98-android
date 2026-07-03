# NEW-CAREER screen (SELECCION / "ENTER YOUR NAME AND SELECT A TEAM") — reversed from MANAGER.EXE

640×480 px, lifted from `FUN_0055d560` (entry = the `sub esp,0x5e?` prologue at
`0x55d560`; the seleccion asset cluster `pun/bal/borra/over` xrefs sit at
`0x55da..0x55df`). Decompile: `tools/re/specs/seleccion_dec/fn_0055d560_FUN_0055d560.c`.
Immediates read straight from capstone (`tools/re/pe.py disasm_va`), NOT the lossy
decompile (Ghidra hides the `push`-arg order).

This is the REAL new-career front door, and it is ONE screen, not two. The app's
current `BrowseScreen` Track-B flow splits it into a division picker then a club
picker; the original does manager-name entry + club selection (across all divisions)
on a single screen. Faithful rebuild collapses `_show_career_pick_league` +
`_show_career_pick_club` into one screen. (Per `feedback_pm98_stay_true_to_original`.)

## Background
- `FUN_004fa840(screen_id=0x3c0)` is the generic FONDO+BARRA loader. Case `0x3c0`
  resolves to `iVar4=0, uVar5=0, local_1cc=0` → **`RECURSOS\FONDO0.BMP`** (640×480,
  the washed stadium-with-two-players photo) + **`RECURSOS\BARRA0.BMP`** (640×62, the
  soccer-ball + pitch divider bar) masked by **`BARRAMASK0.BMP`**.
- Render: `export_art.render("RECURSOS.PKF","FONDO0.BMP",pal_name="MANAGER.PAL",force_pal=True)`
  (BM screen, no embedded palette → external MANAGER.PAL). Verified by looking:
  `/tmp/.../pm98shots/fondo0_MANAGER.PAL.png`, `barra0.png`.

## Geometry helpers (same family as the menu)
- `FUN_00436fb0(x,y)` → point. **LAST push = x.** Each widget emits TWO: pt#1 = SIZE
  (w,h), pt#2 = POS (x,y). `FUN_00436fd0(pos,size)` → `Rect(x,y,x+w,y+h)`.
- `FUN_00436270` = `CRect` caption variant (white-text labels). `FUN_00437020(r,g,b)`
  caption colour (**r = last push**, stores [r,g,b,0]). `FUN_005c06d0(this,"…bmp",…)`
  blits a sprite. `FUN_005beae0("ProManNN")` sets the widget font.

## Reversed widgets (pos = top-left, size = w×h; from capstone)
| widget                 | pos (x,y)  | size (w×h) | font     | colour (r,g,b) |
|------------------------|------------|------------|----------|----------------|
| Manager (top label)    | (26, 8)    | 80×18      | ProMan10 | white          |
| League (top label)     | (40, 21)   | 70×18      | ProMan10 | white          |
| Title "ENTER YOUR NAME AND SELECT A TEAM" | (108,12) | 480×27 | ProMan14 | white |
| PLAYER label           | (127, 67)  | 124×25     | —        | gold(255,223,0)|
| name-input field       | (292, 67)  | 197×25     | ProMan12 | white          |
| RETURN button          | (25, 427)  | 112×25     | —        | yellow(255,255,0)|
| LOAD GAME button (+carga.bmp @0x32) | (175,427) | 152×25 | — | gold(255,223,0) |
| DELETE button (+borra.bmp @0x32)    | (348,427) | 112×25 | — | red(255,31,0)  |
| CONTINUE button        | (508, 427) | 112×25     | —        | yellow(255,255,0)|

- **The 20-slot grid is the PLAYER (career save) slot list, NOT a club grid**
  (corrected 2026-07-02 against walkthrough frames 008-012: slot 1 highlighted gold,
  frame 011 shows slot 1 filled "MWM | Manchester Utd." after CONTINUE). The
  `while(i<0x14)` loop lays 20 numbered rows in 2 columns of 10 (after row 10 x
  advances +312, y resets to 104). Each row: number badge + NAME cell + CLUB cell.
  Frame-measured (008): rows y=107..263, pitch 16, bar h 12; left col badge x≈20..44,
  name cell x≈45..149, club cell x≈150..308; right col +312.
- **Club selection is the central white kit panel** (frame-measured x≈150..490,
  y≈276..406): gold-framed white box, division title in gold + ball icon at top,
  **2 rows of 10 club kits** (20 Premier clubs), tap kit → club name shown beneath
  (frame 010 "Manchester Utd."). Division picked via 4 plaques flanking the panel:
  Premier League (13..130) / First Division left, Second/Third Division (503..617)
  right, rows y≈291..311 and 329..349; selected plaque text red, others white.
- **PLAYER bar** (top, frame-measured): left arrow chip (83,66)~28×28, bar x≈118..497:
  orange PLAYER chip x≈127..245, dark-red slot-number cell x≈247..290, black name
  field to x≈497, right arrow ≈(502,66). Arrows cycle the active save slot.
- CONTINUE with name+club locks the slot and advances to the next PLAYER (frame 011:
  PLAYER 2 active); CONTINUE with the active slot empty proceeds → PRESEASON screen
  (frames 012→013, see pretemporada_screen_re.md). Multi-player hot-seat is original
  behaviour; the app engine is single-career for now (slot 1 real, honest gap).
- Difficulty/score sprites for rows: `seleccion\pun10/pun11/pun20/pun21.bmp`
  (points digits) and `seleccion\bal1..bal4.bmp` (rating balls); arrows
  `seleccionpro\FLECHA0/1.BMP`.
- `INFOFUT\if5maseq.htm` is the context-help anchor (ignored for the port).

## Build plan (→ a new `app/scenes/SeleccionScreen.gd`, replacing BrowseScreen's
new-career path)
1. Export `FONDO0.BMP`→`app/art/screens/seleccion_bg.png` and `BARRA0`(masked) as the
   top divider; bake them like `menu_bg.png` (one PNG), OR blit FONDO0 + BARRA0@top.
2. Draw the static labels/buttons at the rects above with the PROMAN raster fonts.
3. Team grid = 2 columns × N rows of 126×25 cells from `GameDB` clubs (all divisions),
   each with name + difficulty balls (bal1..4) + points sprite; tap = select.
4. Manager-name field = an editable text box (PM98 has a name entry here).
5. Wire `Main.gd`: `_show_home → new` mounts SeleccionScreen; CONTINUE→`_begin_career`,
   RETURN→`_show_home`. Verify by LOOKING (boot the app, screenshot).

## Pixel-parity pass (2026-07-03) — chrome doctrine + new frame-derived facts

The screen's static look now ships as the REAL frame-008 pixels
(`app/art/screens/seleccion/chrome.png`, caret erased), same doctrine as
`build_menu_bg_from_ref.py`; the dynamic layer redraws ONLY state deltas.
Verified by `app/tests/shot_entry_parity.gd` + `tools/re/diff_entry_parity.py`:
**seleccion_008 pixel-exact; seleccion_011 (locked state) 100px** (the PLAYER
digit's checker two-tone dither — see below). Facts established:

- **The runtime screen COMPOSITE is not reproducible from PKF blits alone**: the
  fondo/barra render doesn't match any FONDO0-9/BARRA under any .PAL (dithered
  remap by the engine); the frame IS the source of truth for the composite.
- **PLAYER-bar arrows = `seleccion\pun10/pun20.bmp`** (34x29 pitch-grid chips,
  SAD 0.0 at abs (79,65)/(501,65)); `pun11/pun21` = pressed states.
  FLECHA0/1 (16x14) are NOT these.
- **Panel kits = DBDAT/NANOESC.PKF** (24x32 full kit incl shorts; palette-less
  OS/2-core DIB -> export_icons.decode_dib, MANAGER.PAL). SAD 0.0 for all 20
  cells at **x 167+31i, y 308/345**. MINIESC (48x64) is the shirt-only art.
  The engine adds a soft SHADOW pass that is NOT a plain palette blit (idx0
  cells render position-parity-dithered greys), so the app ships frame-rendered
  24x32 patches per Premier club (`app/art/kits/panel/`), nano art elsewhere.
- **OVER.BMP (26x36) = the selection cell** behind the kit at kit-(1,2).
- **Panel structure**: gold frame rect x 158..480 y 291..383 (line colour
  (212,191,85)); the title composition = ball sprite at (237,272) + division
  name at x270 (ProMan12 @ NATIVE size 13) ON the top line, which breaks at
  FIXED x 232..405. Club-name line renders below the bottom line (gold).
- **Taken clubs render WASHED** (50% dither toward white; frame 011's Man Utd).
  The washed render is position-independent -> the frame-cut washed patch ships
  (`app/art/kits/washed/`), checker approximation for unframed clubs.
- **Filled slot style (frame 011)**: black badge/white digit; name bar (40,60,80)
  with (200,200,240) CENTRED text; club bar (100,100,140) with (170,191,255)
  CENTRED text. Active slot: red badge (85,0,0)/gold digit (255,223,0), bars
  (212,159,0)/(212,191,0), white 2px outline INSIDE the bg gaps (rows y-3..y-2 &
  y+13..y+14, cols x20..21 & 309..310). Row texts/digits = **ProMan8 at its
  NATIVE .fnt size 11** (scaling the bitmap fonts was the whole glyph drift);
  digit centring rounds RIGHT of centre (ceil), '1' sits one px further right.
- **PM98 disables buttons by WASHING them toward the backdrop** (frame 008
  CONTINUE washed vs 012 solid); the solid overlay is cut from 012 (the SEGUIR
  ball icon ANIMATES — 011/012 differ there, excluded in the diff).
- **PLAYER cell digit** = ProMan14 @ native 15, bright gold (255,223,0) with a
  dark-brown (72,30,2) outline; the ORIGINAL renders it as a checker two-tone
  dither the app approximates flat (the remaining 100px / mean-diff 22.7 in the
  011 parity — accepted + documented).
- Empty-slot-1 background truth (after the baked active outline leaves) comes
  from frame 011 (`seleccion/row1_degap.png`).
