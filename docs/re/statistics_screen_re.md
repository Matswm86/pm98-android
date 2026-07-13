# STATISTICS sub-screen (LINE-UP → STATISTICS) — RE + build notes

The LINE-UP **STATISTICS** button (T/I/S plate row 3) opens a dedicated
STATISTICS screen. `app/scenes/StatisticsScreen.gd` renders it: the REAL game's
resting frame baked below the shared barra + a minimal dynamic layer. Doctrine
`pm98_stay_true_to_original`: the per-player stat columns have **no source in the
app** and are shown as PM98's own zero state — never faked.

## Binding frames (run-2/1, Mon 4 Aug 1997, Manchester Utd)
- `069_162642.png` — XI-only visit (rows 1–11, MP=1 else dashes).
- `042_162537.png` … `044_162540.png` — full-squad (19 rows) after a match:
  MP/MIN/RATING/G./SHOTS/PASSES/TAC. filled (used to prove which cells are
  dynamic vs the empty-slot furniture).
- `147_154839.png` — run-1 zero state (all dashes), independent witness of the
  resting RETURN button.

Bake: `tools/re/build_lineup_subs_chrome_from_frames.py` →
`app/art/screens/stats/{chrome,title,title_manutd}.png`. The 11 filled rows in
069 are cleared by tiling the empty slot (row 13, asserted == row 15), so the
baked chrome is 19 blank slots — PM98's own pre-match look.

## Layout (640×480, body baked at y62; design-space coords)
Title sprite `title.png` at **(237, 22)**.

### Body title "STATISTICS FOR <CLUB>."
Verbatim navy+red sprite `title_manutd.png` at **(157, 71)** for Manchester Utd
(`club id == 40`, the walked club); any other club redraws the text in navy
(`0,0,128`, frame-sampled) at x182 y72. (The red shirt icon is only in the
Man Utd sprite — a minor gap for other clubs.)

### Header columns (probed frame 042, y98..108)
`#` x33..39 · `PLAYER` x67..121 · `MP` x177..186 · [clock]`MIN` x200..224 ·
`RATING` x242..266 · `MoM` x277..292 · `G.` x307..312 · [boot]`SHOTS` x329..363 ·
`PASSES` x377..415 · `TAC.` x429..461 · `S.` x488..493 · yellow x510 · red x532 ·
injury x552.

### Rows (19 slots, fill tops 111+16i, h13)
Per squad player the scene draws only **#** (shirt number, navy `0,0,128` —
frame 042-sampled — cell `[18,28]` centre ≈31) + **PLAYER** name at x66 (black).
Over-full squads keep all players but only the 19 visible slots are drawn (no
invented per-section scrolling). RETURN `(505,446,128,30)`.

## Wiring
`LineupScreen.statistics_pressed` (`TIS_BTNS[2]`) → `Main._show_statistics_screen`
→ `setup(_mgr_club(), _match_header())`. RETURN reopens LINE-UP.

## HONEST GAP (the whole stat table)
The app's `Career` / match engine **accumulates no per-player season statistics**:
there is no store for MP, MIN, RATING, MoM, G., SHOTS, PASSES, TAC., S., cards or
injuries per player across a season. (`Career` tracks only `clause_matches` /
`clause_goals` for players on a contract clause — a different, partial counter,
deliberately not surfaced here to avoid a misleading mixed table.) Every stat
column and the TEAM TOTAL row therefore stay at PM98's own pre-match zero state
(the baked empty-slot furniture), exactly matching the real game's fresh-season
look (frame 147_154839). No number is fabricated. Wiring a real per-player
season-stat accumulator into the match engine is the future work that would fill
these cells.

## Verification
`app/tests/test_statistics_screen.gd` (ALL PASS, headless): asset load, row list
= squad, 19-slot clamp on an over-full squad, Man Utd verbatim-title routing,
RETURN signal, paint pass. Pixel parity NOT MEASURED headless.
