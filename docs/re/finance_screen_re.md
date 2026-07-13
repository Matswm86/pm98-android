# FINANCES ("INCOME + EXPENSES") screen — FRAME-TRUE rebuild (2026-07-13)

The earlier "reversed-from-MANAGER.EXE" hand-drawn version was **rejected as
invented** (wrong labels, invented tab colours, an invented SET PRICES button + a
cash cheat, wrong header, wrong ledger line-items). This rebuild throws that away
and reproduces the **real captured frame** 1:1, following the PreseasonScreen
frame-bake precedent.

## Binding frames (walkthrough RUN 3, ~16:43-16:44)

`screenshots/original-walkthrough-2026-07-02/` — the FINANCES tour is frames
004-015:

| frame | view |
|---|---|
| 004_164346 (==005) | INC. + EXP. / PER WEEK summary |
| 006_164349 | INCOME detail / PER WEEK (per-competition sections + named `SALE Jordi Cruyff`) |
| 008_164357 (==009) | EXPENSES detail / PER WEEK (transfers, wage sub-rows, hospitals/insurance groups, ground improvements, loans 1-4) |
| 012_164404 | EXPENSES detail / PER SEASON (populated: `PLAYERS' WAGE 676,442`, `50 bonuses 5,000`, `Staff Wages 1,211`) |
| **013_164406 == 014_164407** | **INC. + EXP. / PER SEASON summary — THE BAKED VIEW** |

**013/014 is the baked view** because `FinanceModel.summary` yields **season**
figures, so the model's numbers belong on the PER-SEASON summary. The frame's own
column totals verify the value mapping exactly:

```
TICKETS 541,500 + PUBLICITY 9,750 + TELEVISION 187,500 + SALE 9,120,000 = TOTAL INCOME 9,858,750
PLAYERS' WAGE 676,442 + PLAYERS' BONUS 5,000 + STAFF WAGES 1,211        = TOTAL EXPENSES 682,653
```

## Real layout (frame 013) — what the screen actually is

- **Top tab strip** (baked): view tabs `INC. + EXP.` / `INCOME` / `EXPENSES`
  (left) and period tabs `PER WEEK` / `PER SEASON` (right); the selected tab shows
  a yellow down-arrow. NOT a plaque header — the finance screen has NO manager/club
  plaque, NO SET PRICES button, NO cash cheat.
- **Content header** (baked): `INCOME + EXPENSES` (blue, left) + dynamic
  `SEASON YYYY · YY` (black, right).
- **INCOME column** (7 rows): TICKETS, PUBLICITY, TELEVISION, EUROPEAN CUP INCOME,
  SALE + LOAN PLAY., INSURANCE GROUP 3, LOANS → `TOTAL INCOME` (blue box, blue ink).
- **EXPENSES column** (11 rows): SIGN PLAYER, CANCELLATION, PLAYERS' WAGE,
  PLAYERS' BONUS, PLAYERS' INCENTIVE, PLAYERS' INSURANCE, HOSPITALS, STAFF WAGES,
  REFORM GROUND, FINES, LOANS AND INTEREST → `TOTAL EXPENSES` (yellow box, red ink).
- **WEEKLY BALANCE chart**: dark header (`BALANCE` / `▼ WEEKLY BALANCE TABLE`),
  fixed ±2,500K axis, blue field above zero / yellow below, week ticks 1/10/…/50.
- **Bottom**: `LAST WEEK` + `CURRENT WEEK` boxes, each INCOME / EXPENSES / CASH
  (CASH in gold), and the `RETURN` button (globe icon).

## Frame-bake pipeline

`tools/re/build_finance_chrome_from_frames.py`:
1. crop frame 013 (641→640) ;
2. blank ONLY the dynamic value cells by column-copy (18 ledger cells, 2 totals,
   6 bottom-box values, SEASON, the captured chart bars) — every label / section /
   tab / chart-frame / border stays as original pixels ;
3. → `app/art/screens/finance/chrome.png` (+ `finance_chrome.json` anchors).

`app/scenes/FinanceScreen.gd` draws `chrome.png` 1:1 at 640×480 and overlays only
the live numbers, in the **narrow WINFONTS the game actually uses** (verified by
glyph-width against the frame; NOT proman10):

| element | font | native size |
|---|---|---|
| ledger income/expense values | **Calend8** (5px digits) | 15 |
| LAST/CURRENT WEEK values | **Calend12** (7px digits) | 15 |
| the two totals + SEASON | **Proman8** (8px digits) | 11 |

## Model → frame value mapping (frame-true vs approximated vs gap)

`FinanceModel.summary(club, tier)` (season projection; the real per-line figures
are a runtime float ledger with no save-game, see `finance_constants.md`).

- **FRAME-TRUE (exact)**: TICKETS ← gate; TELEVISION ← tv; the two TOTALs (= the
  summed columns, matching the frame arithmetic).
- **APPROXIMATED (bucket mapping, documented)**: PUBLICITY ← boards + sponsor;
  PLAYERS' WAGE ← wages; PLAYERS' BONUS ← bonus. LAST/CURRENT WEEK income+expenses
  = season figure / 52 (no per-week history); CASH is the real Career figure.
- **HONEST GAP (shown as £0 exactly as the frame shows for a fresh save)**:
  EUROPEAN CUP INCOME, SALE + LOAN PLAY., INSURANCE GROUP 3, LOANS, SIGN PLAYER,
  CANCELLATION, PLAYERS' INCENTIVE, PLAYERS' INSURANCE, HOSPITALS, STAFF WAGES
  (non-player), REFORM GROUND, FINES, LOANS AND INTEREST.
- **HONEST GAP (chart)**: the WEEKLY BALANCE per-week series is a runtime float
  ledger we do not have; the scene plots the model's single `weekly_balance` flat
  across elapsed weeks on the fixed axis — deliberately NO invented variation.
- **NOT YET BUILT (flagged)**: the INCOME / EXPENSES detail views and the PER WEEK
  period (frames 006/008/012) are not interactive; the baked view is the
  INC.+EXP./PER SEASON summary only. Tab-switching is a future increment.

## Parity

Render `finance_demo.png` vs frame 013 over all **static (non-value) chrome**:
**99.95 % exact-match** on 241,966 pixels, mean Δ 0.078; the only Δ>40 pixels fall
inside the LAST/CURRENT WEEK value rows, where our club's numbers differ from the
captured Man Utd numbers (dynamic-value bleed, not chrome). The ledger/tabs/section
headers/chart-frame/borders are pixel-identical.

## WIRING note (Main.gd — NOT edited here)

`FinanceScreen` keeps `setup(summary, club, manager, season, cash, week)` and the
signals `back_pressed` / `prices_pressed` / `cheat_cash` so `Main._show_finance_screen`
still compiles and connects unchanged. Behaviour change: the frame-true screen has
**no SET PRICES button and no cash cheat**, so `prices_pressed` / `cheat_cash` are
never emitted (only RETURN → `back_pressed`). Main can therefore drop its
`scr.prices_pressed.connect(_show_finance_control)` and `scr.cheat_cash.connect(...)`
lines (harmless if left). The board TICKET PRICE / SPONSOR BOARDS controls belong on
the **GROUND / improvements** flow (walkthrough frames 066-069), not FINANCES —
that is where PM98 actually sets them.
