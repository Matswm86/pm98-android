# PM98 — SEASON PLAYTHROUGH AUDIT (2026-07-25)

> **RESCUED INTO THE REPO 2026-07-26.** This file previously existed only in a session
> scratchpad under `/tmp` (referenced by
> `handoff-pm98-season-audit-and-manutd-reference-run-2026-07-25.md` as "read this first")
> and would have been lost to garbage collection. Copied verbatim below; only this banner
> was added.
>
> **Status of the findings as of 2026-07-26** (verified against HEAD `4076800`, see
> [`AUDIT_COMPLETE_2026-07-26.md`](AUDIT_COMPLETE_2026-07-26.md)):
> - **S1** (cups unreachable) — CLOSED 07-25 for the DRAW card (`Career._queue_cup_draw` →
>   `Main._pop_cup_draw`). **But the knockout/Europe VIEWS are still unreachable** — see the
>   2026-07-26 audit's reachability finding.
> - **S2** (lower divisions 39/46 rounds) — CLOSED 07-25.
> - **S3** (career not seed-reproducible) — **OPEN.** 12 `randomize()` sites in `Career.gd`
>   (lines 500, 528, 1467, 1988, 2187, 2250, 2388, 2629, 2742, 3292, 4052, 4109).
> - **S4** (no matchday economy) — CLOSED 07-25 (witnessed-true rebuild).
> - **S5** (European ties on the legacy engine) — **OPEN.** `MatchSim.gd:105-110` fallback path.
> - **S6** (U.E.F.A. Cup winner discarded) — CLOSED 07-25.
> - **S7** (cup/Europe field shapes) — PART-CLOSED: 92-club domestic cups shipped 07-25;
>   the European 24-club / 6-group / 2-qualifier shape is unconfirmed.
> - **S8** (no retirement / ageing intake) — **OPEN.** No retirement mechanic in `app/scripts`.

> **What this is.** Every previous audit in this repo is screen-shaped: one screen, one
> frame-diff. This one plays the game. A whole Manager League season was driven in the
> Android port — bootstrap, 38 league weeks, both domestic cups, all three European
> competitions, the board review, the rollover, and the first league match of 1998-99 —
> and the same career was driven in the real `MANAGER.EXE` under wine as the reference.
>
> Verdict legend, as in [`APP_VS_SPEC_AUDIT.md`](APP_VS_SPEC_AUDIT.md): **INVENTION**
> (not traceable to source — must fix) · **DIVERGENCE** (source known, app does something
> else) · **GAP** (honest, source unavailable) · **DEFECT** (app disagrees with itself —
> a bug, not a fidelity question).
>
> **No fixes were applied.** Findings only.

Audited baseline: commit **`af4f1b5`** (the tree as of 2026-07-25 14:52). Work landing
after that — e.g. the youth binary-exact port `55fa5df` — is not covered.

Club: **Bolton W**, manager **mwm** — the same career as
`screenshots/parity-run-2026-07-16/`, so that run's 68 original frames stay usable.

## How it was run

| Side | Harness | Command |
|---|---|---|
| Port, model | `app/tests/season_e2e_report.gd` (new) | `XDG_DATA_HOME=… ~/godot462 --headless --path app --script res://tests/season_e2e_report.gd` |
| Port, UI | `PM98_SEASON_SHOT` mode in `Main.gd` (new) | run as the normal app on Xwayland `:7`, `--rendering-driver opengl3` |
| Port, statics | `tools/re/reachability.py` (new) | transitive call-graph reachability over `Main.gd` |
| Original | `tools/re/wine/season_loop.sh` + `season_state.py` (new) | on an isolated wineprefix + desktop `pm98audit` |

Everything ran from an isolated copy of the repo; the live tree was never written to.
This box has **no Xvfb** — the UI runs used a dedicated Xwayland `:7`, the pattern
`tools/re/wine/README.md` already documents for a seatless run.

---

## The headline

The port plays a season through to the end and starts the next one. The manager's own
league season is solid: 38 rounds, correct fixtures, real scorers, a correct table, a
board verdict, a working pyramid rollover with promotion, relegation and play-offs, and
a first match of 1998-99 that kicks off cleanly.

**What is broken is everything that happens around the manager's own 38 fixtures.**

---

## Findings, most severe first

### S1 — DEFECT · every cup and every European competition is unreachable in a played career

