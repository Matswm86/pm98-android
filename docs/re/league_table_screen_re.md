# LEAGUE TABLES (CLASIFICACION) — screen RE

The standings screen the hub **INFORMATION → LEAGUE TABLES** entry opens. Rebuilt
FRAME-TRUE under the frame-bake precedent used by Finance / Transfer / Squad / Stadium:
the static chrome is the ORIGINAL pixels cut 1:1, and ONLY the dynamic layer (the
standings rows) is redrawn live over it.

## Binding source — WALKTHROUGH FRAME 045 (CORRECTED 2026-07-13) + LOWER DIVISIONS (2026-07-19)

> **Correction:** an earlier build of this doc claimed "no walkthrough frame exists" and
> fell back to the PC gallery capture `ma_10.png`. That was WRONG — the sub-agent's
> contact-sheet scan missed it. The LEAGUE TABLES screen **is** in our own walkthrough.
> Re-found by template-matching every frame's chrome against ma_10 (main session): three
> frames scored MAD 9.16 vs 30+ for all others.

> **Lower divisions now WITNESSED (2026-07-19).** The gaps below that said "lower
> divisions not witnessed" / "cross-division tabs are a no-op" are RESOLVED. A live wine
> campaign drove four fresh careers (Barnsley/Manchester C/Blackpool/Barnet across all
> four tiers) and clicked every division tab. Frames in
> `screenshots/wine-captures-2026-07-19-lowerdiv/`:
> - `lt_first`/`lt_second`/`lt_third` (Premier career), `w5_lt_default` (First Div career),
>   `w6_lt_second_seed`, `w7_lt_third_seed` — the FIRST/SECOND/THIRD DIVISION chromes,
>   24-row grid, PROMOTION/PLAY-OFFS/RELEGATION pennant columns, per-division selected tab.
> - `lt_wk2_premier` — the POSITION-MOVEMENT MARKER states (white UP triangle / red DOWN
>   triangle / grey no-change square). **ma_10's per-row "placeholder square" IS this
>   marker in its no-change state** — the rows carry NO crest/kit (the old kit-in-row draw
>   was an invention, now removed).
> - `lt_goalscorers_third` — GOAL SCORERS is DIVISION-SCOPED (the button on a lower
>   division's table opens THAT division's chart).
>
> Baked by `tools/re/build_leaguetable_division_chromes.py` →
> `chrome_first/second/third.png` + `marker_up/down/flat.png` (all cut 1:1, byte-exact
> vs their witness frames: MAD 0.00 on every chrome region). The screen now switches
> tables for real off `Career.standings_for(tier)` (the living pyramid, see
> `docs/re/living_league_re.md` and `Career.gd` `divisions`).
>
> **Seed order (P=0):** all four divisions list clubs in the WITNESSED pre-season order —
> last season's finish, relegated-from-above at the top, promoted-from-below at the bottom
> — NOT alphabetically. Transcribed to `data/season_seed_1997.json` by
> `tools/re/export_season_seed.py`.
>
> **Round offset:** divisions BELOW the manager's have already played round 1 by the
> manager's week-1 Saturday; divisions at/above are in sync (witnessed on all four careers).
>
> **Div-3 membership fix:** the live game fields **Macclesfield T.** in Division Three,
> NOT Hereford U. (the static EXE league table is the stale 96-97 layout). `build_db.py`
> now applies the swap; witnessed on three careers.

| source | size | state |
|---|---|---|
| **`screenshots/original-walkthrough-2026-07-02/045_154505.png`** | 641×480 PNG | **BINDING (our walkthrough).** Premier, Fri 1 Aug 1997 / date-stepper 9/8/1997, manager **MWM** @ Man Utd, **pre-season all-zeros** (P/W/D/L/GF/GA/PTS all 0, empty LEADER box) — the real season-open state. Also `046_154507`, `049_154516` (identical). |
| `~/MWM-AI/data/pm98-refs/real-gallery/ma_10.png` | 640×480 PNG | Corroborating **populated** state: Week 17, Luis Silva @ Man Utd. |
| `hires_league_table.jpg` | 474×355 JPEG | same screen, cross-check only |

