# DATA BASE screen — reverse-engineering notes (the REAL target)

Status: **architecture VERIFIED FROM SOURCE 2026-06-29. Layout reverse = NOT STARTED.**
This file supersedes the "PCF5 mode inside MANAGER.EXE" plan in
`handoff-pm98-title-hitfix-database-pcf5-2026-06-29` and the MASTER handoff's Track B —
that plan was **wrong** (see "Correction" below).

## What the DATA BASE actually is (verified against the binaries in the rar)
The title-screen **DATA BASE** button (and the invented green `_show_home`/`_mount_browse`
list in Main.gd that currently stands in for it) maps to a **separate, standalone program**:

- `MANAGER.EXE` DATA BASE handler `FUN_004f8750` does `CreateProcessA("%c:PM98.EXE PCF5%X")`
  — it relaunches **`PM98.exe`**, the game's tiny (10.5 KB) **dispatcher**.
- `PM98.exe` (verified: imports `CreateProcessA`; string table = `manager.exe`, **`dbasewin.exe`**,
  `actwin.exe`, `infosurf.exe`, `PCF5_Loader_Event1/2`) → for the PCF5/DATA-BASE mode it
  `CreateProcessA`'s **`Dbasewin.exe`**.
- **`Dbasewin.exe`** (604 KB, **PE32 GUI, MFC42**) IS the DATA BASE: window titles
  `"Data Base - Premier Manager 98"`, `"History - Premier Manager 98"`,
  `"Progress - Premier Manager 98"`. It is the **PC Fútbol 5 database engine reskinned for the
  Premier League**.

⇒ There is **no `PCF5` argv branch to reverse in MANAGER.EXE**, **no `PCF5DAT.PKF`**, and **no
`MENUPCFUT5` RECURSOS group** (none of those exist in this install). The skin archive is
**`RC_DBASE.PKF`**; the football data is **`DBDAT/`**; the program is **`Dbasewin.exe`**.

### Correction (why the old plan was wrong)
The prior handoffs inferred "PM98 runs a PCF5 *mode* of the same binary, draws via the
`FUN_004fa840` FONDO map, data in PCF5DAT.PKF / MENUPCFUT5." Checking the rar's actual files
falsifies all three: the DB is a *different executable* (`Dbasewin.exe`), the resources are
`RC_DBASE.PKF` + `DBDAT/`, and PCF5DAT.PKF/MENUPCFUT5 are absent. `MANAGER.EXE` only *launches*
the DB; it does not render it. (Lesson: the `CreateProcessA("PM98.EXE …")` string was read as
"same binary, new mode" without checking that a separate `PM98.exe` + `Dbasewin.exe` ship in
the install.)

## Screens (from `Dbasewin.exe` strings)
`DATA BASE` (main team/player browser) · `HISTORY` · `PROGRESS` (`MANAGER PROGRESS` /
`PLAYER PROGRESS`) · `SEGUIMIENTO` (scouting/tracking). Each is a full-screen 640×480 view.

## Skin archive — `RC_DBASE.PKF` (266 BMP entries, real Windows BMPs)
Same PKF container as RECURSOS (parse with `tools/re/pkf_unpack.py`), but the payloads are
**ordinary "BM" bitmaps** (not "DM" DIBs). Render any entry with the new
**`tools/re/rc_dbase_image.py <ENTRY> <out.png>`** (handles both BMP flavours + the shared
palette — see its header). Two flavours:
- **Palette-bearing** (BITMAPINFOHEADER, bfOffBits=1078): the `_NEW`/`_BARSA` variants,
  `PANTALLA.BMP`, etc. Render directly.
- **Palette-LESS 8bpp** (OS/2 core header, bfOffBits=26): pixels only. The DATA BASE is one
  256-colour mode, so these use the ONE shared screen palette → fall back to the game's shared
  VGA palette (`DAT.PKF @0x5ca`). Verified identical to the embedded palette on FONDO DBASE.

