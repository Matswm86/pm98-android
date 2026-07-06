# Per-club OWN tactics + TRUE XI — decoded from EQUIPOS.PKF (closes the VIEW RIVAL honest gap)

**2026-07-06.** The walked rival frames proved clubs carry their OWN tactic
(Barcelona's slot layout matches no stock formation, `rival_screen_re.md`). This
session decoded where that tactic lives and shipped it as app data. Decompiles in
`docs/re/clubtactics/`. **Second pass (same day): the squad loop's per-player
records are now parsed too — every club's SHIPPED XI (which player stands at
which tactic slot) is extracted and fielded on VIEW RIVAL.**

## The pointer chain (VERIFIED, disasm 0x57340c..0x57345c in FUN_005733d0)

```
[0x66afd0]+0x38 / +0x3a          ; next fixture's home/away club ids (u16)
  -> the side that != your club id ([manager+0x10]) = the RIVAL club id
FUN_00585ee0(registry@0x66c0d0, id)   ; per-club lazy handle, new(0x20):
                                      ; {count=0xff, club_id, 0, 0, club*, 0,0,0}
  -> FUN_005793d0(handle)             ; returns handle+0x10, lazily calling
     -> FUN_005792b0(handle, 0)       ;   new(0x2a4) club object (FUN_00579880
                                      ;   ctor) + FUN_00579b80 file load
        -> [screen+0x1928]            ; what the VERRIVAL builder draws from
```

`FUN_00579b80` opens `sprintf("DBDAT\\equipos\\eq96%04u.dbc", club_id)` (string
@0x662158) — served from **EQUIPOS.PKF** (standard PKF directory, one `.DBC` per
club, `tools/re/dbc_extract.py`) — and `FUN_00579c70` parses the record into the
club object. Mode word 0x410 for slot 0, 0x210 otherwise; `param_2 == 9` is a
names-only parse.

## The 0x2a4 CLUB object (not a separate tactic struct)

The "tactic" the rival screen draws IS the club object; the same object carries
the squad linked list the CPU picker walks:

