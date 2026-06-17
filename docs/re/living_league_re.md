# LIVING LEAGUE — rival clubs' squads injure & develop in-season (T2 #12)

PM98 simulated a *living* league: the CPU-controlled rival clubs were not frozen
tables of static ratings. Their players picked up injuries, developed and declined
across a season, so the form table you chased actually moved. This increment brings
the rival (AI) squads up to the same engine depth the manager's club already had,
so rival ratings drift through the season instead of standing still.

Scope decided with the owner (2026-06-17): build it as a **faithful** reproduction,
not a flagged enhancement. The original modelled a living league; this mirrors the
manager-club mechanics (Availability + Training) onto the rivals.

## What changed (all in `app/scripts/Career.gd`)

### 1. Availability-aware AI ratings — `_ratings_for(id)`
Previously a rival club was rated from its FULL roster (`club_view(id)`), so a
rival's injuries never weakened it. Now a rival is rated from its **available**
players only (`_fit_view(id)` → `MatchEngine.team_ratings`), exactly as the
manager's XI already excludes injured/suspended men. A thin rival XI pulls toward
`MatchEngine`'s rating floor (never below it), so an injury crisis at a rival is a
real, bounded dip in their results — not a collapse to zero.

The manager's own club (chosen tactics) and frozen foreign European opponents
(`euro_ratings`) are unchanged. Legacy saves with no live roster for a club still
fall back to the static `clubs_override`.

### 2. A rival week, lived — `advance_week` → `_roll_ai_squads`
Each round, for every rival club:
- `_ai_featured_by_club()` captures the fit XI each rival fields this round (its
  keeper + ten outfielders by current ability, availability-filtered), captured
  BEFORE the match so the rolls land on who actually played.
- `Availability.tick_week(squad)` — recoveries tick (discarded; the rival feed
  stays quiet).
- `Availability.roll_match(rng, featured)` — this round's knocks/bookings land on
  the rival XI. A NEW injury of `AI_INJ_NEWS_WEEKS` (3) matches or longer is
  surfaced to the club news feed ("CRYSTAL PAL.'s NASH is out injured for 3
  matches."); minor knocks drift quietly.
- `Training.train_week(rng, squad, "Normal")` — the rival squad develops (young
  rivals climb, veterans slide), so ratings drift over the season.

The manager's own club is excluded here (it is rolled separately on its chosen
tactics + training intensity, as before).

### 3. Rollover — rivals age and reset, like the manager's club
In `advance_season`, alongside the existing AI contract auto-renew, each rival
player now ages a year and the squad is reset for the new season:
`Availability.reset` (bans/injuries cleared) + `Training.reset_progress`
(development carry-over zeroed). So the dev engine re-evaluates each rival from his
new age each season — the multi-year drift that makes a living league move.

## Bounds / guards (the "ratings bounded, squads fieldable" invariants)
- **Squad size**: injuries never remove a player, so they cannot shrink a roster.
  The only thing that resizes a rival squad is the pre-existing AI transfer market,
  which already refuses to sell below `TransferMarket.SQUAD_MIN` (16).
- **Attribute drift**: `Training` clamps every attribute it develops to
  `[ATTR_FLOOR=22, ATTR_CAP=96]`; CA never climbs past the cap. (Seed ratings can
  sit naturally outside that softer band — the clamp only governs change.)
- **Performance**: a full Premier season with all ~19 rivals living costs ~3.1s
  headless (the `test_career` canary), well inside budget.

## Open follow-on (Tier 3, flagged not built)
Rivals age but there is no AI youth/regen intake yet, so over many (5+) seasons a
league would slowly soften as veterans decline toward the floor with no fresh blood.
The dev floor bounds it, and real careers run a handful of seasons, but a faithful
multi-decade living league wants rival youth regen — deferred to Tier 3.

## Verification
- `app/tests/test_living_league.gd` — two full seasons: asserts rival injuries
  appear in-season, a notable one reaches the news feed, rival ratings/attributes
  drift, squads stay at/above the SQUAD_MIN floor, attributes stay sane, and the
  rollover ages + resets the rivals. `test_career.gd` is the perf canary.
- Real GL render `club_news.png` (PM98_SCREENS_SHOT): the CLUB NEWS feed shows
  named rival injuries (Crystal Palace, Newcastle, Bolton) interleaved with the
  manager's results — the living league made visible without flooding the feed.
