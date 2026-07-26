# PM98 Android — remaining-work inventory (refreshed 2026-07-26)

Mats asked: "I want the game on Android as it was on PC in '98 — what's missing?"
This is the honest, full list. Nothing hidden.

> The 2026-06-20 edition of this file was five weeks stale — it still listed the collision
> builder, the match-tick driver, PKF sprite decompression and the season-end screens as
> open, and all four have since landed. **Per-screen truth is the `Status:` line at the top
> of each `docs/re/<screen>_re.md`, not this file.** This file is the map, they are the
> territory.
>
> The 2026-07-26 rewrite still carried one stale line of its own — "SAVE GAME is still a
> toast". It has not been a toast since 2026-07-18: `Main._menu_action` "save" opens the
> ten-slot `SaveGameDialog`, render-diffed 0 px against witnesses 51/52/53. Removed.
> **The habit that catches these: grep the code for the entry point before repeating a gap.**

## 0. Mats's live QA report, 2026-07-26 evening — fix FIRST, before new screens

Reported from play on the shipped build; every item verified in his hands, none is a
guess. One is already fixed (last bullet); the rest are open and OUTRANK the semifinal /
final build:

* ~~**The SCOUT "EXTRA SEARCH FILTERS" panel is invented graphics**~~ — **REDONE
  2026-07-26 evening**: the panel is now `ours_panel.png`, baked from real frames by
  `tools/re/build_scout_ours_from_frames.py` (the trainers dialog's plate + its six REAL
  HANDLING..SHOOTING button plates + the scout screen's own fields/arrows); the scene
  draws only live text in sampled inks. All six scout witnesses still 0 px.
  See `scout_screen_re.md` §"The OURS panel".
* ~~**Kit blits truncated / outside frames.**~~ — **RE-TUNED 2026-07-26 evening.** The
  wrapped-bank `Rect2(0,0,31,64)` crop is gone everywhere: the shared
  `PMChrome.KIT_SRC` (and its aspect-fit `draw_crest`, feeding EuroSupercup /
  CompResult / CharityShield / LeagueTable) plus the per-screen crops in
  `ChampionshipsScreen`, `ManagersMonthScreen`, `MatchResultScreen`,
  `EndOfSeasonScreen`, `CupDrawScreen` (grid + card), `MenuScreen` (45x57 1:1,
  re-centred in the witnessed 50x65 boxes) and `MatchScreen` (content top-left at the
  witnessed y89 band, fit 42x53) all use the exact-decode figure bbox
  `Rect2(1,3,45,57)`; `MatchSimulador._club_colour` samples the same bbox.
  **`RivalScreen` was a false positive** — it consumes the nano/ bank (never wrapped)
  and is pinned by `diff_entry_parity`'s full-frame 0 px case; untouched. Gates re-run
  green: seasonend-year, cupdraw, supercup (+ scout/knockout unaffected).
  `LineupRollScreen`/`FixturesScreen` draw the whole sheet (no truncation) — left as-is.
* **Preseason is gone in season two** — no friendly setup reachable at the second
  season's start.
* **No contract-renewal message toward season end**, which the original raises.
* **The finance INCOME and EXPENSE screens do nothing** when opened, although both are
  tracked in captures.
* **TEAM TACTICS does not match the tracked original** (`tactics_subscreens_re.md` holds
  the measurements).
* **Neither cheat works in play**: MIXED PLAY (blocked on the un-located club tactic
  byte, §3b) AND the shipped THREE UP FRONT hack — Mats reports no effect ("won't get me
  goals"). ~~THREE UP FRONT~~ — **FIXED 2026-07-26 evening.** The flag/persistence/
  routing were all sound; the TRIGGER side had three port bugs: (1) the default 4-4-2
  never arms it (pick 4-3-3 — 463/476 clubs auto-pick exactly 2 FW on 4-4-2, all 20
  Premier clubs field 3/3 on 4-3-3); (2) `Tactics.repaired()` replaced an injured
  striker with the best ANY-position player (its pool carried no `pos`), silently
  turning 4-3-3 into 4-4-2 — now same-position-first; (3) worst: `_ai_featured_xi`
  fielded "best ten by CA" with no shape, so 16/20 Premier clubs armed the cave AGAINST
  Mats while he never armed it — AI XIs now field position-aware 4-4-2 like the
  original's stored club tactics. Seam-tested end-to-end (`test_three_up_front_seam`:
  live chain arms at 4-3-3, opponent doesn't, ON = the cave's 6 goals, OFF differs on
  the same seed). **NOTE for play: the cheat needs 3 natural forwards in the fielded
  XI — pick 4-3-3 in PREDEF TACTICS.** MIXED PLAY remains blocked (§3b). Also found
  and recorded: the seven TEAM TACTICS levers reach only the legacy engine —
  `MatchSim`'s stat branch never reads `rh`/`ra` (fix belongs to the TEAM TACTICS
  rebuild session).