Key assets (dims confirmed by rendering):
| Entry | size | role |
|---|---|---|
| `FONDO DBASE.BMP` | 640×480 | main DATA BASE background (washed-blue football photo + grid) |
| `FONDO_HISTORIA.BMP` | 640×480 | HISTORY background |
| `FONDO SEGUI.BMP` | 640×480 | SEGUIMIENTO background |
| `FONDO_SCREENS.BMP` / `PLANTILLA_FONDO.BMP` / `SELECCION_FONDO.BMP` | 640×480 | other DB views |
| `BANDA DBASE.BMP` / `BANDA DBASE_NEW.BMP` | 640×54 | top banner ("PC FÚTBOL" + LFP logo) |
| `CLUB TITULO.BMP` | 640×72 | soccer-ball title bar (BARRA-style, red underline) |
| `CAMPO.BMP` | 132×190 | pitch graphic (formation view) |
| `BOLA_AZUL/BLANCA/NEGRA/ROJA.BMP` | 8×8 | rating dots |
| `BOTON {ARRIBA,ABAJO,DER,IZQ} {PULSADO,SIN PULSAR}.BMP` | — | scroll/nav arrows (up/down/left/right, pressed + idle) |
| `BOT_{AZUL,ROJO} {NORMAL,PASA,PULSADO}.BMP` | — | blue/red buttons (idle / hover / pressed, + `_G` greyed) |
| `FICHA {OFF,ON} 1..3.BMP`, `FICHABAJO …` | — | player-card tabs |
| `LUPA.BMP` | — | search magnifier |
| `COPA_PREMIER / COPA_LIGAESP / ICO FACUP / ESCUDO_LFP / …` | — | competition emblems |
| `ICO_*` (dozens) | — | section/competition icons |
`rc_dbase_image.py --list` dumps all 266 with sizes.

## Data layer — `DBDAT/` (the football database)
- `EQUIPOS.PKF` (4.0 MB) — teams (the core records).
- `BIGESC/MINIESC/NANOESC/RIDIESC.PKF` — club crests at 4 sizes; `BANDERAS/MINIBAND.PKF` — flags;
  `BIGFOTO/MINIFOTO.PKF` — player photos; `BIGENTR/MINIENTR.PKF` — manager photos;
  `BIGCAMP.PKF` — stadiums.
- `PAISES.30` (countries), `NOMBRES.30` (first names), `APELLIDO.30` (surnames) — **`DMLT`-magic
  encoded text tables** (decode TBD; not plain ASCII).
- `premier.dbc` is referenced by `Dbasewin.exe` (.data @0x495324) as the DB config; the live
  records resolve out of `DBDAT/`.

## Reverse plan (next session — replaces the falsified Track B)
`Dbasewin.exe` is **imported into the Ghidra `pm98` project** (`-process dbasewin.exe`, image
base 0x400000; .text 0x401000, .rdata 0x484000, .data 0x491000, .rsrc 0x51d000). It is an MFC
app that loads `RC_DBASE\*.bmp` by name (101 lowercase path strings in `.data`) into a
resource manager and `BitBlt`s them at literal coords. To rebuild the main DATA BASE screen
faithfully:
1. Find the bitmap-name → ID table in `.data` (around `RC_DBASE\` @0x491404) and the loader
   that fills the resource manager.
2. Find `CView::OnDraw` / the main `BitBlt` site for `FONDO DBASE` + `BANDA DBASE` → read the
   blit rects (banner position, list region, button rects). Reverse the row layout + columns +
   font of the team/player list (do NOT eyeball — that was the Title-screen tap bug).
3. Decode the `DBDAT` record format (EQUIPOS) + the `.30` `DMLT` text tables enough to populate
   the browser (country → league → team → player → FICHA).
4. Build `scenes/DataBaseScreen.gd` from the real extracted art (rc_dbase_image.py output) +
   reversed layout; replace `_show_home`/`_mount_browse` in Main.gd; wire the title DATA BASE
   action. Render at 640×480 on DISPLAY :1 and LOOK; overlay hit-rects.

## Scope
This is a **complete separate sub-application** (4 screens + a binary DB decode), comparable in
size to the match-engine track — a multi-session faithful port, NOT a one-session fix. Do not
ship a partial screen (real background behind an invented list) — that is the invented-art trap
the `pm98_stay_true_to_original` rule forbids.

## Cheatsheet
- Render DB art: `cd tools/re && python3 rc_dbase_image.py "FONDO DBASE.BMP" /tmp/x.png` (`--list` for all).
- Decompile dbasewin: `~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless ~/ghidra-projects pm98
  -process dbasewin.exe -noanalysis -scriptPath tools/re/ghidra_scripts -postScript
  DecompileAt.java /tmp/claude-1000 0xVA`. objdump: `objdump -d -M intel -b pei-i386
  --start-address=0xVA --stop-address=0xVA "extracted/Premier Manager 98/Dbasewin.exe"`.
- wine screenshots of the live app are **BLACK** here (headless :1; scrot can't read the wine
  framebuffer — same limit as MANAGER.EXE). Ground truth = the extracted BMPs + the binary blits.
