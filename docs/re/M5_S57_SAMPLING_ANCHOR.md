# M5 s57: the orientation fork does not exist — the differ was sampling mid-tick

s56 widened `m5_seq_posdiff.py` past x/y and reported an `orient17c`/`orient180` fork at
clk 657 and systematically across team 0 at clk 801, secondary forks on `curve6c`,
`lock5c` and `guard2d7`, and a ball possession/dead-ball divergence at clk 721 where
"silicon has the ball stopped and owned, the port has it moving".

**None of them are real.** Over clk 1-830 — the whole extent of the Z2 capture — the port
is byte-exact to the silicon on every field the capture carries, at ZERO tolerance:

```
# anchor 0x5910fd, port clk == silicon clk -1, clk [1, 830]
# anchor verified once-per-tick over 830 ticks
  RNG         830 rows  EXACT
  t0.i0 .. t1.i10   181 rows each  EXACT      (22 players x 16 fields)
  BALL        181 rows  EXACT                 (10 fields)
  BTRAJ       181 rows  EXACT                 (48-int trajectory buffer + 3 seg lengths)
RESULT: byte-exact -- 75583 words compared over clk [1, 830], 0 mismatches
```

75,583 words compared, 0 mismatches (830 LCG states + 181 roster ticks x 413 words).

And it is not one lucky capture. Every banked Z2 capture under
`~/MWM-AI/data/pm98-m4-oracle/capture2/` — six of them, from six separate wine runs across
s45 to s55b, with three different `players_row` widths — is byte-exact against the same
single port dump:

| capture | window | words compared | result |
|---|---|---|---|
| `oracle_dartwatch_s45_ext` | clk 1-303 | 8,289 | EXACT |
| `oracle_dartwatch_s47a_300_588` | clk 1-588 | 73,416 | EXACT |
| `oracle_dartwatch_s51_630_660` | clk 1-661 | 10,054 | EXACT |
| `oracle_dartwatch_s53_arm_630_660` | clk 1-661 | 13,464 | EXACT |
| `oracle_dartwatch_s55_555_655` | clk 1-656 | 42,369 | EXACT |
| `oracle_dartwatch_s55b_650_1250` | clk 1-830 | 75,583 | EXACT |

**223,175 words, six captures, zero mismatches.** The differ narrows itself to the words a
capture actually holds and prints which fields dropped out, so an older 13-column capture
cannot silently flatter the result. (The s55b file banked in `capture2/` runs to clk 830,
seven ticks further than the working copy s56 used; its 1250 target was never reached.)

## The bug was in the differ, and it is one line

`m5_seq_posdiff.py` (s55) and `m5_field_posdiff.py` (s56) both index the silicon by clk:

```python
players[d["clk"]] = {(r[0], r[1]): r for r in d["pl"]}
```

Every pl-bearing stop of that tick overwrites the previous one, so the row that survives
is whichever stop happened to come LAST — and the number of stops per tick depends on what
the tick did. In the s55b capture over clk 650-823:

| pl-bearing stops in the tick | ticks |
|---|---|
| 1 | 1 |
| 2 | 30 |
| 3 | 123 |
| 4 | 16 |
| 6 / 7 / 9 | 1 / 2 / 1 |

So the sampling instant moves around inside the tick from clk to clk. At a mid-tick stop
some players have already been advanced by this tick's movement pass and others have not,
and any quantity derived from the WHOLE roster is read half-updated. That is what the
`+/-TOL` phase tolerance was compensating for; it is why s55 needed `TOL=2`; and it is
exactly why `orient17c`/`orient180` "forked".

`+0x17c` / `+0x180` are not state — they are the per-refresh min-projection over every
opponent, rebuilt by `build_relationship_matrix` (`FUN_005b8690`, `Pm98Movement.gd`)
on the 1-in-8 `ctx+0x2e0` cadence. A single half-updated roster snapshot changes the
minimum. Consistent with that, every reported orient fork clk is a matrix-refresh clk:
657, 721, 777, 801 are all `== 1 (mod 8)`.

## The clk-721 ball "divergence" is the same artefact, and it is visible in one table

Lay the two ball streams side by side (all ten fields; the whole window behaves this way):

```
clk           x          y          z         vx      vy      vz  face34  own54  b58
SIL 720   1875130   -1747286     128500      13633    2451   -7704    1854      0    0
PRT 720   1888763   -1744835     120796      13633    2451   -7882    1854      0    0
SIL 721   1888763   -1744835     120796          0       0       0    1854      1    0
PRT 721   1889171   -1744607     118473          0       0       0       0      1    1
SIL 722   1889171   -1744607     118473          0       0       0       0      1    1
```

`PRT N` is `SIL N+1`, exactly, including the possession event. s56 compared `SIL 721`
against `PRT 720` (the offset with the fewest differing fields at that row) and read the
one-tick lead as "the port has the ball moving". Both engines take the ball on the same
tick.

## Why the offset is -1, from the ported control flow

`ret0 0x5910fd` is the return of `call 0x5ec240` — an RNG state READ, not a draw — inside
`FUN_005910c0`, the replay-record snapshot. Per `MATCH_TICK_DRIVER_MAP.md` the tick order
is: clock bump `+0x450` (step "open-play clock", `Pm98Driver.gd` L107-112) -> replay record
(step 4, `FUN_005910c0`) -> movement core (step 6). So the stop labelled clk N is the state
at the START of silicon tick N, i.e. the END of tick N-1. The port dumps after
`Pm98Driver.tick()` returns and labels it with the post-bump clk. Hence

    PORT clk N-1  ==  SILICON clk N        (one instant, no tolerance)