* ~~Debt alert at week 1 despite millions positive~~ — **FIXED 2026-07-26** (`2201ccf`):
  the at-a-loss trigger followed the week's P&L; it now follows the BANK BALANCE, the
  reading the refrun witnesses support (R16 correction in
  `REFRUN_manutd_1997-98_FINDINGS.md`).

Four more, reported 2026-07-26 evening (second round, same play session):

* **Season-2+ talents render wrong in lineups / squad management** — "they have stars,
  but no position or roles". New intake players must carry the same fields (position,
  posFine role, etc.) and draw exactly like the decoded squad.
* **The cup-draw animation is not the original's** — today the spinning ball plays with
  every pairing already on screen; the original reveals the draw progressively
  (`cupdraw_screen_re.md`).
* **Youth recruitment and training does not work like the original at all** — tracked in
  `youth_re.md`; Mats: implement it in a dedicated session.
* **The Ground screen's stadium image never grows** — the original swaps in a bigger
  stadium picture at each capacity expansion; the art is in the sources
  (`stadium_screen_re.md`).

## The one-paragraph truth

The **manager game** — career, leagues, transfers, finance, tactics, cups, Europe, youth,
staff, training, contracts, board, screens, scouting, insurance, injuries, honours — is
built, reverse-engineered from `MANAGER.EXE` and its data files, and render-diffed against
real captured frames at 0 differing pixels on screen after screen. What is genuinely
under-built is **the match itself**: the byte-exact engine is not yet the engine the app
plays with, and the animated 2D match view does not exist.

## 1. The byte-exact match engine (M5) — THE critical path

The app plays every match on `MatchSim.simulate` (`Career.gd`, `Cup.gd`), which — corrected
2026-07-26, the old wording here understated what has shipped — routes to **`Pm98StatMatch`**,
the byte-exact port of the original's instant-result runner (`FUN_0044ee70` family,
oracle-anchored), whenever both XIs pass `_usable`. Only when an XI is unusable does it fall
back to the abstracted legacy `MatchEngine` (app-tuned constants, validated against
real-football aggregates, NOT against PM98 output) — and that fallback fires ~37 times a
season on European ties because foreign clubs carry no usable XI (S5 below). The
instruction-exact POSITIONAL engine (`Pm98Driver` / `Pm98Outer` / `Pm98Movement` /
`Pm98Action` / `Pm98Resolver` / `Pm98CollBuilder`) exists, is oracle-locked leaf by leaf
against a Ghidra PCode emulator, and is **not wired into gameplay**. Swapping it in is the
whole game's fidelity ceiling.

Where it actually stands, measured 2026-07-26 (`docs/re/M5_S58_FRONTIER_1032.md`):

* Against the live silicon captures the port is **byte-exact over clk 1-1032** — 22 players
  x 16 fields, the ball x 10 fields, its 51-word predicted-trajectory tail, and the LCG
  state at every tick boundary. Across all **eight** banked captures: **319,335 words,
  zero mismatches, zero tolerance.**
* **clk 1032 is match minute 3.** `+0x450` is the open-play tick counter and the minute is
  `+0x450 * 0x2d / +0x19ac` with `+0x19ac = 14400`, so the verified window is the first
  ~3.2 minutes of one reference match — 7.2 % of a half.
* Therefore the frontier is a CAPTURE problem, not an engine problem. Extending
  `tools/re/wine/m5_rsp_capture.py` past clk 1032 is the only thing that can falsify the
  engine further, and it runs at ~1 clk/10 s in-window — roughly **90 minutes of wall
  clock per further minute of match time**, plus a fresh boot per attempt (a dead debug
  stub cannot be re-attached; see the s58 write-up). Reaching the kill-test divergence at
  clk ~3500 is ~7 hours of capture. That is a scheduling decision, not a research one.
