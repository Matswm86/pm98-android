# OFFER / CONTRACT record — BINARY-EXACT (2026-07-23)

Closes the carried TODO#3 ("RENEW wage-stepper increment is un-RE'd — a documented
placeholder", same for MAKE OFFER) plus the TRANSFER MARKET's `YEARS | LEFT` honest gap,
and corrects `transfer_value_re.md §9.2`'s framing of where the fee/wage floats live.

Everything below is read from `extracted/Premier Manager 98/MANAGER.EXE` with
`tools/re/{fdump,dispscan,datdump}.py` — no wine, no frame guessing, no fitting.

> **Money unit.** The engine stores money in its own integer-ish float unit; the display
> path divides by **200** (`transfer_value_re.md §10`). Every constant here is given in
> internal units *and* in £. 200 internal = £1 (PM98 is a Spanish title; the internal unit
> reads as pesetas at the 1997 ≈200 ptas/£ rate).

## 1. The record — embedded in the player at +0x6c

`FUN_0057a5a0` (the per-club squad pass) calls the generator with `lea ecx,[esi+0x6c]`, so
the record is a **sub-struct of the player**. That reconciles §9.2's "player+0x70 = fee /
+0x74 = wage" with the OFFER form's own `rec+4` / `rec+8`:

| rec | player | type | field |
|---|---|---|---|
| +0x00 | +0x6c | u16 | club id |
| +0x04 | +0x70 | f32 | **CLUB FEE** |
| +0x08 | +0x74 | f32 | **YEARLY WAGE** |
| +0x0c | +0x78 | f32 | clause money (0 / 1e6 = £5,000 / 2e6 = £10,000) |
| +0x10 | +0x7c | i32 | clause flag A |
| +0x14 | +0x80 | i32 | clause flag B |
| +0x18 | +0x84 | u8 | **YEARS** (contract term) |
| +0x19 | +0x85 | u8 | **LEFT** (years remaining) |
| +0x1a | +0x86 | u8 | matches-to-renew target (20; 1-year deals only) |
| +0x1c | +0x88 | f32 | the third money cell / the bid the accept test compares |

Getters used by the form: `FUN_00528860` = `fld [rec+4]` (CLUB FEE cell, widget +0x4eac),
`FUN_00528870` = `fld [rec+8]` (YEARLY WAGE cell, +0x52c4), `FUN_00528880` =
`byte[rec+0x18]` (YEARS cell, +0x56dc). Third money cell -> widget +0x6324.

## 2. The ◄/► money stepper — VALUE-DEPENDENT, not hold-dependent

One handler pair per money field (`+0x4`, `+0x8`, `+0x1c`), all identical:

```
UP    0x529a20 / 0x529b80 / 0x529cf0        DOWN  0x529ac0 / 0x529c20 / 0x529da0
  v = rec[field]                              v = rec[field]
  if v < 10,000,000: v += 1,000,000           if v <= 1,000,000: return   (test ah,0x41)
  elif v < 50,000,000: v += 2,000,000         if v < 10,000,000: v -= 1,000,000
  else: v += 5,000,000                        elif v < 50,000,000: v -= 2,000,000
  rec[field] = v; reformat the label          else: v -= 5,000,000
```
(The UP path reaches the same numbers by `fsub` of the NEGATIVE constants at
`0x631278/88/90`; DOWN `fsub`s the positive twins at `0x631298/a0/a8`. Thresholds
`0x631270` = 10,000,000 and `0x631280` = 50,000,000.)

**In £:**

| current value | step |
|---|---|
| below £50,000 | **£5,000** |
| £50,000 .. £249,999 | **£10,000** |
| £250,000 and up | **£25,000** |

Floor: ◄ leaves the value alone at or below **£5,000**. There is **no acceleration ramp**
and no per-player "never below his current wage" clamp — both were app inventions
(`MakeOfferScreen.TIERS`, `PlayerInfoScreen.OFF_WAGE_STEP_WK = 100`) and are deleted.

## 3. YEARS stepper — 1..5, mirrored onto LEFT

`0x529e40` (►) / `0x529f90` (◄): `y = byte[rec+0x18]`; UP bails at `y >= 5`, DOWN at
`y <= 1`; the new value is written to **both** `+0x18` (YEARS) and `+0x19` (LEFT); and
when the term leaves 1 year the handler zeroes `+0x1a` and disables three clause widgets
(`+0x4264`, `+0x361c`, `+0x3a34`). So the matches-to-renew clause exists **only on a
one-year deal**.

