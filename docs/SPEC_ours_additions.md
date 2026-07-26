# SPEC — additions that are OURS, not the binary's (2026-07-25)

Companion to [`SPEC_scout_attribute_search.md`](SPEC_scout_attribute_search.md). Everything
here is a deliberate deviation from the original, approved by Mats on 2026-07-25. Label each
one in code the way `Youth.SEARCH_SPEEDUP` is labelled, so a later faithfulness audit does not
mistake it for reversed behaviour.

Ordered as agreed. Items 1-4 are **approved to build**. The appendix is **not**.

---

## 1. Honours board + career résumé

**Why.** The game tracks eight trophies but shows each one only in the moment it is won, then
forgets. Grep across `app/scripts` and `app/scenes` for `career_history`, `honours_board`,
`palmares`: **zero hits**. A ten-season save currently leaves no record of itself.

**Worse, the data is not even captured.** `Career._capture_euro_honours`
(`Career.gd:3736-3747`) stores `european_cup` and `cup_winners_cup` only, so the **U.E.F.A.
Cup winner is discarded every season** — including when it is you. That is finding R14 of the
reference run, and it has to be fixed first or the board will have a permanent hole.

**The eight trophies**, witnessed on the season-end trophy backdrop
(`out/refrun-manutd-9798/play/p0538_UNKNOWN.png`) and on THE CHAMPIONSHIPS sheet:

Premier League · F.A. Cup · Coca-Cola Cup · Charity Shield ·
European Cup · U.E.F.A. Cup · Cup Winner's Cup · European Supercup

The Intercontinental Cup is a ninth one-off that is *not* on the backdrop but does raise its
own champion card (R7), so decide whether it earns a résumé line.

**What to build.**

- **Honours board** — per trophy, the seasons you won it and the seasons you were runner-up.
  Source it from the same record the champion cards are built from, so a level final carries
  its `(on penalties)` qualifier (R14) rather than a bare score.
- **Career résumé** — one row per season: club, division, final position, the board's
  objective and whether you met it, cups reached and won, and whether the season ended in a
  sacking or a move. The original raises no board-verdict screen at all (R15), so this is
  where a career's shape becomes legible for the first time.
- **Across clubs.** `Career.seasons_at_club()` and `spell_start_year` already track spells, so
  a résumé spanning clubs is close to free.

**Presentation.** Reuse the champion-card chrome — one layout already serves at least six
competitions at pixel parity (R15), and the trophy backdrop art is a shipped asset for five of
the eight. Do not invent a new visual language for this.

## 2. Enforce and surface the scout-quality result cap

**The bug.** `Youth.gd:22` records the senior scout's shortlist cap from `FUN_00575750` as
**`(quality + 2) * 5`**. Neither `Career._tick_scout_search` (`Career.gd:2255`) nor
`_scout_scan_own` (`Career.gd:2270`) applies any cap: the scan appends every match it finds.
So **a 1-star scout returns exactly what a 5-star scout returns**, and scout quality is
currently decorative on the senior side.

Caps implied by the formula: 1 star -> 15 · 2 -> 20 · 3 -> 25 · 4 -> 30 · 5 -> **35**.

**Do not truncate silently** ([[feedback_no_silent_failures]]). Show the shortfall in the
PLAYERS FOUND panel — *"35 of 112 shown, limited by your scout"* — so a better scout is a
visible upgrade rather than an invisible one. That line is ours; the cap is the binary's.

**Open question for whoever builds it:** the cap is a *count*, so which 35 of the 112? The
original's result order is un-RE'd (see item 4), so pick a defensible rule and document it.
Highest `AV` first is the honest default; a random draw would make a good scout feel worse.

## 3. Put AV in the PLAYERS FOUND list

`AV` is `(SPEED + STAMINA + AGGRESSION + QUALITY) / 4` (`TransferMarket.av_of`, from
`FUN_0057a5a0`) — **the same number the match engine uses as a player's strength**. It is
therefore the only column in the list that predicts results.

