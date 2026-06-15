# PM98 match engine — reverse-engineering map (Path 2)

Status: **engine located and architecturally mapped**; per-event probability
formulas + RNG not yet reconstructed (next session). All addresses are virtual
addresses in `extracted/Premier Manager 98/MANAGER.EXE`, derived from the Ghidra
12.1.2 analysis at `~/ghidra-projects/pm98` (decompiled C dumps under
`docs/re/{decompiled,sim,flow}/`). Tooling: `tools/re/*.py` + `tools/re/ghidra_scripts/*.java`.

## Headline finding (corrects the placeholder engine's assumptions)

The PM98 **management match result is an event-based, minute-by-minute
simulation** — NOT a single scoreline draw, and NOT "LZ-packed math in DAT.PKF"
(that earlier belief is wrong; see `app/scripts/MatchEngine.gd` header, now
corrected). The sim generates discrete match events (goals, cards, penalties,
corners, shots, injuries) onto a per-match event queue, which a separate display
loop dequeues with commentary. The 3D highlights are Actua Soccer 2 (separate);
this is the 2D management sim that produces the scoreline.

## The Match object + event queue (data model, VERIFIED)

The big "Match" simulation object holds an **event queue**:
- `match + 0x1a24` : pointer to event array
- `match + 0x1a28` : event count (int)
- `match + 0x1a2c`, `+ 0x1a30` : queue head/cursor + a delay counter
- each event = **16 bytes**: `[u32 type, u32 p1, u32 p2, u32 delay/countdown]`

Only 5 functions touch `+0x1a28` (`tools/re/ghidra_scripts/FindFieldUsers.java 0x1a28`):
`0x591180`, `0x591ba0`, `0x5923f0` (match setup — string/name heavy), `0x594470`
(enqueue), `0x594570` (dequeue/display).

## Event-type enum (VERIFIED from the commentary switch @ 0x539140)

`FUN_00539140(this, eventType, p1, p2)` is the commentary formatter — a
`switch(eventType)` that picks the message string. Decoded codes:

| type | event | commentary string (VA) |
|---|---|---|
| 3 | Yellow card | `Yellow card: %s (%s)` (0x65cf38) |
| 4 | Sent off (2nd yellow) | `%s (%s) sent off` (0x65cf24) |
| 5 | Sent off (straight red) | `%s (%s) sent off` (0x65cf24) |
| **7** | **GOAL** | `Goal by %s (%s)` (0x65cf00) |
| 8 | Own goal | `Goal by %s (%s) (o.g.)` (0x65cee8) |
| 9 | Penalty conceded | `Penalty conceded by %s (%s)` (0x65cecc) |
| 10 (0xa) | Penalty taken | `Penalty taken by %s` (0x65ceb8) |
| 0xb | Offside | `%s (%s) offside` (0x65cea8) |
| 0xc | Corner (to) | `Corner to %s` (0x65ce98) |
| 0xd | Corner (taken) | `Corner taken by %s` (0x65ce84) |
| 0x10–0x17 | shots / misses | e.g. `Shot was way off target` (0x65cd9c) |

Phase strings (kick off / half time / full time / extra time) at 0x65cc54–0x65ccf0;
`KICK OFF` helper = `FUN_005387d0`.

## Call chain (VERIFIED)

```
event generators (9 fns) --enqueue--> FUN_00594470 --> match.eventQueue (+0x1a24)
                                                              |
match loop (FUN_005983f0 / 0x598690 / 0x598740) --dequeue--> FUN_00594570
                                                              |
                                       FUN_004511d0 (29B thunk) --> FUN_00539140 (commentary)
```

**The 9 event-generator functions** (callers of the enqueue `0x594470`) — these
hold the per-event PROBABILITY logic to extract next:
`0x58e2c0, 0x58f3c0, 0x5909f0, 0x5966d0, 0x5a50c0, 0x5a7260, 0x5ab5a0, 0x5aeda0, 0x5b41c0`.
The whole match-event subsystem spans roughly **.text 0x58e000–0x5b4000**.

## Match-RESULT screen (separate from the sim — VERIFIED, fully decompiled)

The post-match result screen is a distinct UI class (ctor `0x469960`, dtor
`0x469f60`, display methods `0x46a110` and `0x470b70`). It READS the final
result struct; it does not compute it. Result data model:
- screen `+0x400` / `+0x404` (alt screen `+0x3f8` / `+0x3fc`) : home / away result-struct pointers
- screen `+0x3f4` (alt `+0x3fc`/flags) : leg/replay flag (1st leg vs MATCH RESULT vs REPLAY)
- result struct `+0x38` (u16) / `+0x3a` (u16) : the two goal counts (leg1 / leg2 or normal / ET)
- result struct `+0x3c` (u8) / `+0x3d` (u8) : penalty-shootout scores
- number→sprite via `FUN_00579390`/`FUN_00579730`; digit blit `FUN_005d5220`.
The original "MATCH RESULT" anchor (string 0x653e48 pushed at 0x46a338) lives in
the display method `0x46a110`, reached only via vtable `0x627f9c` (virtual method,
no direct caller — why the call-xref heuristic first mislocated it).

## RNG — still open
Not the MSVC CRT `rand()` (LCG multiplier 214013/0x343FD is absent from the whole
image). The lone `0x269EC3` at 0x5ec268 is in a string/resource helper, not a PRNG.
Custom PRNG location is the next-session target (search the 9 generators for the
common arithmetic-only seed-mutating callee).

## Next session (precise entry points)
1. Decompile the GOAL generator: of the 9 generators, find the one that enqueues
   `type=7`; read its probability gate (team-strength + attribute inputs + RNG roll).
2. Identify the RNG by its callers inside the generators.
3. Map the match loop `0x5983f0/0x598690/0x598740` (minute progression, possession).
4. Extract the scoreline distribution and fold a faithful model into `MatchEngine.gd`.
