# RESULTS → EURO. LEAGUE — the European competition screen (group phase + knockout)

**Status: the GROUP view is BUILT and render-diffed (2026-07-26). The KNOCKOUT view is
not.** `app/scenes/EuroGroupScreen.gd` + `app/art/screens/euroleague/` (baked by
`tools/re/build_euroleague_chrome_from_frames.py`); `Main._show_euro_group_screen` raises
it and the invented `CupScreen` placeholder is deleted. Parity vs all six witnessed group
frames: **0 px outside two named residuals** — see "What actually shipped" at the end.

Built 2026-07-25: the six-group / 24-club field, the six-winners-plus-two-best-runners-up
advancement rule, and the phase label. `Cup.next_label` now emits the original's own
`1/8 Final` verbatim for every matchday of the group phase, instead of a
`Group Matchday %d` counter — the badge was witnessed unchanged on 1 Oct, 5 Nov and
26 Nov 1997 (`docs/re/REFRUN_manutd_1997-98.md` R3), so it is a fixed competition-phase
string and wrong-but-canonical. Asserted in `app/tests/test_refrun_findings.gd`.

The app used to show the European GROUP phase on an invented `CupScreen` placeholder
(`Main._show_cup_group_placeholder`, removed 2026-07-26). This doc records the original's
real screen, from the binary and from live captures, so the build had no guessing in it.

## Where it lives

Hub → **RESULTS** → the right-hand competition rail. The rail's chips, in the original's
own order (frame `04_results_competition_buttons.png`): F.A. Cup, Coca-Cola Cup, Charity
Shield, **Euro. League**, Cup Winner's, U.E.F.A., Euro. Superc., Intercont., 1st/2nd/3rd
Play-Offs.

## The binary

The screen's own string block, `.data` file offsets 0x252a4c–0x252d60 (VA 0x65444c–0x654760):

```
0x65444c  img\resultados\uefa\flecha cuartos.BMP     bracket arrows
0x654474  img\resultados\uefa\gana derecha.BMP
0x65449c  img\resultados\uefa\gana izquierda.BMP
0x6544c4  img\flecha abajo paso.bmp / abajo off / arriba paso / arriba off
0x6545c8  EURO. LEAGUE          the title plate
0x6545d8  Round %u              the ROUND paginator
0x6545e4  1/8 FINALS
0x6545f0  GROUP %c              the GROUP A..F buttons
0x6545fc  GROUP  
0x654604  DBDAT\MINIBAND\ba96%04u.bmp   the per-club mini flag in a group row
0x654624  European League
0x654634  img\copas\ligacampeones big.bmp
0x654654  GROUP
0x65469c  1/16 FINALS
0x6546a8  1/32 FINALS
0x6546b4  U.E.F.A. Cup      + img\copas\uefa big.bmp
0x65471c  CUP WINNER'S CUP  + img\copas\recopa big.bmp
```

`FUN_004937f0` builds the body widget (vtable `0x62b7a0`, name getter `FUN_00496820`
returning `European League`); `FUN_00496fd0` draws it and calls the shared
`FUN_00470050` WINNER band. `1/8 FINALS` is also referenced by `FUN_00493ed0`,
`FUN_0049aca0` and `FUN_0049e4d0`; the MINIBAND loader is `FUN_004953e0`.

## The live captures (`screenshots/wine-captures-2026-07-25-euro-competitions/`)

Bolton W, Manager League, season 1997-98. **The European competitions run from season one
with the real 1997-98 entrants** — no qualification needed to browse them.

