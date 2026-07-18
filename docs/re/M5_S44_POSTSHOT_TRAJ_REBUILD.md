# M5 s44 — kick-release traj rebuild ROOT-FIXED (FUN_005ab5a0 L25); parity 271→281, drift frontier 24→47

Executes the s43 frontier (`M5_DART209_POSDRIFT` residual tail, first divergent tick clk 272)
and closes the s36-s38 t1.i9 chain. **One source-true line: `resolve_post_shot`
(FUN_005ab5a0) must call `_ball_predict_traj` (FUN_0058fda0) FIRST** — the decompile's L25
call the port had dropped as presumed-render (the exact trap the `_ball_tail` comment
documents). Every kick release (acc40/ad*/ae* handler chains) rebuilds the ball's 16-slot
predicted-trajectory buffer `+0x114..0x1d4` at release time; same-tick off-ball players'
`_b0040_target` interception reads those slots (`ball+(idx+0x17)*0xc`, idx clamped 15). The
port left the at-rest buffer (all zero) visible for the remainder of the kick tick →
one-quantum wrong first steps for every off-ball reactor — the whole s34/s35 "residual
drift tail" class.

## The kill chain (capture2 fixture, seed 0xea0d2a8d)

1. s43 frontier: first divergent tick clk 272 — oracle 12 draws vs port 5.
2. NEW RSP dartwatch (below): full-roster dump at every draw, clk 0-306. Orbit-aligned
   position diff (`tools/re/m5_orbit_posdiff.py`) showed the s35 residual tail UNCHANGED
   (t1.i9 @0 (+5,-5), t0.i8 @60, t0.i9 @80, t1.i7 @185, t1.i5 @201) and the 272 event =
   t0.i9's dart-init (5b2f67/5b2fae) firing 2 clk late — matrix inputs off the drifted pair.
3. RSP steertgt on t1.i9 (capture2): both engines call B0040 (ret0 0x5b04cb) at the kick
   tick with IDENTICAL visible ball state (pos 0, vel set, face 0) — yet silicon's target is
   (-194860,-298) vs port (-142564,-218). Same ray, lead ×1.367.
4. Integer replica of the b0040 bisection reproduces the port EXACTLY with all-zero traj
   slots; silicon's lead needs slot15 ≈ 36·vel — a FRESH predicted trajectory.
5. Caller scan: FUN_005acc40 → FUN_005ac1a0 → **FUN_005ab5a0 → FUN_0058fda0() first
   statement** (also 5adfc0/5ae4c0/5ae910 → 5ab5a0). The port's `resolve_post_shot` had
   everything EXCEPT the rebuild.

## Fix + verification

- `Pm98Movement.resolve_post_shot`: `_ball_predict_traj(ball)` added before the `+0xcc`
  reads (one line + comment).
- t1.i9 kickoff arm: port now BYTE-EXACT vs silicon through the entire watch window
  (pos/face/yaw/spd/target all match; the (5,-5) quantum is gone).
- All 16 oracle suites PASS (incl. test_postshot 162 — the PCode oracle always ran the
  real fda0, so the banked expectations already contained it).
- Full kill-test: FULL TIME reached, no errors; scoreline now 7-1 (was 4-2) — expected
  reshuffle, NOT a regression indicator.
- Seed-lockstep ladder vs capture2: byte-exact through **clk 281 / draw 1056** (was 271/
  1001), with the oracle/port clk LABELS aligned at the frontier (the old ±2 skew gone).
- Orbit position diff: drift frontier moved tick 24 → **clk 47**; earliest forker now
  t0.i9 during the clk-47 shot tick (setup_shot, 6-draw tick, ords 218-224): port step
  (+6505,+2599) vs oracle (+6276,+1861) from identical pre-tick state. t0.i8 @60,
  t1.i7 @185, t1.i5 @201 survive; t1.i9 clean until 259.

## NEW: sudo-free live-oracle method (ptrace_scope=1)

Wine double-forks every process to PPid 1, so /proc/<pid>/mem is Yama-blocked without
`sudo sysctl kernel.yama.ptrace_scope=0` — the s37-s43 blocker. **The winedbg --gdb stub
needs no sudo** (wineserver holds PR_SET_PTRACER), and its RSP `m/M/Z1/Z2` packets do
everything IF you send `Hg<tid>` after the `?` status (without thread selection the stub
never answers `m` — probed 2026-07-18). Tools:

- `tools/re/wine/m5_rsp_capture.py` — base scan/candidates + frame0 poke + XI check + Z2
  seed-watch with per-draw full-roster dumps, all over RSP. Produced today's
  `oracle_dartwatch_306.jsonl` (scratchpad; regenerate any time).
- `tools/re/wine/m5_rsp_steertgt.py` — Z1 on FUN_005a89c0, per-hit steer target + player
  + ball block for one player, plus frame0 poke. (The Z1@0x5983f0 base-grab variant
  CRASHES the stub across the KICK OFF click — use base candidates 0x03dbf0d8/0x03dbf060,
  they reproduce per boot.)
- Gotchas: ONE connection per stub, client disconnect kills the stub (and usually the
  game); NEVER wrap the stub in `timeout` (SIGTERM kills the game); the preseason injury
  roll can silently swap a starter — the XI check vs frame0 aborts, re-roll the boot
  (~1-in-2 clean).

## NEXT

1. t0.i9 @ clk 47 (the shot tick): same drill — port vs oracle per-draw positions exist in
   today's dartwatch capture (ords 200-240); suspect airborne-kick traj rounding
   (`_traj_segment` FILD/FSQRT float path) or shot-resolve sub-phase ordering.
2. Then t0.i8 @60 / t1.i7 @185 / t1.i5 @201 / t1.i9 @259, re-running the ladder after each.
3. Scoreline bar unchanged: 5-2 @ 8'/24'/35'/43'/53'/62'/71', then the seed sweep.
