# STATISTICS row widget — draw method, column map, RATING formula (RE, CLOSED)

Status: **CLOSED 2026-07-24.** The row widget's draw method is `FUN_004afce0`
(`@0x4afce0`, runs to `@0x4b1059`). It resolves the `+0x04 / +0x08 / +0x14..+0x40`
conflict between the positional reading of the live frames and the provisional
`FUN_00450510` labels: **the positional reading wins**, and `RATING` is not a stored
field at all — it is recomputed from the record on every paint.

Verification is pixel-exact, not argued: every one of the 14 column-separator
x-positions the draw method pushes is present in the live frames at exactly
`widget_origin_x + offset` (`tools/re/verify_statrow_rating.py` documents the map;
the separator check is reproduced below).

## The widget

| thing | value | evidence |
|-------|-------|----------|
| setup / ctor | `FUN_004afc50` (`@0x4afc50`, `ret 0x5c`) | copies 17 dwords of by-value stack arg into `this+0x3f4`, then `FUN_005bc780` |
| draw | `FUN_004afce0` | the function immediately after the setup; reads exactly the fields the setup writes (`this+0x3f4..+0x430`, `+0x438`, `+0x43c`) and is installed in a virtual table at `0x62a7d4`. The binding proof is not the vtable slot but the geometry: its 14 separator x-coordinates land pixel-exact on the live frames (below) |
| repaint entry | `FUN_005bec80(this, 0)` | called after every field poke, `@0x4b25e5` / `@0x4b2692` / `@0x4b269e` / `@0x4b246c` |
| **stride** | **`0x444`** (`add ebx, 0x444` `@0x4b26b9`) | *the earlier `0x41c` in `season_stats_re.md` was wrong* |
| record slot | `widget + 0x3f4`, `0x44` bytes = `rec+0x00..+0x43` | `@0x4afc60` (setup), `@0x4b25d8` (per-row refill) |
| widget size | `0x223 x 0xe` (547 x 14) | `push 0x223` / `push 0xe` `@0x4afca5` |
| rows | 19 slots at `y = 0x29 + 0x10*i`, `i = 0..18`; loop ends at `0x159` | `@0x4b1e63..0x4b1eca` |
| array base | `screen + 0xa7cc`; **TEAM TOTAL is slot 19** at `screen + 0xf8d8` | `0xa7cc + 19*0x444 = 0xf8d8` |

Non-record fields the screen pokes on each widget:

| field | per-row source | TEAM TOTAL source |
|-------|----------------|-------------------|
| `+0x438` | the setup arg; gates the MoM and injury cells (`!= 0` to draw) | same |
| `+0x43c` (u16) | the record pid (`rec+0x44`) — indexes `DAT_0066c158[]` for the name | forced `0` (`@0x4b2463`) |
| `+0x440` | `screen+0x1928` | the MIN value (`@0x4b245b`) |

### Off-by-one trap in the per-row refill

`@0x4b25be` computes `lea edi,[esp+0x60]`, then **`push ebp` at `@0x4b25c6` moves esp
by -4** before `lea esi,[esp+0x64]` at `@0x4b25ce`. The two `lea`s therefore name the
*same* address: the widget's record block starts at `rec+0x00`, **not** `rec+0x04`.

## Column map (12 numeric cells, x in widget space)

Separators pushed by the draw method: `0, 0x91, 0xa8, 0xd1, 0xf8, 0x10f, 0x12a, 0x15e,
0x192, 0x1c6, 0x1dd, 0x1f4, 0x20b, 0x222`. Cell `[0, 0x91]` is the `#` + `PLAYER` block.

