# M5 clk-47 draw gap — setup_shot EXONERATED; root = t1.i3 roster drift via the +0xb0 NULL-as-index-0 mark bug (s31, 2026-07-11)

Executes NEXT-1 of `M5_DIVERGENCE_CLK9_ROOT_FIX.md` (s30). The s30 framing ("the Villa slot-8
shot tick draws 5 vs 6 — single-step the FUN_005ac1a0 chain") was a red herring: setup_shot is
bit-exact. The missing 6th draw belongs to **t1.i3's per-clk wander**, killed in the port by the
Finding-2 roster drift — whose own root is a second instance of the s30 bug class (a binary NULL
pointer read as a valid index 0).

## Finding 1 — setup_shot is bit-exact; the clk-47 timing was a coincidence

- Port clk-47 draws (per-player attribution via the new gated `Pm98Rng._who` hook): all 5 are
  t0.i8 inside `setup_shot` (reach / weak-flag / yaw / pitch / landing). The ref's first 5 draws
  from the SAME clk-46 seed produce a **bit-identical ball**: pos + velocity at clk 47-50 match
  the wide-q capture exactly ((-67903,-82680) → (-86368,-88248) → …, vel (-18465,-5568,+3716)).
- The 6th ref draw is outcome-neutral for the ball and recurs **1/clk from clk 47 through ~117**
  (capture2 Pass-0 LCG deltas; the flight + the long run-up until t0.i6 receives at clk 118).

## Finding 2 — the ref's 1/clk is t1.i3's wander; the port lost it by WALKING him out of the band

- The `_velocity_nonactive` wander (move_dispatch L107-108, port line ~1040) re-arms p+0x54 and
  draws 1 rng — it fires when cond1 (`|x+anchor| > 0x13ffff or |y| > 0xbffff`) is true and cond2
  (`|x-anchor| > 0x13ffff or |y| > 0xbffff`) is FALSE and the team is not in possession. It moves
  nothing — a frozen player can draw it forever.
- REF: t1.i3 (Bolton role 4) is FROZEN at (2689965,-345555) from clk 0: cond2 = 1078355 ≤
  0x13ffff → **structural 1 draw/clk from clk 0**. Both engines matched through clk 46 because
  the PORT's t1.i3 — walking since clk 0 — happened to stay inside the cond2 band until exactly
  clk 46-47 (crossed 2457601 between the clk-45/46 tick starts). From clk 47 the port drew 0.
- So the "clk-47 gap" = the s30 Finding-2 roster drift becoming draw-visible. There was never a
  shot-chain bug.

## Finding 3 — why the port walked t1.i3: `+0xb0` NULL read as opp index 0 (the keeper)

`FUN_005b36f0` (select_mark_target) L20: `iVar6 = *(p+0xb0); if (iVar6 != 0)` — a POINTER null
test. `FUN_005a3400` slice B seeds +0xb0 from the opp descriptor's +0x13c table (NULL in live
sim: every frame-0 `+0x2cc` is -1). The port read `p.get(0xb0, -1)` as an opp INDEX → the raw 0
== "mark the opposing KEEPER t0.i0", and the scan fallback (`result = tgt_idx`, binary local_18)
returned it even when box-invalid. assign_markers then wired 0x150=0 → b1500's mark-follow arm
walked t1.i3 (and the other scan-eligible t1 players) toward keeper-derived mark points from
clk 0 — draw-free, position/act drift, the s30 Finding-2 signature.

**Fix (same convention as the s30 `_desig` resolver):** +0xb0 resolves pointer-style — a Dict
(fixture) resolves to its opp index; int 0/absent = the binary's NULL = none. Fixtures in
`test_marktarget.gd` / `test_assignmarker.gd` migrated to poke the target Dict (semantics
unchanged vs the real-binary oracle runs). Suites: marktarget 8/8, assignmarker 77/77.

## Finding 4 — team-ctx key-model mismatch: tactic block + active table invisible to readers

- `Pm98Match._build_team` wrote the squad header at DWORD-index keys `team[0xbf+k]` and the
  active table at `team[0x4f+slot]`; the movement-family readers use BYTE offsets
  (`_g(gs, 0x318)` defensive-line, `0x31c` aggression, `0x304`, `0x314`; decide_slice_b's
  `+0x13c + idx*4`). Every reader saw 0.
- Real frame-0 values (read from `capture2/frame0_full/regions/03b10000-03de0000.bin` at
  match_base 0x03dbf1c0 + 0x46c/0x78c): **t0 Villa 0x318=1, 0x31c=1; t1 Bolton 0x318=0,
  0x31c=1** (squad_header[7]/[8] in the existing import JSON — byte 0x2fc + k*4 ≡ dword 0xbf+k).
- Fixed with byte-offset mirrors in `Pm98Match._build_team` + all 13 frame-0 diag loaders
  (`team[0x2fc + k*4]` for the 9 header dwords, `team[0x13c + slot*4]` for the active table).

## OPEN — the dominant divergence is now the frozen t1 roster (inverted from before)

Post-fix the port's unmarked t1 outfielders (i1/i2/i4/i5/i6/i7/i10) FREEZE at kickoff (b1500
no-mark → anchor walk; anchor 0x1e0 == kickoff pos, both = mirror(slots 0x1f8..)) while the REF
walks them all from clk 0 (act 1→2, e.g. i1 drifts (−0.961,−0.277)·~1700/clk by clk 10; rays do
NOT converge on the ball/carrier/mark-points/pulled-anchors/box corners). Eliminated by direct
check: stale frame-0 marks (all NULL), the 3b20 pull for t1 (0x318=0 → gate |0−3768320| ≥
2·3768320/3 fails), extra b1500 no-mark arms (decompile tail == port), position_team (open-play
no-op, oracle-pinned), the 36f0 scan (reciprocity is geometry-correct: every t0 cand's nearest
t1 player is i8/i9 at kickoff — the binary would concentrate marks identically). Seeds now
diverge at clk 44 (port 3/clk vs ref 2/clk at 43-46) — meaningless until the t1 mover is found.

**NEXT: ground truth from the reference.** Wine-side write-watch on t1.i1 pos (t1base 0x03708a00
+ 0x3bc + 4) during clk 0-2 to NAME the mover function; then port/verify it. Only then re-run
the seedtrace ladder (diag_m5_seedtrace vs capture2 Pass 0, split + anchor-check 7/8/10).

## Session tooling added

- `MatchEngine.Pm98Rng._who` (gated per-player draw attribution; set by `Pm98Driver._advance_team`
  when `_log_on`), tags each draw "t?.i? file:line".
- `app/tests/diag_m5_clk47.gd`: tick-window state dump (ball ownership block, possession mirrors,
  per-player velocity-block gates), t1.i1/i3 mark/anchor detail, verbose 36f0 scan replica.

## Reproduce

- Draw attribution: `~/godot462 --headless --path app --script res://tests/diag_m5_clk47.gd`
  (set CLK_LO/CLK_HI; `_who` needs `Pm98Rng._log_on`, the diag flips it).
- Ref draw ladder: capture2 Pass 0 per-clk seeds → LCG step-count between consecutive clks.
- Descriptor truth: `frame0_full/regions/03b10000-03de0000.bin` @ 0x03dbf1c0+0x46c/0x78c+off.
