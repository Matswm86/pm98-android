# European competitions (Track A engine depth)

Three continental knockouts layered onto the season, qualified into from last season's
domestic finish. Engine: the existing `app/scripts/Cup.gd` chassis (two-legged ties were
already built for the Coca-Cola Cup); wiring + qualification + prizes in `Career.gd`;
screen reuses `app/scenes/CupScreen.gd`.

## What the binary tells us (MANAGER.EXE strings)

The original runs the full European set; the strings are present in `.rdata`/`.data`:

```
EUROPEAN CUP / EUROPEAN CUP CHAMPION / EUROPEAN CUP INCOME
U.E.F.A. CUP CHAMPION / U.E.F.A. CUP INCOME / EUROPEAN LEAGUE
CUP WINNERS' CUP / CUP WINNER'S CUP CHAMPION
EUROPEAN SUPERCUP / EUROPEAN SUPERCUP CHAMPION / EURO. SUPERCUP
INTERCONTINENTAL CUP / INTERCONTINENTAL CUP CHAMPION
THE CHAMPIONSHIPS / TEAMS IN CHAMPIONSHIPS
```

Trophy art (all DM bitmaps in `IMG.PKF`, shared VGA palette idx0-transparent, cracked via
`tools/re/export_art.py`, the second-trophy ghost cropped):

| Competition       | seed (last season)        | art (IMG.PKF)        | asset |
|-------------------|---------------------------|----------------------|-------|
| European Cup      | league champions          | `LIGACAMP.BMP`       | `app/art/screens/cup/ligacamp.png` |
| U.E.F.A. Cup      | runners-up (top `UEFA_SPOTS` below the champions) | `UEFA BIG.BMP` | `app/art/screens/cup/uefa.png` |
| Cup Winners' Cup  | F.A. Cup winners          | `RECOPA BIG.BMP`     | `app/art/screens/cup/recopa.png` |

## The prize schedule — the ONE code-resident money table (already reversed)

From `docs/re/finance_constants.md` (string-encoded at VA `0x653518`–): 1,000,000 to
compete, 255,000 per draw, 510,000 per win, 1,500,000 to reach the quarter-finals,
1,625,000 to reach the semifinals. These are the only prize figures the EXE carries (the
domestic prize money is a dynamic per-club float ledger, not a static table). We use them
directly: `Career.EURO_ENTRY/EURO_WIN/EURO_QF/EURO_SF`. Per-match draw/win is collapsed to
per-tie (our legs are abstracted into one tie), so a tie won pays the "win" figure;
`EURO_WINNER` (lifting it) is a documented bonus, not a reversed value.

## Model (Career.gd)

* `mint_european_cups(euro_pool, rng)` runs at `advance_season`, after the new fixtures are
  set, seeded from the honours captured at the top of the rollover (`last_champion_id`,
  `last_runners_up`, `last_fa_winner_id` -- the same hook the Charity Shield uses). The
  first season has no prior honours, so Europe starts from the **second season on**.
* Each comp's field is `EURO_FIELD` (16) clubs: the domestic qualifier(s) + a draw of
  strong foreign clubs. `Main._euro_pool()` rates the international set in `game_db`
  (clubs with no `leagueId`) and hands the strongest 48 to the rollover; their ratings +
  names are **frozen** into `euro_ratings`/`euro_names` at draw time, so the brackets
  resolve and save/load without GameDB. Foreign clubs are dealt distinctly across the
  three competitions (one shuffled bag).
* Rounds play in `_play_due_cup_rounds` (the European brackets loop alongside the domestic
  cups); `_ratings_for` resolves a foreign id via the frozen ratings, and `_euro_prize`
  pays the manager on the UEFA schedule. A 16-team two-legged knockout is
  `Round 1 -> Quarter Finals -> Semifinals -> Final`.

## The European Cup group stage (2026-06-17)

