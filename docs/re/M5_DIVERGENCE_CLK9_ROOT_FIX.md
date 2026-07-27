# M5 clk-9 extra draw — ROOT CAUSE FOUND + FIXED: the dead B0040 designated-interceptor route (s30, 2026-07-11)

Evidence: tools/re/wine/m5_clk9_analyze.py, app/tests/test_decideset.gd, app/scripts/Pm98Action.gd
  -- the analyser that localised clk 9, and the suite + leaf the fix landed in.

Executes the NEXT of `M5_CLK9_CANDIDATE2_REFUTED.md` (s29). The s29 plan was "single-step the
gate-4 g0 chain at clk 9"; doing that (new `app/tests/diag_m5_g0chain.gd` + a gated
`Pm98Movement.lean_trace` hook) proved the g0 chain is NOT the bug — and the position evidence
in the s29 wide-q capture then refuted **candidate 1 as well**. The real root is a dead code
path: `formation_gate_b1420`'s B0040 designated-interceptor route could never fire because the
port compared a player Dict against an int index with `is_same`. Fixed; the port's per-clk RNG
seed now matches the reference **through clk 46** (was clk 8).

## Finding 1 — candidate 1 ("reference engages at clk 9") is REFUTED too

From the s29 wide-q capture (`m5_clk9_wideq_2026-07-11/clk9_timeline.jsonl`):

- Ref clk-10 ball = `(-12195,-46615)` = clk-8 ball + one full clk-8-vel physics step, then
  vel=(0,0,0), `b40 = V8`. An engage during clk 9's player pass would have zeroed vel at clk 9
  (slice C L549-552) and frozen the ball at `(-11016,-42102)` — the ball's own advance runs
  AFTER the players. It did not freeze → **the reference receiver did NOT take control at clk 9**.
- Ref clk-10/11 receiver t0.i8 pos + act are BIT-IDENTICAL to the port's. **Both engines engage
  at clk 10.** The port's gate-4 g0[0]=46411 fail at clk 9 is CORRECT (verified by
  `diag_m5_g0chain.gd`: traj slot 0 == ball current pos; g0 recomputes exactly; at-lean inputs
  == the binary's).

## Finding 2 — the s28 "bit-identical at clk-8-end (every player position)" claim is FALSE

`app/tests/diag_m5_posdiff.gd` vs the wide-q `pl` tables: 9-13 of 22 players differ from
**clk 0 END** onward (tens of units, growing; act-code splits like t1.i3 act=0 FROZEN at
(2689965,-345555) in the reference forever vs walking act=1/2 in the port). The near-ball core
(ball, receiver t0.i8, taker) IS exact. s28 verified RNG + ball and extrapolated the roster —
wrongly. Equal per-clk seeds prove equal draw COUNTS, not equal draw call-sites, and not
positions. This residual roster drift is the NEXT divergence class (see NEXT).

## Finding 3 — the root: `is_same(int, Dictionary)` killed the B0040 route

`fn_005b1420_FUN_005b1420.c` L33-37:
```c
if ((param_1 == *(int *)(*(int *)(param_1 + 0x184) + 0x204)) &&   // p == gs+0x204 (POINTER)
   (*(int *)(*(int *)(param_1 + 400) + 0x40) == 0)) {              // no carrier
    FUN_005b0040();  return 1;                                     // draws NOTHING
}
if (ball+0x54 != p+0x2b8) return FUN_005b1500();                   // press path (the roll)
```

