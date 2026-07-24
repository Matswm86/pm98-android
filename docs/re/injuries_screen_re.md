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
the scene draws: **PLAYER name** at x64 (black) + the real **diagnosis** in the
TYPE OF INJURY cell `[209,115]` (black) + the **Week** value (`injured_weeks`)
centred in cell `[355,40]` (frame row grey box x358..385).

### TYPE OF INJURY — BINARY-EXACT (2026-07-23)
The diagnosis is the game's own, no longer furniture. `Availability.INJURY_TYPES`
is lifted verbatim from **MANAGER.EXE** (`extracted/Premier Manager 98/`), the
injury-name pointer array at **VA 0x6622e8** (18 entries, native index order):

| idx | type | idx | type | idx | type |
|---|---|---|---|---|---|
| 0 | virus | 6 | dislocated wrist | 12 | broken cheekbone |
| 1 | cold | 7 | dislocated finger | 13 | dislocated shoulder |
| 2 | pulled muscle | 8 | sprained wrist | 14 | fractured rib |
| 3 | dead leg | 9 | groin strain | 15 | shin splints injury |
| 4 | pulled hamstring | 10 | broken nose | 16 | slipped disc |
| 5 | sprained ankle | 11 | broken toe | 17 | broken leg |

- The diagnosis is a byte at the injury record's **+2** field; accessor fn
  `injury_name()` @ **0x584e50** (`idx<18 -> table, else "XXXX"` sentinel @ 0x662448).
- `is_serious()` @ **0x584e20** returns 1 for indices **11..17** = the "badly
  injured" news tier (`Availability.SERIOUS_MIN=11`).
- Injury news wording is the game's exact templates (unit **weeks**, not matches):
  serious `%s is badly injured: he will be out for %u weeks with a %s.` (@0x662c04,
  one-week @0x662bc0); ordinary `%s will be out for the next %u weeks with a %s.`
  (@0x662b24, one-week @0x662afc). Feed line `%s, (%s), is out for %u week%s with a %s.`
  (@0x662990).
- **Roll distribution + duration table — CLOSED 2026-07-23** (`injury_model_re.md`):
  the per-type probability ladder (roll_B @0x585210) and the per-type duration
  jump-table (setter @0x584e70 / @0x585048) are now lifted binary-exact into
  `Availability.MATCH_INJURY_CDF` + `_injury_weeks(rng, ti)`. NOT DAT.PKF-driven —
  the tables are static code in MANAGER.EXE. The old invented short-weighting +
  uniform-within-tier pick are gone.
- **Insurance economy CLOSED 2026-07-24** (`insurance_economy_re.md`): `PRICE` =
  total injury weeks x £1,500 (`FUN_00584e00`), `INSUR.` = the policy group byte,
  `COST` = PRICE less the group payout (`FUN_0058c000`, 50 %/100 % for groups
  2/3), and the H column = `is_serious(diagnosis)`. Row builder @0x543770.
- **Still open**: the weekly-illness path (virus/cold, roll_A) — flagged, not faked.

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
1. ~~**TYPE OF INJURY**~~ — **CLOSED 2026-07-23**: the column now renders the real
   diagnosis (binary-exact table above; `Availability.injury_type_name`).
2. **PHYS. checkbox** (treatment toggle) — no treatment model; furniture.
3. ~~**PRICE / INSUR. / COST**~~ — **CLOSED 2026-07-24** (`insurance_economy_re.md`),
   together with the un-headered **H** column (`is_serious` -> YES/NO). The
   populated row's furniture is now frame-cut verbatim from witness 83
   (`tools/re/build_injuries_row_from_frame.py`) and the whole row render-diffs
   **0 px** against it. The INSURED row's document icon (@0x543b09) is now
   witnessed — see gap 6.
6. **Insured-row document icon** — **CLOSED 2026-07-24.** `screenshots/wine-captures-2026-07-24-cadence-season-store/
   07_injuries_row_insured_giggs.png` finally witnesses it: Giggs (Group 1) picked up a
   7-week dislocated wrist in a live career, and his INSUR. cell reads
   `[document icon] 1        0%` with COST equal to the full PRICE (£10,500) — i.e. **group
   1 pays 0%**, so the icon marks "a policy exists", not "a payout happened". The sprite
   occupies **x487..494 (8 px) x y266..275 (10 px)** inside the cell (cell border x483) on
   that 640x480 frame: a document with a folded top-right corner and two darker text rules.
   Remaining: cut it into the row strip (a baker pass); the port still draws the policy
   digit alone.
4. **"N PLAYERS" = physio quality** is *inferred* from frame 034's 5-stars↔"5
   PLAYERS" pairing (not reversed from the binary); flagged as an inference.
5. **Header red-cross plaque** — the injuries-mode barra decoration (frame 034
   top-left) is not reproduced; the scene uses the standard shared header.

## Verification
`app/tests/test_injuries_screen.gd` (ALL PASS, headless): asset load,
injured→section listing, **real diagnosis per row** (fractured rib / pulled
muscle), suspension exclusion, Week=injured_weeks, physio read from staff,
no-physio blank band, INSURANCE no-op, RETURN signal, paint pass.
`app/tests/test_availability.gd` adds: every injury carries a valid diagnosis +
exact news wording, serious/ordinary tiers both occur, recovery clears the type.
Render-diff `tests/shot_injuries_verify.gd` (`out/injuries_typed.png`, display
:1, 2026-07-23): diagnoses land in the TYPE OF INJURY column (x209..) beside
name/week; verified by eye vs the column map above.
