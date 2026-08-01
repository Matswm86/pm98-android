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
HIGHLIGHTS→honest note (3D `.p3d` UNOPENED — s85: absent from the .rar, but the ISO's
314 MB `PCF5DAT.PKF` has never been enumerated), CANCEL→dismiss, OK→confirm.

## BRIEF — geometry (frame 073, spec `brief`)

Frame 073 is KICK OFF (empty EVENTS, 0-0), so the resting chrome is the frame itself with
only the dynamic club NAMES + the state label cleared (`brief.png`). The screen redraws:

- **Clock** LCD box x258..372 y30..100 (digit over-painted; proman18 approximates the
  original 7-seg face — GAP), **half/state label** below (KICK OFF / FIRST HALF / …).
- **Scoreline** on the black band (y99..136): the fixture escudos at the ends (home
  x14..55 / away x585..626, the escudo drawn to the frame-64 kit bounds — scale 1.32,
  anchor y57 lands the opaque y24..63 at y89..142). The frame-073 kits are BLANKED in the
  bake (build_match_flow: home x8..74 / away x560..640, y80..150) so the wrong club's kit
  no longer shows around the redrawn one (the "Villa red" parity bug, charter #7c).
  home name x76..256, score boxes x258..320 + x322..380, away name x382..586.
- **POSSESSION** bar — LIVE (charter #7b): the real engine POSS counters, see below.
- **EVENTS** white body **x153..467** y269..436 (light-grey MIN col x153..198 + white
  COMMENT col x199..467, scrollbar x470..476): MIN right-aligned at x190, COMMENT
  left-aligned at x199 clipped to the panel. (The old x312..470 rect drew only the right
  third, clipping the goal line's club — "Goal by Salako" → "Goal by Milose", charter #7a.)
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
- **STADIUM panel** (x14..292, y348..452) — REBUILT 2026-07-24. The two witnessed FT
  boards (Old Trafford `match_result_fulltime.png` vs The Dell `15_fulltime.png`) were
  diffed pixel-for-pixel: only the six VALUE spans differ, so the arrow chevrons, all
  five row LABELS, the sub-cell boundaries and the stadium sprite are STATIC chrome.
  The old bake row-medianed the whole label area away, leaving blank bars under a
  floating sprite — the reported "stadium image truncated and wrong". Value anchors
  (ink runs, identical in both frames): ground name x86 y358 (black on white);
  CAPACITY x109 y377; ATTENDANCE x128 y394 + "NN %" in the right sub-cell x236;
  ATTENDANCE MONEY x177 y411; SPONSOR BOARDS SOLD "NN %" x236 y428; SPONSORSHIP
  MONEY x177 y445. All five now FILL (see the money-row note below).
- **MAN OF THE MATCH** (full time) — LIVE 2026-07-24. Black header band x310..585
  y349..369; 32x32 mugshot cell at (312,370); the name centred on the blue band
  (x346..583 y370..401, 4-row vertical period) in **ProMan10** ink (180,200,220) —
  "Holdsworth (Bolton W)" measures 159px of ink and only ProMan10's advances (154)
  come near it. The pick is `Pm98StatStore.pick_mom` (FUN_0044a370, oracle-banked),
  surfaced through `Career.fold_match_stats` → `manager_res.motm_pid`.
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
| Stadium ground NAME + CAPACITY | GameDB `club.stadium` / EQUIPOS `param_1[6]` (all 476 clubs) | **REAL** (source-exact, always filled) |
| Stadium ATTENDANCE (+%) | `finance_preview` (home) / `FinanceModel` (away) | **PROJECTION** (runtime gate un-reproducible) |
| BRIEF feed: Shot / Save / Run / Cross / Header / Injury | positional engine only | **GAP** — omitted |
| BOOKINGS (name+min) | positional engine only | **GAP** — empty chrome |
| TOTAL FOULS | positional engine only | **GAP** — blank |
| POSSESSION % (BRIEF bar) | `Pm98StatMatch.possession` — the engine's own `POSS` (0x64/0x804) counters, `_stats` FUN_00450510 | **REAL** — home/(home+away); the BRIEF bar eases 50/50→final over the clock (final split is engine-exact; the per-minute path is a display ease, the instant engine having no per-minute stream) |
| ATTENDANCE MONEY / SPONSOR BOARDS / SPONSORSHIP MONEY | the FINANCES ledger's own TICKETS / SPONSOR BOARDS lines divided by the tier's home-game count (`FinanceModel.summary`) | **PROJECTION** — same standing as ATTENDANCE; the original's per-match runtime gate lives in the save, not in code (finance_constants.md) |
| MAN OF THE MATCH | `Pm98StatStore.pick_mom` = FUN_0044a370, oracle-banked | **REAL** (name + club + mugshot) |

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
  matchday modal (ours stays closed). **Charter #7 APPLIED 2026-07-17: BRIEF feed
  geometry (#7a), LIVE possession from the engine POSS counters (#7b), and the
  frame-073-kit blank + fixture-escudo redraw (#7c) are all done.** The remaining
  feed *richness* (shot/save/cleared lines between the goals) is still the M5
  positional-engine gap — the instant engine produces goals only, never fabricated.
  Roll corner kits = the un-extracted hi-res kit render family.

## Charter #6 APPLIED — 2026-07-17 (RESULT read-out repairs)

The HALF/FULL TIME read-out is repaired against the LIVE witness run
(`matchday_flow_witness_re.md` §5; the pixel-true stills
`screenshots/wine-captures-2026-07-17-matchflow/results_mode_{half,full}time_readout.png`
+ `readout_fulltime_thedell_away_filled.png`):

- **#6a Score-box geometry** (`build_match_flow_chrome` BOX_L/BOX_R/BOX_Y +
  `MatchResultScreen.BOX_L/BOX_R`): the two navy boxes are x266..319 / x320..373,
  y78..113 (frame-measured, identical across all 3 witnessed FT frames). The old
  (246,320)/(339,375) @ y66 over-painted navy up over the name bar + left into the
  band -- the "score-box overdraw" defect. Re-baked; boxes now land x267..318 /
  x321..372 (0px vs witness).
- **#6d STADIUM panel = fixture HOME club's ground, ALWAYS FILLED**
  (`Main._result_stadium`): killed the "honest blank away" rule. Ground NAME +
  CAPACITY are now source-exact for EVERY club (see below); manager-home reuses the
  Career `finance_preview`, an away fixture projects the home OPPONENT's gate from
  its tier + real capacity. The ground-name row is BLACK-on-WHITE (witnessed; was
  drawn white-on-white = invisible). ATTENDANCE/% stay a FinanceModel PROJECTION
  (per-match runtime gate is un-reproducible, finance_constants.md) so they will NOT
  match the witness's runtime-sim numbers; the money/sponsor rows stay an honest gap.
- **Real stadium capacity for all 476 clubs** (EQUIPOS `param_1[6]`, the
  `<10 -> 6000` engine rule from fn_00579c70 L100-101 applied; `equipos_parse` +
  `extract_squads_exact` "capacity" + `build_db`). Verified: 15/15 La Liga
  (teams_laliga "u32 @year-12") + the witnessed English FT read-outs Old Trafford
  55,300 / Villa Park 39,339 / The Dell 15,200. NOT the later `param_1[0x7a]` u32
  (range 400..1500) the RE first mis-labelled capacity.
- **#6e Header phase chip** (`Main._show_match_result`): the read-out barra's green
  plaque is no longer stuck "Preseason"/"Preparation" in season. Friendlies keep that
  default (witnessed 1 Aug); a LEAGUE match reads the division + the week just played
  ("Premier"/"Week 1", 9 Aug) and the date is corrected to that Saturday.
- **#6f HALF TIME read-out is CONTINUE-gated** (`MatchResultScreen._on_input`, both
  modes): the HT read-out is NOT a tap-anywhere dismiss -- it carries a real CONTINUE
  button + the STATISTICS/TACTICS/LINE-UP chrome (baked, inert like the BRIEF doors).
- **Honest gaps kept (never fabricated)**: POSSESSION % (the RESULT read-out's own
  counter, distinct from the now-live BRIEF POSS bar — witness §: 57/43 vs 55/45 same
  match) and TOTAL FOULS -- the instant-result stat engine produces goals only (plus
  the BRIEF possession counters); the positional match-rating stream those need is
  test-only (M5). The pill / header chrome renders; those values stay absent.
  **MAN OF THE MATCH is no longer a gap** (2026-07-24): the selector is the ported,
  oracle-banked FUN_0044a370, so the board names him with his mugshot. A pre-season
  friendly runs the selector too but still folds NOTHING into the season store — the
  live witness pins only the fold-back, not the report.

Verified LIVE-render (GL, `app/tests/shot_readout_verify.gd`): the away-league FT +
HT read-outs match the Dell/Villa witness (score box, filled stadium, in-season chip).
