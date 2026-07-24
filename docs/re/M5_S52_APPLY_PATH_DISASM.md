# M5 s52: the b0040 → heading APPLY path, disassembled

Closes the s51 next-session item 1 ("disassemble the apply path between `_move_b0040`'s return
and the write to t1.i10 `0x34/0x64`; does live `b1420` pick the B0040 arm, or does the caller
clamp the overflow?").

Answer: **neither. Nothing downstream of `FUN_005b0040` clamps anything, and the live engine did
not apply B0040's target at the fork tick at all.** Evidence:
`tools/re/specs/b0040_apply_path_s52.txt`.

## 1. The chain, end to end

All five functions are in `docs/re/move/`:

| step | function | what it does with the point |
|---|---|---|
| 1 | `FUN_005b0040` tail (`LAB_005b04a6`) | `local_c` = interception point |
| 2 | `FUN_005b1330(local_c, M+0x1828)` | per-axis `min(max(v, lo), hi)` — **the only clamp in the chain** |
| 3 | `FUN_005a89c0(this=P, pt, 0x5a)` | sets curve `P+0x6c`; 75 % if carrier; PARKs to 0 in phase {2,3,4,5,7} |
| 4 | `FUN_005a8bc0(this=P, pt)` | delta boxes; `heading = atan(delta)`; the backpedal flip |
| 5 | `FUN_005a8f20(this=P, heading)` | once-per-tick guard `P+0x2d7`, TURN / COMMIT / INTEGRATE |

So the "caller clamps the overflow" hypothesis is dead: `FUN_005b1330` **is** the clamp, it runs
*inside* b0040, and the port already reproduces it (`_b0040_target`, oracle-locked in s50).
Steps 3–5 never re-clamp and never re-pick a target.

The backpedal flip in step 4 (`heading -= 0x8000; P+0x6c = -P+0x6c; P+0x90++`) is gated on the
delta being inside ±0x20000 per axis. At the fork tick the delta is `(-4118722, -519801)` — 31×
outside the box — so it cannot fire in either build. The port implements it correctly.

## 2. `FUN_005a8f20` is a pure heading tracker — which makes the capture decisive

Decompile lines 58–115, verbatim:

```
d     = (short)(heading - u16 P+0x34);   ad = |d|
steps = trunc((ad - 0x100) / 0x400) + 1
steps < 2  (ad < 0x500) -> P+0x34 = heading          else  P+0x34 += (d > 0 ? +0x400 : -0x400)
ad < 0x1555             -> P+0x64 = heading, P+0x68 ramps toward P+0x6c by <= 0x106
else                    -> P+0x68 = max(0, P+0x68 - 0x1ca)
```

Because the only writes to `0x34` / `0x64` are `heading` itself (snap / commit) or a fixed ±0x400
step, the s51 capture **back-solves the applied heading exactly** on every snapping or committing
tick. `tools/re/m5_8f20_heading_solve.py` does that, then forward-replays the rules:

```
clk 635  yaw 28286 -> 9258   COMMIT  =>  heading = 9258
clk 639  face 9854 -> 9258   SNAP    =>  heading = 9258
clk 640  face 9258 -> 8234   slew-   =>  heading in [42026..3797] mod 2^16   (0x68 DECAYs: ad >= 0x1555)
clk 643  yaw  9258 ->  765   COMMIT  =>  heading = 765
clk 648  face 1066 ->  763   SNAP+COMMIT => heading = 763
forward replay with heading = 9258 (<=639) then 765 / 763 / 762  ->  EXACT MATCH, 0 mismatches, clk 631-660
```

This also explains the two things s51 left open, with no invention needed:

* the **staged `0x64`** (`28286 → 9258 → 765 → 763`) is just the `ad < 0x1555` commit gate opening
  as the face slews into range — not a separate "committed heading" mechanism;
* the **"1-tick pause"** is the `0x1ca` speed decay: `0x68` runs `1310 → 852 → 394 → 0` over the
  three ticks where `ad >= 0x1555`, then re-ramps at `+0x106` once the gate reopens at clk 643.

## 3. s51 correction: the port never flips `0x34` to 34078

s51 recorded "the port flips `0x34` → 34078 at 639 and FREEZES". The first half is wrong.
`app/tests/diag_m5_t1i10_apply.gd` (new) shows the port's `0x34` slewing **upward** +0x400/tick —
`9258 → 10282 → 11306 → 12330 → …` — because 34078 is *ahead* of the face in 16-bit terms
(`s16(34078 − 9258) = +24818`). 34078 is the **heading** (the angle to b0040's clamped −corner),
never the face. The freeze is real, but its cause is `0x68` decaying `0x1ca`/tick to 0 and staying
there, since `ad >= 0x1555` on every subsequent tick.

## 4. Where the fork actually is

Silicon's applied heading at clk 643 is **765**; the port hands the trio **34078**. 765 is a ray at
4.2° from the player — a point at `ball.pos + facedir * lead` with `lead ≈ 1 292 251`, i.e.
`(2042699, −1715134)`, **inside** the pitch box, so it is not a clamp artefact of any kind. The
port's lead at the same tick is `−1 040 510 322` (the i18 signed wrap of s50 §3), which clamps to
the −corner at 34078.

Every b0040 input at that tick is byte-identical between port and silicon: player pos
`(350402, −1839495)`, ball pos `(770857, −1945817)`, ball vel `(13633, 2451)`, ball face `0x34 =
1854`, and the 16 marker slots (s51 §3). Two inputs were still open; both are now closed:

* **the marker-adjust arm** (`ball+0xb0 / +0xbc > 0x2cccc` → `lead = max(lead, dot(ball+0xcc /
  +0xd8 − ball, facedir))`) would have rescued the overflowed lead. It is inert: those fields are
  **0 in the real frame-0 snapshot** (`frame0_struct_import.json`, ball dwords `0xb0/0xbc/0xcc..0xe0`),
  and a Ghidra store scan (`FindStoreDisp 0xb0` / `0xcc`) finds **no object-relative write** to
  either displacement anywhere in the match engine (`0x58xxxx–0x5bxxxx`) — every hit is `[ESP+…]`.
* **`curve_rate = (P+0x70 * P+0x3ac)/15000 + P+0x3a8`**, the loop's converge/diverge knob and the
  only b0040 input not captured live. Killed by `app/tests/diag_m5_t1i10_leadsweep.gd`: reaching
  heading 765 needs `curve_rate ≈ 1.7e4`, i.e. `P+0x70 ≈ 69 819`. The **real** `P+0x70` at frame 0 is
  **13 860** and the port's at the fork tick is 13 429. A 5× excursion in that field is not credible.

So the live engine did not apply B0040's output on that tick. `FUN_005b1420`'s B0040 arm needs
`P == GS+0x204 && BALL+0x40 == 0`; the capture proves the carrier half holds in silicon
(`ball+0x40 == 0` at every clk 630–660), so the open half is **`GS+0x204` (the designate)** — or
`FUN_005a8f20`'s once-per-tick `P+0x2d7` guard being consumed by an earlier steer call in the tick.

## 5. Next session

1. Capture `GS+0x204` (team-header designate) and `P+0x2d7` for t1.i10 over clk 636–645. Those two
   fields separate "b1420 picked a different arm" from "an earlier steer call won the tick guard".
   Add them to `m5_rsp_capture.py`'s player/team rows; everything else needed is already captured.
2. If the designate moved: find the writer of `GS+0x204` and compare against the port's
   `Pm98Movement._desig` update path (s45 ctrl-mirror designation).
3. If the designate held: dump every `steer_8f20` entry for t1.i10 in the tick, real and port, and
   find the earlier caller.
4. Still no engine fix this session — per the locked no-invent rule, the target source has to be
   identified before anything is coded.

## Files

* `docs/re/move/fn_005b1330_FUN_005b1330.c`, `fn_005a89c0_…`, `fn_005a8bc0_…`, `fn_005a8f20_…` —
  the disassembled chain (already in-tree; this session read and cross-checked them).
* NEW `tools/re/m5_8f20_heading_solve.py` — back-solve + forward replay of the real 8f20 rules.
* NEW `app/tests/diag_m5_t1i10_apply.gd` — the port's full apply chain per tick.
* NEW `app/tests/diag_m5_t1i10_leadsweep.gd` — the curve_rate sweep / lead back-solve.
* NEW `tools/re/specs/b0040_apply_path_s52.txt` — the committed evidence.
