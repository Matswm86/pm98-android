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

## PER WEEK — CAPTURED AND BUILT (2026-07-25)

The reference run caught the **INC. + EXP. / PER WEEK** view twice, and it settles the whole
economy (`docs/re/REFRUN_manutd_1997-98.md` R5/R6/R9/R16):

| frame | week | stamp |
|---|---|---|
| `screenshots/refrun-manutd-1997-98/novel/p0045_finance_perweek_wk4.png` | `CURRENT 4` | From 10-8-1997 to 16-8-1997 |
| `screenshots/refrun-manutd-1997-98/novel/p0509_finance_perweek_wk29.png` | 29, stepped back | From 1-2-1998 to 7-2-1998 |
| `screenshots/refrun-manutd-1997-98/novel/p0495_UNKNOWN.png` | `CURRENT 31` | From 15-2-1998 to 21-2-1998 |

Week 29 is a played HOME week and reads, exactly:

```
INCOME    TICKETS £364,980 · TELEVISION £90,000 · everything else £0   -> £454,980
EXPENSES  PLAYERS' WAGE £226,923 · PLAYERS' BONUS £5,000 ·
          STAFF WAGES £7,019 · everything else £0                      -> £238,942
```

and the following AWAY week reads income £0, expenses £233,942 = 226,923 + 7,019. So:

* **flat, every week:** PLAYERS' WAGE + STAFF WAGES
* **home matchday only:** TICKETS + TELEVISION + PLAYERS' BONUS
* **away week:** a pure loss

### What is now real in the app

`Career` keeps the books (`week_ledgers`, one record per completed week, capped at the
finance year's 52) and every cash movement posts through `_post_income` / `_post_expense`
against these same lines, so the bank and the ledger cannot drift. The screen draws:

* the **ledger rows** as season-to-date accruals off the real lines (was a projection);
* the **LAST WEEK / CURRENT WEEK** tiles off the real records — and matching the frames,
  CURRENT WEEK reads £0/£0 while the week is still running, with only CASH live;
* the **BALANCE chart** as one bar per banked week at its own finance-week slot, blue above
  the axis and red below (was one constant drawn flat across the elapsed weeks).

### The calendar

Finance week 1 opens **Sunday 20 July 1997** and the week runs Sunday..Saturday, so
`finance week = league week + 2`. Derived from the three stamps above, cross-checked against
the channelTV card (hub "Week 27", Saturday 7 February 1998, ledger week 29).
`FinanceModel.finance_week_span` reproduces all three verbatim.

### TICKET PRICE = £7.50, witnessed

The FULL TIME stadium panel prints CAPACITY, ATTENDANCE and ATTENDANCE MONEY together:
Old Trafford 21,014 in -> £157,605, Anfield 41,000 in -> £307,500. Both are exactly
attendance x 7.50, on two different clubs, so the opening price is a game default rather
than a per-club figure. Only the PREMIER is witnessed; the same default carries down the
pyramid because nothing witnessed says otherwise.

### TELEVISION = the channelTV fee, per competition

Premier **£90,000** · Charity Shield **£187,500** · European Cup **£375,000**. The card's
fee IS that week's TELEVISION line (proved on week 29). The Coca-Cola Cup, F.A. Cup,
U.E.F.A. Cup and Cup Winners' Cup fees were **not measured** and pay £0 — a visible gap,
not a guess.

### The channelTV card — BUILT

`app/scenes/ChannelTvScreen.gd`, chrome from
`tools/re/build_channeltv_card_from_frames.py`. The bake diffs the two captured cards
(`p0474_channel_tv.png` £90,000 and `p0032_channel_tv.png` £187,500) and REFUSES to run
unless they are byte-identical everywhere except the fee line and the OK button, so the
logo, the camera art and both body lines are the original's own pixels and the fee is the
only thing the scene draws. It rides the post-week unprompted-card chain (the same one the
monthly awards and the TEAM OFFER cards use), because the original raises it unprompted;
whether it comes before or after the XI-validity gate is NOT witnessed, so it does not gate
CONTINUE.

### Still not built

The PER WEEK view itself — the tab, the `WEEK  < CURRENT n >` stepper and the date stamp —
needs its own chrome bake off `p0495`, whose value cells are all £0 and therefore trivially
blankable. The DATA behind it now exists; only the view is missing.