| frame | state |
|---|---|
| `01_teams_in_championships.png` | the **TEAMS IN CHAMPIONSHIPS** screen (season start; EXE 0x656f60): European Cup Newcastle Utd + Manchester Utd., U.E.F.A. Arsenal/Liverpool/Leicester/Aston Villa, Cup Winners' Chelsea, Charity Shield Man Utd v Chelsea, European Supercup Borussia D. v F.C. Barcelona, Intercontinental Borussia D. v Cruzeiro |
| `05_euroleague_round2_undrawn.png` | EURO. LEAGUE **ROUND 2**, ties drawn, legs not played |
| `06_euroleague_round1_played.png` | EURO. LEAGUE **ROUND 1** played: 1ST LEG / 2ND LEG / AGGR. columns, the winner of each tie inked yellow |
| `07_euroleague_group_a.png`, `08_group_A..F.png` | the **GROUP phase**: header `1/8 FINALS` + `Round 1`, GROUP A table, the group's results below it, and the six GROUP A..F buttons |
| `09_comp_uefa.png` | U.E.F.A. CUP — the same MATCHES list with a single `1/16 FINALS` paginator and **no** group buttons |
| `11_european_supercup_champion_card.png` | the **EUROPEAN SUPERCUP CHAMPION** card (CAMPEON family, the screen `CharityShieldScreen` already implements): Borussia D. / Scala over F.C. Barcelona / Van Gaal |
| `12_uefa_cup_champion_card.png` | the **U.E.F.A. CUP CHAMPION** card, same family: Arsenal / Wenger over Liverpool / Evans, raised in the season-end sequence |
| `13_league_tables_final_markers.png` | the season-end **LEAGUE TABLES** walk (8 May 1998, one screen per division, `CONTINUE` at (610,437)) with the original's own `PROMOTION` / `PLAY-OFFS` / `RELEGATION` chips down the left edge |

### Screen structure, as captured

* **Header band** `y88..110`: the competition trophy at the left, the `EURO. LEAGUE` title
  in green caps, then **two** paginators — the PHASE (`◄ 1/8 FINALS ►`) and the ROUND
  (`◄ Round 1 ►`). The U.E.F.A. Cup and Cup Winners' Cup carry only the phase paginator.
  Arrow boxes measured on `05_…`: left ◄ at x233..253, right ► at x343..358, y90..103; the
  right arrow renders **dim when the next phase has not been drawn yet**.
* **Knockout view**: a `MATCHES` list with `1ST LEG`, `2ND LEG`, `AGGR.` columns; the
  advancing club's name and score inked yellow, the eliminated club grey.
