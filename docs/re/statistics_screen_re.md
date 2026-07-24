# STATISTICS sub-screen (LINE-UP → STATISTICS) — RE + build notes

The LINE-UP **STATISTICS** button (T/I/S plate row 3) opens a dedicated
STATISTICS screen. `app/scenes/StatisticsScreen.gd` renders it: the REAL game's
resting frame baked below the shared barra + the dynamic layer over it. Doctrine
`pm98_stay_true_to_original`: since 2026-07-24 the per-player stat columns have a REAL
source — the ported season store — and the screen is parity-verified at 0 px against a
live MANAGER.EXE career (below). A player who never featured still prints the original's
own dashes; nothing is faked either way.

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
Per squad player: **#** (shirt number, navy `0,0,128`, proman10@10 LEFT-aligned at x28)
+ **PLAYER** name at x66 (black, proman10@10) + the **12 stat cells** (calend8@15, black)
in the row widget's separator pairs. The TEAM TOTAL is the same widget at y425, values in
black. All of it frame-measured — see the parity section.
Over-full squads keep all players but only the 19 visible slots are drawn (no
invented per-section scrolling). RETURN `(505,446,128,30)`.

## Wiring
`LineupScreen.statistics_pressed` (`TIS_BTNS[2]`) → `Main._show_statistics_screen`
→ `setup(_mgr_club(), _match_header())`. RETURN reopens LINE-UP.

## The stat table — WIRED AND PARITY-VERIFIED 2026-07-24
The former gap is closed. `Career` keeps the real season store and this screen renders it.

* `app/scripts/Pm98StatStore.gd` ports the commit (`FUN_0044e440`), the season fold-back
  (`FUN_00448b60 @0x448f6b`), the MoM selector (`FUN_0044a370`), the RATING formula and
  the cell / TEAM-TOTAL formatting. Oracles: `test_statcommit_oracle` (323 checks) and
  `test_mom_oracle` (18).
* `Career.season_stats` (pid -> 17 dwords) + `season_club_minutes` + `season_club_mp` are
  the persistent store; `Career.fold_match_stats()` folds each finished fixture in.
  `season_stat_rows()` / `season_stat_totals()` are what `setup()` takes.
  Regression: `test_season_stat_store` (33 checks).
* The cadence the store follows is settled in **[`stat_commit_cadence_re.md`](stat_commit_cadence_re.md)**
  — measured, not assumed.

**RENDER PARITY: 0 differing pixels of 254,592**, `tools/re/diff_statistics_parity.py`,
app vs `screenshots/wine-captures-2026-07-24-cadence-season-store/01_season_store_before_7matches.png`
(real MANAGER.EXE, Man Utd, 7 matches into 1997-98 — the same club-squad entry point this
screen ports). Reproduce with `app/tests/shot_statistics_verify.gd`. The three masks and
their reasons are in the comparator's docstring; the only one inside the table is the
scroll thumb, which is the signature of the list-scrolling this screen still does not do.

Faces and geometry the parity run pinned (all measured against every bundled atlas, none
assumed): stat cells **calend8@15** (digit ink 4x9, dash 3x1), `#` and PLAYER
**proman10@10**, `#` LEFT-aligned at x28, single cells centred in their separator pair,
`x/y` pairs laid out as three separate draws, TEAM TOTAL values in **black** (only its
label is red).

(`Career` also tracks `clause_matches` / `clause_goals` for players on a contract clause
— a different, partial counter, deliberately not surfaced here to avoid a misleading
mixed table.)

**MANAGER.EXE itself DOES have the store**, and it is now oracle-verified in
**`season_stats_re.md`** (2026-07-24, `tools/re/run_statcommit_oracle.sh` →
`tools/re/specs/statcommit_oracle.txt`): 0x48-byte records at `DAT_0066afd0+0x9c/0xa4`
(match report) and at `playerobj+0x24` (persistent), written by `FUN_0044e440` as a
straight copy of participant `+0xec..+0x12f` plus the id at `+0x44`.

**This screen (`FUN_004b11c0`) reads those records directly, not via the getter**: it
`rep movsd`-copies each record out of `DAT_0066afd0+0xa4` (`@0x4b1fd3`) / `+0x9c`
(`@0x4b20f5`), or rebuilds it from the club squad's persistent stores (`@0x4b2233`:
`rec[0..0x43] = playerobj+0x24`, `rec+0x3c = byte playerobj+0x23`,
`rec+0x44 = u16 playerobj+0x00`), into its own row vector at `screen+0xfd1c`. The
TEAM TOTAL row sums record dwords `+0x08..+0x40` (`@0x4b2398`).

