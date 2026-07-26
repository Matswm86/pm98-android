# The knockout views — RESULTS → any cup, every layout the original switches between

**Status: WITNESSED and measured 2026-07-26, NOT BUILT.** The app has no knockout screen at
all: `Main._show_euro_group_screen` raises `EuroGroupScreen` for the European group phase
(0 px, `euro_league_screen_re.md`) and there is nothing for a knockout round in any
competition. This doc is the evidence and the geometry, so the build has no guessing in it.

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
and the advancing-club highlight in this layout are still open. The phase paginator can be
walked back to a finished phase, which is how to get it.

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

## What the port needs before this can be built

* the bracket's `AGGR.` cell with a decided tie (page the phase paginator back);
* the played FINAL, for the `WINNER` band;
* the layout switch itself: count-driven for 1/2/3, round-driven for 4/5 — confirm by
  finding a 4-tie round the original does NOT draw as a bracket, if one exists.
