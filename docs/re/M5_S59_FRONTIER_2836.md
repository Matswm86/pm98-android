# M5 s59: the 7-hour capture, four real engine bugs, and clk 2836

s58 closed at clk 1032 (match minute 3) with one sentence: the frontier is a capture
problem, not an engine problem. s59 ran the capture — and the capture immediately made it
an engine problem again, four times over. The port is now byte-exact over **clk 1-2836**
(match minute ~8.9, 19.7 % of a half, 2.75x the s58 window).

## The result

Against **all nine** banked Z2 captures in `~/MWM-AI/data/pm98-m4-oracle/capture2/`, one
port dump (`diag_m5_dart209.gd` to clk 2850), zero tolerance:

| capture | window | words compared | result |
|---|---|---|---|
| `oracle_dartwatch_s45_ext` | clk 1-303 | 8,289 | EXACT |
| `oracle_dartwatch_s47a_300_588` | clk 1-588 | 73,416 | EXACT |
| `oracle_dartwatch_s51_630_660` | clk 1-661 | 10,054 | EXACT |
| `oracle_dartwatch_s53_arm_630_660` | clk 1-661 | 13,464 | EXACT |
| `oracle_dartwatch_s55_555_655` | clk 1-656 | 42,369 | EXACT |
| `oracle_dartwatch_s55b_650_1250` | clk 1-830 | 75,583 | EXACT |
| `oracle_dartwatch_s58_820_964` | clk 1-964 | 60,849 | EXACT |
| `oracle_dartwatch_s58c_950_1032` | clk 1-1032 | 35,311 | EXACT |
| **`oracle_dartwatch_s59_1020_2837`** | **clk 1-2836** | **753,257** | **EXACT** |

**1,072,592 words, nine captures, zero mismatches.**

## The capture

Per the s58 handoff: `Xvfb :5` (not rootful Xwayland — COSMIC stalls hidden Wayland
surfaces), `PM98_DESKTOP=pm98m5`, `boot.sh` → `nav_kickoff.sh mats` (BAD ROLL on boot 1,
clean on boot 2) → `winedbg --gdb` → `m5_rsp_capture.py 51359 <lpid> frame0_struct_import.json
out.jsonl 3600 1020 3600` → KICK OFF at (320,457).

* New base this boot: **`0x03dcf0d8`** — added to the script's candidate list (all six
  observed bases are now candidates; the HOT-band scan ran once, ~4 min, then found it).
* The stub did NOT die this time. The run stalled at **clk 2837** after ~4 h in-window —
  the WATCH event-board pause wanting its KICK OFF click — and was stopped there. The
  streamed jsonl banked clk 1020→2837 in full (~30.9 MB): in-window rate ~1 clk/9 s,
  free-run 0→1020 in ~20 min, exactly the s58 arithmetic.

## The four engine bugs the new ground exposed (in discovery order)

1. **`_steer_carrier_drag` compared the RAW world ball vx** where the binary rotates a
   stack copy of the ball velocity by -facing and compares the ROTATED forward component
   (disasm `0x5a92e9-0x5a92f2` rot, `0x5af33f-0x5a9346` compare; the Ghidra decompile's
   pre-rotation `iVar7` is an artifact). A ball kicked toward -x compared negative
   forever, so the knock-on re-fired EVERY tick, re-accelerating the ball with the
   carrier's ramping speed. First mismatch clk 1422; fixed → 1450.
2. **The resolver's ball-touch tail (fn_005aeda0 L491-607) was not ported** — the old
   "provably inert" claim was falsified at clk 1449-1450: silicon runs it on every
   LAB_005afabf route (bails included) and it is the mid-air deflection (probe at
   polar 0x9998/0x4ccc/self vs the live local_34 box; C550 power draw; engage
   ball→toucher, strong arm releases the carrier; **ball+0x70 = 0xc touch cooldown** —
   the once-only gate; C585 jitter draw; `ball.vel = trunc(ball.vel/16) +
   rot(scale_vec3(P.vel, power+0x20000), jit-jbase)`). Ported as
   `Pm98Resolver._touch_tail` via `_afabf`, threading the live `local_34`
   (0xc000 pre-draw, drawn reach+0x4000 after L196). NOTE: out-of-range play-states
   RETURN DIRECTLY in the C (L128-133) — they never reach the tail; wiring them through
   it regressed the frontier to 1160 before the revert.
3. **The header-block gate read a phantom match scalar.** The C reads
   `8 < *(*(target+0x184)+4)` — the target's TEAM-HEADER roster count (= 11 live), and
   L392 reads the resolver's own `gs+4`. The port read `m[4]`, absent from the live
   struct — the header block never ran outside fixtures (the tree-oracle template
   aliases T+0x184 → M, which is where the `m[4]` literalization came from). Fixed both
   reads to gs+4; `test_resolver_tree` fixtures now mirror the template's cross-refs.
