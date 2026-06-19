# PM98 — match-tick driver call-graph map (FUN_00598740)

Verified 2026-06-19 by reading the decompiles + disasm + the player vtable. This replaces the
loose "FUN_005b70e0 shell + FUN_005b73a0 -> driver" sketch in the prior handoffs with the actual
per-tick call order, and splits SIMULATION (needed for a headless match-outcome engine) from
DISPLAY/SOUND (inert in headless, gated by match+0x180b/+0x180c/+0x180d/+0x5fac). Cite this; do not
re-derive.

## Player vtable (VA 0x639224, the object whose `this` is a player, stride 0x3bc)
Dumped from MANAGER.EXE .rdata at file offset 0x23801c (`objdump`/python struct):
```
+0x00  0x5ed810   (dtor/RTTI-ish)
+0x04  0x5a5460   FUN_005a5460   = per-player SPRITE/ANIMATION draw  (DISPLAY, skip headless)
+0x08  0x5a3400   FUN_005a3400   = per-player DECIDE (move target)   (SIM, DONE)
+0x0c  0x5a4560   FUN_005a4560   = per-player ADVANCE (physics)       (SIM, NOT PORTED <- next)
+0x10  0x5a4600   ...
```
The per-player passes are driven by trivial player-loop dispatchers (each loops `param_1[1]` players
from base `*param_1`, stride 0x3bc, `this`=player):
- `FUN_005b8bf0` -> calls vtable **+8** (DECIDE = FUN_005a3400). DONE downstream.
- `FUN_005b8c20` -> calls vtable **+0xc** (ADVANCE = FUN_005a4560). **port FUN_005a4560 first.**
- `FUN_005b70e0` -> calls vtable **+4** (FUN_005a5460 SPRITE/ANIM) + a free-kick visual block +
  FUN_005b8a60. **RENDER pass -- NOT needed for the headless outcome engine.**

## FUN_00598740 per-tick SIM sequence (this = match, returns 1=continue / 0=match over)
Stripping the display/sound/commentary (FUN_00590f00/f40/f60, FUN_004e*, FUN_005ec240/230 RNG
save-restore brackets that net-zero), the load-bearing simulation order is:

1. `FUN_00593a30()` — per-tick pre-update (NOT ported; classify).
2. set-piece special (phase 7, or phase 5 w/ +0x19cc, taker-side, first-time): rebuild a queue,
   `FUN_005b8f20` (select_active, DONE) -> match+0x438, then `FUN_005b70e0`x2 (RENDER) +
   `FUN_005b73a0`x2 (positioning). Then return early. NOTE: the x2 FUN_005b70e0 here is render;
   the sim-relevant part of this branch is select_active + FUN_005b73a0.
3. main sequence (the per-tick movement core), each called **x2 (once per team)**:
   - `FUN_005b8bf0` x2  — DECIDE dispatch -> FUN_005a3400 (DONE).
   - 4 sub-entity DECIDE: `(*[match+0x1610]+8)()`, `+0xaac`, `+0xe74`, `+0x123c` — 4 objects with the
     SAME vtable shape (+8 decide / +0xc advance). Identities UNRESOLVED (likely ball + team-AI
     contexts). Investigate before the driver port.
   - `FUN_005b8690` x2  — relationship matrix (DONE).
   - `FUN_005b94f0` x2  — marker assignment (DONE).
   - `FUN_005b8c20` x2  — ADVANCE dispatch -> **FUN_005a4560 (NOT PORTED, next)**.
   - 4 sub-entity ADVANCE: `(*[match+0x1610]+0xc)()`, `+0xaac`, `+0xe74`, `+0x123c`.
   - `FUN_005b8ce0(0)` x2 — nearest-to-ball selector (DONE).
   - DAT_006d31bc = (DAT_006d31bc + 1) & 0x3ff  — the 1024-frame replay ring counter.
4. open-play resolution (phase==0 path, lines 362-692): the per-tick ball-vs-player resolution.
   Calls the already-ported predicates `FUN_0058f100`/`0058ede0`/`0058fbe0`/`0058f140` + the
   dispatcher `FUN_005966d0` (DONE) + the aggregate `FUN_00450e60` (DONE) + RNG `FUN_005ec250`
   (DONE = Pm98Rng) + NOT-ported `FUN_0058f0b0`/`0058f3c0`/`005a1820`/`0059a120`. This overlaps the
   resolver `FUN_005aeda0` we already ported (Pm98Resolver) -- reconcile which the driver actually
   invokes when porting.
5. tail stats/commentary (lines 693-894): mostly DISPLAY (FUN_004e*, FUN_00590f60) + RNG-timed
   commentary; the sim-relevant residue is the possession/stat counters + `FUN_00594570(0)`.
6. return: 0 (match over) iff match+0x454 == 1, else 1.

## Remaining ports to reach the full-match KILL-TEST (driver 0x598740)
SIM, in dependency order:
1. ~~**FUN_005a4560** (ADVANCE, vtable+0xc)~~ **DONE 2026-06-19** -> Pm98Movement.advance + _advance_motion,
   oracle test_advance.gd (48 ck). **FINDING: it is PURE replay record/playback, NOT physics** -- the
   player position (+0x4/+0x8/+0xc) is set directly by DECIDE (FUN_005a3400) each tick. NO-OP in a live
   headless run (ring != 0, or replay+record both off). leaf FUN_005ed8e0 = the 9-dword motion snapshot.
2. **FUN_005b73a0** (positioning, ~4.8KB, 7 RNG draws -- trace 0x5ec250 for draw ORDER). Calls
   FUN_005b8690 (DONE) first; C++ unwinding + nested player loops. Will need SLICING like 5a3400.
3. the 4 sub-entity vtables at match+0x1610/+0xaac/+0xe74/+0x123c (resolve identities + their
   +8/+0xc methods).
4. the small per-tick helpers: FUN_00593a30, FUN_00593b70, FUN_005946d0, FUN_00594410,
   FUN_005942e0, FUN_00594570, FUN_005910c0, FUN_00591120, FUN_0058f0b0, FUN_0058f3c0,
   FUN_005a1820, FUN_0059a120, FUN_0059a1e0, FUN_00590ac0.
5. **FUN_00598740** itself (the driver) -> then the full-match kill-test (event-stream + scoreline
   parity, fixed seed, N>=50).

DISPLAY / SOUND (stub or skip in the headless engine -- all gated by match+0x180b/0x180c/0x180d/0x5fac):
- FUN_005a5460 (sprite/anim, vtable+4), FUN_005b70e0 (render shell).
- FUN_00590f00/f40/f60 (sound), FUN_004e* (commentary), FUN_005f* (sprite draw), FUN_00436fb0.

## Note
The headless match-outcome engine does NOT need the render passes (FUN_005a5460 / FUN_005b70e0).
The prior handoff's "FUN_005b70e0 shell" next-step pointed at a render pass; the correct next sim
port is FUN_005a4560 (advance), then FUN_005b73a0 (positioning), then the FUN_00598740 driver.
