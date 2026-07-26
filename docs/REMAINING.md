# PM98 Android — remaining-work inventory (refreshed 2026-07-26)

Mats asked: "I want the game on Android as it was on PC in '98 — what's missing?"
This is the honest, full list. Nothing hidden.

> The 2026-06-20 edition of this file was five weeks stale — it still listed the collision
> builder, the match-tick driver, PKF sprite decompression and the season-end screens as
> open, and all four have since landed. **Per-screen truth is the `Status:` line at the top
> of each `docs/re/<screen>_re.md`, not this file.** This file is the map, they are the
> territory.

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

Where it actually stands, measured 2026-07-26 (`docs/re/M5_S57_SAMPLING_ANCHOR.md`):

* Against the live silicon capture the port is **byte-exact over clk 1-823** — 22 players
  x 16 fields, the ball x 10 fields, its 51-word predicted-trajectory tail, and the LCG
  state at all 823 tick boundaries. 72,685 words, zero mismatches, zero tolerance.
* **clk 823 is match minute 2.** `+0x450` is the open-play tick counter and the minute is
  `+0x450 * 0x2d / +0x19ac` with `+0x19ac = 14400`, so the verified window is the first
  ~2.6 minutes of one reference match — 5.7 % of a half.
* Therefore the frontier is a CAPTURE problem, not an engine problem. Extending
  `tools/re/wine/m5_rsp_capture.py` past clk 823 (~1 clk/10 s in-window, one wine boot per
  attempt, ~1-in-2 clean-XI rate, own display required) is the only thing that can falsify
  the engine further.
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

* **EURO. LEAGUE knockout view** — `MATCHES` with `1ST LEG` / `2ND LEG` / `AGGR.`; the frame
  is in hand (`16_euroleague_qtr_finals.png`), the bracket art is un-decoded. The GROUP view
  shipped 2026-07-26 at 0 px outside the two named residuals.
* **Draw-then-play** — `Cup.play_round` still pairs AND plays in one step; the original
  draws, shows the draw, and plays later. Wants its own session.
* **Per-club ground prices** — only Man Utd's are witnessed (`docs/re/stadium_screen_re.md`).
  The rest cannot be shipped without evidence; do not interpolate them.
* **The kit-outline blit pass** — the engine's un-reversed outline/bevel pass. Tested and
  REJECTED: a 50 % blend with the background (left-edge pixels darken, right-edge lighten to
  128/144 grey, so it is a bevel or shadow sprite, not a blend).
* **MINIBAND dither** — 99 px across the six euro group frames.
* **SAVE GAME** is still a toast + `_career.save()`, not the original save flow
  (`APP_VS_SPEC_AUDIT.md` §B1, verdict STUB).

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