| # | column | cell x | widget dword | **record offset** | participant offset |
|---|--------|--------|--------------|-------------------|--------------------|
| 1 | `MP` | `0x91..0xa8` | `+0x3f4` | **`+0x00`** | `+0xec` |
| 2 | `MIN` | `0xa8..0xd1` | `+0x3f8` | **`+0x04`** | `+0xf0` |
| 3 | `RATING` | `0xd1..0xf8` | **computed** | — | — |
| 4 | `MoM` | `0xf8..0x10f` | `+0x400` | **`+0x0c`** | `+0xf8` |
| 5 | `G.` | `0x10f..0x12a` | `+0x404` | **`+0x10`** | `+0xfc` |
| 6 | `SHOTS` | `0x12a..0x15e` | `+0x408` / `+0x40c` | **`+0x14` / `+0x18`** | `+0x100` / `+0x104` |
| 7 | `PASSES` | `0x15e..0x192` | `+0x410` / `+0x414` | **`+0x1c` / `+0x20`** | `+0x108` / `+0x10c` |
| 8 | `TAC.` | `0x192..0x1c6` | `+0x418` / `+0x41c` | **`+0x24` / `+0x28`** | `+0x110` / `+0x114` |
| 9 | `S.` | `0x1c6..0x1dd` | `+0x420` | **`+0x2c`** | `+0x118` |
| 10 | yellow | `0x1dd..0x1f4` | `+0x424` | **`+0x30`** | `+0x11c` |
| 11 | red | `0x1f4..0x20b` | `+0x428` | **`+0x34`** | `+0x120` |
| 12 | injury | `0x20b..0x222` | `+0x430` | **`+0x3c`** | `+0x128` |

**Never drawn:** `rec+0x08` (`+0x3fc`, feeds RATING only), `rec+0x38` (`+0x42c`, an MoM
eligibility gate — see below) and `rec+0x40` (`+0x434`). All three are still summed into
the TEAM TOTAL row.

The injury cell skipping `+0x42c` and landing on `+0x430` is corroborated by the screen's
persistent-store path, which explicitly writes `rec+0x3c = byte playerobj+0x23`
(`@0x4b2233`) — i.e. `rec+0x3c` **is** the injury field.

### Cell formatting

* Single cells: `sprintf("%u", v)` when `v != 0`, otherwise the literal `"-"`
  (`0x653bc4 = "%u"`, `0x654448 = "-"`).
* `x/y` pairs: when `first + second == 0` the whole cell is the literal `"-/-"`
  (`0x654f44`). Otherwise **`x = first`, `y = first + second`** — the numerator is
  right-aligned, the `/` (`0x654c74`) is centred in the cell, the denominator is
  left-aligned (`@0x4b075d..0x4b0938`, `%ld` = `0x652f00`). So the record stores
  *(succeeded, failed)* and the screen prints *succeeded / attempted*.
* `MoM` and injury draw only while `widget+0x438 != 0`.
* `RATING` draws only while `MIN` (`rec+0x04`) `> 0` (`@0x4b04ed..0x4b0503`), else `"-"`.

## RATING is computed, never stored

`@0x4b03f6..0x4b04cb`:

```
ratio(n, d) = 0 if n + d == 0 else (100 * n) // (n + d)      # unsigned div

A = ratio(rec+0x08, rec+0x04)      # NOTE: numerator is the SECOND field of the pair
B = ratio(rec+0x14, rec+0x18)      # SHOTS
C = ratio(rec+0x1c, rec+0x20)      # PASSES
D = ratio(rec+0x24, rec+0x28)      # TAC.
M = (A + B + C + D) >> 2
RATING = 4 + (6 * (M + 10 * min(rec+0x10, 10))) // 100
```

`>> 2` is `shr` (unsigned) and `// 100` is the `0x51EB851F`/`shr 5` magic-multiply, so
both truncate. The range is 4..16.

**This settles the "RATING TEAM TOTAL is neither a sum nor a constant" gap** in
`statistics_screen_re.md`: the totals row is just another widget of the same class, so
its RATING is the same formula applied to the totals record (whose `+0x08..+0x40` slots
are column sums). Nothing reads a stored rating anywhere.

### Independently confirmed by the Man-of-the-Match selector

`FUN_0044a370` (`@0x44a370`, called from `FUN_00448b60 @0x448f21` and
`FUN_0044d520 @0x44d531`) walks the same report arrays and recomputes **the identical
four ratios and the identical `M + 10*min(rec+0x10, 10)` score** (`@0x44a463..0x44a617`)
to pick the highest-scoring record, writing that record's pid into `DAT_0066afd0+0xac`.
The pairs it uses — `(+0x08 over +0x04+0x08)`, `(+0x14 over +0x14+0x18)`,
`(+0x1c over +0x1c+0x20)`, `(+0x24 over +0x24+0x28)` — match the draw method exactly.
It compares with `jbe` (`@0x44a617`), so the **first** record wins a tie. Records are
skipped when `rec+0x38 != 0` (`@0x44a40c`), `rec+0x30 >= 2` (two yellows, `@0x44a448`)
or `rec+0x34 != 0` (red, `@0x44a455`). *The selector itself is not ported yet — no oracle
banked — so `rec+0x38`'s meaning stays unnamed.*

