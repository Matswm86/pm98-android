# PROMANAGER career screens — OFFERS SELECTION + MANAGER HISTORY (live-witnessed 2026-07-16)

The APP_VS_SPEC_AUDIT B5-1 tail item was the invented `_mount_browse` surfaces
**JOB OFFERS** / **YOUR CAREER** / end-of-season list ("no original counterpart
proven — confirm against the running original, else drop"). This session confirmed
against the running original: **both original counterparts EXIST** and are now
witnessed. Binding frames: `screenshots/promanager-career-2026-07-16/` (16 frames,
captured live from MANAGER.EXE under wine via `tools/re/wine/boot.sh` + `snap.sh`,
Promanager League, manager "mwm", TOTAL level, Players-age default OFF).

## Why they were never seen before
- Title-strip OCR sweep over ALL existing captures (638 walkthrough frames +
  124 frames across the 5 other capture sets) has **zero** hits for OFFERS
  SELECTION / MANAGER HISTORY / END OF SEASON — the 2026-07-02 walkthrough was
  Manager League only, and never season-end.
- The INFOFUT help files the EXE references (`if5proma.htm`, `if5prinf.htm`)
  are NOT shipped on the iso, the rar, or the installed tree — no help-file
  shortcut exists; the EXE + live run are the only sources.

## Screen 1 — OFFERS SELECTION (Promanager career start)
Route: title → PRO-MANAGER LEAGUE → SELECT LEVEL OF THE GAME (NIVELES) → pick
level → **OFFERS SELECTION**. Witness frames 03–07.

- Header: green-pitch plaque "Promanager League" top-left, title
  `OFFERS SELECTION` (0x25e5bc), ball icon top-right.
- Upper table = the 7 Promanager save slots: columns `MANAGER | TEAM | DIVISION
  | OBJECTIVE`. Active slot: black name-entry cell + an `OFFERS` button cell
  under TEAM. Grey row chips left; filled slot gets its number + arrow chip.
- Type name → click OFFERS → lower panel `OFFERS FOR <name>` (0x25e724) fills:
  columns `TEAM | DIVISION | OBJECTIVE`, red numbered chips 1..10 + arrow per
  row. Witnessed: a fresh manager gets **10 offers, all 3rd Div.** —
  6× Avoid Relegation + 4× Mid Table (reputation-banded; band mechanics beyond
  the fresh-manager case are NOT witnessed).
- Row **arrow** → club-detail popup (frame 06): headers `<club>` (orange) +
  `<division>` (yellow), kit sprite, rows `STADIUM | CAPACITY | MEMBERS |
  INTIAL CASH` (sic, 0x25e6ec–0x25e6e0 block) + OK. Witnessed values: Brighton
  & HA → "Priestfield Stadium / 17,600 seats / - / £750,000".
- Clicking a row **accepts**: upper slot fills `mwm | Brighton & HA | 3rd Div.
  | Avoid Relegation`, the NEXT slot's name cell activates (multi-manager,
  like the seleccion 20-slot list), CONTINUE goes green.
- Bottom bar: `RETURN | Load Game | Delete | CONTINUE` (the GAME menu strings
  0x25e5a8 Delete / 0x25e5b0 Load Game sit in the same block).
- CONTINUE → the standard PRETEMPORADA "Preseason for <club>" screen (frame
  08) — the Promanager flow joins the known start-of-season chain from there:
  preseason friendlies → TEAMS IN CHAMPIONSHIPS (0x255560, frame 09) → cup
  draw EMPAREJAMIENTOS (frame 10) → CHARITY SHIELD CHAMPION (CAMPEON family,
  frame 11) → START OF SEASON division-objectives table (0x25546c, frame 12,
  `TEAM | MANAGER | OBJECTIVE` + division tabs) → **PROMANAGER MENU** hub
  (0x25c804, frame 13 — same layout as MANAGER MENU, different title).

