# SCOUT screen + async scout search — frame RE (wine witnesses 2026-07-18)

> **GAP CLOSED 2026-07-24** — the E.U. / NON E.U. / PLAYERS WITHOUT TEAM enablement
> condition (called "un-witnessed" below) is the hired SCOUT's star rating: 3.5 / 4.0
> / 4.5. Four careers sampled; see [`transfer_loop_live_re.md`](transfer_loop_live_re.md) §5.

The TRANSFER MARKET's SCOUT screen: hire-gated search-criteria panel + the async
"scout searches for ~2 game weeks" loop + the PLAYERS FOUND results list. Decoded
from the live wine witness run `screenshots/wine-captures-2026-07-18-goalscorers/`
(Bolton career, weeks 3-5). All coords are design-space 640x480; wine captures are
641px wide — crop `[:, :640]` (map-region proof: 100% match after right-crop).

## Binding witnesses

| frame | state |
|---|---|
| 43_scout.png | NO SCOUT hired: criteria LEDs + league checks + SEARCH all WASHED (checker dither toward grey); empty scout strip; gate text "You need to hire a scout to search for a player." in the PLAYERS FOUND panel |
| 56-60 | STAFF flow: scout K. Burrowes ★★★ signed (£20,000 wage) |
| 61_scout_with_scout.png | scout hired, nothing selected: strip = name plate "K. Burrowes" + 3 gold stars + WAGE £20,000; LEDs dark-red enabled-off (85,0,0); SEARCH enabled; list EMPTY (no headers, no gate text) — THE chrome base |
| 62 / 64 / 66 | SEARCH tapped with no criteria toggle ON (62: nothing; 64/66: Premier league check ONLY) → "PREMIER MANAGER 98" alert "You have to select some options to make the search." centred (317,237) over the LUT-dimmed screen (15082/15158 sampled px == PMAlert dim_lut; misses = the known white (x+y)-parity dither pair) |
| 63_premier_checked.png | Premier checkbox ON: LED cell (284,140) 22x13 → bright (255,0,0) |
| 67_pos_enabled.png | POSITION toggle ON (LED (114,113) 22x13) + dropdown filled "GOALKEEPER" (field x131..255 y131..146, black text centred cx193) |
| 68_results3.png | after SEARCH: red armed ring around SEARCH (diff x516..619 y209..237); list shows searching text "The scout is now searching for players / with the selected capabilities." (2 lines, LEFT x123, tops y338/y358) |
| 73_scout_results.png | week 4 (one advance later): STILL searching (same panel) |
| 78_after_potm.png | week 5 hub: "PREMIER MANAGER 98" alert **"The scout has finished his search."** (the async completion alert; 2 week-advances after arming) |
| 81_scout_found2.png | results: column headers appear (NAME/AV/MO/CLUB FEE/WAGE/YEARS, y286..292) + 8 visible rows y297+16k + scroll column (down arrow enabled) |
| 82_scout_playercard.png | row tap (Hislop) → the CONTRACT+OFFER "PLAYER INFORMATION" card (same family as 49 over TRANSFER MARKET — NOT the attrs-top MakeOffer card) |

## Criteria dropdown enums — BINARY-EXACT (MANAGER.EXE getter tables, 2026-07-23)

The RE previously listed AGE/QUALITY/PRICE filled-values as an "honest gap" (only
POSITION "GOALKEEPER" was witnessed live) and the app had guessed them as numeric
spinners (age 16-40, quality 1-5, price 250k-step money). **WRONG** — all five
criteria are enum dropdowns whose contents are arrays of string pointers in the
binary, indexed by the dropdown position. Lifted verbatim (via `tools/re/enum_pcf5dat.py`
method: section map .data VA = fileoff + 0x401A00, scan pointer runs):

