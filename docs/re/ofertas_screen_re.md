# CURRENT OFFERS (OFERTAS) + the FICHAR hub — reversed from MANAGER.EXE

> **SUPERSEDED IN PART 2026-07-24** — the live game shows YOUR OUTGOING BIDS on this
> screen (target player + the club you bid to), not your transfer-listed players. See
> [`transfer_loop_live_re.md`](transfer_loop_live_re.md) §2 for the capture. The band
> geometry below is unchanged and still correct.

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

### Band layout (measured off the capture; BUILT 2026-07-02, CurrentOffersScreen.gd)
Capture→design offset dx=+2 dy=+12 (anchored on the RE'd band y=98 + panel rects; the
PNG is a 644x456 window crop). The 564x48 block = a kit-figure gutter (x 36..62, the
band template DAT_00666f70 is un-RE'd → the club's extracted kit art stands in at the
captured spot (40,y+1)-(58,y+24)) + the boxed rows x 63..599, four rows inside 1px
black borders (hlines at y+13/+26/+39):
- **Row 1 (y+1..+12)** name/attr strip: navy fill (42,95,170) x64 w272, name white at
  x=86 (names render TITLE-CASED — the EQUIPOS cipher is single-case, the original
  cases at render: "Southgate", frame-077 "Van der Gouw" → PMChrome.title_case_name);
  8 white value cells x=338 pitch 25 w 24 `EN SP ST AG QU FI MO AV`, value colours
  EN(150,0,0) SP/ST/AG/QU(100,100,140) FI(42,95,170) MO(100,130,10) AV(210,0,0);
  ROLE cell [538,+23] olive (140,170,30) + the camrol icon (player+0x18 fine pos + 1),
  white when the slot is empty; POS cell [562,+37] black GK/DEF/MID/FOR.
  **FI/MO/AV are the live dynamics** (decoded 2026-07-03, docs/re/morale_re.md):
  FI = fitness bar, MO = morale (FUN_00582db0 base), AV = the real rating
  (FUN_00581e60). A player with no dynamic form yet still renders `-`.
- **Row 2 (y+14..+25)** labels row: fill (160,180,200), text (30,52,98) ProMan8,
  CLUB / CLUB OFFER / YEARLY WAGE / YEARS centred over their row-3 cells, CLAUSES
  centred over the whole clause region.
- **Row 3 (y+27..+38)** ONE offer row (fills drawn even when empty, capture bands 3-5):
  CLUB [67,w108] (200,220,240) w/ dark-navy text; CLUB OFFER [176,w115] (42,63,170) w/
  pale (166,202,240) £; YEARLY WAGE [292,w115] (75,109,172) w/ (180,200,220) £
  (= Contract.yearly(weekly)); YEARS [408,w36] (30,52,98) w/ white int; then light
  cells [445,w19] [465,w29], the CLAUSES icon strip [495,w81] (4 slots of ~20px for
  descenso/partidos/primasgol/casacoche — empty in the capture; drawn only if an offer
  row carries `clauses`) and [577,w19].
- **Row 4 (y+40..+46)** footer strip, fill (160,180,200).
Panel-top column header at y=84: `NAME` (42,63,170) at x=86 + the codes over their
cells in the value colours (hdr AV = (212,95,0), MO hdr (80,110,5), ROLE black,
POS (128,128,128)). The original shows ONE offer row per band while the app store
keeps ≤5 bids — the row shows the NEWEST bid; a band tap hands the full list to the
caller for accept/refuse (the original's answer interaction is un-RE'd → interim
browse dialogs in Main until sourced). RETURN bottom-right w/ the OFERTAS money-bag.

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
1. ~~`CurrentOffersScreen.gd`~~ **SHIPPED 2026-07-02**: screen built off the measured
   geometry above; the TRANSFER MARKET screen's CURRENT OFFERS nav button (the sourced
   FUN_00532a50 hub route) opens it; band tap → bid-list → ACCEPT/REFUSE through
   `Career.accept_offer/refuse_offer` (interim browse dialogs — the original's answer
   interaction is un-RE'd). Clause icons baked (`export_icons.py`:
   clause_{descenso,partidos,primasgol,casacoche}.png). Tests:
   `test_current_offers_screen.gd`; render fixture `current_offers_demo.png`.
2. The make-offer card (OFFER panel on the PLAYER INFO card, `make_offer_card.png`):
   RE `FUN_0052c66f`-region rects before build; CLAUSES checkboxes + steppers.
