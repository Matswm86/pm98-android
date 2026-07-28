# FINANCES ("INCOME + EXPENSES") screen — FRAME-TRUE rebuild (2026-07-13)

Status: BUILT — all six view/period combinations 0 px against their frames
(summary: p0495/p0509; detail: 006/008/012, 2026-07-27). Open: the `N bonuses`
count model, the SIGN-row label grammar, the summary view's chart axis scale
(LATENT DEFECT §end), the two unmeasured domestic-cup TV fees. The summary's
dynamic euro label is CLOSED (2026-07-27, both witnessed arms 0 px).

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

#### CORRECTED 2026-07-28: the LEAGUE fee is PER DIVISION, and the port was paying everyone the Premier figure

"Premier League £90,000 (confirmed constant)" was true only of the division it was measured
in. Three careers were driven from the title screen at TOTAL control and **all four English
divisions are now witnessed** (frames in `tools/re/refs/lowdiv-2026-07-28/`):

| division | club | fee | when |
|---|---|---|---|
| Premier | Manchester Utd. | **£90,000** | Sat 25 Oct 1997 + Sat 7 Feb 1998 (REFRUN R6) |
| First | Birmingham C | **£45,000** | seven cards, weeks 9-24 |
| Second | Blackpool | **£35,000** | week 8 |
| Third | Barnet | **£35,000** | week 7 |
| Third | Brighton & HA | **£35,000** | weeks 14 + 16 (s76, `tools/re/refs/cupfee-2026-07-28/`) |

**The Third-Division rung is now witnessed on a SECOND club.** A fourth career was driven at
TOTAL control for s76 (Brighton & HA, Third Division, from the title screen) and both channelTV
cards it raised — Sat 8 Nov 1997 (week 14) and Sat 22 Nov 1997 (week 16) — read the same
**£35,000**. So the figure is not a Barnet-specific one.

Two things worth keeping. **The ladder is not proportional** — 90k → 45k is a halving, but
45k → 35k is not, so no formula was inferred and each rung is a captured number. And
**Second and Third pay the SAME fee**, which is the same shared-arm shape the ground-grade
preset selector has: `FUN_0057d780`'s jump table sends competition indices 2 and 3 to one
arm (`stadium_screen_re.md`). That is circumstantial, not proof, and is recorded as such —
but it does say the producer is very likely keyed on the same `club+0x50` competition index.

Ported: `FinanceModel.LEAGUE_TV_FEE` + `league_tv_fee()`, read by `Career._post_home_match`
and `Career._queue_channel_tv`; gate `app/tests/test_channeltv_screen.gd`, which also pins
the non-proportionality so a later tidy-up cannot smooth it into a formula the game does
not have.

#### The field, traced in the binary (2026-07-28)

The 2026-07-28 claim "the card reads `club+0x290`" is now **verified against MANAGER.EXE**,
and the field's whole lifetime is mapped:

| site | what it does |
|---|---|
| `FUN_00545FD0` @0x546188 | `cmp [club+0x290], 0` — the weekly hub run raises the card only when the fee is non-zero |
| @0x546214 | reads it into the card's draw call |
| @0x54624a | clears it to 0 once the card has been shown |
| `FUN_005724E0` | the card itself: the fee arrives as its FIRST stack argument (a float), is money-formatted (flags 0x1402) and concatenated after `"For "` (0x661c30); the art is `RECURSOS\PREMIER\ICONOS\TV\canalTV.bmp` (0x661c08) |
| `FUN_0057A980` @0x57ab1d | the weekly pass books it as income — and ONLY for the club whose `+0x5c != 0xffff` (the hot-seat slot), which is why it is a manager-only line |
| @0x5799d7 | zero-initialised when a club record is built |
| @0x57cb15 / @0x57cb1f, @0x57bed8 | round-trips through the save |