`Main._show_competitions()` (`app/scenes/Main.gd:3493`) has **zero callers**. It is the
only caller of `_open_competition()` (`:3557`), which is in turn the only live route to
`_show_cup_screen`, `_show_charity_shield`, `_show_one_off_final`, `_show_comp_result`
and `_show_cup_group_placeholder`. Every other call site (`:519-592`) sits inside
`_cup_shot()` — the env-gated screenshot harness.

Confirmed a second way by transitive reachability (`tools/re/reachability.py`, roots =
`_ready` / `_boot` / `_menu_action` / signal targets, `_*_shot` excluded):

```
UNREACHABLE IN A PLAYED CAREER: 3
  CompResultScreen   [ORPHANED]  <- _show_comp_result
  CupDrawScreen      [SHOT-ONLY] <- _cupdraw_shot, _show_cup_screen
  CupScreen          [ORPHANED]  <- _show_cup_group_placeholder, _show_one_off_final
```

And confirmed a third way by running the game: the `PM98_SEASON_SHOT` walk fired all 16
hub routes; each mounts exactly one screen, and **none of them is a cup**.

```
news→NewsScreen  staff→StaffScreen  fixtures→FixturesScreen  opponent→RivalScreen
table→LeagueTableScreen  lineup→LineupScreen  finance→FinanceScreen  board→DirectivaScreen
stadium→StadiumScreen  buy→TransferScreen  tactics→TacticsBoardScreen  sell→SquadScreen
results→ResultsScreen  save→SaveGameDialog  match_options→MatchOptions  options_audio→OptionsPanel
```

`CupDrawScreen.gd` is the SORTEO screen shipped at **0 differing pixels of 307,200**
(commit `e6728bb`, yesterday). It cannot be opened by a player.

You also never *play* a cup tie. `Career._play_due_cup_rounds` (`Career.gd:814`) is
called from inside `advance_week` (`:798`) and resolves every domestic and European tie
silently. Over the audited season the F.A. Cup ran 5 rounds, the Coca-Cola Cup 5, the
European Cup 3, the U.E.F.A. Cup 4 and the Cup Winners' Cup 4 — all invisible.

**How it got here** is recorded in the code: `Main.gd:4392-4394` says the FIXTURES icon
now opens the source-true CALENDAR, "replacing the rejected BrowseScreen
'COMPETITIONS'/'SEASON FIXTURES' SUBSTITUTE". The substitute was correctly removed; the
real replacement route was never wired, and `_show_competitions` was left in the tree.

### S2 — DEFECT · the three lower divisions never finish their season

`_play_division_round` (`Career.gd:1304`) plays exactly **one** round of each other
division per manager week. The manager's Premier season is 38 rounds; a 24-club division's
fixture list is 46. Measured at season end:

| tier | clubs | rounds in fixture list | rounds played | unplayed |
|---:|---:|---:|---:|---:|
| 1 (manager) | 20 | 38 | 38 | 0 |
| 2 | 24 | 46 | 39 | **7** |
| 3 | 24 | 46 | 39 | **7** |
| 4 | 24 | 46 | 39 | **7** |

15% of every lower-division season is never played, and `_pyramid_rollover`
(`Career.gd:1394`) then computes automatic promotion, the play-off pool and relegation
from that truncated table. The symmetric case is worse: a Division One career (46 weeks)
would run the Premier out of fixtures after 38 and leave it idle for 8 weeks.

### S3 — DEFECT · a career is not reproducible at a fixed seed

Two runs of the same driver at seed `19970809`, same club, same code:

| | run A | run B |
|---|---|---|
| final league position | 14 | 14 |
| manager's 38 weekly results | *identical* | *identical* |
| preseason friendlies | differ | differ |
| all four final tables | differ | differ |
| squad after rollover | **13** | **19** |
| first match of 1998-99 | 1-1, scorers ALJOFREE 5' / Abou 53' | 1-1, scorers Impey 24' / Sellars 46' |

Root cause, proven by kill-test rather than inspection: `Career.gd:387`
(`yrng.randomize()` — the academy intake and staff pool) and `Career.gd:414`
(`form_rng.randomize()` — the morale/fitness roll for every player). Seeding **only**
those two lines made two fresh runs **byte-identical** across the whole season, the
rollover and the season-2 opener. Both were then reverted; the numbers above are from
the shipped code.

