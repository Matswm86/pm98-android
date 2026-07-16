# NEWS extra (NOTICIAS) — frame-true reconstruction

**Status 2026-07-16: SHIPPED — all three witnessed states 0px pixel-exact on the
full overlay footprint** (`tools/re/diff_news_parity.py`).

The hub NEWS control opens the original's newspaper overlay, not a screen: the
"News extra" page floats over the live MANAGER MENU hub. The previous app build
showed an invented `Career.news_log` BrowseScreen feed here (audit §B1
SUBSTITUTE, §B5-1); this rebuild replaces it with the original page.

## Binding frames (walkthrough run1, MWM / Manchester Utd, Fri 1 Aug 1997)

| frame | state |
|---|---|
| `155_154857` | front page: masthead (football photo + red **News** block + typewriter *extra*), blue `Premier League : MARKET` subtitle + light-blue rule, **EMPTY** white body (preseason), `WEEKS: LAST/ACTUAL` toggle (ACTUAL selected, black plate), bottom file-tabs **MARKET**(on)/INJURIES/BOOKINGS, right rotated division tabs **Premier**(on)/1st/2nd/3rd Div., grey `[X]` |
| `156_154859` | same + INJURIES bottom tab in its **over** state (only diff: 69x12px inside the tab) |
| `157_154901` | pixel-identical to 155 (state stability check) |
| `158_154905` | 1st Div. tab clicked: **masthead gone**, subtitle `First Division : MARKET` at the page top, Premier tab off / 1st Div. on, `[X]` in its yellow **over** art |

No other NEWS frame exists in the 638-frame walkthrough (all three runs swept
via title-strip contact sheets — the same sweep that found the youth frames).

## MANAGER.EXE provenance

The NOTICIAS string block (near the MARKET/ACTUAL/LAST strings):

- `"%s : %s"` — the subtitle format string; division names `Premier League` /
  `First Division` / `Second Division` / `Third Division` are EXE strings.
- `recursos\iconos\noticias\cerrarOn/Over/Off.bmp` — the `[X]` really has
  on/over/off states (the yellow X in 158 is `cerrarOver`, not our styling).
- `lefttabon/over/off.bmp` (15x57 = the division tab slots) + `esquina.bmp`
  (120x64, the scrollbar corner). Extracted from `RECURSOS.PKF` (pkf_unpack) —
  blank templates, engine draws the rotated text.
- `"calend8"` sits inside this string block — taken as the body-list face (see
  reconstruction notes).
- Original news-line templates exist in the EXE (`%s has an injury and will be
  out for the next %u weeks.`, `%s is banned for acumulation of bookings.` —
  the EXE's own typo) — available for a future league-wide news engine.

## Decoded facts (pixel-measured)

- **Overlay footprint = exactly x145..494, y27..451** (350x425, square corners,
  pixel-verified corner grids). Outside = the live hub showing through; the hub
  behind is frozen while the modal is open (155 vs 158 differ ONLY inside the
  masthead strip — even the animated crowd pixels are identical).
- Subtitle face = **proman10** (frame "MARKET" glyphs match the proman10 atlas
  bitmap-exactly; calend8/euro8/futcon8/proman8 all ruled out). Ink colour
  (42,63,170); both witnessed subtitles ink-centre on **cx 308**; cap-top y87
  (front page) / y32 (division page). Rule (166,202,240) y100/y45, x147..471.
- WEEKS plates: LAST [199,411,42,16] grey 192 + black text; ACTUAL
  [241,411,43,16] black + white text (= selected).
- Division tabs x478..494: Premier y49..104, 1st y105..159, 2nd y160..215,
  3rd y216..272; below = black backing y273..386 + v-scrollbar track y387..451.
  Tab off→on = face 192→255 (letters stay 100-grey) — witnessed on the
  Premier/1st pairs across 155/158.
- Bottom tabs y435..451: MARKET x147..212 (active = white face, open top,
  black label), INJURIES x213..282, BOOKINGS x283..361, notch x363..372,
  h-scrollbar x374..491.

## Build (`tools/re/build_news_chrome_from_frames.py` → `app/art/screens/news/`)

- `page_premier.png` / `page_division.png` — the two witnessed pages, verbatim
  350x425 cuts of 155/158.
- `x_over.png` (from 158), `tab_injuries_over.png` (from 156) — verbatim.
- `tab_premier_on/off.png`, `tab_first_on/off.png`, `tab_second/third_off.png`
  — verbatim cuts from the two pages.
- **Reconstructions (no frame exists, derivation documented):**
  - `tab_second_on.png` / `tab_third_on.png` — their off arts + the off→on
    colour map derived from the witnessed 1st-Div pair (asserted consistent).
  - `tab_injuries_on.png` / `tab_bookings_on.png` / `tab_market_off.png` —
    spliced: the witnessed MARKET-on (resp. INJURIES-off) tab structure
    stretched to the slot via a clean face column + the category's own label
    glyphs stamped from its witnessed art. Witnessed pixels only.

## Scene (`app/scenes/NewsScreen.gd`) + wiring

`Main._show_club_news()` mounts the overlay (pattern: StaffHireOverlay);
`[X]` / tap-outside → `back_pressed` → freed. `setup(news_log, week, division)`.
Live layers on the baked page: division/category tab states, subtitle re-strike
(blank-white + proman10 ink-centred cx308) only when the state deviates from the
two baked subtitles, `[X]`/INJURIES over-arts while pressed, WEEKS selection,
and the news list.

**Content mapping (real Career data only, nothing fabricated):**
- MARKET = kinds `transfer`/`contract`/`staff` · INJURIES = `injury` ·
  BOOKINGS = none (Career does not model bookings — tab stays honestly empty).
- Career news is the managed club's own → items appear under the club's own
  division tab; the other division tabs are empty (the witnessed state IS an
  empty page). `result`/`cup`/`youth` kinds stay on hub alerts, not the paper.
- WEEKS: ACTUAL = items stamped with the current week, LAST = previous week
  (semantics inferred from the labels; FinanceScreen's LAST/CURRENT WEEK
  columns are the in-game precedent).

## Verification

- `tools/re/diff_news_parity.py app/out` — **155 / 156 / 158 all 0px** over the
  full 350x425 footprint (shots: `app/tests/shot_news_parity.gd`, DISPLAY=:1).
- `app/tests/test_news_screen.gd` — 36 headless asserts (chrome json, art set,
  witnessed default state, category/week/division filtering, hit boxes, back
  signal): ALL PASS.

## Honest gaps (do NOT invent)

- **Filled body un-witnessed** — both witnessed bodies are empty. The list
  reconstruction (calend8 @15, black, x152, pitch 13, newest first) renders
  real Career items only; layout/typography of the original's news lines is
  unknown. The EXE's news templates + league-wide market/injury/booking
  generation are un-modelled (Career records own-club events only).
- LAST-selected WEEKS art un-witnessed → palette-swap reconstruction at draw
  time (plates + proman10 re-strike).
- INJURIES/BOOKINGS-active + 2nd/3rd-Div-active tab arts un-witnessed →
  builder splices (above). MARKET-off likewise.
- Masthead behaviour: witnessed only Premier-with-masthead + 1st-Div-without.
  The scene shows the masthead page iff division == Premier; whether the
  original restores the masthead on tabbing back is un-witnessed.
- Scrollbars are baked static (no witnessed thumb/scroll state).
- The counter/`WEEKS %u` string suggests deeper week navigation may exist —
  un-witnessed, not built.
