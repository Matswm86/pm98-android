# RESULTS → EURO. LEAGUE — the European competition screen (group phase + knockout)

**Status: CAPTURED AND SPECIFIED, NOT YET BUILT.** The app still shows the European GROUP
phase on the invented `CupScreen` placeholder (`Main._show_cup_group_placeholder`). This
doc records the original's real screen, from the binary and from live captures taken this
session, so the build has no guessing left in it.

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
  boxes (**the winner's goals inked yellow**), away club, kit. To the right, the six
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
