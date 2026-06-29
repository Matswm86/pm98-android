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

## VERIFIED 2026-06-29 (session 2): how dbasewin draws — the real primitive vocabulary
`Dbasewin.exe` is in the Ghidra `pm98` project (program id `00000001`, name `dbasewin.exe`;
image base 0x400000; .text 0x401000, .rdata 0x484000, .data 0x491000, .rsrc 0x51d000).

**Confirmed from the binary this session (not assumed):**
- **No RT_DIALOG and no RT_BITMAP resources** — `.rsrc` holds only ICON/GROUP_ICON/VERSION
  (parsed the PE resource dir). So screens are **NOT dialog templates**; layout is drawn in
  code at literal coords. (This kills any "find the dialog template" shortcut.)
- Bitmap paths are built at run time: `lstrcpyA(buf, "RC_DBASE\")` then append the bmp name
  (the bare prefix `"RC_DBASE\"` @0x492224 is pushed at 6 sites). Some are also full literals
  (e.g. `"RC_DBASE\fondo dbase.bmp"` @0x4916b4).
- **Draw primitives** (decompiled, saved to `docs/re/decompiled/dbasewin/`):
  | fn | role | signature |
  |---|---|---|
  | `FUN_00404120` | **Point(x,y)** | writes x@+0, y@+4 |
  | `FUN_00404180` | **Rect(base,delta)** | rect = base_point .. base_point+delta_point (normalized) |
  | `FUN_004042d0` | **SetColor** | `(buf, 0xffffff)` = white text |
  | `FUN_004042b0` | small 3-arg ctor (text style/box) | `(buf, a,b,c)` |
  | `FUN_00456560` | **SetFont(name)** | copies font name → `this+0x3b4`, resolves font obj → `this+0x3d4` |
  | `FUN_004580b0` | **blitBitmap** | `(this, "RC_DBASE\…bmp", x, y, flag=0x32, 0)` |
  | `FUN_00458730` | blit variant (crest/photo) | `(widget, srcObj, x, y, 0x32, 0)` |
  | vtable **+0xc0** | **widget.draw()** | each UI widget is an object at `this+<off>`; drawn via `(**(code**)(vt+0xc0))()` |
- **Bitmap fonts** (PC Fútbol `.FNT`, NOT GDI): `Proman10` `Proman12` `Proman18` `Proman8`
  `Futuri18` `Calend8`. SetFont is called before each group of draws.

**Worked example — `FUN_0042aba0` = a DATA BASE list/squad view draw routine** (entry 0x42aba0):
1. `lstrcpyA(buf, "DBDAT\MINIESC\")` — mini crests path.
2. `SetFont("Proman10")`; `blitBitmap("RC_DBASE\fondo dbase.bmp", 0, 0, 0x32, 0)` — **bg at (0,0)**.
3. `this+0x860 = "INFOFUT\dbplant.htm"` (squad help link); `this+0x2d4c` toggles
   `"LISTS"` vs `"PHOTOS"` mode.
4. A series of widget rects built from Point pairs (raw literals, all within 640×480):
   `(0x5e,0x19)=(94,25)`, `(0x1af,0x1a3)=(431,419)`, `(0x58,0x19)=(88,25)`,
   `(0x21d,0x1c1)=(541,449)`, title `(0x174,0x27)`/`(0xe0,0x12)` under `Proman18`,
   mid panels under `Proman12` at `(0xd0,0x73)` / `(0xd1,0x13b)=(209,315)` / `(0x1ae,0x8c)`…
   each followed by `widget.draw()` (vt+0xc0).
5. **Loop A** (3 rows): labels `"New signing"`, `"Youth player"`, `"Absence from the team"`
   (PTR table @0x493958) + a crest per row (`FUN_0044d4e0` sets cell text, `FUN_00458730`
   blits the crest).
6. **Loop B** (4): action-button bitmaps `nuevo fichaje / ascendido / baja / mas porteros /
   menos porteros / mas jugadores / menos jugadores` (@0x493a94..0x493b00), path-built with
   the `"RC_DBASE\"` prefix.
7. Tails into `FUN_0042b3e0`, `FUN_0042c200`, `FUN_0042b540` (sibling draw/refresh fns).

⇒ The method is proven: decompile the per-screen draw fn, read Point/Rect literals, map widget
offsets → bitmaps. **The `0x42b155` text-draw branch** in `FUN_0042aba0`'s sibling chain shows
the font+box struct (`Proman10` vs `Futuri18`, x=0xc4,y=0x12,w=0x15…) — the per-string layout.

## DMLT text tables — DECODED + VERIFIED (cipher = XOR 0x61)
`tools/re/dmlt_decode.py` decodes `DBDAT/*.30`. Format: `"DMLT"` + u32 payload_len + u32 count
+ records `[u16 len][len bytes]`; **each byte XOR 0x61**. Counts: PAISES 128 (countries),
NOMBRES 148 (first names), APELLIDO 327 (surnames). Cross-checked byte-for-byte against the
repo's `assets/country_codes.json`; XOR 0x61 is the only transform that also decodes the
accents (raw 0xb0 → `Ñ`, e.g. `CATALUÑA`) and punctuation (`REP. OF IRELAND`, `U.S.A.`).
NOTE: `assets/strings.json` already holds all three pools but **uppercased**; the real bytes are
mixed-case (`Adrian`, `Abel`) — the tool preserves original casing. Record 0 of PAISES = `XXX`
(no-country sentinel). The team/player records (EQUIPOS.PKF) are **still undecoded**.

## Reverse plan (remaining)
1. ~~Find the loader~~ DONE: it's `blitBitmap`/`SetFont`/`Point`/`Rect` at literal coords, per
   screen. Continue decompiling the other view fns (HISTORY/PROGRESS/SEGUIMIENTO draw routines)
   and the `BANDA DBASE` banner blit site.
2. Finish `FUN_0042aba0`'s exact widget→offset→bitmap map and the team/player **list row layout**
   (row pitch, columns, the `FUN_0044d4e0` cell writer). Reverse, don't eyeball.
3. Decode the `DBDAT` **EQUIPOS.PKF** record format (teams → players, ratings) to populate the
   browser country → league → team → player → FICHA. (`.30` text pools already decoded.)
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
- Decode DB text pools: `cd tools/re && python3 dmlt_decode.py` (all 3) or `dmlt_decode.py PAISES.30`.
- dbasewin decompilations live in `docs/re/decompiled/dbasewin/` (Point/Rect/SetFont/blit + `FUN_0042aba0`).
- Decompile dbasewin: `~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless ~/ghidra-projects pm98
  -process dbasewin.exe -noanalysis -scriptPath tools/re/ghidra_scripts -postScript
  DecompileAt.java /tmp/claude-1000 0xVA`. objdump: `objdump -d -M intel -b pei-i386
  --start-address=0xVA --stop-address=0xVA "extracted/Premier Manager 98/Dbasewin.exe"`.
- wine screenshots of the live app are **BLACK** here (headless :1; scrot can't read the wine
  framebuffer — same limit as MANAGER.EXE). Ground truth = the extracted BMPs + the binary blits.
