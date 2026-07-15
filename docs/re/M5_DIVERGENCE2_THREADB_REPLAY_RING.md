# M5 Thread B — the ps=4 (WATCH) faithful-branch post-goal deadlock

Continues `handoff-pm98-m5-killtest-rebaseline-div2-rootcause-2026-07-15` (Thread B root-cause) and
the live drive `handoff-pm98-m5-kickoff-lockstep-confirmed-2026-07-15`. This doc records the
**live-validated** replay-ring semantics, the **record=1 fix**, and the **second, deeper blocker**
the fix exposed (which the offline rebaseline had folded into Thread B).

## 1. Ring semantics — LIVE-VALIDATED 2026-07-15 (not decompile-only)

Drove the real `MANAGER.EXE` under wine to a WATCH match (Aston Villa vs Bolton W, the capture2
fixture, `ptrace_scope=0`), found the match base with `m4_findbase.py` (no debugger), and polled the
replay-ring fields per frame through a full goal→restart→resume. Evidence:
`~/MWM-AI/data/pm98-m4-oracle/threadB_ring_2026-07-15/ring.jsonl` (365 samples).

| global / field | port symbol | LIVE value in WATCH |
|---|---|---|
| `DAT_00665d8c` (record) | `Pm98Driver.WATCH_RECORD` | **1** (read at frame-0 and throughout) |
| `DAT_006d31c4` (playback) | `Pm98Driver.WATCH_PLAYBACK` | **0** |
| `match+0x27e8` (ring HEAD) | `m[0x27e8]` | **+1 every frame** (grows even during the phase-8 goal board); reset to 0 at each kickoff restart, then regrows |
| `match+0x27ec` (ring TAIL) | `m[0x27ec]` | **0 always** (advanced ONLY when playback!=0, `fn_00598740` L208) |
| `match+0x1a20` (goal latch) | `m[0x1a20]` | 0 in every post-goal sample (phases 8/2/0) |

Captured goal (Villa 1-0, min 39.5): score `0-0 → 1-0` at phase 8 (disp 6, goal board) with the
clock frozen during the celebration board, then a phase-2 kickoff restart (head reset 0), then
**the clock resumed 6327 → 6329** as open play returned. The match did NOT freeze post-goal.

This matches `fn_00598740` exactly: the record block (L114-163) does `+0x27e8 += 1` every frame when
`record!=0 && playback==0`; `+0x27ec` is bumped only under `playback!=0` (L204-208). So in WATCH
`+0x27e8 > +0x27ec` holds after frame 1.

## 2. The fix (Pm98Driver.gd) — record=1

The port modelled `record=0` (headless simplification), so the ring HEAD `+0x27e8` never advanced and
stayed `0 == +0x27ec`. The tick's latched early-out (`fn_00598740` L106-107, `Pm98Driver.tick` L~163):

```gdscript
if (_g(m, 0x1a20) != 0) and (_g(m, 0x27e8) <= _g(m, 0x27ec)):   # (latch||pb) && head<=tail
    return _match_over(m)
```

fires forever once the goal latch `+0x1a20=1` sets (the clock increment is AFTER it → frozen clock →
`WAIT_LOOP_GUARD` breach). The fix models `record=1` (const `WATCH_RECORD`) and advances the counter
in the record-block slot, exactly like the binary:

```gdscript
if WATCH_RECORD and not WATCH_PLAYBACK:   # DAT_00665d8c==1 && DAT_006d31c4==0
    m[0x27e8] = _i(_g(m, 0x27e8) + 1)      # L136-139 ring-head advance (counter only)
```

The 5-dword `+0x27e4` snapshot and the 12-dword `+0x27dc` ring are replay-display data with no
scoreline/event effect, so only the counter is modelled. **Validated:** with the fix the ps=4 run's
`head27e8` grows +1/tick (heartbeat: head=1999 at tick 2000, etc.) and the post-goal early-out no
longer fires. `test_match_init` still passes (asserts `+0x27e8==0` at init, unaffected). ps=1 branch
regression-checked — still advances (min 5→10, clock/head grow+reset, no stall).

## 3. Second blocker EXPOSED — the ps=4 pause-branch board stall (NOT the ring)

The rebaseline folded this into Thread B ("relies entirely on the record=1 ring"). It is separate.
With the ring fixed, the ps=4 faithful branch advances past the ring early-out but then **stalls at
the first event board**: `diag` heartbeat shows clock frozen at **clk=1600, phase 8, disp 5** (=
foul/card/offside, `Pm98Dispatch.gd:187`), score 0-0, while `head27e8` climbs 1999→27999 (the ring
IS advancing — the fix works — but the match phase never leaves 8).

Mechanism (`Pm98Outer._pause_branch` L108-120): the WATCH pause loop breaks on code 5 only when
`+0x461 & 6 != 0`. That bit is set by `fn_00598740` L219 (`+0x461 |= 4`), but that block is guarded
by `if (+0x448 != 0) goto default` (L216) — it runs **only in phase 0**. Stuck at phase 8, it never
fires → the pause loop spins to `WAIT_LOOP_GUARD`. In WATCH the phase-8 board is dismissed by the
user's **KICK OFF click** (exactly what `autoresume.py` clicked in the M4 oracle drive); ps=1 (live
branch) auto-dismisses via the `+0x1a1e` restart-arm — which the pause branch lacks (rebaseline §2.5:
"the WATCH branch has no restart-arm path"). So ps=4 headless cannot resolve event boards.

**NEXT (Thread B sub-problem 2):** model the headless KICK-OFF-resume for the pause branch — what a
KICK OFF click does to `+0x1a1e`/`+0x1a38`/phase at a disp≠0 board. Best settled with one more live
drive watching a **foul→free-kick resume** (`ptrace_scope=0`, m5_gdbrsp watch on `+0x1a1e`/`+0x1a38`),
since the offline decompile of the message-pump path (`FUN_005bce40`) is display-coupled. Until then,
the headless full-match kill-test must use the auto-advancing ps=1 branch (`PM98_FORCE_PS=1`).
