# M5 s37 — t1.i9 arm-step drift LOCALIZED to the FUN_005b0040 (`_b0040_target`) steer target

Continues [[handoff-pm98-m5-t1i9-target-2026-07-14]] (s36). s36's BLOCKER was: the
armwatch captures never dumped the steer `target_pos` passed to `FUN_005a89c0` for
t1.i9, so the 1.67-deg first-step heading error could not be attributed to a leaf term.

**s37 closed that blocker with a live capture, and localized the divergence to a single
leaf: the target returned by `FUN_005b0040` (port `_b0040_target`).**

## Tooling built — `tools/re/wine/m5_gdbrsp_steertgt.py`

A raw-RSP harness that sets a **code breakpoint at `FUN_005a89c0` (0x5a89c0)** and, at every
hit where `ECX == t<team>.i<idx>`'s player VA, dumps the steer TARGET + the caller leaf:

- `FUN_005a89c0` is `__thiscall` (ECX=player) and forwards its stack `param_2` straight to
  `FUN_005a8bc0`, which reads the target as three i32 at `[param_2 + 0/4/8]`
  (`docs/re/move/fn_005a8bc0_FUN_005a8bc0.c` L37-39). So at the 89c0 entry:
  `ret0=[esp]` = the caller leaf, `[esp+4]=param_2` → target ptr, `[esp+8]` = speed_scale.
- Filters to one player (default t1.i9), writes only matched stops. Z0 → Z1 (HW-exec)
  breakpoint fallback (the winedbg stub rejected Z0, accepted Z1).

## The drive (self-consistent, no seed-poke needed)

The port's s36 replay used capture2's frame-0 (`FRAME0_SEED=0xea0d2a8d`). A fresh drive
gets a different seed, so instead of chasing capture2's exact state, s37 made a
**self-consistent pair from ONE fresh drive**:

1. Re-drove the EXACT capture2 walkthrough on headless Xwayland `:2` — Manager League →
   TRAINER → name "MWM" → **Bolton W** (away, team1) → preseason opp **Aston Villa** (home,
   team0) at Villa Park → WATCH → KICK OFF screen. Verified every screen against capture2's
   `s0x_*.png`.
2. At the clean KICK OFF pause: `dump_mem.py full` → fresh frame-0 (seed **`0xc357aa2c`**),
   `m4_struct_import.py` → `frame0_struct_import.json`. Persisted with the silicon jsonl +
   regions at `~/MWM-AI/data/pm98-m4-oracle/steertgt_2026-07-15/` (data dir, not git).
3. Attached `winedbg --gdb` (ptrace_scope lowered to 0 for the drive), ran the harness,
   clicked KICK OFF → captured t1.i9's 89c0 target for clk 0-3 (silicon).
4. `app/tests/diag_m5_t1i9_steertgt.gd` replays THAT fresh frame-0 + seed `0xc357aa2c`
   (port) and dumps t1.i9 per tick. Both sides now describe the SAME state.

## Result — aligned by ACT + SPEED (position confirms the alignment)

| step | silicon (live 89c0 capture) | port (`diag_m5_t1i9_steertgt`) |
|------|-----------------------------|--------------------------------|
| unarmed (act0, spd0) | pos **(26214, 98304)** face **0xb563** | pos **(26214, 98304)** face **0xb563** — **byte-identical** |
| **arm (act1, spd262)** | pos (26145, 98050) face **0xb53d** target **(12361, 47217)** | pos (26150, 98049) face **0xb606** target **(1647, 2)** |
| +1 | pos (26007, 97544) face 0xb537 spd **524** (keeps ramping) | pos (26150, 98049) spd **0** (DE-ARMS) |

- The unarmed step is **byte-exact** (same pos + face), so the states are genuinely aligned;
  the arm-step positions differ by only 5px (same order as s36's 722663 vs 722658).
- **The divergence is one value: the arm-step steer TARGET.** Silicon `(12361, 47217)`;
  port `(1647, 2)` — a near-origin (y≈0) garbage point. From that wrong target the port's
  heading is `0xb606` vs silicon `0xb53d` (Δ +0xC9), and one tick later the port **de-arms**
  (speed → 0) while silicon keeps ramping. The wrong arm target is the ROOT; everything
  after cascades from it.
- **Leaf named:** every matched silicon row has `ret0 = 0x5b04cb` — the return site inside
  `FUN_005b0040`, immediately after its tail `FUN_005a89c0(uVar13, 0x5a)` call
  (`docs/re/move/fn_005b0040_FUN_005b0040.c` LAB_005b04a6 L131-132). So the target is
  whatever `FUN_005b1330(local_c, m+0x1828)` produced, i.e. the output of the port's
  `_b0040_target` (`app/scripts/Pm98Movement.gd:1559`). scale 0x5a confirmed on both sides.

## What is NOT yet pinned (the NEXT lever)

`_b0040_target` builds `local_c` from the ctrl/ball object (`p+0x190`): its velocity
`+0x20/0x24`, the carrier point `+0x84..`, the formation markers `+(idx+0x17)*0xc`, and the
`+0xcc/+0xd0/+0xe0` marker-adjust points, then clamps into `m+0x1828`. The s37 capture
dumped only the RESULT target, not those INPUTS, so we cannot yet say whether the port's
b0040 gets wrong INPUTS (ball velocity / markers already drifted) or right inputs but a
wrong COMPUTATION. Both produce `(1647, 2)`.

Also observed: silicon calls 89c0 at the UNARMED step too (target `(11420, 43624)`, a smooth
predecessor of the arm `(12361, 47217)`), but the port emits NO steer at the unarmed ticks
(its formation gate early-returns). Position is byte-exact there (speed 0, no drift), but it
hints the port reaches the b0040 steer one tick late.

## NEXT (in order)

1. **Extend `m5_gdbrsp_steertgt.py`** to also dump, at the t1.i9 arm stop, the ctrl object
   (`p+0x190`) input fields `_b0040_target` reads: `+0x20/0x24` (ball vel), `+0x28`, `+0x34`
   (ball facing), `+0x84/0x88`, `+0xb0/0xbc`, `+0xcc/0xd0/0xd4`, `+0xd8/0xdc/0xe0`, plus the
   formation-marker slots `(idx+0x17)*0xc`. Re-drive Villa/Bolton (same walkthrough), feed
   the same fresh frame-0 to `diag_m5_t1i9_steertgt.gd`, and diff INPUT-by-INPUT to name the
   exact term that makes port `_b0040_target` return `(1647,2)` instead of `(12361,47217)`.
2. Trace `_b0040_target` internals port-side for this state (it is deterministic from the
   frame-0 struct) — log `to_common`, the loop's `point`/`lead`, the clamp inputs — to see
   which branch/term collapses to the near-origin point.
3. Then apply the same INPUT-capture to t0.i8 (clk 60) / t0.i9 (clk 80) one-quantum onsets.

## Repro

- Silicon: `~/MWM-AI/data/pm98-m4-oracle/steertgt_2026-07-15/steertgt_t1i9_silicon.jsonl`
  (harness + winedbg stub; drive per `tools/re/wine/README.md` §Reproduce; needs
  ptrace_scope=0 for the live drive; the game dies on detach — capture first).
- Port: `~/godot462 --headless --path app --script res://tests/diag_m5_t1i9_steertgt.gd`
  (offline, reads the persisted frame-0 struct; reproduces target `(1647,2)` at t=26).

Oracle suites unaffected — no production code touched this step (harness + diag + doc only).