## LIVE POPULATED WITNESS (2026-07-24) — the table is no longer unseen

`screenshots/wine-captures-2026-07-24-statistics-live/` — real MANAGER.EXE under wine,
fresh TOTAL-level Manager League career at Manchester Utd, Charity Shield vs Chelsea
(RESULTS mode). The half-time and full-time boards each expose a per-team **STATISTICS**
button; frames 02/03 are the two half-time tables, 05/06 the two full-time tables.

What the frames establish (read off the frames, nothing inferred):

- **`SHOTS` / `PASSES` / `TAC.` are `x/y` pairs** (made/attempted), so each consumes **two**
  record fields, not one. `MP`, `MIN`, `RATING`, `MoM`, `G.`, `S.`, yellow, red and injury
  are single cells. 15 cells total.
- **`MIN` is a real per-player field**, not a constant: at full time Solskjaer reads `45`
  while the rest read `90`; on the Chelsea sheet Petrescu reads `45`. (The 2026-07-24
  cadence work identified the mechanism: this is NOT a substitution but
  `FUN_00450510`'s event-minute branch — `bk >= 2` or a pending shot makes `+0xf0` the
  event minute instead of `+= dur`. Same mechanism froze Cole at 20' on his red card.)
- **`MoM` is `record+0x0c`** — decisive: the full-time board names **Wise (Chelsea)** MAN OF
  THE MATCH (frame 04) and *only* Wise's row carries `MoM = 1` (frame 05). That is exactly
  the field `FUN_0044d520` stamps (`rec+0xc = 1` where `rec+0x44 == DAT_0066afd0+0xac`).
- **`G.` is `record+0x10`** — Wise and Flo scored, both rows read `G. = 1`, team total `2`.
- **`MP` is `record+0x00`** — every row reads `1`, matching the accumulator's forced `1`.
- **TEAM TOTAL is a per-column sum for every cell from `G.` rightwards, and NOT a sum for
  `MP` / `MIN` / `RATING`.** Verified arithmetically on the Man Utd half-time sheet:
  SHOTS `7/9`, PASSES `12/35`, TAC. `7/30`, S. `6`, yellow `1`, G. `1` all equal the column
  sums exactly, while MP reads `1` (not 11), MIN `45` (not 495) and RATING `7` (not 54).
  This matches the disassembly, which computes `sum(rec+0x00)` and `sum(rec+0x04)` and then
  **discards both**, writing `[esp+0x2c]` / `[esp+0x10]` into the first two total cells
  (`@0x4b2398..0x4b2455`). The RATING total is `7` for Man Utd and `7` then `8` for Chelsea
  across the same match, so it is neither a sum nor a constant — **its source is the
  RATING formula applied to the totals record**, closed in `statistics_row_widget_re.md`.

### Column → record offset: CLOSED 2026-07-24
The row widget's draw method is `FUN_004afce0` and the full map is in
**[`statistics_row_widget_re.md`](statistics_row_widget_re.md)**. The positional reading
wins; the provisional `FUN_00450510` labels in `stat_match_engine_re.md` were the wrong
half of the conflict and are corrected there.

Two things the earlier note got wrong and this closes:

* the widget stride is **`0x444`**, not `0x41c` (the TEAM TOTAL is simply slot 19 of the
  same array: `screen+0xa7cc + 19*0x444 = screen+0xf8d8`);
* **RATING is not a stored field.** It is recomputed every paint as
  `4 + 6*((A+B+C+D)/4 + 10*min(G,10))/100` over four success ratios. That is why the
  TEAM TOTAL rating is "neither a sum nor a constant" — it is the same formula applied to
  the totals record. `tools/re/verify_statrow_rating.py` inverts it against all 24 rating
  cells in frames 02/06 and reports SURVIVES.

Injury is `+0x3c` (the draw skips `+0x42c`), matching this screen's own persistent-store
path which writes `rec+0x3c = byte playerobj+0x23`. `+0x38` and `+0x40` stay unnamed.

## Verification
`app/tests/test_statistics_screen.gd` (ALL PASS, headless): asset load, row list
= squad, 19-slot clamp on an over-full squad, Man Utd verbatim-title routing,
RETURN signal, paint pass.
`app/tests/test_season_stat_store.gd` (33 checks): the Career side — fold-back, both club
counters, row/total builders, JSON round-trip, legacy-save load.
**Pixel parity: 0 px** (see above) — measured under Xwayland with the GL renderer, which
is the acceptance bar for this screen, not the headless suites.
