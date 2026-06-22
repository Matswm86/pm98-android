# PM98 — EXACT match-engine + tactics port plan

Goal: replace the **calibrated** model in `app/scripts/MatchEngine.gd` and the **ours**
att/def lever model in `app/scripts/Tactics.gd` with FAITHFUL ports of the real
`MANAGER.EXE` positional simulation + its tactics coupling, validated bit-for-bit.
Read `match_engine_re.md` first (the decoded ground truth). This doc is the work plan.

Legit RE of the owner's own binary for the owner's own remake. Deliverable = original
GDScript reproducing the decoded algorithm, not redistribution of the binary.

## STATUS (2026-06-18)
- **Stage 3 task 2 item 3b-players — ROSTER BUILD FUN_005b6ba0 + FUN_005a2830 PORTED -> Pm98Match._build_team/_build_player (2026-06-22).**
  `kickoff_init` now runs the 11-player build per team when a lineup is injected at team[0x9c]
  (career/save data, injected like `session`; the e2e oracle can dump it straight from a live match).
  **`_build_team` (FUN_005b6ba0):** squad-header copy team[0xbf..0xc7], the formation-slot active table
  team[0x4f..], the keeper/marker role table team[0x5b..] (present iff record[0x44]!=0 == the binary's
  slot+0x70 flag), and the role-5/6 captain pick (max fatigued ability +0x39c -> +0x2d6=1).
  **`_build_player` (FUN_005a2830, sim subset):** header back-pointers (+0x61/+0x62/+0x63), team/slot/array
  index, shirt, role +0x2c8 (GK->1 / demarcacion 1->2 adjust), start positions, and the full 0xde..0xe8
  derived stat block (GK branches, the e3 match-mode branch, the match-clock fatigue scale, 0xea/0xeb/
  0x1c/0x1e). Player Dict is BYTE-keyed (word index i -> byte key i*4). DEFERRED (none read downstream):
  display strings/glyphs/sprite-masks + the 0xe1 ftol() field (FPU operand lost in this decompile).
  **RNG VERIFIED (the load-bearing gate, now closed): the whole FUN_005b6ba0 -> FUN_005a2830 closure
  (462/455 fns) NEVER reaches the draw FUN_005ec250** -- static call-graph over the full objdump, 0 of
  552 indirect-call sites RNG-bound. So the build draws 0 and kickoff's 4-draw seed inventory is invariant
  to whether the roster is empty or full (asserted: rng state unchanged + kickoff-with-roster draws exactly 4).
  `app/tests/test_player_build.gd` (67 ck, hand-computed oracle independent of the port) PASS; full sweep
  **86/86** + boot **0 SCRIPT ERROR**. NEXT: 3c reconcile Pm98Movement opponent-descriptor model; 4 e2e
  oracle dump of a real lineup -> validate the derived stat block + scoreline; 5 N>=50 fixed-seed kill-test.
- **Stage 3 task 2 — MATCH KICKOFF / PHASE-INIT FUN_00593600 PORTED -> Pm98Match.kickoff_init (2026-06-22).**
  `Pm98Match.kickoff_init(m, session, rng)` ports the kickoff/phase-init the asset loader FUN_005923f0
  runs last: goal geometry (+0x1820/+0x1824 from session+0x4c/+0x50), the pitch box (+0x1828..+0x183c),
  the free-kick spot tables, phase=2, the kickoff side + 3 commentary timers, arms +0x1a1e, +0x180e=1,
  +0x454=0. **Draws the match seed EXACTLY 4x on the empty skeleton** (FUN_005b6ba0/005b6ee0/00593a30/
  005f57xx draw 0 -- verified from disasm). Banked tables: DAT_00664060 pitch-type [0x1c20,0x3840,0x5460,
  0x8ca0], DAT_00664070 restart->phase [0,2,3,6,4,5,2,7] (wired into Pm98Driver._restart_phase -- was a
  stub identity; 3->6 / 6->2 differ; test_driver case-A updated). `app/tests/test_kickoff_init.gd` (61 ck)
  PASS; full sweep **85/85** + boot **0 SCRIPT ERROR**.
  **CORRECTION:** FUN_005923f0 is the match ASSET/DISPLAY loader (palettes / hierba grass / hier* textures
  / coreloj FLC / Modelos+PARADOS models), NOT the player loader; FUN_00591ba0 is the match DESTRUCTOR.
  The real 22-player loader is FUN_00593600 -> FUN_005b6ba0 (per-team, 11 players, stride 0x3bc, squad
  source team+0x9c) -> FUN_005a2830 (per-player) -- team+0x9c is set by the match-start caller 0x44f1xx
  from the career/save subsystem (outside the sim corpus). NEXT: 3b-players (port FUN_005b6ba0 +
  FUN_005a2830, verify FUN_005a2830 seed draws) OR oracle-dump the kickoff roster; 3c reconcile movement.
- **Stage 3 task 2 — MATCH-INIT CTOR FUN_00591180 PORTED -> Pm98Match.gd (2026-06-22).**
  `Pm98Match.build_match(rng) -> m` ports the match-object constructor (operator new(0x5fb8) +
  FUN_00591180): the base subobject (FUN_005c52b0 @ match+0), two team headers (FUN_005b6360 @
  +0x46c/+0x78c), two keepers (idx 1/2 @ +0xaac/+0xe74) + referee (+0x123c) via FUN_005a2640, the
  ball (FUN_0058e050 @ +0x1610), the auxiliary sub-objects, the sentinel bboxes (base +0x3fc.. and
  positioning +0x1828..), and every scalar zero. TRANSCRIPTION-validated against the decompile +
  the **objdump this-pointer offsets** (esi=match; every sub-ctor `lea ecx,[esi+off]` confirmed);
  sub-ctors 0x5b6360/0x5917f0/0x591560/0x591830 freshly decompiled. **Builds an EMPTY-ROSTER
  skeleton** (team[0]=0 player-base, team[1]=0 count -- the 22 players load in the populate
  FUN_005923f0). **LOAD-BEARING: FUN_005baca0 @ +0x2bac draws the match seed exactly 1080x at
  construction** (360x3 noise table, value=roll*32); build_match reproduces them; the test asserts
  the rng advances by exactly 1080. `app/tests/test_match_init.gd` (130 checks) PASS. No regression
  (full sweep **84/84** + boot **0 SCRIPT ERROR**). NEXT (renumbered in MATCH_TICK_DRIVER_MAP.md):
  3b = populate FUN_005923f0 (players/goal-dims/session), 3c = reconcile Pm98Movement's opponent-
  descriptor model (match+0x46c/+0x78c header-vs-players) so the movement core runs on the skeleton.
- **Stage 3 task 2 — DRIVER SHELL FUN_00598740 + FUN_00593b70 PORTED -> Pm98Driver.gd (2026-06-22).**
  The per-tick match driver (`Pm98Driver.tick(m, rng) -> 1/0`) and its restart handler
  (`Pm98Driver.restart_handler`) -- the integration shell wiring every DONE piece (predicates, dispatcher,
  events, the movement cluster) in the binary's exact per-tick order. **TRANSCRIPTION-validated against the
  decompile/disasm, NOT end-to-end-oracle-validated** (blocked by the two open STEP-2 gaps: no 22-player
  match-init FUN_00591180, no full-match oracle). Disasm correction banked: `FUN_0058f100` returns AL =
  ball+0x63 (armed flag), not void -- the driver branches on it. `app/tests/test_driver.gd` (34 checks) locks
  the match-over return, the +0x1a1e skip gate -> restart_handler + its lone seed draw, the set-piece
  early-return + +0x1a20 latch, FUN_00593a30 flag clear, the open-play DISPATCH CODES (read from
  match+0x1a38: dead_ball->3 / post_bar->4 / build-up->1 / restart-placement->5/7 / goal-area->6), the
  COMPLETE per-tick RNG-draw inventory (+0x19e4=3, +0x19e8=1/3, +0x19ec=1 commentary timers + the L465
  goal-area discard draw, measured by replaying a reference Pm98Rng), and the FUN_00594570 dequeue. The
  movement core + player-pointer field writes are wired BEST-EFFORT (no-op without match-init, via `_ref`).
  Full map + caveats in docs/re/MATCH_TICK_DRIVER_MAP.md ("DRIVER SHELL PORTED"). No regression (driver 34 +
  full sweep 83/83 + boot 0 SCRIPT ERROR). NEXT = match-init FUN_00591180, then the e2e oracle + kill-test.
- **Stage 1 (oracle) DONE.** Ghidra PCode emulation harness `tools/re/ghidra_scripts/PcodeEmu.java`
  (reusable: spec-driven register/memory/stack setup, cdecl/thiscall/fastcall call, EAX +
  memory + step-level trace capture, callee stubs). Proven on the RNG `FUN_005ec250`: seeded
  srand(1), reproduced 41,18467,6334,26500,19169 bit-for-bit (independent confirmation of the
  MSVC LCG bytes). Spec `tools/re/specs/rng.spec`.
- **Stage 1b (1-fn gate parity) DONE.** The harness drove the REAL resolver `FUN_005aeda0`
  end-to-end (entry -> guards -> geometry sub-calls 005b1230/005a1700 -> finishing gate ->
  RNG -> clean RET, 373 steps) on a constructed player/target/match fixture
  (`tools/re/specs/resolver_gate.tmpl`, sweep `tools/re/run_gate_oracle.sh`). Read the gate's
  own per-mil + threshold out of the CPU registers across an ATTR sweep
  (`tools/re/specs/gate_oracle_table.txt`). The finishing gate is now disasm-verified AND
  emulator-verified: threshold = `9*(ATTR<55 ? ATTR/3 : ATTR-25)` (sub-55 STEPPED, kink
  54->162 then 55->270; `imul 0x55555556`=div3, lea x5x5x5/shl3=*1000, lea[edi+edi*8]=*9,
  sar 0xf=>>15). Ported EXACT to `app/scripts/Pm98Resolver.gd`; locked by
  `app/tests/test_resolver_gate.gd` (ALL PASS, oracle-backed). MatchEngine.gd unchanged (still
  calibrated; the exact engine swaps in at stage S7).
- **Stage 2a (LUT blocker RESOLVED) DONE.** The trig-LUT blocker is settled empirically: the
  resolver's RNG draw stream + final RNG state are **INVARIANT to the sin/cos LUT** `DAT_006d31c8`.
  The PCode emu drove `FUN_005aeda0` into the MAIN goal/save/miss tree (target play-state 5 ->
  skips the finishing block, enters the tree), once with a zero LUT and once with a reconstructed
  cos table (`LUT[k]=round(65536*cos(2*pi*k/4096))`, the exact form `FUN_005ee0f0` indexes): the
  draw stream (41,18467,...) and final state (1030492215) are bit-identical. The LUT only changes
  ball COORDINATES + the projection count (proj 2->3, the line-514 fallback fires under a real
  table); the position-based fallback distance gates keep the RNG-consuming decisions
  geometry-independent. So the decision tree ports faithfully WITHOUT the LUT; real sin/cos
  coordinates are deferred to **Stage 3 (movement)**, where the LUT initializer must be decoded.
  Findings: `FUN_005ee0f0`/`005ee670` read the sin/cos LUT `0x6d31c8`; `FUN_005ee080` reads a
  SEPARATE arctan LUT `0x6d71c8` (the handoff conflated them) and is OFF this path (0 hits).
  Reproduce: `tools/re/check_lut_invariance.sh` (PASS, 32s, 2 emu runs).
  Branch-covering ground truth banked: `tools/re/run_tree_oracle.sh` ->
  `tools/re/specs/tree_oracle_streams.txt` (6 fixtures, 6-11 draws, distinct outcomes:
  nrng + final state + match+0x461 bits + stats + target play-state, all clean RET).
- **Stage 2b (resolution tree ported) DONE.** `FUN_005aeda0` lines 120-485 (the goal/save/miss
  decision tree, play-states 3-8) ported to `Pm98Resolver.resolve_tree` -- branch logic + flags
  bVar5/6/7/8 (on-target/header/off-target/saved), the permil/`_prob_scale` idioms (incl. the
  overflow-safe >>8->>7 split), the target-state set (6/7), the match+0x461 outcome bits, and the
  engaged deflection/corner enqueue (0x13/0x14). Geometry firstgate (LUT) skipped: the LUT-free
  position fallback governs (proven invariant). Locked by `app/tests/test_resolver_tree.gd`:
  24/24 assertions PASS across the 6 branch-covering fixtures -- draw count + final RNG state +
  match+0x461 bits + target play-state all bit-exact vs the oracle. No regression
  (test_resolver_gate + test_engine still PASS; app boots clean).
- **Stage 2c (goal/save block oracle-validated) DONE.** The bVar5-true resolved-outcome block
  (resolver lines 391-464) is now exercised by the oracle, closing the "structurally ported, not
  oracle-exercised" gap. `FUN_0058fb50` (ball-in-goal-box) + its sign-bucket bit0 gate (lines
  397-424) ported EXACT to `Pm98Resolver._goal_box`/`_sign_bucket`/`_goal_box_hit`, replacing the
  `bvar17=0` stub. Two bVar5-true fixtures added to `run_tree_oracle.sh` (skill 0x64): `hi_face`
  (a save -> bit2 + stats +0x9c/+0xa0, exercises the M+0x19ac-div-guarded `FUN_0044ec00` path) and
  `hi_angle` (an on-target miss -> bit0 ONLY, the direct kill-test for the goal-box port: the old
  stub gives bits=8, the oracle says 9). Template now pokes `M+0x19ac != 0` (else div0->HALT in the
  goal/save stat update, lines 437/445) + `P+0x2b8 -> &team arena` (the `FUN_0044ea40/ec00` base
  ptr). The suppress-save block is now faithful to the C `(bVar7=false, bVar8)` comma-expr.
  `test_resolver_tree.gd`: 56/56 PASS across 8 fixtures (draws + final state + bits + target-state +
  stats g/o/a). The 6 bvar5=false fixtures reproduce byte-identical -> template additions don't
  perturb them. No regression (gate + engine PASS; app boots clean, 0 SCRIPT ERROR).
  NOTE: the bVar8 (goal) stat path -- stats +0x98, bit1, `FUN_0044ea40` -- is the structural MIRROR
  of the validated bVar7 save path but is NOT independently oracle-pinned: with srand(1) in the
  isolated origin-coord tree, the draw alignment yields saves/misses, never a goal (provably:
  branch A needs thr<=350 AND thr>895 simultaneously). It validates end-to-end at Stage 3 when real
  matches score goals.
- **Stage 3 task 1 (trig-LUT initializer DECODED + PORTED + oracle-validated) DONE.** The boot
  initializer is `FUN_005edff0` (disasm 0x5edff0..0x5ee073), called once from the match-subsystem
  init `0x5c36e0` (guard flag `0x674ea4`). It fills TWO tables: the cos LUT `@0x6d31c8` (4096 int32,
  `COS[k]=ftol(cos(k*C1)*C2)`, k=0..4095, written DOWNWARD from k=4095) and the SEPARATE arctan LUT
  `@0x6d71c8` (8193 int16, `ATAN[j]=ftol(atan(8j*C3)*C4)`, j=0..8192). Constants are the EXACT
  8-byte .rdata doubles 0x63a040/48/50/58: C1=2pi/4096 (=0.0015339807878856446, NOT the naive
  `TAU/4096` which is ~10 ULP off), C2=65536.0, C3=1/65536, C4=0x4000/(pi/2). `ftol` is the MSVC
  float->long cast (`jmp *0x6233a4`) = TRUNCATION toward zero, NOT round-half (corrects the prior
  session's round() guess; it only happened to agree). Angle unit = 0x10000 = full circle (cos table
  indexed by angle>>4). **Bit-exactness proven** (`tools/re/lut_oracle.c`): the binary's real x87
  `fcos`/`fpatan` under PC=64 AND PC=53 both equal 64-bit-double `cos`/`atan2` truncation for ALL
  4096+8193 entries (0 differ) -- so GDScript's `int(cos()*65536)` reproduces it exactly. Ported to
  `app/scripts/Pm98Trig.gd` (LUT build via `_static_init` + the reader cluster: `mul16`/`muladd16`/
  `ratio16` fixed-point, `cos_a`/`sin_a`, `polar_vec` FUN_005ee0f0, `rotate_vec` FUN_005ee670,
  `atan_angle` FUN_005ee080, `scale_vec3` FUN_005ee170). GDScript pitfalls handled: `>>` rejects
  negative operands and `/` truncates-toward-zero, but x86 `sar`/`shrd` FLOOR -- so an `_asr`
  floor-shift helper backs every fixed-point `>>`. Locked by `app/tests/test_trig_lut.gd` (30 checks:
  every LUT entry vs banked `tools/re/specs/{cos,atan}_lut.txt` + checksums + structural invariants +
  reader vectors). No regression (tree/gate/engine PASS; app boots clean, 0 SCRIPT ERROR).