## 4. YEARS at generation — the age ladder in `FUN_00576cd0`

The same call that fills CLUB FEE and YEARLY WAGE rolls the contract term
(`@0x576d09` / `@0x576e5c`), with `r = rand(100)` via the game's own `FUN_0058df90`:

```
c = 2 if r < 50 else 1      d = 1 if r < 25 else 0      e = 1 if r < 12 else 0
age <= 22 -> c + 2      (4 @50%, 3 @50%)
age <= 25 -> e + d + c  (4 @12%, 3 @13%, 2 @25%, 1 @50%)
age <= 30 -> d + c      (3 @25%, 2 @25%, 1 @50%)
else      -> c          (2 @50%, 1 @50%)
```

`age` is `FUN_00584b50` = **`1997 - birthYear`** (`mov eax, 0x7cd; sub eax, [player+0xfc]`)
— an independent binary confirmation of the season-start age basis in
`transfer_value_re.md §14`. LEFT is stamped equal to YEARS at generation.

This replaces the app's invented `3 if age<=29 else 2 if age<=32 else 1` ladder in
`Career._seed_roster`.

## 5. Clause seeds (same call, `@0x576d16..0x576d71`), by AV = core4>>2

| AV | rec+0x10 | rec+0x14 | rec+0x1a | rec+0xc |
|---|---|---|---|---|
| >= 85 | 1 | 1 | – | £10,000 **if posFine == 9** |
| 80..84 | 1 | – | – | £5,000 **if posFine == 9** |
| 75..79 | 1 | – | 20 | – |
| 70..74 | – | – | 20 | – |
| < 70 | – | – | – | – |

then `if YEARS > 1: rec+0x1a = 0`. `posFine 9` = table idx 8 = **CENTRE FORWARD**
(`positions_re.md`) — i.e. the goal-bonus money is striker-only.

**Not claimed:** which of the four named checkboxes (`Free if relegated` / `Matches to
renew` / `Scoring bonus` / `House and car`) `rec+0x10` and `rec+0x14` map to. No frame
witnesses it, so the port carries them as numbered flags and renders no guessed label.
`rec+0x1a` is read as the matches-to-renew target on the evidence that the years handler
clears it exactly when a term stops being 1 year.

## 6. The accept test — `FUN_005889c0(player, offer)`

Single caller: `FUN_0058a360 @0x58a3f0` (transfer resolution).

```
m = (int16) word[player+0x9a]          # a PER-MILLE price modifier, init 1000 = 100%
if byte[player+0x98]: m -= 200         # the flag knocks 20% off
ask = fee                              # float player+0x70
if m < 1000: ask = fee * m * 0.001
accept iff bid (offer+0x1c) >= ask
```
Constants `_DAT_00638fb0/fb8/fc0` = **200.0 / 1000.0 / 0.001** (previously "un-extracted";
`transfer_value_re.md §9.3` read `+0x9a` as "contract years" — it is not).

`player+0x9a` is initialised to `0x3e8` (1000) at `0x581d2f`, clamped to **[500, 1250]** by
the adder at `0x584960`, and set to one of 1000 / 900 / 800 / 700 / 500-or-600 by
`FUN_005849a0` from an appearances/goals ratio against a position-banded threshold. The app
still requires full book value (the conservative end of that range); wiring the modifier is
the next step, and is now a bounded one — **not** shipped this session.

## 7. Ported

`app/scripts/OfferRecord.gd` (steps, years, seeds, `av_of`), used by
`MakeOfferScreen._step`, `PlayerInfoScreen._renew_input`, `Career._seed_roster` and
`TransferMarket.market`. Tests: `app/tests/test_offer_record.gd`,
`test_make_offer_screen`, `test_player_info_renew`. Render-diff:
`app/tests/shot_transfer_market_verify.gd`.

## 8. Reproduce

```
python3 tools/re/fdump.py 0x529a20 0x120      # money stepper (UP)
python3 tools/re/fdump.py 0x529e40 0x80       # YEARS stepper
python3 tools/re/fdump.py 0x576cd0 0x1c0      # the record generator
python3 tools/re/fdump.py 0x5889c0 0x80       # the accept test
python3 tools/re/dispscan.py 0x9a --mn mov,movsx,movzx   # the price-modifier writers
```

`tools/re/dispscan.py` is new this session: a linear .text sweep for a struct
displacement that **restarts one byte on after any undecodable byte** — capstone's
`disasm()` stops at the first bad byte, which silently truncated earlier scans long
before the 0x58xxxx range and is why the `+0x9a` writers were missed until now.