**What is still not found, stated so the next session does not repeat the search:** the
site that WRITES the fee. There is no `mov [reg+0x290], <value>` anywhere in `.text`
outside the three sites above (a byte-accurate scan of the whole section for the
displacement `0x00000290`, including the imm32 encodings, returns 40 instructions and none
of them is a producer on the club record), so the producer must reach the field through an
aliased base pointer. And the fee is **not a constant anywhere**: 90,000 / 187,500 /
375,000 appear as neither u32 nor f32 nor f64 in MANAGER.EXE, and a scan of every shipped
file under the game directory finds none of them either. It is computed at runtime.

So the cup fees still cannot be ported without either that producer or a captured CUP home
tie, and the port continues to pay £0 and flag it.

**2026-07-28 addendum — the search now has a shape it did not have.** The three driven
careers proved the LEAGUE fee varies by division (above), so whatever writes `club+0x290`
takes the competition into account; it is not a per-club data byte any more than
`club+0x50` was. The three lower-division drives banked ten channelTV cards between them
and **not one was a cup tie** — the Birmingham career reached week 24 (F.A. Cup third-round
territory) before stalling on an injured-XI modal, and the two shorter drives never got
past the autumn. So the cup fee is still open, and it is open for the same reason as
before: nobody has watched the card come up on a cup home tie.

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

### The PER WEEK view — BUILT 2026-07-25, render-diffed at 0 px

`chrome_perweek.png` is a second bake off `p0495_finance_perweek_wk31.png` (the reference
run's LIVE week, whose every value cell already reads £0, so the only spans the bake has
to clear beyond the shared body are the week label and the date). `FinanceScreen` gained
a view switch on the original's own two tabs and the stepper's own arrows.

**Two frames, 0 differing pixels each**, everywhere except the balance chart:

| region | `finance_perweek_31` vs `p0495` | `finance_perweek_29` vs `p0509` |
|---|---|---|
| tab strip · week label · date span | 0 | 0 |
| income column · expense column · totals | 0 | 0 |
| LAST WEEK / CURRENT WEEK tiles | 0 | 0 |
| balance chart | 3912 (excluded) | 3912 (excluded) |

The chart is the ONLY exclusion: the frame carries the reference season's own 52 weeks of
bars and the shot is fed the two weeks the run actually measured, so the rest cannot be
drawn without inventing figures.

Reproduce:

```bash
python3 tools/re/build_finance_chrome_from_frames.py
~/godot462 --headless --path app --import
DISPLAY=:5 PM98_SHOT_DIR=<dir> ~/godot462 --rendering-driver opengl3 \
    --resolution 640x480 --path app --script res://tests/shot_finance_perweek.gd
python3 tools/re/diff_finance_perweek_parity.py <dir>
```

#### Three things the render-diff corrected, on BOTH views

The PER SEASON view had never been render-diffed — only its chrome was baked — and the
overlay it drew was wrong in three ways that the PER WEEK diff exposed. Each replacement
was pinned by rendering EVERY BMFont atlas the game ships against the frame's own pixels
and keeping only the zero-differing-pixel answer:

| element | was | IS (0 px) |
|---|---|---|
| ledger value cells | calend8, right edge 305 / 601 | **euro8**, pen END 306 / 602, pen top 99 + 16i |
| TOTAL INCOME / EXPENSES | proman8 @11 | **proman10**, pen END 307 / 605, pen top 284 |
| LAST / CURRENT WEEK tiles | calend12 @15 | **proman8**, pen END 226 / 459, tops 429 / 441 / 453 |
| SEASON header | proman8, `SEASON 1997 · 98` | **proman10**, `SEASON 1997 - 98`, pen END 601 |

And the chrome bake itself over-cleared: the LAST WEEK value cell was blanked to x=248
and the CURRENT WEEK cell to x=498, which wiped the LAST WEEK box's right border, the
CURRENT WEEK box's left border and 30 px of the desktop behind it. The real cells stop
inside their own black box frames at x=228 and x=461.

#### The header, solved

| span | content | font / ink | anchor |
|---|---|---|---|
| gold box `300..391` | `CURRENT 31` / `29` | proman10, `(255,223,0)` | centred, `floor((693 - advance) / 2)`, pen top 60 |
| white panel | `From 1-2-1998 to 7-2-1998` | proman8, `(128,128,128)` | pen x 416, pen top 60 |

