# RESULTS / MENUPRINCIPAL "results" (MARCA) — frame RE (walkthrough run-1 037→038)

The MANAGER MENU hub tile **RESULTS** (top-left INFORMATION quadrant) opens the
matches-on-date view with the competition rail. Rebuilt under the entry-flow
doctrine: static chrome = the real frame baked verbatim
(`tools/re/build_results_chrome_from_frames.py` → `app/art/screens/results/`),
dynamic layer = `app/scenes/ResultsScreen.gd`. Closes the APP_VS_SPEC_AUDIT §B1
`results (MARCA)` **SUBSTITUTE** verdict (the invented BrowseScreen W/D/L text
list at `Main.gd:2528-2547` is what the user rejected).

Parity: **static chrome = 0px vs frame 038**; every non-zero pixel lives in the
dynamic redraw layer (career-driven rows, header text, date). See §Parity.

## Binding frames (run 1, `screenshots/original-walkthrough-2026-07-02/`)

Run-1 timestamps 15:42–15:52. The hub was clicked into RESULTS at 15:44:52.

| frame | ts | state | use |
|---|---|---|---|
| `037_154450.png` | 15:44:50 | MANAGER MENU hub (quadrant screen; RESULTS tile top-left) | proves the 037→038 transition — the hub tap that opens RESULTS |
| **`038_154452.png`** | 15:44:52 | **RESULTS, resting state** | **THE binding frame** — sole pixel source for all chrome |
| `039_154454.png` | 15:44:54 | RESULTS, Intercont. rail chip glow tick | animation-only, not used |
| `040`–`042_1544xx` | 15:44:56–59 | RESULTS, RETURN ball-roll hover | animation-only, not used |
| `043_154501.png` | 15:45:01 | RESULTS, RETURN pressed | animation-only, not used |

039–043 differ from 038 **only** in the right-rail hover / RETURN press
animation, so 038 (resting) is the single witness for every static pixel.

Frame 038 contents (verbatim, all baked into `chrome.png`): the shared barra with
the baked **RESULTS** title sprite; **PREMIER LEAGUE** competition band + trophy;
the **MATCHES ON** band; 9 fixture-row plates (Barnsley v West Ham Utd … Wimbledon
v Liverpool — the original 97-98 matchday-1 pairings, Man Utd's 10th game absent →
it falls on the next date); the date inset "9/8/1997"; the competition rail (F.A.
Cup, Coca-Cola Cup, Charity Shield, Euro. League, Cup Winner's, U.E.F.A., Euro.
Superc., Intercont., 1st/2nd/3rd Play-Offs); the four division chips (Premier /
First / Second / Third Division) + RETURN.

## Source-doctrine trace

| element | source | status |
|---|---|---|
| all background art, trophy, bands, rail chips, division chips, RETURN | frame 038 baked into `chrome.png` (rows + date inset cleared to their sampled plate colours) | **frame-true, 0px** |
| baked **RESULTS** title sprite, **PREMIER LEAGUE** caps | frame 038 pixels (outside every patch / stay baked) | **frame-true, 0px** |
| textless header patches (names/kit/cal/status) | cut from `app/art/screens/header/band.png` (the proven shared barra bake) | **frame-true source** |
| header text (manager plates, calendar, status) | PMChrome HDR_* grammar, same recomposition the header bake proved | dynamic redraw |
| fixture rows (RIDIESC kits + PROMAN10 names) | `PMChrome.ridi_kit()` + `proman10.fnt`, career data | dynamic redraw |
| date digits "d/m/yyyy" | `date_digits.png` — `1789/` **exact frame cuts**, `023456` fitted-fill synthesis | mixed (see gaps) |
| non-Premier title caps | `title_caps.png` PROMAN18 fitted-fill synthesis | approximation (see gaps) |
| arrow plates | left-disabled + right-enabled are **frame cuts**; their mirrors synthesize the un-walked left-enabled / right-disabled states | mixed (see gaps) |

Ultimate raw-art fallback (unused here — nothing needed decoding beyond the frame):
RESULTS/MARCA art lives in `IMG.PKF` (`docs/re/pkf_format.md`); it has no `iconos`
folder (APP_VS_SPEC_AUDIT §B1). Every pixel above traces to frame 038 or the
band.png bake, so no PKF decode was required.

## Geometry (all measured on frame 038)

