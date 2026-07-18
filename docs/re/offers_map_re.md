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

## The left column is the PRESEASON chrome

Map (27,80 300x220), EUROPE/S.AMERICA side tabs, country strip, kit panel
(8,336 321x130), kit cells x13+31i y368/405, OVER gold selection cell at kit-2,
flag markers (data/pretemp_flag_markers*.json), enlarged-flag draw, nano-kit
fallback, own-club checker wash: ALL identical pixels (match ratio 1.000 on
map/tabs/strip vs app/art/screens/pretemp/chrome.png). PreseasonScreen's
machinery is the reference implementation.

* Flag tap: strip name + enlarged flag ALWAYS; the kit panel switches ONLY for
  a BROWSABLE country. Witness set: Spain (21 db clubs) switches (45);
  Macedonia (1 club — Sileks) does NOT (119); preseason frame 015 shows
  Hungary (5 clubs) not switching either. Adopted rule: browsable iff the
  country's club list holds a full league (>= 16 clubs: Spain/Argentina/
  France/Italy/Germany/Portugal/Holland) — fitted to all three witnesses, the
  original's exact list un-RE'd.
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
