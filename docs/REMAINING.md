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

## The one-paragraph truth

The **manager game** — career, leagues, transfers, finance, tactics, cups, Europe, youth,
staff, training, contracts, board, screens, scouting, insurance, injuries, honours — is
built, reverse-engineered from `MANAGER.EXE` and its data files, and render-diffed against
real captured frames at 0 differing pixels on screen after screen. What is genuinely
under-built is **the match itself**: the byte-exact engine is not yet the engine the app
plays with, and the animated 2D match view does not exist.

## 1. The byte-exact match engine (M5) — THE critical path

The app plays every match on `MatchSim.simulate` (`Career.gd`, `Cup.gd`), an abstracted
engine self-documented as app-tuned and validated against real-football aggregates, NOT
against PM98 output. The instruction-exact engine (`Pm98Driver` / `Pm98Outer` /
`Pm98Movement` / `Pm98Action` / `Pm98Resolver` / `Pm98CollBuilder`) exists, is oracle-locked
leaf by leaf against a Ghidra PCode emulator, and is **not wired into gameplay**. Swapping
it in is the whole game's fidelity ceiling.

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
  **The bracket is now fully specified and unblocked (2026-07-26).** Re-measured off FIVE
  competitions instead of two — the pageback drive left 14 more bracket frames nobody had
  opened — which corrected three things the doc had wrong (the score ink is `(180,200,220)`,
  not white; the domestic slots sit at their own x positions, they are not the European ones
  minus slot 1; the kit art does NOT already exist). `tools/re/verify_bracket_split.py`
  re-proves what the build needs: **20 panels over 6 frames are byte-identical outside six
  content rects**, the flags blit at **0 px**, and `desktop.png` already covers every
  inter-panel gap. What stays open: a decided `AGGR.` cell (all 17 bracket frames in the repo
  checked, plus the 139-frame pageback drive — none has one), and the eight kit blits, which
  are MINIESC plus the un-reversed outline pass and must be a declared bucket.
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
* **The kit-outline blit pass** — the engine's un-reversed outline/bevel pass. Tested and
  REJECTED: a 50 % blend with the background (left-edge pixels darken, right-edge lighten to
  128/144 grey, so it is a bevel or shadow sprite, not a blend).
  **Attack it on the BRACKET, not the group screen (2026-07-26).** The bracket's 47x59 kit is
  MINIESC — 1373 of 1661 opaque pixels match at `(27, T+11)` — and its residual is **173
  silhouette-edge pixels carrying five known greys** `(144,144,144)` `(128,128,128)`
  `(80,80,80)` `(44,44,44)` `(160,160,164)`, against the group screen's 32. It also settles
  the shape question: the sprite's opaque bbox is **45x57 while the blit is 47x59**, so the
  pass draws a ring one pixel OUTSIDE the silhouette. 115 interior pixels remain unexplained.
* ~~**MINIBAND dither** — 99 px across the six euro group frames.~~ **CLOSED 2026-07-26.**
  Not dither: the flags were decoded with the shared VGA palette instead of `MANAGER.PAL`
  plus the 20 Windows static system colours. Re-exported, **0 px** over all 24 flag cells
  (`euro_league_screen_re.md` §Parity).

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
* **The top-level MINIESC kit bank looks mismapped** (noticed 2026-07-26, not chased).
  `app/art/kits/40.png` renders as two half-shirts and `app/art/kits/1381.png` is a **star**,
  not a kit. `map_crests.py --export` wrote that bank from `DBDAT/MINIESC.PKF`, whose entries
  do decode correctly when rendered directly through `tools/re/pkf_image.py` — so it is the
  export's id mapping or its crop that is wrong, not the archive. Nothing visible is broken
  today: every screen that shows a kit uses the `nano` (24x32) or `ridi` (17x20) banks, which
  are right. It matters the moment the BRACKET lands, because that layout's 47x59 blit is
  MINIESC (§3).

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
* **219 GDScript test suites** under `app/tests/`.
* **Render-diff discipline**: screen after screen is baked from the real captured frames and
  proven at 0 differing pixels by a `tools/re/diff_*_parity.py`. That is the standard every
  new screen has to clear.

## Where the truth lives

| question | file |
|---|---|
| is screen X faithful? | `docs/re/<screen>_re.md` `Status:` line |
| what does the app do that the original does not (and vice versa)? | `docs/re/APP_VS_SPEC_AUDIT.md` |
| what is decoded already? | `docs/re/EXACT_PORT_PLAN.md` §"Already decoded — cite, don't redo" |
| where is the byte-exact engine? | `docs/re/PLAN_byte_exact_match_engine.md` + `docs/re/M5_S57_SAMPLING_ANCHOR.md` |
| which source file proves a claim? | `docs/re/SOURCE_INVENTORY.md`, `docs/re/SPEC_BINDING.md` |
