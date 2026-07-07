# M5 Divergence #1 — open-play tick-level trace (s20, 2026-07-07)

Continues `handoff-pm98-m5-killtest-run-2026-07-07` (s19). That handoff localized the M5
kill-test FAIL to an "open-play resolver/movement bug" and guessed the next step was to
"trace the shot at clk~601 (setup_shot -> resolve_post_shot)". **This session ran that trace
and the guess was wrong in an important way: the goal is NOT a resolver/shot misfire — it is
a real kick that ends an uncontested ~540-tick dribble.** The divergence is a MOVEMENT /
ball-CONTEST problem, not a shot-conversion problem.

## Method
New tick-level harness `app/tests/diag_m5_tick_trace.gd` (reuses the s19 byte-load from
`run_match_from_struct.gd`, then drives `Pm98Driver.tick` DIRECTLY — arming the +0x1a1e
restart gate on a tick-ret-0 exactly like `Pm98Outer._live_branch` — and logs per-tick ball
kinematics + phase/clk/rng to a CSV, plus 22-player + keeper snapshots at chosen ticks and a
carrier-contest metric).

Run: `~/godot462 --headless --path app --script res://tests/diag_m5_tick_trace.gd`

## What the trace shows (faithful ps=4, frame-0 seed 0xea0d2a8d)
- **t25**: kickoff completes (phase 2->0), ball at centre ~(-4k,-12k,0), uncontrolled.
- **t38**: Villa outfielder **#9** (formation slot 9, role 0x2c8=9) collects the rolling ball
  (ball+0x40 controller = p9).
- **t38 -> t579**: p9 dribbles in a near-straight line, roughly constant vx ~5000-8000/tick,
  from x=-48k to **x=2,155,429**. ONE player, ~540 ticks, no possession change, no tackle.
- **t580**: ball RELEASED (controller -> 0) with **vx=35547** — a real struck kick (shot).
- **t580 -> t626**: ball flies 2.19M -> **3,793,430** (goal line +0x1820 = 3,768,320; window
  [line, line+0x10000]), |y|=168,974 < 0x3a8f5, z=8,216 in [0,0x270a3] -> `goal_area` (FUN_0058ede0)
  returns 1 -> `_goal_area_branch` -> **GOAL at t626 / clk601 / min 1'**, score 1-0.

Reference: first goal at clk **2837** (min 8'). RNG is in LOCKSTEP with the reference stream
(s19: the port's goal-1 seed sits on the frame-0 LCG at draw#2108; reference goal-1 at
draw#10210). So the ~2236-tick / ~8100-draw gap is **purely deterministic movement**, not RNG.

## Contest metric (542 open-play ticks of the dribble, carrier vs nearest outfield opponent)
- carrier HAS an assigned marker (+0x154 != -1): **75.3%** of ticks (408/542).
- nearest opponent within tackle-range (<0x60000 = 393,216): **68.3%** of ticks (370/542).
- nearest-opponent distance: **min 26,566 (0x67c6)**, mean 353,255.
- ball WON by the defence: **0 times in 542 ticks.**

So for ~2/3 of the dribble an opponent is essentially on the ball (one gets within 0x67c6),
and the carrier is marked 3/4 of the time — yet it is **never dispossessed**. Meanwhile the
carrier charges straight at goal instead of wandering under pressure.

## Ruled OUT this session (do not re-investigate)
- **Not a resolver/shot misfire.** The t580 event is a legitimate kick (velocity release),
  not `resolve_post_shot` fabricating a goal. `goal_area` fires because the ball physically
  entered the goal volume.
- **Not the 7260 / `_movement_decision` `p[0x2bc]==0` gate.** Verified against the decompile:
  `fn_005a4600_FUN_005a4600.c:387` reads `*(param_1 + 700) == 0` — the port
  (`Pm98Action.gd:343`, `:464`) is faithful. `p[0x2bc]` is the static formation slot (0 = GK
  slot); FUN_005a7260 is the GK distribution/ball-handling routine (sets phase 6, +0x19dc
  timer) and is correctly gated to the keeper slot. Not the bug.
- **Not stubbed b1500/b1c80.** `offball_opp_b1500` (Pm98Movement.gd:6292) and
  `offball_own_b1c80` (:6381) ARE ported and wired LIVE (`formation_gate_b1420(p, true, rng)`
  at Pm98Movement.gd:1118 and :5458). The "UNPORTED / trace-only" comments at :5580-5625 are
  the STALE `wire=false` oracle path, not the live path.
- **Not RNG desync.** Lockstep with the reference stream (above).

## The narrowed open question (for the next session)
Two non-exclusive candidate causes remain, both inside the ported movement family the s19
handoff named ("65a0 / b1500 family"):

1. **Attacker too fast/direct.** The carrier runs `_move_8680` (settle) — because in
   `_movement_decision` (Pm98Action.gd:488) the ball controller IS the player — which chains
   `settle_8680 -> formation_gate_b1420 -> offball_own_b1c80` (own-possession carrier logic:
   state-5 goal-burst, dribble). The carrier's path is a straight ~constant-velocity charge to
   goal with no wander/pressure-response. Suspect the b1c80 carrier goal-burst / the deferred
   `ball_touch_7260` dribble-grid (Pm98Movement.gd — "L177-668 DEFERRED") makes the dribble too
   direct.
2. **Defence never tackles.** The dispossession calls `possession_tail_aafd0` live in
   `offball_opp_b1500` at Pm98Movement.gd:6332 (press branch) and :6356 (non-press branch), but
   each is behind: `is_same(carrier, mk)` (the defender's mark target must BE the carrier —
   only the single assigned marker qualifies) + a y-alignment gate (`< 0x5999`, :6334) + a
   matrix-distance gate (`_si(p, _dist_off(mk...)) < _rscale7(rng.next(), 0x333)`, :6346) + a
   ~2% aggression roll (`_rscale15(rng.next(),1000) < aggr`, aggr=0x14 default, :6355). With
   these gates the tackle never fired in 542 ticks. NOTE the reference ALSO holds the ball for
   ~2800 ticks before its first goal, so a low tackle rate may be FAITHFUL — the decisive test
   is whether the carrier's DOWNFIELD SPEED matches the reference, not whether tackles are rare.

### Next step (priority)
Disambiguate (1) vs (2) with the wine/emu oracle, which the port CANNOT do from GDScript alone:
- Drive the REAL FUN_005a65a0/`offball_own_b1c80`/`ball_touch_7260` under the PCode emu from the
  same byte-loaded frame-0 and compare the carrier's per-tick position to the port's CSV. If the
  real carrier advances slower / changes direction, the bug is in the port's carrier movement
  (candidate 1) — most likely the deferred `ball_touch_7260` dribble-grid (Pm98Movement.gd
  L177-668) or the b1c80 goal-burst. Port those leaves, re-run `diag_m5_tick_trace.gd`, and
  expect the dribble to lengthen toward the reference's ~2800 ticks.
- Only if the carrier speed already matches the reference should the tackle gates (candidate 2)
  be audited against the FUN_005b1500 decompile line-by-line.

Do NOT invent tackle thresholds or dribble speeds — every constant must come from the decompile.

## Artifacts
- Harness: `app/tests/diag_m5_tick_trace.gd`
- CSV (regenerated on each run): scratchpad `m5_tick_trace.csv` (626 rows to the goal)
- Reference oracle: `~/MWM-AI/data/pm98-m4-oracle/capture2/` (timeline.jsonl 33062 recs;
  m5_reference_villa_bolton_5_2.json; frame0_struct_import.json)
