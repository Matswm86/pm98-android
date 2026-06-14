# Premier Manager 98 — File Format Notes (reverse-engineered)

Source copy: **Dinamic Multimedia** Iberian release (multilanguage). Data tables
are stored **in English** (verified: countries, first names, surnames all decode
to English). The EXE carries ES/CA/IT/FR UI/error strings; the game *database* is
English. Publisher string in plaintext inside `EQUIPOS.PKF`:
`Copyright (c)1996 Dinamic Multimedia`.

Build target: **native English Android clone** that reads these original assets.

## 1. `.30` string tables — SOLVED ✅
Files: `DBDAT/PAISES.30` (countries), `NOMBRES.30` (first names),
`APELLIDO.30` (surnames).

Container:
```
offset 0   : 'DMLT' magic (4 bytes)
offset 4   : uint32  (size-ish field)
offset 8   : uint32  record count
offset 12  : stream of records, each [uint16 len][len bytes]
```
Cipher (pair-swapped alphabet, A=0):
```
forward  letter_index L -> code = L if L even else L+2
         (A=0, B=3, C=2, D=5, E=4, F=7, G=6, ... Z=27)
decode   each byte b -> alphabet[b & 0x1F]; code 1 = space, 26 = apostrophe
```
The **first byte** of every record carries a `+0x20` start flag (removed by the
`& 0x1F` mask). Examples: `20 05 00 0c`→ADAM, `29 08 02 0a 04 18`→HICKEY.

Decoder + JSON export: `tools/pm98_strings.py` → `assets/strings.json`
(128 countries incl. `XXX` sentinel, 148 first names, 327 surnames).
Known cosmetic quirk: byte `0x4f` in two multiword country labels renders as `N`
("REP. OF IRELAND", "NORTH. IRELAND") — fix in post.

## 2. `.PKF` packed files — NOT encrypted, decode pending
16-byte header: `01 XX XX XX XX XX XX XX [30 94|63 1f] 2a 43 f8 b4 1e f1`.
The `2a 43 f8 b4 1e f1` tail is constant across all PKFs (format signature).
Byte 0 = `0x01` (version).

Entropy (bits/byte) tells the story — none are encrypted:
| file            | entropy | nature |
|-----------------|---------|--------|
| EQUIPOS.PKF     | 5.26    | team/player DB, plain records, **cipher text fields inline** |
| IMG.PKF         | 5.74    | indexed-color sprites (plain, per S4) |
| RECURSOS.PKF    | 6.33    | UI graphics/resources |
| BANDERAS.PKF    | 6.34    | flag sprites |
| DATSIM.PKF      | 4.41    | **match-VIEW sprites, PLAIN** (H 2.7-4.4, ~50% 0x00, 00/FF runs) |
| DAT.PKF         | 7.77    | **the ONE genuinely packed file** (uniform H~7.5, zero strings) = packed gfx/resources |

CORRECTION (S6 2026-06-15, verified vs bytes): earlier notes called DAT.PKF
"match-sim data" and assumed an LZ packer for the image PKFs. Wrong on both:
- The image/badge/photo PKFs are **plain indexed bitmaps** (S4 cracked them); no
  LZ involved. `paletas/*.dat` don't exist as loose files (palette is inline,
  DAT.PKF@0x5ca).
- `DATSIM.PKF` ("DAT-SIM") is **not compressed** (entropy 2.7-4.4) — plain match-
  view sprite data, decodable like EQUIPOS.
- `DAT.PKF` is the only file with uniform ~7.5 entropy + no ASCII = genuinely
  packed, but it holds **graphics/resources, not match formulas**.