The real 1997-98 European Cup ran a group phase (`THE CHAMPIONSHIPS` / `GROUP` strings;
the binary's European Cup label set is `group + 1/8 Final, Qtr Finals, Semifinals,
Final`). It is now built on the `Cup.gd` chassis: the 16-club field is drawn into **4
groups of 4**, each playing a **double round-robin** (6 matchdays, 3-1-0 points, ranked by
points then goal difference then goals for); the **top 2 of each group** (8 clubs) seed the
two-legged knockout (`Quarter Finals -> Semifinals -> Final`). Only the European Cup has a
group phase; the U.E.F.A. Cup and Cup Winners' Cup were straight knockouts that season.

* `Cup.create(..., {group_stage:{groups:4, advance:2}})` builds the group structure; the
  group draw is deferred to the first matchday (it needs the rng), like the knockout draw.
* `Cup.play_next` dispatches a group matchday (`play_group_matchday`) while the groups are
  live, else a knockout round (`play_round`). The season loop calls `play_next` for every
  competition; a knockout-only comp falls straight through to `play_round`.
* The group phase pays the manager on the **reversed per-match** UEFA schedule that the
  knockout collapses to per-tie: `EURO_WIN` (510k) a win, `EURO_DRAW` (255k) a draw, plus
  `EURO_QF` (1.5m) for qualifying to the last 8.
* `CupScreen` shows the manager's group table + his matchday results during the phase
  (`Main._cup_group_view`); real render `european_cup_group.png`.

## Abstracted (honest simplifications, flagged in code)

* **16-club field, 4 groups of 4.** The real competition had 24 clubs in 6 groups (6
  winners + 2 best runners-up -> the last 8). We keep the existing 16-club field and run 4
  groups of 4 -> top 2 -> the same last-8 knockout. Same honest "smaller field" scope as
  the single-division domestic cups.
* **Foreign field from `game_db`.** The opponents are real clubs from the game's own
  international database, rated from their squads, frozen for the season (they don't
  develop -- same scope as "AI clubs don't develop").
* **Two legs settled by the full 1997-98 ladder.** A two-legged knockout tie is decided on
  aggregate, then away goals, then 30-minute extra time in leg 2 (its goals join the
  aggregate, ET away goals still count), then penalties -- `Cup._play_two_leg_tie`.
## Winners-of-winners finals (2026-06-16)

The **European Supercup** (last season's European Cup winners v Cup Winners' Cup winners)
and the **Intercontinental Cup** (European Cup winners v the South American champions) are
contested at the start of the new season, like the Charity Shield -- single neutral
matches via `Cup.single_neutral_match` (level -> penalties), around their own trophies
(`IMG.PKF` `SUPERCOPA_EUROPA BI` / `INTERCONTINENTAL BI`, shared VGA palette).

To survive the rollover (which rebuilds `euro_ratings`), `_capture_euro_honours` reads
last season's European Cup + Cup Winners' Cup winners and FREEZES their ratings into
`euro_winner_ratings` BEFORE the reset; `_play_euro_supercups` then contests both finals
off those frozen ratings. The South American champion is supplied by the caller
(`Main._sa_champion`) -- the strongest South American club in game_db (country tags
`Argentina`/`Brasil`/`Uruguay`/... -- a documented stand-in, since we don't simulate the
Copa Libertadores; the European fields exclude South American clubs, who play here instead).
Prizes (`SUPERCUP_PRIZE` / `INTERCONTINENTAL_PRIZE`) are documented, not reversed. Both
persist in the save and surface in CLUB NEWS + the COMPETITIONS chooser. Tests:
`app/tests/test_supercups.gd`; real render `screenshots/european_supercup.png`.

## UI

* The hub **COMPETITIONS** chooser lists each European comp the division qualified for,
  routing to `CupScreen` around the right trophy (`Main._euro_emblem`). `_cup_view` gained
  a **NOT QUALIFIED** status for a comp the manager never entered (domestic cups always
  include the whole division, so it never fires there) -- you still see the trophy + the
  draw + the eventual champion.
* Entry + results surface in CLUB NEWS.

## Tests + verification

`app/tests/test_europe.gd` (mint + the three fields + correct domestic seeding, distinct
foreign draw across comps, frozen-rating resolution, the manager's entry bonus + that each
comp resolves to a champion, save/load, and that a rollover without a pool stays inert).
Verified by a real in-engine render: `screenshots/european_cup.png` (Manchester Utd's Cup
Winners' Cup run -- out in Round 1 to Dep. Español on penalties; Valencia bt Dep. Español
3-1 in the final).
