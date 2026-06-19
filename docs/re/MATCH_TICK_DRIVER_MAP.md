# PM98 -- match-tick driver call-graph map (FUN_00598740)

Verified 2026-06-19 by reading the decompiles + disasm + the player vtable. This replaces the
loose "FUN_005b70e0 shell + FUN_005b73a0 -> driver" sketch in the prior handoffs with the actual
per-tick call order, and splits SIMULATION (needed for a headless match-outcome engine) from
DISPLAY/SOUND (inert in headless, gated by match+0x180b/+0x180c/+0x180d/+0x5fac). Cite this; do not
re-derive.

## VA<->file delta = 0x401200 (CORRECTED 2026-06-19)
.rdata VA->file: `file = VA - 0x401200`. (An earlier dump in this doc used 0x401208 and read
every vtable shifted +8 -- that error is what made the sub-entity methods below look like sprite
draws. Verified the right delta by locating player DECIDE 0x5a3400 in the binary: its LE dword sits
at file 0x23802c == VA 0x63922c == player-vtable+8. The player-vtable LAYOUT below was already
correct; only the file-offset note was off.)

## Player vtable (VA 0x639224, the object whose `this` is a player, stride 0x3bc)
Dumped from MANAGER.EXE .rdata at file offset 0x238024 (`file = 0x639224 - 0x401200`):
```
+0x00  0x5ed810   (dtor/RTTI-ish)
+0x04  0x5a5460   FUN_005a5460   = per-player SPRITE/ANIMATION draw  (DISPLAY, skip headless)
+0x08  0x5a3400   FUN_005a3400   = per-player DECIDE (move target)   (SIM, DONE)
+0x0c  0x5a4560   FUN_005a4560   = per-player ADVANCE (replay rec/play, no-op live)   (SIM, DONE)
+0x10  0x5a4600   ...
```
The per-player passes are driven by trivial player-loop dispatchers (each loops `param_1[1]` players
from base `*param_1`, stride 0x3bc, `this`=player):
- `FUN_005b8bf0` -> calls vtable **+8** (DECIDE = FUN_005a3400). DONE downstream.
- `FUN_005b8c20` -> calls vtable **+0xc** (ADVANCE = FUN_005a4560). DONE (replay rec/play, no-op live).
- `FUN_005b70e0` -> calls vtable **+4** (FUN_005a5460 SPRITE/ANIM) + a free-kick visual block +
  FUN_005b8a60. **RENDER pass -- NOT needed for the headless outcome engine.**

## FUN_00598740 per-tick SIM sequence (this = match, returns 1=continue / 0=match over)
Stripping the display/sound/commentary (FUN_00590f00/f40/f60, FUN_004e*, FUN_005ec240/230 RNG
save-restore brackets that net-zero), the load-bearing simulation order is:

1. `FUN_00593a30()` -- per-tick pre-update (NOT ported; classify).
2. set-piece special (phase 7, or phase 5 w/ +0x19cc, taker-side, first-time): rebuild a queue,
   `FUN_005b8f20` (select_active, DONE) -> match+0x438, then `FUN_005b70e0`x2 (RENDER) +
   `FUN_005b73a0`x2 (positioning). Then return early. NOTE: the x2 FUN_005b70e0 here is render;
   the sim-relevant part of this branch is select_active + FUN_005b73a0.
3. main sequence (the per-tick movement core), each called **x2 (once per team)**:
   - `FUN_005b8bf0` x2  -- DECIDE dispatch -> FUN_005a3400 (DONE).
   - 4 sub-entity DECIDE: `(*[match+0x1610]+8)()`, `+0xaac`, `+0xe74`, `+0x123c` -- vtable+8.
     **IDENTITIES RESOLVED 2026-06-19 (see "Sub-entity resolution" below): ball + 2 GKs + referee.**
     All four +8 (decide) methods are replay record/playback (FUN_0058e220 ball-snapshot, FUN_005a4560
     for the other three) -> NO-OP in a live headless run (DAT_006d31c4==0). The SIM work is in +0xc.
   - `FUN_005b8690` x2  -- relationship matrix (DONE).
   - `FUN_005b94f0` x2  -- marker assignment (DONE).
   - `FUN_005b8c20` x2  -- player ADVANCE dispatch -> FUN_005a4560 (DONE; replay rec/play, no-op live).
   - 4 sub-entity ADVANCE: `(*[match+0x1610]+0xc)()`, `+0xaac`, `+0xe74`, `+0x123c` -- vtable+0xc.
     **This is the real per-tick sub-entity sim. ball physics + GK tracking live HERE, all UNPORTED.**
   - `FUN_005b8ce0(0)` x2 -- nearest-to-ball selector (DONE).
   - DAT_006d31bc = (DAT_006d31bc + 1) & 0x3ff  -- the 1024-frame replay ring counter.
