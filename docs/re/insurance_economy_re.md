# INSURANCE ECONOMY — BINARY-EXACT (2026-07-24)

Closes `insurance_screen_re.md`'s "premium CHARGING cadence + injury payout flow
un-RE'd" gap, `injuries_screen_re.md` §Gaps #3 (the `PRICE` / `INSUR.` / `COST`
columns "resting furniture") and the FINANCES screen's `PLAYERS' INSURANCE` /
`HOSPITALS` / `INSURANCE GROUP 3` £0 lines.

Everything below is read from `extracted/Premier Manager 98/MANAGER.EXE` with
`tools/re/{fdump,pe,xref_scan}.py`, cross-checked against the Ghidra decompiles
already in `docs/re/finance/` and the one witnessed populated INJURIES row
(`screenshots/wine-captures-2026-07-18-goalscorers/83_injuries_populated.png`).
No frame guessing, no fitting.

> **Money unit.** 200 internal = £1 (`transfer_value_re.md` §10). Every constant
> is given in internal units *and* in £.

## 1. The premium — `FUN_0058c020(group, monthlyWage)`

```
group 1 -> q = monthly / 150 ; if q <  40,000 -> q =  40,000     (£200)
group 2 -> q = monthly / 120 ; if q < 100,000 -> q = 100,000     (£500)
group 3 -> q = monthly /  70 ; if q < 200,000 -> q = 200,000   (£1,000)
other   -> 0
return q - (q % 1000)                       # floored to a multiple of £5
```
The three divisions are the compiler's reciprocal-multiply idioms — magic
`0x1b4e81b5 >> 4` (= /150), `0x88888889 >> 6` (= /120) and `0xd41d41d5` with the
shift-add correction `>> 6` (= /70) — and the common tail at `0x58c0d7` is the
`% 1000` floor.

**This is why the two wine witnesses saw identical prices.** Ward (£1,250/month)
and Frandsen (£14,583/month) both land under every clamp, so both price at
£200/£500/£1,000. A player only leaves the group 1 clamp above **£30,000 a
month**. The app's old `INSURANCE_PRICES = {1: 200, 2: 500, 3: 1000}` flat
constant was a correct reading of the witness and a wrong reading of the game;
it is replaced by the formula.

## 2. The payout percentage — `FUN_0058c000(group)`

```
group 2 -> 50        group 3 -> 100        everything else -> 0
```
`(al != 3)` -> `setne cl` / `dec ecx` / `and ecx, 0x64` is the 100-or-0 branch.
**GROUP 1 reimburses nothing.** That is the binary, not a missing case.

## 3. The injury price — `FUN_00584e00(injuryRecord)`

`byte[rec+1]` — the injury's **TOTAL** rolled duration (`player+0x69`,
`injury_model_re.md`) — times `3 * 5^5 * 32` = **300,000 internal = £1,500 per
week**.

Witness 83 confirms it end to end: Branagan, *pulled hamstring* (type 4, duration
formula `B+2` -> 2..3 weeks), Week **3**, `PRICE` **£4,500** = 3 x £1,500.

## 4. The INJURIES row — `@0x543770 .. 0x543d85`

| cell | source | draw rect (row-relative) | ink |
|---|---|---|---|
| TYPE OF INJURY | `FUN_00584e50` (the diagnosis) | 155..329 | black |
| Week | `byte[rec+0]`, weeks STILL to run | 330..358 | `0xffffff` |
| H | `FUN_00584e20` is_serious -> `YES` / `NO` | 359..381 | `d6 3c 00` / black |
| PRICE | §3 | 382..455 | `18 34 63` |
| INSUR. | `byte[player+0xb5]`: 0 -> `NO`, else the digit | 456..511 (digit 469..480) | `39 51 63` / black |
| COST | `PRICE - PRICE * pct / 100` (`@0x543ca7`) | 512..582 | `0xffffff` |

Row rects are offset by **+28** on screen (measured: `PRICE` 382+28 = 410, which
is exactly the witness's cell). A **zero COST is not drawn** — `@0x543cd2` tests
the result and skips the whole draw — so a GROUP 3 injury shows an empty cell,
not "£0".

## 5. The weekly finance pass — `@0x57f382 .. 0x57f4ed`

Per player in the club's squad list (`club+0x24`, chained on `player+0x100`):

```
weeklyWage  = yearly(+0x74) * 1/52    [0x638df8]
monthlyWage = yearly(+0x74) * 1/12    [0x638dfc]
+0x50 += weeklyWage                                       (every player)
group = byte[player+0xb5]
if group: +0x60 += premium(group, monthlyWage) * 12 / 52
if byte[player+0x68]:                                     (injured)
    wk = price(total) / weeksLeft                         (fild / fidiv)
    +0x64 += wk
    if group:
        +0x54 += weeklyWage
        group 2: +0x68 += 50  * wk * 0.01                 [0x638e00 = 0.01]
        group 3: +0x6c += 100 * wk * 0.01
                 +0x70 += FUN_0058bfd0(group) + weeklyWage
