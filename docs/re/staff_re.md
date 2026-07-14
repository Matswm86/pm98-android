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
★★★★★ £47,000 · HEADING A. Mitchell ★★★ £16,000 · TACKLING T. O'Brian ★★★★½ £21,000 ·
SHOOTING T. Alan ★★★★½ £33,000 · PHYSIOTHERAPIST P. Gelbier ★★★★★ £45,000 · PSYCHOLOGIST
J. Bodin ★★★★½ £15,000 · ASSISTANT MANAGER A. Leigh ★★★★ £16,000 · SCOUT K. Hatch ★★★★½
£45,000 · YOUTH TEAM MANAGER D. Read ★★★½ £21,000 · YOUTH TEAM SCOUT W. Sugar ★★★★★
£36,000 · GROUNDSMAN G. Debnam ★★★★½ £4,000.

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

## Model — 13 single-occupancy roles (BUILT 2026-07-14)
`app/scripts/Staff.gd` now models the real game's **13 single-occupancy roles** (was a 5-role
multi-occupancy simplification): 6 skill coaches (HANDLING / PASSING / DRIBBLING / HEADING /
TACKLING / SHOOTING) + PHYSIOTHERAPIST / PSYCHOLOGIST / ASSISTANT_MANAGER / SCOUT /
YOUTH_TEAM_MANAGER / YOUTH_TEAM_SCOUT / GROUNDSMAN (the exact `personnel_chrome.json` keys).
Each role holds exactly ONE member; `Career.hire_staff` REPLACES the holder (outgoing returns
to the pool, no compensation — a SACK is the paid exit). Half-star ratings (`stars`, 1.0..5.0)
are the witnessed display; a 1..5 `quality` is kept for the effect hooks. **What is faithful:
the 13 role slots, single occupancy, half-star ratings, the surface strings** (all witnessed).
**What is OURS (flagged, un-RE'd source data): the wages and the effect magnitudes** — PM98
loads these from the save. Engine hooks preserved: the 6 coaches → `training_factor`,
PHYSIOTHERAPIST → `physio_factor`, YOUTH_TEAM_MANAGER → `youth_factor`, SCOUT/ASSISTANT_MANAGER
→ their automation. **HONEST GAP (never invented): PSYCHOLOGIST / YOUTH_TEAM_SCOUT / GROUNDSMAN
are hireable but have no engine effect** (no decoded source data), so they are no-ops.

## Hire overlay — SINGLE-ROLE built (2026-07-14), TRAINERS remaining
`app/scenes/StaffHireOverlay.gd` + `tools/re/build_staff_overlay_chrome_from_frames.py` +
7 baked plates `art/screens/staff/overlay_<cat>.png` + `overlay_chrome.json`. Each of the 7
single-role categories (PHYSIOTHERAPIST 108 / PSYCHOLOGIST 110 / ASSISTANT_MANAGER 113 /
SCOUT 114 / YOUTH_TEAM_MANAGER 115 / YOUTH_TEAM_SCOUT 117 / GROUNDSMAN 119) has its own plate:
the ORIGINAL frame's pixels with the **baked** CURRENT/AVAILABLE header wording (irregular in
the original — "SCOUTS YOUTH TEAM AVAILABLE", "GROUNDSMEN AVAILABLE" — so BAKED, never
generated) + its active-red rail button; the career-dynamic zones (current holder, 3 candidate
rows, £amounts) are blanked and redrawn live from `Staff.member_in_role` / `Staff.pool_for_role`.
Verified by render vs frames 113 (filled) + 119 (vacant): chrome frame-true, live data
frame-placed. `test_staff_overlay.gd` 15/15.
- **STILL TODO: the TRAINERS layout (frame 100)** — a different plate: CURRENT TRAINING STAFF
  6-skill list + STAFF AVAILABLE filtered by a 6-button skill picker. Tapping the TRAINERS rail
  button is an inert no-op until that layout is built, so the 6 coach roles are not yet
  hireable through the overlay (the model + CLUB PERSONNEL screen already show them).

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
