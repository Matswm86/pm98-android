# M5 clk-9 divergence — a single EXTRA RNG draw, and the handoff's reference-pass error (2026-07-08, s28)

**Supersedes the "NEXT" of `M5_DIVERGENCE_CLK12_INTERCEPT_CLAMP.md` (s27).** That handoff said the
first remaining divergence was a "clk-16..27 cslot-8-vs-9 possession wobble" and the first big break
was "clk 115". **Both were measured against the WRONG reference pass.** Corrected below.

## Finding 0 — the reference timeline has TWO concatenated passes; the handoff diffed the wrong one

`data/pm98-m4-oracle/m5_traj_correctseed_2026-07-08/m5_traj_timeline.jsonl` (17,436 rows) is **two
full passes concatenated**:
- **Pass A** = rows 0..10003, `seed0 = 0xea0d2a8d` (3926731405), first goal **clk 2837 Villa 1-0** —
  this is THE authoritative correct-seed reference (matches capture2, per the dir's README).
- **Pass B** = rows 10004..17433, `seed0 = 3212901752`, a different/garbled run (goal at clk 0, 2-1).

A per-clk dedup that keeps the LAST row per clk (what s27 effectively did) pulls in **Pass B** rows
for clk 16..32, which is why s27 saw a phantom "possession flips to cslot-9" at clk 16 and a "self-heal
at clk 27". Against **Pass A only**, the port carrier is Villa slot-8 the whole time — no wobble.

**Rule for the future: split the timeline on `clk` going backwards (2 segments) and diff Pass A
(rows 0..10003) ONLY.** `tools/re` diff scripts must not clk-dedup across the whole file.

## Finding 1 — against Pass A, the ball is BIT-EXACT through clk 46; first divergence is clk 47

Diffing `diag_m5_tick_trace.gd` port CSV vs Pass A ball rows: `bx,by,bz` are **identical clk 0..46**.
First mismatch at **clk 47**: a lofted kick by Villa slot-8 (`setup_shot`, action 0x4):
- ref  v = `(-18465,-5568,3894)`
- port v = `(-17189,-5327,3691)`  (both magnitude AND direction off → an RNG-state difference, since
  `setup_shot` is RNG-heavy and the deterministic inputs at clk 47 are bit-exact).

## Finding 2 — the clk-47 shot is downstream; the ROOT is a single extra RNG draw at clk 9

Both engines run the identical MSVC LCG (`state*214013+2531011`), a bijection, so the seed is a global
draw-counter. Using `capture2/timeline.jsonl` (denser per-clk seeds than correctseed) as the oracle:

| clk | ref state (cap2) | port state | draws ref | draws port |
|-----|------------------|------------|-----------|------------|
| 7   | 3629482858       | 3629482858 (SAME) | 3 | 3 |
| 8   | 4049057575       | 4049057575 (SAME) | 3 | 3 |
| **9** | **1174984409** | **195608120 (DIFF)** | **2** | **3** |
| 10  | 1266482802       | (re-cadenced)      | 3 | 3 |

Port and reference are **bit-identical (RNG + every player position) at clk-8-end**. From that
identical state the **port draws 3 RNGs at clk 9, the reference draws 2** — one extra. Everything
downstream (incl. the clk-47 shot and the eventual clk-816 phase-1 stall) is this one draw compounding.

## Finding 3 — the extra draw is Bolton p9's press-roll in `offball_opp_b1500`

Per-tick call-site tally (`diag_m5_rng_callsites.gd`, caller-credited): clk 9 draws are
`2x Pm98Movement.gd:1050` (Bolton p4/p11 non-active wander, `_velocity_nonactive`→L107) +
`1x Pm98Movement.gd:6654` = the **`_rand_range_3c90(0,0x29999)` tackle-roll** in
`offball_opp_b1500`'s `if press:` arm. The presser is Bolton `p2c8=9` marking `mk = p2c8=14` (the
Villa kickoff receiver). `press = is_same(ball+0x4c, mk)`, and the port's `ball+0x4c = p14` at clk 9.

**EXPERIMENTAL CONFIRMATION (not committed):** temporarily skipping that one draw at clk 9:
- port clk-9 state → `1174984409` (== reference), cadence re-syncs clk 9..14;
- the clk-47 shot becomes **exactly `(-18465,-5568,3894)`** (bit-identical to Pass A);
- ball bit-exactness extends **clk 46 → clk 155**;
- the match now **reaches a goal (tick 1255)** instead of stalling in phase 1 at clk 816.

So the extra draw at clk 9 is definitively the root, and removing it is reference-faithful downstream.

## Why this is hard to FIX faithfully (open question for the next session)

The `offball_opp_b1500` press logic is faithful to the decompile (`fn_005b1500_FUN_005b1500.c` L35-64,
L98): with `carrier(ball+0x40)==0` it falls to the marked man and draws when `mk == ball+0x4c`. The
kickoff pass legitimately sets `ball+0x4c = receiver` (`Pm98Movement.gd:1792`, action-0x37 layoff),
and every `ball+0x4c = 0` clear in the decompile corpus is already ported. So on paper BOTH engines
have `ball+0x4c = p14` at clk 9 and BOTH should draw — yet the reference draws 2.

That means a transcription bug makes the port take a different branch at clk 9 **from bit-identical
inputs**. Two candidates remain, and the available reference data cannot disambiguate them (the
correctseed poller skips clk 9-11; capture2's `q` blob is only 64 bytes = ball 0x00..0x3f, so it never
captures `ball+0x40`/`ball+0x4c`):

1. **Engage-one-tick-early.** If the reference engages the ball (`ball+0x40 = receiver`) at clk 9
   (the port engages at clk 10 — the gate-4 catch-zone `g0[0]=46411 > 39319` at clk 9, passes at clk
   10 with `g0[0]=39129`), then at clk 9 `carrier != 0`, the receiver's lean clears `ball+0x4c`, and
   p9's press is false → no draw. Leaf: `_lean9490_slice_c` gate 4 / `_grid9490_build` /
   `_lean9490_aim_scalars` (the s22 hypothesis, now narrowed to a 1-tick, not 4-tick, lateness).
2. **Wrong marked man.** If `assign_markers` gives the p9-unit a marked man ≠ p14 at clk 9, then
   `press = (mk == ball+0x4c=p14)` is false → no draw.

**NEXT:** get the binary's `ball+0x40` and `p9+0x150` at clk 9 — either re-capture with a wider `q`
blob (extend `tools/re/wine/m5_poll_traj.py` to dump ball 0x00..0x60) or single-step the gate-4
catch-zone `g0` computation against the disasm. Do NOT ship a `clk==9`-gated suppression; it is a
symptom patch, not the faithful cause.

## Reproduce
- Ball diff vs Pass A: `diag_m5_tick_trace.gd` → CSV; python-diff `bx,by,bz` vs rows 0..10003 of
  `m5_traj_correctseed_2026-07-08/m5_traj_timeline.jsonl`. First mismatch clk 47.
- Draw-count oracle: LCG-distance between `capture2/timeline.jsonl` per-clk seeds vs the port CSV `rng`
  column. Port draws 3 at clk 9, ref draws 2.
- Call-site: `diag_m5_rng_callsites.gd` (its `_log_on` hook + `_rand_range_3c90` caller-crediting).
- Carrier/press state per clk: `app/tests/diag_m5_carrier.gd` (NEW this session).
