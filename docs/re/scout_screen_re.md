# SCOUT screen + async scout search — frame RE (wine witnesses 2026-07-18)

> **GAP CLOSED 2026-07-24** — the E.U. / NON E.U. / PLAYERS WITHOUT TEAM enablement
> condition (called "un-witnessed" below) is the hired SCOUT's star rating: 3.5 / 4.0
> / 4.5. Four careers sampled; see [`transfer_loop_live_re.md`](transfer_loop_live_re.md) §5.
>
> **GAP CLOSED 2026-07-26** — the bottom two-segment bar, recorded below as "baked furniture,
> behaviour un-witnessed, never animated". It is the original's **per-row ROLLOVER READOUT**
> and it is witnessed three times. Built and render-diffed at **0 px** on all three, bar body
> and row frame. See §"The bottom bar" — and note the habit that found it: the frames had been
> in the repo since 2026-07-25, and a 4-line scan over every committed capture found them in
> seconds. Scan what you already have before calling something un-witnessed.

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
* Bottom strip (white panel + 2-segment grey bar) = the ROLLOVER READOUT, closed
  2026-07-26 — see the dedicated section below. (This line used to read "baked
  furniture; its behaviour (progress?) is un-witnessed".)
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

## The resolver itself, disassembled 2026-07-25 — the search is no longer inferred

Everything above was witnessed at the SCREEN. This section is the code behind it. The
senior scout is a two-slot vtable at **0x6354f8** (constructed at 0x554975 / 0x557588 /
0x57c765), the exact shape of the youth scout's 0x632fc8:

| slot | function | what it is |
|---|---|---|
| 0 | `FUN_005753e0` | the per-player FILTER predicate |
| 1 | `FUN_00575750` | the SEARCH: scan, then trim to the scout's cap |

The criteria object is one struct: `+4` own club id (word), `+6` the scout's raw
quality byte, `+7` a busy flag, `+8` the result vector, `+0x10` AGE, `+0x11` QUALITY,
`+0x12` POSITION, `+0x13` PRICE, `+0x14` ROLE (each `0xff` = that filter OFF), `+0x1c..
+0x28` the four division checkboxes, `+0x2c` E.U., `+0x30` NON E.U., `+0x34` WITHOUT TEAM.

### `FUN_00575750` — the scan and the CAP

```
for id in 1 .. 0x9c40:                  # the whole 40000-slot player table
    if slot is live and vtable[0](player):   # the filter below
        result[n++] = player_id
cap = (quality_byte + 2) * 5                  # @0x5757e7
if n > cap:                                   # @0x575800
    keep `cap` of them by drawing UNIFORMLY AT RANDOM WITHOUT REPLACEMENT
    (rand()*n >> 15 into the array, retry any slot already zeroed)  @0x575826-0x5758b9
```

Two things follow, and both were open questions before today:

* **The cap is by HALF-STAR, not by star.** The quality byte is the staff record's raw
  1..10 (`Staff.quality_byte` = stars x 2, already proven live by the physiotherapist's
  "N PLAYERS" ladder). A ★★★ scout is quality 6 and caps at **40** — which is exactly the
  result count witness 81 shows through its 18px slider, `floor(94 x 8 / 40)`. The frame
  and the disassembly agree to the player. The ladder is
  20 / 25 / 30 / 35 / **40** / 45 / 50 / 55 / 60 for 1.0★ .. 5.0★.
* **The trim is RANDOM, not "the best N."** `docs/SPEC_ours_additions.md` left "which 35
  of the 112?" open and suggested highest-AV as an honest default. The binary answers it:
  a uniform draw without replacement. A weak scout brings back FEWER names, not worse
  ones, and re-running the same criteria gives a different shortlist. Ported in
  `Career._scout_apply_cap`.

### `FUN_005753e0` — the filter, criterion by criterion

Rejects outright: the manager's own club, and any club id >= 0x26e4.

| criterion | offset | rule |
|---|---|---|
| AGE | `+0x10` | 17-22 / 23-26 / 27-30 / 31-33 / >33 (@0x57544b) |
| POSITION | `+0x12` | the coarse byte `player+0x1c` must equal it |
| ROLE | `+0x14` | **any one of the player's SIX role bytes** `+0x1d..+0x22` (@0x5754bc) |
| QUALITY | `+0x11` | `(p[0x9c]+p[0x9d]+p[0x9e]+p[0x9f]) >> 2` (= AV) against the 7 bands |
| PRICE | `+0x13` | `value x 1e-06` (the double at 0x638200 = units of 5K) against 10 bands |

**ROLE is a six-slot test, and that is new.** The port matched `posFine` only; the engine
loops `+0x1d` (posFine) plus the five alternates `+0x1e..+0x22` — the same bytes the
extractor already exports as `posAlts` — and accepts on the first hit. So searching for
SWEEPER finds every player who can play there, not only those listed there first.

### The region gate is a three-way, not an OR

The tail (@0x575675) picks exactly one toggle for each player:

```
club id == 0x26de              -> the PLAYERS WITHOUT TEAM box   (+0x34)
club division (club+0x50) < 4  -> that ENGLISH division's box    (+0x1c + div*4)
otherwise (a foreign club)     -> FUN_0058d2f0(player+0x1a) ? E.U. (+0x2c) : NON E.U. (+0x30)
```

So **E.U. / NON E.U. never reach an English club's players** and the division boxes never
reach a foreign one. The port used to let E.U./NON E.U. rescan the manager's own division;
fixed in `Career._scout_scan_own` and in `Main._show_scout_screen`'s world pool.

### The E.U. list IS in MANAGER.EXE after all

`FUN_0058d2f0` is a flat compare chain over the PAISES country code returning 1 for
eighteen: 2 GERMANY · 5 AUSTRIA · 0x0c BELGIUM · 0x12 DENMARK · 0x13 SCOTLAND ·
0x16 SPAIN · 0x17 FINLAND · 0x18 FRANCE · 0x1a GREECE · 0x1b HOLLAND · 0x1e ENGLAND ·
0x1f REP. OF IRELAND · 0x20 NORTH. IRELAND · 0x24 ITALY · 0x26 LUXEMBOURG · 0x2d WALES ·
0x2f PORTUGAL · 0x35 SWEDEN. This doc previously recorded the list as "not located in
MANAGER.EXE — historical membership". It is located, it is those eighteen, and the
historical list the port shipped happens to be exactly the same set, so nothing changed
except the provenance (`Career.EU_CODES`).

## The bottom bar — the original's ROLLOVER READOUT (2026-07-26, 0 px)

Two sessions recorded this bar as inert furniture. It is not. Three frames in
`screenshots/refrun-manutd-1997-98/novel/` show it in use, and a fourth from the same list
shows it empty, which is what settles what drives it:

| frame | list | bar |
|---|---|---|
| `p0241` | Kluivert (row 2) framed | Milan kit · `Patrick KLUIVERT` · `Milan` |
| `p0279` | Etxeberria (row 2) framed | Athletic Club kit · `Joseba ETXEBERRIA Lizardi` · `Athletic Club` |
| `p0283` | Nesta (row 4) framed | Lazio kit · `Alessandro NESTA` · `Lazio` |
| `p0245` | same results, NO row framed | empty |

**It is a rollover, not a selection.** In `p0245` the pointer has moved to SEARCH (its armed
ring is up) and the readout has cleared; in `p0242` / `p0281` a modal is up and it has cleared
too. A click-selection would have survived both. There is no other state in which it appears.

Measured, all three frames agreeing to the pixel:

| element | value |
|---|---|
| club kit | `app/art/kits/ridi/<club_id>.png` at **(17, 442)** — 0 px on ridi/1020 Milan, 1004 Athletic Club, 1023 Lazio (found by matching the 17x18 ink against all 476 ridi kits at every offset in ±3) |
| segment A | the player's FULL rendered name, centred; segment `x40..285`, ink rows **y448..454** |
| segment B | the club name, centred; segment `x287..449`, same rows |
| face | **proman8 at 11 px**, ink pure black — the six witness strings size within 1 px of the measured ink widths and nothing else in the bank is close |
| pen x | `floor(cx - advance/2)`, **cx = 163.0 in A, 368.0 in B**. Solved, not assumed: the six measured ink starts (112/83/109 and 353/330/353) bracket cx to exactly those two values. Rounding instead of flooring puts `Athletic Club` 1 px right — that was the whole residual. |
| the held row | grows a **2 px BLACK frame**, `x32..474`, `y (top-1)..(top+14)`: it replaces the grey 1 px border and eats one row of the white gap above and below. Isolated by diffing `p0279` against `p0283` — the same list with a different row held, 1820 px, all of it two rings. |

The full name is **`legalName` verbatim**. game_db already stores the string the original
renders, surname uppercased in place: `Iván DE LA PEÑA López`, `Joseba ETXEBERRIA Lizardi`.
`PMChrome.card_name` used to rebuild it by uppercasing the LAST word, which cannot produce a
middle surname at all (it printed `Iván De La Peña LÓPEZ`), and **1,272 of the 9,547 shipped
names** have a surname that is not the trailing run. Fixed 2026-07-26: a mixed-case
`legalName` is printed verbatim; the 97 all-uppercase ones (talent pool / youth / sample_db)
still take the rebuild, which is what `test_make_offer_screen`'s four cases assert. Five
witnesses back the rule — three here plus the two fichas `p0242` / `p0282`.

**Android has no pointer**, so the rollover is bound to the PRESS: while a finger is held on a
row that row frames and the bar reads out, and the release still opens the card. That is a
port decision about an input the original does not have, not an invented pixel.

Gate: `tools/re/diff_scout_bar_parity.py` — bar body and row frame, 0 px on all three.

## The OURS panel (2026-07-25) — flagged, not hidden

`docs/SPEC_scout_attribute_search.md` + `docs/SPEC_ours_additions.md`, owner-approved:
a NAME substring box, six per-attribute "at least" thresholds (30..95 by 5, exactly
`Training.TRAINABLE`), and a sort selector. The original has none of them.

**2026-07-26 evening — REBUILT IN ORIGINAL CHROME.** Mats on the first version: *"NOT that
AI slope image you used! REDO!"* — it was drawn procedurally in an invented navy/yellow
palette (`C_OURS_BG (20,24,60)` etc.), colours that exist in no captured frame. Replaced by
`app/art/screens/scout/ours_panel.png`, baked by `tools/re/build_scout_ours_from_frames.py`
— every pixel is frame chrome or a flat fill in a sampled ink:

* the **CLUB PERSONNEL trainers dialog** (walkthrough `100_154657.png`) donates the white
  plate + 2 px black frame, the flat `(200,220,240)` header fill (measured x90..342
  y108..122, borderless), and the six REAL `HANDLING/PASSING/DRIBBLING/HEADING/TACKLING/
  SHOOTING` button plates — the exact six labels the six filters need — cut verbatim
  (DRIBBLING's selected glow + HEADING's focus ring de-highlighted with the staff baker's
  own neutralise technique, each keeping its real wording);
* the label-free neutral plate (HANDLING with its cyan zapped) carries the panel's own
  NAME / SORT BY / CLEAR / CLOSE, rendered live in the plates' own cyan `(85,223,255)`;
* the SCOUT screen's own **pale-blue criteria fields** (61: wide x131..255 y131..146,
  small x35..83 y177..192) and **enabled arrows** (67) are the value boxes and steppers;
  the wide field is width-extended by tiling one interior column (flat fill + 1 px
  borders — lossless);