| criterion | getter table VA | order (index 0..N) |
|---|---|---|
| POSITION | `0x662d10` (4) | GOALKEEPER, DEFENDER, MIDFIELDER, FORWARD |
| ROLE     | `0x662df8` (18, short-form) | KEEPER, RIGHT BACK, LEFT BACK, SWEEPER, INS. CENT. LEFT, INS. CENT. RIGHT, RIGHT MID., INSIDE RIGHT, CENTRE FORWARD, CENTRAL MID., LEFT MID., RIGHT WINGER, CENTRAL STRIKER, LEFT WINGER, DEF. MIDFIELDER, RIGHT FORWARD, LEFT FORWARD, INSIDE LEFT |
| AGE      | `0x661e08` (5) | 17-22, 23-26, 27-30, 31-33, +33 |
| QUALITY  | `0x661e20` (7) | 50-65, 66-70, 71-75, 76-80, 81-85, 86-90, +90 |
| PRICE    | `0x661e40` (10) | 10 - 75 K., 80 - 125 K., 130 - 250 K., 250 - 500 K., 500 - 1,500 K., 1,500 - 3,000 K., 3,000 - 5,000 K., 5,000 - 7,500 K., 7,500 - 10,000 K., + 10,000 K. |

* POSITION == the app's existing list (was correct). ROLE == `PlayerInfoScreen.FINE_ROLE`
  short-form, exact order — the scout value-render at `0x5753c4` reads the SHORT table
  `0x662df8` (paired with POSITION `0x662d10` at `0x5753b4`), so the wide ROLE field uses
  the short names, NOT the long-form parallel table `0x662db0`.
* The five getter thunks sit together at `0x575390`/`0x5753a0`/`0x5753b0`/`0x5753c0`/`0x5753d0`.
* QUALITY is on the 0-99 ability scale = the same metric as the results AV column
  (witnessed AV 69-85 sits inside 66-70..81-85). NOT the training attribute list
  (GENERAL/FITNESS/SPEED/STAMINA/AGGRESSION @0x25945x is a different screen — no pointer
  table exists over it).
* Geometry confirms the enums: AGE + QUALITY are the SMALL fields (x35..84) — every band
  string is <=5 chars; POSITION/ROLE/PRICE are the WIDE fields (x131..255). The game sizes
  the fields to exactly fit these bands.
* App wiring: `ScoutScreen.AGE_BANDS/QUALITY_BANDS/PRICE_BANDS`; criteria carry the band
  INDEX (`age_band`/`quality_band`/`price_band`, -1 = off since index 0 is valid);
  `Career.SCOUT_AGE_BANDS/SCOUT_QUALITY_BANDS/SCOUT_PRICE_BANDS_K` hold the inclusive numeric
  bounds behind each band for `_scout_match` (AGE vs player age, QUALITY vs row AV, PRICE vs
  row fee in K). Still un-witnessed: the exact filled-value glyph style (bar POSITION).

## Witnessed rules

* **Hire gate**: no scout → everything washed + gate text; SEARCH inert.
* **Validation**: ≥1 LEFT-column criteria toggle (POSITION/AGE/ROLE/QUALITY/PRICE)
  must be ON. League checkboxes alone do NOT count (64/66: Premier-only refused).
* **E.U. PLAYERS / NON E.U. PLAYERS / PLAYERS WITHOUT TEAM stay WASHED even with
  the ★★★ scout hired** (sampled dither in 61/63/67 identical to 43). Enablement
  condition un-witnessed (better scout? never?) — the app keeps them washed+inert,
  documented.
* **Async**: search runs in the background; still searching after 1 advance (73),
  finished alert on the hub after the 2nd advance (78). Duration with the ★★★
  scout = 2 week-advances (quality-dependence un-witnessed).
* **Results persist** on the screen after completion (81 re-entered from hub).
* **AV column = floor((VE+RE+AG+CA)/4)** — verified EXACT on all 8 visible rows
  (Beeney 69 … Hislop 85; same formula as the OFFERS squad list, 28/28 there).
  NOT the insurance av6.
* **MO** = live morale (89/82/97/… week-5 values; not static-derivable).
* Result set spans clubs incl. BOTH Wimbledon GKs (Heald row3 + Sullivan row8) —
  every matching player returns, not one per club. Visible order (Leeds, Villa,
  Wim, Blackburn, Newcastle, Spurs, Derby, Wim) is neither club-grouped nor
  alphabetical nor by AV; the four NON-XI (backup) GKs precede the four XI GKs —
  an internal scan order the port cannot reproduce byte-exactly → app uses its
  own scan order, documented model behaviour.