4. open-play resolution (phase==0 path, lines 362-692): the per-tick ball-vs-player resolution.
   Calls the already-ported predicates `FUN_0058f100`/`0058ede0`/`0058fbe0`/`0058f140` + the
   dispatcher `FUN_005966d0` (DONE) + the aggregate `FUN_00450e60` (DONE) + RNG `FUN_005ec250`
   (DONE = Pm98Rng) + NOT-ported `FUN_0058f0b0`/`0058f3c0`/`005a1820`/`0059a120`. This overlaps the
   resolver `FUN_005aeda0` we already ported (Pm98Resolver) -- reconcile which the driver actually
   invokes when porting.
5. tail stats/commentary (lines 693-894): mostly DISPLAY (FUN_004e*, FUN_00590f60) + RNG-timed
   commentary; the sim-relevant residue is the possession/stat counters + `FUN_00594570(0)`.
6. return: 0 (match over) iff match+0x454 == 1, else 1.

## Sub-entity resolution (the 4 vtable objects at match+0x1610/+0xaac/+0xe74/+0x123c)
RESOLVED 2026-06-19 from the match ctor FUN_00591180 (0x5911a4..0x59125f) + each object's vtable
(delta 0x401200) + the advance-leaf disasm. The match ctor builds them:
- `match+0xaac`  : ctor FUN_005a2640, then `[obj]=0x639208`, `[obj+0x3bc]=1`  (index 1)
- `match+0xe74`  : ctor FUN_005a2640, then `[obj]=0x639208`, `[obj+0x3bc]=2`  (index 2)
- `match+0x123c` : ctor FUN_005a2640, then `[obj]=0x6391f8`
- `match+0x1610` : ctor FUN_0058e050, `[obj]=0x639080`, `[obj+0x1d4]=match`
FUN_005a2640 (shared base ctor) stores `match` at obj+0x18c and `match+0x1610` (the ball) at obj+0x190.
`FUN_005b70b0` is the engine's `get_ball()` -> returns `*(this+0x138)+0x1610`, i.e. **match+0x1610 IS
the ball**; its x/y therefore alias match+0x1614/+0x1618 (read by the GK + ref trackers).

| match off | identity            | vtable   | +8 decide (replay, no-op live) | +0xc ADVANCE (the sim)                         |
|-----------|---------------------|----------|--------------------------------|------------------------------------------------|
| 0x1610    | **THE BALL** (3D)   | 0x639080 | FUN_0058e220 (snapshot+replay) | **FUN_0058e2c0 = ball physics**                |
| 0xaac     | **GK team-1** (idx1)| 0x639208 | FUN_005a4560 (replay)          | FUN_005a2240 -> 5a24b0 -> **FUN_005a22d0**     |
| 0xe74     | **GK team-2** (idx2)| 0x639208 | FUN_005a4560 (replay)          | FUN_005a2240 -> 5a24b0 -> **FUN_005a22d0**     |
| 0x123c    | **REFEREE** (2D)    | 0x6391f8 | FUN_005a4560 (replay)          | FUN_005b5940 -> **FUN_005b5dd0**               |

What each ADVANCE does (verified from disasm, headless = match+0x5fac/0x180* == 0):
- **FUN_0058e2c0 (ball, 0x58e2c0..0x58ebd0)** -- the full ball model, MUST port:
  (a) timers dec (+0x5c/+0x68/+0x70); (b) lerp-to-target over +0x6c steps toward +0x9c/+0xa0/+0xa4
  (set-piece ball placement); (c) free flight: tentative pos+vel, a display+sound bounce probe gated
  by 0x5fac (SKIP headless, 0x58e448..0x58e632), then the headless-relevant collision loop over the
  match+0x17f4/+0x17f8 collider list (FUN_00590b30 seg-test + FUN_005efac0 resolve -> goal/post
  bounce, goal detect via +0x448 phase + FUN_005909f0 + FUN_00594470); (d) gravity: airborne (z>0)
  adds global accel DAT_0066c1b0/b4/b8 to vel; ground (z<=0) bounce -> z=0, vel damped by
  FUN_005edfa0(.,0xc51e) horiz / -FUN_005edfa0(.,0x9c28) vert, stop when |vx|,|vy|<0x22; (e) spin
  frame +0x2c by speed FUN_005ee500; (f) tail FUN_0058fda0. NB the +0x23d7 added/removed around the
  collision phase is a working-frame coord bias, not state.
