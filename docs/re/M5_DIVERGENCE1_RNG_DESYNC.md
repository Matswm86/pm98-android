# M5 Divergence #1 — it is an RNG DRAW-COUNT DESYNC at kickoff-possession, not shot conversion (s22, 2026-07-07)

Continues `M5_DIVERGENCE1_SHOT_CONVERSION.md` (s21). **This session overturns s21.** s21 concluded
the port's premature clk601 goal was a *shot-conversion* anomaly (the port's clk~555 shot flies too
flat/straight) and wanted a fragile same-situation real-engine re-capture (seed poke). That framing
is wrong: by clk~555 the port's RNG stream is already **hundreds of draws** out of sync with the real
engine, so the clk~555 shot is downstream noise, not the cause. The real divergence is **500+ ticks
earlier**, at the kickoff, and it was pinned this session using **only the reference data that
already exists** (`capture2/`, seed `0xea0d2a8d`) — no GUI re-capture.

## Method — seed-vs-clk draw-index diff (no re-capture needed)

Both engines run the identical MSVC LCG (`state = state*214013 + 2531011 mod 2^32`; the seed lives at
`0x006d3184`). The seed is therefore a **global accumulator of every RNG draw**. Assign each 32-bit
seed value its position on the LCG line from the frame-0 seed (`0xea0d2a8d`) = its **draw-index**.
Then:

- **Reference** = `capture2/timeline.jsonl` (33,060 rows, m4_poll, records `seed` per change with
  `clk`). Every sampled seed maps onto the LCG line -> its draw-index.
- **Port** = `diag_m5_tick_trace.gd` byte-loads the same `capture2/frame0_struct_import.json`, sets
  `rng.state = 0xea0d2a8d`, and logs `rng.state` per tick -> each tick's end-of-tick draw-index.

Compare the two draw-index-vs-clk curves. First clk where the port's cumulative draw-count leaves the
reference's = the tick where the port draws a different NUMBER of RNGs = the desync. (This is robust
to the reference's async ~200 Hz sampling, which only adds a few-draw jitter band; the real signal is
a monotonic runaway far outside that band.)

## Findings (all reproducible from committed tools)

1. **The LCG is identical and phase-2 kickoff is bit-exact.** Every reference seed and every port
   end-of-tick seed lies on the `0xea0d2a8d` LCG line (zero off-path values -> LCG constants
   confirmed 214013/2531011, both engines). The kickoff windup (ticks 1-24, clk 0) + the kickoff
   shot (`setup_shot`, tick 25) draw **exactly 63** RNGs in BOTH engines -> both reach draw-index 63
   = seed `0x61a1e052` at the phase-2->0 transition. Kickoff is faithful.

2. **clk 0-8: exact RNG lockstep** (draw-index delta = 0 for 9 consecutive clks). The port draws
   3/tick in the loose-ball flight (`2x move_dispatch L1040 + 1x _rand_range_3c90 L5693`), matching
   the reference draw-for-draw.

3. **First divergence at clk 9-13: the port collects the rolling kickoff ball ~4 ticks LATE.**
   - Reference: gains possession at clk ~9 (its draw pattern switches to the 4/tick "possession"
     shape there).
   - Port: the ball stays loose until **clk 13** (tick 38), when a player engages it (ball+0x40
     assigned) and from clk 14 the possession draw `offball_opp_b1500 L6346` switches on -> 4/tick.
   - The kickoff is a **ground ball** (bz=0, vz=0) rolling AWAY from every player (nearest-player
     distance grows 70k -> 153k over clk 5-12); at engage the nearest player is ~149k units away.
     So this is a **pass / possession-completion**, not a proximity touch.

4. **The desync then runs away monotonically.** Once possession-gain is 4 ticks off, the flight
   (3/tick) vs possession (4-5/tick) draw rates diverge and compound: by clk 55 the port draws
   5-9 RNGs/tick while the reference draws ~1/tick, and by **clk 119 the port has drawn 261 MORE
   RNGs than the reference**. Every downstream leaf now runs on a desynced stream -> different
   game -> the phantom clk601 goal. The s21 "flat/straight shot" is a symptom of this, not a cause.

