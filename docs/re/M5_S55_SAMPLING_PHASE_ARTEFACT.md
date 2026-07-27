# M5 s55: the parity frontier was a measurement artefact — clk 270-660 is clean, all 22 players

Evidence: tools/re/wine/m5_rsp_capture.py, tools/re/m5_clk_posdiff.py, app/tests/test_driver_advance_engine.gd
  -- the capture harness, the differ whose SAMPLING PHASE was the artefact, and the suite that stayed green through it.

s54 handed over "push the frontier past 651 — the other four forking players (t1.i3/4/5/8/9)".
Those four are not forking. Neither were the three at clk 587, nor the ones at 630, nor the
clk-643 freeze that the s54 fix removed. **The per-clk differ's alignment premise is false**, and
once the measurement is corrected the port matches silicon over every capture we hold —
clk 270 to 660, all 22 players and the ball, within one tick of sampling phase.

Tool: `tools/re/m5_seq_posdiff.py` (new). Capture: `oracle_dartwatch_s55_555_655.jsonl` (new,
5652 stops, this session's boot).

## 1. The false premise

`tools/re/m5_clk_posdiff.py` says, in its own docstring:

> A Z2-stopped dartwatch capture carries several stops per clk, and the LAST stop of a clk is
> the settled end-of-tick roster — the same instant the port dump records.

The second half is wrong. The Z2 watchpoint is on the **LCG seed**, so it only stops on an RNG
**draw**. Any player the sim moves *after* the tick's last draw is read PRE-move, and its row
carries the **previous** tick's position. The number of draws per clk varies (6 to 14 in the s55
capture), so which players are read post-move changes tick to tick.

The signature is unmistakable once you look for it. s55, t1.i8:

```
clk   silicon (last stop)        step        port                    port-silicon
586   (869193, -648238)      +6158,+1136     (869193, -648238)          0,     0
587   (869193, -648238)          0,    0     (875353, -647102)      +6160, +1136   <- "FORK"
588   (875353, -647102)      +6160,+1136     (881515, -645975)      +6162, +1127
589   (881515, -645975)      +6162,+1127     (887679, -644857)      +6164, +1118
590   (887679, -644857)      +6164,+1118     (893839, -643730)      +6160, +1127
591   (893839, -643730)      +6160,+1127     (899994, -642565)      +6155, +1165
592   (906140, -641353)     +12301,+2377     (906140, -641353)          0,     0   <- re-aligns
```

`port[clk=N] == silicon[clk=N+1]`, exactly, every tick — the port is not ahead, the *sample* is
behind. At clk 592 the tick happens to carry 11 stops instead of the usual 6-9, the last one
lands after the move, silicon "takes a double step" of +12301 (two ticks in one row) and the
columns line up again. A trajectory that re-aligns on its own is not a fork.

The same artefact explains the whole recent series: clk 587 (t1.i8/i9/i10), clk 630
(t1.i4/i5/i8/i9), the clk-643/651 t1.i10 frontier. **s54's fix is untouched by this** — it was
verified by an instant-exact comparison at the `FUN_005b0040` entry the trace itself recorded,
which never used this alignment. What was wrong was the frontier *number*, not the fix.

## 2. The corrected test

`m5_seq_posdiff.py` drops alignment entirely. A capture row `(clk, player, pos)` PASSES iff the
port holds that player at that **exact** position at some clk in `[clk - TOL, clk + TOL]`
(`PM98_CLK_TOL`, default 2). Nothing is collapsed and nothing is phase-corrected: each sampled
instant is checked on its own against the port's own per-clk position, so a one-tick sampling
phase costs nothing while a coordinate the port never holds still fails.

Two earlier drafts of this tool were wrong and are worth recording so they are not rebuilt:
* collapsing each side to its distinct-position sequence and comparing index-by-index — breaks on
  the ticks the capture drops entirely (s55 clk 591→592 skips the (899994, -642565) the port
  passes through);
* subsequence matching without a clk bound — a player that revisits a coordinate matches an
  occurrence 130 ticks away and the "MATCH" means nothing.

## 3. Result

Port side: `diag_m5_dart209.gd`, `PM98_CLK_LO=0 PM98_CLK_HI=700` (dump wider than the window —
the ±TOL lookup needs the neighbouring ticks).

| capture | window | players | ball |
|---|---|---|---|
| `oracle_dartwatch_s45_ext` | 270-302 | 22/22 PASS | (no ball rows) |
| `oracle_dartwatch_s47a_300_588` | 300-588 | 22/22 PASS | 289/289 |
| `oracle_dartwatch_s51_630_660` | 630-660 | 22/22 PASS | 31/31 |
| `oracle_dartwatch_s53_arm_630_660` | 630-660 | 22/22 PASS | 31/31 |
| `oracle_dartwatch_s55_555_655` (new) | 555-655 | 22/22 PASS | 101/101 |

All of it holds at `TOL=1` as well; `TOL=0` fails (7 and 16 players on the two big captures),
which is the one-tick sampling phase itself and is the expected result, not a defect. The ball is
checked against **every** stop of its clk, not the last one — it moves several times per tick.

Cross-check that the captures are the same run: s51 and s53 (older boots) agree with s55 **0/572
mismatched player-clks** over their common window, so the boot is reproducible and the older
captures are sound. The "forks" were never in the data.

## 4. What is actually open

* **Beyond clk 660 is unmeasured.** Every capture stops there; a match is 14400 clks. A longer
  Z2 capture (650-1250) is the next evidence. Until it lands, "parity to 660" is the honest claim
  and nothing beyond it is known either way.
* **Positions only.** The differ checks player x/y and ball x/y. Velocities, orientation
  (`+0x17c/+0x180`), possession and the event queue are captured but not yet diffed.
* **TOL slack.** A fork that resolves inside TOL ticks is invisible. Re-check a suspicious window
  at `PM98_CLK_TOL=1`.
* **A stationary player passes trivially.** Read the moving ones — the per-player line reports the
  move count.

## 5. Files

* NEW `tools/re/m5_seq_posdiff.py`
* NEW capture (out of repo) `~/MWM-AI/data/pm98-m4-oracle/capture2/oracle_dartwatch_s55_555_655.jsonl`
* `tools/re/m5_clk_posdiff.py` — premise now documented as unsound for late-moving players
