# PM98 — COMPLETE AUDIT (2026-07-26)

> Full-project audit against the binding rule (faithful port of the real Premier Manager
> 98 PC game, no invented content). Performed read-only at HEAD `4076800` (2026-07-26,
> clean tree): 64 scenes, 120 RE docs, 321 test scripts, 20 manual parity gates.
> Every load-bearing claim below was verified against code, not prose.
> Companion: [`AUDIT_season_playthrough_2026-07-25.md`](AUDIT_season_playthrough_2026-07-25.md)
> (the whole-season model audit, rescued into the repo the same day as this file).

## 1. NEW FINDING — the cup/Europe views ship gameplay-unreachable

The knockout and European screens built and 0px-verified over 07-25/26 cannot be reached
by a player in a real career:

- `Main.gd:3631 _show_competitions()` has **zero callers** repo-wide. Its docstring says it
  belongs on the hub CALEN/fixtures icon, but that icon routes to `_show_fixtures_screen()`
  (RESULTS + LEAGUE TABLES only).
- `_open_competition()` (Main.gd:3695) is called only from inside `_show_competitions()`.
- `_show_cup_screen()`'s only other callers (Main.gd:572/585/592/622/647) are all inside
  `_cup_shot()` — the `PM98_CUP_SHOT` dev-shot harness.
- `ResultsScreen.gd` declares exactly one signal (`back_pressed`); the competition rail is
  baked, inert chrome. `KnockoutScreen.competition_selected` is never connected in `Main.gd`.

**Unreachable in gameplay:** `KnockoutScreen` (LIST, 0px), `EuroGroupScreen`,
`EuroSupercupScreen`, `CompResultScreen`, and the SEASON FIXTURES browse.
**Reachable:** `CupDrawScreen` (post-week `_pop_cup_draw` chain, the 07-25 S1 fix) and
`CharityShieldScreen` (season open/end chains).

The original-true entry point is the RESULTS competition rail — the `KNOCKOUT_RAIL` map
(Main.gd:4223) already encodes bracket-key → rail-chip. Wiring it belongs with the BRACKET
build (s61 work list item 1), not with this audit.

**Fully dead code:** `CupScreen.gd` (197 lines — sole consumer `_show_one_off_final()`,
Main.gd:4142, itself never called; superseded by `CompResultScreen`, see
`CompResultScreen.gd:22`) and the interim `_show_training()` browse (Main.gd:4892,
dev-harness only, superseded by `TrainingScreen.gd`).

## 2. Invented-screen register (the "any invented screens?" answer)

**Invented screens: one**, approved and self-declared.

| Item | Status |
|---|---|
| `HonoursScreen.gd` (HONOURS + CAREER RESUME) | **OURS**, approved 2026-07-25 (`SPEC_ours_additions.md` item 1); entered via a plaque the original leaves inert, so MANAGER HISTORY keeps its 0px parity |
| THREE UP FRONT row (`MatchOptions.gd`) | Invented pixel-site, approved; MANAGER_HACK.EXE cheat port, default OFF, OFF is bit-identical to stock; bounded by `diff_options_parity.py` |
| SCOUT door label (`ScoutScreen.gd`) | Invented pixel-site, approved 2026-07-26; state-split so it covers no pixel the original draws; bounded by `diff_scout_bar_parity.py` |
| `BrowseScreen.gd` green DB-navigation tree | Invented *surface* (no single original counterpart), live only in DATA BASE mode navigation |
| 7 legacy green `_set_view` ItemList views + interim training browse | Invented, but **gameplay-unreachable** (dev harness only) |
| `CupScreen.gd` | Invented, orphaned, dead (see §1) |
| FinanceScreen 5-tap cash gesture | Hidden cheat, user-requested, draws nothing |

**Invented geometry inside otherwise source-true screens** (all declared in-file or in docs):
`MatchSimulador` layout/camera/per-tick positions (app substitute — `PCF5DAT.PKF`
un-enumerable, gap A6); `TeamTacticsScreen` (un-walked, honest source gap);
`MatchCommentary` fabricates non-goal BRIEF events (rates/minutes/possession/cards — only
M5 wire-in fixes this); the fixture **pairing order** (dates are a source GAP, the pairing
is ours, audit O2).

Everything else traces to source. The de-invention record (`SPEC_BINDING.md` §6) holds.

## 3. Working as the original? — open model divergences

