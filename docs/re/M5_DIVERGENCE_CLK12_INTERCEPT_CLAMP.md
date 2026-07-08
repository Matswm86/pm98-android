# M5 clk-12 divergence — the kickoff receiver ran to the pitch CORNER (2026-07-08)

**RESOLVED 2026-07-08 (s27).** One-line root cause + faithful fix at the bottom. This is the
divergence that div#0 ([[M5_DIVERGENCE0_KICKOFF]]) exposed once the opening kick was made faithful.

## Symptom

After the div#0 kickoff fix, the ball trajectory matched the correct-seed reference
(`data/pm98-m4-oracle/m5_traj_correctseed_2026-07-08/`) bit-exact clk 0..11, then at **clk 12** the
ball TELEPORTED +35539 in x (port `(-13365,-51095)` -> `(22174,-60808)`) while the reference
dribbled it smoothly `-x` (`(-19393,-47335)` -> `(-37588,-59066)`). The port's kickoff receiver
(Villa slot-8) then "dribbled" the ball on a huge orbit toward the +x/+y corner.

## Invent-nothing trace (all via `tests/diag_m5_receiver.gd`)

1. The +x jump is written by `_movement_decision -> move_dispatch -> _openplay_arm1` for the receiver
   as CARRIER. The receiver correctly runs `_active_chase_return` (chase-flag `+0x63=1` is faithful
   to FUN_005b70e0), which steers `-x` — but the carried-ball advance in `steer_8f20` places the ball
   at `P + polar(r, facing)` with `r≈51843` and `facing≈+x`, throwing it to the corner.
2. `r` and `facing` are wrong because the receiver arrived at the collection MIS-POSITIONED: during
   the run (clk 1..11) it went `+x` (right) to `(-18305,-93165)` instead of `+y` (up, toward the
   ball) to the reference `(-21415,-80668)`. Its facing tracked `+x`, not the ball.
3. The run is `_move_b0040` (FUN_005b0040, oracle-locked). Dumping its output: the steer target was
   **`(3768320, 2359296)` every tick = the +x/+y pitch corner** (`= m+0x1820 / m+0x1824`). The
   receiver was chasing the corner, not the ball.
4. The interception loop's PRE-clamp `point` was actually SANE (`≈(-14107,-53900)`, near the ball).
   The per-axis clamp into the pitch box `[m+0x1828..m+0x1834]` turned it into the corner.
5. The box bounds are correct in memory (`m+0x1828 = -3768320` lo, `m+0x1834 = +3768320` hi) — but
   the frame0 struct stores the negative lo as **unsigned `0xffc40000`**, and `_b0040_target` read
   it with the raw `_g` (no sign-extend). So `_clamp_i(v, lo=4291198976, hi=3768320)` =
   `min(max(4291198976, v), 3768320)` = `3768320` for EVERY point -> the corner.

## The fix (faithful)

The decompile reads the box as `*(int*)(m+0x1828)` — **signed int32**. Port `_b0040_target`'s clamp
now sign-extends the bounds with `_si` instead of `_g` (`app/scripts/Pm98Movement.gd`, the clamp at
the end of `_b0040_target`).

```gdscript
# was: _clamp_i(int(point[0]), _g(m, 0x1828), _g(m, 0x1834)) ...
_clamp_i(int(point[0]), _si(m, 0x1828), _si(m, 0x1834)),
_clamp_i(int(point[1]), _si(m, 0x182c), _si(m, 0x1838)),
_clamp_i(int(point[2]), _si(m, 0x1830), _si(m, 0x183c)),
```

`_g` "worked" in `test_b0040`'s oracle only because that fixture stores the bounds as signed
negatives; the real frame0 dump stores them unsigned, which is what exposed the latent bug.

## Verification

`tests/diag_m5_receiver.gd` after the fix: the receiver runs UP toward the ball and collects at
`(-21415,-80668)` — **bit-exact the reference carrier** — with the ball at `(-19393,-47335)`. The
ball+carrier then match the reference **bit-exact clk 12..20** (was: teleport at clk 12). Whole-match
diff vs the correct-seed reference carrier rows: bit-exact tracking extended from **clk 12 -> clk
~115** (clk 21..23 is a minor cslot-8-vs-9 possession wobble that self-heals; first big break is now
clk 115). No regressions: `test_b0040` 56 / `test_65a0openplay` 760 / `test_decideC` 70 /
`test_decideCtaker` 54 / `test_steering` 132 ALL PASS.

## NEXT

First remaining divergence is **clk 21** (small, ~800u): the reference hands possession to cslot-9
(the taker) while the port keeps cslot-8; it self-heals by clk 27 but likely seeds the **clk-115**
big break. Diff tool: `tests/diag_m5_tick_trace.gd` (port CSV) vs
`data/pm98-m4-oracle/m5_traj_correctseed_2026-07-08/m5_traj_timeline.jsonl` carrier rows.
