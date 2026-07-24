# Stat-commit cadence — the two branches of FUN_0044ee70 (RE, CLOSED 2026-07-24)

Status: **CLOSED.** This settles the contradiction logged as §5 of
`handoff-pm98-statrow-foldback-clauses-2026-07-24`. Nothing about the
`FUN_0044e440` oracle was wrong — the live sheets simply did not come from the branch
the port implements.

## The contradiction as it stood

Two facts collided and neither could be bent:

* `FUN_0044e440` (the stat commit) **unconditionally zeroes** participant
  `+0xec..+0x12f`, and `FUN_00449990` **overwrites** the report record with a
  `rep movsd` of 0x12 dwords. Both re-verified here instruction by instruction
  (`@0x44e7ad..0x44e7e0`, `@0x449a50`). `FUN_0044d0d0`, the half-time transition, calls
  the commit as its third instruction, unconditionally (`@0x44d0d3`). Both halves feed
  `FUN_00450510` with `dur = 0x2d` (`push 0x2d` at `@0x44f908` and `@0x44fc1d`), and
  `+0xf0` (MIN) is a `+= dur` (`@0x450786..0x450795`). **A full-time record must
  therefore hold the second half only, and MIN must read 45.**
* The live full-time sheet reads `MIN = 90` and every column `>=` its half-time value.

## The fork

`FUN_0044ee70` branches at `@0x44eed9`:

```
@0x44eed9  mov  eax, [0x652a10]
@0x44eede  cmp  eax, edi            ; edi = 0
@0x44eee0  je   0x44f5ce            ; -> the STATISTICAL branch
@0x44eee6  cmp  [ebx + 0x7f0], edi  ; per-team flag, side 0
@0x44eeec  jne  0x44eefa
@0x44eeee  cmp  [ebx + 0xf90], edi  ; per-team flag, side 1
@0x44eef4  je   0x44f5ce            ; both zero -> the STATISTICAL branch
@0x44eefa  ...                      ; the PRESENTED branch
```

`0x44f5ce` is the branch this project ports. **All four** `FUN_00450510` call sites
(`@0x44f90a`, `@0x44fc21`, `@0x44ff46`, `@0x450235`) and all four period-transition
commits (`FUN_0044d0d0/d190/d250/d310`) live inside it. The presented branch at
`@0x44eefa` calls `FUN_0044cd10` and then pumps an event loop; its own commit sites are
`@0x44f2b0`, `FUN_0044d3d0 @0x44d4d5` and `FUN_0044d520 @0x44d526`.

## Which branch the live sheets came from — measured, not argued

`DAT_00652a10` read out of the **running career** on 2026-07-24 (winedbg's gdb proxy,
raw RSP `m652a10,4`, against the live MANAGER.EXE that produced the captures):

```
0x00652a10 0x00000001
```

Non-zero. So the manager's own fixture takes the **presented** branch, and the
statistical branch's commit-and-zero cadence never applied to it. `FUN_0044e440` and its
oracle are correct; they describe the branch that runs **CPU-vs-CPU background
fixtures**, where a full-time record does hold the second half only.

## The presented branch's contract — measured off two matches

Captures: `screenshots/wine-captures-2026-07-24-statistics-live/` (Charity Shield,
Man Utd v Chelsea) and `screenshots/wine-captures-2026-07-24-cadence-season-store/`
(Euro Cup 1/8, Man Utd v Barcelona, played in RESULTS mode).

**1. The full-time report record holds the WHOLE match.** Euro tie, half-time -> full
time, Man Utd:

| player | MIN | SHOTS | PASSES | TAC. | S. |
|---|---|---|---|---|---|
| Schmeichel | 45 -> **90** | -/- -> -/- | 0/4 -> 0/8 | -/- -> -/- | 6 -> 15 |
| Beckham | 45 -> **90** | 1/1 -> 2/2 | 7/8 -> 8/11 | 3/7 -> 3/11 | - |
| Sheringham | 45 -> **90** | 1/1 -> 4/4 | 1/3 -> 4/6 | 1/1 -> 4/6 | - |
| **Cole** (red card, 20') | **20 -> 20** | 0/1 -> 0/1 | 2/2 -> 2/2 | 0/1 -> 0/1 | - |

Every cell is monotone across ~30 comparisons, and a player whose minutes were frozen by
an event is frozen in every column too. Under the statistical branch's cadence the
full-time row would be an independent second-half sample; it is not.

Cole's `MIN = 20` is the `bk >= 2` branch of `FUN_00450510` (`@0x45075e ->
+0xf0 = +0xe4`), i.e. MIN becomes the event minute. Same mechanism as Solskjaer's frozen
45 on the Shield sheet — **not** a substitution.

**2. The season fold-back adds exactly that record.** LINE-UP -> STATISTICS (the
club-squad path, `@0x4b2233`) before and after the same tie:

| | MP | MIN | SHOTS | PASSES | TAC. |
|---|---|---|---|---|---|
| Beckham before | 7 | 630 | 9/17 | 61/70 | 23/60 |
| his full-time row | 1 | 90 | 2/2 | 8/11 | 3/11 |
| Beckham after | **8** | **720** | **11/19** | **69/81** | **26/71** |

Field-for-field. Same for Sheringham (MoM 3 -> 4, G. 3 -> 5) and for Cole, whose MIN
grows by his frozen 20 and whose red column goes `-` -> `1`.

**3. The two club counters.** `club+0x274` (the TEAM TOTAL `MIN` cell, `@0x4b221a`) went
`630 -> 720`, i.e. `+= 90`, and cup ties **do** count. The TEAM TOTAL `MP` cell
(`@0x4b21ed`) stayed at **7** across the same tie while every player's MP went 7 -> 8;
7 is exactly the 6 league rounds played plus the Charity Shield, so cup ties do **not**
bump it. `@0x449189` also has a `+= 120` branch gated on `F+0x58 != 0 && F+0x48 != 0`;
neither field has an identified producer, so that branch is **not modelled**.

## What the port does

`Pm98StatMatch.CADENCE_PERIOD` (default) is the statistical branch, traced instruction by
instruction, and keeps `test_statcommit_oracle` green at 323 checks.
`Pm98StatMatch.CADENCE_MATCH` is the presented branch's measured contract: commit once,
after the last period, with no intermediate zeroing. `MatchSim.simulate(..., stats: true)`
uses `CADENCE_MATCH`, because that is the sheet the app's STATISTICS screen renders.

**Open, deliberately not guessed:** which of the presented branch's three commit sites
fires when, and how a half-time sheet is produced without losing the first half. Its stat
source is the positional engine (the separate M5 workstream), so the cadence above is
banked from the frames, not from the disassembly.

## Reproduce

```
.re-venv/bin/python tools/re/fdump.py 0x44e440 0x620      # the commit + its zero loop
.re-venv/bin/python tools/re/fdump.py 0x449990 0xe0       # the record insert (rep movsd)

# The live read. ptrace_scope is 1 on this box, so /proc/<pid>/mem is unreadable for a
# wine process this session did not spawn -- winedbg's gdb proxy reads it instead.
export WINEPREFIX=$PWD/.wineprefix DISPLAY=:2
WPID=$(bash tools/re/wine/wdbg_pid.sh | cut -d' ' -f1)
winedbg --gdb --no-start --port 12345 "$WPID" &
python3 tools/re/wine/rsp_read.py 12345 652a10:4          # -> 0x00000001
```
