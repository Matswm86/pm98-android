# GOAL SCORERS screen — witness RE + frame-true port (2026-07-18)

Charter #8 item 1 (APP_VS_SPEC_AUDIT §C1 #1: "button painted, dead — no screen, no
code refs"). Entry: LEAGUE TABLES → GOAL SCORERS (button 525,354,99,24, baked in the
league-table chrome per `league_table_screen_re.md`). RETURN goes back to LEAGUE
TABLES (witnessed, capture 29).

## Binding sources

**EMPTY state** (the only state any pre-existing capture held):
- `screenshots/original-walkthrough-2026-07-02/047_154510.png` == `048_154514.png`
  == `screenshots/parity-run-2026-07-16/orig/12_goalscorers.png` — three independent
  captures, 0.00 mean-abs-diff (title + graph fingerprints identical). Preseason,
  blank pager band, 14 empty list bars, empty graph, 3 empty compare slots.
- Confirmed by sweep: NO populated GOAL SCORERS exists in the 638-frame walkthrough,
  the parity run, the promanager run, any wine-captures set, or the real-gallery
  (`~/MWM-AI/data/pm98-refs/real-gallery/` scanned — no ma_* shows this screen).

**POPULATED + interactions** — witnessed live this session (2026-07-18) by driving
the ORIGINAL in wine (`tools/re/wine/boot.sh` harness) through a fresh Manager League
career (mwm @ Bolton W, TOTAL, all 4 friendlies skipped, RESULTS mode, played to
week 5). Captures: `screenshots/wine-captures-2026-07-18-goalscorers/` (01–90,
gitignored like all capture sets). Key frames:

| frame | state |
|---|---|
| 18 | WEEKS 2 list populated (Heskey/Sheringham/Ripley 2, 11 more at 1) |
| 19/20 | pager ◀/▶ clicked at 2 weeks — **0 px change** |
| 21 | white COMPARE armed → label "SELECT" (+ standard click-focus ring) |
| 22 | row tapped while armed: slot bar = kit+"Heskey", row outlined, **mark already plotted**, label still SELECT |
| 23 | button re-tapped: label back to COMPARE, outline gone, mark stays |
| 24/26 | red slot armed + Sheringham selected (red mark overdraws white at shared cell) |
| 27 | unarmed row tap → per-player goal-log popup (Stuart Edward RIPLEY) |
| 28/29 | popup RETURN → screen; screen RETURN → LEAGUE TABLES (populated table bonus witness) |
| 84–87 | week-5 re-entry: "WEEKS 4" list, **compare slots RESET to empty** |
| 88/89 | pager arrows at 4 weeks — 0 px change again |
| 90 | Abou (3 goals) compared → mark x77..83 y294..295 |

## Witnessed semantics (all ported)

- **Pager band** = "WEEKS n" gold(255,223,0) centred in the dark-red band, where
  n = league rounds played (header "Week 3" ↔ "WEEKS 2"; header week = n+1). Blank
  before round 1 (the walkthrough state). **Stepper arrows are inert** at 2 and 4
  rounds (single clicks, 0 px). UNKNOWN: whether they page a >14-entry list late
  season — ported as baked inert chrome; re-witness if a long-season capture appears.
- **List**: 14 bars (y123 pitch 16 h 12), G. cell x319-354 (ink 30,52,98) /
  PLAYER navy bar x356-465 (white ink) / TEAM grey bar x467-605 (black ink), text
  centred, thin face (= proman8 raster @11, the INSURANCE-row face). Ranked by goals
  desc; tie order in frames 18/87 is consistent with "first to reach that count
  first" (Heskey wk1 before Sheringham wk2 in the 2-goal group) — adopted, but the
  original's exact tiebreak is NOT exhaustively provable from two frames.
- **COMPARE flow**: button arms a slot (label block swaps to "SELECT" — one sprite,
  white-slot 21 vs red-slot 24 label regions differ 0.00; the white ring in 21 is
  the engine's click-focus border, also seen on INSURANCE "PARAM." — not armed
  chrome). While armed: row tap fills the slot bar (club kit + surname, dark ink on
  the light area) + outlines the row (85,127,255, 2px, x317..607, band ±2) + plots
  the graph line immediately; the arm persists. Re-tapping the button disarms
  (outline clears, plot + slot stay). Slots are per-visit: re-entry resets (87).
