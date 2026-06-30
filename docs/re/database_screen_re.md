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

## VERIFIED 2026-06-29 (session 6): the status legend (Loop A) — fully reversed + BUILT
Objdump of `FUN_0042aba0` Loop A (`0x42b16d..0x42b2d1`) nails the last two unknowns from
session 5 (the x-array + the marker bitmaps). The Ghidra stack-aliasing is resolved against the
prologue writes (`0x42ac22..0x42ac77`):

- **x-array** `[esp+esi+0x74]` (esi=0,4,8) = the prologue array `{0xa,0x5a,0xaa,0x118}` →
  the 3 cells sit at **x = 10 / 90 / 170**, all at **y = 0x1cc = 460** (`push 0x1cc` @0x42b26c).
- **marker bitmaps** `[esp+esi+0x48]` (esi=0,4,8) = the first 3 of the 7-entry bmp array
  (`nuevo fichaje.bmp` / `ascendido.bmp` / `baja.bmp`); the other 4 (`mas|menos porteros|jugadores`)
  are the action buttons (Loop B, still unplaced).
- **font** = `Calend8` (`FUN_00456560(this,"Calend8")` @0x42b0e6, just before the loop);
  **text colour = black** (`FUN_004042d0(buf, 0)` @0x42b24c).

Marker↔label pairing (objdump-confirmed, PTR_s_New_signing @0x493958):

| cell | x | marker bmp | dims | glyph | label (str) |
|---|---|---|---|---|---|
| 0 | 10  | `NUEVO FICHAJE.BMP` | 11×11 | green ◀ badge | `New signing` @0x493a6c |
| 1 | 90  | `ASCENDIDO.BMP`     | 11×11 | blue ▲ badge  | `Youth player` @0x493a5c |
| 2 | 170 | `BAJA.BMP`          | 11×11 | red ▼ badge   | `Absence from the team` @0x493a44 |

Each marker is a solid colour-coded 11×11 badge with a white arrow (not transparent); blitted at
the cell origin (`FUN_00458730` @0x42b2ad), label drawn to its right. Cell width auto-sizes to the
measured text (`FUN_00462910` + 0x20 pad) — so faithful = badge at (x,460) + caption right of it.

**Built**: extracted `CALEND8.FNT` → `app/art/fonts/calend8.{fnt,png}` (`fnt_to_bmfont.py`,
224 glyphs, h=15) + the 3 markers → `app/art/icons/dbase_{new_signing,youth,absence}.png`
(`rc_dbase_image.py`). `PMChrome.font("calend8")` loads it; `DataBaseScreen._draw_legend()` blits
the 3 badges at (10/90/170, 460) with black Calend8 captions, in both LISTS and PHOTOS modes (the
original runs the legend setup once, mode-blind). Verified with a PIL mirror over real FONDO DBASE
using the **actual `calend8` atlas + extracted badges** (`/tmp/.../db_mirror_legend.png`): all 3
read cleanly, no column overlap, inside 640×480. (Headless `get_image()` is null here — the
documented GL limit — so the mirror is ground truth.)

**Legend icon↔text gap (investigated, left as approximation):** the caption's exact x-inset from
its marker is NOT a literal. The legend rows are a **distinct, simpler widget class** than the 4
columns — dtor `FUN_00409ee0`, **vtable `0x484948`** (the columns use dtor `FUN_004320f0`); both
share the `+0xc0` setter `FUN_0045b080`. `FUN_00458730` stores the marker as **cell content**
(per-cell stride 0x94, image ptr @+0x80, flags @+0x90/+0x92, column array base `this+0x360`); the
label is the widget **title**. Their relative x is computed at **paint time** inside that class's
MFC owner-draw (a `CRect` derived from the cell), i.e. `icon_w + runtime_pad`, not a baked number.
`FUN_0045b080` only bakes a **2px client-border** inset (`+0x88 = +0x78 + 2`), gated on style bit
0x400000 — applicability to the legend (AddItem style 0x900) unconfirmed. Recovering the exact gap
= decompiling vtable `0x484948`'s owner-draw painter (several more hops, may resolve to a runtime
expr) for a 0–3px payoff → **not pursued**. `DataBaseScreen._draw_legend()` keeps `marker_w + 3` as
the labeled approximation. (This is the same un-reversed paint slot flagged since session 5.)

