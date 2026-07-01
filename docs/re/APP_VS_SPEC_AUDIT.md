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

### A3 — INFERENCE · `assets/game_db.json` international club country tags
Meta declares `intlCountryMatchRate 0.914`; 33 of 476 clubs have blank/unknown country (left
blank, **not fabricated**). The 351 present international tags are best-effort inference, not
all source-verified. **Action:** keep the meta flag; do not present inferred tags as decoded.

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

**Still open:** human-readable action label per kind (no name string in the engine — never
invent one) · `player+0x2bc` band-flag meaning · `JUGCAM.IND` internal layout/consumer ·
PGF header `h5∈{1,2}` · **camera POSITION-follow traced (s4):** eye = `matchctx+0x1614` vec3 +
fixed `0x500000` Z (`FUN_005f5740`); look-at = tracked actor `*(matchctx+0x43c)+4` / `*(+0x440)+4`,
fallback anchor `+0x1614` (`FUN_005f57e0`); zoom = clamped `FUN_005edfa0(+0x2874,0x1051e)`
(`FUN_005f5840`) — remaining GAP is *what* writes the anchor `+0x1614` (reads only in `.text` → a
per-frame vec3 copy from the tracked object; do not name it "ball" without the copy) · the exact
scene-graph vtable slot that sets `ecx`=a specific player (base-class stubs `0x605d96` obscure the
static path — likely needs a dynamic trace) · PCF5DAT 3/4 camera.

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
  inferences (A3, A4) or honestly-flagged gaps (A5, A6).
- Recommended next action (separate, user-approved): apply the A1/A2 doc corrections, then
  resume verified work (e.g. the JUG sprite facing-order check) under the binding spec.
