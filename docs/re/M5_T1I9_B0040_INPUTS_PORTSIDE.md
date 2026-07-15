# M5 s38 — t1.i9 arm-step: port-side `_b0040_target` input trace → WRONG-INPUT (stale ball)

Continues [[handoff-pm98-m5-t1i9-steertgt-localized-2026-07-15]] (s37). s37 localized the
t1.i9 arm-step drift to a single leaf: the target returned by `FUN_005b0040` / port
`_b0040_target` — port `(1647, 2)` vs silicon `(12361, 47217)`. The open question was
whether the port feeds b0040 **wrong INPUTS** (already-drifted ball/markers) or **right
inputs with a wrong COMPUTATION**.

**s38 answer (port-side, offline): the port's b0040 reads a STALE ball at the arm step —
`ball_pos=[0,0,0]`, `ball_face=0` — which forces `facedir≈+x` and collapses the target to
the near-origin `(1647,2)`. Geometry proves silicon's ball input was materially different, so
this is a WRONG-INPUT error, not a wrong-computation one.** The extended live harness (below)
will pin exactly which ball field (pos, face, or both).

## Tooling

- **`app/tests/diag_m5_b0040_inputs.gd`** — replays the SAME persisted frame-0 + seed
  `0xc357aa2c` as `diag_m5_t1i9_steertgt.gd` and dumps `Pm98Movement.b0040_trace` for t1.i9
  per tick: every input `_b0040_target` reads + the internal terms (facedir, lead0,
  lead_final, bisection iters, to_common, pre-clamp point, clamp bounds).
- **`Pm98Movement.b0040_trace`** — a new diag-only static array, appended only when
  `MatchEngine.Pm98Rng._log_on` is true (the exact sanctioned gate `steer_trace` uses). Pure
  reads, zero mutation. All oracle suites unchanged: `test_b0040` 56, `test_65a0openplay`
  760, `test_engine_tick` 182, `test_engine_wire` 383, `test_7260` 60 — ALL PASS.
- **`tools/re/wine/m5_gdbrsp_steertgt.py` (s38)** — now also dumps the ctrl (ball) object
  (`*(player+0x190)`) at every matched 89c0 stop: `ball_pos +4/8/c`, `ball_vel +0x20/24/28`,
  `ball_face +0x34`, `ctrl+0x4c==player`, `carrier +0x84..`, markers `+0xb0/bc/cc/d8`, plus
  player terms `p+0x2bc/0x70/0x3ac/0x3a8`. These diff 1:1 against `diag_m5_b0040_inputs.gd`.

## Port trace at the arm step (t=26, target `(1647,2)`)

```
p_pos      = [26214, 98304, 0]   # pre-tick pose (byte-exact with silicon's unarmed pose)
ball_pos   = [0, 0, 0]           # ball still at origin
ball_vel   = [-4350, 12699, 0]   # velocity IS set (ball kicked this tick)
ball_face  = 0                   # <-- facing NOT yet updated from the velocity
facedir    = [65536, 100, 0]     # polar_vec(0x10000, 0) ≈ +x axis
to_common  = true, kiters = 4
lead0 = 26364  ->  lead_final = 1647
point_preclamp = [1647, 2, 0]  ->  target = [1647, 2, 0]   (= ball_pos + facedir·lead)
```

One tick later (t=27) the ball has integrated and been re-faced, and the target snaps to a
sane downfield point:

```
t=27  ball_pos=[-4350,12699]  ball_face=19824  facedir=[-21224,61971]  target=[-37957,110826]
```

The port also emits **no b0040 call for t1.i9 at the unarmed ticks** (t ≤ 25 produced zero
`b0040_trace` rows) — the formation gate suppresses it there, whereas silicon's b0040 fires
at the unarmed step too (match1, target `11420,43624`). So the port both starts one step late
**and** reads a not-yet-faced ball on its first call.

## Why this is a WRONG-INPUT, not a wrong-computation (offline proof)

On the common path, `_b0040_target` returns `ball_pos + facedir·lead` (the carrier branch is
not taken here: `to_common=true`, and `carrier_84=[-230892,674169]` ≠ the silicon target).

- With `ball_face=0`, `facedir` is the **+x axis**. Any `lead` along +x yields a target on
  the x-axis: `y ≈ 0`. The port's `(1647, 2)` is exactly that.
- Silicon's target `(12361, 47217)` lies at **≈75.3°** (`atan2(47217,12361)`), with `y ≫ x`.
  A +x `facedir` cannot reach it for **any** `lead`. Silicon's match1 target `(11420,43624)`
  is the same 75.3° ray, magnitude growing — a fixed downfield aim.
- Therefore silicon's ball INPUT differed from the port's: either `ball_face` was non-zero
  (≈0x3596 if the ball was near origin) **or** `ball_pos` was already downfield — or both.
  The computation is the same integer path on both sides; the **input ball state** is what
  diverged. Root cause class: **the port's ball facing/position is stale (one tick behind) at
  the receiver's first b0040 call.**

This is falsifiable: if the live drive shows silicon ALSO reading `ball_pos=[0,0,0]` **and**
`ball_face=0` yet still returning `(12361,47217)`, the proof is wrong and it is a
computation bug. The extended harness captures exactly those fields to settle it.

## NEXT (in order)

1. **Live-drive with the s38 harness** (needs ptrace_scope=0; see the s37 handoff's restore
   note): re-drive Villa/Bolton, capture t1.i9's match2 (arm) row, and diff its `ball` block
   against the t=26 port row above. Confirm the prediction (silicon `ball_face`/`ball_pos`
   non-zero at the arm step) and name the exact field.
2. If confirmed WRONG-INPUT: trace **where the port updates the ball facing (ctrl+0x34) and
   position**, and whether that update is ordered BEFORE the off-ball receivers' b0040 in the
   silicon tick but AFTER it in the port's `Pm98Driver.tick`. That ordering is the fix site,
   not `_b0040_target` (which is byte-correct given its inputs — b0040 oracle still 56/56).
3. Cross-check the sibling onsets t0.i8 (clk 60) / t0.i9 (clk 80) with the same input capture.

## Repro

- Port trace: `~/godot462 --headless --path app --script res://tests/diag_m5_b0040_inputs.gd`
  (offline; reads the persisted frame-0 struct; reproduces `(1647,2)` inputs at t=26).
- Silicon: extended `m5_gdbrsp_steertgt.py` per `tools/re/wine/README.md` §Reproduce
  (attended live drive; the game dies on detach — capture first; match base moves every
  drive, re-run `m4_findbase.py`).
