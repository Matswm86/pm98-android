# RESULTS → EURO. SUPERC. — the European Supercup screen, and the tie behind it

**Status: SPECIFIED FROM THE BINARY AND A REAL FRAME.** The app used to render the
Supercup as one neutral match on the invented `CupScreen`; the original plays it over
**two legs** and draws them on a screen of its own.

Binding frame: `screenshots/wine-captures-2026-07-25-euro-competitions/09_comp_supercup.png`
(live drive of the original, Bolton W career, 1997-98 — Borussia D. v F.C. Barcelona,
drawn but not yet played).

## The screen builder — `FUN_004a1820`

1133 bytes, decompiled 2026-07-25. What it establishes:

| evidence | fact |
|---|---|
| `s_EUROPEAN_SUPERCUP_00654784` | the title plate string, VA 0x654784 (file 0x252d84) |
| `img\copas\supercopa_europa big.bmp` @ 0x65476a | the trophy art down the left |
| `s_Proman10_00652e9c` / `Proman12` | the two fonts the panel uses |
| `FUN_00470050(…)` | the shared **WINNER** band, the same call the EURO. LEAGUE screen makes |
| `*(iVar5+0x40)` / `*(iVar5+0xfc)` | the two contesting club ids, read out of the competition record at `career+0xc` |
| `param_1+0x3474 / +0x3478` | those two ids, cached on the screen |
| `param_1+0x347c = iVar5`, `+0x3480 = iVar5+0xbc` | **two match records, 0xbc apart — the two legs** |
| `FUN_005c0d50(param_1+0x3030, 0, 0x20, 0x32, 0)` | the RETURN / rail widget block |

## The two-leg panel — `FUN_0046a110`

4796 bytes; the shared widget that draws BOTH legs. It is the same widget the F.A. Cup
uses for a replay: when `param_1+0x3f4 != 0` its two headers read `MATCH RESULT` /
`REPLAY RESULT` (VA 0x653e48 / 0x653e38) instead of `1ST LEG MATCH` / `2ND LEG MATCH`
(VA 0x653e68 / 0x653e58).

Every coordinate below is a literal in that function, panel-relative:

| element | call | panel x,y | size |
|---|---|---|---|
| leg 1 header bar | `FUN_0043ce50` after `FUN_00436fb0(0xdf,0xc)` @ `(2,8)` | 2, 8 | 223 x 12 |
| leg 2 header bar | same @ `(2,0x78)` | 2, 120 | 223 x 12 |
| `STADIUM` caption | `FUN_005d9d80(s_STADIUM_00653e30, 0, 0x19, 0xe3)` | centred, y 25 | — |
| leg 1 venue name | `FUN_005d9d80(*(param_1+0x408), 0, 0x25, 0xe3)` | centred, y 37 | — |
| `STADIUM` caption 2 | `… 0, 0x8a, 0xe3` | centred, y 138 | — |
| leg 2 venue name | `FUN_005d9d80(*(param_1+0x40c), 0, 0x96, 0xe3)` | centred, y 150 | — |
| club plate (row 1) | `FUN_004ac740(param_1+0x41c)` @ `(7,0x36)` `(0xaf,0x14)` | 7, 54 | 175 x 20 |
| score cell (row 1) | `FUN_004ac740(param_1+0x42c)` @ `(0xb8,0x36)` `(0x24,0x14)` | 184, 54 | 36 x 20 |
| club plate (row 2) | `… param_1+0x424` @ `(7,0x4c)` | 7, 76 | 175 x 20 |
| score cell (row 2) | `… param_1+0x434` @ `(0xb8,0x4c)` | 184, 76 | 36 x 20 |

The leg-2 block repeats the row pair at **+112**; the two captions repeat at **+113**
(the original is one pixel inconsistent between the bars and the captions — both values
are literals, and the frame agrees with both).

`param_1+0x400` / `+0x404` are the two leg match records; a leg is drawn only when its
record is non-null and both club ids (`+0x38`, `+0x3a`) are non-zero, which is why the
un-played tie in the frame still shows both blocks (drawn) with empty score cells.

## The frame, measured

The panel widget is mounted at **(137, 124)** — the panel's black borders are the only
long black runs in the column, at x137/138 and x362/363, and every literal above lands
on the frame when offset by that origin:

| element | absolute rect (design px) |
|---|---|
| title plate `EUROPEAN SUPERCUP` | border rows 84/85 + 109/110, white interior x139..361 y86..108 |
| leg 1 header bar (dark green `50,70,0`) | x139..361, y132..143 |
| `STADIUM` caption ink (olive `100,130,10`) | x210..289, y150..158 |
| leg 1 venue ink (green `17,90,34`) | x210..288, y162..172 |
| leg 1 club plates (`200,220,240`) | x144..318, y178..197 and y200..219 |
| leg 1 score cells (`42,63,170`) | x321..356, same rows |
| leg 2 header bar | x139..361, y244..255 |
| `STADIUM` caption 2 / venue 2 | y263..271 / y275..283 |
| leg 2 club plates | y290..309 and y312..331 |
| club-name ink (`80,100,120`) | left-aligned at **x167**, cap band +5..+13 from the plate top |
| mini kit | in the plate's left well, x≈145..161 |
| WINNER band | the shared band below the panel, y354..413 |

## What this says about the COMPETITION

* **The Supercup is home-and-away, not a neutral final.** Two leg blocks, each with its
  own STADIUM.
* **The Cup Winners' Cup holder hosts the first leg.** Witnessed 1997-98: leg 1
  `Camp Nou` with `F.C. Barcelona` named first, leg 2 `Westfalen` with `Borussia D.`
  named first — Barcelona were the 96-97 Cup Winners' Cup holders and Dortmund the
  96-97 European Cup holders. TEAMS IN CHAMPIONSHIPS lists the pair the other way round
  ("European Supercup — Borussia D. / F.C. Barcelona"), so the naming order on that
  panel is *European Cup winner first* while the *hosting* order is CWC winner first.
* Both `stadium` names are already in `app/data/game_db.json` (`F.C. Barcelona` →
  Camp Nou, `Borussia D.` → Westfalen), straight out of EQUIPOS — nothing to invent.
* The **Intercontinental Cup stays one match**: it is drawn by `FUN_0048daf0`, which is
  byte-identical to the Charity Shield builder `FUN_004717a0` bar the title and the
  trophy (`docs/re/comp_result_screen_re.md`), and its frame carries a single STADIUM.

## Not witnessed

* a **played** Supercup — the frame's tie is drawn but not yet contested, so the score
  cells, the WINNER band fill and any aggregate/extra-time presentation are unseen;
* whether the original settles a level aggregate on away goals, extra time or a replay.
  The app applies the same 1997-98 UEFA ladder it already uses for every other two-legged
  round (`Cup._play_two_leg_tie`) rather than invent a Supercup-specific rule.
