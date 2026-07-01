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
camera angle, plus the `kind` byte (INVENTORY §5, still unconfirmed) and the un-reversed PCF5DAT 3/4
tile-scroll camera. Until those land the WATCH sprites are a stylised slice (the baked 24 frames are
~1-2 real directions' phases, not 8 facings). Flag, do not paper over with another guess.
Open sub-gaps: `kind` semantics · `JUGCAM.IND` (55296 B) reader not traced · PGF header `h5∈{1,2}`
meaning · camera-angle source (`param_2+0xdc/0xde`).

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
