# TACTICS sub-screens — PREDEF. TACTICS + TEAM TACTICS

The two sub-screens that hang off the TACTICS board (`docs/re/tacticas_screen_re.md`,
`TacticsBoardScreen.gd` — parity-locked at 0px vs frame `014_162413`, NOT touched
here). Both were WRONG before this pass:

- **PREDEF. TACTICS** (the 10-formation picker) was a PMChrome-primitive overlay
  drawn *inside* `TacticsBoardScreen._draw_picker()` (blue bevels + `draw_circle`
  dots) built from disassembly geometry only — the picker was recorded "un-walked"
  in `tacticas_screen_re.md`. **It is in fact WALKED** (run-1 frames 140/142), so it
  is now frame-baked and moved to its own scene.
- **TEAM TACTICS** (the ATTACK|DEFENCE modal) was drawn procedurally with a phantom
  source citation ("read off ma_9" — no such file exists in the repo). Its control
  *content* was actually source-true; its layout and sourcing were not.

Builder for both chromes: `tools/re/build_tactics_subs_chrome_from_frames.py`.

---

## 1. PREDEF. TACTICS — FRAME-TRUE (the 10-formation picker)

**Binding frame** `screenshots/original-walkthrough-2026-07-02/140_154820.png`
(Man Utd board, picker open, RESTING — no selection).
**Dynamic-selection witness** `142_154825.png` (the "3-5-2" cell selected).
Builder `FUN_0056f4c0` (`tacticas_screen_re.md`). All coords 640x480.

The whole modal is STATIC (the same 10 source-table formations always), so it is
cut verbatim from frame 140 exactly like every other chrome bake in the repo:

| element | value (frame coords) | evidence |
|---|---|---|
| modal rect | **(106,158) 447x249** | auto-detected: maroon title x-extent + silver body run (asserts 440..460 x 235..255; ~ the disasm `0x1c3 x 0xfa` = 451x250 body) |
| title bar | maroon, white "PREDEFINED TACTICS" | rows y160..180, glyph-white asserted |
| thumbnail grid | 5 cols step 80px, centres x **167 247 327 407 487**; row-0 thumbs top y213, row-1 top y297 | green-pitch column/row runs |
| labels | row-0 ABOVE thumbs (band y195..208), row-1 BELOW (band y354..367) | black-text row bands |
| CANCEL | (272,378) 113x24 | frame-measured navy button |
| selection box | blue-grey bevel **fill (120,120,160)**, name repainted WHITE (`(0,0,0)` black resting → `(255,255,255)` white selected) | 142−140 diff bbox (208,193) 80x16 over the 3-5-2 label |

Grid order == source table `DAT_00660240` == `Tactics.FORMATION_ORDER` EXACTLY:
`3-4-3 3-5-2 4-3-3 4-4-2 5-3-2 / 5-4-1 4-2-4 5-2-3 4-5-1 3-3-3-1`.

**Bake output** `app/art/screens/tactics/predef_chrome.png` (447x249, opaque, the
whole modal). Also decoded for completeness (the picker thumbnail art, unused by
the frame-cut bake but source-true): `predefwin_campo.png` (80x75),
`predefwin_jug.png` / `predefwin_por.png` (8x7 dots).

**Screen** `app/scenes/PredefTacticsScreen.gd` (overlay): draws a dim backdrop +
the frame-baked chrome + the selection box on the CURRENT formation, with live
per-cell + CANCEL hit-rects. Signals `formation_picked(form)` / `cancelled`
(CANCEL or a tap outside the modal). **Parity: the modal chrome is a verbatim
frame cut; the selection box lands within 1px of frame 142** (composite check).

