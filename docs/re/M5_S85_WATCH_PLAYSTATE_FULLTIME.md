# M5 s85: the WATCH harness reaches FULL TIME, and the reason it never could

Status: **the whole match runs.** `run_match_from_struct.gd` now drives the byte-loaded
engine from frame 0 to **dispatch code 10 (FULL TIME)** in 37,059 outer steps — the first
time the WATCH path has left the first goal at all. The frontier moves from "deadlocks at
clk 3885" to "goal 2 is two minutes late".

`Evidence:` `app/tests/run_match_from_struct.gd`, `app/scripts/Pm98Outer.gd`,
`extracted/Premier Manager 98/MANAGER.EXE` @0x593b3a, `~/MWM-AI/data/pm98-m4-oracle/capture2/`.

## 1. The result

| | port | reference (capture2, seed 0xea0d2a8d) |
|---|---|---|
| goal 1 | **8' Aston Villa, clk 2837, bank 0, rng 1082620623** | **8' Aston Villa, clk 2837, bank 0** |
| goal 2 | 26' Bolton W, clk 8469 | 24' Bolton W |
| goals 3-7 | — | 35' 43' 53' 62' 71' |
| full time | **dispatch 10, +0x450=14400 +0x19a8=14400 half 1** | full time |
| final | 1-1 | 5-2 |

Goal 1 is still bit-exact — same clock, same bank, same RNG state — so nothing in this
change touched the validated clk 1-2836 window. Goal 2 has the **right team** and is two
minutes late, which is the shape of a divergence somewhere in 2837 < clk < 8469 rather than
a structural break: that is the new frontier and it is a normal M5 localisation job.

## 2. Why it could never have worked before

The capture's frame-0 dump has session `+0xfa0 = 4`, and the harness kept that for the whole
match. Under play-state 4 every outer frame takes `Pm98Outer._pause_branch`, and **that
branch cannot leave a set-piece with no user input.** Two independent reasons, both read out
of the binary rather than inferred:

* the wait loop's break set is `+0x1a19` / `viewing` / `+0x1a2c` with a code test / `code
  == 10` / `+0x1a1f`, and **the code test explicitly excludes codes 3 and 4**
  (`code != 3 and code != 4`). A throw-in / goal-kick restart raises exactly code 3;
* nothing in the branch arms `+0x1a1e` either. `FUN_00593ab0` (the wait frame) discards its
  driver tick's return and reaches the arm ONLY through the nonzero-pump skip path:

```
0x593ae9  call 0x598740          ; one driver tick, return DISCARDED
0x593afc  call 0x5bce40(0)       ; the message pump
0x593b30  mov cl,[0x6d31c4]      ; playback flag (0 live)
0x593b3a  test eax,eax
0x593b3c  je 0x593b65            ; pump == 0 -> RETURN, no spin, no arm
0x593b3e  call 0x598740 ...      ; spin to segment end
0x593b5e  mov byte [esi+0x1a1e],1
```

Measured with the new `PM98_WAIT_PROBE` (below), not argued: after the clk-2837 goal the
match restarted correctly and played on to **clk 3885**, raised **dispatch code 3**, and
then spun the full 40,000-frame guard with `clk / +0x1a1e / +0x1a1f / +0x1a2c` all frozen.

**So the real game is not in play-state 4 there.** 4 is the EVENT BOARD — the state the dump
was taken in, before the user has clicked KICK OFF. A WATCH match in progress is play-state
**2** (`FUN_005943f0`, viewing), which is the state whose per-frame wait-loop break IS the
WATCH pacing and the state `Pm98Outer._replay_cut` is gated on — the very draws
`handoff-pm98-m5-s59-frontier-2836` says the WATCH path consumes and the raw driver loop
does not.

## 3. The fix, and why it is a model and not a workaround

The KICK OFF click the harness already injects (one per board pause, `next_pump_result = 1`
plus `+0x1a1f`) is exactly the click that DISMISSES the board. The career layer owns
`+0xfa0`, so the harness now drops it to 2 on that same click. The board pause and its
dismissal are one event and are modelled as one event.

Cross-checked both ways before it was adopted: `PM98_FORCE_PS=2` from frame 0 produces the
identical goal 1 (clk 2837, rng 1082620623) and the identical full time, so the change costs
nothing on the window nine oracle captures already pin. `PM98_FORCE_PS` stays, as the A-B.

## 4. Two harness instruments this needed

* **`PM98_WAIT_PROBE=<n>`** (`Pm98Outer._wait_probe`) prints the wait loop's own state every
  n frames. A `WAIT_LOOP_GUARD` breach only says "the loop never broke"; the break set has
  five members and each is a field the driver tick may or may not have moved, so watching
  them is the only way to name the dead rung. Off by default, read once.
* **`STALL_STEPS_LIVE`.** The stall guard's threshold depends on what one step IS. Under the
  pause branch a step is a whole wait loop — thousands of ticks — so three frozen steps is a
  dead match. Under the live branch a step is ONE FRAME, and the clock legally stands still
  for every frame that is not phase 0: the phase-2 kickoff alone eats ~24 and a set-piece
  eats hundreds. The old flat 3 fired on a perfectly healthy play-state-2 match at clk 0.

## 5. What this closes and what it does not

**Closes:** "the M5 set-piece leaves — full time, goals 2-7 — are a RUN of the harness, not
a fix to it". They were not: the harness could not reach them. It can now, and full time is
attributed.

**Does not close:** goals 2-7 themselves. Goal 2 is 26' against the reference's 24', same
team, so there is a real divergence between clk 2837 and clk 8469 to localise — the same
kind of work as every previous frontier step, with the same tools (`m5_*_posdiff.py`, the
Z2 dartwatch captures). Stoppage time and the cross-seed `PM98_SEED` sweep are still unrun.

**Unchanged:** the engine is still not the engine the app plays with. `MatchSim.simulate`
is, and since s74 that IS the original's own stat engine, so this is the fidelity of the
match VIEW, not of results.
