# Per-player stat store (MP/MIN/RATING/G./SHOTS/PASSES/TAC.) — RE map

Status: **STORE + GETTER + WRITE PATH + ACCUMULATOR now ORACLE-VERIFIED (2026-07-24).**
`tools/re/run_statcommit_oracle.sh` drives the real `FUN_0044e440` through the Ghidra
PCode emulator across 5 fixtures (all RET) and banks every byte it writes to
`tools/re/specs/statcommit_oracle.txt`. The **persistent** store is also located and
ctor-verified. What is still NOT reversed: the record dword → display-column map, and
the writer that folds a match record back into the persistent store. Nothing is ported
yet; per `pm98_stay_true_to_original` / `ship_real_content_no_assumptions` no field
meaning below is inferred where the oracle did not show it.

## Two stores, one 0x48-byte record layout

| store | where | lifetime |
|-------|-------|----------|
| **match report** | `DAT_0066afd0 + 0x9c/+0xa0` (home) and `+0xa4/+0xa8` (away), stride `0x48` | rebuilt per fixture by the match ctor `FUN_00448b60` (`@0x448e0f..0x448e83`) |
| **persistent** | `playerobj + 0x24`, 0x44 bytes, id implicit at `playerobj + 0x00` | lives on the global player object |

The persistent one is **ctor-verified**: `FUN_00581c80` (the player-object ctor) does
`lea ecx,[esi+0x24]; call 0x4484d0` — `FUN_004484d0` is the *same* 0x44-byte zeroing
ctor the report vector uses for a new record slot. This is why
`FUN_00581c80` "treats `+0x24` as a constructed sub-object": it **is** a stat record.
It also explains the transfer price ladder reading `player+0x34` — that is
`playerobj+0x24 + 0x10`, i.e. the **same `+0x10` goals field** in the persistent copy
(`offer_record_re.md §6`).

`getter FUN_00449b50` (`__thiscall(this=DAT_0066afd0, pid:u16)`) linear-searches both
report arrays for `record+0x44 == pid` and returns the record ptr or 0.

## The record IS the participant's `+0xec..+0x12f` block

**Oracle-verified.** Seeding every dword of participant `+0xec..+0x12c` with a unique
sentinel `0x10000*(side+1) + 0x100*(player+1) + k` and running `FUN_0044e440` gives
`record+K == sentinel(side,player,K)` for **every** `K` in `0x04..0x40`:

```
home rec0  +0x04=0x10104 +0x08=0x10108 +0x0c=0x1010c +0x10=0x10110 +0x14=0x10114
           +0x18=0x10118 +0x1c=0x1011c +0x20=0x10120 +0x24=0x10124 +0x28=0x10128
           +0x2c=0x1012c +0x30=0x10130 +0x34=0x10134 +0x38=0x10138 +0x3c=0x1013c
           +0x40=0x10140      (fixture A_clean, statcommit_oracle.txt)
```

So, in the participant-relative convention used elsewhere in these docs
(participant `p` of side `s` at `match + 0x7a0*s + 0xac*p`):

```
record + K   =  participant + 0xec + K      for K = 0x00 .. 0x43
record + 0x44 =  participant + 0x88          (the PLAYER ID, u16 — see below)
record + 0x46 =  NEVER WRITTEN (uninitialised stack padding; FUN_00449990 stores only
                 the u16 id at local+0x44 before the 0x48-byte rep movsd)
```

`participant+0x88` is the **global player id**, not a shirt number: the accumulator's
tail loop uses it to index `DAT_0066c158[]` (count `DAT_0066c150`) to reach the player
object. Confirmed by the oracle (records land keyed by exactly the ids poked at `+0x88`).

### Field meanings that are VERIFIED

| off | meaning | evidence |
|-----|---------|----------|
| `+0x00` | **appeared / MP flag** | accumulator forces `1` (`@0x44e770`); every consumer greys the row on `[rec]==0` (`@0x4fcf55`, `@0x4fd814`, `@0x578822`); oracle shows `+0x00=0x1` while the sentinel says `0x10100` |
| `+0x04` | stat with a **≥80** price-drift threshold | price ladder `FUN_005849a0` (`offer_record_re.md §6.2`) |
| `+0x0c` | **Man of the Match** | `FUN_0044d520` sets `rec+0xc = 1` for the record whose pid equals `DAT_0066afd0+0xac` (`@0x44d563` home, `@0x44d59c` away); **live-confirmed 2026-07-24** — the full-time board names Wise (Chelsea) MoM and only his STATISTICS row reads `MoM = 1` (`screenshots/wine-captures-2026-07-24-statistics-live/` 04+05) |
| `+0x10` | **goals** | price ladder `num = [player+0x34] + [stats+0x10]`; source field participant `+0xfc` is the per-shirt goal-event count (`FUN_00450d20`, `stat_match_engine_re.md`) |
| `+0x18` | key passes | source participant `+0x104` (`FUN_00450510`) |
| `+0x1c` | passes | source participant `+0x108` |
| `+0x20` | tackles | source participant `+0x10c` |
| `+0x24` | dribbles | source participant `+0x110` |
| `+0x28` | rating | source participant `+0x114` |
| `+0x44` | player id (u16) | search key everywhere |

