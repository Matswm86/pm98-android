# PM98 — EXACT match-engine + tactics port plan

Goal: replace the **calibrated** model in `app/scripts/MatchEngine.gd` and the **ours**
att/def lever model in `app/scripts/Tactics.gd` with FAITHFUL ports of the real
`MANAGER.EXE` positional simulation + its tactics coupling, validated bit-for-bit.
Read `match_engine_re.md` first (the decoded ground truth). This doc is the work plan.

Legit RE of the owner's own binary for the owner's own remake. Deliverable = original
GDScript reproducing the decoded algorithm, not redistribution of the binary.

## STATUS (2026-06-18)
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
2. **Field reset + facing + position (lines ~147-177):** zero player +0x3b4/+0x48/+0x90/+0x54/+0x58/
   +0x68/+0x6c/+0x20..+0xc/+4/+8; facing `player+0x34 & +0x64` = `(side ? 0x8000 : 0)` (180deg if
   away); `player+0xb0` from a table (match+0x188 +0x13c + player+0x2cc*4), `player+0x61=1` if
   nonzero; `FUN_005a5430(player+0x2bc==0 ? 0x1e : 0)` (set position code -- PORTED as
   `Pm98Movement.set_position_code`; LUT &DAT_00665208 extracted into POS_REMAP_LUT, DONE).
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
+0x1e0..+0x224 (target + bbox), +0x3a4, +0x3b4. **Slice plan:** (A) prologue+bbox; (B) reset+facing+
pos (deps FUN_005a5430 + POS_REMAP_LUT now DONE); (C) the switch case-by-case (dep FUN_0058eca0 now
DONE). Both slice-B and slice-C state-setter dependencies are ported; A/B/C remain to wire into 5a3400.
**Oracle:** set up a player struct + match struct + teaminfo; stub FUN_005bbf10 (queue-grow) as the
5b8f20 oracle did; inject ftol + cos/atan LUT; read back the mutated player fields.

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
