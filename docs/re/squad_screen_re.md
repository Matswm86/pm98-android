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