`+0x08`, `+0x14`, `+0x2c..+0x40` have no identified producer or consumer yet. **Do not
guess them.**

## `FUN_0044e440` is a COPY, not an arithmetic accumulator

This is the single most load-bearing correction the oracle produced. The write helper
`FUN_00449990` (home) / `FUN_00449a70` (away) is **find-by-id-else-append then
`rep movsd 0x12` OVERWRITE** — it performs no addition. Verified two ways:

* fixture `E_duppid` gives two participants the same id ⇒ home count **10, not 11**
  (found, overwritten), so find-then-replace is real;
* fixture `B_partial` blanks 2 home + 1 away id ⇒ counts **9 / 10** (a zero id is skipped
  entirely, no record).

After each commit the accumulator **zeroes participant `+0xec..+0x12f`** (`@0x44e7ad..
0x44e7e0`); the oracle reads `0` back at `+0xec`, `+0x104`, `+0x12c` for every fixture.
So a report record always holds the stats produced **since the last commit**, and any
season/career total must come from the persistent `playerobj+0x24` copy — not from
repeated calls to this function.

## Everything else `FUN_0044e440` writes (all oracle-verified)

**Header copy** into `DAT_0066afd0`:

```
F+0x18 = u16 M+0x64      F+0x1a = u16 M+0x804        (possession, oracle 57 / 39)
F+0x30 = M+0x28          F+0x34..0x37 = bytes M+0x2c / 0x30 / 0x34 / 0x38
F+0x40 = M+0x1c          F+0x48 = M+0x20             F+0x50 = M+0x24
F+0xb4 = M+0x3c          F+0xb8 = M+0x40
```
then `FUN_00449960(F)` frees the old display event list (`F+0x60`) and zeroes `F+0x64`.

**Scoreline counters**, from the `M+0xf98` event vector (`{type,minute,p4,payload}`,
`payload = shirt<<16 | teamid`). Jump table `0x44ea18` routes the type; `p4 != 0`
credits the **other** side (own goal); table `0x44ea2c` maps type 0..4 → report code
1..5 for the display list.

| event type | counters bumped |
|-----------|------------------|
| 0, 1 (H1, H2 goal) | `F+0x3c` home / `F+0x3d` away |
| 2, 3 (ET1, ET2 goal) | `F+0x4c`/`F+0x4d` **and** `F+0x3c`/`F+0x3d` |
| 4 | `F+0x54` home / `F+0x55` away |

Fixture `C_events` (home goal, home own-goal, away ET1, home type-4, away ET2) banks
`+0x3c=1 +0x3d=3 +0x4c=0 +0x4d=2 +0x54=1 +0x55=0` — matching that table exactly,
including the own-goal side flip.

**Assist / shot marker vector** at `F+0x94/+0x98`, stride `0xc`. Before appending, every
selected participant's existing entries are erased (`FUN_00451210`, `@0x44e6ee`). Then
per participant: one record per set assist marker (`+0xd4`, `+0xd8`) and one for the shot
marker (`+0xdc`). Record format, verified by fixture `D_markers`:

```
+0x00 kind   1 = assist, 2 = shot
+0x04 value  minute | (teamid << 16)      teamid = u16 at sidebase+0x7e8
+0x08 pid    u16 participant id (+0x0a is high garbage from the dword store)

D_markers -> rec0 {1, 0x28000c, 1}  rec1 {1, 0x28001e, 1}
             rec2 {2, 0x28002a, 1}  rec3 {2, 0x110011, 21}
```
(assist minutes come from `+0xe0`/`+0xe4`, the shot minute from `+0xe8`.)

