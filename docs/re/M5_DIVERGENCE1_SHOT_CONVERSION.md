# M5 Divergence #1 — it is SHOT CONVERSION, not movement (s21, 2026-07-07)

Continues `M5_DIVERGENCE1_OPENPLAY_TRACE.md` (s20). That session localized the port's
premature clk601 goal to "an uncontested ~540-tick dribble" and framed the open question as
**carrier movement** (candidate 1: carrier too fast/direct) vs **defence tackle** (candidate 2).
This session ran the s20 handoff's own "decisive next action" — driving the REAL engine and
comparing to the port — and the answer is that **both s20 candidates are wrong**: the port's
movement is faithful; the divergence is that the port **CONVERTS a shot the real engine's
physics send over/wide.**

## Method (this session actually drove the real engine)
1. **Static leaf audit** — ran every movement/keeper oracle-parity test. ALL GREEN:
   `test_65a0openplay` 760, `test_b1500family` 589, `test_steering` 132, `test_b1420` 16,
   `test_settle` 72, `test_keeperadv` 32, `test_restartdecide` 122 = **1,855 checks bit-exact**.
   So per-function movement math is faithful; any divergence is emergent.
2. **Ground-truth field check** — dumped `0x2bc` for all 22 frame-0 players
   (`frame0_struct_import.json`): it is the slot index 0..10, slot 0 = role 1 = GK in both
   teams. So the `p[0x2bc]==0` gate at `Pm98Action.gd:343` is **GK-only** → `ball_touch_7260`
   never moves the outfield carrier. The s20 "deferred dribble-grid" sub-suspect is **eliminated**
   for outfield play. (The port's own "not on pitch" comments at `Pm98Movement.gd:23,136` are
   mislabeled; the gate BEHAVIOUR matches the s20 GK reading.)
3. **Live real-engine capture** — booted the real `MANAGER.EXE` under wine (Xwayland :2 on
   cosmic-comp), drove the menu to a WATCH Aston Villa vs Bolton W friendly (same fixture as the
   M5 reference), found the match base with `m4_findbase.py` (0x03dbf188), and captured a NEW
   **per-tick ball + carrier trajectory** with `tools/re/wine/m5_poll_traj.py` (NEW — a superset
   of `m4_poll.py` that also reads ball xyz/vel and derefs the ball controller ball+0x40 → the
   carrier's slot/team/x/y/act). Fresh seed `0x0f0f82bf` (NOT the reference `0xea0d2a8d` — so this
   is a same-ENGINE, different-SITUATION reference, see caveat). Data preserved at
   `~/MWM-AI/data/pm98-m4-oracle/m5_traj_capture_2026-07-07/m5_traj_timeline.jsonl`.

## What the real engine does (12,500+ trajectory rows, first half + into second)

### Long single-carrier dribbles are NORMAL — the port's is not anomalous
The real engine routinely lets ONE carrier hold the ball 300–950 ticks and advance millions
of units downfield, uncontested, exactly like the port:

| carrier | ticks held | downfield x-span |
|---|---|---|
| PORT (reference frame-0) | 541 (clk 13→554) → **GOAL** | ~2.2M |
| real t0/#6 | 575 (clk 123→698) | 2.57M |
| real t0/#8 | 632 (clk 3974→4606) | 3.27M |
| real t0/#7 | 949 (clk 5568→6517) | 3.48M |

→ **Candidate 1 (carrier too fast/direct) is refuted.** The real carrier is not slower.

### The real engine SHOOTS like the port — but misses
26 open-play releases; **12 are shot-class** (post-release ball speed > 15000), peak **37,287**
and **34,746** from carrier_x 2.7–3.5M — comparable to / faster than the port's 35,547 from
2.19M. And yet the real match was **0-0 through clk 6729** (past the reference's clk-2837 first
goal); goals only came later (2-1 by half-time). The real engine takes the same power shots and
does not convert them early.

### WHY the real shots miss vs why the port scores — the mechanism
Tracing real shots vs the port's goal shot (all velocities are ball +0x20/+0x24/+0x28):

| | release vel (vx, vy, vz) | flight | outcome |
|---|---|---|---|
| **PORT goal** (t580, x=2.19M, y=70k) | (35547, **2183**, **3494**) | flat: z peaks low, y stays in mouth | **straight into goal** |
| real shot A (clk4606, x=2.76M, y=-149k) | (33028, **10793**, ~6742) | **lofts to z=101,020**, vx collapses at x=3.46M | over/short — no goal |
| real shot B (clk4891, x=3.56M, **y=1.02M**) | (11865, **-32359**, …) | crosses line at **y=469k > mouth 240k** | **wide** — phase→8 restart |

