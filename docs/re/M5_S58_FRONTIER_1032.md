# M5 s58: the capture pushed to clk 1032, and the engine still does not move

s57 closed with the engine byte-exact over **clk 1-830** and one sentence for the next
session: *"nothing in the engine can be falsified further without a longer capture."* This
session took two. The port is byte-exact over **clk 1-1032**.

## The result

Against **all eight** banked Z2 captures in `~/MWM-AI/data/pm98-m4-oracle/capture2/`, one
single port dump, zero tolerance:

| capture | window | words compared | result |
|---|---|---|---|
| `oracle_dartwatch_s45_ext` | clk 1-303 | 8,289 | EXACT |
| `oracle_dartwatch_s47a_300_588` | clk 1-588 | 73,416 | EXACT |
| `oracle_dartwatch_s51_630_660` | clk 1-661 | 10,054 | EXACT |
| `oracle_dartwatch_s53_arm_630_660` | clk 1-661 | 13,464 | EXACT |
| `oracle_dartwatch_s55_555_655` | clk 1-656 | 42,369 | EXACT |
| `oracle_dartwatch_s55b_650_1250` | clk 1-830 | 75,583 | EXACT |
| **`oracle_dartwatch_s58_820_964`** | **clk 1-964** | **60,849** | **EXACT** |
| **`oracle_dartwatch_s58c_950_1032`** | **clk 1-1032** | **35,311** | **EXACT** |

**319,335 words, eight captures, zero mismatches.**

202 ticks of ground the engine had never been checked against, and not one word moved:
22 players x 16 fields, the ball x 10 fields, its 51-word `FUN_0058fda0` predicted-trajectory
tail, and the LCG state at every tick boundary.

## How the captures were taken (and the two things that cost time)

Per `tools/re/wine/README.md` §"Drive without stealing the owner's screen": a dedicated
`Xwayland :5` plus a fresh `PM98_DESKTOP`, so the harness never raises a window on the
owner's desktop. That part worked exactly as documented — both runs happened without
touching the live session. Sequence: `boot.sh` → `nav_kickoff.sh mats` (clean XI first try,
both times) → `winedbg --gdb --no-start --port N 0xWPID` → `m5_rsp_capture.py <port> <lpid>
frame0_struct_import.json out.jsonl <stop> <win_lo> <win_hi>` → click KICK OFF at (320,457).

**1. The base candidates missed on both boots** and the HOT-band scan ran (~4 min each). Add
each new base to the candidate list when it is observed; the scan is the safety net, not the
path.

**2. The stub died mid-run BOTH times — and the GAME did not.** No OOM entry in the journal.
After the first death a snapshot of the wine window showed MANAGER.EXE still happily playing
the 2D WATCH view at "Aston Villa 0-0 Bolton W". The capture jsonl is streamed line-buffered,
so everything up to the death survived intact — **that is the only reason this session has a
result at all.** Keep the streamed write; never buffer this file.

Re-attaching to the still-running game failed with `Can't attach process: error 5`, twice,
about a minute apart — different from the documented error 87 (a concurrent `wdbg_pid.sh`
probe). A dead stub appears to leave the process un-attachable, so every extension costs a
fresh boot + nav.

For the case where re-attach DOES work, `m5_rsp_capture.py` now honours **`PM98_NO_POKE=1`**:
it skips the frame-0 poke, the seed write and the frame-0 XI check, and only re-arms the Z2
watch. Use it ONLY on a game whose frame 0 was already poked and which has been free-running
the same trajectory since — re-poking a mid-match struct with frame-0 values destroys the run.

## Where the frontier is now

`+0x450 * 0x2d / +0x19ac` with `+0x19ac = 14400` puts **clk 1032 at match minute 3**
(1032 x 45 / 14400 = 3.2). The verified window is 7.2 % of one half, up from 5.8 %. The
`run_match_from_struct.gd` kill-test divergence (first goal 11' vs the reference 21') sits at
clk ~3500 vs ~6700 — still 3.4x beyond any capture, so it remains unattributable to the
engine.

The arithmetic is unforgiving: in-window capture runs at roughly **1 clk / 10 s**, so each
further minute of match time is ~90 minutes of wall clock plus a boot. Reaching the kill-test
divergence at clk ~3500 is ~7 hours of capture. That is the actual cost of the next falsifying
step, and it is a scheduling decision, not a research one.

## Still open (unchanged from s57)

1. The three `+0x43c` null sentinels (absent / 0 / -1) — behaviour-affecting.
2. The cross-seed sweep (`PM98_SEED` plumbing landed in s55) — still unrun.
3. The engine is still not the engine the app plays with (`MatchSim.simulate`).

## Reproduce

```bash
~/godot462 --headless --path app --import
PM98_CLK_LO=0 PM98_CLK_HI=1045 PM98_TICK_CAP=1130 \
  ~/godot462 --headless --path app --script res://tests/diag_m5_dart209.gd > port_1045.txt
C=~/MWM-AI/data/pm98-m4-oracle/capture2
python3 tools/re/m5_anchor_posdiff.py port_1045.txt $C/oracle_dartwatch_s58c_950_1032.jsonl 1 1032
```

Every capture must be diffed over an explicit `[1, hi]` window — clk 0 carries more than one
anchor stop, so a bare invocation trips the differ's own once-per-tick guard. That guard is
working as designed; it is not a failure of the run.
