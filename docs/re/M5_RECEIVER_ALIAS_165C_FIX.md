# M5 s33 — the dead match+0x165c "mirror": receiver alias root-fixed; per-draw parity clk 0-128

Executes s32 NEXT-1 ("localize the clk-755 sustained seed divergence"). The localization
overturned s32's parity claim first, then a live seed watch named the missing draw site,
and the fix moved the true frontier from clk 89 to clk ~209.

## Finding 0 — s32's "parity through clk 754" was a zero-crossing artifact

Mapping every per-clk seed (port seedtrace + wideq rows) onto the LCG orbit as a DRAW
INDEX (seed → #draws since frame-0; MSVC LCG is full-period so indices are unique)
shows the port/ref cumulative draw counts drift apart from **clk 89** (+1/clk to ~+27,
plateau, partial give-back) and cross zero at clk 465 and 754 — the only two clks ≥ 89
where raw end-seeds matched. An equal SEED after unequal draw COUNTS is a crossing, not
parity. Lesson for every future ladder: **compare draw indices, never raw seed equality**
(`ref_idx(c) must fall inside the port's [end(c-1), end(c)] window`).

## Finding 1 — live seed watch: the missing draw is the b1500 press roll (0x5b19c7)

New capture (`m5_gdbrsp_seedwatch.py`, s32 stub procedure, Z2 on the SEED global
0x006d3184): every draw stops the game once; wine's Z2 fires on access, so each rand()
call yields 2 stops — eip 0x5ec255 (entry load) + eip **0x5ec271** (post LCG store =
the draw; `[esp]` = the drawing call-site, rand() has no frame). 885 stops, clk 0-129,
capture2 fixture, 85/86+seed frame-0 bar. Result per clk:

- clk ≤ 88: one steady draw/clk from **0x5a673d** (FUN_005a65a0 +0x54 wander refresh —
  the port has it, Pm98Movement.gd:1051).
- clk 89-114: a second draw/clk from **0x5b3ca2**, stack `0x5b19c7` = FUN_005b1500's
  mark==receiver press arm calling **FUN_005b3c90(0, 0x29999)** (base+rand()*spread —
  the tackle-range roll). The port NEVER ran this arm.
- clk 115+: control gained (t0 slot 6); the press site hands off to 0x5b184b
  (b1500 mark==controller arm) and the wander doubles — all already ported.

## Finding 2 — root cause: match+0x165c is ball+0x4c, not an index field

In the binary the ball block is EMBEDDED at match+0x1610, so match+0x165c IS ball+0x4c
(the designated-receiver POINTER) — one dword. The port remodeled m[0x165c] as a
separate INDEX mirror, but **no pass-path writer ever maintained it** (only two
`= -1` clears existed). Three consumers were reading a dead value:

1. `assign_markers._holds_ball` — pass B's "opponent holds the ball" test. The
   in-flight receiver never counted as a holder, so no marker was wired to him;
   t1.i8 fell to pass-C churn (mk 8 → 1 → cleared) instead of pressing the receiver.
   THE seed divergence: 1 missing draw/clk for the whole flight window.
2. `select_nearest` cond_B — the active never locked to the receiver during flight.
3. `Pm98Dispatch._case_buildup` — the seed-BEARING commentary-draw gate read
   `m[0x165c] != 0`; the -1 clear sentinel wrongly passed it (spurious draw), absence
   wrongly failed it.

Fix: all three read ball+0x4c from the ball Dict (identity compare / index resolve),
with the old index/int reads kept ONLY as the oracle-fixture fallback (fixtures poke
match keys and build no m["ball"] — same idiom as `_bm`).

## Verification

- **Per-draw ground truth**: port per-clk end seeds == live watch per-clk last-draw
  seeds for **every clk 0-128** (clk 129 row is the capture stop artifact). This is
  draw-count exactness, not sampled-row luck.
- Emergent timing honored: the port wires mk=6 from clk 76 (when pass B first sees the
  receiver) yet the press draw starts at exactly clk 89 — same as the silicon.
- Suites all green: b1500family 589, 65a0openplay 760, engine_tick 182, 9490 211,
  9490sliceB 111, 9490sliceC 171, steering 132, decideB 100, assignmarker 77, b1420 16,
  marktarget 8, movement 60, dispatch 366, selectactive 24+125, settlewire 39,
  restartdecide 122.
- Ladder vs wideq (draw-index windows): the clk 89-154 violation cluster is GONE.
  clk 25's lone violation is now PROVEN a wideq sampling/tear artifact (the live watch
  shows exact per-draw parity there).

## OPEN — next divergence frontier

- **clk ~209**: a one-time +2 draw event the port misses (ref jumps +2 vs the port
  window at 209-214, offset then holds ~constant) — a discrete 2-draw event around
  clk 208-209 (dispatch case-2? a timer expiry arm? a tackle roll pair?). Then the
  gap grows again from clk ~280.
- Same method applies: re-run `m5_gdbrsp_seedwatch.py` with stop_clk ≈ 220 and read
  the caller of the extra draws directly. ~15 min end-to-end.
- Then the s31 ladder tail: roster act codes t1.i6/i9/i10, `ctx[0x1fc]` consumer,
  Android half-screen confirmation.

## Reproduce

- Live watch: boot/drive per `tools/re/wine/README.md` (menu coords in README §Reproduce),
  `m5_poke_frame0.py --apply`, `winedbg --gdb --no-start --port 47119 0xWPID`, then
  `python3 m5_gdbrsp_seedwatch.py 47119 <lpid> <base> out.jsonl <stop_clk>` and click
  KICK OFF. Data: `~/MWM-AI/data/pm98-m4-oracle/m5_seedwatch_2026-07-12/`.
- Port ladder: `diag_m5_seedtrace.gd`; window state: `diag_m5_flightmark.gd`.
