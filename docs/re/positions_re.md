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

## Fine position (the scorer-roulette weight) — byte at `d[Y-12]` (decoded 2026-06-23)

Separate from the broad 0-3 demarcación, the record carries a **fine position code**
(0..18) that the statistical match engine reads as the **scorer-roulette weight**: the
loader `FUN_00583bd0` reads it into the in-memory player at `+0x18`, the bridge
`FUN_0044d5f0` copies it (`+1`) to participant `+0xc8`, and the resolver `FUN_0044ece0`
indexes the 19-entry `POS_WEIGHT` LUT (`DAT_006532ec` = `[0,0,3,3,3,7,7,12,10,35,10,12,
15,18,15,3,18,18,10]`) with it to decide WHO scores (see `stat_match_engine_re.md`).

**It sits at `d[Y-12]`** (Y = the birth-year anchor), in BOTH the compact Spanish/
continental records and the extended English records (same EQUIPOS.PKF, same offset).
The decompiled loader reads it 8 field-bytes after the broad-position byte, but the two
streams (field stream vs the inline name pool) make the on-disk distance non-trivial; the
offset was instead pinned by cross-validation, the same method used for the broad byte:

1. **Clean role partition** across 6079 compact + 8094 English player anchors:
   GK→`1` (615/618 + 822 English; `POS_WEIGHT[1]=0`, keepers never score), DF→`2..6`
   (weights 3-7), MF→`7..18` (12-18, plus defensive mids at code 15 = weight 3), FW→`9`
   the central-striker slot (843 + 1185 players; `POS_WEIGHT[9]=35`, the heaviest) plus
   wide forwards at 12/14/16/17. No other offset in a ±20 window produces this.
2. **Reproduces real squads.** 1997-98 Barça: all 3 keepers→1, the central strikers→9
   (w35), wide forwards→17 (w18), defensive mids→15 (w3). Man Utd: Schmeichel/Van der
   Gouw→1, Cole/Solskjaer/Sheringham→9, Jordi Cruyff (withdrawn fwd)→14.
3. **~3 keeper records disagree** (broad byte says GK, fine byte says outfield: STURM
   GRAZ FODA PO=12, LILLESTROM KIHLSTEDT PO=19) — original-data quirks, reproduced
   verbatim (the low PO shows the fine byte is the more accurate of the two there).

`posFine` (int 0..18, null only for un-decoded records) is emitted by both extractors,
carried through `build_db.py`, and consumed by `Pm98StatMatch._fill_participant`, which
sets participant POS = `posFine` directly (per-role `POS_OF` fallback only when absent /
out of range). Test: `app/tests/test_posfine.gd`.
