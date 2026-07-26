# PM98 — PLAN: byte-exact text-match engine (BRIEF + RESULTS true to original)

## Decision (2026-07-01, Mats)
BRIEF + RESULTS must be **byte-exact to PM98**, not PM98-plausible. The 3D/side-on view is
deprioritised (last). Approved path: build an **end-to-end oracle**, kill-test the recovered
`Pm98*` engine's scoreline/events against it, then **wire that engine** as the result source for
`Career` (replacing the calibrated `MatchEngine`/`MatchSim` for the manager's own matches at least).

## Where we are (empirical, this session)
- **Result source today = `MatchEngine`/`MatchSim`** — self-documented as ABSTRACTED: faithful MSVC
  PRNG (`FUN_005ec250`) + per-shot Bernoulli form, but **app-tuned chance volume + constants**,
  validated against *real-football* aggregates (`test_engine.gd`: 2.55 goals/game, 45% home — PASS),
  NOT against PM98 output. This is the invention to retire.
- **Recovered engine `Pm98*`** — per-function bit-exact port: **90 `run_*_oracle.sh` PCode-emu oracles
  + 142 `test_*.gd`**. `Pm98Match.build_match` builds the real match struct (2 keepers, referee, ball,
  2 team headers, 22 players via `_build_player`).
- **`run_full_match.gd` (STEP-5a):** drives `Pm98Match.build_match → kickoff_init → loop
  Pm98Driver.tick()`. Result THIS session: seed=1, 22 players, 3000 ticks, **0 crashes**, phase
  histogram `{2:31, 0:2969}` (reaches open-play phase 0 — was stuck in phase 2 before the 06-23
  vtable-offset fix), **final score 0-0**.
- **Why 0-0 (named by the harness, not guessed):** (a) INPUT is SYNTHETIC — no real squad records, no
  real kickoff placement; (b) the OUTER match loop `FUN_005983f0` (above per-tick `FUN_00598740`) is
  NOT ported; (c) the goal-scoring leaves `setup_shot` (`FUN_005ac1a0`) / `resolve_post_shot` are
  `call_resolve=false` STUBS, so no shot ever converts. No player reaches a shooting/resolve state.

## Milestones (each gated; verify before next; do NOT invent)
1. **M1 — Goal-scoring path live. ✅ DONE (verified 2026-07-01, s9).** The premise was STALE: all 8
   handler sites in `Pm98Action._action_switch` already pass `call_resolve=true` (cascade
   oracle-GREEN, `test_engine_cascade.gd`). Evidence (`app/tests/diag_match_states.gd`, seed 1):
   P8 enters action 0x4 at t12, `setup_shot` writes 13 ball landings t31-44, the kickoff kick moves
   the ball at t31 — non-zero shots ✅. Still 0-0 because the shots are minimum-power touches
   (synthetic attributes, touch/power=min) and the two remaining movement NO-OPs (`_move_9490`;
   `_move_65a0` non-taker open-play slice) freeze all players after t44 — that is M3 territory
   (real input) + the deferred movement ports, NOT a cascade stub.
2. **M2 — Outer match step `FUN_005983f0` ported. ✅ CODE DONE (2026-07-01, s9) — oracle pending.**
   Ported to `app/scripts/Pm98Outer.gd` (+ wait-frame `FUN_00593ab0`; callee classifications in the
   file header, all decompile-verified). CORRECTION to this plan's premise: `FUN_005983f0` is the
   per-FRAME step (667 B), not the 90-minute loop — the career loop `FUN_0044ee70` re-calls it per
   frame; the clock increments INSIDE `FUN_00598740` (already ported, `Pm98Driver.gd` L141), and
   half/full-time is `Pm98Dispatch._case_phase` (dispatch 1 at `+0x450 > thresh`; rung `+0x19a0`:
   0=H1, 1=H2, 2/3=ET at thresh/3; session `+0x44`/`+0x48` = extra-time/aggregate flags, both 0 =
   league match ends at 90'). Exit MET: `run_full_match.gd` seed 1 plays H1 → HT restart (clock
   banked `+0x19a8=7200`) → H2 → **FULL TIME code 10 at frame 16005** (not the cap), deterministic.
   Remaining for M2 CLOSE: the `run_outer_oracle.sh` PCode-emu residue lock (shell branch select,
   score copy `+0x478/+0x798 → +0x19b0/+0x19b4`, `+0x1a1e` arm, return flag).
2b. **Lean `FUN_005a9490` FULLY PORTED + WIRED. ✅ (2026-07-01, s10).** Slice C (post-scan
   shot/clear/ball-control tail, decompile L339-553) ported (`_lean9490_slice_c` /
   `_lean9490_clear_arms` / `_lean9490_offball` in `Pm98Movement.gd`) and oracle-locked from the
   TRUE entry (`run_9490sliceC_oracle.sh` → `test_9490sliceC.gd`, 171 checks: 3 clear arms +
   out-of-window + chase-0xb + low/high take-control anim + own/foreign commentary draws, RNG
   post-state pinned per arm). `_move_9490` stub retired (`lean_9490(p, true, rng)`);
   `run_engine_oracle.sh` regenerated un-stubbed — field-value-identical, `test_engine_tick`
   184 GREEN. **e2e CONSEQUENCE (root-caused, diag_h2_stall.gd):** `run_full_match` now HITS CAP
   at the H2 restart — the restart_handler's per-rung kickoff PLACEMENT callees (`FUN_0044d0d0`
   H1 / `FUN_0044d190` H2 / `FUN_0044d250` / `FUN_0044d310`) are modeled as no-ops, so the
   engaged taker stands ~46 m from the placed ball and the lean's Slice-A dribble-runaway gate
   (dist > 0x10000) correctly RELEASES it → phase 2 forever. Pre-wire FT-at-16005 only worked
   because stale H1 possession (owner/`+0x54` never cleared without the lean) survived the half.
   The lean is source-faithful; the blocker moved into M3's placement item.
