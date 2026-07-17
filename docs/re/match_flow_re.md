# PM98 CAREER MATCH FLOW — MATCH OPTIONS + BRIEF + RESULT (RE + rebuild)

The career match presentation: the in-match **MATCH OPTIONS** picker, the running
**BRIEF** read-out, and the **HALF/FULL TIME RESULT** read-out. Rebuilt frame-true from
the real game's own captures. User priority (APP_VS_SPEC_AUDIT §B6): **BRIEF + RESULT are
the target; 3D WATCH is last.**

Owner scenes: `app/scenes/MatchOptions.gd`, `app/scenes/MatchScreen.gd` (BRIEF),
`app/scenes/MatchResultScreen.gd` (new). Static chrome baked by
`tools/re/build_match_flow_chrome_from_frames.py` → `app/art/screens/matchflow/*.png` +
`tools/re/specs/match_flow_chrome_samples.json`. The barra is the parity-locked
`PMChrome.draw_match_header` (docs/re/match_header_re.md) — reused, never rebuilt.

## Binding frames (the pixel source)

| Screen | Frame | State |
|---|---|---|
| MATCH OPTIONS | `wine-captures-2026-07-12/dropdown_matchoptions_match.png` | MATCH tab; RESULTS red, LINE-UPS ON, CANCEL/OK |
| RESULT FULL TIME | `wine-captures-2026-07-12/match_result_fulltime.png` | Man Utd 1-2 Bolton, Old Trafford, MotM Cole |
| RESULT HALF TIME | `wine-captures-2026-07-12/match_result_halftime_oldtrafford.png` | HALF TIME; manager-side TACTICS/LINE-UP |
| BRIEF | `original-walkthrough-2026-07-02/073_162649.png` | F.C. Barcelona 0-0 Man Utd, KICK OFF |

Also witnessed (not baked from, cross-checks): the away-side RESULT layout
`match_result_halftime_{reebok_home,morumbi_away,selhurst_away}.png` (manager LINE-UP/
TACTICS sit on the manager's side), the walkthrough FULL TIME `083_162707` (Barcelona
2-2, identical chrome to the fresh capture), and the BRIEF-family frames `055-085`.

## MATCH OPTIONS — geometry

Reversed controller **FUN_004e2630** (match_view_re.md): the four view-mode buttons are a
single row, 98×25, at y100, panel-local x {5,109,214,317} inside a 437-wide panel. The
frame is the pixel source; the whole modal is cut **verbatim** to `mo_modal.png` (446×258,
anchored (98,116)) — every label is static chrome so nothing is redrawn. Frame-measured
absolute hit-rects (spec `match_options`): view row y 279..297 — WATCH(116,97) /
HIGHLIGHTS(220,97) / BRIEF(325,97) / RESULTS(428,97); bottom row y 342..370 — CANCEL(323,102)
/ OK(430,102). Routing: WATCH→2D simulador, BRIEF→brief, RESULTS→brief seeked to 90',
HIGHLIGHTS→honest note (3D `.p3d` absent from disc + .rar), CANCEL→dismiss, OK→confirm.

## BRIEF — geometry (frame 073, spec `brief`)

Frame 073 is KICK OFF (empty EVENTS, 0-0), so the resting chrome is the frame itself with
only the dynamic club NAMES + the state label cleared (`brief.png`). The screen redraws:

- **Clock** LCD box x258..372 y30..100 (digit over-painted; proman18 approximates the
  original 7-seg face — GAP), **half/state label** below (KICK OFF / FIRST HALF / …).
- **Scoreline** on the black band (y99..136): kits at the ends (KIT_H 8..70 / KIT_A 585..638),
  home name x76..256, score boxes x258..320 + x322..380, away name x382..586.
- **POSSESSION** bar — GAP (see below), left the frame's neutral 50/50.
- **EVENTS** white body x312..470 y268..432, MIN col x316, COMMENT x356, clipped to the panel.
- In-match buttons: LINE-UP(495,227) / TACTICS(495,283) / MAN-TO-MAN(495,339) /
  STATISTICS ×2 (495,393)+(14,393) — chrome, open no sub-screen on this path; KICK OFF
  (262,442) advances to full time / CONTINUE, EXIT(508,442) leaves.

