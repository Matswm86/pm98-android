# OFFERS (map browse) screen — frame RE (run-3 + wine witnesses)

The TRANSFER MARKET's OFFERS screen: the Europe/S.America flag map + country kit
grid on the left (SHARED pixel-for-pixel with the PRESEASON screen chrome) and a
NEW right side: club squad browse list + (England-only) division buttons +
RETURN. Player tap → the attrs-top MAKE-OFFER card (make_offer_re.md run-3
101-118 — that card opens FROM THIS screen).

## Binding witnesses

Run-3 walkthrough `screenshots/original-walkthrough-2026-07-02/` (asdf/Man Utd,
week 3) — NOTE run-3 frames are 641px wide too, crop `[:, :640]`:

| frame | state |
|---|---|
| 098_164709 | England, Premier League button selected (gold+red), Premier kit grid, list EMPTY (AV/ROL headers + 14 empty row boxes = furniture) |
| 099_164711 | Second Division selected: kit grid swaps to div-2 clubs, list still empty (division tap ≠ club tap) |
| 100_164712 | Blackpool kit tapped: title "Blackpool", 14 rows (squad 19 → scrollable), Brabin row carries the black press border; Taylor row tap → 101 card |
| 119_164747 | after card: list persists; MACEDONIA flag tapped → strip "MACEDONIA" + enlarged map flag, but kit panel STAYS England/Blackpool (no browsable league for that country) |

Wine `screenshots/wine-captures-2026-07-18-goalscorers/` (Bolton, week 3):

| frame | state |
|---|---|
| 44_offers_map.png | fresh open: ENGLAND panel, Premier League selected, empty list. vs 098 the ONLY diffs are the barra plaque + the OWN-CLUB kit cell (Bolton washed here, Man Utd washed there) → chrome is career-invariant, own kit renders WASHED (checker), the preseason taken-club treatment |
| 45_offers_country.png | Spain flag tapped: strip "SPAIN" + enlarged flag; kit panel → SPAIN (20 kits, 2x10); division buttons GONE (England-only) |
| 46_offers_club.png | first kit tapped: gold OVER cell at (12,366); strip CLEARS + enlarged flag reverts; "F.C. Barcelona" title + 14 rows; club name label under the kit grid (ink y450..457, the preseason last-pick ink 120,120,160) |
| 47_offers_player.png | Rivaldo row → the MakeOfferScreen card (attrs top + OFFER panel) over the LUT-dimmed screen |

## The ">= 16 clubs" rule was a hover artefact — CORRECTED 2026-07-25

The owner reported that "a LOT of nations do nothing when I click them" on the OFFERS
map. He was right, and the cause was ours.

Two frames were read as click-negatives: walkthrough **015_154401** (strip "HUNGARY",
panel still ENGLAND) and **119_164747** (strip "MACEDONIA", panel still England /
Blackpool). Both are the **country strip's HOVER readout**, not a click — frame
**016_154403**, two seconds later with no further input, shows the strip already
cleared and the panel still on ENGLAND. Nothing was ever clicked in either frame.

A live sweep settles it. Real MANAGER.EXE under wine, fresh TOTAL Manager-League
career (Bolton W), preseason map: **all 47 European flags and all 10 S.American
flags clicked, with the ENGLAND flag re-tapped between each**. The kit panel
switched every time. Frames in
`screenshots/wine-captures-2026-07-25-offers-map-countries/`, each verified by the
country name the panel itself prints:

| frame | country | clubs in EQUIPOS | panel |
|---|---|---|---|
| 01 | MACEDONIA | 1 (Sileks) | switches, one kit |
| 02 | HUNGARY | 5 | switches, five kits |
| 03 | FINLAND | 3 | switches, three kits |
| 04 | LITHUANIA | 3 | switches, three kits |
| 05 | SWEDEN | 5 | switches, five kits |
| 06 | BOLIVIA (S.AM) | 3 | switches, three kits |
| 07 | BRAZIL (S.AM) | 10 | switches, ten kits |

MACEDONIA — the single-club country the old rule was built to exclude — loads exactly
like SPAIN's twenty. Any minimum-club threshold is therefore dead, not merely
mis-tuned. `OffersScreen` now opens a country iff GameDB holds any club for it (56 of
the 57 flagged countries; the 57th is ENGLAND, which routes through the division
buttons). Regression: `test_offers_screen` drives `_route_target("flag:<NAME>")` for
every marker and fails on any that does not load its full club list.