- **Stage 3 task 3 (4 of 4 scoring predicates PORTED + oracle-validated) DONE.** `FUN_0058f140`
  (keeper-reach save) is the 4th and last: expanded keeper-box test + goal-mouth reach logic ->
  `bvar12`, the ball+0x61 reach LATCH (bit0 set in-reach; save survives only on the out-of-reach edge
  while latched), the keeper-reach geometry (two `atan_angle` calls keeper->goal-line vs keeper->ball,
  `abs(s16(a2-a1)) < 0x3555` AND `abs(keeper+0x3a4 + keeper.x) < 0x370000`), and the deflect-write
  (clamp ball into the RAW goal box -> +0x90/+0x94, +0x98=0, then `+0x94 += sign*0x6666`). Ported as
  `Pm98Predicates.keeper_save(b,m,k) -> {ret, save}`. The keeper's match-context (keeper+0x18c) is the
  same match in play, so kmatch reads use `m`; `keeper+0x34` cancels (k34-k34). The save-stat bump +
  0x15/0x16 commentary enqueue (`FUN_005909f0` -> `FUN_00594470`, the match event queue) is deferred to
  driver task 2 -- `keeper_save` returns `save`, the EXACT gate, oracle-validated. Oracle
  `tools/re/run_keeper_oracle.sh` (LUT injected via `emit_lut_membts.py`; match+0x462=0 isolates the
  save counter at keeper+0x3b8+0x80 from the event queue) -> `specs/keeper_oracle.txt` (7 fixtures incl.
  one that FIRES the save + a negative-clamp). Locked by `test_predicates.gd` (now 147 checks; +49 keeper
  checks: ret + 0x61 latch + keeper-clear + deflect vec + save-fired, all bit-exact). No regression (trig
  30 + tree 56 + gate + engine PASS; boots 0 SCRIPT ERROR).
- **Stage 3 task 3 (first 3 of 4 scoring predicates) DONE earlier.** `FUN_0058ede0`
  (goal-area test + match+0x462 height-band bits + z/y clamp-and-reflect with 0x9eb8 velocity damping),
  `FUN_0058f100` (target-trajectory copy to +0x90/+0x94/+0x98), and `FUN_0058fbe0` (post/bar collision:
  clamp + reflect+damp) ported to `app/scripts/Pm98Predicates.gd`. Validated DIRECTLY as standalone
  functions: the predicates are pure functions of (ball, match) state, so the PCode emu drives the REAL
  binary on constructed ball+match fixtures (NOT origin coords -- arbitrary positions/velocities) and
  captures the mutated state. Helpers folded: `FUN_005ee1c0` velocity-damp (= mul16 each component),
  sound `FUN_00590f00` (skipped via match+0x180a=0), keeper stat `FUN_005909f0` (no-op via ball+0x50=0).
  Oracle `tools/re/run_predicate_oracle.sh` -> `specs/predicate_oracle.txt` (10 fixtures); locked by
  `app/tests/test_predicates.gd` (98 checks: ret + b462 + ball y/z + vx/vy/vz + deflection vec, all
  bit-exact). GDScript pitfall confirmed: `0x37333`=226099 (not 225587). Fixed `PcodeEmu.hexVal` to
  accept negative hex (`-0x...`) + added a stale-`.out` guard to the runner. No regression (trig 30 +
  tree 56 + gate + engine PASS; boots 0 SCRIPT ERROR).
- **Stage 3 task 2 — event-queue layer PORTED + oracle-validated DONE (first task-2 slice).**
  `FUN_00594470` (enqueue, `__thiscall` this=match) + `FUN_005909f0` (keeper_event, `__thiscall`
  this=ball) ported to `app/scripts/Pm98Events.gd`. enqueue appends a 16-byte record
  `[code, player+0x2b8, player+0x2c0, 0x168]` at `match+0x1a24`, bumps the count `match+0x1a28`, sets
  the `0x1a30` timer to 300 on flag==1, and updates `match+0x1a2c = max(., flag)` UNLESS the match phase
  (`match+0x468 -> +0xfa0` read by `FUN_005943d0`/`b0`) is 0 or 4 AND code==1 AND flag==1; no-op when
  `match+0x1a38!=0` (queue frozen). keeper_event bumps the keeper save stat (`*(keeper+0x3b8)+0x80` for a
  save / `+0x7c` for conceded) then enqueues `0x16` (band `0x40`) or `0x15` (band `0xa0`) for the keeper.
  **This CLOSES the deferred `keeper_save.save` -> enqueue wire**: the binary's `FUN_0058f140` calls
  `FUN_005909f0(this=ball, save_flag=0)` at 58f30b BEFORE it zeroes ball+0x50 at 58f314; the now-ported
  pieces compose in that order (test_events.gd integration check). Decoded from objdump (the C decompile
  hides the thiscall ecx): enqueue's this=match is loaded in keeper_event at 590a24 from ball+0x1d4.
  Oracle `tools/re/run_event_oracle.sh` drives both fns through the REAL binary; the queue grower
  `FUN_005bbf10` (Win32 `GlobalReAlloc`) is STUBBED (`stub 0x5bbf10 0 0`) with the event buffer
  pre-allocated at 0x260000 -> first event lands at buf exactly. No LUT needed (neither fn reads trig).
  Banked `specs/event_oracle.txt` (11 fixtures: 6 enqueue + 5 keeper_event). Locked by
  `app/tests/test_events.gd` (85 checks: count + event record + 0x1a2c/0x1a30 + stat counters + the
  composition wire, all bit-exact). No regression (predicates 147 + tree 56 + trig 30 + gate + engine
  PASS; boots 0 SCRIPT ERROR).
- **Stage 3 task 2 — dispatcher PORTED + oracle-validated DONE (second task-2 slice).**
  `FUN_005966d0` (__thiscall this=match, outcome 1-7) ported to `app/scripts/Pm98Dispatch.gd`
  (`dispatch` + the case-1 aggregate `_agg_decision` = `FUN_00450e60`). It turns a resolver outcome
  into the events it appends via the already-locked `Pm98Events.enqueue`: case 1 phase markers
  (0x1c-0x20, may rewrite the outcome to 10 = replay/penalties), case 2 build-up + case 3 restart
  (empty type-0 events), case 4 corner (0xc), case 5 foul/card/offside (1/3/4/5/0xb), case 6 GOAL/own
  goal (7/8), case 7 penalty conceded (9) + card. The whole on-screen-commentary layer is stubbed:
  every `FUN_004e*` is guarded by `match+0x180b` (=0 headless) so it never runs, and the
  `FUN_005ec240/230` brackets around it are an RNG save/restore that then net-zeros the seed (dropped).
  The ONLY load-bearing draws are the two conditional `FUN_005ec250` -- case 2 (geometry-gated: the ball-
  speed projection via `Pm98Trig.muladd16`/`cos_a`/`sin_a`/`atan_angle` > 0 AND match+0x165c) and case 6
  (genuine normal-time goal with match+0x462 bit2 clear AND match+0x461 bit5 set) -- both replicated,
  consuming exactly one `MatchEngine.Pm98Rng` draw. `_agg_decision` (the 2-leg aggregate / away-goals /
  ET decision read in case 1 sub-cases 1,3) is a faithful port of `FUN_00450e60` + its 4 goal-log
  counters (`FUN_00450d60/db0/e00/e30`). Oracle `tools/re/run_dispatch_oracle.sh` drives the REAL
  `FUN_005966d0` (FUN_005bbf10 realloc + the `call ebp` lstrcpyA @ *0x623054=0x251092 both STUBBED, event
  buffer pre-set, cos/atan LUT injected for case 2, RNG seeded to 1) AND `FUN_00450e60` directly ->
  `specs/dispatch_oracle.txt` (25 dispatcher fixtures across all 7 cases + the 0x440 prepend + the busy
  guard, + 4 aggregate fixtures). Locked by `app/tests/test_dispatch.gd` (366 checks: count + every event
  record + the rng-state draw parity + display/bookkeeping fields + freeze/phase-lock + 0x1a2c, all
  bit-exact). No regression (events 85 + predicates 147 + tree 56 + trig 30 + gate + engine PASS; boots 0
  SCRIPT ERROR). NOTE: case-1 `_team_reset` (`FUN_005946d0` -> `FUN_005b7080` x2 over the undecompiled
  per-player reset `FUN_005a32c0`) is a VERIFIED no-op only when team+4==0 (the loop count), which is how
  the case-1 fixtures pin it; the deeper `_agg_decision` branches (the +0x28 path + the iVar2==iVar4 tail)
  are faithful ports not yet oracle-exercised (the 4 fixtures pin the leaf-cmp + 2-leg branches -> 0/1/2).
