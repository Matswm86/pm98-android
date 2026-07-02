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
3. **M3 — Real kickoff placement + real squad input.** Replace synthetic input: load the real
   81-dword player records + team data (`matchctx+0x1a5c` block — provenance still a GAP, resolve
   first) so the sim runs on decoded EQUIPOS attributes, not synthetic. Port the real kickoff-taker
   decision (see `[[handoff-pm98-decide-wiring-active-ptr-2026-06-24]]`, `FUN_005a7260`).
   ~~FIRST: port the restart placement~~ **DONE in 2c** — the e2e unblocker landed there.
4. **M4 — End-to-end ORACLE (the kill-test).** Two candidate oracles (pick the cheaper that works):
   - **(a) full PCode-emu** of `FUN_005983f0`'s whole match with all leaves REAL (no stubs), same
     seed + same initial struct, dumping scoreline + the 16-byte event queue. Reuses `PcodeEmu.java`;
     risk = step budget (a full match is millions of insns; may be slow/infeasible in EmulatorHelper).
   - **(b) wine `MANAGER.EXE` harness** — run the real match engine under wine headless with a
     controlled seed, read the scoreline + events from known match-struct addresses. Reuses the
     06-23 wine trace tooling. Risk = driving to a match + the PCF5DAT graphics engine coupling.
   Exit: an oracle emits a reference (scoreline, per-minute events) for a fixed seed + squads.
5. **M5 — Parity + wire.** Kill-test: `run_full_match.gd` scoreline + event stream == oracle,
   bit-for-bit, across a seed sweep. Then wire `Pm98` engine into `Career.play_round` /
   `MatchScreen` (BRIEF) so BRIEF narrates the engine's real event queue and RESULTS shows the
   engine's scoreline. Retire `MatchSim` from the manager-match path (keep for CPU-league bulk only
   if perf demands, flagged).

## BRIEF-specific (mostly done — verify, don't rebuild)
- Commentary TEMPLATES already verbatim from `MANAGER.EXE` (`MatchCommentary.gd`, VAs cited); event
  taxonomy maps 1:1 to the decoded enum. GAP = the event RATES/timing (ours) → fixed by M5 (drive
  from the engine's real event queue). Verify the BRIEF screen layout vs `MatchScreen.gd` RE header.

## Notes / open GAPs feeding this plan
- ~~`docs/re/match_engine_re.md` does not exist~~ **STALE (verified 2026-07-01): it EXISTS (16.2K)**
  — the decoded event enum, phase strings (0x65cc54–0x65ccf0), and the enqueue→dequeue call chain
  are all in it. The s8 handoff claim is retired.
- `matchctx+0x1a5c` (per-actor 256-B data block base) provenance unresolved — embedded object,
  vtable `0x6267b0`, built at `0x5420c5` on an unverified base. Blocks M3 real-input.
- Siblings resolved (s8): `+0xaac`/`+0xe74` = the two KEEPERS, `+0x123c` = REFEREE (not "teams").