## The exact leaf (call-path captured this session)

The clk-13 possession-gain fires through:

```
engine_tick (Pm98Action.gd:342)
  -> _move_9490 (Pm98Action.gd:644)  = FUN_005a9490 "lean" leaf
    -> _lean9490_offball (Pm98Movement.gd:7136)
      -> _lean9490_slice_c (Pm98Movement.gd:7050)
        -> _ball_engage_player (Pm98Movement.gd:3843)   # ball[0x40] = taker
```

The take-control decision is **gate 4 of `_lean9490_slice_c`** (L7071): the ball must be inside the
player's facing-frame **catch zone** — grid row 0 must satisfy `g0[0] in [0x1, 0x9997]` (forward),
`|g0[1]| <= 0x8000` (lateral), `g0[2] <= 0x1e665` (height). The port's ball enters this zone ~4 ticks
later than the binary's. The grid is built by `_grid9490_build` from the ball position relative to
the player's position + facing (`_lean9490_aim_scalars`).

## Why this is a leaf/gate bug, not just chaos

State is bit-identical at the START of clk 9 (clk 0-8 lockstep + deterministic ground-ball physics
from the bit-exact kickoff velocity). From identical inputs the reference engages at clk 9 and the
port does not until clk 13. So one of these computes differently from the decompile at that exact
state:
- `_grid9490_build` (g0 forward/lateral/height, the catch-zone coordinates), or
- `_lean9490_aim_scalars` / the facing `p+0x34` feeding the grid frame, or
- an earlier gate in `_lean9490_offball`/`_slice_c` (the L7064 "ball heading away" angle gate, the
  L7057 fast-ball clear, or the `applied` marker-scan flag) that suppresses the catch for 4 ticks.

CAVEAT to close first: draw-index lockstep proves equal draw COUNT, not that both engines APPLIED
those draws to the same players. A draw-count-neutral positional drift in clk 1-8 could also feed a
late catch. Rule this out by confirming the port's clk-8 player/ball positions against one real-engine
per-tick sample (below), OR by finding the gate delta directly in the decompile (preferred — cheaper).

## NEXT (priority) — pin the catch-zone delta

1. Decompile-diff `_grid9490_build` + `_lean9490_slice_c` gate-4 bounds + `_lean9490_aim_scalars`
   against FUN_005a9490 for the clk-9 state (dump p+0x34 facing, p.x/y/z, ball.x/y, and the built
   grid[0] each tick clk 5-14 with `diag_m5_dist.gd`'s byte-load). The tick where the port's g0[0]
   first exceeds the binary's (ball appears ~one catch-zone-width further forward) is the constant/
   sign/scale bug. Every value from the decompile / emu oracle — invent nothing.
2. If gate-4 inputs match the decompile at clk 9 (grid is faithful), the drift is upstream and
   draw-count-neutral: get ONE real-engine per-tick position sample for clk 1-13 (drive the WATCH
   Villa-Bolton match at seed `0xea0d2a8d`, `m5_poll_traj.py`) and diff player positions tick-by-tick;
   the first position delta names the leaf.

## Artifacts (this session)

- `app/tests/diag_m5_rng_callsites.gd` NEW — byte-loads the reference frame-0, drives the tick loop
  with `MatchEngine.Pm98Rng._log_on`, and tallies which call-site draws each tick (control window
  clk 5-12 vs over-draw window clk 44-60). Named the desync leaves.
- `app/tests/diag_m5_dist.gd` NEW — per-tick ball-to-nearest-player distance clk 5-14 (proved the
  engage is a pass-completion, not a proximity touch).
- `MatchEngine.gd` `Pm98Rng._log_on`/`_draws` — gated (default OFF, zero cost) RNG draw-call-site
  hook the two diags use.
- The reference (seed `0xea0d2a8d`) was ALREADY complete at `capture2/` — the s21 "need a seed-poke
  re-capture" is unnecessary for this diagnosis.
