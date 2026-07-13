# INJURIES sub-screen (LINE-UP → INJURED) — RE + build notes

The LINE-UP **INJURIES** button (T/I/S plate row 2) opens a dedicated INJURIES
screen. `app/scenes/InjuriesScreen.gd` renders it: the REAL game's resting frame
baked below the shared barra + a dynamic layer from `Availability.gd` /
`Career.staff`. Doctrine `pm98_stay_true_to_original`: no invented content.

## Binding frames (run-2, Mon 4 Aug 1997, Manchester Utd)
- `034_162510.png` — empty list (no injuries): the whole body is resting
  furniture; the PHYSIOTHERAPIST band shows "P. Gelbier ★★★★★" and "5 PLAYERS".
- `039_162530.png` — witness (cursor on RETURN; INSURANCE-region patch source).
- Cross-ref screenshot: `screenshots/screens/squad_injuries.png`.

Bake: `tools/re/build_lineup_subs_chrome_from_frames.py` →
`app/art/screens/injuries/{chrome,title,phys_star}.png`.

## Layout (640×480, body baked at y62; design-space coords)
Title sprite `title.png` at **(253, 22)**.

### Header columns (probed frame 034, y92..104)
`PHYS.` x20..57 · `PLAYER` x80..134 · `TYPE OF INJURY` x209..324 · `Week`[H]
x353..403 · `PRICE` x428..460 · `INSUR.` x491..527 · `COST` x560..590.

### Section rows (grey 220, h16; baker `INJ_SECT_TOPS`)
GOAL `[105,125,145]`, DEF `[174,194,214,234]`, MID `[262,282,302,322]`,
FOR `[350,370,390]`. Per **injured** player (`injured_weeks>0`) in his section
the scene draws: **PLAYER name** at x64 (black) + the **Week** value
(`injured_weeks`) centred in cell `[355,40]` (frame row grey box x358..385).

Injuries are rolled for the **manager's club only** (`Availability.gd` scope),
so the list is exactly that squad. **Suspensions are not injuries** and are
excluded (they are `suspended_weeks`, a different counter).

### PHYSIOTHERAPIST band (frame 034 bottom)
From the first hired `Staff.PHYSIO` (`Career.staff`): **name** at x62 y448
(black, white band) + **quality stars** (`phys_star.png`, x220 pitch 14 y449, one
per quality point 1–5) + **"N PLAYERS"** = physio quality, white digit on the
black band, cell `[239,16]` y429. Blank when no physio is hired.

## Wiring
`LineupScreen.injuries_pressed` (`TIS_BTNS[1]`) → `Main._show_injuries_screen` →
`setup(_mgr_club(), _career.staff, _match_header())`. RETURN reopens LINE-UP.
INSURANCE `(358,434,124,34)`, RETURN `(500,434,134,34)` (button bodies probed
x385..476 / x525..609).

## HONEST GAPS (flagged, never filled)
1. **TYPE OF INJURY** — `Availability.gd` stores only `injured_weeks`, no
   injury-type string; the column stays furniture (no fabricated diagnoses).
2. **PHYS. checkbox** (treatment toggle) — no treatment model; furniture.
3. **PRICE / INSUR. / COST** — the app models no injury-insurance economy; those
   columns stay furniture and INSURANCE is a documented no-op.
4. **"N PLAYERS" = physio quality** is *inferred* from frame 034's 5-stars↔"5
   PLAYERS" pairing (not reversed from the binary); flagged as an inference.
5. **Header red-cross plaque** — the injuries-mode barra decoration (frame 034
   top-left) is not reproduced; the scene uses the standard shared header.

## Verification
`app/tests/test_injuries_screen.gd` (ALL PASS, headless): asset load,
injured→section listing, suspension exclusion, Week=injured_weeks, physio read
from staff, no-physio blank band, INSURANCE no-op, RETURN signal, paint pass.
Pixel parity NOT MEASURED headless (real-display shot is the outstanding check).
