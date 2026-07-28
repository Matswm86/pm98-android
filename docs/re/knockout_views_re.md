# The knockout views — RESULTS → any cup, every layout the original switches between

**Status: ALL FIVE layouts are BUILT and 0 px outside declared buckets** -- the LIST (1),
the KIT LIST (2, built 2026-07-28, see "The kit list, as built"), the BRACKET (3), the
SEMIFINAL CARDS (4) and the FINAL (5). Cards ship for
EURO. LEAGUE + Coca-Cola Cup and the final for EURO. LEAGUE — the other competitions'
cards/final chromes are unwitnessed and fall back to the SORTEO (honest gap). The bracket:
`KnockoutScreen._draw_bracket`, gated by `diff_knockout_parity.py` cases 3-4 at **0 px
outside three declared buckets** (the barra kit; the eight 60x68 kit columns, which are
the exact-decoded MINIESC sprite plus the un-reversed outline pass; the euro case's rail,
whose chip lit-states are career state). `Main._show_cup_screen` raises it at exactly
4 ties, verified live via `PM98_CUP_SHOT` (F.A. Cup QTR from a real career). See "The
bracket, as built" below for the solved anchors.
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

~~**Still unwitnessed here:** a bracket tie with BOTH legs played~~ — **WITNESSED AND
BUILT 2026-07-28**, see §"The decided bracket" at the end of this file. The aggregate rule
was never in doubt (the COMPACT layout carries it: `06_euroleague_round1_played.png` has
`1ST LEG 2-1 · 2ND LEG 1-0 · AGGR. 2-2`, the two legs summed with the home/away sides
swapped); what the frame settled is how the bracket DRAWS a decided tie, and it turned out
to be three things the port had wrong.

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

## The bracket, re-measured 2026-07-26 — and three things above are WRONG

