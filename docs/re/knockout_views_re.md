# The knockout views — RESULTS → any cup, every layout the original switches between

**Status: the LIST layout is BUILT and 0 px (2026-07-26); layouts 3-5 measured, not built.**
`KnockoutScreen.gd` draws the compact list in both column sets and
`tools/re/diff_knockout_parity.py` proves it at **0 differing pixels** against
`06_euroleague_round1_played.png` (European, 15 ties, every aggregate filled) and
`03_facup_r3_drawn_UNPLAYED_1997-12-20.png` (domestic, 16 ties, every cell empty), outside
two declared buckets — the barra manager kit, a hole this screen shares with `ResultsScreen`
and `EuroGroupScreen`, and the scrollbar's thumb (see "What is inferred" below).
`Main._show_cup_screen` raises it for any knockout phase of nine ties or more; a smaller
round still falls through to the SORTEO card, because the bracket / semifinal-card / final
layouts are measured here but not yet built.

Frames: `screenshots/wine-captures-2026-07-26-knockout-views/` and
`screenshots/wine-captures-2026-07-26-cup-draw-then-play/` (a live Bolton W 1997-98 career
driven by `tools/re/wine/autodrive.py run plans/season_euro_probe.json`, which walks into
RESULTS and photographs the whole competition rail every second hub visit), plus the
2026-07-25 set in `screenshots/wine-captures-2026-07-25-euro-competitions/`.

## Why this was blocked until now

The previous session had exactly one knockout frame with more than four ties played, and
one bracket frame (`16_euroleague_qtr_finals.png`) in which **all four ties were unplayed**
— so leg scores, aggregate placement and the winner ink in the bracket form were
unwitnessed, and every one of them would have had to be invented. The 2026-07-26 drive
photographs the rail on a schedule instead of at one moment, which catches each phase in
the state it is actually in that week. It produced **five layouts, four of them never seen
before.**

## The five layouts

The original does not have "a knockout screen". It switches presentation with the size of
the round, and the column set with the competition:

