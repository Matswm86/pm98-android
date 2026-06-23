# PM98 Android — COMPLETE Remaining-Work Inventory (2026-06-20)

Mats asked: "I want the game on Android as it was on PC in '98 — what's missing?"
This is the honest, full list. Nothing hidden. Read top to bottom once.

## The one-paragraph truth
We took the **perfectionist path**: reverse-engineering the original 1998 `MANAGER.EXE`
match engine from compiled x86, instruction by instruction, validated bit-exact against the
real machine code via a Ghidra PCode-emu oracle. That is research-grade work and it is WHY
this is slow. It is also ~90% done. The *manager game* (career, leagues, transfers, finance,
tactics, cups, Europe, youth, staff, training, contracts, board, screens) is extensively
built and unit-tested. What is genuinely under-built is the **animated 2D match view** and
**full sprite/graphics extraction** — the part that makes it *look* like the game you remember.

## The fork that decides "weeks vs months"
There are two different definitions of done. Pick one (or sequence them):

- **A. Playable-faithful (FAST, days-to-weeks).** Ship the manager game on your phone NOW using
  the already-working *plausible* match engine (`MatchEngine.gd` + `SeasonSim.gd`) and the
  procedural PM98-look screens. Add a simple 2D match view. Treat the bit-exact engine as a
  drop-in upgrade later. You get a real, installable, PM98-feeling game soon.
- **B. Bit-exact (SLOW, the current track).** Finish the instruction-exact match engine so the
  on-pitch simulation reproduces the original's scoreline/behaviour exactly, THEN build the view
  and graphics. Highest fidelity, but the long road.

RECOMMENDATION: do **A now** (get it on the phone and playable), keep **B** as the background
upgrade. The two share all the data/UI/manager work; only the match-sim internals differ.

---

## DONE (so it's clear what is NOT missing)
- Manager systems, unit-tested (~78 GDScript tests, all green): career across clubs, living
  league, divisions (Premier+1+2+3), fixtures/tables/promo-releg, cups, European competitions,
  super cups, transfers + market, free agents, loans, contracts, finance (budget/gate/sponsor/
  wages/debt/charity), staff + roles, training, youth, tactics, lineup, squad, stadium works,
  board/manager, save/load (Career.gd), commentary text.
- Data: `game_db.json` (3.1 MB), 5654 players across 281 detailed teams, La Liga + English squads,
  team/country directories, crest codes, easter eggs.
- Graphics so far: 502 badge PNGs; procedural PM98-look screen chrome (`PMChrome.gd`, 640x480,
  matched to real screenshots).
- Audio: a few music modules extracted (`assets/audio/`).
- Build: GitHub Actions `build-android.yml` (APK) + `screenshot.yml`. (Never build gradle locally.)
- Match engine bit-exact RE — ~90% (all oracle-validated, see `docs/re/EXACT_PORT_PLAN.md`):
  Stages 1/1b/2a/2b/2c done; Stage 3 done = trig LUT, scoring predicates, keeper save, event
  queue, dispatcher, the full per-player DECIDE (FUN_005a3400 slices A/B/C1/C2/C3 + else-replay),
  relationship matrix, role/marker selection, ADVANCE (FUN_005a4560), positioning (FUN_005b73a0
  slices A-H), ball ADVANCE (timers + free-flight integration/gravity/bounce/roll), collision
  box leaves, and 11 geometry leaves.

---

## MISSING — the complete list, by area

### 1. Match engine bit-exact — the LAST engine pieces (track B)  [IN PROGRESS]
Detailed sub-state lives in `~/MWM-AI/memory/handoff-pm98-collbuilder-map-geomleaves-2026-06-20.md`
and `docs/re/goal/collision_geometry_builder_re.md`. Summary of what's left:
- **Collision-geometry builder `FUN_005946f0`** (fills the post/collider array `match+0x17f4`):
  - phase 0 (constant-fold) ported + validated BUT must be re-derived from disasm (decompile hides
    ~10 scratch frame slots the lerps read); add a completeness check vs the 271-slot frame dump.
  - phases 1-3 (master geometry, lerp/bilerp/grid) — the hard decode: stdcall arg-recycling, must
    read from disasm with esp tracking (decompile args are wrong). Validate vs the MASTER-quad oracle.
  - phase 4 (post fill) — disasm is clear; validate vs the 62-POST oracle.
  - integrate: call the builder at match-init so `m[0x17f4]` populates; the ball loop already reads it.
  - both emu oracles are banked (`collbuilder_oracle.txt` + `collbuilder_frame.txt`); fast iteration.
- **Match-tick driver `FUN_00598740`** — the top-level assembly that calls DECIDE → ADVANCE →
  positioning → resolution each tick. Call-graph is mapped; the leaf pieces are mostly done.
- **Full-match KILL-TEST** — drive N≥50 fixed-seed matches, assert event-stream + scoreline parity
  vs the original. This is the acceptance gate that says "the engine IS the 1998 engine."