2c. **Restart placement PORTED + ball-embedding alias fixed. ✅ (2026-07-02, s11).** The 2b/M3
   premise was WRONG: decompiled, `FUN_0044d0d0`/`d190`/`d250`/`d310` (ECX = session, asm
   0x593d04..) are NOT placement — they bank the finished period into the season record
   (`FUN_0044e440` → `DAT_0066afd0`) and rebuild the session panels (`FUN_0044d5f0`; one
   sim-feedback write, session+0x14 = 0). RNG-clean live (`ScanRngReach.java`, real fn
   boundaries: closure 125/4/52 fns for d0d0-family/5946d0/5946f0, ZERO `FUN_005ec250` sites;
   the highlight replayer `FUN_0044cae0` is human-manager-gated → off). The REAL placement is
   restart_handler's own L96-102 `FUN_005b6ba0 x2` (per-player ctor re-run IN PLACE; write-set
   sentinel-diffed in `specs/playerbuild_writeset.txt` → `_build_player(into=)` in-place rebuild
   + the previously missed ctor write `p[0x2c]=slot`), plus the entity vt+4 decides: BALL
   `FUN_0058e120` (release carrier, vel 0, spot→centre at phase 2, pos=spot, +0x58=-2) and
   KEEPER `FUN_005a2140 x2` (park at goal, pos code 0x42) — both ported into `Pm98Movement`
   and oracle-locked (`run_restartdecide_oracle.sh` → `test_restartdecide.gd`, 122 checks;
   referee `FUN_005b5790` skipped, outcome-irrelevant). ALSO fixed while proving it: the
   ball-EMBEDDING alias (binary: ball object AT match+0x1610, so m+0x1614/18/1c/1630/34/
   1644/1668/16a0-a8 ARE ball fields) — the port's m-keys were dead on the live path; reads
   now route through `Pm98Movement._bm` (ball Dict when present, fixture m-key fallback), and
   `_ball_freeflight`'s held-flag read moved to the writers' byte-key 0x63 convention.
