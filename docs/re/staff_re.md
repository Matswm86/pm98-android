# CLUB PERSONNEL (EMPLEADOS / backroom staff) — reverse-engineering notes

The Main Menu's **EMPLE** (empleados) icon opens the original's **CLUB PERSONNEL** screen.
Rebuilt FRAME-TRUE 2026-07-13 from the live walkthrough, replacing the earlier
strings-only substitute (audit `APP_VS_SPEC_AUDIT.md` B1: *"strings-only, NO reversed
layout"* + an invented TRAINING browse on the same icon). TRAINING (ENTRENAMIENTO) is a
SEPARATE original screen — the rebuilt CLUB PERSONNEL no longer depends on the invented
browse and has NO training button.

## Binding frames (owned game frames, run1 15:47)
`screenshots/original-walkthrough-2026-07-02/`
- **121_154736.png** — the clean CLUB PERSONNEL screen (Man Utd / MWM, 1 Aug 1997). The
  build's binding frame.
- **113..120** — the **hire overlay** (per role category). 113 = ASS. MANAGER, 115 = YOUTH
  MANAGER (vacant), 117 = YOUTH TEAM SCOUT, etc.

## The real layout (witnessed, frame 121)
Header barra: club/manager plaque + crest, **CLUB PERSONNEL** title, calendar sheet
(Friday 1 August 1997), Preseason / Preparation band — the shared PMChrome header.

Body, on a dark panel:
- **TRAINING STAFF** section header, then a **2-col x 3-row grid** of skill trainers. Each
  cell = a blue skill label over a colour name-bar (white staff name at left + gold
  half-star rating at right) with a red **WAGE** / black **£amount** block:
  - left col:  HANDLING · DRIBBLING · TACKLING
  - right col: PASSING · HEADING · SHOOTING
- Seven **role cards** below, laid out **MIRRORED** left/right with the role's VGA portrait
  on the OUTER edge (white pixels: physio in a lab coat, groundsman in green, etc.):
  - left col (name-bar left / WAGE right):  PHYSIOTHERAPIST · ASSISTANT MANAGER ·
    YOUTH TEAM MANAGER · GROUNDSMAN
  - right col (WAGE left / name-bar right):  PSYCHOLOGIST · SCOUT · YOUTH TEAM SCOUT
- Bottom-centre **SIGN** (money icon) + **SACK** buttons; bottom-right **RETURN** (globe).

Ratings are **0..5 in half-star steps** (a gold half-star = .5). Each role's name-bar has a
themed colour: training bars run orange→red, PHYSIO/PSYCH lavender, ASS.MANAGER/SCOUT/
YOUTH MANAGER steel-blue, YOUTH SCOUT mauve, GROUNDSMAN green.

Witnessed reference staff (frame 121, Man Utd — transcribed pixel-by-pixel, SOURCE not
invented; the parity oracle + default fixture, in `personnel_chrome.json` REF_STAFF):
HANDLING A. Padmore ★★★ £17,000 · PASSING D. Gledhill ★★★★½ £34,000 · DRIBBLING S. Merrick
★★★★★ £47,000 · HEADING A. Mitchell ★★★ £16,000 · TACKLING T. O'brian ★★★½ £21,000 ·
SHOOTING T. Alan ★★★★½ £33,000 · PHYSIOTHERAPIST P. Gelbier ★★★★★ £45,000 · PSYCHOLOGIST
J. Bodin ★★★★½ £15,000 · ASSISTANT MANAGER A. Leigh ★★★★ £16,000 · SCOUT K. Hatch ★★★★½
£45,000 · YOUTH TEAM MANAGER D. Read ★★★½ £21,000 · YOUTH TEAM SCOUT W. Sugar ★★★★★
£36,000 · GROUNDSMAN G. Debnam ★★★★½ £4,000.
**CORRECTED 2026-07-18:** O'brian is **★★★½** (3 gold + a half, re-verified by zoom on
frames 103, 105 AND 121 — an earlier read said ★★★★½) and the b is lowercase (the
APELLIDO.30 row is `O'brian`); REF_STAFF + `personnel_chrome.json` fixed.

