# THE CALENDAR — fixtures screen RE (walkthrough run-1 050-055)

The screen the hub **FIXTURES** icon opens in the original PM98. The audit
(`APP_VS_SPEC_AUDIT.md` §B1) marked the old app UI (BrowseScreen "COMPETITIONS"
chooser + "SEASON FIXTURES" list, `Main.gd` `_show_competitions`/`_show_calendar`)
a **SUBSTITUTE** for the real `RECURSOS\ICONOS\EMPAREJAMIENTOS` screen. The
walkthrough proves that icon opens the screen titled **THE CALENDAR** (frame 050
hub → 051), so this is what is rebuilt here.

Rebuilt under the entry-flow doctrine to **pixel parity 0px** on the binding
frame: chrome = the real frame baked **verbatim** (`tools/re/build_fixtures_chrome_from_frames.py`
→ `app/art/screens/fixtures/`), dynamic layer = `app/scenes/FixturesScreen.gd`
(`class_name FixturesScreen`).

## Binding frames (run 1, 15:45)

| frame | state |
|---|---|
| `050_154518.png` | MANAGER MENU hub. INFORMATION quadrant: RESULTS / LEAGUE TABLES / **FIXTURES** (the "25 SEPT" calendar-page icon). The click target. |
| `051_154519.png` | **THE CALENDAR — BINDING.** Fresh Man Utd. career, Friday 1 Aug 1997. The chrome verbatim. |
| `052/053/054_154521..25` | Same screen; the ONLY diff vs 051 is the RETURN button's animated ball/arrow icon (asserted in the bake: every changed pixel is inside x520..628 y433..463). |
| `055_154527.png` | back on the hub — RETURN returns to MANAGER MENU. |

The whole screen is one engine-composited still. No other calendar state (other
club, other month paged, played results, an empty calendar) appears anywhere in
the 639-frame walkthrough — so frame 051 is the ONLY witnessed state (see Gaps).

## Layout (frame-measured, all asserted in the bake)

- **Header band** y0..61: shared barra. Left plaque MWM / Manchester Utd.;
  centre title sprite **THE CALENDAR** (glyph bbox x219..376, cut at x217 y22);
  right date box Friday / 1 / August / 1997; status plaques Preseason /
  Preparation. Baked; recomposed only for a divergent career (below).
- **Two month sheets**, spiral-bound white bodies at x80..249 (left) and
  x280..449 (right), y84..206. Baked red month title (rows 86..96), baked
  `S M T W T F S` weekday header (rows 99..110, byte-identical between the two
  sheets — asserted), and the day-cell grid: first cell box at sheet-x+16, y114;
  pitch 20×18; box 17×15 incl. 1px black border. A day whose slot lands on grid
  **row ≥ 5 overflows** its own sheet and appears as the NEXT sheet's leading
  row-0 cell (witnessed: 31 AUG missing from AUGUST, present as SEPTEMBER's first
  cell). The **today ring** (1 AUG) is a 2px red frame + 1px white ring, bbox
  (194,112)-(214,130).
- **Page arrows**: left (41,100,29,94), right (461,100,29,93).
- **Competition legend** (right column, chip x538..551, 10 rows top→bottom):
  LEAGUE · F.A. CUP · EUROPEAN LEAGUE · CUP WINNER'S · U.E.F.A. · CHARITY SHIELD
  · EURO. SUPERCUP · INTERCONTINENTAL · PRESEASON · COCA-COLA CUP. Chip fills
  frame-sampled (see Colours).
- **TODAY band** (left rail label): today's fixture. Name bar border box
  (99,232)-(438,253), competition-colour fill, 30×20 country flags (BANDERAS) at
  the ends. Stage-bars box (99,258)-(439,290): two comp-shaded rows (comp name /
  round) with 28×31 ball cells at both ends (identical L/R — asserted). Larger
  kit sprites in the outer slots.
- **NEXT band**: next four fixtures, row interior tops y317 + 38i. Per row:
  ball cell x44..73 (present for most comps; the CHARITY row is a plain black
  cell — witnessed), home-kit plate x83..115, name bar x115..384 (comp-fill),
  two comp/round bars split at x249, away-kit plate x385..415, date panel
  x422..494 (comp-dark fill; white weekday + white day + comp-tinted month).