- Deferred (display-only, off the headless scoreline; safe to skip): RGB565 colour leaf, goal-frame
  mesh sweep `FUN_005f3b80`, builder display tail, builder phases 5-6 (entity/net-pair — verified
  not read by the current engine; re-check when the driver lands).
- Estimate: builder + driver + kill-test = a few focused sessions (it's decode effort, not unknowns).

### 2. 2D match VIEW  [BUILT — the FAITHFUL PM98 screen; not a dot-pitch]
CORRECTED 2026-06-23: the real PM98 non-CD match view IS a results/commentary screen, and it is
DONE — `scenes/MatchScreen.gd` (clock + half, both shirts + score, possession bar, minute-by-minute
EVENTS table, REPLAY/CONTINUE/EXIT, blue FONDO9 backdrop), wired into both the exhibition
(`_play_watch_match`) and career (`_open_match`) flows, driven by the live stat engine via
`MatchCommentary.timeline()`→`MatchSim.simulate()`, tested green (`tests/test_match_screen.gd`,
`test_browse_nav.gd`, `test_audio.gd`). The iconic top-down green pitch with moving player dots was
the Actua-engine 3D **highlights**, shipped only on the CD and absent from the game archive — so a
dot-pitch would be a BEYOND-ORIGINAL enhancement, not "as it was in '98". Genuine remaining gaps:
- **Scorer/event fidelity** — **DONE 2026-06-23**: the EVENTS table now names the players the stat
  engine actually picked (`Pm98StatMatch.goal_events` → `MatchSim.simulate`'s `goals` →
  `MatchCommentary`), at the engine's minutes, across exhibition + career; legacy fallback still
  re-rolls when no usable XI. Test `tests/test_engine_scorers.gd` (645 asserts).
- **Scorer-roulette WEIGHT (fine position `+0x18`)** — **DONE 2026-06-23**: decoded to the
  EQUIPOS byte `d[Y-12]`, extracted to `game_db` as `posFine`, and used directly as the
  participant POS_WEIGHT index by the bridge (per-role fallback only for sparse records). Now each
  player's *odds* of being the scorer match the original (central strikers heaviest, keepers zero),
  not just per-broad-role. Decode in `docs/re/positions_re.md`; test `tests/test_posfine.gd`.
- **(Optional, beyond-original)** an animated top-down dot/sprite pitch, IF wanted as an addition.

### 3. Graphics / asset extraction  [PARTIAL — badges only]
Roadmap Phase 0 still open:
- **PKF sprite decompression** — the algorithm that unpacks player sprites, faces, pitch tiles,
  kits, stadiums, UI art. Only badges are out so far. This is the single biggest visual unlock.
- **Palette files** (`paletas/*.dat`) → RGB palettes (needed to colour the RGB565/indexed sprites).
- **Image export** to PNG: faces, kits, stadium backdrops, flags, full badge set.
- Without these the game can look PM98-ish (procedural chrome) but not pixel-original.

### 4. Data completeness  [PARTIAL]
- English-league squads are sparse (bio-interleaved record format not fully cracked).
- ~876 directory-only teams beyond the 476 detailed records (separate format).
- `DAT.PKF`/`DATSIM.PKF` match-sim rating tables still LZ-packed (only needed to fully tune the
  *plausible* engine toward the original; the bit-exact engine gets this from the code path itself).

### 5. Audio  [MINIMAL]
- Menu/match music (`.s3m` modules) — a few extracted; wire the rest.
- Match SFX (crowd, whistle, kick) and any sampled commentary — RAW SFX export not done.

### 6. UI / screens  [MOSTLY DONE, gaps to confirm]
- Management screens are built with PM98-look chrome and tested. Remaining: confirm every original
  screen is reachable from a coherent navigation flow on a phone (office hub → all sub-screens →
  match day → results → continue), and the match-day flow ties the view (item 2) in.

### 7. Save/load + season lifecycle  [BASIC EXISTS, harden]
- `Career.gd` has save/load; verify a full multi-season career round-trips (transfers, finances,
  youth growth, board state) and survives app restart on Android.

### 8. Android packaging / device polish  [PIPELINE EXISTS]
- APK builds via CI. Remaining: real-device pass (touch targets, screen sizes, performance of the
  match view), app icon/splash, and a signed release build for your phone.

---

## Suggested order if you want it on your phone soonest (track A first)
1. Build the 2D match VIEW on top of the *plausible* engine (item 2) — makes it feel like a game.
2. PKF sprite + palette extraction (item 3) — swaps procedural art for original pixels.
3. Ship a signed APK to your phone; play full seasons.
4. In parallel/after: finish the bit-exact engine (item 1) and swap it in under the same view.
5. Fill data gaps (item 4), audio (item 5), polish (items 6-8).

(Track B continuation detail = the collision-builder handoff; the rest of the engine RE status =
`docs/re/EXACT_PORT_PLAN.md`.)
