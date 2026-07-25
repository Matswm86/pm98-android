# REFERENCE RUN — Manchester Utd. 1997-98, played by hand (2026-07-25)

> **What this is.** The original `MANAGER.EXE` driven through a **complete season** by a
> human, with a passive recorder banking every screen change. It exists because every
> automated drive in this repo dies at the same wall — the XI-validity gate ("The initial
> line-up is not correct") — and so **the season boundary had never been witnessed**. Commit
> `eb009ae` reached week 41 of 42; the 2026-07-25 audit reached Premier week 8.
>
> This run reached the last league week of 1997-98, the entire end-of-season sequence, the
> rollover, and into **October 1998** of the following season.
>
> Verdict legend as in [`APP_VS_SPEC_AUDIT.md`](APP_VS_SPEC_AUDIT.md): **INVENTION** ·
> **DIVERGENCE** · **GAP** · **DEFECT**. Findings are numbered **R1-R17** and continue the
> season audit's S/O series.
>
> **No fixes were applied.** Findings only.

Club **Manchester Utd.**, manager `MWM`, **RESULTS** match mode. Chosen because as 96-97
runners-up they contest the Charity Shield and enter the European Cup, so the run also
witnesses the European screens the audit was missing.

## The capture

| | |
|---|---|
| frames banked | **775** (one per screen change, deduped by average hash) |
| distinct screens curated | **238** -> [`screenshots/refrun-manutd-1997-98/`](../../screenshots/refrun-manutd-1997-98) |
| of which never witnessed before | **179** (`novel/`) |
| already-taught screens | **59** (`named/`) |
| pointer samples | ~15,000, window-relative, recovers the click target per transition |
| raw frames + manifest | `out/refrun-manutd-9798/` (gitignored, durable) |

Harness: [`tools/re/wine/record_play.py`](../../tools/re/wine/record_play.py) — passive, never
clicks, names every frame with `autodrive.identify()` and prints **NEW SCREEN** when a frame
matches nothing taught. Ran on an isolated wineprefix
(`~/MWM-AI/data/pm98/wineprefix-play`, desktop `pm98play`) with `TRANSITIONS: OFF` so every
banked frame is a settled screen rather than a mid-fade blit.

Full finding detail, with frame numbers and evidence, is in
`out/refrun-manutd-9798/FINDINGS.md`. This file is the summary and the work list.

---

## The headline

**The original's economy is punishing and event-driven; the port's is a flat constant with
the wrong sign.** Three independent measurements say so (R6, R9, R16), ending in a mechanic
the port does not have at all: you can go broke managing Manchester United.

**Second headline:** the end-of-season sequence is eight screens long and the port has none
of it, while the port's own "end of season" screen is an invention that also steals the
original's screen name (R15).

---

## Findings

| # | Verdict | Finding | Port site |
|---|---|---|---|
| R1 | DIVERGENCE | Domestic cups span all 92 clubs and Premier clubs enter at **Round 3**. Witnessed: Bradford City (Div 1) **won the F.A. Cup**, Wycombe W. (Div 2) reached the Coca-Cola final. | `Career.gd:200` `LEAGUE_CUP_OPTS`, `Cup.gd:25-29` |
| R2 | GAP | Cup **replays** exist (MATCH / REPLAY buttons on domestic draws). | `Cup.gd` models two legs instead |
| R3 | DIVERGENCE | Hub badge reads **"Euro. Cup / 1/8 Final"** through the whole group phase (1 Oct, 5 Nov, 26 Nov — label never advances). | `Cup.gd:167` emits `"Group Matchday %d"` |
| R4 | DEFECT | The 0-pixel `CupDrawScreen` is raised **unprompted** by the original; the port has no live route to it. Confirms audit S1. | `Main.gd:3493`, `Career.gd:814` |
| R5 | GAP | FINANCE **INC.+EXP. / PER WEEK** is a real per-week ledger with 7 income and 11 expense lines + a 52-week balance graph. | `FinanceScreen.gd:246` "no per-week history" |
| R6 | INVENTION | **channelTV**: the original sells broadcast rights per home match, and the fee is that week's TELEVISION line. Per-competition constant: Premier **£90,000**, Charity Shield **£187,500**, European Cup **£375,000**. | zero hits for `channel`/`broadcast` in `app/` |
| R7 | DIVERGENCE | **Intercontinental Cup** fires in the **first December week** (real 1997 date), against the actual Libertadores holder, and is presented as a card. | `Career.gd:3756` plays it at season open, opponent "approximated by the strongest South American club" |
| R8 | GAP | The cup-draw screen has **two panel forms**, and the switch is **list length**: <=16 ties -> two columns with kit badges; >16 ties -> one centred line per tie, scrollable. Buttons are competition-dependent: MATCH/REPLAY domestic, **1ST LEG/2ND LEG** European. | single-form `CupDrawScreen` |
| R9 | INVENTION | **The weekly economy, decomposed.** Flat weekly cost £233,942 (wage £226,923 + staff £7,019) every week; home matchday adds TICKETS £364,980 + TELEVISION + bonus £5,000. Away week = **-£233,942**. Cash fell £9,613,964 -> £3,283,406 across the season. | `Career.gd:752`, `FinanceModel.gd:83` — flat +£265,875 every week, £4.5M -> £16M |
| R10 | DIVERGENCE | Transfer deadline warnings at **2 weeks and 1 week** out (Sun 8 Mar 1998, week 32 -> deadline week 34). **No deadline day event.** | `DEADLINE_TAIL := 6` should be **4**; no warning is raised |
| R11 | DIVERGENCE | **European Supercup** fires in **March**, is two-legged (Barcelona 2\|1 - Borussia D. 0\|3), and shares the champion card. | `Career.gd:3756` plays it at season open |
| R12 | CONFIRMED | Lower divisions play **all 46 rounds** and run **ahead** of the Premier (First Division P=44 at Premier week 37; Third Division P=46 before the Premier's last match). Confirms audit S2. Zone table already matches on all four tiers. | `Career.gd:1304` plays one round per manager week -> stalls at 39 |
| R13 | DEFECT | The original **auto-presents the final table of each division as it finishes**, unprompted, with a blank club plate and the division in the badge. | no such sequence |
| R14 | DIVERGENCE | **U.E.F.A. Cup champion card exists** and the club name takes a result qualifier — `Lyon (on penalties)`. Confirms audit S6. | `Career.gd:3736-3747` discards the U.E.F.A. winner |
| R15 | DEFECT | **The season-end sequence, 8 steps, witnessed for the first time** (below). It contains **no board-verdict screen**. | `Main.gd:4796` `_show_end_of_season` invents one AND takes the original's screen name |
| R16 | INVENTION | **Running-at-a-loss counter**: one hub alert per week, incrementing, **resets on returning to profit** (reached 3, cleared by selling Butt). Feeds the sacking path. Threshold **>3**, unmeasured. | zero hits for `at a loss`/`loss_weeks`/`bankrupt` in `app/` |
| R17 | CONFIRMED + DECISION | Youth scout **returns exactly one prospect**; per-scout SEARCH CAPABILITY mask is real; duration measured Dec 1997 -> 14 Oct 1998 ≈ **45 weeks**, inside `search_weeks`' predicted 45-50 for a 4-star scout. **Owner decision: halve youth training too.** | `Youth.gd:263` confirmed; training lever below |

### R15 — the season-end sequence, in order

1. final tables of the divisions that already finished (unprompted)
2. **eight champion cards**, all on one `champion_card` layout — U.E.F.A. Cup, Premier League,
   Cup Winner's Cup, F.A. Cup, European Cup (Charity Shield at season start, Intercontinental
   in December, Supercup in March)
3. **THE CHAMPIONSHIPS** — all eight finals with scorelines
4. **END OF SEASON** — champion / U.E.F.A. places / promoted / relegated, all four divisions
5. **GOAL SCORERS OF THE YEAR** — one per division, with goal counts
6. **PLAYERS OF THE YEAR** — one per **club**, four division tabs (92 awards)
7. **MANAGERS OF THE YEAR** — one per division
8. **Preseason** for the new season, then per-player *"X has left your club as his contract
   has not been renewed"* alerts on the hub

Winner highlight rule, measured on all eight finals: the winning club's name is drawn in
solid black `(0,0,0)`, the loser's in grey `(9,9,9)`. **Nothing is ever shared** — a level
score means penalties, and the champion card then appends `(on penalties)`.

MANAGERS OF THE YEAR is **not** "the champion's manager": Second Division went to Wycombe W.
(cup finalists, not champions), Third to Peterborough (3rd, promoted). A cup run counts and
the rule is unknown.

---

## Work list

> **STATUS 2026-07-25 (evening).** Items 1, 3, 5, 6, 7, 8, 9 and the owner deviation are
> SHIPPED; item 4 is shipped in part; item 2 is not started. Every shipped item is asserted
> in [`app/tests/test_refrun_findings.gd`](../../app/tests/test_refrun_findings.gd), which
> checks the numbers and strings against this document rather than against the port.
> Detail per item below.

**Blocked on nothing, evidence in hand:**

1. **SHIPPED.** `FinanceModel` gains the original's own per-week ledger (7 income + 11
   expense lines, the screen's own labels and order) and `Career` posts every cash movement
   through it, so the bank and the books can never disagree. PLAYERS' WAGE + STAFF WAGES are
   charged EVERY week; TICKETS + TELEVISION + PLAYERS' BONUS only on a HOME matchday; an
   away week is a pure loss. Measured on the same club the run measured: **+£189,214 home /
   -£237,981 away** against the witnessed +£216,038 / -£233,942, and 16-17
   running-at-a-loss alerts in a season. Three things fell out of the frames along the way:
   * the **TICKET PRICE is £7.50 a head, witnessed** — the FULL TIME stadium panel prints
     capacity, attendance and ATTENDANCE MONEY together, and 21,014 x 7.50 = £157,605 (Old
     Trafford) and 41,000 x 7.50 = £307,500 (Anfield) are both exact. The app's own
     £15/12/10/8 tier ladder was roughly double it. Man Utd's per-home-match gate now lands
     within 3.4% of the ledger's £364,980.
   * the **finance year runs Sunday..Saturday from 20 July 1997**, so finance week = league
     week + 2. `FinanceModel.finance_week_span` reproduces all three captured stamps
     verbatim.
   * the **channelTV fee IS that week's TELEVISION line**, on a per-competition constant.
     The two domestic cups and the two other European competitions were never measured and
     pay £0 rather than a guess.
   The running-at-a-loss counter and its verbatim alert are in; the SACKING THRESHOLD is
   not witnessed, so `LOSS_SACK_WEEKS` is ours and flagged, and it feeds the board review
   the app already has rather than an invented mid-season dismissal.
2. **NOT STARTED.** Route the cups and Europe (R4), and present the draw with both panel
   forms and competition-dependent buttons (R8). `CupDrawScreen` is still 0-px art with no
   live caller.
3. **SHIPPED.** Both cups are contested by all 92 league clubs with the Premier entering at
   Round 3. `Cup` gained `late_entry`, and byes now normalise ANY off-power-of-two field
   (the old code only did round one's). The field walks 72 -> 64 -> (+20) 52 -> 32 -> 16 ->
   8 -> 4 -> 2, labelled Round 1..Round 5, Qtr Finals, Semifinals, Final — PM98's own
   ladder. Ties are single-leg with a REPLAY per the Round 3 draw card (R2); the League
   Cup's invented two-legged rounds are gone.
4. **PART SHIPPED.** The invented board-verdict sheet is DELETED, and the witnessed
   sequence runs in its place: final division tables (lower divisions first, blank manager
   plate) -> champion cards -> GOAL SCORERS OF THE YEAR -> MANAGERS OF THE YEAR -> the new
   preseason. Champion cards are baked for the **six competitions whose card art was
   witnessed** (Charity Shield, Intercontinental, Coca-Cola, U.E.F.A., F.A. Cup, European
   Supercup); the Premier League, European Cup and Cup Winners' Cup frames were never
   captured, so those raise no card rather than borrow another trophy's.
   **Still missing: THE CHAMPIONSHIPS, END OF SEASON and PLAYERS OF THE YEAR** — steps 3, 4
   and 6. Their binding frames are committed at `tools/re/refs/season-end-2026-07-25/`;
   each needs its own chrome bake.
5. **SHIPPED.** `_capture_euro_honours` keeps the U.E.F.A. Cup winner, and a champion's club
   name takes the original's result qualifier — `Lyon (on penalties)`.
6. **SHIPPED.** The Intercontinental Cup fires in the first DECEMBER week and the European
   Supercup in MARCH, both read off the app's own calendar, and both raise a champion card.
   Neither is a curtain-raiser any more.
7. **SHIPPED.** `DEADLINE_TAIL` 6 -> 4, plus the two warning alerts and no deadline-day
   event. The two-week wording is the witnessed string; the one-week form is that string
   pluralised the way PM98 pluralises its own `"%u offer%s"` alert, and is flagged as such.
8. **SHIPPED.** Lower divisions play all 46 rounds and run ahead of the Premier. The
   catch-up rule spreads the surplus evenly and reproduces the witnessed First Division
   **P = 44 at manager week 37** exactly. The per-division midweek allocation (which put
   the Third Division two weeks further on) is NOT witnessed and is not invented.
9. **SHIPPED.** `Cup.next_label` emits `1/8 Final` verbatim for every matchday of the group
   phase.

**Owner deviation, SHIPPED (R17):** halve youth training to match the already-halved
scouting. The lever is **not** `YOUTH_GAIN_GATE` — dropping it to 0 only takes 60% to 100%,
a 1.67x speedup. The exact 2x is a `YOUTH_GROWTH_SPEEDUP := 2` multiplier on `gain` in
`Training.develop_youth_week`, labelled ours the same way `SEARCH_SPEEDUP` is. **Trap:** the
clamp is currently `if n <= base` (skip on overshoot), so a +2 step stalls one point short on
an odd gap and the youth never reports ready. It must become `mini(n, base)`.

## Not reached

- the **first 1998-99 league match** as a clean capture, and the 1998-99 **START OF SEASON**
  objective sheet — the recorder was stopped for ~2 minutes during curation and the objective
  sheet fell in that gap, so **O1** (category vs the port's "Finish 13 or higher") is still
  unmeasured for the rollover season
- youth **training progression** and the **promotion-ready** message (R17)
- the F.A. Cup Round 3 **tie count** (the panel scrolls; counting it would turn R1's field
  size into an exact number)
- the running-at-a-loss **sacking threshold** (R16), and the sacking screen itself
- the Coca-Cola Cup **home TV fee** (R6's fourth competition)
