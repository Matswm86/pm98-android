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
- **Stage 3 task 3 (3 of 4 scoring predicates PORTED + oracle-validated) DONE.** `FUN_0058ede0`
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
- **NEXT = Stage 3 task 2 (driver + movement) + the last predicate `FUN_0058f140` (keeper-reach save).**
  Driver `00598740` (904-line C dump) + `005983f0`/`00598690` + the movement physics 2 levels down
  (callees `0x5a1820`, `0x59a120`, the `0x5b7xxx/0x5b8xxx/0x5b9xxx` player-AI cluster) -- real ball
  coordinates come from the `Pm98Trig` LUT. The dispatcher `005966d0` (outcome 1-7 -> event enqueue,
  353-line, entangled with display flag 0x180b + language tables). `FUN_0058f140` (keeper save) was
  deferred from this increment: deepest entanglement (keeper struct, `atan_angle` geometry, the 6-int
  box helpers `00590ba0/be0`, the 0x15/0x16 enqueue via `005909f0`, the DAT_006d31c4 branch) -- port
  next with the LUT injected (`tools/re/emit_lut_membts.py`). **KILL-TEST** for task 2 = full-match
  event-stream parity (fixed seed + fixed squads -> identical event stream + scoreline, N>=50).

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
