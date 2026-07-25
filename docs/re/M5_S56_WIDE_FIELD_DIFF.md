# M5 s56: the differ was only ever checking x/y — widened, and it finds real forks

`m5_seq_posdiff.py` (s55) fixed the sampling-phase artefact and reported **22/22 players +
ball PASS over clk 270-823**. That verdict is about **x and y and nothing else**. The Z2
capture already carries the whole player row — orientation, facing, yaw, speed, the mover
state and the FUN_005b1420 / FUN_005a8f20 gate inputs — and the ball's velocity, and none
of it was compared. Two trajectories can hold identical positions for a window while their
velocity or facing has already diverged, so the old claim was weaker than it read.

## What changed

* `app/tests/diag_m5_dart209.gd` — the port dump's `PL` row now **appends** the rest of
  `m5_rsp_capture.py`'s `players_row()` (face+0x34, yaw+0x64, spd+0x68, curve+0x6c, +0x54,
  +0x58, lock+0x5c, team+0x2b8, onpitch+0x2bc, guard+0x2d7, +0x2d8), and a new `BALL` line
  carries `ball_row()`'s x y z vx vy vz face34 own54 +0x58 N5c. The first eight `PL`
  columns are untouched, so every existing differ still parses the dump positionally.
* `tools/re/m5_field_posdiff.py` (new) — the same ±TOL phase tolerance as s55, but applied
  to the **whole row**: a capture row passes iff the port holds **every checked field
  simultaneously** at one clk in the window. Matching different fields at different
  instants would be meaningless. A failing row is reported at the instant with the FEWEST
  differing fields, so the field that actually forked is named.

Not compared, and why: player `+0x184` and ball `+0x40`/`+0x4c` are pointers in silicon and
Dictionaries in the port; the ball's 48-int predicted-trajectory tail and its three
bounce-segment lengths are in the capture but not in the port dump.

## Result — capture `s55b_partial.jsonl`, clk 650-823, TOL 2

**x/y alone reproduces s55 exactly** on a freshly generated port dump: 22/22 players and
the ball PASS, phase -1..0. The port has not moved; what follows is new information, not a
regression.

Adding ONE field at a time to x/y:

| added field | verdict |
|---|---|
| `sub13c`, `face34` (+0x34), `yaw64` (+0x64), `spd68` (+0x68), `p54`, `p58`, `team2b8`, `onpitch2bc`, `p2d8` | **PASS** — no fork in 650-823 |
| **`orient17c`** (+0x17c) | **FORK** — first at clk 657 (t1.i3), then systematically across the whole of team 0 at clk 801 |
| **`orient180`** (+0x180) | **FORK** — same clk 657 onset |
| **`curve6c`** (+0x6c) | FORK at clk 650 on t1.i3 — silicon 0, port 7056 |
| **`lock5c`** (+0x5c) | FORK at clk 773 (t1.i2) / 775 (t0.i7) — silicon 0, port 1 |
| **`guard2d7`** (+0x2d7) | FORK at clk 650 (t1.i3) and 721-722 — silicon 0, port 1 |

The **ball** fails the full-row check at clk 721: silicon has `vx/vy/vz = 0` and `own54 =
1`, the port has it moving (13633, 2451, -7882) and `own54 = 0` — a possession/dead-ball
state divergence that a position-only differ cannot see, because the ball's x/y still match
throughout.

Sample at the systematic team-0 onset, clk 801 (nearest instant −1, one field differing):

```
t0.i2  orient17c: silicon  125735  port  152031
t0.i3  orient17c: silicon 2244376  port 2261485
t0.i5  orient17c: silicon   12410  port   13275
t0.i7  orient17c: silicon  180178  port  131585
```

## How to read this

* **`orient17c`/`orient180` is the strongest signal.** It moves for a whole team at one
  clk while x/y, facing, yaw and speed all still match — the class of divergence the
  x/y-only differ is blind to by construction, and the next thing to chase.
* **`curve6c` and `guard2d7` fail on t1.i3's FIRST captured row** (that player has a single
  row in the window). A divergence present at the first sample is as likely to be a stored
  representation mismatch as a trajectory fork; it should be checked at a clk where the
  player has a run of rows before it is called a fork.
* **`lock5c` and `guard2d7` are 1-vs-0 flags.** They cost no RNG draw, so they can differ
  for many ticks without moving anything — which is exactly why they were never caught.

## Reproduce

```bash
~/godot462 --headless --path app --import
PM98_CLK_LO=640 PM98_CLK_HI=830 PM98_TICK_CAP=900 \
  ~/godot462 --headless --path app --script res://tests/diag_m5_dart209.gd > port_wide.txt
python3 tools/re/m5_field_posdiff.py port_wide.txt <capture>.jsonl 650 823
PM98_FIELDS=x,y python3 tools/re/m5_field_posdiff.py port_wide.txt <capture>.jsonl 650 823
```

## Still open (unchanged by this session)

* the silicon capture past clk 823 — needs a wine boot, ~1 clk/10 s in-window;
* the `run_match_from_struct.gd` kill-test divergence (first goal 11' vs the reference 21',
  then the `Pm98Outer._pause_branch` wait-loop guard);
* the cross-seed sweep (`PM98_SEED` plumbing landed in s55, unrun);
* unifying the three `+0x43c` null sentinels (absent / 0 / -1) — behaviour-affecting.