| region | value | note |
|---|---|---|
| design space | 640×480, letterboxed by `minf(w/640,h/480)` | same scale/origin/tap as PreseasonScreen |
| fixture rows | `ROW_Y0=154`, `ROW_PITCH=23`, `N_ROWS=9`, `ROW_H=22` | 9 plates = frame truth |
| home kit cell | x span `16–44` (`KIT_HOME_X=21` draw origin) | left edge |
| home name cell | x `45–213`, right-aligned pen END `x=207` | PROMAN10 |
| home score cell | x `214–247`, centre `x≈230` | |
| away score cell | x `249–282`, centre `x≈265` | |
| away name cell | x `283–455`, left pen `x=288` | PROMAN10 |
| away kit cell | x `456–484` (`KIT_AWAY_X=461` draw origin) | right edge |
| name line-box top | `row_top + 6` | |
| black border columns | `14,15,44,213,247,248,282,455,484,485` | asserted black in build |
| date inset | clear rect `(342,128)–(456,151)`; digit cells `y=129 h=20`; pen origin `x=352` for "9/8/1997"; centre `cx=396` | |
| PREMIER LEAGUE band patch | `(104,86)–(422,109)`; caps line-box top `y=88`; GDI span `S=511` (reproduces witness `x=143`) | |
| prev / next arrows | `R_PREV=(308,127,27,25)`, `R_NEXT=(459,127,27,25)`; inner grid squares 19×17 at `(312,131)`/`(463,131)` | |
| RETURN hit-rect | `(504,433,116,29)` | |

## Colors sampled (mode of the cleared cells, frame 038)

| plate | light row | washed row |
|---|---|---|
| name-cell bg | `(200,220,240)` | `(160,180,200)` |
| score-cell bg | `(120,140,160)` | `(100,120,140)` |
| kit-cell bg | `(180,200,220)` | `(140,160,180)` |
| row name ink (PROMAN10) | `(100,120,140)` | `(120,140,160)` |

Fitted PM98 gradient-text fill (single-witness, measured on 038):
- **date** — bright `(180,210,50)` / mid `(160,190,40)` / dim `(127,159,85)` / halo `(20,20,60)` / bg `(0,0,50)`
- **title** — bright `(42,95,170)` / mid `(75,109,172)` / dim `(42,95,170)` / halo `(240,240,240)` / bg white

Fill rule: glyph interior → bright; the 4-edge pixels → `(x+y)` odd = mid, even =
dim; the 1px 4-ring around → halo. Phase locked to absolute screen `(x+y)` parity
so the checker lands where the original renderer put it.

## Dynamic layer (`ResultsScreen.gd`)

- **header** — band.png patches at source positions + PMChrome HDR grammar (manager
  plates, calendar, status). `header` uses the shared `draw_match_header` keys.
- **rows** — for each of ≤9 fixtures: home/away RIDIESC kit + right/left-aligned
  PROMAN10 club name in the alternating row ink. Manager-only persisted score
  (see gaps) drawn centred in the score cells; every AI fixture stays empty.
- **date** — the round's date rendered from `date_digits.png` cells, parity-picked.
- **title** — only repainted when the career league ≠ baked PREMIER LEAGUE:
  white patch + fitted-fill PROMAN18 caps.
