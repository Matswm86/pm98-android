# M5 s45: the m+0x1650 controller-mirror fix — one alias read closes five drift onsets

## Symptom

Orbit position diff (s44): earliest drift onset t0.i9 during the clk-47 SHOT tick
(setup_shot by t0.i8, 6-draw tick, ords 218-224). Port step (+6505,+2599) — a re-aim at
full speed toward a pitch-corner target — vs oracle (+6276,+1861) — the pre-shot heading
kept, −458/tick decel starting ON the shot tick. Later onsets t0.i8@60, t1.i7@185,
t1.i5@201, t1.i9@259, then the clk-281-285 avalanche.

## Root cause

In the binary the ball struct is EMBEDDED in the match at +0x1610, so **match+0x1650 IS
ball+0x40** (the carrier pointer): every open-play engage/release updates it implicitly.
The port models the ball as a separate Dict and kept an m[0x1650] INDEX mirror with only
two writers — `_decide_slice_c_taker` (set-piece taker) and `ball_restart_decide` (−1).
The open-play engage path (`_ball_engage_player`) never wrote it, so from the kickoff on,
m[0x1650] froze at the CLK-0 KICKOFF TAKER (t0 index 9).

`_select_roles` (FUN_005b8a60, the 1-in-8-throttled matrix tail) force-designates
gs+0x204 (in-possession candidate) to the controller index when the controlling team is
ours. With the stale mirror, team 0's designated interceptor stayed **t0.i9 forever**
instead of tracking the live carrier (t0.i8 by clk 3x).

The designation is INERT while a carrier exists (b1420's designated arm needs
`ball+0x40 == 0`), which is why clk 0-46 stayed byte-exact. The instant the shot released
the ball (resolve_post_shot tail clears ball+0x40), b1420 routed t0.i9 → `_move_b0040`:
the interception bisection diverged (kiters=18/18, lead → ~1.03e9), the pitch-box clamp
produced a corner target, and t0.i9 re-aimed at full speed. Silicon's designated player
was the SHOOTER t0.i8; its t0.i9 fell to b1c80 → role-9 leaf 3e50 → the loose-ball chase
(steer to ball, slow turn + decel) — the observed constant-slope decelerating step.

`select_nearest`'s entry ownership guard (FUN_005b8ce0 cond_A) read the same stale key.
Same class as the s33 m[0x165c] receiver-mirror fix.

## Fix

`Pm98Movement._ctrl_index(m)`: resolve ball+0x40 → roster index (+0x2c4) live when
m["ball"] exists; bare oracle fixtures keep the poked m[0x1650] index model. Used by
`_select_roles` and `select_nearest` (the only two stale readers left; `_holds_ball` was
already alias-fixed in s33).

## Verification

- diag_m5_t0i9_clk47 (new): designation flips to the carrier at the pre-47 matrix tick;
  t0.i9 clk 47-50 positions byte-equal to the RSP dartwatch capture, incl. the +0x17c
  matrix value at 49 (0xcdba5) and the decel-on-shot-tick timing.
- Orbit position diff vs oracle_dartwatch_306: **every listed onset closed** — t0.i9@47,
  t0.i8@60, t1.i7@185, t1.i5@201, t1.i9@259 and the 281-285 avalanche all gone. New
  drift frontier **clk 287** (was 47), a sub-LSB class: t1.i2 x-step 4533 vs 4534,
  y jitter ±8; t1.i5@287, t1.i1@290, t0.i10@291. t1.i2/t1.i5 route through _move_b0040
  every tick (opp-possession, role ≠ 4 → b1500 ret 0 → 65a0 L138), whose bisection reads
  the airborne traj slots — next suspect stays `_traj_segment`'s FILD/FSQRT float path.
- Suites: test_b0040 56, test_b1420 16, test_b1500family 589, test_relmatrix 128,
  test_settle 72, test_settlewire 39, test_movement 60, test_selectactive 24,
  test_postshot 162, test_driver 34, test_engine_wire 911 — ALL PASS.
- Kill-test: see commit message (run after this doc).