## The hire overlay (frames 113-120) — witnessed, NOT yet built
Tapping a role opens a dialog: a purple title strip, a **CURRENT <ROLE>** box (holder name +
stars + WAGE, empty when vacant), a **<ROLE>s AVAILABLE** list where each candidate has a
green **SIGN** button + name + stars + WAGE, and a right-hand **category rail** —
TRAINERS · PHYSIO. · PSYCHOLOGIST · ASS. MANAGER · SCOUT · YOUTH MAN. · YOUTH SCOUT ·
GROUNDSMAN + **OK** (TRAINERS expands to the six skill sub-trainers). The rebuilt screen
emits `role_selected(role)` on a card tap; the overlay panel itself is the next build step.

## How it is built (PreseasonScreen / Directiva / Finance frame-bake precedent)
`tools/re/build_staff_chrome_from_frames.py` cuts frame 121's pixels 1:1 into
`app/art/screens/staff/personnel_body.png` (640x422, the body below the barra, drawn 1:1 at
y58) and writes `personnel_chrome.json`: the 13 MEASURED slot rects (cross-checked by a
structural colour-bar detector), per-slot bar colour + name/stars/wage anchors, the
SIGN/SACK/RETURN button rects, sampled inks, and REF_STAFF. `app/scenes/StaffScreen.gd`
draws the baked body, the live header (PMChrome.draw_header, so club/manager/date track the
career), and — when live `personnel` data is supplied — the 13 slots' {name, half-stars,
£wage} over the baked cells.

### frame-true vs approximated vs honest-gap
- **Frame-true (100.00% exact-pixel vs frame 121, body y58..480):** the entire CLUB
  PERSONNEL body — TRAINING STAFF panel, all 6 skill cells, 7 role cards, portraits,
  section/role labels, WAGE labels, SIGN/SACK/RETURN — is the frame's own pixels.
- **Shared component (differs by design):** the header barra is the app's live PMChrome
  header (same on every ported screen), not the baked original — it updates with the career.
- **Approximated (the live-data overlay):** when a `personnel` dict of HIRED staff is
  supplied, the scene repaints each hired role's name-bar with a single sampled colour (the
  originals are a top-bright / bottom-dark gradient) and redraws name/half-stars/£wage;
  training rows land clean, role rows are legible with ~1px cosmetic edge tolerance.
- **Live-data stars corrected (2026-07-14, was the last-flagged follow-up):** `_stars()` used
  to draw RIGHT-anchored gold + **grey placeholder off-stars** on hired/synthetic slots. The
  original (frame 121) draws ONLY the earned gold stars, **LEFT-anchored** from a fixed
  origin, unfilled slots bare (measured: step 11px, first centre = `stars_right - 53.5` for
  the 6 skill-trainer bars, `- 49.0` for the 7 role cards). `_stars()` rewritten to match;
  `_star_off` colour removed. Verified by re-rendering with the frame-121 REF_STAFF ratings
  as live data: live-drawn star centres overlay frame 121's own baked stars within **≤2px on
  all 13 slots**, no grey stars. `test_staff_screen` 17/17 still PASS.
