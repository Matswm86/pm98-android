# SESSION + LINEUP provenance — the real match INPUT (closes the M3 "matchctx+0x1a5c" gap)

**2026-07-06.** Resolves `PLAN_byte_exact_match_engine.md` M3's blocking GAP ("matchctx+0x1a5c
provenance") and recovers the FULL career→match input chain: which bytes of which object feed
`Pm98Match._build_player`'s record and `kickoff_init`'s session. Every claim below is
disasm/decompile-verified against `extracted/Premier Manager 98/MANAGER.EXE` (objdump of the raw
PE + Ghidra `DecompileAt`; decompiles in `docs/re/move/fn_0044d5f0_*.c`, `docs/re/session/`,
`docs/re/clubtactics/`). Nothing inferred.

## 1. The chain (all links disasm-proven)

```
career match runner FUN_00448b60
  └─ session object (= the port's `session` Dict; play-state at +0xfa0):
     two 0x7a0 LINEUP blocks ctor'd by FUN_00449400 at session+0x58 (team 0)
     and session+0x7f8 (team 1)                                [0x4493a6-0x44943d: stack
                                                                pair, dtor 0x605da0 x2 stride 0x7a0]
  └─ FUN_0044ee70 (career match loop) calls FUN_0044d5f0(session) FIRST → fills both
     lineups from the FIXTURE global DAT_0066afd0 + each club's loaded .DBC object
  └─ match start @0x44f276: FUN_00590fc0(session)              [sole caller]
       └─ new(0x5fb8) + ctor FUN_00591180 (= build_match)
       └─ FUN_005923f0(matchctx, session)                      [sole caller @0x591053]
            ├─ stores session at matchctx+0x468                [decompile L184]
            ├─ FUN_005b63e0(team_hdr=mc+0x46c+ti*0x320, ti,
            │              session+0x58+ti*0x7a0, mc) x2       [disasm 0x5934d5-0x5934fc:
            │   └─ stores the lineup ptr at team+0x9c           mov eax,[edi+0x468];
            │      (= the port's team[0x9c] injection point)    lea ecx,[esi+eax+0x58]]
            └─ tail: FUN_00593600 = kickoff_init → FUN_005b6ba0 x2 builds the 22 players
               from team+0x9c (already ported)
```

**So the port's two injected models are the SAME binary object at two offsets:**
`session` == the career/session object, and `team[0x9c]` == `session + 0x58 + ti*0x7a0`.

## 2. matchctx+0x1a5c RESOLVED — a PALETTE table, display-only (GAP demoted)

`FUN_005923f0` (the match asset loader) allocates it: `+0x1a60=7; FUN_005bbf10;
+0x1a58=0x7ff; +0x1a5c = align256(+0x1a54 + 0xff)` (decompile L252-261) — a 256-aligned view
of a 2KB buffer. Five 0x100-byte blocks: base+0x000/+0x200 (team 0/1), +0x400 (referee),
+0x500/+0x600 (keeper 1/2) — zero-filled at init, then `FUN_005b63e0` fills per team:
0x30 kit bytes at `[+0x1a5c]+ti*0x200+0x9..0x38` (from team_hdr+0x296.., decompile L175-182)
and a 0x100-byte keeper palette at `+ti*0x200+0x100` loaded from `DatSim\paletas\palpor%d`
(L206-214; %d drawn from the RNG with team-kit collision re-rolls L183-191 — the ONLY seed
draws in the fill). Consumers: player/keeper/referee `+0x2dc` block pointers (jug RENDERING
palettes). **Nothing outcome-relevant reads it — the headless engine can keep `m[0x1a5c]=0`.**

The "81-dword (0x51) records" (`this+0x3b0[DAT_006d31c0] → this+0x40` per frame,
`APP_VS_SPEC_AUDIT` §the-3-siblings) are the per-actor STATE bank used for highlight
save/restore (`Pm98Movement.gd` L2824 "81-dword restore"), NOT squad input. The plan's M3
wording conflated them with the palette table; both are now correctly named.

## 3. The LINEUP block (0x7a0) — layout + who writes what

Ctor `FUN_00449400`: header dwords +0x0..+0x28 zeroed; 11 slots at **+0x2c, stride 0xac**
(per-slot ctor 0x449460: positions default 0x90000000/0x70000000 sentinels); +0x790 (u16
team id) / +0x794 / +0x798 / +0x79c zeroed. +0x794/+0x79c = strdup'd club-name /
tactic-name strings (`FUN_0044bc60`/`FUN_0044bd10`).

