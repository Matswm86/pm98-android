# Injury model — roll + duration, BINARY-EXACT (2026-07-23)

Closes the last-standing INJURIES gap flagged by the owner: the per-type roll
distribution and duration table were previously **invented** (`Availability`'s old
`_injury_weeks` short-weighting + uniform-within-tier `_pick_injury_type`). Both are
now lifted byte-for-byte from `extracted/Premier Manager 98/MANAGER.EXE` — no wine,
no invention, same objdump + capstone method as the injury-name table.

> **Premise correction.** The prior handoff called this data "DAT.PKF-driven". It is
> **not**: `DAT.PKF` holds only palettes / index bitmaps / brightness LUTs (see
> `pkf_format.md`). The injury type table, the two roll ladders, and the duration
> jump-table are all **static code + data inside MANAGER.EXE**, reached by direct
> `call rel32` (not vtable, not a DAT record). The RNG is the game's own
> `FUN_0058df90(n) -> uniform 0..n-1` (no `rand`/`srand` import).

Tooling: `tools/re/injury_model.py` (the transcribed spec + a self-check that both
ladders sum to 100%), `tools/re/xref_scan.py` / `fdump.py` / `datdump.py` (the
disasm helpers). Section map as in `injuries_screen_re.md`.

## Call graph
```
weekly illness/injury tick  0x57a9b0 loop
  -> apply(player, kind=1)   0x584b80  --calls--> roll_A 0x5850b0   (news tag 8)
match injury                          apply_match(player) 0x584c00
  -> roll_B 0x585210                                                (news tag 7)
both rolls -> setter 0x584e70 : stores type@+2, rolls 4 coins, jumps @0x585048
              -> per-type DURATION into injury bytes +0 (remaining) / +1 (total)
```
Injury record lives at **player+0x68**: `+0x68` remaining weeks · `+0x69` total weeks
(news singular/plural gate: `>1`) · `+0x6a` type index (0..17 -> table 0x6622e8) ·
`+0x6b` = 0. `is_serious` (0x584e20) and `injury_name` (0x584e50) read `[this+2]`
i.e. the `+0x6a` byte.

## Type distributions (each is `rand(100)` through a cmp ladder)

**roll_A @0x5850b0 — WEEKLY (includes illness).** virus/cold present.
**roll_B @0x585210 — MATCH (physical only).** virus/cold absent; `[69,74)` -> sprained
wrist(8) instead of virus(0). Tail (both): `cmp 0x63; sbb eax,eax; add eax,0x11`
=> 98 -> slipped disc(16), 99 -> broken leg(17).

| type | name | roll_A % | roll_B % |
|---|---|---:|---:|
| 0 | virus | 24 | – |
| 1 | cold | 1 | – |
| 2 | pulled muscle | 5 | **25** |
| 3 | dead leg | 10 | 10 |
| 4 | pulled hamstring | 10 | 10 |
| 5 | sprained ankle | 8 | 8 |
| 6 | dislocated wrist | 8 | 8 |
| 7 | dislocated finger | 8 | 8 |
| 8 | sprained wrist | – | 5 |
| 9 | groin strain | 1 | 1 |
| 10 | broken nose | 5 | 5 |
| 11 | broken toe | 5 | 5 |
| 12 | broken cheekbone | 2 | 2 |
| 13 | dislocated shoulder | 5 | 5 |
| 14 | fractured rib | 5 | 5 |
| 15 | shin splints injury | 1 | 1 |
| 16 | slipped disc | 1 | 1 |
| 17 | broken leg | 1 | 1 |

The app's `roll_match` fires per featured player after a match, so it uses **roll_B**
(`Availability.MATCH_INJURY_CDF`). ~~The weekly-illness path (roll_A, virus/cold) is a
separate mechanic the app does not yet model~~ — **PORTED 2026-07-28**
(`Availability.roll_weekly_illness` + `WEEK_INJURY_CDF`, gate
`app/tests/test_weekly_illness.gd`). Note what the ladder actually does: **virus's 24 % is
TWO bands, not one** — `[0,0x13)` at the head and `[0x45,0x4a)` where roll_B puts sprained
wrist — which is why sprained wrist cannot happen weekly and virus cannot happen in a match.

**The trigger, `FUN_0057a980` @0x57a9f4-0x57aac8, ported gate for gate:**

1. `DAT_0066b1e8 != 0` skips the whole block (the dead dev flag — never set in retail).
2. `2 * already_injured >= squad` → nothing (`lea edx,[ebp+ebp] / cmp edx,eax / jae`).
3. `already_injured + 16 >= squad` → nothing (`add ebp,0x10 / cmp ebp,eax / jae`), so a
   squad of sixteen or fewer is exempt outright.
