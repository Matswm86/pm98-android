# M5 Divergence #1 — ROOT CAUSE FOUND + FIXED: the ball predicted-trajectory buffer was never built (s23, 2026-07-07)

Continues `M5_DIVERGENCE1_RNG_DESYNC.md` (s22). s22 pinned the divergence to a late kickoff-possession
(port collects the ball ~4 ticks late -> RNG draw-count desync -> phantom clk601 goal) and named the
gate-4 catch zone of `_lean9490_slice_c` as the suspect, with a caveat: the drift could be a
"draw-count-neutral positional drift" feeding a late catch. **This session found exactly that drift,
in the decompile, and fixed it. The handoff's stated suspects were RED HERRINGS: `_grid9490_build`,
the gate-4 bounds, and `_lean9490_aim_scalars` are ALL byte-faithful to the binary.** The real bug is
the INPUT they consume: the ball's 16-slot predicted-trajectory buffer at `ball+0x114..0x1d3` was
**never populated**, because the function that builds it (`FUN_0058fda0`) was deferred as "render
trail, no sim read."

## The decompile-diff (handoff NEXT step 1) — all three suspects are faithful

- `_grid9490_build` (Pm98Movement.gd:6821) reads `ball + 0x114 + 12*j` for j=0..15, subtracts p.pos,
  rotates by `-p.facing` — matches FUN_005a9490 L206-220 exactly.
- Gate-4 catch box `|g0[0]-0x4ccc| <= 0x4ccb` (== g0[0] in [1, 0x9997]) / `|g0[1]| <= 0x8000` /
  `g0[2] <= 0x1e665`, and the chase box on grid row 2 (`local_a8/a4/a0` = the array-overrun view of
  `local_c0[6..8]` = grid[2]) — match FUN_005a9490 L420-451 exactly.
- `_lean9490_aim_scalars` — feeds the marker-scan heading gate, not gate 4; also faithful.

## The real bug (empirical proof, `app/tests/diag_m5_trajbuf.gd`)

The buffer feeding all of the above is **never written**. `_si(ball, 0x114+12j)` returns 0 for every
unset slot, so `_grid9490_build` computes `rot(-p.pos, -facing)` for ALL 16 rows — a constant,
player-position-based value that does NOT track the ball. Byte-loading the reference frame-0
(seed `0xea0d2a8d`) and dumping the nearest player's grid[0] per tick, clk 5-12:

```
PRE-FIX : buf.has0x114=false  grid0=(26213,78,0)   (FROZEN — same every tick, ball ignored)
POST-FIX: buf.has0x114=true   grid0 tracks the ball: (3230,-70628) -> (-11873,-117105) -> ...
```

`FUN_0058fda0` writes `ball+0x114` in its SECOND loop (decompile L125-198). It is NOT pure render:
the render mid-points go to `+0x74/+0xa8`, but the 16-slot forward trajectory at `+0x114` is consumed
by `_grid9490_build` (lean gate-4 catch) AND the 7260 marker builders AND the work[] copy at
Pm98Movement.gd:2086. `run_balltail_oracle.sh`'s own note ("FUN_0058fda0 runs but only touches
+0x74/+0xa8, not read here") is the exact wrong assumption that let the deferral slip through.

## The fix

`Pm98Movement._ball_predict_traj` (+ `_traj_segment`, `_traj_ftol`) ports FUN_0058fda0's two passes:
- **Loop 1** segments the ball flight into up to 3 arcs (between ground bounces). Grounded roll
  (`vz==0 && pz==0`): decelerate by a 0x22-magnitude friction step along the velocity heading;
  seg length `= (dominant_vel / step_component) / 9` (the 0x38e38e39 magic-divide-by-9). Airborne:
  projectile under g=0xb2 (178); seg length `= trunc((vz + sqrt(vz*vz + 356*z0)) / 178)` — the FP
  constants decoded from `ds:0x639090` (`-356.0` = `-2*g`) and `ds:0x639098` (`1/178`), then
  `vx,vy *= 0xc51e/0x10000` (0.77) and `vz` bounces to `-(vz_ground * 0x9c28/0x10000)` (0.61),
  settling to 0 below 0x28f. (The `if vz<1` test at decompile L80 only changes the unused render
  midpoint, so it is dropped — the segment length + END are always computed.)