- **arrows** — prev enabled only when `_idx>0`, next disabled on the last page.
- **paging** — every round splits into pages of ≤9 rows (the table has exactly 9
  plates); page `p` renders on the round date + `p` days, mirroring the original's
  own within-matchday date split (matchday 1 = 9 games 9/8, Man Utd's on 10/8).

Data: `fixtures = Career.fixtures` (`Array[round]`, round = `Array[[home_id,away_id]]`);
`results = Career.results` (manager-only `[{week,opp_id,home,hg,ag}]`); `club_names`
maps id → display name. Fresh career = no fixtures → chrome only, no crash.

## Honest gaps (never captured; NOT invented)

1. **Score digits on this screen** — no walkthrough frame shows a *played* result on
   the RESULTS table (frame 038 is fresh, all cells blank). Manager scores render as
   PROMAN10 centred in the frame's score cells: the cell geometry is frame-true, the
   digit glyph rendering is the **only** unwitnessed part. AI fixtures have no
   persisted score in Career, so they stay honestly empty.
2. **Date digits `0 2 3 4 5 6`** — the witness date "9/8/1997" only exposes `1 7 8 9 /`
   (exact frame cuts, true fill). The other six digits are **fitted-fill synthesis**;
   build-time residual vs the witness cells = **480 of 1520 px**. Any date past
   round 0 (page-2 `10/8`, round `16/8`, …) uses at least one synthesized digit AND
   an inferred date — see (5).
3. **Non-Premier competition title** — only PREMIER LEAGUE was captured. Any other
   league repaints the white band + PROMAN18 fitted-fill caps; build-time residual
   vs the captured "PREMIER LEAGUE" witness = **1118 of 2700 px**. Documented
   approximation, flagged in-scene.
4. **Un-walked arrow states** — only left-disabled and right-enabled were captured.
   Left-enabled / right-disabled are horizontal mirrors of the opposite captured
   plate (symmetric grid squares), not independent witnesses.
5. **Round→date mapping for rounds > 0 / page > 0** — only round-0 date (9/8/1997)
   is frame-verified. The season-start + `r` weeks + `day_off` days model (→ round 1
   = 16/8, overflow page = 10/8) is a **plausible inference**, NOT captured. The
   split-into-pages date behaviour reproduces the frame's own 9-row/next-date split
   but the specific downstream dates are un-witnessed.
6. **Competition rail + division chips are not career-wired** — they keep their baked
   frame-038 states (F.A. Cup … 3rd Play-Offs; Premier League highlighted). Their
   career-driven states (which cups the club is in, which division) were never
   captured, so they are chrome-only, not interactive.

## Parity

**Static chrome vs frame 038 = 0px.** Headless GL render (real renderer, DISPLAY=:1,
opengl3) of the frame-038 state, diffed by ROI (`|Δ|>12` per pixel):

| ROI | px | % of ROI | source |
|---|---|---|---|
| static chrome (all dynamic zones masked) | **0** | 0.00% | frame-true |
| title band | 0 | 0.00% | baked |
| PREMIER LEAGUE caps | 0 | 0.00% | baked |
| competition rail | 0 | 0.00% | baked |
| division chips + RETURN | 0 | 0.00% | baked |
| header (y<62) | 1114 | 2.81% | dynamic text redraw (PMChrome AA vs frame) |
| fixture rows | 1584 | 1.57% | app RIDIESC kits + PROMAN10 names (career, not frame's baked pixels) |
| date inset | 69 | 2.34% | fitted-fill date model residual |
| MATCHES band + arrows | 69 | 0.32% | (overlaps the date inset) |
| **TOTAL** | **2767** | **0.90%** of 307200 | |

Cross-check: the render's row diff (1584px) is **identical** to the build script's
independent numpy recomposition of the same state (1584px) — the Godot scene draws
pixel-for-pixel what the deterministic model predicts. All non-zero diff is the
intended dynamic layer (career-driven rows + live header text + the documented date
model); no static pixel deviates from the original.

## Rebuild / test

```bash
python3 tools/re/build_results_chrome_from_frames.py     # deterministic, rerunnable
~/godot462 --headless --path app --import
~/godot462 --headless --path app -s tests/test_results_screen.gd     # 53 assertions, ALL PASS
# real-renderer parity shot:
DISPLAY=:1 PM98_SHOT_DIR=<dir> ~/godot462 --rendering-driver opengl3 \
    --path app -s tests/test_results_screen.gd     # writes results_038.png
```

## Wiring (APPLIED 2026-07-13)

Hub tap dispatch routes `"results" → _show_results_screen()`, whose body now mounts
this `ResultsScreen` (the rejected BrowseScreen W/D/L list is gone). It is also opened
by THE CALENDAR's RESULTS button (mounted OVER the calendar; its RETURN re-raises the
calendar). The applied body is exactly: instantiate `ResultsScreen`, then

```gdscript
func _show_results_screen() -> void:
    var scr: ResultsScreen = load("res://scenes/ResultsScreen.gd").new()
    scr.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(scr)
    scr.setup(_match_header(),                      # Main.gd:1470, already used by other screens
        _career.league_name, _career.season,
        _career.fixtures, _career.results,
        _career.week, _career.club_id, _career.club_names)
    scr.back_pressed.connect(func() -> void:
        AudioManager.ui_select(); scr.queue_free())
```

`setup()` signature: `(header:Dictionary, league_name:String, season:String,
fixtures:Array, results:Array, week:int, club_id:int, club_names:Dictionary)`.
`back_pressed` is the RETURN signal (dismiss + re-raise the hub, same contract as
`_dismiss_career_browse`). Fresh career (empty `fixtures`) renders chrome only.