Chrome of frame 045 vs ma_10 is **pixel-identical** (col-header / right-tabs / panel-frame
MAD = 0.00; only the plaque name + date differ), so the ma_10-baked `chrome.png` is a valid
1:1 for the walkthrough state too. Frame 045 witnesses the empty/seed state; ma_10 witnesses
a populated state — both now covered.

`ma_11`/`ma_12` are TRANSFER MARKET / CLUB PERSONNEL, not other-division tables, and
frames 045/046/049 do NOT click into First/Second/Third. So **no lower-division
league-table state is witnessed anywhere** — see Gaps.

## Layout (all measured off ma_10; sampling log below)

- **Barra** y0..~46: shared PMChrome header — manager+club plaque (left) + crest, centred
  title **LEAGUE TABLES**, calendar sheet (Sat 29 Nov 1997), green Premier / Week 17
  plaque + trophy. Drawn LIVE (`PMChrome.draw_header`), baked plaque blanked (see bake).
- **Panel** x8..494, y~48..437: white/cream bordered table box.
  - **Subtitle strip** y68..96: "PREMIER LEAGUE" (blue) + Date stepper: gold "Date"
    label, [◀] arrow, navy date box (green `27/11/1997`), [▶] arrow.
  - **Column header** y97..113: `POS  TEAM  P  W  D  L  GF  GA  PTS`, per-column tinted
    (P/W/GF grey, D green, L/GA/PTS red).
  - **20 rows** y114 + 16·i, 14px band + 2px white gap. Per row: zone tag (left),
    POS number, crest, team name, P/W/D/L/GF/GA cells, PTS cell.
- **Zone-tag column** x10..68: gold **EURO. CUP** pennants (rows 1-2), yellow **U.E.F.A.**
  pennants + trophy (rows 3-5), tan **RELEGATION** tags (rows 18-20). Position-fixed for
  Premier → baked.
- **LEADER card** x532..606, y95..164: "LEADER" vertical label + white card holding the
  leader's kit. **No name text** (the current app invented one — removed).
- **Division tabs** x525..624: Premier (y194, RED gradient + yellow, selected) / First
  (y224) / Second (y254) / Third (y284), dark + grey text.
- **GOAL SCORERS** (525,354,99,24) · **RETURN** (525,423,99,25) — dark buttons; RETURN has
  a gold ◀ + yellow "RETURN".

### Row palette (sampled — pixel dumps, not guessed)

| element | normal row | managed (my-club) row |
|---|---|---|
| POS+crest region bg (x73..122) | `(180,200,220)` | `(42,63,170)` |
| POS number ink | `(0,0,128)` | `(166,202,240)` |
| name plate bg (x123..270) | `(0,0,128)` navy | `(0,0,0)` black |
| name ink | `(255,255,255)` | `(255,255,255)` |
| P cell bg / ink | `(220,220,220)` / `(128,128,128)` | `(80,80,80)` / `(192,192,192)` |
| W cell bg / ink | `(180,200,220)` / `(100,120,140)` | `(80,100,120)` / `(166,202,240)` |
| D cell bg / ink | `(212,223,170)` / `(127,159,85)` | `(80,110,5)` / `(170,223,170)` |
| L cell bg / ink | `(212,191,170)` / `(170,127,85)` | `(85,0,0)` / `(255,31,0)` |
| GF cell bg / ink | `(180,200,220)` / `(100,120,140)` | `(80,100,120)` / `(166,202,240)` |
| GA cell bg / ink | `(212,191,170)` / `(170,127,85)` | `(170,127,85)` / `(212,191,170)` |
| PTS cell bg / ink | `(72,30,2)` brown / `(255,223,0)` gold | `(150,0,0)` red / `(255,255,255)` white |
| column separators | `(0,0,0)` 1px | `(0,0,0)` 1px |
| date value ink | `(180,210,50)` yellow-green on `(0,0,50)` navy | — |