| offset | content | source |
|---|---|---|
| +0x10 | club id | ctor arg (`FUN_00579880`) |
| +0x24 | squad list head (nodes linked at player+0x100) | player loop in `FUN_00579c70`; walked by the picker `FUN_005776f0` |
| +0x28 | squad count | same loop |
| +0x60 + i*0x20, i=0..10 | **11 tactic slots**, 8 u32 each; [4],[5] = mk1 x,y; [6],[7] = mk2 x,y (raw 318x198 design space; fields [0..3] present but un-decoded — same 8-field row format as the stock table `DAT_00660240`) | `FUN_0058c130` x 11 (each reads 8 u16 from the .DBC and widens) |
| +0x1c0 | tactic name, 0x18 chars (initialised to the club NAME string) | `FUN_0057a3e0` |
| +0x1d9..+0x1df | **7 TEAM-TACTICS lever bytes** (per-byte semantics un-RE'd — EXACT_PORT_PLAN gap B) | read right after the slot block |
| +0x298 + s | XI slot s's FINE-POSITION byte = player+0x1d + 1 (== game_db posFine, the POS_WEIGHT roulette index — proven by frame 015's role column), for the player whose XI slot byte player+0x1b == s in 1..11 | player loop (**the .DBC stores the club's SHIPPED XI assignment** — now extracted, see below) |

Draw sites (already in `rival_screen_re.md`): bright rival markers read
`club+0x60+i*0x20` fields +0x10/+0x14 (mk1, bVar2>=5) and +0x18/+0x1c (mk2,
bVar2>=7); the ghost pass reads the SAME layout from your own Tactics
(param_3+0x60). Layer mapping `(raw*258/318, raw*154/198)`.

## The .DBC parse order (FUN_00579c70, replicated exactly by the exporter)

`+0x24` u16 alloc-size · `+0x26` u16 fmt (gates at 0x1f9/0x1fe/0x203/0x207/600) ·
`+0x28` u8 unread · `+0x29` u8 flag · strings = `[u16 len][bytes XOR 0x61]`
(`FUN_0058c810` — the REAL cipher; the old `alphabet[b&0x1f]` reading in
FORMATS.md/parse_equipos.py is an approximation of this) · name, name2, u8,
name3, u32 (min 6000), fmt>=0x1fe: u32 (rounded to 4000s), u16 (min 0x3c), u16
(min 0x69), u16 · flag==0: [fmt>0x207: +2] u32, skip str+4, u32 -> param_1[0x7a]
(earlier labelled "capacity"; observed range 1..1500 — Man Utd 1500 — NOT a
plausible seat count, display semantics UNRESOLVED), skip str, skip str, u16,
u16, u8, tail skip 0x51/0x73/0x7b by fmt · **11 x 8 u16 slot block** · **7
lever bytes** · tag-2 records (`FUN_00579170`) · player records until tag 0
(`FUN_005820f0` / fmt>=600 `FUN_00581f80`).
Header identities (pinned vs game_db + frames, 2026-07-06): name2 == STADIUM
("Old Trafford"), name3 == FULL CLUB NAME ("Manchester United F. C."), the u8
between them == the PAISES.30 COUNTRY CODE (all 476 resolve; Wrexham/Cardiff/
Swansea = WALES, Celtic = SCOTLAND). The three flag==0 block strings =
[chairman, sponsor, kit maker] ("C M Edwards", "SHARP", "UMBRO") — EQUIPOS
stores NO manager name.

## The squad loop + player record (FUN_005820f0 — the TRUE XI)

After the levers: 1 tag byte; `while tag == 2` → side-record (`FUN_00579170`:
u16 + XOR string + flag==0-gated skips — still unidentified, skipped exactly);
then an unconditional do-while of player records until a 0 tag. Per record
(fmt<600 path; all EQUIPOS fmts are 0x1f9..0x20b):

```
u16 player id        == game_db photoId where present (the J96 face-bank key)
u8                   -> +0xf8
XOR string x2        short name (+0x4), full name (+0x8) — heap ptrs
u8  XI SLOT          -> +0x19 AND +0x1b;  VALID player iff < 0x62
u8                   unread
u8 x6                -> +0x1d.. decoded (0 -> 0x62, else raw-1);
                        +0x1d == game_db posFine - 1 (fine position)
u8 x3                -> +0x1a, +0x16, +0x17 (un-RE'd)
u8  BAND             -> +0x1c: 0 GK / 1 DF / 2 MF / 3 FW (the POS column)
u8 day, u8 month, u16 year    (engine defaults day/month when 0; randomizes
                               year outside 1901..1985 — FUN_0058df90)
u8 x2                -> +0xf9 HEIGHT cm / +0xfa WEIGHT kg (FICHA converts via
                        FUN_0058dd70/FUN_0058de00 stone/feet; engine randomizes
                        height 170..179 when < 150, weight 75..84 when < 20 —
                        extract_squads' old "flag/media" reading of these two
                        bytes is DISPROVEN; "media" was the weight byte)
flag==0 only         1 byte + 10 len-prefixed fields, engine-skipped. DECODED
                     2026-07-06 (extract_squads_exact.py): T1 birthplace
                     ("Gladsaxe"), T2 previous club ("Brondby (91)"), T3
                     NATIONALITY ("Denmark"; absent -> ENGLAND, frames 081/084),
                     T4..T9 six bio prose pages, T10 career-history CSV
                     (season,club,div,apps,goals — the PLAYER INFO data)
u8 x10 attrs         VE RE AG CA RM RG PA TI EN PO (mirrored to +0x9c/+0xaa
                     rows; club 0x26e4 gets a random degrade — special id)
```

- **XI slot byte +0x1b**: 1..11 = the club's SHIPPED XI; the player at slot s
  stands at tactic slot s-1 (frame 015: disc numbered s sits on slot s-1's mk,
  11/11 walked pairs). 12..0x61 = squad, not fielded. **>= 0x62 = DROPPED**:
  the caller re-parses invalid records into the same object and rolls back
  their heap strings — Barcelona ships 26 records but fields a 23-man squad
  (Dugarry, Amunike, Stoitchkov are slot>=0x62 leavers the engine discards;
  game_db's heuristic extraction kept them).
- The registry at DAT_0066c158 maps id -> player; id 0 gets the next global
  counter (DAT_0066c154). Special club ids in the parser: 0x26de (validity
  exemption), 0x26ae (third string), 0x26e4 (attr degrade) — none in EQUIPOS.

### game_db mapping (order-based since the 2026-07-06 rebuild)

game_db squads are now built from THIS SAME parser in stream order
(tools/extract_squads_exact.py -> tools/build_db.py), so the club's k-th kept
record IS game_db players[k]; the exporter asserts name + posFine + 10-attr
identity on all 9547 players before trusting the order, then maps XI slot s ->
the LAST record carrying slot byte s (engine: last writer wins). Result:
475/476 slot-complete AND fully game_db-matched (the 1 = a .DBC that leaves a
slot unfilled). The old `match_xi` cascade — and the corruption it compensated
for (old-cipher squads: Sammer/Effenberg/Brehme absent, Real Madrid's
'FEARAÚLUARAÚL GONZÁL', 3 English gaps O´Connor/Birmingham C, G. Jones/
Tranmere, L. Marshall/Scunthorpe, Barcelona's 3 undropped leavers) — is GONE:
the rebuild closed all of it (9 club names fixed too: 'Schalke 04',
'Munich 1860', 'Brighton & HA' — digits/&/apostrophes the 5-bit cipher could
not encode).

## Kill-tests (all PASS, run on every export)

1. **Barcelona (EQ960001)**: unique 176-byte hit at .DBC offset 0x6a; mapped
   {mk1}/{mk2} == the walked rival_015 disc/arrow lists (frame bake,
   `rival_chrome_samples.json`) — EXACT, both phases, all 11 slots.
2. All 476 records parse; every coordinate inside the 318x198 design space;
   every mapped marker inside the (242,138) draw window.
3. **476/476** decoded names == game_db.json names (same decode on both sides
   since the rebuild); GK slot = index 0 with mk1==mk2==(0,88) raw in ALL 476.
4. Witnesses: Man Utd = stock 4-4-2 coordinates (the walked 3-5-2 in frame 014
   was that career's chosen tactic, not the shipped default). Only **19/476**
   clubs sit on stock formations — 457 carry custom layouts. Shapes present
   include 3-6-1, 4-6-0 and 5-5-0 (no stock name exists for the last two).
5. **TRUE XI vs walked frame 015**: Barcelona xiNames == the 11 rows
   [Hesp, Reiziger, Abelardo, Guardiola, F. Couto, Sergi, Figo, Luis Enrique,
   Anderson, Giovanni, Rivaldo], xiFine == row_truth_015.fine ==
   [1,2,5,15,5,3,16,7,9,13,17], band bytes spell the POS column
   (GOAL/DEF/DEF/MID/DEF/DEF/MID/MID/FOR/MID/MID), and slot i carries the
   walked disc/arrow numbered i+1 — EXACT, first parse.
6. Every squad parse lands in bounds (heap use <= alloc @+0x24, cursor <=
   record end — FUN_00579c70's own success check); >= 470 slot-complete.
7. Record<->game_db identity: same squad size, name, posFine and 10-attr row
   for every player (9547 checks — the order-based mapping's precondition);
   every slot-complete club fully matched (475/476); Man Utd 11/11
   (shipped XI = Schmeichel, G. Neville, Irwin, Berg, Pallister, Butt,
   Beckham, Sheringham, Cole, Giggs, Solskjaer).

## App wiring (shipped)

- `tools/re/export_club_tactics.py` → `app/data/club_tactics.json` (476 clubs:
  raw slots + mapped mk1/mk2, 7 raw lever bytes, stock-formation match, and
  `xi` (game_db player id per slot 1..11, -1 only where the .DBC leaves the
  slot unfilled) + `xiNames`/`xiFine` (record name + raw fine byte)).
- `RivalScreen`: live rivals draw their OWN stored slots AND — when the club's
  `xi` is game_db-complete — field their SHIPPED XI (`Tactics.with_xi`), slots
  paired in NATIVE .DBC order (disc s at tactic slot s-1, `_shipped_xi`).
  Clubs with xi holes keep `Tactics.auto_pick_shape` + the band-reordered
  slot pairing (`_club_slot_order`, sourced FUN_004fe2d0 band rule). Injected
  `rival_markers` (parity) still wins; clubs missing from the data fall back
  to the old stock path. Parity rival_015 unchanged (0px).
- `Tactics.with_xi(club, xi_ids, d, m, f)`: fields the shipped XI verbatim;
  `Tactics.auto_pick_shape(club, d, m, f)`: count-based fill for the fallback.

## Honest residue

- Slot fields [0..3] un-decoded (present in stock + club tables alike).
- The 7 lever bytes are stored RAW; byte→lever mapping is EXACT_PORT_PLAN gap B.
- Player bytes +0x16/+0x17/+0x1a and the 6-byte fine array's entries [1..5]
  un-RE'd.
- Tag-2 records (`FUN_00579170`) un-identified (parsed + skipped exactly).
- ~~game_db squad corruption~~ **CLOSED 2026-07-06**: game_db rebuilt from the
  exact parser (extract_squads_exact.py -> build_db.py); 475/476 xi-complete,
  leavers dropped, names/accents/digits exact, player ids renumbered
  (1..9547; career saves are self-contained — rosters frozen at draw time).
- The flag==0 club-block u32 (param_1[0x7a], observed 1..1500) display
  semantics unresolved — NOT used as capacity in game_db (La Liga capacities
  stay from teams_laliga.json).
- ~~Player bio pages T4..T9 + career-history CSV T10 unexported~~ **EXPORTED
  2026-07-06**: verbatim into `assets/bios.json` keyed by game_db player id
  (extract_squads_exact `bioPages`/`careerCsv` -> build_db split; 2025
  extended-record players, all 6 pages + CSV each; id-join kill-tested,
  0 name mismatches). The CSV keeps the source's own dirt ('Sin datos.'/
  'No data.', typo'd separators) — never repaired. NO app consumer yet.
  Display surface FOUND + walked 2026-07-06: the standalone DATA BASE player
  card (Dbasewin.exe tabs), NOT the FICHA coin (decorative, no handler) —
  see docs/re/dbase_player_card_re.md for the walk, parser truth and
  tab-disable rule.
- MatchSim CPU fielding still uses `Tactics.auto_pick` (own-XI fielding for
  the sim changes match outcomes — separate, sign-off-worthy change).