- **FUN_005a22d0 (GK, idx in +0x3bc)** -- slides the keeper along x toward ball.x (match+0x1614),
  pinned to the goal x (match+0x1820 +/-0x40000), accel in +0x3c0 clamped [-0x1555,0x1555], sets
  facing +0x34 via atan2 to ball; calls FUN_005a5430 (set_position_code, DONE). Affects saves ->
  MUST port for outcome.
- **FUN_005b5dd0 (referee)** -- moves itself in 2D (writes obj+0x4/+0x8) following the ball via atan2
  (FUN_005ee080) + dist (FUN_005edfb0); sets own anim state. Writes NO ball/score/phase/+0x454 field.
  **Outcome-irrelevant -> SKIP candidate** for the headless scoreline engine (verify no player decide
  reads match+0x123c first).

## Remaining ports to reach the full-match KILL-TEST (driver 0x598740)
SIM, in dependency order:
1. ~~**FUN_005a4560** (ADVANCE, vtable+0xc)~~ **DONE 2026-06-19** -> Pm98Movement.advance + _advance_motion,
   oracle test_advance.gd (48 ck). **FINDING: it is PURE replay record/playback, NOT physics** -- the
   player position (+0x4/+0x8/+0xc) is set directly by DECIDE (FUN_005a3400) each tick. NO-OP in a live
   headless run (ring != 0, or replay+record both off). leaf FUN_005ed8e0 = the 9-dword motion snapshot.
2. ~~**FUN_005b73a0** (positioning, ~4.8KB)~~ **DONE 2026-06-19** -> slices A-H (f5544ae), all set-piece
   branches ported + per-slice oracles. Pm98Movement.position_team.
3. ~~resolve the 4 sub-entity vtables~~ **RESOLVED 2026-06-19** (table above). Resolution turned up
   THREE unported SIM functions (the prior "render/skip" reading was a delta-0x401208 artifact):
   a. **FUN_0058e2c0 -- ball physics (BIG, the priority).** Will need slicing (lerp / collision-loop /
      gravity+bounce / spin). Leaves to confirm/port first: FUN_005efac0 (ball-vs-collider resolve),
      FUN_00590b30 (seg/box test), FUN_005ee500 (speed mag), FUN_0058fda0 (tail), FUN_005909f0,
      FUN_00594470 (goal/restart), FUN_005edfa0 (DONE? it's the rotate/scale used in trig moveleaves),
      FUN_005ee080/0f0 (DONE). Decide companion FUN_0058e220 = FUN_005ed8e0 snapshot + replay (no-op).
   b. **FUN_005a22d0 -- goalkeeper x-track (MEDIUM).** Two instances, idx in +0x3bc. Leaf FUN_005a5430
      (DONE). Affects saves -> needed for scoreline.
   c. FUN_005b5dd0 -- referee 2D follow. SKIP candidate (writes only its own pos); confirm no reader.
4. the small per-tick helpers: FUN_00593a30, FUN_00593b70, FUN_005946d0, FUN_00594410,
   FUN_005942e0, FUN_00594570, FUN_005910c0, FUN_00591120, FUN_0058f0b0, FUN_0058f3c0,
   FUN_005a1820, FUN_0059a120, FUN_0059a1e0, FUN_00590ac0.
5. **FUN_00598740** itself (the driver) -> then the full-match kill-test (event-stream + scoreline
   parity, fixed seed, N>=50).

DISPLAY / SOUND (stub or skip in the headless engine -- all gated by match+0x180b/0x180c/0x180d/0x5fac):
- FUN_005a5460 (sprite/anim, vtable+4 on player AND vtable+0 on the GK/ref classes), FUN_005b70e0
  (render shell). The sub-entity vtable+0/+4 slots (FUN_005a5460/5a2140/5902b0/58e120/5b5790) are the
  DRAW/aux methods, NOT the per-tick decide/advance the driver calls (+8/+0xc) -- do not port them.
- FUN_00590f00/f40/f60 (sound), FUN_004e* (commentary), FUN_005f* (sprite draw), FUN_00436fb0.

## Note
The headless match-outcome engine does NOT need the render passes (FUN_005a5460 / FUN_005b70e0) nor
the replay decide-slots. With player DECIDE/ADVANCE + positioning all DONE, **the correct next sim
port is the ball physics FUN_0058e2c0, then the goalkeeper FUN_005a22d0, then the FUN_00598740
driver** (referee FUN_005b5dd0 is a skip candidate). The earlier "all 4 sub-entities are render,
skip them" reading was wrong: it came from reading the vtables at file delta 0x401208 (off by 8),
which put the sprite method at the +8/+0xc slots. Correct delta is 0x401200.