Filler `FUN_0044d5f0(this=session)` — decompile `docs/re/move/fn_0044d5f0_FUN_0044d5f0.c`.
Side 0 loop L117-348 (slot base `session+0x84+i*0xac`), side 1 L385-668 (`session+0x7f8+0x2c+i*0xac`)
— **identical field set, away club, same venue pitch dims, NO coordinate mirroring at build
time**. Per slot i (0-indexed; squad node looked up by `FUN_0057a2e0(club, i+1)` = walk
`club+0x24` list, next `+0x100`, match XI-slot byte `player+0x19`):

- Slot EMPTY (no node with `+0x19 == i+1`) **or UNAVAILABLE** (`FUN_005836a0`: byte
  `player+0x68` (injury) or `player+0xb6 + DAT_0066b1dc` (per-competition suspension row)):
  every field below = 0, except rec+0x28 = −1. rec+0x44 = 0 → not built by FUN_005b6ba0.

**The record (= slot base; the port's `rec` Dict) — field map** (`rec+off ← source`):

| rec off | port read | source (binary) |
|---|---|---|
| +0x04 u16 | `p[0x2c0]` shirt/id | `player+0x0` = the .DBC u16 player id |
| +0x08/+0x0c | `p[0x1f8/0x1fc]` start pos A | club tactic slot block **[4],[5] = mk1 x,y**, grid→pitch (§4) |
| +0x10/+0x14 | `p[0x204/0x208]` start pos B | block **[6],[7] = mk2 x,y**, grid→pitch |
| +0x18..+0x24 | `p[0x228..0x234]` roam box | min/max of transformed **[0]±[2], [1]±[3]** (x,y,dx,dy) — the previously "un-decoded" slot fields [0..3] |
| +0x28 | `p[0x2cc]` marking idx | `club+0x230+i*4 − 1` (ctor-zeroed career/UI table → default −1 = no man-marking; feeds team `+0x13c` lookup in Pm98Movement L2487-2517) |
| +0x2c | `p[0x370]` (=−1) | byte `player+0x16` (.DBC "u8 x3" run byte 2 — semantics still open) |
| +0x30 | `p[0x36c]` (=−1) | byte `player+0x17` (.DBC "u8 x3" run byte 3 — semantics still open) |
| +0x34 | `p[0x378]` | byte `player+0xa8` — the fitness-cap companion (99 at season init, `morale_re.md`) |
| +0x35..+0x38 | `p[0x37c]/p[0x380]/…` | `FUN_005841e0` outputs 1-4 = raw **VE/RE/AG/CA** (`+0x9c..+0x9f`) |
| +0x39 | (rec[0x39]) | byte `player+0xa7` = **FITNESS** (40..99 runtime, `morale_re.md`) |
| +0x3a | | constant **99** |
| +0x3b | | `FUN_005841e0` output 5 = **STR** = `(VE+RE+AG+CA)>>2`, position-fit-gated (§5) |
| +0x3c | | `player+0xa0` = **PO**; `+10` if i==0 (GK slot), clamp 99 |
| +0x3d | | `player+0xa1` = **EN**; `+10` clamp 99 if role byte `player+0x1c`==1 (DEF) |
| +0x3e | | `player+0xa2` = **PA** |
| +0x3f | | `player+0xa3` = **RM** |
| +0x40 | | `player+0xa4` = **RG** |
| +0x41 | | `player+0xa5` = **TI**; `−10` if league club (`club+0x5c != 0xffff`) and TI > 30 |
| +0x42 | `p[0x2d0]` clamp 1..60 | byte `player+0xf8` = the .DBC u8 right after the player id (semantics open; engine clamps 1..0x3c) |
| +0x44 | `p[0x2c8]` + present flag | `player+0x18 + 1` = **posFine** (loader copies `+0x18 ← +0x1d` = posFine−1, fn_005820f0 L64; so 1..18, never 0 when present — the presence flag `FUN_005b6ba0` tests) |
| +0x48 | | broad role switch on `player+0x1c`: 0/1/2/3 = GK/DEF/MID/ATT |
| +0x50..+0x64 | | prior-leg CARDS: scan fixture `+0x94` vector (stride 0xc, id at +8): type==1 → first/second yellow flags +0x50/+0x54 + minute +0x5c/+0x60; else red flag +0x58 + minute +0x64 |
| +0x68..+0xa8 | `p[0x2da]` reads +0x98 | prior-leg EVENT entry: fixture `+0x9c` vector (stride 0x48, count +0xa0, id u16 at entry+0x44) copied verbatim (0x11 dwords); zero for a league match |

`.DBC` attr scatter confirmed at source (`FUN_005820f0`, param typed `ushort*`): the 10
stream attrs land at `+0x9c..+0xa5` in order VE RE AG CA PO EN PA RM RG TI **with a full
mirror row at +0xaa..+0xb3** — exactly `stat_match_engine_re.md`'s table (its FUN_00583bd0
citation is the SAVE-file deserializer; both paths agree). `+0xa6` = MORALE base, `+0xa7` =
FITNESS, `+0xa8` = cap byte, `+0xb6/+0xc4` = the two 0xe-byte suspension rows zeroed by the
node ctor `FUN_00581c80` (which also defaults `+0xa7`=99, the 6 preferred-position bytes
`+0x1d..+0x22`=0x63, `+0x9a` u16 = 1000).

