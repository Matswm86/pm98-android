# Player position (demarcación) decode — EQUIPOS.PKF

The PM98 / PC Fútbol player record carries a one-byte **demarcación** (playing
position) three bytes before the birth-year anchor, in the small field block that
precedes it. It is a clean 0-3 enum:

| byte | position    | section label |
|------|-------------|---------------|
| 0    | goalkeeper  | GOALKEEPERS   |
| 1    | defender    | DEFENDERS     |
| 2    | midfielder  | MIDFIELDERS   |
| 3    | forward     | FORWARDS      |

## Where it sits

For both record layouts the position byte is at `d[Y - 3]`, where `Y` is the u16
birth-year anchor each extractor already locates:

- **English extended records** (`tools/extract_english.py`): attrs live in a separate
  `6c 6b` block after the bio; the position byte is in the field block before `Y`.
- **Compact Spanish/Italian/continental records** (`tools/extract_squads.py`): attrs
  are at `Y+4..Y+13`; the same `d[Y-3]` byte holds the position.

## Cross-validation (how we know it is the position field, not noise)

1. **Clean 0-3 partition.** Across the 92 English clubs the byte distributes
   `{0: 194 GK, 1: 677 DF, 2: 598 MF, 3: 481 FW}` — no stray values. The 476-record
   compact set distributes the same four buckets.

2. **Agrees with the independent PO (goalkeeping) attribute.** Of the 194 English
   players with `d[Y-3]==0`, 177 (91%) have PO>50 (a real keeper rating); the 481
   `d[Y-3]==3` players are all outfield (PO<=25). The two fields are decoded from
   different parts of the record, so their agreement is not circular.

3. **Reproduces a known real squad.** The 1997-98 Arsenal record splits exactly into
   the famous spine: GK Seaman/Manninger/Lukic; DF Adams, Keown, Dixon, Winterburn,
   Bould; MF Vieira, Petit, Parlour, Overmars, Platt; FW Wright, Bergkamp, Anelka.
   Barcelona's compact record splits as cleanly.

It also **corrects** outfielders that a PO>50 heuristic mislabelled as keepers
(Grimandi PO=65 → MF; Dabizas, Ketsbaia, Boateng, Pollock → outfield) and promotes
real backup keepers whose PO was recorded ≤50 (Walton, Wells). 25 English `isGK`
flips, all in the right direction.

## Wiring

`pos` (`"GK"/"DF"/"MF"/"FW"`, null only for un-decoded records) is emitted per player by
both extractors, carried through `tools/build_db.py` into `assets/game_db.json`, and
consumed by:

- `SquadScreen._sections()` — four position sections instead of GK/outfield.
- `Tactics._fill_xi()` — the back line prefers DF, the front line FW, midfield MF,
  spilling into other outfielders only when a position bucket is short.
- `isGK` is now derived from `pos == "GK"` (authoritative), with the old PO>50 rule as
  the fallback for records without a decoded position.
