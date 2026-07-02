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

## App mapping (-> `app/scenes/RivalScreen.gd`)
PM98's staff EFFECTS are data-driven from the save; the app's `Staff` model is ours
(1..5 star quality) — see `Staff.gd`. So the reveal is driven by
`Staff.assistant_quality(career.staff)` (0..5), kept at the two states the app's data can
render faithfully (no invented phases / arrow-directions):
- **q == 0** -> the hire-Assistant message; no rival table / dots (sourced bVar2==0).
- **q >= 1** -> full rival XI table + TEAM RATING + formation dots (sourced bVar2>=1 table,
  bVar2>=5 dots; a hired assistant's ability is always well above 5 in the original).

GAP (honest, not faked): the original's finer tiers add a SECOND defence-phase marker set
(the first loop's mirrored `0xf2-x`, `0x8a-y` coords, sourced bVar2>=7) so the pitch fills
both halves, plus per-player movement arrows (`fleul/fleur/fledl/fledr.bmp`, sourced
bVar2>=9 — visible in the walkthrough frame). Both need per-player two-phase tactic data
PM98 does not decode for CPU clubs, so this port draws only the single nominal formation
(`Tactics.auto_pick`) the app models; it does not invent a second phase or arrow directions.

Rival XI + formation come from `Tactics.auto_pick(rival_club)` (the same selector MatchSim
fields CPU sides with). The COMPUTER/mgr box shows the rival club's `manager`, else
`COMPUTER`. Native 640x480; scales to fit its parent (same transform as LINE-UP).
Wired at the hub OPPONENT icon (Main `_show_opponent`), replacing the WRONG-SCREEN
DATA BASE browser (APP_VS_SPEC_AUDIT B1). Tests: `app/tests/test_rival_screen.gd`.
