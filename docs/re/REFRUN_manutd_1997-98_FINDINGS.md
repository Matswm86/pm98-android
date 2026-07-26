# Reference run — Man Utd 1997-98, findings as they land (2026-07-25)

Mats plays the original; the passive recorder banks every changed frame to `play/`.
Frame numbers below are `play/pNNNN_*.png`. Numbering continues the audit's S/O series.

> **This is the evidence file for [`REFRUN_manutd_1997-98.md`](REFRUN_manutd_1997-98.md).**
> It was written to `out/refrun-manutd-9798/FINDINGS.md`, which is gitignored, so it is
> committed here instead: the summary is worthless without the frame-by-frame reasoning
> behind each finding. The RAW capture it cites (775 frames, `play_manifest.tsv`, the
> ~15,000-sample `pointer_trail.tsv`) is 60 MB+ and stays local under
> `out/refrun-manutd-9798/`; the frames that are load-bearing for a shipped fix are
> committed under `screenshots/refrun-manutd-1997-98/` and named for what they prove.

---

## R1 — DIVERGENCE · the Coca-Cola Cup field and entry round are wrong

Frame `p0129_cup_draw.png`, ROUND 3 draw, Wed 1997. Man Utd drawn at **Bradford City**
(Division One, manager *Jewell*, ground *The Pulse Stadium*); the MATCHES panel also holds
**Aston Villa v Carlisle U.**

The original follows **real-life League Cup rules** (confirmed by Mats): the whole league
pyramid contests it, and Premier clubs **enter at Round 3**. The port:

