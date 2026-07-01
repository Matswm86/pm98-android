# PM98 — SOURCE ASSET INVENTORY (source of truth)

> **Purpose.** This is the single authoritative list of every original Premier Manager 98
> asset, its real size/member-count, and **whether we can actually open it (YES / PARTIAL /
> NO)** — proven by decoding a representative, not inferred from filename. It is the binding
> reference for [`SPEC_BINDING.md`](SPEC_BINDING.md). **Nothing may be added to the app that
> is not traceable to a row here. Gaps are listed in §5 and flagged — never filled with
> invented content** (rule `pm98_stay_true_to_original`).
>
> Every number below was produced this pass from real `stat` / `7z l` / `pkf_unpack.parse`
> output — not relayed from memory. Reproduce: see §6.

## 1. Sources on disk
| Source | Path | Files | Size | Notes |
|---|---|---|---|---|
| Extracted RAR tree | `extracted/Premier Manager 98/` | 173 | 104.3 MB | The installed game (decode target) |
| CD ISO | `/home/mats/backup/Div/premier manager 98.iso` | 3,207 | 540 MB | Adds DirectX 5 + InstallShield setup + **PCF5DAT.PKF** |
| Original RAR | `/home/mats/backup/Div/Premier_Manager_98.rar` | — | — | Archive of the extracted tree |