## TEAM TOTAL row (`@0x4b2322..0x4b246c`)

| totals slot | report-array source | club-squad source |
|-------------|---------------------|-------------------|
| `+0x00` (MP) | constant `1` (`@0x4b21ed`) | `sum` of a vtable `+0xf4` call over `0x66b190..0x66b1c8` |
| `+0x04` (MIN) | **`max`** of `rec+0x04` over rows (`@0x4b21d0`) | `club+0x274` (`@0x4b221a`) |
| `+0x08 .. +0x40` | per-column **`sum`** (`@0x4b2398..0x4b241d`) | same |

`sum(rec+0x00)` and `sum(rec+0x04)` *are* computed in that loop and then discarded — the
two constants above overwrite them. This is exactly what the live frames show.

`club+0x274` is written by the career-match runner: `+= 0x78` (120) when
`F+0x58 != 0` **and** `F+0x48 != 0`, else `+= 0x5a` (90) — `@0x449189..0x4491b3`, for
both clubs. It is the club's season minutes.

## Live verification

`screenshots/wine-captures-2026-07-24-statistics-live/` frames 02 (Man Utd half-time)
and 06 (Man Utd full-time), 640x480, widget origin x = **25**.

**Geometry — exact.** Predicted separator screen-x `[25, 170, 193, 234, 273, 296, 323,
375, 427, 479, 502, 525, 548, 571]` equals the observed dark-navy `(30,52,98)` columns in
both frames, all 14, zero drift.

**Totals arithmetic — exact.** Full-time Man Utd: `SHOTS 10/13`, `PASSES 33/68`,
`TAC. 22/65` are the per-column sums of the numerators *and* of the printed
denominators, which is only possible if the printed denominator is `first + second` and
the totals row sums both fields — as the disassembly says. `G. 1`, `S. 13`, yellow `1`
are plain column sums. `MP` reads `1` (not 11) and `MIN` reads `90` — the **max**, with
Solskjaer on 45 and everyone else on 90. A sum would read 945.

**RATING — 24 cells, no counter-example.** `tools/re/verify_statrow_rating.py` inverts
the formula for every printed rating. Everything except `rec+0x08` is legible off the
frame, so each row pins an interval for its own `rec+0x08`; the run reports every
interval non-empty, the full-time intervals compatible with the half-time ones (`+0xf4`
only accumulates), and the implied column sums inside the accumulator's budget
(`FUN_00450510` hands out exactly `dur` involvement counts across all 22 participants).

```
$ python3 tools/re/verify_statrow_rating.py
...
VERDICT: SURVIVES — 24 rating cells across 2 live frames
```

## What this corrects in the older docs

* `season_stats_re.md`: widget stride `0x41c` -> **`0x444`**; `+0x04`, `+0x08`,
  `+0x14..+0x28`, `+0x2c..+0x40` are now named (except `+0x38` / `+0x40`).
* `stat_match_engine_re.md`'s provisional `FUN_00450510` labels: participant `+0x104` is
  **not** "key-pass" (it is SHOTS-failed), `+0x10c` is **not** "tackles" (PASSES-failed),
  `+0x110` is **not** "dribble" (TAC.-succeeded) and `+0x114` is **not** "rating"
  (TAC.-failed). Participant `+0x108` = PASSES-succeeded was already right.
  No rating is stored anywhere.

## Reproduce

```
python3 tools/re/verify_statrow_rating.py                  # the 24-cell falsification run
.re-venv/bin/python tools/re/fdump.py 0x4afc50 0x90        # row-widget setup
.re-venv/bin/python tools/re/fdump.py 0x4afce0 0x1400      # the draw method
.re-venv/bin/python tools/re/fdump.py 0x44a370 0x580       # MoM selector, same formula
```
(`fdump.py` needs a valid instruction boundary; for a mid-function VA disassemble from
the function entry and filter.)