Read this section, not the one above, before building. The table above was measured off two
frames; this was measured off **five bracket frames across five competitions** — the
pageback drive left 14 more in `screenshots/wine-captures-2026-07-26-knockout-pageback/`
(euro, Cup Winner's, U.E.F.A., Coca-Cola at weeks 83/92/106/116/127) that nobody had opened.
The three corrections:

1. **The score ink is NOT white.** It is `(180,200,220)` — the same colour as the name bars —
   with an 80 % blend `(160,180,200)` on the glyph edges, which is what the `.fnt` bitmap's
   two alpha levels produce over the `(80,100,120)` box. A white ink would be visible from
   across the room as wrong.
2. **The domestic form does not "leave slot 1 empty".** Its two slots are at *different x
   positions* from the European three, not a subset of them: `RES.` at `x135..227` and
   `REPLAY` at `x271..361`, with the arrow gap `x229..269` between them and plain white
   panel either side (`x82..133`, `x363..415`). The European slots are `x83..175`,
   `x193..283`, `x310..414`.
3. **The kit art does NOT already exist.** `app/art/kits/offers/` holds exactly **one**
   witness-cut patch (Brighton, 107) — the claim that the bracket's 47x59 blit "is exactly
   that set" was checked and is false. See §"The kit" below; the flags claim IS true.

### Verified geometry (five competitions, 20 panels)

Panels at `T = 113, 193, 273, 353`, each `x20..477`. Relative to T:

| dy | what |
|---|---|
| 0-1, 70-71 | the panel's black frame rows (full width x20..477) |
| 2-5 | white interior |
| 6 | black rule, `x82..415` (the top of the name block) |
| 7-26 | name bars: home `x114..247`, away `x250..383`, ground `(180,200,220)`; flags `x83..112` and `x385..414` |
| 27 | black rule, `x82..415` |
| 28-31 | white |
| 32 | black, over each slot's span |
| 33-46 | the plates. EURO `(140,160,180)` / `(140,160,180)` / `(42,95,170)`; DOM `(140,160,180)` / `(120,140,160)` |
| 47 | black, over each slot's span |
| 48-61 | the value boxes. EURO `(80,100,120)` / `(80,100,120)` / `(20,0,90)`; DOM `(80,100,120)` / `(60,80,100)` |
| 62 | black, over each slot's span |
| 63-69 | white |

**The chrome/content split, proven over 20 panels.** With only these six rects declared as
content — the two kits `x22..81` / `x416..475` (dy 2..69), the two flags `x83..112` /
`x385..414` (dy 7..26), the two name bars (dy 7..26) — plus each column set's value boxes,
**12 European panels across 3 competitions and 8 domestic panels across 2 are byte-identical
outside them.** So one 458x72 panel strip per column set can be baked verbatim and repeated
four times, and `desktop.png` already covers every gap: it is 0 px against both bracket
frames at `y185..192`, `y265..272`, `y345..352` and `y425+`.

**The band.** `BAND_Y = (64, 112)` for this family (the panel starts at 113, not 125). The
phase plate sits **one row higher for EURO. LEAGUE than for everyone else**: euro's plate
interior is `x213..297, y79..99` with arrows at `(189,79)` / `(299,79)`; F.A. Cup,
Coca-Cola, U.E.F.A. and Cup Winner's all use `x315..399, y78..98` with arrows at
`(291,78)` / `(401,78)`.

**Text placement.** Names are CENTRED, not edge-anchored as in the list layout: home ink
centres on x≈177, away on x≈318 (their bars' centres are 180.5 and 316.5, so this is not
"centre of the bar" — solve the exact cx off the eight witnessed names with the
`floor(cx - advance/2)` rule that the SCOUT bar needed, `docs/re/scout_screen_re.md`). Ink
rows are dy 12..21, colour `(60,80,100)`. The leg-1 score centres on its box (x129 for the
European slot 1; ink rows dy 52..58).

### The kit — MINIESC, and it hands the outline pass a 5x bigger sample

The 47x59 blit is **`DBDAT/MINIESC.PKF`**, whose sprites render 48x64 with a 45x57 opaque
bbox. Placed at `(27, T+11)` it matches in **1373 of 1661 opaque pixels**; every offset in
±4 is worse. The identification is not in doubt (`EQ960401.BMP` = Borussia Dortmund, panel 1
of the euro QTR frame).

The 288-pixel residual is the **un-reversed kit outline/bevel pass**, and it is the same
thing as the EURO. LEAGUE group screen's 32-px residual (§Aside above) — this is just a much
larger sample of it:

* **173 of the 288 sit on the 1 px silhouette edge**, and the frame carries greys there
  — `(144,144,144)`, `(128,128,128)`, `(80,80,80)`, `(44,44,44)`, `(160,160,164)` — where the
  sprite has its near-black `(22,22,22)` outline index. That is exactly the "left edge dark,
  right edge light, drawn after the kit" directional plane the group-screen note describes.
* The blit is **47x59 while the sprite's opaque bbox is 45x57** — one pixel larger on every
  side. So the pass draws a ring OUTSIDE the silhouette, which is why the on-screen rect has
  never matched any sprite dimension.
* 115 residual pixels are interior and still unexplained.

**So the bracket can be built now**, with the eight kit rects as a declared bucket exactly
as `diff_knockout_parity.py` already declares the barra manager kit and `OffersScreen`
declares its kit panel. And work-list item 6 (the kit-outline bevel) should be attacked here
rather than on the group screen: 173 edge samples with five known greys beats 32.

**The flags DO blit exactly.** `app/art/flags/dbcard/<code>.png`, 30x20, at `(83, T+7)` and
`(385, T+7)` — **0 px** on four tested cells (Germany 2, Greece 26, Spain 22, England 30).
Note `T+7`, not the `T+6` claimed above: dy 6 is the black rule.

~~**Still unwitnessed after all 17 bracket frames in the repo were checked:** a decided
`AGGR.` cell~~ — **CLOSED 2026-07-28** (§"The decided bracket"). Still open: any ink at all
in the domestic `RES.` / `REPLAY` boxes, which no frame in the repo carries.
`tools/re/wine/knockoutwatch.py` scans a drive's frames for the two cells it was written for.

## The bracket, as built (2026-07-26, session s62)

Everything the re-measured section left open was solved off the frames before building:

* **names** are proman10 CENTRED at `pen = floor(cx - advance/2)` with **cx 178.5 (home)
  / 319.5 (away)** — all 15 witnessed names across the euro and F.A. Cup QTR frames land
  exactly (the doc's earlier "x≈177 / x≈318" estimate refined). Pen top `T+12`, ink
  `(60,80,100)`.
* **scores** centre on their value box: first number's pen END at `cx-5`, dash pen
  `cx-2`, second number's pen at `cx+5`, pen top `T+50`, ink `(180,200,220)` (euro slot 1
  cx 129: ink ends 122, dash 127..129, B starts 134 — all four witnessed cells). **The
  dash draws at the `.fnt`'s SECOND alpha level** — its six pixels are the 80 % blend of
  the ink over the slot's own box ground `(160,180,200)` in every witnessed cell — so the
  port prints it with that blend per slot ground. The unwitnessed slots (2ND LEG, AGGR.,
  RES./REPLAY ink, the advancing-club highlight) apply the same grammar and the LIST
  layout's winner-yellow rule, declared as inference in `KnockoutScreen.gd`.
* **kits**: the 48x64 MINIESC sprite blits at **(26, T+8) / (423, T+8)** — unique-best
  offset on all 16 witnessed cells (second-best 3-5x worse), ~85-90 % of opaque pixels
  exact. The residual is the outline pass (below). NOTE the top-level
  `app/art/kits/<id>.png` bank shipped WRAPPED until 2026-07-26 (the Pillow decode
  honoured the stripped header's bogus bfOffBits, rotating every sprite 21 rows + 16
  columns); it is re-exported through `pkf_image.dib_indices` and now carries the true
  45x57-bbox sprites.
* **desktop**: the empty-body RESULTS frame carries a 6 px fragment at `x14..19,
  y125..177` that the list panel (x6..477) always covered but the bracket panel
  (x20..477) exposes; patched from the euro QTR frame (frames 02/03/08 are byte-identical
  over `x0..19, y113..185`).
* **the euro rail differs between careers**: frames 02/03 (March) vs the baked
  `rail_euro.png` (August) differ in 6,686 px, all of it the cwc/uefa/supercup/euro chips'
  lit-state. WHICH chips are lit is career state the port does not model, so the euro
  parity case buckets the rail; the domestic case's rail matches its witness 0 px and is
  enforced.

## The outline pass, SOLVED in two of three parts (2026-07-27)

The s62 narrowing below stands, but two of its three components are now CLOSED:

1. **The "unexplained ~115 interior px/cell" was the realised-palette bug** — the same
   family as the MINIBAND flags. The MINIESC bank was exported with `force_vga=True`
   (the shared VGA table at DAT.PKF+0x5CA); the running game realises MANAGER.PAL + the
   20 Windows statics. Measured over the 16 bracket witness cells the disagreement is a
   CONSISTENT per-entry remap — (24,24,16)→(10,15,0) in 203/204 px (index 111, the very
   entry export_flags.py documents), the green ramp (90,126,71)→(39,159,59) 69/69,
   (115,148,99)→(61,191,82) 41/41, (37,78,12)→(0,95,0) 38/38,
   (192,227,192)→(192,220,192) 26/26 (index 8, the money-green static). Fixed in
   `map_crests.export_kits` (realised palette); all 476 kits re-exported. The
   kit-consuming gates re-ran green (cupdraw PASS, supercup, seasonend 0, euroleague
   unchanged, entry — its one FAIL, rival_015, reproduces with the OLD kits, i.e.
   pre-existing).
2. **The ring (shadow + outer bevel) is POSITION-CONSTANT and now baked verbatim.**
   Every MINIESC kit shares one silhouette, so the pass's outside-silhouette result is
   the same pixels for every club: across the 16 witnessed cells, the L column's ring is
   248 static px vs 9 club-varying, the R column's 211 vs 57 (Sporting Port.'s deviant
   silhouette). The baker votes every witnessed cell and bakes
   `kitwell_under_L/R.png` (244 / 202 px) drawn UNDER the sprite, and per-card icon
   overlays `icon_under/over_sf1/sf2.png` (55 under + 33 over px) around the cards'
   ridi icons — the OVER layer carries the positions where the pass provably overrides
   the sprite itself and the result is club-independent across 12 witnessed cells.
