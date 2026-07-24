# M5 s54: the fork is the ball's banked trajectory fields — `ball+0xb0` / `ball+0xcc`

s53 left exactly one question: re-run the b0040 oracle on the tick's LIVE inputs and compare the
intermediate **lead**, not the final point. Done, live, on silicon. The lead ladder is identical
in both builds — all 18 iterations, including the int32 wrap — and the fork is **after** the loop,
in the marker-adjust arm the port could never enter because it never wrote the fields the arm reads.

Evidence: `tools/re/specs/b0040_traj_fields_s54.txt`.
Raw: `data/pm98-m4-oracle/capture2/b0040trace_s54_636_643.jsonl` (29 live `FUN_005b0040` calls).

## 1. Every b0040 input is identical live — including `curve_rate`

Read straight off the s53 arm capture for clk 636-646 (`tools/re/m5_b0040_live_inputs` path in
`m5_b0040_trace_solve.py`): player position, ball pos/vel/face `1854`, and the 16 interception
marker slots at `ball+0x114` (exactly `ball.pos.xy + i*4*ball.vel.xy` at every tick).

`curve_rate` is now settled too, and it is NOT the fork. s52 could only bound it; the s53 steer
capture banks `P+0x6c = 6457` on every tick, and `6457` IS `FUN_005a89c0`'s formula at scale `0x5a`
on `P+0x70 = 13429`, `P+0x3ac = 2739`, `P+0x3a8 = 4251` — the port's values. The s54 trace then
reads those three fields directly at the `FUN_005b0040` entry and they are `13429 / 2739 / 4251`,
so `curve_rate = 6703` in both builds.

## 2. The live bisection ladder equals the port's, wrap included

`tools/re/wine/m5_rsp_b0040trace.py` arms `Z1` at four points inside the real function
(`0x5b0040` entry to gate on `this`, `0x5b0312` = `MOV EBX,EAX` for the per-iteration
`lead_in`/`nd`/`lead_out`, `0x5b04a6` for the pre-clamp accumulator, `0x5b04c1` for the clamped
target). At clk 639, silicon:

```
  k=1   lead_in=-394836     nd=332525       -> -31155
  ...
  k=18  lead_in=721336533   nd=1492610119   -> -1040510322     <- the int32 wrap
```

Identical to the port's ladder, every iteration, at clk 637/638/639/640/641/642. **So s50's
conclusion holds: the loop and the wrap are faithful.** What differs is the value that survives it:

```
clk 639   silicon pre-clamp = [   2052679,   -1713324, 161386]
          port    pre-clamp = [-1023306846, -187689993, 161386]   (before this fix)
```

## 3. The marker-adjust arm fires on silicon and could never fire on the port

`FUN_005b0040`'s post-loop block (decompile lines 96-110) is already in the port:

```
if (p+0x2bc != 0) {
    if (0x2cccc < ball+0xb0) { dotA = dot16(ball+0xcc - ball.pos, facedir); if (lead <= dotA) lead = dotA; }
    if (0x2cccc < ball+0xbc) { dotB = dot16(ball+0xd8 - ball.pos, facedir); if (lead <= dotB) lead = dotB; }
}
```

Live at clk 639: `ball+0xb0 = 287963` (> `0x2cccc` = 183500) and `ball+0xcc = (2052359, -1715423, 0)`,
so `dotA = 1302391`. The loop's lead is the wrapped `-1040510322`, which is `<= dotA`, so **the arm
replaces it** and the point becomes `ball.pos + facedir*1302391 = (2052679, -1713324)` — silicon's
pre-clamp, exactly. Well inside the pitch box, so no clamp, and `atan` of it from the player is
`771` — the heading s53 measured off the wire.

In the port those fields were **0**, so the arm was dead and the wrapped lead went to the clamp and
produced the `-corner` and heading `34078`. s52 killed this arm on the frame-0 snapshot (where the
fields genuinely are 0 — the ball has not been kicked yet) and on a Ghidra store scan limited to
`0x58xxxx-0x5bxxxx`; the writer is `FUN_0058fda0`, and its stores are `piVar7`-relative with
`piVar7 = param_1 + 0xa8`, so a displacement scan for `0xb0` / `0xcc` cannot see them.

## 4. What the fields are, and the fix

`FUN_0058fda0`'s **Loop 1** (decompile `docs/re/move/fn_0058fda0_FUN_0058fda0.c` L26-110) banks each
of the 3 predicted flight segments into the ball. The port computed all of it into a local `segs`
array for the `+0x114` sample buffer and threw the rest away:

| field | s in 0..2 | meaning |
|---|---|---|
| `ball+0x74 + 4*s`  | `*local_3c`     | segment LENGTH in ticks |
| `ball+0xa8 + 0xc*s`| `piVar7[0..2]`  | segment MIDPOINT — for an airborne segment the **apex** |
| `ball+0xcc + 0xc*s`| `piVar7[9..0xb]`| segment END position |
| `ball+0xf0 + 0xc*s`| `piVar7[0x12..0x14]` | segment END velocity |

The airborne midpoint is sampled at `ta = vz / 178` (`iVar6 = (int)local_10 / 0xb2`) — the time to
apex, **not** half the segment — with `z = (vz - (ta*178)/2)*ta + pz`. At clk 639 that is
`(6714 - (37*178)/2)*37 + 161386 = 287963`, the captured `ball+0xb0` to the unit. The grounded
branch samples the roll at half the segment length with `z = 0`. `ball+0xcc` is
`pos + t*vel = (770857 + 94*13633, -1945817 + 94*2451) = (2052359, -1715423)`, the captured value to
the unit — i.e. the ball's first-bounce landing spot, which is what the arm is for: on a lofted
ball, run to where it will land instead of chasing an interception the player cannot reach.

Fix (`app/scripts/Pm98Movement.gd`): `_traj_segment` also returns the midpoint, and
`_ball_predict_traj` writes all four groups back into the ball, exactly as Loop 1 does. No change to
`_b0040_target` — its marker-adjust block was already correct and simply starts firing.

## 5. Result

```
28/28 live FUN_005b0040 calls, clk 636-664: player position AND pre-clamp target instant-exact
```

(instant-exact = compared at the function entry the trace itself recorded, so no skew model is
involved). t1.i10's position ladder now tracks silicon at every clk 636-651 under the documented
one-tick dump-label offset (`port[clk=N] == silicon[clk=N+1]`); before the fix it froze at
(351187, -1838528) from clk 641 while silicon ran on. The old parity frontier of clk 643 was this
freeze.

Suites: `test_ballpredict` 336, `test_balltail` 108, `test_b0040` 56, `test_b1420` 16,
`test_steering` 198, `test_movement` 60, `test_movement_build` 32, `test_65a0openplay` 760,
`test_kicksetup` 13, `test_trig_lut` 78, `test_7260` 60 — ALL PASS.

## 6. Harness notes

* New base `0x03dbf240` (a copied wineprefix moves it; added to the candidate lists in
  `m5_rsp_b0040trace.py` / `m5_rsp_steer8f20.py`).
* The career session on `DISPLAY=:2` must not be disturbed — isolate with
  `PM98_WINEPREFIX=<copy> PM98_DESKTOP=<name>` on a separate Xwayland display.
* `m5_sparse_posdiff.py` / `m5_orbit_posdiff.py` align by LCG draw ORDINAL and report phantom forks
  whose two printed coordinates are equal (seen at clk 630 on the s53 capture). `m5_clk_posdiff.py`
  (new) compares the settled end-of-tick roster per clk instead; for a single player at a known call
  site the instant-exact b0040 comparison above is stronger still.
