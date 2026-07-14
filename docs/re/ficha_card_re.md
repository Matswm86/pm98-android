# FICHA / PLAYER INFORMATION card — frame RE (walkthrough run-1 079-085)

The card SQUAD MANAGEMENT opens on a player row. Rebuilt 2026-07-03 to **pixel
parity 0px** (both pairs) under the entry-flow doctrine: chrome = the real frame
baked verbatim (`tools/re/build_ficha_chrome_from_frames.py` →
`app/art/screens/ficha/`), dynamic layer = `app/scenes/PlayerInfoScreen.gd`.
Closes the B7 "CLAUSES + YEARS|LEFT on the FICHA itself" gap (the old
hand-drawn full-screen card is gone).

## Binding frames (run 1)

| frame | state |
|---|---|
| 077/078 | SQUAD MANAGEMENT (clean host) |
| 079 | Van der Gouw card fresh, OK unpressed — the chrome BASE |
| 080/081 | same card, OK **held** (red ring persists across captures); 081 coin at "i" |
| 082/083 | back on SQUAD MANAGEMENT (clean again) |
| 084/085 | Solskjaer card, OK held; the two frames differ ONLY in the info coin |

Card states: 081 = **Free if relegated** + **Matches to renew (20)** checked
(with the "Matches played: 0" sub-line), Scoring/House washed. 084 = Free +
**Scoring bonus (£5,000)** checked (with "Goals: 0"), Matches/House washed.

## Host palette-dim (081-vs-082)

While the card is up, the WHOLE squad screen behind palette-dims through the
SAME exact LUT as the hub alert (`alert/dim_lut.json`): applying that LUT to
clean 082 reproduces dimmed 081 outside the card with **zero unknown colours**
(the only residual mismatch is the squad row-selection cursor, dynamic state).
In-app: `SquadScreen.set_dimmed` routes every colour/kit through
`PMChrome.dim_col` / `PMAlert.dim_texture`, `PMChrome.draw_bg` swaps to the
pre-baked `management_bg_dim.png` (exact LUT pass at bake time), and Main
brackets the card's lifetime. Hosts without LUT-dim support yet (DATA BASE
browse) keep the card's old flat backdrop — documented interim, `host_dims`.

## Geometry (screen coords; card black frame (76,58)-(563,420))

Same 488px-wide card as MAKE-OFFER, 10px lower, 20px shorter. **Every shared
top-section element = the make-offer design coords +9 in y** (verified
pixel-identical at dy=+9 over the identity zone) — photo (130,68) 32x32
borderless, name ink-left x171 (anchor y78), position word centred **x246**
(ink rule: ink_left = 245 − ink_w/2; 245.5 put GOALKEEPER 1px left),
AGE/WGT/HGT value strips y126..137 (centres 171/236.5/301.5), NAT flag
(141,154) + country cx204 / KIND cx304 (y154), camrol (182,169) + fine role
cx279 (y171), STATUS cx200.5 / INSURANCE cx307.5 (y201), kit 32x37 at
(140,211), club name x162 (y218), stat cells digits cx484 y104+10i, RATING
navy cx525 (y131), skill chips y173+13i with stars x450+14j (halves =
(v+1) div 10) and values cx535.

Unique to this card:

- **Buttons** pin the card origin to the FUN_00526a60 card-local rects exactly:
  RENEW (85,325)104x25 → screen (161,383); TRANSFER (272,383); SACK (383,383);
  OK (429,325)52x25 → (505,383). Held OK = 2px red ring OUTSIDE the border,
  rect (503,381)-(558,409), frame-cut `ok_pr.png` (081≡084); the ring is
  extrapolated onto the three siblings (identical chrome, make-offer doctrine).
- **CONTRACT panel** (136,257)-(556,360), black CONTRACT strip x136..158:
  CLUB FEE bar (212,63,0) interior x180..324 y278..289, gold (255,223,0) value
  centred x252 (anchor y279); YEARLY WAGE bar (42,63,170) y308..319, pale
  (180,200,220) value; YEARS box olive (80,110,5) interior x180..235 y340..351,
  digit (200,230,60) cx207.5; LEFT box teal (42,95,85) x276..311, digit
  (42,191,85) cx293.5 (anchors y341).
