# M5 s90 — a fresh boot does NOT reproduce the reference past clk 2837

> **s91 update, §5:** candidate 3 — "the reference is one sample of a timing family" — is
> **REFUTED** by measurement, and the wall-clock mechanism behind it is refuted with it. The
> item is narrower now, and points at candidate 2. Read §5 before planning anything here.

Status: **the s87 plan for goal 2 has a prerequisite that is now measured and FAILS.** The
plan was "boot, nav to the same fixture, poke the frame-0 seed, capture 2837..8469, diff the
port against it". A clean boot reproduces goal 1 BIT-EXACTLY and then plays a different
match. The window that plan wanted to capture cannot be obtained that way.

`Evidence:` `tools/re/wine/m5_rsp_capture.py` (`PM98_CLK_TRACE`, the frame-0 full diff),
`~/MWM-AI/data/pm98-m4-oracle/capture2/timeline.jsonl`,
`.../capture2/frame0_struct_import.json`, `app/tests/run_match_from_struct.gd`.

## 1. Three answers to "when is goal 2", and they are three different matches

| | goal 1 | goal 2 |
|---|---|---|
| **banked reference** (`capture2/timeline.jsonl`) | clk **2837**, 1-0, seed 1082620623 | clk **7805**, 1-1 (Bolton W) |
| **the port** (`run_match_from_struct.gd`) | clk **2837**, 1-0, rng **1082620623** | clk **8469**, 1-1 (Bolton W) |
| **a clean s90 boot of the ORIGINAL**, seed poked | clk **2837**, 1-0, seed **1082620623** | clk **4582**, **2-0** (Aston Villa) |

All three agree on goal 1 to the clock AND to the LCG state. Then the port is 664 clk late
with the right team and the right scoreline, and the original's own re-drive is 3,223 clk
early with the WRONG team.

**The port is closer to the banked reference than a fresh boot of the original is.** That is
the finding, and it is what makes the s87 plan unrunnable as written: there is no way to
capture "the reference's per-frame 2837..8469" by re-driving the game, because re-driving the
game does not produce the reference's match after clk 2837.

## 2. It is not the frame-0 state at all

The obvious suspect is the s53 one — "the preseason condition roll can move the derived
pace/stamina and the sim forks from tick 1" — and the capture already guards it with a
five-field XI check. s90 widened that check to **every dword the frame-0 dump records**, of
every object it can address, and the answer is no:

* `xi_check` — 0 mismatches (the five fields it always tested);
* the full diff — **0 mismatches**. All 22 player records over their whole 0x0..0x3b8
  contiguous dword dump (the entire 0x3bc stride), both team headers, the ball at
  `base + 0x1610` and the session at `*(base + 0x468)`.

So at kick-off the state the reference dump describes is reproduced exactly: the players
byte for byte, the 86 match scalars poked (85 written, 1 already equal), the LCG seed poked.
**The divergence is not in anything the capture restores, and therefore poking more of it
cannot fix it.** `PM98_POKE_PLAYERS=1` exists and is a no-op on a clean boot; that is the
result, not a disappointment.

Two measurement traps this had to walk through, both fixed in the tool so the next reader
does not re-derive them:

* `_va` in the dump is the REFERENCE boot's address. Comparing the ball at its stored `_va`
  reported 32 phantom mismatches; the live ball is `base + 0x1610`.
* the team-header dump stores `0x2ec` and `0x2ed` as single BYTES, and `0x2ec` is
  dword-aligned so an alignment filter does not catch it. Comparing the live dword there
  against a byte reported hdr1 as the one remaining "mismatch" — purely because the live
  `+0x2ee` set-piece freeze byte shares that dword. **`0x2ee` is not in the dump at all**,
  which is a real gap: the reference's freeze flag at frame 0 is unknown.

## 3. What the clock trace says about WHERE it goes wrong

`PM98_CLK_TRACE=1` banks one row per clock write for the whole window, and the shape at the
goal is unmistakable: at clk 2837 the original writes the clock **65 times** where the port
takes **433 outer steps**, against a steady 6 writes / 1-2 steps per tick either side of it.
The goal-1 restart is a long, differently-paced event on both sides, and it is the only thing
between the last agreeing state and the first disagreeing one.

Note what this does NOT establish. Per-tick seed equality is not a divergence test here — the
clock is written 6 times a tick and the tick draws ~33 times, so the trace samples under a
fifth of the stream and two identical streams would still show different seeds.
`m5_clktrace_diff.py` says so in its own docstring rather than leaving the trap set.

## 4. What the next session should actually do

Not "re-run the capture for longer". The three candidates, in the order they can be killed:

