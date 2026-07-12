# M5 s34 — the clk-209 "+2-draw event" named, and the positional-drift layer under it

Continues `M5_RECEIVER_ALIAS_165C_FIX.md` (s33). Executed s33 NEXT-1: re-ran the
seed-global watch to clk 220 on the capture2 fixture (seed `0xea0d2a8d` poked at the
KICK OFF screen, 85/86 frame-0 bar, base `0x03dbf060` all three runs this session).

## 1. The clk-209 event, named

`seedwatch_clk220.jsonl` (1753 stops, clk 0-221; prefix byte-identical to s33's
clk-128 capture — 362/362 draws equal):

- Regular open-play tick in this window = 4 draws: wander x2 (`0x5a673d`),
  `0x5b2c15`, mark==controller press `0x5b184b`.
- clk 209 carries **6 draws**: the two extras are `ret0 0x5b2f67` + `0x5b2fae`
  with stack `[site, 0x5b4118, 0x5ee6c8]` — **FUN_005b2f30, the DART mover init**
  (duration roll + polar-angle roll), called from **FUN_005b3e50** (the roles-9/12/14
  own-possession leaf; call site ret 0x5b4118, line-94 tail call in the decomp).
- The same pair fires at clk 121, 182 (caller `0x5b548e` = FUN_005b5150) and 193
  (caller `0x5b4118`) — **the port matches all of those exactly**. Draw-index ladder
  (full-period LCG → indices): port end-index == ref end-index for EVERY clk 0-208,
  `-2` at 209-216, re-aligned from 217.
- So the port is NOT missing an arm: it fires the SAME dart init at **clk 217**
  (draw tags `t0.i9 Pm98Movement.gd:6097/6103`) — 8 clks late.

## 2. Why 8 clks late: the 0x17c gate crosses one matrix-refresh cycle late

Silicon constants verified in the decomp (`FUN_005b3e50`): early-out
`0x3ffff < p+0x17c` → midpoint steer; dart only when `p+0x17c <= 0x3ffff` AND
`planar_mag(gxm - p.pos) <= |ball.x - gxm| - 0xc0000`. Port constants identical.

`dartwatch_clk220.jsonl` (same fixture, run 2; `m5_gdbrsp_dartwatch.py` = seedwatch +
per-stop full-roster field dumps over clk 195-218) gives the silicon values for the
darting player **t0.i9** (Villa roster index 9, id 0x2c8 = 9); the port diag
(`app/tests/diag_m5_dart209.gd`) gives the port side. `p+0x17c` refreshes on the same
1-in-8 matrix cadence both sides (clk 201 / 209 / 217):

| refresh clk | silicon 0x17c | port 0x17c |
|---|---|---|
| 201 | 0x4f48c | 0x4db82 |
| 209 | **0x3fa39** (≤ 0x3ffff → dart) | **0x4055a** (> 0x3ffff → defer) |
| 217 | 0x3eb61 | 0x3c7fd |

The projection is the t0.i9 ↔ t1.i5 nearest-opponent pair (symmetric min; t1.i5
carries the same values). The inputs — both players' positions — had already
drifted port-vs-silicon. The dart skew is a SYMPTOM.

## 3. The layer underneath: no-draw-cost positional drift, per player, with onsets

`dartwatch_full218.jsonl` (run 3, window clk 0-218, players dumped at every draw
stop; draw stream byte-identical to runs 1-2). Phase-corrected diffing (players
processed after the tick's first draw are read at the NEXT clk's first stop —
avoids the s33 "sampling tear" false positives; t0.i0-i5 rows at clk 0 are
pre-placement artifacts, ignore):

| player | first pos divergence | signature |
|---|---|---|
| t1.i9 | kickoff tick, d=(5,-5) | whole movement schedule shifted **one tick early** in the port (port step at tick N == silicon step at tick N+1, verified N=1..19) |
| t0.i3 (id4 CB) | clk 1, d=(261,-4) | **wrong mover**: port runs it on the same +x accel ramp as t0.i4 (261,-4 / 523,-8 / … plateau 4736,-66); silicon parks it 2 ticks then creeps -x/-y (-184,-187 / -364,-379 / …) |
| t0.i9 | clk 13 (arm), placement off from the kickoff tick | silicon places it at (-26214,-39) tick 1 and holds 19 ticks, ramp (250,77)/tick starts tick 20; port holds at (-25964,38) — exactly ONE ramp step ahead — and ramps from tick 13 (**7 ticks early**) |
| t0.i4 (id4 CB) | clk 17 | same one-tick-early shift as t1.i9 (port tN == sil tN+1 for the whole ramp) |
| t0.i8 | clk 60 | d=(-253,-70), one step quantum |
| t1.i7 | clk 185 | d=(457,39) |
| t1.i5 | clk 201 | tiny; downstream of the pair drift |

Everyone else (t0.i0/i1/i2/i5/i6/i7/i10, t1.i0-i4/i6/i8/i10) is **byte-exact through
clk 218** — so this is NOT a global integrator bug; it is per-player ARM TIMING and
(for t0.i3) mover SELECTION at/after kickoff. This is the same territory as the
s30/s31 open item "roster act codes t1.i6/i9/i10" — now extended with exact onsets
and signatures for t0.i3/i4/i8/i9 + t1.i7/i9.

## 4. Where this leaves the ladder

- Draw-index parity: clean 0-208, the 209 dart is the FIRST RNG-visible symptom of
  the positional layer. Fixing the kickoff arm timing/mover selection should move
  the dart to 209 for free (the port's 17c at the 209 refresh lands 0x4055a vs
  silicon 0x3fa39 purely from the drifted pair positions).
- Do NOT patch the dart leaf: constants and structure are verified identical.

## Reproduce

- Run 1: `m5_gdbrsp_seedwatch.py <port> <lpid> <base> out.jsonl 220`.
- Runs 2-3: `m5_gdbrsp_dartwatch.py <port> <lpid> <base> out.jsonl 220 195 218`
  (or `219 0 218` for the full window). Drive per `tools/re/wine/README.md`
  §Reproduce; poke `m5_poke_frame0.py --apply` at the KICK OFF screen first.
- Port side: `~/godot462 --headless --path app --script res://tests/diag_m5_dart209.gd`.
- Data: `~/MWM-AI/data/pm98-m4-oracle/m5_seedwatch_2026-07-12/`.
