# CURRENT OFFERS (OFERTAS) + the FICHAR hub — reversed from MANAGER.EXE

Decoded 2026-07-02 (strings → `pe.foff_to_va` → FindRefsTo → DecompileAt; decompiles
in `docs/re/ofertas/`). Visual reference: the owner's capture
`screenshots/transfer-offers-2026-07-02/current_offers.png` ("asdf / Manchester Utd.",
Week 4). Career-side accumulation shipped 2026-07-02 (`Career.sale_offers`,
`test_current_offers.gd`); the two screens are NOT built yet.

## Strings (file offset → VA)
- `CURRENT OFFERS` 0x259d00 → `0x65b700` (refs: FUN_00532a50 @0x532d28; 0x523dc4)
- `YEARLY WAGE` 0x259dc0 → `0x65b7c0` · `CLUB OFFER` 0x259dcc → `0x65b7cc`
  (refs: 0x52c66f/0x52c692 = the make-offer card, 0x525893/0x5258b6)
- `CLUB OFFERS` 0x25a588 → `0x65bf88` (refs 0x530d8f/0x530dbd)
- icons: `recursos\iconos\fichar\ofertas.bmp` → `0x65c2ac`, `...\fichar\secretari*.bmp`

## FICHAR (transfers) hub — `FUN_00532a50` (1940 bytes)
The transfer-area hub screen. Standard chrome: title rect `(150,16,447,43)` ProMan14,
help topic `INFOFUT\if5mafic.htm`, arrowup/arrowdown scroll icons, list panel widget
(`FUN_004f50c0`) at `{8,0x48,0x1f2,0x1b3}` = (8,72)-(498,435). Right-hand button
column (each 112x25 via the fb0(size)/fb0(pos)/fd0 push pattern):
- **CURRENT OFFERS** (512,286) + `iconos\fichar\ofertas.bmp`
- **SCOUT** (512,323) + `iconos\fichar\secretari*.bmp`
- **OFFERS** (512,360)
- **RETURN** (512,440)
So the route is: hub FICHAR icon → this transfer hub → its CURRENT OFFERS button →
the offers screen. (The app retired its invented `_show_transfers` hub route; this
is the sourced replacement to build.)

## CURRENT OFFERS screen — 0x523dc4 tail + `FUN_00523ed0` + `FUN_00523f70`
The string-ref at 0x523dc4 is mid-function (flat -noanalysis project); the dumped
tail shows the standard title block + a RETURN at `CRect(0x1ee,0x1ba,0x25e,0x1d3)` =
**(494,442)-(606,467)**, then two helpers:
- **`FUN_00523f70` — the white panel**: outer border `CRect(0x1f,0x4e,0x25e,0x1b6)` =
  (31,78)-(606,438), inner white fill (33,80)-(604,436).
- **`FUN_00523ed0` — the 5 player bands**: iterates the 5 listed-player slots at
  `this+0x480 → [0x20c..0x21c]` (u32 player indices into the global player table
  `DAT_0066c158`), drawing each band via `FUN_00524500(x=0x24, y)` with **y = 0x62
  (98) stepping 0x43 (67)** → bands at y = 98, 165, 232, 299, 366.
- **`FUN_00524500` — one band** (285 bytes): header block 0x234x0x30 = **564x48**;
  when the player exists it loads his `iconos\camrol\%02u.bmp` role icon
  (`player+0x18` fine position + 1 — same LUT as the squad screens) and the four
  CLAUSES icons: `descenso.bmp` (Free if relegated), `partidos.bmp` (Matches to
  renew), `primasgol.bmp` (Scoring bonus), `casacoche.bmp` (House and car).
  Fonts ProMan8 for the rows.

### Band layout (capture, to refine when built)
Per band: player header row `NAME | EN SP ST AG QU FI MO AV ROLE POS` (his attribute
strip — MO is the same dynamic-morale gap as SQUAD MANAGEMENT → render `-`), then up
to 5 offer rows `CLUB | CLUB OFFER | YEARLY WAGE | YEARS | CLAUSES`, cells boxed in
the house style. RETURN bottom-right.

## App-side state (SHIPPED)
`Career.sale_offers` (pid → up to **5** rows `{buyer_id, buyer_name, offer,
weekly_wage, years, week}`), accumulated weekly in `advance_week` via
`TransferMarket.solicit_offer` while the window is open (`OFFER_CHANCE_PER_WEEK`
0.45), news line per new bid. `offers_for` / `accept_offer` (routes through
`accept_sale`'s squad-floor guards, clears the band + listing) / `refuse_offer`;
unlisting withdraws all bids; persisted in the save as `sale_offers`.
NOTE: the pre-existing `Career.pending_offers` Array is the MANAGER-JOB offers
store — do not confuse the two.

## NEXT (build order)
1. `CurrentOffersScreen.gd` off this geometry + the capture; wire accept/refuse to
   `Career.accept_offer/refuse_offer`.
2. The FICHAR hub screen (or an interim direct route to CURRENT OFFERS from the hub
   transfer icon) — decide against the walkthrough evidence for the hub icon flow.
3. The make-offer card (OFFER panel on the PLAYER INFO card, `make_offer_card.png`):
   RE `FUN_0052c66f`-region rects before build; CLAUSES checkboxes + steppers.
