# The MANAGER LEAGUE season-end sequence — witnessed end to end (2026-07-25)

**Status: CAPTURED; FIVE OF THE EIGHT STEPS BUILT (2026-07-25 evening).**

| step | screen | state |
|---|---|---|
| 1 | LEAGUE TABLES, one per division, blank manager plate | **BUILT** — `Main._season_end_final_tables`, lower divisions first |
| 2 | champion cards | **BUILT for six trophies** — Charity Shield, Intercontinental, Coca-Cola, U.E.F.A., F.A. Cup, European Supercup. PREMIER LEAGUE, EUROPEAN CUP and CUP WINNER'S CUP card art was never captured, so `CharityShieldScreen.has_card()` returns false and the card is SKIPPED, never borrowed |
| 3 | THE CHAMPIONSHIPS | **NOT BUILT** — binding frame `20_the_championships.png`, needs its own chrome bake |
| 4 | END OF SEASON | **NOT BUILT** — binding frame `21_end_of_season.png` |
| 5 | GOAL SCORERS OF THE YEAR | **BUILT** — the awards panel is byte-identical to the shipped MANAGERS OF THE MONTH chrome (diffed), so `ManagersMonthScreen.setup_titled()` serves it with no new art |
| 6 | PLAYERS OF THE YEAR | **NOT BUILT** — binding frame `23_players_of_the_year.png`. NOT the same screen as PLAYERS OF THE MONTH: the title sits in the top barra band, the panel geometry differs and the four division tabs are a 2x2 grid with a CONTINUE button |
| 7 | MANAGERS OF THE YEAR | **BUILT**, same layout as step 5. The PICK is ours and flagged (see below) |
| 8 | Preseason | already the app's own |

**The invented board-verdict screen is GONE.** `Main._show_end_of_season` used to present an
unconditional "Final position / Board objective / Reputation / Verdict" sheet under the
original's own screen name. The original raises nothing of the kind. The board still
decides (`Career.board_review`), but it surfaces only when it has consequences — a sacking
or a job offer — and then through the original's own modal alert box.

**MANAGERS OF THE YEAR's pick is ours.** The run settled what the rule is NOT (see below);
the binary's rule is un-reversed. `Career._manager_of_year` gives it to a domestic-cup
FINALIST from the division (the one thing the witness positively shows counts — Wycombe W.)
and otherwise to the club that finished furthest above its pre-season seed. Flagged exactly
the way MANAGERS OF THE MONTH's month-form pick is. The SCREEN is the original's.

---

**Original capture status: CAPTURED, NOT YET BUILT.** Eight steps run between the last league match and
the new season's preseason. The app has none of them; `Main._show_end_of_season` is an
invented board-verdict screen that also takes the original's screen name.

Two independent captures agree:

* the reference Manchester Utd. 1997-98 season, played by hand
  (`docs/re/REFRUN_manutd_1997-98.md`, finding **R15**);
* a Bolton W career driven by `tools/re/wine/autodrive.py` to 8 May 1998 and walked
  through the whole sequence, frames in
  `screenshots/wine-captures-2026-07-25-season-drive/` (`13`, `20`-`24`).

This corrects `seasonend_flow_re.md`, which concluded from the binary that "Manager
League has NO season-end screens at all". That is true of the two PROMANAGER screens it
reversed — 0x3b8 END OF THE SEASON and 0x3ba END OF THE GAME are gated on
`DAT_0066b1e4` and never mount in a Manager League career — but the award and summary
sequence below is a different family and it does run.

## The sequence

| # | screen | how it is dismissed | frame |
|---|---|---|---|
| 1 | **LEAGUE TABLES**, the final table of each division, raised unprompted as that division finishes — the manager plate in the barra is BLANK and the badge carries the division | `CONTINUE` (573, 437) | `13_league_tables_final_markers.png` (2026-07-25 euro set), and live |
| 2 | **champion cards**, one per competition, all on the shared CAMPEON layout | `OK` (115, 352) | `champ_cwc` (CUP WINNER'S CUP CHAMPION), live |
| 3 | **THE CHAMPIONSHIPS** — all eight finals with their scorelines, two score columns where the tie was two-legged | `CONTINUE` (573, 451) | `20_the_championships.png` |
| 4 | **END OF SEASON** — CHAMPION / RUNNER-UP + U.E.F.A. CUP places + PROMOTED + RELEGATED, all four divisions on one sheet | `CONTINUE` (573, 437) | `21_end_of_season.png` |
| 5 | **GOAL SCORERS OF THE YEAR** — one per division with his goal count, on the four-panel green-header layout | `OK` (573, 255) | `22_goal_scorers_of_the_year.png` |
| 6 | **PLAYERS OF THE YEAR** — one per CLUB, four division tabs (92 awards) | `CONTINUE` (557, 438) | `23_players_of_the_year.png` |
| 7 | **MANAGERS OF THE YEAR** — one per division, same four-panel layout as (5) | `OK` (573, 255) | `24_managers_of_the_year.png` |
| 8 | **Preseason** for the new season | the normal preseason chrome | live |

Steps 5 and 7 share their layout with MANAGERS / PLAYERS OF THE MONTH — close enough
that one pixel signature matches both, so a screen name alone cannot tell them apart;
the title plate does.

## What the captures settle

* **MANAGERS OF THE YEAR is not "the champion's manager".** 1997-98 Bolton career:
  Premier went to **Wenger (Arsenal)** while the champions were **Blackburn R.**; First
  to Francis (Birmingham C), Second to Martin (Southend Utd), Third to Allardyce
  (Notts C.). The reference run saw the same shape — Second Division to Wycombe W., cup
  finalists rather than champions. **The rule is still unknown.**
* **THE CHAMPIONSHIPS shows two score columns for a two-legged final.** The witnessed
  row `EUROPEAN SUPERCUP — F.C. Barcelona 2 | 3 · Borussia D. 0 | 0` is independent
  confirmation of the two-legged Supercup built this session
  (`docs/re/euro_supercup_screen_re.md`), with the Cup Winners' Cup holder named first.
  The F.A. Cup and Coca-Cola Cup rows carry the same second column.
* **There is no board-verdict screen anywhere in the sequence.**

## Not witnessed

* whether step 1 raises a table for the manager's OWN division before or after the
  others (the lower divisions finish first — `REFRUN` R12);
* the tie-break MANAGERS / PLAYERS OF THE YEAR use;
* the sequence in a career where the manager is relegated or sacked.