and the anchor is the only stop in the tick at which all 22 players are in a mutually
consistent state. That is not asserted, it is measured — the four candidate stops, over the
roster window clk 650-823:

| anchor | ticks | players full-row exact at -1 | ball exact at -1 |
|---|---|---|---|
| `0x5910fd` (FUN_005910c0 record) | 174 | **3828/3828** | **174/174** |
| `0x5a673d` (wander) | 124 | 841/2728 | 124/124 |
| `0x5b3ca2` | 117 | 1266/2574 | 117/117 |
| `0x5b184b` (mark press) | 72 | 874/1584 | 72/72 |

The ball is 100 % at every anchor because its advance runs after all of the tick's draws;
only the once-per-tick record stop puts the players on a single instant too.

## RNG lockstep over the full capture, and the one draw-count difference

The capture records the LCG word at every stop (verified as the MSVC LCG:
`next(4274475265) == 3898077120 == 4274475265*214013+2531011 mod 2^32`). Comparing the
anchor state against the port's end-of-tick `rng=` column: **830/830 ticks equal**.

Per-tick DRAW COUNTS (silicon stops with `eip 0x5ec271`, the post-store trap, vs the port's
logged draws) differ at exactly TWO clks in 0-830:

* **clk 0** — 63 vs 6: the capture attaches during match init, before the port's tick loop.
* **clk 620** — 8 vs 7, and it is CORRECT. The stop sequence is

  ```
  0x5ec245 ret 0x5abcdd  seed 4143873914   <- SAVE state
  0x5ec271 ret 0x4e7e10  seed  863340629   <- draw (the headless-gated commentary leaf)
  0x5ec239 ret 0x5ac066  seed 4143873914   <- RESTORE state
  0x5ec271 ret 0x5b3ca2  seed  863340629   <- next real draw, from the restored state
  ```

  The save/draw/restore triple around `FUN_004e7e10` is net-neutral, so the port eliding it
  is faithful. `Pm98Movement.gd` already documents that pair as net-neutral; this is the
  first LIVE confirmation of it, restored word and all.

## What this changes

* `orient17c`, `orient180`, `curve6c`, `lock5c`, `guard2d7` and the clk-721 possession
  state are **not open items**. Do not chase them. `M5_S56_WIDE_FIELD_DIFF.md` carries a
  correction header pointing here.
* The `+/-TOL` phase machinery is dead. `tools/re/m5_anchor_posdiff.py` replaces
  `m5_seq_posdiff.py` and `m5_field_posdiff.py` for all future parity work; it refuses to
  run if the chosen anchor is not exactly once per tick, so this class of bug cannot come
  back silently.
* `app/tests/diag_m5_dart209.gd` now also dumps the LCG state (`rng=`) and a `BTRAJ` line
  carrying the rest of `m5_rsp_capture.py`'s `ball_row()` — the `FUN_0058fda0`
  predicted-trajectory buffer `ball+0x114..0x1d4` (48 i32) and the three bounce-segment
  lengths `ball+0x74/0x78/0x7c`. s56 named these as captured-but-undiffed; they are now
  diffed and exact, which takes the ball claim from 10 of 63 captured words to all 61
  comparable ones (the two pointer fields `+0x40`/`+0x4c` stay out).

## The real frontier, stated honestly

`+0x450` is the open-play tick counter and the match minute is `+0x450 * 0x2d / +0x19ac`
with `+0x19ac = 14400` in this fixture. **clk 830 is match minute 2.** The byte-exact
window is the first ~2.6 minutes of one reference match, 5.7 % of a half.

So the port is byte-exact as far as any silicon evidence reaches, and the frontier is now
purely a CAPTURE problem, not an engine problem:

1. **Extend the Z2 capture past clk 830.** `tools/re/wine/m5_rsp_capture.py`, ~1 clk/10 s
   in-window, one boot per attempt with a ~1-in-2 clean-XI rate, and it needs its own
   display (`tools/re/wine/README.md` §"Drive without stealing the owner's screen").
   Nothing in the engine can be falsified further without it.
2. The `run_match_from_struct.gd` kill-test divergence (first goal 11' vs the reference
   21') lives at clk ~3500 vs ~6700 — four times beyond the capture, so it is untouched by
   this session and cannot be attributed yet.
3. Unifying the three `+0x43c` null sentinels (absent / 0 / -1) — behaviour-affecting,
   still open.
4. The cross-seed sweep (`PM98_SEED` plumbing landed in s55) — still unrun.

## Reproduce

```bash
~/godot462 --headless --path app --import
PM98_CLK_LO=0 PM98_CLK_HI=840 PM98_TICK_CAP=920 \
  ~/godot462 --headless --path app --script res://tests/diag_m5_dart209.gd > port_840.txt
C=~/MWM-AI/data/pm98-m4-oracle/capture2
python3 tools/re/m5_anchor_posdiff.py port_840.txt $C/oracle_dartwatch_s55b_650_1250.jsonl 1 830
```

Captures used: all six under `~/MWM-AI/data/pm98-m4-oracle/capture2/`, the longest being
`oracle_dartwatch_s55b_650_1250.jsonl` (seed `0xea0d2a8d` poked at the KICK OFF screen, base
`0x3dbf0d8`, clk 0-830, roster rows from clk 650; its 1250 target was never reached).
Start at clk 1, not 0 — the capture holds two anchor stops at clk 0 because it attaches
mid-init, and the differ correctly refuses that window.
