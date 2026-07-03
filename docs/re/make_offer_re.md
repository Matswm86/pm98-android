# MAKE-OFFER card (PLAYER INFORMATION + OFFER panel) — frame RE (run-3 101-118)

The buy-side card the original opens from the OFFERS (transfer-browse) screen when
you pick another club's player: the FICHA identity card with the CONTRACT panel
replaced by the interactive **OFFER** panel (steppers + clause checkboxes) and the
button row **CANCEL / LOAN PLAYER / OFFER**. Decoded 2026-07-03 from walkthrough
run-3 frames 101-118 (Scott Taylor, Blackpool FW) + the owner's McKinlay capture
(`screenshots/transfer-offers-2026-07-02/make_offer_card.png`, Blackburn MF,
capture→design offset dx=+2 dy=+12) + the MANAGER.EXE label-draw helpers
`FUN_0052c66f` / `FUN_00525893` (decompiles in `docs/re/ofertas/`).

## Binding frames (run 3)

| frame | state |
|---|---|
| 100_164712 | the OFFERS browse screen (map + division squad list) the card opens over |
| 101_164714 | Taylor card fresh: offer £5,000 / fee £3,000,000 / wage £5,000 / years 1, no clause checked — the chrome BASE |
| 104-110 | CLUB OFFER ► held: 90,000 → 1,675,000 → 2,975,000 → 3,200,000 → settles 3,050,000 (hold-repeat accelerates; cap observed 3,200,000) |
| 112 | YEARLY WAGE stepped to £25,000 |
| 113 | **Scoring bonus checked**: red X + its stepper ACTIVATES showing £5,000 (black digits, arrow triangles turn black) |
| 114 | **House and car checked** (red X only — no stepper on that clause) |
| 116 | wage £35,000 |
| 118 | YEARS stepped to 3 + **OFFER pressed** (2px red ring outside the button border) |
| 119 | card closed back to the OFFERS screen — the offer submits silently (no message box) |

Flow truth: OFFERS browse list → player row tap → this card. CANCEL and OFFER both
return to the browse screen; nothing else exits. The info coin at (83,56)-(122,95)
is the animated spinner every card carries (it cycles frame-to-frame — parity
excludes it).

## Geometry (design coords; card black frame (76,48)-(563,430), white body (78,51)-(561,428))

- **Name bar**: navy (0,0,128) y66..84, solid x146..526 then the right fade ramp
  from x527 → white. Name white, `legalName` card form ("Scott TAYLOR"),
  **single-struck PROMAN12@13** (the face's natural weight IS the frame's bold
  look — a double-struck pass overshoots), ink-left x171 (parity-pinned). Photo
  (McKinlay): a **borderless 32x32** block at design (130,59) over the bar's
  left end, only when face art exists — Taylor (photoId 17924, no art in the
  bank) shows none, exactly like Thornley on the TEAM OFFER card.
- **Position word** ("FORWARD"): black PROMAN10, bbox (210,92)-(280,99) →
  centred x245.5, ink-top y92.
- **AGE / WEIGHT / HEIGHT**: label bands y106..116 (baked), value strips y117..128:
  AGE x140..201 olive (100,130,10) fill, WEIGHT x205..266 steel (59,85,130),
  HEIGHT x270..331 brown (135,73,22); values WHITE centred x170.5 / x235.5 /
  x300.5. The original shows imperial ("11 11", "5 10") — **we show metric**
  (75 kg / 180 cm), the standing 2026-06-26 user call; both cells parity-excluded.
- **NATIONALITY / KIND**: label bands y136..143 (baked), value strips y144..155
  grey (128,128,128); NAT box x140..251 (MINIBAND mini 14x10, SAD 0.0, at
  **(141,145)**; country white centred x204), KIND x257..351 ("NATIONAL"
  centred x304).