* Also open: the `run_match_from_struct.gd` kill-test divergence (first goal 11' vs the
  reference 21', i.e. clk ~3500 vs ~6700 — far beyond any capture, so unattributable
  today); unifying the three `+0x43c` null sentinels (absent / 0 / -1, behaviour-affecting);
  the cross-seed sweep (`PM98_SEED` plumbing landed in s55, unrun).
* Full history: `docs/re/PLAN_byte_exact_match_engine.md`, `docs/re/EXACT_PORT_PLAN.md`
  §"Gaps to close" and §"Already decoded — cite, don't redo", `docs/re/M5_*.md` (s9→s57,
  newest last). **Cite these; do not re-derive.**

## 2. The animated 2D match view + sprite extraction

`docs/re/APP_VS_SPEC_AUDIT.md` §A8: the faithful JUG render is not built and the side-on
WATCH view is an approximation. Specs are in `docs/re/jug_render_spec.md` and
`docs/re/match_view_re.md`. **Deprioritised by Mats's own 2026-07-01 decision** recorded in
`PLAN_byte_exact_match_engine.md`; the results/commentary presentation (`MatchScreen.gd`)
is real and shipped, and PM98 ships two match presentations, so this is the second one.

## 3. The screen / model tail

* **The knockout views** — NO LONGER BLOCKED ON EVIDENCE, still NOT BUILT. The old entry
  said "the frame is in hand"; one frame was, and every tie in it was unplayed, so leg
  scores, aggregates and the winner ink were unwitnessed. A scheduled-probe drive
  (`plans/season_euro_probe.json`) photographed the whole competition rail every second hub
  visit through 1997-98 and caught **five layouts, four never seen before**: compact list,
  kit list, the four-panel bracket, the two-card semifinal view with `FINALIST` plates, and
  the trophy+`WINNER` final. Geometry, column sets and the chrome/content split are measured
  in **`docs/re/knockout_views_re.md`**. One cell remains unwitnessed — a bracket `AGGR.` with a
  decided tie. The other, a filled `WINNER` band, turned out to be **already in the repo**:
  `09_comp_charity.png` carries it, and outside the name bar that band is pixel-identical to
  the European final's empty one. `tools/re/wine/knockoutwatch.py` finds either cell in a
  directory of frames.
  Two seasons were driven and both missed those two cells for a structural reason (the view
  auto-advances the moment the next phase is drawn), so a third season is the wrong move —
  page the phase paginator BACK from Semifinals instead. See `knockout_views_re.md`.
  **The LIST layout is BUILT and 0 px** (2026-07-26): `app/scenes/KnockoutScreen.gd`, baked
  by `tools/re/build_knockout_chrome_from_frames.py`, proven by
  `tools/re/diff_knockout_parity.py` against the European 15-tie frame and the domestic
  16-tie frame, and raised by `Main._show_cup_screen` for any phase of nine ties or more.
  Panel geometry is asserted by `app/tests/test_knockout_layout.gd`.
  **Still to build: the bracket (4 ties), the semifinal cards (2) and the final (1)** —
  all measured in `knockout_views_re.md`; a round that small still falls through to the
  SORTEO card. The `WINNER` band is witnessed.
  **The BRACKET is BUILT and 0 px (2026-07-26, s62).** `KnockoutScreen._draw_bracket`,
  raised by `Main._show_cup_screen` at exactly 4 ties, gated by `diff_knockout_parity.py`
  against both witnesses (euro leg-1-played, F.A. Cup unplayed) at **0 px outside three
  declared buckets** (barra kit; the eight kit columns = MINIESC sprite + the un-reversed
  outline pass; the euro case's career-state rail). Every anchor was solved off the frames
  — see `knockout_views_re.md` §"The bracket, as built". Verified live: `PM98_CUP_SHOT`'s
  real career raises the domestic bracket at its F.A. Cup QTR. What stays open: a decided
  `AGGR.` cell is still unwitnessed (the port applies the leg-1 grammar + the list's
  winner rule, declared as inference), and **the kit list (5-8 ties), semifinal cards (2)
  and final (1) are still not built** — those rounds fall back to the list form (5-8) or
  the SORTEO card (2/1).
* ~~**Draw-then-play**~~ — **CLOSED 2026-07-26.** The separation is witnessed twice in two
  competitions (F.A. Cup R2 played 14 Dec → R3 drawn unplayed 20 Dec → played 10 Jan;
  Coca-Cola R4 played 1 Dec → Qtr Finals drawn unplayed 7 Dec), so the rule needed no
  inventing: the next round is drawn as soon as the previous one resolves and is played at
  its own scheduled week. `Cup.draw_next_round` + `b["pending_draw"]`,
  `app/tests/test_cup_draw_then_play.gd`.
* ~~**Per-club ground prices**~~ — **CLOSED 2026-07-26.** The cost function `FUN_0057ddd0` is
  reversed and every one of the 476 clubs is priced from the binary's own jump tables, keyed
  by the club's stature band (`GroundCost.gd`, 24/24 witnessed prices exact including the
  original's float32 dirt). See `docs/re/stadium_screen_re.md` §"The cost function". What
  remains there is the per-club STARTING grades — `club+0x50`, the preset selector, is not
  yet reversed, so only Man Utd's captured grades are used and nothing is interpolated.
* **The kit-outline blit pass** — the engine's un-reversed outline/bevel pass.
  **Restructured 2026-07-26 (s62)** by classifying every differing pixel of all 16 bracket
  kit cells: it is (1) a flat `(128,128,128)` **drop shadow, 1-2 px, bottom/right of the
  silhouette only** (dest-halving on the white panel — which is why the old "50 % blend"
  test failed: it blended the outline index, but the shadow ignores the sprite entirely),
  (2) a **highlight applied to the sprite's own top/left edge pixels** (192/160,160,164/144
  entries), and (3) ~115 scattered interior single-pixel diffs per cell, unexplained.
  A minority of ring pixels also match palette-snapped half-blends of the NW sprite
  neighbour, so an anti-alias component may coexist at concavities. No 0 px rule yet; the
  bracket's kit columns stay a declared bucket. Full data:
  `knockout_views_re.md` §"The outline pass, narrowed again".
