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

- **Team grid** (the per-club rows): built in a loop over the 4 division lists
  (`&DAT_0066b190..0066b1a0`), widget-id base `300+index`, cell SIZE **126×25**
  (`0x7e×0x19`), ProMan14. A second `while(i<0x14)` loop lays 20 slots in **2 columns**:
  after row 10 (`if i==10`) x advances `+0x138 (312)` and y resets to `0x68 (104)`.
  Difficulty/score sprites blitted per row: `seleccion\pun10/pun11/pun20/pun21.bmp`
  (points digits) and `seleccion\bal1..bal4.bmp` (star/ball rating, loop of 4).
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