Two other unconditional wall-clock seeds are in the same class and did not fire on this
path: `Career.gd:1263` (`ensure_divisions`), `:1734` (`board_review`'s headhunt roll),
`:2366` (`promote_youth`). The remaining `randomize()` calls are `if rng == null`
fallbacks and are fine. Two sites (`:724`, `:3377`) already do the right thing — they
derive a sub-seed from the caller's — so the pattern was understood, just not applied
everywhere.

**Fairness note:** the *original* is also non-deterministic run to run — `FUN_004f8f60`
seeds the CRT with `srand(time(NULL) * 0x7b)` (`seasonend_flow_re.md:33-35`), and we saw
it: the Charity Shield came out Man Utd on one boot and Chelsea on penalties on the next.
So this is **not** a player-facing fidelity bug. It matters because the port's own
acceptance machinery — save/load equivalence, the M5 kill-test, any app-vs-original
parity claim — assumes a seed pins a career, and it does not.

### S4 — INVENTION · there is no matchday economy; the bank moves by a constant every week

`cash += weekly_net` (`Career.gd:752`), where `weekly_net` is derived once from
`FinanceModel.summary()` — a **whole-season** budget in which the gate is
`attendance × ticket × 19 home games` (`FinanceModel.gd:83`) spread flat across the year.

Measured over the audited season, every single week:

```
wk 1 Manchester Utd. (A) 1-0  +£305,076      wk 2 Barnsley       (H) 0-0  +£303,576
wk 3 Blackburn R.    (A) 1-2  +£300,576      wk36 Tottenham H    (H) 1-2  +£305,076
wk37 Aston Villa     (A) 1-1  +£303,576      wk38 Leeds Utd      (H) 2-1  +£305,076
```

Home and away are indistinguishable. Cash rose monotonically from £4,509,531 to
£16,029,869 — an £11.5M profit in one season at a club whose board objective was to
avoid relegation.

A second season was run as **Manchester Utd.** to check this was not a Bolton artefact.
It is not, and the richer club makes the point sharper. The weekly baseline is a flat
**£265,875 whether the fixture is home or away** (wk10 H +265,875 · wk11 A +265,875 ·
wk16 H +265,875 · wk17 A +265,875 · wk33 A +265,875 · wk36 H +265,875). The spikes that
do occur — +£891,375, +£1,281,000, +£2,775,875 — are cup and European prize money and
transfer fees, and they land on **away** weeks as readily as home ones (wk4 A +891,375,
wk22 A +1,281,000). So there is real event income, but **no gate**: a full Old Trafford
and an away trip are worth the same to the bank.

*(Recorded because I got this wrong first time: comparing raw home-week and away-week
means for Man Utd shows £682,744 vs £417,355, which looks like a gate. It is not — it is
the prize spikes happening to fall on more home weeks. The baseline is the evidence.)*

### S5 — DIVERGENCE · European ties are simulated by the invented legacy engine, not the byte-exact one

37 `[MATCHSIM_FALLBACK]` warnings in one season, every one of them from
`Cup.play_group_matchday` (`Cup.gd:367`) via `_play_due_cup_rounds`:

```
[MATCHSIM_FALLBACK] #1: XI failed _usable (h=11 ok=true, a=0 ok=false)
  -> legacy result for 40 v 1047
```

Foreign clubs carry no usable XI, so `MatchSim` drops to `MatchEngine` — the engine whose
own header says its constants are ours. Not one European tie is played by the
oracle-validated `Pm98StatMatch`. `test_career.gd` asserts zero fallbacks and passes,
because it only checks the manager's own league fixtures.

### S6 — DIVERGENCE · the U.E.F.A. Cup winner is played for and then thrown away

`_capture_euro_honours` (`Career.gd:3736-3747`) captures `european_cup` and
`cup_winners_cup` only. The U.E.F.A. Cup runs its four rounds and its champion is
discarded at the rollover. The original lists "U.E.F.A. Cup" won/runner-up as one of the
eight trophy lines on the END OF THE SEASON report (`seasonend_flow_re.md:116`), and
commit `eb009ae` captured a **U.E.F.A. CUP CHAMPION** card from the real game yesterday.

### S7 — DIVERGENCE · cup fields are one division wide

From the live brackets: F.A. Cup `n0=20`, Coca-Cola Cup `n0=20` — the 20 Premier clubs
only. The real F.A. Cup is contested by all 92 league clubs (plus non-league), which is
where giant-killing comes from; `Cup.gd:25-29` already flags the abstraction. European
fields are `n0=16`, against the original's **24 clubs in six groups of four plus two
qualifying rounds** (`euro_league_screen_re.md:78-83`).

### S8 — GAP · no player ever retires

Grep across `app/scripts` and `app/scenes` returns zero retirement logic.
`advance_season` ages the manager's squad and every AI roster by one year
(`Career.gd:3319`, `:3366`) with no upper bound. Measured across the rollover: the squad's
oldest player went 33 → 34, and all nine leavers left on contract expiry
(`contract_years: 1`), none by age:

```
Fairclough 33 · Sheridan 33 · Holdsworth 29 · Salako 28 · Taggart 27
Johansen 26 · Gunnlaugsson 24 · Thompson 24 · Todd 23
```

There is also no new-generation intake — squads are topped up only from the academy, the
free-agent pool and the talent pool. Over several seasons a career ages into a dead end.
Whether the original has a rollover ageing/retirement pass is **un-located**
(`seasonend_flow_re.md:181-186` lists `FUN_005865b0`, `FUN_005c1df0`, `FUN_00443180` as
un-chased), so the fix needs the RE first — this is a genuine gap, not an invention.

---

## App vs the original, driven side by side

Driving the real `MANAGER.EXE` to the same point produced these direct comparisons.

### O1 — DIVERGENCE · the board objective is the wrong kind of thing

The original's **START OF SEASON** sheet gives every club one of four category labels —
`Champion` / `U.E.F.A.` / `Mid Table` / `Avoid Relegation`. Bolton W's is
**"Avoid Relegation"**.

The port's objective for the same club is **"Finish 13 or higher"** — a position, not a
category. (Evidence: `orig/p4.png` this session vs `career.objective_text`.)

### O2 — DIVERGENCE · the fixture calendar is not the original's

Original, Saturday **9 August 1997**, Premier Week 1: **Bolton W v Southampton**.
Port, week 1: **Bolton W at Manchester Utd.**

The port builds its calendar with `SeasonSim._round_robin` and dates it
`season_start + round*7`. The real 1997-98 calendar lives in the un-enumerable
`PCF5DAT.PKF` (`SOURCE_INVENTORY.md` §5.1) — so the *dates* are a real GAP, but the
*pairing order* is invented and could be sourced the day PCF5DAT opens.

### O3 — the original names every club's manager on START OF SEASON

Wenger, Gregory, Wilson, Hodgson, Vialli, Strachan, Lombardo, Smith, Kendall, Graham,
O'Neill, Evans, Ferguson, Dalglish, Atkinson, Jones, Gross, Redknapp, Kinnear, Barnard —
a full column, from the game's own data. Worth checking against the standing note that
`game_db`'s club `manager` field is un-decoded.

### O4 — screens the original raises unprompted during a season

Captured live this session, in order, none of which the port's own season chain raised:

1. **CHARITY SHIELD CHAMPION** card (`orig/p2_after_champs.png`) — OK at (115,352)
2. **START OF SEASON** objectives sheet (`orig/p4.png`) — CONTINUE at (578,428)
3. **MANAGER MENU** hub (`orig/p5_hub.png`)
4. **PLAYERS OF THE MONTH (AUGUST)** (`orig/season/w03_t4.png`) — with live
   PREMIER / FIRST / SECOND / THIRD division tabs, OK at (570,359)

**These coordinates were previously undocumented.** The 2026-07-25 drive
(commit `eb009ae`) stalled at week 41 of 42 partly because the click list did not contain
them; the first pass of this audit's driver ground to a halt at the August awards sheet
for exactly the same reason. They are now in `tools/re/wine/season_loop.sh`.

---

## Corrections to my own earlier readings

Recorded so nobody re-derives them as findings:

- All-away fixtures, `?` opponents, zero injuries and `0:0` goal columns in the first
  driver run were **my** field-name errors (`advance_week` returns
  `home_id`/`away_id`/`manager_home`, the table row uses `GF`/`GA`, the player field is
  `injured_weeks`). Corrected; the real data is above.
- "38 of 56 scenes never mounted" from the UI walk is **not** a reachability result. That
  harness never taps inside a screen and never plays a match through the UI. The
  defensible number is the 3 in S1.
- A `CompResultScreen` parse error on first boot was a stale
  `global_script_class_cache.cfg` in my rsync'd copy, fixed by `--headless --import`. Not
  a project bug.

---

## Status of the reference run — BLOCKED at week 8, and here is exactly why

The wine drive booted, navigated the full career-entry chain, reached the MANAGER MENU
hub and played to **Tuesday 23 September 1997, Premier Week 8** (109 frames in
`orig/season/`). It is then blocked, permanently, by the original's own XI-validity gate:

> **"The initial line-up is not correct. A player is either banned or injured."**

This is the same wall the 2026-07-25 career drive (commit `eb009ae`) hit. Two causes were
found and one was fixed:

1. **Fixed — the alert's OK is at (432,268), not (458,264).** Earlier drives clicked just
   outside the button, so the modal never dismissed and the drive ground in place. Also
   newly pinned: the monthly awards sheets' OK at **(570,359)**, the CHARITY SHIELD
   CHAMPION card's OK at **(115,352)**, START OF SEASON's CONTINUE at **(578,428)**, and a
   second info modal on LINE-UP — *"Players banned will not be available for the next
   match."* — whose OK is at **(500,263)** and which covers the player rows until cleared.
2. **Not fixed — the XI swap cannot be scripted yet.** Dismissing the alert is not enough;
   the original will not advance the week until the banned man is out of the XI. Detecting
   *who* is banned works reliably (`tools/re/wine/lineup_offender.py`: the flagged row is
   drawn on a gold `(212,191,85)` plate with a black `1 MATCH` band around x=250 — it
   correctly picked Holdsworth on row 9). What does not work is putting someone else in
   his place. Tapping the flagged row and then each substitute row in turn leaves the XI
   unchanged.

   The reason is already written down in this repo: `lineup_screen_re.md:85` says the
   line-up edit interaction is **RECONSTRUCTED**, and *"the click→swap dispatch function
   itself is **not yet** [reversed]"*. So the true hit rects and the tap protocol are
   unknown, and a blind select-then-swap does not reach them.

**Consequence for this audit.** The season boundary and the 1998-99 opener remain
**unwitnessed in the original**, exactly as commit `eb009ae` recorded. Everything in this
document that concerns the rollover — S2, S8, and the season-2 half of O1/O2 — is
therefore reported against the port's own behaviour and the RE docs, and is **not** claimed
to be a diff against observed original behaviour.

**What unblocks it** (in order of cost):
- Reverse the LINE-UP click→swap dispatch (`lineup_screen_re.md` "not yet" item). This is
  the real fix and it also closes a standing RE gap.
- Or drive the career with a squad that cannot trip the gate — the gate fires on a banned
  or injured starter, so a save whose XI is all-fit at every check would pass. That needs
  the SAVE GAME dialog wired into the driver so a clean state can be restored on each trip.
- Or poke the suspension/injury counters in the live process (the `winedbg`/`/proc` route
  the M4/M5 harnesses already use) to keep the XI legal for the length of the drive.

---

# WHAT REMAINS

Two evidence tiers, kept apart on purpose. **Tier A** was measured in this session.
**Tier B** is what the repo's own RE docs record as open; each line below was spot-checked
against its cited source today, but not re-derived.

## Tier A — found and proven this session

| # | Item | Where | Size |
|---|---|---|---|
| 1 | Wire a route to the cups + Europe; retire the orphaned `_show_competitions` | `Main.gd:3493`, `:3557`, `MenuScreen` route table `:4249` | small — the screens exist and are pixel-exact |
| 2 | Present cup ties as matches instead of resolving them silently | `Career.gd:798`, `:814` | medium |
| 3 | Run lower divisions to the end of their own fixture list | `Career.gd:1304`, `:1338` | small, but changes every promotion/relegation outcome |
| 4 | Make a seeded career reproducible | `Career.gd:387`, `:414` (+ `:1263`, `:1734`, `:2366`) | two lines for the main fix |
| 5 | Give the finance model a matchday: per-fixture gate, home ≠ away | `Career.gd:752`, `FinanceModel.gd:62-100` | medium |
| 6 | Give foreign clubs a usable XI so European ties leave the legacy engine | `MatchSim.gd:105`, `Cup.gd:367` | medium |
| 7 | Capture the U.E.F.A. Cup winner at the rollover | `Career.gd:3736-3747` | trivial |
| 8 | Widen the cup fields (F.A. Cup across all 92; Europe 24 in 6 groups + 2 qualifiers) | `Cup.gd:25-29`, `Career.gd:3666-3670` | medium; Europe's shape is already specified in `euro_league_screen_re.md:78-83` |
| 9 | Objective as the original's four categories, not a position | `Career.objective_text`, `SeasonStartScreen` | small — **blocked on nothing**, the labels are witnessed |
| 10 | Ageing / retirement at the rollover | `Career.gd:3319`, `:3366` | **blocked**: needs `FUN_005865b0` / `FUN_005c1df0` / `FUN_00443180` reversed first |
| 11 | Real fixture pairings for the new season | `SeasonSim._round_robin`, `Career.gd:3426` | **blocked** on `PCF5DAT.PKF` for dates; pairings could come sooner |

## Tier B — recorded open in the repo, verified present today

- **EURO. LEAGUE screen — specified, not built.** `euro_league_screen_re.md:3`:
  *"Status: CAPTURED AND SPECIFIED, NOT YET BUILT."* The group phase still renders on
  `Main._show_cup_group_placeholder`, which S1 shows nobody can reach anyway.
- **FINANCE detail views — not built.** `finance_screen_re.md:85`:
  *"NOT YET BUILT (flagged): the INCOME / EXPENSES detail views and the PER WEEK…"*;
  `FinanceScreen.gd:246` *"We hold no per-week history"*. Same root cause as S4.
- **The byte-exact positional match engine is not connected to anything.** Grepping
  `Pm98Driver|Pm98Outer|Pm98Match|Pm98Movement` across `app/scenes/`, `Career.gd` and
  `MatchSim.gd` returns **zero hits** — 395 KB of oracle-validated port, test-only.
  What the player watches is `MatchCommentary` timing.
- **M5 parity frontier moved backwards yesterday.** `M5_S56_WIDE_FIELD_DIFF.md:4` states
  the "22/22 + ball PASS over clk 270-823" verdict *"is about x and y and nothing else"*;
  widening the differ found `orient17c`/`orient180` forking from clk 657 and the ball
  forking at clk 721. Against a 14,400-clk match, parity is on ~4% of one match, on two
  fields.
- **MULTAS, SECRETARIO, CREDITOS have no implementation.** Grep across `app/scenes` +
  `app/scripts`: `multas` 0 hits, `creditos` 0 hits, `secretario` 1 hit and it is a
  sprite-folder name in `PMChrome.gd`. (`fines` appears in `FinanceScreen.gd` /
  `OffersScreen.gd`, so the *money* exists; the screen does not.)
- **Never run on a device.** No APK from this build has been played; this box cannot run
  one.

## Doc staleness — three files now mislead

**`docs/REMAINING.md` (dated 2026-06-20) is the worst offender** and should be replaced by
this file. Verified wrong today:

| REMAINING.md says | Actually |
|---|---|
| `:95-99` "PKF sprite decompression … Only badges are out so far. This is the single biggest visual unlock." | Done. `app/art/` holds **1,228 faces, 961 kits, 509 flags, 60 screens, 45 icons**. |
| `:103` "English-league squads are sparse (bio-interleaved record format not fully cracked)" | Done. **All 92** English league clubs field ≥11 players; 9,547 players in `game_db.json`. |
| `:65-67` match-tick driver `FUN_00598740` open; `:56-64` collision builder open | Both ported — `Pm98Driver.gd` (18 KB), `Pm98CollBuilder.gd` (42 KB). |
| `:43` "Match engine bit-exact RE — ~90%" | Function-level porting is far along; *behavioural* parity is two fields over ~4% of one match (see M5 above). The percentage reads as progress-to-done and is not. |

`docs/ROADMAP.md` — Phase 0 still has unticked boxes for PKF decompression, palettes and
image export, all long since done; Phase 2 still says "Engine choice: Godot 4 … Decide at
start of Phase 2".

`docs/re/APP_VS_SPEC_AUDIT.md` — already self-declared stale by the 2026-07-23 handoff.
Its §A5 entry ("the league table is not yet computed from a real season loop") is closed;
this audit ran that loop.

## Artifacts

```
audit-out/season_report.md         the port's season, week by week
audit-out/season_report_runA.json  full machine-readable report, run A
audit-out/season_report_runB.json  run B — the S3 determinism evidence
app/shots/season_screens.json      hub route → screen map
orig/season/*.png                  the original, frame by frame
orig/season_manifest.tsv           week / step / classifier verdict
```
