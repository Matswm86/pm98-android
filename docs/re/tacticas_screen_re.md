# TACTICS (TACTICAS) screen — reversed from MANAGER.EXE

The full TACTICS board, reached from the LINE-UP screen's `TACTICS` button
(frame `013_162412` → `014_162413`). Distinct from the **TEAM TACTICS** modal
(ma_9, `TacticsScreen.gd` = the ATTACK|DEFENCE panel): this is the outer screen
titled just `TACTICS %s` (club name) that shows the XI with ROLE/POS columns, a
skill-emphasis grid, and the big pitch with the formation's two-phase markers.

Binding frame: `screenshots/original-walkthrough-2026-07-02/014_162413.png`
(Man Utd, 3-5-2). Builder: `FUN_00568800` (entry `0x568800`; the auto-analyzer
mis-splits it as `FUN_00568a3d`). Predef overlay: `FUN_0056f4c0`. Predef repaint
(re-lays the markers on pick): `FUN_0056ac90`. Team-tactics modal spawn from the
`TEAM TACTICS` button here: `FUN_0056ea15`. All coords 640x480 px, lifted by the
same push-tracking method / widget helper chain as `lineup_screen_re.md` and
`rival_screen_re.md` (`fb0(w,h)=CSize ; fb0(x,y)=CPoint ; fd0(pos,size)=CRect ;
(*+0xc0)=create`).

## Widget rectangles (VERIFIED via push-tracking disasm of FUN_00568800)
| element | string / bmp @VA | pos (x,y) | size (w,h) | rect |
|---|---|---|---|---|
| title | `TACTICS %s` @0x66164c | (150,16) | (297,27) | shared chrome title bar |
| PREDEF. TACTICS | `PREDEF. TACTICS.` @0x66151c + `predef.bmp` | (7,373) | (156,29) | 7..163, 373..402 |
| LOAD TACTICS | `LOAD TACTICS` @0x6614e8 + `carga.bmp` | (7,407) | (156,29) | 7..163, 407..436 |
| SAVE TACTICS | `SAVE TACTICS` @0x6614d8 + `grabar.bmp` | (7,443) | (156,29) | 7..163, 443..472 |
| PARAM. | `PARAM.` @0x65f7b4 | (478,286) | (72,23) | 478..550, 286..309 |
| RATING | `RATING` @0x654fa8 | (558,286) | (72,23) | 558..630, 286..309 |
| TEAM TACTICS | `TEAM TACTICS` @0x6614a4 + `equipo.bmp` | (478,330) | (152,25) | 478..630, 330..355 |
| VIEW RIVAL | `VIEW RIVAL` @0x661498 + `verrival.bmp` | (478,365) | (152,25) | 478..630, 365..390 |
| LINE-UP | `LINE-UP` @0x656334 + `ali.bmp` | (478,400) | (152,25) | 478..630, 400..425 |
| RETURN | `RETURN` @0x6549e4 | (498,440) | (112,25) | 498..610, 440..465 |
| skill grid | HANDLING..SHOOTING | (7,275) | (156,91) | 7..163, 275..366 |
| pitch title bar (`TACTICS 3-5-2`) | (dynamic) | (177,275) | (278,30) | 177..455, 275..305 |
| CAMPO pitch | `tacticas\campo.bmp` (152x92, stretched) | (177,305) | (278,167) | 177..455, 305..472 |
| marker layer (child of pitch) | — | rel (10,5) | (258,154) | abs origin (187,310) |

The XI **table** (top-left below the chrome) is built by the same
`FUN_004f4db0 / FUN_004f4b00 / FUN_00465d90` squad-table helpers as LINE-UP
(control `param+0x3e00/0x46b8/0x41f4`). Columns: `N. | PLAYER | EN SP ST AG QU FI
MO | AV | ROLE | POS` — but unlike LINE-UP it shows the **full fine-role name** in
the ROLE column (`GOALKEEPER / RIGHT BACK / INSIDE CENTRE LEFT / CENTRAL MIDFIELDER
/ CENTRE FORWARD / LEFT FORWARD …` = the LONG table at `0x662db0`, indexed by
`posFine`, see `positions_re.md`) and a left-pointing `flecha.bmp` arrow before the
broad `POS` code (`GOAL/DEF/MID/FOR`). Only the 11 starters are listed (no
SUBSTITUTES/RESERVES sections). `ROL.BMP` is the ROLE-column header glyph.

## PARAM. / RATING toggle (bit `0x8` of `+0x144`)
The two top-right buttons flip the stat columns between the numeric **PARAMETERS**
view and the star **RATING** view (frame 014 has RATING active → EN..MO render as
`STARPARON.BMP` filled / `STARPARON-OFF.BMP` empty star strips; AV stays numeric).
The same `+0x144` flag family gates every label in the TEAM TACTICS modal builder
`FUN_0056ea15`.

