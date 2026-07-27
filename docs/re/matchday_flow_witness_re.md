# CAREER MATCHDAY FLOW — LIVE WITNESS RUN (2026-07-17)

Evidence: screenshots/wine-captures-2026-07-17-matchflow, docs/re/match_flow_re.md
  -- the captured frames this file is a reading of, and the flow document they feed.

The complete career matchday chain driven LIVE in the original (wine harness
`tools/re/wine/boot.sh`, fresh Manager-League "mwm" @ Bolton W, TOTAL level,
played: Villa friendly + Southampton wk-1 + into wk-3), captured as stills AND
20fps/10fps VIDEO. Binding frames + the three videos:
`screenshots/wine-captures-2026-07-17-matchflow/` (LOCAL — `screenshots/` is
gitignored, same as the 07-16 parity sets; the two analysis strips are tracked
in `docs/re/inventory-evidence/`). This doc supersedes the
guessed/still-only semantics in `APP_VS_SPEC_AUDIT.md` §C1 #12 and §C2
"FT hand-off" (corrections in §C6 there), and refines `match_flow_re.md`.

Every claim below was WITNESSED this run (frame/video named per claim).
Nothing here is inferred from the binary.

## 1. When MATCH OPTIONS appears — FIRST career match ONLY

- Career's FIRST match (the 1 Aug friendly): hub CONTINUE raises the MATCH
  OPTIONS modal over the (undimmed) hub — `matchday_options_first_match.png`.
  Witnessed identically on 06-24, 07-16 (orig/60) — every one a FRESH career.
- EVERY LATER MATCH: hub CONTINUE goes STRAIGHT into the stored presentation.
  Witnessed twice: wk-1 (`continue_wk1_no_modal_straight_to_brief.png` —
  KICK OFF screen ~1s after CONTINUE, no modal) and wk-3 (same, on video
  `wk1_no_modal_launch_20fps.mp4`).
- ⇒ audit C1 #12's "MATCH OPTIONS before EVERY match" is WRONG — the 07-16
  witness was a first match and was over-generalized. Gate the modal on a
  persisted per-career "first match played" flag.
- UNTESTED: whether a career RELOADED from a save shows it again (needs
  SAVE GAME + reboot; the original does NOT autosave — see §6).
- Fresh-career defaults in the modal: view mode = RESULTS (red), LINE-UPS ON.

## 2. Modal semantics (all witnessed)

- CANCEL → modal dismissed, hub unchanged (same date, week NOT played);
  CONTINUE re-opens it — `matchday_options_cancel_back_hub.png`.
- LINE-UPS toggle = the small ON/OFF CELL only (~x222..268, y341..369):
  one click flips ON↔OFF (`matchday_options_lineups_off.png`). The LINE-UPS
  label plate is INERT — two clicks at (162,356) changed nothing while the
  next cell click toggled first try. (App WIP maps both plates → correct to
  cell-only.)
- View-mode button tap = SELECT + LAUNCH immediately (match 1: single BRIEF
  tap at (325,288) → match mounted, no OK pressed — still `16_onbox`-state
  modal 1.2s earlier, KICK OFF screen 1.2s after).
- OK = LAUNCH with the current selection (roll4 video: OK with RESULTS red →
  match launched). Settings persist across matches (LINE-UPS ON survived to
  wk-1 with no modal shown).

## 3. XI-validity gate BEFORE the modal

CONTINUE with an injured player in the XI does NOT open MATCH OPTIONS — it
raises the standard alert box: **"The initial line-up is not correct. A
player is either banned or injured."** (`continue_xi_invalid_alert.png` —
Thompson had "virus 1 week"). Fixing the XI in LINE-UP (swap the flagged row
for a fit reserve; swap = click row, click replacement row) unblocks it.
Bonus witness: entering the hub after the injury news raised
"Thompson is out for 1 week with a virus." (`hub_alert_injury_virus.png`).

## 4. The pre-match XI-vs-XI photo roll (LINE-UPS ON)

Plays between LAUNCH and the presentation, in EVERY view mode — witnessed in
RESULTS mode (roll4 video) and BRIEF context (07-16 orig/61-63). LINE-UPS
OFF → skipped (match-1 launch with OFF went straight to the KICK OFF screen).

Timing measured off `roll_ok_launch_20fps.mp4` (detector table re-runnable):

- Transition to the clean fondo (no rows) first: ~0.9s of empty background —
  `roll_first_frame_clean_fondo.png` (f0092). Row 1 is NOT pre-landed.
- **Row pitch ≈ 4.3s** (faces of rows 0..6 land at ≈0.9, 5.1, 9.35, 13.6,
  17.85, 22.15s…). Full 11 rows ≈ 47s, then the header caps it.
- Per row (video strips `docs/re/inventory-evidence/
  roll_face_unfold_column_strip.png` + `roll_row2_band_landing_strip.png`):
  the photo pair GROWS IN PLACE at the row's face cells (vertical unfold,
  HOME face first, AWAY face ~1.5s later) — it does NOT fly up from the
  bottom. The HOME surname slides in from the LEFT EDGE on its normal dark
  band (white ink); the AWAY surname slides in from the RIGHT EDGE as a
  WHITE plate with BLACK ink that inverts to normal on landing
  (`roll_row3_awayplate_midslide.png`, 07-16 orig/62 "Phillips",
  `roll_wk1_rows12_midflight.png`). Numbers land last (away number after the
  away name settles — orig/61 shows Branagan settled, no away number yet).
