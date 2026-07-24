# LINE-UP (ALINEACIÓN) screen — reversed layout from MANAGER.EXE

> **SWAP DISPATCH WITNESSED 2026-07-24** — a SUBSTITUTE selected against a RESERVE
> exchanges their rows, and only the RESERVES section scrolls. See
> [`transfer_loop_live_re.md`](transfer_loop_live_re.md) §3.

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

## 2026-07-04 — frame-baked BODY parity pass (lineup_155 FULL FRAME 0px)

Binding frame 155_162931 + witnesses 003/128/131/160; bake =
`tools/re/build_lineup_chrome_from_frames.py` (entry-flow doctrine). Everything
below is frame-measured/asserted; the old "Build mapping" reconstruction above
is superseded by `app/scenes/LineupScreen.gd`'s baked pipeline.

- **Row grid**: 16px units from y87 (sep / 12px fill / sep / 2px white); XI fill
  tops y88+16i; SUBSTITUTES white band y263..285 (23px, ball + label baked as
  `band_subs.png`), subs y287+16j; RESERVES band y366..387 (22px); res y389+16k.
  Table borders x7-8/x463-464, y67-68/y465-466; column header band y69..86 is
  STATIC across modes/frames/runs (asserted; stays in chrome).
- **Tints**: XI rows tint by FORMATION-SLOT band (FUN_004fe2d0, = TACTICS);
  SUBSTITUTES rows are UNIFORM (212,223,255), RESERVES UNIFORM (180,200,220)
  with sep colours (120,120,160)/(100,120,140); XI seps (128,128,128). Card
  icons FICHATIT/FICHACONV/FICHANOCONV per tier (baked in the row templates).
- **RATING rows**: STARJUGON strip at x172+14j (glyph top fill+1), odd half =
  STARJUGON-OFF (same pair as TACTICS); fine-role SHORT name (ProMan8, ink
  100,120,140) right-aligned to the x349 sep; AV ProMan8 red GDI-centred in
  (351,22); CAMROL 25x14 at x374; POS word GDI-centred in (401,34) on the tint.
  The SHORT-role table is code-embedded (pushes at 0x567d35..0x567da8):
  KEEPER / RIGHT BACK / LEFT BACK / SWEEPER / INS. CENT. LEFT / INS. CENT.
  RIGHT / RIGHT MID. / INSIDE RIGHT / CENTRE FORWARD / CENTRAL MID. / LEFT
  MID. / RIGHT WINGER / CENTRAL STRIKER / LEFT WINGER / DEF. MIDFIELDER /
  RIGHT FORWARD / LEFT FORWARD / INSIDE LEFT (14 of 18 frame-witnessed).
- **PARAMETERS rows** (witness 128; PARITY PAIR `lineup_128` 0px 2026-07-06):
  grey sep cols x173..323 step 25; values GDI-centred per cell; inks
  EN (150,0,0), SP/ST/AG/GU (100,100,140), FI (42,95,170), MO (80,110,5).
  **Value sources pinned off `FUN_004f5260`'s numeric arm** (decompile in
  docs/re/lineup/): EN = the `+0xa8` dynamic byte (99 across the board — NOT
  the stored EN attr) · SP/ST/AG/QU = `+0x9c..+0x9f` = game_db VE/RE/AG/CA ·
  FI = `+0xa7` · MO = `FUN_00582db0` · AV = `FUN_00581e60`. The 128 pair is
  FORMULA-DRIVEN: only the frame's FI/MO dynamics are staged; AV (20/20) and
  TEAM RATING 82 (= 910/11) come out of the live rules (morale_re.md).
  Frame 128's formation = 4-4-2 (row tints D,D,D,D/M,M,M,F,M,F = the 4-4-2
  slot bands; run 2 later plays 3-5-2). Both toggle plates walked (155
  RATING-on / 128 PARAM-on) + the dark-red arrow beside the ACTIVE toggle;
  the plate cuts include the 2px active-surround bottom rows y91..92/y114..115
  (a 68:91/92:115 cut leaves rows 91/115 stuck in the 155 chrome state).
- **INJURED row** (Beckham, 7 weeks): gold tint (212,191,85) + 1px black frame
  (both in `row_inj.png`); cells [cross|count(yellow)|WEEKS(black)|FI navy|MO
  green]; "DAYS"/"DAY"/"WEEK(S)" strings live beside the role table.
- **SELECTED row** (Solskjaer): 2px black frame at x28-29/x437-438,
  y fill-2..fill+13, drawn over the normal template.
- **UNDO rule**: T/I/S is the default (003/128/131 — 131 is SELECTED and still
  shows T/I/S); UNDO replaces the block iff a PENDING CHANGE exists — an XI
  edit this visit (160) or an injured starter still in the XI (155).
- **Coverage zone**: selecting a player dims his slot's coverage rect on the
  CAMPO — rect = slot raw fields [0..3] as (x0,y0,w,h) through the marker map
  `(4 + x*148/318, 3 + y*88/198)` (155 slot9 + 156 slot5 + 131 4-4-2 slot6 all
  fit). The dim is a positional NOISE dither (no colour/Bayer LUT fits) —
  walked zones ship as verbatim patches (`zone_352_9/352_5/442_6.png`);
  un-walked zones use a majority-vote LUT (documented approximation).
- **Markers**: DVERDE disc + AVERDE arrow per slot at raw[4..7] through the
  same map; the SELECTED slot draws DBLANCO/ABLANCO on top of the zone,
  undimmed; greens inside a zone dim WITH it. Bake recomposes 155's pitch to
  0px. One palette index decodes (192,227,192) under MANAGER.PAL but renders
  (192,220,192) on this screen (sprites + campo patched to frame truth).
- **Right panel**: TEAM RATING strip stars = STAREQON with an engine shadow
  ring rendered through the noise dither — position-deterministic, so walked
  per-cell PATCHES ship (`star_eq_full_0..3/half/nude.png`, x512+15j y133);
  value = ProMan10 right-aligned at x613 (ink 160,160,200). Name band =
  ProMan10 white GDI-centred in (478,152), text top y158. Attr buttons: values
  = attrs PO/PA/RM/RG/EN/TI verbatim (Solskjaer 11/72/84/81/66/79 = frame),
  ProMan8 (42,95,170) GDI-centred in (col+47,31); stars = STARPARON(-OFF) at
  col+10j, top btn+12, with the same noise shadow — walked strips ship
  verbatim per halves-signature (`attr_stars_0..5.png`), un-walked counts draw
  plain glyphs (documented).
- **Scrollbar**: fully static across walked frames (scroll 0): DOWN box =
  ARROWDOWNOFF verbatim at (443,434); the UP box is a composed at-limit look
  (frame-cut `scroll_up_limit.png`); thumb/track cut for un-walked scrolls.
- **Bench/reserve order** is save-stored (team+0x1930/0x1934) — the club dict
  may pin `bench`/`reserves` pid arrays (the parity shot does); the app
  default derives them by ability.