2d. **FUN_005a65a0 FULL open-play port — M65a0 stub RETIRED. ✅ (2026-07-02, s12).**
   `move_dispatch` restructured to the binary's literal top-to-bottom shape: the velocity block
   (L43-109, the `+0x54` wander re-arm — the root gate on organic shots after the lean's engage
   zeroes `+0x54`) now runs for EVERY dispatched player, not just the handled subset. Newly ported:
   the param_2==0 `FUN_005b1420` gate wiring (L129-136; its return now gates the L138 fall-through),
   the active chase-return (L153-204: own-half steer, the SIGNED `< 0x38e` facing quirk, the
   nearest-teammate scan at `[p+0x3a4/2, 0]`, `FUN_005aa490` pass-handoff → `kick_setup` preset,
   `p+0x63` clear), the arm-2 leaves (L206-232: 8f20/b0040 split + active sideline steer +
   `FUN_005aa870(0)` tail), the IF-A anim-end (L394-401, `FRAME_COUNT`/`DAT_00664fb8`), the phase-2
   holder steer (`FUN_005a8bc0`) and the FULL phase-4 free-kick run-up (L260-285,
   `mirror_to_side`). STILL DEFERRED (trace-only): the IF-B same-team set-piece runner (L293-392)
   and b1420's `FUN_005b1500`/`FUN_005b1c80` role sub-leaves (decompiled to `docs/re/move/`; both
   return role-leaf bytes via the `FUN_005b41b0/41c0/4a80/4f70/3d00/3e50/5520/5150` family — their
   own future slice; stubbed ret 1 in port AND every oracle). Oracle:
   `run_65a0openplay_oracle.sh` → `specs/65a0openplay_oracle.txt` → `test_65a0openplay.gd` (REAL
   `FUN_005a65a0`, only b1500/b1c80 stubbed; LCG state pinned per fixture so draw count + order are
   locked). `run_engine_oracle.sh` regenerated with 65a0 + b1420 un-stubbed (LCG poked 0 ==
   `engine_tick`'s default `Pm98Rng.new(0)`).
3. **M3 — Real kickoff placement + real squad input.** Replace synthetic input so the sim runs
   on decoded EQUIPOS attributes, not synthetic. Port the real kickoff-taker
   decision (see `[[handoff-pm98-decide-wiring-active-ptr-2026-06-24]]`, `FUN_005a7260`).
   ~~FIRST: port the restart placement~~ **DONE in 2c** — the e2e unblocker landed there.
   **3a. PROVENANCE RESOLVED (2026-07-06, s13 — `docs/re/session_lineup_re.md`).** The real
   input is NOT the `+0x1a5c` block (that is the PALETTE table, display-only, demoted) and NOT
   "81-dword records" (the per-actor highlight save/restore bank). It is the two **0x7a0 LINEUP
   blocks at `session+0x58/+0x7f8`** (ctor `FUN_00449400`, filler `FUN_0044d5f0`), stored at
   `team+0x9c` by `FUN_005b63e0` — the port's `team[0x9c]`/`session` injections are these exact
   objects. Full rec-field map (shirt/positions/roam box/VE..PO/fitness/posFine+1/role/marking/
   prior-leg events), the 318×198→pitch transform `FUN_0058c300`, venue pitch dims, and the
   7-lever→`team[0xc1..0xc7]` header path are in the RE doc.
   **3b. EXPORTERS + REAL-LINEUP FEEDER SHIPPED (2026-07-07, s14).** Export gaps closed:
   player `+0x16/+0x17` → game_db `b16/b17` (b16∈{1,2,3}, b17∈{1..6}, un-RE'd enums) and the
   stadium pitch-dim u16 pair → `club_tactics.json` `pitch` (engine substitute rule
   `+0x34<0x1e→0x3c` / `+0x36<0x34→0x69` from `fn_00579c70` L112-117; Man Utd 116×76 = the
   real Old Trafford pitch in yards, Barcelona 107×72 — real per-stadium data, kill-tested).
   `+0xf8` was ALREADY exported as `squadNo` since `cc06ef4` (the RE doc's gap list was stale
   on that field). `app/scripts/Pm98LineupFeeder.gd` = the `FUN_0044d5f0` port (bit-exact
   32-bit `FUN_0058c300` transform incl. the u32 mul/div overflow, `FUN_005841e0` STR gate,
   PO/EN/TI adjusts, header x-lines + engine-order levers `[0,1,2,4,5,6,3]`, season-init
   FI 70 / cap 99 per `morale_re.md`). `run_full_match.gd` now runs REAL squads (MU 40 vs
   LIV 42, both eng_prem): seed-1 baseline = **FULL TIME code 10 at frame 15212, minute 90,
   H1 7966 / H2 7246 frames, phases {2:92, 0:14400, 8:720}, 0-0, final rng 276518391** —
   deterministic (2 identical runs). Known edge: posFine-18 XIs (114 clubs, not MU/LIV)
   index the role table past its zeroed 0x24 block — the binary overruns there too.
   **Remaining for M3 CLOSE:** ~~port the kickoff-taker decision~~ **DONE — CORRECTION
   (2026-07-07, s15): the "kickoff-taker decision" framing was STALE.** FUN_005a7260 and
   the 65a0 kickoff-taker slice (aa4d0/aa680) were already ported (s10-s12); the
   kickoff-exit-rootcause handoff (06-24) had falsified "port 7260 to leave phase 2"
   before the plan was written. The REAL 0-0 blocker was s12's deferred item: b1420's
   **FUN_005b1500/FUN_005b1c80 role sub-leaves stubbed ret 1**, which ended FUN_005a65a0
   at L129-136 for every off-ball player — the team never moved in open play, so nobody
   ever re-reached a shooting state after the kickoff kick.
   **3c. OFF-BALL FORMATION MOVEMENT PORTED (2026-07-07, s15).** FUN_005b1500 (opponent-
   possession mover: keeper-hold anchor, mark-follow shadow/press/tackle, the b0040
   receiver handoff, the role-4 FUN_005b4a80 striker press — jump table @0x5b1bf4: role 4
   is the ONLY live leaf, all others ret 0 via the FUN_005b41b0 thunk chains) +
   FUN_005b1c80 (own-possession: the state-6 drop-back-onside, the state-5 goal burst +
   AA870 release, the 2b70 unmark run, the 3060 push-up, the LONG-BALL receiver scan, the
   role-leaf switch @0x5b2ae0 → 41c0/4f70/3d00/3e50/5520/5150) + helpers (3b20 anchor,
   2f30 dart, 3a10 pass-lane, 35c0 cross pick, 4820 run target, 3c90/1c40/1c60). Wired
   through formation_gate_b1420(wire, rng) → 65a0 L138 fall-through live. ALSO fixed the
   latent p+0x188 shape bug (live = the opponent team-ctx Dict, fixtures = a bare Array;
   loose_ball_search/resolve_post_shot/feed handlers read it as Array → first live pass
   would have crashed; now `_roster()`-tolerant). **e2e (seed 1, MU vs LIV): FULL TIME
   code 10 at frame 16384, minute 95 (clock banked 8001+7200), phases {2:104, 0:15201,
   8:1079}, dispatch {6:359, 1:719, 10:1}, final rng 3169177747 — and the score is
   **1-0**: the first ORGANIC GOAL from the recovered engine on real squads,
   deterministic across 2 runs.** Oracle: tools/re/run_b1500family_oracle.sh (REAL
   0x5b1500/0x5b1c80 under PcodeEmu, NO stubs) → specs/b1500family_oracle.txt →
   app/tests/test_b1500family.gd.
4. **M4 — End-to-end ORACLE (the kill-test). ✅ DONE 2026-07-07 via option (b), wine harness.**
   Chose (b). First reference captured: `tools/re/wine/m4_reference_villa_bolton.json` +
   `tools/re/wine/README.md` (full harness + reproduce steps). Drove the real `MANAGER.EXE` under
   wine (repo `.wineprefix`, `wine explorer /desktop=pm98,640x480`) to a WATCH match, attached
   winedbg at the FIRST `0x5983f0` (outer-step) hit after KICK OFF to grab the match base
   (`0x3dcf0b0`) + the frame-0 seed (`0x8abd86a4`) + a full rw-memory snapshot, then free-ran
   `m4_poll.py` (reads scoreline/clock/phase/seed/event-window from `/proc/<lpid>/mem`) while
   `autoresume.py` clicked KICK OFF at each segment/half-time pause. **Reference: Aston Villa
   2-2 Bolton W, goals 21' Yorke / 63' Collymore / 66' Gunnlaugsson / 88' Holdsworth, FULL TIME
   dispatch code 10 @ min 90.** On-screen event feed banked verbatim; internal phase coverage
   {0:6572, 8:1402, 6:204, 1:160, 2:68, 5:57}. Frame-0 match-struct region + timeline saved to
   `~/MWM-AI/data/pm98-m4-oracle/` (outside git). Caveats in the JSON: this is a REFERENCE not yet
   a proven port parity (port runs MU/LIV seed 1, not Villa/Bolton 0x8abd86a4), and cross-drive
   reproducibility needs the seed poked at `0x006d3184` before each run.
   - ~~(a) full PCode-emu~~ / ~~(b) wine harness~~ — (b) won: it worked end-to-end at low cost;
     (a) was not attempted (a full match is millions of insns, step-budget risk in EmulatorHelper).
   Exit MET: an oracle emits a reference (scoreline, per-minute events) for a fixed seed + squads.
5. **M5 — Parity + wire.** Kill-test: `run_full_match.gd` scoreline + event stream == oracle,
   bit-for-bit, across a seed sweep. Then wire `Pm98` engine into `Career.play_round` /
   `MatchScreen` (BRIEF) so BRIEF narrates the engine's real event queue and RESULTS shows the
   engine's scoreline. Retire `MatchSim` from the manager-match path (keep for CPU-league bulk only
   if perf demands, flagged).
   **SWEEP 2026-07-24 (s55):** `tools/re/run_match_sweep.sh 50 5` — after the `+0x43c` resolver
   crash fix (`23307d1`), **50/50 seeds reach FULL TIME on dispatch code 10, 0 failures, 5
   deterministic across two runs.** Scores spread realistically (2-1 the mode, 8/50; range 0-2 to
   3-1). This is robustness + reproducibility only — NOT parity vs MANAGER.EXE.
   **STATUS 2026-07-24 (s55).** Tick-level parity, measured properly, is **clean over clk
   270-660** — all 22 players and the ball, every silicon capture we hold, within one tick of
   sampling phase (`tools/re/m5_seq_posdiff.py`; `docs/re/M5_S55_SAMPLING_PHASE_ARTEFACT.md`).
   The "frontier 643/651" of s49-s54 was a false premise in `m5_clk_posdiff.py`, not physics.
   Nothing beyond clk 660 is measured yet — a full match is 14400 clks and every capture stops
   at 660, so parity from 661 on is unknown in both directions. The end-to-end kill-test
   (`run_match_from_struct.gd`, byte-loaded frame-0, Villa 5-2 Bolton) still diverges early —
   first goal 11' Aston Villa vs the reference's 21' — and then trips
   `Pm98Outer._pause_branch`'s wait-loop guard, so it cannot yet reach FULL TIME. Extending the
   capture window is the gate on everything downstream.
   **Items 2-5 of the collision-builder doc's next-session plan are DONE and were stale in that
   doc:** `FUN_005946f0` phases 0-4 are ported (`Pm98CollBuilder`, `test_collbuilder` 438 checks,
   `test_geomleaf` 93), the post array is wired into the ball collision loop
   (`Pm98Movement` reads `m[0x17f4]`), and the tick driver `FUN_00598740` is ported
   (`Pm98Driver.tick`, `test_driver` 34). What remains of item 5 is the ≥50-match fixed-seed
   kill test, which is blocked on the clk-660 measurement horizon above — not on either function.
   **STATUS 2026-07-26 (s57) — supersedes the s55/s56 wording above.**
   `docs/re/M5_S57_SAMPLING_ANCHOR.md`. Sampled at ONE fixed silicon stop per tick
   (`ret0 0x5910fd`, the `FUN_005910c0` replay-record read) instead of "the last pl-bearing stop
   of that clk", the port is **byte-exact over clk 1-823 at ZERO tolerance**: 22 players × 16
   fields, the ball × 10 fields, its 51-word `FUN_0058fda0` trajectory tail, and the LCG state at
   all 823 tick boundaries — 72,685 words, 0 mismatches (`tools/re/m5_anchor_posdiff.py`).
   The ±TOL phase machinery is retired with it, and s56's `orient17c`/`orient180`/`curve6c`/
   `lock5c`/`guard2d7` forks and its clk-721 ball-possession divergence are all artefacts of the
   moving sample point — **do not chase them**. The one per-tick draw-count difference in the
   window (clk 620, silicon 8 vs port 7) is the net-neutral save/draw/restore triple around the
   headless-gated `FUN_004e7e10` commentary leaf, confirmed live from the restored LCG word.
   **The frontier is now purely a CAPTURE problem.** `+0x450 * 0x2d / +0x19ac` with
   `+0x19ac = 14400` puts clk 823 at match minute 2, so the verified window is 5.7 % of one half.
   The 11'-vs-21' kill-test divergence sits at clk ~3500 vs ~6700 — four times beyond any capture
   we hold — so it cannot be attributed to the engine yet. Extending
   `tools/re/wine/m5_rsp_capture.py` past clk 823 remains the gate on everything downstream.

   **STATUS 2026-07-26 (s58) — the capture was taken.** `docs/re/M5_S58_FRONTIER_1032.md`.
   A fresh drive on its own `Xwayland :5` (`PM98_DESKTOP=pm98cap`, so the owner's desktop is
   never touched) reached **clk 1032** across two runs before the debug stub died (twice) — the game itself survived,
   and the streamed jsonl kept everything. Diffed at the same anchor the port is **byte-exact
   over clk 1-1032**, and across all eight banked captures it is **319,335 words, 0 mismatches,
   zero tolerance**. 202 ticks of previously unchecked ground, nothing moved. clk 1032 = match
   minute 3.2 = 7.2 % of a half. Cost of the next step, measured: ~1 clk/10 s in-window, i.e.
   ~90 min of wall clock per further match minute, and a fresh boot per attempt (a dead stub
   could not be re-attached — `error 5`, twice). `PM98_NO_POKE=1` now exists on the capture
   script for the case where a re-attach DOES succeed.

## BRIEF-specific (mostly done — verify, don't rebuild)
- Commentary TEMPLATES already verbatim from `MANAGER.EXE` (`MatchCommentary.gd`, VAs cited); event
  taxonomy maps 1:1 to the decoded enum. GAP = the event RATES/timing (ours) → fixed by M5 (drive
  from the engine's real event queue). Verify the BRIEF screen layout vs `MatchScreen.gd` RE header.

## Notes / open GAPs feeding this plan
- ~~`docs/re/match_engine_re.md` does not exist~~ **STALE (verified 2026-07-01): it EXISTS (16.2K)**
  — the decoded event enum, phase strings (0x65cc54–0x65ccf0), and the enqueue→dequeue call chain
  are all in it. The s8 handoff claim is retired.
- ~~`matchctx+0x1a5c` provenance unresolved~~ **RESOLVED 2026-07-06 (s13): the per-actor 256-B
  PALETTE table** — align256 view of the `+0x1a54` buffer, blocks 0x000/0x200 team kits+keeper
  palettes (`FUN_005b63e0`, `DatSim\paletas\`), 0x400 referee, 0x500/0x600 keepers. Display-only;
  headless engine keeps `m[0x1a5c]=0`. Real M3 input = the session lineups —
  `docs/re/session_lineup_re.md`.
- Siblings resolved (s8): `+0xaac`/`+0xe74` = the two KEEPERS, `+0x123c` = REFEREE (not "teams").
