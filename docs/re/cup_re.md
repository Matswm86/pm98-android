# The F.A. Cup (Track A engine depth)

The domestic knockout, layered onto the league season. Engine: `app/scripts/Cup.gd`
(pure logic on a JSON-serializable bracket dict, like `SeasonSim` fixtures). Screen:
`app/scenes/CupScreen.gd`. Wired into `Career.gd` (plays alongside the league).

## What the binary tells us (MANAGER.EXE strings)

The original game runs several cup competitions. The English domestic + European set,
each with its own `ACTLIGA\*.CPT` competition file and `img\...\copas\*.bmp` art:

| Competition          | label tokens in the EXE                                   | CPT file        | art |
|----------------------|-----------------------------------------------------------|-----------------|-----|
| **F.A. Cup**         | `Round 1`..`Round 5`, `Qtr. Finals`, `Semifinals`, `Final`, `Champion`, `Finalist` | `FACUP%03u.CPT` | `img\premier\copas\facup.bmp` |
| Coca-Cola (League)   | `Round 1 - 1st`/`- 2nd` … `Semifinals - 1st`/`- 2nd` (two-legged) | `CCCUP%03u.CPT` | `img\premier\copas\cocacola.bmp` |
| Charity Shield       | `Charity Shield` (single match)                           | —               | `img\premier\copas\charity.bmp` |
| European Cup         | group + `1/8 Final`, `Qtr Finals`, `Semifinals`, `Final` (two-legged) | —        | `img\copas\ligacampeones.bmp` |
| UEFA Cup             | `1/32`..`1/8 Final - 1st`/`- 2nd`, `Qtr.`, `Semis`, `Final` | `CUEFA%03u.CPT` | `img\copas\uefa.bmp` |
| Cup Winners' Cup     | `Cup Winners' Cup`                                        | —               | `img\copas\recopa.bmp` |
| European Supercup    | `European Supercup`                                       | —               | `img\copas\supercopa_europa.bmp` |
| Intercontinental     | `Intercontinental Cup`                                    | —               | `img\copas\intercontinental.bmp` |

UEFA prize-money strings (`"1 million from UEFA for competing in this championship"`,
`"255.000 for every draw match"`, `"1.5 million … to the quarter finals"`, etc.) confirm
cup runs pay out in the original.

**Implemented: the F.A. Cup and the Coca-Cola (League) Cup**, both on the one `Cup.gd`
chassis (`Cup.create(ids, weeks, opts)` selects the competition). The European competitions
(which depend on a high league finish — a multi-season hook) and the Charity Shield
(champions v F.A. Cup winners — a cross-season single match) are the remaining cup steps.

### Coca-Cola (League) Cup specifics (faithful)

* **Two-legged ties** (home-and-away, advance on aggregate) for every round EXCEPT the
  Final, which is a single match — exactly the binary's `Round 1 - 1st`/`- 2nd` …
  `Semifinals - 1st`/`- 2nd` set plus a lone `Final`. A level aggregate goes to penalties
  (`legs: 2, two_legged_final: false`).
* **Sequential round labels**: `Round 1 → Round 2 → Qtr Finals → Semifinals → Final`
  (`label_scheme: "sequential"`, and note `Qtr Finals` with no period, vs the F.A. Cup's
  `Qtr. Finals` — both spellings are in the EXE).
* Finishes **earlier** in the season than the F.A. Cup (`span_hi: 0.7`) so the two finals
  don't coincide — the League Cup final lands ~week 22, the F.A. Cup's ~week 32.
* A **smaller purse** than the F.A. Cup (`prize_round`/`prize_winner`).
* Art: `IMG.PKF: COCACOLA BIG.BMP` → `app/art/screens/cup/cocacola.png`.

## Faithful (lifted from the game)

* **Round labels** are PM98's own, in PM98 order. For a 16-club field after round one:
  `Round 4 → Round 5 → Qtr. Finals → Semifinals → Final` — the progression a Premier-
  division club runs (Premier clubs enter the real F.A. Cup at Round 3).
* **Open draw**: the F.A. Cup re-draws the surviving clubs at random EVERY round (it is
  not a fixed seeded bracket). `Cup.play_round` shuffles the survivors each round.
* **Knockout with replays**: a level tie is replayed at the reversed venue (`REPLAY` in
  the binary); a level replay is settled on penalties. News flags `(after a replay)` /
  `(on penalties)`.
* **Prize money**: a cup run credits the bank (gate receipts + prize fund) and lifting the
  cup pays a trophy bonus — the original pays out for cup progress (see the UEFA strings).
* **Art**: the iconic F.A. Cup trophy on the screen is the game's own
  `IMG.PKF: FACUP BIG.BMP`, a `DM` entry drawn with the shared VGA palette (idx 0
  transparent), cracked via `tools/re/export_art.py` and the faint second-trophy ghost on
  the left cropped off → `app/art/screens/cup/trophy.png`.

## Abstracted (honest simplification — flagged in code)

* **Single-division field.** The real F.A. Cup spans every division; our career models one
  division, so the cup is contested among that division's clubs (20 in the Premier League,
  24 below) — a faithful knockout over a smaller, one-tier field. Same spirit as the
  existing "AI clubs get no injuries/development" scope flag.
* **Prize figures** (`Cup.ROUND_PRIZE`, `Cup.WINNER_BONUS`) are reasonable, documented
  values — NOT a reversed PM98 domestic prize table (only the UEFA figures are in the EXE).
* **Schedule.** Cup rounds are spread evenly across the league weeks (midweek ties), not
  the exact historical F.A. Cup calendar.

## Bracket maths (Cup.gd)

* `_floor_pow2(n)` — largest power of two ≤ n (the field round one reduces to).
* Round one gives byes (`2·p − n`, p = `_floor_pow2(n)`) only when n is NOT already a power
  of two; it then halves cleanly. 20 → 4 ties + 12 byes → 16 → 8 → 4 → 2 → champion.
* `_num_rounds(n)` — total rounds (one preliminary + the halvings, or just the halvings if n
  is a power of two). 20/24 → 5, 16 → 4.

## Integration (Career.gd)

* `fa_cup` (the bracket dict) lives in the save next to `fixtures`/`table`.
* `advance_week` plays every cup round whose scheduled week has arrived
  (`_play_due_cup_rounds`); the manager's tie reads availability-aware ratings (an injured
  player misses the cup tie too), pays prize money, and writes a `cup`-kind news line.
* `advance_season` mints a fresh cup; a pre-cup save loads with an inert empty bracket and
  gets its first real cup at the next rollover.

## UI

* On the hub, the **CALEN/fixtures** icon opens `CupScreen` (the season-calendar/competitions
  slot — the next-match readout stays on the RIVAL/opponent icon; a full fixture calendar is
  future work). The screen shows the trophy + the manager's status, YOUR CUP RUN (the
  manager's tie each round), and THE DRAW (the latest round, the manager's tie in gold).
* Cup results also surface in the CLUB NEWS feed (gold, `_news_colour("cup")`).
