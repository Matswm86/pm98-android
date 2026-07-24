# M5 s53: the b1420 arm holds, the steer order matches — the b0040 HEADING is the fork

Closes both s52 next-session hypotheses with live silicon. Two captures, both on a run that is
byte-identical to the banked s51 reference (same 5677 stops, same `0x34/0x64/0x68` ladder, same
positions).

Evidence: `tools/re/specs/b1420_arm_steer_s53.txt`.
Raw: `data/pm98-m4-oracle/capture2/oracle_dartwatch_s53_arm_630_660.jsonl`,
`data/pm98-m4-oracle/capture2/steer8f20_s53_634_646.jsonl`.

## 1. Capture A — the designate never moves (s52 hypothesis 1: DEAD)

`m5_rsp_capture.py` now records the whole `FUN_005b1420` gate: per player
`[+0x184, +0x5c, +0x2b8, +0x2bc, +0x2d7, +0x2d8]`, per team `+0x1fc/+0x200/+0x204` (resolved to
`[team, idx]`) and `+0x2ee`, plus `sub_fa0` = `*(match+0x468)+0xfa0`. Read with
`tools/re/m5_b1420_arm_solve.py`:

```
clk | 0x34   0x64   0x68 | gs204   | guard | carrier | own/team | 2ee fa0 | arm   | pos
630 | 18046 28286      0 | [1, 10] |  111  | 0x0     | 0/1      |   1 4   | B0040 | (347925, -1842546)
639 |  9258  9258   1310 | [1, 10] |  111  | 0x0     | 0/1      |   1 4   | B0040 | (350402, -1839495)
643 |  5162   765    262 | [1, 10] |  111  | 0x0     | 0/1      |   1 4   | B0040 | (351448, -1838509)
657 |   762   762   3930 | [1, 10] |  1    | 0x0     | 0/1      |   1 4   | B0040 | (382535, -1836173)
```

`*(gs+0x204) == t1.i10` at **every** clk 630-657 and `ball+0x40 == 0` throughout, so live
`FUN_005b1420` takes the **B0040 arm on every tick** — exactly like the port. The designate does
not move, and no other arm ever fires. The team-header model is confirmed too: every player's
`+0x184` on a side points at the same object (`header_split = 0`, checked across both XIs).

## 2. Capture B — the steer ORDER is identical (s52 hypothesis 2: DEAD)

`m5_rsp_steer8f20.py` (new) free-runs on the seed watch to clk 634, then arms `Z1` on
`FUN_005a8f20` and logs every entry: `ECX` = `this`, `[esp]` = the caller, `[esp+4]` = the heading
argument, and `P+0x2d7` **before** the function writes it.

Live silicon makes exactly **44 calls per tick** = 22 players x 2, and t1.i10's two are always:

| # | caller `ret0` | guard before | outcome |
|---|---|---|---|
| 43 | `0x5a8eee` (the `b0040 -> 89c0 -> 8bc0` chain) | **0** | **APPLIED** |
| 44 | `0x5a4fae` (engine_tick's body-orient steer) | 1 | no-op |

The port's `app/tests/diag_m5_t1i10_steerdump.gd` prints the same two, in the same order, with the
same guard values — `_move_b0040 -> steer_89c0 -> steer_8bc0 -> steer_8f20` first and applied,
`engine_tick -> _move_8f20` second and no-op. **Nothing consumes the guard early in either build.**

## 3. What the fork actually is

The applied heading, straight off the wire (`[esp+4]` at the `0x5a8eee` call):

```
clk  | 634  635  636  637  638 | 639 | 640 | 641 642 643 644 645 646
sil  | 9258 9258 9258 9258 9258 | 771 | 767 | 765 765 765 765 765 765
port | 9258 9258 9258 9258 9258 |34076|34078| 34078 …
```

Both agree exactly while the interception solves, then diverge on the single tick where the port's
lead overflows. The port's lead at that tick is `-1 040 510 322` (the i18 signed wrap, s50 §3),
which clamps to the `-corner` and yields 34078; silicon stays on a small positive ray (771 -> 765,
lead ~= 1.29e6, well inside the pitch box).

So every routing question is now closed:

* the arm is the same (B0040), verified live;
* the call chain is the same (`0x5a8eee`), verified live;
* the order and the once-per-tick guard are the same, verified live;
* the b0040 *inputs* are byte-identical (s52 §4), and the marker-adjust arm and `curve_rate` are
  both dead (s52 §4).

The remaining difference is **inside the lead computation of `FUN_005b0040` itself on the overflow
tick** — the port wraps where silicon does not. s50's PCode oracle locked b0040 as a function, so
the next session has to re-run that oracle **with the live inputs of this exact tick** and compare
the intermediate lead, not the final point: either the emulation diverges from silicon there
(x87 vs integer), or an input that the oracle feeds differs from the live one.

No engine change is shipped here. Per the locked no-invent rule the target source is identified
one level deeper than s52 had it, but the wrap itself is not yet explained.

## 4. Harness fixes this session (all cost a run before they were found)

* **Concurrent sessions collide.** One wineprefix = one wineserver, and `explorer /desktop=<name>`
  reuses an existing desktop of that name, so a second boot on another DISPLAY dies with
  `X Error … BadWindow … X_CreateWindow`. `env.sh` now honours `PM98_WINEPREFIX` / `PM98_DESKTOP`,
  and `wdbg_pid.sh` picks the LPID whose `/proc/<pid>/environ` carries that prefix.
* **The base moves with the WINEPREFIX path length** — a copied prefix landed the match struct at
  `0x03dcf1d0` instead of `0x03dbf0d8`, so the stored candidates missed and the fallback mem scan
  ran (~20 min per 2 MB over RSP). The scan now probes `0x03d00000-0x03e00000` first; every
  observed base (`0x03dbf060`, `0x03dbf0d8`, `0x03dbf228`, `0x03dcf1d0`) is in that band.
* **An XI mismatch is fatal, not cosmetic.** A run whose XI differed only in t0.i9's derived
  pace/stamina (`+0x37c/+0x380`, from the preseason condition roll) produced a completely different
  match — t1.i10's ladder came out `63979/58859` at clk 630 against the banked `18046/28286`. The
  capture now ABORTS on mismatch (`PM98_XI_FORCE=1` overrides).
* **Never remove a watchpoint mid-run.** `z2,<seed>,4` while the target sits on a seed trap KILLS
  winedbg's gdbproxy. Leave the Z2 armed and filter stops by EIP.
* `nav_kickoff.sh` (new) drives title -> KICK OFF unattended, detects the modal alert by pixel and
  aborts the roll when the preseason injury roll rejects the line-up.

## Files

* NEW `tools/re/wine/m5_rsp_steer8f20.py`, `tools/re/wine/nav_kickoff.sh`
* NEW `tools/re/m5_b1420_arm_solve.py`, `tools/re/specs/b1420_arm_steer_s53.txt`
* NEW `app/tests/diag_m5_t1i10_b1420.gd`, `app/tests/diag_m5_t1i10_steerdump.gd`
* EDIT `tools/re/wine/m5_rsp_capture.py` (gate fields + XI abort + HOT-band scan),
  `tools/re/wine/env.sh`, `tools/re/wine/boot.sh`, `tools/re/wine/wdbg_pid.sh`,
  `tools/re/wine/README.md`
* EDIT `app/scripts/Pm98Movement.gd` — diag-only `steer8f20_trace` (gated on `Pm98Rng._log_on`,
  same idiom as `steerhdg_trace`); no behaviour change.