The port's `_select_roles` (FUN_005b8a60) writes `ctx[0x204]` = nearest-to-ball as an **int
index** (the port's pointer model), but `formation_gate_b1420` checked
`is_same(gs.get(0x204), p)` — int vs Dict, never true → **B0040 unreachable**, every designated
player fell through to b1500/b1c80.

The kill sequence (all from `diag_m5_posdiff.gd` designations + the LCG):
- clk ≤ 8: Bolton `0x204` = t1.i9 → t1.i8 (the presser marking the receiver) correctly runs
  b1500's press arm (`ball+0x4c == mk`) → `3c90(0,0x29999)` roll → 3 draws/clk, matches ref.
  (i9's own route change is draw-neutral: B0040 draws nothing; its b1500 shadow arm drew
  nothing either — press false for i9, carrier null.)
- clk 9: Bolton `0x204` flips **i9 → i8** (the ball's approach makes i8 the nearest Bolton
  unit; margin ~50k ≫ the roster drift). Binary: i8 takes **B0040 → no press roll → 2 draws**.
  Port (bug): i8 still pressed → the extra draw. This was the whole s22→s29 hunt.
- clk 10+: carrier V8 ≠ 0 disables the B0040 route → i8 falls to b1500's carrier-marked arm
  (`is_same(carrier, mk)` → the 0x333 aggression roll) → 3 draws, matches ref again.

Two sibling instances of the same type bug fixed in the same pass (both dead code until now):
b1500's tail override `gs+0x200` read (`desig is Dictionary` — never) and the carrier-arm
aggression `desig_me = is_same(gs.get(0x200), p)`.

Plus one latent crash the fix exposed: b1420's no-carrier test was `carrier == null or
carrier == 0` — GDScript throws "Invalid operands 'Dictionary' and 'int'" once carrier is an
engaged Dict. Now `not (carrier is Dictionary)` (the binary's pointer-null test).

## The fix (Pm98Movement.gd)

- New `_desig(gs, off)` resolver: role slots +0x1fc/+0x200/+0x204 hold indices (-1/absent =
  none; a fixture-poked Dict passes through) → resolve via the ctx roster BEFORE any
  `p == *(gs+off)` pointer compare.
- `formation_gate_b1420`: `is_same(_desig(gs, 0x204), p) and not (carrier is Dictionary)`.
- `offball_opp_b1500`: both `gs+0x200` reads now `_desig(gs, 0x200)`.
- Diag tooling: `diag_m5_g0chain.gd` (at-lean input capture via the new gated
  `Pm98Movement.lean_trace` hook), `diag_m5_posdiff.gd` (roster diff vs the wide-q `pl`
  tables), `diag_m5_seedtrace.gd` (per-clk end-seed trace).

## Validation

- Per-clk seed vs capture2 **Pass 0** (its timeline is ALSO two concatenated passes — split on
  clk going backwards, anchor-check 7/8/10 before diffing; the same trap as s28 Finding 0):
  **MATCH clk 0..46**, first divergence clk 47 (was: clk 9). clk 9 = 1174984409, clk 10 =
  1266482802, clk 11/12 exact — the s28 experimental skip's numbers, now reached faithfully.
- Wide-q positions: t1.i8 now bit-exact at clk 10/11; t1.i9 re-converges (Δ=10 at clk 11).
- Oracle suites all GREEN: test_b1420 (16), test_b1500family (589), test_65a0openplay (760),
  test_engine_tick (182), test_9490sliceB (111), test_9490 (211), test_9490sliceC (171),
  test_ballpredict (336).
- Do-not-repeat notes: `rtk`-style greps on `docs/re/**.c` for `+ 0x54) =` / `+ 0x4c) =`
  found every writer; the frame-0 import DOES carry every player dword (`dwords["0x54"]`),
  so "import gap" hypotheses are checkable in seconds.

## NEXT (M5, in order)

1. **clk-47 setup_shot draw-count gap**: from the bit-identical clk-46 seed, the Villa slot-8
   shot tick draws 5 in the port vs 6 in the reference. Single-step `setup_shot`
   (FUN_005ac1a0 chain) draw sites at clk 47 the same way (callsites diag + decompile diff).
   The pre-existing roster drift (Finding 2) may feed it — a kick-aim teammate search reads
   opponent positions.
2. **Roster drift from clk 0** (Finding 2): t1.i3 frozen-in-ref (act 0) vs walking-in-port is
   the loudest lead; note `ctx[0x1fc]` (furthest-from-anchor role) currently has NO port
   reader — the binary's consumer may be an unported b1c80 role leaf. Also t1.i6/i9/i10
   act-code splits at clk 0-1.
3. Marker/act parity at clk 0 END via `diag_m5_posdiff.gd` before chasing anything deeper.

## Reproduce

- Seeds: `~/godot462 --headless --path app --script res://tests/diag_m5_seedtrace.gd` →
  diff vs capture2 Pass 0 (split + anchor-check first).
- g0 chain: `res://tests/diag_m5_g0chain.gd` (needs `Pm98Movement.lean_trace_on`, the diag
  flips it per tick).
- Roster diff: `res://tests/diag_m5_posdiff.gd` vs
  `~/MWM-AI/data/pm98-m4-oracle/m5_clk9_wideq_2026-07-11/clk9_timeline.jsonl` `pl` rows.
