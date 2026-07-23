# TRANSFER MARKET (FICHAR) screen — reversed layout from MANAGER.EXE

640×480 px, lifted from `FUN_00532a50` (the draw routine reached only through the
screen object's vtable; the constructor `FUN_00532a10` sets `PTR_LAB_00631ba8`).
Decompile: `docs/re/transfer/fn_00532a50_FUN_00532a50.c`. Anchored on the title
`"TRANSFER MARKET"` @ `.data 0x65c274` and the `recursos\iconos\fichar\` assets.
Immediates read straight from the disassembly (capstone), not the lossy decompile.

## Frame-true rebuild + divergence list (2026-07-13)

The old `TransferScreen.gd` was **rejected as invented**. The screen is now baked
FRAME-TRUE from the real walkthrough, following the PreseasonScreen / FinanceScreen
frame-bake precedent:

- **Binding frame**: `screenshots/original-walkthrough-2026-07-02/097_164707.png`
  (Man Utd, Saturday 23 August 1997, Premier / Week 3) — the real TRANSFER MARKET
  (FICHAR) screen.
- **Bake tool**: `tools/re/build_transfer_chrome_from_frames.py` cuts the frame's
  pixels 1:1 into `app/art/screens/transfer/chrome.png` (barra + column headers +
  scrollbar + nav column + FONDO all baked), blanking ONLY the KEEPER header cell +
  the list body; the `[+]` sprite is cut to `plus.png`. The scene redraws the band
  headers + live rows over the baked chrome.

**Element-by-element: OLD (invented, rejected) → FRAME 097 (truth) → NOW (rebuilt).**

| Element | OLD invented layout | FRAME 097 | Rebuilt scene |
|---|---|---|---|
| Columns | PLAYER / RATING / AV / MO / AGE / CLUB FEE / WAGE / CLUB | `[+]` \| flag \| Name \| ★ \| **AV MO CLUB FEE WAGE YEARS** | matches frame (baked headers) |
| Band names | RED, **plural** (KEEPERS…) | **navy `(0,0,128)`, singular** KEEPER/DEFENDER/MIDFIELDER/FORWARD | navy singular ✓ |
| Band caps | — | `[3,5,5,5]` fixed slots (`DAT_0065c020`), dearest first, blanks stay | `[3,5,5,5]`, dearest-first ✓ |
| Row lead | club crest | `[+]` expand box | `plus.png` (cut 1:1) ✓ |
| BANK box | fabricated £ box | **absent** | removed ✓ |
| "Window: OPEN / N offers left" | fabricated text | **absent** | removed (fields kept in `setup()` sig only) ✓ |
| Bottom strip | invented "top target" line | plain help band (baked) | baked, no invented text ✓ |
| Nav column | — | CURRENT OFFERS / SCOUT / OFFERS / RETURN (right) | baked; hit-rects only ✓ |
| Scrolling | ARROW up/down paging list | **inert** — 18-slot grid always fits; scrollbar is baked art | no scroll model ✓ |

**Frame-measured inks / geometry (sampled off 097, dom-ink):**
`AV = (212,63,0)` orange-red (was mis-set (210,0,0)); `MO = (75,109,172)` blue;
`CLUB FEE = (210,0,0)` red; `WAGE = (150,0,0)` maroon (was (144,0,0)); `YEARS =
(42,63,170)` navy; band = `(0,0,128)`. **Value grid = ProMan8** (`_f8`@8): frame packs
`£12,500,000` into ~55px (x285..340); `_f10`@11 rendered 98px and overflowed AV/MO —
fixed. AV right-edge x250, FEE right x337, WAGE right x404 (all verified in-shot).

**FRAME-TRUE:** barra region, column headers, band names+colour, `[+]` box, star column,
scrollbar, nav chrome, FONDO, and (since 2026-07-23) the AV/MO/FEE/WAGE ink boxes
and the star strip, pixel-matched to frame 097.

**CLOSED 2026-07-23 — every value cell is now source-backed.** The three "honest gaps"
and the two "accepted approximations" this section used to list are gone; what replaced
each, with its evidence:

| cell | was | now |
|---|---|---|
| **AV** | the CA attribute | **core4 >> 2** (`FUN_00534570`, `transfer_value_re.md` §1) |
| **stars** | `CA/20` vector polygons, 5 grey slots | **halves = (AV+1) div 10** (drawer `FUN_004f79b0`) on the frame-cut STARJUGON art at the frame's own x156 / pitch-14 / 12x9 geometry, **no dim placeholders** (frame 097 draws none) |
| **MO** | `-` ("un-RE'd dynamic save value") | **displayed morale** `FUN_00582db0` via `Morale.display` — RE'd 2026-07-03 (`morale_re.md`); the gap note was simply stale |
| **CLUB FEE / WAGE** | "the app's valuation model; real fees un-portable float data" | the **RE'd lookup tables** `feeTable/wageTable[stature*54 + abilTier*6 + ageTier] x5000` (`FUN_00576cd0`, `transfer_value_re.md` §10/§12/§13) — also stale; the port landed 07-22d |
| **YEARS \| LEFT** | `-` ("not in the market row") | the term `FUN_00576cd0` rolls at generation (rec+0x18/+0x19; age ladder in `offer_record_re.md` §4). The final year gets frame 097's pale-yellow chip `(255,255,170)` x446..469, 12 rows from slot_y+2, with a red `(255,31,0)` digit |
| **nationality flag** | `-` (no flagCode on the row) | `flagCode` = player record byte **+0x1a** (`player_info_re.md`), threaded through `TransferMarket.market()` |

**Value-grid faces re-measured — the old grid was mis-drawn.** The screen drew every value
in `proman8 @8`, i.e. proman8 SCALED DOWN from its native 11, which mashed 8/9/comma
glyphs into blobs (a "9" read as "0"). Two faces at their NATIVE sizes reproduce frame
097's ink runs exactly (row slot_y=156): AV "79" x235..249 and MO "86" x260..274 =
**proman8 @11**; FEE "£1,000,000" x293..336 (44px) and WAGE "£350,000" x365..403 (39px)
and the YEARS digits = **calend8 @15** (advance 44 / 39 — exact; the FinanceScreen ledger
precedent). After the fix the app's AV/MO/FEE/WAGE ink boxes match the frame's to the
pixel, verified by `app/tests/shot_transfer_market_verify.gd`.

**Remaining honest gap — one, and it is a term not a value:** the MO **club term**
(`FUN_0057b710`: gate receipts + fair-wage bonus) needs the SELLING club's ledger, which
the app only simulates for the manager's own club. An AI club's row therefore shows the
player's stored base morale, never a fabricated number.

**Known parity item, pre-existing:** the original paints each value cell as a white box
with a grey border (a full row grid); the app draws only the horizontal row separators
over the blanked panel fill. Not introduced here, and not faked here.


**Parity (rendered `transfer_demo.png` vs frame 097):** columns land under the baked
headers with no overlap — AV_right 248 (frame 249), FEE 281–335 (frame 285–340), WAGE
366–402 (frame 358–406), 33–36px AV→FEE gap. Structurally 1:1 with frame 097 modulo the
honest gaps above.

**WIRING (owned by Main.gd, unchanged):** `Main._show_transfer_screen()` already calls the
8-arg `setup(market, club, manager, season, cash, window, offers, week)` and connects
`back_pressed` (queue_free), `current_offers_pressed` (→ CURRENT OFFERS screen), and
`player_pressed` (→ MakeOfferScreen). **SCOUT** and **OFFERS** are sourced nav buttons but
not yet wired to a screen (scene hit-tests them, emits nothing — no-op). No Main edit was
needed.

## Reversed-source detail (below supersedes only the pre-rebuild "Build mapping")

Geometry helpers (same family proven on finance/squad/lineup):
- `FUN_00436fb0(x,y)` → a point. Pushed `push y; push x; call`.
- `FUN_00436fd0(pos,size)` → `Rect(pos.x, pos.y, pos.x+size.x, pos.y+size.y)`.
  In each text/blit block the FIRST `FUN_00436fb0` builds the **size**, the
  SECOND builds the **pos**; calibrated against the known title box.
- `FUN_00437020(r,g,b)` set text colour; `FUN_00436270(packedRGB)` set fill.
- `FUN_004f50c0(this, pos, size)` lays the scrolling list panel (and registers the
  18 `camrol%02u.bmp` role icons + the incidencia/star icons).
- `FUN_005c06d0(this, "...bmp", ...)` blits a bitmap asset.

## Reversed elements
- **Title** `"TRANSFER MARKET"` (0x65c274): `FUN_00436fd0(pos=(150,16), size=(297,27))`
  = (150,16)..(447,43); in-game font ProMan10. (We draw it in the BARRA bar in
  ProMan14, the workspace tab-title convention shared with the other screens.)
- **List panel** (`FUN_004f50c0`): `pos=(8,72) size=(490,363)` = (8,72)..(498,435);
  16 px rows. The panel scrolls in the original (arrowup/arrowdown on/off icons
  registered at the top: `RECURSOS\iconos\arrowup{on,off}.bmp` + `arrowdown…`).
- **Position bands**: the outer loop walks the 4-entry table `DAT_0065c020 = [3,5,5,5]`
  → KEEPERS(3) / DEFENDERS(5) / MIDFIELDERS(5) / FORWARDS(5) = the 18 `camrol`
  role slots. Each band has a header drawn in `FUN_00437020(0x78,0x8c,0xa0)`
  (blue-grey) then fixed slots, filled with the player row or left blank.
  `FUN_00586eb0(band)` returns the live count for the band.
- **Right-hand nav column** (each a separate button widget, label at screen x≈512,
  size (112,25), drawn through `widget->vtable+0xC0`):
  - `CURRENT OFFERS` (0x65b700) at y=286
  - `SCOUT` (0x65a8f8) at y=323, icon `recursos\iconos\fichar\secretario.bmp` (32 px)
  - `OFFERS` (0x65c2d0) at y=360, icon `recursos\iconos\fichar\ofertas.bmp` (32 px)
  - `RETURN` (0x6549e4) at y=440 (same y as the squad screen's RETURN)
- **Bottom help line**: ProMan8 text band at pos=(8,440) size=(490,26).

## Build mapping (→ `app/scenes/TransferScreen.gd`)
> ⚠ SUPERSEDED by "Frame-true rebuild + divergence list (2026-07-13)" above. The column
> list + BANK box + plural band names below describe the **rejected invented** layout and
> are kept only as the RE trail. The shipped screen matches frame 097, not this text.
- FONDO + BARRA; BARRA title "TRANSFER MARKET" at (150,16) ProMan14 + manager/club/
  bank chrome.
- List panel (8,72)..(498,435), 16 px rows, ProMan8 grid. Columns are the buyable-
  market fields (the screen's authentic ROLE / NAME / CLUB FEE / YEARLY WAGE / CLUB):
  a ★ key / ♥ shortlist flag, NAME, AGE, AB (CA), CLUB FEE, YEARLY WAGE, CLUB.
- **The original's 4 bands KEEPERS / DEFENDERS / MIDFIELDERS / FORWARDS**, each capped
  to its `[3,5,5,5]` slot count (`DAT_0065c020`), dearest target per band first — same
  split as the SQUAD screen. Unblocked by the demarcación-byte decode
  (`docs/re/positions_re.md`): the 4-way GK/DF/MF/FW position is the band key. (The
  per-player 18-way `camrol` sub-role — DFC/LD/MC… — remains finer than we decode;
  the 4 visible bands match the original's headers, which is what the screen shows.)
- Right nav column at x≈512: a BANK box + CURRENT OFFERS / SCOUT / OFFERS / RETURN
  labelled cells (the secretario/ofertas bitmaps live in `recursos\iconos\fichar\`;
  represented as labelled buttons, the same convention the squad screen used for
  YOUTH TEAM / RETURN).
- Driven live by `Career.market()` (`TransferMarket.market`), which already sorts
  dearest first; the screen takes the row list (GameDB-free, headless-testable).

## Free agents (T2 #9)
PM98 lets you sign out-of-contract players on a free. A **FREE AGENTS** entry on the
transfer desk lists `Career.free_agents`; tapping one opens a wage negotiation
(`Career.sign_free_agent` → `Contract.evaluate_renewal`: accepts at/above his demand, balks
just below, refuses a lowball) and signs him for **no fee** onto the live squad + wage bill.
Same board guards as a transfer (window, weekly offers, squad max), minus cash. The pool is
seeded at career start and refreshed each season by `TransferMarket.generate_free_agents`
(released journeymen, GameDB-free, reusing the Youth name pools + attribute builder), and the
manager's own **non-renewed leavers drop into it** at the season rollover (capped at
`FREE_POOL_CAP`). New career state (`free_agents` / `free_seq`) round-trips through save/load.
Test: `app/tests/test_free_agents.gd`.

## Loans — loan IN (T2 #8)
A **LOAN MARKET** entry on the transfer desk lists other clubs' fringe (their non-first-XI
surplus, `TransferMarket.loan_market`); confirming `Career.sign_loan(pid, parent)` takes the
player for the season for **no fee** (you pick up his wage), removing him from his parent's
roster and stamping `on_loan` / `loan_from` on his dict. Same board guards as a signing
(window / weekly offers / squad max). A loanee **cannot be sold** (`accept_sale` guard) and is
tagged `[ON LOAN]` in MY SQUAD. At the season rollover `_return_loanees()` runs first (before
contracts tick, so a loanee is never mistaken for an expiring player of yours) and sends him
back to his parent club. State rides the existing `rosters` serialization (the `on_loan` flag
is on the player dict), so it round-trips for free. Test: `app/tests/test_loans.gd`.
NOT modeled (deferred, honest scope): loaning your own players OUT, loan-to-buy options, and
"free if relegated" clauses — `TransferMarket.gd` notes those strings as faithful surface.