* the panel sits at the dialog's own witnessed origin **(67,63), 458x289**; title ink is
  the band's own `(0,0,190)`; values/notes are black / the screen's border grey.
* threshold display is `MIN %d` (fits the real 49 px field; "AT LEAST %d" did not).

The scene (`ScoutScreen._draw_ours`) draws ONLY live text over the plate. Verified: all six
witnessed states still 0 px (`diff_scout_offers_parity.py`), bar Part A 0 px / Part B
bounded (`diff_scout_bar_parity.py`), and `shot_scout_ours_panel.png` renders the panel.

They live in an overlay that is **closed by default**, opened by tapping the 2-segment bar at
x11..500 y438..463, so all six witnessed states still verify at 0 px (re-run 2026-07-26 after
the readout landed: noscout/idle/premier/position/searching/results all 0 px).

**2026-07-27 — the NAME box is INSTANT (Mats, live QA).** Typing in the panel's NAME
field now runs `Career.instant_name_search` on every keystroke: a synchronous lookup
over the whole decoded database (live division rosters + all 384+ static GameDB clubs
+ free agents, own club excluded), matching the folded surname OR the folded full
rendered name (`legalName` — "patrick" finds Kluivert). No scout mission is armed, no
other criterion is needed, and the hits land as NORMAL scout results — the same
`_scout_row` shape, the same PLAYERS FOUND rows, the same tap-through to the offer
card. Enter closes the panel so the rows are fully visible; SEARCH with a name and
nothing else re-fires the lookup instead of the witnessed refusal alert (which stays
the answer for a truly empty tap). The mission machinery is untouched and still owns
every attribute/band search; the scout's shortlist cap is a mission rule and does NOT
apply — the lookup builds at most `Career.INSTANT_NAME_ROWS` (200) rows and the panel
message says "N of M shown - type more of the name" when it clips. No new chrome was
needed: the panel already carried the NAME object, so this cost zero new pixels
(all six witnesses + both bar gates re-run 0 px / PASS 2026-07-27). The panel is
still gated on a hired scout — the witnessed 43-state ("You need to hire a scout")
binds the screen without one; the distinction Mats drew is mission vs lookup, not
scout employment.

