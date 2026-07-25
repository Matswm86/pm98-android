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

## Not yet witnessed

* the QTR FINALS / SEMIFINALS / FINAL phases of the European Cup (the career is mid-season);
* which two clubs advance out of each group in the original's own rule (the real 1997-98
  competition took the six winners plus the two best runners-up);
* the `flecha cuartos` / `gana derecha` / `gana izquierda` bracket art — loaded by the
  screen, absent from every frame we hold.