- After row 11: the header band (home name ◄► away name + corner kits) and
  the grey manager row (home mgr left, own entered name right, e.g.
  "Jones" / "mwm") — `roll_complete_villa_holding.png`.
- **A tap mid-roll snaps to the COMPLETE board** (row 2 mid-flight + click →
  full board incl. header 1.5s later: `roll_complete_after_skip_click.png`).
- **The complete board AUTO-ADVANCES after a hold** — witnessed with ZERO
  clicks: complete board (47) → HALF TIME read-out (48) across a 10s gap.
  Hold ≈ 5–15s (not frame-exact). After a skip-tap the board still held ≥8s
  before advancing. An app model that waits for a tap forever is wrong.
- Column identity: LEFT = fixture HOME club, RIGHT = AWAY (both witnessed
  matches had Bolton away → right column). Header order "Home ◄► Away".
- Players without a photo show the placeholder silhouette (several Bolton
  rows).

## 5. Presentation by mode (career match)

**BRIEF** (07-16 witness + `brief_full_match_10fps.mp4`):
- IDLE pre-kick (00:00): doors LINE-UP/TACTICS/MAN-TO-MAN/STATISTICS + left
  STATISTICS + centre KICK OFF + right EXIT (orig/64).
- RUNNING: **every button vanishes except EXIT** —
  `brief_running_exit_only.png` (21:00: no doors, no KICK OFF, no left
  STATISTICS). Possession live (33/67), feed rich (engine grammar; the
  continuation lines are indented with no minute repeat; "Kick Off" line is
  plain, no minute). 90' runs in ~25 real seconds (≈3.6 min/s).
- FULL TIME: KICK OFF + doors gone; **a single CONTINUE stands in the EXIT
  slot** — `brief_fulltime_continue_only.png` (orig/68 same). CONTINUE → the
  FULL TIME read-out → CONTINUE → hub.

**RESULTS** (this run, roll4 chain): roll → **HALF TIME read-out** (bookings,
TOTAL FOULS, live possession, stadium panel, manager-side STATISTICS ×2 +
TACTICS + LINE-UP buttons, CONTINUE) `results_mode_halftime_readout.png` →
CONTINUE → **FULL TIME read-out** (second-half data added, MAN OF THE MATCH)
`results_mode_fulltime_readout.png` → CONTINUE → hub. So RESULTS mode has a
HALF TIME STOP, not a straight jump to full time.

**Read-out possession ≠ BRIEF possession** (57/43 vs 55/45 same match) — two
separate counters in the original; don't force them equal.

**STADIUM panel: ALWAYS the fixture HOME club's ground, FILLED** — witnessed
at two AWAY matches for the manager: Villa Park (capacity 39,339 / att
13,375 34% / £100,312 / boards 36-38% / £7,500-8,250) and The Dell (15,200 /
12,160 80% / £91,200 / 78% / £17,250) `readout_fulltime_thedell_away_filled.png`.
The app's "honest blank for away venues" is a parity gap (audit C2 already
flags it; charter #6).

## 6. EXIT during a match = leave the championship (NOT a result skip)

- EXIT tap (idle or running) → alert box **"Do you want to leave the
  championship ?"** with Yes/No — `brief_exit_leave_championship_alert.png`.
- **No** → alert closes, match resumes (28:00, running) —
  `brief_exit_no_resumes.png`.
- **Yes** → drops to the TITLE SCREEN. The career is ABANDONED UNSAVED
  (no autosave exists; the rebuilt career started from scratch) —
  `brief_exit_yes_title_screen.png`.
- ⇒ the audit §C2 line "pressing EXIT silently skips the FULL TIME read-out"
  described the APP bug, but the intended original behaviour is NOT
  "EXIT → read-out": it is this confirm-and-abandon. An app port needs the
  alert + Yes = leave career WITHOUT persisting the in-flight week (the app
  currently saves the result BEFORE presenting — faithful EXIT-Yes must not
  keep that save).

## 7. Bye weeks

FULL TIME read-out CONTINUE at wk-1 landed on the hub at **Week 3** (Sat 23
Aug) — the wk-2 bye passed silently, no stop, no modal
(`hub_week3_after_bye_skip.png`). Matches the app's bye handling.

## 8. Recapture recipe

boot.sh → MANAGER LEAGUE (165,277) → TOTAL (445,300) → banner (390,79) +
XTEST-type name (xdotool WITHOUT --window; --window/XSendEvent typing is
IGNORED by the game) → Bolton kit (291,318) → CONTINUE (565,438) → rival
slot-1 (50,385) + SKIP (557,344)×3 → CONTINUE (567,452) → champs (575,460) →
hub. Hub CONTINUE (588,267); modal OK (485,350) / CANCEL (374,356) /
LINE-UPS cell (240,351); BRIEF KICK OFF (320,457), EXIT (568,458), alert
Yes (401,263) / No (446,263); read-out CONTINUE (534,451); shield OK
(111,351); START OF SEASON CONTINUE (567,431). ffmpeg x11grab -window_id
for video (snap.sh only for stills).