- **CLAUSES column**: navy "CLAUSES:" header (static, baked); four 11x11
  checkboxes at x351, rows y273/287/316/345 (Free / Matches / Scoring /
  House); labels ink-left x366 at anchor = box row. **Checked** = black border,
  white 9x9 interior, solid 7x7 (255,31,0) core + BLACK label; **washed** =
  grey-144 border, field-grey-220 interior + grey-144 label. Active labels
  carry their figure — "Matches to renew (20)", "Scoring bonus (£5,000)" — and
  a black progress sub-line: "Matches played: 0" (ink-top y300, anchor 298),
  "Goals: 0" (ink-top y329, anchor 327). The screen draws boxes as rects (the
  bake asserts the exact pattern in both frames) — every state combination
  renders, incl. the never-walked Free-washed resting look (extrapolated
  widget doctrine).

## Data fixes the frames forced (tools/extract_english.py)

- **Nationality**: VdG's record carries `['HOLLAND', 'VITESSE', <bio>]` — no
  separate birthplace/nationality fields; frame 081 shows HOLLAND, so the game
  reads the country wherever it sits among the bio strings. The decoder now
  prefers the LAST whitelist match (explicit 3-string layout wins: Schmeichel
  GLADSAXE/BRONDBY/DENMARK) and falls back to any earlier country string.
  Rebuild churn: 24 nationality recoveries, all real (Gallacher SCOTLAND,
  Kewell AUSTRALIA, Barnes/Blake/Marshall JAMAICA, Maik Taylor + Leese GERMANY,
  Hiden/Manninger/Dorner AUSTRIA, Wiekens/De Zeeuw/Snijders HOLLAND, ...).