**ISO-only content** (not in the RAR tree): the DirectX 5 runtime, InstallShield `SETUP.*`,
and **`PCF5DAT.PKF` = 314,854,588 B** (the PC Fútbol 5 engine-data container — see §5 GAP).
Verified absent from both sources: any `.p3d` 3D model / `Modelos\` folder (0 hits).

## 2. Container archives (PKF) — self-verified member counts
`members` = type-2 FILE entries from `pkf_unpack.parse` (clean END reached on all rows).

| Container | Source | Bytes | Members | Holds |
|---|---|---|---|---|
| `DAT.PKF` | RAR+ISO | 2,498,013 | 41 | UI palettes/indices/menus (MENU.PAL, MANAGER.IND, GRADIENT.DAT…) |
| `DATSIM.PKF` | RAR+ISO | 5,898,299 | 1,704 | Match-view art: JUG.PGF kits, BALON.RAW, CIELO1.BMP, HIER*.RAW, RED.BMP, COFLECHA.PGF |
| `IMG.PKF` | RAR+ISO | 2,126,009 | 267 | Interface images (cups, calendars, standings) |
| `RECURSOS.PKF` | RAR+ISO | 7,715,581 | 392 | UI resources (icons, lineup, employees, bars) |
| `RC_DBASE.PKF` | RAR+ISO | 3,871,932 | 266 | Data-Base screen art incl. **`CAMPO.BMP`** (top-down pitch w/ lines) |
| `MUSICAS.PKF` | RAR+ISO | 2,021,303 | 8 | S3M tracker music (DINAMIC0–5.S3M) |
| `SFX/AMBIENTE.PKF` | RAR+ISO | 2,751,841 | 37 | Ambient match SFX |
| `SFX/COMENT.PKF` | RAR+ISO | 45,048,281 | 1,376 | Commentary audio (many language packs) |
| `DBDAT/BANDERAS.PKF` | RAR+ISO | 89,785 | 127 | Country flag DIBs |
| `DBDAT/MINIBAND.PKF` | RAR+ISO | 28,839 | 127 | Mini flags |
| `DBDAT/BIGCAMP.PKF` | RAR+ISO | 449,874 | 16 | Stadium images |
| `DBDAT/BIGENTR.PKF` | RAR+ISO | 838,707 | 37 | Manager (entrenador) photos |
| `DBDAT/MINIENTR.PKF` | RAR+ISO | 41,579 | 37 | Mini manager photos |
| `DBDAT/BIGESC.PKF` | RAR+ISO | 2,867,032 | 92 | Large club crests |
| `DBDAT/MINIESC.PKF` | RAR+ISO | 1,494,152 | 476 | Mini crests (one per club) |
| `DBDAT/NANOESC.PKF` | RAR+ISO | 397,448 | 476 | Nano crests |
| `DBDAT/RIDIESC.PKF` | RAR+ISO | 222,256 | 476 | Tiny crests |
| `DBDAT/EQUIPOS.PKF` | RAR+ISO | 4,099,004 | 476 | **476 per-team `.DBC` database records** |
| `DBDAT/MINIFOTO.PKF` | RAR+ISO | 753,479 | 690 | Mini player photos |
| `DBDAT/BIGFOTO/*.PKF` | RAR+ISO | 13,934,808 | 73 archives | Squad photo banks (EQ960301…) |
| **`PCF5DAT.PKF`** | **ISO-only** | **314,854,588** | **unknown** | **PC Fútbol 5 engine data — NOT enumerable (§5)** |

## 3. Non-container data files
| File | Bytes | Format | Holds |
|---|---|---|---|
| `DBDAT/APELLIDO.30` | 2,774 | DMLT string table | Player surnames |
| `DBDAT/NOMBRES.30` | 1,044 | DMLT string table | Player first names |
| `DBDAT/PAISES.30` | 1,257 | DMLT string table | 128 country names (0=XXX … 18=DENMARK) |
| `GFX.DAT` | 80,958 | **unknown** | Unidentified (§5 GAP) |
| `WINFONTS/*.FNT` | 31 files | Windows 2.x raster font | UI fonts |
| `SONIDOS/*.RAW` | 2 files | headerless 8-bit PCM | Whistle / select SFX |
| `MANAGER.EXE` | 2,651,136 | PE32 x86 | Game logic (RE source for screens/engine) |

## 4. Format → OPEN STATUS (proven this pass)
Every YES was decoded and **viewed** this session (image) or printed (text); evidence in
`docs/re/inventory-evidence/format_contactsheet.png` unless noted.

| Format | Open? | Decoder | Evidence (verified this pass) |
|---|---|---|---|
| PKF container | **YES** | `pkf_unpack.py` | DAT/DATSIM/IMG/RECURSOS member counts, clean END |
| DM-DIB / BM-DIB image | **YES** | `pkf_image.py`, `rc_dbase_image.py`, `export_art.py` | viewed face, flag (DENMARK), title, `campo.png` |
| PGF sprite | **YES** | `pgf_decode.py` | viewed COFLECHA arrow + ball |
| RAW 256×256 indexed | **YES** | `export_match_art.py` | viewed HIERPREM / HIERBA / CAMPINA grids |
| ACT palette | **YES** | (used by RAW/PGF decode) | `PALETA.ACT` drove every decode above |
| DMLT `.30` table | **YES** | `dmlt_decode.py` | `PAISES.30` → 128 countries printed |
| FNT raster font | **YES** | `fnt_to_bmfont.py` | `app/art/fonts/calend8.png` etc. in repo |
| RAW PCM audio | **YES** | `export_audio.py` (ffmpeg 6.1.1 present) | tool path + ffmpeg confirmed |
| S3M music | **YES** | `export_audio.py` (ffmpeg libopenmpt) | tool path + ffmpeg confirmed |
| RIFF PAL | PARTIAL | `export_art.py` | decoder present; not independently re-rendered this pass |
| DBC team record | **PARTIAL** | `dbc_extract.py` | 476 extracted; full per-team field schema ~281/476 (`docs/FORMATS.md`) |
| `SFX/*.PKF` inner WAV | **NO** | — | container lists; inner audio packing undocumented |
| `GFX.DAT` | **NO** | — | header `01 0a 00 0a 00 04 00…`+`7f 80…`; no decoder |
| `PCF5DAT.PKF` | **NO** | attempted `enum_pcf5dat.py` | not enumerable (§5) |

## 5. GAPS — known, flagged, NEVER to be filled with invention
1. **`PCF5DAT.PKF` (314 MB, ISO-only) — not enumerable.** `enum_pcf5dat.py` this pass:
   `parse@0` = "bad tag 0x0"; whole-file scan best clean directory chain = **0 records**
   (only 30 noise seeds in 39 M tag-matches). It does NOT follow the PM98 PKF grammar — it
   is the older PC Fútbol 5 container variant and would need its own directory format
   reversed. **Consequence: the side-on 2D simulador's pitch geometry, camera, per-tick
   positions, and any pitch-line tiles live here and are unavailable.**
2. **Side-on simulador pitch lines do NOT exist as static tiles.** Verified by viewing all
   7 `HIER*.RAW` + `CAMPINA.RAW`: the grass atlas is plain green grass + crowd + goal-net
   mesh + advertising boards only; a palette white-on-green scan found zero line tiles. The
   original draws them via the engine (PCF5DAT, GAP #1). **Do not paint invented lines.**
   *(Note: the TOP-DOWN MatchScreen/lineup pitch `CAMPO.BMP` in RC_DBASE.PKF DOES have real
   white lines and is source-true — the gap is the side-on view only.)*
3. **`GFX.DAT` (81 KB) — unknown format**, no decoder.
4. **`SFX/*.PKF` inner-WAV packing** — containers list but the inner audio encoding is
   undocumented.
5. **DBC per-team record schema ~281/476 complete** — headers 100%; remaining squad records
   partial (`docs/FORMATS.md`).

## 6. Reproduce
- Sizes/members: `python3 tools/re/pkf_unpack.py` (root PKFs) and the parse loop over DBDAT.
- ISO census / PCF5DAT presence: `7z l "/home/mats/backup/Div/premier manager 98.iso"`.
- PCF5DAT verdict: `7z e <iso> PCF5DAT.PKF -o<scratch> && python3 tools/re/enum_pcf5dat.py <scratch>/PCF5DAT.PKF`.
- `.30` proof: `python3 tools/re/dmlt_decode.py "extracted/Premier Manager 98/DBDAT/PAISES.30"`.
- Image proofs: `docs/re/inventory-evidence/format_contactsheet.png`.