Column x-anchors (cell `[left, width]`): P `[271,23]` W `[296,23]` D `[321,23]`
L `[346,23]` GF `[371,34]` GA `[407,34]` PTS `[443,38]`. Row-1 top y114 (exact).
**Rows are uniform navy — there is NO light/dark alternation** (verified across all 20).

## Adversarial divergence pass — OLD app vs ma_10

Render of the pre-rebuild `LeagueTableScreen.gd` (all-procedural, guessed `Color()`
consts) vs the binding frame:

| element | OLD app | ma_10 (truth) | verdict |
|---|---|---|---|
| background | dark navy `management_bg` | light blue-grey **marble** | WRONG — baked marble now |
| panel/chrome | procedural bevels, guessed hex | frame pixels | WRONG — baked now |
| subtitle | "PREMIER LEAGUE", approx blue/pos | frame | close, baked now |
| Date strip | blue box, redrawn value | gold "Date" + navy box, green value | WRONG styling — baked frame + green value |
| column headers | all one blue | **per-column tint** (D green, L/GA/PTS red) | WRONG — baked now |
| row background | **alternating** light/dark navy | **uniform** navy | INVENTED alternation — removed |
| my-club highlight | faint 10% white overlay on my row | full **black plate + dark cells + red PTS + white PTS** | WRONG — real re-skin now |
| stat cells | **all tan** (`C_CELL`) for P..GA | **per-column** grey/blue/green/tan tints | INVENTED — per-column now |
| PTS cell | brown-red guess | brown+gold (normal) / red+white (mine) | WRONG — sampled now |
| POS number | euro slots forced **gold** | navy on light-blue (all) | INVENTED gold — removed |
| zone tags | flat colour rects, guessed hex, no icon | **gold/yellow/tan pennants + trophy icons** | WRONG — baked pennants now |
| LEADER card | kit **+ invented name text** | kit **only** | INVENTED name — removed |
| division tabs | blue bevels, "Premier" dark-red | RED-gradient selected / dark unselected | WRONG — baked now |
| GOAL SCORERS / RETURN | blue / dark-red, no arrow | dark buttons, RETURN has gold ◀ | WRONG — baked now |
| fonts | proman12 @13 guessed sizes | frame | now baked chrome + proman rasters for rows |

## Rebuild

- **Bake** `tools/re/build_leaguetable_chrome_from_frames.py` → `app/art/screens/leaguetable/chrome.png`
  + `leaguetable_chrome.json`. Cuts ma_10 1:1, blanks ONLY: the standings row band
  (x71..487, y114..431 → white), the LEADER kit (→ white), the date-box digits (→ navy),
  and the manager plaque (→ marble, since the live barra overdraws it). Everything else —
  marble bg, panel, subtitle, Date frame, column headers, zone-tag pennants, LEADER frame,
  tabs, GOAL SCORERS, RETURN — is frozen ma_10 pixels.
- **Scene** `app/scenes/LeagueTableScreen.gd`: blits chrome 1:1, overdraws `PMChrome.draw_header`
  live (TransferScreen pattern), then redraws the 20 rows + leader kit + date value from
  the standings array, using the SAMPLED palette above. `setup()` signature unchanged, so
  Main's wiring is untouched.

### Render parity (leaguetable_demo.png vs ma_10, matched demo table)

Row-1 name-plate top: **y114-119 exact match**. Stat value x-centroids (row 2, identical
data): P 282.3 vs 282.8 · W 309.0 vs 307.0 · D 331.0 vs 330.8 · L 353.0 vs 356.5 ·
GF 387.0 vs 386.5 · GA 422.5 vs 423.5 · PTS 460.7 vs 464.2 — all within 0.2-3.5px, values
land inside their baked cells with no overlap. Baked bands (strip / colhdr) diff <4% of
pixels >60 (residual = the redrawn green date value 29 vs frozen 27).

## Real vs seed vs gap

