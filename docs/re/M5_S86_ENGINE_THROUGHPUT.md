# M5 s86: the WATCH engine's throughput, attributed and halved

Status: **the positional engine's cost is measured, attributed per sub-pass, and the two
largest items are gone.** `bench_live_match.gd` reports **34.5 -> 59.2 outer-fps** on this
box against the 60 the view needs, i.e. a WATCHED match went from playing at 0.58x real
time to 0.99x. Nothing about what the engine COMPUTES changed: the whole gain is work that
was being done and thrown away.

Evidence: `app/tests/bench_live_match.gd`, `app/scripts/Pm98Driver.gd` (the `PM98_TICK_PROF`
accumulators), `app/scripts/Pm98Movement.gd`, `app/tests/run_match_from_struct.gd`,
`tools/re/run_match_sweep.sh`, `docs/re/sim/fn_00598740_FUN_00598740.c`

## 1. "Not wired into MatchSim" was the wrong frame, and the right number was never taken

`REMAINING.md` carried, as the largest functional gap, *"the M5 3D / positional engine is
not wired into `MatchSim`"*. It is wired, and it has been since the M5 wire-in:
`Main._show_match_running` builds a `Pm98LiveMatch` for a **watched** fixture and hands it
to `MatchSimulador.set_live`, while every fixture the manager does not watch runs on
`Pm98StatMatch`. That is not a shortcut — it is the routing `FUN_0044ee70` itself does on
the session play-state (`Pm98LiveMatch`'s own header argues it in full). Wiring the
positional engine into `MatchSim.simulate` would make the port LESS faithful.

What was real, and never measured, is **throughput**. `MatchSimulador._step_live` asks for
`delta * ENGINE_FPS` engine frames a render tick with `ENGINE_FPS = 60`, so the view keeps
real time iff the engine sustains 60 outer frames a second. The figure everyone quoted —
"~9 minutes per match in GDScript" — is a per-match total, and a per-match total cannot say
whether the match plays at the right SPEED. It does: 34.5 fps against 60 is **0.58x**, a
90-minute match stretched over about nine minutes of viewing instead of five.

## 2. Where the time went

`PM98_TICK_PROF=1` (new, off by default, one static-bool test per section when off) puts an
accumulator around each named sub-pass. Over 1,498 ticks of a real Villa/Bolton fixture:

| pass | us/tick | |
|---|---|---|
| `advance_team` | 26,624 | 22 x `Pm98Action.engine_tick` |
| ` et:move_9490` | 6,686 | the "lean" |
| ` et:movement_decision` | 6,350 | |
| `assign_markers` | 9,072 | 11 x 11 a team |
| `ball+keepers` | 1,983 | |
| `relmatrix` | 1,924 | |
| `select_nearest` / `classify_open_play` / `commentary_tail` / `dequeue` | < 300 each | |

## 3. The lean was building a grid it was about to throw away

`FUN_005a9490`'s off-ball branch computes two aim scalars and a **16-row rotated trajectory
grid** at decompile L189-220, and only THEN reaches the L222-227 ball guards, which abort
outright when the ball has a carrier. The port transcribed that order faithfully.

The consequence is the whole cost: **while the ball is carried, guard 4 aborts every
off-ball player**, so up to 21 of the 22 players per frame were rotating sixteen 3-vectors
and discarding all of them. Both builders are PURE — they read the player, the ball and the
match, return a value, write nothing, draw no RNG — so deferring them past the guards is
observably identical. `lean_trace_on` keeps the eager order, because the trace records
`sc` / `g0` / `g2` on the aborting rows and a diagnostic must not change shape to suit an
optimisation.

**`et:move_9490`: 6,686 -> 1,138 us/tick.**

## 4. And the marker scan was recomputing per-opponent constants per defender

`assign_markers` pass B is 11 x 11 a tick a team. Everything in the inner loop that depends
only on the opponent — his column in the 8690 matrix, his z, his team, and BOTH arms of the
q-metric (each arm reads him alone; which arm applies is the only per-defender part) — is
now hoisted, and the off-pitch `continue` moved ahead of a score that was being computed and
discarded for every substitute. Arithmetic and comparison order are untouched;
`test_assignmarker.gd` is the gate and it is green.

## 5. The A/B, run rather than argued

Unit gates prove the passes; they do not prove a whole match. So `run_match_from_struct.gd`
was run to FULL TIME on both versions — the working tree, and a scratch copy of `app/` with
`Pm98Movement.gd` / `Pm98Driver.gd` / `Pm98Action.gd` restored from `HEAD`:

| | HEAD (before) | after |
|---|---|---|
| outer steps to dispatch 10 | **34,198** | **34,198** |
| goal 1 | 8' Aston Villa, clk 2837, rng 1082620623 | identical |
| goal 2 | 26' Bolton W, clk 8469, rng 3611573666 | identical |
| full time | +0x450 14400, +0x19a8 14400, half 1, **rng 2679052131** | identical |

Bit for bit over 34,198 outer frames, including the final RNG state. That is the claim.

**One correction to the s85 record while we are here.** That session reported the same run
as "37,059 outer steps". It is **34,198**, and it is 34,198 on HEAD as well — so the figure
was not changed by anything here and does not reproduce on the code it was written about.
Everything else s85 recorded (both goals, the full-time state, the 2679052131 RNG) is exact.

## 6. What this does NOT claim

* **Not a fidelity change.** No draw order, no RNG, no arithmetic moved.
  `test_9490`, `test_9490sliceB`, `test_9490sliceC`, `test_assignmarker`, `test_marktarget`,
  `test_relmatrix` and `test_live_match` all pass, the whole 253-test suite is green, and the
  full-match A/B above is bit-identical.
* **Not "fast enough on a phone".** 59 fps is this desktop under load; an Android device is
  a different measurement and there is no device on this box. What can be said is that the
  headroom went from 0.58x to 0.99x on the same hardware, and that the remaining cost is now
  concentrated in two named passes rather than spread thin.
* **The bench is LOAD-SENSITIVE.** Taken with two wine drives running, the same 2,000-frame
  run reported 42.2 / 58.8 / 44.4 fps in three consecutive attempts. Quote it from an idle
  box or quote the profile's per-pass attribution, which is a ratio and holds either way.

## 7. The cross-seed sweep, RUN — it had never been

`tools/re/run_match_sweep.sh` has been in the repo since s55 and every session since has
listed the sweep as "unrun". The reason it could not run is one line: it defaults to
`$HOME/godot462`, which is not this box's binary (`tools/run_tests.sh` has always used
`godot4`). It now falls back rather than picking one, so neither box breaks.

**16 seeds, the first 4 run twice: 16/16 reached FULL TIME on dispatch code 10, 4/4
digest-identical across two runs, 0 failures.** Scorelines 0-0 through 4-2.

What that certifies is what the harness's own header says and no more: the recovered engine
plays a full 90 minutes from real squads on an arbitrary seed without stalling, and it is
deterministic. It is **not** silicon parity — nothing in the sweep is compared against
MANAGER.EXE, and the one seed that IS compared (the capture-2 fixture above) still diverges
at goal 2.

## 8. What is next, in cost order

`et:movement_decision` (6,350 us/tick) is now the largest single item and has not been
looked at. `assign_markers` is still 4,731 after the hoist. Between them they are about
two-thirds of a tick.