* **Group view**: a black-bordered table headed `GROUP A` with columns `PTS P W D L GF GA`;
  four rows, each a position plate (navy, white digit), the club name on a light-blue bar
  with its **MINIBAND** country flag right-aligned in the name cell, then the seven number
  cells. Under the table, that matchday's results — kit, right-aligned home club, two score
  boxes (one goal digit inked yellow — **NOT the winner's**, see the retraction below), away
  club, kit. To the right, the six
  `GROUP A`..`GROUP F` buttons, the selected one lit red on white.
* **Six groups of four = 24 clubs** — the real 1997-98 Champions League field, and the label
  the original gives that phase is `1/8 FINALS`.

## What this means for the app

`docs/re/europe_re.md` currently documents a **16-club field in 4 groups of 4** as an
"honest simplification". The original's own field is **24 clubs in 6 groups of 4**, with two
qualifying rounds (`Round 1`, `Round 2`) ahead of it. That simplification is no longer
necessary and should be replaced by the real shape when this screen is built.

## The full field, witnessed 2026-07-25 (session 4)

The previous session could not capture GROUP F: `08_group_D.png` was a duplicate of
GROUP C because the click did not land, and the file names then ran one behind. The
cause is now known — the six GROUP buttons are pitched **24 px** apart with centres at
**y194 / 218 / 242 / 266 / 290 / 314** (x≈403), not the 20 px that was clicked.

A fresh Bolton W career was driven to **week 22** (`tools/re/wine/autodrive.py`) and all
six groups were captured after the final matchday, plus the phase after them:

`screenshots/wine-captures-2026-07-25-season-drive/10..15_euroleague_group_A..F.png`
and `16_euroleague_qtr_finals.png`.

| group | table after Round 6 (PTS P W D L GF GA) |
|---|---|
| A | Göteborg 15 · Manchester Utd. 13 · Borussia D. 5 · Anorthosis 1 |
| B | Lierse 11 · PSV 10 · C.Salzburgo 7 · B. Leverkusen 4 |
| C | Parma 12 · Brondby 9 · Oporto 9 · Valletta 6 |
| D | Juventus 13 · Mónaco 11 · Olympiakos 6 · Barry Town 4 |
| E | Newcastle Utd 15 · Gotu 8 · Croatia Zag. 8 · Rosenborg 3 |
| F | Real Madrid C.F. 12 · Bayern M. 9 · Feyenoord 7 · MTK 7 |

**The group entrants are drawn per career, not fixed data.** This career's six groups
share almost nothing with the previous session's, because the qualifying rounds ahead of
them are played from the career's own RNG. That settles the old worry about "filling in
the last four from the real 1997-98 competition": there is no canonical field to fill in.

## The advancement rule — CONFIRMED, not inferred

`16_euroleague_qtr_finals.png` (the QTR FINALS view, never witnessed before) holds
**Mónaco v Juventus, Lierse v Real Madrid C.F., Manchester Utd. v Göteborg, Parma v
Newcastle Utd** — eight clubs, four two-legged ties, each row a kit + flag pair with
`1ST LEG` / `2ND LEG` / `AGGR.` bars.

Against the six tables above that is exactly:

* the **six group winners** — Göteborg, Lierse, Parma, Juventus, Newcastle Utd,
  Real Madrid C.F.; plus
* the **two best runners-up on points** — Manchester Utd. (13) and Mónaco (11), ahead of
  PSV 10, Brondby 9, Bayern M. 9, Gotu 8.

So the group phase is 6 x 4 with **6 winners + 2 best runners-up** into the quarter
finals. The phase label the original prints over the groups is `1/8 FINALS`, and the
group matchday paginator runs `Round 1` .. `Round 6` (a double round-robin of four).

## The qualifying rounds — the entrant counts, witnessed

Browsed at week 1 of a fresh career (`02_euroleague_round2_week1.png`,
`03_euroleague_round1_played.png`), counted off the row bands:

| phase | ties | clubs |
|---|---|---|
| `Round 1` (already played at career start) | 15 | 30 |
| `Round 2` | 16 | 32 = the 15 Round-1 winners + 17 clubs entering here |
| `1/8 FINALS` (the groups) | — | 24 = the 16 Round-2 winners + 8 entering here |
| `QTR FINALS` | 4 | 8 |

All fifteen Round-1 winners reappear in the Round-2 list, which is what fixes the 15/17
split. At week 1 the phase paginator's right arrow is **dim** past `Round 2`: the group
draw does not exist until Round 2 has been played, which is why a week-1 career cannot
be paged into the groups at all.

The sister competitions are straight knockouts of a different size, from the same rail:
**U.E.F.A. Cup** opens at `1/16 FINALS` with **16 ties (32 clubs)**, **Cup Winners' Cup**
at `1/8 FINALS` with **8 ties (16 clubs)** — and the Cup Winners' rows are the taller
kit-flanked variant, 22 px instead of 15 px.

## Not yet witnessed

* the SEMIFINALS and FINAL of the European Cup, and the `flecha cuartos` /
  `gana derecha` / `gana izquierda` bracket art the screen loads;
* the tie-break the original uses between runners-up level on points (this career's two
  qualifiers were clear on points, so goal difference was never exercised).

## Geometry banked 2026-07-25 (late) — the screen is STILL NOT BUILT

Measured off `tools/re/refs/euro-competitions-2026-07-25/15_euroleague_group_F.png` (all
six group frames are now committed beside it, `10..15_euroleague_group_A..F.png`) so the
next session starts from numbers rather than from a frame. **No scene was written and
nothing was baked** — `Main._show_cup_group_placeholder` still raises the invented
`CupScreen`.

**What varies across the six group frames** — and therefore what the chrome must clear —
is exactly one region: `y180..325, x75..446`. Everything else (barra, the EURO. LEAGUE
title band and its two paginators, the competition rail, the division chips, RETURN) is
identical on all six and is static chrome.

### The GROUP table

Black frame rows at y186-187 / 207-208 / 223 / 238 / 253 / 268-269; columns at x79-80 /
94 / 199 / 221 / 237 / 253 / 269 / 285 / 301 / 317-318. So:

| cell | span |
|---|---|
| position plate | x81..93, navy `(20,0,90)`, digit white |
| club name + MINIBAND flag | x95..198 |
| PTS · P · W · D · L · GF · GA | x200..220, 222..236, 238..252, 254..268, 270..284, 286..300, 302..316 |

Four rows at y209 / 224 / 239 / 254, pitch 15, and the bands alternate
`(200,220,240)` / `(160,180,200)`.

### Text, solved with `tools/re/probe_text_anchor.py` at ZERO differing pixels

Everything on the table is **calend12**, pen top = the row's own top:

| cell | anchor |
|---|---|
| position | centred on `81 + 93` |
| club | LEFT-aligned, pen x **100** |
| each number | centred on `x0 + x1 + 1` — verified on PTS (205 for `12`), P (226) and GA (306) |

Only the LIGHT band's inks are pinned so far: club `(60,60,100)`, numbers
`(180,200,220)`. The dark band's club ink is not yet measured.

### Still to measure before building

* the dark band's club and number inks;
* the MINIBAND flag rect inside the name cell (`DBDAT\MINIBAND\ba96%04u.bmp`);
* the results rows under the table (kit, right-aligned home club, two score boxes with one
  goal digit inked yellow — **the "winner's goals" reading is RETRACTED**, see below — away
  club, kit) — their row tops and cell spans;
* the six GROUP A..F buttons' lit/unlit faces: all six lit states ARE witnessed, one per
  frame, so they can be cut verbatim rather than synthesised — buttons pitched 24px at
  centres y194 / 218 / 242 / 266 / 290 / 314, x approx 403, panel borders x360-361 and
  x443-444;
* the knockout view (`MATCHES` with `1ST LEG` / `2ND LEG` / `AGGR.`), which
  `16_euroleague_qtr_finals.png` holds.

## Measurements taken 2026-07-25 (late) — the four open items are CLOSED

All off the six committed frames `tools/re/refs/euro-competitions-2026-07-25/
10..15_euroleague_group_A..F.png`. The screen is still NOT built; what follows is
everything the previous entry listed as "still to measure", plus the kit bank, which was
the real blocker.

### The dark band's inks — the same as the light band's

Sampled per cell on all four rows of GROUP F:

| cell | light row (y209 / y239) | dark row (y224 / y254) |
|---|---|---|
| club-name cell background | `(200,220,240)` | `(160,180,200)` |
| club-name ink | `(60,60,100)` | **`(60,60,100)` — identical** |
| P/W/D/L/GF/GA cell background | `(100,120,140)` | `(80,100,120)` |
| number ink | `(180,200,220)` | **`(180,200,220)` — identical** |
| PTS cell background | `(20,0,90)` | `(20,0,90)` |
| PTS ink | `(180,200,220)` | `(180,200,220)` |
| position plate | `(0,0,128)` navy | `(0,0,128)` navy |
| position digit | white | white |

Only the two BACKGROUNDS alternate. Every ink is band-independent, so there is no second
ink table to carry.

### The MINIBAND flag rect

**x183..196, y = row top + 2, 14 x 10** — right-aligned inside the name cell, measured on
all four rows (the rows whose club name is short show the cell clean up to x182). That is
exactly the size `PMChrome.mini_flag` already ships (`art/flags/mini_%03d.png`, the
14x10 MINIBAND bank), so no new art is needed.

### The results rows under the table

Two rows in every captured frame (a group of four plays two matches a matchday).

| element | span |
|---|---|
| row 1 | y278..290 · row 2 y300..312 — **pitch 22, bar height 13** |
| left kit | x80..96, y274..293 (the RIDIESC blit, see below) |
| home-club bar | x97..179, white `(255,255,255)`, club name RIGHT-aligned |
| score box 1 | x181..196, black |
| score box 2 | x199..214, black |
| away-club bar | x216..300, white, club name LEFT-aligned |
| right kit | x301..317 |

**One goal digit per row is inked yellow `(255,255,0)`, the other `(180,200,220)` — and it
is NOT the winner.** Counted on all six frames: the yellow is in the SECOND box on row 1
and in the FIRST box on row 2, every single time, whoever won. GROUP F is the plain
counter-example — row 1 Feyenoord 1-3 Bayern M. puts the yellow on the winner's 3, row 2
MTK 0-2 Real Madrid puts it on the LOSER's 0. So the earlier "winner inked yellow" reading
from the low-res session was wrong; the marker tracks the ROW, not the result, and its
actual rule is **unresolved**. Do not port it as a winner highlight. Whatever it is, it
needs either a frame where a group plays a different number of matches or the draw code
(`FUN_00496fd0`) read.

### The six GROUP buttons

Differ A-vs-B at **y183..205 and y207..229**, columns **x358..446**. So six buttons of
**89 x 23 pitched 24 px**: tops y183 / 207 / 231 / 255 / 279 / 303. All six lit faces are
witnessed one per frame, so every face can be cut verbatim rather than synthesised.

### The header band is NOT static — it carries the leader's kit

`y180..207`: a **kit blit at x75..97** (the group's top club) plus `GROUP <letter>` in the
bold outlined face on the black band. Varying columns are x75..97 (kit), x105..168 and
x172..185 (the text). So the "everything but y180..325 x75..446 is chrome" note stands,
but inside it the header is dynamic too.

### The kit bank is RIDIESC — already shipped

The results-row kit is the game's **RIDIESC** 17x20 kit (`DBDAT/RIDIESC.PKF`), which the
port already exports to `app/art/kits/ridi/<id>.png` and reads through
`PMChrome.ridi_kit`. Proven by matching Feyenoord's own `ridi/1104.png` against frame 15:
best fit at **(80,274)** with 32 of 221 opaque pixels differing — the residual is the
engine's soft-shadow pass, the same one already documented for the NANOESC blits
(`build_match_header_from_frames.py`), not different art.

### What used to block a 0-px build — both settled 2026-07-26

1. **The desktop under the two results rows.** The old plan was to page the ROUND
   paginator to an UNPLAYED round and expect the zone to come back empty. **It does not**
   — captured live and witnessed in
   `tools/re/refs/euroleague-group-2026-07-26/03_group_A_round5_unplayed.png`:
   an unplayed round still draws both kits, both white club bars and both black score
   boxes, and drops **only the goal digits**. So the rows' own chrome is static and stays
   baked; the desktop is needed only where the kit sprites are transparent.
   The desktop itself came from a different capture:
   `01_results_premier_empty_body.png`, the SAME RESULTS screen with an empty body. Proven
   the right source, not assumed — the wallpaper band `y330..430 / x75..450` is **0 px**
   identical between that frame and every group frame, **across two different careers**,
   and the 206 px of the four kit rects that the blit leaves uncovered match it exactly.
2. **The kit shadow pass** — still open, and now measured on the live build rather than
   estimated: see the residual table below.

## What actually shipped (2026-07-26)

`tools/re/build_euroleague_chrome_from_frames.py` bakes:

* `chrome.png` — the whole 640x480 screen from frame 10, with every dynamic cell blanked
  to its frame-sampled flat colour (the club cells, the seven number cells, the two white
  club bars, the two black score boxes, the ROUND plate) and the five kit rects replaced
  by the empty-body desktop;
* `hdr_group_A..F.png` — the `GROUP <letter>` plate cut verbatim per letter. Necessary,
  not lazy: the string is **CENTRED**, so `GROUP D` sits one pixel left of `GROUP A`
  (measured; frames 10 vs 13 differ across x105..168 for that reason alone);
* `btn_lit_A..F.png` — each GROUP button's lit face, one per witnessed frame. The unlit
  faces are baked into the chrome, each cut from a frame whose selected group is a
  *different* letter.

Text anchors, all solved with `tools/re/probe_text_anchor.py` at zero differing pixels:

| cell | font | ink | anchor |
|---|---|---|---|
| table club name | calend12 | `(60,60,100)` | LEFT, pen x **100**, pen top = row top |
| table numbers | calend12 | `(180,200,220)` | centred on `x0 + x1 + 1` |
| results home club | calend12 | `(80,100,120)` | RIGHT, pen END **177** |
| results away club | calend12 | `(80,100,120)` | LEFT, pen x **219** |
| goal digits | calend12 | `(180,200,220)` / `(255,255,0)` | centred on the box, pen top = bar top − 1 |
| `Round %u` | proman10 | `(0,0,0)` | centred on **829** (plate x372..456), pen top **124** |

**The yellow goal digit is ported as the checkerboard it measures as.** Row 1 marks the
SECOND box, row 2 the FIRST — now witnessed on **20 rows**: the six wk22 group frames
(12 rows) plus a second career's GROUP A paged through all six matchdays (8 played rows,
`04..09_group_A_round1..6.png`). Those six rounds also prove the display order: matchday 4
is matchday 1 with the venues swapped and the club order swaps with it, so the LEFT club
is the HOME club — and the yellow still does not follow it. It is `(row + box) % 2 == 1`,
and **what it means is still unresolved**. It is NOT a winner marker.

### Parity — `tools/re/diff_euroleague_parity.py` on all six groups

```
group A: 1268px differ (1246 kit blits, 22 MINIBAND flags, 0 outside)
group B: 1269px differ (1255 kit blits, 14 MINIBAND flags, 0 outside)
group C: 1290px differ (1278 kit blits, 12 MINIBAND flags, 0 outside)
group D: 1286px differ (1258 kit blits, 28 MINIBAND flags, 0 outside)
group E: 1259px differ (1257 kit blits,  2 MINIBAND flags, 0 outside)
group F: 1284px differ (1263 kit blits, 21 MINIBAND flags, 0 outside)
```

Every table cell, name, number, score digit, yellow marker, button face, header plate,
ROUND label and barra value is **exact**. The two residuals, both pre-existing and both
named rather than hidden:

* **kit blits** — the barra manager kit (only Man Utd's 35x44 header patch has ever been
  cut, so a Bolton W barra falls back to the 24x32 NANOESC kit and differs by the whole
  blit: ~640 px), the group leader's NANOESC kit (79 of 419 opaque px) and the four
  RIDIESC results kits (32 of 221 each). The RIDIESC/NANOESC residual is *only* the
  sprite's 1-px outline ring, and it is **not** a plain blend of the outline with the
  background (tested: left-edge pixels darken, right-edge pixels lighten to 128/144 grey),
  so the pass is still un-reversed. Not invented, not faked.
* **MINIBAND flags** — 99 px over all six frames, every one a single dithered pixel on a
  neighbouring palette entry. The right flag is at the right rect in every row.

### Still not built

The **knockout view** (`MATCHES` with `1ST LEG` / `2ND LEG` / `AGGR.`), which
`16_euroleague_qtr_finals.png` holds, and the bracket art (`flecha cuartos`,
`gana derecha`, `gana izquierda`) the screen loads.
