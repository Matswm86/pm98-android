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

**Blocked on nothing, evidence in hand:**

1. `FinanceModel` / `Career.gd:752` — per-week ledger with a real matchday gate (R5, R6, R9)
   and the running-at-a-loss counter + sacking path (R16). This is the largest and the most
   load-bearing: three findings and the only measured *sign* error in the port.
2. Route the cups and Europe (R4), and present the draw with both panel forms and
   competition-dependent buttons (R8).
3. Widen the cup fields to the pyramid, Premier entering at Round 3 (R1); add replays (R2).
4. Build the season-end sequence (R13, R15) and retire `_show_end_of_season`'s invented board
   verdict, freeing the name for the original's overview screen.
5. Capture the U.E.F.A. Cup winner (R14, trivial) and render the `(on penalties)` qualifier.
6. Move Intercontinental to December and Supercup to March (R7, R11).
7. `DEADLINE_TAIL` 6 -> 4 plus two warning alerts (R10).
8. Run lower divisions to 46 rounds, ahead of the Premier (R12).
9. Emit the original's `"1/8 Final"` badge string verbatim (R3).

**Owner deviation to implement (R17):** halve youth training to match the already-halved
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
