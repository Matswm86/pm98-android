# FINANCES (CAJA — "INCOME + EXPENSES") screen — reversed layout from MANAGER.EXE

640×480 px, lifted from `FUN_00501c2a` (+ the list-area `FUN_00502120`). Decompiles:
`docs/re/finance/fn_00501c2a_*.c`, `fn_00502120_*.c`. Anchored on `"INCOME + EXPENSES"`
@ `.data 0x6595e0`. Geometry via the `makeRect(pos,size)` helpers (`FUN_00436fb0/fd0`).

## Reversed elements
- **Content header bar** (`team+0x46c0`): `makeRect(pos=(21,51), size=(592,27))` =
  (21,51)..(613,78), font `Proman10`.
- **Title** `"INCOME + EXPENSES"`: drawn in that bar at rel `makeRect((10,7),(173,14))`
  → ≈ (31,58), colour `FUN_00437020(0x2a,0x3f,0xaa)` (blue), `ProMan10`.
- **Ledger list area** (`FUN_00502120`): `makeRect(pos=(21,78), size=(592,323))` =
  (21,78)..(613,401); the income/expense line-item rows scroll here, `Proman10`.
- **Bottom total boxes**: INCOME `makeRect((8,415),(221,50))` = (8,415)..(229,465);
  EXPENSES `makeRect((241,415),(221,50))` = (241,415)..(462,465).
- **Row markers**: `recursos\iconos\caja\flechaGreen.bmp` (income / up) and
  `flechaRed.bmp` (expense / down); list scroll arrows `flechal.bmp` / `flechar.bmp`.
  (`caja` = the cash-box screen.)

## Build mapping (→ `app/scenes/FinanceScreen.gd`)
- FONDO + BARRA; BARRA centre title "FINANCES" (the tab name, our convention) +
  manager/club chrome; content header bar at (21,51) reading "INCOME + EXPENSES".
- Ledger list in (21,78)..(613,401): an INCOME section (green ▲ rows) then an
  EXPENDITURE section (red ▼ rows), each row = marker + label + right-aligned £amount.
  Labels are PM98's authentic ledger items (FinanceModel: TICKETS / SPONSOR BOARDS
  SOLD / SPONSORSHIP MONEY / TELEVISION ; STAFF WAGES / BONUS).
- Bottom: INCOME total box (8,415,229,465) + EXPENSES total box (241,415,462,465) at
  the reversed coords, plus a BALANCE box on the free right area (470..632) — the
  natural completion (season balance), data from FinanceModel; flagged as our add.
- Driven by `FinanceModel.summary(club, tier)`; the screen takes the summary dict
  (GameDB-free, headless-testable).

## Board PRICE controls (T2 #6)
PM98's finance has TICKET PRICE / PRICE OF BOARD control screens; the figures were static
tier constants. Now a **SET PRICES** button (top strip, `BTN_PRICES`) emits `prices_pressed`;
`Main._show_finance_control()` is a PM98-chrome browse to cycle the **match ticket price** and
the **advertising-board price**, with a live preview of attendance / season gate + board
income. Stored on the career (`ticket_price` / `board_price`, save round-tripped) and applied
through `_club_with_roster` so the ledger reflects them. `FinanceModel.summary` reads
`club.ticket_price` / `club.board_price` (default = the tier constant, so non-managed clubs and
legacy callers are unchanged) and applies a **linear demand response**: attendance multiplier
`1.6 - 0.6*(ticket/default)`, boards-sold multiplier `1.5 - 0.5*(board/default)`. Both make
revenue a downward parabola, so gate peaks ~1.33x and board income ~1.5x the default price —
a real lever with a sweet spot, not "always charge the max". Win/scoring BONUS stays the gate-
linked pool (not yet a separate lever). Test: `app/tests/test_finance_control.gd`.
