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
- **Approximated (the live-data overlay):** when a per-club `personnel` dict replaces the
  witnessed reference, the scene repaints each name-bar with a single sampled colour (the
  originals are a top-bright / bottom-dark gradient) and redraws name/half-stars/£wage;
  training rows land clean, role rows are legible with ~1px cosmetic edge tolerance.
- **Honest gap (data):** there is NO extracted PM98 per-club staff DB (the EMPLEADOS staff
  table is not reversed; `extracted/cm0102/.../staff.dat` is a DIFFERENT game). Until it is,
  the screen shows the WITNESSED Man Utd reference as an explicit placeholder. The old
  `app/scripts/Staff.gd` effect/wage model (TRAINER/PHYSIO/YOUTH_COACH/SCOUT/ASSISTANT — a
  5-role invention) is UNRELATED to this 13-position original surface and is left untouched
  (its `test_staff.gd` / `test_staff_roles.gd` still pass).

## WIRING (Main.gd — not edited in this pass)
`_show_staff_screen` should call `scr.setup(personnel, manager, club, season, week, club_id)`
with the managed club's real 13-role backroom once the EMPLEADOS DB is reversed (pass `{}`
for the witnessed reference until then), and connect `role_selected(role)` (hire overlay),
`sign_pressed` / `sack_pressed`, and `back_pressed` (dismiss — works today). The old
`hire_requested` / `sack_requested` / `training_requested` signals are RETAINED on the scene
(never emitted) so the current unmodified Main `.connect` calls do not fault; `setup` accepts
the old Array positional call without faulting (renders the pristine reference). This kills
the invented TRAINING browse (`training_requested` is never emitted).

## Tests + verification
- `app/tests/test_staff_screen.gd` (NEW): chrome load (13 slots + buttons + REF_STAFF),
  money formatter, back-compat setup, and frame-true hit-testing (role card → role_selected,
  buttons → their signals). 17/17 PASS headless.
- `app/tests/test_staff.gd` / `test_staff_roles.gd`: the legacy Staff.gd model — still PASS.
- REAL render: `app/tests/shot_staff.gd`
  (`DISPLAY=:1 PM98_SHOT_DIR=out ~/godot462 --rendering-driver opengl3 --path app
  --script res://tests/shot_staff.gd`) → `staff_ref.png` (pristine reference = frame 121,
  BODY parity 100.00% exact) + `staff_live.png` (a synthetic other-club backroom, proving
  the data-driven overlay).
