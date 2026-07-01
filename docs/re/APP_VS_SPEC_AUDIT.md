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

### A7 — GAP · `app/scenes/MatchSimulador.gd:474-482` `_facing()` frame-index→compass order UNVERIFIED
Verify-half done 2026-07-01: decoded + **viewed** JUG.PGF row-0 frames 0..7 (4211 frames total;
row-0 cell dims `20,16,12,12,12,16,20,20`). They ARE 8 distinct body rotations — frame 0 is
front/face-visible, frames 6-7 show the back of the head (facing away), 2-4 are narrow side
profiles. **But** the width/pose distribution (wide at 0, narrow clustered at 2-4, wide at 6-7)
does NOT match a clean 45°-per-step compass rotation, so `_facing()`'s assumption "frame 0 = down
(+y), each +1 = +45°" is **not source-confirmed**. The true frame-index→direction mapping is the
engine's own sprite-selection LUT (MANAGER.EXE / PCF5DAT), not yet reversed. **Action:** do NOT
apply an invented frame remap; fix is blocked on reversing the sprite-index function. Evidence:
`scratchpad/jug_row0_facings.png` (regenerable from DATSIM.PKF).
**RE lead (candidates, not yet confirmed):** in `docs/re/move/`, the fns that both call the
`FUN_0059*` `simulador.pgf`/sprite-loader region AND do direction quantization (`& 7` / `* 8`):
`FUN_005a4600`, `FUN_005a65a0`, `FUN_005ac1a0`, `FUN_005adc60`, `FUN_005adfc0`, `FUN_005b0040`,
`FUN_005b73a0`. Reverse whichever indexes the JUG bank by an 8-way direction to recover the true
order before touching `_facing()`.

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