- **Buttons**: RESULTS (510,280,126,28), LEAGUE TABLES (510,313,126,28),
  RETURN (519,432,110,32).

## Colours (frame-sampled)

- Month title / today ring red **(210,0,0)**.
- Legend chips: league (166,202,240) · fa_cup (255,255,170) · euro_league
  (170,255,170) · cup_winners (255,191,170) · uefa (255,204,255) · charity
  (192,192,192) · supercup (192,192,192) · intercont (160,160,164) · preseason
  (212,191,0) · cocacola (160,160,200). Day-cell fills == the legend chip of the
  cell's competition (verified on the AUG 4 gold / AUG 3 grey / AUG 10 blue /
  SEP 17 green cells).
- **Witnessed band shades** (frame-sampled, the only two competitions that
  actually appear in the TODAY/NEXT bands on 051):
  - preseason: bar1 (212,127,0), bar2 (212,159,0), date-bg (102,50,12), inks
    (102,50,12)/(135,73,22), TODAY name ink dark-olive (10,15,0).
  - charity: bars/date-bg (80,80,80), black inks.
  - Every OTHER competition's band shades are **derived procedurally** from its
    legend colour (`_shades()`: cell.darkened(0.35/0.2/0.62)) — a documented
    approximation, never witnessed in a band.

## Rebuild design — baked witnessed state, redrawn divergence

Following `PreseasonScreen` / `build_entry_chrome_from_frames.py`: the ONE
witnessed state renders as the frame's OWN pixels.

- `chrome.png` = frame 051 **verbatim** (header, sheets, month titles, day grid,
  TODAY/NEXT interiors, legend, buttons — all baked bitmap art).
- `FixturesScreen.setup()` runs `_detect_baseline()`: true iff (today = Fri 1 Aug
  1997) ∧ (15 entries) ∧ (1 AUG = Juventus preseason) ∧ the witnessed comp cells
  (3 AUG charity, 4/6/8 AUG preseason, 10 AUG league, 17 SEP euro-league). A
  genuine fresh Man Utd. career on the opening day legitimately resolves to it.
- **Baseline view** (baseline ∧ showing the baked AUG/SEP sheets): `_draw()` shows
  the baked chrome UNTOUCHED — no app-font text, no header recompose. Frame-true.
- **Divergent** (any other club / date / fixture set, or the user has paged off
  AUGUST 1997): `_draw()` repaints the header via `PMChrome.draw_match_header` +
  re-blits the title sprite, `_clear_body()` whites the baked text regions (the
  bake's `clear_rects`), then redraws the sheets / TODAY / NEXT with the app
  fonts. Verified to render cleanly (Arsenal, Jan 1998: correct sheets, F.A. Cup
  yellow, dates, nano-kit fallbacks) — an HONEST, un-witnessed approximation.

Why baked, not font-redrawn: the original CALENDAR bitmap font is **not
pixel-identified**. A full app-font redraw of the witnessed state (kkita for the
red title/bands, PROMAN8 for digits) drifted **8.9% of the frame** (mean abs diff
25) — the app glyphs are thinner/narrower than the frame's bold-condensed font,
so centred strings land at the wrong x. Candidate extracted fonts (calend12/
calend8/futcon8/euro8) were probed against the frame's "AUGUST 1997" ink (95px
wide) and none matched (best ~50px wide) — so the font is left as an open gap and
the witnessed pixels are baked instead.

## Parity

`app/tests/shot_fixtures_parity.gd` renders the frame-051 baseline;
`tools/re/diff_fixtures_parity.py` diffs the full frame:

```
raw diff (>12/px):        0 px  (0.0000%)
after exclusions:         0 px  (0.0000%)   thresh 0.40%
mean abs diff:       0.000
```

**0px, byte-exact** (same standard as pretemp_013). The differ still lists the
RETURN animated-icon rect as an exclusion (a stability guard — it animates across
052-054; 051 bakes one phase); it excludes 0 differing pixels here.
Rendered under `--rendering-driver opengl3` on the local X display (headless has
no `frame_post_draw`; the shot self-skips there).

