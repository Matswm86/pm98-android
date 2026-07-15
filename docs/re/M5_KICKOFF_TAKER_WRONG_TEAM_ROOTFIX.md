# M5 s40 — the kickoff wrong-direction ROOT FIX: taker was selected from the wrong team

Continues [[handoff-pm98-m5-t1i9-kickoff-ball-trajectory-2026-07-15]] (s39c). s39 correctly
re-rooted the t1.i9 arm-step drift to a **wrong-direction kickoff kick** (port 108.9° up-LEFT
vs silicon 75.3° up-RIGHT; X-sign flipped) and told the next session to "name the exact
function that writes the ball velocity `(−4338,12667)` at tick 26 and fix the X-sign /
attack-direction term." This is that fix. The X-sign was NOT an arithmetic flip inside any
oracle-locked function; it was **the kickoff taker being picked from the wrong team**, so the
ball was kicked into the wrong half.

## How it was found (fully offline, no live drive)

Added a **gated ball-velocity change-probe** to `Pm98Driver.tick` (`ballvel_probe`, gated on
`Pm98Rng._log_on`, zero effect when off — same precedent as `b0040_trace`). It records a row
each time `ball+0x20/+0x24` changes across a tagged tick sub-phase. Repro:
`~/godot462 --headless --path app --script res://tests/diag_m5_ballvel_writer.gd`.

The probe named the writer in three narrowing passes:
1. **`_movement_core`** → the change happens at `adv t0.i9` (the kickoff taker's `engine_tick`),
   then `ball_advance` roll-friction trims it. So it IS a player kick — **s39b/s39c's "frozen,
   no kick action" was a measurement artefact**: the kick action lives transiently inside
   `engine_tick` and was cleared before their pre/post-tick snapshot.
2. **`engine_tick`** → the vel is set in `_action_switch` for **action 0x4** →
   `Pm98Movement.goal_aim_025` → `setup_shot`, which writes `ball+0x20/24 = polar(power, atan(aim−ball))`.
3. **`goal_aim_025`** → `aim = target.pos`, `target = ball[0x4c]`. A gated dump of the target
   showed: **taker = t0.i9 (team 0)**, target = t0.i10 (team 0) at **(−225152, +655361)** →
   the kick aimed into team-0's OWN half (−x), angle 108.9°.

## The inconsistency

Dumping the kickoff-side flags at the kick tick:

```
m[0x45c]=1  m[0x19c8]=1   (kicking side = team 1, Bolton W away)
taker (m[0x438]).team = 0 (team 0, Aston Villa)     <-- WRONG
```

The kicking side is **team 1**, but the taker was a **team-0** player. Team 0 attacks +x, so
its kickoff partner sits at −x behind the spot → the ball is kicked toward −x. Silicon's ball
goes +x because silicon's taker is a **team-1** player (team 1 attacks −x, partner at +x → ball +x).

## Root cause (disasm-proven) — `FUN_00593b70` selects the taker from `team[m[0x45c]]`

`restart_handler` set `m[0x438] = select_active(_sim_ctx(m, 0))` — **hardcoded team 0**. The
binary uses the KICKING SIDE. Disasm of `FUN_00593b70` at the `FUN_005b8f20` (select_active)
call site:

```
593f02:  8b 85 5c 04 00 00   mov  eax,[ebp+0x45c]     ; eax = m[0x45c] = kicking side
593f08:  8d 04 80            lea  eax,[eax+eax*4]      ; *5
593f0b:  8d 04 80            lea  eax,[eax+eax*4]      ; *25
593f0e:  c1 e0 05            shl  eax,0x5              ; *32  -> eax = 0x320 * side  (0x320 = team stride)
593f11:  8d 8c 28 6c 04 00 00 lea ecx,[eax+ebp+0x46c]  ; ecx = &match.team[side]  (m+0x46c + 0x320*side)
593f18:  e8 03 50 02 00      call 0x5b8f20             ; select_active(team[side])
593f23:  89 85 38 04 00 00   mov  [ebp+0x438],eax      ; m[0x438] = result
```

`FUN_005b8f20(param_1)` reads `param_1[0x4e]`=match, `param_1[0]`=players, `param_1[1]`=count,
`param_1[0x5a]`=active — it is a TEAM ctx, and the disasm passes `team[m[0x45c]]`, not team 0.
The old `_sim_ctx(m, 0)` was faithful only when `m[0x45c]==0`; with `m[0x45c]==1` it took the
wrong team. `FUN_005b70e0` x2 (decide + `kickoff_partner_placement`) and `FUN_005b73a0` x2
(position) still iterate BOTH teams (loop `esi += 0x320`), so only the select_active line was wrong.

## The fix (`app/scripts/Pm98Driver.gd`, `restart_handler`)

```gdscript
var ctx_side := _sim_ctx(m, _g(m, 0x45c))          # was _sim_ctx(m, 0)
if not ctx_side.is_empty():
    m[0x438] = _active_ref(ctx_side, Pm98Movement.select_active(ctx_side))
...
for ti in 2:
    var ctx := _sim_ctx(m, ti)                     # decide/partner loop unchanged (both teams)
```

No oracle-locked function was touched. This corrects ALL restart types (throw-in, corner,
goal-kick, kickoff), not just kickoff — the team-0 hardcode was wrong whenever `m[0x45c]==1`.

## Verification (offline, no ptrace / no live drive)

- Kick direction now **75.33°** (`ball vel (1345,5138)` at the kick tick) vs silicon's **75.3°** —
  the X-sign flip is gone; the ball goes into team-1's half (+x).
- **t1.i9's `_b0040_target` reproduces the s37 silicon capture BYTE-EXACT** at the post-kick ticks:
  `(11420, 43624)` (unarmed) and `(12361, 47217)` (arm). The whole s36→s39c arm-step-drift chase
  resolves for free once the ball travels silicon's direction — the leaf was always byte-correct.
- Oracle/unit tests GREEN: test_driver 34, test_b0040 56, test_balladvance 110, test_decideC 70,
  test_decideCtaker 54, test_decideC3 91, test_decideset 84, test_decideReplay 40,
  test_kickoff_init 61, test_shotsetup 182, test_driverleaf/leaf2 14/14, test_driver_advance_engine 5,
  test_menu_screen / test_match_screen PASS. (test_driver's 2 tolerated `'sim'` SCRIPT ERRORs are
  pre-existing — confirmed by stash-run.)

## Still open (needs a fresh live drive; ptrace_scope→0, flagged for Mats)

- **Timing:** the port now kicks at diag-tick 43 (team-1 taker windup) vs the old wrong-team kick
  at tick 25. Whether tick 43 matches silicon's kickoff tick is UNCONFIRMED without a new silicon
  capture (s39 NEXT step 2). The DIRECTION + the byte-exact b0040 targets are the decisive result;
  the absolute kick tick is the remaining parity check.
- silicon-side taker identity was never directly captured (s39b caveat); this fix makes the port
  internally consistent with the disasm and reproduces silicon's ball trajectory + b0040 targets,
  which is the available ground truth.

## Repro / probe

- Reproducer: `app/tests/diag_m5_ballvel_writer.gd` (loads the persisted frame-0 at
  `~/MWM-AI/data/pm98-m4-oracle/steertgt_2026-07-15/`, seed `0xc357aa2c`).
- The gated probes (`Pm98Driver.ballvel_probe` + the `et:*` engine_tick sub-phase probes +
  `Pm98Movement.goalaim_trace`) stay in-tree, gated on `Pm98Rng._log_on`, for future match-engine
  velocity-writer chases.
