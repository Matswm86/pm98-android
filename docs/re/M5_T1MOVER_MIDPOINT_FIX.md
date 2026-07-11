# M5 t1-freeze ROOT-FIXED — the b1500 no-mark steer target is MIDPOINT(ball, 3b20 anchor), not the anchor (s32, 2026-07-11)

Executes s31 NEXT-1/NEXT-2 of `M5_CLK47_WANDER_GAP_MARKS.md`: name the binary's t1 mover with a
live hardware write-watch, port it, re-run the seed ladder. Result: **seed parity moved from
clk 44 to clk 754** on a one-line target fix in `offball_opp_b1500`.

## Method — live hardware write-watch (new capability)

- Interactive winedbg `watch` is UNUSABLE on this no-debug-info target (wine-9.0): bare
  `watch *0x<addr>` → "No type or type mismatch" (an int constant has no pointer type);
  `(int*)` casts fail SILENTLY. The same i386 debug-register backend IS reachable through
  `winedbg --gdb --no-start --port N 0xWPID` + a raw RSP client speaking `Z2` (write
  watchpoint), `vCont;c`, and parsing the expedited registers out of the `T05` stop packet
  (zero extra round trips per stop). Tool: `tools/re/wine/m5_gdbrsp_watch.py`.
- Gotchas (all hit): plain `c` resumes only one thread — the game stays frozen (utime pinned);
  MUST send `vCont;c`. The stub accepts ONE connection ever. SIGTERM/kill of the stub KILLS the
  game (kill-on-exit). Attach must not race another winedbg (`wdbg_pid.sh`'s own probe) — error 87.
- Drive: capture2 procedure (boot → menu-drive → KICK OFF → `m5_poke_frame0.py --apply`,
  85/86 + seed 0xea0d2a8d) → arm Z2 on t1.i1.x (resolved live from `match_base+0x78c`,
  heap arrays move every run) → click KICK OFF → 972 stops to clk 3.
- Data: `~/MWM-AI/data/pm98-m4-oracle/m5_t1mover_watch_2026-07-11/` (watch_t1i1.jsonl,
  kickoff timelines, run1 phase-2-only capture).

## Finding 1 — the mover chain, named by the silicon

The ONLY writer that CHANGES t1.i1.x in open play stops at EIP `0x5a939e` = the position
integrate inside **FUN_005a8f20** (`p.pos += polar(speed, yaw)`; the +0x106/tick speed ramp
matches the observed dx ramp -252/-504/-756 exactly). Call chain per stop stacks + disasm:
**FUN_005b1500 @0x5b1b06 → FUN_005a89c0 → FUN_005a8bc0 @0x5a8ee9 → FUN_005a8f20**. The whole
trio was ALREADY ported and oracle-locked. ~20 other EIPs fire on the watch but only REWRITE
x with the same value each frame (0x5ee512 render family, 0x5b8690/0x5b1c40 families,
0x5a5460, 0x58fb50; placement SET at 0x5a3a07 = FUN_005a3400). Decompiles of all 73 touched
functions dumped via `DecompileAt` during the session.

## Finding 2 — the port bug: wrong steer TARGET in the no-mark arm

`fn_005b1500` no-mark fall-through, asm 0x5b1aa4-0x5b1b06 (Ghidra's decompile is misleading
here — the local_18/local_c association is wrong; the asm is unambiguous):

```
call 5b3b20                      ; eax -> pulled 3b20 anchor {x,y,z}
eax = (ball.x + anchor.x)>>1     ; cdq/sub/sar = TRUNCATING /2   (ball = [p+0x190]+4/8/c)
ebx = (ball.y + anchor.y)>>1
ebp = (ball.z + anchor.z)>>1
call 5b1330 (buf, p+0x210)       ; clamp the MIDPOINT into the roam box
call 5a89c0 (target, 0x5a)       ; steer
```

The port steered to `_clamp_roam(_anchor_3b20(p))` — the raw anchor. At kickoff the anchor ==
own pos → steer_8bc0 box-2 "arrived" zeroes speed every tick → the whole unmarked t1 roster
FREEZES (the s31 dominant divergence). The binary's target is the **midpoint of (ball pos,
anchor), roam-clamped** — far at kickoff → 8f20's ramp walks everyone from clk 0. It also
resolves the s31 "rays don't converge" puzzle: the target tracks the moving ball at half
distance. Hand-check: i1 (2239662,1417960), ball ~(0,0), roam-y-min 1096238 → clamped target
(1119831,1096238) → dir (-0.961,-0.276) — the s31-measured ref direction to 3 decimals.

Fix: `Pm98Movement.offball_opp_b1500` final arm now builds the truncating midpoint before
`_clamp_roam` (commit this session). One line of semantics; everything else was already true.

## Verification

- Port t1.i1 walks BIT-EXACTLY on the live-watch ground truth: x 2239662→(2238906 clk1)→
  (2238150 clk2)→(2237142 clk3), y 1417960→1417741→1417523, act 0→1; t1.i10 un-freezes;
  t1.i3 stays frozen with his structural 1 wander-draw/clk (ref-faithful).
- Suites all green, no regression: b1500family 589, 65a0openplay 760, engine_tick 182,
  9490 211, steering 132, decideB 100, assignmarker 77, b1420 16, marktarget 8.
- **Seed ladder (diag_m5_seedtrace vs s29 wide-q per-clk seeds): bit-exact through clk 754**
  (was clk 44). Isolated pre-755 mismatch rows (25, 751-753…) are mid-burst REF SAMPLING
  artifacts — an LCG cannot re-converge after a real divergence, and clk 27+/754 match.
- Positional diff vs wide-q pl tables: 10 players delta-0 at clk 3; movers differ by ~one
  tick of walk (the poller samples mid-clk; bursts drop rows) — consistent, not a port error.

## OPEN — next divergence frontier

- **clk 755**: first sustained seed divergence. Localize with the same ladder (LCG step-count
  around 750-760) + a targeted diag at that window; likely another unported/mis-modeled arm
  (first possession-change/tackle/out-of-play event region).
- The wide-q pl-table sampling offset makes fine-grained position diffs past clk ~4 fuzzy; if
  a positional oracle is needed, take a fresh watch/poll capture with per-clk boundary reads.
- Then resume the s31 ladder tail: roster act codes t1.i6/i9/i10, `ctx[0x1fc]` consumer
  (s30 NEXT-2), Android half-screen confirmation (s29 `6308a99`).

## Reproduce

- Watch harness: boot/drive per `tools/re/wine/README.md`, then
  `winedbg --gdb --no-start --port 47119 0xWPID` and
  `python3 m5_gdbrsp_watch.py 47119 <lpid> <base> out.jsonl 2 1` → click KICK OFF (320,457).
- Port walk check: `~/godot462 --headless --path app --script res://tests/diag_m5_clk47.gd`
  (CLK window 0..4; t1.i1 rows at t=26..28).
- Seed ladder: `diag_m5_seedtrace.gd` vs `m5_clk9_wideq_2026-07-11/clk9_timeline.jsonl`.