- **REAL** — the standings rows. `Career.standings()` returns the live table
  (`Career._init_table` seeds every league club at P/W/D/L/GF/GA/Pts = 0 at season start;
  `advance_week` accumulates real simulated-match stats). Pre-season (week 0) it is the
  HONEST all-zero seed (real club names, zeroed stats, name-sorted), NOT an invented table.
  Keys (`id,name,P,W,D,L,GF,GA,Pts`) match what the scene reads. Leader kit = `standings[0]`
  (real). Manager/club/season/week in the barra = live `Career` fields.
- **SEED** — the demo render/test uses a fixed 20-club Premier table mirroring ma_10 so it
  can be overlaid; the app itself never uses that fixture.
- **SEED** — the demo render/test uses a fixed 20-club Premier table mirroring ma_10 so it
  can be overlaid; the app itself never uses that fixture.
- **RESOLVED (2026-07-19)** — the following were flagged gaps, now witnessed + built:
  1. ~~Lower divisions not witnessed~~ → all four division chromes baked byte-exact from
     the live wine campaign (`chrome_first/second/third.png`); a non-Premier career now
     renders its own division skin.
  2. ~~Cross-division tabs are a no-op~~ → the tabs are LIVE, backed by the living pyramid
     (`Career.standings_for(tier)` + `prev_positions_for`). Tapping First/Second/Third
     shows that division's real simulated table + movement markers.
  3. **Row marker** — the small box beside POS is the POSITION-MOVEMENT marker (grey
     square / white up / red down vs the previous revision), NOT a crest. The old
     kit-in-row draw is removed.
  4. **Leader kit** shows only once the leader has a played game (empty card at P=0,
     witnessed).
- **GAP / honest placeholder (remaining)**:
  1. **Date-box value semantics.** The box shows the LAST TABLE-REVISION date; witnessed
     `9/8/1997` at week 1, `16/8/1997` at week 2 (w5 career), and ma_10's `27/11` vs
     calendar Sat `29/11`. Our weekly model revises on the manager's Saturday, so the
     scene draws the calendar-sheet date (`PMChrome.date_parts`) — a small approximation
     of the exact revision-date offset, un-RE'd.
  2. **Playoff bracket** (rollover) uses the real 1997-98 English one-leg semi/final
     format; the in-game bracket UI is un-witnessed (FLAGGED in `Career._playoff_winner`).
  3. **Season 2+ objectives/round-offset** are the app's consistent extension of the
     witnessed season-1 rules (later boards un-witnessed).

## Wiring (Main.gd)

`_show_league_table_screen()` → `_open_table(_career.standings(), _career.club_name,
_career.season, "Week %d", _career.tier, _career.club_id, _career.manager_name)`.
`_open_table` mounts the screen, calls `setup(...)`, and — for a career overlay — calls
`scr.set_pyramid(...)` so the division tabs pull `Career.standings_for(tier)` /
`prev_positions_for(tier)`. Signals: `back_pressed` → dismiss; `club_selected(id)` → that
club's DATA BASE squad; `scorers_pressed` → the SELECTED division's GOAL SCORERS chart
(`_show_goal_scorers_screen(scr.selected_tier())`, division-scoped per witness).

## Verification

- `app/tests/test_pyramid.gd` — the living pyramid: 4-division build, witnessed seed
  orders + head-start offset, per-division scorers, weekly movement, save/load round-trip,
  `ensure_divisions` fast-forward for legacy saves, and a full-season rollover
  (promotions/relegations/playoffs → 20/24/24/24 memberships, manager follows finish).
  **43 asserts, ALL PASS** headless (~20s incl. a full 4-division season).
- `app/tests/test_league_screen.gd` — asserts all 4 chromes + marker sprites + fonts load,
  both row grids (20/24), RETURN anchor, my_id wired, kit load, and the live division-tab
  switching (inert without pyramid data, switches with it). **ALL PASS** headless.
- `app/tests/shot_league_divisions.gd` — real-render parity of the witnessed w5 First-Div
  seed state: chrome regions **MAD 0.00 in the bake** vs `w5_lt_default.png`; render-side
  delta is the Mesa software-GL sRGB edge shift (+1 RGB, dy=0), not positional.
