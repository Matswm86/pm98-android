# VIEW RIVAL (VERRIVAL) screen — reversed layout from MANAGER.EXE

The OPPONENT-scouting screen. Reached from the MANAGER MENU "OPPONENT" (RIVAL) icon and
from TACTICS -> VIEW RIVAL (`recursos\iconos\tacticas\verrival.bmp`, string "VIEW RIVAL"
@0x661498). Its own art folder is `RECURSOS\ICONOS\VERRIVAL` (asistente/bola/flecha).
Decompiled builder: `docs/re/verrival/fn_005733d0_FUN_005733d0.c` (entry 0x5733d0; a
`FUN_005736f2` sibling is the repaint of the same object). All coords are 640x480 px,
lifted from the binary via the widget chain `fb0(w,h)=size ; fb0(x,y)=pos ; fd0(pos,size)
-> CRect(x,y,x+w,y+h) ; (*(this+0xc0))()=create` (same helpers as the LINE-UP screen,
`lineup_screen_re.md`).

## Widget rectangles (VERIFIED via push-tracking disasm of FUN_005733d0)
| element | string | pos (x,y) | size (w,h) | rect |
|---|---|---|---|---|
| title | `VIEW RIVAL` @0x661498 | (150,16) | (297,27) | drawn by shared chrome title bar |
| PARAMETERS btn | `PARAMETERS` @0x658f5c | (492,85) | (134,21) | 492..626, 85..106 |
| RATING btn | `RATING` @0x654fa8 | (492,109) | (134,21) | 492..626, 109..130 |
| rival club-name box | (club name) | (481,155) | (154,18) | 481..635, 155..173 |
| crest + TEAM RATING | `equipo.bmp` + stars | (481,173) | (154,32) | 481..635, 173..205 |
| COMPUTER / mgr box | `COMPUTER` @0x653340 or rival mgr | (482,205) | (152,15) | 482..634, 205..220 |
| TACTICS btn | `TACTICS` @0x65632c | (508,395) | (112,25) | 508..620, 395..420 |
| RETURN btn | `RETURN` @0x6549e4 | (508,440) | (112,25) | 508..620, 440..465 |
| team-attr grid | HANDLING..SHOOTING | (9,297) | (156,91) | 9..165, 297..388 |
| ASSISTANT panel | `ASSISTANT` + asistente.bmp | (8,398) | (181,69) | 8..189, 398..467 |
| CAMPO pitch (big) | `tacticas\campo.bmp` | (196,300) | (278,167) | 196..474, 300..467 |
| marker layer (child of campo) | — | rel (10,5) | (258,154) | abs origin (206,305) |

The rival XI **table** (N. PLAYER EN SP ST AG QU FI MO AV ROL POS, 11 rows) fills the
top-left below the chrome (control `param_1+0x48bc`, populated by the same
FUN_004f4db0 / FUN_004f4b00 / FUN_00465d90 squad-table helpers as LINE-UP). Marker dots
map `(tac_x*258/318, tac_y*154/198)` onto the marker layer (design space 318x198), the
same mapping as LINE-UP scaled to the big pitch.

## The reveal gate — scouting depth scales with your ASSISTANT (VERIFIED, the defining rule)
`bVar2 = *(byte*)(manager.staff_slot[8] + 1)` where the staff slot table is
`FUN_0057cd70(mgr, 8)` = `*(mgr+0x264)[8]` (slot 8 = the ASSISTANT MANAGER; returns 0 when
empty). `bVar2` is the assistant's ability. The builder branches on it:
- **bVar2 == 0** (no assistant): the rival table is hidden and the message
  `"In order to find information about the rival team\n\nyou need to hire an Assistant."`
  (@0x661d20) is shown; NO pitch markers.
- **bVar2 >= 1**: rival XI table (names + attrs) + TEAM RATING shown.
- **bVar2 >= 5** (`if(4<bVar2)`): formation dots drawn on the pitch (primary phase).
- **bVar2 >= 7** (`if(6<bVar2)`): a second marker phase is added.
- **bVar2 >= 9** (`if(8<bVar2)`): the four formation arrows
  (`fleul/fleur/fledl/fledr.bmp`) + per-dot numbers.

The dot label is `sprintf("%u", *(byte*)(player+0xf8))` (the marker number), font ProMan8.

## BODY PARITY 2026-07-06 — rival_015 FULL FRAME 0px (frame-baked rebuild)

