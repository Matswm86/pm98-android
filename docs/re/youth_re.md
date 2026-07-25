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

---

## FRAME-TRUE SCREEN REBUILD (2026-07-16) — supersedes the screen section above

The landscape-list screen described above was OUR layout, not the game's. The original
YOUTH TEAM screen **is witnessed in the walkthrough** — main run frames `087_154632` /
`088_154633` (RATING held) / `089_154635` (RETURN held) and run-3 frames `047_164509`
(active scout search) / `048_164510` (SEARCH held) — and the screen was rebuilt
frame-true against them (the earlier "staff is a separate deferred item" framing had
gone stale once CLUB PERSONNEL shipped; the roster line "no walkthrough frame" for youth
was never true — same lesson as league-tables' `feedback-verify-agent-not-found-claims`).

**Witnessed layout** (both frames): shared live barra; SCOUT panel (portrait, black bar,
purple name bar + gold stars, SEARCH CAPABILITY 2×3 tracks with YES/NO values, six LED
toggles with labels, SEARCH plaque); PLAYERS FOUND panel (white interior, message);
MANAGER panel (portrait, black bar, blue name bar + stars, "N PLAYERS" count, green
YOUTH TEAM band, NAME/SP/ST/AG/QU/AV/ROL/WAGE/YEARS headers, 11 grey rows + folder
icons + scrollbar); PARAMETERS/RATING plaque toggle (+ static red arrow); bottom-right
HANDLING..SHOOTING tile grid; RETURN.

**Build** (`tools/re/build_youth_chrome_from_frames.py` → `app/art/screens/youth/`):
frame 087's body below the barra IS the authentic empty state and is baked verbatim as
`youth_body.png` — only the six YES/NO value cells (re-striped from the tracks' own
clean columns) and the PLAYERS FOUND interior (whited) are lifted out, because live
values replace them. Sprites cut verbatim from the frames: available/lit LEDs, enabled
SEARCH, PARAMETERS-unselected + RATING-selected plaques, star cells, and the three
held-state rings (`search_held` 048 red / `rating_held` 088 white / `return_held` 089
white). Facts decoded pixel-level along the way:

- **Values are INK-CENTRED per cell** (staff-wage doctrine): NO x110..124 / YES
  x107..127 share cx 117 (left col), cx 242 (right col). Face = **proman8 @ native 11**
  (frame 'N' 7×7 = the atlas bitmap exactly).
- **Message layout**: line 1 ink-centred on cx 476, line 2 LEFT-aligned to line 1's ink
  start (087 both lines start x392; 047 both x344 — line 2 alone is NOT centred). Face =
  **proman10 @ native 10** (frame 'e' 6×7 = its atlas; proman8 lowercase does NOT match).
- **Star rows alternate TWO sprites** (cells 1/3/5 = A, 2/4 = B, pitch 11) on both the
  scout and manager bars; a uniform sprite diffs on every even cell.
- **Three LED states**: disabled (087, no scout — baked), available (047, scout hired),
  lit (047 DRIBBLING/PASSING/SHOOTING = the selected capabilities).
- **SEARCH has disabled art** (087 pale lettering, baked) vs enabled (047 yellow).
- Column headers measured off the baked band: NAME x59..99, SP cx187, ST cx211.5,
  AG cx237, QU cx262, AV cx287, ROL cx312, WAGE cx358.5, YEARS cx418.5.
- Header seam pixel (58,522) is the ORIGINAL's own phase variance (in-season 44 vs
  preseason 22 grey); excluded in the gate with that provenance.

**Model wiring**: scout bar = `Staff.YOUTH_TEAM_SCOUT` hire, manager bar =
`Staff.YOUTH_TEAM_MANAGER`; capabilities YES iff a scout is hired (the witnessed pair;
a per-skill gradient is un-witnessed); LED taps toggle the search-skill selection;
SEARCH → `Career.start_youth_search(skills)` → `youth_search` ticks in `advance_week`
and resolves with the MANAGER.EXE strings ("finished his search" / "...hasn't found");
the searching state renders frame 047's message. Duration (`YOUTH_SEARCH_WEEKS` = 2)
and the find-chance (0.25 + 0.11·stars) are OUR reconstruction — the strings-decoded
loop is the game's, the numbers are not RE'd.

---

## PLAYERS FOUND is now a real shortlist (2026-07-25)

Owner report: *"the youth scout is the same [as the senior scout]. The players they find
are supposed to be possible to click on to offer contract. But that youth scout result
only appears once per season towards the end on original (or rather a set of weeks); in
our android game it's ok to lower the amount of weeks it takes so we have 2 intakes per
season."*

He is right that there is an offer step, and MANAGER.EXE proves it: **"The youth player
%s has rejected your offer."** (0x663be8) can only exist because the original ASKS. The
app used to skip straight from "finished his search" to "%s has joined your Youth Team.",
so there was nothing to click and no way to be turned down.

The loop now matches the strings:

1. `Career.start_youth_search(skills)` arms it and clears the last shortlist.
2. `_tick_youth_search` resolves it into **`Career.youth_found`** — up to
   `YOUTH_FOUND_MAX` (3) prospects, or none, with the game's own two messages (both also
   queued as hub alerts). Nobody joins on his own any more.
3. `YouthScreen` draws `youth_found` in the frame-measured `pf_interior`
   `[326, 102, 302, 117]` and a row tap emits `prospect_pressed(pid)`.
4. `Career.sign_youth_prospect(pid, rng)` signs him — *"%s has joined your Youth Team."* —
   or he refuses — *"The youth player %s has rejected your offer."* Either way he leaves
   the shortlist. Refusal odds rise with his hidden potential and fall with the YOUTH
   MANAGER's pull (OURS; the original's are database-driven).

**Cadence.** `YOUTH_SEARCH_WEEKS` 2 → **19**. The original delivers its intake once a
season, late on; 38 league rounds ÷ 19 gives the owner's requested TWO intakes per season
and no more (`test_youth_prospects` asserts both bounds).

**Still a reconstruction:** the panel's FILLED look. No frame we hold shows it, so the row
grammar (name · age · ability · 1-5 potential pips, 16px pitch) is the app's own, kept
plain and inside the measured interior. Render check `app/tests/shot_youth_found.gd`
(also asserts every row hit-tests back to itself); regression `test_youth_prospects.gd`.

---

**Honest gaps (do NOT invent)**: filled roster-row rendering (rows witnessed EMPTY —
values render in the game faces under the baked headers; WAGE/YEARS stay blank, youth
contracts un-modelled); the filled PLAYERS FOUND list; frame 047's "3 PLAYERS" over an
empty visible list (which counter that is is unresolved — live count = youth.size(),
the oracle pins the witnessed text); the bottom-right skill-tile grid's behaviour
(baked static, taps no-op); row-tap PROMOTE is an un-walked interaction (kept, no
visual badge); the shared PMChrome live barra is an approximation of the original
textured header (app-wide, tracked separately).

**Verification**: `tools/re/diff_youth_parity.py` — ALL FIVE shots (`shot_youth_parity.gd`)
diff **0px on the body** vs their binding frames (087/088/089/047/048).
`test_youth_screen.gd` (33 asserts) covers chrome json, state machine, LED geometry,
SEARCH signal gating, and the Career search model; `test_youth.gd` (model) + the full
37-file screen sweep stay green. Live render re-verified via `PM98_YOUTH_SHOT=1`.