- **KIND**: frames kill the old British-only rule — VdG (HOLLAND) and
  Solskjaer (NORWAY) both show **NATIONAL**. Interpretation: the post-Bosman
  EU/EEA work-permit class (the Spanish original's "comunitario" flag) —
  EU-15 + EEA 1997 → NATIONAL, else NON-NATIONAL. The negative side is a
  hypothesis (no non-EU player FICHA walked yet; the EXE carries the
  NON-NATIONAL string). 78 kind flips on rebuild, all EU/EEA foreigners.
- The bake SAD-0.0-asserts mini_027 (HOLLAND) / mini_044 (NORWAY) against the
  frames' flag pixels — the pipeline fix is pixel-proven, not inferred.

## Model wiring

- `Career.sign_player` now takes the make-offer card's `bonus` and stamps
  `clause_bonus` (+ `clause_goals`=0) for a Scoring-bonus deal and
  `clause_apps`=0 for Matches-to-renew; `MakeOfferScreen.offer_made` gained the
  bonus arg (0 unless the clause is checked).
- `Career.advance_week` advances the counters on the LIVE roster dicts: a
  featured XI man with `clause_apps` logs an appearance each played week; a
  `clause_goals` man logs his non-own goals from the stat engine's scorer
  vector. OUR tracking semantics — the original's exact counters are un-RE'd
  beyond the frame labels.
- A matches-to-renew TARGET is not negotiable on the make-offer card (its
  stepper is washed/valueless, un-RE'd) → `clause_matches` is only rendered
  when present; live signings show the label without the "(N)".
- Card name form generalised to `PMChrome.card_name` (surname = the record's
  `name` field as suffix): "Raimond VAN DER GOUW" (081), "Ole Gunnar
  SOLSKJAER" (084); TEAM OFFER + MAKE-OFFER now share it.
- Kit-bank split: `art/kits/ficha/` = the 32x37 CARD slot (82 Blackpool, 40
  Man Utd from 081); the TEAM OFFER card's 24x33 slot cut moved to
  `art/screens/teamoffer/kit_40.png` (its bake + screen updated; the two slots
  had collided on 40.png). NOTE: TeamOfferScreen must cache the kit at
  setup — a draw-time `load()` blits nothing on the presented frames under
  `--script` runs (caught by the parity suite).

## Honest gaps

- **FICHA RATING formula RE'd (2026-07-03), parity-INCLUDED**: the box renders
  the real `FUN_00581e60` = (VE+RE+AG+CA+FITNESS+MORALE)/6, in the value-cell
  font (proman12 @13) at `RATING_C (526,132)` — 0px vs frames 081/084 (80 / 82).
  The old squad-AV keeper mismatch is resolved: RATING never averaged the skill
  attrs, it is the four core attrs + the two dynamic bars. See
  **docs/re/morale_re.md**.
- WEIGHT/HEIGHT metric by the standing 2026-06-26 user call (parity-excluded).
- BIGFOTO downscale kernel un-RE'd (NEAREST fit; photo block parity-excluded).
- Info coin animates (baked as 079's frame; parity-excluded). RE'd 2026-07-06:
  decorative — FUN_00526640 builds it as a 40x40 `RECURSOS\ICONOS\info.gif`
  widget at card-local (7,7), id -1, no click handler; live clicks (single/
  double/right) do nothing. Do NOT wire it to bios — see dbase_player_card_re.md.
- Read-only card (DATA BASE opener) covers RENEW/TRANSFER/SACK with card
  white — that opener state is un-walked; kept app behaviour, not frame truth.
- Dismissal animation un-evidenced; card closes instantly.
- DATA BASE / RivalScreen hosts keep the flat backdrop (no LUT dim yet).
- KIND for non-EU players + the matches-to-renew target: see above.

## Parity

`shot_entry_parity.gd` states: ficha_081 (VdG, clauses [0,1] + matches 20 +
apps 0, fee 450,000 / yearly 225,000 / years 1 / left 1, fitness 70 morale 94,
age 34, OK held) and ficha_084 (Solskjaer, clauses [0,2] + bonus 5,000 +
goals 0, fee 8,500,000 / yearly 575,000, fitness 70 morale 90, age 24, OK
held). `diff_entry_parity.py`: ROI = the card (76,58)-(564,421); exclusions =
coin, photo block, WEIGHT/HEIGHT strips, RATING box. **Both pairs: 0px —
pixel-exact** (2026-07-03).

## 2026-07-14 — NATIONALITY/KIND null-guard (undecoded foreign/reserve players)

The FICHA flag ART/placement is source-faithful (real BANDERAS.PKF waving flag, flush-left in
the value band, verified vs `screens/player_info_ref.jpg` — Schmeichel renders the Dannebrog
[code 18] + "DENMARK"). BUT the DATA is only decoded for ~2,042 of 9,547 players: the rest
(foreign/None-league + reserves) carry `nationality: null` **and** `kind: null` in
`game_db.json`, while `build_db` still defaults `flagCode` to 30 (ENGLAND).

Before this fix that rendered as **"<NULL>"** text + an **invented ENGLAND flag** (e.g.
Barcelona's Ruud Hesp, a Dutch keeper, showed the St George's cross). Root cause: GDScript
`Dictionary.get(k, default)` returns `null` when the key is PRESENT with a null value, so the
`"ENGLAND"`/`"NATIONAL"` fallbacks never fired, and the flag drew off the always-present
`flagCode`. Fix (`PlayerInfoScreen.gd`, FICHA-side only, no db rebuild): gate the flag + country
text on a KNOWN nationality; otherwise honest **"-"** and NO flag — never invent a country.
`kind` shares the new `_decoded_or_dash()` helper. Matches the existing weight/height "-" gap
convention. Render-verified both paths (Schmeichel = flag+DENMARK+NATIONAL; Hesp = "-"/"-").
`test_player_info` guards `_decoded_or_dash(null|""|"denmark")`.

**HONEST GAP / follow-up (NOT invented):** the real per-player nationality for the ~7,505 null
players is a source-decode task (their EQUIPOS/extended records aren't run through the country
decode yet). Until decoded, those FICHAs show "-" rather than a wrong flag.