```

`FUN_0058bfd0` returns `premium(3, 0.0) / 3` = `200,000 / 3` = 66,666 internal =
**£333.33**, and only for group 3.

Note the original divides the injury price by the **remaining** weeks, not the
total, so the weekly hospital bill climbs as the man heals. Reproduced verbatim.

### Ledger slots -> screen lines

The 18 FINANCES rows are built in `FUN_00508be4` from the per-week record
(`club+0x1e4`, stride `0x20c`), in frame order:

| row | getter | record | line |
|---|---|---|---|
| inc 5 | `FUN_00580000` | +0x70 | **INSURANCE GROUP 3** |
| exp 2 | `FUN_0057ff00 - FUN_0057ff20` | +0x50 - +0x54 | **PLAYERS' WAGE** |
| exp 5 | `FUN_0057ff80` | +0x60 | **PLAYERS' INSURANCE** |
| exp 6 | `FUN_0057ffa0 - FUN_0057ffc0 - FUN_0057ffe0` | +0x64 - +0x68 - +0x6c | **HOSPITALS** |
| exp 7 | `FUN_00580020` | +0x74 | STAFF WAGES (the 13-role loop `@0x57f377`) |

**Cash follows the ledger exactly.** Every one of those setters tail-calls
`FUN_00580cd0(club, amount)`, which adds the same signed amount to the club
balance at `club+0x1ec` — negated (`fchs`) for the expense setters, positive for
the payout / refund / income ones. So an insured injured player genuinely has his
wage refunded, and a GROUP 3 policy genuinely books wage + £333 as income on top
of covering the treatment. That is PM98's own model, not an interpretation.

## 6. Ported

- `app/scripts/Insurance.gd` — every function above, in internal units so the
  integer truncation happens where the original's does.
- `app/scripts/Availability.gd` — stores `injury_weeks_total` (`player+0x69`)
  when a diagnosis is rolled; clears it on recovery / season reset.
- `app/scripts/Career.gd` — `_tick_insurance()` in the weekly cash tick, the
  four season-to-date accumulators (`ins_premiums` / `ins_hospitals` /
  `ins_wage_refund` / `ins_group3_income`, saved and loaded), and
  `insurance_price()` replacing the flat `INSURANCE_PRICES` constant.
- `app/scenes/InjuriesScreen.gd` — the H / PRICE / INSUR. / COST cells and the
  frame-cut populated-row strip (`tools/re/build_injuries_row_from_frame.py`).
- `app/scenes/InsuranceScreen.gd` — `price_of(player, group)` replaces the flat
  price on both the row COST cell and the POLICY modal.
- `app/scenes/FinanceScreen.gd` — the three ledger lines + the PLAYERS' WAGE
  netting; the two totals now sum the drawn columns (the frame's own arithmetic).

## 7. Verification

- `app/tests/test_insurance.gd` — 44 asserts: every clamp corner, the £5 floor,
  both wine-witness wages, the payout table, witness 83's £4,500, the
  price/remaining hospital divisor, the group 3 bonus, the whole weekly pass, and
  an end-to-end `Career` week proving cash == the ledger and that it survives a
  save round-trip.
- **Render-diff `0 px`**: `app/tests/shot_injuries_row_verify.gd` +
  `tools/re/diff_injuries_row_parity.py` compare the rendered Branagan row
  (y104..121) against witness 83 cell by cell — PHYS. / N / PLAYER / cross /
  TYPE / Week / H / PRICE / INSUR. / COST all **100.00 % exact**.
  Whole-body residual is 228 px in the PHYSIOTHERAPIST band only, which is
  pre-existing chrome-bake drift (the chrome came from run-2 frame 034, the
  witness from the 07-18 run) and untouched by this work.
- `app/tests/shot_finance_insurance_verify.gd` renders the FINANCES ledger off a
  live 10-week career with one man in each policy group injured; the three
  figures land on their labelled rows and the totals sum the columns.

## 8. Reproduce

```
python3 tools/re/fdump.py 0x58c000 0x180     # payout % + premium
python3 tools/re/fdump.py 0x584e00 0x20      # injury price
python3 tools/re/fdump.py 0x58bfd0 0x30      # the group 3 weekly bonus
python3 tools/re/fdump.py 0x57f2a0 0x260     # the weekly finance pass
python3 tools/re/fdump.py 0x543770 0x620     # the INJURIES row builder
python3 tools/re/fdump.py 0x580cd0 0x50      # the balance adjuster
```
`0x57f330` and `0x543960` both start mid-instruction for a linear disassembler —
use the resync sweep in `tools/re/dispscan.py`, or dump from the earlier
addresses above.

## 9. Still open

- **`player+0x98` on the INJURIES screen**: nothing here uses it. See
  `offer_record_re.md` §6 for the transfer-list flag.
- ~~**The insured-row document icon**~~ (`@0x543b09`): **CLOSED 2026-07-24.** `screenshots/wine-captures-2026-07-24-cadence-season-store/
  07_injuries_row_insured_giggs.png` finally witnesses it: Giggs (Group 1) picked up a
  7-week dislocated wrist in a live career, and his INSUR. cell reads
  `[document icon] 1        0%` with COST equal to the full PRICE (£10,500) — i.e. **group
  1 pays 0%**, so the icon marks "a policy exists", not "a payout happened". The sprite
  occupies **x487..494 (8 px) x y266..275 (10 px)** inside the cell (cell border x483) on
  that 640x480 frame: a document with a folded top-right corner and two darker text rules.
  Remaining: cut it into the row strip (a baker pass); the port still draws the policy
  digit alone.
- **PHYS.** (the treatment checkbox) is still resting furniture — the row strip
  carries its unticked face verbatim; the ticked state is unwitnessed.
- **The weekly-illness path** (`roll_A` @0x5850b0) still isn't modelled, so only
  match injuries ever reach this economy (`injury_model_re.md` §Still open).
