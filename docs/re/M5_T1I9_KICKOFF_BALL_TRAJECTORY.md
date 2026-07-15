# M5 s39 — t1.i9 arm-step drift re-rooted: the port's KICKOFF BALL goes the WRONG DIRECTION

Continues [[handoff-pm98-m5-t1i9-b0040-inputs-2026-07-15]] (s38). s38 localized the t1.i9 arm-step
steer target to `_b0040_target` reading a **stale ball** (`ball_pos=[0,0,0]`, `ball_face=0`) and
proposed the fix was a `Pm98Driver.tick` **ordering** change (face the ball before the off-ball
receivers run their b0040). **s39 shows that fix would NOT resolve it: the port's kickoff ball is
travelling in the WRONG DIRECTION, not merely one tick stale. The divergence is upstream of
`_b0040_target` (which is byte-correct), in the kickoff KICK.**

## The decisive offline test — `app/tests/diag_m5_ball_onset.gd`

Replays the SAME persisted frame-0 + seed `0xc357aa2c` as s37/s38 and, at the START of each tick
(the exact state a receiver reads during that tick's player-advance, since players advance BEFORE the
ball in `FUN_00598740`), dumps the ball pos/vel/face AND force-runs `_b0040_target(t1.i9)` regardless
of the arming gate. Output (ticks 20-30):

```
t=20..25  ball_pos=[0,0,0] vel=[0,0,0] face=0x0000  STATIONARY  forced_target=[0,0,0]
t=26      ball_pos=[-4350,12699] vel=[-4338,12667] face=0x4d70   forced_target=[-37957,110826]
t=27      ball_pos=[-8688,25366] vel=[-4326,12635] face=0x4d6f   forced_target=[-41942,122460]
t=28..30  ... ball keeps rolling at face ~0x4d6d, x growing more negative ...
```

(indexing offset +1 vs s38's during-tick capture: this "t=26" pre-state == s38's post-arm state.)

## Why `_b0040_target` is exonerated (arithmetic, from the captured silicon targets)

`_b0040_target` on the moving-ball path returns `facedir_unit · lead` (the `+ball.pos` is ~0 at the
kickoff centre). Silicon's two captured targets (s37) decompose EXACTLY onto that path:

- unarmed (tick 25): `(11420, 43624)` — angle `atan2(43624,11420) = 75.34°`, magnitude = `65536·0.687`
  ⇒ `facedir_unit(75.3°) · lead`, **lead ≈ 45036**.
- arm (tick 26):     `(12361, 47217)` — angle `75.34°`, ⇒ `facedir_unit(75.3°) · lead`, **lead ≈ 48787**.

Same 75.3° ray, lead growing as the receiver-to-intercept distance changes — a textbook moving-ball
interception. Neither is the stationary-branch value `clamp(facedir·0x10000) = (16634,63393)`, so
**silicon's ball is MOVING at both steps**, and `_b0040_target` reproduces silicon's numbers when fed
silicon's ball. The leaf is not the bug (oracle still 56/56).

## The real divergence — the kickoff ball's DIRECTION (and, secondarily, its timing)

| | direction of travel | ball velocity | when moving |
|-|--------------------|---------------|-------------|
| **silicon** | **75.3° (up-RIGHT, +x,+y)** | ≈ `(+3316, +12667)`-shape (from face 75.3°) | already moving at tick 25 (unarmed) |
| **port**    | **108.9° (up-LEFT, −x,+y)** | `(−4338, +12667)` (face `0x4d70`) | not kicked until tick 26 |

Both directions are STABLE across ticks (silicon 75.3° at ticks 25+26; port 108.9° at ticks 26-30),
so the gap is NOT a timing artifact of the tick-offset — **the port kicks the ball toward the wrong
half. The X-component sign is flipped** (port −4338 vs silicon's implied +3316); Y matches.

Because `ball_advance` sets `ball+0x34 = atan_angle(vel)` (`Pm98Movement.gd:3412`), the receiver's
`facedir` is fixed by the kick velocity. s38's ordering fix would only change the port's read from
`face=0` to `face=0x4d70 (108.9°)` — STILL wrong vs silicon's `75.3°`. The kick direction must be
fixed, not the read ordering.

## Where the kick direction comes from

All port kick trajectories set velocity as `polar_vec(mag, kicker_facing)` — the ball inherits the
KICKER's facing (`Pm98Action._lay_lob_trajectory` L184-187 uses `polar_vec(0x1333, p+0x34)`;
`setup_kick` L228-236 scales the existing velocity). So the port's `108.9°` == the kickoff kicker's
facing (or its computed kick aim) at the kick tick. The divergence is therefore in the **kickoff
kicker's facing / kick-aim**, an x-half (attack-direction) error — Bolton W (team1, away) should be
kicking toward +x but the port kicks toward −x.

## Latent, OFF the critical path (NOT this bug, do not chase now)

The `FUN_005b0040` decompile's STATIONARY branch (ball vel==0, L63-71) skips the interception block
INCLUDING the final `FUN_005ee170(local_c,uVar7)` (L128), leaving `local_c = facedir` (mag `0x10000`
from L37), so silicon's stationary-ball target would be `clamp(facedir)`, not `clamp(ball.pos)`. The
port seeds `point = ball.pos` (`Pm98Movement.gd:1575`) and returns `clamp(ball.pos)` when stationary.
**Whether these differ is UNRESOLVED** — Ghidra dropped the output params on L37/L75/L128 so the
buffer aliasing is lossy, and at the kickoff centre `ball.pos ≈ 0 ≈` a short facedir, so `test_b0040`
(56/56) may simply not cover a stationary ball with a large non-zero facing. It is MOOT for the t1.i9
divergence (silicon's ball is moving), but flag it: if a stationary-ball-with-facing case is ever the
oracle target, re-check this branch against a PcodeEmu run.

## NEXT (in order)

1. **Trace the kickoff kick in the port**: which player takes it, its facing/aim at the kick tick, and
   the exact function that writes the ball's first velocity `(−4338,12667)` (`diag_m5_ball_onset`
   pins it to tick 26). Compare the kicker's facing / attack-x-sign to silicon (live 89c0/ball-vel
   capture, or trace the port's kickoff placement `Pm98Driver.restart_handler` +
   `Pm98Match.kickoff_init` attack-side fields `+0x19c8/+0x45c`).
2. Confirm whether the port kicks one tick LATE independently of the direction (silicon moving at
   tick 25, port at tick 26) — likely the same kickoff-arm-timing family as
   `M5_KICKOFF_ARM_TIMING_FIX.md`.
3. Only after the kick direction+timing match: re-check t1.i9's b0040 target equals silicon's
   `(11420,43624)`/`(12361,47217)`; it should fall out for free (leaf already byte-correct).

## Repro

- `~/godot462 --headless --path app --script res://tests/diag_m5_ball_onset.gd` (offline, reads the
  persisted frame-0 struct at `~/MWM-AI/data/pm98-m4-oracle/steertgt_2026-07-15/`).
- Oracle unaffected (no production code touched): `test_b0040` 56/56.
