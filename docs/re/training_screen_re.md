# TRAINING sub-screen (LINE-UP → TRAINING) — RE + build notes

> **THE DEVELOPMENT MODEL IS NOW EXACT (2026-07-25).** Owner report: *"training doesn't
> actually do anything. The players' stats don't go up. They do in the original, so fix
> it so it's exact."* He was right, and the cause was ours: the app carried an invented
> age-based drift whose PRIME rate (`0.015`/week) needed **67 weeks per attribute point**,
> so a manager's core squad never moved in a season. See
> [The weekly development pass](#the-weekly-development-pass-fun_00582760) below.

## The weekly development pass (`FUN_00582760`)

Located and ported this session. `FUN_0057b400` is the **weekly club turn** — it is the
same function that runs `FUN_0057f080` (the four "The works to … has finished." messages)
and fires the two scout "…has finished his search" lines — and it walks the club's squad
list (`club+0x24`) calling `FUN_00582760` once per player, **for every club**.

**Every attribute is stored twice.** Decoded from the DBC loader `FUN_005820f0`
@0x582185-0x582250, which writes each of the ten EQUIPOS bytes into two blocks:

| | VE | RE | AG | CA | PO | EN | PA | RM | RG | TI |
|---|---|---|---|---|---|---|---|---|---|---|
| **LIVE** | +0x9c | +0x9d | +0x9e | +0x9f | +0xa0 | +0xa1 | +0xa2 | +0xa3 | +0xa4 | +0xa5 |
| **BASE** | +0xaa | +0xab | +0xac | +0xad | +0xae | +0xaf | +0xb0 | +0xb1 | +0xb2 | +0xb3 |

`+0x9c..+0x9f = VE/RE/AG/CA` is independently confirmed: `FUN_00534570` averages exactly
those four as `core4`, the known wage/AV input (`wage_formula_re.md` §2). BASE is the
shipped rating and is never rewritten after load; `FUN_0058b030` restores VE/RE/AG/RG
**from** BASE when the engine regenerates a player, which pins the direction of the pair.

The pass, verbatim:

```
mode = player[+0xa9]                      ; 0 = not in training
if mode == 0:                             ; DECAY
    for a in [PO, EN, PA, RM, RG, TI]:
        if base[a] < live[a]: live[a] -= 1
else:
    roll = rand(7) + 0x12                  ; 18..24 headroom for the focused attribute
    gain, cap[6] = 0, [0,0,0,0,0,0]
    switch mode:
      1 GENERAL   -> gain 1, cap[*] = 5
      2 FITNESS   -> gain 0                            (condition only)
      3 HANDLING  -> gain 1, cap[PO] = roll
      4 PASSING   -> gain 1, cap[PA] = roll
      5 DRIBBLING -> gain 1, cap[RM] = roll
      6 HEADING   -> gain 1, cap[RG] = roll
      7 TACKLING  -> gain 1, cap[EN] = roll
      8 SHOOTING  -> gain 1, cap[TI] = roll
      0x20 YOUTH  -> gain = 1 if rand(100) > 0x27 (60%); core4 climbs to BASE, then
                     mode = 0 + "Your youth manager has informed you that %s is ready
                     to be promoted to the first team squad."
    if gain:
        for a in the six:
            n = live[a] + gain
            if n <= base[a] + cap[a]: live[a] = 99 if n > 98 else n
    condition(+0xa7) += 3 if mode == 2 else 1          (FUN_00584c60, clamps [0x28, 99])
```

**The mode codes land exactly on this screen's eight focus rows**, and the skill →
attribute map is the one the app already had from SPEC_BINDING §3 (HANDLING→PO,
PASSING→PA, DRIBBLING→RM, HEADING→RG, TACKLING→EN, SHOOTING→TI). That is a strong
independent check on both.

Consequences that are the ORIGINAL's, not ours:

* a focused attribute climbs **a full point every week** until it is 18-24 clear of the
  shipped rating — so a season of focus is worth ~20 points, not the old ~8;
* **GENERAL** lifts all six, but only to base+5;
* **SPEED / STAMINA / AGGRESSION / QUALITY are not trainable at all**. Only the youth
  mode moves them, and only back up to the player's own shipped adult rating;
* taking a man off training **bleeds his gains away at a point a week**, down to base
  and no further;
* an AI club carries no focus, so its squad holds at its shipped ratings.

Ported in `app/scripts/Training.gd` (`develop_week`, with the disassembly in-file);
`Career.advance_week` and `_roll_ai_squads` both call it. Player records now carry
`attrs_base` (the BASE block), seeded at roster creation and lazily for legacy saves.
Regression: **`app/tests/test_training_exact.gd`** — one assertion per clause above,
including the `0x62` snap and the decay floor.

**Stated, not invented:** whether a separate SEASON-ROLLOVER pass ages attributes is
un-located. `FUN_005825c0` (season init) touches only morale `+0xa6`, condition
`+0xa7/+0xa8` and the counters — no attribute drift. The app's own age-based drift is
therefore gone from the weekly pass; `Training.trend()` survives only as the screen's
arrow readout, and the LIGHT/NORMAL/INTENSIVE lever now only feeds the injury roll
(the engine's pass has no intensity term).


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
5. ~~**Per-section scrolling**~~ — **CLOSED 2026-07-24.** The original SCROLLS each
   section; it does not cap the squad. Witnessed live on a Bolton W career with 9
   defenders in 6 slots (`screenshots/wine-captures-2026-07-24-role-training-staff/`
   `17_training.png` -> `18_train_scrolled.png`): the DEFENDERS bar is live with its
   thumb parked at the top, and ONE down-arrow click moves the list by exactly one row
   (Todd off the top, Whitlow onto the bottom). The old truncation was the owner's
   "newly signed players never appear in TRAINING" — `Career` appends a signing to the
   END of the squad, so the new man was always the one dropped.

   Geometry (design px): scroll column **x313 w16**; bands KEEPERS y87 h46,
   DEFENDERS y150 h94, MIDFIELDERS y262 h94, FORWARDS y374 h78; buttons **16** tall at
   each end (their last row is the bevel that turns black when the arrow goes live),
   track = `band_y+16 .. band_y+band_h-17`. Slider grammar is the game's usual
   `thumb_h = floor(track*visible/total)`, `thumb_y = track_y + floor(track*first/total)`
   — 41 px and +6 px for the witnessed 9-in-6 case, both exact.

   Art `tools/re/build_training_scroll_from_frames.py` (asserts the thumb 3-slice
   rebuilds both frames at 0 px); render-diff `app/tests/shot_training_scroll.gd` —
   **all four bars, both offsets: 0 differing px** vs the original. FORWARDS' RESTING
   bar is the one thing still un-witnessed (it is live in every frame we hold), so that
   band keeps the baked plate when it has nothing to scroll.
6. **AVER / grid AV formula** — rendered via the app rating (see above); PM98's
   exact internal figure is not reversed.

## Verification
`app/tests/test_training_screen.gd` (ALL PASS, headless): asset load, GK/DF/MF/FW
bucketing, isGK routing, AV=app-rating, grid hit-test + select/deselect, AUTO
no-op, TACTICS/RETURN signals, paint pass. Pixel parity is NOT MEASURED headless
(Godot dummy driver can't rasterize; a real-display `shot_*_parity` pass is the
outstanding visual check, as with LINE-UP).