## Honest gaps (never filled with invented content)

1. **CALENDAR bitmap font not identified** → the divergent redraw uses stand-in
   app fonts (kkita/PROMAN8). Cannot be pixel-measured (no divergent frame).
2. **Only frame 051's state is witnessed.** Band shades for every competition
   other than preseason/charity, empty TODAY/NEXT interiors, the day-cell
   appearance of un-walked competitions, and the page-arrow paging **semantics**
   (the app clamps to the fixture-month range — a reasonable default, not
   witnessed) are all un-witnessed.
3. **Weekday abbreviations**: only Sunday / Monday / **Weds** / Friday are
   witnessed (the NEXT date column, 051). Tuesday/Thursday/Saturday use full
   names as a placeholder.
4. **Career → calendar-date mapping: per-round DAY is NOT source-provable (WIRED with
   an explicit, flagged inference).** The real 1997-98 fixture SCHEDULE + per-round
   calendar dates live in the engine container `PCF5DAT.PKF`, which is **NOT enumerable**
   (`SOURCE_INVENTORY.md` §5 GAP#1); the app's own schedule is `SeasonSim`-generated, not
   the original's. So the exact calendar DAY of each round is **not derivable from source
   and is NOT invented into the Career model** (`season_fixtures()` stays week-indexed,
   unchanged). The live wiring (`Main._calendar_entries()`) instead:
   - places **preseason friendlies** on their **real witnessed August dates** (1/4/6/8 AUG
     1997, assigned in `_begin_career` from the walkthrough) — source-true on the AUG sheet;
   - places **league rounds** week-ordered by the same inferred weekly cadence the RESULTS
     screen already ships (`ResultsScreen._date_for`: season-start **9 AUG** + round×7 days).
     The **WEEK STRUCTURE** (one round per week) is the game's own cadence; the **exact
     calendar-day placement** of each league round is the **honest gap** (e.g. the witnessed
     CALENDAR shows Man Utd's round-1 on 10 AUG, one day after the inferred 9 AUG anchor).
   - Cups / Charity Shield / Europe carry no derivable date yet → **omitted** (gap).
   Because a generic live career won't reproduce the exact frame-051 witnessed set (Juventus
   preseason + Charity 3 AUG + Euro 17 SEP), `_detect_baseline()` resolves false for live
   play → the **divergent app-font redraw** runs (the documented, un-witnessed approximation).
   The baked frame-051 baseline stays reachable only by `test_fixtures_screen` / the parity shot.

## Wiring (APPLIED 2026-07-13)

The hub FIXTURES action `Main._menu_action "fixtures"` now runs
`_show_fixtures_screen()` (was `_show_competitions()` → the rejected "COMPETITIONS"
BrowseScreen SUBSTITUTE). It instantiates `FixturesScreen`, `setup(header, entries,
today)`, and connects `back_pressed` (→ free, re-raise hub), `results_pressed` (→
`_show_results_screen()` mounted OVER the calendar so its RETURN re-raises the
calendar), `tables_pressed` (→ `_show_league_table_screen()`). `header` = a
manager-mode `_match_header()` (frame 051 shows the manager plaques). `entries` =
`_calendar_entries()`; `today` = a pending friendly's real date, else the current
league round's inferred date. Each entry is `{y,m,d, comp, comp_name, round,
home_id, away_id, home, away, home_flag, away_flag}` (flags from the club's real
`countryCode`). **Per-entry date assignment is NOT built into `season_fixtures()`**
(it stays week-indexed) — dates are assigned in `_calendar_entries()` under the
source-doctrine trace in gap #4 (preseason = witnessed dates; league = flagged
weekly-cadence inference; cups/Europe omitted).

`_show_competitions` / `_show_calendar` / `_open_competition` are left in the file
(still used by the screenshot-batch routine) but are no longer the hub FIXTURES path.
**Known follow-up (not this pass):** the cup/Charity/Europe CupScreens were reachable
only through the old `_show_competitions` chooser; THE CALENDAR (source-true) has no
cups button (un-witnessed), so those screens currently have no live hub entry — a
separate wiring decision, flagged here so it is not silently lost.
