# M5 s36 — t1.i9 one-quantum drift is a FIRST-STEP TARGET error (not facing/arm)

Continues [[handoff-pm98-m5-kickoff-arms-2026-07-12]] (s35). NEXT-1 was "t1.i9 one-tick-early
(clk 1, d=(5,-5), b1500 opp-possession side); same facing/arm class is the prime suspect."

**That hypothesis is WRONG. The facing/arm integration is pixel-perfect. The divergence is a
single first-step steer-TARGET error.** Proven port-side only (replay from the capture2 frame0
struct — no live drive needed; silicon reference = `armwatch2_clk25.jsonl` run 5).

## Evidence — port `diag_m5_t1i9.gd` vs silicon `armwatch2` t1.i9 (pl idx t=1,i=9)

Fields `x y act frm sub … face(0x34) yaw(0x64) speed(0x68) curve(0x6c)`:

| step | silicon face/yaw | port face/yaw | Δ |
|------|------------------|---------------|---|
| unarmed (act0) | a29e / a29e | a29e / a29e | 0 (identical pos 722854,822178) |
| arm step (act1, spd 262) | **9dc5 / 9dc5** | **9ef5 / 9ef5** | **+0x130** |
| +1 (spd 524) | a1c5 / af0e | a2f5 / **af0e** | face +0x130, **yaw matches** |
| +2 (spd 786) | a5c5 / aef9 | a6f5 / **aef9** | face +0x130, yaw matches |
| +3 | a9c5 / aeec | aaf5 / **aeec** | face +0x130, yaw matches |
| +4 | adc5 / aedb | aedb / aedb | converged |
| +5 | aec5 / aec5 | aec5 / aec5 | converged |

Reading: only the **first (arm) step heading** diverges — port `0x9ef5` vs silicon `0x9dc5`.
Face then integrates toward yaw at an IDENTICAL 0x400/tick, so it stays exactly 0x130 high
until convergence at clk6; yaw (recomputed heading) matches silicon from the 2nd step on. The
0x130 heading error is the sole cause of the `d=(5,-5)` position drift (arm-step pos
722663/821997 vs silicon 722658/822002).

## Where the 0x130 comes from

`Pm98Movement.steer_trace` for the arm step: `target_pos = (-142564, -218, 0)`, speed_scale 0x5a.
`atan_angle(-142564-722854, -218-822178) = atan_angle(-865418,-822396) = 0x9ef5` — confirms the
heading is computed straight from that target, no curve-flip. Silicon's `0x9dc5` (221.8°) vs the
port's 223.5°: the two targets point in nearly the same direction, off by only 1.67°. So the
port's first-step target is slightly wrong — NOT a wildly stale read.

Target source is a **computed leaf target**, not a stored field: at the arm step the port's
`p[0x158]=p[0x164]=p[0x170]=(0,0,0)`, `p[0x1ec]=(-2761064,631528)`, ball `ctrl+4/8=(-1260,-4810)`
— none equal `(-142564,-218)`. Steps 2-4 targets are a consistent `~(-522925,-1997283)`; only
step-1's `(-142564,-218)` is the outlier, and it's the one clk where t1.i9 has just armed.

## BLOCKER to a source-true fix (do NOT invent a target)

The armwatch captures dumped position/facing/yaw/speed/curve but **NOT the steer target_pos**
passed to `FUN_005a89c0` for t1.i9. Without silicon's actual first-step target we cannot name
which leaf-computation term is 1.67° off. NEXT-1 fix requires a live capture:

- Extend `tools/re/wine/m5_gdbrsp_armwatch.py` to also dump, at t1.i9's arm stop, the ECX/args
  into `FUN_005a89c0` (target x,y,z) and the leaf that called it (ret0 on the 89c0 entry).
- Then diff that target against the port's `(-142564,-218)` to localize the term.
- Prime suspects: `_b0040_target` / `_approach_steer_target` / `_clamp_roam` (all speed_scale
  0x5a); the b1500 opp-possession decision branch t1.i9 runs.

Harness ready: `app/tests/diag_m5_t1i9.gd` (port field + target-field + ball/goal dump, clk 0-6).
Oracle suites unaffected — no production code touched this step.

**s37 UPDATE (2026-07-15): blocker CLOSED — see `M5_T1I9_STEER_TARGET_LOCALIZED.md`.**
Live-captured t1.i9's 89c0 target: the arm-step target is port `(1647,2)` vs silicon
`(12361,47217)`, leaf `FUN_005b0040` (`ret0=0x5b04cb` = `_b0040_target`). Unarmed step
byte-exact; the wrong b0040 target is the root. NEXT = capture b0040's ctrl/ball INPUTS.
