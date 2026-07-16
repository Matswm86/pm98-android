# PM98 — APP vs SPEC AUDIT (findings only — no fixes applied)

> Cross-check of the shipped app (`app/art`, `app/data`, `app/scenes`, `app/scripts`) against
> [`SOURCE_INVENTORY.md`](SOURCE_INVENTORY.md) + [`SPEC_BINDING.md`](SPEC_BINDING.md). Each
> finding cites a real source. **No edits were made** — the user reviews before any fix.
> Verdict legend: **INVENTION** (not traceable to source — must fix) · **INFERENCE**
> (documented best-effort, keep flagged) · **GAP** (honest, already flagged in code) ·
> **SOURCE-TRUE** (verified clean this pass, listed for the record).

## Findings (most severe first)

### A1 — INVENTION · `docs/re/match_view_re.md:144-145` — ✅ CORRECTED 2026-07-01
Claims: *"`HIERPREM.RAW` also holds white pitch-line grass tiles; overlaying them at the right
positions (penalty boxes / halfway) would replace the currently line-less grass."*
**False.** This pass decoded and **viewed** all 7 `HIER*.RAW` + `CAMPINA.RAW`: the grass atlas
is plain green grass + crowd + goal-net mesh + advertising boards only. A palette white-on-green
tile scan found **zero** line tiles. The real side-on pitch lines are engine-drawn from the
un-enumerable `PCF5DAT.PKF`. This claim seeded the (correctly abandoned) "NEXT #1" task.
**Fix:** replace lines 144-145 with the verified truth (no static line tiles; engine-drawn,
PCF5DAT gap). Evidence: `docs/re/inventory-evidence/format_contactsheet.png` (HIERPREM grid).

### A2 — INVENTION · `docs/re/match_view_re.md:76` — ✅ CORRECTED 2026-07-01
Labels `CAMPINA.RAW` as **"(pitch)"**. **Wrong** — viewing it shows the countryside / skyline
backdrop (trees, buildings, a perimeter brick wall in horizontal strips), not the playing
surface. **Fix:** relabel `CAMPINA.RAW` as "countryside/skyline backdrop". Evidence: viewed
this pass (`scratchpad/campina_grid.png`).

### A3 — ~~INFERENCE~~ **CLOSED 2026-07-06** · international club country tags now EXACT
The EQUIPOS club-record header byte (param_1[5]) is the PAISES.30 country code — all 476
clubs resolve in the game's own table (Wrexham/Cardiff/Swansea = WALES, Celtic = SCOTLAND).
game_db carries `countryCode` + the PAISES English name on every club; the old fuzzy
directory inference and the `intlCountryMatchRate` meta flag are gone
(`tools/extract_squads_exact.py` kill-tests, `docs/re/club_tactics_re.md`).

### A4 — INFERENCE · `app/data/sample_db.json` (synthetic fallback)
`GameDB.gd:26` load order is `res://data/game_db.json` → `user://game_db.json` →
`res://data/sample_db.json` ("tiny synthetic fallback so the app always runs"). The real
`game_db.json` is present so the sample is never used at runtime, and use is gated by the
`is_sample` flag. **Action:** none required; ensure any UI that loads under `is_sample` says so
(it is invented content, must never read as real data).

### A5 — GAP · `LeagueTableScreen.gd:20`
Comment: *"(don't invent a table) — flagged for the season-loop pass."* The league table is not
yet computed from a real season loop. **Honest gap, already flagged.** Do not populate with an
invented standings table; build the season loop or show the honest empty/seed state.

### A6 — GAP · `MatchSimulador.gd` side-on camera/layout
The side-on simulador's band layout / camera / per-tick positions are **app substitutes**
(PCF5DAT not reversed — INVENTORY §5.1). The art tiles are 100% source; the geometry is not.
**Action:** never present the side-on view as source-faithful geometry; keep the documented
"faithful substitute, not invented match data" framing (`MatchSimulador.gd:20`).

