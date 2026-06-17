# TRANSFER MARKET (FICHAR) screen — reversed layout from MANAGER.EXE

640×480 px, lifted from `FUN_00532a50` (the draw routine reached only through the
screen object's vtable; the constructor `FUN_00532a10` sets `PTR_LAB_00631ba8`).
Decompile: `docs/re/transfer/fn_00532a50_FUN_00532a50.c`. Anchored on the title
`"TRANSFER MARKET"` @ `.data 0x65c274` and the `recursos\iconos\fichar\` assets.
Immediates read straight from the disassembly (capstone), not the lossy decompile.

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
- FONDO + BARRA; BARRA title "TRANSFER MARKET" at (150,16) ProMan14 + manager/club/
  bank chrome.
- List panel (8,72)..(498,435), 16 px rows, ProMan8 grid. Columns are the buyable-
  market fields (the screen's authentic ROLE / NAME / CLUB FEE / YEARLY WAGE / CLUB):
  a ★ key / ♥ shortlist flag, NAME, AGE, AB (CA), CLUB FEE, YEARLY WAGE, CLUB.
- **Sections KEEPERS / OUTFIELD only**, dearest first — same honest split as the
  SQUAD screen. The original's 4-band KEEPERS/DEFENDERS/MIDFIELDERS/FORWARDS needs
  the per-player 18-way `camrol` role code, which is NOT yet decoded out of the DB
  (carry-over blocker: "player outfield positions not decoded"); guessing it would
  invent data, so we render the two bands we can derive faithfully (`isGK`).
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
