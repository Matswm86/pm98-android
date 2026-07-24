# TRAINING sub-screen (LINE-UP → TRAINING) — RE + build notes

> **GAPS #2 AND #4 CLOSED 2026-07-24** — the per-player FOCUS tags, AUTO, the caps and
> the CURRENT TRAINING STAFF band (name + stars + TP, TOTAL TRAINABLE = ΣTP) are now
> witnessed live. See [`transfer_loop_live_re.md`](transfer_loop_live_re.md) §6.

The LINE-UP screen's **TRAINING** button (T/I/S plate row 1) opens a dedicated
TRAINING screen. `app/scenes/TrainingScreen.gd` renders it: the REAL game's
resting chrome baked below the shared barra, plus a dynamic layer that traces
only to real app data. Doctrine: `pm98_stay_true_to_original` — every pixel is
frame-measured or an honest gap; **no invented numbers**.

## Binding frames (run-2, Mon 4 Aug 1997, Manchester Utd)
- `004_162346.png` — fresh state: no focus tags, grid TOTAL 0, right panel
  resting, CURRENT TRAINING STAFF band full, TOTAL TRAINABLE PLAYERS 25.
- `005_162348.png` — after AUTO: HA/TA/PA/SH tag chips + grid TOTAL 16.
- `006_162350.png` — Keane selected: the grid row becomes a **black bar** with
  light text + STARJUGON-selected stars.
- `007_162352.png` / `008_162354.png` — cursor-free button band (AUTO patch source).
- `010_162401.png` — Butt selected: AVER header value, GENERAL sub-rows
  (SPEED/STAMINA/AGGRESSION/QUALITY) + FITNESS…SHOOTING skill rows with stars +
  AV value; PASSING focus row.

Chrome/sprite bake: `tools/re/build_lineup_subs_chrome_from_frames.py` →
`app/art/screens/training/*.png` + `tools/re/specs/lineup_subs_samples.json`.

## Layout (640×480, body baked at y62; all coords design-space)
Title sprite `title.png` at **(250, 22)** (drawn over the barra by the scene;
`PMChrome.draw_match_header(self, "training", …)` supplies no "training" title).

### Left grid (frame-probed this session)
Row-bar fill `x16..286 h13`; section tops (baker `TR_SECT_TOPS`):
KEEPERS `[88,104]`, DEFENDERS `[151,167,183,199,215,231]`,
MIDFIELDERS `[263,279,295,311,327,343]`, FORWARDS `[375,391,407,423,439]`.
Columns (probed frame 005): `N.` header x20..32 → shirt-number cell centre ≈26
(`NUM_CELL=[16,21]`); names align under the section headers at **x53**; the
STARJUGON strip at **x163** pitch 14; `FI` header x240..252; `AV` header
x263..280 → AV cell centre ≈272 (`AV_CELL=[261,22]`).

Per row the scene draws: **number** (navy `0,0,128` = `grid_n`), **name**
(black), **STARJUGON** rating strip (`halves=(AV+1)÷10`, odd half = the dim
star), **AV** (red `210,0,0` = `grid_av`). Selected row: black bar +
white number/name, `star_sel_*`, bright-red AV (`grid_av_sel 255,0,0`).

**AV = the app's rating** = `LineupScreen._av_of` (mean of the 8 outfield attrs
VE/RE/AG/CA/RM/RG/PA/TI) — the exact number the user-accepted LINE-UP screen
already shows. PM98's internal training rating may differ (esp. keepers); using
the app rating keeps the two screens consistent rather than inventing a formula.

### Right panel (AVER., frame 010) — the richest traceable content
When a grid row is tapped, `_sel_pid` selects him and the panel paints his
**decoded attributes** on PM98's own rows (map = SPEC_BINDING §3):

| PM98 row (design y) | decoded attr |
|---|---|
| SPEED 130 / STAMINA 144 / AGGRESSION 158 / QUALITY 172 | VE / RE / AG / CA |
| HANDLING 200 / PASSING 214 / DRIBBLING 228 | PO / PA / RM |
| HEADING 242 / TACKLING 256 / SHOOTING 270 | RG / EN / TI |

Each: stars at x481 pitch 14 (`rp_star_on` on the white GENERAL sub-rows,
`rp_star_on_strip` on the FITNESS…SHOOTING strip; dim half `rp_star_off`) +
AV-column value in cell `[597,26]`, ink `59,85,130` (= `rp_av`). Header:
number `[356,16]` + name x384 + AVER value right-aligned x626 (same navy ink).

### Footer
TOTAL TRAINABLE PLAYERS = squad size, white, cell `[606,28]` y418 (frame: 25).
Grid TOTAL = "0" (rest), black, cell `[287,24]` y456. Buttons: AUTO
`(348,444,84,30)`, TACTICS `(448,…)`, RETURN `(548,…)` (dark-body extents
probed x351..425 / 451..525 / 551..625).

## Wiring
`LineupScreen.training_pressed` (T/I/S plate row 1, `TIS_BTNS[0]`, live only
while no pending change) → `Main._show_training_screen` → `setup(_mgr_club(),
_career.staff, _match_header())`. TACTICS → `_show_tactics_board_screen`;
RETURN → reopens LINE-UP.

## HONEST GAPS (flagged, never filled)
1. **FI (fitness) grid column** — the app tracks no per-player fitness byte; the
   FI cell stays empty (resting furniture).
2. **Per-player FOCUS tags (HA/TA/PA/SH) + AUTO assignment** — no focus model in
   `Training.gd` (it is intensity + passive weekly development). AUTO is a
   documented no-op; grid TOTAL stays 0; tag chips (`tag_*.png`) unused.
3. **Right-panel per-skill FOCUS row + "last" column** (`focus_row.png`) — same
   reason; the app has no per-skill focus or previous-value history.
4. **CURRENT TRAINING STAFF band** (per-skill coaches HANDLING…SHOOTING + TP) —
   the app's staff are generic roles (Trainer/Physio/Youth, `Staff.gd`), not
   PM98's six per-skill coaches; the band stays resting furniture, `staff_star.png`
   unused. `_staff` is accepted for API parity but not rendered.
5. **Per-section scrolling** — the scroll strips are baked furniture; sections
   overflowing their visible slot count are truncated (not scrolled).
6. **AVER / grid AV formula** — rendered via the app rating (see above); PM98's
   exact internal figure is not reversed.

## Verification
`app/tests/test_training_screen.gd` (ALL PASS, headless): asset load, GK/DF/MF/FW
bucketing, isGK routing, AV=app-rating, grid hit-test + select/deselect, AUTO
no-op, TACTICS/RETURN signals, paint pass. Pixel parity is NOT MEASURED headless
(Godot dummy driver can't rasterize; a real-display `shot_*_parity` pass is the
outstanding visual check, as with LINE-UP).