* ~~**MINIBAND dither** — 99 px across the six euro group frames.~~ **CLOSED 2026-07-26.**
  Not dither: the flags were decoded with the shared VGA palette instead of `MANAGER.PAL`
  plus the 20 Windows static system colours. Re-exported, **0 px** over all 24 flag cells
  (`euro_league_screen_re.md` §Parity).

## 3a. Reachability — WIRED 2026-07-26 (s62, same day it was found)

The complete-audit pass (`docs/re/AUDIT_COMPLETE_2026-07-26.md` §1) traced the call graph
and found every knockout/Europe view gameplay-unreachable: `_show_competitions()` had zero
callers and the RESULTS rail was baked, inert chrome. **Fixed the same day**: the rail is
the original's own door (every knockout/Europe frame in the RE corpus was captured by
clicking it), so `ResultsScreen` now hit-tests the eight competition chips and emits
`competition_selected`; `Main._open_rail_competition` routes a chip through the existing
`_open_competition` actions, ignoring chips whose competition the career is not in (as the
original's dimmed chips are); `KnockoutScreen`'s own rail is connected the same way, so
competition-to-competition hops work. Player path: hub → RESULTS → rail chip →
cup / Europe views. The play-off chips stay inert (no play-off view exists — honest gap).
Covered by `test_results_screen`. Still open from the audit: the dead `CupScreen.gd` +
`_show_one_off_final()` and the interim `_show_training()` browse — a cleanup pass.

## 3b. THREE UP FRONT — the one place this port draws a pixel the original does not

SHIPPED 2026-07-26 and listed here so it is never a surprise: the MANAGER_HACK.EXE cheat
(`docs/re/hack_three_forwards.md`) is ported into `Pm98StatMatch` and switched by a row on
the OPTIONS modal. Default OFF, and OFF is bit-identical to stock — the eight banked
oracle fixtures reproduce draw-for-draw with the flag on and no forwards in the XI.
`tools/re/diff_options_parity.py` bounds it: the rest of that modal is still 0 px against
the MANAGER.EXE capture, the row's band overlaps none of the original's controls, and the
original draws nothing underneath it.

**The SECOND and last such site, 2026-07-26: the SCOUT door.** The EXTRA SEARCH FILTERS panel
(§`docs/SPEC_scout_attribute_search.md`) had been shipped and working since 07-25 behind a
bottom bar with no label of any kind — Mats: *"I don't see the new search objects."* The bar
now carries `EXTRA SEARCH FILTERS` / `TAP HERE`. While fixing it the bar turned out to be the
**original's own rollover readout** (three witnesses, now built at 0 px — see
`docs/re/scout_screen_re.md`), so the two uses are split by state: a row held → the original's
readout, nothing held → the label. `tools/re/diff_scout_bar_parity.py` bounds it from the
frames: all ten committed frames of that screen are either a readout or blank, and the two
segments overlap none of the 21 original controls. **No other screen carries invented pixels.**