EXE strings: `OFFERS SELECTION` 0x25e5bc, `Promanager` 0x25e5d0, art refs
`recursos\iconos\seleccionpro\flecha1.bmp`/`flecha0.bmp` 0x25e60c/0x25e638.
PKF art: RECURSOS.PKF dir `SELECCIONPRO` = FLECHA0/FLECHA1/INFO00 only (the
screen otherwise reuses shared FONDO/BARRA + table chrome). The column-header
string block 0x25e6c0–0x25e724 (`CONFIRM PASSWORD | PASSWORD | INTIAL CASH |
MEMBERS | PUBLIC | DIRECTORS | OBJ. | POS. | DIVISION | OFFERS FOR`) is SHARED
by this screen, its popup, and MANAGER HISTORY (password strings = the
protected-slot feature, un-witnessed).

## Screen 2 — MANAGER HISTORY (the real "YOUR CAREER")
Route (witnessed in Promanager, week 1): hub FINANCES → BOARD ROOM → new
bottom-left button **MANAGER INFO** (red ?) → **MANAGER HISTORY**. Frames
14–16.

- Title `MANAGER HISTORY` (0x25b674), manager-name plaque top-right, ball icon.
- Upper table = one row per club spell: `TEAM | DIVISION | POS. | OBJ. |
  DIRECTORS | PUBLIC` (~9 visible rows + scrollbar; witnessed row: "Brighton
  & HA | 3rd Div. | 23rd | YES | 5 | 5", gold text, POS. red). OBJ. YES =
  objective currently met; DIRECTORS/PUBLIC = the two board-confidence values.
- Lower table = per-competition record: `COMPETITION | PLA | WIN | DR | LOS |
  GF | GA | POSITION` with fixed rows LEAGUE / F.A. CUP / COCA COLA CUP /
  CHARITY / U.E.F.A. / CUP WINNER'S / EUROPEAN CUP / SUPERCUP / INTERCONT.
  (row-label tints: domestic light-blue, U.E.F.A.+CUP WINNER'S green,
  EUROPEAN CUP+ later dark-blue — read from frame 15).
- Right: red left-arrow + `TOTAL` toggle button (lit red when ON, frame 16;
  with a single one-week-old spell the tables are identical ON vs OFF — the
  per-spell vs career-total split is INFERRED from the button name, not
  witnessed). `RETURN` bottom-right.
- EXE strings 0x25b674–0x25b704: `MANAGER HISTORY`, `INFOFUT\if5prinf.htm`,
  `recursos\iconos\historial\flecha.bmp`, `POSITION | INTERCONT. | SUPERCUP |
  COCA COLA CUP | COMPETITION`. RECURSOS.PKF dir `HISTORIAL` = FLECHA.BMP.

## Board-room entry discrepancy (OPEN — do not guess)
Walkthrough frame `167_154921` (Manager League, **preseason** 1 Aug) shows NO
MANAGER INFO button on BOARD OF DIRECTORS; the Promanager **week-1** capture
(frame 14) has it. Two variables differ (mode, preseason-vs-season) — which
one gates the button is UNRESOLVED. Also unresolved: frame 167's APPLY FOR
LOAN middle column header reads `YEARS`; frame 14's reads `WEEK`. Both need
either a Manager-League in-season capture or the EXE xref
(`FUN_?` behind 0x25b674) before the app adds the button outside Promanager
context. String 0x257844 "This option is only available in Manager League or
in Promanager League" may relate (vs Trainer/Accountant levels), not to the
mode split.

## END OF SEASON / END OF THE GAME (strings decoded, screens NOT witnessed)
- `END OF THE SEASON` 0x25aa60 block: "The directors are pleased/disappointed
  with the results." / "You receive a bonus of %s for last year." / "You began
  the season as {Champion of %s|%s runner up|in the %s position of %s} and
  have finished {as the Champion|as runner up|in the %s position}." / "As
  manager %s%s, you have [not] achieved the objective you have been signed to
  (%s)." + per-cup won/runner-up lines (0x25ac59–0x25af0d). Adjacent art ref:
  `recursos\iconos\noticias\newsextra.bmp` — delivery surface likely the news/
  report family, NOT a browse list. Reaching it needs a full simulated season.
- `END OF THE GAME` 0x25a940 + "Congratulations, you have proved yourself to
  be an excellent manager." + `RECURSOS\PREMIER\ICONOS\FinObjetivo\
  goal_game.bmp` (PKF dir FINOBJETIVO) = the game-completion screen.
- Sacking is message text (0x261d44 "The Directors have held an urgent
  meeting," / 0x261d6f "and have sacked you as manager of the club.", plus the
  squad-minimum and financial variants 0x261c90/0x261e18). **What screen
  follows a sack is NOT witnessed and NOT string-provable** — whether the
  original returns to OFFERS SELECTION, ends the career, or does something
  else is an open question for the EXE sack code path.

## SHIPPED 2026-07-16 — MANAGER HISTORY rebuilt frame-true (0px both states)
`ManagerHistoryScreen.gd` + `tools/re/build_managerhistory_chrome_from_frames.py`
(bakes `app/art/screens/managerhistory/body.png` + `total_on.png` from frames
15/16) + `diff_managerhistory_parity.py`: **0px on the FULL 640x480** vs both
witnessed states. Decoded in the build:
- Upper table: 13 rows, y=96+15r, fill h14; cells TEAM 20..117 (navy 0,0,128) /
  DIVISION 119..201 (80,100,120) / POS. 203..243 (60,80,100) / OBJ. 245..285
  (30,52,98) / DIRECTORS 287..369 / PUBLIC 371..453; text **proman8@11**
  (glyph-verified), ink top = fill top+4; TEAM left-pad 3, POS. left-pad 9
  (single-witness: centring puts "23rd" at 209, witnessed 212 — NOT centred),
  DIVISION/OBJ./DIRECTORS/PUBLIC advance-centred floored.
- Lower table: rows y=334+15r; data cols alternate fills PLA/DR/GF (204,204,255)
  vs WIN/LOS/GA (180,180,220); numbers proman8@11 black, centred; plaque name
  proman12@13 ink (30,52,98) advance-centred, baseline 33.
- **TOTAL recolour (witnessed frame 16):** when TOTAL is lit the spell row drops
  its gold: white on the navy cells (TEAM/OBJ.), black on the slate cells.
  Gold is plausibly the current-spell highlight — un-witnessed beyond one row.
- Data: `Career.competition_record()` (league `results`, cup-bracket manager
  ties incl. replays + both legs with ET folded into leg 2, one-off finals) +
  `comp_total` folded at each season boundary (advance_season / record_spell,
  mutually exclusive paths), saved/loaded. TOTAL view = folded + running season.
  Past spells' DIRECTORS/PUBLIC were never stored → honest empty cells;
  accumulation starts at ship (no retroactive data). POSITION column stays
  empty (filled format un-witnessed). Tests `test_manager_history_screen.gd`
  20/20 + `test_manager`/`test_career` green; PM98_MANAGER_SHOT real-render OK.
- `_show_job_offers()` (JOB OFFERS browse) → rebuild as OFFERS SELECTION's
  `OFFERS FOR` panel + club-detail popup chrome. The app fires it post-sack /
  headhunt (original post-sack surface unknown, above) — using the original
  offers chrome replaces invented chrome with witnessed chrome, flagged that
  the original's mid-career usage is unproven.
- `_show_end_of_season()` list → future: the 0x25aa60 directors' report text
  engine (needs the season-end witness first). Stays a flagged substitute.
- Career-start: the app keeps seleccion (Manager League path, already frame-
  true). A future Promanager mode would use OFFERS SELECTION at start.
