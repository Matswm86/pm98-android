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

## Abstracted (honest simplifications, flagged in code)

* **Knockout, no group stage.** The real 1997-98 European Cup had a group phase
  (`THE CHAMPIONSHIPS` / `GROUP` strings). We model all three comps as straight two-legged
  knockouts -- the classic European format and the same chassis the domestic cups use. A
  group stage is future work.
* **Foreign field from `game_db`.** The opponents are real clubs from the game's own
  international database, rated from their squads, frozen for the season (they don't
  develop -- same scope as "AI clubs don't develop").
* **Two legs collapsed to one tie** (as the domestic two-legged cup already does), so the
  per-match UEFA draw/win money is credited per-tie.
* **European Supercup + Intercontinental Cup** (winners-of-winners) are **not yet built**
  -- they need this season's European winners carried forward, a further cross-season
  layer. `Cup.single_neutral_match` (built for the Charity Shield) is the chassis for them.

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