**2026-07-26 — the bar got a visible label, and the bar turned out to be the original's.**
Mats: *"I don't see the new search objects. Scout screen looks like it always has still."* The
panel had been shipped and working since 07-25 behind a bar with no label of any kind, which
is why it read as missing. The same session found the bar's real behaviour (above), so the two
uses are now split by STATE, not by pixels:

* a row held → the original's readout owns the bar, and the label is not drawn;
* nothing held → the label `EXTRA SEARCH FILTERS` / `TAP HERE` (or `N ACTIVE`, or `CLOSE`), in
  the readout's own proman8-at-11 black on the bar's own grey.

So the port never covers a pixel the original draws — the label only occupies a state the
original leaves blank, and it yields on the first press. `diff_scout_bar_parity.py` §B proves
that from the frames rather than asserting it: it checks all ten committed frames of this
screen and requires each one to be either a readout or blank, and it checks the two segments
against the 21 original controls for overlap. This is the SECOND and last site in the port
that draws a pixel the original does not (the first is THREE UP FRONT on OPTIONS).

The panel also prints the cap shortfall — *"40 of 112 shown - your scout could only bring
back 40"*. The cap is the binary's; saying it out loud is ours, because a silent trim
reads as "that is all there was".

The NAME box matches on a **folded key**, not on the raw string: lower-cased, the 20
accented letters the squads actually use folded to ASCII, and every non-alphanumeric
character dropped. The game's own name data forces it — 635 of the 9,547 shipped names
carry an accent, and the database ships **two different apostrophes**, ASCII in `O'Neill`
(40 names) and an ACUTE ACCENT in `O´Connor` (15), so no typed apostrophe could ever hit
both. Dropping spaces too makes `o neill` / `oneill` / `O´Neill` one key, and lets
`pancho guerrero` find `"Pancho" Guerrero` (68 names carry a quoted nickname). It stays a
SUBSTRING test: `guerro` still misses `Guerrero`, because near-matching is not something
the original does and not something to invent. `Career.fold_name`.

**The honest note that travels with the six filters:** only `STR`, `PASS` (=PA) and
`GKSAVE` (=PO+10) are read by the match engine, so DRIBBLING / HEADING / TACKLING /
SHOOTING filter on numbers that do not move a scoreline. That was known when they were
asked for; do not "fix" it by hiding them.