- **M5 not wired (the critical path).** Matches are played by `Pm98StatMatch` (byte-exact
  instant-result port) via `MatchSim`; the instruction-exact positional engine is ported and
  oracle-locked but not called from gameplay. Byte-exact frontier: clk 1–1032 (~match minute
  3, 7.2% of a half; 319,335 words, 0 mismatches). Kill-test diverges (first goal 11' vs
  21'); capture past 1032 is its own ~7h session; cross-seed sweep unrun.
- **S3 OPEN — careers are not seed-reproducible.** 12 `randomize()` sites in `Career.gd`
  (500, 528, 1467, 1988, 2187, 2250, 2388, 2629, 2742, 3292, 4052, 4109). Not a fidelity
  bug (the original reseeds from `time()`), but it breaks the port's own acceptance
  machinery: save/load equivalence, the M5 kill-test, any seeded parity claim.
- **S5 OPEN — European ties on the invented engine.** Foreign clubs fail `_usable`, so
  `MatchSim.gd:105-110` falls back to the legacy `MatchEngine` (~37 warnings/season).
  `test_career.gd` passes because it only checks the manager's own league.
- **S8 OPEN — no retirement / ageing intake.** No retirement mechanic exists in
  `app/scripts`; multi-season careers age into a dead end. Blocked on reversing
  `FUN_005865b0` / `FUN_005c1df0` / `FUN_00443180`.
- Smaller opens: sacking threshold (>3, unmeasured), Coca-Cola home TV fee (£0, flagged),
  weekly-illness path, insured-row document icon, O1 (objective is a category, port shows a
  position), O3 (club manager names on START OF SEASON), S7 remainder (European field
  24/6-groups/2-qualifiers unconfirmed).
- **Closed and witnessed-true:** the economy (07-25 rebuild: ~+£189k home / −£238k away,
  £7.50 ticket), lower-division 46-round seasons, U.E.F.A. Cup winner, cup-draw
  draw-then-play, per-club ground pricing, MINIBAND dither, name casing (1,272 players).

## 4. What is left (build queue — s61 handoff is authoritative)

1. Knockout **BRACKET** (fully specified 07-26; `verify_bracket_split.py` PASSES) →
   semifinal cards → final → **wire reachability** (§1).
2. Kit-outline pass (173 edge samples on the bracket); top-level MINIESC bank mismap.
3. **M5 capture session** (~7h, own session) → kill-test attribution → engine wire-in.
4. MAN-TO-MAN MARKINGS (the last hub gap); MIXED PLAY (blocked on the club-tactic byte).
5. Android: real-device pass, icon/splash, signed release. **A full 321-suite sweep has
   never run to completion**; CI has no test gate (`build-android.yml` exports only;
   `screenshot.yml` steps are all `|| true`) and all 20 parity gates are manual.
6. Never-implemented original screens (low priority or blocked): MULTAS, SECRETARIO,
   CREDITOS, TV, HIGHLIGHTS/3D (hard gap — no `.p3d` on either source), SELECCIONPRO,
   SININFO, the European entry alert, a TEAMS IN CHAMPIONSHIPS route, XI photo-roll
   verification, the animated 2D JUG view (deprioritised by Mats 07-01).

**Gated on Mats, do not start:** the SHOOTING appendix (NOT APPROVED, asked 3×); the
modern-era data pack (NOT authorised).

## 5. Evidence & reproducibility gaps

- The walkthrough is **638 PNGs on disk** (601 unique by md5; three capture runs with
  colliding indices), not the "479 frames" figure in circulation and not the 639 in
  `APP_VS_SPEC_AUDIT.md` §B6. Citations must keep the `_HHMMSS` suffix.
- **No frame→screen manifest exists** for the walkthrough; only ~121 frame IDs (~19%) are
  cited anywhere. The screen inventory lives as prose in `APP_VS_SPEC_AUDIT.md` §B6.
- `screenshots/`, `out/`, `scratchpad/` are **gitignored** — no parity gate is reproducible
  from a clone. (s61 started banking key refs under `tools/re/refs/`; that pattern should
  continue.)
- There is **no stored gate-results ledger** — pass/fail truth is the prose `Status:` line,
  and only ~12 of 120 RE docs carry one. Known failure mode: "0px shot-parity ≠ live
  parity" (the STAFF wages case, `APP_VS_SPEC_AUDIT.md` §C5) — a 0px claim without a live
  re-drive is a claim about the baked state.

## 6. Doc rot found (fixed where marked ✓)

| Doc | Problem | |
|---|---|---|
| `SPEC_BINDING.md` §5.5/§5.7/§5.8 | listed open but closed (DBC 476/476 07-06; country exact 07-06; season loop 07-25) — §5.5/§5.7 contradicted by §2/§3 of the same file | ✓ |
| `SPEC_BINDING.md` §4 | "All 20 game screens" vs 63 shipped; table omits every screen since ~07-02 | ✓ banner |
| `season_end_sequence_re.md` | Status said steps 3/4/6 NOT BUILT; all three shipped 07-25 at 0px | ✓ |
| `APP_VS_SPEC_AUDIT.md` §B1/§B2 | SAVE GAME = STUB (shipped 07-18); missing-screen list names ≥6 screens that now exist | ✓ banner |
| `REMAINING.md` §1 | said matches run on the abstracted engine; actually `MatchSim` routes to `Pm98StatMatch` when both XIs are usable — hides the real risk (S5) | ✓ |
| `REMAINING.md` | truth table cited s57 (superseded by `M5_S58_FRONTIER_1032.md`); suite count 219 vs 321 (224 `test_*`) | ✓ |
| `REMAINING.md` | S3/S5/S8 and the §1 reachability finding were absent entirely | ✓ |
| `ROADMAP.md` | June-era: Phase 0 "IN PROGRESS" for long-finished work; "decide engine at Phase 2" | ✓ banner |
| `REFRUN_manutd_1997-98.md` | STATUS block says all shipped; item 4 body still says three screens missing (STATUS is correct) | — |
| `ChannelTvScreen.gd` | the only screen with zero test coverage | — |
