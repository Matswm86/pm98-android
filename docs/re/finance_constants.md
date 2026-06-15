# PM98 finance constants — extracted from MANAGER.EXE (Path 3)

Method: plaintext string scan of `.rdata`/`.data` + `push imm32` / `mov reg,imm32`
xref scan over `.text` (`tools/re/strings_xref.py`). All VAs below are virtual
addresses in `MANAGER.EXE`. Values in display strings use the European thousands
separator `.` (so `255.000` = 255,000).

## European / UEFA competition prize schedule (VERIFIED — string-encoded)

Contiguous prize-message block at VA `0x653518`–`0x653680`, shown to the player when
competing in / progressing through the European Cup / UEFA Cup. The amounts are
embedded directly in the message text (no separate imm32 — the text IS the value):

| Event | Amount | Source string VA |
|---|---|---|
| Compete in championship (entry) | 1,000,000 | `0x65352c` "1 million from UEFA for competing in this championship" |
| Per **draw** match | 255,000 | `0x653583` "255.000 for every draw match" |
| Per **win** match | 510,000 | `0x6535a6` "510.000 for every match won." |
| Qualify to **quarter finals** | 1,500,000 | `0x6535d8` "1.5 million from UEFA for your qualification" |
| Qualify to **semifinals** | 1,625,000 | `0x653644` "1.625 million from UEFA for your qualification" |

Note: win reward = exactly 2× draw reward. These are EUROPEAN-competition rewards,
**not** the domestic league position prize money (that table is a separate numeric
block, not yet located — the `'Prizes'` string at `0x653000` is only a UI column
label returned by a string-getter at `0x4425d0`, not the table).

## Finance ledger line items (VERIFIED — label strings + code xrefs)

These are the income/expense categories the weekly/seasonal finance engine posts to.
Each has live `push imm32` xrefs into `.text` (the code that renders the ledger row),
confirming they are real, used labels — they document the structure of the finance
system to reproduce:

Income side: `TOTAL INCOME` (0x659810), `TICKETS` (0x659774), `SPONSORS AND SALES`
(0x659760), `SPONSORSHIP MONEY` (0x656188), `SPONSOR BOARDS SOLD` (0x65619c),
`ATTENDANCE MONEY` (0x6561b0), `SALE + LOAN PLAY.` (0x659acc),
`U.E.F.A. CUP INCOME` (0x659ae0), `EUROPEAN CUP INCOME` (0x659b0c),
`INSURANCE COMPENSATION GROUP 3` (0x6597b4), `INSURANCE GROUP 3` (0x659ab8).

Expense side: `STAFF WAGES` (0x6599ec / "Staff Wages" 0x6598c4),
`TRANSFERS` (0x6597d4), `LOANS` (0x6597ac), `LOANS AND INTEREST` (0x659a78),
`FINES` (0x6599d0), `BONUS` (0x65a34c / " bonuses" 0x6598ec).

Player-contract terms (transfer/contract screens):
`CLUB FEE` (0x65be64), `YEARLY WAGE` (0x65b7c0), `Win bonus` (0x65a4c0),
`Scoring bonus` (0x65be2c), `Free if relegated` (0x65be50), `Costless` (0x65d858).
Ticketing / sponsorship controls: `TICKET PRICE` (0x65b66c),
`PRICE OF BOARD` (0x65b67c), `SPONSOR BOARDS` (0x65b65c).

Weekly balance: `WEEKLY BALANCE TABLE` (0x659b34), `BALANCE` (0x659b4c),
`INCOME + EXPENSES` (0x6595e0).

## Finance data model — the weekly ledger record (VERIFIED, session 4)

The two open hypotheses from session 2/3 ("a static domestic position-prize table"
and "numeric defaults sitting as imm32 in the finance screens") are now **resolved,
and both were wrong about being static**. The finance system is a **dynamic per-club
float ledger**, not a constant table.

Traced from the `LOANS AND INTEREST` summary screen `FUN_00508be4` (VA `0x508be4`,
references `0x659a78`) and its 26 line-item accessor callees `FUN_0057fd60`–`FUN_005806e0`:

- The club object holds an **array of weekly finance records** at `*(club + 0x1e4)`.
- Each weekly record is **`0x20c` = 524 bytes**.
- A season is **`0x34` = 52 weeks**; the summary screen sums a line item across all
  52 records (season-to-date) in the `if` branch, or shows one week in the `else`.
- Each line-item getter is a **pure accumulator**: seed `_DAT_00638dd8 = 0.0f`, then
  sum a contiguous run of `float` sub-fields at a fixed offset inside the week record.
  Examples (offset within the 524-byte record, run length):
  `FUN_005804d0` +0x8c ×14 · `FUN_00580540` +0xc4 ×14 · `FUN_0057fd60` +0x14 strided×4.
  These are summed/subtracted in `FUN_00508be4` to build the income/expense rows whose
  labels are the ledger strings in the section above (TICKETS, SPONSORS, STAFF WAGES…).

**Consequence for fidelity work:** there is **no closed-form domestic prize/income
formula and no static default table to extract**. Domestic income (gate receipts, TV,
sponsorship) and expenses (wages, transfers, loans+interest) are accumulated as
80-bit x87 floats into this per-week record by the simulation as the season runs.
The *initial* values (opening ticket price, board price, loan terms, etc.) are
**loaded from the club database at new-game**, not hardcoded as code immediates — so
they live in the data files, consistent with PM98's database-driven design, not in
`MANAGER.EXE`. The only **static, code-resident** prize schedule is the European/UEFA
one in the section above.

## Finance SCREEN structure (VERIFIED — render functions decompiled)

The finance/management screens are vtable-dispatched render methods (so they have no
direct `call` xref; Ghidra needed forced function creation at the label-push sites).
Decompiles in `docs/re/finance/`. Confirmed screen fields:

- **Prices screen** (`FUN_00520083` TICKET PRICE / `FUN_0052000b` PRICE OF BOARD):
  rows for `TICKET PRICE`, `PRICE OF BOARD`, `SPONSOR BOARDS`, plus a conditional
  "You have an offer to sell all the [sponsor boards]" prompt
  (`s_You_have_an_offer_to_sell_all_th_0065b608`) gated on club flags at `+0x1e0`.
- **Win bonus screen** (`FUN_0050ccc0`): renders `Win bonus` + `for %s`
  (`s_for__s_0065a4b8`) — i.e. a **per-player** win bonus, not a club-wide constant.
- **Scoring bonus screen** (`FUN_0052c0f7`): offers `Scoring bonus` with a
  `House and car` (`0x65be1c`) alternative vs a cash `OFFER` — a contract-incentive
  chooser, again per-player, no static amount in code.

Note: the integer operands in these render calls (e.g. `0xe6, 0x35, 0x19e, 0x42`) are
**screen-layout coordinates** (x, y, w, h, colour) passed to the text widgets
`FUN_005d9d80`/`FUN_005da180`, NOT money values — verified by their reuse as identical
geometry across unrelated labels. Do not mine them as finance constants.

`'Prizes'` (`0x653000`) is returned by the 6-byte stub getter `FUN_004425d0` and is a
UI column label only (confirmed: no `call` xref, address-taken into a vtable).
