# Youth Team — reverse-engineering notes + model

The YOUTH TEAM is reached from the SQUAD MANAGEMENT (PLANTILLA) screen's bottom-right
button, which the squad-screen reverse located at `(0x20b,0x168)..(0x27b,0x181)` loading
`recursos\iconos\plantilla\juveniles.bmp` (see `squad_screen_re.md`). Until this session
that button was a painted dead-end; it now opens an interactive youth screen.

## Faithful surface (strings scanned from MANAGER.EXE)

The original game's youth surface is entirely string-resident; these are verbatim from
`extracted/Premier Manager 98/MANAGER.EXE`:

```
YOUTH TEAM            YOUTH PLAYER         PROMOTE / PROMOTED
YOUTH SCOUT          YOUTH MAN. / YOUTH MANAGER / YOUTH TEAM MANAGER
SCOUT                SCOUTS YOUTH TEAM    YOUTH TEAM SCOUT

You need to hire a scout to search youth players.
The scout is now searching for players
The youth team scout has finished his search.
The youth team scout has finished his search and hasn't found
%s has joined your Youth Team.
Your youth manager has informed you that
%s is ready to be promoted to the first team squad.
The youth player %s has rejected your offer.
```

So the original loop is: hire a **YOUTH SCOUT** → he searches → either "hasn't found" or a
youngster "has joined your Youth Team"; a **YOUTH MANAGER** develops them; when one is
ready the youth manager reports "%s is ready to be promoted to the first team squad"; you
**PROMOTE** him (a very raw prospect could reject the offer).

## What we built (and what is ours vs PM98's)

PM98's youth ratings + scout/manager quality are **data-driven** (loaded from the club
database at new-game), not code constants — there is nothing numeric to port, the same as
the transfer-fee and finance models (see `finance_constants.md`). So the **surface** above
is PM98's; the **development model** is ours, in `app/scripts/Youth.gd`:

- **Intake** (`Youth.intake`): a youngster aged 15–17 with a modest current ability (CA
  30–46) and a hidden **potential** (CA + 8..42, capped 88) — his ceiling. ~1 in 6 is a
  keeper. Ids are minted from `Career.YOUTH_ID_BASE` (900000), well above the ~8k senior id
  space, so a promoted youth never collides with a real player. He carries the **same dict
  shape** as a senior (`id/name/age/isGK/attrs{VE RE AG CA RM RG PA TI EN PO}`) plus
  `potential`, `dev_progress`, `ready`, `is_youth`, so every existing screen (squad,
  line-up, training, transfer value) reads a promoted youth unchanged.
- **Development** (`Youth.develop_week`): each youth climbs toward his potential (~a point
  of ability every ~3 weeks — one to two seasons to first-team grade). When his CA first
  reaches `READY_CA` (58) the youth manager flags him (`ready=true`) and a "youth" news
  line fires once. A youngster at his ceiling holds; a low-potential one never reaches the
  grade and ages out.
- **Career integration** (`Career`): a fresh career seeds an academy of `YOUTH_SEED_COUNT`
  (5); `advance_week` develops the youth alongside the senior training week; `advance_season`
  (`_roll_youth`) ages the youth a year, **releases** anyone over `GRADUATE_AGE` (19) who
  was never promoted, then scouts a fresh crop of 1–3 ("%s has joined your Youth Team").
  `promote_youth(pid)` moves a *ready* youth out of `youth` into `rosters[club_id]` on a
  fresh contract (guarded by the squad cap, faithful "not ready" / "squad full" refusals).
  `youth` + `youth_seq` persist in `to_dict`/`from_dict`; a pre-youth save loads an empty
  inert academy and gets its first crop at the next rollover.
- **Screen** (`app/scenes/YouthScreen.gd`): PM98 chrome (marble FONDO + BARRA + ProMan),
  the crop listed with current ability + a 1–5 **star** potential projection, the READY
  ones badged gold and tappable to PROMOTE; an ACADEMY count box, a star legend and RETURN.
  Interactive like `MenuScreen` (design-space hit-testing of rows + RETURN).

### Staff (EMPLE) hook

The original gates intake behind a hired YOUTH SCOUT and faster growth behind a YOUTH
MANAGER. The staff/employees screen is a separate deferred item, so the club currently runs
a baseline youth setup; `Youth.intake`/`develop_week` take a `factor` (default 1.0) so a
future staff system can raise intake quality + development rate with no rework here.

## Tests + verification

`app/tests/test_youth.gd` covers the unit model (intake shape, climb-to-potential, the
readiness flag + single news, graduate stamping) and the Career integration (seed,
develop, promote, the guards, rollover age/release/re-scout, persistence + legacy-save
compat). Verified by a REAL render (`PM98_YOUTH_SHOT=1` under opengl3): the YOUTH TEAM
screen with a READY gold prospect over four developing ones, and the SQUAD screen's now-live
green YOUTH TEAM button (`screens/youth.png`, `screens/squad.png`).
