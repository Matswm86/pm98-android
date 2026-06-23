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

## Stats accumulator (PORTED + oracle-validated)

### `FUN_00450510` — per-segment player-stats accumulator (`@0x450510`, 2052 B)

`__thiscall(this=match, dur, p3, p4)`. Call sites are `(0x2d,0,0)` (a 45-min half)
and `(0xf,0,0)` (a 15-min ET segment). Does NOT change the scoreline, but it consumes
a **heavily data-dependent** number of `rand()` draws between the two halves, so it
MUST be ported in-order or H2's scorer stream desyncs. Ported to `Pm98StatMatch._stats`.
Draw budget per call:

1. **Possession** (2 draws): `M+0x64`/`M+0x804` += `(rand()*(dur/8))>>15 + dur/40`.
2. **Accumulation loop** (N draws): alternate side, advance player; each *selected*
   visit rolls `rand()%200` vs the strength byte (`+0xbf`, **halved when role `+0xcc`==0**)
   and bumps that player's counter on a hit. Stops once the running counter total
   reaches `dur`. **Strength bytes must be nonzero or this never terminates.**
3. **Per-player stat draws** (4 per selected player, +2 for a non-GK role-2/3 player):
   key-pass `+0x104` (2 draws, role 2/3 non-GK only), passes `+0x108` + tackles `+0x10c`
   (2), dribble `+0x110` (1), rating `+0x114` (1). The GK (player 0) uses `*2` scalings
   and its own pass seed; outfielders use `*5`.
4. **Event re-roll** (block C): for each player, while a local counter `< +0xfc`
   (= `FUN_00450d20` count of that shirt's goal events) roll `+= rand()%3`. So this
   couples to the H1 goals already in the queue — a scorer drives extra draws here.
5. **Convergence loop** (block D, ≤1000 iters): role-2/3 players draw **1** (`+= rand()%2`),
   role-1 players draw 1 coin **+1 if even**; converges immediately for an all-role-0 XI.

`FUN_00450d20` (`@0x450d20`, 55 B) counts events with `type != 4`, matching shirt
(record `+0xe`), and `p4 == 0`. No `rand()`. Ported to `_count_events`.

**Validation.** `tools/re/run_statacc_oracle.sh` drives the real `FUN_00450510` through
the emulator (injected rand thunk, `FUN_00450d20` runs for real against a pre-filled
event vector) and banks the draw count + final LCG state + sampled stat fields for 4
fixtures (clean / +events / +roles+markers / ET-duration). `app/tests/test_statacc_oracle.gd`
asserts `_stats` reproduces all of them (44 checks green).

## Orchestration (PORTED + oracle-validated, LEAGUE)

### `FUN_0044ee70` PS==5 (lines 357-792) — instant-result driver → `Pm98StatMatch.simulate`

For a **LEAGUE** fixture (extra-time flag `M+0x44`==0 AND penalties flag `M+0x48`==0)
the engine runs **H1 then H2**, each:

* **Buildup markers.** One shot pass (`FUN_0044ec00`, 1/16 four-coin gate, sets shot
  marker `+0xdc`) then two assist passes (`FUN_0044ea40`, 1/2 one-coin gate, sets
  `+0xd4/+0xd8`). Each picks `side = rand()&1`, `idx = rand()%11`; for `idx==0` it skips
  unless the team shape byte (`+0xbb`) beats `rand()%100`; else places a marker at minute
  `rand()%span + base`. Markers feed the resolver's availability check. (Both also fire
  a UI vtable call — a no-op headless; in the emulator a fake `DAT_0066b1e0` vtable +
  `DAT_0066c150=0` keep it from faulting.)
* **Chance-count loops.** Average each XI's strength (`+0xbf`); per side
  `chances = rand()%8 - opp_avg - 1 + own_avg` (if `<0`, `+= rand()%own_avg`), clamped to
  `3 - rand()%3`; each chance calls the resolver `FUN_0044ece0(side, seg, rand()%45 + 1)`.
* **Stats accumulator** `FUN_00450510(0x2d,0,0)`, then the H1→H2 transition `FUN_0044d0d0`
  (no `rand()`, no event). After H2: `FUN_00450510(0x2d,0,0)` then the full-time gate
  `FUN_00450e60` (no `rand()`; its result is unused when ET/pen are off).

Buildup minute base/span: H1 `(0x2d,1)`, H2 `(0x2d,0x2e)`. The resolver's per-period
minute offset (`FUN_004510b0`: +0/+0x2d/+0x5a/+0x69 by segment) means a seg-1 goal at
within-period minute 25 is recorded at minute 70.

**Validation (end-to-end).** `tools/re/run_statmatch_oracle.sh` enters the real
`FUN_0044ee70` at its entry, skips the positional/UI block by zeroing `DAT_00652a10`,
stubs the UI helpers (`FUN_0044d5f0`, the `d0d0/d190/d250/d310/d520` transitions, the
gate, `FUN_005bbf10`), and runs the full statistical engine for 4 league fixtures,
banking the complete event queue + final score + draw count + final LCG state.
`app/tests/test_statmatch_oracle.gd` asserts `simulate` reproduces every one bit-exact
(36 checks: scores 3-2, 4-2, 0-1, 1-3; draw counts 856/836/789/891).

## NEXT

1. **Extra time + penalties** (cup only — `M+0x44`/`M+0x48` set). The ET segments
   (seg 2/3) use a **different** chance-count formula `(own_avg-opp_avg)/6 - 1 + rand()%3`
   with a probabilistic tail loop (`while count < chances/2 || rand()%4==0`), the real
   `FUN_00450e60` gate, transitions `FUN_0044d190/d250/d310`, and the penalty-shootout
   event emitter (lines 742-787). Add a cup fixture (flags set) to the oracle, port,
   validate. `Pm98StatMatch.simulate` currently stops after H2.
2. **Replace `app/scripts/MatchEngine.gd`** (the abstracted per-shot model) with
   `Pm98StatMatch` as the faithful instant-result engine wired into the career/league loop.
3. The `PS != 5` positional engine stays parked (see `MATCH_TICK_DRIVER_MAP.md`).
