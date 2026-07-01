# PM98 — BINDING SPEC (the authority)

> **BINDING CLAUSE.** No object, screen, mechanic, or asset may be added to PM98 Android
> unless it traces to a real file listed in [`SOURCE_INVENTORY.md`](SOURCE_INVENTORY.md) or a
> reversed function in `MANAGER.EXE` cited here. **Gaps are listed in §5 and flagged — never
> filled with invented content.** When source is missing, the app must show the honest gap
> (omit / neutral placeholder), not a fabricated value. (Rule `pm98_stay_true_to_original`.)
>
> Every row cites its source. This doc consolidates the 29 `docs/re/*.md` RE notes + the
> decoded DB into one reference; it does not introduce any new fact.

## 1. Game identity (from `assets/game_db.json` meta + `docs/FORMATS.md`)
- Premier Manager 98 (Dinamic Multimedia / Gremlin Interactive), season **1997-98**.
- Engine family: PC Fútbol 6 / Dinamic OPTIMUM (PM98 Spanish = same family) — `docs/FORMATS.md:146`.
- DB reverse-engineered from `DBDAT/EQUIPOS.PKF` (owned game files).

## 2. League / club structure (decoded — `docs/FORMATS.md`, `game_db.json`)
| League id | Name | Country | Tier | Clubs |
|---|---|---|---|---|
| `eng_prem` | Premier League | England | 1 | 20 |
| `eng_div1` | Division One | England | 2 | 24 |
| `eng_div2` | Division Two | England | 3 | 24 |
| `eng_div3` | Division Three | England | 4 | 24 |

- **476 clubs total** (92 English in the 4 tiers above + 384 international). English ids:
  `english_id == 301 + (position-38)`, pos 38 = Blackburn (`docs/FORMATS.md:91`). The game
  keeps Hereford in Div3 (per MANAGER.EXE's own league table — `game_db.json` meta note).
- **8,046 players**, nested under `clubs[].players`.
- International clubs: country tag is **best-effort inference** (meta `intlCountryMatchRate
  0.914`; 33 clubs left blank, not fabricated). See AUDIT finding A3.

## 3. Player record (per `clubs[].players[]`; fields cited to source)
| Field | Source |
|---|---|
| `name` / `legalName` | EQUIPOS DBC name cipher (pair-swapped alphabet, `docs/FORMATS.md:22`) |
| `birthYear` / `age` | DBC media/birth block (`docs/re/player_info_re.md`) |
| `pos` / `posFine` / `isGK` | demarcación decode (`docs/re/positions_re.md`) |
| `media` | u8 overall rating (`docs/FORMATS.md:205`) |
| `attrs` (10) | u8 each, 1-99, DBC attribute row (`docs/FORMATS.md:207`, `:296`) |
| `heightCm` / `weightKg` | FICHA physicals decode (`docs/re/ficha_physicals.md` / handoff) |
| `photoId` | BIGFOTO/MINIFOTO bank id (`docs/re/faces_re.md`) |
| `nationality` / `flagCode` | `DBDAT/PAISES.30` (128 countries) + `BANDERAS.PKF` |
| `kind` | role/type classification (verify exact source byte — see GAP §5.6) |

**Attribute legend** (Spanish DBC order → UK card label, *confirmed vs the in-game Babb
reference card*, `docs/re/player_info_re.md:55`):
`VE` velocidad=SPEED · `RE` resistencia=STAMINA · `AG` agresividad=AGGRESSION ·
`CA` calidad=QUALITY · `RM` remate=DRIBBLING · `RG` regate=HEADING · `PA` pase=PASSING ·
`TI` tiro=SHOOTING · `EN` entradas=TACKLING · `PO` portero=HANDLING. `RATING`=mean of 8
outfield attrs; `FITNESS`/`MORAL` are dynamic form, NOT static attrs (defaulted on load).

## 4. Screens (each app scene → its RE doc + source)
All 20 game screens are reversed from `MANAGER.EXE`; the app scene must match the documented
layout/rects, not an invented one.

| App scene | RE doc |
|---|---|
| `TitleScreen` | `docs/re/title_screen_re.md` |
| `MenuScreen` | `docs/re/menu_screen_re.md` |
| `DataBaseScreen` | `docs/re/database_screen_re.md` |
| `SeleccionScreen` (new-career club picker) | `docs/re/seleccion_screen_re.md` |
| `LineupScreen` | `docs/re/lineup_screen_re.md` |
| `SquadScreen` | `docs/re/squad_screen_re.md` |
| `TransferScreen` | `docs/re/transfer_screen_re.md` |
| `FinanceScreen` | `docs/re/finance_screen_re.md` + `finance_constants.md` |
| `StadiumScreen` | `docs/re/stadium_screen_re.md` |
| `DirectivaScreen` | `docs/re/directiva_screen_re.md` |
| `PlayerInfoScreen` | `docs/re/player_info_re.md` |
| `CupScreen` | `docs/re/cup_re.md` + `europe_re.md` |
| `StaffScreen` / `YouthScreen` | `docs/re/staff_re.md` / `youth_re.md` |
| `MatchScreen` / `MatchOptions` / `MatchSimulador` | `docs/re/match_view_re.md` + engine docs |
| `LeagueTableScreen` / `TacticsScreen` / `BrowseScreen` | (per engine/season docs) |

Match engine: `docs/re/EXACT_PORT_PLAN.md`, `match_engine_re.md`, `stat_match_engine_re.md`,
`MATCH_TICK_DRIVER_MAP.md` (bit-exact port, oracle-validated against MANAGER.EXE).

## 5. KNOWN GAPS — flag, never fill (mirrors `SOURCE_INVENTORY.md` §5 + app audit)
1. **`PCF5DAT.PKF` not enumerable** → the side-on 2D simulador's pitch geometry, camera, and
   per-tick positions are unavailable. `MatchSimulador` layout is an explicit app substitute.
2. **Side-on simulador pitch lines do not exist as source tiles** — never paint invented lines.
   (Top-down `CAMPO.BMP` lines ARE source-true.)
3. `GFX.DAT` (81 KB) unknown format.
4. `SFX/*.PKF` inner-WAV packing undocumented.
5. DBC per-team record schema ~281/476 complete.
6. Player `kind` exact source byte — confirm before relying.
7. International club country tags are best-effort inference (rate 0.914).
8. League table not yet computed from a season loop (`LeagueTableScreen.gd:20`).

## 6. Active de-invention record (already removed by prior passes — keep removed)
The DataBase/Directiva/Finance/Stadium screens previously shipped invented content that has
been removed and must NOT return: DataBase green list / row-banding / separators / subtitle
(`DataBaseScreen.gd`), Directiva "THE BOARD EXPECTS / YOUR RECORD" text, Stadium SEATS/STAND/
TIER readouts. See the AUDIT for the full list.