## RESULT — geometry (frame fulltime, spec `result`)

Barra (PMChrome.draw_match_header, fixture mode) + the baked HALF/FULL TIME title sprite
(`title_{halftime,fulltime}.png`, chrome-gradient frame sprites, anchored (242/244,13)).
Below (all cleared in the bake, redrawn by the screen):

- **Scoreline band** y66..108: home kit (6,60) / away kit (590,60), home name from x40,
  away name to x604, score boxes x246..320 + x339..375.
- **GOALS columns** = the REAL vector: home col x169..289, away col x482..602; 7 rows,
  first row top y172, pitch 16, scorer left + minute right. **BOOKINGS** columns stay empty.
- **TOTAL FOULS**, **POSSESSION %** — GAP (over-painted honest-absent).
- **STADIUM panel** (x14..292, y348..452): car icon + ground name + CAPACITY + ATTENDANCE
  (Career-known); the ATTENDANCE-MONEY / SPONSOR-BOARDS / SPONSORSHIP-MONEY rows stay blank.
- **MAN OF THE MATCH** (full time, x325..604): header + generic sprite kept, name blank (GAP).
- **CONTINUE** (479,439) full time only; the HALF TIME read-out dismisses on any tap.

## Event grammar — renderable TODAY vs GAP

The instant-result stat engine (`Pm98StatMatch`, via `MatchSim.simulate`) records **only
goal events** — `{minute, side(credited 0/1), scorer, scorer_side, own_goal}` (MatchSim
`_resolve_goals`). So of the witnessed BRIEF/RESULT grammar (APP_VS_SPEC_AUDIT §B4b):

| Field | Source | Status |
|---|---|---|
| Scoreline (H-A) | `MatchSim` `home_goals`/`away_goals` | **REAL** |
| GOALS: scorer + minute | the stat engine's goal vector | **REAL** |
| BRIEF feed: Kick Off + Goal lines | goal vector (fabricated RATE_* dropped) | **REAL** |
| Stadium CAPACITY / ATTENDANCE (+%) | `Career.stadium_capacity` / `finance_preview` | **REAL** (Career model) |
| BRIEF feed: Shot / Save / Run / Cross / Header / Injury | positional engine only | **GAP** — omitted |
| BOOKINGS (name+min) | positional engine only | **GAP** — empty chrome |
| TOTAL FOULS | positional engine only | **GAP** — blank |
| POSSESSION % | not produced | **GAP** — neutral empty bar |
| ATTENDANCE MONEY / SPONSOR BOARDS / SPONSORSHIP MONEY | per-match money not modelled | **GAP** — blank |
| MAN OF THE MATCH | not produced | **GAP** — blank panel |

Full fidelity of the GAP rows needs the positional match engine's event stream (the
`Pm98Match`/`Pm98Driver`/`Pm98Outer` track, still test-only) — never fabricate them.
`MatchCommentary`'s RATE_* shots/fouls/cards/corners are **dropped at the consumer**
(`MatchScreen._honest_feed` keeps only goal-flagged lines).

## Parity status

- MATCH OPTIONS: **frame-true** (modal cut verbatim; 0px by construction).
- RESULT / BRIEF: static chrome is the real frame with dynamic data cleared + redrawn.
  Frame-true chrome; **approximated** where a dynamic value is redrawn with a substitute
  font (club names/scores proman18; stadium labels + goal rows proman8 — the original
  faces are not isolated). Full-pixel parity **NOT MEASURED** (no clean original render of
  a *matching* fixture to diff against — the frames carry different clubs/values).
- Honest GAPs are rendered as empty/blank original chrome (never fabricated).

## Wiring (Main.gd — NOT edited; owner boundary)

- `_career_advance()` (friendly / `advance_week`) → `_show_match_result(res)`; `res` carries
  the real `goals` vector. `_next_fixture()` resolves the pending friendly then the league
  fixture (feeds the header plaques).
- Today `_show_match_result` → `MatchCommentary.narrate(...)` → `_open_match()` mounts
  **MatchScreen (BRIEF) + MatchOptions**. The BRIEF feed is ALREADY honest — MatchScreen
  drops the fabricated lines, so no Main.gd change is required for the BRIEF honesty fix.