- **Graph marks** (pixel-calibrated on 3 witnesses):
  dot(week w, cumulative total g) = 2x2 px at (67 + 5·(w−1), 309 − 5·g).
  Weeks with total 0 draw NOTHING (Sheringham wk1 absent). Consecutive plotted
  weeks connect — flat runs witnessed contiguous (Heskey x67..73 = wk1→wk2 at 2).
  A RISING connection was never witnessed (both compares were flat) — ported as a
  straight 2px segment between the dots; this is the port's ONLY interpolation.
  Colours = the slot stripe colours sampled off the chrome: WHITE 255,255,255
  (witnessed as marks), RED 255,31,0 (witnessed), BLUE 0,0,220 (slot-3 stripe;
  a blue compare was never armed — pattern-derived from slots 1-2 stripe==mark).
  Later slots overdraw earlier at shared cells (26).
- **Goal-log popup** (27): title = "First Middle SURNAME" (the roster `legalName`),
  12 rows of WEEK (dark-red cell, gold digit) | MATCH home club | away club (navy
  cells, white ink) | MIN. (light cell, navy "´88"-style minute), strip "Data up to
  MATCH n" (n = rounds played), RETURN. Modal over the screen. The original's
  minute glyph is a leaning tick (´); the proman raster carries ASCII apostrophe
  only → rendered "'88" (typography substitution, documented here).

## Data layer (app)

`Career.scorer_log` — NEW persisted ledger: every league goal of EVERY fixture in
the round loop of `advance_week` ({week 1-based, scorer, club, minute, h, a}).
The stat engine's `res["goals"]` vector already names real scorers for all
fixtures (ai_featured XIs), it was just being discarded for non-manager matches.
- **Own goals excluded** from the ledger: the goals vector's `scorer` for an OG is
  the conceding-side player; crediting him on a scorers chart would be wrong. The
  original's OG handling on this screen is unwitnessed (no OG occurred in the run).
- League fixtures only: friendlies witnessed absent (preseason state empty after
  friendlies existed); cup competitions unwitnessed → not fed (documented gap).
- `league_scorers()` / `scorer_goal_dict()` / `_legal_name()` accessors; save/load
  round-trips; legacy saves load with an empty ledger (honest empty chart).

## Port verification (all run this session)

- Bake: `tools/re/build_goalscorers_chrome_from_frames.py` → chrome.png (047
  verbatim, only the barra plaque blanked for the live PMChrome header),
  select_label.png (cross-check white-vs-red slot 0.00), popup.png (27 crop, title/
  rows/strip text blanked to their sampled cell colours).
- GL render (`app/tests/shot_goalscorers_verify.gd`, DISPLAY=:1 opengl3):
  - empty state vs 047: **0 px** body diff (barra masked).
  - compare state vs 23, graph region: **0 px** — Heskey's mark lands exactly on
    the original's pixels (x67..73, y299..300).
  - populated list vs 18 / popup vs 27: layout+position+size aligned; residual
    ~6.4k px = glyph-shape differences of our proman8 raster vs the original face
    (same face-level standard as the other ported list screens).
- Headless: `test_goalscorers_screen.gd` (34 asserts) + `test_league_screen` +
  `test_career` + `test_wiring_pass` — ALL PASS; boot smoke clean.
