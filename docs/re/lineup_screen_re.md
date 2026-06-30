# LINE-UP (ALINEACIÓN) screen — reversed layout from MANAGER.EXE

All coordinates are **640×480 screen pixels**, lifted from the binary (not guessed).
The game text is English (`LINE-UP`, `RESERVES`, `SUBSTITUTES`, the `N./EN/SP/...`
column codes are the literal strings in `.data`). Decompiled C dumps:
`docs/re/lineup/fn_004fc321_*.c` (screen draw) and `fn_004fe860_*.c` (squad-list
header draw). Geometry helpers `FUN_00436fb0/fd0` decoded below.

## Geometry helper semantics (VERIFIED)
- `FUN_00436fb0(pt, x, y)` → `pt = (x, y)`  (a CPoint/CSize setter).
- `FUN_00436fd0(out, pos, size)` → `out = CRect(pos.x, pos.y, pos.x+size.x, pos.y+size.y)`.
  So every `makeRect(pos, size)` below means **left=pos.x, top=pos.y, w=size.x, h=size.y**.
- `FUN_00437020(r,g,b)` sets the next text colour; `FUN_005d9d30(rgb)` applies it.
- Text draw: `FUN_005d9d80(text,left,top,right,bottom,flags)` (normal) /
  `FUN_005da180(...,1)` (highlighted — selected when `*(team+0x144) >> 3 & 1`).
  `FUN_004ca3c0(text, rect.0..3, flags)` is the pos+size variant.

## Squad-list header row (`FUN_004fe860`, y = 5, height 12)
Columns by left-x (the literal `.data` strings):

| col | string | left | right |
|-----|--------|------|-------|
| number   | `N.`     | 25  | 48  |
| name      | `PLAYER` | 63  | 151 |
| energy    | `EN`     | 166 | 191 |
| speed     | `SP`     | 191 | 216 |
| stamina   | `ST`     | 216 | 241 |
| aggression| `AG`     | 240 | 265 |
| quality   | `QU`     | 266 | 291 |
| finishing | `FI`     | 293 | 318 |
| morale    | `MO`     | 317 | 342 |
| average   | `AV`     | 342 | 367 |
| role      | `ROL`    | 364 | 396 |
| position  | `POS`    | 394 | 428 |

(`EN/SP/ST/AG/QU/FI/MO/AV` = the 8 attribute columns; the 2-letter codes are the
game's own. Section labels `SUBSTITUTES` @ (103,204) and `RESERVES` @ (104, dynamic).)

## Player rows (`FUN_004fc321`)
- **Starting XI**: loop `i = 0x15; i < 0xc5; i += 0x10` → **11 rows**. Each row rect
  `makeRect(pos=(21, i-2), size=(411,16))`. First row top ≈ y17, step 16 → XI occupies
  y≈17..177.
- **Substitutes**: header `SUBSTITUTES` @ y204; rows from y≈220 (`i=0xdc`, step 16),
  count `team+0x1930`.
- **Reserves**: header `RESERVES` below subs; rows from `(subs+0xf)*16`, count `team+0x1934`.
- Scroll arrows loaded from `recursos\iconos\arrowupoff/on.bmp`, `arrowdownoff/on.bmp`.

## Pitch (right side) + formation markers
- Pitch **panel** widget (`team+0x4c18`): `makeRect(pos=(476,155), size=(156,187))`
  → on-screen rect **x 476..632, y 155..342**. Loads `recursos\iconos\alineacion\campo.bmp`.
- The marker sub-pitch (`team+0x1c4b4`) is a child at `makeRect(pos=(6,96), size=(148,88))`
  i.e. relative to the panel → absolute ≈ **(482, 251), interior 148×88** (the small
  landscape `CAMPO.BMP`, 152×92, lives here; the panel's upper ~96px is the header strip).
- **Marker placement** (per player, marker size 10×10):
  `marker = ( pitch.x + tac_x * 148/318 , pitch.y + tac_y * 88/198 )`
  where the player's tactical `(tac_x, tac_y)` live in a **318×198** design space
  (`puVar10[6], puVar10[7]`). Two marker passes (home shirt + a second overlay).
- `recursos\iconos\alineacion\balon.bmp` (ball) and `flecha.bmp` (formation arrow) also blit.

## Build mapping (→ `app/scenes/LineupScreen.gd`)
- Native 640×480, FONDO marble bg + BARRA bar + `LINE-UP` title (same chrome as the
  league table screen).
- Left: squad list at the exact column x's above; XI rows x21/w411/h16 from y17; the
  attribute columns show the player's decoded attrs; SUBSTITUTES / RESERVES sections.
- Right: the small landscape `CAMPO` at ≈(482,251) 148×88 (scaled), with 11 kit/dot
  markers placed by the `*148/318, *88/198` mapping. Formation `(tac_x,tac_y)` per slot
  defined per Tactics.gd formation in the 318×198 space.
- Driven live by `Career` roster + `Tactics` XI/formation.

## XI editing — select-then-swap (the line-up edit interaction)
SOURCED from the binary:
- **Three squad tiers.** `FUN_004fc321` partitions the squad into a fixed **11-slot XI**
  (the draw loop `i=0x15; i<0xc5; i+=0x10`), a **SUBSTITUTES** list whose count is at
  `team+0x1930`, and a **RESERVES** list whose count is at `team+0x1934`. Each XI slot
  carries a formation `(tac_x,tac_y)` (drawn `*0x94/0x13e, *0x58/0xc6` onto the CAMPO).
- **A selected/highlighted player.** The squad-text draw chooses the highlighted glyph path
  (`FUN_005da180`, vs normal `FUN_005d9d80`) when the per-row selected bit is set
  (`*(team+0x144) >> 3 & 1`), i.e. the screen tracks one selected player and draws his row
  highlighted. This is the visual half of a select-then-act edit.

RECONSTRUCTED (faithful to the above; the click→swap dispatch function itself is **not yet
located** in the decompiles — a known gap to pin down, NOT an invented dialog): PM98's
line-up edit is **tap a player to select (highlight), tap a second to swap them**. Because
the XI is a fixed slot list, the edit primitive is "put player P into slot S, swapping P
out of his old slot if he already had one" — exactly `Tactics.assign(slot, pid)`. So a
bench tap onto an XI slot subs that player on (the displaced man drops out of the XI and
reappears under SUBSTITUTES, which is the derived "not in xi" set); an XI↔XI tap exchanges
two slots/roles. The **GK slot only accepts a keeper** (and a keeper only the GK slot),
enforced by `Tactics.validate`'s role check, so a swap that would break it is rejected.

## Build mapping (→ `app/scenes/LineupScreen.gd`, XI editor)
- `_row_at(d)` hit-tests a design-space point to a flat-list row (mirrors `_draw_squad`'s
  scroll window); `_hit` returns `"row:<i>"` for it (after the RETURN/TACTICS/arrow checks).
- `_tap_row` holds `_sel_pid`: first tap selects, a second tap calls `_try_swap`, a tap on
  the already-selected player deselects. `_swap_legal` enforces the GK rule; on a legal swap
  `Tactics.assign` mutates the live XI and the screen emits `xi_changed` → Main persists via
  `_save_tactics` + `Career.save()`. Selected row drawn highlighted (gold tint + border).
- Tests: `app/tests/test_lineup_xi.gd` (23 assertions: sub-on, XI↔XI, GK guard accept+reject,
  deselect, bench↔bench, signal, synthetic `_hit`/`_on_input` round-trip).