`CURRENT ` is prefixed only while the stepper is parked on the live week — witnessed on
all three captured frames (`CURRENT 31`, `CURRENT 4`, and a bare `29` when stepped back).

#### Witnessed, and therefore copied

The LAST WEEK / CURRENT WEEK tiles and the BALANCE chart do **not** follow the stepper:
`p0495` and `p0509` are two different selected weeks with byte-identical tiles and chart.

## The INCOME + EXPENSES detail views — BUILT 2026-07-27, render-diffed at 0 px

> The previous edition of this file ended "No frame of either was ever captured" — a
> claim its OWN binding table (frames 006/008/011/012, above) refuted. The same false
> line lived in `FinanceScreen.gd`. Deleted on both sides; the habit that catches
> these: grep the frame inventory before repeating a gap.

Chromes: `tools/re/build_finance_chrome_from_frames.py` `bake_details()` —
`chrome_income.png` off 006 (INCOME / PER WEEK) and `chrome_expenses.png` off 011
(EXPENSES / PER SEASON; 011==012 body pixel-for-pixel, they differ only by the mouse).
The mouse's hover ring on each frame's lit tab is repaired from the neighbouring frame
(007's INCOME tab, 013's PER SEASON tab) and the baker asserts the transplant. The two
UN-captured period variants are composited, not invented: 010 vs 011 proves the detail
BODY is identical across periods, and the tab-strip / header-band rects (P1/P2) diff to
ZERO both across careers (004 vs p0495) and across views (013 vs 011), so
`chrome_income_perseason.png` and `chrome_expenses_perweek.png` are original pixels
throughout.

Solved on the frames (0 differing pixels, BMFont atlas method):

| element | font | anchor | ink |
|---|---|---|---|
| value cells | euro8 | pen END 299 (left col) / 596 (right), top = plate top + 1 | black |
| wage / hospital gross sub-rows | euro8 | same | `(80,110,5)` green |
| insurance sub-rows | euro8 | same | `(42,95,170)` blue |
| `SALE <name>` label | euro8 | pen 341 | `(60,90,0)` dark green |
| `Players´ Wage` / `N bonuses` labels | euro8 | pen 43 | black |
| `Staff Wages` label | euro8 | pen 340 | black |
| `Not played` ×2 | euro8 | pen 339, tops 96 / 174 | `(128,128,128)` |
| the single TOTAL bar | proman10 | pen END 605, top 381 | `(30,52,98)` / `(170,0,0)` |

The view tabs: `INC. + EXP.` (8,7,100,25) · `INCOME` (116,7,100,25) · `EXPENSES`
(224,7,100,25) — measured by the method that re-derives both period-tab rects exactly.

Witnessed RULES the scene now follows:

* **The data-driven labels appear only beside a posted figure** — 008's £0 week shows
  empty label cells where 012's season shows `Players´ Wage` / `50 bonuses` /
  `Staff Wages`.
* **The CURRENT WEEK tile and the stepper's live week read the RUNNING record** —
  frames 004/006 carry the Cruyff sale under CURRENT WEEK before the week has closed
  (and the season totals of 012/013 include it). `Career.live_week_book()` (the
  running `_wk`, now also saved as `week_open`).
* **LAST WEEK / CASH is a STORED close-of-week figure, not a derivation** — frame 006:
  LAST £7,556,099 + current-week income £9,120,000 = £16,676,099, £1 off the live
  £16,676,098. A derived figure could not disagree, so the original stores it;
  `Career.cash_close` does the same (the £1 itself is the original's own unexplained
  dirt, reproduced in the parity harness by feeding both stored figures).
* **Every empty cell reads £0** exactly as the frames show for a fresh save.