4. `rand(7) != 0` → nothing. **One week in seven.**
5. `rand(100) < 0x46` (70 %) searches squad slots **1..12**, else slots **12..size**.
6. **Five** candidate draws (`mov [esp+0x10],5`); a candidate already injured is skipped,
   and a later candidate REPLACES the current pick when `rand(100) > candidate +0xa7`
   (his FITNESS) — so the less fit a man is, the likelier he is the one who falls ill.
7. `apply(player, 1)` @0x584b80 → roll_A → the shared duration setter, then the news line
   from `.data` slot 0x662d84 → 0x663230: `"%s is out for %u week%s with a %s."`, which is
   the wording `matchday_flow_witness_re.md` witnessed on the hub verbatim.

## Duration table (setter @0x584e70 + jump table @0x585048)

The setter always rolls four weighted coins (each 0/1), then the injury type selects
a formula via `jmp [type*4 + 0x585048]`:

```
A = rand(100) < 75    B = rand(100) < 50    C = rand(100) < 25    D = rand(100) < 12
```

| type(s) | handler | weeks formula | range | mean |
|---|---|---|---|---|
| 0,1,2,8 | 0x584F39/EDD | `B+1` | 1..2 | 1.50 |
| 3 dead leg | 0x584EF4 | `1` | 1 | 1.00 |
| 4,7,10 | 0x584F63 | `B+2` | 2..3 | 2.50 |
| 5 sprained ankle | 0x584F07 | `B+3` | 3..4 | 3.50 |
| 6 dislocated wrist | 0x584F1E | `D+C+B+5` | 5..8 | 5.87 |
| 9 groin strain | 0x584F50 | `2` | 2 | 2.00 |
| 11 broken toe | 0x584F7A | `C+B+3` | 3..5 | 3.75 |
| 12 broken cheekbone | 0x584F94 | `(C+B+9)*2` | 18..22 | 19.50 |
| 13 dislocated shoulder | 0x584FB0 | `C+B+6` | 6..8 | 6.75 |
| 14 fractured rib | 0x584FCA | `(C+B)*2+D+5` | 5..10 | 6.62 |
| 15 shin splints | 0x584FE8 | `(C+B)*2+D+25` | 25..30 | 26.62 |
| 16 slipped disc | 0x585006 | `(D+C+A+B+10)*2` | 20..28 | 23.24 |
| 17 broken leg | 0x585029 | `(C+B+20)*2+D` | 40..45 | 41.62 |

Unit is **weeks** (the news templates print `%u weeks`), decremented one per matchday
in `Availability.tick_week` (PM98 runs ~one league match per week). Serious injuries
are genuinely season-length (broken leg 40+ weeks) — that is the game's own model, not
a cap the port invented.

News tier is by **type** (`is_serious` = type 11..17 -> "badly injured"), NOT by
duration — hence a 5..8-week dislocated wrist (type 6) still prints the ordinary
"will be out" line while a 3-week broken toe (type 11) prints "badly injured". The five
templates were confirmed byte-exact (0x662c04 / 0x662bc0 serious; 0x662b24 / 0x662afc
ordinary; 0x662990 feed) — the port's wording already matched.

## Port + verification
- `app/scripts/Availability.gd`: `MATCH_INJURY_CDF` const (roll_B), `_roll_match_injury_type`
  (exact ladder), `_injury_weeks(rng, ti)` (the jump-table formulas). `roll_match` now
  rolls the diagnosis first, then its duration — the binary's order.
- `app/tests/test_availability.gd::_unit_injury_model`: asserts every match diagnosis
  is in {2..17}, all 16 occur, pulled muscle is modal, and every type's duration stays
  inside its exact `[min,max]` with both extremes reachable (dead leg == 1, broken leg
  40..45). All 38 asserts PASS; test_injuries_screen / test_career / test_news_screen PASS.
- Render-diff `tests/shot_injuries_verify.gd` -> `out/injuries_typed.png` (display :1,
  opengl3): the Week column now carries the model's real spans — broken leg **40**,
  dislocated shoulder **8**, groin strain **2**, pulled muscle **2** — beside the
  binary-exact diagnoses, in-column.

## Still open (flagged, not faked)
- Weekly-illness path (roll_A, virus/cold, whole-squad fitness-weighted victim pick at
  0x57a9b0) is not modelled — the app only injures match participants.
- The victim-selection weighting (5 random candidates, re-roll toward the least-fit via
  `rand(100) <= [player+0xa7]` at 0x57aa88) is the game's *who*-gets-hurt logic; the app
  keeps its own per-player `INJ_CHANCE` gate. Type + duration (the *what*) are now exact.