**Still open after session 6:** the 7 action-button bitmaps (`nuevo fichaje`…`menos jugadores`) —
Loop B (`0x42b2d7+`) only sets their TEXT (`FUN_0044d4e0` on `this+0x742c`), never positions them,
so the button rects live in another fn and remain to be reversed. Plus the column body paint slot
(the `A_PANEL=0.30` compositing choice), and HISTORY/PROGRESS/SEGUIMIENTO + the browser shell.

## VERIFIED 2026-06-29 (session 7): the Loop-B "buttons" are per-column "MORE" scroll badges — BUILT
The session-5/6 unknown (where the 4 Loop-B cells `this+0x742c` get positioned) is resolved.
They are **not** add/remove buttons — they are **per-column overflow ("more") scroll badges**.

- **Constructor `0x42aa00`** (writes vtable `0x486910` at `[this]`) allocates `this+0x742c` as a
  **0x4c-stride cell array** (`FUN_0047e100`, elem ctor `0x44cfa0`) — the SAME lightweight-cell
  class as the legend cells `this+0x72fc`, **not** CWnds (those are 0x418). Loop B in `FUN_0042aba0`
  only fills their TEXT (`FUN_0044d4e0`) with the bmp paths; no rect, by design.
- **Placement is in the render fn `FUN_0042b540`** (objdump-confirmed via the Ghidra decompile),
  which adds **4 header items, ids 0xdd / 0xde / 0xdf / 0xe0**, one per column, each a fresh
  `operator_new(0x418)` child positioned via the `[vt+0xc0]` setter — args
  `(parent_col, rect, "", style=0x200000, id)`:

  | id   | parent col (off) | rect base | rect delta | child `+0x54` (cell idx) | cell bmp |
  |------|------------------|-----------|------------|--------------------------|----------|
  | 0xdd | GK  `+0x45f4`    | (0xa2,2)=(162,2) | (0x25,0x13)=(37,19) | 0 | `MAS PORTEROS.BMP` |
  | 0xde | DEF `+0x4a0c`    | (162,2)          | (37,19)             | 2 | `MAS JUGADORES.BMP` |
  | 0xdf | MID `+0x4e24`    | (162,2)          | (37,19)             | 2 | `MAS JUGADORES.BMP` |
  | 0xe0 | FWD `+0x523c`    | (162,2)          | (37,19)             | 2 | `MAS JUGADORES.BMP` |

  Base (162,2) is **relative to the parent column** (the setter's 1st arg is the column widget),
  so absolute = col-origin + (162,2): GK (168,15), DEF (168,142), MID (380,142), FWD (592,142).
  All 4 bmps are exactly **37×19** = the rect delta, so they blit 1:1 (no stretch).
- **Painter `FUN_0042e590`** (the owner-draw item painter, Ghidra-decompiled this session): its
  `0xdc < id < 0xe1` branch draws cell `this+0x742c + [this+0x54]*0x4c` into the framework item
  rect (`this+0x78`) via `FUN_0040f640` (an InvalidateRect/blit). So the badge bitmap fills the
  reversed badge rect — position is the literal above, not a runtime expr (unlike the legend gap).
- **Visibility = overflow.** Each item is added only under `if (cap < count)`: the GK badge when
  `GK_count > cap` and the outfield badges when that column's `count > cap`, where `cap` is the
  fixed visible-row cap from the same fn's row loop (`iVar8`): **GK 4 (LISTS) / 2 (PHOTOS)**,
  **outfield 15 (LISTS) / 7 (PHOTOS)**. So "MAS" (= Spanish *more*) = a scroll-down/overflow
  indicator. `MENOS …` (cells 1/3, *fewer*/up) are the scrolled-state counterparts; this render
  path never places them (only the four MAS badges), so they are extracted but not wired.
- Badge glyphs (rendered): `MAS PORTEROS` = **green** down-chevron, `MAS JUGADORES` = **red** down-
  chevron; `MENOS …` = up-chevrons.

**Built**: extracted the 4 badges → `app/art/icons/dbase_{more_gk,more_players,less_gk,less_players}.png`
(`rc_dbase_image.py`, 37×19 each). `DataBaseScreen.gd` adds `CAP_{GK,OUT}_{LISTS,PHOTOS}` consts +
`_row_cap()` (rows now capped at the binary's fixed cap, clamped to geometry) and, when a column's
`players.size() > cap`, blits its MORE badge at relative (162,2) (`MORE_BADGE` const) — GK→`more_gk`,
outfield→`more_players`. Verified: headless `--import` clean; `shot_database.gd` boot (demo bumped to
5 GKs so the GK badge path runs) = `DB-SHOT OK`/`SHOTS DONE`, no SCRIPT ERROR. **LOOKED** at a PIL
mirror over real `FONDO DBASE` with the actual extracted badges at the reversed absolute coords
(`/tmp/.../db_mirror_more.png`, scratchpad, not committed): all 4 badges sit in their column-header
top-right, fully inside the column rect (right edges 205/205/417/629 < col rights 214/215/427/639),
read cleanly. (Headless `get_image()` is null here — the documented GL limit — so the mirror is
ground truth.)

**Still open after session 7:** the `MENOS` (scrolled-up) badges + actual list scrolling (the
columns are capped, not yet scrollable); the column body paint slot (`A_PANEL=0.30` compositing
choice, the last un-reversed value); HISTORY/PROGRESS/SEGUIMIENTO + the country→league→team browser
shell. Decompiles saved: `FUN_0042e590` (item painter) + callees (`FUN_00404230/470/180/120/490/590`,
`FUN_0040f640`) — in scratchpad this session; `FUN_0042b540` (the placement fn) already in
`docs/re/decompiled/dbasewin/`.

## VERIFIED 2026-06-30 (session 8): the column body paint slot — CLOSED (body is transparent)
The last un-reversed value on this screen (the `A_PANEL=0.30` body-fill compositing choice) is
now settled **from the binary**, not guessed. The column widget is its own MFC class:

- **Column class** = vtable **`0x485ed8`** (set by dtor `FUN_004320f0`). Its `GetMessageMap`
  (vtable +0x30 = `FUN_00463ce0`) returns the AFX_MSGMAP at **`0x489de0`** (base map `0x453d90`).
- **WM_ERASEBKGND (0x0014) → `FUN_00457b00` = `return 1`.** Returning TRUE suppresses the default
  background erase, so **the column paints NO body fill** — the parent **FONDO DBASE** (football
  photo + faint blue grid) shows through the entire column body verbatim. ⇒ "solid fill vs tint"
  is answered: **neither.** The body is transparent.
- **WM_PAINT (0x000F) → `FUN_00459930`**: the normal path is clip-box / dirty-rect bookkeeping
  (it intersects `GetClipBox` into the child at `+600` and flags `+0x42c`); the only `FillRect`
  is `GetStockObject(4)` = **BLACK_BRUSH** over a ±0x2000 rect — an error/uninitialised fallback,
  not the body. So the column window draws **no body, no border, no header band of its own.**
- **The group COLORREF is still real** (per-group identity, session 5) but is consumed only as
  **5 precomputed shades**: the setter `FUN_0045b080` calls the alpha-blend
  **`FUN_004042f0(group, target, a)`** = `group*a/256 + target*(256-a)/256` per channel, storing
  into the column at:

  | off | target | a | = | role (reconstructed) |
  |---|---|---|---|---|
  | +0x404 | black | 0x98 | group*0.594 | dark border / shadow |
  | +0x408 | white | 0x82 | group*0.508 + white*0.492 | pastel title band |
  | +0x40c | white | 0x3e | group*0.242 + white*0.758 | light tint |
  | +0x410 | white | 0xae | group*0.680 + white*0.320 | mid-light tint |
  | +0x414 | (+0x5c) | 0x3e | 2nd-base*0.242 + white | secondary light tint |

  (The exact slot→element assignment of band vs border is the one remaining reconstruction: the
  column window paints none of them, so they belong to the title item whose geometry is not yet
  pinned. But every shade is one the binary actually computes from the real group colour, and a
  pastel band + dark border is their canonical use.)

**Built**: `DataBaseScreen.gd` — removed the invented `A_PANEL=0.30` body fill (body is now
transparent, FONDO shows through, matching ERASEBKGND=1) and the invented `A_HDR`/`lightened(0.45)`
chrome alphas; added `_grp_shade(group, target, a_byte)` (= `FUN_004042f0`) + consts
`SHADE_DARK_A=0x98` / `SHADE_BAND_A=0x82`; `_draw_column` now draws a pastel band (+0x408) over a
dark 1px border (+0x404), both from the column's real group COLORREF, white title (verified).
Verified: headless `--import` clean; `shot_database.gd` = `DB-SHOT OK`/`SHOTS DONE`, no SCRIPT
ERROR. **LOOKED** at a PIL mirror over real FONDO DBASE with the new transparent-body + binary-
shade chrome (`/tmp/.../db_mirror_session8.png`): all 4 columns read cleanly, the football photo +
grid shows through the bodies (as the binary does), group identity carried by the pastel bands.
Decompiles saved: `fn_004320f0` (dtor/vtable), `fn_0045b080` (setter), `fn_004042f0` (blend),
`fn_00457b00` (WM_ERASEBKGND), `fn_00459930` (WM_PAINT) in `docs/re/decompiled/dbasewin/`.

**Superseded by session 9 (below):** the pastel-band + dark-border that session 8 reconstructed
from the group shades is **WRONG for columns** — the column draws no band/border at all.

## VERIFIED 2026-06-30 (session 9): the column draws NO band/border either (title text only)
Decompiled the item content painter **`FUN_004613c0`** (the fn that reads the column's group
shades +0x404..+0x414 — found via a displacement xref scan), and its two edge primitives
`FUN_00461e20` (top+left edge) / `FUN_0043d2d0` (bottom+right edge). It is a classic Win32 3D
panel painter, but **every piece of chrome is gated on style bits the column does not have**
(column AddItem style = **0x808**, session 4):
- **Background fill** (`FUN_00404b60`, using the per-widget colour at +0x80) is drawn only when
  `style & 0x80800 == 0`. Column 0x808 has bit **0x800 set** -> fill **skipped**. (Matches the
  WM_ERASEBKGND=1 finding: no body fill, FONDO shows through.)
- **3D-bevel border** (the group-shade edges: +0x40c/+0x400 outer, +0x408/+0x404 inner, via
  `FUN_00461e20`/`FUN_0043d2d0`) is gated on `style & 0x80000`. Column 0x808 lacks 0x80000 ->
  **no bevel**. ⇒ the 5 group shades are **button chrome (style 0x80000 bevel-buttons), NOT
  column chrome.** Session 8's reconstructed band+border was wrong.
- **Per-column SetTextColor** (`FUN_00452b40(dc, +0x414)`) is gated on `(this+0x3f4 & 2) &&
  (style & 0x200000)`. Column lacks 0x200000 -> title text uses the **inherited DC colour**
  (the screen's text colour, set white via `FUN_004042d0(_, 0xffffff)`).
- The column's **0x800 branch** (which it does have) draws **only the title text** (`FUN_00452b90`
  at the item rect) over the transparent body.

⇒ **A faithful column = transparent body (FONDO through) + white title text. No fill, no band, no
border.** `DataBaseScreen.gd` updated: removed the session-8 band/border + the `_grp_shade` helper
+ `SHADE_*` consts; `_draw_column` now draws only the title over the transparent body. Verified:
headless import clean; `shot_database.gd` = `DB-SHOT OK`/`SHOTS DONE`, no SCRIPT ERROR; **LOOKED**
at a PIL mirror over real FONDO (`/tmp/.../db_mirror_session9.png`): white titles + status-coloured
names lie directly on the football photo/grid (the grid carries the column structure), no panels,
reads as a period PC-Futbol DB screen. Decompiles saved: `FUN_004613c0` (item painter),
`FUN_00461e20` / `FUN_0043d2d0` (edge prims) in `docs/re/decompiled/dbasewin/`.

**Still open after session 9:** the `MENOS` scrolled-up badges + real list scrolling; HISTORY /
PROGRESS / SEGUIMIENTO + the country -> league -> team browser shell. (The squad-view DATA BASE
screen is now reversed end to end: layout + rows + photos + legend + MORE badges + body/chrome.)

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
- Legend assets (session 6): `cd tools/re && python3 fnt_to_bmfont.py CALEND8.FNT ../../app/art/fonts calend8`
  + `python3 rc_dbase_image.py "NUEVO FICHAJE.BMP" ../../app/art/icons/dbase_new_signing.png`
  (likewise `ASCENDIDO.BMP`→`dbase_youth.png`, `BAJA.BMP`→`dbase_absence.png`).
- Decode DB text pools: `cd tools/re && python3 dmlt_decode.py` (all 3) or `dmlt_decode.py PAISES.30`.
- dbasewin decompilations live in `docs/re/decompiled/dbasewin/` (Point/Rect/SetFont/blit + `FUN_0042aba0`).
- Decompile dbasewin: `~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless ~/ghidra-projects pm98
  -process dbasewin.exe -noanalysis -scriptPath tools/re/ghidra_scripts -postScript
  DecompileAt.java /tmp/claude-1000 0xVA`. objdump: `objdump -d -M intel -b pei-i386
  --start-address=0xVA --stop-address=0xVA "extracted/Premier Manager 98/Dbasewin.exe"`.
- wine screenshots of the live app are **BLACK** here (headless :1; scrot can't read the wine
  framebuffer — same limit as MANAGER.EXE). Ground truth = the extracted BMPs + the binary blits.
