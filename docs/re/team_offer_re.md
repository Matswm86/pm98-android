# TEAM OFFER answer card — frame RE (walkthrough run-3 086-092 + 150-153)

The modal the original pops over the MANAGER MENU when CPU clubs bid on a
transfer-listed player. Rebuilt 2026-07-03 to **pixel parity 0px** (both pairs)
under the entry-flow doctrine: chrome = the real frame baked verbatim
(`tools/re/build_team_offer_chrome_from_frames.py` → `app/art/screens/teamoffer/`),
dynamic layer = `app/scenes/TeamOfferScreen.gd`.

## Binding frames (run 3)

| frame | state |
|---|---|
| 086_164647 | Thornley card fresh: row-1 REFUSE solid, "Free if relegated" checked — the chrome BASE |
| 087_164648 | row-1 ACCEPT **pressed** (red inner outline) |
| 088_164650 | row-1 ACCEPT settled |
| 089_164652 | OK pressed |
| 090_164654 | McClair card (BIGFOTO photo present) |
| 091_164656 | row-1 REFUSE pressed |
| 150/151, 152/153 | Clegg (all clauses washed), Butt — same card, week 4 |
| 093/094, 154 | after OK: per-sale "X has been signed by Y." hub message boxes |

Flow truth: cards pop during CONTINUE processing after match day (085 FULL TIME
→ 086 TEAM OFFER); each offer row carries ONE toggle chip (REFUSE default, tap
flips, red inner outline while held); OK commits all rows and is the only exit;
each accepted sale then raises its own hub message box.

## Geometry (086 coords)

- Modal: (98,5)-(540,473) incl. black frame; card white body x100..538.
- Offer rows: list interior x129..445 (x114..127 = the scroll rail/arrow column,
  static chrome), rows y370+14i (5 rows, separators y369+14i), all row bg
  (240,240,240) filled or empty. Mini flag at (134, 371+14i) — **MINIBAND.PKF
  14x10, SAD 0.0**, borderless. Club text left x156, navy (30,52,98); amount
  right-edge 436, dark red (85,0,0); both PROMAN8@11.
- Answer chip zone x446..536: SOLID chip renders y370..382+shadow y383..385
  (its drop shadow darkens the washed chip's rim below); WASHED chip = a 14-row
  period `[128,128 | 160 | interior x7 | 160 | 128,128]` at y370+14i. Pressed =
  red inner outline extending y368..384. State cuts: btn_refuse_on(086),
  btn_accept_on(088), btn_refuse_pr(091), btn_accept_pr(087), ok_pr(089).
- OK chip x446..536 y442..470.
- Identity bands: NATIONALITY value x116..228 + KIND x234..327 (rows 124..135,
  2-tone washed dither); mini flag again at (117,125); STATUS x116..238 +
  darker INSURANCE x241..327 (rows 171..182); ROLE row y140..153: label chip
  x116..156, white gap col x157, **camrol sprite 25x14 at (158,140) SAD 0.0**
  (its black border/ring pixels are alpha-0 in our export — the screen draws a
  black backing rect), teal band x183..327, role word centred x255.
- AGE/WEIGHT/HEIGHT value strips y97..108 (centres 147.5/212/287). **Metric
  shown per the 2026-06-26 user call** — the original converts to imperial;
  the parity pairs exclude the WEIGHT/HEIGHT cells.
- Kit: 24x33 frame patch at (112,181) (`app/art/kits/ficha/`, Man Utd only —
  panel-kit precedent; scaled NANOESC fallback for clubs no frame shows).
  Club name PROMAN8 black, left x138 y191.
- Stat cells x449..471 y76+10i (digits centred x460); RATING box x482..522.
- Skill strip: all-black chips y144+13i (11 rows); star glyphs 11x8 at
  x426+14j, y chip+1 (star_full/star_half cut from the frame, SAD-0-asserted at
  every position). **halves = (value+1) div 10** — CORRECTED 2026-07-03: 090's
  HEADING 79 shows 4 FULL stars (the earlier "79→3½ confirms" was a misread),
  and the make-offer card 101 pins 19→1 full / 79→4 full. The rule fits all 18
  observations across 086/090/101; Thornley's six values (17, 70, 64, 67, 53,
  47) give identical output under both rules, so the 086/088 parity pairs never
  caught it. Values PROMAN8 **centred x511**.