The port's goal shot is anomalously **flat (vz=3494) and straight (vy=2183)**; the real shots
carry ~2× the loft and 5×+ the lateral spread (or are taken from a wide y), so they balloon
over the bar / drift outside the goal mouth (|y| < 0x3a8f5 = 239,861 at the goal line x=0x398000
= 3,768,320). **The port converts because its shot flies dead-straight along the ground into the
mouth; the real engine's comparable shots do not.**

## Verdict
The M5 divergence #1 is in the **shot / kick-trajectory / ball-launch path**, NOT movement and
NOT the keeper (keeper placement y=±0x250000 and the X-only tracker are BOTH oracle-GREEN =
identical in both engines). This **overturns the s20 conclusion** ("a MOVEMENT / ball-CONTEST
problem, not a shot-conversion problem") and **restores the s19 instinct** (the shot at clk~555).
s20 was right that it is a *real kick* (not a fabricated resolver goal); it was wrong that the
kick's flight is faithful. The port's ball leaves the carrier too flat and too straight.

## Ruled OUT this session (with evidence, do not re-investigate)
- Carrier movement / dribble speed — real carriers dribble just as far/fast (table above) + all
  movement leaves oracle-GREEN (1,855 checks).
- `ball_touch_7260` deferred dribble-grid — GK-slot-gated, never runs for the outfield carrier
  (`0x2bc` = slot index, slot 0 = GK, verified against 22-player frame-0 ground truth).
- Keeper mispositioning — `keeper_restart_decide` (y=±0x250000) and `keeper_advance` (X-only)
  are BOTH oracle-GREEN; the real keeper sits in the same place. Not the cause.
- Set-piece / restart shape — the reference buildup to goal-1 is one continuous phase-0 sequence
  (clk 0→2837, disp stays 0), same shape as the port. No restart difference.

## NEXT (priority) — pin the shot-velocity computation
The ball launch velocity (35547, 2183, 3494) is set by the case-0x13 shot handler
(`FUN_005ac1a0` setup_shot → the L137-193 "kick-aim teammate search + ball launch" block noted
in `Pm98Action.gd`'s engine_tick CAVEAT) and/or `resolve_post_shot` (`FUN_005ab5a0`). Audit
whether the port under-computes the shot's **vy lateral spread and vz loft** vs the decompile:
1. Shot-leaf oracle tests were RUN this session and are **ALL GREEN**: `test_shotsetup` 182,
   `test_postshot` 162, `test_engine_scorers` 645 = 989 checks bit-exact. So the shot vector is
   **emergent too** — the launch math is faithful in isolation; a full-state INPUT to the shot
   handler (aim target, power, or loft source) differs for the port's specific state. This makes
   step 2 (exact-seed same-situation capture) the only way to see which input diverges. (There is
   no leaf left to blame in isolation — 2,844 movement+keeper+shot checks are all GREEN.)
2. **Decisive same-situation confirmation** (de-risked: the full wine pipeline is proven this
   session): re-drive the WATCH Villa-Bolton match, POKE seed `0x006d3184 = 0xea0d2a8d` at the
   kickoff frame (phase 2, frame-0) so the real engine runs the EXACT reference frame-0, and
   capture with `m5_poll_traj.py`. Confirm the real engine, from the identical state, either does
   not take the clk~555 shot or takes it and misses (real first goal clk2837). Then diff the real
   vs port launch velocity for that exact shot — the delta IS the bug. Racy poke (seed advances
   per frame); use a tight poke loop at the phase-2→0 transition.

Do NOT invent aim/loft constants — every value from the decompile / the emu oracle.

## Artifacts
- NEW `tools/re/wine/m5_poll_traj.py` — ball+carrier trajectory poller (offsets verified:
  ball embedded at match+0x1610, ball.x=+0x1614, ctrl=+0x1650 → player VA; carrier slot=+0x2bc).
- Real capture `~/MWM-AI/data/pm98-m4-oracle/m5_traj_capture_2026-07-07/` (timeline.jsonl +
  frame-0 meta + kickoff/live screenshots). Fresh seed 0x0f0f82bf, Villa vs Bolton WATCH.
- Port CSV (regen): `diag_m5_tick_trace.gd` → scratchpad `m5_tick_trace.csv`.