Data mapping (`Career` detail record, `FinanceModel.new_ledger_detail`): per-competition
TICKETS/TELEVISION split by `_post_home_match`'s own comp key (league / `cup:` /
euro brackets / charity); every EUROPEAN CUP INCOME posting = the euro section's POINTS
row (incl. the Charity Shield purse, which the summary already books on that line and
which has no row of its own — keeps visible rows summing to the TOTAL); wage
gross/refund and hospital gross/group2/group3 sub-rows from the insurance tick (pay3
derived as pay−pay2 so sub-rows always sum exactly to the canonical line); `SALE <name>`
from the sell flow; GROUND cats seats/carpark/facility/service → SEATS/CAR PARK/
FACILITIES/EXTRAS.

Gate: `tools/re/diff_finance_detail_parity.py` — three shots
(`app/tests/shot_finance_detail.gd`) vs 006 / 008 / 012, **0 px everywhere**; the only
exclusion per frame is the camera cursor's hover ring on the tab the mouse sat on.
No chart exclusion: the detail views carry no chart.

Open, honestly flagged (NOT built):

* **`N bonuses`** — the count is data-driven (`detail.bonus_n`) and nothing sets it:
  the original's per-player bonus model is not reversed ("50 bonuses" for £5,000 by
  week 4 vs our flat £5,000/home-matchday). The label is drawn only when a count exists.
* **A SIGN label** on the expenses TRANSFERS row — no frame witnesses the grammar
  (Man Utd bought nobody), so a signing shows its fee with a bare label cell.
* **Several sales in one scope** — only the single-sale `SALE <name>` grammar is
  witnessed; more than one sale shows the summed fee with a bare label cell.