1. **The restart's own RNG consumption.** Both sides pause at the goal and neither pauses the
   same way. If the number of draws consumed between the goal and the restart differs, every
   subsequent event moves. This is measurable with the SEED watchpoint (not the clock one)
   over a window of a few hundred ticks around 2837 — small, cheap, and it either shows a
   draw-count difference or it does not.
2. **State the frame-0 dump does not carry.** The two KEEPER objects are in the dump and are
   NOT compared, because their live address is not derivable from `base` by anything read so
   far. Naming that gap is the honest state of §2's "0 mismatches".
3. **The banked reference itself.** `capture2` was driven with `autoresume.py` clicking KICK
   OFF at each segment pause, and its timeline is a poll, not a per-frame trace. If the click
   timing feeds the RNG, the reference is one sample of a family rather than a fixed target —
   in which case goal 2 is not a "divergence" to localise at all and the port's 8469 is as
   good an answer as 7805.

Until one of those three is settled, "the port's goal 2 is two minutes late" is not a defect
statement about the engine. It is a comparison against a target that has not been shown to be
reproducible.

## 5. s91 — candidate 3 is REFUTED, and so is the whole "wall clock feeds the sim" class

`Evidence:` `tools/re/wine/m5_idle_seed_poll.py` run against a live isolated boot;
`MANAGER.EXE` @0x5bdfd6, @0x5ec250.

Candidate 3 was the one that would have retired the item, so it was taken first. It does not
survive, and neither does the mechanism behind it.

### 5.1 The RNG does not advance while the game waits for the click

The match RNG is `FUN_005ec250`, a plain LCG on `DAT_006d3184`
(`seed = seed * 0x015a4e35 + 0x269ec3`, returning `(seed >> 16) & 0x7fff`), with `0x5ec230`
and `0x5ec240` as its setter and getter and 340 call sites. Because it is an LCG the number
of draws between two observed seeds is recoverable exactly, so "did the stream move" is a
measurement, not an impression.

A fresh boot in an isolated prefix was driven to the reference fixture's KICK OFF screen —
Aston Villa v Bolton W, the exact screen `autoresume.py` clicks — and the seed was read six
times over 25 s with **no input at all**:

| screen | idle intervals | seed |
|---|---|---|
| the title screen | 5 x 5 s | `0x0762a12b`, unchanged every time |
| the reference fixture's KICK OFF | 5 x 5 s | `0x2153b03d`, unchanged every time |

**Zero draws consumed while paused.** So how long `capture2` sat at a segment boundary
before its KICK OFF click cannot have moved the stream, and `capture2`'s timeline is not
"one sample of a timing family" for that reason. Candidate 3 is dead as written.

### 5.2 And the frame loop is a LIMITER, not a catch-up

The obvious remaining way for wall clock to reach the sim is a variable-step main loop, and
the binary says it is not one. `MANAGER.EXE` imports exactly one timer, `WINMM!timeGetTime`
(no `GetTickCount`, no `QueryPerformanceCounter`), at 19 sites; the one in the main loop,
beside the `PeekMessageA` pump at `0x5bd095`, reads:

```
005bdfd6  call dword ptr [0x6234bc]   ; timeGetTime
005bdfdc  mov  ebx, [esp+0x28]        ; the previous frame's stamp
005bdfe2  sub  ecx, ebx
005bdfe4  cmp  ecx, 0x10
005bdfe7  jae  0x5bdff8               ; >= 16 ms already gone -> go
005bdfe9  call dword ptr [0x6234bc]   ; else BUSY-WAIT until it is
005bdff6  jb   0x5bdfe9
```

That is a fixed ~16 ms floor per frame with a spin, and there is no "advance N steps for the
elapsed time" arm anywhere near it. A loaded machine renders the same number of frames per
game clock, just later. Combined with §5.1, **no path has been found by which wall clock or
input timing reaches the match stream at all.**

### 5.3 What this leaves

Candidate 3 is out; candidate 1 (the restart's own draw count) and candidate 2 (state the
frame-0 dump does not carry) are both still live, and §2's "0 mismatches" now points harder
at candidate 2 — because if nothing external feeds the sim and the compared state is
identical, then the state that was NOT compared is where the difference has to live. The
named gap is the two KEEPER objects, whose live address is not derivable from `base` by
anything read so far, plus `+0x2ee` (the set-piece freeze byte, absent from the dump).

The cheapest next move is therefore **not** another capture: it is finding the keeper
pointer in the match struct so §2's diff can cover them. Only if that comes back clean does
candidate 1's seed-watchpoint window around clk 2837 become worth its wall clock.