- **Vacant state (correct default, CORRECTED 2026-07-14):** a PM98 career opens with **NO
  staff** — `Career.staff == []` — and the manager signs them from a generated pool
  (`Staff.generate_pool`); AI/rival clubs have **no staff at all**. So there is **NO
  per-club staff DB and none is needed** (an earlier version of this doc wrongly called
  that a data gap "blocked on PCF5DAT" — WRONG). Because the baked body is frame 121 (a
  fully-HIRED club, captured ~10s after the walkthrough manager signed everyone — see
  frames 110-121), every unfilled role is **blanked to the vacant state** (empty bar, no
  name/stars/£; frame 115's empty "CURRENT …" bar). Left role cards' baked names overhang
  the measured bar ~30px to the left (portrait ends x49, name starts x50, bar.x=80), so
  `_blank_bar` grows the left edge for `kind=role, mirror=false` slots.

## The real candidate pools (WITNESSED 2026-07-18, charter #9)

Two independent careers' hire lists were transcribed frame-by-frame: **run1 Man Utd**
(frames 095-120, 1 Aug 1997 — the walkthrough manager signs all 13 roles) and the **wine
Bolton career** (`wine-captures-2026-07-18-goalscorers/` 56-59, Week 3). Every row below
is read off the original's own pixels (zoomed 3x; half-star = the half glyph).

**Man Utd pools (all 13 — frames 095/097/099/101/103/105 trainers, 107/110/112/115/117/119
singles):**

| Pool | Candidates (name ★ £/yr, list order) |
|---|---|
| HANDLING | T. Munt 1.5 £5,000 · A. Padmore 3.0 £17,000 · T. Watkinson 1.0 £4,000 |
| PASSING | D. Gledhill 4.5 £34,000 · L. Adams 1.5 £6,000 · Y. Jumblat 4.0 £27,000 |
| DRIBBLING | P. Wren 4.5 £41,000 · S. Merrick 5.0 £47,000 · L. Gledhill 1.0 £3,000 |
| HEADING | A. Mitchell 3.0 £16,000 · C. Somers 1.5 £6,000 · J. Young 1.0 £3,000 |
| TACKLING | D. Swann 3.0 £19,000 · G. Willis 1.0 £3,000 · T. O'brian 3.5 £21,000 |
| SHOOTING | T. Alan 4.5 £33,000 · P. Powell 2.5 £13,000 · G. Dale 2.5 £12,000 |
| PHYSIOTHERAPIST | P. Gelbier 5.0 £45,000 · B. Woolrich 2.0 £9,000 · R. Dwyer 3.0 £16,000 |
| PSYCHOLOGIST | S. Norton 2.0 £6,000 · P. Keen 2.0 £6,000 · J. Bodin 4.5 £15,000 |
| ASS. MANAGER | A. Leigh 4.0 £16,000 · P. Wright 2.0 £7,000 · L. Malik 2.5 £9,000 |
| SCOUT | G. Young 1.0 £4,000 · J. Loxton 2.0 £8,000 · K. Hatch 4.5 £45,000* |
| YOUTH MANAGER | D. Read 3.5 £21,000 · T. Snell 2.5 £12,000 · M. Mcgrath 3.0 £20,000 |
| YOUTH SCOUT | M. Dearing 1.5 £6,000 · W. Sugar 5.0 £36,000 · L. Larson 1.5 £7,000 |
| GROUNDSMAN | A. Dongle 3.0 £2,000 · J. Davies 1.0 £1,000 · G. Debnam 4.5 £4,000 |

*Hatch's row itself wasn't captured (frame 114 is post-sign); his 4.5/£45,000 is frame
121's hired card. **Bolton pools (partial):** HANDLING T. Savage 5.0 £52,000 · R. Robinson
3.0 £19,000 · B. Rogers 5.0 £52,000 (56/57) · SCOUT R. Robson 1.5 £6,000 · J. Gomez 1.0
£4,000 · K. Burrowes 3.0 £20,000 (58/59).

**Mechanics decoded from the sequences:**
- **Each of the six trainer SKILLS has its OWN 3-candidate pool** (HANDLING's list ≠
  PASSING's ≠ DRIBBLING's...), same as each single role.
- **Signing REMOVES the candidate** — the remaining rows shift up and the third row goes
  empty (witnessed after every one of the 15 signings) — but only until the week rolls.
- **THE WHOLE LIST IS REGENERATED EVERY WEEK — witnessed 2026-07-24** (charter: the
  owner's "there are plenty in the original, some vary in star ranking; now it is the
  same the whole time"). One Bolton W career, PHYSIOTHERAPISTS list, nobody signed in
  between (`screenshots/wine-captures-2026-07-24-role-training-staff/`):

  | week | frame | candidates |
  |---|---|---|
  | 1 | `23_physio_wk1.png` | A. Burgess ★★½ £6,000 · R. Fields ★★ £7,000 · N. Kelso ★★ £5,000 |
  | 3 | `29_physio_wk3.png` | F. Hallet ★★★ £18,000 · D. Todd ★★★★½ £35,000 · P. Horlicks ★★★★★ £47,000 |
  | 4 | `32_physio_wk4.png` | G. Conner ★ £4,000 · E. Wragg ★★★★½ £42,000 · J. Preece ★★★★½ £42,000 |

  Three different men each time and a fresh star spread — including the 4.5-5.0 star
  staff the owner could never reach. Closing and reopening the screen inside the SAME
  week returns the identical list (`30_physio_wk3_reopen.png`), so the roll happens on
  the week tick, not on screen open. Ported as `Career._refresh_staff_pool`, called from
  `advance_week`; test `app/tests/test_staff_weekly_pool.gd`.
- **List order is NOT rating-sorted** (HANDLING 1.5/3.0/1.0; YOUTH MANAGER 3.5/2.5/3.0) —
  generation order.
- **Wages are per-candidate**, not a function of stars: three 3.0-star trainers earn
  £16k/£17k/£19k in one career and £19k (Robinson) in the other; 5.0-star trainers £47k
  (Merrick) vs £52k (Savage, Rogers). Role classes scale differently (4.5★: trainer
  £33-41k, SCOUT £45k, PSYCHOLOGIST £15k, GROUNDSMAN £4k). All witnessed wages are round
  £1,000s.
- **Two careers → two different pools**: pools are generated per-career.

**The name bank is the game's own:** all 43 witnessed candidate surnames are rows of
`DBDAT/APELLIDO.30` (327 surnames; DMLT, XOR 0x61 — incl. `O'brian` via the escape byte
0x46^0x61=`'`), and the forename initials fit `NOMBRES.30` (148 forenames, e.g. Y. =
York/Yakub). Probability of 43/43 by coincidence ≈ 0. Exported verbatim by
`tools/re/export_staff_names.py` → `app/data/name_pools.json`.

**App model (Staff.gd, rebuilt 2026-07-18):** candidates draw name = table forename
initial + table surname; wage = `_WAGE_ANCHORS` — the exact witnessed (stars→wage) points
per role class (the 6 trainer skills share one class), interpolated between anchors, rng
within a band where several wages were witnessed at one rating, snapped to £1,000.
`pool_for_role` returns generation order (the stars-descending sort was killed). Youth
regen + free-agent names now draw from the same real tables (`Youth._gen_name`).
**FITTED (flagged, un-RE'd):** the star-rating distribution (uniform 1.0-5.0), wages
between/beyond witnessed anchors, per-career regeneration timing. The exe's own generator
was not reversed.

## Model — 13 single-occupancy roles (BUILT 2026-07-14)
`app/scripts/Staff.gd` now models the real game's **13 single-occupancy roles** (was a 5-role
multi-occupancy simplification): 6 skill coaches (HANDLING / PASSING / DRIBBLING / HEADING /
TACKLING / SHOOTING) + PHYSIOTHERAPIST / PSYCHOLOGIST / ASSISTANT_MANAGER / SCOUT /
YOUTH_TEAM_MANAGER / YOUTH_TEAM_SCOUT / GROUNDSMAN (the exact `personnel_chrome.json` keys).
Each role holds exactly ONE member; `Career.hire_staff` REPLACES the holder (outgoing returns
to the pool, no compensation — a SACK is the paid exit). Half-star ratings (`stars`, 1.0..5.0)
are the witnessed display; a 1..5 `quality` is kept for the effect hooks. **What is faithful:
the 13 role slots, single occupancy, half-star ratings, the surface strings** (all witnessed)
**+ since 2026-07-18 the pool mechanics, the real name bank and the witnessed wage anchors**
(see "The real candidate pools" above). **What is OURS (flagged, un-RE'd): the effect
magnitudes** (PM98 loads these from the save) and the fitted gaps flagged above. Engine
hooks preserved: the 6 coaches → `training_factor`,
PHYSIOTHERAPIST → `physio_factor`, YOUTH_TEAM_MANAGER → `youth_factor`, SCOUT/ASSISTANT_MANAGER
→ their automation. **HONEST GAP (never invented): PSYCHOLOGIST / YOUTH_TEAM_SCOUT / GROUNDSMAN
are hireable but have no engine effect** (no decoded source data), so they are no-ops.

## Hire overlay — SINGLE-ROLE + TRAINERS built (2026-07-14)
`app/scenes/StaffHireOverlay.gd` + `tools/re/build_staff_overlay_chrome_from_frames.py` +
8 baked plates `art/screens/staff/overlay_<cat>.png` + `overlay_trainers.png` +
`overlay_chrome.json`. Each of the 7 single-role categories (PHYSIOTHERAPIST 108 / PSYCHOLOGIST
110 / ASSISTANT_MANAGER 113 / SCOUT 114 / YOUTH_TEAM_MANAGER 115 / YOUTH_TEAM_SCOUT 117 /
GROUNDSMAN 119) has its own plate: the ORIGINAL frame's pixels with the **baked**
CURRENT/AVAILABLE header wording (irregular in the original — "SCOUTS YOUTH TEAM AVAILABLE",
"GROUNDSMEN AVAILABLE" — so BAKED, never generated) + its active-red rail button; the
career-dynamic zones (current holder, 3 candidate rows, £amounts) are blanked and redrawn live
from `Staff.member_in_role` / `Staff.pool_for_role`. Verified by render vs frames 113 (filled) +
119 (vacant): chrome frame-true, live data frame-placed.

### TRAINERS layout (frame 100) — BUILT 2026-07-14
`overlay_trainers.png` baked from **`100_154657.png`** (run1 15:47). A DIFFERENT plate: a
**CURRENT TRAINING STAFF** 6-skill list (HANDLING/PASSING/DRIBBLING/HEADING/TACKLING/SHOOTING,
each a coloured coach bar x175..341 with white name + gold half-stars + right-aligned black
£wage at x432 on the white panel) over a **STAFF AVAILABLE** pool (green candidate bars, black
name from x178 + gold half-stars + £wage, three baked SIGN buttons) filtered by a **2×3 skill
picker** (button rects [112/212/312 × 338/370], w82 h26), + the same 8-category right rail
(TRAINERS active-red) + OK. Measured off frame 100 (screen coords, `overlay_chrome.json`
`trainers`). The CURRENT bars are a FIXED orange→dark-red gradient by ROW position (not by
filled state): (212,95,0)/(212,63,0)/(210,0,0)/(170,0,0)/(150,0,0)/(85,0,0) — baked, names
redrawn over them for hired coaches, vacant rows left bare.
- **frame-true chrome:** static-chrome MAD **0.60** vs frame 100 (310/144k px differ — all the
  intentional HEADING de-border + 1px blank-fill edges). Plate placed at (67,63), scale 1.
- **Neutralised in the bake (only DRIBBLING-selected was ever witnessed, so per-skill bake is
  impossible):** frame 100's DRIBBLING blue-glow (the selected filter) + HEADING white focus-
  ring are keyed out to neutral buttons (paste a label-free HANDLING template, restore each
  button's own cyan label). The scene draws the live **selected-skill highlight** — a
  translucent-blue fill + bright edge over the chosen skill button. **FLAGGED APPROXIMATION** of
  the witnessed speckled glow (not pixel-reproduced). Default selected skill = the coach card
  tapped (or HANDLING when reached via the rail); the original's true default is un-witnessed.
- **Stars corrected (fidelity):** the original draws ONLY earned gold stars (left-aligned, + a
  left-half for .5) — **NO grey placeholder stars** (witnessed frames 100 + 113). `_stars()`
  now omits the off-star; this also improves the single-role overlay (same widget). ~~The main
  `StaffScreen.gd` (frame 121) still draws grey off-stars on live data — a SEPARATE follow-up.~~
  **DONE 2026-07-14** — see "Live-data stars corrected" above (left-anchored, no off-star,
  verified ≤2px vs frame 121 on all 13 slots).
- **Wiring (Main.gd):** the TRAINERS rail button and any coach card open `_open_staff_hire(
  "TRAINERS", refresh, skill)`; the picker's `skill_selected` re-filters the AVAILABLE pool
  (`Staff.pool_for_role`), a green SIGN → `Career.hire_staff`, another rail cat → switch, OK →
  close. CURRENT shows all six coaches from `Career.staff_personnel()`.
- `test_staff_overlay.gd` **27/27** (single + trainers hit-testing); render `shot_staff_overlay
  .gd` → `overlay_trainers.png` reproduces frame 100 (bar/skill/WAGE chrome frame-true; font is
  the app's shared substitute — accepted app-wide).

## WIRING (Main.gd) — BUILT
`_show_staff_screen` passes `Career.staff_personnel()` (role→{name,stars,wage} dict) to
StaffScreen.setup. `role_selected(role)` opens `StaffHireOverlay` for `Staff.category_of(role)`;
the overlay's `sign_candidate(id)` → `Career.hire_staff`; `category_selected` re-opens for the
new category; `ok_pressed` / tap-outside closes. The CLUB PERSONNEL `sign_pressed` opens the
overlay for the last-tapped role; `sack_pressed` sacks that role's holder (MODEL CHOICE:
sacking is selection-driven, the last card tapped is the selection). The old
`hire_requested`/`sack_requested`/`training_requested` signals are RETAINED (never emitted).

## Tests + verification
- `app/tests/test_staff_screen.gd` (NEW): chrome load (13 slots + buttons + REF_STAFF),
  money formatter, back-compat setup, and frame-true hit-testing (role card → role_selected,
  buttons → their signals). 17/17 PASS headless.
- `app/tests/test_staff.gd` / `test_staff_roles.gd`: the legacy Staff.gd model — still PASS.
- REAL render: `app/tests/shot_staff.gd`
  (`DISPLAY=:1 PM98_SHOT_DIR=out ~/godot462 --rendering-driver opengl3 --path app
  --script res://tests/shot_staff.gd`) → `staff_ref.png` (the VACANT career-start state —
  all 13 bars blanked, matching frame 115's empty state) + `staff_live.png` (a synthetic
  hired backroom, proving the data-driven overlay). The baked-chrome layout itself is
  100.00% exact-pixel vs frame 121 before the per-slot name blanking.

## Wage-value layer made 0px source-exact (2026-07-16)
The live wage £amounts were the last non-frame-true element of CLUB PERSONNEL. Root
cause found by rendering the frame-121 backroom (`ref_staff`) and diffing: the old
anchors were AUTHORED ("clear of SIGN/SACK"), not measured, and the draw was
right-anchored while the ORIGINAL centres each amount's INK box in its cell.
Frame-121 measurements (all 13 value bboxes):
- role-L cell x218..308 (border 309-310), values share ink-centre **cx 266**
  (£45,000 x241..291 / £16,000 x242..289 / £4,000 x245..287 — right edges differ,
  so NOT right-aligned); role-R cell x336..413, **cx 374**; trainer-L **cx 287**;
  trainer-R **cx 566** (£34,000 ink x541..591 — earlier reads to x608 were the baked
  cell underline at y132, not text).
- one face everywhere: **proman8 @ native 11pt** — per-row ink profile matches the
  frame row-for-row; baseline = glyph top + 7 (tops: trainer by+8, role cell_y+11).
- ink-centring needs the per-char ink insets (the atlas cells carry blank columns);
  `build_staff_chrome_from_frames.py` now measures them off `proman8.png` and bakes
  `wage_font_metrics` {ch: [xadvance, ink_lo, ink_hi]} into `personnel_chrome.json`.
  Half-pixel centres floor (£16,000: pen = cx − 23.5 → 242, matches frame).
- blank cells (`wage_cell`) now match the measured cells and stop short of the baked
  underlines (trainer y132 etc.) — this also fixed live cards erasing a neighbour's
  drawn value (the old 108-wide blanks overlapped the mirrored column: left-card
  wages rendered truncated, e.g. "£36" for £36,500, on every hired career screen).
Oracle: `shot_staff.gd` now also emits `staff_ref121.png` (the witnessed Man Utd
backroom). Verified: **all 13 wage cells diff 0px vs frame 121**. Names/stars remain
the app-wide substitute-font layer (stars ≤2px, 2026-07-14).
