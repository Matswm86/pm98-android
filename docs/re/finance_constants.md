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

## Still to extract (next pass)
- Domestic league **position prize money** table (numeric block, not string-encoded).
- Numeric values for ticket price defaults, board prices, loan interest %, insurance
  group payouts, win/scoring bonus defaults (these live as imm32 in the screens above —
  follow the xref'd code at e.g. `0x50ccc0` "Win bonus", `0x52c0f7` "Scoring bonus").
