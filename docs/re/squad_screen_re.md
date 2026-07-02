# SQUAD MANAGEMENT (PLANTILLA) screen — reversed layout from MANAGER.EXE

640×480 pixels, lifted from `FUN_00552110` (decompile: `docs/re/squad/fn_00552110_*.c`).
Anchored on the string `"SQUAD MANAGEMENT"` @ `.data 0x65f098` (pushed at the screen
draw). Geometry via `CRect::CRect(left,top,right,bottom)` and the `FUN_00436fb0/fd0`
`makeRect(pos,size)` helpers already documented in `lineup_screen_re.md`.

## Reversed elements
- **Title** `"SQUAD MANAGEMENT"`: `CRect(0x96,0x10,0x1bf,0x2b)` = (150,16,447,43), font
  `ProMan14` (`s_ProMan14_00656830`).
- **Squad list panel** (`FUN_004f50c0` widget): rect `{8, 0x48, 0x204, 0x1d5}` =
  (8,72)..(516,469). Player rows 16px tall (`0x10`), row width `0x1d2`=466, drawn
  relative to the list widget at `param_1+0x1928`; the squad is iterated in **4
  sections** (loop over the table at `0x634e28`, 4 entries — each yields a per-group
  player count). Section headers + the per-cell values are filled by the grid widget.
- **"YOUTH TEAM"** button: `CRect(0x20b,0x168,0x27b,0x181)` = (523,360)..(635,385),
  loads `recursos\iconos\plantilla\juveniles.bmp`. (`"YOUTH TEAM"` @ `0x65d428`.)
- **Info box** bottom-right: `CRect(0x213,0x1b8,0x271,0x1d1)` = (531,440)..(625,465).
- Help topic `INFOFUT\if5mapla.htm`; fonts also `ProMan12`/`ProMan10`/`ProMan8`.

## Build mapping (→ `app/scenes/SquadScreen.gd`)
- Title at (150,16) ProMan14; FONDO marble + BARRA bar; manager/club chrome.
- Full-width list at the reversed panel bounds, 16px rows; per-attribute columns reuse
  the player-grid codes proven on the line-up screen (`N. PLAYER … EN SP ST AG QU FI
  MO AV POS`) since it is the same grid framework. The original's 4-section split is
  position-based; the demarcación byte is now decoded out of EQUIPOS.PKF
  (`docs/re/positions_re.md`), so we section by the **4 real position groups** with the
  original's own band labels — **KEEPERS / DEFENDERS / MIDFIELDERS / FORWARDS** (the
  4-entry table at `0x634e28`) — each sorted by ability. Row height compresses just
  enough to keep a deep squad's forwards on-panel (the original paged; we fit all).
- Right column: squad count, the reversed YOUTH TEAM button (placeholder — youth not
  built), RETURN. Driven live by the Career roster.

## True columns (walkthrough evidence, run-1 frame `077_154612`) — PORTED 2026-07-02
The real SQUAD MANAGEMENT is a **contract** view, not an attribute grid. Columns:
**N° | PLAYER | AV | MO | LOAN | WAGE | YEARS** — the SquadScreen refit now draws them
at the frame's measured geometry (border scan: cells AV 273-298 | MO 298-323 | LOAN
323-359 | WAGE 359-429 | YEARS 429-454 | 454-479; N° box 16-46; boxed 13px rows at
16px pitch) with the frame-sampled colours: N° navy `(0,0,128)`, section labels blue
`(0,0,190)`, AV `(212,63,0)`, MO `(75,109,172)`, LOAN olive `(100,130,10)`, WAGE
`(150,0,0)`, YEARS `(42,63,170)`; an expiring contract's remaining-year cell = red
`(255,31,0)` on yellow `(255,255,170)`. Each column CODE in the header row is drawn in
its own value colour, and the first section's label lives in that header row.
- **N°** = the decoded per-player squad number (`squadNo`, byte after the photo-id u16
  — `squad_number_re.md`); `-` when the club's stored set isn't individuated.
- **AV** = `_avg_of`; **LOAN** = YES/NO off `on_loan`; **WAGE** = `Contract.yearly(
  current_weekly)` formatted `£1,000,000`; **YEARS** = `contract_term | contract_years`
  (term | left, both stamped by Career; `-` for a bare GameDB browse club).
- **MO** stays an honest `-` — morale is a dynamic save value with no app model yet
  (do NOT show the unrelated static RM attribute). APP_VS_SPEC_AUDIT B7.
- **Row order** = reverse record order per section (decoded, `squad_number_re.md`);
  the ability sort is gone. Row-height compression for deep squads remains our one
  documented deviation (the original pages/scrolls per section).
Wired to the hub PLAYERS button (Main `_show_squad_screen`) 2026-07-02.