The youth PLAYERS FOUND panel already shows `AV` (witnessed:
`out/refrun-manutd-9798/play/p0758_UNKNOWN.png`, `Spindle AV 18`). The senior list should
match it. Without this, the six new attribute filters in the companion spec return names with
no way to judge them.

## 4. Sortable result columns

Once six independent filters can return dozens of rows, an unsorted list defeats the feature.

**Nothing to be faithful to here:** `Career.gd:2268` states outright that *"The original's
result order is un-RE'd (`scout_screen_re.md`) — this is the app's own scan order,
documented."* So sorting is a free addition. Sort on any shown column, AV included.

---

## Appendix — making Shooting matter. NOT APPROVED. Do not build without Mats.

Recorded because the mechanism was established today and should not have to be rediscovered.
**Decision pending.** It changes every result in the game and would break match parity with
the original by design, so it needs a career-start switch ("Classic 98" / "Extended") stamped
into the save.

### How a goal is actually decided (`Pm98StatMatch`, oracle-validated)

1. **The opposing keeper gets a save roll first.** `rng.mod(130) < GKSAVE`, where
   `GKSAVE = HANDLING + 10` in the keeper slot, clamped to 99 (`Pm98StatMatch.gd:180-182`).
   Pass, and the goal simply does not happen. So **HANDLING is the most powerful single
   attribute in the game**: at the 99 cap a keeper erases `99/130 = 76%` of would-be goals,
   against `38%` for a HANDLING-40 keeper. This also confirms there is no point paying for a
   keeper above HANDLING 89 — that is where the clamp bites.
2. **The scorer is then a role-weighted roulette** over the ten outfield players, re-rolled
   until an available player wins (`Pm98StatMatch.gd:189-207`). Weights are
   `POS_WEIGHT` (`DAT_006532ec`), indexed by the player's fine role:

| role | w | role | w | role | w |
|---|---|---|---|---|---|
| CENTRE FORWARD | **35** | RIGHT / LEFT WINGER | 15 | INSIDE RIGHT / CENTRAL MID. / INSIDE LEFT | 10 |
| CENTRAL STRIKER | 18 | RIGHT / LEFT MID. | 12 | INS. CENT. LEFT / RIGHT | 7 |
| RIGHT / LEFT FORWARD | 18 | | | full backs, sweeper, def. midfielder | 3 |
| | | | | KEEPER | 0 |

That is why a centre forward scores ~12x as often as a right back across a season, and it is
role doing the work, not dice.

### The gap, and the minimal change

**SHOOTING, DRIBBLING, HEADING and TACKLING never enter any of it.** Two centre forwards both
sit at weight 35 whether they shoot 98 or 72.

The minimal intervention is therefore one line: **scale the existing role weight by the
player's SHOOTING** — e.g. `POS_WEIGHT[role] * shooting / 75` — which keeps the role structure
that already produces believable distributions and makes a 98 striker outscore a 72 one by
about a third. Redistribute, do not add on top, or league goal totals inflate and the table
stops looking like 1998.

The same shape extends to the other three if wanted: HEADING weights who gets the header on
set pieces (header events are already distinguished in commentary), TACKLING feeds how many
chances a defence concedes, DRIBBLING weights the assist roll.

---

## BUILD LOG — 2026-07-25 (late). Items 1-4 shipped; two of them were wrong as specified.

### 1. Honours board + career resume — BUILT

The R14 blocker was already closed (`Career._capture_euro_honours` captures
`euro_winner_uefa`), so the board ships with no hole. Added:

* `Career.honours` — one record per COMPLETED season, written by
  `_capture_season_honours()` at the rollover while the brackets still stand. Idempotent
  per (season, club). Persisted; a pre-ledger save loads with an empty ledger.
* `Career.honours_board()` — the fold: per competition, the seasons won and the seasons
  lost in the final, each carrying its own `(on penalties)` qualifier from the tie itself.
