# PM98 match engine — reverse-engineering map (Path 2)

Status: **engine located, mapped, RNG reconstructed (verified), scoring path
decoded, faithful per-shot model folded into `app/scripts/MatchEngine.gd`.**
All addresses are virtual
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

## RNG — SOLVED (it IS MSVC `rand()`; prior "absent" claim was wrong)

`FUN_005ec250` @ **0x5ec250** is the PRNG, the standard Microsoft C runtime LCG:

```
state = state*214013 + 2531011        // global state @ 0x6d3184
return (state >> 16) & 0x7FFF          // 15-bit, [0, 32767]
```

The earlier "multiplier 214013/0x343FD absent → not MSVC rand()" conclusion was a
**byte-grep artefact**: the compiler strength-reduced `*214013` into a lea/shl/sub
chain, so `0x343FD` never appears as a literal. Verified against the real bytes at
file-offset 0x1eb650:
```
a1 84 31 6d 00        mov  eax,[0x6d3184]
8d 0c 40              lea  ecx,[eax+eax*2]      ; 3*eax
8d 14 88              lea  edx,[eax+ecx*4]      ; 13*eax
c1 e2 04  03 d0       shl  edx,4 ; add edx,eax  ; 209*eax
c1 e2 08  2b d0       shl  edx,8 ; sub edx,eax  ; 53503*eax
8d 84 90 c3 9e 26 00  lea  eax,[eax+edx*4+0x269ec3] ; (1+4*53503)*eax + inc = 214013*eax + 2531011
a3 84 31 6d 00        mov  [0x6d3184],eax
c1 f8 10  25 ff 7f..  sar  eax,16 ; and eax,0x7fff
c3                    ret
```
`53503*4 + 1 = 214013 = 0x343FD`; increment `0x269ec3 = 2531011` is the lea
displacement (the `0x269EC3 @ 0x5ec268` the prior note dismissed). A GDScript port
of this LCG reproduces the canonical `srand(1)` sequence `41, 18467, 6334, 26500,
19169` exactly.

**Probability idiom:** the sim never uses the raw roll; it scales it, e.g.
`(int)(roll*1000) >> 15  <  threshold` → uniform compare in [0,1000), i.e. a
**per-mil** probability. `(roll*N)>>15` generalises to a uniform integer in [0,N).
`005ec240`/`005ec230` are a save/restore pair that brackets every *commentary*
roll so cosmetic text does not perturb the deterministic match seed.

## Scoring path — DECODED

`FUN_00598740` (per-tick driver, "minute loop") classifies the live ball/play state
with predicates `FUN_0058f100 / 0058ede0 / 0058fbe0 / 0058f140` (shot-on-goal,
goal-scored, corner, throw-in) and calls the **resolution dispatcher**
`FUN_005966d0(outcome)` where `outcome` is a category 1-7:

| outcome | meaning | event(s) enqueued |
|---|---|---|
| 6 | **goal scored** | `8 - (team!=defending)` = **7 (GOAL)** or 8 (own goal) |
| 5 / 7 | foul / penalty conceded | yellow 3, red 4/5, normal 1, offside 0xb, pen 9 |
| 4 | corner | 0xc |
| 1 | phase / kick-off | 0x1c-0x20 |
| 2,3 | restart / buildup | 0 |

The actual goal/no-goal decision is upstream of the dispatcher, in
`FUN_005aeda0` (per-player **shot/tackle/save resolver**, 23 RNG calls — the
heaviest user). Its outcome gates are **linear in player attributes** thresholded
against the per-mil LCG roll. Player object layout used: `+0x384` skill, `+0x40`
position (9 = forward, gets a bonus), `+0x60` engaged-flag, `+0x18c` → match obj.
Representative gates (permil):
- shot proceeds to resolution: `roll < 900` (90%)
- good-facing goal gate: `(skill + (pos==9?20:0))*5 − (engaged?200:0) + 200`
- medium/poor facing: `skill*2` / `skill` / `skill/2` (± forward bonus)
- it writes the outcome class into `match+0x461` bits {0:team,1,2} which the
  dispatcher then reads to pick commentary.

