# M5 s35 — kickoff arm timing ROOT-FIXED: dead gs+0x200 in the role-4 leaf + the taker faces the PARTNER

Executes `M5_DART209_POSDRIFT.md` (s34) NEXT-1. Two root causes found and fixed; the
clk-209 dart-init pair now fires at 209 in the port, per-clk draw counts match the
silicon seedwatch over its ENTIRE window (clk 0-218), and the per-clk seed ladder vs
capture2 Pass 0 extends from the 209 region to **clk 272** (first persistent
divergence clk 273). All oracle suites GREEN (2513 checks / 11 suites); the s26
kickoff ball velocity (-1251,-4777) is unchanged.

## Fix 1 — `_role_leaf_4f70`'s dead `gs+0x200` read (the s30 `_desig` class)

`fn_005b4f70` non-carrier (roles-4 own-possession leaf, L62-75): target = endpoint2,
but when `p != *(gs+0x200)` (the nearest-to-anchor designate, a PLAYER POINTER) the
binary snaps `target.x = desig.x` — NO null check, unconditional deref. The port read
the slot raw (`gs.get(0x200)` + `is Dictionary`), and `_select_roles` stores an int
index → the override was DEAD CODE, exactly the class s30 fixed in b1420/b1500 —
this leaf was the missed sibling. t0.i3 (the first role-4 CB) therefore steered to
its own far endpoint2 (t0.i4's +x accel ramp shape) instead of creeping to the
designate's x. Fixed with the same `_desig(gs, 0x200)` resolver.

**Effect (dart209 diff, tear-safe):** t0.i3 AND t0.i4 byte-exact through clk 217
(both were drifting; i4's "one-tick-early" was downstream of i3's wrong steer
through the pair matrices).

## Fix 2 — the kickoff taker faces the PARTNER, not the restart spot

`kickoff_partner_placement` (FUN_005b70e0 tail) re-faced the taker toward the
restart spot: `tface = atan(spot - taker)` ≈ 0x0008 at kickoff. The Ghidra decomp
hides the `__thiscall` ECX of `FUN_00590ae0` (= `this - src` vec sub); the raw disasm
at `0x5b72ea` is `mov ecx,esi` where esi = **the partner's position vec** (ebp+4):

```
5b72e7: lea eax,[ebx+4]      ; src = TAKER pos      (ebx = team+0x168 = the taker)
5b72ec: mov ecx,esi          ; this = PARTNER pos   (esi = partner+4, post-teleport)
5b72ee: call 0x590ae0        ; dst = partner - taker
5b72fa: call 0x5ee080        ; atan -> taker +0x34 AND +0x64
```

With the partner at (-26214,-98304) and the taker at (-26214,-39): tface =
atan(0, -98265) = **0xc000**, then the goal blend (+0x34 only) gives **0xe000** —
both live-verified this session (armwatch2: silicon taker +0x64 = 0xc000,
+0x34 = 0xe000, held through the act-4 kick anim).

**Why this was the 7-tick skew:** both engines exit the act-4 anim at clk 13
(armwatch: 2c wraps identically; the s34 "anim length" framing was wrong) and both
arm the 3e50 midpoint steer that tick (silicon 6c = 7018 at clk 13). But steer_8f20
ramps speed (+0x106/tick) only when |s16(heading - facing)| < 0x1555. Port facing
0x0008 → gap ~0xc00 → ramp IMMEDIATELY (walk from clk 13). Silicon facing 0xe000 →
gap 0x2be7 → 6 ticks of 0x400/tick turn-in-place (speed decays at 0x1ca) before the
ramp gate opens → first step clk 19/20. The port's early walk drifted the
t0.i9↔t1.i5 pair projection, pushing the +0x17c dart gate over 0x3ffff at the 209
matrix refresh — the whole s34 dart skew.

**Effect:** t0.i9 byte-exact through clk 79; the dart pair fires at clk 209; draw
ladder clean 0-218 vs the seedwatch.

## New instrumentation

- `tools/re/wine/m5_gdbrsp_armwatch.py` — seedwatch + per-stop roster dumps of
  (x, y, +0x40 act, +0x2c frame, +0x30 subtick, +0x48, +0x54, +0x58, +0x80, +0x84,
  +0x34 facing, +0x64 yaw, +0x68 speed, +0x6c curve) over a clk window. clk 0 alone
  spans ~24 engine ticks / ~63 stops, so kickoff transitions resolve per stop.
- `app/tests/diag_m5_takerarm.gd` — port counterpart (same fields per tick, plus a
  per-tick steer-target trace via the new gated `Pm98Movement.steer_trace` hook in
  steer_89c0, `Pm98Rng._log_on` keyed, zero cost live).
- Captures: `~/MWM-AI/data/pm98-m4-oracle/m5_seedwatch_2026-07-12/armwatch_clk25.jsonl`
  (run 4) + `armwatch2_clk25.jsonl` (run 5, extended fields). Both draw-stream
  byte-identical to the s33/s34 runs. NOTE run-5 drive: one aborted attempt hit a
  random "Johansen injured" event that invalidates the fixture lineup — re-drive
  until the hub shows no popup; also the match base moved (0x03dcf060), so re-run
  `m4_findbase.py` every drive and NEVER reuse a prior base for the poke.

## Residual drift tail (all one-quantum onsets; next session)

| player | first divergence | note |
|---|---|---|
| t1.i9 | clk 1, d=(5,-5) | port schedule one tick early (b1500 side) |
| t0.i8 | clk 60, d=(-253,-70) | one step quantum (receiver) |
| t0.i9 | clk 80, d=(-251,-72) | one ramp-step quantum (was clk 13) |
| t1.i7 | clk 185, d=(457,39) | |
| t1.i5 | clk 201, tiny | downstream of pair drift |

Next RNG-visible symptom: per-clk seed ladder first persistent divergence **clk 273**
(port one draw-set behind the reference from 273 — ref end-of-273 seed == port
end-of-274). The same arm-timing/facing class is the prime suspect (t1.i9's one-tick
shift feeds the t1 matrices).

## Reproduce

- Port: `~/godot462 --headless --path app --script res://tests/diag_m5_dart209.gd`
  (draw ladder + roster), `diag_m5_takerarm.gd` (kickoff counters + steer trace),
  `diag_m5_seedtrace.gd` (per-clk seeds vs capture2 Pass 0 — split the two passes,
  anchor-check clk 7/8/10).
- Silicon: drive per `tools/re/wine/README.md` §Reproduce, `m5_poke_frame0.py --apply`
  at KICK OFF (expect 85/86 + seed), then
  `python3 m5_gdbrsp_armwatch.py <port> <lpid> <base> out.jsonl 26 0 25`, KICK OFF 320,457.
