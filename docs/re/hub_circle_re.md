# MANAGER MENU hub — central club CIRCLE panel, reversed from MANAGER.EXE

Binary decode of the hub's central circle stack (the "CPU / Gregory / Aston
Villa / Bolton W / mwm / PL 1" panel) — the charter-#2 items the 2026-07-16
parity run flagged as "semantics unresolved — witness more originals before
coding". Everything below is read from MANAGER.EXE (VA↔file mapping: .text
+0x400c00, .rdata +0x401200, .data +0x401a00) and cross-checked against the
witnessed frames (parity-run orig/07+73+78, promanager 13, walkthrough
001_160008). Method at the bottom; all addresses reproducible.

## The render function: `FUN_00549240` (undefined-region, vtable-reached)

`thiscall(this)` — 1227 bytes, epilogue `RET 4`. Reached ONLY via vtable
`0x6339d0` slot +0x10c (0x633adc); auto-analysis leaves it undefined (same
class of find as the sack path). `this` = the circle sub-widget at
**screen+0x19c0** of the MENUPRINCIPAL screen object (ctor `FUN_005458f0`
stores `PTR_0x6339d0` at `param_1[0x670]`). Its drawing surface is
`this+0x400`; text state on the surface: `+0x118` text colour (set by
`FUN_005d9d30`), `+0x120/+0x140` font name/handle (set by `FUN_005d9d50`).
Text is drawn by `FUN_005d9d80(surface, char* text, l, t, r, b, 0x100)` /
`FUN_005da180(..., 0x100, 1)` (variant picked on `[surface+0x144]>>3 & 1`),
centred in the rect (the s8-decoded integer cell-centring
`x0 + (cell_w - (advance-1))/2` fits every witnessed label).

### Slot objects and the home/away rule (`FUN_005469c0` @ 0x546a08-0x546a6b)

The widget holds THREE pointers: `+0x3f4` = **TOP slot club**, `+0x3f8` =
**BOTTOM slot club**, `+0x3fc` = the ACTIVE manager's club. Populated at menu
init from the current-fixture record `DAT_0066afd0`:

```
[+0x3fc] = own club (init arg)
homeIdx  = word [0x66afd0+0x38]          ; fixture HOME club index
awayIdx  = word [0x66afd0+0x3a]          ; fixture AWAY club index
if own.index == homeIdx:  TOP = own club,          BOTTOM = clubByIdx(awayIdx)
else:                     TOP = clubByIdx(homeIdx), BOTTOM = own club
```

**TOP = HOME side, BOTTOM = AWAY side — always.** The witnessed
"opponent always on top" was an artefact: every witnessed fixture had the
user away (fixtures screen orig/13: "Aston Villa - Bolton W",
"Southampton - Bolton W" 9 AUG, "Coventry - Bolton W" 23 AUG — home club
listed first). `clubByIdx` = `FUN_00585ee0(0x66c0d0, idx)` then
`FUN_005793d0` (lazy `[club+0x10]` wrapper — same type as the init arg).

Slot-club fields used by the render:
- `+0x4`  club name (char*)
- `+0x10` club index (kit/crest lookups)
- `+0x2c` the club's REAL manager name (char*, from the game DB — witnessed
  Gregory/Jones/Strachan/Molby/Van Gaal). Drawn for CPU-managed clubs.
- `+0x5c` human-manager slot index, **0xffff = CPU-managed**. When human,
  `DAT_0066c178 + idx*0x9c` = that player's manager record; the record's
  name (offset +0x0) is what the manager bar shows (witnessed "mwm"/"MWM").
  This is the same manager-record table whose +0x28 = Promanager level
  (seasonend_flow_re.md) — records are 0x9c bytes.

### The "PL 1" chip = PLAYER NUMBER (not level, not league position)

Chip logic per side (top reads `+0x3f4`, bottom `+0x3f8`):

```
if club->0x5c == 0xffff:  text = "CPU"                      (0x65e320)
else:                     text = "PL " + itoa(0x5c + 1)     ("PL " @ 0x65e324, "%ld" @ 0x652f00)
```

`+0x5c + 1` = the 1-based human-player slot → **"PL n" = Player n**. That is
why it reads "PL 1" for Bolton (Premier), Brighton (3rd Div, Promanager) and
Man Utd (walkthrough) alike, and never changes with week/table/level. In a
hotseat multi-manager game the second player's club would show "PL 2".
menu_screen_re.md's earlier "league position PL n" description was wrong
(the 07-16 app drew Bolton's alphabetical rank 5 → "PL 5"); corrected there.

### Geometry (panel-relative; widget rect pos **(220,173) size 205x173**, set
at 0x547cad-0x547cd4; add (220,173) for full-screen)

