# DATA BASE screen — reverse-engineering notes (the REAL target)

Status: **architecture + 4-column squad-view layout VERIFIED FROM SOURCE 2026-06-29.
`DataBaseScreen.gd` BUILT + wired (session 4).**
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

## VERIFIED 2026-06-29 (session 3): the player-list is a 4-column model, reversed
Decompiled the draw chain `FUN_0042aba0` tails into. `FUN_0042aba0` is the **main
DATA BASE screen setup** (it blits `fondo dbase.bmp` at 0,0); the scrollable player
list itself is the **model→sort→render** trio below. Saved decompilations:
`FUN_0042c200`, `FUN_0042b540`, `FUN_0042c030`, `FUN_0042c1c0`, `FUN_0044d4e0` in
`docs/re/decompiled/dbasewin/`.

- **Model + sort — `FUN_0042c200`**: walks a **player linked list** (next ptr at
  player+0x54), and for each player (skip if byte@+0x20 == `'b'`) reads a **category
  byte @+0x16** (0/1/2/3) and a **u16 id @+0x14**, copying into one of **4 arrays**
  (`DAT_00497480 / _498 / _488 / _490`, counts `_484 / _49c / _48c / _494`).
  Each array entry is **0x50 bytes**: `[u16 id][u32 teamIdx][u32 flag(=record@+0x4c==3)]
  [name string @+0xc]`. Then it binary-insert-sorts each array. ⇒ the 4 lists are the
  **4 position groups** (GK / DEF / MID / FWD).
- **Render — `FUN_0042b540`**: lays the 4 lists into **4 on-screen columns** at base
  widgets **`this+0x45f4 / +0x4a0c / +0x4e24 / +0x523c`**. Two modes toggled by
  **`this+0x2d4c`** (the `LISTS`↔`PHOTOS` flag set in `FUN_0042aba0`):
  | mode | font | row pitch (Δy) | first y | row x | col x,w | header rows |
  |---|---|---|---|---|---|---|
  | **LISTS** (`2d4c==0`) | `Proman10` | **0x12 (18)** | 0x15 (21) | 0x3 | x=0xc4,w=0x10 | 4 |
  | **PHOTOS** (`2d4c!=0`) | `Futuri18` | **0x28 (40)** | 0x19 (25) | 0x9 | x=0xbb,w=0x24 | 2 |
  Each row = a fresh `operator_new(0x418)` CWnd; y starts at *first y* and increments
  by *row pitch* per row. Per row it calls `FUN_0042c1c0(row, mode, entry.id)` then
  `FUN_0042c030(row, entry.name@+0xc, mode)`.
- **Per-row crest/photo — `FUN_0042c1c0`**: `pvVar = FUN_00445f10(entry.id)` (resolve
  club crest / player photo by id), `FUN_00458730(row, pvVar, 0,0, 0x32,0)` (blit). So
  every list row carries its **crest/photo keyed by the entry's u16 id**.
- **Per-row name text — `FUN_0042c030`**: measures the name in the active bitmap font
  (`FUN_00462910` on the font obj `this+0x3d4`) and sets the row widget's rect
  (`this+0x88..0x94`); padding differs by mode (0x29/0xa PHOTOS vs 6/2 LISTS).
- **Cell rich-text — `FUN_0044d4e0`** (used by the squad-mgmt panel rows in
  `FUN_0042aba0`, stride 0x4c): tokenizes the first word, uppercases it, and
  dispatches to one of several formatters (`FUN_0044d6a0 / da80 / dcc0 / dfb0 / e260`)
  — a markup mini-language for embedded fields. Not needed for the plain browser list.

⇒ A faithful `DataBaseScreen.gd` squad view = **4 columns (GK/DEF/MID/FWD)**, each
position-sorted, Proman10 @18 px pitch (list) or Futuri18 @40 px + crest/photo
(photo), columns anchored at the four base-x's above. Row content = name (measured,
clamped) + crest/photo by team/player id. **This is the layout to build to — reversed,
not eyeballed.**

