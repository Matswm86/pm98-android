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
