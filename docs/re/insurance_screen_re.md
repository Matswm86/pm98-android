# INSURANCE screen + INSURANCE POLICY modal — RE + frame-true port (2026-07-18)

Witnessed LIVE in wine during the 2026-07-18 goalscorers run (fresh Manager
League mwm/Bolton career, week 3): captures 33-39 + 83 of
`screenshots/wine-captures-2026-07-18-goalscorers/`. Ported the same day:
`app/scenes/InsuranceScreen.gd`, baker
`tools/re/build_insurance_chrome_from_frames.py`, art
`app/art/screens/insurance/` (+ `insurance_chrome.json` geometry/inks).
Reached INJURIES -> INSURANCE; RETURN re-raises INJURIES (witnessed 39->40).

## Binding witnesses

| capture | state |
|---|---|
| 33 | resting screen, all uninsured; PARAM. carries the engine's transient click-focus ring |
| 34 | == 33 minus the PARAM. ring (verified: the ONLY diff) -> **the body chrome source** |
| 35 | INSURANCE POLICY modal on Ward, UNINSURED — whole frame palette-dimmed |
| 36 | GROUP 1 tapped: red pending border on "1", header previews INSUR. GROUP 1 / £200 BEFORE OK |
| 37 | after OK: Ward row = green arrow, pale-green cell + doc + "1", grey COST cell + red 200 |
| 38 | Frandsen's modal, uninsured (wage £14,583 vs Ward £1,250 — SAME prices) |
| 39 | == 37 (state persists; Frandsen closed uninsured = OK commits nothing untapped) |
| 83 | populated INJURIES row (Branagan): PRICE £4,500, INSUR. NO, COST £4,500 (payout side, un-RE'd) |

## Decoded structure (all measured, design 640x480)

- **Sections fixed**: KEEP y87 x3 slots, DEF y151 x5, MID y247 x5, FOR y343 x4;
  pitch 16, row box h14 (borders y0/y0+13, fill 240,240,240). Bolton has 4 MFs
  -> the MID 5th slot is PLAIN PANEL: row grids are per-player, not furniture.
  Order = REVERSE record order per section (matches all 16 witnessed rows).
- **Row cells**: icon x7..28 (folder sprite, identical every row) | box x29..602,
  verticals 173,198,223,248,273,298,323,349,374,410 | arrow button x474..501 |
  INSUR. cell x502..534 | sep x535 | COST cell x536..601 | border x602. The
  x7..8 black dashes are the PANEL frame (kept in chrome; visible on empty slots).
- **Insured row state** (37): arrow_on sprite; INSUR. cell fill (170,223,170) +
  doc icon at (511, top+2) + group digit at x524 (ink == the modal button digit
  ink — PROVEN for group 1 (60,90,0); groups 2/3 (0,0,128)/(85,0,0)
  pattern-derived); COST cell fill (192,192,192) + price centred, ink (170,63,85).
- **Digit grammar** (the port's 0px key): digit runs are monospaced at advance 8
  ("1" -> 5) and centre on a per-column centre CX with px = floor(CX - tw/2).
  CX: num 41.5, EN 186, SP 211, ST 236, AG 261, QU 286, FI 311, MO 336, AV 362,
  AGE 393. Fitted on ALL 26 witnessed cell landings; per-string
  get_string_size centring drifts 1px on "1"-carrying values.
- **Column value sources** (witness-bound): SP ST AG QU = attrs VE RE AG CA
  (exact on every checked row); FI = the LIVE fitness stat (morale_re.md +0xa7;
  fresh 99 -> 70 witnessed); MO = live morale; AV = Morale.av6 (Ward
  (64+64+54+39+70+90)/6 = 63 == witness, verified on 5 rows); EN = ENERGIA,
  99 on ALL 16 rows = the between-matches rested state (app renders a stored
  `energy` or 99).
- **Foreigner flag**: mini nationality flag at (50, top+2) in the N° cell.
  Witnessed: Icelanders yes; Danes/Finn/Irish no -> rule = nationality NOT in
  the EU-1997 member list (pattern-derived; the original's bit un-RE'd).
- **Scrollbar** (x609..624 per section): noscroll = 17px dotted up arrow + pale
  dither + 18px dotted down arrow (KEEP+MID witnessed); scrollable = 16px up +
  track (120,140,160) + slider + black row + 15px black-face down (DEF 9/5 +
  FOR 6/4 witnessed). Slider h = floor(track_h*slots/total), off =
  floor(track_h*first/total) — reproduces DEF 25px AND FOR 20px exactly. BOTH
  dither faces are period-4 row patterns (rows [A,B,C,B] after fixed headers) —
  reconstruction reproduces all four witnessed columns 0px. Up-enabled face =
  vflip(down-enabled), pattern-derived (both witnesses at first=0).
- **Wage column**: monthly = yearly/12 truncated (witness values are exact
  /12 of round yearly figures). App renders Contract.current_weekly x 52/12 —
  the VALUES are the app's calibrated wage model, not the original's decoded
  wages (charter-#10 parity gap; masked in the GL diff).
- **Modal** (x104..554, y86..392): whole frame dims through the PMAlert alert
  LUT (9/9 sampled colour pairs match; strip right of the modal verifies 0px).
  Header card cells x148..338 / x341..504 (borders 146/147, 339/340, 505/506);
  title bands y121..135, value row y150..160. GROUP prices are FLAT constants
  £200/£500/£1,000 (35 vs 38). Selecting previews immediately (36); the 2px
  red (255,31,0) border frames the tapped box OUTSIDE its black border
  (x228..263 y359..384 around "1"); fresh-open shows NO border (35/38). OK is
  the only exit; commits the tapped group. SELECT boxes: NONE (128,361,90,22),
  1/2/3 (230/270/310, 361, 32, 22); OK ~(458,357,92,30).

## Port verification (2026-07-18)

- GL (`app/tests/shot_insurance_verify.gd` + masked diff; masks = live barra
  y<62 + WAGE cells only):
  - resting vs 34: **0 px**  (16 live rows, flags, scrollbars, chrome — everything)
  - insured vs 37: **0 px**  (arrow_on, doc cell, digit, cost — everything)
  - modal vs 35/36/38, modal rect: furniture/dim/border/doc icons **0 px**;
    residual ~0.9-1.2k px = the dynamic text bands ("Ward (age 27)",
    UNINSURED/INSUR. GROUP n, £ values) — our proman8@12 advances differ from
    the original's modal face (the goalscorers-popup face-level standard), plus
    the inherently-different model wage value.
- Headless: `test_insurance_screen.gd` (40+ asserts) + `test_injuries_screen`
  + `test_career` + `test_wiring_pass` + `test_goalscorers_screen` — ALL PASS;
  boot smoke clean.
- REAL APP driven E2E (run_the_app rule; blind-driven via xdotool +
  `x11grab -window_id` captures): booted, LOAD GAME -> mwm/Bolton save, hub ->
  LINE-UP -> INJURED -> INSURANCE (live squad, live FI/MO, flags, sliders) ->
  Ward arrow -> POLICY modal (LUT dim live) -> GROUP 2 (red border + preview
  £500) -> OK -> row shows green arrow + doc + navy "2" + COST 500 ->
  career.json carries `Ward: insurance_group 2` -> RETURN re-raises INJURIES.

## Honest gaps / unknowns kept

- RATING view un-walked -> baked PARAM.-active state is the only view; both
  toggle buttons inert (also MONTHLY WAGE / MONTHLY COST legend = static bake).
- Premium CHARGING cadence + injury payout flow un-RE'd -> no money moves; the
  FinanceScreen PLAYERS' INSURANCE / INSURANCE GROUP 3 lines stay £0 gaps.
  (INJURIES PRICE/INSUR./COST columns likewise stay resting furniture.)
- Row digit inks for groups 2/3, up-enabled arrow face, scrolled slider
  positions, insured-player modal re-open border: pattern-derived, unwitnessed.
- Wage VALUES (charter #10): original per-player wages undecoded; grammar
  (yearly/12, £-comma format) is faithful.
- The header stays bright under the modal (draw_match_header is not LUT-aware;
  the SquadScreen FICHA precedent) — the witness dims it.
- EN column renders the rested 99 (live in-match energia unmodeled).