## VERIFIED 2026-06-29 (session 4): the 4 column screen rects + headers + sort key
The column **screen rects** were the missing literal (FUN_0042b540 places rows relative
to the column widget; the widget's own rect is set in **FUN_0042aba0** at 0x42af54..0x42b0df).
Each is built `widget.AddItem(parent, rect, title, style=0x808, id=0)` via vtable **+0xc0**
(`FUN_0045b080`, a property-setter that stores the rect — not the paint slot), with the rect
normalized by `FUN_00404180(base=2nd-Point-pushed, delta=1st)`:

| col | offset | base | delta | rect (l,t,r,b) | title (str) | cat |
|---|---|---|---|---|---|---|
| GK  | +0x45f4 | (6,13)   | (208,115) | **(6,13,214,128)**   | `GOALKEEPERS` @0x493900 | 0 |
| DEF | +0x4a0c | (6,140)  | (209,315) | **(6,140,215,455)**  | `DEFENDERS` @0x493910   | 1 |
| MID | +0x4e24 | (218,140)| (209,315) | **(218,140,427,455)**| `MIDFIELDERS` @0x493920 | 2 |
| FWD | +0x523c | (430,140)| (209,277) | **(430,140,639,417)**| `FORWARDS` @0x493930    | 3 |

So GK = a wide-short box top-left (≤5 rows); DEF/MID/FWD = three tall side-by-side columns.
The screen also draws `MANAGER`/`THE SQUAD` labels (str 0x493940/0x493948) + a `Calend8`
caption (str 0x493a78). **Sort = alphabetical by name**: `FUN_0042c540` adds `0xc` to both
entries (= name @+0xc) and calls the `lstrcmp` import `ds:0x4840c8`. Category 0/1/2/3 in
`FUN_0042c200` = GK/DEF/MID/FWD (matches game_db `pos` GK/DF/MF/FW). Header msg-id boxes
(0xdd–0xe0) are small per-column badges at base(0xa2,2) — not the visible title.

⇒ **Built**: `app/scenes/DataBaseScreen.gd` (FONDO DBASE bg + the 4 rects above + Proman10
LISTS rows + MINIFOTO thumbnail by `photoId` + alpha sort), wired into `Main.gd`
(`_open_database_squad`, replacing the invented `_open_squad` on the DATA BASE browse club
taps). Render harness `app/tests/shot_database.gd` (+ a screenshot.yml step). Remaining for a
future pass: the **PHOTOS mode** (Futuri18, 40 px rows), the country→league→team picker art
(SELECCION_FONDO), and HISTORY/PROGRESS/SEGUIMIENTO.

## VERIFIED 2026-06-29 (session 5): the 4 columns carry distinct per-group COLORREFs
Each AddColumn call in `FUN_0042aba0` (the `call DWORD PTR [edi+0xc0]` setter, with
`edi = *(ebp+0x45f4..)`) is preceded by **`FUN_004042b0(colorbuf, R, G, B)`**, which writes
a **4-byte COLORREF `{R, G, B, 0x00}`** (objdump: `[eax]=R`, `[eax+1]=G`, `[eax+2]=B`,
`[eax+3]=0`; `ret 0xc`). So every position column has its **own identity colour** — the
original colour-codes the four groups; it does **not** use one shared blue. Reversed at the
four call sites:

| col | offset | FUN_004042b0(R,G,B) | COLORREF | hue |
|---|---|---|---|---|
| GK  | +0x45f4 | (0x50,0x6e,0x05) | RGB(80,110,5)  | olive green |
| DEF | +0x4a0c | (0xd4,0x3f,0x00) | RGB(212,63,0)  | orange |
| MID | +0x4e24 | (0xaa,0x00,0x00) | RGB(170,0,0)   | red |
| FWD | +0x523c | (0x6c,0x15,0x15) | RGB(108,21,21) | maroon |

Header **title text is white** — verified `mov ebx,0xffffff` in the column setter chain
(`FUN_0045b080` @0x45b107). Applied in `DataBaseScreen.gd`: each column's header band +
border + body tint now derive from its real COLORREF (replacing the prior single invented
blue `C_PANEL`/`C_HDR`). Cross-checked with a PIL mirror over the real `FONDO DBASE`.

**Header title (built):** widget `this+0x5a6c`, a Proman18 string set white (`0xffffff`,
FUN_004042d0) at rect base **(224,18)** delta **(372,39)** (objdump 0x42ae7e..0x42aea6:
`push 0x174/0x27` then `push 0xe0/0x12`, same base=2nd / delta=1st convention as the columns).
The string is the club/competition name (FUN_00445a90→FUN_0043b660). `DataBaseScreen.gd` now
draws the club name in Proman18 here; the old small caption + invented `"DATA BASE"` subtitle
(no such on-screen string in the binary) are removed. A club crest widget `this+0x5e84` blits
top-right at ~(585,4) 58×64 — NOT built (the app's `PMChrome.draw_crest` draws a kit, not the
MINIESC emblem; building it would mismatch).

**Legend (partially reversed, NOT built):** Loop A (`0x42b16d..0x42b2d1`, 3 iters) lays 3 cells
at **y=460** (`push 0x1cc`), x from a stack array (`mov edx,[esp+esi+0x74]`, candidate values
10/0x5a/0xaa = 10/90/170), each `New signing`/`Youth player`/`Absence from the team`
(PTR@0x493958) + a crest blit (FUN_00458730). The 3 x's and the cell delta need confirming
before building. **Action buttons (NOT placeable here):** Loop B (`0x42b2d7..0x42b385`, 4 iters)
only sets cell TEXT (FUN_0044d4e0) on widgets `this+0x742c` — it does NOT position them
(`[edi+0xc0]` is not called), so the 7 button rects (`nuevo fichaje`…`menos jugadores`) live in
another function and remain to be reversed.

**PHOTOS mode (built):** the alternate render of the same 4-column squad (FUN_0042b540,
`this+0x2d4c`) — Futuri18 names, row pitch **40** (0x28), first-y **25** (0x19), row-x **9**,
larger photo. `FUTURI18.FNT` extracted from `WINFONTS/` via `tools/re/fnt_to_bmfont.py` →
`app/art/fonts/futuri18.{fnt,png}` (224 glyphs, h=19; sampled by eye). `DataBaseScreen.gd`
branches both modes; toggled by a tap on the title strip (`TITLE_RECT`) — a documented mobile
stand-in for the real LISTS/PHOTOS bitmap button (its on-screen position is not yet reversed).
Default = LISTS. NB: `this+0x2d4c` polarity vs session-3's table is unconfirmed (FUN_0042aba0
sets it to 1); the toggle renders both regardless, so the default is a one-line flip once known.

**Still open (not yet reversed):** the column widget's actual *paint slot* (a per-object
function pointer, NOT `[edi+0xc0]` which is the rect/title/colour SETTER, and NOT
`FUN_0045b080` which is a sibling called directly). So whether the real body is a *solid*
group-colour fill vs a tint vs colour only in the header band is undetermined — current
`A_PANEL = 0.30` body alpha is a compositing choice, the only un-reversed value left on this
screen. The legend rows (`New signing`/`Youth player`/`Absence from the team`, PTR
@0x493958) + 7 action-button bitmaps (`nuevo fichaje`/`ascendido`/`baja`/`mas|menos
porteros`/`mas|menos jugadores`) drawn by Loops A/B in `FUN_0042aba0` are also still unbuilt.

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