**Documented approximation (honest gap):** the dim backdrop. PM98 dims the board
with a palette LUT (`alert_box_re.md`); that LUT is board-state-specific and can't
be applied to the live *dynamic* board inside `_draw`, so the screen uses an alpha
dim `Color(0,0,0,0.45)` — identical in spirit to the retired inline picker's
`Color(0,0,0,0.5)`. The MODAL itself is 100% frame-true. The selected label's white
glyphs are repainted with ProMan12 + middot separators (the baked resting glyphs'
exact face/kerning are covered by the box, so this is a text-draw approximation of
the same class as the board's "TACTICS <formation>" title redraw).

---

## 2. TEAM TACTICS — SOURCE-TRUE ART, UN-WALKED LAYOUT (ATTACK|DEFENCE modal)

Board button `equipo.bmp` (478,330); modal spawn `FUN_0056ea15`
(`tacticas_screen_re.md`).

### HONEST GAP: the modal is UN-WALKED
It appears in **NO** walkthrough frame. Run-1 (board→PREDEF→board→LINE-UP),
run-2 (board `014`→VIEW RIVAL `015`→hub), and run-3 (finance/transfers/Euro-cup)
were all scanned frame-by-frame (per-run contact sheets); `APP_VS_SPEC_AUDIT` B6
lists the captured tactics screens as "TACTICS + PREDEFINED (10 formations) +
VIEW RIVAL" and, separately, "MAN-TO-MAN MARKINGS" — **never** a team-tactics /
attack-defence modal. `FUN_0056ea15` is not disassembled and no `lift_widgets.py`
exists. So the modal **cannot be frame-baked** and its assembled window geometry
was **NOT MEASURED** for parity.

**MEASURED 2026-07-26.** It is witnessed now:
`screenshots/wine-captures-2026-07-26-team-tactics/01_team_tactics_modal_live.png`, a live
640x480 capture of the modal open over TACTICS in a running MANAGER.EXE (Man Utd v
Newcastle, 23 December 1999). It is a capture of the real screen, so the modal CAN now be
frame-baked; what follows is what a bake needs, measured off it:

| element | span |
|---|---|
| modal outer frame | `x57..582`, `y95..397` (black rows y95-96 / y396-397, columns x57-58 / x581-582) |
| `TEAM TACTICS` title band | `y95..118` (band closes on the black row y118-119) |
| ATTACK panel | the left half; DEFENCE the right |
| X-boxes | 12x9 white plates, X drawn in red |
| ATTACKING / SPECULATIVE / MIXED PLAY | `(103,177)`, `(103,203)`, `(103,229)` |
| TACKLING SOFT / MEDIUM / AGGRESSIVE | `(374,190)`, `(442,190)`, `(523,190)` |
| MARKING ZONAL / MAN TO MAN | `(374,236)`, `(484,236)` |
| CLEARANCES SHORT / LONG | `(373,282)`, `(483,282)` |
| PRESSURISE OWN / MIDFIELD / OPPONENT | `(372,330)`, `(444,330)`, `(516,330)` |
| PASSING ↔ LONG BALL slider handle | around `(184..200, 268..270)`; the frame reads 70 % / 30 % |
| COUNTER ATTACK | YES 80 % / NO 20 % on the same slider idiom |
| OK | centred under both panels, `y≈365..385` |

Worth remembering WHY the levers on this modal do not change an instant result: the
statistical engine reads only `SEL`, `STR`, `GKSAVE`, `PASS`, `POS`, `ROLE`, and none of
these settings is among them (`docs/re/hack_three_forwards.md` §1).

### What IS source-true (and used verbatim)
1. **Every control + label.** The modal's complete label set is a contiguous
   string block in `MANAGER.EXE` at `0x25ff3c..0x260014` (`strings -t x`):

   | VA | string | VA | string |
   |---|---|---|---|
   | 0x25faa4 | TEAM TACTICS | 0x25ff8c | PRESSURISE FROM... |
   | 0x26000c | ATTACK | 0x25ff48 | OWN |
   | 0x260004 | DEFENCE | 0x25ff3c | MIDFIELD |
   | 0x25fff4 | ATTACKING PLAY | 0x25c5a0 | OPPONENT |
   | 0x25ffe0 | SPECULATIVE PLAY | 0x25ffb4 | TACKLING |
   | 0x25ffd4 | MIXED PLAY | 0x25ff84 | SOFT |
   | 0x25ffcc | PASSING | 0x25ff7c | MEDIUM |
   | 0x25ffc0 | LONG BALL | 0x25ff70 | AGGRESSIVE |
   | 0x260014 | COUNTER ATTACK | 0x25ffac | MARKING |
   | 0x25ffa0 | CLEARANCES | 0x25ff68 | ZONAL |
   | 0x25ff54 | SHORT | 0x25ff5c | MAN TO MAN |
   | 0x25ff4c | LONG | | |

   This is why the control SET is authoritative even with no frame — and it
   matches `Tactics.gd`'s levers 1:1 (mentality Attacking/Speculative/Mixed;
   PASSING↔LONG BALL; COUNTER ATTACK; TACKLING Soft/Medium/Aggressive; MARKING
   Zonal/Man-to-man; CLEARANCES Short/Long; PRESSURISE Own/Midfield/Opponent).