* `Career.career_resume()` — one row per season: club, division, final position, the
  board's objective and whether it was met, the trophies lifted, how the season ended.
* `app/scenes/HonoursScreen.gd` — two pages, HONOURS and CAREER.

**Presentation note, deliberately not followed to the letter.** The spec said to reuse the
champion-card chrome. The champion card is a single-trophy card; an honours board is a
list of nine competitions across N seasons, and forcing the card's layout onto it would
have meant inventing a card that the original never draws. The screen instead borrows the
SCOUT extra-panel plate — an OURS surface that already exists — and says on its own face
that it is this port's, not the 1998 game's.

**Entry point:** a tap on the manager-name plaque of the witnessed MANAGER HISTORY screen,
a zone that screen leaves inert. MANAGER HISTORY still renders **0 px** against both its
witnesses (`diff_managerhistory_parity`, re-run). Nothing advertises the tap, because
drawing a button there would cost a witnessed pixel.

### 2. The scout result cap — BUILT, and the spec's numbers were WRONG

`FUN_00575750` was disassembled (see `docs/re/scout_screen_re.md`). Two corrections:

* **The ladder is 20 / 25 / 30 / 35 / 40 / 45 / 50 / 55 / 60**, not 15/20/25/30/35. The
  quality byte in `(quality + 2) * 5` is the raw **1..10 half-star** value, not the 1..5
  star count. A ★★★ scout caps at **40** — which is exactly the result count the 2026-07-18
  witness frame 81 encodes in its 18px slider. Had the spec's ladder been implemented, it
  would have contradicted a live frame.
* **"Which 35 of the 112?" is not ours to choose.** The resolver keeps its N by a uniform
  random draw without replacement. Not highest-AV. A weak scout brings back fewer names,
  not worse ones.

The shortfall line ships as asked, in the extra-filters panel:
*"40 of 112 shown - your scout could only bring back 40."*

### 3. AV in PLAYERS FOUND — ALREADY THERE, nothing to do

The spec says the senior list does not show AV. It does, and always has:
`ScoutScreen._draw_row` draws it at `CELL_AV_CX` in `C_AV`, and the RE doc's own
verification line pins the digit-centring of "69" to witness ink x238. AV is a witnessed
column of the original's own header strip, not an addition. No change made.

### 4. Sortable result columns — BUILT

`ScoutScreen.view_rows()` sorts on NAME / AV / MO / CLUB FEE / WAGE / AGE, either
direction. The control lives in the extra-filters panel rather than on the header strip,
because a sort marker drawn on the witnessed headers would cost parity. Default is the
Career scan order, i.e. exactly what the screen showed before.

### 5. The DOOR — added 2026-07-26, because items 1-4 were invisible

Approved by Mats on 2026-07-26 after he reported the additions missing from the build:
*"I don't see the new search objects. Scout screen looks like it always has still."* They were
all there. What was missing was any way to know: the panel opened by tapping the bottom bar,
which was a blank grey two-segment field with **no label of any kind**. Nothing on screen
suggested it did anything.

The bar now carries `EXTRA SEARCH FILTERS` in its left segment and `TAP HERE` (or `N ACTIVE`,
or `CLOSE` while open) in its right, in the screen's own proman8-at-11 black.

**And the bar turned out not to be ours to take.** Checking it against every committed frame
of the screen — instead of only the six parity witnesses — found three in which the ORIGINAL
uses it: a per-row rollover readout printing the held row's club kit, full name and club. That
is now built and render-diffed at 0 px (`docs/re/scout_screen_re.md` §"The bottom bar"). So the
label is drawn **only while the original's readout is empty**, and yields on the first press.
`tools/re/diff_scout_bar_parity.py` proves both halves from the frames.

This is the second and last site in the port that draws a pixel the original does not; the
other is THREE UP FRONT on the OPTIONS modal. `docs/REMAINING.md` §3b keeps the count visible.

### The appendix (making SHOOTING matter) — still NOT APPROVED, still not built.
