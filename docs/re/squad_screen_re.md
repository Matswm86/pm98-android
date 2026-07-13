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
- **AV** = `Morale.av6` (the real `FUN_00581e60` rating — morale_re.md) when the
  squad carries form, else `_avg_of` for a bare GameDB browse club; **LOAN** =
  YES/NO off `on_loan`; **WAGE** = `Contract.yearly(current_weekly)` formatted
  `£1,000,000`; **YEARS** = `contract_term | contract_years`
  (term | left, both stamped by Career; `-` for a bare GameDB browse club).
- **MO** = `Morale.display` when form exists, else an honest `-` (morale is a
  dynamic save value — morale_re.md; do NOT show the unrelated static RM
  attribute). APP_VS_SPEC_AUDIT B7.
- **Row order** = reverse record order per section (decoded, `squad_number_re.md`);
  the ability sort is gone. Row-height compression for deep squads remains our one
  documented deviation (the original pages/scrolls per section).
Wired to the hub PLAYERS button (Main `_show_squad_screen`) 2026-07-02.

## Frame-baked rebuild — REBUILT 2026-07-13 (supersedes the "Build mapping" above)
The chrome is now the real frame VERBATIM, not hand-drawn (RivalScreen/LineupScreen
header-rollout doctrine). `tools/re/build_squad_chrome_from_frames.py` cuts frame
`077_154612` into two assets under `app/art/screens/squad/`, every measured invariant
asserted so a bad crop fails loudly (re-run is deterministic — byte-identical output):
- **chrome.png** 640×418 = frame body y62..479 VERBATIM: blue-marble FONDO, white boxed
  table panel, the `N° KEEPERS AV MO LOAN WAGE YEARS` column-header row (each code in its
  value colour, KEEPERS baked inline as the frame lists it), the per-section scrollbar and
  the YOUTH TEAM + RETURN buttons — only the player-row grid cleared to panel white.
- **title_squad.png** = the frame's own `SQUAD MANAGEMENT` grey-emboss glyphs composited
  over `header/band.png` (the band ghost interpolated out) so it blits seamlessly over the
  live header.
`SquadScreen.gd` paints ONLY the dynamic layer: the shared SILVER header via
`PMChrome.draw_match_header` (the SAME header LINE-UP / VIEW RIVAL validated 0px against),
the title sprite, chrome.png over `BODY_Y0=62`, then the DEFENDERS/MIDFIELDERS/FORWARDS
section bands + per-cell player rows (grey-128 border, grey-240 fill, 16px pitch — the
frame's own structure) at the measured cell x-spans and frame-sampled inks. The OLD
invented chrome is GONE: the dark-navy `management_bg`, the blue title bar, the SQUAD-count
box and the club-kit (`_kit_tex`) right panel were never in the frame — the frame's right
column is the scrollbar + the two buttons. (The stale "Build mapping" bullets above — the
attribute-grid columns, the squad-count box, the placeholder YOUTH button — are retained
only as the pre-2026-07-02 history; the contract-view + frame-bake supersede them.)

### Divergences / honest gaps (frame-true vs app deviation)
- **Row-height compression** — the original pages/scrolls each section; we compress row
  pitch (11..16px) to fit a deep squad on one panel. The one intentional layout deviation.
- **Per-section scrollbar is baked static** (non-functional): a consequence of fitting all
  rows — nothing to scroll. The original's live per-section paging is not reproduced.
- **MO = `-` for a form-less club** (bare GameDB browse / the shot_screens demo fixture):
  morale is a dynamic save value, absent until a Career carries it. Honest gap, NOT the
  static RM attribute (APP_VS_SPEC_AUDIT B7). Real career rosters render the live MO.
- **N° = `-` for a pad club** (squad set not individuated): what the original engine
  displays for a `0x01`-pad squad is UNRESOLVED — no walkthrough frame of a pad club's
  SQUAD exists (`squad_number_re.md`). Individuated clubs (Man Utd et al.) show real N°.
- **AV for a form-less club** falls back to `_avg_of` (mean of 8 outfield attrs) rather than
  the real `FUN_00581e60` rating, which needs FITNESS/MORAL form. Career squads use the real
  formula (`Morale.av6`).
- **Header stays bright under the FICHA dim**: `draw_match_header` is not LUT-aware and
  PMChrome is out of this screen's edit scope; the body + rows dim through the exact alert
  LUT, the silver header does not. Documented PMChrome gap.
- **Demo/synthetic render** (`squad_demo.png`, Arsenal fixture) shows the layout frame-true
  but with synthetic values (MO `-`, form-less AV); it is a chrome/layout witness, not a
  data-parity capture. The data-level frame truth is asserted at BAKE time against frame 077
  (header codes, cell separators, AV/WAGE/YEARS colours, the expiring yellow LEFT-cell).
