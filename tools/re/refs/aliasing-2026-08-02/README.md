# `aliasing.bin` — `DAT_006b5890`, read out of the running original (2026-08-02, s89)

`sha256 401e3411d3c1bc4b29012092bca799af9536290f070790e98703777ba34e0636`, 8,192 bytes.

## What it is

The classifier table the shadowed blit's `flags & 0x20` arm looks each 13-bit neighbourhood
code up in: `FUN_005d60a0` replaces every non-zero mask byte with `table[code] * 2 + 1`.
Six sessions could not model that pass because the table **cannot be read out of the image**
— `0x6b5890` is above `.data`'s raw end (`0x667000`), so it is `.bss`, built at runtime by
the graphics-init at `0x5c9762..0x5c9a02`.

## How it was obtained — and why not from the sources

The init reads `dat\aliasing.dat` if it exists and otherwise COMPUTES the 8,192 bytes from
`letras.bmp` and writes the file out as a cache. **Neither file ships.** Measured, both ways
(`tools/re/build_aliasing_table.py --check-sources`): `letras.bmp` is not loose in the
install, not in any of the six PKF containers, not on `pm98.iso` (its two `letras` hits are
MANAGER.EXE's own string literal, immediately followed by `dat\aliasing.dat`) and not in
`Premier_Manager_98.rar`; and no `dat/` directory or `aliasing.dat` exists in either source.

So the table is a property of the RUNNING program. It was read over the winedbg RSP stub at
the KICK OFF screen of a Bolton W career, by `m5_rsp_capture.py`, which now dumps
`0x6b5890..+0x2000` and the run-once guard `0x6b7920` on the same connection it needs for
the M5 trace. **The guard read 1** — the init HAD run — and the table read
**3,921 of 8,192 non-zero, 223 distinct values**.

## Why it is the real table and not `.bss` garbage — three structural checks

`tools/re/build_aliasing_table.py` transcribes the generator, and every prediction that
transcription makes about the bytes holds:

1. **Rotation invariance: 0 violations in 8,192.** The generator accumulates each pixel into
   four codes related by `T(c) = (c & 1) | ((c >> 3) & 0x3fe) | ((c & 0xe) << 9)`, so `sum`
   and `count` are constant on every `T`-orbit and `table[T(c)] == table[c]` must hold
   exactly. It does — for all 8,192, across orbits of size 1, 2 and 4.
2. **The `count = 1` initialisation shows up in the arithmetic.** 616 complementary pairs sum
   to exactly 127, which is what a code seen ONCE with `d = 255` produces: `255 // 2 = 127`
   and `0 // 2 = 0`. A `count = 0` init could not produce it, and noise could not either.
3. **It is monotone in popcount**, i.e. it is a coverage/anti-aliasing classifier:

   | bits set | 0 | 1 | 4 | 7 | 10 | 12 | 13 |
   |---|---|---|---|---|---|---|---|
   | mean `table[c]*2+1` | 1.0 | 68.7 | 44.7 | 55.1 | 107.1 | 233.3 | **253.0** |

   A fully-enclosed pixel (all 13 bits) gets **253**, not 255 — a 2/256 nudge toward the
   destination on every interior pixel, which is exactly the magnitude that flips a pixel
   through the `DAT_00675398` dither and exactly the shape of the 1-px residual.

## What is NOT established

* **Determinism across boots is CONFIRMED on THREE independent boots** (2026-08-02, same
  session) — two fresh boots of this wineprefix and one FULLY isolated instance: a `cp -a`
  copy of the prefix with its own wineserver, its own X display and its own boot and career.
  All three dump `guard 1`, 3,921 non-zero, 223 distinct and the **same sha256**, byte for
  byte. So the bytes are a property of the program, not of a session. (WHERE the generator's
  input surface comes from is still not reversed: `letras.bmp` is in neither source, yet the
  load plainly succeeds.)
* **The pass is not closed.** `tools/re/probe_groupdraw_kit_edge.py` runs it against the one
  oracle with a witnessed destination (the group draw: five of six boxes are empty, so the
  pixels under group A's kits are readable off group C's band) and it **improves** the four
  kits from 396 wrong pixels to 349 — directionally right, not closed. The remainder needs
  the port's own render of that screen (the right club per row) rather than this probe's
  best-match sprite.