### A7 — RESOLVED 2026-07-01 · engine sprite-select recovered; `_facing()` model was invented
The engine player-draw is **`FUN_005a5460`** (`docs/re/move/fn_005a5460_FUN_005a5460.c`), reached
via JUG loader `FUN_005923f0` (`jug.pgf`→`ctx+0x2468`) / `.PGF` parser `FUN_005d3f60`. Full recovered
spec: **`docs/re/jug_render_spec.md`**. The frame index (`:337/343`) is
`JUGbank + (framesPerDir[kind]*dir + base[kind] + phase) * 0x4c` — i.e. JUG is laid out per-kind as
**`[direction][phase]` (direction OUTER)**, only **5 unique directions** are stored (`dir>4 → dir=8-dir`
+ render-side horizontal mirror, `:251-254`), and direction is bucketed by **non-uniform camera-relative
perspective thresholds** `DAT_006653e0=[3584,13312,19456,29184,36352,46080,52224,61952]` (`:206-282`),
not a uniform 45° `atan2`. There are two modes (8-way / 12-way) chosen per `kind`; per-kind
`framesPerDir` (`DAT_00664fb8`) and `base` (`DAT_006744e8`, .bss/runtime) tabulated in the spec.
**Finding:** `_facing()`'s "frame 0 = down, +45°/step" and `export_match_art.py`'s `[3×8]` /
`fr[row*8+d]` bake are BOTH inventions (the bake is the transpose of the real layout; the "W-pattern
proof" was a rationalisation of the mirrored half-sweep). The engine renders a pseudo-3D two-billboard
sprite under a fixed 3/4 camera — **it has no side-on 2D view at all.**
**Action taken:** removed the false "source-faithful compass" claims from `_facing()` +
`export_match_art.py` (behaviour unchanged — no invented remap applied); the side-on WATCH view is now
labelled a documented app approximation, consistent with the already-noted app-choice camera/tiling.

### A8 — GAP (opened by A7) · faithful JUG render not built; side-on WATCH view is an approximation
A source-faithful player render needs §2 `[dir][phase]` indexing + §3 mirror against a recovered
camera angle, plus the `kind` byte and the un-reversed PCF5DAT 3/4 tile-scroll camera. Until those
land the WATCH sprites are a stylised slice (the baked 24 frames are ~1-2 real directions' phases,
not 8 facings). Flag, do not paper over with another guess.

**PARTIALLY CLOSED 2026-07-01 (raw-binary, cross-validated):** the JUG frame-selection model is
now fully reversed. There are **74 kinds (0..73)**, not 16 (the spec table was truncated). The
per-kind tables (`mode`/`fpd`/`next-state`/`flag`) and the `base` frame-offset table are dumped
straight from `.data`; `base` is filled by `FUN_005a2830` as
`base[k] += fpd[k]*mode[k]` for `mode[k]>0`, and summing over all 74 kinds equals **4211 — the
exact JUG.PGF header frameCount** (independently read from `DATSIM.PKF` `LFGP`@0x1547ea). `mode[k]`
is the literal stored-direction count; negative-mode kinds are mirror-twins (0 new frames).
Reproduce: `tools/re/dump_jug_kind_tables.py` (validates PASS). Spec updated: `jug_render_spec.md`
§2/§3/§4a/§5. The `kind` *setters* are traced (gait `FUN_005a8f20`→0..3, set-piece
`FUN_005a3400`/`FUN_005a7260`, GK `FUN_005a65a0`, LUT `DAT_006655b0`).
**FURTHER NARROWED 2026-07-01 (session 2, raw-binary + viewed):**
- **`JUGCAM.IND` is NOT an image** (55296 B = 256x216, `DATSIM.PKF` @off 5311682). Decoded
  both orientations to noise (viewed); width sweep finds no coherent bitmap at any divisor
  width. It is an index/lookup table (72% zero, ~180 small monotonically-increasing indices).
  Opened as a FILE at sim (re)entry via `FUN_005ec020` (only xref at VA `0x592a63`, in
  `FUN_005923f0`'s `+0x5fac != 0` block). It is **not** consumed by `FUN_005a5460`'s frame
  math. Internal layout + consumer still a GAP. (Detail: `jug_render_spec.md` §5.)
- **`FUN_005a5460` is the player DRAW virtual method** (vtable slot `+0x08`), so no direct
  caller. Player vtable base = **`0x639220`** (`[0x639228]=0x5a5460`), set by constructors
  `0x5952a4`/`0x5963fc`. Prologue-verified convention: `param_1=ecx=this` (player);
  **`param_2` = a caller-pushed first stack arg** (`[esp+0x32c]`) = the render/camera ctx,
  distinct from `this->simctx` (`*(this+0x18c)`, which holds the JUG bank `+0x2468`). Direction
  math confirmed: `cameraAngle=*(short)(param_2+0xdc)`, `playerFacing=*(short)(this+0x34)`,
  `uVar22=facing-camera+0x4000`. **Correction:** the zero-arg draw-loop dispatches
  (`FUN_005b8bf0` iterator + 4 fixed `call [obj+8]` in `FUN_00598740`) push NO arg → they are
  NOT the calls into `0x5a5460`; the real arg-pushing `call [vt+8]` site is not yet pinned.
**CAMERA-ANGLE ORIGIN RESOLVED 2026-07-01 (session 3, byte-for-byte write chain):**
- `param_2` (the draw's camera ctx) = the **render device object `D`**. Its `+0xdc`/`+0xde` are
  written by the camera setter **`FUN_005d7db0` (`SetCamera`)** — the *sole* writer of both
  offsets (Ghidra `FindWordStore 0xdc 0xde`): `D[0x37]=(short)yaw` (`+0xdc`), `+0xde=pitch`.
- Arg chain, exact-disasm (not Ghidra vararg guess): sim `@0x59a3c2`
  `FUN_005f7150(sceneRoot=matchctx+0x430, D, cam=matchctx+0x27f0)` →
  `FUN_005d7b20(D, cam)` → `FUN_005f6230(viewCtx=cam, D)` → `SetCamera(this=D, yaw=cam+0x8c,…)`.
  Hence **`D+0xdc = (matchctx+0x27f0)+0x8c = matchctx+0x287c`** (16-bit yaw), `D+0xde=+0x287e`.
- Cross-check: `FUN_00598740:113` copies `*(word)(matchctx+0x287c)` → `matchctx+0x181c` (confirms
  `+0x287c` is the live yaw). `FUN_005f7150` threads `D` down as the scene-draw arg, so `D` reaches
  each player draw as `param_2`. Evidence decompiles: `docs/re/move/fn_005d7db0`, `_005f6230`,
  `_005d7b20`, `_005f7150`. (`FUN_005a1820` = an AABB overlap test / view-mode picker, ruled out.)

**YAW-WRITER RESOLVED 2026-07-01 (session 4) — the s3 "camera-follow yaw" sub-gap was a wrong
premise: the match camera never rotates, yaw is a constant 0.** Byte-verified static proof:
- `camctrl = matchctx+0x27f0` is plain data (ctor zeroes `+0/+4`, no vtable). A byte-search of
  disp `0x27f0` in `.text` finds all 8 address-computations; at each `lea reg,[matchctx+0x27f0]`
  camctrl is passed straight into a thiscall/arg, so its `+0x8c` can only be written by a callee
  (`0x5f56a0/0x5f5740/0x5f5840/0x5f57e0`, + read-only draw entry `0x5f7150`).
- **Only `FUN_005f56a0` (the camctrl ctor) writes `+0x8c`**: `0x5f5731 mov word [eax+0x8c],cx`
  with `cx=0` (also `+0x8e`/`+0x90` = 0) → yaw=pitch=roll=**0**. The other three methods write
  position/target only (`+0x54/+0x48`, `+0x6c`, `+0x84`) — the camera pans, never rotates.
- No matchctx-relative store to `+0x287c/+0x287e/+0x2880` exists (byte-search): the only `+0x287c`
  access is a **read** at `0x5989f4` (the `→+0x181c` copy). Value chain closed: `FUN_005f6230`
  reads `camctrl+0x8c/+0x8e/+0x90` → `SetCamera` → `D+0xdc` → draw `cameraAngle`.
- **Corollary:** the draw's `cameraAngle = *(short)(param_2+0xdc) = 0`, so `uVar22 = playerFacing −
  cameraAngle + 0x4000` collapses to a fixed `playerFacing + 0x4000` — orientation-fixed match view,
  no yaw recovery needed. Evidence: `docs/re/move/fn_005f56a0/_005f5740/_005f5840/_005f57e0/_005f6230`.
- The three s3 candidate stores (`0x5a27ed/0x5a31bc/0x5af9bf`) are **NOT** camctrl — base is a player
  struct (same block zeroes the `+0x34` facing word) or a counter (`eax=[esi+0x3b8]`, `dec`); shared
  offset `0x8c` is coincidental.

**VIEW-MATRIX + PROJECTION RESOLVED 2026-07-01 (session 5) — the s4 "read `FUN_005eeba0` before
claiming the view angle" gap is closed: there is no rotation tilt anywhere in the match camera.**
Ghidra-decompiled (`docs/re/move/fn_005eeba0/_005eea80/_005eea50/_005ee800`):
- `FUN_005eeba0(out,eye,yaw,pitch,roll)` = fixed-point (16.16) Euler VIEW matrix
  `V = T(-eye)·R(-yaw)·R(-pitch)·R(-roll)`; each `R` is a cos/sin-LUT (`DAT_006d31c8`) single-axis
  rotation (matmul `FUN_005ee800`). **It takes eye + 3 angle words only — no look-at target.**
- yaw=pitch=roll = the constant-0 words `camctrl+0x8c/0x8e/0x90` (s4) ⇒ every `R` = identity ⇒
  **`V` = pure translation `T(-eye)`.** World-axis-aligned camera; it never rotates toward the tracked
  actor (no look-at→Euler conversion). The on-screen "3/4" look is **not** a tilted camera.
- The 2nd matrix `SetCamera` composes is a projection SCALE, not a tilt: `FUN_005eea50(0x10000,k,k)`
  (diagonal builder) with `k = (ftol(width·C1@0x639ac0·C2@0x639ae0) · camctrl+0x88) >> 16`.
- **`D` (draw device) = `camctrl = matchctx+0x27f0`, one struct** (corrects s3's "(D, cam)"): the
  `FUN_005d7b20→_005f6230→SetCamera` chain all thiscall the same object, which is written back at
  `+0xdc/+0xde/+0xe0` (=matchctx+0x287c…). `camctrl+0x88` ctor default = `0x10000`.
- GAP (flag): whether `camctrl+0x88` is ever set ≠1.0 (13 `lea [esi+0x2878]` sites → `FUN_005c9f60`/
  `_005c0d50`, a likely settings path; base `esi` unconfirmed) — a scale even if so, never a tilt.

**ANCHOR-WRITER RESOLVED 2026-07-01 (session 6) — the s4/s5 "what writes the eye anchor
`matchctx+0x1614`" GAP is closed. It is NOT a raw copy from a named "ball"; it is a vtable
object's own per-frame position-update method. No camera-rotation implication (s5 stands).**
Byte-search (`.text` disp `0x1614`/`0x1618`/`0x161c`) + Ghidra decompile
(`docs/re/move/camwriter/fn_0058e2c0`, `_0058e050`, `_0058e120`, `_0058e220`, `_005902b0`,
`_00598740`):
- **`matchctx+0x1610` is a C++ object** (vtable `0x639080`, ctor **`FUN_0058e050`** installs
  `[this]=0x639080`, called at `0x591254` with `this=matchctx+0x1610`; back-ptr `this+0x1d4 →
  matchctx`). The "anchor" vec3 is the object's **position at `this+4/+8/+0xc` =
  `matchctx+0x1614/0x1618/0x161c`** — so every store is `[this+4]`, which is exactly why a
  matchctx-relative disp-`0x1614` byte-search finds **reads only** (all 20 hits are `mov reg,
  [ebp+0x1614]` / `lea`, zero `mov [..+0x1614],reg`). Hypothesis from s4 GAP confirmed.
- **Writer = vtable slot 3 (`+0xc`) = `FUN_0058e2c0`**, called per-frame at `FUN_00598740:192`
  (`(**(code**)(*(matchctx+0x1610)+0xc))()`). It updates `this+4/+8/+0xc` two ways: **(A) lerp**
  toward target `this+0x9c/+0xa0/+0xa4` over `this+0x6c` sub-steps (`pos += (target-pos)/n`);
  **(B) velocity-integrate** `this+0x20/+0x24/+0x28` (`pos += vel`) **clamped to the pitch AABB
  `matchctx+0x1828..+0x183c`** (min/max), with a fixed `±0x23d7` Z bias. Path B gates on flag
  `this+0x63`.
- **`matchctx+0x1610` is a UNIQUE object, not one of four of a kind** (corrects the first draft of
  this block). Only `+0x1610` uses ctor `FUN_0058e050` / vtable `0x639080`. The 3 objects at
  `+0xaac`/`+0xe74`/`+0x123c` are a **different class** (shared ctor **`FUN_005a2640`**, MI: installs
  vtables `0x639224`→`0x639238`→`0x639228`) that each store **`this+0x190 = matchctx+0x1610`** (a
  pointer to the `+0x1610` object) + `this+0x18c = matchctx`. All four implement the same per-frame
  interface, so `FUN_00598740` calls slot 2 (`+8`) then slot 3 (`+0xc`) on all four
  (`:182-185, 192-195`) — but they are **1 + 3, not 4-of-one**. The `+0x1610` object's position is
  read as the camera look-at fallback (`0x597c42 lea eax,[ebp+0x1614]` → `FUN_005f57e0`) **and** the
  player-AI orientation reference (`FUN_005b73a0:588/630`).
- **Consumer chain (unchanged conclusion):** slot 0 (`FUN_005902b0`) READS this position, maps
  it via `FUN_00590aa0`, and writes it into the render device at `[matchctx+0x1d4]+0x294c+0x40`
  → drives camera POSITION only. **No rotation anywhere** — s5's "no tilt" holds.
- **Identity = the match BALL (byte-evidence, strong).** `FUN_0058fbe0`/`FUN_0058f3c0` (methods on
  this object) do 3D **ball physics**: position `this+4/8/c`, velocity `this+0x20/0x24/0x28`,
  **velocity reflection at boundaries** (`this+0x24 = -this+0x24`, `this+0x28 = -this+0x28` = bounce
  off touchline / ground), **clamp to the pitch AABB** `matchctx+0x1828..+0x183c`, an **attacking-side
  flag** `this+0x54` vs `matchctx+0x19a0`, and **goal-target geometry** written to `this+0x90/0x94/0x98`
  from pitch half-width `matchctx+0x1820/0x1824`. `FUN_0058eca0` = `SetPossessor(this, player)` (sets
  `this+0x40=player`, bumps possession counter `this+0x80`). It is also the point all players orient
  to (AI) and the 3 sibling objects each hold a pointer to it. No other football-sim object fits.
- **3 SIBLING OBJECTS RESOLVED 2026-07-01 (session 7, CORRECTED s8) — they are the two per-team
  KEEPERS + the REFEREE, reconciled with the existing `Pm98Match` port (which already had this right).**
  ⚠️ **s7's first pass mislabelled `+0xaac`/`+0xe74` as "TEAM 1/TEAM 2" — WRONG.** There is exactly
  ONE object per side (not 11), it is placed *behind its own goal line* at kickoff, and the keeper-save
  geometry `FUN_0058f140` operates on this class — so it is the GOALKEEPER, not the team. The 20 outfield
  players live in a separate array (`Pm98Match._build_player`). Evidence = construction disasm
  `0x5911d7-0x591242` + Ghidra (`docs/re/move/siblings/fn_005a2140`, `_005b5790`, `_005a2240`/`_005b5940`,
  `_005a4560`; ctor `move/camwriter/fn_005a2640`) + `app/scripts/Pm98Match.gd` + `Pm98Predicates.gd`:
  - Ctor `FUN_005a2640(this, matchctx)` sets base-vtable chain `0x639224→0x639238→0x639228`, stores
    `this+0x18c=matchctx`, `this+0x190=matchctx+0x1610` (the ball). Then construction **stamps a team
    index `this+0x3bc`**: `+0xaac`→**1** (`0x5911f0`), `+0xe74`→**2** (`0x591219`); `+0x123c` gets
    **no** index and a *different* derived vtable (`0x6391f8` vs `0x639208` for the two keepers).
  - **`+0xaac` = KEEPER (team 1), `+0xe74` = KEEPER (team 2).** Keeper slot-1 (`FUN_005a2140`) at
    kickoff/reset (`DAT_006d31c4==0`) places each keeper **in its own goal, keyed on the 1/2 index**:
    idx 1 → `this.y = -0x10000 - [matchctx+0x1824]`, `this.x = [matchctx+0x1820]/2`; idx 2 → `this.y =
    [matchctx+0x1824]+0x10000`, `this.x = -[matchctx+0x1820]/2` (`matchctx+0x1820/0x1824` = pitch
    width / half-length). Each keeper selects its own 256-B data block: `this+0x2dc =
    [matchctx+0x1a5c] + (idx==1?5:6)*0x100` (= base+0x500 / +0x600). Keeper-save = `FUN_0058f140`.
  - **`+0x123c` = REFEREE** (`FUN_005b5790` forces `this+0x3bc=0`, block base+0x400). It positions
    itself **from the BALL + the restart type**: switch on `[matchctx+0x448]`, cases read the ball's
    goal-target geometry `ball+0x90/0x94/0x98` (`this+0x190`) and clamp (penalty-spot / corner /
    free-kick offsets); on free-kick/penalty (`FUN_005b5dd0`) it walks to the restart target
    `matchctx+0x16a0..0x16a8`. (Labelled "referee" in the `Pm98Match` port; the neutral index-0 actor.)
  - All three share the per-frame quadruplet `{5a5460,5a3400,5a4560,5a4600}`; slot 2 (`FUN_005a4560`)
    copies an **81-dword (0x51) record** `this+0x3b0[DAT_006d31c0] → this+0x40` each frame (the s6
    "record copy" is this; corrected: record base `this+0x3b0`, stride `0x51` dwords, not `0x191`).
  - GAP still open (flag, do NOT fill): a literal goal-line-cross test for the ball; home/away mapping
    of keeper-idx 1↔2. ~~provenance of the `matchctx+0x1a5c` data table~~ **RESOLVED 2026-07-06:
    the per-actor PALETTE table** (align256 of the `+0x1a54` buffer; team kit bytes + `DatSim\paletas\
    palpor%d` keeper palettes via `FUN_005b63e0`; +0x400 referee, +0x500/+0x600 keepers). Display-only
    — no outcome consumer; see `docs/re/session_lineup_re.md` §2.

**Still open:** human-readable action label per kind (no name string in the engine — never
invent one) · `player+0x2bc` band-flag meaning · `JUGCAM.IND` internal layout/consumer ·
PGF header `h5∈{1,2}` · **camera POSITION-follow (s4/s6):** eye = `matchctx+0x1614` vec3 +
fixed `0x500000` Z (`FUN_005f5740`); look-at = tracked actor `*(matchctx+0x43c)+4` / `*(+0x440)+4`,
fallback anchor `+0x1614` (`FUN_005f57e0`); anchor writer = `FUN_0058e2c0` slot 3 (s6, above);
zoom = clamped `FUN_005edfa0(+0x2874,0x1051e)` (`FUN_005f5840`) — remaining GAP is the object's
**semantic identity** (target-setter of `this+0x9c` / the 3 sibling objects; do not name it "ball"
without it) · the exact scene-graph vtable slot that sets `ecx`=a specific player (base-class
stubs `0x605d96` obscure the static path — likely needs a dynamic trace) · PCF5DAT 3/4 camera.

## Verified SOURCE-TRUE this pass (no action — recorded so they aren't re-flagged)
- `app/art/kits/*.png` (92) = real **club crests** (BIGESC/MINIESC), id-named via EQUIPOS club
  index — `tools/re/map_crests.py:export_kits`. (Folder name "kits" is loose but art is source.)
- `app/art/screens/campo.png` = `recursos\iconos\alineacion\campo.bmp` = `CAMPO.BMP` member of
  `RC_DBASE.PKF` (ref MANAGER.EXE `FUN_004fc321`) — the top-down pitch WITH real lines.
- `app/art/faces` (613) / `faces/mini` (690 = MINIFOTO.PKF members) / `flags` (127 =
  BANDERAS.PKF) / `match` (9, all DATSIM) — decoded source art (viewed in contact sheet).
- `StadiumScreen.gd` tier = `clamp(capacity*11/130000,0,11)` reversed from `FUN_0051a6e0`;
  `_club_id_guess()` honestly returns `-1` (omits crest) — misnamed, not an invention.

## Prior inventions ALREADY removed by earlier passes (keep removed — do not regress)
From in-code comments (verified by grep this pass):
- `DataBaseScreen.gd`: invented green list, alternating row banding, separator lines, subtitle.
- `DirectivaScreen.gd`: invented "THE BOARD EXPECTS / YOUR RECORD" text.
- `StadiumScreen.gd`: invented SEATS / STAND / TIER readouts.
- `FinanceScreen.gd`: invented week-by-week history (replaced with the honest model constant).

## Summary
- **2 true inventions** found — both in the stale `match_view_re.md` doc (A1, A2), not in
  shipped app data/art. They directly caused the abandoned pitch-line task.
  **Both CORRECTED 2026-07-01** (re-verified by fresh decode: CAMPINA = countryside backdrop,
  HIERPREM grid = grass+boards+crowd only, zero line tiles).
- The app's data/art is otherwise **source-traceable**; remaining items are documented
  inferences (A4; A3 closed 2026-07-06 — country tags now exact) or honestly-flagged
  gaps (A5, A6).
- ⚠️ **SUPERSEDED IN SCOPE 2026-07-02:** the pass above audited asset/data PROVENANCE only.
  It never walked the screen NAVIGATION. The §B fan-out below audits what every home-screen
  action actually opens vs the original — and finds the user's complaint is correct: most
  sub-flows are invented substitutes, and many original screens are missing entirely.

---

# §B — HOME-SCREEN FAN-OUT RECHECK (2026-07-02, user-ordered)

> Method: (1) enumerated the ORIGINAL screen set from `RECURSOS.PKF` (parsed clean: 448
> records, 36 folder headers, 392 files, 0 errors) + `strings MANAGER.EXE` path refs;
> (2) walked every `Main.gd:_menu_action` route (Main.gd:2026-2050) and every
> `_mount_browse` call site; (3) traced the career match chain; (4) ran the screen test
> suites. The original PC game is runnable locally for visual confirmation:
> `WINEPREFIX=<repo>/.wineprefix wine drive_c/PM98/MANAGER.EXE` (~150MB RAM total).

## B0 — The ORIGINAL screen inventory (source-proven)
`RECURSOS\ICONOS\<folder>` in RECURSOS.PKF — 27 screen folders, each a real original
screen (MANAGER.EXE holds a literal `recursos\iconos\<name>` path string for all but
CREDITOS and MENUPCFUT5):
ALINEACION · CAJA · CREDITOS · DIRECTIVA · EMPAREJAMIENTOS (fixtures/pairings) ·
EMPLEADOS (staff) · ENTRENAMIENTO (training) · ESTADIO · FICHAR · HIGHLIGHTS ·
HISTORIAL (history) · LESIONADOS (injuries) · MENUPCFUT5 · MENUPRINCIPAL · MULTAS (fines) ·
NIVELES (objectives) · NOTICIAS (news) · OFERTAS (offers) · OPCIONES (options) ·
PLANTILLA (squad) · SECRETARIO · SEGUROS (insurance) · SELECCION · SELECCIONPRO ·
TACTICAS · TV · VERRIVAL (view opponent)
plus `PREMIER\ICONOS\{MENUPRINCIPAL, NIVELES, TV, FINOBJETIVO}` + `PREMIER\SININFO`
(PM98 English-market overrides). MARCA (results) and CLASI (league table) have no iconos
folder — their art is in IMG.PKF (CLASIFICACION etc., per pkf_format.md).
GAP (honest): per-folder file counts are not encoded in the PKF directory (all 392 file
records carry zero folder-membership fields; files chunk 32/dir-chunk physically).

## B1 — Per-action verdict (12 icons + 4 controls, Main.gd:2026-2050)
Verdicts: **TRUE** = reversed original layout · **SUBSTITUTE** = invented UI standing in
for a real original screen · **WRONG-SCREEN** = opens a different original surface than
the original does · **PARTIAL** · **STUB**.

| action (icon) | original target (evidence) | app today (cite) | verdict |
|---|---|---|---|
| results (MARCA) | results view, art in IMG.PKF (no iconos folder) | BrowseScreen W/D/L text list, Main.gd:2076-2095 | **SUBSTITUTE** |
| table (CLASI) | CLASIFICACION (IMG.PKF) | LeagueTableScreen (ma_10 rebuild) | TRUE layout (data: A5 gap) |
| fixtures (CALEN) | EMPAREJAMIENTOS folder | BrowseScreen "COMPETITIONS" chooser + "SEASON FIXTURES" list, Main.gd:1569-1626 | **SUBSTITUTE** |
| lineup (ALINE) | ALINEACION | LineupScreen (ma_7, FUN_004fc321) | TRUE |
| tactics (TACTI) | TACTICAS folder | BrowseScreen menu wrapper → TacticsScreen modal (ma_9), Main.gd:2204-2242 | **PARTIAL** (wrapper invented; original TACTICAS screen not ported) |
| opponent (RIVAL) | VERRIVAL folder (dedicated screen) | RivalScreen (VIEW RIVAL, FUN_005733d0 port; rival_screen_re.md), Main `_show_rival_screen` | **TRUE** (fixed 2026-07-02; assistant-gated report) |
| buy (FICHA) | FICHAR | TransferScreen (ma_11) | TRUE |
| sell (VENDE) / PLAYERS | the hub PLAYERS button opens SQUAD MANAGEMENT (walkthrough run-1: PLAYERS -> squad list -> player -> RENEW/TRANSFER/SACK). The "sell" is the per-player TRANSFER action there, NOT a separate hub screen. | SquadScreen (SQUAD MANAGEMENT), Main `_show_squad_screen`; player tap -> PlayerInfoScreen | **TRUE (nav)** fixed 2026-07-02. GAP: SquadScreen still shows the DATA-BASE attribute columns, not the real contract columns (AV/MO/LOAN/WAGE/YEARS) — see B7; PlayerInfoScreen still OK-only (no RENEW/TRANSFER/SACK yet). |
| staff (EMPLE) | EMPLEADOS folder | StaffScreen (strings-only, NO reversed layout; StaffScreen.gd:3-12) + invented TRAINING browse (Main.gd:2117-2160; original ENTRENAMIENTO is its own screen) | **PARTIAL/SUBSTITUTE** |
| finance (CAJA) | CAJA | FinanceScreen (og_12) | TRUE |
| board (DECIS) | DIRECTIVA | DirectivaScreen (ma_14; meters derived) | TRUE |
| stadium (ESTAD) | ESTADIO | StadiumScreen (ma_15, FUN_0051a6e0) | TRUE |
| NEWS (control) | NOTICIAS "News extra" overlay (walkthrough 155-158) | NewsScreen overlay (frame-baked pages, 0px parity x3; news_screen_re.md), Main `_show_club_news` | **TRUE** (fixed 2026-07-16) |
| SAVE GAME (control) | original save flow | `_career.save()` + toast only, Main.gd:2030-2032 | **STUB** |
| CONTINUE (control) | advance + match | real stat-engine result BUT invented watch/commentary (§B3) | **PARTIAL** |
| EXIT (control) | leave to front door | flow OK, Main.gd:2029 | TRUE-ish (flow) |

## B2 — Original screens with NO app counterpart at all (flag, port or drop the icon —
never fill with invented stand-ins)
ENTRENAMIENTO · EMPAREJAMIENTOS · NOTICIAS · TACTICAS (screen itself) · VERRIVAL ·
HISTORIAL · LESIONADOS · MULTAS · NIVELES (objectives + PREMIER FinObjetivo "goal_game") ·
OFERTAS · OPCIONES · SECRETARIO · SEGUROS · TV · HIGHLIGHTS · CREDITOS · SELECCIONPRO ·
PREMIER\SININFO. Also: **SquadScreen (PLANTILLA — a TRUE ported screen!) is an orphan**,
reachable only from the devshot list (Main.gd:544), not from the hub; YouthScreen is
transitively orphaned behind it.

## B3 — Career match trueness (the "game match isnt true" verdict)
- **Scoreline = REAL ENGINE.** CONTINUE → `Career.advance_week` (Career.gd:374-389) →
  `MatchSim.simulate` → **`Pm98StatMatch`** (byte-exact port of the instant-result engine
  FUN_0044ee70 family, oracle-verified) for the manager's match AND the whole league.
- **BUT silent fallback to an INVENTED sim**: if `_usable()` fails (XI missing attrs),
  MatchSim.gd:86 falls back to `MatchEngine.gd` — self-declared "NOT a 1:1 port …
  constants are ours". Must hard-fail or guarantee XIs instead.
- **Everything the player WATCHES is invented**: `MatchCommentary.gd` fabricates event
  rates/minutes/possession/cards (MatchCommentary.gd:14-16, 141-150); MatchScreen +
  MatchSimulador render that fabricated timeline. The REAL positional engine port
  (Pm98Match/Pm98Driver/Pm98Outer/Pm98Movement, 141 suites green) is **test-only** —
  no scene reaches it. The original also has NO side-on 2D view (A7): its match view is
  a pseudo-3D 3/4 camera (PCF5DAT camera un-reversed — gap, do not fake).
- Honest short path: emit the stat engine's OWN recorded event vector to the result
  screen (delete the RATE_* sprinkles); full fidelity = wire Pm98Outer/Driver into WATCH
  once the tick driver is e2e-complete.

## B4 — Not functional (current tree, verified by running)
**STATUS 2026-07-02: ALL FOUR REPAIRED (`1e5adb3`); full suite 146/146 green. The §B3
silent MatchSim fallback is also CLOSED (`aca1a15`: Hereford attrs recovered → all 92
English clubs field a usable XI; Career pads roster XIs; MatchSim counts+warns).**
- `test_menu_screen`: parse error — the parallel menuicons stream removed
  `MenuScreen._fmt` the test still calls (untracked `app/art/screens/menuicons/`).
- `test_browse_nav`: SeleccionScreen.gd:107 "Identifier not found: GameDB" compile
  failure in test context → career-select instantiation fails inside the test.
- `test_stadium_works` / `test_transfer_screen`: tap-dismiss/back regressions (1 FAIL each).
- `shot_screens.gd` (the screen-render smoke): times out headless (>3 min; previously CI-green).
  (Root cause: `frame_post_draw` never fires on the headless dummy driver — CI runs it
  rendered under xvfb. Now guarded: headless run prints SHOTS SKIPPED and exits.)

## B6 — BINDING VISUAL REFERENCE: full original-game walkthrough (2026-07-02)
`screenshots/original-walkthrough-2026-07-02/` = **639 PNG frames** captured live from the
real MANAGER.EXE under Wine (this repo's `.wineprefix`, registry virtual desktop) while the
user played through EVERY hub object + sub-screen. Auto-captured on change (~1.5s poll,
window-id grab) + 2 user screenshots. Covers: title, SELECT LEVEL (TRAINER/MANAGER/
ACCOUNTANT/TOTAL + "Players age?"), LOAD GAME, ENTER NAME+SELECT TEAM, preseason friendly
picker (Europe/S-America maps, 4 RIVAL slots), TEAMS IN CHAMPIONSHIPS, MANAGER MENU hub,
RESULTS (matches-on-date + competition rail), LEAGUE TABLES + GOAL SCORERS (graph+compare),
THE CALENDAR, TRANSFER MARKET + CURRENT OFFERS + SCOUT + OFFERS(map) + PLAYER INFORMATION
offer flow (+ "F.C. Barcelona has rejected your offer" dialog + channelTV £187,500 event),
SQUAD MANAGEMENT + contract overlay (RENEW/TRANSFER/SACK), YOUTH TEAM, CLUB PERSONNEL (all
9 staff roles + hire overlays), LINE-UP (PARAMETERS/RATING), TRAINING (per-player focus
grid), INJURIES (+ INSURANCE per-player), TACTICS + PREDEFINED (10 formations) + VIEW RIVAL
(= hub OPPONENT, user-confirmed same screen), STATISTICS, MAN-TO-MAN MARKINGS (+ marking
lines), NEWS extra, FINANCES (income/expenses week/season + balance graph), BOARD OF
DIRECTORS (confidence meters + loans + bonuses), GROUND (works/improvements/extras),
MATCH OPTIONS (WATCH/HIGHLIGHTS/BRIEF/RESULTS + graphics/cameras/sound + lineups ON/OFF),
RESULT-mode match (HALF/FULL TIME + stadium panel + man-of-match), **BRIEF-mode match**
(clock, kits scoreline, possession bar, minute-stamped colour-coded event feed, in-match
LINE-UP/TACTICS/MAN-TO-MAN/STATISTICS), pre-match XI-vs-XI photo screen, 3D WATCH match,
CHARITY SHIELD trophy screen, SAVE GAME dialog. Run 3 (+160): FINANCE income/expenses
per-week AND per-season (per-competition sections, named transfer-sale lines, loans,
hospitals/insurance groups), transfer-list flow (MARKET tag, "PLAYER PLACED ON TRANSFER
MARKET" banner, TEAM OFFER screen w/ per-offer REFUSE, CPU rejection dialog), **EUROPEAN
CUP GROUP DRAW** (ball machine, groups A-F, 1/8 FINAL), GROUND MATCH DAY (ticket price
per fixture, sponsor-boards season offer), CAR PARK corner-level grid, foreign-league
OFFERS browsing + Ronaldo/Weah cards, active youth-scout search, 2 more matches.

**USER PRIORITY (binding, 2026-07-02):** rebuild target = *fully playable as the original
with BRIEF + RESULT match modes*. The 3D WATCH match is explicitly LAST — the user mostly
plays BRIEF. Everything else in B5 comes first.

## B4b — BRIEF/RESULT evidence note (2026-07-02, from the run-2 walkthrough frames)
The original BRIEF EVENTS feed (run-2 sheet09, Man Utd v Sao Paulo friendly) shows
minute-stamped lines of these kinds: Kick Off / "Shot by X (club)" / "Shot saved by
GK (club)" / "Good run by X (club)" / "Cross by X (club)" / "Header by X (club)" /
"X (club), injured" / "Goal by X (club)" (goal lines red/colour-coded), plus the
possession bar and the FIRST HALF clock. The HALF TIME / FULL TIME (RESULT) panels
show per-side BOOKINGS (name+min) and GOALS (name+min) columns, TOTAL FOULS, the
POSSESSION % bar, the stadium panel (capacity/attendance/att. money/sponsor boards/
sponsorship) and MAN OF THE MATCH w/ photo.
**Engine implication:** the instant-result stat engine (Pm98StatMatch) records ONLY
goal events (types 0-3 + pens) — shots/saves/runs/crosses/injuries/bookings/fouls/
possession are produced by the REAL-TIME match engine the engine-RE track is porting.
So the source-true BRIEF feed must consume the positional engine's event stream once
it lands; MatchCommentary's RATE_* sprinkles cannot be made source-true from the
instant-result vector alone (its GOAL lines already ride the real vector — scorer +
minute — since MatchSim `goals`).

## B5 — Ranked fix list (user reviews; no fixes applied in this pass)
1. Remove/replace the invented BrowseScreen surfaces that shadow REAL original screens:
   NEWS feed, RESULTS list, COMPETITIONS/SEASON FIXTURES, TRAINING browse, sell/tactics
   menu wrappers, JOB OFFERS / YOUR CAREER / End-of-season lists (no original counterpart
   proven — confirm against the running original, else drop).
   **YOUR CAREER: CLOSED 2026-07-16 s4** — original = MANAGER HISTORY, witnessed live
   and rebuilt frame-true (0px both states; promanager_career_screens_re.md).
   **JOB OFFERS: CLOSED 2026-07-16 s5** — original = OFFERS SELECTION, witnessed live
   and rebuilt frame-true (0px all five states incl. the club-detail popup + palette
   dim; the app's post-sack mount uses the witnessed chrome, original mid-career
   surface still unknown). End-of-season list remains a flagged substitute (the
   0x25aa60 directors'-report text engine needs a season-end witness).
2. Wire the orphaned TRUE screens: SquadScreen (PLANTILLA) into the hub where the
   original puts it; fix opponent (RIVAL) to a VERRIVAL port, not the DB browser.
3. Port the missing original screens B2 (evidence-first, one at a time: EMPAREJAMIENTOS,
   NOTICIAS, ENTRENAMIENTO, TACTICAS, VERRIVAL first — they sit behind live hub buttons).
4. Close the MatchSim invented-fallback + replace fabricated commentary with the stat
   engine's real event vector (B3).
5. Repair the parallel-stream breakage (B4) or revert the untracked menuicons stream.

## B7 — SQUAD MANAGEMENT + PLAYER INFORMATION contract flow (2026-07-02, open)
Wiring done (B5-2): OPPONENT -> VIEW RIVAL (RivalScreen), PLAYERS -> SQUAD MANAGEMENT
(SquadScreen). Title now the real "SQUAD MANAGEMENT" (@0x65f098). REMAINING source-gaps
(evidenced by walkthrough run-1 frame `077_154612` = the real SQUAD MANAGEMENT):
- **Contract columns. SHIPPED 2026-07-02** (frame-077 geometry + colours; see
  squad_screen_re.md "True columns" + squad_number_re.md). **N°** = the newly decoded
  per-player squad number (EQUIPOS byte after the photo-id u16; frame truth 19/19 for
  Man Utd incl. Berg 21 off-frame + Babb 6 extended-block cross-check); shown only for
  clubs whose stored set is individuated (18 of 92 English clubs), `-` otherwise — the
  original's pad-club display is UNRESOLVED, never invent a renumbering. Row order =
  reverse record order per section (decoded from the frame; ability sort removed).
  AV=`_avg_of`, LOAN=`on_loan` YES/NO, WAGE=`Contract.yearly(current_weekly)`,
  YEARS=`contract_term|contract_years` (term stamped at every deal site in Career).
  **REMAINING GAP: MO** — PM98 morale is a dynamic save-game value; the app has NO
  morale model and no static attr matches the frame's MO (79-99). Renders `-`; do NOT
  fabricate it. (Owner 2026-07-02: morale IS in MANAGER.EXE — RE it when convenient,
  after the offers flow.)
- **PLAYER INFORMATION actions.** DONE 2026-07-02. The overlay's real **RENEW / TRANSFER /
  SACK / OK** row (source rects FUN_00526a60, card-local RENEW(85,325,104,25) /
  TRANSFER(196,..) / SACK(307,..) / OK(429,..,52,25)) is now live on the manager's own
  squad player: RENEW = `Career.renew` (meet his demand), TRANSFER = `Career.toggle_listed`
  ("placed on the transfer market"), SACK = new `Career.release` (compensation of contract;
  he joins the free-agent pool; squad-floor + keeper-min + on-loan guards). Card is
  read-only (buttons hidden) for another club's player. CLUB FEE label fixed (was VALUE).
  REMAINING (narrowed 2026-07-03): the TEAM OFFER accept/refuse screen is BUILT —
  TeamOfferScreen at pixel parity 0px vs run-3 086/088 (see team_offer_re.md), wired
  to CURRENT OFFERS band taps AND popped from CONTINUE after match day (frames
  085->086); the interim ACCEPT/REFUSE browse dialogs are gone. The signing message
  raises the REAL hub alert box (093/094/149; alert_box_re.md) — parity-locked
  2026-07-03. **FICHA CLAUSES + YEARS|LEFT: SHIPPED 2026-07-03** — the whole card
  rebuilt frame-baked to 0px vs run-1 081/084 incl. the CLAUSES column (checked/
  washed boxes, figure labels, progress sub-lines), the YEARS|LEFT boxes, the
  FUN_00526a60 button row with the held-OK ring, and the SquadScreen palette-dim
  (exact alert LUT, 081-vs-082). See ficha_card_re.md. Still open there: FICHA
  RATING formula (parity-excluded), non-EU KIND evidence, matches-to-renew target.

# §C — LIVE SIDE-BY-SIDE PARITY RUN, MANAGER LEAGUE (2026-07-16, session 6)

> Method: BOTH builds driven live on this box with identical clicks (both render
> 640x480, so one coordinate script drove both). Original: wine harness
> (tools/re/wine/boot.sh), NEW Manager-League career, TOTAL level, "mwm" @ Bolton W,
> played to in-season Week 3. App: current tree (@0683969), same career start, played
> to Week 2. Frames: `screenshots/parity-run-2026-07-16/{orig,app}/` (68 + 58,
> gitignored). Every claim below was verified against code before being written.

## C0 — Handoff question RESOLVED: MANAGER INFO button is MODE-gated
Original BOARD OF DIRECTORS witnessed in Manager League at BOTH preseason (orig/52)
AND in-season Week 3 (orig/79): **NO MANAGER INFO button in either**. Promanager wk1
had it (s4). ⇒ the button is Promanager-only, not phase-gated. The app (no button in
Manager League) is CORRECT as-is; gate any future MANAGER HISTORY entry on mode.

## C1 — Original screens with NO working app counterpart on this path (witnessed)
| # | original screen (frame) | app today (verified) |
|---|---|---|
| 1 | GOAL SCORERS graph+list (orig/12) | button painted, dead — no screen, no code refs |
| 2 | INSURANCE per-player (orig/17) | documented no-op (InjuriesScreen.gd:152) |
| 3 | SCOUT search (orig/35) | "sourced but not yet wired" (TransferScreen.gd:222) |
| 4 | OFFERS foreign-league map (orig/36) | same — unwired (TransferScreen.gd:222) |
| 5 | GROUND IMPROVEMENTS panel: SEATS/CAR PARK/FACILITIES/SERVICES offers (orig/21) | invented "GROUND WORKS" text browse w/ invented prices (app/56) — B5-1-class stand-in still live |
| 6 | SAVE GAME 8-slot GAME/PLAYER dialog (orig/54) | slotless toast "Game saved" (app/59) |
| 7 | TEAMS IN CHAMPIONSHIPS (orig/06) | never shown (preseason → hub directly) |
| 8 | START OF SEASON objectives table (orig/71) | never shown on season entry |
| 9 | CHARITY SHIELD trophy screen (orig/70) | never shown (no Charity Shield event at all) |
| 10 | Pre-match XI-vs-XI photo roll (orig/62-63, LINE-UPS ON) | never shown |
| 11 | In-match MAN-TO-MAN MARKINGS (orig/66) | all 4 in-match doors dead: MatchScreen.gd:219 `_:pass` (LINE-UP/TACTICS/MAN-TO-MAN/STATISTICS) |
| 12 | MATCH OPTIONS before EVERY match (orig/60) | screen exists but only via hub OPTIONS icon; career CONTINUE jumps straight into BRIEF (Main.gd:1015-1018, persisted mode) |

## C2 — Functionality divergences (witnessed + code-verified)
- **SKIP semantics wrong**: original SKIP advances ONE rival slot (4 individually
  skippable dates); app SKIP == CONTINUE, ends the whole picker
  (PreseasonScreen.gd:264-266 `"skip","continue": preseason_done.emit`). You cannot
  schedule a friendly on a later slot while skipping an earlier one.
- **STALE-CAREER BLEED**: fresh mwm/Bolton career, TRANSFER MARKET rendered a previous
  session's career ("asdf" / Manchester Utd / Premier Week 3 / 23 Aug header) with its
  transfer pool (app/33). State isolation bug between saved careers/screens.
- **FT hand-off**: at 90:00 the bottom button still reads KICK OFF (original relabels
  CONTINUE, orig/68); pressing EXIT silently skips the FULL TIME read-out entirely.
- **FULL TIME read-out broken visually** (app/67 vs orig/69): score boxes overdraw the
  name bar, possession row hidden, MAN OF THE MATCH name EMPTY, stadium panel blank on
  away matches (original FILLS it — Villa Park data shown at Bolton's away friendly, so
  "honest blank for away" in Main.gd:1460 is itself a parity gap), header chip stuck
  "Preseason/Preparation" in Week 1.
- **BRIEF feed**: goals-only (known B4b engine gap) BUT format also diverges: names
  truncated w/o club ("Goal by Milose" vs "Goal by Milosevic (Aston Villa)"), kick-off
  line format differs, possession bar static 50/50 all match (original live).
- **Fixture calendar invented**: app = naive weekly-Saturday round robin (Man U W1,
  Barnsley W2...); original = real 97-98 calendar (Southampton 9 AUG, BYE-gap, midweek
  Thu 28 AUG, Mon 1 SEP...) (app/13 vs orig/13). Known PCF5DAT-dates gap, now witnessed.
- **Initial league table alphabetical** + LEADER panel pre-filled w/ Arsenal shirt;
  original seeds prior-season order (Man Utd top, Bolton 18) + EMPTY leader (app/11 vs
  orig/11). Hub badge shows "PL 5" vs original "PL 1"; app centre stack also inverted
  (own club TOP, no opponent-manager name, "AWAY" chip instead) (app/09 vs orig/07).
- **Contract/finance economics not source-true**: Ward fee £350k/wage £119,600/3yr/age 28
  vs original £50k/£15,000/2yr/27 (app/38 vs orig/38); squad wages all inflated;
  starting cash £5.4M vs £1,960,096; FINANCE pre-books season income (tickets £8.5M @
  1 Aug) vs original all-£0 preseason; invented line label "EUROPEAN CUP INCOME" vs
  source "U.E.F.A. CUP INCOME" (app/50 vs orig/50).
- **FINANCE is a single static PER-SEASON view**: PER WEEK / INCOME / EXPENSES / INC.+EXP.
  tabs all dead (verified clicks app/51-52); original defaults to PER WEEK with the
  week pager (orig/50). Balance graph has a white overdraw band.
- **Invented content**: 5 fabricated youth players at career start (orig youth list
  EMPTY, app/39 vs orig/39); staff hires posted as News-extra MARKET items (original
  posts none after identical hires, app/58 vs orig/53); staff-hire candidate pools/wages
  invented; GROUND capacity 35,000 vs 20,500, CAR PARK/PITCH rows empty, different
  stadium art (app/55 vs orig/20).
- **TEAM TACTICS overlay compressed**: option labels missing (SOFT/MEDIUM/AGGRESSIVE,
  ZONAL/MAN TO MAN, SHORT/LONG, OWN/MIDFIELD/OPPONENT), no OK button, close-X art at
  ~627,124 but hitbox at 528,120 (app/24, TeamTacticsScreen.gd:46) (orig/25).
- **Header state**: date card shows next-fixture date on sub-screens (original keeps
  current game date); header identity block shows fixture clubs on RESULTS (original
  keeps mwm/club); SQUAD MANAGEMENT manager-name bar empty; date card art squeezed on
  several screens (CURRENT OFFERS/YOUTH/NEWS).
- **Default-view diffs**: LINE-UP opens RATING (original PARAMETERS); STATISTICS blank
  cells (original renders "-" placeholders); TACTICS pitch banner "TACTICS 4-4-2"
  (original: club name); staff SIGN overlay opens PHYSIO tab (original TRAINERS);
  default XI/roles differ from EQUIPOS stored XI.
- **Name entry**: only the PLAYER-banner strip accepts typing; original also accepts
  after clicking the slot row. Name uppercased to "MWM" (original keeps "mwm").

## C3 — Confirmed working end-to-end in the app this run
New career (name/team/level) → preseason friendly + league weeks advance w/ autosave →
BRIEF match w/ real goal vector → FT read-out reachable (via the mislabeled button) →
hub date/phase advance → staff hire (assistant+scout) → contract card RENEW/TRANSFER/
SACK live → News extra populates → BOARD ROOM meters/loans/bonus (bonus 2 label reads
"for Champion"; original binds it to the club objective, "for Avoid Relegation" for
Bolton) → TRAINING/INJURIES/STATISTICS/TACTICS/PREDEF all mount frame-true.

## C4 — Suggested fix order (screen-parity first, per user's stay-true rule)
1. C2 stale-career bleed (state corruption).
2. C1 #7/8/9 season-flow screens (TEAMS IN CHAMPIONSHIPS, START OF SEASON, CHARITY
   SHIELD) + #12 MATCH OPTIONS into the career CONTINUE chain + #10 XI photo roll.
3. C1 #1-#6 missing hub sub-screens (GOAL SCORERS, INSURANCE, SCOUT, OFFERS map,
   GROUND IMPROVEMENTS, SAVE dialog).
4. C2 data parity: real 97-98 fixture calendar, prior-season table seed, EQUIPOS
   contract economics, starting cash, FINANCE per-week model.
5. FT read-out render fixes + in-match doors (need MAN-TO-MAN screen port).

## C5 — User-witnessed items (2026-07-16 late session; frame-verified before logging)
- **STAFF stars live-drift** (app/43 vs orig/45): original staff bars show few chunky
  gold stars right-aligned (Withnail ★★, Smith ★½); app renders more, washed, smaller
  stars overlapping the bar edge (Atkinson ~3½, Barton ~4½) + halo text style. The
  07-16 "STAFF wages 0px vs frame 121" gate passes on the BAKED state — the LIVE
  screen drifts. Pattern: 0px shot-parity ≠ live parity; verify by booting.
- **Hub geometry overflow** (app/19 vs orig/31): centre-circle bars (club/opponent/
  AWAY) are too wide, extend past the circle edge with shadows outside the frame;
  upper-left identity block is one oversized blue panel overflowing its chrome vs the
  original's two narrow grey bars. (On top of the C2 inverted-stack/content issues.)
- **BRIEF feed still goals-only**: was never actually fixed — the earlier fix made
  goal lines ride the REAL stat-engine vector (scorer+minute); the full
  shots/saves/runs/crosses/corners feed requires the M5 positional-engine port (B4b).
  Current rendering also truncates ("Goal by Milose", no club) though _honest_feed
  builds "Goal by %s (%s)" — column clipping bug (MatchScreen draw).
- **Goals credited to ONE side during BRIEF, corrected on the result page**
  (user-witnessed): engine-league path verified OK in code (MatchSim goal dicts carry
  credited `side`, MatchScreen._score_at splits by it; app/66 showed a correct 1-1).
  Candidate cause for the user's runs: `MatchCommentary.gd:129` `g.get("side", 0)`
  defaults EVERY goal to home when a path emits goal dicts without `side` — the FT
  read-out uses stored hg/ag so the final page "corrects". Reproduce, then fix the
  default to `scorer_side` fallback.
- **FT read-out stadium/capacity + MAN OF THE MATCH wrong/empty** — confirmed C2 item,
  user re-flagged; away stadium panel must FILL (original does), MoM name must render.
