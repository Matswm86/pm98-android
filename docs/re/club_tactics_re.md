# Per-club OWN tactics — decoded from EQUIPOS.PKF (closes the VIEW RIVAL honest gap)

**2026-07-06.** The walked rival frames proved clubs carry their OWN tactic
(Barcelona's slot layout matches no stock formation, `rival_screen_re.md`). This
session decoded where that tactic lives and shipped it as app data. Decompiles in
`docs/re/clubtactics/`.

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
| +0x298 + s | slot s+1's marker number = player+0x1d + 1, for players with XI slot byte player+0x1b in 1..11 | player loop (**the .DBC also stores the club's CURRENT XI assignment** — un-extracted, see residue) |

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
(min 0x69), u16 · flag==0: [fmt>0x207: +2] u32, skip str+4, u32 capacity, skip
str, skip str, u16, u16, u8, tail skip 0x51/0x73/0x7b by fmt · **11 x 8 u16 slot
block** · **7 lever bytes** · tag-2 records (`FUN_00579170`) · player records
until tag 0 (`FUN_005820f0` / fmt>=600 `FUN_00581f80`).

## Kill-tests (all PASS, run on every export)

1. **Barcelona (EQ960001)**: unique 176-byte hit at .DBC offset 0x6a; mapped
   {mk1}/{mk2} == the walked rival_015 disc/arrow lists (frame bake,
   `rival_chrome_samples.json`) — EXACT, both phases, all 11 slots.
2. All 476 records parse; every coordinate inside the 318x198 design space;
   every mapped marker inside the (242,138) draw window.
3. 467/476 decoded names == game_db.json names (the 9 = known '?'-recovered
   records); GK slot = index 0 with mk1==mk2==(0,88) raw in ALL 476.
4. Witnesses: Man Utd = stock 4-4-2 coordinates (the walked 3-5-2 in frame 014
   was that career's chosen tactic, not the shipped default). Only **19/476**
   clubs sit on stock formations — 457 carry custom layouts. Shapes present
   include 3-6-1, 4-6-0 and 5-5-0 (no stock name exists for the last two).

## App wiring (shipped)

- `tools/re/export_club_tactics.py` → `app/data/club_tactics.json` (476 clubs:
  raw slots + mapped mk1/mk2, 7 raw lever bytes, stock-formation match).
- `RivalScreen`: live rivals now draw their OWN stored slots
  (`_club_slot_order`, GK first then DEF/MID/FWD by the sourced FUN_004fe2d0
  band rule: mk1.x_raw<0x41 DEF, elif mk2.x_raw<0x104 MID, else FWD); the XI is
  `Tactics.auto_pick_shape` with the slot-table's band counts. Injected
  `rival_markers` (parity) still wins; clubs missing from the data fall back to
  the old stock path. Parity rival_015 unchanged (0px).
- `Tactics.auto_pick_shape(club, d, m, f)`: count-based fill for shapes with no
  stock name.

## Honest residue

- Slot fields [0..3] un-decoded (present in stock + club tables alike).
- The 7 lever bytes are stored RAW; byte→lever mapping is EXACT_PORT_PLAN gap B.
- The .DBC's per-player XI slot byte (player+0x1b) + marker number (player+0x1d)
  are parsed by the engine but NOT yet extracted into game_db — extracting them
  would replace auto-pick with the club's TRUE shipped XI (next lever).
- Tag-2 records (`FUN_00579170`) un-identified.
- MatchSim CPU fielding still uses `Tactics.auto_pick` (own-shape fielding for
  the sim changes match outcomes — separate, sign-off-worthy change).