* **The euro section header is baked static** (`EUROPEAN CUP`, Man Utd's competition).
  A U.E.F.A. Cup / Cup Winners' Cup career keeps the witnessed header — no detail-view
  frame of another euro competition exists.
* **`Not played` clears when the one-off tie is played**; what the original prints
  INSTEAD (if anything) is unwitnessed — the app prints nothing.

## LATENT DEFECT recorded 2026-07-27 — the SUMMARY view's euro label + chart axis

`orig/51_finance_season.png` (parity run, a non-European lower-club career) shows
**`U.E.F.A. CUP INCOME`** where frame 013 (Man Utd, European Cup) shows
**`EUROPEAN CUP INCOME`**, and a **`±250 K.`** chart axis where 013 shows `±2,500 K.` —
both are DYNAMIC in the original and both are baked static into `chrome.png` (013's
values). Two witnesses are not enough to derive either rule (the label default appears
to be U.E.F.A. CUP INCOME with European Cup participation switching it; the axis scale
driver is unknown — wealth? division?), so this stays a recorded defect rather than a
guessed fix. Closes when a third career state is captured.

**HALF-CLOSED 2026-07-27 — the LABEL rule is no longer a guess, it is read from the
binary.** No third capture was needed. `.data` holds **three** labels, not two:

| VA | string |
|---|---|
| 0x659B0C | `EUROPEAN CUP INCOME` |
| 0x659AE0 | `U.E.F.A. CUP INCOME` |
| 0x659AF4 + 0x659B00 | `CUP WINNERS` + ` CUP INCOME` (drawn as one label) |

and the drawing site is one chain of branches in `0x5081B0..0x50838F`, each arm pushing
its own label into the same `FUN_005DA180` / `FUN_00436240` text call — 0x5081E3 and
0x508219 push `EUROPEAN CUP INCOME`, 0x508295 and 0x5082CB push the `CUP WINNERS` pair,
0x508334 and 0x508367 push `U.E.F.A. CUP INCOME`, selected by a virtual predicate on the
competition object at `DAT_0066B1B0` (`call [vt+0x48]` at 0x50823F). So the row is
**"the European competition this club is IN"**, one of the three, and the two witnesses
were simply two different entrants — exactly the reading the note above suspected, now
with the code behind it.

**BUILT 2026-07-27 — the LABEL half is CLOSED, and both witnessed arms are 0 px.**
The decompile `docs/re/finance/fn_0050812e_FUN_0050812e.c` shows the chain is a
three-arm ladder over two competition globals, with U.E.F.A. as the **fall-through**:

```
if      ((*DAT_0066b1b4)->vt[0x48]() != 0)  ->  EUROPEAN CUP INCOME      0x659B0C
else if ((*DAT_0066b1b0)->vt[0x48]() != 0)  ->  CUP WINNERS CUP INCOME   0x659AF4+0x659B00
else                                        ->  U.E.F.A. CUP INCOME      0x659AE0
```

which is exactly why the non-European career reads `U.E.F.A. CUP INCOME`: it is not a
"UEFA default", it is the arm nothing else claimed.

* **Baker** (`build_finance_chrome_from_frames.py`, `EURO_LABEL_BOX`): the label plate
  is flat — in y146..158 the panel is `(220,220,220)` from x32 to x197 between white
  rules at x25..31 and x198..199, asserted at bake time and cross-checked between the
  two witnesses, which are **pixel-identical everywhere outside the ink**. So the refill
  is the original's own ground, not a reconstruction. Blanked in `blank_body`, so both
  summary chromes get it.
* **Scene**: `FinanceScreen.EURO_LABELS` / `_draw_ledger`, fed `oneoff.euro_comp` from
  `Career.euro_income_comp()` (membership = entered this season, `euro_seeds`). Font,
  pen and ink are READ, not chosen — `tools/re/probe_text_anchor.py` returns an
  identical-bitmap match on both frames: **proman8, pen (34,147), ink (80,110,5)**.
* **Gate**: `tools/re/diff_finance_eurolabel_parity.py` +
  `app/tests/shot_finance_eurolabel.gd`. `european_cup` vs `013_164406` **0 px**,
  `uefa_cup` vs `orig/51_finance_season.png` **0 px** — two arms, two different careers.
  `diff_finance_perweek_parity` and `diff_finance_detail_parity` re-run green.
* **Still declared**: the `CUP WINNERS CUP INCOME` arm has no capture. Its string is the
  binary's own and the gate asserts only that it renders and differs from the other two.

~~**Still open: the `±N K.` chart axis scale.**~~ — **CLOSED 2026-07-28, from the binary,
and it took a render defect with it.**

`FUN_00509760` walks the plotted weeks accumulating the largest **|week-on-week balance
delta|** (@0x50994a..0x509990 — the routine also proves the chart plots the DELTA, not the
running total: `FUN_0057fce0` returns the cumulative balance and the loop stores
`value - running` per week). It then picks the **smallest entry of a three-float table that
is at least that peak**, walking down from the largest at @0x509a31..0x509a57:

| .data | value | label |
|---|---|---|
| 0x659540 | 50,000,000f | `250` |
| 0x659544 | 100,000,000f | `500` |
| 0x659548 | 500,000,000f | `2,500` |

and prints that entry × `5e-06` (the double at 0x62d930) between `"+"` / `"-"` (0x6587d4 /
0x654448) and `" K."` (0x659b2c), in the face the same routine selects by name at
@0x509d92: **`euro8`** (0x6597a4). So the original can draw exactly three axes, and both
witnessed frames are two of them.

**The render defect it exposed.** The baker blanked the plot field over `x60..634 /
y333..377`, but the field is `x76..604 / y332..374` — so the blank ran over the two AXIS
LABEL PLATES at `x28..74` and wiped the `" K."` off both of them. The shipped chrome read
`+2,500` / `-2,500` with the unit missing and the plate edge overpainted. Both are fixed:
the plates are blanked to their own flat grounds ((0,0,160) and (85,0,0)) and the label is
drawn live, centred in the plate (field sum 28 + 74 + 1 = 103) at pen top plate + 5, in the
witnessed inks (117,147,187) / (255,31,0). The bars now use the original's own cadence too
(52 slots at a 10 px pitch, @0x509a67).

Gate: `tools/re/diff_finance_axis_parity.py` — **both witnessed states 0 px** on both
plates (`013_164406.png` ±2,500 K., `orig/51_finance_season.png` ±250 K.), and the
un-captured middle step renders and is asserted distinct from both.
That half stays a recorded defect and wants the next finance capture.