**Still to do here — the MIXED PLAY variant.** The other half of
`docs/re/hack_three_forwards.md`: make toggling MIXED PLAY the trigger instead of three
forwards. Blocked on locating the club tactic byte — `FUN_0056ea15` (the TEAM TACTICS
modal) is un-disassembled and the setting is not in the stat engine's input set at all.
Plan: memory-diff that byte in a **clone** of the play prefix (`/tmp/pm98-play/
sandbox-prefix`, display `:8`, never the live career) while toggling ATTACKING ↔ MIXED with
synthetic clicks, then re-target the `att3` cave at it. The modal's geometry is measured
now (`tactics_subscreens_re.md`), so the click target is known: MIXED PLAY's X-box (103,229).

## 3c. Model-level divergences from the season audit — OPEN (rescued 2026-07-26)

From `docs/re/AUDIT_season_playthrough_2026-07-25.md` (previously /tmp-only, now in-repo);
verified still open at HEAD `4076800`:

* **S3 — a career is not reproducible at a fixed seed.** 12 `randomize()` sites in
  `Career.gd` (500, 528, 1467, 1988, 2187, 2250, 2388, 2629, 2742, 3292, 4052, 4109).
  Not player-facing (the original also reseeds from `time()`), but the port's own
  acceptance machinery — save/load equivalence, the M5 kill-test, seeded parity claims —
  assumes a seed pins a career, and it does not.
* **S5 — European ties run on the invented legacy engine.** Foreign XIs fail `_usable`
  (`MatchSim.gd:105-110`), ~37 loud `[MATCHSIM_FALLBACK]` warnings per season.
  `test_career.gd` asserts zero fallbacks and passes because it only checks the manager's
  own league. Fix = usable foreign XIs (feed from `game_db` directory records) or a
  stat-engine path that does not need a full XI.
* **S8 — no player ever retires.** No retirement/ageing-intake mechanic exists in
  `app/scripts`; squads age without bound and a multi-season career ages into a dead end.
  Blocked on reversing `FUN_005865b0` / `FUN_005c1df0` / `FUN_00443180`.
* Smaller opens from the same audit + refrun: the running-at-a-loss **sacking threshold**
  (>3 weeks, unmeasured) and the sacking screen; the Coca-Cola Cup home TV fee (pays £0,
  flagged); the weekly-illness (virus/cold) insurance path; the insured-row document icon;
  **O1** board objective is a category (Champion / U.E.F.A. / Mid Table / Avoid Relegation),
  the port shows a position; **O3** the original names every club's manager on START OF
  SEASON; **S7 remainder** — the European field shape (24 clubs / 6 groups / 2 qualifying
  rounds) is not confirmed shipped.

## 4. The SHOOTING appendix

NOT APPROVED and not built. It changes every result in the game, so it needs Mats's
explicit go/no-go before a line of it is written.

## 5. Data completeness

`app/data/game_db.json` carries the decoded database. Still partial:

* English-league squads are sparse (the bio-interleaved record format is not fully cracked).
* ~876 directory-only teams beyond the detailed records (separate format).
* `DAT.PKF` / `DATSIM.PKF` match-sim rating tables are still LZ-packed. Only needed to tune
  the *abstracted* engine toward the original — the byte-exact engine gets these from the
  code path itself, so this is track-A work only.