- The **match engine is compiled x86 code in `MANAGER.EXE`** (2.5MB PE32), with
  embedded constants in plaintext (e.g. "255.000 for every draw match / 510.000
  for every match won", `img\partido\*`, `img\goleadores\*`, "MAN OF THE MATCH").
  There is NO decodable "match math" data file. Engine fidelity = behavioral
  replication and/or static RE of MANAGER.EXE, NOT unpacking a PKF.

## 3. `EQUIPOS.PKF` record layout — IN PROGRESS
Contains clubs, leagues, squads, player attributes + an English bio/commentary
text section. NOT encrypted (entropy 5.26). Confirmed content (full international
DB, English): English divisions (Man Utd, Liverpool, Arsenal, Chelsea, Leicester,
Blackburn, Sheffield Wed, Nottm Forest, Everton, Middlesbrough...), Scottish
(Rangers, Celtic), Italian (Inter, Milan), Spanish (Barcelona, Real Madrid,
Atletico, Deportivo, Sociedad, Betis, Celta...), German, South American.

Map so far:
- bytes 16..~232: sparse global header (mostly zeros).
- ~offset 237+: a **20-entry multi-level block index**, 38-byte stride, constant
  `02 9a 91 9a be 5f 68 [idlo][idhi] 31 54 41 bb ef af a2 e0 fa df a3 e8 00*5
   <u32 dataOffset><u32 size> 01 00 00 00`. `idlo` groups segments (0x73,0x72,0x71,
  0x70,0x6a...), `idhi` increments within a group. Within a group, dataOffset chains
  by size (e.g. 18384 +2159 → 20543 +2129 → 22672...). The 0x73 group's offsets are
  large (373248+) and point to the English bio/commentary segment; the 0x72/0x71
  groups point to low offsets (~18k+). So the DB is segmented and per-team records
  are NESTED inside these blocks — NOT a flat team table. This layered index is the
  core thing left to fully decode. Some sizes exceed EOF → likely uncompressed-size
  fields (segments may be packed); reconcile before trusting offsets.
- team block example (BARCELONA @~1500): short name, stadium ("CAMP NOU"), full
  name ("CLUB BARCELONA"), then a run of u16 attribute fields, then the squad.
- player record: surname (low-byte cipher) + first name (low-byte cipher) +
  display name (base-0x20 cipher, e.g. "FERRER LLOPIS") + binary attribute block.
- ~offset 1,000,000+: large English **player-biography / commentary** text section.

TODO field IDs (validate, don't guess): stadium capacity + **expansion tiers**,
**youth-squad potential (CA/PA)**, player position/age/skills/value/wage/contract,
club finances, league/division assignment.

### Schema-mapping method
`Dbasewin.exe` is the game's own DB editor and yields the field VOCABULARY via
static strings (already harvested): CAPACITY, AGE, BIRTH DATE/PLACE, INJURY,
"Youth player", BUDGET, GROUND, SPONSOR, the 4 divisions, full position list.

**Wine GUI oracle attempt (2026-06-14): FAILED — do not retry blindly.** Wine 9.0
runs Dbasewin.exe (window appears, process alive) but it renders **fully black**
to the X framebuffer (DirectDraw/MFC offscreen paint). Tried: default mode, GDI
ddraw renderer override (`HKCU\Software\Wine\DirectDraw renderer=gdi`), and
virtual-desktop (`explorer /desktop`). All black; `scrot` captures 0 non-dark px.
Even if rendered, GUI navigation would be blind via xdotool. Parked.

**Active method = cross-validation against the bytes** (no GUI): frame the team /
player record tables, then identify each field by matching values across ALL
records to known ground truth (capacity rank-order, ages 16-40, position enum,
nationality index into PAISES 0-127). Validate, never guess single values.

### Existing-tools research (Option 3, 2026-06-14) — engine identified
This is the **PC Fútbol 6 / Dinamic OPTIMUM engine** (PM98 Spanish = same family).
Open community editor: `github.com/jandro996/EditorPCFutbol6` (compiled .NET, no
source published; ships manuals). Community hub: pcfutbolmania.com.
- `EQUIPOS.PKF` = a packed container of per-team **DBC** records, keyed by the
  team-ID scheme below. The editor unpacks PKF → `DBDAT/<pkfname>/eqXXNNNN` DBCs
  and regenerates "punteros" (field pointers) automatically — so the byte-offset
  map is internal to the editor, NOT published. Offsets still come from
  cross-validation (Option 1).
- Confirmed editable field set (from the help file): team name, long name,
  manager, **stadium, capacity, founding year**, players, **youth (Juveniles)**,
  free agents. Matches our targets.
- **Team-ID directory obtained + VERIFIED** against our EQUIPOS (top clubs all
  match; misses are accent/short-form artifacts): `assets/pcf_team_directory.json`
  (1352 teams). England IDs 301-3331 (124 clubs), Scotland 1251-1272 (22).
  Special slots: 9950 Free Agents, 9955-9958 Youth (ESP/ENG/ITA/ARG), 9900-9903
  "Stars". The `EQ9603xx` photo files are keyed by these IDs.
- `assets/pcf_country_directory.json` (99 entries). NOTE discrepancy: our
  `PAISES.30` has 128 countries vs the doc's 99 → our build may differ slightly
  from stock PCF6; confirm the exact roster by parsing EQUIPOS records directly.
- Reference docs saved under `docs/refs/` (Punteros_Equipos.pdf,
  Punteros_Paises.pdf, Manual_Editor.pdf, Ayuda_Editor.chm).

### Team record (DETAILED) — DECODED ✅ (`tools/parse_equipos.py`)
The index (38-byte entries, SIG `9a 91 9a be 5f 68`) carries u32 dataOffset @ +26
and u32 size @ +30 (earlier +25 read was off-by-one). It lists **20 detailed
records = the Spanish Primera División 1997-98** (Barcelona…Salamanca), chained
1458 → +size → 3421 → ... → 43115.

Per-record layout (verified across all 20):
```
"Copyright (c)1996 Dinamic Multimedia"  (ASCII, 36 bytes)
[1 flag byte] [5 header bytes 03 03 02 00 01]
[u16 len][cipher name]      e.g. "REAL MADRID C.F."
[u16 len][cipher stadium]   e.g. "SANTIAGO BERNABEU"
[u16 len][cipher full name]
[u16 len][cipher manager]   (entrenador)
... numeric block ...
  capacity : u32 @ (foundingYear_offset - 12)   <- CROSS-VALIDATED vs real stadiums
  founding year : u16        (Barcelona 1899, Madrid 1902, Athletic 1898 — all real)
  then default ratings template (66,42,66,88...) + per-team prestige u16s
... then the squad (player records) ...
```
Verified capacities: Camp Nou 108428, Bernabéu 104779, Calderón 56500, Mestalla
49100, Espanyol/Montjuïc 55000, Betis 47500, Celta 31990, etc. (u32, so the two
>65535 confirm width). Output: `assets/teams_laliga.json`.
Accent bytes (0x88=É,0x9b=Ú,...) → finish the map for clean display (cosmetic).

### Player (squad) record — FULLY DECODED ✅ (`tools/extract_squads.py`)
Squad follows the team fields, players **sorted by position** (GKs first). Full
per-player record layout (forward-parsed, verified vs the real 97-98 squads):
```
[3-byte player header]              (tag/flags; not yet decoded, just skipped)
[u16 len][shortname cipher]         common/display name, e.g. "FIGO" "JAVI NAVARRO"
[u16 len][fullname  cipher]         legal name; may pack "LEGAL<0x4d>COMMON",
                                    e.g. "LUIS FILIPE MADEIRA CAEIRO<sep>FIGO"
[variable padding + 6 field bytes]  (nationality/position/number/value? — TODO)
birth year : u16                    (verified: Hesp 1965, Baía 1969, Busquets 1967)
[flag/squad byte, high bit set 0x80+]
media : u8                          (overall rating)
10 attributes u8 each, in order:
  VE velocidad, RE resistencia, AG agresividad, CA calidad, RM remate,
  RG regate, PA pase, TI tiro, EN entradas, PO portero
01  terminator
```
**The robust anchor** = birth year u16 in 1950-1983 immediately followed by a byte
>=0x80 (the squad flag) + sane media/attrs/term. Parsing is anchor-driven: for each
anchor, names are forward-parsed (exact length prefixes) from the previous record's
end, validated by the anchor as an alignment oracle. CROSS-VALIDATED: 3 GKs (sorted
first) have PO 85/80/90, outfielders PO < 26. Attribute names from the editor manual.

**Name cipher details (this is the keystone for ALL string fields):**
- letters: `ch(b)=alphabet[b&0x1f]` (pair-swapped, A=0); `0x01`/`0x41`=space, `0x4f`='.'.
- accented letters: `byte = 0x80 | (0x20 word-start flag) | accent-code`; clear bit 5
  then map base: `0x80=Á 0x86=Ç 0x88=É 0x8c=Í 0x8e=Ï 0x90=Ñ 0x92=Ó 0x9b=Ú 0x9d=Ö
  0x84=Ü 0xcb=ª`. (Derived + verified: FÚTBOL, VÍTOR BAÍA, CAÑIZARES, RAÚL, ROMÁRIO.)
- `0x4d` = separator joining LEGAL and COMMON names inside the fullname field.
- string validity gate (kills field-byte misreads): bytes `<=0x5f or >=0x80`, <45%
  null bytes, ≥60% letters/space, and NO `?`/`+` (unmapped codes = field bytes).

**Output: `assets/squads_laliga.json`** — 20 Primera 97-98 squads, **533 players**,
0 empty / 0 garbled names. Per player: name, legalName, birthYear, age, media, 10
named attrs, isGK. Verified: full Barcelona + Real Madrid 97-98 rosters are exact.
Known soft spot: 1 player (Tenerife "DOMINGOS") has an attribute row that looks
byte-shifted (PO70 but RM83); names/years are 100% clean.

### Stadium expansion + youth potential — RESOLVED (not stored fields)
- **Stadium expansion**: NOT a per-team data field (editor documents only
  capacity + founding year for the stadium). In the original it's a *gameplay
  mechanic* (pay to raise capacity up to a limit). Reproduce in the Phase-1 engine;
  the starting `capacity` (extracted) is the input.
- **Youth potential**: PM98/PC Fútbol has **no explicit potential rating** (the
  manual lists only media + the 10 attributes). Youth development is emergent:
  young players (low birth year → low age) whose attributes grow via the engine.
  Youth players live in club squads + the dedicated "Juveniles" team slots
  (directory IDs 9955-9958). To match the original, replicate the age-based
  development engine in Phase 1; extract young players + their 10 attributes as input.

### ALL detailed records via the Copyright marker — DECODED ✅ (2026-06-14)
EQUIPOS.PKF is **4.0 MB**, not 43 KB. The 20-entry SIG index only covers Spanish
Primera. **Every detailed team record starts with the ASCII string
`Copyright (c)1996 Dinamic Multimedia`** — it appears **476×**. Scanning for it
(`record_offsets()`) yields all 476 records; boundaries = consecutive markers.
Same per-record layout as the Primera 20, so `extract_squads.py` parses them all.
- Records **0-37 = Spain Primera (20) + Italy Serie A (18)**: contiguous (~2 KB
  each), dense squads, fully clean (verified vs reality).
- Records **38+ = continental + English + S.American + minor leagues**. Continental
  teams (Germany, France, Portugal, NL, Scotland, S.America, …) have dense squads.
  **English-league clubs** (Man Utd, Liverpool, Blackburn … and the English lower
  divisions) have reliable headers but their squads are **SPARSE, interleaved with
  large English bio/commentary blocks** (gaps up to ~100 KB). Squad framing for the
  English records is the main TODO (the players ARE there in the same format — e.g.
  Man Utd: Solskjaer/Cruyff/Johnsen/May found — just not contiguous).

**Output `assets/teams_all.json`**: all 476 team records (name/stadium/fullName/
manager), **281 with complete dense squads = 5654 players**.

### Player media field — subtype gotcha (RESOLVED)
The **10 attrs are ALWAYS at Y+4..Y+13** (Y = birth-year anchor); term at Y+14.
The **media (overall) byte at Y+3 is only present when the squad flag d[Y+2] >= 0xA0**
(observed 0xA0-0xC3). For flags **0x80-0x9F (e.g. 0x8C)**, Y+3 is a `0x01` pad and
media is NOT stored → emit null and derive in-engine. This subtype is rare in the
top leagues (La Liga 0, Serie A few) but common in lower/foreign leagues (~30% of
the 5654). Attrs stay correct for every player (e.g. Benfica GK Ovchinnikov PO=77).

### English-league squads — FRAMING SOLVED ✅ (`tools/extract_english.py`)
The 92 English clubs are Copyright-records **idx 38-129** (Premier + Div 1/2/3;
idx 38 Blackburn where the gap jumps 2 KB→71 KB, through idx 129 Wigan, then idx
130 Borussia D. drops back to ~1.5 KB dense continental records). Their squads are
NOT missing or scattered — they were just rejected by the Spanish anchor's
`attrs<=99 + terminator` gate. English player records use an **extended layout**:
```
[career history |SEASON|CLUB|pos|apps| ...]
[u16 len][shortname][u16 len][fullname]
[small field block ~6-14 bytes]
[u16 birthYear 1940-1985][flag >=0x80]
[birthplace][prev club][nationality][bio prose]
```
The key difference vs the Spanish compact record (`[year][flag][media][10 attrs]
[01]`): for English records **Y+4 is the birthplace string, not the attributes**.
Anchoring on (year 1940-1985, flag>=0x80) + a length-prefixed short+full name
ending just before Y recovers **all 92 squads = 1948 players**, names + birth
years cross-validated (the full Man Utd 97-98 squad incl. Beckham/Scholes/Giggs/
Keane/Schmeichel is exact; Liverpool, Arsenal verified). Output:
`assets/squads_english.json`.

### English attribute block — DECODED ✅ (wired into `extract_english.py`)
Earlier claim that English attrs "aren't stored" was WRONG. They are stored, just
NOT at Y+4 (that's birthplace). The attribute row is:
```
[6c 6b season marker][10 attrs: VE RE AG CA RM RG PA TI EN PO, each 1-99]
[0x01 terminator][record-id byte]
```
one per player, sitting AFTER the player's bio. Pairing: each birth-year anchor
takes the attr block whose offset falls between it and the NEXT anchor (block →
the anchor that precedes it). **GKs are sorted first** and the PO byte cleanly
separates them: validated VAN DER GOUW 77, **SCHMEICHEL 91**, SEAMAN 92, James 84,
Given 76, Hitchcock 74 (keepers) vs every outfielder PO 8-21. Direction is *proven*,
not assumed: the opposite pairing makes defender CASPER come out PO=91, which is
absurd, so "block-after-anchor" is the only consistent reading. In the youth pool
(last Copyright record @EOF) the same block follows empty `2f 25 4d` = "ND|" career
placeholders; in senior records it follows the real career history. The earlier
`[01 00 76][01 00 25]×n` *triplet* block is a shared TEMPLATE (identical across
Andrew Lee + Lee Campbell), NOT the attrs.

Coverage: **1840 / 1948 players (94%)** carry an attribute row. The misses are
almost all the *last* player per club (e.g. Beckham), whose block isn't present in
detectable form before the next club's Copyright marker — those stay `attrs: null`
rather than risk a wrong row (do NOT relax the 0x01-terminator gate; bio text has
stray `6c 6b` runs that would false-positive). Ground truth from Mats: youth
recruits Andrew Lee (b.1979 Sheffield), Lee Campbell (b.1980 Mansfield), Shepherd,
Wall — all present at file end.

### Still remaining
- The ~876 teams in the 1352-team directory beyond these 476 detailed records
  (likely a more compact record elsewhere, or directory-only stubs).

### Key remaining unknown: other-segment / player RECORD FRAMING
Stadium names like OLD TRAFFORD/ANFIELD also appear in the bio section (>1MB), so
name-adjacency is NOT a reliable capacity anchor. Need the structured team-record
table (likely one of the 8 blocks). CAMP NOU @1518 is the one confirmed real team
record so far. Framing this table is the gate to capacity/expansion/youth fields.
Extracted raw strings: `assets/equipos_strings.txt` (~80k, includes bio text).

## 4. Other assets
- `GFX.DAT` — header `01 0a 00 0a 00 04 00 ...` looks like dimension fields.
- Audio: `MUSICAS.PKF` holds `.s3m` tracker modules (`dinamic0..5.s3m`) via MIDAS;
  `SONIDOS/*.RAW` are raw PCM; `SFX/*.PKF` packed sound banks.
- Images by type: `BIGFOTO/` squad photos, `*ESC` crests/badges, `BANDERAS`
  flags, `*CAMP` stadiums, `MINIFOTO` player faces, `*ENTR` (entrenador=manager).
