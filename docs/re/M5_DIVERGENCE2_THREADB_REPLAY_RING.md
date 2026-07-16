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

## 4. Sharpened root cause — 2026-07-15 (source-only, no new drive)

Traced the full board-resume mechanism against the decompiles + the §1 live capture. The exact
trigger is confirmed **display-coupled** (so the live drive is still the settling path), but the
mechanism and a candidate headless proxy are now pinned:

1. **A board is a +0x454 cooldown, not a click.** `Pm98Dispatch.dispatch` sets `+0x454 = 0x168`
   (360; `0x2d0`/720 for a phase-boundary), phase-locks `+0x448 = 8`, and stamps `+0x1a38 = code`.
   The tick tail decrements `+0x454` each frame (`Pm98Driver.gd:216`); `_match_over` returns
   ENGINE_OVER (0) exactly when `+0x454 == 1`. **360 ticks ÷ ~33 fps ≈ 11 s** = the §1 capture's
   disp-3 board span (t=59.5→70.3, clk frozen 2511 then resumed 2515). So the board length is the
   `+0x454` cooldown.
2. **The pause branch never converts that expiry into a restart.** In `_live_branch`, tick-ret-0
   arms `+0x1a1e=1` → next tick `restart_handler` → `phase = RESTART_PHASE_TABLE[+0x1a38]`
   (`{…3→6,6→2…}`, matches the capture's 8→6 and 8→2), `+0x1a38=0`, resume. But WATCH boards route
   to `_pause_branch`, whose `_wait_frame` (FUN_00593ab0 L27-36) arms `+0x1a1e` **only when
   `DAT_006d31c4(playback)!=0 OR pump!=0`**. §1 read playback==0 in WATCH, and headless pump is
   hardcoded `PUMP_RESULT_HEADLESS=0` → the arm never fires → phase sticks at 8, ring `+0x27e8`
   climbs unheeded. This is the byte-exact reason, not a modeling gap in the port.
3. **Why the pause branch (not live) even runs the board:** `Pm98Outer.step` L78 routes to
   `_pause_branch` when `play_state∈{0,4} OR +0x19a0==4 OR +0x1a20 latch`. A **foul (disp 5) sets up
   a free-kick → the +0x1a20 set-piece latch**, which is cleared ONLY by `kickoff_init`
   (FUN_00593600 L94) in the sim corpus. Headless the set-piece taker never executes (deferred
   open-play movement), so the latch never clears and the pause loop's disp-5 break
   (`code!=5 or +0x461&6`, bit set only in phase 0) can never satisfy → `WAIT_LOOP_GUARD`.
4. **The disp-5@clk1600 is itself divergent.** The §1 real capture shows ONLY disp 3 and disp 6 —
   **never disp 5**. Our sim manufactures a foul at clk 1600 that the real fixture/seed does not,
   i.e. the stall is downstream of the deferred-movement divergence (handoff NOTE), not an
   independent board bug.

**The one unknown left = the pump's nonzero trigger** (what a real board-end / KICK-OFF posts, and
whether it coincides with `+0x454==1`). That is NOT repo-knowable — it lives in the display/message
path. Two faithful ways to settle it, NO guessed board-duration allowed (project doctrine):
- **(A) live drive** (`ptrace_scope=0`, open now): watch `+0x1a1e`/`+0x1a38`/`+0x454`/phase across a
  real foul→free-kick resume; confirm whether the arm coincides with the `+0x454` expiry.
- **(B) wire the deferred set-piece/open-play movement** so the free-kick taker executes and clears
  `+0x1a20` the source way — larger, and also removes the spurious disp-5@1600.