## The pitch: two-phase formation markers (VERIFIED, the defining data)
`recursos\iconos\tacticas\campo.bmp` (152x92) is stretched into the 278x167 pitch
control; markers overlay the 258x154 child layer at offset (10,5). Each of the 11
formation slots draws **two** markers from the coordinate table `DAT_00660240`
(10 formations x 11 slots x 8 int32):
- **Primary (defensive phase)** — fields `[4],[5]` → a green **disc** `dverde.bmp`.
- **Secondary (attacking phase)** — fields `[6],[7]` → a green movement **arrow**
  (`fleul/fleur/fledl/fledr.bmp` chosen by the sign of the primary→secondary delta;
  `averde.bmp` is the horizontal variant).

Mapping (both `FUN_00568800` and `FUN_0056ac90`):
`mx = raw*258/318 , my = raw*154/198`. The disc carries the player's shirt number
(`sprintf("%u", player+0xf8)`, ProMan8). In frame 014 (3-5-2) this places the
discs on the own half and the arrows fanning toward the opponent goal — reproduced
exactly by our bake (discs at mk1 left, arrows at mk2 right).

Slot ordering: rows 0..9 = the ten outfield slots, **row 10 = the goalkeeper**
(parked at marker (0,68) = far-left centre in 9 of 10 formations; 3-3-3-1's 11th row
is a degenerate sentinel `(1,900,900,0…)`). Baked with an explicit `gk_slot` field.

## PREDEF overlay (FUN_0056f4c0) — the 10-formation picker
Tapping PREDEF opens a centred child window (`0x1c3 x 0xfa` = 451x250 body) titled
by `predefw*.bmp`, holding a **5-col x 2-row** grid of the 10 formation thumbnails
+ a `CANCEL` button (`0x6578f8`, at rel (0xaa,0xda)=(170,218) size (0x6e,0x19)).
Thumbnail k sits at `x = (k%5)*0x50 + 0x18`, `y = (k>4)*0x64 + 0x23`, size
`0x50 x (0x4b + (k<5 ? 0x10 : 0))` — i.e. two rows of five. Names come from the
pointer table `0x6601f8`: **3-4-3, 3-5-2, 4-3-3, 4-4-2, 5-3-2, 5-4-1, 4-2-4,
5-2-3, 4-5-1, 3-3-3-1** (verbatim). Picking one copies that formation's 11 slot
rows into the live XI structs and repaints the pitch via `FUN_0056ac90`.

## Baked assets (this pass)
- `tools/re/export_formations.py` → `app/data/formations.json` (10 formations,
  slot mk1/mk2 + gk_slot, from DAT_00660240).
- `tools/re/export_icons.py` TACTICAS block → `app/art/icons/tacticas/*.png`
  (predef, grabar, verrival, equipo, ali, rol, flecha, star_on/off, mk_disc,
  mk_arrow, fle_ul/ur/dl/dr).
- Big pitch reuses the already-baked `app/art/screens/campo.png` (= the same
  152x92 `tacticas\campo.bmp`).

## App mapping (→ `app/scenes/TacticsBoardScreen.gd`)
Native 640x480, scales to fit (same transform as LINE-UP/RIVAL). Reached from the
LINE-UP `TACTICS` button (previously that button opened the TEAM TACTICS modal
directly; now it opens this board, whose own `TEAM TACTICS` button opens the
modal). Buttons wire to: PREDEF → the 10-formation picker overlay (sets
`Tactics.formation`); LOAD/SAVE → the existing `_load_tactics`/`_save_tactics`;
TEAM TACTICS → `TacticsScreen` modal; VIEW RIVAL → `RivalScreen`; LINE-UP → back
to `LineupScreen`; RETURN → hub. PARAM./RATING toggles the stat columns.

## Honest gaps (documented, not faked)
- **Per-slot ROLE reassignment arrow un-wired.** PM98's `flecha`/`flerol` arrow in
  the POS column lets the manager re-cast a player's role within the formation; the
  app has no per-slot role-override model (the match engine reads `posFine` from the
  player DB, not a tactics override), so the arrow is drawn faithfully but read-only
  — same doctrine as the deferred MO/morale and FICHA RATING gaps. The formation
  *shape* (PREDEF) is fully wired.
- **Formation model widened.** `Tactics.gd` shipped only 4 formations
  (5-3-2/4-4-2/4-3-3/3-5-2) with an invented lerp-grid pitch layout; the board's
  pitch now uses the real 10-formation `formations.json` coordinates. The 6 new
  shapes (3-4-3, 5-4-1, 4-2-4, 5-2-3, 4-5-1, 3-3-3-1) are selectable via PREDEF and
  drive the pitch display; the att/def ratings weighting for the new shapes reuses
  the nearest modelled factor (documented in `Tactics.gd`).
- **Skill-emphasis grid** (HANDLING/PASSING/DRIBBLING/HEADING/TACKLING/SHOOTING) is
  rendered as the frame shows; in the original it filters which attribute the star
  column reflects — wired as a display toggle over the RATING columns only.