| # | layout | seen at | columns |
|---|---|---|---|
| 1 | **compact list**, 15 px rows, no kits | 15-16 ties (Euro. League Round 1 / Round 2, U.E.F.A. 1/16) | European: `1ST LEG` `2ND LEG` `AGGR.` · domestic: `RES.` `REPLAY` |
| 2 | **kit list**, 22 px rows, kit each side | 5-8 ties (U.E.F.A. 1/8, Cup Winners' 1/8, Coca-Cola R4) | same pair as above |
| 3 | **bracket**, four 80 px-pitch panels, kit + country flag each side | 4 ties (any QTR FINALS) | European: `1ST LEG` `2ND LEG` → `AGGR.` plates · domestic: `RES.` → `REPLAY` |
| 4 | **semifinal cards**, two side-by-side, each with a `1ST LEG` / `2ND LEG` block | 2 ties | venue name, then the two clubs, then `FINALIST 1` / `FINALIST 2` plates |
| 5 | **the final**, the competition trophy + a `RESULTS` card + a `WINNER` band | 1 tie | `STADIUM <name>`, the two finalists, an empty laurelled WINNER band |

Layout 4 is keyed on the round, not just the count: it names the semifinals and carries the
FINALIST plates. Layouts 3 and 4 are the ones that were entirely unwitnessed.

### 1 — compact list

`wine-captures-2026-07-25-euro-competitions/06_euroleague_round1_played.png` (15 ties,
played: `2 - 1`, `1 - 0`, `2 - 2` under the three column heads, the ADVANCING club's name
and its scores inked yellow, the eliminated club grey) and
`05_euroleague_round2_undrawn.png` (16 ties drawn, all three cells empty).
`03_facup_r3_drawn_UNPLAYED_1997-12-20.png` is the domestic form: `RES.` and `REPLAY`
heads, 16 rows, both cells empty. Its played counterpart
`05_facup_r3_PLAYED_1998-01-10.png` fills `RES.` and inks the winner yellow — and leaves
`REPLAY` empty on the four ties that finished level (`1 - 1`, `2 - 2`), which is the
original's replay concept the port does not model (REFRUN R2).
A list longer than the panel scrolls: the yellow ▲/▼ arrows at x≈478.

### 2 — kit list

`01_uefa_1_8finals_leg1_played_1997-12-07.png`: eight ties, 22 px rows, a kit blit each
side, `1ST LEG` filled (`1 - 2`, `0 - 3`, `0 - 0`, …) and `2ND LEG` / `AGGR.` still empty.
That is the mid-tie state — the same round a week later would carry all three.
`wine-captures-2026-07-25-euro-competitions/09_comp_cwc.png` is the same layout unplayed.

### 3 — the bracket (the one that was blocked)

`02_euroleague_qtrfinals_UNPLAYED_1998-01.png` vs
`03_euroleague_qtrfinals_LEG1_PLAYED_1998-03-14.png`, same career, same four ties:

```
Borussia D.  v Manchester Utd.   1ST LEG 0 - 0
Olympiakos   v F.C. Barcelona    1ST LEG 1 - 1
Real Madrid  v Bayern M.         1ST LEG 1 - 0
Parma        v Sporting Port.    1ST LEG 1 - 2
```

Geometry, measured on the frames (design space 640x480):

| element | span |
|---|---|
| panel | `x20..477`, `y113..184`; black frame rows y113-114 / y183-184, columns x20-21 / x476-477 |
| panel pitch | **80** — panels at y113, y193, y273, y353 |
| left kit | `x22..81` (dynamic `x27..71`) |
| left flag | `x83..112` |
| home + away name bars | `x136..374`, one text each, y≈120..134 |
| right flag | `x385..414` |
| right kit | `x416..475` (dynamic `x424..469`) |
| `1ST LEG` plate + its value box | plate y145..159, value box y160..175 |
| leg-1 score ink | **y165..171**, `0 - 0` drawn at x115..122 / dash x127..129 / x134..141 — centred on the value box, white `(255,255,255)` |
| value-box grounds | `(80,100,120)` and `(140,160,180)` |
| `AGGR.` plate | blue, its value box navy |

Chrome vs content was separated the honest way: three frames of this layout from **two
different careers and two different competitions** (euro QTR, Cup Winners' QTR) differ
ONLY inside `y120..180` of each panel, so every other pixel is static chrome and can be
baked verbatim. The domestic form of the same bracket is
`07_cocacola_qtr_drawn_UNPLAYED_1997-12-07.png` — identical panel geometry, `RES.` and
`REPLAY` plates instead of the three European ones.

**Still unwitnessed here:** a bracket tie with BOTH legs played, so the `AGGR.` cell's ink
and the advancing-club highlight *in this layout* are still open. Note the aggregate itself
IS witnessed, in the COMPACT layout — `06_euroleague_round1_played.png` carries
`1ST LEG 2-1 · 2ND LEG 1-0 · AGGR. 2-2`, i.e. the aggregate is the two legs summed with the
home/away sides swapped. Only the bracket form's own cell is missing.

**Two full seasons were driven and both missed it, for a structural reason — read this
before driving a third.** The screen auto-advances to the next phase the moment that phase
is DRAWN, and the next round is drawn as soon as the previous one resolves (the
draw-then-play rule above). So a completed bracket is on screen only for the days between
its last 2nd leg and the next draw, which a two-week probe cadence walks straight over:

| season | bracket seen | next probe |
|---|---|---|
| 1997-98 | QTR FINALS, 1st legs in, Sat 14 Mar 1998 (`03_...`) | already Semifinals |
| 1998-99 | QTR FINALS, 1st legs in, Sat 13 Mar 1999 | already Semifinals, Sat 27 Mar |

**The method that will work** is not another season, it is the **phase paginator's LEFT
arrow**: pause the drive with the euro at Semifinals and page back one phase to the
finished quarter-finals. Same trick gets the played `WINNER` band — the Final was still
undecided at week 38 in both seasons and is played inside the season-end sequence, when the
hub never comes back. The arrow moves with the label width (measured `(197,96)` / `(303,96)`
for `QTR FINALS`, `(243,97)` / `(350,97)` for `ROUND 1`), so measure it on the live frame.
Reaching the euro semifinals from a fresh career is ~34 weeks, about an hour of drive.

### 4 — the semifinal cards

`04_euroleague_semifinals_LEG1_PLAYED_1998-04-04.png` and
`06_cocacola_semifinals_drawn_1998-01-10.png`. Two cards side by side, headed
`SEMIFINAL 1` (blue) and `SEMIFINAL 2` (green). Each card carries a `1ST LEG` band, then
the **venue** (`Old Trafford`, `Karaiskakis`, `The Hawthorns`, `Jose Alvalade`,
`Santiago Bernabéu`, `Portman Road`, `The Dell`) and the two clubs with a score box on the
right, then a `2ND LEG` band with the venues and clubs swapped, then an empty
`FINALIST 1` / `FINALIST 2` plate under each card.

The venue strings are the clubs' own grounds, so they come from the club record, not from
the fixture. The colour split (SF1 blue / SF2 green) is fixed per card, not per club.

### 5 — the final

`05_euroleague_final_UNDECIDED_1998-04-25.png`: the competition trophy at the left, a
`RESULTS` card holding the two finalists' kits + flags, `STADIUM` and the ground name
(`Das Antas`), the two club rows with empty score boxes, and a laurelled `WINNER` band,
empty until the match is played.

## Draw-then-play — the schedule question, answered

The other thing this drive settled. Frames in
`screenshots/wine-captures-2026-07-26-cup-draw-then-play/`:

| when | what |
|---|---|
| Sun 14 Dec 1997 | F.A. Cup **Round 2 played** (`RES.` filled, winners yellow, four ties level with `REPLAY` empty) |
| (that week's advance) | the **SORTEO** for Round 3 is raised unprompted |
| Sat 20 Dec 1997 | F.A. Cup **Round 3 drawn, every `RES.` cell empty** |
| Sun 28 Dec 1997 | Round 3 **still** unplayed |
| Sat 10 Jan 1998 | Round 3 **played** |
| Mon 1 Dec 1997 | Coca-Cola **Round 4 played** |
| Sun 7 Dec 1997 | Coca-Cola **Qtr Finals drawn, unplayed** (bracket layout, `RES.`/`REPLAY` empty) |

Two competitions, the same order. So there is no interval to invent: **the next round is
drawn the moment the previous one resolves, and it is played at its own scheduled week.**
Ported 2026-07-26 as `Cup.draw_next_round` + `b["pending_draw"]`; see
`app/tests/test_cup_draw_then_play.gd`.

## Aside — what the kit-outline residual is NOT (2026-07-26)

The EURO. LEAGUE group screen's only remaining residual is the kit blits, and this session
narrowed it without closing it. Measured on `ridi/1104.png` against
`refs/euro-competitions-2026-07-25/15_euroleague_group_F.png` at the recorded (80,274):

* the differing pixels are **32 of the 118 that carry outline index 135 `(22,22,22)`** —
  the other 86 outline pixels render exactly, so it is the OUTERMOST ring only;
* they are **not the background showing through**: 0 of the 32 equal the empty-body
  desktop at the same coordinate;
* they are **not a blend**: every frame value is an exact palette entry, and the indices it
  lands on (54, 242, 236, 128, 134, 92, 100, 136, 248) have no arithmetic relation to
  either the outline index or the background's;
* they are **not an off-by-one**: (0,0) is the best of all 25 offsets in ±2 (32 differing,
  next best 69), and none of the 32 equals a neighbouring kit pixel in any direction;
* they are **not the realised-palette bug** that closed the MINIBAND flags — re-decoding
  under `MANAGER.PAL` + Windows statics is byte-identical (tested 2026-07-26).

What survives: the left-edge pixels take dark entries and the right-edge pixels light ones,
which is a directional pass. So it is a **second sprite plane or an emboss table keyed on
the silhouette**, drawn after the kit — not anything the kit decode can fix.

## Geometry banked 2026-07-26 — the LIST layout, as built

Measured on `06_euroleague_round1_played.png` (European) and
`01_facup_r2_PLAYED_1997-12-14.png` / `03_facup_r3_drawn_UNPLAYED_1997-12-20.png`
(domestic). All spans inclusive, design space 640x480.

| element | span |
|---|---|
| panel | `x6..477`; top border y125-126, the title band y127..151, its underline y152-153 |
| body top | y154 |
| column cells, European | home `8..158` · away `161..309` · 1ST LEG `312..365` · 2ND LEG `367..420` · AGGR. `422..475` |
| column cells, domestic | home `8..185` · away `188..363` · RES. `365..418` · REPLAY `420..473` |
| row grounds, light/dark | names `(120,140,160)`/`(100,120,140)` · score cells `(160,160,200)`/`(120,120,160)` · the LAST score cell `(140,140,180)`/`(100,100,140)` |
| the manager's own tie | replaces the alternation outright: names `(60,80,100)`, score `(59,85,130)`, last `(30,52,98)`, ink `(140,160,180)` |
| home name | proman10, RIGHT-aligned, pen END at `cell_x1 - 4`, pen top `row_top + 2` |
| away name | proman10, LEFT-aligned, pen at `cell_x0 + 4`, same pen top |
| a score cell | first number RIGHT-aligned pen end `cell_x0 + 21`, the dash at `cell_x0 + 24`, second number pen `cell_x0 + 31`, pen top `row_top + 2` |
| inks | the club going through `(255,223,0)`, the other `(42,63,85)` |

**The panel is sized to the round.** Two sizes are witnessed and they are *not* the same
pitch, which is why `app/tests/test_knockout_layout.gd` asserts both:

| ties | body height | black rules at | foot |
|---|---|---|---|
| 15 | 225 | y168, 183, 198 … 363 (pitch 15) | y378..380 |
| 16 | 255 | y168, 184, 200 … 392 | y408..410 |

Both fall out of `rule_i = 154 + floor((i+1) * body_h / n) - 1` with
`body_h = 15 * n` up to 15 ties and the panel's full **255** at 16 or more. Above 16 the
list scrolls at the full height (`01_facup_r2` is the witness, 16 rows plus a scrollbar).

**The marked digit.** The club going through has ITS OWN goals inked yellow in every cell,
and the SECOND LEG is printed with the sides swapped — its host first — so the marked
position flips there. Witnessed on all 15 rows of `06_euroleague_round1_played.png`; the
aggregate confirms it arithmetically (leg 1 `2-1` + leg 2 `1-0` → `AGGR. 2-2`).

**The phase paginator.** Plate interior `x254..338 y88..108` for EURO. LEAGUE,
`x315..399 y88..108` for the domestic and U.E.F.A./Cup Winner's bands; the label is
proman10 `(100,100,140)`, centred, pen top `plate_y0 + 5`. The arrow buttons are 23x21 at
the plate's two sides. **A DISABLED arrow's triangle is a two-colour checkerboard keyed on
ABSOLUTE screen parity** — the same disabled right arrow differs in 76 px between (299,79)
and (401,88), every one a symmetric swap of one of five colour pairs — so both phases are
cut from real frames. The ENABLED faces are not dithered: the enabled left arrow is 0 px
different across those same two parities.

**The competition band is not placed by any rule this port can state.** Over eight frames
its outer box is `x69..365` for EURO. LEAGUE in the list layouts, `x28..324` for the same
competition in the bracket layouts, and `x71..428` for F.A. Cup / Coca-Cola / U.E.F.A. /
Cup Winner's in BOTH — three placements that no width of the name, the label or the panel
accounts for. So each witnessed (competition, layout) pair is cut verbatim as a strip and
`bands.json` records where its label and arrows sit.

## Geometry banked 2026-07-26 — the BRACKET layout, for the next build

Measured on `03_euroleague_qtrfinals_LEG1_PLAYED_1998-03-14.png` (European) and
`08_facup_qtrfinals_DOMESTIC_bracket_unplayed_1999-03-04.png` (domestic), so the build
needs no guessing either. Four panels, `T = 113, 193, 273, 353` (pitch **80**), each
`x20..477`:

| element | span, relative to the panel top T |
|---|---|
| black frame | rows `T`, `T+1` and `T+70`, `T+71`; columns x20-21 and x476-477 |
| interior | white `(255,255,255)` |
| left kit / right kit | `x22..81` / `x416..475` |
| left flag / right flag | `x83..112` / `x385..414` |
| the two name bars | `y T+7 .. T+26`, home `x114..247`, away `x250..383`, ground `(180,200,220)` |
| the three plate slots | `y T+33 .. T+46`, at `x83..175`, `x193..283`, `x310..414` |
| their value boxes | `y T+48 .. T+61`, same three x spans |
| European | slot 1 `1ST LEG`, slot 2 `2ND LEG`, slot 3 `AGGR.` — plates `(140,160,180)`/`(140,160,180)`/`(42,95,170)`, boxes `(80,100,120)`/`(80,100,120)`/`(20,0,90)` |
| domestic | slot 1 is EMPTY white; slot 2 `RES.`, slot 3 `REPLAY` — plates `(140,160,180)`/`(120,140,160)`, boxes `(80,100,120)`/`(60,80,100)` |
| a leg score | white `(255,255,255)`, ink rows `y T+52 .. T+58`, `0 - 0` at x115..122 / dash x127..129 / x134..141, i.e. centred on its value box |

The chrome/content split is proven twice over: the same layout in two careers and two
competitions differs ONLY inside `y T+7 .. T+67` of each panel, and the SAME career's
unplayed and leg-1-played frames differ in **490 px total, all of them the leg-1 score
ink**. Everything else is static and can be baked verbatim.

**Still missing for the bracket:** a tie with BOTH legs played, so the `AGGR.` cell's ink
and the advancing-club highlight in this layout stay unwitnessed. The aggregate RULE is not
in doubt — `06_euroleague_round1_played.png` carries it in the compact layout, two legs
summed with the sides swapped — only where the bracket draws it.
`tools/re/wine/knockoutwatch.py` scans a drive's frames for it (and for the cell below).

## The filled WINNER band — it was already in the repo (2026-07-26)

**Closed without a new capture.** `09_comp_charity.png`, banked 2026-07-25 and sitting in
`screenshots/` ever since, carries the band with a club in it: `WINNER` over
**Manchester Utd.**, with the winner's own kit inside the laurel wreath. It is not a
different widget — outside the name bar itself the Charity Shield's band and the European
final's empty one are **pixel-identical** over `x55..371, y352..417`; the ONLY rows that
differ are 383..395, which is the name.

| element | value |
|---|---|
| empty bar | `x60..371`, `y383..397`, ground `(200,220,240)` |
| the winner's name | ink `x65..219`, rows `y383..395`, two-tone `(42,63,170)` + `(85,95,170)` |
| laurel wreath | from `x374`; it overlaps the bar's right end, and holds the winner's KIT once decided |

The lesson is worth keeping: the cell was called unwitnessed for two sessions because it
was looked for on the European final, which is decided inside the season-end sequence where
the hub never returns. The one-off finals (Charity Shield, Supercup, Intercontinental) reach
the same view *within* the season. `knockoutwatch.py scan` over every committed frame set
found it in seconds — **scan what you already have before driving another season.**

## What is inferred, and therefore declared

Three things in the built screen are not pixel-witnessed, and the parity gate buckets or
documents each rather than hiding it:

1. **the scrollbar thumb.** Its arrows and trough are the original's own; the two frames in
   hand differ only in the thumb's LENGTH, which fixes neither the rounding nor a minimum,
   so length and tracking are computed proportionally. `diff_knockout_parity.py` reports the
   column `x478..493` as its own bucket.
2. **the REPLAY column with ink in it.** Every witnessed domestic frame leaves it empty —
   the original raises a replay in a later week. The port prints the replay in the same
   grammar as `RES.`; the ink rule there is unwitnessed.
3. **the enabled RIGHT arrow at odd screen parity.** No frame has one. It is taken to be
   dither-free like its witnessed twin, the enabled LEFT arrow.

## What the port needs before this can be built

* the bracket's `AGGR.` cell with a decided tie (page the phase paginator back);
* the played FINAL, for the `WINNER` band;
* the layout switch itself: count-driven for 1/2/3, round-driven for 4/5 — confirm by
  finding a 4-tie round the original does NOT draw as a bracket, if one exists.
