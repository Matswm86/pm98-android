# PM98 -- match-tick driver call-graph map (FUN_00598740)

> **⛔ CORRECTION 2026-06-23 (LIVE WINE TRACE) — the player vtable base below is OFF BY 4.**
> The live match's player objects carry vtable pointer **`0x639228`**, NOT `0x639224` (verified by
> `winedbg` on a real watched match: `EAX=[player]=0x639228`; and by the object ctors at
> `0x5a271e/0x5a295c/0x5b6ec6` storing `0x639228`). `0x639224` is a DIFFERENT class's vtable.
> Consequence: every "FUN_005b8xxx → +off → FUN_005aXXXX" mapping in this file is shifted one slot.
> **LIVE-CONFIRMED:** the per-tick dispatcher `FUN_005b8c20` (`call [eax+0xc]`, eax=0x639228 →
> `[0x639234]`) calls **`FUN_005a4600`** (the action-resolve → resolver `FUN_005aeda0` → scoring),
> NOT `FUN_005a4560`. This is why the headless port stays at phase 2 / 0-0: it ported `FUN_005b8c20`'s
> target as the no-op replay `FUN_005a4560`. Full evidence + the corrected vtable + the port fix:
> `[[handoff-pm98-vtable-offset-rootcause-2026-06-23]]`. **The vtable + dispatcher + per-tick sections
> below are now CORRECTED to base 0x639228 (2026-06-23) and verified three ways (live trace, binary
> bytes, sub-entity-pattern cross-check); a FUN_005a4600 structural map + port scope is appended at the
> end.** The 2026-06-19 "VA<->file delta" note just below predates the correction -- the LAYOUT it
> defends is right, but its `+8=DECIDE / +0xc=replay` role labels were the off-by-4 and are superseded.


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

