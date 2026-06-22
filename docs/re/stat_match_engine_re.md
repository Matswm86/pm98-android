# PM98 STATISTICAL match engine (RE map)

Premier Manager 98 ships **two** match engines inside the career-match runner
`FUN_0044ee70` (`@0x44ee70`, 5729 bytes). They are selected on the play-state:

```
PS = *(*(match + 0x468) + 0xfa0)        ; match+0x468 = session ptr; PS at session+0xfa0
```

| `PS`        | branch                              | what it is |
|-------------|-------------------------------------|------------|
| `!= 5`      | `FUN_0044ee70` lines 51-333         | **positional / watchable** sim (22-player ball physics, the FUN_00598740 tick driver). Ends `goto LAB_0044f520`. This is the engine blocked on the phase-0 / `FUN_005a4600` dead-code question (see `MATCH_TICK_DRIVER_MAP.md`). |
| `== 5`      | `FUN_0044ee70` lines 357-792        | **statistical / instant-result** sim. Pure `rand()` + integer arithmetic. THIS DOCUMENT. |

Every match the human does **not** watch positionally (all AI-vs-AI league fixtures,
and the human's own "instant result") is produced by the statistical engine. It is
fully self-contained: no message pump, no phase state machine, no display, no
`FUN_005a4600`. The port target is `app/scripts/Pm98StatMatch.gd` (replacing the
ABSTRACTED `app/scripts/MatchEngine.gd` once complete).

## RNG

The statistical engine calls the **msvcrt C-runtime `rand()`** via the import thunk
`call ds:0x6233b0` — a SEPARATE stream from the positional sim's internal LCG
`FUN_005ec250`, but the SAME algorithm (MSVC `rand`):

```
state = state*0x343FD + 0x269EC3            ; *214013 + 2531011
draw  = (state >> 16) & 0x7FFF              ; [0, 32767]
```

The probability idiom throughout is `(rand()*N) >> 15` = a uniform draw in `[0, N)`
(`rand()` is non-negative, so the binary's `(x + (x>>31 & 0x7fff))` sign-bias
correction is a no-op). `Pm98StatMatch.Rng.mod(n)` reproduces this exactly.

## Match-struct layout the statistical engine touches

Two team blocks of `0x7a0` bytes, side 0 at `match+0`, side 1 at `match+0x7a0`. Each
holds **11 participant records, stride `0xac`** (these are the compact per-match
participant blocks, NOT the `0x3bc`-stride positional player objects built by
`FUN_005a2830`). Per participant (offsets from its own base `side*0x7a0 + i*0xac`):

| off    | type  | meaning |
|--------|-------|---------|
| `+0x88`| u16   | **shirt / selected** — 0 ⇒ not in the XI; nonzero ⇒ shirt number (also the event payload's high half) |
| `+0xbf`| u8    | strength/condition byte (possession + stats model, `FUN_00450510`) |
| `+0xc0`| u8    | **keeper save rating** (only participant[0] = the GK is consulted) |
| `+0xc2`| u8    | passing/tackling stat seed (`FUN_00450510`) |
| `+0xc8`| i32   | **position code** 0..18 → `POS_WEIGHT` (scorer roulette) |
| `+0xcc`| i32   | role flag (2/3 = the watched-pair branch in `FUN_00450510`) |
| `+0xd4`,`+0xd8`| i32 | event slots A/B (e.g. assist/booking); both set ⇒ unavailable |
| `+0xdc`| i32   | pending-shot marker (`FUN_0044ec00` sets it); nonzero ⇒ unavailable |
| `+0xe0`,`+0xe4`,`+0xe8`| i32 | event payload weights for the slots above |
| `+0xf0`..`+0x120`| i32 | accumulated match stats (rating, passes, tackles, possession) |

Per team block (offsets from `side*0x7a0 + match`):

| off     | meaning |
|---------|---------|
| `+0x7e8`| u16 team id (event payload's low half) |
| `+0x64` / (team1 `+0x804`) | possession counters (`FUN_00450510`) |

Match-global:

| off      | meaning |
|----------|---------|
| `+0xbb`, `+0x85b`(`+0x7a0+0xbb`) | team "shape/aggression" bytes the kickoff rand-loops read (`(side&1)*0x7a0 + 0xbb`) |
| `+0xf98` | event-vector data pointer (16-byte records) |
| `+0xf9c` | event-vector count |

### Position-weight LUT `DAT_006532ec`

VA `0x6532ec`, file offset `0x2518ec` (.data: VMA `0x652000` → foff `0x250600`).
**19 entries** (index = participant position code `+0xc8`), decoded LE int32:

```
[0, 0, 3, 3, 3, 7, 7, 12, 10, 35, 10, 12, 15, 18, 15, 3, 18, 18, 10]
```

GK slots (0/1) weigh 0; the central-striker slot (9) carries the heaviest weight
(35). Entries ≥19 are unrelated `.data` and are NOT part of the table.

## Scoring path (PORTED + oracle-validated)

### `FUN_0044ece0` — chance / goal resolver  (`@0x44ece0`, 399 B)

`__thiscall(this=ECX=match, arg0=side, arg1=seg, arg2=minute)`. Confirmed from the
prologue: `mov ebx,ecx` (this=match), `mov esi,[esp+0x2c]` = arg0 = side.

1. **Keeper-save gate.** Defender base = `(side==0)*0x7a0 + match`, participant[0].
   If the keeper is in the XI (`+0x88 != 0`) **and** `rand()%130 < keeper_save(+0xc0)`
   → **SAVE**, emit nothing, return. A keeper with `+0x88 == 0` cannot save, so the
   chance always proceeds. (`rand()%130` = `(rand()*0x82) >> 15`.)
2. **Scorer roulette.** Attacking base = `side*0x7a0 + match`. Sum
   `POS_WEIGHT[participant[i].pos]` over all 11 (GK contributes 0). Roll
   `(rand()*total) >> 15`; walk participants **1..10** (the GK, slot 0, is skipped)
   accumulating weight; the first participant whose running sum passes the roll AND
   is **available** wins. Available = fewer than two of `{+0xd4,+0xd8}` set AND
   `+0xdc == 0`. If none picked, re-roll (another `rand()`).
3. **Emit.** `FUN_004510b0(this=match, type=seg, minute, 0, payload)` where
   `payload = (scorerShirt << 16) | teamId`, `teamId = *(u16)(attacking_base+0x7e8)`.

### `FUN_004510b0` — event append  (`@0x4510b0`, 189 B)

Appends a 16-byte record `{type:i32, minute:i32, p4:i32, payload:i32}` to the vector
at `match+0xf98` (grows it via `FUN_005bbf10`). The minute gets a **per-period
offset switched on `type` (= the segment index)**:

```
type 0 (h1):  +0       type 2 (ET1): +0x5a (90)
type 1 (h2):  +0x2d    type 3 (ET2): +0x69 (105)
            (45)
```

So a goal at `(seg=1, minute=20)` is recorded at minute `65`. `Pm98StatMatch.MINUTE_OFFSET`.

### Validation

`tools/re/run_statresolve_oracle.sh` drives the REAL `FUN_0044ece0` through the
Ghidra PCode emulator (`PcodeEmu.java`): an injected MSVC-LCG `rand()` thunk at the
`0x6233b0` IAT slot, `FUN_005bbf10` stubbed so the event lands in a pre-sized buffer,
two synthetic XIs. It banks `tools/re/specs/statresolve_oracle.txt`;
`app/tests/test_statresolve_oracle.gd` asserts `Pm98StatMatch.resolve_chance`
reproduces the banked `{count, type, minute, payload}` bit-exact across 8 fixtures
(goals in all 4 segments, varied scorers, keeper save, low-keeper goal, side-1 attack,
GK-out chance). **All 8 fixtures emulator-exact** (29 checks green).

Two `PcodeEmu.java` gotchas cost real time and are pinned in the oracle header:
`mem`/`arg` values are parsed as **hex** (decimal 11 silently becomes `0x11`=17,
indexing past the 19-entry LUT into garbage), and only **one directive per line** is
read. `FUN_005bbf10` is **cdecl** (`ret`), so its stub must pop 0 arg bytes — popping
8 corrupts the return chain (PC lands on a stack arg).

## Orchestration (NOT yet ported — NEXT)

`FUN_0044ee70` lines 357-792 drive the resolver. Structure per period (kickoff, two
half-segments each, halftime, two more, extra time):

* **Chance-count rand loops.** For each side, average the selected XI's strength byte
  (`+0xbf`), then `chances = (rand()%8 - opp_strength) - 1 + own_strength`, clamped by
  `3 - rand()%3`; each chance calls `FUN_0044ece0(side, seg, rand()%45 + base_minute)`.
  Build-up events come from `FUN_0044ec00` (shot marker `+0xdc`) and `FUN_0044ea40`
  (assist slots `+0xd4/+0xd8`); both also fire a UI vtable call that is a no-op headless.
* **Segment stats accumulator** `FUN_00450510` (`@0x450510`, 2052 B) — per-participant
  possession, passes (`+0x108`), tackles (`+0x10c`), rating (`+0x114`); consumes many
  `rand()` draws (so it MUST be ported in-order to keep the stream aligned with the
  resolver) but does NOT change the scoreline.
* **Half/period transitions** `FUN_0044d0d0` / `d190` / `d250` / `d310` / `d520`;
  abandonment/extra-time gate `FUN_00450e60`.

NEXT session: port the `FUN_0044ee70` PS==5 skeleton (chance-count loops + segment
ordering) on top of the validated resolver, oracle the whole-match event queue +
final score end-to-end, then port `FUN_00450510` for player match ratings. The
`PS != 5` positional engine remains parked (see `MATCH_TICK_DRIVER_MAP.md`).