2. **Every ART piece.** RECURSOS holds the complete EQWIN* ("EQuipo WINdow")
   cluster (contiguous past offset ~5.8M; same-named decoys earlier are skipped).
   Decoded verbatim (SAD-0, MANAGER.PAL) to `app/art/screens/tactics/`:

   | file | source (RECURSOS) | size | role |
   |---|---|---|---|
   | eqwin_attack.png | EQWINATAQUE.BMP | 198x47 | ATTACK header (green pitch + BLUE arrows + globe) |
   | eqwin_defence.png | EQWINDEFENSA.BMP | 198x47 | DEFENCE header (green pitch + ORANGE arrows + globe) |
   | eqwin_ment{1,2,3}.png | EQWINAZUL1-3.BMP | 45x18 | mentality option tiles (blue arrow + baked checkbox) |
   | eqwin_row_tackle.png | EQWINDIB1.BMP | 192x17 | TACKLING row (3 shoe icons: normal/ice/fire) |
   | eqwin_row_marking.png | EQWINDIB2.BMP | 156x17 | MARKING row (1-player / 2-player icons) |
   | eqwin_row_clear.png | EQWINDIB3.BMP | 156x16 | CLEARANCES row (kick+arrow / smoke) |
   | eqwin_row_press.png | EQWINDIB4.BMP | 188x17 | PRESSURISE row (own/mid/opp pitch-zones) |
   | eqwin_pass_short.png | EQWINTOQUE.BMP | 41x21 | PASSING (touch) slider end |
   | eqwin_pass_long.png | EQWINLARGO.BMP | 41x21 | LONG BALL slider end |
   | eqwin_peak.png | EQWINPICOS.BMP | 18x18 | slider peak marker (unused yet) |
   | eqwin_step.png | EQWINBOTON.BMP | 20x17 | +/- stepper button |
   | eqwin_close.png | EQWINX.BMP | 9x7 | window close (the modal's ONLY exit) |
   | eqwin_arrow.png | EQWINFLECHA1.BMP | 6x11 | slider pointer (unused yet) |
   | equipo_icon.png | EQUIPO.BMP | 26x15 | the board's TEAM TACTICS button icon |

3. **Each option strip's checkbox centres**, measured off the decoded art and
   self-verified in the bake (each centre must be near-white): tackle
   `[31,100,180]`, marking `[35,145]`, clear `[31,143]`, press `[34,105,177]`,
   mentality-tile `34`. The selected option gets a tick painted into its box.

### What is RECONSTRUCTED (un-walked, flagged NOT MEASURED)
- The two-panel window arrangement and every y-position (`TeamTacticsScreen.gd`
  geometry constants). Grounded in the art: each header is 198px wide → two white
  panels side by side ≈ a ~448px modal, sized like PREDEF.
- The **strip→control assignment** is inferred from icon semantics: shoe=tackle,
  1-vs-2 players=marking, kick/smoke=clearances, pitch-zones=pressurise. The
  binary string block confirms the option NAMES and counts (3/2/2/3) but not which
  DIB strip the engine draws for which control.
- The **mentality tile order** (Attacking/Speculative/Mixed) is un-walked; the
  binary stores them as MIXED/SPECULATIVE/ATTACKING (low→high VA).

**Screen** `app/scenes/TeamTacticsScreen.gd`: dim + a bevelled window with the
blue "TEAM TACTICS" title, EQWINX close, the two real headers, the mentality tiles,
the four option strips (with selection ticks), and the PASSING/COUNTER sliders
(real TOQUE/LARGO ends + EQWINBOTON steppers). Every control mutates the live
`Tactics` and emits `changed`; the EQWINX emits `done`. **There is no OK/SAVE/RETURN
in this modal** — SAVE/LOAD TACTICS are BOARD buttons, not modal controls; the
modal exits only via the X. This corrects the retired `TacticsScreen.gd`, which
invented OK/SAVE/RETURN and the crude bevel layout.

---

## Wiring (APPLIED 2026-07-13)

`Main.gd::_show_tactics_board_screen` / `_show_tactics_screen` now adopt the new scenes:

- **PREDEF:** on `predef_pressed`, Main mounts `PredefTacticsScreen` over the board,
  `setup(_tactics().formation)`; `formation_picked(form)` → the shared `apply_form`
  (`set_formation(form, club)` + save + refresh) + free overlay; `cancelled` → free.
  The board's inline picker is **superseded WITHOUT modifying `TacticsBoardScreen`**
  (to keep its 0px parity + `test_tactics_board` regression intact): the board still
  opens its inline `_picker_open` overlay on the tap, and Main immediately suppresses it
  (`scr._picker_open = false; scr.queue_redraw()`) before mounting the frame-true modal,
  so only the frame-baked `PredefTacticsScreen` is visible/interactive. The board's own
  `formation_picked` connect is retained (the direct/test path in `test_career_ui`).
- **TEAM TACTICS:** `_show_tactics_screen` now mounts `TeamTacticsScreen` (was
  `TacticsScreen`), `setup(_tactics())`, `changed(dict)` → persist, `done` → free both
  overlays. The `save_requested` connect is **dropped** (no in-modal SAVE — the modal
  exits only via EQWINX). `TacticsScreen.gd` is now legacy (left in-tree, unreferenced).

Both new scenes are standalone overlays; they draw their own dim + transform (native
640x480, scale-to-fit), so they mount the same way `TacticsScreen` did.

## Tests
- `app/tests/test_predef_tactics_screen.gd` — mounts PredefTacticsScreen, asserts the
  frame-baked chrome loads, 10 cells in `FORMATION_ORDER`, 10+CANCEL hit-rects,
  `formation_picked` / `cancelled` signals, every cell inside the modal rect.
- `app/tests/test_tactics_screen.gd` — updated to drive `TeamTacticsScreen`: every
  source-true control hit-rect, each setter fires, `changed`/`done` signals, checkbox
  spec loaded from the samples json.
- `app/tests/test_tactics_board.gd` — regression (unchanged); the board is untouched.
  `~/godot462 --headless --path app -s tests/<file>` (run `--import` once after a bake).

## Deviation check — main TACTICS board vs frame 014
`TacticsBoardScreen.gd` and `app/art/screens/tacticas/*` are **untouched** this pass,
so the board's committed pixel parity (0px vs `014_162413`, `tacticas_screen_re.md`
"PIXEL PARITY 2026-07-03", `tests/shot_entry_parity.gd` + `diff_entry_parity.py`) is
preserved. `test_tactics_board.gd` regression = ALL PASS. Not re-rasterized (no X11
here); parity holds by non-modification. User verdict on the board ("close") stands —
no deviation introduced.