## 4. Formation → pitch transform (start positions + roam box)

Source block = `club + 0x60 + i*0x20` (8 dwords, the club's OWN tactic slot —
`club_tactics_re.md`; raw 318×198 design space; exported in `app/data/club_tactics.json`
`slots[i].raw`). Transform = `FUN_0058c300(block, 0x13e, 0xc6, pitchW, pitchH)`:

1. pre-nudge: if `[4]`≠0 `[4] += 0x13e/0x1e` (=10); `[5] += 0xc6/0x12` (=11); same for `[6]/[7]`.
2. `FUN_0058c270`: all 8 scaled `x*pitchW/0x13e`, `y*pitchH/0xc6` (integer division).
3. recenter/flip: `[3] = −[3]`; `[0] −= pitchW/2`; `[1] = −([1] − pitchH/2)`;
   `[4]/[6] += −(pitchW/2) + pitchW/0x27c`; `[5]/[7] = −([5]/[7] + (−(pitchH/2) + pitchH/0x18c))`.

pitchW/pitchH = **the VENUE club's stadium dims << 16**: `FUN_00585ee0(registry@0x66c0d0,
fixture+0x44)` → club handle → `FUN_005793d0` → club record → u16s at `+0x36`/`+0x34`
(→ session `+0x4c`/`+0x50`, which `kickoff_init` halves into `m[0x1820]/m[0x1824]`). These
u16s are the .DBC header pair parsed with mins 0x3c/0x69 (`club_tactics_re.md` parse order)
— i.e. the pitch is per-stadium, from EQUIPOS.

Roam box: ordered min/max over transformed `[0]` vs `[0]+[2]` and `[1]` vs `[1]+[3]` →
rec `+0x18/+0x1c/+0x20/+0x24` (minX/minY/maxX/maxY).

## 5. FUN_005841e0 STR gate — CORRECTION to stat_match_engine_re.md

The ×3/4 reduction is **NOT** "club-performance/fatigue history". Verified from the fresh
decompile (`docs/re/session/fn_005841e0_FUN_005841e0.c`): for a fielded starter
(`player+0x19 < 0xc`) of a loaded league club, the gate compares the player's broad ROLE byte
(`+0x1c`) against his OWN tactic slot's raw grid coords (`club + (slot+2)*0x20`, 1-indexed
slot = the same `+0x60+i*0x20` blocks):

- GK slot (`+0x19`==1) with a non-GK role, or GK role in an outfield slot → **STR = mean/2**.
- DEF keeps full mean iff slot `[4]` (mk1.x) < 0x6b; MID iff 0x59 < mk1.x < 0xb6;
  ATT/other iff `[6]` (mk2.x) > 0xd3. Otherwise **STR = mean·3/4**.

i.e. a POSITION-FIT band check on the attack axis of the 318-wide design grid — fully
derivable from .DBC data (no runtime club state involved). The two raw outputs also feed the
lineup (rec +0x35..+0x38 = raw VE/RE/AG/CA).

## 6. Lineup header + team-level fields (what the engine's team header carries)

`FUN_005b6ba0` copies lineup `+0x4..+0x28` (skip +0x0/+0xc) → `team[0xbf..0xc7]`. Filled as:

- lineup+0x4 (`team[0xbf]`) = transform(`club+0x260`) — x-coord line, ctor default 0xc6 (198)
- lineup+0x8 (`team[0xc0]`) = transform(`club+0x25c`) — x-coord line, ctor default 0x4f (79)
  (both run through `FUN_0058c300` as block[4]-style x values; VALUE semantics un-RE'd —
  probably team lines; the .DBC parser does not overwrite the ctor defaults)
- lineup+0xc = fixture+0x18 (u16; SKIPPED by the b6ba0 header copy)
- lineup+0x10..+0x28 (`team[0xc1..0xc7]`) = the **7 tactic lever bytes in order
  club+0x1d9, 0x1da, 0x1db, 0x1dd, 0x1de, 0x1df, 0x1dc** — the levers land in the team
  header the engine reads (`team[0xc7]` = lever `+0x1dc` selects the 0xe1 ftol constant per
  `stat_match_engine_re.md` — first engine-consumer of a lever byte; EXACT_PORT_PLAN gap B
  is now traceable through team[0xc1..0xc7] consumers).
- lineup+0x790 u16 = club id (fixture+0x38 home / +0x3a away); +0x794/+0x79c = club-name /
  tactic-or-"COMPUTER" strings (`FUN_0057d1f0(club)` = `DAT_0066c178 + club[0x5c]*0x9c`
  when league club, else `club+0x2c`).

Session fields also written by FUN_0044d5f0 (beyond the port's current session model):
`+0x64`/`+0x804` = fixture+0x18/+0x1a u16s; `+0x18` = competition-is-league flag
(DAT_0066b1dc ∈ {0,1,2,3}); `+0x10` = fixture+0x4; `+0x44/+0x48` = fixture+0x58/+0x5c;
`+0x1c/+0x20/+0x24` = fixture+0x40/+0x48/+0x50; `+0x28` = fixture+0x30; `+0x2c..+0x38` =
fixture bytes +0x34..+0x37; `+0x4c/+0x50` = venue pitch dims<<16; `+0x54` = 0; `+0x58` =
(venue==home) with neutral→1; `+0x7f0` = away-club-is-human (`club+0x5c != 0xffff`... note:
0xffff = NON-league/friendly-pool club); `+0x68..+0x80` / `+0x808..+0x820` = the 7 home/away
lever bytes as dwords (order 1d9,1da,1db,1dd,1de,1df,1dc).

## 7. What this unlocks (M3 wiring readiness)

All lineup inputs are now derivable from ALREADY-EXPORTED data + known defaults:

- ids/attrs/posFine/role: `app/data/game_db.json` (engine-exact parser) ✓
- tactic slots incl. fields [0..3]: `app/data/club_tactics.json` `slots[i].raw` ✓
- levers: `club_tactics.json` raw lever bytes ✓
- XI assignment: `club_tactics.json` `xi` ✓ (slot byte `+0x19`)
- morale/fitness/cap: runtime — season-init values known (`morale_re.md`: morale 90+rand(10),
  fitness halfway to 40 from 99 → 70, cap 99)
- **EXPORT GAPS — CLOSED 2026-07-07**: player `+0x16`/`+0x17` (rec+0x2c/+0x30) → game_db
  `b16`/`b17`; stadium pitch-dim pair → `club_tactics.json` `pitch` (substitute rule, NOT a
  plain min: `+0x34 < 0x1e → 0x3c`, `+0x36 < 0x34 → 0x69` — fn_00579c70 L112-117; Man Utd
  116×76, Barcelona 107×72, kill-tested). CORRECTION: `+0xf8` (rec+0x42) was ALREADY
  exported as game_db `squadNo` since commit `cc06ef4` — this doc's original gap list
  over-counted it. Also pinned this pass: rec+0x44 = (player+0x18)+1 where the loader copies
  `+0x18 ← +0x1d` (= posFine−1, fn_005820f0 L64), so **rec+0x44 == game_db `posFine`**
  (1..18), not "posFine+1" as §3's wording suggested.
- club+0x230 marking table + club+0x25c/+0x260: ctor defaults (0 → rec+0x28 = −1; 79/198).

Feeder shipped (2026-07-07): `app/scripts/Pm98LineupFeeder.gd` builds both lineups + session
from game_db + club_tactics per THIS map; `run_full_match.gd` seed-1 e2e on real squads
(MU vs LIV) reaches FULL TIME deterministically. Next: M4 e2e oracle (which can still dump a
live lineup from wine as an independent cross-check of THIS map).