- **Loop 2** walks the 3 segments sampling every 4 frames into the 16 slots; grounded samples clamp
  the frame count to `dominant_vel/step`; a partial fill pads forward with the last position.

Wired into `_ball_tail` (the 0x58eb95 trail entry), so it runs every tick for held, lerp, and
free-flight balls, matching the binary.

## Oracle (the invention guard)

`tools/re/run_ballpredict_oracle.sh` drives the REAL FUN_0058fda0 (entry `0x0058fda0`, ECX=ball)
under the Ghidra PCode emulator and banks the 48-int `+0x114` buffer for 7 fixtures (4 grounded-roll
incl. the actual kickoff regime + 3 airborne). `test_ballpredict.gd` asserts the port bit-for-bit:
**ALL PASS (336 checks).**

### Emu artifact caught + corrected (do not revert)

The classic `_ftol` stub the other oracles use (`fnstcw/or ah,0xC/fldcw/fist`) forces round-toward-zero
via the x87 control word, but **PcodeEmu's `fist` ignores `fldcw` and rounds-to-nearest** (verified:
an exact time-to-ground of 5.70 emu-rounds to 6; real `_ftol` truncates to 5). So the emu is NOT a
faithful oracle for the airborne segment length when the FP time has fraction > 0.5. The ballpredict
oracle swaps in a **`fisttp`** stub (`83EC08DB0C248B042483C408C3`), which lifts to Ghidra's
round-toward-zero FLOAT2INT regardless of control word — making the emu match the real game's
truncation. `_traj_ftol` in the port truncates to match. (Grounded roll uses integer `/9`, no ftol,
so the kickoff regime is unaffected either way.)

## Result

- Buffer now populated; grid tracks the ball (was frozen garbage). Root cause closed.
- **Phantom clk601 goal ELIMINATED** (`diag_m5_tick_trace.gd`: `goal_tick=-1`, was clk601).
  Stash-diff proof: pre-fix the trace stops at clk601 with phases `{2:24, 0:601, 8:1}` (the phantom
  goal); post-fix it plays past clk601 to the 4000-tick limit with no goal.
- No regression: `test_balltail` / `test_engine_tick` / `test_9490sliceC` / `test_65a0openplay` /
  `test_b1500family` all still GREEN (the change is purely additive — it only fills `+0x114`).

## NEXT divergence (surfaced by the fix, NOT caused by it)

With the phantom goal gone, the match plays on and reveals a **phase-6 stall**: phase 6 (Driver.gd:453
"keeper-throw / goal-kick distribution setup") dominates the post-fix trace (2833/4000 ticks) with the
ball parked at the goal line (~x=3548057, goal line 3768320) and its position frozen for the last many
ticks. The ball rolls downfield, goes out near the goal, arms phase 6, and the goal-kick restart never
completes — analogous to the earlier "phase 2 forever" stalls (a placement/restart leaf not resolving).
Chase this next: trace the phase-6 arm (Driver.gd L559-581 keeper-throw / goal-kick distribution) and
find the leaf that should clear phase 6 back to open play. Invent nothing — decompile the phase-6
restart path and diff against the port.

## Reproduce

- Buffer proof: `~/godot462 --headless --path app --script res://tests/diag_m5_trajbuf.gd`
- Oracle: `bash tools/re/run_ballpredict_oracle.sh` ; test: `res://tests/test_ballpredict.gd`
- Full match / clk601: `res://tests/diag_m5_tick_trace.gd` (goal_tick now -1)
