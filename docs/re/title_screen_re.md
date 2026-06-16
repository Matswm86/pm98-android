# TITLE / FRONT-DOOR screen — reversed from MANAGER.EXE

The PREMIER MANAGER 98 front door: the title scene with **DATA BASE / MANAGER LEAGUE /
PRO-MANAGER LEAGUE** options + an **EXIT**. Rebuilt at `app/scenes/TitleScreen.gd`,
PIL mirror `tools/re/preview_title.py`, harness `app/tests/test_title_screen.gd`.

## Draw function: `FUN_00545180` (entry 0x545180, 875 bytes)

This is the front-door dialog's draw/init. Decompile dumps in `docs/re/title/`.

1. **Background** — at the top it calls `FUN_004fa840(this, 0x4e3e, 0, ...)`. The
   disassembly confirms the screen id pushed is `0x4e3e` (20030):

   ```
   5451a6:  6a 00              push 0x0
   5451a8:  68 3e 4e 00 00     push 0x4e3e      ; param_3 = screen id
   5451af:  50                 push eax
   5451b0:  e8 8b 56 fb ff     call 0x4fa840    ; generic full-screen bg loader
   ```

   `FUN_004fa840` is the shared screen-setup routine: it builds a full-screen
   `CRect(0,0,0x280,0x1e0)` = (0,0,640,480), switches on the screen id to pick a FONDO
   index, and `sprintf`s one of three format strings:
   - `RECURSOS\FONDO%u.bmp`
   - `RECURSOS\PREMIER\FONDO%u.bmp`         (iVar4 == 3 or 4)
   - `RECURSOS\PREMIER\SININFO\FONDO%u.bmp` (iVar4 == 7)

   `case 0x4e3e: iVar4 = 7` (and skips the BARRA top bar). So the front door's
   background is **`RECURSOS\PREMIER\SININFO\FONDO7.bmp`** — the iconic 640×480
   PREMIER MANAGER 98 title scene (logo + player photo + Gremlin/Actua marks, with the
   three option buttons drawn into the art). Index 0 is opaque (a real background, not
   transparent). Palette: MANAGER.PAL (`export_art … --force-pal`; the BM omits/junks
   its own). Verified by PIL render: a perfect, palette-correct title.

2. **Version string** — draws `sprintf("F%u.%u", …)` into `CRect(0,0x1cc,0x28,0x1e0)`
   = the bottom-left corner via the text vmethod at `vtbl+0xc0`.

3. **Control layout table** — a do-while loop over `DAT_00633588` stepping `+0xb`
   u32 = a **44-byte record** until the id field is 0. Per record:
   `[0]`=control id, pos = `FUN_00436fb0([1],[2])`, size = `FUN_00436fb0([3],[4])`,
   `rect = FUN_00436fd0(pos,size)` = `(pos.x, pos.y, pos.x+size.x, pos.y+size.y)`
   (the same point/rect helpers used by every other screen). The bitmap name is field
   `[9]`; it is blitted into the control rect via `FUN_005c06d0(path, …)`. Ids in
   `[20000,20022]` load from `RECURSOS\PREMIER\SININFO\%s` at **y − 0x14**; ids outside
   (salir 20026) load from `RECURSOS\PREMIER\ICONOS\%s` at y as-is.

   Table base VA `0x633588` is in `.rdata` (file offset = VA − 0x401200 = 0x232388).
   Decoded (after the y−20 adjustment for the three menu items):

   | id    | asset                 | size  | table pos | blit rect (x,y,w,h)   |
   |-------|-----------------------|-------|-----------|-----------------------|
   | 20002 | base_datos.bmp        | 332×45| (20,217)  | (20,197,332,45)       |
   | 20021 | liga_manager.bmp      | 332×45| (20,275)  | (20,255,332,45)       |
   | 20022 | liga_promanager.bmp   | 332×45| (20,334)  | (20,314,332,45)       |
   | 20026 | salir.bmp             | 73×35 | (552,431) | (552,431,73,35)       |

   The button bitmaps live in the **SININFO** PKF group (RECURSOS.PKF): BASE_DATOS /
   LIGA_MANAGER / LIGA_PROMANAGER are 332×45 (sizes match the table exactly), SALIR is
   73×35. All confirmed by `tools/re/export_art.py` dims.

## Art-vs-code divergence (what we ship, and why)

`FONDO7` is a **complete pre-rendered title scene**: its three option buttons (DATA
BASE / MANAGER LEAGUE / PRO-MANAGER LEAGUE) are already drawn into the art, on the
**right** (x≈356–620, y≈121/179/237). The control table above positions 332-wide
buttons on the **left** (x=20) — the "SININFO" owner-drawn control layout. There is no
plain (button-less) FONDO7 anywhere in RECURSOS.PKF (all three FONDO7 entries are the
same right-button scene), so the two genuinely diverge and can't be reconciled without
running the original. Rather than ship a redundant double-button screen, we treat
FONDO7 the way the ESTADIO tier scenes are treated — a pre-rendered scene blitted whole
— and put the interactive hit-rects over the buttons the player actually sees:

| action          | what it is                | hit rect (640×480)      |
|-----------------|---------------------------|-------------------------|
| `database`      | DATA BASE (baked button)  | (350,119,285,35)        |
| `career_league` | MANAGER LEAGUE (baked)    | (350,177,285,35)        |
| `career_pro`    | PRO-MANAGER LEAGUE (baked)| (350,235,285,35)        |
| `exit`          | EXIT — painted pill       | (552,431,73,35)         |

The three button rects are **measured** off the pre-rendered art (the buttons have no
code coords — they're in the bitmap). EXIT keeps the **exact reversed salir coord**
(552,431,73×35); since FONDO7 has no baked exit graphic and salir.bmp is only a glow
fragment, TitleScreen paints a small navy "EXIT" pill there so the option is visible
and tappable.

## Wiring (`Main.gd`)

`_boot()` builds the home view then raises `_show_title_screen()` over it (skipped under
the `PM98_SHOT_DIR` screenshot harness). `_title_action`: EXIT → `get_tree().quit()`;
DATA BASE → free the overlay to reveal the home/database browser; either league mode →
`_push(_show_career_pick_league)` (the pro/league split isn't modelled in this build, so
both start the same new career — flagged honestly).

## Provenance

Background © Dinamic Multimedia / Gremlin (fan remake, non-commercial). The original
game art is the only reference (`extracted/Premier Manager 98/`); nothing external.
