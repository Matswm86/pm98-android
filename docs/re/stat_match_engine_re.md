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
gate `FUN_00450e60`, the penalty finalize `FUN_00606220`, `FUN_005bbf10`), and runs the
full statistical engine, banking the complete event queue + final score + draw count +
final LCG state. `app/tests/test_statmatch_oracle.gd` asserts `simulate` reproduces every
one bit-exact (**105 checks** over **4 league + 4 cup** fixtures; league scores 3-2/4-2/
0-1/1-3, draws 856/836/789/891).

## Extra time + penalties (PORTED + oracle-validated, CUP)

### `FUN_0044ee70` ET/penalty tail (lines 549-787)

A **cup** tie still level at full time plays two 15-min extra-time segments then a
penalty shootout. Each ET/penalty stage is gated on a static flag (ET = `M+0x44`, pen =
`M+0x48`) AND the no-rand full-time gate `FUN_00450e60`, which returns 0 only while the
aggregate is level (1 = side 0 ahead, 2 = side 1). Because that gate consumes **no
rand**, the oracle stubs it to 0 (forcing the longest path) and the port takes the
decision as `simulate(mem, rng, run_et, run_pen)`. League = both false.

* **Each ET segment** (seg 2 = ET1 base `0x5b`, seg 3 = ET2 base `0x6a`; span `0xf`) runs
  the same 1-shot + 2-assist buildup, then a **probabilistic tail loop per side**:
  `chances = (own_avg - opp_avg)/6 - 1 + rand()%3` (if `< 0`, `+= ((own_avg/20)*rand())>>15`;
  **no `3-rand()%3` clamp**), then `count=0; while count < chances/2 OR rand()%4==0 {
  resolve(side, seg, rand()%15+1); count++ }`. The `rand()%4` is drawn only once `count`
  reaches `chances/2` (`||` short-circuit). Then `FUN_00450510(0xf,0,0)` ET stats. →
  `_et_half`.
* **Penalty shootout** (lines 743-787 → `_penalties`): `s0=rand()%6`, `s1=rand()%6`, then
  `while s0==s1 { s1+=rand()&1; s0+=rand()&1 }` (each iter draws two coins, s1 then s0).
  Emit one **type-4** event per converted penalty: for each side draw `idx=rand()%11`
  until `sN` **selected** takers have scored (an empty slot redraws, no count). Payload
  `(shirt<<16)|teamId`; type-4 events carry no minute offset and are **excluded from the
  scoreline** (`score()` / `_count_events` skip type 4). The shootout records only the
  outcome.

The cup oracle fixtures (`cup_A..D`) share league seeds/squads but set the flags; draws
climb to 1314/1255/1229/1341 and the queues add type-2/3 ET goals + type-4 penalties,
all bit-exact.

## Full-time / tie-resolution gate (PORTED + oracle-validated)

### `FUN_00450e60` full-time gate (`@0x450e60`, 586 B, NO rand) → `Pm98StatMatch.ft_gate`

Returns a **byte verdict**: `0` = still level (replay / play on), `1` = side 0 through,
`2` = side 1 through. It is **pure score arithmetic** — no `rand()` — so the statmatch
oracle stubs it to 0 (forcing the longest ET+pen path); the port instead computes the
real verdict and `simulate()`'s caller passes it in as `run_et` / `run_pen`.

Inputs on the match struct (all i32; `0xff` = "no carry / single leg" sentinel):

| field   | meaning |
|---------|---------|
| `+0x20` | two-legged flag (carry `+0x34/+0x38` into the aggregate when set with `+0x44`) |
| `+0x24` | decide-by-penalties enabled |
| `+0x28` | aggregate-only (away-goals OFF) branch enable |
| `+0x2c` / `+0x30` | leg carry: side0 / side1 first-leg goals (`A` / `B`) |
| `+0x34` / `+0x38` | alt leg carry (`C` / `D`), used only when `+0x20` **and** `+0x44` set |
| `+0x44` / `+0x48` | extra-time / penalties enabled (`M+0x44` / `M+0x48`) |

It calls four REAL leaf readers over the `+0xf98` event vector (pure, idempotent —
the port computes each once and reuses): `FUN_00450d60`→side0 score, `FUN_00450db0`→side1
score, `FUN_00450e00`→side0 pens, `FUN_00450e30`→side1 pens. A normal goal (`p4==0`)
credits the team in the low short of payload; an own goal (`p4!=0`) credits the OTHER
side, so each score reader passes its own id for normal goals and the other id for own
goals. Decision order: single-match winner → (else) `+0x28` aggregate-only → (else)
away-goals (aggregate, then away goals = side0 carry vs side1 this-match, then pens).

Oracle: `tools/re/run_ftgate_oracle.sh` runs the real bytes on 15 synthetic structs
(single match / no-pens / aggregate / away-goals branches), banking each EAX into
`tools/re/specs/ftgate_oracle.txt`. `app/tests/test_ftgate_oracle.gd` rebuilds the same
structs and asserts `ft_gate` returns the binary's byte (**15/15**).

## Mem-from-clubs bridge (MAPPED — `FUN_0044d5f0`)

The participant records the stat engine reads are filled by `FUN_0044d5f0` (`@0x44d5f0`,
3602 B), which `FUN_0044ee70` calls as its **first action** (line 48, `this=match`).
Caller chain confirmed by xref: `FUN_00448b60` (the career-match runner) constructs the
two `0x7a0` team blocks (`local_fbc`, ctor `FUN_00449400`) then calls `FUN_0044ee70`;
`FUN_0044ee70` calls `FUN_0044d5f0` to populate them from the **fixture global
`DAT_0066afd0`** + each club's loaded squad. Decompile: `docs/re/move/fn_0044d5f0_*.c`.