**Condition write-back** (tail, `@0x44e9b8..0x44ea0c`): for every selected participant,
`byte participant+0xb8` clamped to `0x63` is stored to `playerobj+0xa8`. Oracle:
`0xff -> 99`, `0x41 -> 65`, `0x60 -> 96`.

## Who reads the records

1. **STATISTICS screen `FUN_004b11c0`** — reads the arrays **directly**, not via the
   getter. It `rep movsd 0x12`-copies each 0x48 record out of `F+0xa4` (`@0x4b1fd3`) or
   `F+0x9c` (`@0x4b20f5`) into its own vector at `screen+0xfd1c/+0xfd20`. The
   **alternative source** (`@0x4b2233`) walks the club squad via `FUN_0057a2c0(club,i)`
   and builds the same 0x48 record from the **persistent** store:
   `rec[0x00..0x43] = playerobj+0x24`, then `rec+0x3c = byte playerobj+0x23`,
   `rec+0x44 = u16 playerobj+0x00`.
   The **TEAM TOTAL** row (`@0x4b2398..0x4b242c`) sums record dwords `+0x08 .. +0x40`
   across all rows (the `+0x00` and `+0x04` sums are computed and discarded).
2. **Transfer price ladder** `FUN_005849a0` (`@0x57b2e8`, `@0x57b3a9`) — `offer_record_re.md §6`.
3. **A squad "has-played" filter** (`@0x578819`) and the LINE-UP list grey-out
   (`@0x4fcf4c`, `@0x4fd801`) — both only test `[rec] == 0`.
4. **Post-match summary** `FUN_0044d5f0` (`@0x44db1f`) — finds the record for one pid and
   copies it out, then scans the `F+0x94` marker vector for that pid to fill its
   assist/shot slots (`screen+0x50..+0x64`).

## Write path callers

`FUN_0044e440` is called from six period-transition handlers plus the finalizer:
`FUN_0044d0d0/d190/d250/d310` (`@0x44d0d3/d193/d253/d313`), `FUN_0044d3d0` (`@0x44d4d5`),
**`FUN_0044d520`** (`@0x44d526`) and `FUN_0044ee70` (`@0x44f2b0`). These are exactly the
transitions `Pm98StatMatch.simulate` stubs as "no rand, no event" (lines 521-533) — true
for the RNG, but they are where the stats get committed.

`FUN_0044d520` is the full-time one (called at `@0x44f51b`, `@0x44f557`, `@0x450419`
inside the driver `FUN_0044ee70`): accumulator → `FUN_0044a370(F)` → MoM stamp
(`rec+0xc = 1` where `rec+0x44 == F+0xac`) → post-match screen `FUN_0044d5f0`.

## STILL OPEN (bounded, none may be invented)

1. **Record dword → display column.** `+0x00` (MP), `+0x0c` (MoM) and `+0x10` (G.) are
   anchored by the live capture (see `statistics_screen_re.md` §"LIVE POPULATED WITNESS");
   `SHOTS`/`PASSES`/`TAC.` are `x/y` pairs consuming two fields each. The screen hands
   each 0x48 record to a row widget (stride `0x41c`, record at widget `+0x3f4`, e.g.
   `@0x4b2438..0x4b2455` for the totals row); that widget's draw method is not yet located,
   and the obvious positional reading of the remaining cells contradicts the provisional
   `FUN_00450510` labels, so `+0x04`, `+0x08`, `+0x14..+0x28` and `+0x2c..+0x40` stay
   unnamed.
2. **The fold-back writer.** The persistent store is `playerobj+0x24`; the code that
   folds a finished match's report record into it has not been found. `FUN_0044d5f0`
   (checked) only *reads*.
3. **Port.** Once (1) is closed: un-stub the transitions in `Pm98StatMatch`, run the
   ported `FUN_0044e440` per segment into a Godot store keyed by pid, wire it into
   `StatisticsScreen` and `OfferRecord`, and assert against
   `tools/re/specs/statcommit_oracle.txt`.

## Reproduce

```
bash tools/re/run_statcommit_oracle.sh          # 5 fixtures -> specs/statcommit_oracle.txt
python3 tools/re/fdump.py 0x44e440 0x2c0        # accumulator
python3 tools/re/fdump.py 0x449990 0x120        # add-or-find home (OVERWRITE, ret 0x48)
python3 tools/re/fdump.py 0x449b50 0x100        # getter / store shape
python3 tools/re/fdump.py 0x44d520 0x100        # full-time handler + MoM stamp
python3 tools/re/fdump.py 0x581c80 0x30         # player ctor -> FUN_004484d0 on +0x24
```
