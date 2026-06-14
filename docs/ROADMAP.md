# PM98 Android — Native Clone Roadmap

Goal: a native English Android game that reads the **original PM98 assets**
(database, names, badges, photos, kits, stadiums) and reproduces the original
look + gameplay. For personal use on Mats's phone. Source files in `extracted/`.

This is a multi-month build. Phases are ordered so each one produces something
verifiable and nothing is wasted.

## Phase 0 — Asset reverse-engineering (the foundation)  [IN PROGRESS]
- [x] `.30` string tables cracked → English countries/first names/surnames
      (`tools/pm98_strings.py`, `assets/strings.json`)
- [x] PKF feasibility: confirmed **not encrypted**, extractable
- [~] `EQUIPOS.PKF` record layout → clubs, leagues, squads, player attributes → JSON
      - [x] 20 Primera 97-98 teams: capacity+founding (`teams_laliga.json`) AND full
            squads — 533 players, names+birthYear+media+10 attrs (`squads_laliga.json`,
            `tools/extract_squads.py`); verified vs real rosters, 0 garbled names
      - [x] ALL 476 detailed team records via the Copyright marker → `teams_all.json`:
            headers for all 476, **281 with full squads = 5654 players** (Spain, Italy,
            Germany, France, Portugal, NL, Scotland, S.America, …). Attrs reliable
            everywhere; media null for the 0x8c subtype (derive in-engine). See FORMATS.
      - [ ] English-league clubs: headers OK but squads sparse (bio-interleaved) — frame next
      - [ ] the ~876 directory teams beyond the 476 detailed records — separate format
      - capacity is the stored start value; **stadium expansion** is engine logic.
        **youth potential** is emergent (no stored rating) — see FORMATS.md.
- Scope decision: **full database, every league/club/player** (no trimming)
- [ ] PKF decompression algo → extract sprites
- [ ] Palette files (`paletas/*.dat`) → RGB palettes
- [ ] Image export: badges, flags, squad photos, faces, stadiums, kits → PNG
- [ ] `DAT.PKF`/`DATSIM.PKF` match-sim tables (ratings, formulas)
- [ ] Audio export (`.s3m` modules, RAW SFX)

Deliverable: `assets/` full of clean JSON + PNG + audio, plus a documented schema.

## Phase 1 — Data model + engine core (headless, testable)  [STARTED]
SCOPE (Mats, 2026-06-14): **replicate ALL original PC gameplay mechanics and
behaviours**, not a subset. Confirmed in-scope (each matches the original):
- [~] Match simulation engine — **plausible v1 shipped** (`scripts/MatchEngine.gd`
  + `scripts/SeasonSim.gd`): squad 10-attrs -> ATT/DEF/GK ratings -> per-match
  Poisson scoreline -> double round-robin season -> league table (3/1/0, GD/GF,
  promo/releg zones). Validated headless over 300 Premier seasons
  (`tests/test_engine.gd`): goals/game 2.57, home-win 46%, draw 25%, away 28%,
  champion ~76 / bottom ~32 pts, strong clubs finish high. NOT the original
  DAT.PKF math (still LZ-packed); tune toward it once cracked. Lower divisions
  pass the structural smoke (`tests/test_divisions.gd`) but their points spread
  is not yet calibrated (a 24-team champ can run hot ~110+). Wired into the UI
  (league view -> "Simulate season" -> final table).
- League structure: fixtures, tables, promotion/relegation, cups
- Transfers + transfer market behaviour
- **Scouting + recruitment** (scout reports, player discovery)
- **Youth players + youth development / "potential"** (emergent: age + 10 attrs +
  growth engine; PM98 has no stored potential number — see FORMATS.md)
- **Stadium expansion** (pay-to-expand capacity up to a limit; capacity is the
  stored starting value, expansion is engine logic)
- Finances (budget, gate receipts, sponsor, wages, debt)
- Training, injuries, contracts, board confidence, morale
- Save/load
- League/club/player data model loaded from extracted JSON
Deliverable: a headless sim that plays full seasons with realistic results, unit-tested.
Method for mechanic fidelity: derive behaviour from the editor manual + observed
data + (if needed) running the original under DOSBox/Wine for reference; cross-check.

## Phase 2 — UI shell (original look)
- Engine choice: Godot 4 (2D, easy Android export, GDScript) vs Kotlin/Compose.
  Decide at start of Phase 2 once we know asset shapes. Android builds go via
  **GitHub Actions CI**, never local gradle (per workspace rule).
- Recreate the original screens (office, squad, tactics, league table, match view)
  using the extracted original sprites → identical visuals
- Touch-friendly navigation over the original mouse-driven menus
Deliverable: installable APK with original graphics, wired to the engine.

## Phase 3 — Match presentation + polish
- Match-day visuals/commentary, audio, transitions
- Balance pass vs original behaviour
Deliverable: full playable game on the phone.

## Risks / unknowns
- PKF decompression: if the algo is non-trivial, `Dbasewin.exe` (the shipped DB
  editor) and the community PM-editor scene are references.
- Match-engine fidelity: matching the original formulas exactly is the hardest
  part; first target is *plausible*, then tune toward original.

## Working rules
- `extracted/` and `assets/` are gitignored (derived from owned game files;
  personal use only, not for redistribution).
- Each tool is standalone Python, verifiable against the real bytes.