`FUN_0044d5f0` runs two identical 11-iteration loops (side 0 lines 117-348 at participant
base `match+0x84+i*0xac`; side 1 lines 385-665 at `match+0x7f8 + i*0x2b dwords`). Per slot
`i` (1-indexed via `FUN_0057a2e0(i)` which walks the squad linked list `club+0x24` / next
`+0x100`, matching the lineup-slot byte `player+0x19`):

* slot empty (`FUN_0057a2e0`==0) **or** unavailable (`FUN_005836a0()!=0`, injured/suspended)
  ⇒ all fields zeroed, **`SEL=0`** (not in XI). Otherwise the fields below are filled.

**Stat-engine INPUT fields** (only these are read by `Pm98StatMatch`; port offset = absolute
`side*0x7a0 + i*0xac + off`; binary writes at `iVar11 = match+0x84 + i*0xac`, side 0):

| port field | port off | `FUN_0044d5f0` line | source (in-memory player record) |
|------------|----------|---------------------|----------------------------------|
| `SEL`    | `+0x88` | 175 (`iVar11+0x04`) | u16 shirt @ `player+0x00` |
| `STR`    | `+0xbf` | 226 (`iVar11+0x3b`) | `FUN_005841e0(player)` = `mean(player+0x9c..0x9f)`, then `×3/4` in-form / `÷2` out-of-form (gated on `player+0x19<0xc`, `player+0x1c`, opponent-is-human) |
| `GKSAVE` | `+0xc0` | 231 (`iVar11+0x3c`) | byte `player+0xa0`; **`+10` if slot 0 (GK)**, clamp 99 |
| `PASS`   | `+0xc2` | 242 (`iVar11+0x3e`) | byte `player+0xa2` |
| `POS`    | `+0xc8` | 251 (`iVar11+0x44`) | byte `player+0x18` **`+1`** → `POS_WEIGHT` index |
| `ROLE`   | `+0xcc` | 253 (`iVar11+0x48`) | byte `player+0x1c` → switch 0/1/2/3 (`GK/DEF/MID/ATT`; string LUT `PTR_s_GOALKEEPER_00662d10`) |

**Team-level fields:**

* `TEAMID` side0 `+0x7e8` = `DAT_0066afd0+0x38` (home club id, line 82); side1 `+0xf88` =
  `DAT_0066afd0+0x3a` (away, line 349).
* `SHAPE` side0 `+0xbb` aliases participant-0's `iVar11+0x37` = `player[slot1]+0x9e` (a GK
  attribute byte); side1 `+0x85b` likewise. The buildup loops read it as-is — no separate
  handling; the bridge just fills participant 0.
* `ft_gate` carry/flags `match+0x20..0x48` ← `DAT_0066afd0+0x58/0x5c/0x40/0x48/0x50/0x30/
  0x34..0x37` (lines 64-73). League = sentinels/0; a cup tie sets them from the tie state.
* Pre-loaded events (lines 634-661): if `DAT_0066afd0+0x64` (u16) > 0, prior-leg goals/cards
  are replayed into the queue via `FUN_004510b0`. A league instant-result has 0.

`ROLE` semantics line up with the port: `0`(GK) halves strength in `_stats` and is excluded
from the scorer roulette; `1`(DEF) takes the role-1 convergence path; `2/3`(MID/ATT) are the
watched pair (key-pass / assist draws). `POS = player+0x18 + 1` indexes `POS_WEIGHT[1..18]`.

### Residual before the bridge is runnable

The **only** unresolved link is the in-memory player offsets → the decoded `game_db.json`
attrs (`VE RE AG CA RM RG PA TI EN PO`, order from `tools/extract_squads.py`). The in-memory
record is the **fully-loaded player object** (has form `+0x19`, club id `+0x14`, position-fit
bands via `DAT_00638e34..40`, next-ptr `+0x100`), NOT the raw `EQUIPOS.PKF` blob, so the 10
attrs are NOT a verbatim copy at `+0x9c`. Two ways to close it, either of which avoids a guess:
1. **Oracle `FUN_0044d5f0` + `FUN_005841e0`** against synthetic player records (known bytes at
   `+0x9c..0xa2/+0x18/+0x1c`) — validates the transform end-to-end; the GDScript bridge then
   maps `game_db` attrs → those offsets, the single remaining unknown.
2. **RE the PKF→player-object loader** (the function that writes `player+0x9c..0xa6` from
   EQUIPOS.PKF) to get the offset→attr names directly, **or** one-time dump a known player's
   live record under wine and read the bytes.

`player+0x18` (POS) / `player+0x1c` (ROLE) are already decodable: they are the demarcación /
broad-role bytes mapped in `docs/re/positions_re.md` (`game_db` `pos` / `isGK`).

## NEXT

1. Close the **residual** above (oracle `FUN_0044d5f0`, route 1 preferred — same PCodeEmu
   pattern as `run_statmatch_oracle.sh`), producing the `game_db`-attr → in-memory-offset map.
2. **Then** replace `app/scripts/MatchEngine.gd`: build a `Mem` per club from the lineup
   (SEL=shirt for the 11 selected available; STR/GKSAVE/PASS/POS/ROLE per the table above),
   `simulate(mem, rng)` for H1+H2; for a cup tie set carry/flags and use
   `run_et := ft_gate(mem)==0` after H2, `run_pen := ft_gate(mem)==0` after ET.
3. The `PS != 5` positional engine stays parked (see `MATCH_TICK_DRIVER_MAP.md`).