- REAL APP driven end-to-end (run_the_app rule): loaded the mwm/Bolton save, played
  week 1 (MU 3-2 Bolton), opened LEAGUE TABLES → GOAL SCORERS: live ledger showed
  the whole round's real scorers ("WEEKS 1", Flo 2 top, our Frandsen/Thompson +
  MU's Sheringham/Solskjaer/Giggs present), COMPARE armed/filled "Flo", unarmed tap
  opened "Tore Andre FLO" popup (2 goals, West Ham Utd–Chelsea '27 '60, "Data up to
  MATCH 1").

## Honest gaps / unknowns kept

- Pager arrows inert (witnessed inert at 2 and 4 rounds; late-season behaviour
  unknown — never invented).
- List truncates at the 14 witnessed bars; whether the original pages beyond 14 is
  the same unknown as the arrows.
- Rising graph-line shape between weeks: straight-segment interpolation (flagged
  above) — re-witness with a multi-week scorer when a longer career is driven.
- Blue mark colour pattern-derived (slot-3 never armed in a witness).
- Tie order model choice (first-to-reach) — consistent with, not proven by, frames.
- Cup goals not fed (unwitnessed whether the original counts them here).
- Sim-season league tables (no career): button inert — no ledger exists there.

## Bonus witnesses banked this run (for the REMAINING #8 items + others)

Same capture set, ready for their own ports — no re-drive needed:
- **INSURANCE**: 33-39 — INSURANCE POLICY modal (GROUP 1/2/3 = £200/£500/£1,000
  per month, FLAT across players: Ward £1,250 wage vs Frandsen £14,583 same prices
  → game constants); select group 1 → row INSUR. arrow green + "1" + COST 200;
  83 — populated INJURIES row (Branagan, pulled hamstring, wk 3, H NO, PRICE
  £4,500, INSUR. NO, COST £4,500).
- **SCOUT**: 43 (no-scout gate "You need to hire a scout to search for a player."),
  62 ("You have to select some options to make the search."), 67 (criterion enable
  toggle + POSITION=GOALKEEPER dropdown), 68 ("The scout is now searching for
  players with the selected capabilities." — search is ASYNC), 78 ("The scout has
  finished his search." hub alert ~1 game-week later), 81 (PLAYERS FOUND populated:
  NAME/stars/AV/MO/CLUB FEE/WAGE/YEARS rows), 82 (row → PLAYER INFORMATION offer
  card, the existing overlay).
- **OFFERS map**: 44 (empty, England kits + league selector), 45 (Spain selected —
  flag enlarges, country plate, 20 Spanish kits, selector hidden for foreign),
  46 (F.C. Barcelona squad list w/ N°/flags/stars/AV/ROL), 47 (row → Rivaldo
  PLAYER INFORMATION card w/ LOAN PLAYER/OFFER).
- **SAVE GAME**: 51 (8-slot GAME/PLAYER dialog over undimmed hub), 52 (slot 1
  selected → black), 53 ("wk3" typed), 54 (**"The game can´t be saved." alert** —
  wine-environment failure (disk-space check path per EXE strings), so the dialog
  UI + error path are witnessed; a successful save is NOT — the app keeps its own
  save format anyway).
- **Season flow**: 09 (CHARITY SHIELD CHAMPION — MU bt Chelsea), 10 (START OF
  SEASON objectives table), 75 (Coca-Cola Cup ROUND 2 draw w/ drum + 1ST/2ND LEG),
  76 (MANAGERS OF THE MONTH (AUGUST) 4-division cards), 77 (PLAYERS OF THE MONTH
  per-club table w/ division tabs).
- **Hub stack**: 16 vs 78 — home game = PL1/mwm/own-club on TOP (own block upper);
  away game = CPU/opp-manager/opp-club on TOP (charter #2 semantics data).
- **LEAGUE TABLES populated**: 29 — live standings after 2 rounds (Coventry 6pts
  leader + kit in LEADER card, Bolton black managed row w/ up/down POS arrows,
  date-box "14/8/1997" while header says 23 Aug → the box is a ROUND-date value,
  refining the "2 days behind" note in league_table_screen_re.md).
- **LINE-UP injured-XI gate**: 84 ("You can´t play without goalkeeper." alert;
  injured row = red cross + orange "3 WEEKS" band replacing stats), 85 (swap moves
  Branagan to SUBSTITUTES with the same band).
- **Staff pools (charter #9 data)**: 57 (TRAINERS tab: T. Savage ★★★★★ £52,000,
  R. Robinson ★★★★ £19,000, B. Rogers ★★★★★ £52,000), 58 (SCOUT tab: R. Robson ★★
  £6,000, J. Gomez ★ £4,000, K. Burrowes ★★★ £20,000), 60 (hired bar: "WAGE
  £20,000 | K. Burrowes | ★★★").

## Wine-harness notes (new this run)

- Skipping all 4 preseason friendlies fast-forwards through CHARITY SHIELD +
  START OF SEASON straight to the Week-1 hub (fastest route to in-season state).
- RESULTS view mode + LINE-UPS OFF sims a half instantly (HALF TIME read-out ~3s
  after OK) — a full league round costs ~30s of clicking. Career to week 5 ≈ 10 min.
- SAVE GAME fails under wine ("can´t be saved") → no save-state shortcut exists;
  future witness runs must re-drive the career (use the recipe above).
- `snap.sh` honours a preset `$ORACLE_OUT` (export it to the capture dir; default
  points at a dead session scratchpad).
