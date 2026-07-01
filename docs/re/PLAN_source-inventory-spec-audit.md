# PM98 — Source Inventory + Binding Spec + App Audit (anti-invention pass)

## Context
The PM98 Android port must be a faithful port of the real Premier Manager 98 (rule
`pm98_stay_true_to_original`). Recent sessions introduced invented content. The user has
drawn a hard line: **no more game logic until a verified source-of-truth inventory and a
binding spec exist**, every asset format must be proven openable (not inferred from
filename), and **gaps get flagged, never filled**.

Two inventions were already caught this session by opening the actual source:
1. The prior handoff + `docs/re/match_view_re.md` claim "white pitch-line tiles are in
   HIERPREM.RAW." **False.** Viewing `HIERBA.RAW` (generic) and `HIERPREM.RAW` (PM98 skin)
   shows they are the same atlas — grass + crowd + goal-net mesh + advertising boards, all
   plain-green grass, zero line tiles. A palette white-on-green scan across all 7 HIER*.RAW
   + CAMPINA found none.
2. `match_view_re.md` labels `CAMPINA.RAW` as "(pitch)." **Wrong** — it is the countryside
   skyline backdrop (trees, buildings, perimeter brick wall in horizontal strips).

Pitch lines in the original are engine-drawn from the unopened `PCF5DAT.PKF`, not a static
tile. The user chose: **pause + audit the app against the spec**, and **attempt PCF5DAT now**.

## Verified ground truth (from real stat/7z/code reads + image-viewing this session)
- **Sources:** RAR tree `extracted/Premier Manager 98/` = 173 files / 92 PKF (~8,800 members).
  ISO `/home/mats/backup/Div/premier manager 98.iso` = 3,207 files; adds DirectX5 +
  InstallShield + **`PCF5DAT.PKF` = 314,854,588 B at ISO root (never opened)**.
- **Openable (proven):** PKF, DM-DIB, BM-DIB, PGF, DMLT `.30`, FNT, RAW (audio + 256×256
  indexed), ACT palette, S3M, RIFF-PAL. **Partial:** DBC (headers 100%, full per-team record
  schema ~281/476). **Unknown / not opened:** `GFX.DAT` (81K), `SFX/*.PKF` inner-WAV packing,
  `PCF5DAT.PKF`.
- **No inventory doc and no binding spec exist.** `assets/game_db.json` (4.3MB) is the decoded
  DB; 29 `docs/re/*.md` cover screens/engine; `docs/refs/*.pdf` = community field references.
- `.p3d` 3D models absent from BOTH ISO and RAR (verified) → HIGHLIGHTS 3D stub is honest.

## Plan

### Phase 0 — Enumerate PCF5DAT.PKF (user: "attempt now")
- Extract once from ISO without mounting: `7z e "/home/mats/backup/Div/premier manager 98.iso"
  PCF5DAT.PKF -o<scratch>` (314MB; confirm free disk first).
- **Reuse** `tools/re/pkf_unpack.py::parse(buf)` via a thin new wrapper `tools/re/enum_pcf5dat.py`
  that reads the extracted file and prints the member directory (name, offset, size, type).
  Do NOT modify pkf_unpack's hardcoded GAME scan; just import `parse`.
- Record the honest result: member list if it parses, or "directory did not parse cleanly →
  GAP" if it does not. If it parses, note whether any member looks like pitch/cesped/line art
  (decode one sample and LOOK — do not infer from name). Whatever the outcome, it is logged as
  fact in the inventory; no invention if it fails.