- **ROLE** row y160..173: label + icon cell baked chrome except the **camrol
  sprite 25x14 at (182,160), SAD 0.0** (same export as SQUAD/TEAM OFFER; its
  border/ring pixels are alpha-0 in the export and the frame shows them black —
  the screen draws a black backing rect, TEAM OFFER doctrine) and the fine-role
  word white centred x279 on the teal (42,95,85) band x207..351.
- **STATUS / INSURANCE**: label bands y180..190 (baked), value strips y191..202:
  STATUS slate (100,100,140) x140..238, "FIT" centred x200.5; then a white
  3px divider x261..263 and the INSURANCE value area **steel (59,85,130)**
  x264..351, "NONE" centred x307.5.
- **Club kit + name**: frame-rendered kit patch x140..171 y202..238 (Blackpool cut
  into `app/art/kits/ficha/` by the bake — the panel-kit precedent; scaled
  NANOESC fallback otherwise); club name black, title-cased, ink-left **x162**
  on the grey bar y208..219. The two empty slate bars below are static chrome.
- **Stat panel** x362..500: labels baked; six value cells x472..495 pale green
  (192,220,192), rows y96+10i (9 rows tall), digits BLACK centred x484.
  SPEED=VE STAMINA=RE AGGRESSION=AG QUALITY=CA FITNESS/MORAL=dynamic form.
- **RATING**: grey (220,220,220) box x505..544 y120..138, digits navy
  (59,85,130) PROMAN14. Frame shows 85 for Taylor while the browse list shows
  91 — the FICHA rating formula stays un-RE'd; the box is parity-excluded and
  renders our squad-AV (83), same doctrine as TEAM OFFER.
- **Skill strip**: six black chips x448..521, y164+13i (11 rows), labels baked.
  Star glyphs 11x8 (the TEAM OFFER star_full/star_half cuts, SAD 0.0) at
  x450+14j, y chip+1; **halves = (value+1) div 10** — the rule fitting ALL 18
  star observations across this card + TEAM OFFER 086/090 (090's HEADING 79
  shows 4 FULL stars, killing the earlier div-10 reading; TeamOfferScreen fixed
  2026-07-03). Values BLACK PROMAN8 centred x535.
- **OFFER panel** (grey 220 field x159..555 y251..387; black OFFER strip x136..158
  with the pale-lavender vertical word — all baked):
  - Stepper group frames x158..344 (offer/wage) and x158..253 (years), each a 1px
    black outline enclosing [◄ | bar | ►].
  - **CLUB OFFER**: red (210,0,0) bar interior x181..325 y271..282; arrows
    x165..178 / x328..341 (white buttons, black triangles); value GOLD
    (255,223,0) centred x253.5, ink-top y274.
  - **CLUB FEE**: orange (212,63,0) x181..325 y306..317, NO arrows (the asking
    price); value GOLD centred x253.5.
  - **YEARLY WAGE**: blue (42,63,170) x181..325 y336..347 + arrows; value PALE
    (180,200,220) centred x253.5.
  - **YEARS**: olive (80,110,5) x181..236 y368..379; arrows x165..178 /
    x239..252; value pale-green (200,230,60) centred x209.
  - Money strings PROMAN8, "£%,d". No pressed-arrow art exists in any frame —
    the arrows are static chrome (the original repaints only the value).