4. **The header body was a stub of the real thing.** The C: `FUN_005a5430(this=TARGET)`
   — the remap LUT (LUT[6]=LUT[7]=10) clears t+0x2c/+0x30, which the port's bare
   `t[0x40]=` skipped (stale anim frame → a phantom 6/7 windup draw at clk 1495); the
   target's motion-lerp to polar(0x20000, t.face) over 0x30 steps (FUN_005a7220,
   this=target @0x5af374); the carrier release when the target holds the ball
   (FUN_0058ed50, this=ball @0x5af39e); and on the keeper-beaten roll,
   `match+0x440 = the TARGET POINTER` (not literal 1) + target stats +0xa4 = 1.

Also landed with s59 (committed separately as `f5ab46c`): the three `+0x43c` null
sentinels unified to the binary's model (player pointer, null = 0) — which this session's
touch tail then consumed (`is_same(m.get(0x43c, 0), p)` at the L558 stat swap), and the
finishing pre-block (fn_005aeda0 L41-118) ported as `_finishing_1b` (8-tick projections,
adj(t+0x398) roll, target caught → state 0x17 + 32-tick lerp + ball mirror + C102 draw).

## The kill test: the first goal is EXACT

The old framing ("port 11' vs reference 21'") died twice over. "21'" belonged to the OLD
M4 2-2 reference (seed 0x8abd86a4) — the capture2 5-2 reference for THIS fixture (seed
0xea0d2a8d) first-goals at **minute 8, Aston Villa, clk 2837, bank 0**. And the fixed
engine, run raw to full time (`diag_m5_s59_fork.gd`, GOAL lines, 34k ticks in ~9 min),
produces **exactly that: GOAL clk=2837 bank=0 score=1-0 min=8**. Same tick, same team.
It also retro-explains the s59 capture stall: silicon paused at clk 2837 because the
GOAL raised the events board — the port scores on the same tick the capture stopped.

Goals 2-7 (ref: 24' 35' 43' 53' 62' 71', 5-2) are NOT attributable via the raw loop —
after goal 1 the WATCH path consumes replay-cut draws (`Pm98Outer._replay_cut`) the raw
driver loop does not, so the trajectories legitimately fork (raw loop: 26' 51' 55',
1-3). Attribution needs the WATCH harness — and `run_match_from_struct.gd` is now the
blocker: post-s59 it grinds >5 h at full CPU without terminating (the raw engine does
full time in 9 min), i.e. the Outer WATCH wait-loop / goal-latch (+0x1a2c) interplay
spins after the first real goal. That harness-side loop is the next kill-test item.

## Still open

1. ~~The WATCH-path harness spin above~~ — **CLOSED 2026-07-28 by `5b25acd`**, and this
   line is corrected here rather than left to mislead a later session. It was the BOARD
   PAUSE, not the goal latch: under the dump's play-state 4 the wait loop breaks on the
   goal's `+0x1a2c` and `_dequeue_flush` then CLEARS it, so the next step had nothing left
   to break on and spun its whole 40,000-frame guard with the clock frozen. Two pieces of
   real binary state were missing headless — `+0x1a1f` (set from the global pause byte
   `DAT_00674cb3`, which is exactly what an events board sets) and the KICK OFF click,
   which reaches `FUN_00593ab0` as a nonzero pump result whose skip path arms `+0x1a1e`.
   `Pm98Outer.next_pump_result` is that injection point and `run_match_from_struct.gd`
   raises both on the frame after a pause-branch break. Two probes settled what was left
   instead of guessing: `PM98_TICK_PROBE` showed the driver returning 1 for eight ticks
   then 0 forever with clk/phase/dispatch frozen, and `PM98_PROBE_RESTART` showed
   `restart_handler` working when armed — so that hypothesis is killed, not hanging. A
   STALL GUARD now reports a frozen clock after 3 steps instead of hanging for hours.
   Goals 2-7 attribution is a RUN of that harness now, not a fix to it.
2. The ps-9 chase geometry (fn_005aeda0 L121-170) — still deferred, RNG-free, returns
   directly (no tail).
3. The cross-seed sweep (`PM98_SEED`) — still unrun.
4. The engine is still not the engine the app plays with (`MatchSim.simulate`).

## Reproduce

```bash
~/godot462 --headless --path app --import
PM98_CLK_LO=0 PM98_CLK_HI=2850 PM98_TICK_CAP=3000 \
  ~/godot462 --headless --path app --script res://tests/diag_m5_dart209.gd > port_2850.txt
C=~/MWM-AI/data/pm98-m4-oracle/capture2
python3 tools/re/m5_anchor_posdiff.py port_2850.txt $C/oracle_dartwatch_s59_1020_2837.jsonl 1 2836
```

Diff over an explicit `[1, hi]`; clk 2837 itself is the pause tick (thousands of
board-loop draws with the clock frozen) — cap at 2836.