**`rival_015` vs `015_162415` = 0px, FULL FRAME, no exclusions** (was header-ROI
only). Bake: `tools/re/build_rival_chrome_from_frames.py` (assert-driven) →
`app/art/screens/rival/` + `rival_chrome_samples.json`. Binding frame 015
(Barcelona, run 2); witnesses 048 (pixel-exact dup of 015, asserted), 151
(Juventus, run 1 — everything static between the two stays in chrome), 152
(151 + RETURN hot). Frame-decoded truth:

- **Table = the LINE-UP squad-table control at +2px.** Borders x9-10/x472-473,
  y82-83/y284-285; header band y84..101 STATIC (chrome; the numeric column
  letters EN SP ST AG QU FI MO AV show in BOTH modes). 11 fixed row boxes at
  16px pitch (top sep y102+16i): sep / 12px (240,240,240) fill / sep / 2px
  white; grey box borders x31/x439; white margins x11..30, x440..471. Row
  cells (all ProMan8 @11, ink top fill+3): N. GDI-centred [35,+17) navy · name
  x69 black · STARJUGON x174+14j (halves=(AV+1) div 10, odd half = the DIMMED
  star; frame-asserted on all 22 row observations) · fine-role LONG name
  right-aligned x351 (100,120,140) · AV [353,+22) (210,0,0) · CAMROL 25x14 at
  x376 (black backing sep..sep; row icons == camrolNN sprites, asserted for
  the frame's 11 fine roles) · POS word [403,+34). One uniform row template
  (`row.png`, asserted identical across all 11 rows x both frames).
- **Right panel.** Club plate (481,155,154,18) = BLACK band, club name WHITE
  ProMan10 @10 GDI-centred, text rows y160..167 ("F.C." stays uppercase —
  PMChrome.title_case_name dotted-abbreviation rule). TEAM RATING strip:
  NANOESC 24x32 kit at (485,174) WITH the engine shadow pass (SELECCION/header
  precedent → walked club 1000 cut as `kit_1000.png`; live clubs = shadowless
  nano blit, documented); star cells x516+15j y186..204 on a noise-dither bg
  (walked 4-full cells cut as patches, cell 4 nude; un-walked counts fall back
  to plain STAREQON glyphs, documented); value ProMan10 @10 (160,160,200)
  right-aligned to x617, y_top 191. COMPUTER band static (a named rival
  manager overdraws it — un-walked). Toggles: PARAM nude + RATING active both
  walked RATING-side only; the flip re-uses the tactics-board doctrine
  (label-cleared plates + redrawn labels + arrow patches; `arrow_at_param` /
  `arrow_off_rating` are synthesized — un-walked). ASSISTANT band interior
  (117,147,187): name WHITE ProMan10 @10 x18, stars = STARPARON @ x125+11j
  y449 wrapped in a noise-dither shadow (walked 4-star strip cut verbatim;
  other counts plain glyphs, documented).
- **Pitch.** TACTICAS `CAMPO.BMP` 278x167 blitted 1:1 at (196,300); marker
  layer (206,305) 258x154. BRIGHT = the rival XI: DVERDE disc at mk1 + AVERDE
  arrow at mk2 per slot (discs first, arrows on top — the GK draws BOTH at the
  same spot, arrow covering; 014's "no arrow when mk1==mk2" does NOT hold
  here), shirt digits ProMan8 in **WHITE on both kinds** (unlike the tactics
  board's green/black), window 16/13, glyph top sprite row 2. **Barcelona's
  slot layout matches NO stock formation** (clubs carry their own tactic) —
  the walked 22-marker list is bake-derived (digit identification by exact
  composite match) and injected by the parity shot; live rivals use
  Tactics.auto_pick (documented). **GHOST (dim) = YOUR OWN team mirrored**:
  disc at (242-mk1.x, 138-mk1.y) + HORIZONTALLY FLIPPED arrow at
  (242-mk2.x, 138-mk2.y) per own slot with own shirt digits — the mirror
  constants are the decompile's `0xf2-x / 0x8a-y`; the dim pass is a
  positional NOISE dither (multi-valued per colour, no LUT fits) → the walked
  own-state (run-2 MU 3-5-2, shirts 1,2,3,21,6,8,7,10,9,11,20) ships as 22
  verbatim 16x16 patches (boxes overlapping bright markers are flagged
  POISONED and excluded from live reuse), un-walked own states use a
  majority-vote dim LUT + dim digits (127,159,85) — documented approximation.
  The bake PROVES the full model: campo + ghost patches + bright composites
  recompose frame 015's pitch to **0px**.

Honest gaps: ~~AV formula + TEAM RATING source~~ **CLOSED 2026-07-06
(morale_re.md)**: AV = `FUN_00581e60` (core4+FI+MO)/6 — drawn by the shared
table row painter `FUN_004f5260`; TEAM RATING = `FUN_004fe540`:
`FUN_0057a3a0()/0xb` (sum of XI AVs skipping injured/banned, FIXED /11 —
walked 87 = 959/11 on this frame, 77 = (936−88)/11 on lineup-155). Walked
values stay injected in the parity shot (frame FI/MO not reproducible live);
live = `Morale.av6` + the sourced team-rating rule. ~~Rival club tactics
un-decoded~~ **CLOSED 2026-07-06 (club_tactics_re.md)**: each club's OWN tactic
ships in its EQUIPOS.PKF `.DBC` record (11 x 8 u16 slot block, `FUN_00579c70` /
`FUN_0058c130`) and is what `*(screen+0x1928)` (the lazily-loaded club object,
`FUN_005793d0` chain) holds at +0x60+i*0x20 — Barcelona's decoded block
reproduces THIS frame's 22 walked markers EXACTLY (offset 0x6a, unique hit);
live rivals now draw it from `app/data/club_tactics.json`. ~~The .DBC's TRUE XI
bytes player+0x1b/+0x1d un-extracted~~ **CLOSED 2026-07-06 second pass
(club_tactics_re.md)**: the squad records' XI slot byte (player+0x1b, 1..11;
slot s stands at tactic slot s-1) is extracted for all 476 clubs and — where
game_db-complete (475 clubs since the 2026-07-06 exact-cipher game_db rebuild;
the 1 hole = a .DBC that leaves a slot unfilled) — fielded verbatim on this
screen (`Tactics.with_xi`, native slot order). Rival BRIGHT digits + the
table N. column = the slot number 1..11 (frame 015: Barcelona's stored
squadNos [13,22,3,4,5,12,7,21,9,10,11] do NOT appear); only the dim own-ghost
digits carry real squad numbers. Barcelona's shipped XI reproduces THIS frame's 11 rows + fine
codes + POS column EXACTLY. auto_pick remains the holes/missing-club fallback
(`FUN_005776f0` confirms the in-engine picker maxes `FUN_00581e60 × (+0xa8 cap
byte)` per broad group — the sim-side fielding, still app-side auto_pick).
Still open: PARAMETERS numeric view un-walked on this screen (cells centred under the
header letters, lineup-128 inks) · the hire-an-Assistant state un-walked
(kept as the text rendering) · flip-state toggle plates + arrow spots are
reconstructions · ghost dim LUT/digit ink are approximations for un-walked
own states.

## App mapping (-> `app/scenes/RivalScreen.gd`)
PM98's staff EFFECTS are data-driven from the save; the app's `Staff` model is ours
(1..5 star quality) — see `Staff.gd`. So the reveal is driven by
`Staff.assistant_quality(career.staff)` (0..5), kept at the two states the app's data can
render faithfully:
- **q == 0** -> the hire-Assistant message; no rival table / dots (sourced bVar2==0).
- **q >= 1** -> full rival XI table + TEAM RATING + formation dots (sourced bVar2>=1 table,
  bVar2>=5 dots; a hired assistant's ability is always well above 5 in the original).

SUPERSEDED 2026-07-06: the "second marker phase" of the decompile is now frame-decoded
(see BODY PARITY above) — it is YOUR OWN team's two-phase markers mirrored via the
`0xf2-x / 0x8a-y` constants, drawn dim, NOT a rival defence phase; and the per-marker
"arrows" in the frame are the AVERDE mk2 movement arrows (the fle* sprites stay unused
on the walked screen). The app renders BOTH marker sets faithfully; the reveal gate
keeps the two app states (q==0 message / q>=1 full report).

Rival marker layout comes from the club's OWN stored tactic (`club_tactics.json`, decoded
2026-07-06 — see `club_tactics_re.md`; slots reordered GK/DEF/MID/FWD by the sourced
FUN_004fe2d0 band rule) with `Tactics.auto_pick_shape` selecting the XI for the slot-table's
band counts; clubs missing from the data fall back to `Tactics.auto_pick` + stock
formations (MatchSim still fields CPU sides with auto_pick — unchanged). The parity shot
injects the walked marker list (the frame also pins the XI). The
COMPUTER/mgr box shows the rival club's `manager`, else `COMPUTER`. Native 640x480;
scales to fit its parent (same transform as LINE-UP). Wired at the hub OPPONENT icon
(Main `_show_opponent`, which also passes the manager's own Tactics for the ghost
overlay). Tests: `app/tests/test_rival_screen.gd`.