3. **Still open: the on-sprite edge bevel of the 48x64 kits.** Its values depend on the
   sprite's own underlying colours (the 16 cells disagree), so it cannot be baked and
   its rule is still un-reversed — ~160-190 px per bracket cell after 1+2.

Measured effect on the parity buckets (diff_knockout_parity.py): bracket kit columns
3868/3556 → **1659/1691**; the cards' eight icon buckets → **0 px on the cocacola
witness, 0 on six of eight euro cells** (the two Sporting Port. icons keep 53 px — the
deviant silhouette). The buckets stay declared for the club-dependent remainder.
The same bake should port to the OTHER ridi/kit sites (EuroGroupScreen's 24 group cells
still carry ~1260 px/frame, OffersScreen's panel) — follow-up, same method.

## The outline pass, narrowed again (2026-07-26, s62) — it is a DROP SHADOW plus a highlight

Classifying every differing pixel of all 16 bracket kit cells against the exact-decoded
sprites restructures the residual into three distinct components:

1. **a flat `(128,128,128)` drop shadow, 1-2 px, on the BOTTOM and RIGHT of the
   silhouette only.** The ring above and left of the silhouette stays background white
   (464 + 336 px undrawn). This is dest-halving on the white panel (255 → 128), i.e. the
   classic GDI half-tone shadow — which is why the group screen's earlier "50 % blend"
   test failed: it blended the OUTLINE INDEX with the background, but the shadow ignores
   the sprite's colours entirely.
2. **a highlight applied to the sprite's own TOP/LEFT edge pixels** (not outside them) —
   the differing opaque-edge pixels take light entries `(192,192,192)`, `(160,160,164)`,
   `(144,144,144)` along the top/left silhouette edge.
3. **scattered interior single-pixel diffs** (~115/cell) with no edge structure —
   candidates: a palette-realisation difference or a shading pass; unexplained.

A minority of ring pixels (220 over 16 cells) also match palette-snapped
`(sprite-NW-neighbour + white)/2` half-blends exactly, so an edge anti-alias component may
coexist with the flat shadow at concavities. **No 0 px rule yet — the kit columns stay a
declared bucket** — but the shape of the pass is now known: shadow below-right, highlight
on-edge above-left, plus an interior component.

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

## The semifinal cards and the final, as built (2026-07-27)

Both layouts went in against the frames named in §4/§5 plus
`09_euroleague_semifinals_DRAWN_unplayed_1999-03-27.png` (a SECOND career's euro semis) —
`tools/re/diff_knockout_parity.py` cases 5-7, **0 px outside declared buckets** on all
three witnesses. What the measuring settled:

* **The band is a THIRD family (`cards`), shared by the semis and the final.** The euro
  final band differs from the euro semis band in the 292 label pixels only ("Final" vs
  "Semifinals"), so one strip serves both. The euro cards band is byte-identical to the
  euro BRACKET band outside the plate + arrows (0 px); the cocacola cards band is NOT —
  its own strip, trophy bottom at y117, plate interior `(336,87)..(420,107)`, arrows
  left_on at `(312,87)` / right_off_p1 at `(422,87)` (both EXACT matches of the baked
  pager faces). So a domestic cards band cannot be derived from the bracket's — F.A. Cup
  / U.E.F.A. / Cup Winner's semis stay SORTEO until captured.
* **The plate label case is witnessed per family**: euro cards plates print the
  sequential scheme's own mixed case ("Semifinals", "Final"); the domestic plate prints
  caps ("SEMIFINALS"). The list/bracket plates are caps everywhere. `Main` applies
  exactly that rule.
* **One cards body strip serves both column sets**: the euro and cocacola cards frames
  are byte-identical below the band outside the content rects (3 frames, 2 competitions,
  2 careers). Baked from the fully-unplayed cocacola frame
  (`cards_body.png`, x0..499 y120..427).
* **Geometry** (per card, SF2 = SF1 + 258 for every dynamic element): leg blocks at
  y190/y282 (venue rows, black grounds), club bars at y209/231 and y301/323 (20 px,
  grounds SF1 `(200,220,240)` / SF2 `(192,220,192)`), score boxes x191..226 / x449..484
  (grounds SF1 `(42,63,170)` / SF2 `(80,110,5)`), FINALIST boxes x20..216 / x281..477.
* **Text**: everything dynamic is NATIVE proman10. Venue pen `(33, block_top+4)`
  left-aligned (leftmost ink identical on all three frames); club name pen
  `(34, bar_top+5)`; score digits centred on the box (`_txt_mid` field sums 418/934 —
  the witnessed "1" lands x464..468, the "2" x462..469, white ink). Venue inks
  SF1 `(117,147,187)` / SF2 `(61,191,82)`; name inks SF1 `(42,95,170)` /
  SF2 `(80,110,5)`.
* **The kit icon is the ridi bank** (17x20), matched unique-best at `(13, bar_top)` —
  Man Utd 188/221 opaque px; the residual is the same un-reversed outline pass the
  bracket's MINIESC columns carry, so the eight 17x20 icon rects are declared buckets.
* **The 2ND LEG block swaps sides** (its host first, its venue the away club's own
  ground) — witnessed on all three frames; same grammar as the list layout's leg-2
  column.
* **The FINAL's card + WINNER band chrome is byte-identical to `09_comp_charity.png`'s
  outside the content rects (0 px)**, so the redraw grammar is CompResultScreen's
  witnessed one — kits aspect-fitted into the 48x60 wells (the hi-res panel kit bank is
  still un-extracted; the two wells are declared buckets), 30x20 dbcard flags at
  `(199,163)`/`(270,163)` (exact), stadium value centred on 243 in `(17,90,34)`. The
  finalists' names are NATIVE proman12 — the witness 'R' is 11x9 with advance 12,
  proman12's own metrics — at pen `(155, bar_top+4)` (y271/y302), ink `(80,100,120)`.
* **Model fix the cocacola witness forced**: the original's Coca-Cola SEMIFINALS are
  two-legged (1ST/2ND LEG blocks + both venues on the 1998-01-10 frame) while its other
  rounds stay single-leg + replay — `Cup` now takes `semi_legs` and `LEAGUE_CUP_OPTS`
  sets 2. The F.A. Cup's semis stay single-leg (unwitnessed either way, per the
  Career.gd comment).
* **The FINAL is at a NEUTRAL ground** — Das Antas 1998, neither finalist's stadium.
  One witness fixes no selection rule, so the pick is DECLARED OURS: a deterministic
  rng draw from the competition's own field, never a finalist's ground, recorded on the
  draw (`Cup._pair_round` → `venue_id`). A competition without a stored field records
  -1 and the view (euro-only anyway) would leave the line empty.

Declared inferences added by this build (on top of the list below): the advancing-club
highlight on a DECIDED semifinal (the list layout's yellow rule applied to the cards'
own inks) and the FINALIST plate fill (the winner centred in the WINNER band's ink) —
**no captured frame anywhere in the corpus shows a decided semifinal** (scanned all
committed sets 2026-07-27); the FA-model replay printed in a card's 2ND LEG block; the
played FINAL's score digits + WINNER name, which keep CompResultScreen's approximation
(the witnessed charity digits and two-tone winner ink match no extracted font bank).

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


## The decided bracket — WITNESSED 2026-07-28, and it corrected three things

The 07-26 build had no frame of a decided bracket tie, so it applied the compact LIST's
rule (ink the winner's name yellow) and declared it. The pageback drive finally landed one:
**`screenshots/wine-captures-2026-07-28-knockout-decided/01_euro_qtr_finals_decided.png`**
(banked as `tools/re/refs/knockout-2026-07-26/09_euroleague_qtrfinals_DECIDED_1998-04-11.png`),
the euro QTR FINALS of the same Bolton W career on Sat 11 April 1998, every tie played —
plus the same state in two more competitions on the same day
(`02_cwc_qtr_finals_decided.png`, `03_uefa_qtr_finals_decided.png`), which is what makes
the readings below rules rather than one-offs.

Root cause of the earlier misses is confirmed and now moot: the view auto-advances the
moment the next phase is drawn, so the QF is only reachable by paging BACK from the semis,
and the drive has to have reached the QF SECOND legs (~April) first. The 07-26/07-27 drives
stopped in January, at which point the QF bracket exists but is unplayed.

**What the frame settled, and what the port had wrong:**

1. **The winner's whole NAME PLATE is repainted**, not just his ink. Fill `(42,95,170)`
   over the strip's own `(180,200,220)`, across the full plate (`x114..247` home /
   `x250..383` away, rows `T+7..T+26`). The yellow ink `(255,223,0)` was already right.
2. **Two chevrons point inwards at the ends of that plate.** `(166,202,240)`, five px wide,
   inset one px from each plate edge, nine rows tall, apex row `T+16`, width
   `5 - |dy|` — a solid triangle. Measured on both a home winner (Manchester Utd., panel 3)
   and an away winner (Borussia D., panel 1).
3. **The plain score ink and the dash blend are PER BOX.** The two leg boxes print
   `(180,200,220)` on `(80,100,120)` with the dash at the witnessed 80 % blend; the navy
   `AGGR.` box prints `(180,180,220)` on `(20,0,90)` and its dash carries **no blended
   pixel at all** on any of the four ties — it is the full ink. Neither could be seen
   before, because no frame had ever had a filled aggregate.

The aggregate's GRAMMAR is also now witnessed in the bracket and matches the compact
layout: leg 2 is printed HOST-first (so it reads the other way round from leg 1) while
`AGGR.` is always (left club, right club). Oporto `0-2` then `0-2` = `2-2` with Borussia
through on away goals; Manchester Utd. `2-0` then `0-1` = `3-0`.

Built in `KnockoutScreen._draw_winner_plate` + the per-box `BRACKET_SCORE_INK_*` /
`BRACKET_DASH_BLEND_*`; gated by `diff_knockout_parity.py` case `knockout_euro_qtr_done`
at **0 px** outside the standing buckets.

**One declared band on that case:** the phase paginator's white plate is two rows taller on
a paged-back frame than on a live one (white rows 77..101 at x190, against 78..100 on
`03_euroleague_qtrfinals_LEG1_PLAYED`), at identical width and with an identical label. One
witness of each state is not a rule, so the port keeps drawing the live-phase plate and the
band is declared rather than guessed.

## Same drive, three more bands now witnessed — NOT yet built

The 2026-07-28 drive also banked the first frames of three chromes this file had listed as
unwitnessed. They are in `screenshots/wine-captures-2026-07-28-knockout-decided/`:

* **`04_facup_semifinals_finalists.png`** — the F.A. Cup SEMIFINALS band with both
  `FINALIST` plates FILLED. Single-leg ties at a neutral ground (the venue is the panel's
  own first row: `Hillsborough`, `Anfield`), so the domestic semifinal card is a different
  shape from the euro two-legged one.
* **`05_cocacola_semifinals_twolegs.png`** — the Coca-Cola SEMIFINALS with BOTH legs drawn
  (`1ST LEG` at `Selhurst Park`, `2ND LEG` at `Ewood Park`) and both `FINALIST` plates
  filled. This independently re-confirms the 07-27 model fix (Coca-Cola semis are
  two-legged) from a second career.
* **`06_cocacola_final_winner.png`** — the Coca-Cola FINAL: the cup trophy art,
  `MATCH RESULT` over `STADIUM Wembley`, an empty `REPLAY RESULT` panel, and the filled
  `WINNER` band with the champion's kit in a laurel wreath.

Building these three is a chrome-bake pass of the same shape as the euro cards/final build;
until then those competitions' 2/1-tie phases still fall back to the SORTEO card.

`screenshots/` is LOCAL, so all five frames of that drive are ALSO banked in the tracked
reference tree — **`tools/re/refs/knockout-2026-07-28/`** (its README maps each file to the
cell it first witnesses). The euro one is the gate reference and sits with its siblings in
`knockout-2026-07-26/`.


## The kit list, as built (2026-07-28)

Layout 2 is the form the original switches to for a round of **5-8 ties**: 22 px rows, a
17x20 `ridi` kit blitted each side of the two names, and the SAME column pair as the
compact list. Three witnesses, two competitions, two careers, BOTH column sets:

| frame | what it witnesses |
|---|---|
| `09_comp_cwc.png` | European, 8 ties, drawn -- every score cell empty |
| `01_uefa_1_8finals_leg1_played_1997-12-07.png` | European, 8 ties, `1ST LEG` filled |
| `13_cocacola_r4_KITLIST_PLAYED_1997-12-01.png` | **DOMESTIC**, 8 ties, `RES.` filled, winners inked |

The domestic one is new to the reference tree this session (it was local-only in
`screenshots/wine-captures-2026-07-26-cup-draw-then-play/`); a sweep of the whole local
corpus for this layout's signature found **20 frames and every one of them has EIGHT
ties**, which matters below.

### Geometry (all spans inclusive, design space 640x480)

| element | span |
|---|---|
| panel | `x6..493` -- three columns WIDER than the compact list's x6..477, because a round this small never scrolls and the scrollbar column is simply part of the panel |
| panel top | border + gradient title band + the white gap + the first row rule, `y125..153` |
| one row unit | `y154..183`: 22 content rows, the black rule, 6 white rows, the next rule. Pitch **30** |
| the tail | `y386..398` on an 8-tie round: the rule under the last row, 10 white rows, the 2-row bottom border |
| cells, European | kit L `15..42` · home `44..164` · away `167..287` · kit R `289..316` · 1ST LEG `319..372` · 2ND LEG `374..427` · AGGR. `429..482` |
| cells, domestic | kit L `15..42` · home `44..192` · away `195..342` · kit R `344..371` · RES. `374..427` · REPLAY `429..482` |
| grounds | kit wells `(140,160,180)` · name cells `(100,120,140)` · score cells `(120,120,160)` · the LAST score cell `(100,100,140)` |
| the ridi kit | `(+5, +1)` inside its 28x22 well -- the unique best offset on all 48 witnessed cells |
| text | pen top `row_top + 6` for every name and every score digit; the cell-relative x anchors are the compact list's OWN, unchanged (`-4` / `+4` / `+21` / `+24` / `+31`), and all reproduce exactly here |
| inks | through `(255,223,0)`, out `(42,63,85)` -- the compact list's rule, re-verified on the DOMESTIC witness (a level tie inks neither club; a decided one inks the winner AND his own goal digit) |

**The row grounds do NOT alternate.** All 24 witnessed rows carry the same five grounds,
which is why one baked row strip serves every row. Outside the content rects the three
frames are byte-identical, so the strip is the original's own pixels.

**No witness shows the MANAGER's own tie in this layout** (Bolton W is in none of the 20
frames' ties), so the port draws it like any other row rather than importing the compact
list's `mine` grounds. Recorded, not invented.

**5-7 ties are neither witnessed nor reachable.** Every competition in the port halves
16 -> 8 -> 4 -> 2 -> 1, so 8 is the only size this layout can be raised at; the rows are
drawn top-aligned from the compact list's own witnessed `BODY_TOP` and the tail follows
the last row, which is exact at 8.

Gate: `diff_knockout_parity.py` cases `knockout_uefa_kitlist`, `knockout_cwc_kitlist` and
`knockout_cocacola_kitlist` -- **0 px outside the barra kit and the 16 kit wells**.

## The outline pass is DITHERED ON SCREEN PARITY (2026-07-28) -- the 07-27 note was wrong

The 2026-07-27 entry below concluded the on-sprite pass "is NOT position-constant". That
is false, and the kit list is what proved it: the pass is position-constant **per absolute
screen parity**, exactly like the phase paginator's disabled arrow.

The evidence is clean because this layout puts the same sprite bank in three wells at two
parities: the left well (`x15`) and the EUROPEAN right well (`x289`) are both odd and agree
pixel for pixel across all three witness frames, while the DOMESTIC right well (`x344`,
even) disagrees with them at **222 of the well's 616 positions**. Voting the overlay per
side -- which is what the bracket does -- therefore produced an almost empty right-hand
overlay; voting it per `(well_x + row_top) & 1` produces two full ones.

Measured effect on the gate, same shots, same witnesses:

| case | kit residual, per-side vote | per-parity vote |
|---|---|---|
| `knockout_uefa_kitlist` | 556 | **68** |
| `knockout_cwc_kitlist` | 552 | **64** |
| `knockout_cocacola_kitlist` | 548 | **28** |

**What this does NOT close: the 48x64 MINIESC bevel.** All four bracket wells sit at one
parity (`x22`/`x416` with tops 113/193/273/353, all odd sums), so per-parity baking cannot
help there -- the bracket's residual is club-varying silhouettes, not dither. A dilation
model was measured against all 16 witnessed bracket cells and REJECTED: the union kernel
`0<=dx,dy<=3` covers 4090 of the 4098 outside-silhouette pixels but paints **1988** the
original leaves white, and no single shift explains more than 94.8 %. The pass is a real
bevel with its own ramp, and it still needs the code.

## The FINALIST plate, FILLED -- witnessed 2026-07-28

`tools/re/refs/knockout-2026-07-28/12_facup_semifinals_FINALISTS_1998-04-11.png` and
`13_cocacola_semifinals_TWOLEGS_1998-04-11.png` are the first frames that show a DECIDED
semifinal, and they correct the cards layout twice:

1. **The plate's fill.** The port printed the advancing club as a GDI string centred in the
   plate, in the WINNER band's ink -- flagged as declared-OURS since the build. The
   original puts the club's **24x32 `nano` kit** at `(plate_x0 + 2, 377)` and prints his
   name **proman10** at `(plate_x0 + 43, 380)`, LEFT-aligned, in THAT CARD's own name ink
   (blue for SEMIFINAL 1, green for SEMIFINAL 2). All four witnessed plates land exactly.
2. **Nothing in this layout is inked yellow.** Both frames are played out, and every club
   name and every goal digit prints in the card's own ink -- including the winner's. The
   port's `C_THROUGH` here was an inference from the LIST layout; the frames refute it.

Gate: `diff_knockout_parity.py` case `knockout_cocacola_semis_done` -- 0 px outside the
barra kit, the rail (career state), the ridi icons, the two nano kits and the paged-back
paginator plate. That last one is the same declared band the decided BRACKET carries: on a
paged-back frame the label plate's white surround reaches `x310..336` on rows 85 and 109
where the live-phase frame the band was cut from has its black border. One witness of each
state is not a rule, so it is declared rather than guessed at.