- **Stage 3 task 2 — movement first slice (nearest-to-ball selector) PORTED + oracle-validated DONE.**
  `FUN_005b8ce0` (__thiscall this=sim-context, char find_in_front) ported to `app/scripts/Pm98Movement.gd`
  (`select_nearest`): pick the eligible player (player+0x2bc != 0) nearest the ball by 3D Euclidean distance
  `ftol(sqrt(dx^2+dy^2+dz^2))` (d = player.xyz +4/+8/+0xc minus ball.xyz match+0x1614/+0x1618/+0x161c) and make
  it active (sim-ctx+0x168); optional +/-0x3555 facing cone gate via `atan_angle` (find_in_front); entry
  ownership shortcut (match+0x1650 controller / +0x165c via team +0x2b8); lock-keep (active+0x5d); commit sets
  the +0x5c active flags and, on a CHANGED active with team-flag teaminfo+0x2ee set AND phase 0 (FUN_005943b0),
  zeroes the new active's velocity +0x54/+0x58. NO RNG. **NAMING CORRECTION:** the prior handoff called
  `FUN_005b8f20` "ball physics" -- it is actually the PHASE-BASED active-player SELECTOR; the real physics is
  spread across `FUN_005b8690` (pairwise player/ball relationship matrix, +0xb8 angles / +0xe4 distances),
  `FUN_005b94f0` (marker assignment, +0x150/+0x154) and this `FUN_005b8ce0` -- all C++ vtable-dispatched
  (player stride 0x3bc = 0xef ints; methods +8 "decide" / +0xc "advance" via FUN_005b8bf0/FUN_005b8c20).
  Oracle `tools/re/run_movement_oracle.sh` drives the REAL `FUN_005b8ce0` under PCode emu (10 fixtures:
  nearest / 3D / cone-skip / cone-keep / owned-1650 / owned-165c / lock-keep / velocity-reset / out-of-range /
  ineligible). TWO emulation wrinkles solved + REUSABLE: (1) `ftol` = FUN_00605fb0 = `jmp [0x6233a4]`, an
  UNBOUND msvcrt _ftol thunk (target 0x251000 below image base -> HALT); inject a faithful truncate-toward-zero
  `_ftol` (`fnstcw; or ah,0x0c (RC=11); fist; restore`, NON-popping to match the caller's `fstp st(0)` cleanup)
  at 0x252000 + repoint the IAT slot `mem 0x006233a4 4 0x00252000` -- `fsqrt` itself emulates natively.
  (2) base-spec `mem` directives MUST be ONE PER LINE: PcodeEmu splits on whitespace and parses only the first
  directive, so `;`-joined `mem ... ; mem ...` silently drops all but the first (this masked the velocity-reset
  fixture until fixed). Distances kept to exact integers (pure-axis / 3-4-5) so ftol truncation is rounding-mode
  independent. Banked `specs/movement_oracle.txt`; locked by `app/tests/test_movement.gd` (60 checks: active
  index + all three +0x5c flags + the velocity reset, all bit-exact). No regression (dispatch 366 + events 85 +
  predicates 147 + tree 56 + gate + trig 30 + engine PASS; boots 0 SCRIPT ERROR).
- **Stage 3 task 2 — movement slice 2 (relationship matrix + role selection) PORTED + oracle-validated DONE.**
  `FUN_005b8690` (__fastcall this=sim-ctx) ported to `Pm98Movement.build_relationship_matrix` and its tail-call
  `FUN_005b8a60` to `Pm98Movement._select_roles`. 8690 is THROTTLED: increments ctx+0x2e0 (`inc;and 7`) and only
  works on the wrap to 0 (every 8th call). When it runs it builds, per player, the pairwise angle (atan
  `FUN_005ee080` == `Pm98Trig.atan_angle`, minus facing +0x34) at `0xb8+(slot+team*11)*2` (s16) and the projected
  PLANAR distance (cos/sin LUT reads == `Pm98Trig.cos_a/sin_a` + muladd16 `FUN_005edfb0`) at `0xe4+(slot+team*11)*4`
  (int32), plus +0x17c (nearest-opponent dist) and +0x180 (nearest-opponent-IN-FRONT, ~65deg cone 0x2e39, seed
  1000.0=0x3e80000). team-0's context (gate `[ctx+8]==0`) additionally seeds every opponent (match+0x78c, count
  +0x790), fills the cross-team half + the opponents' fields, and tail-calls 8a60. 8a60 picks 3 OUR-team role
  players into ctx +0x1fc/+0x200/+0x204 = furthest-from-anchor (max |x - +0x3a4|) / nearest-to-anchor / nearest-
  to-ball-3D (`ftol(sqrt(dx^2+dy^2+dz^2))`, x87 seq @5b8b81..5b8bb5 disasm-confirmed NO axis scaling = same metric
  as select_nearest's _ball_dist; box-gate is just a sqrt-skip optimization == `dist<best`), the last forced to the
  controller match+0x1650 when match+0x1664 == our team. NO RNG. The matrix never collides with the select_nearest
  player fields, so both slices share one player Dict. **Matrix layout is a UNIFIED 22-entry array** (own team in
  this context's slots 0..10, opponents in slots 11..21); +0xce/+0x110 are just slot-11 bases (0xb8+11*2 / 0xe4+11*4).
  Oracle `tools/re/run_relmatrix_oracle.sh` drives the REAL `FUN_005b8690` (which executes 8a60 internally) under
  PCode emu, 4 fixtures (t0_2v2 full path + the +0x180 cone split / t1_within team-1 within-only at the +11 slots
  with nonzero facings / tick_skip the &7 throttle / ctrl_forced the controller role-force), banked verbatim to
  `specs/relmatrix_oracle.txt` (one `CALL 0 RET ... mem[..]=..` line/fixture). REUSED the injected-_ftol + LUT-inject
  harness. Locked by `app/tests/test_relmatrix.gd` (128 checks: 32 readbacks/fixture = all matrix slots both
  directions + +0x17c/+0x180 + the 3 role slots + tick, bit-exact). No regression (movement 60 + dispatch 366 +
  events 85 + predicates 147 + resolver tree/gate + trig 30 + engine PASS; boots 0 SCRIPT ERROR).
- **Stage 3 task 2 — movement slice 3 (marking-target selector leaf) PORTED + oracle-validated DONE.**
  `FUN_005b36f0` (__fastcall this=player) ported to `Pm98Movement.select_mark_target(ctx, p_idx)` -- a PURE
  selector (disasm-verified: writes only stack locals) that returns the opp index our player should mark, the
  leaf of the marker-assignment pass `FUN_005b94f0`. Keeps the current target (player+0xb0) while still valid
  (inside the marking box +0x210..+0x224 INCLUSIVE in box mode team_desc+0x310==0, or `abs(tgt.x+tgt.anchor)`
  within a `team_desc+0x300/+0x2fc + match+0x1820` band in alt mode); else scans unmarked (+0x154==0) opponents
  (descriptor player+0x188 = {base,count}), scores each by the 8690 relationship-matrix dist
  `player+0xe4+(slot+team*11)*4`, inflated by `mul16` when OUT of the box (EXCLUSIVE/strict test; penalty
  0x18000 box-mode / 0x13333 alt) and by an x-gap term (`abs(cand.x-p.x)/15 + 0x10000`), and returns the lowest-
  scoring one for which p is ALSO that opponent's nearest defender (reciprocity, scanning player+0x184 = our team
  {base,count}). The trivial helpers `FUN_005b1c40` (abs(x-anchor), null->0xc80000) / `FUN_005b1c60`
  (abs(x+anchor)) / `FUN_005edfa0` (==`Pm98Trig.mul16`) are inlined. NO RNG and NO float-import -> the oracle
  needs NO _ftol/LUT injection (just poke state, read EAX). **Subtlety pinned by the oracle:** the strict
  candidate box test EXCLUDES the boundary (a player at z==zmin is "out of box" and penalized) -- the port
  matches bit-for-bit. Oracle `tools/re/run_marktarget_oracle.sh` drives the REAL `FUN_005b36f0` (EAX = returned
  target pointer), 8 fixtures (keep_box / keep_alt / invalid_search / search_pick / recip_filter / taken_skip /
  penalty_box / penalty_flip -- the last proves the out-of-box penalty CONSTANT by flipping the winner), banked to
  `specs/marktarget_oracle.txt`. Locked by `app/tests/test_marktarget.gd` (8 checks: returned opp index, bit-exact).
  No regression (relmatrix 128 + movement 60 + dispatch 366 + events 85 + predicates 147 + resolver tree/gate +
  trig 30 + engine PASS; boots 0 SCRIPT ERROR).
- **Stage 3 task 2 — movement slice 4 (marker-assignment PASS) PORTED + oracle-validated DONE.**
  `FUN_005b94f0` (__fastcall this=sim-ctx) ported to `Pm98Movement.assign_markers(ctx)` -- the per-tick marking
  pass that assembles slice 3's `select_mark_target`. **param_1 IS the ctx** (disasm 0x5b94f6 `mov ebx,ecx`, and
  every helper call is `mov ecx,ebx`), so ctx +0/+4/+8 = our players base/count/team threaded into the
  `0x5b70b0`/`0x5b70c0`/`0x5b8c90` accessors. Runs only while we are NOT in possession (`0x5b8c90`:
  match+0x1664 == ctx+8). Three passes: (poss) if match+0x1668 != match+0x1664 zero each OUR player's
  +0x13c..+0x178 block (`0x5b13c0`); (A) clear our +0x150/+0x154; (B) for each opponent HOLDING the ball (its
  +0x190->+0x40 == itself, OR == ball+0x4c = match+0x165c) scan OUR team for the lowest-scoring eligible marker
  (score = our->opp matrix dist + |z-diff|/3 via the 0x55555556 magic; eligible = on-pitch AND anchor-gap < the
  opp's; best seed 0x3e80000) and wire +0x150/+0x154; (C) every still-unmarked OUR on-pitch player runs
  `0x5b36f0` and wires the links. Integer-only -> oracle needs NO _ftol/LUT. **Composition fix pinned by the
  oracle:** slice 3's "already marked" test was `+0x154 != 0`, but PASS B writes a real our-team INDEX 0 there,
  which collides with the model's null; the faithful translation of the binary's null-pointer test in the
  `-1 = none` model is `!= -1`. Fixed `select_mark_target` accordingly and updated `test_marktarget` (free -> -1,
  taken -> a non-negative index); marktarget still 8/8. Oracle `tools/re/run_assignmarker_oracle.sh` drives the
  REAL `FUN_005b94f0` and reads back the +0x150/+0x154 links + the possession-change scalars, 7 fixtures
  (passB_route2 / in_possession / poss_change / passB_route1 / passB_reject / passC_taken_guard / off_pitch),
  banked to `specs/assignmarker_oracle.txt`. Locked by `app/tests/test_assignmarker.gd` (77 checks: every link
  mapped pointer->index via its base, bit-exact). No regression (marktarget 8 + relmatrix 128 + movement 60 +
  dispatch 366 + events 85 + predicates 147 + resolver tree/gate + trig 30 + engine PASS; boots 0 SCRIPT ERROR).
- **Stage 3 task 2 — movement slice 5a (phase active-selector, gate/6/4/else) PORTED + oracle-validated DONE.**
  `FUN_005b8f20` (__fastcall this=sim-ctx) -> `Pm98Movement.select_active(ctx)`, the per-tick selector of the
  active player ctx[0x168] by the match phase (match+0x448). This slice ports FOUR of its branches: the FORCED
  override (global byte `DAT_006d31c4`, modelled `ctx["force_active"]`, -> active = match+0x438), **phase 6**
  (active = player[0]), **phase 4** (drop the two highest-+0x39c players, then take the highest +0x394 of the
  rest; signed, ties keep the first), and the **else** path (phase 0/1/3/... -> `FUN_005b8ce0(0)` =
  `select_nearest(find_in_front=0)`, the now-ported fallback). Every path clears the old active's +0x5c, resets
  ctx[0x168], and sets the new active's +0x5c. POINTER->INDEX: ctx[0x168] / match+0x438 are player indices
  (-1 = none). Disasm-verified 0x5b8f20 (the phase-4 compares are signed `jge`; the forced gate reads
  `ds:0x6d31c4` then match+0x438). Oracle `tools/re/run_selectactive_oracle.sh` drives the REAL `FUN_005b8f20`
  (faithful _ftol injected, NO cos/atan LUT since find_in_front=0 skips the cone), 4 fixtures (forced / phase6 /
  phase4 / else_nearest), banked `specs/selectactive_oracle.txt`. Locked by `app/tests/test_selectactive.gd`
  (24 checks: active index + all four +0x5c flags, bit-exact). No regression (movement 60 + marktarget 8 +
  assignmarker 77 + relmatrix 128 + dispatch 366 + events 85 + predicates 147 + resolver tree/gate + trig 30 +
  engine PASS; boots 0 SCRIPT ERROR). **DEFERRED to slice 5b** (each needs extra oracle infra): **phase 2** (a
  static LUT at `0x6392c8` indexed by player+0x2c8 -- extract the real table, no Win32) and **phase 5/7** (a
  PERSISTENT set-piece queue at ctx+0x208/+0x20c built on Win32 `GlobalReAlloc` = `FUN_005bbf10` + `memmove` --
  insertion-sort descending by +0x3a0(+0x388 if phase 7), the +0x2ed/+0x2ee flag via `FUN_005943f0/d0/b0`, pop
  the front per call; the oracle needs import stubs + a real injected `memmove` + a pre-seeded queue buffer).
  Both currently `push_error` + leave active = -1 in `select_active`.
- **Stage 3 task 2 — movement slice 5b (phase 2 LUT + phase 5/7 set-piece queue) PORTED + oracle-validated DONE.**
  COMPLETES `FUN_005b8f20`: the two branches slice 5a deferred (no RNG). **phase 2** ->
  `Pm98Movement._select_phase2`: active = the on-pitch player with the highest `LUT[player+0x2c8]`,
  where `LUT` is the STATIC int32 .rdata table `&DAT_006392c8` extracted bit-for-bit into
  `PHASE2_LUT` (20 entries `[0,0,0,0,0,0,0,1,2,20,3,4,18,14,16,5,12,10,6,0]`; file offset
  0x2380c8, doubles begin at 0x639318). The compare is `LUT[active] <= LUT[cand]` so a TIE keeps
  the LATER on-pitch player (proven by the `p2_tie_last` + `p2_allzero` fixtures; strictly unlike
  phase 4's `<`). +0x2c8 = `*(player+0x3b8)+0x44` (the squad position code, 0..18). **phase 5/7**
  -> `Pm98Movement._select_phase57`: the persistent set-piece queue (ctx+0x208 buffer / ctx+0x20c
  count, modelled as `ctx["queue"]` = Array of player INDICES whose size IS the count, persisting
  across calls). Empty queue -> BUILD (append every player), a selection pass, the +0x2ed flag, a
  maybe-truncate-to-1, a maybe-zero-+0x8c; then EVERY call POPS the front. **CRITICAL discovery
  (disasm 0x5b91db): the build pass is NOT a clean descending sort** -- the binary caches
  `queue[i]` once per outer iteration (`edi`) and the comparator keeps comparing that CACHED value
  even after swaps move it, so the exact swap sequence is the observable (e.g. keys
  [0x100,0x400,0x200,0x300] build to order [P3,P2,P1,P0], NOT sorted). `_select_phase57` reproduces
  the verbatim double loop. key = `player+0x3a0` (+ `player+0x388` when phase 7), signed; off-pitch
  (cached +0x2bc == 0) always swaps (sinks). flag (ctx+0x2ed) = (ctx+0x2ee != 0) AND sub-phase
  (match+0x468 -> +0xfa0) in {0,2,4} (`FUN_005943f0/d0/b0`, ECX=match). Truncate to 1 unless
  (flag == 0 AND match+0x19a0 == 4); zero every player's +0x8c when bVar2 (all +0x8c were != 0) OR
  match+0x19a0 != 4. Oracle `tools/re/run_selectactive5b_oracle.sh` drives the REAL `FUN_005b8f20`:
  the Win32 grower `FUN_005bbf10` (GlobalReAlloc) is STUBBED (cdecl no-op; ctx+0x208 pre-pointed at
  0x270000 so appends land there) and the IAT memmove `call ds:0x6233d4` is repointed to a FAITHFUL
  injected memmove @0x252100 (forward `rep movsb`, preserves esi/edi/ebx -- the caller re-reads
  esi=&ctx+0x208 right after). NO trig LUT (no float path). Banked `specs/selectactive5b_oracle.txt`
  (10 fixtures: 4 phase-2 + 6 phase-5/7 covering build/truncate, phase-7 +0x388 key, off-pitch sink,
  the flag=1+predicate path, build-no-truncate full-order, and pure-pop+memmove). Locked by
  `app/tests/test_selectactive5b.gd` (125 checks: active + queue count + surviving buffer[0..count-1]
  + flag + all +0x5c + all +0x8c, bit-exact; the binary never erases the buffer past `count`, so the
  queue is compared only over the valid prefix). No regression (selectactive5b 125 + selectactive 24 +
  movement 60 + marktarget 8 + assignmarker 77 + relmatrix 128 + dispatch 366 + events 85 +
  predicates 147 + resolver tree/gate + trig 30 + engine PASS; boots 0 SCRIPT ERROR). **`FUN_005b8f20`
  is now COMPLETE (all 5 phase branches + the forced gate, every path oracle-pinned).**
- **Stage 3 task 2 — movement leaf FUN_005b1260 (planar magnitude) PORTED + oracle-validated DONE.**
  The reusable "length of a 2D vector via the trig LUT" primitive -> `Pm98Trig.planar_mag(x, y)`
  = `muladd16(x, cos_a(ang), y, sin_a(ang))`, `ang = atan_angle(x, y)` (disasm 0x5b1260: atan ->
  cos LUT read at `(ang+8>>4)` + sin at `(0x3ff8-ang>>4)` -> FUN_005edfb0). Composes only already-
  validated Pm98Trig primitives; pinned INDEPENDENTLY by `tools/re/run_planarmag_oracle.sh` ->
  `specs/planarmag_oracle.txt` (5 fixtures: x-axis 1.0, 3-4-5, neg diagonal, zero, skew) and
  `test_trig_lut.gd` (now 35 checks; +5 planar_mag, bit-exact vs the REAL fn). Integer-only (no
  _ftol); only the cos+atan LUTs injected. It is what FUN_005b70e0's nearest-search + FUN_005a3400
  read for vector lengths. No regression (all suites PASS; boots 0 SCRIPT ERROR).
- **Stage 3 task 2 — the 5 small movement geometry leaves PORTED + oracle-validated DONE.**
  Ported into `Pm98Trig.gd` (geometry-leaf section): `vec3_store` (FUN_00590aa0, 3 dword stores),
  `vec3_sub` (FUN_00590ae0, a - b), `vec3_scale_ratio` (FUN_005ee290, `v *= mult/div` with a
  64-bit `imul` then a truncating `idiv`), `clamp_min_sep` (FUN_005ee2d0, minimum-separation push:
  if p1 is inside the L-inf box of half-size `box` around p2 AND `ftol(sqrt(dx^2+dy^2+dz^2)) < box`,
  scale the delta out to `box` via FUN_005ee290, or offset by `polar_vec(box,0)` when p1==p2 exactly),
  and `mid_offset` (FUN_005ee3f0, `p1 = p4 + p2 + trunc((p1-p2)/2)`). **Two trap discoveries
  oracle-confirmed:** (1) the `/div` in 5ee290 and the `/2` in 5ee3f0 (cdq/sub/sar idiom) are
  TRUNCATE-toward-zero, NOT floor -- `scale_negodd` (-7/2 -> -3) and `mid_negodd` (-3/2 -> -1) pin
  it; a naive `_asr` floor would be WRONG on negative odd deltas. (2) the box test is strict `<`.
  Added helpers `_tdiv` (truncating divide) + `_dist3` (`int(sqrt())` = ftol). Oracle
  `tools/re/run_moveleaf_oracle.sh` drives all 5 REAL functions under PCodeEmu (faithful trunc
  `_ftol` @0x252000 + IAT 0x6233a4 repoint; cos/atan LUT injected for 5ee2d0's polar branch;
  perfect-square distances so ftol truncation is exact), banking `specs/moveleaf_oracle.txt`
  (12 fixtures: store/sub, scale even+neg-odd+5:3, clamp move/no-box/no-dist/coincident-polar,
  mid basic/neg-odd-trunc/no-box). Locked by `test_trig_lut.gd::_test_moveleaves` (now 72 checks;
  +37). No regression (selectactive 24+125, movement 60, marktarget 8, assignmarker 77, relmatrix
  128, dispatch 366, events 85, predicates 147, resolver tree/gate, engine ALL PASS; boots 0
  SCRIPT ERROR). NEXT bottom-up: `FUN_005a5460` (vtable[+4]) then `FUN_005a3400` (the DECIDE bulk).
- **Stage 3 task 2 — the 3 DECIDE coordinate helpers PORTED + oracle-validated DONE.** Ported into
  `Pm98Movement.gd`: `goal_target_x` (FUN_005a44f0; the goal-target X for a team = match+0x1820,
  negated when `(match+0x19a0 & 1) == team` -- the `jne` at 0x5a4505 means neg fires on EQUAL),
  `mirror_to_side` (FUN_005a4510 AND FUN_0059a0e0 -- both negate x,y when `(match+0x19a0 & 1) ^ team
  != 0` and copy z; 5a4510 takes match+team explicitly, 0059a0e0 derives them from the player but
  computes the identical formula, so both map to one fn), and `vec_compose` (FUN_005b11f0; out =
  `[in2d[0], in2d[1], z]`, in2d[2] ignored). All `__thiscall`, verified against disasm (the
  Ghidra decompile dropped the implicit `this` at the 5a3400 call sites). Oracle
  `tools/re/run_decidehelper_oracle.sh` drives the 3 REAL fns under PCodeEmu (match struct
  @0x210000, vecs @0x200000; pure integer, NO LUT/ftol), banking `specs/decidehelper_oracle.txt`
  (6 fixtures: goal-target eq/ne/eq0, mirror flip/noflip, compose). Locked by `test_decidehelper.gd`
  (13 checks, all PASS). No regression (decidehelper 13 + movement 60 + selectactive 24+125 +
  marktarget 8 + assignmarker 77 + relmatrix 128 + trig 72 + engine PASS; boots 0 SCRIPT ERROR).
- **Stage 3 task 2 — the 2 DECIDE state setters PORTED + oracle-validated DONE.** Ported into
  `Pm98Movement.gd`: `set_position_code` (FUN_005a5430; `player+0x40 = pos_code`, and when
  `pos_code != POS_REMAP_LUT[pos_code]` clear `+0x2c/+0x30`) and `set_engagement` (FUN_0058eca0;
  engage a target player -- on a CHANGE from `player+0x40` it records the target at +0x40/+0x44/
  +0x48, clears +0x4c, bumps `match+0x458` iff the cached team tag +0x54 changes, copies the
  target team +0x2b8 into +0x54, zeroes the target's +0x54/+0x58, bumps the counter +0x80, and in
  open play with a live stale taker clears `match+0x460`/`+0x43c`; `param_2==0` null maps to index
  -1 so the non-null guard is `>= 0`). The static **position-remap LUT &DAT_00665208** is extracted
  bit-for-bit into `POS_REMAP_LUT` (74 entries, indices 0..0x49; the coherent table ends where a
  0x01010101 byte-object begins at 0x4a, and 5a5430 only indexes by position code so the boundary is
  never crossed) -- the LUT EXTRACTION marked "TODO" in the 5a3400 decode is now CLOSED. Both fns are
  straight-line (no sub-calls, no RNG/ftol/LUT injection); the 5a5430 oracle reads the REAL .data LUT
  from the mapped program image, so it transitively validates the extraction. Oracle
  `tools/re/run_decideset_oracle.sh` -> `specs/decideset_oracle.txt` (12 fixtures: 6 position codes
  keep/remap + 6 engage new/sameteam/takereq/phase/same/null); pointer fields banked as absolute
  addresses, mapped addr->index in the test. Locked by `test_decideset.gd` (84 checks, all PASS).
  No regression (decideset 84 + decidehelper 13 + movement 60 + selectactive 24+125 + marktarget 8 +
  assignmarker 77 + relmatrix 128 + dispatch 366 + events 85 + predicates 147 + resolver tree/gate +
  trig 72 + engine ALL PASS; boots 0 SCRIPT ERROR). NEXT = FUN_005a5430's only remaining dep for
  slice B (the position LUT) is done; port FUN_005a5430-driven slice B + FUN_005a3400 slice A.
- **Stage 3 task 2 — FUN_005a3400 slice A (prologue + bbox) PORTED + oracle-validated DONE.** Ported
  into `Pm98Movement.gd` as `decide_slice_a(p, m)` (decomp lines 45-146): the goal-X anchor
  `+0x3a4 = goal_target_x(orient, match+0x1820, team)`; the two target endpoints (off-pitch -> both
  sit on the goal line + an explicit default box from `0x108000 - x1820` oriented by side with an
  x-component min/max swap; on-pitch -> `+0x1e0 = mirror_to_side(+0x1f8)`, `+0x1ec =
  mirror_to_side(+0x204)`, and a sorted box = `FUN_005b12c0` of `mirror(compose(+0x228,z=0))` vs
  `mirror(+0x230,z=0)`); then the 6-int source copied to the bbox `+0x210..+0x224`, z reseeded
  (`+0x218 = 0xffff0000`, `+0x224 = 0x12c0000`), and 12 signed min/max clamps fold both endpoints
  in. Pure integer (mirror/compose/per-axis min-max), NO RNG/LUT/ftol. **Oracle insight:** slice A
  is a pure prefix, so `run_decideA_oracle.sh` drives the WHOLE real FUN_005a3400 down the REPLAY
  path (`DAT_006d31c4 != 0` @0x6d31c4): slice A executes identically, then the simple replay-copy
  tail RETURNs cleanly -- no callee stubs, no LUT, no RNG, and the 0x51-dword replay copy writes
  only player+0x40..+0x184 so the slice-A outputs (+0x1e0..+0x224, +0x3a4) survive untouched. Banked
  `specs/decideA_oracle.txt` (6 fixtures: off-pitch u9=0/1/team1 + on-pitch noflip/flip/flip-team1;
  13 output fields each). Locked by `test_decideA.gd` (78 checks, all PASS). No regression (decideA
  78 + decideset 84 + decidehelper 13 + movement 60 + selectactive 24+125 + marktarget 8 +
  assignmarker 77 + relmatrix 128 + dispatch 366 + events 85 + predicates 147 + resolver tree/gate +
  trig 72 + engine ALL PASS; boots 0 SCRIPT ERROR). NEXT = slice B (field reset + facing + position,
  deps set_position_code DONE; needs the match+0x188+0x13c table model for +0xb0) then slice C.
- **Stage 3 task 2 — FUN_005a3400 slice B (field reset + facing + position) PORTED + oracle-validated
  DONE.** Ported into `Pm98Movement.gd` as `decide_slice_b(p, m)` (decomp lines 147-177 / disasm
  0x5a374d..0x5a37f8, the `DAT_006d31c4 == 0` real-compute head): clear the per-tick movement scratch
  (`+0x3b4/+0x48/+0x90/+0x54/+0x58/+0x68/+0x6c/+0x20/+0x24/+0x28/+4/+8/+0xc` = 0), set the s16 facing
  `+0x34 & +0x64 = (((orient&1) ^ team) != 0) ? 0x8000 : 0` (180deg when defending the opposite side),
  look up the formation-position value `+0xb0 = *(player+0x188 + 0x13c + player+0x2cc*4)` (0 when the
  slot `+0x2cc` < 0) and set `+0x61 = 1` iff nonzero, then `set_position_code(player+0x2bc==0 ? 0x1e : 0)`
  (DONE leaf). **TWO disasm-verified corrections to the 2026-06-18 slice-B note** (the decompile/handoff
  were loose; the disasm is authoritative): (1) the zeroed velocity-scratch is `+0x20/+0x24/+0x28` ONLY,
  NOT "+0x20..+0x30" -- `+0x2c/+0x30` are untouched here (and set_position_code's remap-clear never fires:
  pos_code is 0 or 0x1e and POS_REMAP_LUT[0]==0 / POS_REMAP_LUT[0x1e]==0x1e both map to self); (2) `+0x61`
  is only SET (to 1) when the table value is nonzero -- the binary `je`-skips otherwise, so it is NEVER
  cleared here. STRUCT MODEL: player+0x188 -> `_ref(p, 0x188)` = the team/formation struct, its int32
  table at +0x13c; player+0x18c -> the match (== `m`). Pure integer (NO RNG/LUT/ftol; set_position_code
  reads only the static POS_REMAP_LUT). **Oracle trick (NOT the slice-A replay path -- slice B IS the
  gated body):** `run_decideB_oracle.sh` drives the WHOLE real FUN_005a3400 with `DAT_006d31c4 = 0` (real
  compute) and `match+0x448 = 8`, so the switch `cmp eax,0x7; ja 0x5a44ba` falls straight to the DEFAULT
  exit (clean RET) immediately AFTER slice B -- slice C never runs, no LUT/RNG, and the default exit does
  NOT rewrite facing. FUN_005bbf10 (queue-grow, called by slice B's head AND the leading FUN_005ed870
  no-op) is STUBBED; FUN_005a5430 runs FOR REAL (reads the mapped .data LUT). Slice A executes as the
  HALT-free prefix but writes only +0x1e0..+0x224/+0x3a4 (not read here). Banked `specs/decideB_oracle.txt`
  (5 fixtures: home_on facing0/pos0/+0xb0 set, away_on facing0x8000/+0xb0=0/+0x61-seed-survives,
  off_pitch facing0/pos0x1e/+0x2c+0x30-survive, neg_idx idx<0/+0x61-seed-survives, away_t1_big high-bit
  +0xb0=0x7fff0000). Locked by `test_decideB.gd` (**100 checks, ALL PASS**, 20 fields/fixture parsed by
  abs addr). No regression (decideB 100 + decideA 78 + decideset 84 + decidehelper 13 + movement 60 +
  selectactive 24+125 + marktarget 8 + assignmarker 77 + relmatrix 128 + dispatch 366 + events 85 +
  predicates 147 + resolver tree/gate + trig 72 + engine ALL PASS; boots 0 SCRIPT ERROR). NEXT = slice C
  (the set-piece switch on match+0x448, dep set_engagement DONE).
- **Stage 3 task 2 — FUN_005a3400 slice C1 (set-piece switch, NON-TAKER paths) PORTED + oracle-validated
  DONE.** Ported into `Pm98Movement.gd` as `decide_slice_c(p, m)` + helpers `_slice_c_set_move` /
  `_slice_c_tail` (disasm 0x5a37f8..0x5a44c4, the `DAT_006d31c4==0` switch tail). C1 covers the DEFAULT
  exit + the NON-TAKER (`player != match+0x438`) move-target writes of cases 3/6/7 + the shared atan
  facing tail. Per `cmp eax,7; ja 0x5a44ba`: phase outside 2..7 -> clean RET *after* the tail, so DEFAULT
  leaves move + slice-B facing UNTOUCHED. Non-taker move target picks from the two slice-A endpoints
  (ep1 = +0x1e0/+0x1e4/+0x1e8, ep2 = +0x1ec/+0x1f0/+0x1f4): case 3 same-team->ep2 / diff->ep1; case 6
  same->per-axis midpoint `_tdiv(ep2+ep1, 2)` (trunc toward zero, confirmed by c6_negmid `(-8+3)/2=-2`)
  / diff->ep1; case 7 same->ep2 / off-pitch(+0x2bc==0)->`set_position_code(0x20)`,ep1,then
  `move[0] += (ball.x(+0x90)>=0 ? -0x5999 : +0x5999)` / else->ep1. Every non-taker case then recomputes
  facing in the common tail (0x5a4494/0x5a449e): `facing = atan((ball+0x4 vec) - move)`, raw-s16 WORD
  write to +0x34/+0x64 (ball = player+0x190). Leaf sigs verified vs disasm: `FUN_00590ae0` vec3_sub
  (this-param), `FUN_005b12c0(dst6, src3a, src3b)` (NOT one src), `FUN_0058eca0(engager, target_ptr)`
  (engager = ball, target = player on takers -- hence ball.engage(player) = take possession).
  **NOT YET PORTED (explicit push_error guards):** all TAKER branches (`player == match+0x438`:
  set_engagement + stamina `(taker-flag?0x2d0:0)+0xb4` + atan aim, RNG save/restore in case 6) and cases
  2/4/5 (the bbox-blend via 5b12c0 + the `_DAT_00674330` .data set-piece position tables + the
  `DAT_006742ec` one-time init). **Oracle:** `run_decideC_oracle.sh` drives the WHOLE real FUN_005a3400
  with `DAT_006d31c4=0`, `match+0x448 in {3,6,7,8}`, `match+0x438 -> a DISTINCT taker T2@0x260000` (so
  non-taker), `player+0x2cc=-1` (slice-B lookup skipped), ball@0x250000, taker@0x260000; cos/atan LUTs +
  faithful `_ftol` injected (moveleaf trick) so the real `FUN_005ee080` atan emulates without fcos;
  FUN_005bbf10 stubbed, FUN_005a5430/590ae0/5ee080 real. Banked `specs/decideC_oracle.txt` (10 fixtures:
  c3_same/diff, c6_same/negmid/diff, c7_same/off_pos/off_neg/on_diff, default). Locked by `test_decideC.gd`
  (**70 checks, ALL PASS**, parsed by abs addr; runs A->B->C). No regression (decideC 70 + decideB 100 +
  decideA 78 + decideset 84 + decidehelper 13 + trig 72 + movement 60 + selectactive5b 125 + marktarget 8 +
  assignmarker 77 + relmatrix 128 + dispatch 366 + events 85 ALL PASS; boots 0 SCRIPT ERROR). NEXT = slice
  C2 (taker branches: ball-engage modelling + stamina + atan aim) then C3 (cases 2/4/5 + the .data tables).
- **Stage 3 task 2 — FUN_005a3400 slice C2 (set-piece switch, TAKER paths) PORTED + oracle-validated DONE.**
  Ported into `Pm98Movement.gd` as `_decide_slice_c_taker(p, m, phase)` + helper `_slice_c_taker_aim`,
  wired from `decide_slice_c` when `is_same(p, _ref(m, 0x438))` (player IS the set-piece taker). Covers the
  TAKER branches of cases 2/3/4/5/6/7. For the player's OWN reported fields every taker shares:
  (1) `set_engagement(ball, 0, [p])` = ball.engage(player) (FUN_0058eca0 this=ball=player+0x190,
  target=player) -- its only player-field effect is +0x54/+0x58=0 (already zeroed by slice B); the rest
  mutate ball/match engagement state (validated in test_decideset). (2) stamina `+0x48 = (flag?0x2d0:0)+0xb4`,
  `flag = teaminfo(+0x184)+0x2ee != 0 AND phase0(match) AND player+0x5c != 0` (FUN_005943b0 confirmed ==
  `[match+0x468]+0xfa0 == 0` = `_phase0`). (3) `set_position_code` 0 (c2) / 0x13 (c3) / 0x1d (c4/5/6/7);
  the 0x13 + 0x1d codes REMAP so they clear +0x2c/+0x30 (kill-tested). Per-case facing+move from the ball
  position (ball+0x90 vec) and the goal-line aim `aim_x = -+match+0x1820 when (orient&1)==(1-team)`:
  cases 2/4/5/7 -> `ang=atan(aim-ball_pos)`, `move=ball_pos - polar_vec(0x6666, ang)` (FUN_005ee0f0 confirmed
  == polar_vec); case 2 keeps facing=ang + early-returns, cases 4/5/7 recompute facing=atan(aim-move) in the
  common tail; case 3 -> facing(+0x34 ONLY, +0x64 keeps slice-B) = (ball+0x94<1)?0x4000:-0x4000,
  move=ball_pos - polar_vec(0x6666, facing); case 6 -> facing(both)=((orient&1)^team)?0x8000:0, move=ball_pos.
  **NOT modelled (verified player-field-inert global side-effects):** the case 4/5/6/7 `.data` set-piece
  globals (0x665154/.../0x67455c), case 6's RNG save/restore bracket (5ec240/5ec230, net RNG-neutral) and its
  gated SFX `FUN_004e9630` (skipped when match+0x180b==0; it is an SFX_COMENT sprintf path touching no P0
  field). **Oracle:** `run_decideCtaker_oracle.sh` drives the real FUN_005a3400 with player==match+0x438,
  ball+0x40=player (so the real ball.engage early-returns -> no wild writes), teaminfo/phase0 structs seeded,
  match+0x180b=0, cos/atan LUT + _ftol injected. Banked `specs/decideCtaker_oracle.txt` (6 fixtures:
  c2_flagT/flagF, c3/c4/c6/c7_taker). Locked by `test_decideCtaker.gd` (**54 checks, ALL PASS**, runs A->B->C
  with match+0x438==p). No regression (decideCtaker 54 + decideC 70 + decideB 100 + decideA 78 + decideset 84
  + decidehelper 13 + trig 72 + movement 60 + selectactive5b 125 + marktarget 8 + assignmarker 77 + relmatrix
  128 + dispatch 366 + events 85 ALL PASS; boots 0 SCRIPT ERROR). NEXT = slice C3 (the NON-taker branches of
  cases 2/4/5: case 2 bbox-blend via 5b12c0 + clamp_min_sep; cases 4/5 the DAT_006742ec one-time init + the
  49-entry _DAT_00674330 set-piece position table indexed by player+0x2c8) then the else-replay branch.
- **Stage 3 task 2 — FUN_005a3400 slice C3 (set-piece switch, NON-TAKER cases 2/4/5) PORTED + oracle-validated
  DONE.** Ported into `Pm98Movement.gd` as `_slice_c_case2_nontaker` + `_slice_c_case45_nontaker` (+ helpers
  `_clamp_i` / `_slice_c_min_sep` + the const `SETPIECE_POS_TABLE`), wired into `decide_slice_c`. This COMPLETES
  the whole `DAT_006d31c4==0` real-compute path of FUN_005a3400 (slices A+B + the switch: C1 non-taker 3/6/7 +
  default, C2 all takers, C3 non-taker 2/4/5). Decoded BIT-FOR-BIT from the disasm (the Ghidra decompile's
  comma-assignments mislead in the case-2 clamp ladder). **case 2** (0x5a3953..0x5a3a2a, any non-taker): clamp
  endpoint1 per-axis into `minmax(v, L)` where `v = [goal_target_x(m+0x1820), -Yscale, -1.0]`, `L = [0, +Yscale,
  +1000.0]` (Yscale = match+0x1824), via the `min(hi,max(lo,.))` jg/jge ladder at 0x5a399c..0x5a39fe, then
  `clamp_min_sep(ball+0x90, 0x90000)`. **cases 4/5 same-team** (0x5a3d12..0x5a3fe9): move = endpoint2, then a
  conditional OVERRIDE from `SETPIECE_POS_TABLE[player+0x2c8]` -> `move = [+/-(m+0x1820 - entry.x), +/-entry.y,
  entry.z]` (x mirror-signed by `(orient&1)^team`; y negated when ball+0x94 > 0), SKIPPED when (phase==5 &&
  match+0x19cc==0) OR the entry is all-zero OR (pos in {5,6} && player+0x2d6==0); on-pitch -> clamp_min_sep
  0xa8000. **cases 4/5 diff-team off-pitch** (0x5a3fee..0x5a4073): set_position_code(0x20), move = endpoint1,
  move.x += `((orient&1)^team ? -0x4ccc : +0x4ccc)`, move.y += `(ball+0x94 >= 0 ? -0x20000 : +0x20000)`.
  **cases 4/5 diff-team on-pitch** (0x5a4078..0x5a40a9): move = endpoint1, clamp_min_sep 0xa8000. All non-taker
  paths converge on the shared atan facing tail `_slice_c_tail` (verified: case 2 jmp 0x5a4494, cases 4/5 jmp
  0x5a4495/0x5a449e -- same atan tail as C1's break-fallthrough). **SETPIECE_POS_TABLE** (19 entries x 3 int32,
  &DAT_00674330) transcribed from the inline init writes 0x5a3d57..0x5a3ed6; `FUN_00605ff0(&DAT_005a4550)` in the
  init is a separate global side-effect that NEVER touches the table (it calls FUN_00605fc0 + returns a bool).
  **Oracle:** `run_decideC3_oracle.sh` drives the WHOLE real FUN_005a3400 with `DAT_006d31c4=0`, the table-init
  flag `0x6742ec` cleared (so the inline table writes land + are read back -> validates the const transitively),
  `FUN_00605ff0` + `FUN_005bbf10` STUBBED (faithful no-ops), cos/atan LUT + faithful `_ftol` injected
  (clamp_min_sep + atan tail); 5a5430/590aa0/5b12c0/590ae0/5ee080/5ee2d0/5a44f0 run FOR REAL. ball.pos kept far so
  clamp_min_sep is a no-op (the move computation is the novel logic; clamp_min_sep internals are pinned in
  test_trig_lut moveleaves). Banked `specs/decideC3_oracle.txt` (13 fixtures: c2 plain/mirror, c4 same-team
  override/mirror, c5 phase-5 guard on/off, c4 all-zero/pos5-guard/pos5-d6/off-pitch, c4 diff-team off/off-neg/on
  -- all CALL 0 RET). Locked by `test_decideC3.gd` (**91 checks, ALL PASS**, runs A->B->C). No regression
  (decideC3 91 + decideCtaker 54 + decideC 70 + decideB 100 + decideA 78 + decideset 84 + decidehelper 13 +
  trig 72 + movement 60 + selectactive 24+125 + marktarget 8 + assignmarker 77 + relmatrix 128 + dispatch 366 +
  events 85 + predicates 147 + resolver tree/gate + engine ALL PASS; boots 0 SCRIPT ERROR). **FUN_005a3400's
  real-compute path is now COMPLETE.** NEXT = the else-replay branch (DAT_006d31c4 != 0, decompile 592-621: the
  0x51-dword player+0x3b0 -> player+0x40 restore + the +0x5c active-marker bookkeeping + the +0x438-taker +0x45c
  stamp), then FUN_005b70e0 shell + FUN_005b73a0 (RNG draws) + driver 0x598740 -> full-match KILL-TEST.
- **Stage 3 task 2 — FUN_005a3400 ELSE-REPLAY branch (DAT_006d31c4 != 0) PORTED + oracle-validated DONE.**
  Ported into `Pm98Movement.gd` as `decide_slice_replay(p, m)` (disasm 0x5a368c..0x5a374c). The non-real-compute
  path: when the global replay flag is set, the per-player DECIDE does NOT recompute -- it (1) copies 0x51 (81)
  dwords from the saved buffer at *(player+0x3b0) into player+0x40..+0x180 (`rep movsd`; the source is a POINTER
  stored at +0x3b0, NOT inline), then (2) if the RESTORED +0x5c (active marker, = buffer offset 0x1c) is set,
  makes this player the team's active player -- team(+0x184)+0x168 = player, clearing the previously-active
  player's +0x5c UNLESS it is null or already this player -- and, when this player is the set-piece taker
  (match+0x438), stamps match+0x45c = player team. The taker-only set-piece globals 0x665154/0x66502c/0x67455c
  are player-field-inert (validated in C2) and not modelled. **This COMPLETES FUN_005a3400 (all paths: slice A
  prologue+bbox, the DAT_006d31c4==0 real-compute head slice B + the switch C1/C2/C3, AND this DAT_006d31c4!=0
  replay branch).** STRUCT MODEL: player+0x3b0 -> saved-state buffer (a ref); player+0x184 -> team struct, its
  +0x168 = the active player (a player ref; absent/null = none); the active-marker bookkeeping uses the GDScript
  built-in `is_same` for pointer identity (player ref vs prior-active ref). **Oracle:** `run_decideReplay_oracle.sh`
  drives the WHOLE real FUN_005a3400 down the replay path (DAT_006d31c4=1) -- the SAME harness as
  run_decideA_oracle.sh (slice A runs as the prefix, writes only +0x1e0..+0x224/+0x3a4, none read here; NO callee
  stubs, NO LUT/RNG). Buffer @0x254000 seeded with 4 distinct dwords (+0/+4/+0x70/+0x140) + the per-fixture +0x1c
  gate; team @0x240000, prior-active OLD @0x280000, match+0x45c pre-seeded 0x7777 sentinel. Banked
  `specs/decideReplay_oracle.txt` (5 fixtures: active_taker_old / active_nontaker_old / inactive / active_noold /
  active_self -- all CALL 0 RET). Locked by `test_decideReplay.gd` (**40 checks, ALL PASS**: the 5 restored copy
  fields + team+0x168 (pointer->dict identity mapped) + prior-active +0x5c cleared + match+0x45c stamp). No
  regression (decideReplay 40 + decideC3 91 + decideCtaker 54 + decideC 70 + decideB 100 + decideA 78 + decideset
  84 + decidehelper 13 + trig 72 + movement 60 + selectactive 24+125 + marktarget 8 + assignmarker 77 + relmatrix
  128 + dispatch 366 + events 85 + predicates 147 + resolver tree/gate + engine ALL PASS; boots 0 SCRIPT ERROR).
  NEXT (FUN_005a3400 fully done) = FUN_005b70e0 shell + FUN_005b73a0 (7 RNG draws, trace 0x5ec250 for ORDER) +
  driver 0x598740 -> the full-match KILL-TEST.
- **Stage 3 task 2 — match-tick driver call-graph MAPPED (FUN_00598740) 2026-06-19.** Read the master
  per-tick driver `FUN_00598740` (sim/fn_00598740) + resolved the player vtable from MANAGER.EXE .rdata
  (VA 0x639224 = `[0x5ed810, 0x5a5460, 0x5a3400, 0x5a4560, ...]`). **Verified: vtable+8 = FUN_005a3400
  (DECIDE, DONE), vtable+0xc = FUN_005a4560 (ADVANCE/physics, NOT ported), vtable+4 = FUN_005a5460
  (SPRITE/ANIM draw -- DISPLAY).** The per-tick SIM order (each x2, once per team): FUN_005b8bf0 (decide
  dispatch ->5a3400) -> 4 sub-entity decides -> FUN_005b8690 (relmatrix DONE) -> FUN_005b94f0 (markers
  DONE) -> FUN_005b8c20 (advance dispatch ->5a4560) -> 4 sub-entity advances -> FUN_005b8ce0 (nearest
  DONE) -> DAT_006d31bc ring++ -> open-play resolution (predicates DONE + dispatch DONE + RNG). **KEY
  CORRECTION: FUN_005b70e0 + FUN_005a5460 are RENDER passes (sprite draw, gated by match+0x180b/0x5fac)
  -- NOT needed for the headless match-outcome engine; the prior handoff's "FUN_005b70e0 shell" next-step
  was mis-aimed at a render pass.** Full map (per-tick order, render/sim split, remaining-function
  inventory) -> `docs/re/MATCH_TICK_DRIVER_MAP.md`. **CORRECTED NEXT (sim path) = FUN_005a4560 (advance,
  vtable+0xc; same replay record/playback brackets as 5a3400, leaf FUN_005ed8e0) -> FUN_005b73a0
  (positioning, slice it) -> the 4 sub-entity vtables -> FUN_00598740 driver -> full-match KILL-TEST.**
- **Stage 3 task 2 — FUN_005a4560 (vtable+0xc ADVANCE pass) + FUN_005ed8e0 PORTED + oracle-validated
  DONE.** Ported into `Pm98Movement.gd` as `advance(p, ring, playback, record, frame)` + `_advance_motion`.
  **KEY FINDING: the ADVANCE pass is PURE replay record/playback -- it does NO physics.** The player's
  POSITION (+0x4/+0x8/+0xc) is written directly by the DECIDE pass (FUN_005a3400) every tick; there is
  no separate integration step (the driver FUN_00598740 calls only decide(+8) + advance(+0xc) per player).
  FUN_005a4560 acts only on the frame-ring wrap (DAT_006d31bc == 0), and then: PLAYBACK (DAT_006d31c4) ->
  FUN_005ed8e0 restores the 9-dword MOTION snapshot from *(player+0x38)[frame*0x24] (+0x4/+0x8/+0xc pos,
  +0x20/+0x24/+0x28 vel, +0x2c, +0x30, +0x34 facing WORD) + the body restores the 0x51-dword DECIDE state
  from *(player+0x3b0)[frame*0x144] -> +0x40..+0x180; RECORD (DAT_00665d8c) -> append the same snapshots
  (FUN_005ed820 = the exact inverse motion layout); else NO-OP. **A live headless match-outcome run sets
  neither replay nor record, so advance() is a NO-OP there** -- it contributes nothing to the scoreline,
  confirming the player movement is FULLY captured by DECIDE (5a3400, DONE) + positioning (5b73a0).
  **Oracle:** `run_advance_oracle.sh` drives the REAL FUN_005a4560 (which calls FUN_005ed8e0; pure copies,
  NO stubs/LUT/RNG/ftol) -> `specs/advance_oracle.txt` (4 fixtures: pb_f0 / pb_f2 [frame-index] / noop_ring
  / noop_live -- all CALL 0 RET). Locked by `test_advance.gd` (**48 checks, ALL PASS**: the 9 motion fields
  + 3 decide-state samples for playback, all 12 unchanged for the two no-op gates). The RECORD path is the
  structural inverse (append) -- ported, exercised only structurally (headless never records). No regression
  (advance 48 + decideReplay 40 + decideC3 91 + decideCtaker 54 + decideC 70 + decideB 100 + decideA 78 +
  decideset 84 + decidehelper 13 + trig 72 + movement 60 + selectactive 24+125 + marktarget 8 + assignmarker
  77 + relmatrix 128 + dispatch 366 + events 85 + predicates 147 + resolver tree/gate + engine ALL PASS;
  boots 0 SCRIPT ERROR). **vtable+0xc DONE. NEXT = FUN_005b73a0 (positioning, ~4.8KB, 7 RNG draws -- the
  last big sim piece before the FUN_00598740 driver; SLICE it like 5a3400).**
- **Stage 3 task 2 — FUN_005b73a0 leaves FUN_005b04e0 + FUN_005b0b40 PORTED + oracle-validated DONE.**
  The two genuinely-new pure-integer predicates the off-ball positioning pass FUN_005b73a0 calls
  (FUN_005b04e0 x2 @ decompile 158/193; FUN_005b0b40 @ 651 + also the stamina pass FUN_005a4600) ->
  `Pm98Movement.pos_forward_ok` + `count_goalside_opponents` (+ helpers `_si`/`_sign1`). **FUN_005b04e0**
  (__thiscall player; pos3): 1 iff pos is inside the pitch box [m+0x1828..+0x1834]x[+0x182c..+0x1838]x
  [+0x1830..+0x183c] AND abs(x) > m+0x1820-0x108000 AND abs(y) < 0x1428f5 AND sign(x) != sign(player+0x3a4)
  (sign bucket = +1 if >=0 else -1). **FUN_005b0b40** (__thiscall player; thresh): count of opponents
  (player+0x188 = {base,count}) with abs(opp.x - opp.anchor) < thresh + abs(player.x + player.anchor),
  x=+0x4 anchor=+0x3a4, null term = 0xc80000, all sums wrap to int32 before the signed compare. Both are
  pure integer, NO RNG/LUT/ftol/sub-calls. **Oracle:** `run_posleaf_oracle.sh` drives both REAL fns under
  PCodeEmu (EAX = return; the stack arg via the `arg` directive) -> `specs/posleaf_oracle.txt` (8 fixtures:
  b04e0 ok/outbox/online/ybig/samesign + b0b40 one/all/none -- all CALL 0 RET). Locked by `test_posleaf.gd`
  (**8 checks, ALL PASS**). GDScript pitfall (warnings-as-errors): a `:=`-inferred ternary with an int
  literal + abs() infers Variant -> use explicit `var x: int =`. No regression (posleaf 8 + advance 48 +
  decideReplay 40 + decideC3 91 + ... + engine ALL PASS; boots 0 SCRIPT ERROR). NEXT = slice FUN_005b73a0
  itself (the leaves are now in place: 5b04e0 + 5b0b40 ported, 5b8690/5a5430/predicates/trig all DONE).
- **Stage 3 task 2 — 3 match-driver (FUN_00598740) leaves PORTED + oracle-validated DONE.** The small
  leaves the per-tick driver calls -> `Pm98Movement.within_box` / `set_phase` / `vec3_copy`.
  **FUN_005a1820** (__thiscall p1; p2, lx, ly, lz): 1 iff p1 within the per-axis L-inf box of half-extents
  (lx, ly, lz) around p2 (STRICT <; per-axis diff wraps to int32 before abs) -- the driver uses it 5x for
  goalkeeper-distribution region tests. **FUN_005942e0** (__thiscall match; phase): match+0x448 = phase
  unless already 8 (locked), mirror to +0x44c unless phase == 1. **FUN_00590ac0**: 3-dword vec copy.
  **Oracle:** `run_driverleaf_oracle.sh` -> `specs/driverleaf_oracle.txt` (9 fixtures: a1820 within/negok/
  x/y/z-fail [EAX], phase set/one/locked [mem +0x448/+0x44c], copy_vec [mem] -- all CALL 0 RET). Locked by
  `test_driverleaf.gd` (**14 checks, ALL PASS**). No regression (driverleaf 14 + posleaf 8 + advance 48 +
  ... + engine = 24 suites ALL PASS; boots 0 SCRIPT ERROR). NEXT = slice FUN_005b73a0 (positioning; 3 phase
  branches -- defensive-wall / phase-7 / phase-3 + phase-5 tail -- all leaves now ported) then the
  FUN_00598740 driver + its remaining helpers (FUN_00593a30/5946d0/94410/94570/5910c0/591120/0058f0b0/
  0058f3c0/59a120/59a1e0) -> full-match KILL-TEST.
- **Stage 3 task 2 — driver resolution leaf FUN_0058f0b0 PORTED + oracle-validated DONE.** ->
  `Pm98Movement.player_opposite_half(p, side)`: 1 iff sign(player.x) != sign(goalx), goalx =
  -(match+0x1820) when (match+0x19a0 & 1) == side else +(match+0x1820) -- the player is on the opposite
  half from `side`'s goal (match = player+0x1d4; sign bucket +1 if >=0 else -1). The driver FUN_00598740
  calls it per team in the goal-area resolution branch (decompile line 377). Pure integer, no sub-calls.
  Oracle `run_halfpitch_oracle.sh` -> `specs/halfpitch_oracle.txt` (5 fixtures: opp/same/side1/orient1/
  zero-x [EAX], all CALL 0 RET); locked by `test_halfpitch.gd` (**5 checks, ALL PASS**). No regression
  (25 suites ALL PASS; boots 0 SCRIPT ERROR). **OBSERVATION (verified): for phase 0 (open play, ~95% of
  ticks) FUN_005b73a0 is just relmatrix(DONE) + ctx[0xb8]=-1 + return -- the off-ball positioning branches
  only fire on set-pieces (phases 3/4/5/7). So slicing FUN_005b73a0 = port the 3 set-piece branches; the
  open-play path is trivial.** NEXT = FUN_005b73a0 set-piece branches (phase-3 smallest, then 7, then 4/5
  wall + phase-5 tail) then the FUN_00598740 driver -> full-match KILL-TEST.
- **Stage 3 task 2 — FUN_005b73a0 slice A (per-team positioning, prologue + OPEN-PLAY path) PORTED +
  oracle-validated DONE.** -> `Pm98Movement.position_team(ctx)`: relationship matrix (FUN_005b8690,
  throttled; DONE) + reset the throttle counter ctx+0x2e0 (= param_1[0xb8]) = -1, then dispatch on the
  set-piece phase (match+0x448). For OPEN PLAY (phase 0, and the other non-set-piece phases 1/2/6) the
  dispatch falls straight to the TAIL which returns (match+0x448 != 5) -- NO player is touched. ctx model
  = the relationship-matrix ctx (ctx["players"]/ctx[0x8] team/ctx[0x138] match/ctx[0x2e0] throttle).
  **The 4 set-piece branches are explicit push_error stubs (future slices): phase 4/(5&0x19cc) wall,
  phase 7, phase 3, the phase-5 TAIL follow-up -- each a player loop with exact RNG ordering.** Oracle
  `run_positionteam_oracle.sh` drives the REAL FUN_005b73a0 with phase in {0,1,6}, ctx+0x2e0 seeded 0 so
  FUN_005b8690 increments to 1 and SKIPS (throttle -> no player iteration, no LUT/RNG, NO stubs); then
  FUN_005b73a0 sets ctx+0x2e0 = -1 and the TAIL returns -> `specs/positionteam_oracle.txt` (3 fixtures,
  all CALL 0 RET, ctx+0x2e0 -> -1 + player+0x4 untouched). Locked by `test_positionteam.gd` (**6 checks,
  ALL PASS**). No regression (26 suites ALL PASS; boots 0 SCRIPT ERROR). NEXT = fill in the phase-3 / 7 /
  4-5 / phase-5-tail set-piece branches, then the FUN_00598740 driver -> full-match KILL-TEST.
- **Stage 3 task 2 — FUN_005b73a0 slice B (phase-3 kickoff/restart) PORTED + oracle-validated DONE.**
  -> `Pm98Movement._position_phase3` (wired into position_team; `position_team` gained an optional `rng`
  param). Decoded from the disasm 0x5b7fec..0x5b81cf. **OUR team** (match+0x45c == team): find the nearest
  on-pitch teammate to the taker (min |x - taker.x|, != taker, best seed 0x640000), then RNG-jitter it
  toward the taker -- `np.x = trunc((rand1*50>>15)*(np.x-taker.x)/100) + taker.x`, `np.y = trunc((rand2*50
  >>15)*(np.y-taker.y)/100) + sign(np.y-taker.y)*0x70000 + taker.y` (z unchanged; 2 FUN_005ec250 draws in
  x-then-y order; /100 = the 0x51eb851f truncate-toward-zero magic) -- and set the TAKER's facing
  (+0x34/+0x64) = atan(np - taker). **ELSE** (opponent's set-piece): clamp the role player ctx+0x200's x to
  the taker's goal side (min if attacking -x else max) and set its y(+0x8) = 0. **Oracle:**
  `run_phase3_oracle.sh` drives the REAL FUN_005b73a0 phase-3 (relmatrix throttle-skipped via ctx+0x2e0=0,
  atan LUT injected, RNG seed @0x6d3184) -> `specs/phase3_oracle.txt` (3 fixtures: our_jitter [seed 12345,
  factor 11 -> P2.x=0x547a hand-verified] / our_seed1 [seed 1, factor 0 -> x collapses to taker] / else_min
  [role.x clamped to 0x20000, y=0], all CALL 0 RET). Locked by `test_phase3.gd` (**8 checks, ALL PASS**).
  GDScript pitfall (warnings-as-errors): `var d := abs(...)` infers Variant (abs returns Variant) -> use
  explicit `var d: int =`. No regression (27 suites ALL PASS; boots 0 SCRIPT ERROR). NEXT = phase-7, then
  the phase-4/5 defensive-wall + phase-5 tail branches, then the FUN_00598740 driver -> full-match KILL-TEST.
- **Stage 3 task 2 — FUN_005b73a0 slice C (phase-7 SCATTER sub) PORTED + oracle-validated DONE.** ->
  `Pm98Movement._position_phase7` (disasm 0x5b7c6d..0x5b7fe5). When match+0x19a0 == 4 (penalty/ET scatter
  mode): every eligible player -- not the taker, AND on-pitch OR (off-pitch on our set-piece side
  team==match+0x45c) -- is scattered to a random polar position: angle = (rand1*0x10000)>>15, radius =
  (rand2*0xa00)>>7, then pos (+0x4/+0x8/+0xc) = endpoint1 (+0x1e0) = endpoint2 (+0x1ec) =
  polar_vec(radius, angle). Two FUN_005ec250 draws per processed player (angle then radius), in player
  order. (The angle path's `(esi*r)>>15` is split as `(esi>>8)*r>>7` to avoid 32-bit overflow; esi is a
  hardcoded 0x10000 here so the one-step branch is dead -- the result is just rand1*2 either way.)
  **The match+0x19a0 != 4 wall path shares machinery with phase 4/5 and is a push_error stub (future).**
  Oracle `run_phase7_oracle.sh` drives the REAL phase-7 (relmatrix throttle-skipped, cos LUT injected, RNG
  seed @0x6d3184) -> `specs/phase7_oracle.txt` (2 fixtures: scatter_seed1 [P1 draws 1-2, P2 draws 3-4] +
  offpitch_skip [match+0x45c=1 -> P1 off-pitch SKIPPED no-draws, P2 scattered draws 1-2], all CALL 0 RET).
  Locked by `test_phase7.gd` (**12 checks, ALL PASS**; pos == endpoint1 == endpoint2 confirmed, skipped P1
  retains its sentinel). No regression (28 suites ALL PASS; boots 0 SCRIPT ERROR). NEXT = the phase-4/5
  defensive-wall (the biggest branch, shares the &DAT_00639270 table + FUN_005b04e0 + bitmap passes with
  phase-7's wall) + the phase-5 TAIL follow-up, then the FUN_00598740 driver -> full-match KILL-TEST.
- **Stage 3 task 2 — FUN_005b73a0 slice D (phase-4 DEFENSIVE-WALL, loop 1 + loop 5) PORTED + oracle-
  validated DONE.** -> `Pm98Movement._position_wall` + `_wall_pull` (disasm 0x5b73a0..0x5b7c6c; entered when
  match+0x448==4 || (==5 && match+0x19cc), AND match+0x45c != team). The two-team marking pass: OUR players
  (ctx["players"]) get assigned to mark OPPONENTS (ctx["opponents"]); both sides carry a claimed/assigned
  bitmap keyed by player+0x2c4. Seeds: opp-claimed[0]=1 + opp-claimed[keeper.+0x2c4]=1 (keeper =
  *(match-team*800+0x8f4)); our-assigned[0]=1 (GK id 0 never repositioned). **LOOP 1** (0x5b74e1..0x5b763d
  + role-9 trampoline 0x5b860c): role 5/6 -> first UNCLAIMED opp role 9 (copy xyz, x-=iVar21); role 10 ->
  opp role 10; first role 2/3 with sign(P+0x1e4)==sign(match+0x16a4) -> WALL ANCHOR x=+/-(0x8000-
  match+0x1820) [neg iff P.team+0x2b8 != (P.match+0x19a0&1)], y=sign(match+0x16a4)*0x40000, z=0. iVar21 =
  (((match+0x19a0&1)^team)?-0x10000:+0x10000); NO break (every matching opp re-claims). **LOOP 5**
  (0x5b7ba0..0x5b7c66): facing(+0x34/+0x64)=atan(ball-player) [FUN_005ee080] then pairwise (i<j, on-pitch)
  FUN_005ee3f0 min-sep with offset [iVar21,0,0]. **Loops 2-4** (mark-target / nearest-opp ftol / fallback-
  RNG, 0x5b763e..0x5b7ba0) = a loud push_error guard for any on-pitch still-unassigned player (NOT YET
  PORTED). Oracle `run_wall_oracle.sh` drives the REAL phase-4 (two-team layout, relmatrix throttle-skipped,
  atan LUT injected, loop-5 min-sep no-op via far-apart players) -> `specs/wall_oracle.txt` (2 fixtures:
  wall_orient0 [iVar21=+0x10000, anchor not negated] + wall_orient1 [iVar21=-0x10000, anchor negated], both
  CALL 0 RET, P1/P2/P3 xyz hand-verified). Locked by `test_wall.gd` (**18 checks, ALL PASS**). No regression
  (all suites pass; boots 0 SCRIPT ERROR). NEXT = wall loops 2-4 + the phase-5 TAIL, then the phase-7 wall-
  else (match+0x19a0!=4), then the FUN_00598740 driver -> full-match KILL-TEST.
- **Stage 3 task 2 — FUN_005b73a0 slice E (phase-5 TAIL Path C) PORTED + oracle-validated DONE.** ->
  `Pm98Movement._position_phase5_tail` + `_phase5_tail_pathC` (LAB_005b81d6, disasm 0x5b81d6..0x5b8603).
  The tail runs whenever match+0x448==5 (after the wall, or directly when the wall was skipped). Dispatch:
  0x19cc!=0 && 0x45c!=team -> PATH A (defensive insertion-sort, still a loud push_error stub); 0x19cc!=0 &&
  0x45c==team -> no-op; **0x19cc==0 && 0x45c==team -> PATH C (ported).** Path C: for each our player with
  sign(P+0x4) != sign(P+0x3a4) AND FUN_005b0b40(P,0) (goal-side opponent count) <= 1, snap P.x to the team
  set-piece anchor x (*(match-team*800+0x98c)+0x4, modelled ctx["spc_anchor"].+0x4) then FUN_005ee2d0
  (clamp_min_sep) min-sep box 0x93333 vs the taker (match+0x438). No RNG. (Phase 5 reaches Path C only via
  the wall-skipped route -- the wall needs 0x19cc!=0, so a phase-5 wall always implies the tail's Path A.)
  Oracle `run_phase5tail_oracle.sh` drives the REAL tail (faithful _ftol injected @0x252000 so clamp fires;
  relmatrix throttle-skipped) -> `specs/phase5tail_oracle.txt` (1 fixture, 3 players: P0 sign-diff+count0 ->
  x=anchor=0x55000 then clamp -> 0x93333 ; P1 sign-same SKIP ; P2 count==2 SKIP, all CALL 0 RET, hand-
  verified). Locked by `test_phase5tail.gd` (**5 checks, ALL PASS**). No regression (all suites pass; boots
  0 SCRIPT ERROR). NEXT = wall loops 2-4 + phase-5 tail Path A + the phase-7 wall-else (match+0x19a0!=4),
  then the FUN_00598740 driver -> full-match KILL-TEST.

- **Stage 3 task 2 — FUN_005b73a0 slice F (phase-4 wall LOOPS 2-4) PORTED + oracle-validated DONE
  2026-06-19.** -> `Pm98Movement._position_wall` (loops 2-4 replace the loud push_error stub) +
  `_wall_nearest_opp` (disasm 0x5b763e..0x5b7ba0). The three marking loops over players LEFT unassigned by
  loop 1, in order: **LOOP 2** (0x5b763e) assigns by the pre-set mark-target ptr `player+0xb0` (modelled
  `_ref(p,0xb0)`) -> if on-pitch, unassigned, target unclaimed + pos_forward_ok(target): snap onto target,
  x -= iVar21, claim both. **LOOP 3** (0x5b76ea) role NOT in {12,13,14,16,17}: nearest unclaimed
  valid-forward opp within 1000.0 (0x3e80000), snap, x -= iVar21. **LOOP 4** (0x5b78b1) nearest within
  100.0 (0x640000); HIT: snap + x += (flag?+0x10000:-0x10000); MISS: excluded role -> endpoint1
  (player+0x1e0), else goal_target_x + 2-draw RNG jitter (x += +/-rng1*33, y = rng2*80 - 0x140000, z = 0).
  KEY FINDINGS: [esp+0x18] == iVar21 (same compute as loop 1); [esp+0x14] == the opponents {base,count} (=
  ctx["opponents"]); loop 4's FUN_0058fb50(box) + inline sign(opp.x)!=sign(opp+0x3a4) is bit-identical to
  loops 2/3's FUN_005b04e0 (pos_forward_ok), so `_wall_nearest_opp` reuses it for both; flag =
  (player.match+0x19a0 & 1) ^ player+0x2b8; the jitter `(rng*33*128)>>7` and `(rng*5*2048)>>7` reduce to
  trunc-div = rng*33 / rng*80 (exact). Oracle `run_wall234_oracle.sh` drives the REAL phase-4 branch
  (faithful _ftol @0x252000 for the fsqrt distance, loop-5 atan LUT, RNG seed @0x6d3184, relmatrix
  throttle-skipped) -> `specs/wall234_oracle.txt` (8 fixtures: l2_marktarget, l3_nearest x2 orients,
  l4_hit x2 orients, l4_endpoint, l4_goalrng x2 orients; all CALL 0 RET). The goalrng o0/o1 pair
  cross-validates: x = ∓1309367 (goalx ∓ rng1*33=1353), same y=166640 (rng2*80-0x140000). Locked by
  `test_wall234.gd` (**24 checks, ALL PASS**). No regression (all 68 parity suites + test_divisions pass;
  boots 0 SCRIPT ERROR). NEXT = phase-5 tail Path A (insertion-sort) + phase-7 wall-else (match+0x19a0!=4),
  then the FUN_00598740 driver -> full-match KILL-TEST.

- **Stage 3 task 2 — FUN_005b73a0 slice G (phase-7 wall-ELSE) PORTED + oracle-validated DONE 2026-06-19.**
  -> `Pm98Movement._position_phase7_wall` (replaces the loud push_error stub) + const `PHASE7_WALL_ROLES`
  (disasm 0x5b7da9..0x5b7fe5, the match+0x19a0 != 4 branch of phase 7). For each on-pitch non-taker player,
  scan the 11-entry role table `&DAT_00639270` (2 rows x 11 int32, file 0x238070; row = flag = team !=
  match+0x45c) -> FIRST unclaimed entry matching the player role (+0x2c8) snaps it to a wall slot:
  x = +/-(0x109999 - goalXscale), y = +/-(Yscale - trunc(Yscale*(flag+1+2*idx)/11)), z=0; both negated iff
  (orient ^ (1-side)) != 0. The 11-bit claimed bitmap is SHARED across players (each row's roles are
  distinct). Then EVERY eligible player runs the tail: clamp_min_sep off taker (0xa0000); if x ends within
  0x109999 of the goal line, snap x = +/-(goalXscale - 0x110000) (neg iff (orient ^ side) != 0); face the
  ball. KEY: the Yscale*(flag+1+2*idx) product is taken mod 2^32 BEFORE the signed /11 (the binary's 32-bit
  `imul edx,ebp`); a matched player's |x - ivar18| is ALWAYS exactly 0x109999 so the goal-line snap always
  fires. Table extracted: row0 [12,7,8,16,13,9,17,10,18,11,14], row1 [3,11,18,5,15,4,6,8,7,2,0]. Oracle
  `run_phase7wall_oracle.sh` (atan LUT + faithful _ftol; taker a separate struct except taker_p where
  match+0x438 aliases P1 -> skipped) -> `specs/phase7wall_oracle.txt` (4 fixtures: flag0, flag1, orient-bit,
  taker_p; all CALL 0 RET). Locked by `test_phase7wall.gd` (**44 checks, ALL PASS**).

- **Stage 3 task 2 — FUN_005b73a0 slice H (phase-5 tail PATH A) PORTED + oracle-validated DONE 2026-06-19
  — FUN_005b73a0 NOW COMPLETE (every branch ported).** -> `Pm98Movement._phase5_tail_pathA` + `_pathA_memmove`
  (replaces the loud push_error stub; disasm 0x5b8211..0x5b854c, match+0x448==5 && 0x19cc!=0 && 0x45c!=team,
  the defensive follow-up that ALWAYS runs right after the phase-5 wall). Distributes the top-N (N=match+0x19cc)
  on-pitch players into a fan around `anchor = taker_pos + polar_vec(0x93333, taker_facing)`. PASS 1 (every
  on-pitch player): clamp off taker (0xa0000), reflect through taker (p = 2*taker - p) if outside the pitch box
  [+0x1828..+0x183c], face the ball, insertion-sort by role CLASS (role<=6->0; {7,8,10,11,15,18}->1; else 2)
  into N slots. PASS 2 (each filled slot s): set_position_code(0x1c) + anchor + polar_vec(radius_s,
  taker_facing+0x4000), radius_s = ftol((s*0.45 - N*0.225) * 65536); face the ball. **KEY QUIRK reproduced:**
  the insertion memmove (ds:0x6233d4) shifts only the POINTER slots, NOT the parallel priority slots, so the
  priority bytes go stale and reorder later inserts -- modelled with a flat 13-int array + an exact backward-copy
  memmove (players stored as 0x10000000+index so a stale slot-pointer never compares < a 0..2 class, matching
  the binary's large positive struct pointers). Oracle `run_pathA_oracle.sh` runs the REAL wall+tail (the wall
  fires first under the same entry condition; all players EXCLUDED roles so the wall is RNG-free -> endpoint1;
  atan/cos LUT + faithful _ftol + an injected backward-copy memmove at 0x253000 overriding ds:0x6233d4) ->
  `specs/pathA_oracle.txt` (2 fixtures, N=2 + N=4; all CALL 0 RET). **EMULATOR CAVEAT:** only EVEN N is banked
  -- radius = ftol(14745.6*(2*slot - N)), so even N keeps every radius off the .5 truncation boundary. The port
  truncates toward zero (the real x87 _ftol, per Pm98Trig); the PCode emulator's `fist` round-to-nearests at .5
  (ignoring the injected truncate control word), so an ODD-N radius like -44236.8 banks the emulator's -44237
  artifact instead of the real binary's -44236. Locked by `test_pathA.gd` (**40 checks, ALL PASS**). No
  regression (all 70 parity suites + test_divisions pass; boots 0 SCRIPT ERROR). NEXT (superseded) = the
  FUN_00598740 driver. **REVISED 2026-06-19 (see MATCH_TICK_DRIVER_MAP.md):** the driver's 4 sub-entity
  vtable calls were mis-mapped as render; the corrected delta (0x401200) shows they are the BALL + 2 GKs +
  referee, and the ball physics FUN_0058e2c0 + GK FUN_005a22d0 must be ported BEFORE the driver.

- **Stage 3 task 2 — ball ADVANCE FUN_0058e2c0 SLICE A (timers + lerp-to-target) PORTED + oracle-validated
  DONE 2026-06-19.** -> `Pm98Movement.ball_advance` + `_ball_step` (+ `_ball_freeflight` loud stub for the
  unported branches). This is vtable+0xc on match+0x1610 (the ball; `get_ball` FUN_005b70b0 returns it),
  the per-tick ball model the FUN_00598740 driver runs once per tick. disasm 0x58e2c0..0x58e357:
  **timers** (every call) +0x58 = +0x54, then decrement +0x5c/+0x70/+0x68 each iff != 0; **lerp** iff
  (post-decrement) +0x68 == 0 AND +0x6c != 0: N = ORIGINAL +0x6c; +0x6c -= 1; pos[axis] +=
  (target[axis]-pos[axis]) / N with x86 idiv (truncate toward zero), target = +0x9c/+0xa0/+0xa4,
  pos = +0x4/+0x8/+0xc. The set-piece ball-placement glide. **NOT ported (slice B+):** the free-flight
  branch (pos+vel, gravity DAT_0066c1b0, ground bounce with FUN_005edfa0 damping, goal/post collision
  FUN_005efac0, spin) and the shared FUN_0058fda0 trail tail + 0x58eb9a facing -- the tail writes only
  +0x34/+0x74+/+0x84+, none of which slice A reads, so it is correctly omitted. Oracle
  `run_balladvance_oracle.sh` drives the REAL FUN_0058e2c0 to a clean RET (the lerp path never derefs the
  match; faithful _ftol injected for the tail's atan/polar; velocity +0x20 != 0 so the 0x58ebb1 epilogue
  takes je->ret and leaves pos intact) -> `specs/balladvance_oracle.txt` (4 fixtures: lerp_pos, lerp_neg
  [the truncate-toward-zero witness: -1398101, not floor -1398102], lerp_n1 [N=1 exact arrival], lerp_guard
  [0-timers stay 0; negative target axis]; all CALL 0 RET). Locked by `test_balladvance.gd` (**32 checks,
  ALL PASS**). No regression (71 parity suites + test_divisions pass; boots 0 SCRIPT ERROR). NEXT = ball
  slice B (free-flight + gravity + ground bounce), then the collision loop, spin, and the FUN_0058fda0 tail;
  then GK FUN_005a22d0; then the FUN_00598740 driver -> full-match KILL-TEST.
- **Stage 3 task 2 — ball ADVANCE FUN_0058e2c0 SLICE B (free-flight: integration + gravity + bounce/roll)
  PORTED + oracle-validated DONE 2026-06-19.** -> `Pm98Movement._ball_freeflight` (replaces the loud stub).
  The branch taken when NOT lerp ((post-dec) +0x68 != 0 OR +0x6c == 0). disasm:
  - **held gate** 0x58e35c: byte ball+0x63 set -> jmp tail, no motion.
  - **integration** 0x58e974..0x58e993: pos(+0x4/+0x8/+0xc) += vel(+0x20/+0x24/+0x28). (The prologue's
    swept-bbox build temporarily does pos.z += 0x23d7 @0x58e437 and undoes it @0x58e96c when collision is
    skipped, so the net z change is just the integration -- modelled directly.)
  - **bounce** 0x58ea48 iff post-int pos.z<0 OR (pos.z==0 && vel.z<0): pos.z=0; vel.x,vel.y =
    mul16(.,0xc51e) (FUN_005edfa0==Pm98Trig.mul16, ~0.770); vel.z = -mul16(vel.z,0x9c28) (~0.610); then
    |vel.z| < 0x28f -> vel.z = 0 (settle).
  - **gravity** 0x58ea1c iff post-int pos.z>0 OR (pos.z==0 && vel.z>0): vel += DAT_0066c1b0/b4/b8 = [0,0,-178]
    (set once by FUN_0058e030 @0x58e030; poked in the oracle).
  - **roll** 0x58e9b6 iff pos.z==0 && vel.z==0: |vel.x|<0x22 && |vel.y|<0x22 -> vel=[0,0,0]; else vel -=
    polar_vec(0x22, atan_angle(vel.x,vel.y)) (FUN_005ee0f0/FUN_005ee080 == Pm98Trig leaves, real cos/atan LUT).
  **DEFERRED to a later slice (all kept inert by the oracle):** the goal/post collision sweep
  0x58e497..0x58e963 (gated off by match+0x5fac==0 and post-count match+0x17f8==0, both 0 in the zeroed
  match); the spin 0x58eb09 (writes +0x2c/+0x30 only; FUN_005ee500 reads vel only) + trail/facing tail
  0x58eb93 (writes +0x34/+0x74/+0xa8); and the bounce's match+0x462 bit-clears, bounce sound, and ball
  +0x61/+0x64 anim-flag bytes -- none touch pos/vel, which read clean for every fixture. Oracle
  `run_balladvance_oracle.sh` extended (+gravity pokes, +cos/atan LUT via emit_lut_membts.py, +vel reads):
  6 new fixtures fb_gravity / fb_bounce / fb_settle / fb_rollstop / fb_rollfric / fb_held, all CALL 0 RET.
  Locked by `test_balladvance.gd` (**110 checks, ALL PASS**, was 32). No regression (71 parity suites +
  test_divisions pass; boots 0 SCRIPT ERROR). NEXT in this fn = the goal/post collision loop
  (FUN_005f3b80 goal sweep + FUN_00590b30/FUN_005efac0 post resolve), then spin + the FUN_0058fda0 tail;
  then GK FUN_005a22d0; then the FUN_00598740 driver -> full-match KILL-TEST.
- **Stage 3 task 2 — ball collision box leaves (FUN_00590b10 + FUN_00590b30) PORTED + oracle-validated
  DONE 2026-06-19.** -> `Pm98Movement.box_add3` / `Pm98Movement.boxes_overlap`, the first two leaves of
  the goal/post collision loop (the next FUN_0058e2c0 slice). Both pure integer, no RNG/LUT/ftol/sub-calls:
  - **FUN_00590b10**(this=v3; s): adds s to three consecutive int32 (a swept-box corner pushed out by the
    0x23d7 ball radius). Each axis wraps to int32.
  - **FUN_00590b30**(this=A; B): STRICT AABB overlap of two `[minx,miny,minz,maxx,maxy,maxz]` boxes -- 1 iff
    on every axis `max(A.min,B.min) < min(A.max,B.max)`; a touching edge (`lo == hi`) returns 0. The
    broad-phase gate the post loop runs (0x58e65b) before the per-post narrow collision.
  Oracle `run_collbox_oracle.sh` -> `specs/collbox_oracle.txt` (10 fixtures, all CALL 0 RET: 3 add incl.
  neg + int32-wrap; 7 overlap incl. all three touching-edge cases + B-inside-A + negative-min signed cmp).
  Locked by `test_collbox.gd` (**16 checks, ALL PASS**). No regression (full parity suite + test_divisions
  pass; boots 0 SCRIPT ERROR).
  **CORRECTION (verified vs the codebase, not re-discovered): the goal-scoring call inside this loop --
  FUN_005909f0 at 0x58e832 + its enqueue FUN_00594470 -- is ALREADY ported** as `Pm98Events.keeper_event`
  + `Pm98Events.enqueue` (the event-queue slice, oracle `run_event_oracle.sh`, test_events.gd). The loop
  wiring will CALL those, not re-port them. So the genuinely-remaining collision work = FUN_005f3b80 (goal
  swept-sphere vs goal-mouth box) + FUN_005efac0 (post narrow-phase swept collision + velocity reflect) +
  the loop control flow (0x58e497..0x58e963); the net-ripple FUN_00590f00 / per-post sound FUN_005babe0 are
  render/audio (skip headless). THEN spin + the FUN_0058fda0 trail tail; then GK FUN_005a22d0; then the
  FUN_00598740 driver -> full-match KILL-TEST.

### FUN_005a3400 DECODED STRUCTURE (the per-player DECIDE; decoded 2026-06-18 -- cite, don't re-derive)
`__fastcall(ECX=player)`. The per-player movement-target / set-piece-positioning computer. **NO net
RNG**: the only RNG touch is `s=FUN_005ec240()` (GET state @0x6d3184) ... `FUN_004e9630` ...
`FUN_005ec230(s)` (SET state back) -- a save/restore bracket that DISCARDS any draw, so the seed is
unchanged (FUN_005ec230=`DAT_006d3184=x`, FUN_005ec240=`return DAT_006d3184`). Two top-level gates:
- **`DAT_006d31c4`** (the replay global; the SAME family as FUN_005a4560/FUN_005ed870; **0 in
  headless**): when `!= 0`, the function copies player pos/vel from the +0x38 replay buffer -- the
  REPLAY path, **OUT OF SCOPE**. When `== 0` (our case) it runs the real compute below.
- **`DAT_006d31c4` also gates FUN_005ed870** (called at the top): in headless it just does
  `FUN_005bbf10(player+0x38,0)` (queue-grow) + `player+0x3c=0` -- replay-buffer housekeeping, no
  movement effect. Treat as a no-op for parity (document the +0x38/+0x3c buffer as out-of-scope).
Real-compute structure (DAT_006d31c4==0):
1. **Prologue + bbox (decomp lines ~45-146):** set `player+0x3a4` = ±match+0x1820 (goal X by side).
   Branch on the on-pitch flag `player+0x2bc`: off-pitch -> a default target box from match+0x1820 /
   const 0x108000 oriented by side; on-pitch -> `mirror_to_side` x2 (player+0x1f8,+0x204 ->
   player+0x1e0..+500) + compose/planar from player+0x228/+0x230. Copy the 6-int target to
   player+0x210; seed bbox player+0x218=0xffff0000 / +0x224=0x12c0000; then 12 min/max clamps build
   the bbox `player+0x210..+0x224` from +0x1e0..+500 and +0x1ec..+500.
2. **Field reset + facing + position (lines ~147-177): PORTED `decide_slice_b`, oracle-pinned.** zero
   player +0x3b4/+0x48/+0x90/+0x54/+0x58/+0x68/+0x6c/+0x20/+0x24/+0x28/+4/+8/+0xc (disasm-verified:
   +0x20/+0x24/+0x28 only, NOT +0x2c/+0x30); facing `player+0x34 & +0x64` = `(((orient&1)^team) ? 0x8000
   : 0)` (180deg if defending the opposite side); `player+0xb0` from the team-struct table
   `*(player+0x188 + 0x13c + player+0x2cc*4)` (0 when +0x2cc < 0), `player+0x61=1` if nonzero (SET only,
   never cleared); `FUN_005a5430(player+0x2bc==0 ? 0x1e : 0)` (PORTED `set_position_code`; neither code
   remaps so +0x2c/+0x30 stay). The +0x188 +0x13c table is modelled as a `_ref(p, 0x188)` struct field.
3. **Set-piece switch on `match+0x448` (lines ~179-end):** cases 2 / 3 / 4+5 / default. Each branches
   on "am I the designated taker" (`player == match+0x438`). The taker path: stamina `player+0x48 =
   (taker-flag ? 0x2d0 : 0) + 0xb4` (taker-flag = teaminfo(+0x184)+0x2ee set AND phase0 via 5943b0
   AND player+0x5c), `FUN_005a5430(case-specific pos: 0/0x13/0x1d)`, then aim at the ball/spot using
   the ported leaves (590aa0/590ae0/5ee080/5ee0f0/5ee2d0/5b12c0) + goal_target_x. Non-taker paths set
   the move target from the bbox / a defensive spot. `FUN_0058eca0(player)` sets engagement
   (player+0x44/+0x48/+0x4c/+0x54/+0x80 + a match counter) -- PORTED as
   `Pm98Movement.set_engagement`, DONE.
**Sim-mutations** (the port must write all): player +0x4/+8/+0xc (move target), +0x20..+0x30,
+0x34/+0x64 (facing s16), +0x40 (pos), +0x48, +0x54/+0x58, +0x61, +0x68/+0x6c, +0x80, +0x90, +0xb0,
+0x1e0..+0x224 (target + bbox), +0x3a4, +0x3b4. **Slice plan:** (A) prologue+bbox = DONE
(`decide_slice_a`, oracle-pinned via the replay path); (B) reset+facing+pos (deps FUN_005a5430 +
POS_REMAP_LUT DONE; the player+0x188 +0x13c table is modelled as a `_ref(p, 0x188)` struct -- DONE,
`decide_slice_b`, oracle-pinned via the switch-default RET); (C) the switch case-by-case
(dep FUN_0058eca0 DONE). Slices A+B wired; C remains.
**Oracle:** slice A used the REPLAY path (DAT_006d31c4!=0) for a clean RET with no stubs/LUT. Slices
B/C run real callees: set up a player struct + match struct + teaminfo; stub FUN_005bbf10 (queue-grow)
as the 5b8f20 oracle did; inject ftol + cos/atan LUT; read back the mutated player fields.

### MOVEMENT-AI SUBSYSTEM MAP (decoded 2026-06-18 -- cite, don't re-derive)
The driver calls, per team per tick (4 call-sites 0x593f38 / 0x598955 / 0x5a1433 / 0x5a1530, each
a `5b70e0; 5b73a0` pair; the 5b8bf0/5b8c20 vtable loops are driven from 0x598b35..0x598baa):
- **`FUN_005b70e0`** (692B, NO direct RNG): per-team shell. Resets role slots ctx+0x1fc/+0x200/
  +0x2dc; loops players calling vtable[+4]; a phase-2-only "nearest on-pitch player to the special
  point match+0x16a0/+0x16a4/+0x16a8" assignment (uses FUN_00590aa0 vec-store + FUN_005b1260 mag +
  atan); resets the relmatrix tick ctx+0x2e0 to -1 + calls `_select_roles` (FUN_005b8a60, DONE).
- **`FUN_005b73a0`** (4834B, **7 RNG draws** + C++ exception frames): per-team shell. Calls
  build_relationship_matrix (FUN_005b8690, DONE) then the big set-piece/positioning logic. The
  ONLY seed-parity-critical RNG in movement lives here -- the oracle MUST trace 0x5ec250 to pin
  the draw order. Slice it (set-piece queue build / per-player positioning / the RNG tail).
- **player vtable A @0x639224** (set in the ctor near 0x5b6e19): [+0]=0x5ed810 (dtor),
  **[+4]=`FUN_005a5460`** (4404B -- NOT "small"; the plan's earlier note was WRONG) = the per-player
  match-VIEW overlay updater (sprintf player name + sprite/text draws via 0x51fd00/5f33xx/5f34xx +
  fills the match render buffer at match+0x29b0..+0x2a10). **PARITY NO-OP, verified 2026-06-18:**
  (1) its ENTIRE body is gated by `match+0x5fac != 0`; (2) `+0x5fac` has exactly ONE writer in the
  whole binary -- the match ctor at 0x591524, which stores ebx, and ebx is `xor ebx,ebx` (the zero
  reg used to clear ~7 adjacent init fields) -> `+0x5fac` is ALWAYS 0, so the body NEVER runs; and
  (3) even if it ran it writes NO sim state (no writes to the player param_1, the ball, or any
  match-sim field -- only the +0x29b0 render region + local draw lists). So FUN_005b70e0's
  per-player vtable[+4] loop is a no-op for the event-stream/scoreline kill-test. DON'T PORT (the
  vtable[+4] analogue of the vtable[+0xc] FUN_005a4560 replay no-op). Decompile docs/re/move/.
  **[+8]=`FUN_005a3400`** (~1309 insns -- the per-player DECIDE / the AI bulk; driven by the
  FUN_005b8bf0 vtable[+8] loop; calls 590aa0/590ae0/5943b0(DONE)/5ee080(DONE)/5ee0f0(DONE)/5ee2d0/
  5b11f0/5b12c0(=planar_mag,DONE)/5bbf10(queue grow)/5ec230+5ec240(RNG save/restore, net-zero like
  the dispatcher)/5ed870/...; NO net RNG draw),
  **[+0xc]=`FUN_005a4560`** (~70 insns -- replay/record SAVE-STATE; copies 0x51 dwords of player
  state to/from a history buffer at player+0x3b0, gated by globals 0x6d31bc/0x6d31c4/0x665d8c that
  are 0 in headless play -> **NO effect on event-stream/scoreline parity; treat as out-of-scope**).
- **Leaf inventory still to port** (mostly pure): 005b11f0/005b12c0, 005b04e0/005b0b40, 005a5430,
  005a44f0/005a4510. **DONE:** FUN_005b1260 (planar_mag); 00590aa0 (vec3_store) + 00590ae0
  (vec3_sub) + 005ee290 (vec3_scale_ratio) + 005ee2d0 (clamp_min_sep) + 005ee3f0 (mid_offset),
  all in `Pm98Trig.gd`, oracle-pinned by run_moveleaf_oracle.sh. FUN_005ee080 (atan_angle) +
  FUN_005ee0f0 (polar_vec) also DONE.
- **Suggested slice order:** the small leaves DONE; FUN_005a5460 (vtable[+4]) = parity-no-op (DON'T
  port, see above) -> FUN_005a3400 (the decide bulk, biggest single piece, ~1309 insns) ->
  FUN_005b70e0 shell -> FUN_005b73a0 (RNG-order critical) -> driver 0x598740. Both vtable[+4]
  FUN_005a5460 AND vtable[+0xc] FUN_005a4560 are parity-no-ops (view/replay overlays).
- **NEXT = Stage 3 task 2 (driver + the rest of movement physics).** Predicates + event-queue + dispatcher +
  the nearest-to-ball selector + the relationship matrix/roles + the marking-target leaf + the marker-assignment PASS are now ported. The 38 movement decompiles are extracted to
  `docs/re/move/` (largest: player-move/AI `0x5b73a0` 4834B, phase-selector `0x5b8f20` 1169B, relationship-
  matrix `0x5b8690` 964B, marker-assign `0x5b94f0` 631B, `0x5b36f0` 788B, player-move `0x5b70e0` 692B). Driver
  `00598740` (904-line C dump) + `005983f0`/`00598690` + the movement physics 2 levels down (callees
  `0x5a1820` (5x), `0x5b94f0` (marker-assign, DONE-adjacent), `0x5b8c20`/`0x5b8bf0` (vtable dispatch loops),
  `0x5b8690` (relationship matrix), `0x5b8f20` (phase selector, calls the now-ported `0x5b8ce0` as fallback),
  the two player-move fns `0x5b70e0`/`0x5b73a0`, and `0x5b6ee0` from 005983f0 -- all in `docs/re/move/`) --
  real ball coordinates come from the `Pm98Trig` LUT. Suggested next bottom-up order: `0x5b8690` (matrix) DONE ->
  `0x5b36f0` (mark-target leaf) DONE -> `0x5b94f0` (marker-assignment PASS) DONE ->
  `0x5b8f20` (phase selector) DONE -- gate/6/4/else (slice 5a) + phase 2 + phase 5/7 queue (slice 5b),
  ALL 5 branches oracle-pinned. NEXT bottom-up: the two player-move/AI fns `0x5b70e0` (692B) +
  `0x5b73a0` (4834B, WATCH RNG call order), then the driver `00598740`. The
  dispatcher (`005966d0`) it calls is DONE. Inject
  the LUT for the movement oracle via `tools/re/emit_lut_membts.py` (same trick `run_keeper_oracle.sh` /
  `run_dispatch_oracle.sh` use). **KILL-TEST** for task 2 = full-match event-stream parity (fixed seed +
  fixed squads -> identical event stream + scoreline, N>=50).

- **Stage 3 task 2 — driver leaves batch 2 (4 PURE leaves of FUN_00598740) PORTED + oracle-validated
  DONE 2026-06-22.** -> `Pm98Movement.vec3_set` (FUN_00590aa0, 3-scalar store), `play_state_eq`
  (FUN_005943b0/f0/d0 = `match+0x468->+0xfa0 == {0,2,4}`; `_phase0` now delegates), `clamp_x_goalside`
  (FUN_0059a1e0, clamp vec.x toward the goal by a 0..50 factor; product wraps i32 before truncating /50),
  `restart_box_ok` (FUN_0059a120 = the SAME-side `==` twin of pos_forward_ok FUN_005b04e0). Oracle
  `run_driverleaf2_oracle.sh` -> `specs/driverleaf2_oracle.txt` (12 fixtures: vec_set; ps_eq{0T,0F,2T,4T}
  [EAX masked &0xff -- the binary leaves CONCAT31 junk = session_ptr>>8 in the upper bytes, caller reads AL];
  clamp_{neg,pos,no} [hand-verified 648806 / -648806 / unchanged]; rb_{same_T,oppside_F,shallow_F,outbox_F]).
  Locked by `test_driverleaf2.gd` (**14 checks, ALL PASS**). No regression (82 suites + test_divisions pass;
  boots 0 SCRIPT ERROR). **With FUN_0058f0b0 (done earlier) this completes the driver's PURE leaf set.**
  Read the full FUN_00598740 body + banked the sim skeleton + RNG-draw inventory in MATCH_TICK_DRIVER_MAP.md
  ("Driver body decode 2026-06-22"). **KEY FINDING (corrects match_engine_re.md):** the driver's per-tick
  commentary/event TIMERS (+0x19e4/+0x19e8/+0x19ec, decompile L747-L844) use UNBRACKETED FUN_005ec250 ->
  they DO advance the match seed (not only dispatcher case 2/6); a bit-exact full-match port must reproduce
  them. **STEP-2 remaining (multi-session): (a) port FUN_0058f3c0 (last open-play predicate) + classify
  FUN_00593b70; (b) port the driver shell FUN_00598740 -> new Pm98Driver.gd; (c) port match-init
  FUN_00591180 (the 22-player match object -- NOT yet ported, blocks the full-match loop); (d) stand up the
  wine OR full-emu end-to-end oracle; (e) the N>=50 fixed-seed event-stream + scoreline KILL-TEST.**

## Already decoded — cite + port, don't redo (see match_engine_re.md for detail)
- RNG `FUN_005ec250` (MSVC LCG, state @0x6d3184) — already exact as `Pm98Rng`. Per-mil idiom
  `(roll*1000)>>15 < permil`. Commentary rolls bracketed by `005ec240/005ec230` (replicate).
- Event queue (`match+0x1a24..+0x1a30`, 16-byte events), enqueue `00594470`, dequeue `00594570`.
- Event enum (3/4/5/7/8/9/0xa/0xb/0xc/0xd/0x10-0x17) — commentary switch `00539140`.
- Scoring path: driver `00598740` (+`005983f0`,`00598690`) → predicates
  `0058ede0/0058f100/0058fbe0/0058f140` → resolver `005aeda0` → dispatcher `005966d0` → enqueue.
  C dumps in `docs/re/{sim,goal}/`. Finishing gate: permil from `player+0x398`,
  `(ATTR<55)?(ATTR/3)*9:(ATTR-25)*9`; second `<600` gate splits on/off-target.
- Match setup `005923f0` (squad load; callees in `sim/callgraph.txt`). Player fields:
  `+0x384` skill, `+0x398` finishing, `+0x40` pos(9=fwd,+20), `+0x60` engaged, `+0x18c`→match.

## Gaps to close (the work)
- **A. Positional movement physics (bulk).** Enumerate the per-tick callees of `00598740`
  (the 22-player + ball advance/AI) over `.text 0x58e000-0x5b4000`; decompile each
  (`ghidra_scripts/DecompileAt.java`); port to GDScript in **integer fixed-point** (`0x10000`
  = 1 unit) with **exact RNG call order**. Port the 9 event-generators (`58e2c0 58f3c0 5909f0
  5966d0 5a50c0 5a7260 5ab5a0 5aeda0 5b41c0`).
- **B. Tactics→sim coupling.** Find the tactics struct: grep ma_9 strings ("ATTACKING PLAY",
  "TACKLING", "MARKING", "PRESSURISE FROM", "COUNTER ATTACK", "LONG BALL") via
  `strings_xref.py`, xref store sites (`FindWordStore.java`) → per-club tactics offsets; find
  read sites in the sim (`FindFieldUsers.java`) → which behavior thresholds they modify; port,
  then replace the `Tactics.gd` `_*_FACTOR` multipliers + `ratings()` math. Keep the modal UI.
- **C. Attribute mapping.** Map `game_db` attr codes (EN/VE/RE/AG/CA/RM/RG/PA/TI/PO) → sim
  player-struct offsets, confirmed via `005923f0` squad→match-player copy.

## Oracle (build FIRST) — definition of "exact"
1. Ghidra PCode emulation (headless): execute a decoded fn on chosen inputs, capture output +
   RNG-state; assert GDScript matches per-function, then per-match. Preferred (no GUI).
2. wine end-to-end: seed @0x6d3184, run a fixture, read result struct `+0x38`/`+0x3a` via
   winedbg; compare. Heavier; confirms the full chain.
- **KILL-TEST:** fixed seed + fixed squads → IDENTICAL event stream + scoreline vs the
  original across N>=50 fixtures. Below that bar it is still a reconstruction; label honestly.

## Stages (commit + validate each)
1. Oracle harness + 1-fn parity (`005aeda0`). 2. Resolver+dispatcher+predicates exact.
3. Driver + movement (full-match event-stream parity = big kill-test). 4. Setup + attr map.
5. Tactics coupling (replace Tactics.gd model; per-lever oracle diff). 6. Swap engine into
`MatchEngine.simulate`, refactor ratings callers, replace calibrated-window asserts with
exact-parity asserts, boot+grep SCRIPT ERROR.

## Tooling (present 2026-06-17)
Ghidra 12.1.2 `~/ghidra_12.1.2_PUBLIC` + project `~/ghidra-projects/pm98.rep` +
`tools/re/ghidra_scripts/*.java`; `objdump`, `wine`, python `capstone` 5.0.7. No radare2.
DATSIM.PKF = match-VIEW art (per `match_view_re.md`), NOT sim math — confirm before chasing.