- **RESULT screen wiring — APPLIED 2026-07-13.** `_show_match_result` still mounts the
  running BRIEF + MATCH OPTIONS (BRIEF stays honest, preserved), and now the MATCH OPTIONS
  **RESULTS** tap opens `MatchResultScreen` over the BRIEF via `_open_result_readout(...)`.
  `_open_match` gained an optional `result_data` param carrying
  `setup(home, away, res.hg, res.ag, res.goals, home_id, away_id, header, stadium, false)`;
  `continue_pressed` → free the read-out + free the BRIEF + `_show_career()` +
  `_pop_pending_team_offers()`. So MATCH OPTIONS' RESULTS/BRIEF taps choose between the
  RESULT read-out and the running BRIEF, as intended. Two honest notes on the applied data:
  the `header` reuses `_match_header()` with the played fixture's clubs overridden in, so its
  **date grammar reads the next week's date** (minor, un-load-bearing gap); the `stadium`
  panel is Career-known **manager-home only** (`finance_preview` capacity+attendance) — away
  venues pass `{}` (opponent gate un-modelled → honest blank panel). Watched (non-career)
  matches pass no `result_data`, so their RESULTS tap keeps the seek-to-90' behaviour.

## Charter #5 APPLIED — 2026-07-17 (witness semantics, s13 app lane)

The full career matchday chain is now wired per the LIVE witness run
(`matchday_flow_witness_re.md`; every conflict in its "FOR THE APP LANE" list
resolved):

- **MATCH OPTIONS = first career match only** (`Career.match_options_shown`,
  persisted). CANCEL -> un-advanced hub; a view-mode tap (or OK) LAUNCHES
  immediately (`MatchOptions.launch_on_select`, matchday context only); the
  LINE-UPS toggle is the ON/OFF cell ONLY (label plate inert); backdrop dim
  removed (frame 60: hub behind is pixel-identical to the plain hub).
- **Pre-match XI-vs-XI photo roll** (`LineupRollScreen.gd`) in EVERY view mode
  when LINE-UPS is ON: ~0.9s clean fondo, ~4.3s/row (faces grow in place,
  home first, away +1.5s; home name slides from the left on its band; away
  name slides from the right as a white plate w/ black ink; numbers last),
  header + manager row, ~8s hold, AUTO-advance; tap mid-roll snaps complete;
  chrome from `tools/re/build_prematch_roll_from_frames.py` (band-translucency
  LUT; complete-board chrome gate vs walkthrough 055 = **4px**). CPU XI = the
  shipped .DBC XI (club_tactics.json, VIEW RIVAL rule), manager XI = Career
  tactics; numbers = squadNo, slot 1..11 fallback.
- **BRIEF states**: idle = full buttons (brief.png); RUNNING = EXIT only
  (`brief_running.png`, baked from the 07-17 witness still); FULL TIME = a
  single CONTINUE in the EXIT slot (`brief_ft.png`, baked from orig/68).
  Feed opens with the plain "Kick Off" line.
- **RESULTS mode**: roll -> HALF TIME read-out (first-half goals/score) ->
  FULL TIME read-out -> hub (`Main._halftime_data`).
- **EXIT mid-match** = "Do you want to leave the championship ?" (PMAlert
  `yesno` render; Yes/No cells cut from the witness still, No at the OK
  anchor). No -> resumes (match paused under the box); Yes -> TITLE SCREEN
  with the in-flight week NOT persisted — the week autosave is DEFERRED to
  the hub return (`_career_advance` / `_show_match_result`).
- Verified LIVE end-to-end (fresh mwm@Bolton career, DISPLAY=:1): modal ->
  BRIEF-tap launch -> roll -> KICK OFF -> running -> EXIT alert No-resume ->
  FT -> read-out -> shield -> season start -> hub wk1; wk-1 CONTINUE with no
  modal -> roll snap-tap -> auto-advance -> EXIT-Yes -> title; LOAD GAME ->
  hub still Week 1 (the abandoned week not saved).
- Remaining flags: clock digits stay the proman18 approximation (7-seg face
  un-extracted); the original deploys the hub TOP DROPDOWN BAR behind the
  matchday modal (ours stays closed); read-out repairs = charter #6; BRIEF
  possession/feed richness = charter #7 / M5 gap; roll corner kits = the
  un-extracted hi-res kit render family.
