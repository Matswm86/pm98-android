# SAVE GAME dialog — RE + frame-true port (2026-07-18)

Witnessed LIVE in wine during the 2026-07-18 goalscorers run: captures
50/51/52/53/55 of `screenshots/wine-captures-2026-07-18-goalscorers/`.
Ported the same day: `app/scenes/SaveGameDialog.gd`, baker
`tools/re/build_savegame_chrome_from_frames.py`, art `app/art/screens/savegame/`.
Opens from the hub SAVE GAME button (replaces the old "Game saved" toast).

## Binding witnesses

| capture | state |
|---|---|
| 50 | the hub beneath (diff reference) |
| 51 | fresh dialog, all slots empty -> **the card chrome** |
| 52 | first slot tapped: GAME cell BLACK + PLAYER cell darkened steel (59,85,130) |
| 53 | "wk3" typed: white thin glyphs (proman8@11) CENTRED in the GAME cell, y147..153 |
| 55 | CANCEL -> hub restored |
| (54) | wine SAVE error alert — wine cannot save; the SUCCESS visual is unwitnessed |

## Decoded structure (design 640x480)

- Card (140,102)-(499,377) over the LIVE **UNDIMMED** hub: the only 50-vs-51
  out-of-card diffs are the hub's own animated stadium + the captions the card
  covers (no dim layer). Same chassis as the NIVEL LOAD GAME card (M_DLG
  (140,102,360,276), frame 005).
- **TEN slots** (not eight): rows y144 + 16k, fill h12; GAME cell x148..349
  (0,0,160), split x350, PLAYER cell x351..488 (75,109,172), border x489.
- Title band y104..124 (150,0,0); header GAME/PLAYER y127..142; info strip
  y307..369 (static); SAVE (377,306,113,25) / CANCEL (377,346,113,25).
- Armed slot: GAME cell -> black, PLAYER cell -> (59,85,130). Typed name =
  white proman8@11 centred in the GAME cell.

## Port model

- Typing = a real LineEdit over the armed GAME cell (the SeleccionScreen
  career-entry pattern: black stylebox, centred white, caret transparent —
  witness shows none; mobile keyboard works). +1px y-nudge lands the glyphs on
  the witnessed rows.
- `Career.save_slot(slot, name)` -> `user://career_slot_N.json` (full career +
  `save_name`) + a sidecar index `career_slots.json` ({game, player} per slot;
  self-heals by scanning slot files). `load_slot`, `slot_metas`.
  `user://career.json` stays the autosave/Continue spine; saving a slot also
  refreshes it.
- NIVEL LOAD modal now lists the 10 slots (same rows; M_ROW_H corrected 17->16
  per the witness pitch); the legacy autosave summary shows on row 0 while slot
  0 is empty (compat). Row tap or LOAD -> `load_game(slot)`; -1 = autosave;
  loading a slot copies it over the autosave.

## Port verification (2026-07-18)

- GL (`app/tests/shot_savegame_verify.gd`, card rect): fresh vs 51 **0 px**,
  armed vs 52 **0 px**, typed vs 53 **0 px** (the LineEdit "wk3" raster lands
  pixel-exact).
- Headless `test_savegame_dialog.gd` ALL PASS (slot API round-trip incl.
  insurance state, index self-heal, arm/type/SAVE/CANCEL flow, NIVEL row
  model) + career/wiring suites + boot smoke clean.
- REAL APP E2E: hub -> SAVE GAME -> tap slot 2 -> typed "wk2 test" (black cell,
  white centred, PLAYER half darkened — frame-true live) -> SAVE ->
  `career_slot_1.json` + index written; fresh boot -> MANAGER LEAGUE -> LOAD
  GAME lists autosave + "wk2 test" -> row tap loads the slot into the hub.

## Honest gaps / unknowns kept

- SUCCESS visual + populated-slot rendering unwitnessed (wine could not save):
  the app closes silently on SAVE and renders stored slots as white centred
  text per cell (the typed-name grammar) — pattern-derived.
- Overwrite-confirm (saving onto an occupied slot), slot delete, and the info
  strip's purpose are un-walked — no confirm dialog is invented; re-saving a
  slot overwrites it.
- The 10-slot model coexists with the app's autosave spine (an app-ism the
  original lacks); documented in NivelScreen/Career.