## The left column is the PRESEASON chrome

Map (27,80 300x220), EUROPE/S.AMERICA side tabs, country strip, kit panel
(8,336 321x130), kit cells x13+31i y368/405, OVER gold selection cell at kit-2,
flag markers (data/pretemp_flag_markers*.json), enlarged-flag draw, nano-kit
fallback, own-club checker wash: ALL identical pixels (match ratio 1.000 on
map/tabs/strip vs app/art/screens/pretemp/chrome.png). PreseasonScreen's
machinery is the reference implementation.

* Flag tap: strip name + enlarged flag, AND the kit panel switches to that
  country's clubs. **EVERY country is browsable — there is no minimum-club
  gate.** (Corrected 2026-07-25; see "The ">= 16 clubs" rule was a hover
  artefact" below.)
* The enlarged flag plaque: witness-cut sprite per seen code
  (`flag_big/22.png`, Spain 45 — the BANDERAS bank art differs by a few
  interior pixels from the wine render); border+flag(code) fallback otherwise.
* Club (kit) tap: gold OVER cell + title + squad list + name label under grid;
  strip clears + enlarged flag reverts (46).
* England: division buttons filter the kit grid (Premier/First/Second/Third —
  BAKED labels; the db league names differ ("Division One") — chrome text wins).
  Selected = red-glow face + gold text (witnessed Premier 44/098 + Second
  99/100); First/Third selected faces are UN-witnessed → synthesized from the
  witnessed glow face + the button's own label pixels, documented.
* Foreign countries: one league, no buttons (45/46).

## Verification (2026-07-18, tools/re/diff_scout_offers_parity.py)

All four witnessed states verify **0 px** (resting-44 fully unmasked; spain-45
masks kit panel [nano fallback] + strip text; barca-46/blackpool-100 mask the
stars column [rating mapping un-RE'd], the bold name/title faces [the raster
is absent from the extracted .fnt bank — the goalscorers residual class, #11
follow-up] and the barra). Everything else — chrome, row furniture strip,
digit grammar, camrols, flags, scroll geometry incl. the pressed Brabin ring —
is pixel-identical.

Key implementation decodes from the drive to 0px:
* **Populated rows carry their own furniture** the empty grid lacks (the x562
  name/AV separator + the camrol cell frame) -> `row_strip.png` cut from 100
  row 1, dynamic ink cleared (the insurance row-strip pattern).
* **The kit grid is ALWAYS 2x10** (witness 45: Spain's 21 clubs show 20 kits
  on the (c*95)/3 pitch; overflow is the original's own clipping).
* **camrol cells**: the icons/camrol bank matched fine 9 exactly but its
  fine-7/13 sprites differ from this list's rendering -> the witnessed cells
  (15 of 18 fines, cut from BOTH frames with an identity assert) override at
  `offers/camrol/NN.png`; icons bank fallback for fines 1/4/14.
* **NON-NATIONAL number-cell flag**: 20x14 at (360, row top) — exactly the 4
  Barcelona NON-NATIONALs (kind byte); Brazil cut identical across 3 rows
  (asserted), Yugoslavia from the Ciric row. `flag_mid/{code}.png` +
  MINIBAND-scaled fallback.
* **The scroll slider is ONE noise texture stamped from the top** (46's
  115-row slider == 100's 140-row slider on every shared row) -> crop the
  witnessed sprite to h-3 + its own 3-row bottom cap. Slider h =
  floor(190*visible/total) (140=14/19 and 115=14/23 both exact).
* **Pressed-row ring** (100 Brabin): 2px black at x341..342/x611..612 +
  y(top-1)/(top+13..14) — spans the camrol cell.
* Textures loaded inside `_draw` MUST be cached — an unheld Resource frees
  before the frame flushes and renders WHITE (the flag/camrol white-rect bug).

## Right panel (new chrome)

* Panel x336..640? borders x337-338 black; row boxes x342..~614: border row
  y105+16k (grey 128), fill y106+16k h12 (240), 14 slots (y106..330). The
  EMPTY grid is furniture (098/44 show it with no club).
* Title: navy proman, centred **CX 485** ("Blackpool" ink x449..520 → 485.0;
  "F.C. Barcelona" x427..543 → 485.5), ink y83..93.
* Headers: red "AV" + black "ROL" sprite (bake from frame, y~92..102).
* Row cells (witnessed at y112 scan + sprite matches):
  - shirt number: navy digits centred ~cx354 (digit-centring grammar);
  - name: black proman12 ink-left x380;
  - stars: LEFT-anchored x488, 13px pitch, half-star glyph (gold);
  - AV: red-orange (212,63,0) digits right-aligned ink-right x580/581
    (2-digit), = **floor((VE+RE+AG+CA)/4)** — 28/28 witnessed rows exact
    (Blackpool 14/14 + Barcelona 14/14, incl. the 55/55/86/88 re-reads);
  - ROL: **the game's own camrol{posFine:02d} 25x14 sprite blitted 1:1 at
    (587, row_top)** — camrol09 matched 100.0% of pixels on witness rows;
  - press state: black border ring around the row box (100 Brabin).
* Scrollbar x~615..639: up arrow (pale dotted disabled at top) / steel beveled
  slider from track top / plain track / down arrow (yellow-on-black enabled).
  Insurance slider formula (h = floor(track*visible/total), off =
  floor(track*first/total)) reproduces the 100/46 slider extents.
* Stars = the un-RE'd rating mapping (TransferScreen/FICHA precedent:
  parity-excluded). Witness kills stars=f(AV): Ormerod & Conroy witness AV 55
  vs 65 wait — corrected reads: same-AV pairs carry different star counts
  (Malkin 59→3.0 vs Ormerod 55→2.5 vs Bonner 56→2.5) → separate mapping.

## The display number decode (slot byte)

The left-cell number is NOT the EQUIPOS squadNo byte. It is the player's
**.DBC slot byte** (equipos_parse `slot`, +0x19/+0x1b):

* slot ≤ 16 → shown AS-IS: 1-11 = the shipped XI (club_tactics.json xi),
  12-16 = the club's stored BENCH picks;
* slot ≥ 17 → renumbered **17, 18, 19… in squad record order** (the raw bytes
  hold a different permutation; the game reassigns on load).

Verified against ALL 28 witnessed numbers: Blackpool 14/14 (incl. the
Taylor/Malkin 17/19 swap the raw bytes get wrong) + Barcelona 14/14 (incl.
Ciric/Óscar/Celades/Roger 20/21/22/23). Exported per-club as `squadSlots` (raw
slot byte per player in record order) by tools/re/export_club_tactics.py; the
app applies the ≥17 renumber rule.

* **List order = squad record order REVERSED** (both witnessed clubs 14/14:
  Pizzi→Sergi = Barcelona records reversed; Preece→Butler = Blackpool reversed).

## Honest gaps / approximations

* S.AMERICA tab browse un-witnessed here — shares the preseason machinery
  (real S.America map art + markers), documented pattern-shared.
* First/Third Division selected button faces synthesized (see above).
* Star rating mapping un-RE'd (parity-excluded, existing precedent).
* Fewer-than-14-player clubs: rows drawn per player over the furniture grid
  (un-witnessed; furniture stays).
* The card opened from here = the EXISTING MakeOfferScreen (witness 47 IS that
  card; loan/offer plumbing already wired through Career.sign_player/sign_loan).

## The kit panel — order, texts and the shadow pass (2026-07-27)

The whole 321x130 panel used to be excluded from `diff_scout_offers_parity.py` as
"nano-kit fallback". Un-masking it found three real defects and left exactly one
un-reversed pass, and the gate now masks only the 20 kit SPRITE rects.

**1. Foreign grids were sorted; the original does not sort them.** Matching every cell
of witness 45 against the shot cell-by-cell gives a clean BIJECTION at ~100 px each, so
the same 20 kits were being drawn in the wrong places. The original's cell 0 is
F.C. Barcelona = `EQ96001.DBC` = archive idx 0, cell 1 R.C. Deportivo = idx 1, cell 2
R. Zaragoza = idx 2 — i.e. **the archive's own record order**, which is exactly what
`GameDB.clubs_in_country` already returns. The app's `sort_custom` by display name put
Athletic Club first. Removed.

**2. ENGLAND is different, and that is witnessed, not assumed.** The Premier resting
panel (witness 44) is 0 px only WITH the alphabetical sort — dropping it costs 899 px.
So `_select_england()` keeps its sort and `_act`'s country branch has none. Do not
"unify" these.

**3. Both panel texts were the wrong font and pen.** `tools/re/probe_text_anchor.py`
returns identical-bitmap matches on the real frames:

| text | original | the port had |
|---|---|---|
| country title | proman10 @10, pen top **346**, GDI-centred on field sum **336** | proman12 @13, centred on the panel rect (4 px left, 4 px high) |
| picked-club label | proman10 @10, pen top **449**, same field sum 336 | pen top 447 |

The field sum is solved on FOUR countries, exact on all four: SPAIN adv 43 -> pen 146,
MACEDONIA 85 -> 125, HUNGARY 69 -> 133, SWEDEN 60 -> 138
(`screenshots/wine-captures-2026-07-25-offers-map-countries/`). Witness 46's
"F.C. Barcelona" gives pen 117 / advance 102, i.e. 2*117 + 102 = 336, the same field.

**Result: the panel is 0 px outside the kit sprites on both foreign witnesses**
(spain 2369 -> 0, barca 3171 -> 0 outside cells).

### What is left inside the cells — the shadow pass, measured

2007 px over Spain's 20 cells, 2421 over Barcelona's, and it is ONE class: every
differing pixel is **white in the port and grey in the original**
((255,255,255) -> (80,80,80) / (192,192,192) / (100,100,100) / (160,160,164) /
(128,128,128) / (144,144,144) / (170,191,170) / (240,240,240)). So the original casts a
grey drop shadow around each nano kit that this port does not draw. It is the same
un-reversed pass as the knockout 48x64 bevel (`knockout_views_re.md` §"The outline
pass"). Measured here so the next attempt starts from data:

* it is NOT the realised-palette bug — the nano bank already decodes under MANAGER.PAL
  and is SAD-0.0 against walkthrough frames 008/013;
* a single **shifted-silhouette** stamp at **dx=2, dy=2** explains 1670 of the 1992
  shadow pixels (fp 386, fn 322) — the best of all 15 offsets tried, so the geometry is
  a diagonal down-right stamp;
* it is NOT position-constant, so it cannot be baked the way the MINIESC ring was: only
  46 positions are unanimous across the 40 witnessed cells, and a unanimous-vote bake
  leaves 2398 of 4428 px. The multi-level greys say multi-offset (the alert box's
  "3 double-stamped diagonal layers" family);
* closing it needs the pass's CODE, not another witness set.

### ~~Still open: the ENGLAND panel in a non-Premier division~~ — WITNESSED 2026-07-28

`shot_offers_blackpool` vs run-3 frame 100 does NOT reduce to a permutation — the
best per-cell match is non-bijective at ~500 px/cell, i.e. the panel is showing a
DIFFERENT SET of clubs from the frame's. The frame also shows no gold OVER cell while
the shot stages one. Which division frame 100's panel is on, and how the original marks
the picked club there, were unanswered.

**Both are now witnessed** (`tools/re/refs/lowdiv-2026-07-28/`, frames 01-05, driven from
the title screen under wine at TOTAL control):

* **All three non-Premier panels are banked**: `01_offers_panel_first_division.png`,
  `02_..._second_division.png`, `03_..._third_division.png`. Each is 20 kits in a 2x10 grid,
  same rect as the Premier panel.
* **The panel title changes with the division AND so does its icon.** Premier League draws
  the gold/orange ball; First / Second / Third draw the blue-silver globe, with the title
  string as the division's own chrome label ("First Division" / "Second Division" /
  "Third Division"). The selected DIVISION BUTTON is the maroon face with red text; the
  other three stay on the neutral grey-blue face.
* **The picked club is marked EXACTLY as in the Premier panel** — this is the answer to the
  open question, and it is a null result in the best sense: a **gold/yellow filled cell
  behind the kit**, plus the club's name centred in the strip **below** the grid
  (`04_offers_third_picked_barnet.png`: Barnet, Third Division). No division-specific
  marking exists. Committing the pick (`05_offers_first_picked_birmingham.png`) writes
  `MATS | Birmingham C` into the numbered manager row and advances to PLAYER 2.

So the whole-panel mask can come off: the port's per-division grids need no new marking
rule, only the correct club SET per division (which the db already carries) and the
division-specific title icon.
