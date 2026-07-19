# M5 s46 — carrier ball-drag rotates by the APPLIED turn, not the full delta

**Root cause of the clk-286/287 sub-LSB turn-step class (t1.i2 face 7b3c vs 7b3d, plus
t1.i5@287, t1.i1@290, t0.i10@291) — the s45 drift frontier.**

## The bug (one line)

`FUN_005a8f20`'s carrier ball-advance rotates the carried ball's velocity with
`FUN_005ee670(local_30)` where `local_30` is the **applied** facing turn — the full delta
`d = heading - face` only when `steps < 2` (face snaps to heading), **reassigned to the
clamped `+/-0x400` step when `steps >= 2`**:

```c
if (iVar17 < 2) {                       // steps < 2
    *(short *)(p + 0x34) = param_2;     // face = heading   (local_30 stays = d)
} else {
    local_30 = ((sVar16 < 1) - 1 & 0x800) - 0x400;   // +/-0x400
    *(short *)(p + 0x34) += (short)local_30;
}
...
FUN_005ee670(local_30);                 // <-- bvel rotated by the APPLIED turn
FUN_005ee290(iVar13, iVar17);           // then scaled iv13/steps
```

The s45 port rotated by `_s16(d)` in **both** cases. Identical whenever `|s16 d| < 0x500`
(steps=1) — which is all six s38 oracle fixtures (and the `carrier` fixture had **zero
ball velocity**, so the rotation was banked as 0=0 regardless). When the carrier demands a
big turn while dragging the ball, the port over-rotated the ball's velocity by the whole
remaining delta **every tick** (~0x16xx/tick observed) while silicon turns it 0x400/tick.

## How it surfaced (the evidence chain, capture2 seed 0xea0d2a8d)

1. s45 frontier: t1.i2 face 7b19→7b3c (port) vs 7b3d (silicon) at clk 286 from a
   byte-identical clk-285 player state; steps=1 → face=heading → the heading itself is 1
   LSB off. (`oracle_dartwatch_s45_ext.jsonl`)
2. PCode oracle on the REAL FUN_005a89c0 chain with the port's exact clk-286 inputs
   (`tools/re/run_steering_t1i2_clk286.sh`) returned **7b3c == port** → the trio + atan
   LUT are exonerated; silicon fed a different steer TARGET.
3. LSB probe (`app/tests/diag_m5_t1i2_lsb_probe.gd`): flipping to 7b3d needs target
   x+44 or y+6 — not a rounding class.
