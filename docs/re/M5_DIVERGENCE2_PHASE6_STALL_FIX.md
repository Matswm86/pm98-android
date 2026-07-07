# M5 Divergence #2 — FIXED: the phase-6 keeper goal-kick distribution was deferred (s24, 2026-07-07)

Continues `M5_DIVERGENCE1_TRAJBUF_FIX.md` (s23). The trajbuf fix eliminated the phantom clk601 goal and
let the match play on, which surfaced a **phase-6 stall**: the ball rolls out near the goal, the keeper
catches it, the driver arms phase 6 (keeper-throw / goal-kick distribution), and the keeper then holds the
ball **forever** — 2833/4000 ticks frozen at the goal line, phase never leaves 6.

**Same bug class as the trajbuf bug: a load-bearing block wrongly dismissed as "a replay mode the headless
sim never reaches" and deferred with a bare `return`.**

## Root cause (empirical + decompile)

The driver's keeper-throw branch (`Pm98Driver._keeper_throw_branch`, decompile FUN_00598740) is byte-faithful:
it sets phase 6, `+0x19dc = 0x6a4`, and the taker, but does **no dispatch**. Phase 6 is cleared only by the
keeper actually distributing the ball. That distribution lives in `FUN_005a7260` (ball_touch_7260) L64-135 —
the block the port had deferred:

```gdscript
# OLD (Pm98Movement.gd:1625) — WRONG:
if _g(m, 0x448) == 6 and (act == 0x1f or act == 0x21 or ...):
    return                                          # DEFERRED slice-N replay prologue
```

`FUN_005a7260` is called from `engine_tick` (FUN_005a4600 L387-423) for the **GK-slot player (`+0x2bc == 0`)**.
`diag_m5_phase6.gd` confirms empirically: during the stall, team1's GK is the ball controller with
**action 0x1f, windup(+0x48) = 0** — it hits that deferred `return` every tick and never distributes.

## The fix (Pm98Movement.gd, oracle-locked)

Replaced the deferred `return` with the real phase-6 CPU/headless distribution (FUN_005a7260 L119-134):
aim at the (team-mirrored) goal line (`steer_8bc0`), and once the windup is 0, draw one match-RNG and take
`_dist_kick_aad30` (`_rscale15(rng,1000) < 200`, ~20%) or `_dist_kick_aae40` (~80%). The HUMAN branch
(L82-117, gated by `p+0x5c` = human-manager flag) is unreachable in CPU-vs-CPU headless and is `push_error`-
guarded rather than ported.

Both distribution leaves were extracted (`docs/re/move/fn_005aad30/aae40.c`) and ported:
- **`_dist_kick_aad30`** (path A, short goal-kick): sets keeper action `0x36`, snaps a polar-`0x40000`
  walk-up target, launches the ball to a polar-`0x39999` target.
- **`_dist_kick_aae40`** (path B, default): picks the nearest angle-aligned teammate from the relationship
  matrix (`p+0xe4` dist / `p+0xb8` angle) or, if none within `0x45ffff`, a blind polar-`0x120000` throw;
  sets keeper action `0x37`.

Actions `0x36`/`0x37` are the already-ported `feed_layoff_036`/`_037` handlers → `setup_shot` →
`resolve_post_shot` → **`set_phase(0)`**, which is what clears phase 6 back to open play.

### Oracle (invention guard)

`tools/re/run_distkick_oracle.sh` drives the REAL FUN_005aad30 + FUN_005aae40 under the PCode emu (keeper at
ECX, ball/match/team pointers wired, cos LUT injected, team count 0 so aae40 takes the blind-throw branch)
and banks every player+ball field write → `specs/distkick_oracle.txt` → `app/tests/test_distkick.gd`:
**ALL PASS (88 checks, 4 fixtures)**. The oracle confirmed the one genuine ambiguity — the polar split
(`0x40000` → player-move, `0x39999` → ball-launch) — and every literal field offset/constant.

## Result

- Phase 6 collapses from **2833 ticks (one endless stall)** to a single clean **25-tick** distribution
  episode (t1168-1192); the match then plays on to the 4000-tick cap in open play (clk 1143 → 3950).
- No regression: `test_7260`(60, the modified fn), `test_balltail`(108), `test_engine_tick`(182),
  `test_9490sliceC`(171), `test_65a0openplay`(760), `test_b1500family`(589), `test_ballpredict`(336) GREEN.

## NEXT divergence (#3, surfaced by this fix, NOT caused by it)

With phase 6 clearing, the goal-kick (an aae40 blind throw — no angle-aligned teammate was found) launches
the ball to **midfield (1521112, 321765, 0)**, where it comes to rest (`diag_m5_phase6.gd` FREEZE dump at
t2500: `vel=0 ctrl=0 armed=0`) and **no player chases it** — the nearest player is ~1.1M units away, the
outfield still shaped around the goal it was defending. So the match freezes again downstream, in open play,
on a loose ball nobody collects.

This is an **off-ball collection / loose-ball-pursuit** divergence (the OPENPLAY_TRACE "players don't
converge" family), NOT in the distribution code (which is oracle-locked). Chase next:
1. Verify against the reference whether the real keeper's goal kick finds an aligned teammate (i.e. is the
   blind-throw branch even correct here, or is the relationship-matrix angle state wrong at distribution time)?
2. If the blind throw is faithful, trace why no outfield player pursues the loose ball — the off-ball
   b1500/b1c80 "go to the ball" leaf. Decompile-diff, invent nothing.
(The authoritative M5 kill-test remains full-match scoreline == the M4 wine oracle — still pending, do it
after div#3.)

## Reproduce

- Stall gone / match plays on: `~/godot462 --headless --path app --script res://tests/diag_m5_tick_trace.gd`
  (phase-6 tick count 2833 → 25; clk reaches ~3950).
- Root-cause confirm + div#3 freeze: `res://tests/diag_m5_phase6.gd`.
- Oracle + lock: `bash tools/re/run_distkick_oracle.sh` ; `res://tests/test_distkick.gd`.