- CONTRACT: fee bar interior x156..300 y249..259 (dithered; both bars END at
  x300 — an earlier x335 reading was the checked clause's red box), wage bar
  same at y280..290; money PROMAN8 gold (255,223,0) / pale (180,200,220),
  both **centred x228**; YEARS/LEFT boxes FLAT interiors (x156..211 / x252..287,
  y311..322), digits PROMAN8 centred x184/x270, colours (200,230,60)/(42,191,85).
- CLAUSES: 4 fixed labels; row-1 rect (327,244)-(440,254); clause_on cut from
  086 (checked+active), all-washed resting from 150. Only clause 0 has frame
  art. Our Career model stores no clauses → live cards always render the
  washed resting state (model gap, not a screen gap).
- Photo: 35x35 block at (106,39) (090), 33x33 interior; BIGFOTO 124x182
  downscaled by an unknown kernel — the screen's NEAREST fit is a documented
  approximation. Photo-less players (Thornley/Clegg: no face art in the bank)
  = no block, matching the frames exactly.

## Typography (the hard-won part)

Every face is used at its NATIVE .fnt size; **no bold pass anywhere on this
card except the name**:

| field | face | notes |
|---|---|---|
| name header | PROMAN12@13 | single-struck; "Ben THORNLEY" = `legalName` (given names Title-case + surname UPPER, Mc prefix lowered); left x147 y49 |
| position word | PROMAN10@10 | natural weight (same face as the baked HANDLING..SHOOTING labels), centred x221.5 y70 |
| everything else | PROMAN8@11 | its glyphs are naturally dense (2px strokes) — what reads as "bold" IS the face |

Number strings ('17' vs '70'/'82' etc.) are explained by **centring**, not
metric overrides: an earlier '1'-bearing hypothesis was wrong and is reverted
(see `fnt_to_bmfont.py` METRIC_OVERRIDES note). PMChrome.text y_top lands ink
2 rows below the anchor for these faces (anchors in TeamOfferScreen are ink-top
minus 2).

## Model wiring (Main.gd)

- CURRENT OFFERS band tap → `_show_team_offer(pid)` (replaces the interim
  ACCEPT/REFUSE browse dialogs).
- CONTINUE: `_pop_pending_team_offers()` after the match result returns to the
  hub (and on bye weeks) — one card per listed player with live bids, chained.
- OK → `_apply_offer_answers`: accepts run first in row order (first sale wins,
  all other bids lapse — `accept_offer` semantics); refused bids drop; refusals
  stay quiet (the original surfaces only signings as messages).
- CLUB FEE = `TransferMarket.value_of`, YEARLY WAGE = `Contract.yearly`,
  YEARS = `contract_term`, LEFT = `contract_years` (our model's split of the
  original pair).

## Honest gaps

- **FICHA RATING formula un-RE'd**: frame values 79 (Thornley), 79 (McClair),
  81 (Butt), 71 (Clegg) fit no mean of the shown attributes (squad-AV gives
  72/80/…); the RATING box is excluded from the parity pairs and still renders
  our squad-AV. Needs a Ghidra pass on FUN_0052e0d0's rating read.
- WEIGHT/HEIGHT cells: metric by user call (parity-excluded).
- Signing messages now raise the REAL "PREMIER MANAGER 98" hub alert box
  (frames 093/094/149) — reversed + parity-locked 2026-07-03, see
  `alert_box_re.md`; the 149-class rejection alert (post-MAKE-OFFER) is still
  un-wired (offer resolution timing differs in-app).
- Foreign CPU bidders (PSV in 152) un-modelled; offer rows default to the
  ENGLAND mini unless the offer carries `flag_code`.
- Photo downscale kernel unknown (NEAREST fit); no parity pair on a photo card.
- Solid-chip drop shadow is baked from "washed chip below" (086); two adjacent
  solid chips never occur in the frames.

## Parity

`shot_entry_parity.gd` states: teamoffer_086 (Thornley fresh + clause 0 +
Aston Villa £8,644,999 + frame fitness 67/morale 85/age 22 + display values
9,500,000 / 500,000 / 4 / 4) and teamoffer_088 (row-1 toggled ACCEPT).
`diff_entry_parity.py`: ROI = the modal; exclusions = WEIGHT/HEIGHT cells +
RATING box. **Both pairs: 0px — pixel-exact** (2026-07-03).