4. Live RSP steer-target capture (`tools/re/wine/m5_rsp_steertgt.py 1 2 292`, Z1 on
   0x5a89c0): silicon's b1500-tail target formula is bit-identical to the port
   (`midpoint(ball, anchor3b20)` roam-clamped — silicon target == the same formula applied
   to **silicon's ball**), but the **ball position at the call differs**: clk 286 sil
   (−592744,−443063,1201) vs port (−592842,−443043,1201) — z equal, x/y off.
5. Ball velocity series: both decay |v| −1000/tick from (7982,34) at clk 285, but the
   **heading rotation per tick** differs ~6x: silicon ~0x400/tick, port ~0x16xx/tick
   (ball face fc3e→f84d→f45d… vs c6bc→afda→9cd3…).
6. Port `ballvel_probe` (diag): the hard rotation happens in `et:after_move_or_decision
   a=0x3` — the carrier t0.i8's engine_tick, i.e. 8f20's ball-drag. The carrier was
   executing a multi-tick turn (steps≥2) through clk 285-291.
7. Decompile (`docs/re/move/fn_005a8f20_FUN_005a8f20.c`): `FUN_005ee670(local_30)` — see
   above. Port fix: rotate by `applied` (= `step` when steps≥2).

The clk 158-159 transient (sil ball −18/−3 x-units, self-healed) is the same class: brief
big-turn drag windows whose error the next straight-line drag re-write erases. The class
is invisible to the player-row orbit differ until an off-ball steer target derived from
the mid-flight ball crosses an atan LSB — the "sub-LSB" signature.

## Fix + lock

- `Pm98Movement.steer_8f20`: `applied := d`, reassigned to the `+/-0x400` step in the
  steps≥2 branch; `rot_vec3(bvel, _s16(applied), 0)`.
- Disasm proof (DumpAsm 0x5a9000-0x5a91c0): the d store at 005a901a (`[ESP+0x18]` under 2
  pushes) and the step store at 005a907b (`[ESP+0x10]` flat) are the SAME absolute slot;
  005a9186 reloads it (`[ESP+0x18]` under 2 pushes again) as the 5ee670 angle — the
  decompiler's `local_30` unification is correct. 5ee290's args are the pushed
  (iv13, steps) with this=&ctrl+0x20 (the ECX this-chain the decompiler dropped).
- Corollary: when steps<2, iv13=0 so the iv13/steps scale ZEROES the ball vel — the
  full-d rotation is dead code for the ball; the only live rotation class is +/-0x400.
  (The live silicon arc confirms: vel turns 0x400/tick, |v| scales (n-1)/n with n
  shrinking 8,7,6,... as the carrier's remaining d closes 0x400/tick.)
- Oracle extended (`tools/re/run_steering_oracle.sh`): `emit_spec` takes optional
  BVX/BVY/BVZ (ctrl+0x20/24/28) + three new fixtures — `carrier_vel` (heading 0x511 →
  steps=2 marginal: rotation +0x400, scale 1/2), `carrier_bigturn` / `carrier_bigturn_neg`
  (steps=15: +/-0x400, scale 14/15). Banked vs the REAL binary via PcodeEmu.
- **Emulator trap (cost 3 phantom fails):** 8f20's ftol is a DIRECT `CALL 0x605fb0`, NOT
  via the IAT thunk the harness repoints — under PCode the real CRT `_ftol` runs and the
  emulator mishandles the x87 RC bits (rounds-to-nearest instead of truncating). Any
  fractional sqrt distance banks +1 vs real silicon. Fixture fix: ball y = 262173
  (= 0x40000 + marker.y 29; sin_a(0)=COS[1023]=100, so polar(0x4ccc,0).y = 29) restores
  the TRUE perfect-square distance 0x50000. The original `carrier` fixture had the same
  fractional distance (327656.8) but iv13/steps = 1/2 swallowed the +1.
- `app/tests/test_steering.gd`: fixture table + builder extended to poke the ball vel —
  **198/198 PASS**.

## Verification (all on capture2, seed 0xea0d2a8d)

- 11 suites ALL PASS (b0040 56 / b1420 16 / b1500family 589 / relmatrix 128 / settle 72 /
  settlewire 39 / movement 60 / selectactive 24 / postshot 162 / driver 34 /
  engine_wire 911).
- Orbit differ (regenerated dart209 posdump vs oracle_dartwatch_306): **NO FORKS through
  clk 306** — t1.i2@287, t1.i5@287, t1.i1@290, t0.i10@291 all closed.
- Full steer-target diff (silicon m5_rsp_steertgt rows vs diag_m5_t1i2_targets):
  **zero diffs clk 0-292** on target/ball/pos/face at every t1.i2 steer call.

## Capture-side additions (reusable)

- `m5_rsp_capture.py`: per-stop `ball` row (m+0x1610: pos/vel/face/ctrl/recv/+54/58/5c).
- `MatchEngine.Pm98Rng._ball_watch` (diag-only): draw log rows carry the mid-tick ball
  pos — draw k is seed-lockstep with silicon RSP stop k.
- `Pm98Movement.steer_89c0` diag block: full input snapshot (pos/face/spd/cur, curve
  formula fields p70/3ac/3a8/388, p90/p5c/p2c/p30, gs2ee, phase flags, ball, b1500
  anchor/roam/p3a4/gs318) appended to `steer_trace`.
- Port diags: `diag_m5_t1i2_targets.gd` (per-tick t1.i2 steer JSON), `diag_m5_ballvel.gd`
  (per-tick `ballvel_probe` rows), `diag_m5_ball_perdraw.gd` (per-draw ball),
  `diag_m5_t1i2_lsb_probe.gd` (atan LSB boundary mapper).