* ~~**The top-level MINIESC kit bank looks mismapped**~~ — **FIXED 2026-07-26 (s62).**
  The id mapping was fine (1381 is club 9902 "STARS", whose kit sprite IS a star); the
  DECODE was not: `export_kits()` rendered through the Pillow path, which honours the
  stripped DIB header's bogus `bfOffBits`, rotating every 48-wide sprite 21 rows + 16
  columns — exactly `export_art.py`'s own module warning. All 476 re-exported through
  `exact=True` (`pkf_image.dib_indices`). Two corrections to the old note: it was NOT
  invisible (MenuScreen, MatchSimulador and `PMChrome.kit()` consume this bank), and the
  BRACKET now blits it.

## 6. Android packaging / device polish

APKs build in GitHub Actions (`build-android.yml`) and publish to the rolling `latest`
pre-release; **never run `./gradlew` on this box** (8 GB, it OOMs). Remaining: a real-device
pass (touch targets, screen sizes), app icon/splash, and a signed release build.

## What is NOT missing (so the list above reads correctly)

* **Art extracted from the original files**, not drawn: 1915 faces, 1480 kits, 675 screen
  chromes, 387 flags, 62 icons, 13 fonts, 9 match sprites — all under `app/art/`.
  PKF decompression is solved (`tools/re/pkf_unpack.py`, `pkf_image.py`, `export_art.py`,
  `export_faces.py`, plus the per-screen `build_*_chrome_from_frames.py` bakers).
* **Audio extracted from the original files** (`docs/re/audio_re.md`): the DINAMIC0 menu
  theme from `MUSICAS.PKF` (S3M) and eight match SFX from `SFX/AMBIENTE.PKF` (u8 PCM
  @ 11025 Hz), wired through the `AudioManager` autoload. Not shipped: the alt goal roars,
  the "oé" chants, and `SFX/COMENT.PKF` (45 MB of Spanish commentary).
* **The engine RE substrate**: collision-geometry builder (`Pm98CollBuilder`), match-tick
  driver (`Pm98Driver`), the full per-player DECIDE/ADVANCE, relationship matrix, marker
  and role selection, ball advance, the trig LUTs, the event queue and dispatcher — all
  ported and oracle-locked. They are done; they are simply not the engine the app calls.
* **322 GDScript test scripts** under `app/tests/` (225 `test_*`, 42 `diag_*`, 52+ `shot_*`).
  **The first full sweep ran to completion 2026-07-26**: 223 of 225 `test_*` green (11 of
  them print non-standard pass markers — "ALL GREEN", per-check "PASS", "N checks, 0
  FAIL"), the 2 failures both accounted for (`test_decideset` = the +0x43c sentinel gap,
  fixed the same day by `f5ab46c`, green on HEAD; `test_pyramid` = FLAKY, an RNG season
  meeting the sparse-English-squads gap — S3's non-reproducibility makes it
  non-deterministic). `shot_*` all ran; the two `*_tapthrough` harnesses fail their
  boot-raises-TITLE check when a prior career save exists in `user://` (harness-state
  contamination, not an app bug). 3 `diag_*` are rotten as scripts (missing output env /
  old-API calls) — probes, not tests. Remaining caveats: CI still runs no test gate
  (`build-android.yml` only exports the APK) and all 20+ `diff_*_parity.py` gates are
  manual-only.
* **Render-diff discipline**: screen after screen is baked from the real captured frames and
  proven at 0 differing pixels by a `tools/re/diff_*_parity.py`. That is the standard every
  new screen has to clear.

## Where the truth lives

| question | file |
|---|---|
| is screen X faithful? | `docs/re/<screen>_re.md` `Status:` line |
| what does the app do that the original does not (and vice versa)? | `docs/re/APP_VS_SPEC_AUDIT.md` |
| what is decoded already? | `docs/re/EXACT_PORT_PLAN.md` §"Already decoded — cite, don't redo" |
| where is the byte-exact engine? | `docs/re/PLAN_byte_exact_match_engine.md` + `docs/re/M5_S58_FRONTIER_1032.md` (supersedes s57) |
| what did the complete audit find? | `docs/re/AUDIT_COMPLETE_2026-07-26.md` + `docs/re/AUDIT_season_playthrough_2026-07-25.md` |
| which source file proves a claim? | `docs/re/SOURCE_INVENTORY.md`, `docs/re/SPEC_BINDING.md` |