## Player vtable (base VA **0x639228**, the object whose `this` is a player, stride 0x3bc)
**CORRECTED 2026-06-23** (live wine trace + binary bytes + sub-entity-pattern cross-check; supersedes
the old 0x639224 reading above). The contiguous vtable bytes at file 0x238024 (VA 0x639224) are:
```
VA 0x639224  0x5ed810   (dtor/RTTI)                      <- this slot belongs to the OTHER class
VA 0x639228  0x5a5460   FUN_005a5460   <- PLAYER vtable +0x00
VA 0x63922c  0x5a3400   FUN_005a3400   <- PLAYER vtable +0x04
VA 0x639230  0x5a4560   FUN_005a4560   <- PLAYER vtable +0x08
VA 0x639234  0x5a4600   FUN_005a4600   <- PLAYER vtable +0x0c
VA 0x639238  0x5ed810   (dtor/RTTI)    <- PLAYER vtable +0x10
```
The live match's player objects store **0x639228** as their vtable pointer (winedbg: `EAX=[player]=
0x639228` at the FUN_005a4600 breakpoint; object ctors at 0x5a271e/0x5a295c/0x5b6ec6). So the PLAYER
vtable, read from its true base, is:
```
+0x00  0x5a5460   FUN_005a5460   = per-player SPRITE/ANIMATION draw  (DISPLAY, skip headless)
+0x04  0x5a3400   FUN_005a3400   = per-player DECIDE / set-piece positioning  (SIM)  -- ported as decide_slice_a/b/c
+0x08  0x5a4560   FUN_005a4560   = per-player ADVANCE replay rec/play  (no-op live)  -- ported as Pm98Movement.advance
+0x0c  0x5a4600   FUN_005a4600   = per-player OPEN-PLAY ENGINE (stamina + set_phase + action switch + move + resolve)  -- *** NOT PORTED ***
+0x10  0x5ed810   (dtor/RTTI)
```
The per-player passes are driven by trivial player-loop dispatchers (each loops `param_1[1]` players
from base `*param_1`, stride 0x3bc, `this`=player; the `call [eax+N]` offset is intrinsic to each
dispatcher, base=0x639228):
- `FUN_005b70e0` -> calls vtable **+4** = **FUN_005a3400 (DECIDE / positioning)**, then a select-active
  walk. Called **ONLY in the set-piece branch** (driver L96, x2), NOT in open play. (Old map called
  this "RENDER pass via +4=FUN_005a5460" -- WRONG, that was the off-by-4.)
- `FUN_005b8bf0` -> calls vtable **+8** = **FUN_005a4560 (replay rec/play, no-op live)**. Per-tick x2.
  (Old map called this "+8 = DECIDE FUN_005a3400" -- WRONG.)
- `FUN_005b8c20` -> calls vtable **+0xc** = **FUN_005a4600 (the OPEN-PLAY per-player ENGINE)**. Per-tick
  x2. *** This is the real sim and it is NOT yet ported. *** LIVE-CONFIRMED. (Old map called this
  "+0xc = ADVANCE replay FUN_005a4560" -- WRONG; that shifted the whole movement core one slot.)

This `+8 = FUN_005a4560 replay / +0xc = real advance` layout is **identical to the already-verified
sub-entity vtables** (GK 0x639208, ref 0x6391f8; see the sub-entity table below) -- the player class
follows the same shape, which is the third independent confirmation of base 0x639228.

> **PORT CONSEQUENCE (the "stuck at phase 2 / 0-0" root cause):** the port currently runs
> `decide_slice_a/b/c` (FUN_005a3400) in the open-play movement core and `Pm98Movement.advance`
> (FUN_005a4560 replay) as the +0xc pass. Both are one slot off. In open play DECIDE must NOT run
> (it is the set-piece-only +4 pass), the +8 pass is the live no-op replay, and **the +0xc pass must
> run a port of FUN_005a4600** -- the only path that calls `FUN_005a50c0` (set_phase, advances phase
> 2->0) and the resolver `FUN_005aeda0` (case 8/9, scoring). See the FUN_005a4600 structural map at the
> end of this file.

## FUN_00598740 per-tick SIM sequence (this = match, returns 1=continue / 0=match over)
Stripping the display/sound/commentary (FUN_00590f00/f40/f60, FUN_004e*, FUN_005ec240/230 RNG
save-restore brackets that net-zero), the load-bearing simulation order is:

1. `FUN_00593a30()` -- per-tick pre-update (NOT ported; classify).
2. set-piece special (phase 7, or phase 5 w/ +0x19cc, taker-side, first-time): rebuild a queue,
   `FUN_005b8f20` (select_active, DONE) -> match+0x438, then `FUN_005b70e0`x2 (RENDER) +
   `FUN_005b73a0`x2 (positioning). Then return early. NOTE: the x2 FUN_005b70e0 here is render;
   the sim-relevant part of this branch is select_active + FUN_005b73a0.
3. main sequence (the per-tick movement core), each called **x2 (once per team)**. CORRECTED
   2026-06-23 for the 0x639228 base -- the player +8 / +0xc roles were swapped in the old map:
   - `FUN_005b8bf0` x2  -- player **+8 dispatch -> FUN_005a4560 (replay rec/play, NO-OP live)**. The
     player decide/positioning (FUN_005a3400) is NOT here; it is the +4 pass run only by FUN_005b70e0
     in the set-piece branch.
   - 4 sub-entity +8: `(*[match+0x1610]+8)()`, `+0xaac`, `+0xe74`, `+0x123c` -- vtable+8.
     **IDENTITIES RESOLVED 2026-06-19 (see "Sub-entity resolution" below): ball + 2 GKs + referee.**
     All four +8 methods are replay record/playback (FUN_0058e220 ball-snapshot, FUN_005a4560
     for the other three) -> NO-OP in a live headless run (DAT_006d31c4==0). The SIM work is in +0xc.
   - `FUN_005b8690` x2  -- relationship matrix (DONE).
   - `FUN_005b94f0` x2  -- marker assignment (DONE).
   - `FUN_005b8c20` x2  -- player **+0xc dispatch -> FUN_005a4600 (the OPEN-PLAY ENGINE)**. *** NOT
     PORTED *** -- this is the real per-tick player sim (stamina, set_phase via FUN_005a50c0, the
     action-code switch incl. resolver FUN_005aeda0, and the movement FUN_005a65a0/7260/8f20).
   - 4 sub-entity +0xc: `(*[match+0x1610]+0xc)()`, `+0xaac`, `+0xe74`, `+0x123c` -- vtable+0xc.
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

---

## Driver body decode + RNG-draw inventory (2026-06-22)
Read the full FUN_00598740 decompile (6507 bytes, /tmp/pm98dec/fn_00598740). The ball physics
(FUN_0058e2c0 -> Pm98Movement.ball_advance) and goalkeeper (FUN_005a22d0 -> keeper_advance) are
DONE since 06-20/06-21, so all the *sub-entity ADVANCE* slots the driver invokes are ported. What is
left is the driver shell itself + a few leaves. The 4 remaining PURE leaves are now PORTED + emu-
oracle-validated (this slice): `vec3_set` (FUN_00590aa0), `play_state_eq` (FUN_005943b0/f0/d0 -> the
`match+0x468->+0xfa0 == {0,2,4}` play-state predicates; `_phase0` now delegates), `clamp_x_goalside`
(FUN_0059a1e0), `restart_box_ok` (FUN_0059a120 = the SAME-side twin of pos_forward_ok). Oracle
`tools/re/run_driverleaf2_oracle.sh` -> `specs/driverleaf2_oracle.txt`; locked by `test_driverleaf2.gd`
(14 checks). FUN_0058f0b0 (player_opposite_half) was done earlier.

### Sim-relevant control-flow skeleton (what the body port must reproduce, in order)
1. `FUN_00593a30` -- sets the display flags +0x180a/b/c from match+0x468->+0xfe8/fec/ff0. **DISPLAY-
   only**; headless (+0x180e==0) leaves them 0. Port as a no-op (or faithful flag set; nothing else reads
   them on the scoreline path).
2. `cVar3 = match+0x1a1e; match+0x1a1e=0; if (cVar3) { FUN_00593b70(); goto end; }` -- a one-shot
   "skip-tick" gate (FUN_00593b70 = NOT yet classified; rare).
3. set-piece special (phase 7, or phase 5 w/ +0x19cc; taker-side; first-time via +0x1a20): rebuild the
   queue (FUN_005bbf10 = Array.append), `FUN_005b8f20` (select_active, DONE) -> +0x438, render x2 (SKIP),
   `FUN_005b73a0` x2 (position_team, DONE), then **early return**.
4. replay record/playback (DAT_00665d8c / DAT_006d31c4): the +0x27dc/+0x27e4 snapshot rings + FUN_005910c0
   /FUN_00591120. **SKIP in a live no-record run** (both flags 0).
5. per-tick idle-counter bump (+0xcb per team, lines 164-179) -- trivial counters.
6. movement core (all DONE): FUN_005b8bf0 x2 (decide dispatch), 4 sub-entity decide (+8 = replay, no-op),
   FUN_005b8690 x2 (relmatrix), FUN_005b94f0 x2 (markers), FUN_005b8c20 x2 (advance dispatch), 4 sub-entity
   advance (+0xc = ball_advance + keeper_advance x2 + referee[SKIP]), FUN_005b8ce0(0) x2 (nearest),
   then `DAT_006d31bc = (DAT_006d31bc+1) & 0x3ff` (the 1024-frame ring counter).
7. open-play / restart classification (lines 209-692), the per-tick "what happened" decision. ONE
   `FUN_005966d0(code)` fires (dispatcher DONE = Pm98Dispatch). Code map by branch:
   - +0x43c != 0 (a restart is pending), the `within_box`/`restart_box_ok` placement ladder (lines
     213-359) -> sets +0x19cc {0,2,6} via the 4 region tests + `FUN_005966d0((+0x461&1)<<1|5)` = 5/7.
   - `!FUN_0058f100 && FUN_0058ede0` (goal-area, lines 361-480): per-player loop; +0x19a0==4 (penalty/ET)
     -> goal-diff test -> FUN_005966d0(1); else -> FUN_005966d0(6) = GOAL.
   - +0x19a0==4 special (lines 481-544) -> FUN_005966d0(1) or (3).
   - FUN_0058fbe0 (corner) -> FUN_005966d0(4); FUN_0058f140 (keeper save) -> FUN_005966d0(2);
     **FUN_0058f3c0 (UNPORTED predicate) -> FUN_005966d0(3)**; the attacking-move build-up -> FUN_005966d0(1).
8. stat/commentary tail (lines 693-888, only under phase==0): possession% (FUN_00590f60 sound = SKIP),
   and the THREE commentary/event TIMER blocks (+0x19e4, +0x19e8, +0x19ec) -- see RNG note below.
9. `FUN_00594570(0)` -- event-queue DEQUEUE (decrement each queued event's +0xc delay, fire
   FUN_004511d0 = commentary thunk [no-op headless], shrink the array). SIM-relevant (queue timing).
10. match-over: returns 0 iff `match+0x454 == 1` (else decrements +0x454 toward 1 when >1).

### RNG-draw inventory (LOAD-BEARING for the kill-test -- a single missed draw desyncs the whole match)
The MSVC LCG (FUN_005ec250 = Pm98Rng) is the match seed. `FUN_005ec240`/`FUN_005ec230` are a
save/restore bracket: any draw BETWEEN a matched 240...230 pair is **seed-neutral** (used so cosmetic
commentary text does not perturb the deterministic match). **CORRECTION to match_engine_re.md's "the
only seed-affecting draws are dispatcher case 2/6":** the driver's per-tick commentary/event TIMERS use
UNBRACKETED FUN_005ec250 and therefore DO advance the match seed. Full inventory:
- **Seed-NEUTRAL (inside 240/230 brackets, all cosmetic FUN_004e* commentary):** lines 431-439, 530-537,
  616-623, 637-666, 676-690, 715-724, 849-863, 868-874. No FUN_005ec250 sits inside any bracket.
- **Seed-ADVANCING (unbracketed FUN_005ec250):**
  - L465: 1 draw (discarded), open-play goal-area per-player loop, branch `(char)player[0xb8]!=0`.
  - L747+L750 + exactly one of {L754|L758|L768|L772}: the +0x19e4 timer-expiry block = **3 draws** when
    `--match+0x19e4 < 1`.
  - +0x19e8 block: L792 (always on expiry) + L796 (short-circuit, only if `iVar19 >= -1`) + L799 (only if
    not early-out) = **1-3 draws** when `--match+0x19e8 < 1`.
  - +0x19ec block: L844 = **1 draw** when the gate at L831-838 passes (incl. `FUN_005e2750()==0`, non-RNG).
  - Inside `FUN_005966d0` (DONE): case 2 (ball-speed gate) + case 6 (genuine goal) each draw -- already
    modeled in Pm98Dispatch.
So a bit-exact full-match port MUST port the +0x19e4/+0x19e8/+0x19ec commentary timers (even though their
outputs feed display) purely to keep the seed in lockstep, plus the L465 per-player discard draw.

### Blockers for the full-match KILL-TEST (why STEP 2 is multi-session, not done here)
1. **No 22-player match-init.** The driver needs a fully-built match object `m` (22 players w/ vtables +
   coords, ball, 2 GKs, referee, goal dims, the post array). That constructor is **FUN_00591180** (+ the
   goal-dim arithmetic FUN_00593600, decoded in the builder handoff) and is **NOT yet ported**. STEP-1
   wired `populate_posts(m)` (the collider array) only -- not the players. Without this, the full-match
   loop cannot run end-to-end.
2. **No end-to-end oracle.** Per-leaf parity uses PcodeEmu on synthetic fixtures; a full match needs the
   REAL event stream + scoreline for a fixed seed. Two options: (a) **wine** (`/usr/bin/wine` is present) +
   a debugger/save-game harness that drives MANAGER.EXE to a match and dumps the +0x1a24 event queue per
   tick; (b) a full-match PCode-emu run (needs FUN_005bbf10/GlobalReAlloc stubbed as Array.append + the
   whole match object in emu memory + thousands of ticks). Neither exists yet.
3. **FUN_0058f3c0** (one open-play classification predicate -> FUN_005966d0(3)) is still UNPORTED.

**Recommended next-session order:** (a) port FUN_0058f3c0 + classify FUN_00593b70; (b) port the driver
shell FUN_00598740 into a new `Pm98Driver.gd` calling the DONE pieces + the timer draws above, with
push_error stubs for any residue; (c) port match-init FUN_00591180 to build a valid `m`; (d) stand up
the wine OR full-emu oracle; (e) run the N>=50 fixed-seed event-stream + scoreline parity kill-test.

---

## FUN_0058f3c0 PORTED + FUN_00593b70 CLASSIFIED (2026-06-22)

### FUN_0058f3c0 -- DONE (Pm98Predicates.dead_ball, oracle-locked)
The last open-play classification predicate. Read the 1922-byte decompile (/tmp/pm98dec/fn_0058f3c0).
It is the **mirror-side twin of post_bar (FUN_0058fbe0)**: identical [signed_line, 2*signed_line]
x-box, [-w, w] y-box (w = match+0x1824), and the identical z/y position-clamp + velocity-reflect, but
the box sign is taken on the OPPOSITE parity (`(poss&1)==(1-side)` vs post_bar's `(poss&1)==side`),
so it watches the ball dying behind the FAR goal line -> dispatcher code 3 (`_case_restart`, dead ball).
Two SIM deltas vs post_bar, both ported:
1. The aim/deflection target +0x90/+0x94/+0x98 is written **UNCONDITIONALLY** (before the box test):
   +0x90 = signed(0x58000 - line), +0x94 = sign(ball.y)*0x928f5, +0x98 = 0. So even a return-0 call
   rewrites the ball's aim (post_bar only writes it on collision).
2. On exit it clears ball+0x50 = 0 (LAB_0058fb27).
Return = the box-test bool. As with keeper_save, the ball+0x50!=0 tail (keeper-proximity probe
FUN_005909f0 + the 0x17/0x18/0x19 event enqueues via FUN_00594470) is DEFERRED to driver integration;
the SIM port is validated with ball+0x50==0. **NO unbracketed FUN_005ec250 in this function** -> it is
SEED-NEUTRAL (the lone FUN_005ec240/230 pair in the else-branch is a save/restore around skipped
commentary). Oracle: 5 new `f3c0_*` rows in run_predicate_oracle.sh -> predicate_oracle.txt; locked by
test_predicates.gd.

### FUN_00593b70 -- CLASSIFIED: the match-restart / phase-reset routine (NOT a pure leaf)
Read the 1858-byte decompile (/tmp/pm98dec/fn_00593b70). It is the **one-shot restart handler** invoked
from the driver's `+0x1a1e` skip-tick gate (driver skeleton step 2): when +0x1a1e was latched the prior
tick, THIS tick runs the full kickoff/restart instead of the normal movement core, then the driver
`goto`s its end. It is driver-shell-sized (it calls select_active + position_team + the phase setups),
so it must be ported ALONGSIDE the FUN_00598740 shell (STEP-2 item 2), **not as an isolated oracle'd leaf.**

What it does (sim-relevant skeleton):
- If `+0x1a38 != 0` (a restart type is pending) and DAT_006d31c4==0: phase = `DAT_00664070[+0x1a38]`,
  set +0x44c/+0x448 = phase, FUN_005946d0 (per-player reset, modeled no-op in Pm98Dispatch). Then
  `switch(+0x1a38)`:
  - `==1` kickoff: +0x19a8 += +0x450; clear +0x1a1f/+0x450/+0x19a4; `switch(+0x19a0)` runs the kickoff
    placement FUN_0044d0d0/d190/d250/d310 (case1 may +2 to +0x19a0; case3 clears +0x45c); then +0x19a0 += 1.
  - `1<x<9` (+ flag gate): a 2x11 player-position snapshot+compare loop (FUN_0044d3d0) latching bVar3.
  - if `+0x19a0 != 4 || +0x19c0==0`: FUN_005b6ba0 x2. Then FUN_005946f0.
- If `+0x19a0 == 4` (penalty/ET): +0x44c/+0x448 = 7; ball spot +0x16a0 = signed(+0x1820 - 0xb0000) by
  +0x45c, +0x16a4/+0x16a8 = 0.
- **State reset block** (always): zero +0x460, +0x461&=0x38, +0x1994, +0x1998, +0x454, +0x19dc, +0x434,
  +0x43c, +0x440, +0x438, +0x444; FUN_005946f0; **+0x1a34 = timeGetTime()** (WALL-CLOCK, non-deterministic
  -- must stub on the headless path; verify nothing on the scoreline path reads it); +0x1a38=0,
  +0x461&=0xcf, +0x1a1f=0, **DAT_006d31c0=0, DAT_006d31bc=0 (resets the 1024-frame replay-ring counter)**,
  +0x27ec=0; re-init the 2 replay rings +0x27dc/+0x27e4 (FUN_005bbf10 = Array clear), +0x27e0/+0x27e8=0.
- Movement re-seed: ball vtable+4 (render, SKIP), FUN_005b8f20 (select_active, DONE) -> +0x438,
  FUN_005b70e0 x2 (render, SKIP), FUN_005b73a0 x2 (position_team, DONE), 3 sub-entity vtable+4 (render,
  SKIP); +0x458=0; FUN_005f5740/57a0/5800 (ball-trail display, SKIP).
- Tail: `switch(+0x448)` commentary, all gated by +0x180b (display) inside 240/230 brackets.

**RNG / kill-test impact:** exactly **ONE unbracketed FUN_005ec250 draw** (decompile L198), and only
when `+0x448 ∈ {2,3,4,5,6}` -- for any other +0x448 the routine early-returns (L195-196) BEFORE that
draw. Everything else is inside 240/230 save-restore brackets (seed-neutral). CAVEAT: the RNG behaviour
of the callees FUN_005946d0/FUN_005946f0/FUN_005b6ba0/FUN_005b8f20/FUN_005b73a0/FUN_0044d0d0../FUN_0044d3d0
is UNVERIFIED -- confirm each draws nothing (or model it) when porting the shell.

---

## DRIVER SHELL PORTED -> Pm98Driver.gd (2026-06-22)

`FUN_00598740` (the per-tick driver) + `FUN_00593b70` (the restart handler) are PORTED to
`app/scripts/Pm98Driver.gd` -- `Pm98Driver.tick(m, rng) -> 1/0` and `Pm98Driver.restart_handler(m, rng)`.
This is the integration shell wiring every DONE piece in the binary's exact per-tick order. **It is a
TRANSCRIPTION of the decompile/disasm, NOT end-to-end-oracle-validated** (blocked by the two STEP-2 gaps:
no 22-player match-init FUN_00591180, no full-match oracle). `app/tests/test_driver.gd` (34 checks) locks
everything that is a pure function of the match Dict and needs no live players.

### Disasm correction banked this session
`FUN_0058f100` is Ghidra-typed `void` but the driver reads its return as a bool. Disasm (0x58f100) shows
it returns **AL = ball+0x63** (the armed flag): `mov al,[ecx+0x63]` at entry, never overwritten on any
exit path. So `cVar3 = FUN_0058f100()` == `ball+0x63` (the trajectory copy is a side effect when armed
AND phase==0). The driver port calls `Pm98Predicates.traj_copy` for the side effect, then reads
`_g(b, 0x63)` for the boolean -- faithful.

### What test_driver.gd LOCKS (transcription, decompile-exact, no live players needed)
- **Match-over return** (LAB_0059a06e): over iff +0x454==1; the +0x454>1 cooldown decrement.
- **+0x1a1e skip-tick gate** -> restart_handler + ITS lone seed draw (fires iff final +0x448 ∈ {2..6}).
- **Set-piece special** (phase 7 / phase 5+0x19cc, taker byte team*800+0x759) -> +0x1a20 latch + early return.
- **FUN_00593a30** headless flag clear (+0x180a/b/c -> 0 when +0x180e==0).
- **Open-play predicate-cascade DISPATCH CODES**, read back from match+0x1a38: dead_ball->3, post_bar->4
  (corner), build-up->1, restart-placement->5/7 (by +0x461 bit0). Goal-area->6.
- **Complete per-tick RNG-draw inventory**, measured by replaying a reference Pm98Rng from the pre-tick
  state: +0x19e4 (exactly 3 on expiry), +0x19e8 (1 / 3 by score-diff), +0x19ec (1 when the minute/ball
  gate passes), and the **L465 goal-area discard draw** (1, gated by the team*800+0x478+0x2e0 byte). The
  dispatch case-2/6 internal draws are already pinned by test_dispatch.gd.
- **FUN_00594570 dequeue**: play-state 0/4 flushes all; play-state 1 + phase 0 decrements per-event delay
  and fires only delay<=0.

### What is BEST-EFFORT in the port (exercised only once match-init lands)
- The **movement core** wiring (decide/relmatrix/markers/advance/nearest per team + ball_advance/
  keeper_advance) -- runs only when `m["sim"]`/`m["ball"]`/`m["keepers"]` are populated; the shell no-ops it.
- The **player-pointer field writes** inside the goal-area / restart-placement / keeper-throw branches
  (scorer+0x1e0 goal vector, the +0x19cc region geometry, the taker stamina) -- read/written via `_ref`
  so they no-op cleanly when the sub-objects are absent.
- `FUN_00593b70`'s **DAT_00664070[+0x1a38]** restart-type->phase table is modeled as identity
  (`_restart_phase`) pending the .rdata extraction; **+0x1a34 = timeGetTime()** is STUBBED to 0 (wall-clock,
  must be injected to match in an e2e oracle).

### STILL-OPEN caveats carried into the kill-test
- `FUN_005946d0` (`_team_reset`) and `FUN_005b6ba0`/`FUN_0044d3d0` RNG remain UNVERIFIED (modeled
  non-drawing, same caveat Pm98Dispatch carries). `FUN_005b73a0` (position_team) DOES draw on set-piece
  phases and is wired with `rng` -- its exact draw count needs real player geometry (match-init).
- DATA MODEL: `m` = match; `m["ball"]` = the ball at match+0x1610 (driver match+0x16XX reads -> ball
  offset 0x16XX-0x1610); `m["sim"]` = [ctx0,ctx1]; `m["keepers"]` = [k0,k1]; `m["ring"]` = DAT_006d31bc.

---

## MATCH-INIT CONSTRUCTOR FUN_00591180 PORTED -> Pm98Match.gd (2026-06-22)

`FUN_00591180` (the match-object ctor that `operator new(0x5fb8)` + the create-wrapper FUN_00590fc0
run) is PORTED to `app/scripts/Pm98Match.gd` -- `Pm98Match.build_match(rng) -> m`. TRANSCRIPTION of
the decompile (docs/re/sim/fn_00591180...) cross-checked against the **objdump this-pointer offsets**
(`esi` = match base; every sub-ctor `lea ecx,[esi+off]` confirmed). Locked by `app/tests/test_match_init.gd`
(**130 checks PASS**). Same posture as the driver shell: not e2e-oracle-validated (the ctor calls
operator_new + the CRT + globals, so it is not a pure PCode-emu leaf).

### Sub-ctors decompiled this session (Ghidra DecompileAt 0x5b6360/0x5917f0/0x591560/0x591830)
- `FUN_005c52b0(this=match+0)` -- the BASE subobject embedded at match+0 (C++ ctor chaining): base
  bbox at match+0x3fc..+0x418 (LO/HI sentinels), match+0xb4 = 1, temp vtable 0x639888 (overwritten).
- `FUN_005b6360(this=team header)` -- the team ctor. **Leaves team[0]=0 (player-array base = null) and
  team[1]=0 (count) -> the ctor builds an EMPTY-ROSTER match.** The 22 players are heap-allocated +
  loaded by the POPULATE FUN_005923f0 (next port). team[0x5a]=0 == movement ctx[0x168] (active idx).
- `FUN_005917f0` -- the 9x8-byte array element ctor ({0,0} each). `FUN_00591560`/`FUN_00591830` are the
  team / 0x4c-array DESTRUCTORS (free header[0] player array, stride 0x3bc -- confirms players are
  heap, not in the header).

### Object map inside FUN_00591180 (match byte offset -> what)
| off    | object                          | ctor              |
|--------|---------------------------------|-------------------|
| +0x0   | base subobject (bbox +0x3fc..)  | FUN_005c52b0      |
| +0x46c | team0 header (= m["sim"][0])     | FUN_005b6360      |
| +0x78c | team1 header (= m["sim"][1])     | FUN_005b6360      |
| +0xaac | keeper0 (idx 1, vt 0x639208)     | FUN_005a2640      |
| +0xe74 | keeper1 (idx 2, vt 0x639208)     | FUN_005a2640      |
| +0x123c| referee (vt 0x6391f8)            | FUN_005a2640      |
| +0x1610| ball (vt 0x639080)               | FUN_0058e050      |
| +0x2470| 9x 8-byte array                  | FUN_005917f0 elem |
| +0x24b8/+0x2504/+0x2550 | 0x4c bbox holders | FUN_005c9210     |
| +0x259c| 2x 0x4c array                    | FUN_005c9210 elem |
| +0x2634| anim/state holder                | FUN_005d7240      |
| +0x27f0| 3D-extent holder                 | FUN_005f56a0      |
| +0x2884..+0x2b40 (stride 0x64) | 8x scale holders | FUN_005f2ad0  |
| +0x2bac| **noise+param table**            | FUN_005baca0      |

### LOAD-BEARING for the seed kill-test: 1080 ctor RNG draws
`FUN_005baca0(this=match+0x2bac)` draws `FUN_005ec250` (the match seed) **exactly 3*360 = 1080 times**
to fill a 360x3 noise table (each value = `(roll*0x1000)>>7` = roll*32 for the 15-bit rand), then a
240x8 float-default record table (no RNG: 0.5f/1.0f/-2.0f/0/0.992f/0.992f). build_match(rng) reproduces
all 1080 draws; test_match_init asserts the rng state advances by exactly 1080. **CAVEAT (unresolved
until FUN_005923f0 is decoded): whether these 1080 ctor draws are part of the per-tick match seed
stream depends on where the populate (re)seeds the match RNG. If it srand()s after construction, pass a
throwaway rng to build_match.**

### STEP-2 REMAINING (item 3 = ctor now DONE; renumbered)
3a. **DONE** -- match-init CTOR FUN_00591180 -> Pm98Match.build_match (skeleton, empty roster).
3b-kickoff. **DONE 2026-06-22** -- match KICKOFF / phase-init FUN_00593600 -> Pm98Match.kickoff_init(m,
    session, rng). Goal geometry (+0x1820/+0x1824 = half pitch len/width from session+0x4c/+0x50), the
    pitch box (+0x1828..+0x183c, min/max-ordered), the free-kick spot tables (+0x194c..+0x197c), phase=2
    (+0x448/+0x44c), the kickoff side (+0x19c8/+0x45c) + the 3 commentary timers (+0x19e4/8/c) the driver
    decrements, arms +0x1a1e, +0x180e=1, +0x454=0. **Draws the match seed EXACTLY 4x on the empty
    skeleton** (verified: FUN_005b6ba0/005b6ee0/00593a30/005f57xx all draw 0). DAT_00664060 pitch-type
    table = [0x1c20,0x3840,0x5460,0x8ca0]; DAT_00664070 restart->phase = [0,2,3,6,4,5,2,7] (banked, wired
    into Pm98Driver._restart_phase -- was identity; 3->6 and 6->2 differ). Locked by test_kickoff_init.gd
    (61 ck) + sweep 86/86 + boot 0 errors.

> **CORRECTION (2026-06-22), supersedes the prior item-3b premise.** The handoff said FUN_005923f0 "loads
> the 22 players". **FALSE -- verified against the decompiles + objdump.** FUN_005923f0 is the match
> **asset / layer / display loader**: palettes (DatSim\paletas\palarb/pallin), the grass texture
> (hierba_raw), the per-league hierarchy textures (hier*_raw), the clock FLC (coreloj), the goalkeeper
> save models (Modelos\/PARADOS) -- all DISPLAY, irrelevant to the headless scoreline engine. Its ONLY
> sim-relevant tail callee is FUN_00593600 (the kickoff-init ported above). FUN_00591ba0 (the handoff's
> "per-team populate") is the match **DESTRUCTOR** (frees the team-header array via
> FUN_00605da0(match+0x46c, 800, 2, FUN_00591560)). **The real 22-player loader is the chain
> FUN_00593600 -> FUN_005b6ba0 (per-team; builds 11 players, loop 0x764/0xac, stride 0x3bc, from the
> squad source at team+0x9c) -> FUN_005a2830 (per-player builder).** team+0x9c (the squad source) is set
> by the match-START caller at 0x44f1xx (the sole caller of the create-wrapper FUN_00590fc0; this=career
> object `ebx`, ebx+0xfa0 = play-state), which loads it from the career / save subsystem -- OUTSIDE this
> sim corpus. So a fully-standalone match-init needs that subsystem; the kill-test can instead seed the
> player array from an oracle dump (see item 4).

3b-players. **NEXT: port the player-build chain FUN_005b6ba0 (per-team) + FUN_005a2830 (per-player).**
    FUN_005b6ba0 reads the squad header (team+0x9c: 9 dwords -> team[0xbf..199]) then builds up to 11
    players (FUN_005a2830(match, slot_idx, team+0x138, squad_slot+0x2c), stride 0x3bc, growing team[0]
    base / team[1] count), then assigns the keeper/marker slots (team+0x5b.. by player+0x2c8 role; +0x2d6
    captain). **VERIFY FUN_005a2830's seed-draw count** (its callees not yet checked) -- if it draws, the
    kickoff RNG inventory gains 2*11*k draws. Needs the squad-source data model (or an oracle dump).
3c. **RECONCILE the movement data model**: Pm98Movement reads the opponent descriptor at match+0x46c/
    +0x78c as a players ARRAY (a fixture shortcut), but the binary-faithful ctor stores the 800-byte team
    HEADER there (players at header[0]). Reconcile (edit Pm98Movement opp-descriptor read + re-run
    run_assignmarker_oracle.sh / run_relmatrix_oracle.sh) so the driver's movement core runs on the
    real skeleton. Until then the per-team passes cannot run on build_match's output (the per-tick RNG
    inventory + control flow + kickoff geometry ARE testable, the movement core is not).
4. End-to-end oracle (wine MANAGER.EXE OR full-emu) + 5. the N>=50 fixed-seed kill-test. The oracle path
   can DUMP the kickoff player array (coords+attributes) and seed Pm98Match directly -- this sidesteps
   porting the entire career/save subsystem just to populate 22 players for the parity test.

---

## STEP-5a: e2e PORT RUNNER STOOD UP -> KICKOFF->OPEN-PLAY TRANSITION IS THE BLOCKER (2026-06-22)

`app/tests/run_full_match.gd` drives the port end-to-end for the first time (build_match ->
populate_posts -> inject synthetic 11-player lineup+session @team[0x9c] -> kickoff_init -> loop
Pm98Driver.tick). **It RUNS: 22 players, thousands of ticks, 0 crashes, 1084 construction draws
exactly, deterministic.** But it is STUCK in **phase 2 (kickoff)** -- 0 dispatches, 0:0 forever.

### Why (decompile + objdump verified, not inferred)
- Driver classification (the only event source per tick) runs ONLY in phase 0
  (`FUN_00598740` decompile L210: `if (+0x448 != 0) goto switchD_default`).
- The positional driver sets phase only to **6** (keeper-throw, L563 `FUN_005942e0(6)`) or **8**
  (dispatcher lock, `FUN_005966d0` -> `FUN_005942e0(8)`). It NEVER sets phase 0 or 1.
- `restart_handler` (FUN_00593b70) sets phase via `RESTART_PHASE_TABLE[rtype]` = [0,2,3,6,4,5,2,7],
  but only when `rtype (+0x1a38) != 0`; kickoff sets +0x1a38=0, and no nonzero index maps to 0.
- **ALL 5 callers of `FUN_005942e0` (set_phase):** 0x59711e (dispatcher, val 8), 0x599631 (driver,
  val 6), 0x5a4874 (`FUN_005a4600`), 0x5a5259 (`FUN_005a50c0`, val 1), 0x5ac0a5 (`FUN_005ab5a0`,
  val 0). The only **set_phase(0)** and **set_phase(1)** live in the **resolver family**
  (FUN_005a4600 / FUN_005a50c0 / FUN_005ab5a0 / FUN_005aeda0 / FUN_005a7260 / FUN_005b41c0 -- the
  `match_engine_re.md` resolution set).
- The resolver `FUN_005aeda0` is called ONLY from 0x5a47f9, inside **`FUN_005a4600` = player
  vtable+0x10**. `FUN_005a4600` is invoked ONLY by `call *0x10(reg)` from the **career/UI layer
  (0x44xxxx-0x54xxxx)** -- NOT from the per-tick driver tree (the driver runs vtable +8 DECIDE /
  +0xc ADVANCE / +4 SPRITE only; there is no +0x10 player-loop dispatcher in 0x5b8xxx).

### Conclusion + next move (supersedes "stand up the oracle" as the critical path)
The kickoff->open-play (phase 2->0) transition + the goal/save/miss resolution live in the
**vtable+0x10 resolver pass (`FUN_005a4600`)**, which is NOT wired into `Pm98Driver.tick`. The
unanswered RE question: **WHEN does a live positional match invoke vtable+0x10?** (the trigger +
call site). Resolve that, port `FUN_005a4600` (+ the FUN_005ab5a0/FUN_005a50c0 set_phase tails;
`Pm98Resolver.resolve_tree` already ports the FUN_005aeda0 inner tree), wire it into the driver,
and only THEN can the e2e match score -> the N>=50 parity kill-test (5b/5c) becomes runnable.
`mtest.exe` was checked and RULED OUT as the oracle (it is "Matties dTest", a file-integrity
checksum verifier for mtest.dat, not a match simulator).

---

## STEP-5b CORRECTION (2026-06-22): the STEP-5a "port FUN_005a4600 into Pm98Driver.tick" PLAN IS WRONG

> **!!! ITSELF SUPERSEDED 2026-06-23 (live wine trace) !!!** This whole section's "phase 0 is
> unreachable / FUN_005a4600 has no caller / don't wire it into the driver" conclusion rested on the
> player vtable base `0x639224`, which is OFF BY 4. The live trace
> ([[handoff-pm98-vtable-offset-rootcause-2026-06-23]]) proved the base is `0x639228`, so the +0xc
> ADVANCE dispatcher `FUN_005b8c20` (run every tick, x2) dispatches `[vtable+0xc] = FUN_005a4600` (the
> open-play engine), NOT the no-op `FUN_005a4560`. The "zero static xrefs" in point 3 below is exactly
> what an indirect `call [eax+0xc]` looks like to a `grep 0x5a4600`. So the STEP-5a plan was RIGHT:
> `Pm98Action.engine_tick` IS now wired into `Pm98Driver._advance_team` (the +0xc pass), and
> `test_driver_advance_engine.gd` proves a 0x1d kicker advances phase 2->1 through it. The points below
> are retained only as the record of the off-by-4 dead end; read them through the corrected base.

Spent a full session on the call-graph + phase-field write map (objdump/decompile/PE-data verified, not
inferred). The STEP-5a conclusion ("port FUN_005a4600 + wire into Pm98Driver.tick") rests on a false
premise. The corrected facts:

### 1. The per-tick driver NEVER runs the +0x10 (action-resolve) pass
`FUN_00598740` calls exactly these player-loop dispatchers (verified by listing every `call 0x5b8xxx`
inside it + each dispatcher's vtable offset): `FUN_005b8bf0` x2 = vtable **+8** (DECIDE), `FUN_005b8c20`
x2 = vtable **+0xc** (ADVANCE). Plus the 4 sub-entity +8/+0xc slots. There is **no +0x10 player-loop
dispatcher** anywhere in 0x5b8xxx, and the driver has no `call [reg+0x10]`. So wiring FUN_005a4600 into
`Pm98Driver.tick` would be putting it where the binary never puts it.

### 2. Phase 0 is UNREACHABLE through any live sim path
Every write to the match phase field `+0x448` in the whole binary (grep `mov [reg+0x448]`):
- sim range: `0x5938fd/0x593bee/0x593de5` (all inside `FUN_00593b70`, the restart handler) +
  `0x5942f0` (`FUN_005942e0` = `set_phase`). The 0x46/0x49/0x4c writes are a different struct
  (`FUN_00491960`'s `+0x448` is a `operator_delete`'d pointer-array, NOT the match).
- `set_phase` arg per call site (verified the pushed immediate): `0x59711e` dispatcher -> **8**;
  `0x599631` driver -> **6**; `0x5a4874`/`0x5a5259` -> **1**; `0x5ac0a5` (in `FUN_005ab5a0`) -> **0**.
- `FUN_00593b70` sets `+0x448 = RESTART_PHASE_TABLE[+0x1a38]` ONLY when `+0x1a38 != 0`.
  Table @0x664070 (correct .data delta: file = VA-0x401200 is .rdata; .data VA 0x652000 -> file
  0x250600, so 0x664070 -> file 0x262670) = **[0,2,3,6,4,5,2,7]**. Index 0 -> phase 0, but the
  `+0x1a38 != 0` guard excludes index 0. So the restart handler can produce phases {2,3,6,4,5,7}, never 0.
- The driver dispatches `FUN_005966d0(code)` with code in {1..7} only; the dispatcher tail sets
  `+0x1a38 = code` (0x597118) then `set_phase(8)` (0x59711e). Never 0.

So in live code the phase is only ever **{1,2,3,4,5,6,7,8}**. The ONLY `set_phase(0)` is `0x5ac0a5`
inside `FUN_005ab5a0`, and `FUN_005ab5a0`'s only callers (0x5acc0e/0x5ae41e/0x5ae8f8/0x5aed7e) are all
inside the `FUN_005a4600` switch subtree. The resolver `FUN_005aeda0` (already ported as
`Pm98Resolver`) is called ONLY from 0x5a47f9, also inside `FUN_005a4600`. **=> phase 0 (the open-play
classification at `FUN_00598740` L209 `if +0x448 != 0 goto default`) is reachable ONLY if FUN_005a4600
runs on players.**

### 3. FUN_005a4600 has ZERO call/jmp xrefs in the entire binary
`grep -c 0x5a4600` over the full objdump = **0**. It appears only as the player vtable+0x10 data slot
(file ref @0x639234). Player vtable @0x639224 = `[+00 5ed810][+04 5a5460 SPRITE][+08 5a3400 DECIDE]
[+0c 5a4560 ADVANCE][+10 5a4600 ACTION-RESOLVE][+14 5ed810][+18 5ed870][+1c 5ed8e0]`. Keeper/ball/ref
vtables do NOT have 5a4600 at +0x10 (ball +0x10 is literally null). All 19 `call [reg+0x10]` sites in
the binary were checked: the 3 that load `[reg+0x438]` (0x467ab9/0x4680d2/0x4688ec) dispatch on a
SCREEN object (`FUN_00467a50`/`FUN_004680b0`/`FUN_00468860` are CString/`SetWindowTextA`/sprintf UI
widget handlers; that object's +0x14 is a "%u %u %u" getter, whereas player+0x14 is the dtor -> NOT a
player). The rest dispatch on app/library singletons. **No statically-provable call site dispatches
FUN_005a4600 on a player.**

### 4. The kickoff state, and why phase stays 2 (matches the port exactly)
`kickoff_init` (FUN_00593600) sets phase=2 (+0x448/+0x44c), `+0x1a38=0`, `+0x19a0=0`, `+0x1a1e=1`.
Tick 1: the `+0x1a1e` gate fires -> `FUN_00593b70`; with `+0x1a38==0` it SKIPS the phase-set block, does
the state-reset, leaves phase=2, does NOT re-arm `+0x1a1e`. Tick 2+: normal driver, phase 2 -> L209
skips classification -> movement core only -> phase stays 2 forever. The port reproduces the binary's
literal control flow; the binary, driven this way, would ALSO stay at phase 2.

### 5. What actually drives a watched match (the real architecture)
`FUN_005983f0` (match step, tail-jmp'd via thunk 0x5910a0 from the career match loop `FUN_0044ee70`
@0x44f394) branches on the play-state `PS = *(match+0x468)+0xfa0` (= career/session play-state, the
career-layer field; `match+0x468` is a pointer to the session, NOT the team header which is +0x46c):
- `FUN_005943b0/d0/f0` = `PS==0 / PS==4 / PS==2`. Set-piece branch iff `PS in {0,4}` (or penalty /
  +0x1a20 latch); else the normal branch (one `FUN_00598740` tick).
- `FUN_0044ee70` L128 `if (PS != 5)` = WATCHABLE positional match (the FUN_005910a0 loop); `PS == 5` =
  the self-contained STATISTICAL match (the `rand()` attack/defense loops at L357-787, FUN_0044ece0 /
  FUN_004510b0). The watched path does NOT pre-compute goals statistically.
- The set-piece branch spins `FUN_00593ab0`, whose controller `FUN_005bce40` is the **Win32 message
  pump** (PeekMessageA/GetCursorPos/AfxGetThread) -> returns -1 headless -> the set-piece branch is a
  no-op headless.

So a watched match must detect goals live (phase 0) yet phase 0 needs FUN_005a4600, which has no static
caller. The only consistent resolution: **FUN_005a4600 is dispatched dynamically on the active player
(`match+0x438` = select_active result) from the match-VIEW screen's per-frame handler / window-proc,
reached through the message-pump indirection that static xref cannot follow** (OR it is vestigial and a
mechanism still unfound injects phase 0). EITHER WAY the missing logic lives in the match-screen
controller layer, not in `FUN_00598740`.

### NEXT (decisive, supersedes "port FUN_005a4600 into the driver")
1. **DYNAMIC trace under wine** (wine-9.0 present): breakpoint/trace `0x5a4600`, `0x5ac0a5` (set_phase 0),
   `0x5942e0` (set_phase), `0x593b70` during a real WATCHED match. Settles: is FUN_005a4600 ever called?
   what sets phase 0? what is `match+0x438` when +0x10 fires? Needs a save-game parked at a match (or
   menu-drive headless). This is the gate; do NOT port FUN_005a4600 blind first.
2. If confirmed live: port FUN_005a4600 (2632 B) + FUN_005a50c0 (872 B, the action-frame stepper that
   sets phase 1) + the switch-case callees, and run it as a **separate per-active-player pass each frame
   on `match+0x438`** (NOT inside Pm98Driver.tick). `Pm98Resolver` already ports the FUN_005aeda0 inner
   tree (case 8/9).
3. SCOPE QUESTION to raise with Mats: the STATISTICAL engine (FUN_0044ee70 PS==5 rand loops) is
   self-contained and far cheaper to port + parity-test than the interactive positional engine. Decide
   whether the playable port needs the positional match headless at all, or whether statistical sim +
   a thinner positional animation is the better target.

## FUN_005a4600 -- the per-player OPEN-PLAY ENGINE (vtable +0xc, run x2/tick by FUN_005b8c20)
Decompile: `docs/re/move/fn_005a4600_FUN_005a4600.c` (generated 2026-06-23, 2632 B). `this`=player
(+0x18c = match, +0x190 = ball, +0x184 = a roster/team struct, +400/0x190 = ball ptr). This is the
function the headless port must run as its +0xc pass. Structure:

1. **Prologue** `FUN_00606220()` (stack-cookie), set player+0x2d7=0, compute player+0x2d8 side-flag
   (player+4 x vs +0x3a4, via FUN_005b0b40), then a **16-tick stamina/fitness decay** on
   player+0x68/0x70/0x74/0x78 (regen = 72000 / match+0x19ac). Then `FUN_005a50c0()` (872 B) =
   **set_phase / state-update subtree -- this is what advances phase 2 -> 0**. PORT THIS.
2. **Action-code switch on `player+0x40`** (the player's current action). One handler per code:
   | code(s)      | handler          | size  | note |
   |--------------|------------------|-------|------|
   | 4, 0x25      | FUN_005acc40     | 975B  | action handler (unported) |
   | 5, 0x24      | FUN_005ad010     | 2391B | action handler (unported) |
   | 6, 7         | *inline*         | --    | held-action timer +0x48 (FUN_005ec250 RNG) |
   | **8, 9**     | **FUN_005aeda0** | 4737B | **the shot/save/goal RESOLVER -- ALREADY ported in Pm98Resolver** |
   | 0x13         | *inline*         | --    | pick nearest teammate (angle-weighted), set pass target +0xa0..0xa8, FUN_005ac1a0 |
   | 0x14, 0x16   | FUN_005ae4c0     | 1103B | action handler (unported) |
   | 0x15         | FUN_005ae910     | 1157B | action handler (unported) |
   | 0x19, 0x1a   | FUN_005adfc0     | 1131B | action handler (unported) |
   | 0x1c         | *inline*+FUN_005a5430 | 34B | (trivial) |
   | 0x1f, 0x21   | *inline*         | --    | reset match+globals |
   | 0x36         | FUN_005ad970     | 737B  | action handler (unported) |
   | 0x37         | FUN_005adc60     | 854B  | action handler (unported) |
3. **Movement tail** (gated by human-control checks FUN_005943b0 / player+0x5c):
   - FUN_005a8680 (820B)  -- idle/hold-position branch
   - FUN_005a65a0(flag) (3193B) -- move-to-target
   - FUN_005a9490 (4062B) -- run state / leg animation
   - FUN_005a7260 (5114B) -- **main locomotion / pathing** (the big one)
   - FUN_005a8f20(facing) (1378B) -- turn / facing update

**PORT SCOPE (counted 2026-06-23):** FUN_005a4600 + FUN_005a50c0 + 7 action handlers (~8.3 KB) +
5 movement fns (~14.6 KB) ~= **26 KB of new decompiled C, plus their own one-more-level callees**
(FUN_005a7260/FUN_005a9490 each fan out further). FUN_005aeda0 (resolver) is the only large piece
already ported. The resolver only fires when a player reaches action-code 8/9, which requires the
movement subtree to drive players to shooting positions -- so there is **no "score-only" shortcut**:
the engine scores only once decide+move+action are all faithful. This is a multi-session port.
