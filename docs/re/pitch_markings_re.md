# The pitch MARKINGS — source-read (closes "declared, not source-read")

Status: **SOURCE-READ + PORTED 2026-07-28.**

Evidence: `extracted/Premier Manager 98/MANAGER.EXE`, `app/scenes/MatchSimulador.gd`,
`app/tests/test_jug_render.gd`

Method: Ghidra 12.1.2 headless on **`FUN_0059a8c0`** — the simulador's pitch builder — plus a
constant sweep of `.text` for the 16.16 encodings of the laws' figures; every hit below is a
literal operand at a call site inside that one function.

## What was carried, and why it was worth checking

`REMAINING.md` §6.3 and the s75 handoff both said:

> **The marking geometry is the laws of the game**, scaled to the session's own length and
> width, because PM98 stores only those two figures. Declared, not source-read.

The first half is right and the second was never tested. `FUN_0059a8c0` builds the whole
marking set from `matchctx+0x1820` (half the pitch LENGTH) and `matchctx+0x1824` (half its
WIDTH) with every other figure a literal in the code, and mirrors each end by negating the
basis vector. So the numbers ARE in the binary.

## The figures, as literal operands

| 16.16 literal | metres | what it builds | call site |
|---|---|---|---|
| `0x1999` | **0.1** | the width of EVERY line, and the overrun past each corner | every call |
| `0x92666` | 9.15 | the centre circle, and the D's radius about the penalty spot | `0x59ba25`, `0x59ba69`, `0x59bd31` |
| `0x10000` | 1.0 | the four corner arcs | `0x59b...` x4 |
| `0x108000` | 16.5 | the penalty area's depth | `0x59bbef` |
| `0x1428f5` | 20.16 | its half-width (its side lines' `y`) | — |
| `0x28851d` | 40.52 | its front line's length (= 40.32 + one line width) | — |
| `0x109999` | 16.6 | its side lines' length (= 16.5 + one line width) | — |
| `0x58000` | 5.5 | the goal area's depth | `0x59bc68` |
| `0x928f5` | 9.16 | its half-width | — |
| `0x12851d` | 18.52 | its front line's length | — |
| `0x59999` | 5.6 | its side lines' length | — |
| `0xb0000` | 11.0 | the penalty spot's distance from the goal line | — |
| `0xaccce` | 10.8 | where the penalty MARK's quad starts (10.8 + half of 0.4 = 11.0) | — |
| `0x6664` x `0x3332` | 0.4 x 0.2 | the centre and penalty MARKS — quads, not dots | — |
| `0x2640` | **53.79 deg** | the D's half-angle | `0x59ba25` |

The touchlines and the goal/halfway lines fall out of two loops rather than a list:

```
y = -halfWid;  step 2*halfWid;  while y <= halfWid    ->  the two TOUCHLINES,
                                                          length 2*halfLen + 2*0.1
x = -halfLen;  step halfLen;    while x <= halfLen    ->  the two GOAL LINES and the
                                                          HALFWAY LINE, length 2*halfWid + 2*0.1
```

## The two things the port had wrong

1. **The D's half-angle.** The port DERIVED it as `acos((16.5 - 11) / 9.15)` = 53.06 deg — the
   textbook construction. The binary uses its own constant `0x2640` = **53.79 deg**, 0.73 deg
   wider. The binary is the authority; the port now carries `D_HALF_ANGLE` read off it.
2. **The spots were dots.** `_spot` drew a projected circle; the engine draws a
   0.4 m x 0.2 m ground quad. Now it does too.

Everything else the port already had right, and can now say so with a citation instead of a
declaration: 9.15 / 16.5 / 20.16 / 5.5 / 9.16 / 11.0 / 1.0 are all literals in `FUN_0059a8c0`.

## Still not source-read here

The **grass shading**. `FUN_0059a8c0`'s first half builds the field itself out of the
`DAT_006642d0` / `DAT_00664310` scale pair and the `hier*.raw` atlases, and the port's mown
bands are still colours sampled off the original's own captured frame
(`tools/re/refs/watch-2026-07-28/watch_02.png`) rather than that build. Said plainly, and left
open. The five `SIMUL<n>.PAL` pitch palettes are now shipped (`kit_palette_re.md` §3) and are
the natural input when it is done.