- **Clauses** (labels baked black; checkbox 11x11 black-border box, 9x9 white
  interior):
  - Free if relegated: box (351,290), label x366 y~291.
  - Matches to renew: box (351,306); its washed stepper below: arrows x373..384 /
    x427..438 (GREY triangles = disabled), bar (128,128,128) x388..423 y320..331.
  - Scoring bonus: box (351,339); wide stepper: arrows x373..384 / x507..518,
    bar x388..503 y354..365. **Player-gated**: active for Taylor (FW), washed
    label for McKinlay (MF) — `FUN_0052c66f` draws it washed unless bit 7 of
    `[player_screen+0x4728]` is set (the exact source predicate beyond
    "forward-class player" is un-RE'd; the app gates on broad pos FW).
    When CHECKED (113): red X, arrow triangles turn BLACK, value £5,000 appears
    (black, centred x446).
  - House and car: box (351,372); no stepper.
  - Check mark = the red X cut from 113's interior (9x9).
- **Buttons** y396..426: CANCEL x140..243 (red (255,31,0) text), LOAN PLAYER
  x253..396 (pale (200,220,240) text), OFFER x405..550 (white text) — ornate
  etched chrome, all baked. **Pressed** (118, OFFER): a 2px red (255,0,0) ring
  OUTSIDE the black border, rect x403..550 y396..424. Only OFFER's pressed state
  exists in frames; the same ring geometry is applied to CANCEL / LOAN PLAYER
  (documented extrapolation — identical widget chrome).

## Stepper behaviour (frame-observed)

- Base step £5,000 (offer + wage + scoring bonus all move in 5k multiples; years
  step 1). Holding repeats with acceleration (5,000 → 90,000 → 1,675,000 →
  2,975,000 across ~2s captures); the exact source repeat curve is un-RE'd — the
  app uses tap=±1 step, hold=accelerating repeat, documented approximation.
- Offer cap observed £3,200,000 against fee £3,000,000 (manager: Man Utd, week
  3). Best model-consistent hypothesis: available funds (our `sign_player`
  rejects offer > cash); the app clamps the stepper to cash. Floor £5,000.
- Initial values are constant regardless of player: offer £5,000, wage £5,000,
  years 1 (Taylor AND McKinlay).
- YEARS observed 1→3; range clamped 1..5 in-app (source max un-RE'd).

## Model wiring

- TRANSFER MARKET row tap (TransferScreen `player_pressed`) and the text-market
  list both open the card. OFFER → `Career.sign_player(pid, from_club, offer,
  rng, weekly, years, clauses)` (weekly/years newly honoured on success; checked
  clause indices stored on the player as `clauses` — display-only until the
  FICHA CLAUSES panel exists). LOAN PLAYER → `Career.sign_loan`. CANCEL closes.
- The original submits silently (119) — result messages ride the existing news
  log/toast, not a modal.

## Honest gaps

- Matches-to-renew checked state: NO frame shows it checked; its stepper stays
  washed and valueless even when checked (clause stored as boolean). Un-RE'd.
- Scoring-bonus gate: exact source predicate (bit 7 of +0x4728) un-RE'd beyond
  the FW-active / MF-washed observation; app gates on broad position FW.
- Offer cap = cash is a hypothesis (one observation, £3.2M); source rule un-RE'd.
- Stepper hold-repeat curve approximated (see above).
- FICHA RATING formula un-RE'd (85 vs our 83) — parity-excluded, renders squad-AV.
- WEIGHT/HEIGHT metric by user call — parity-excluded.
- CANCEL / LOAN PLAYER pressed states extrapolated from OFFER's 118 ring.
- Photo downscale kernel unknown (NEAREST fit, TEAM OFFER doctrine); no parity
  pair on a photo card.
- LOAN PLAYER: the original's loan follow-up screen (if any) is un-walked; our
  card routes straight to `sign_loan` and closes.

## Parity

`shot_entry_parity.gd` states: makeoffer_101 (Taylor fresh) and makeoffer_113
(offer 3,050,000 / wage 25,000 / Scoring bonus checked £5,000).
`diff_entry_parity.py`: ROI = the card frame (76,48)-(564,431); exclusions =
info coin (83,56)-(123,96) [animates], WEIGHT/HEIGHT value strips [metric],
RATING box [formula un-RE'd]. **Both pairs: 0px — pixel-exact** (2026-07-03).
NOTE for iterators: Godot does NOT reimport changed art in `--script` runs —
run `godot --headless --path app --import` after re-baking chrome or the shots
render the stale texture.
