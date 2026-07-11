# M5 clk-9: candidate 2 (wrong marked man) REFUTED — the cause is gate-4 engage timing (2026-07-11, s29)

Executes the NEXT of `M5_DIVERGENCE_CLK9_EXTRA_DRAW.md` (s28): re-capture the reference
with a wider `q` blob to disambiguate the two candidates for the port's extra clk-9 RNG
draw. Result: **candidate 2 is dead; candidate 1 (engage one tick early) is the cause.**

## New capture (authoritative)

`~/MWM-AI/data/pm98-m4-oracle/m5_clk9_wideq_2026-07-11/clk9_timeline.jsonl`, seed
`0xea0d2a8d`, produced with the s29 tooling:

- `tools/re/wine/m5_poke_frame0.py` — automates the s28 "poke seed + 5 pre-match flags"
  procedure by diffing the live KICK OFF-screen struct against
  `capture2/frame0_struct_import.json` (it re-derived exactly the s28 five:
  `+0x45c +0x19c8 +0x19e4 +0x19e8 +0x19ec`, skipping the benign `+0x1a5c` heap ptr;
  post-poke 85/86 + seed — the documented s28 fidelity bar).
- `tools/re/wine/m5_poll_traj.py` (extended) — every row now carries `q60` = ball
  `0x00..0x63` (so `ball+0x40` carrier and `ball+0x4c` receiver are on record), plus,
  while `clk <= 24`, `pl` = all 22 players' `[team, idx, slot, id2c8, act, mk(+0x150),
  x, y]`, polled in a no-sleep tight loop; optional `stop_clk` argv.
- `tools/re/wine/m5_clk9_analyze.py` — offline decode/decision helper.
- Fidelity: first goal **clk 2837 Villa 1-0** (== capture2/correctseed); overlapping
  per-clk seeds match s28's table (clk 10 = 1266482802).

## Finding 1 — clk 5..9 are UNOBSERVABLE from outside: WATCH runs clk 4..10 in one burst

In the capture, clk 3 (t=18.2696) → clk 10 (t=18.2701): the game executed SEVEN ticks
in ~0.5 ms of wall time (catch-up burst inside one render frame), after running clk 1..3
at normal ~16 ms cadence. No /proc poll rate can sample inside that burst — this is why
the correctseed run "skipped clk 9-11" and why the s28 NEXT's "sample EVERY tick clk
6..14" is physically impossible externally. Only flanking ticks (0..3, 10+) are
observable; burst boundaries vary per run.

## Finding 2 — the marker tables are IDENTICAL port vs reference at every observable tick

Reference (`pl` tables, clk 0..3 / 10 / 11):

| unit | slot | id2c8 | marks |
|------|------|-------|-------|
| t1.i8 | 8 | 9 | **t0.i8 = the Villa receiver** (t0.i9 the kickoff taker at clk 0 only) |
| t1.i9 | 9 | 9 | t0.i10 (never the receiver) |
| all other Bolton units | | | +0x150 == 0 (none) |

`ball+0x4c` (recv) = t0.i8 through clk 0..3; at clk 10 `ctrl` = t0.i8 and `+0x4c` = 0.

Port (`app/tests/diag_m5_markers.gd`, same frame0 + seed): **identical** — t1.i8 →
t0.i8 and t1.i9 → t0.i10 at clk 1..5 (stable through the window), recv = t0.i8 clk 1..9,
ctrl = t0.i8 & recv cleared at clk 10. The port's end-of-clk LCG states reproduce the s28
divergence in the same run (clk 8 = 4049057575 SAME, clk 9 = 195608120 vs ref 1174984409).

So the presser unit ("Bolton p9" in s28 = t1.i8, slot 8, id2c8 9 — id2c8 is a ROLE code,
not unique: Bolton slots 8/9/10 all carry id2c8=9) marks the SAME man in both engines at
every tick we can see, on both sides of clk 9. A transient reassignment at exactly clk 9
that restores itself by clk 10 would need assign_markers to flip twice in two ticks while
drawing zero RNGs (the reference's clk-9 draws are exactly the two Bolton wanderers) —
whereas the carrier state ALREADY differs one tick later in exactly the way candidate 1
predicts. **Candidate 2 refuted; candidate 1 stands.**

## What remains (NEXT)

The port's gate-4 catch-zone passes at clk 10 (`g0[0]=39129 <= 39319`) but fails at clk 9
(`g0[0]=46411`); the reference must pass it at clk 9 (engage → `ball+0x4c` cleared →
t1.i8's press arm in `offball_opp_b1500` never reached → 2 draws, not 3). The
transcription bug is in the gate-4 chain:
`_lean9490_slice_c` gate 4 / `_grid9490_build` / `_lean9490_aim_scalars`
vs `fn_005a9490` disasm. Single-step the g0 computation at clk 9 against the decompile —
the g0[0] delta (46411 vs a value <= 39319) from bit-identical inputs is now the ONLY
unexplained quantity. Do NOT ship a clk==9 suppression (unchanged from s28).

## Reproduce

- Reference side: `m5_clk9_analyze.py <capture>/clk9_timeline.jsonl` → fidelity line +
  per-clk ctrl/recv/mk table (needs a run's own `teams` event row for VA resolution;
  three Bolton units share id2c8=9, so resolve by slot, not id).
- Port side: `~/godot462 --headless --path app --script res://tests/diag_m5_markers.gd`
  (mk links are opponent INDICES, -1 = none; a raw frame0 0 aliases to index 0 = the GK,
  which is why only t1.i8/t1.i9 rows are meaningful there — matches the reference's
  null-vs-assigned split).
- Full harness drive: tools/re/wine/README.md; the s29 capture used Xwayland :2 headless.