- `Career.gd:200` `LEAGUE_CUP_OPTS` builds the bracket over the 20 Premier clubs
  (audit S7's `n0=20`), so lower-division clubs cannot be drawn at all
- `"label_scheme": "sequential"` (`Career.gd:202`) counts **Round 1 → Round 2 → Qtr
  Finals**, so the port labels the manager's first tie two rounds early

**Spec:** field = all 92 league clubs, Premier entering at Round 3, and the label must be
the real round number, not a per-club counter. Same correction is due on the F.A. Cup
(audit S7, all 92 + non-league).

## R2 — GAP · cup replays exist in the original

The same draw card offers **MATCH** and **REPLAY** buttons per tie. `Cup.gd` has no replay
concept; `LEAGUE_CUP_OPTS` models early rounds as two legs (`"legs": 2`) instead.

## R3 — DIVERGENCE · the hub's European round badge

Frame `p0110_UNKNOWN.png`, Wed 17 September 1997. Hub badge reads **"Euro. Cup / 1/8
Final"** on what is in fact the **first group-stage matchday** (confirmed by Mats). The
original's label is wrong-but-canonical and must be copied verbatim.

Port: `Cup.next_label` (`Cup.gd:167`) returns `"Group Matchday %d"`. Must emit the
original's string instead.

**Still open:** does the badge stay "1/8 Final" across every group matchday, or step
through 1/8 → 1/4? One look at the next European week settles it.

## R4 — DEFECT (confirms audit S1) · the pixel-exact cup draw is unreachable in the port

`p0125`-`p0129` matched the taught `cup_draw` signature at **1.00** — the SORTEO screen
shipped at 0 differing pixels (`e6728bb`). The original raises it **unprompted** mid-season.
The port's `CupDrawScreen` has zero live callers (audit S1) and resolves ties silently in
`Career._play_due_cup_rounds`. Art perfect, route absent.

## R5 — GAP · the FINANCE per-week ledger is real and detailed

Frame `p0045_UNKNOWN.png`. **INC. + EXP. / PER WEEK**, week stepper `◀ CURRENT 4 ▶`,
"From 10-8-1997 to 16-8-1997".

Income lines: TICKETS · PUBLICITY · TELEVISION · EUROPEAN CUP INCOME · SALE + LOAN PLAY. ·
INSURANCE GROUP 3 · LOANS
Expense lines: SIGN PLAYER · CANCELLATION · PLAYERS' WAGE · PLAYERS' BONUS · PLAYERS'
INCENTIVE · PLAYERS' INSURANCE · HOSPITALS · STAFF WAGES · REFORM GROUND · FINES · LOANS
AND INTEREST

Plus a 52-week BALANCE graph (±2,500 K axis) and LAST WEEK / CURRENT WEEK / CASH tiles
(LAST WEEK income £2,628,544, expenses £230,480, cash £9,613,964).

Port: `finance_screen_re.md:85` records the INCOME/EXPENSES detail views and PER WEEK as
NOT BUILT; `FinanceScreen.gd:246` "we hold no per-week history". This is the same root
cause as audit S4 (no matchday economy) — the original clearly keeps per-week books with a
TICKETS line, so a gate exists.

## R6 — INVENTION · channelTV: the original sells broadcast rights per match

An unprompted `channelTV` card before a **home** match: *"A TV station has bought the rights
to broadcast the current match. For £N"*. Three samples, all Man Utd home fixtures:

| frame | date | hub badge | fee |
|---|---|---|---|
| `p0032_channel_tv.png` | Sun 3 Aug 1997 | Charity / Final | **£187,500** |
| `p0138_channel_tv.png` | Wed 1 Oct 1997 | Euro. Cup / 1/8 Final | **£375,000** |
| `p0210_channel_tv.png` | Sat 25 Oct 1997 | Premier / Week 12 | **£90,000** |

European = exactly 2x Charity Shield. As fractions of the £1,000,000 UEFA entry fee:
37.5% / 18.75% / 9%. Three points is not enough to separate "per-competition constant" from
"varies per match" — **a second Premier home match settles it**: another £90,000 means a
constant table.

Port: no such event exists. Grep `channel|broadcast|tv_rights` across `app/` -> zero hits.
`FinanceModel.gd:86` takes TELEVISION from a flat per-tier constant `_TV[tier]` spread over
the season, so the port earns TV money on away weeks and in weeks with no fixture at all.
Second independent proof of audit S4.

Note the hub badge is the competition context of the **next** fixture: `Charity / Final`,
`Euro. Cup / 1/8 Final`, `Premier / Week 12`.

## R7 — DIVERGENCE · the Intercontinental Cup fires mid-season, not as a curtain-raiser

Frame `p0273_champion_card.png`. **INTERCONTINENTAL CUP CHAMPION — Borussia D. (Scala),
RUNNER-UP Cruzeiro (Weber)**, raised in the **first week of December 1997** (the next date
Mats sees is 7 December). That is the real fixture's date — the 1997 Intercontinental was
played 2 December — and the real result and both managers.

Port: `_play_euro_supercups` (`Career.gd:3756`) plays it **"as the new season opens"**,
bundled with the European Supercup as a curtain-raiser. Three separate corrections:

1. **Timing.** It belongs in the first December week, not at season start. The Supercup is a
   genuine curtain-raiser and can stay; the Intercontinental must move.
2. **Opponent.** `:3759` takes the South American side as *"approximated by the strongest
   South American club"*. The original uses the actual Libertadores holder — Cruzeiro won it
   in 1997 — so this is real data, not an approximation.
3. **Presentation.** The port banks the result to a news line (`_record_supercup_news`) and
   never shows the card. The card matched the taught `champion_card` signature at **0.99**,
   confirming `eb009ae`'s byte-proof that Intercontinental reuses the Charity Shield chrome.

## R8 — GAP · the cup draw screen has two layouts, the port knows one

Same taught `cup_draw` signature, two different MATCHES panels:

- **Coca-Cola Cup, Round 3** (`p0129_cup_draw.png`): two columns with club kit icons per
  side, plus a lower-left card giving the drawn tie's away club, its manager and its ground
  (*Bradford City / Jewell / The Pulse Stadium*), and MATCH / REPLAY buttons.
- **F.A. Cup, Round 3** (`p0381_cup_draw.png`): a single scrollable `Home - Away` text
  column with a scrollbar, no badges, lower-left card empty until a tie is drawn.
  Ties visible: *Rotherham U. - Birmingham C · Crystal Pal. - Everton · Reading - …*

Both entered at **ROUND 3** and both drew clubs from outside the Premier — R1 again, now on
the F.A. Cup as well.

**Unmeasured:** the F.A. Cup Round 3 tie count. The panel scrolls, so the list is longer
than 16 rows; real life is 32 ties / 64 clubs. Counting it would turn R1's "field is wrong"
into an exact field size. Not captured this run (`p0381` is the last `cup_draw` frame).

## R9 — INVENTION · the weekly economy, fully decomposed (supersedes audit S4)

Frame `p0509_UNKNOWN.png` — FINANCE / INC.+EXP. / PER WEEK stepped back to **week 29
(1-2-1998 to 7-2-1998)**, a played **home** week:

| INCOME | | EXPENSES | |
|---|---|---|---|
| TICKETS | £364,980 | PLAYERS' WAGE | £226,923 |
| TELEVISION | £90,000 | PLAYERS' BONUS | £5,000 |
| PUBLICITY / EURO / SALE+LOAN / INSURANCE / LOANS | £0 | STAFF WAGES | £7,019 |
| | | all other lines | £0 |
| **TOTAL INCOME** | **£454,980** | **TOTAL EXPENSES** | **£238,942** |

Week 30 (away, from `p0495`'s LAST WEEK tiles): **income £0, expenses £233,942**.
`226,923 + 7,019 = 233,942` exactly — so the model separates cleanly:

- **flat weekly:** PLAYERS' WAGE + STAFF WAGES = **£233,942**, charged every week
- **home matchday only:** + TICKETS (**£364,980**) + TELEVISION + PLAYERS' BONUS (£5,000,
  probably a win bonus — unconfirmed)
- **away week:** nothing added -> a pure **-£233,942** loss
- home week net **+£216,038**, away week net **-£233,942**

Cash therefore *falls* across the season: **£9,613,964 (wk 4) -> £3,283,406 (wk 31)**. The
BALANCE graph is spiky — blue bars of differing heights, red bars below the line, weeks with
no bar at all.

The port: `Career.gd:752` adds a constant `weekly_net` derived once from a whole-season
`FinanceModel.summary()`, gate = `attendance x ticket x 19` spread flat (`FinanceModel.gd:83`).
Man Utd's audited port season rose monotonically **+£265,875 every week, home or away**,
£4.5M -> £16M. Wrong magnitude, wrong variance and **wrong sign**.

**R6 closes here too:** the channelTV card's fee IS that week's TELEVISION line — £90,000 on
the card (`p0474`, Sat 7 Feb 1998) and £90,000 in the week-29 ledger. Per-competition
constant, home matches only.

## R3 — ANSWERED · the European badge never advances through the group

`Euro. Cup / 1/8 Final` on **1 Oct** (`p0138`), **5 Nov** (`p0237`) and **26 Nov 1997**
(`p0265`). Three group matchdays, same label. So it is a fixed competition-phase string, not
a round counter, and `Cup.next_label` (`Cup.gd:167`) must emit it verbatim in place of
`"Group Matchday %d"`.

## R10 — DIVERGENCE · the transfer-deadline warning is missing, and DEADLINE_TAIL is off by 2

Frame `p0524_UNKNOWN.png`, **Sunday 8 March 1998, Premier Week 32**:
*"The transfer deadline is now 2 weeks away."* -> deadline lands at **week 34**.

Port: `DEADLINE_TAIL := 6` (`Career.gd:267`) puts it at `38 - 6 = 32`. Should be **4**.
Enforcement exists (`can_transfer`, `deadline_weeks_left`, "The transfer deadline has
passed") but nothing raises the warning card.

**There is no deadline-day event** (Mats, 2026-07-25 — not a concept in 1998). The original
raises exactly two warnings, at **2 weeks** and **1 week** before, and the window then shuts
silently. So the port needs two scheduled alerts, not a deadline-day card.

## R11 — DIVERGENCE · the European Supercup also fires mid-season, and shares the champion card

Frame `p0537_champion_card.png`: **EUROPEAN SUPERCUP CHAMPION — F.C. Barcelona (Van Gaal),
RUNNER-UP Borussia D. (Scala)**, raised in the week of **Sunday 8 March 1998** (hub
`p0535_hub.png`, Premier Week 32). Real 1997 result and both real managers.

Port: `_play_euro_supercups` (`Career.gd:3756`) plays it "as the new season opens", same bug
as R7. So the original's schedule is **Intercontinental = first December week, Supercup =
March**, and neither is a curtain-raiser.

Third competition to match the taught `champion_card` at **1.00** (Charity Shield,
Intercontinental, Supercup). One card layout serves all three — extends `eb009ae`'s
byte-proof from Intercontinental to the Supercup.

## R12 — CONFIRMED · lower divisions play all 46 rounds, and run AHEAD of the Premier

- `p0610_UNKNOWN.png` — FIRST DIVISION, table date 18/4/1998, **Premier Week 37**:
  24 clubs, **P = 44** for every club. So 44 of 46 rounds are done in 37 manager weeks; the
  extra 7 come from midweek fixtures.
- `p0638_UNKNOWN.png` — THIRD DIVISION, table date 2/5/1998, shown **before** the Premier's
  last match: 24 clubs, **P = 46**. Complete.

Audit S2 is therefore a real truncation bug, not a modelling choice: `_play_division_round`
(`Career.gd:1304`) plays exactly one lower-division round per manager week, so a 46-round
division stalls at 39 and `_pyramid_rollover` computes promotion off the short table.

**The zone table is already right.** Gutter markers match `SeasonSim.ZONES` exactly: First
Division 2 PROMOTION + 4 PLAY-OFFS (`{"up": 2, "playoff": 4, "down": 3or4}`), Third Division
3 PROMOTION + 4 PLAY-OFFS + no relegation band (`{"up": 3, "playoff": 4, "down": 0}`).
Only the round count needs fixing. (Exact First-Division relegation count still worth one
clean read; 2 bands detected by pixel scan, 3-4 visible in the render.)

Table header carries a **revision date** separate from the current date (`Date 18/4/1998`
while the calendar reads Sat 18 April; `Date 2/5/1998` while it reads Sun 3 May), matching
`LeagueTableScreen.gd:243`.

## R13 — DEFECT · the end-of-season sequence is unprompted and the port has none

After Premier game 37 the original goes **straight to the final tables of the divisions that
have already finished**, before returning to the hub, then straight into the champion cards.
The club plate is blank in this mode and the badge shows the division being presented
(`3rd Div.`) rather than the manager's competition.

The port has no such sequence: `advance_week` resolves everything silently and returns to the
hub (audit S1).

## R14 — DIVERGENCE · U.E.F.A. Cup champion card exists, and carries a result qualifier

`p0643_champion_card.png`: **U.E.F.A. CUP CHAMPION — Lyon (on penalties), Lacombe.
RUNNER-UP Liverpool, Evans.** Both real 1997-98 managers.

Two things:

1. **The club name takes a suffix** — `Lyon (on penalties)`. No earlier card had one, so the
   card's name field is `"%s%s" % [club, qualifier]` and the port must reproduce the
   qualifier text, not just the winner.
2. This is precisely the trophy `_capture_euro_honours` (`Career.gd:3736-3747`) throws away.
   Audit S6 confirmed live: the original both presents it as a champion card and lists it
   among the eight trophies (R8's backdrop). The port has neither.

Fifth competition on the shared `champion_card` layout at 1.00 (Charity Shield,
Intercontinental, Supercup, Coca-Cola Cup, U.E.F.A. Cup).

## R15 — THE SEASON-END SEQUENCE, witnessed for the first time

Exact order, after the final Premier fixture (frames `p0638`-`p0664`):

1. **final tables of the divisions that already finished** (unprompted, blank club plate,
   badge = the division being shown; lower divisions finish first, R12)
2. **eight champion cards**, one per trophy, all on the one `champion_card` layout:
   U.E.F.A. Cup -> Premier League -> Cup Winner's Cup -> F.A. Cup -> European Cup
   (Charity Shield came at season start, Intercontinental in December, Supercup in March)
3. **THE CHAMPIONSHIPS** (`p0653`) — all eight finals with scorelines
4. **END OF SEASON** (`p0655`) — champion / U.E.F.A. places / promoted / relegated, 4 divisions
5. **GOAL SCORERS OF THE YEAR** (`p0656`) — one per division, with goal counts
6. **PLAYERS OF THE YEAR** (`p0657`) — one per **club**, 4 division tabs (92 total)
7. **MANAGERS OF THE YEAR** (`p0663`) — one per division
8. **Preseason for Manchester Utd.** 1998-99 (`p0664`) — friendlies 31 Jul, 3/5/7 Aug 1998

**There is no board-verdict screen anywhere in it.** The port's `_show_end_of_season`
(`Main.gd:4796`) unconditionally presents `board_review()` as "Final position: Nth of 20"
plus sacking / job-offer branches. The original raises nothing of the kind between the last
match and the new preseason. (A *sacking* screen would be conditional, so its absence proves
nothing; the unconditional final-position sheet is what the original does not have.)

Worse, it is a **name collision**: the port calls its invented board screen "end of season",
while the original's END OF SEASON is the four-division promoted/relegated overview at
`p0655`. Two different screens, one name.

### Winner highlight rule (measured, 8/8 rows on `p0653`)

The winning club's name is drawn in solid black `(0,0,0)`; the loser's in grey `(9,9,9)`.
Verified on every one of the eight finals by pixel scan. **Nothing is ever shared** — a level
score means penalties decided it, and the champion card then appends the qualifier
`(on penalties)` to the club name (R14). Charity Shield 0-0 -> Chelsea, black.

`p0653` also carries a **second score column**, present for F.A. Cup, Coca-Cola Cup and
European Supercup, filled here only for the Supercup (Barcelona 2 | 1, Borussia D. 0 | 3).
Whether it is a replay column or a second leg is **not settled** by this frame; R2's
MATCH / REPLAY buttons on the draw card point at replay.

### Award-sheet chrome is shared

GOAL SCORERS OF THE YEAR and MANAGERS OF THE YEAR both matched the taught
`manager_of_month` signature at **0.97** — the monthly and end-of-year award sheets are one
layout, with per-division colour coding (Premier yellow, First green, Second blue,
Third orange).

### MANAGERS OF THE YEAR is not "the champion's manager"

Premier Evans (Liverpool, champions) · First Francis (Birmingham C, champions) ·
Second Smith (**Wycombe W.**, Coca-Cola Cup finalists, *not* champions - Southend won) ·
Third Fry (**Peterborough**, 3rd and promoted, *not* champions - Shrewsbury won).
So a cup run counts. The rule is unknown and cannot be "award the title winner".

## R16 — INVENTION · the running-at-a-loss counter, and the sacking path it feeds

1998-99 season. One alert per week on the hub, with an incrementing counter:

- `p0685_alert_box.png` — Thu 27 Aug 1998, Premier Week 4:
  *"You have been running the club at a loss for 1 week now."*
- `p0716_alert_box.png` — Mon 31 Aug 1998, Premier Week 5: *"... for 2 weeks now."*
- reached **3 weeks**, then Mats sold Butt and the counter **cleared**.

So it counts **consecutive** weeks in the red and resets the moment the club is back in
profit. The sacking threshold is therefore **> 3 weeks** and remains unmeasured.

**Trigger corrected 2026-07-26: "in the red" is the BANK BALANCE below zero, not a
P&L-negative week.** Three discriminating witnesses: the whole 1997-98 refrun season
raised NO alert although every quiet away week closes wages-only P&L-negative; the alerts
began only at W4 of 1998-99, after the summer spend drove the balance under, and cleared
when the Butt sale brought it back; and the P&L reading fired at week 1 of a career
holding millions (Mats, live report, 2026-07-26), which the original does not do. Port:
`Career._close_week_books` now tests `cash < 0`; probed both ways in
`test_refrun_findings`.

Grep for `at a loss|loss_weeks|running the club|bankrupt|insolven` across `app/` returns
**zero hits**. The mechanic does not exist in the port at all.

This is R9 at its sharpest: in the original a Manchester Utd. manager can go broke, because
away weeks cost £233,942 and earn nothing. The port's Man Utd nets +£265,875 every week and
finishes £16M up, so this failure mode is structurally unreachable there. Any fix to
`FinanceModel` has to make it reachable again.

## R17 — the youth scout, measured live, and the OWNER DECISION on training

`p0758_UNKNOWN.png` — YOUTH TEAM screen, Wed 14 October 1998, after the scout returned.

- **SCOUT** `K. Harwood`, **4 stars**. **SEARCH CAPABILITY**: HANDLING/DRIBBLING/TACKLING/
  HEADING/PASSING **YES**, SHOOTING **NO** — a per-scout mask over which attributes he can
  assess. That is `Youth.CAP_ATTR` + `CAP_THRESHOLD := 0x50` (`Youth.gd:49-53`).
- **PLAYERS FOUND: exactly one** — `Spindle`, AV 18, ROL, WAGE £5,000, AGE 17. Confirms the
  ported rule at `Career.gd:1962`: threshold `0x4f` on any lit capability, *"then throw all
  but ONE at random"* (`55fa5df`).
- A separate youth **MANAGER** exists: `M. Williamson`, **5 stars**, "4 PLAYERS".
- YOUTH TEAM columns: NAME · SP · ST · AG · QU · AV · ROL · WAGE · YEARS. Right-hand
  PARAMETERS / RATING tabs and six attribute buttons.
- Signing is the shared offer path: contract offered, then *"has joined your Youth Team"* two
  matches later (Mats).

### Search duration validated against the disassembly

Dispatched **December 1997**, returned **14 October 1998** ≈ **45 weeks**.
`Youth.search_weeks` (`Youth.gd:263`, from `FUN_0053e860` @0x53e967) predicts, for a 4-star
scout: `rand(6) + 0x37 - 5*((4+1)>>1)` = `55 - 10 + rand(0..5)` = **45..50 weeks**. The live
run lands on the band, so the reversed formula is confirmed by observation.

`SEARCH_SPEEDUP := 2` is **ours, not the binary's**, and correctly labelled so at
`Youth.gd:59-63`. It is not present in the original, which is why this playthrough took the
full 45 weeks.

### OWNER DECISION (Mats, 2026-07-25): halve youth TRAINING too

> "Make a note of it to half the length of both scouting and training of youth players.
> Assume they take the same time."

Scouting is already halved (`SEARCH_SPEEDUP := 2`). **Training is not**, and it has no
duration constant to divide — the length is emergent. `Training.develop_youth_week`
(`Training.gd:315`, from `FUN_00582760` case 0x20) rolls **per week**:
`YOUTH_GAIN_GATE := 0x27` -> `rand(100) > 39` -> **60% chance of +1** on every attribute,
hard-stopped at the player's shipped EQUIPOS BASE. When the core four (VE/RE/AG/CA) all
reach BASE the mode clears and the youth manager reports *"…is ready to be promoted to the
first team squad."*

So the lever is **not** the gate: dropping `YOUTH_GAIN_GATE` to 0 gives 100% instead of 60%,
which is only a **1.67x** speedup, not 2x. The exact 2x is **+2 per firing** — a
`YOUTH_GROWTH_SPEEDUP := 2` multiplier on `gain`, mirroring `SEARCH_SPEEDUP` and labelled
the same way as ours.

**Implementation caveat:** the current clamp is `if n <= base` (skip the step if it would
overshoot), so a +2 step would stall one point short whenever the remaining gap is odd. It
must become `mini(n, base)` or the youth never reaches BASE and never reports ready.

**Unwitnessed:** the training progression and the promotion-ready message. Mats stopped
before them, so the growth delta from AV 18 and the promotion card are still uncaptured.

## Confirmed already-correct (no action)

- **UEFA prize schedule.** The original's European entry alert states £1 million for
  competing, £255,000 per draw, £510,000 per win. `Career.gd:234-236` holds exactly those
  figures with those strings as comments. Exact.

## Open on the European entry alert

The alert itself (`p0110`) is a screen the port does not raise — it credits `EURO_ENTRY`
silently. Needs teaching as a signature and a route.