* **YEARS pair**: navy digit on white; the LEFT cell gets yellow fill + red digit
  when the value is 1 (final year) — the TransferScreen rule. Real contract years
  of AI players are un-portable per-club float data → app renders the Contract
  model's values where they exist, else the honest gap "-".
* Fees/wages: witnessed real figures (Hislop £10,000,000 / £1,200,000) come from
  the per-club float ledger (un-portable, finance_constants.md) → TransferMarket
  valuation model, accepted approximation (TransferScreen precedent).

## Geometry (frame-measured)

* Scout strip: name plate (steel 59,85,130) with white proman name ink x64..134
  y91..105 + gold stars ink x171..202; WAGE red label baked; wage value white
  centred ~cx270 y91..105. Empty plate + WAGE label are baked furniture (43).
* Criteria LEDs 22x13 cells: POSITION (114,113), AGE (17,158), ROLE (114,158),
  QUALITY (17,204), PRICE (114,204), Premier (284,140), 1st (367,140),
  2nd (450,140), 3rd (533,140). OFF = dark red (85,0,0) face; ON = bright
  (255,0,0) face (cut from 67; Premier ON in 63 is the same cell).
* POSITION dropdown: left arrow (115,131) 16x16, field x131..255 y131..146
  (pale blue, black border), right arrow (256,131) 16x16. Value = black text
  centred cx193 ("GOALKEEPER" witnessed). ROLE/PRICE fields same row grammar at
  y176/y222 (x131..255); AGE/QUALITY small fields x35..84 (arrows (19,...) and
  (86,...)). Only POSITION's filled state is witnessed.
* SEARCH button ~x518..618 y211..236; armed = red ring (diff x516..619
  y209..237, cut whole-button sprite from 68).
* PLAYERS FOUND panel: title band baked; headers strip y286..292 (x53..470,
  sprite from 81 — headers ONLY render with results); rows: border y297+16k,
  fill y298+16k..+12, 8 slots; [+] icon col x~15; name/stars/value columns per
  the strip cut; scroll column at the panel's right edge (up arrow disabled
  pale / slider / down arrow enabled, witnessed at top with >8 results).
* Gate text sprite (43): ink x90..418 y348..357 (centred on panel cx256).
  Searching text sprite (68): ink x123..387 y338..347 + x123..326 y358..367
  (LEFT-anchored x123, line tops 20 apart). Both cut as sprites → 0px.
* Bottom strip (white panel + 2-segment grey bar) = baked furniture; its
  behaviour (progress?) is un-witnessed — never animated by the app.
* The options alert = PMAlert.render(msg) centred (317,237) + PMChrome dim
  bracket (LUT-verified above; InsuranceScreen precedent).

## Verification (2026-07-18, tools/re/diff_scout_offers_parity.py)

All six witnessed states verify **0 px**: noscout-43, idle-61, premier-63,
position-67, searching-68 fully unmasked (bar the live barra); results-81
masks the money faces, the bold list-name faces, the years digit glyphs
(non-"1"), the strip name/wage and the dropdown value — the original's
bold/outlined rasters are absent from the extracted .fnt bank (the
goalscorers residual class; #11 follow-up: locate/extract that face — it
would also close goalscorers' ~6.4k residual). Chrome, LEDs, enabled arrows,
searching/gate text sprites, headers, row grid + verticals, stars (frame-cut
glyphs: full pitch 14, half on the pitch — the "Hislop 4.5" first read was a
misread, he shows 4.0), digit-grammar AV/MO ("69" lands ink x238 exactly),
the witnessed Australia row-flag (35, top+1), the [+] icon (body x11..33;
x6..10 is per-row marble texture, NOT icon), yellow final-year cells and the
scroll column (slider 18px = floor(94*8/40)) are all pixel-identical.

## App wiring

TransferScreen BTN_SCOUT (496,324,128,21) → `scout_pressed` → Main →
ScoutScreen (fresh GameDB-live). Career:
`scout_search = {criteria, due_week}` armed on SEARCH;
`advance_week` ticks it; on completion stores `scout_results` (pid+club rows),
queues the hub alert text via `pending_alerts` (raised by Main at the next hub
show — the witnessed post-flow timing), and news-logs it. Results survive
save/load. Row tap → the make-offer card family (82).