### Phase 1 — Source Inventory doc → `docs/re/SOURCE_INVENTORY.md` (new, source of truth)
One table enumerating every original asset, built only from real census output:
`asset/container | source (RAR / ISO-only / both) | bytes | members | format | OPEN STATUS
(YES / PARTIAL / NO) | evidence (decoded artifact path or decoder file:line)`.
- Cover the 92 PKF containers + their member counts, `.30` tables, GFX.DAT, RESOURCE.001,
  MUSICAS/SFX, WINFONTS, DBDAT/* (badges/flags/photos/EQUIPOS 476 DBC), and PCF5DAT (Phase 0
  result).
- A dedicated **GAPS** section listing every not-fully-decoded item: GFX.DAT, SFX inner
  packing, PCF5DAT outcome, DBC record schema (~281/476), `.p3d` absent, pitch-line source.

### Phase 2 — Per-format open-verification (prove "can actually open: yes/no")
- Actually open **one representative of every format** and save a decoded/viewed artifact under
  `docs/re/inventory-evidence/` (PNG for images/sprites/atlases, text dump for `.30`/DBC, OGG
  note for audio). **Reuse** existing decoders: `pkf_unpack.py`, `pkf_image.py`, `pgf_decode.py`,
  `dbc_extract.py`, `dmlt_decode.py`, `rc_dbase_image.py`, `fnt_to_bmfont.py`, `export_*.py`.
- For each, log YES (artifact viewed) / PARTIAL / NO into the inventory's OPEN STATUS column.
  Formats that fail (GFX.DAT, SFX packing, possibly PCF5DAT) are logged NO — never substituted.

### Phase 3 — Binding spec doc → `docs/re/SPEC_BINDING.md` (new, the authority)
- Consolidate the real, source-traceable model into one reference: leagues/tiers, club list +
  counts, player record fields (VE/RE/AG/CA/RM/RG/PA/TI/EN/PO + media/birth/pos), the per-screen
  layouts (link the 20 `*_screen_re.md` docs + `game_db.json` schema), and the asset→screen map.
- Each entry cites its source file. Add the **binding clause** verbatim: *"No object, screen,
  mechanic, or asset may be added to PM98 Android unless it traces to a real file listed in
  SOURCE_INVENTORY.md. Gaps are listed here and flagged — never filled with invented content."*
- A **KNOWN GAPS** section mirrors Phase 1 gaps so future work flags, not fills.

### Phase 4 — Audit current app vs spec → `docs/re/APP_VS_SPEC_AUDIT.md` (new, findings only)
- Cross-check the shipped app against the inventory+spec and report **every divergence/invention**:
  - `app/art/**` (esp. `app/art/match/*`) vs real decoded source — flag any synthesized art.
  - `assets/game_db.json` vs decoded DB — flag any field/value not traceable to EQUIPOS/.30/DBC.
  - `app/scenes/**`, `app/data/**` vs the per-screen RE docs — flag invented screens/mechanics.
  - The already-found inventions: the HIERPREM pitch-line claim and CAMPINA="pitch" mislabel in
    `match_view_re.md`; list as corrections to make.
- Output a ranked findings list (invention / unverified / source-true). **No fixes in this pass**
  — the user reviews first.

## Critical files
- New: `docs/re/SOURCE_INVENTORY.md`, `docs/re/SPEC_BINDING.md`, `docs/re/APP_VS_SPEC_AUDIT.md`,
  `tools/re/enum_pcf5dat.py`, `docs/re/inventory-evidence/` (decoded sample artifacts).
- Reuse (no rewrite): `tools/re/pkf_unpack.py` (`parse`, `deobf_name`), `pkf_image.py`,
  `pgf_decode.py`, `dbc_extract.py`, `dmlt_decode.py`, `rc_dbase_image.py`, `fnt_to_bmfont.py`,
  `export_*.py`; `docs/FORMATS.md`, `docs/re/*.md`, `assets/game_db.json`, `docs/refs/*.pdf`.
- Correct (Phase 4 flags, not silent edits): `docs/re/match_view_re.md` pitch-line + CAMPINA lines.

## Verification
- **Inventory:** every row's bytes/member-count reproducible from `stat` / `7z l` / `parse()`;
  every `OPEN: YES` has a viewed artifact in `inventory-evidence/`; every `NO`/`PARTIAL` names why.
- **PCF5DAT:** re-running `enum_pcf5dat.py` reproduces the same member list (or same clean failure).
- **Spec:** spot-check 5 random spec entries (a league, a club, a player field, a screen layout, an
  asset) each resolve to a cited real source file.
- **Audit:** each finding cites app file:line + the source it should match (or "no source → invention").
- No `.import`/binary commits; docs + tools only. Repo not in wmcommit.sh / no pre-commit:
  `rtk proxy git ...`. Nothing committed until the user reviews the audit.

## Out of scope this pass (deferred, flagged not built)
- WATCH sprite 8-direction facing-order fix (verify-then-fix later).
- Any pitch-line rendering (blocked on PCF5DAT outcome; never invented).
- Fixing the inventions the audit finds (user reviews findings first).
