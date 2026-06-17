# MANAGER CAREER ACROSS CLUBS — sacking, job offers, history (T2 #14)

PM98 was a *manager* career, not a club save: the board set you an objective, sacked
you for falling well short of it, and once you were out of work (or had earned a
bigger job) other clubs came in for you. Your career spanned several clubs. This
increment builds that core.

Scope decided with the owner (2026-06-17): **Core + multi-club history** — sacking,
job offers, and a persistent record across every club you manage. The decision math
is a small pure module; the Career holds the state; Main resolves abstract offers to
real GameDB clubs and renders the screens.

## Source grounding
The board's confidence in you is a real reversed mechanic: `docs/re/directiva_screen_re.md`
decoded the BOARD OF DIRECTORS screen's live DIRECTORS / SUPPORTERS CONFIDENCE bars
(`team+0x2c / +0x30`) and the board's objective-text panel. Those confidence stats
are the substrate the original used to decide your fate. This increment models the
*consequence* (the keep/sack verdict + what follows) on top of the existing
objective system (`Career.objective_pos` / `objective_text` / `position()`).

## The decision math — `app/scripts/Manager.gd` (pure, GameDB-free)
- **Reputation** (0..100, starts 50). `reputation_delta(finished, objective, total,
  releg, titles)`: each place above/below the objective is +/-1.4, a league title
  +12, a domestic cup +6, relegation an extra -10. `apply_delta` clamps to [0,100].
- **Sacking** `sack_decision(...)`: sacked when relegated and the brief was not
  survival, OR when you finish `SACK_GAP` (6) places below the objective. Your first
  season at a club is judged more leniently (`SACK_GAP_YEAR1` = 9).
- **Headhunting** `headhunted(...)`: when you finish `HEADHUNT_GAP` (4) places ABOVE
  the objective and your reputation clears `HEADHUNT_REP` (55), a stronger club may
  approach you even though you are safe (probability scales with overachievement).
- **Offer band** `offer_band(reputation, sacked)`: the count + strength-percentile
  window of clubs that will offer you a job. Higher reputation → stronger clubs; a
  sacking dents the band.

## Career state + wiring — `app/scripts/Career.gd`
New state (all saved): `reputation`, `manager_history` (past spells), `pending_offers`,
`sacked`, `sack_reason`, `headhunt_pending`, `spell_start_year`, `_rep_year` (the
once-per-season idempotency guard).

- `board_review()` — called at season end. Once per season (guarded on `_rep_year`):
  applies the reputation delta, runs the sack decision, rolls the headhunt, and (on a
  sack) applies the extra reputation hit. Returns the display summary. Idempotent on
  repeat calls within a season (a redraw never double-applies).
- `take_job(club, league, league_clubs, leagues, reason)` — switch clubs mid-career:
  records the current spell into `manager_history`, advances the career year, and
  rebuilds every per-club piece of state via the new `_init_club` (factored out of
  `create`, so a brand-new career and a club switch share one setup path). The manager
  carries only reputation + history + the year counter; rosters, cash, stadium, youth,
  staff, cups and European state all reset to the new club.
- `record_spell` / `seasons_at_club` / `_releg_count` / `_won_domestic_cup` support it.

`create` now delegates to `_init_club` after seeding `reputation`. The refactor is
behaviour-preserving for an unbroken single-club career (`test_career` unchanged).

## UI — `app/scenes/Main.gd`
- `_show_end_of_season()` runs the board review and branches: **sacked** → the
  dismissal message + "See which clubs want you"; **headhunted** → "Stay" vs "Hear out
  job offers"; otherwise the normal "Start next season". A "Your managerial record"
  row is always present.
- `_generate_offers(headhunt)` maps the Career's `offer_band` to real clubs: every
  manageable club ranked weakest→strongest, sliced to the reputation percentile window,
  the managed club excluded, a headhunt restricted to stronger clubs. Stable across
  redraws.
- `_show_job_offers()` (JOB OFFERS browse) → `_accept_job()` → `Career.take_job` →
  `_enter_career()` at the new club.
- `_show_manager_career()` (YOUR CAREER browse): reputation + label, the current club,
  and every past spell most-recent-first (a sacked spell reads red). This is the
  MANAGER INFO the board screen points at, surfaced as a PM98-chrome list.

## Verification
- `app/tests/test_manager.gd` — 37 assertions: the Manager decision math at its
  boundaries, then the Career integration (sacked at an unmeetable objective,
  reputation drop, idempotent review, a cross-division `take_job`, the spell recorded
  as a sacking, reputation carried, the new club starting clean, the over-achiever
  kept + climbing, a save/load round-trip). `test_career` is the no-regression canary.
- Real GL renders (PM98_MANAGER_SHOT): `job_offers.png` (a sacked manager offered two
  Division Three clubs) and `manager_career.png` (reputation 36 "Unproven"; current
  club ROCHDALE; past spell CRYSTAL PALACE, 1997-98, 19th, sacked, in red).

## Open follow-on (optional, not built)
The board screen (DIRECTIVA) is still tap-to-dismiss; a Tier-3 polish would wire its
reversed MANAGER INFO widget to open YOUR CAREER directly, and show a live
sack-pressure warning on the board panel during a bad season.