So the engine is a **deterministic positional ball-physics sim** (player/ball
fixed-point coords like 0x134000); a closed-form scoreline formula does NOT exist
to extract. Goals emerge from per-shot Bernoulli resolution over chances the
positional sim creates.

## Folded into the GDScript engine (done)

`app/scripts/MatchEngine.gd` (Phase 2) now uses:
- `Pm98Rng` = the exact MSVC LCG above (bit-verified).
- a **per-shot Bernoulli** scoreline: each side gets N chances (modelled from the
  attack-vs-defence gap, since chance *volume* is an emergent property of the
  positional physics we do not port), each converted by a permil gate linear in
  the strength gap — the *form* of `FUN_005aeda0`'s finishing gate.
- Calibrated to real-football windows: 300-season PL harness ALL PASS
  (goals 2.54, home 45.1%, draw 25.3%, away 29.6%, champ 79.9, bottom 30.3);
  `test_divisions` OK. Honest framing in the file header: form is PM98's, the
  volume model + constants are ours.

## Positional predicates decoded (session 4) — chance volume is emergent physics

Decompiled `FUN_0058ede0 / 0058f100 / 0058fbe0 / 0058f140` (dumps in `docs/re/goal/`).
They are **continuous fixed-point ball-physics** in a pitch coordinate system where
`0x10000` (65536) = one unit; the ball state lives at `obj+4`=x, `+8`=y, `+0xc`=z(height),
with velocity at `+0x20/+0x24/+0x28`. Goal line is `obj->match->+0x1820`; goalmouth
depth `0x4ccc`. Decoded roles:
- `0058ede0` — **goal-area / shot-classification box**. Tests x within `±0x10000` of the
  goal line, `|y| < 0x3a8f5`, `0 <= z < 0x270a3`, then sets height-band bits in the match
  outcome byte `+0x462` against thresholds `0x2ffff / 0x21eb7 / 0x1e666 / 0x6667`
  (over-bar / on-target / saveable height bands).
- `0058fbe0` — **post-and-bar collision**: reflects ball velocity (`+0x24/+0x28` negated)
  at boundaries `0x3deb7 / 0x2828e`. Pure deflection physics.
- `0058f100` — copies the ball's target trajectory vector (`+0x40` → `+0x90/+0x94/+0x98`).
- `0058f140` — **keeper-reach save geometry**: ball trajectory vs keeper (`+0x50`), keeper
  rating via `FUN_005ee080`, save if a distance metric `< 0x3555`; default reach `0xc80000`.

**Verdict (resolves last session's item 1):** chance *volume* is fully emergent from this
continuous 22-player ball physics — there is **no discrete "shots per team" parameter** to
extract. A faithful volume port would mean porting the whole positional engine. The current
calibrated volume model in `MatchEngine.gd` is the correct abstraction; this is left as-is.

### Per-shot finishing gate — exact form (verified in `FUN_005aeda0`)
The resolver's shot gate is `roll = FUN_005ec250(); (roll*1000)>>15 < threshold`, with the
threshold piecewise-linear in a player attribute at `player+0x398`:

    threshold_permil = (ATTR < 0x37 /*55*/) ? (ATTR/3)*9 : (ATTR - 0x19 /*25*/)*9

i.e. a finishing curve **kinked at 55**: ~ATTR x3 permil below 55, (ATTR-25) x9 above
(270 permil at 55, 585 at 90). A second `<600` permil gate then splits the on-target vs
off-target branch (`FUN_004e9a70` / `FUN_004e9ba0`), and `FUN_005a5430(0x17)` enqueues the
shot event (type 0x17). `FUN_005ec240`/`005ec230` bracket the commentary roll to protect the
match seed. This confirms the *form* already folded into `MatchEngine.gd` (linear-in-skill
permil) and records the exact kink for any future curve-shaping pass — NOT applied now, since
the 300-season harness is calibrated and there is no ground-truth PM98 scoreline set to
re-validate a curve change against.

## Open / next (active)
- Live match commentary feed in the app — map generators `58f3c0` (shots 0x17-0x20),
  `5a7260`/`5ab5a0`/`5b41c0` (miss types 0xf/0x10/0x11) + formatter `FUN_00539140`. In progress.
- Finance layer in the app — see `finance_constants.md` (weekly-ledger structure decoded).