| element | fill rect (pos,size) | frame rect | text rect (l,t,r,b) |
|---|---|---|---|
| TOP chip      | (76,1) 50x14   | (75,0) 52x16   | (76,1,126,15)    |
| TOP mgr bar   | (30,22) 143x23 | (29,21) 145x25 | (30,22,173,45)   |
| TOP club bar  | (9,53) 187x21  | (8,52) 189x23  | (9,53,196,74)    |
| BOT club bar  | (9,99) 187x21  | (8,98) 189x23  | (9,99,196,120)   |
| BOT mgr bar   | (30,128) 143x23| (29,127) 145x25| (30,128,173,151) |
| BOT chip      | (76,158) 50x14 | (75,157) 52x16 | (76,158,126,172) |

- Kit bitmaps: TOP at (2,48), BOTTOM at (178,94) — `clubByIdx(+0x10)` →
  `FUN_00579710()` bitmap, drawn via `FUN_004b7f60(0x10,0x40,0xff,…)` at
  **0x549679 / 0x5496f6** (the anchors are the literals `mov [esp+0x2c],2 /
  [esp+0x30],0x30` and `0xb2 / 0x5e`). **CORRECTED 2026-07-28: the asset is the
  24x32 NANOESC kit, not a ~50x65 two-shirt group.** `FUN_00579710` caches
  `club+0x18` from the format string at `0x662120` = `DBDAT\NANOESC\eq96%04u.bmp`
  (its sibling `FUN_00579730` does `club+0x1c` from `DBDAT\RIDIESC\`, the 17x20
  icon the knockout kit lists use). Screen anchors therefore (222,221) and
  (398,267). Ported and shipped; the old 45x57 stand-in is deleted.
- Arrow: `recursos\iconos\menuprincipal\flechanegra.bmp` (0x65e22c), loaded
  into the widget surface at init (0x546a7f); drawn at **(18,22)** when the
  active club is TOP, **(18,128)** when BOTTOM (first block of the render,
  y picked with the colour scheme) → full-screen (238,195)/(238,301).

### Colour model (entry block + per-bar `FUN_004ac740` colour copies)

Two colours seed the whole panel: `active=TOP → {A=0xffffff, B=0} else
{A=0, B=0xffffff}` (A at esp+0x14, B at esp+0x10). Net effect, verified
against orig/07 pixels:

- **Active-manager side**: bar fills BLACK at alpha **100/256** over the
  circle marble (sampled (46,69,82)/(60,80,100)), frames WHITE (opaque),
  text WHITE.
- **Other side**: fills WHITE at 100/256 (sampled (160,180,200)/(192,192,192)),
  frames BLACK, text BLACK.
- Fill = `FUN_0043ce50(rect,colour,100)` → alpha-blend when arg ≤ 0xff
  (`FUN_0043ce80` → `FUN_005d4910`); frame = `FUN_00468c90(rect,colour,0x100)`
  (opaque outline). So the marble mottle shows THROUGH every bar — bars are
  translucent tints, not solid boxes.

### Fonts (per draw order inside the render)

1. **Club names**: drawn FIRST with the surface's standing font =
   **PROMAN12** — confirmed by ink: PROMAN12 renders "Aston Villa" (85px
   advance-sum, 84px ink) and "Bolton W" (73/72) PIXEL-IDENTICAL to orig/07
   rows 231-239 (caps rows 1-9 of the 13px glyph grid, single strike — the
   boldness is the face; no double-strike needed).
2. **Manager names**: `set_font("Calend12")` (0x653ce0) at 0x549805 —
   ink-confirmed ("Gregory" witnessed 40px = Calend12 41-1).
3. **Chips**: `set_font("ProMan8")` (0x658928) at 0x54991b — "CPU"/"PL 1"
   witnessed 7px caps.

("Indust18" (0x65e25c) is set at 0x546a6b on the SCREEN object, not this
widget — it is NOT the club-band face.)

### Nation flags (outside this function) — MEASURED AND BUILT 2026-07-28

Witnessed above/below the circle only when the two clubs' NATIONS differ
(Swansea↔Brighton: Wales/England, pro/13; Barcelona↔Man Utd: Spain/England,
walkthrough 001_160008; all-England fixtures show none — orig/07/73/78).
Drawn by a sibling widget, still not decoded — but the ART and the RECTS are
now settled from the game's own files rather than estimated:

* the sprite is `DBDAT\BANDERAS\ba96%04u.bmp` (`0x654a94`), and every one of
  `BANDERAS.PKF`'s 127 entries decodes **30x20**;
* on `001_160008` the flags land at **(308,143)** and **(308,355)** — and the
  port's own `flag_022` (Spain) and `flag_030` (England) reproduce that frame at
  **0 differing pixels** in both rects (`tools/re/diff_hub_circle_parity.py`).
  The earlier "~55x35 at ~(295,138)/(295,348)" estimate is superseded.
* TOP carries the HOME side's nation, BOTTOM the AWAY side's — the same
  home/away rule the bars follow.

Manager-League domestic careers still never show them.

## App implications (charter #2, hub geometry+content)

- Stack top→bottom = chip / manager / club (HOME side), then club / manager /
  chip (AWAY side) — mirrored around the centre. Own side = wherever the
  career club plays that fixture.
- Chip: "PL 1" for the player club (single-player careers are always player
  1), "CPU" for CPU clubs. NEVER league position, week, or level.
- CPU manager bar shows the DB manager surname; app source =
  `app/data/real_managers_1997.json` (witnessed-only); clubs with no
  witnessed name stay honestly blank pending a DB-table extraction.
- The old app "AWAY"/"HOME" chip fallback and "PL <table rank>" are refuted;
  gone with the 07-17 hub rebuild.
- Club band = proman12 single-strike; manager bars calend12; chips proman8.

## Method (reproducible)

- Strings: `strings -n 2 -t x MANAGER.EXE` ("CPU" file 0x25c920 → VA
  0x65e320; "PL " 0x25c924 → 0x65e324; "%ld" → 0x652f00; fonts as above).
- Refs: headless Ghidra 12.1.2 `~/ghidra-projects/pm98 -process MANAGER.EXE
  -readOnly` + FindRefsTo/DecompileAt/DumpAsm (tools/re/ghidra_scripts);
  DecompileAt force-creates the undefined-region function at 0x549240.
  Remember `-process MANAGER.EXE` (headless defaults to dbasewin.exe).
- Raw disasm for the gaps: `objdump -D -b binary -m i386 -M intel
  --adjust-vma=0x400c00 --start-address=<VA>` on MANAGER.EXE.
- Ink checks: threshold-render the witnessed bars (parity-run orig/07) and
  diff against `Fnt` glyph grids from `tools/re/fnt_to_bmfont.py` over
  `.wineprefix/drive_c/PM98/WINFONTS/*.FNT`.

## Un-chased

- ~~The two-shirt kit-group bitmap asset~~ — CLOSED 2026-07-28: `NANOESC`, see above.
- The nation-flag sibling widget's own CODE (the asset, both rects and the
  differs-rule are closed above; what is not read is the function that draws it,
  so "differ" is still the witnessed rule rather than a decoded predicate).
- The DB manager-name table behind `[club+0x2c]` (full source-true manager
  list for all clubs; real_managers_1997.json covers witnessed ones only).
- ~~`FUN_005d4910` alpha-blend exactness~~ — SUPERSEDED 2026-07-28 by a
  measurement. A linear 100/256 RGB blend does NOT reproduce the bars: fitted
  against `RECURSOS.PKF` `FONDO3.BMP` (which IS this screen's background, circle
  marble and rim included) the best alpha is 96..106 but only ~50 % of non-ink
  pixels come out right even after snapping to MANAGER.PAL. The result is
  instead an exact function of **(destination FONDO3 palette INDEX, (x+y)&1)** —
  a 50/50 checkerboard on ABSOLUTE screen coordinates, the same rule
  [`shadow_blit_re.md`](shadow_blit_re.md) found in `FUN_005d5220`. Held to
  **100.00 %** on the chip and manager bars across 179 hub frames; the club bars
  keep a small residual that is the club name's own drop shadow. The table is
  learned and applied by `tools/re/build_menu_bg_from_ref.py`; what is still not
  read is `FUN_005d4910` ITSELF, i.e. WHY the pair is what it is.

Evidence: tools/re/diff_hub_circle_parity.py, tools/re/build_menu_bg_from_ref.py, app/scenes/MenuScreen.gd, app/tests/test_menu_screen.gd
