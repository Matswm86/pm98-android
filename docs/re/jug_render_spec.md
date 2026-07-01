# JUG.PGF player-sprite render — recovered engine spec (resolves AUDIT A7)

Source of truth: `MANAGER.EXE` player-draw `FUN_005a5460`
(`docs/re/move/fn_005a5460_FUN_005a5460.c`), the JUG loader `FUN_005923f0`
(refs `DatSim\jug.pgf` @VA `0x664bc8`, `datsim\jugcam.ind` @VA `0x664d80`), and the
`.PGF` parser chain `FUN_005d35d0` → `FUN_005d3f60` → per-frame `FUN_005caae0`.
Every number below was read from the binary (`objdump`/`pe.py`/Ghidra `DecompileAt`),
not inferred. **This REPLACES the earlier "8-compass, frame 0 = down, +45°/step"
model, which was an invention (AUDIT A7 / A8).**

## 1. Bank + frame layout (measured, not assumed)
- `jug.pgf` is loaded by `FUN_005923f0` (`0x593409`) via `FUN_005d35d0` into the
  simulador context at **`ctx + 0x2468`** (`FUN_005a5460:336`).
- The `.PGF` parser (`FUN_005d3f60`) allocates one **76-byte (`0x4c`) frame slot**
  per frame (`param_1[1]` = frame count, stride `* 0x4c`). JUG.PGF = **4211 frames**.
- On disk each frame header is `LFGP`-bank: 4-byte tag + `6×int32`
  `[h0, H(=h1), h2, h3, W(=h4), h5]` then `W*H` 8-bit pixels
  (see `tools/re/export_match_art.py:pgf_frames`). `h5 ∈ {1,2}` is **NOT** a mirror
  flag (mirroring is render-side, §3); its meaning is still a GAP.

## 2. Frame-index formula (the core of A7)
`FUN_005a5460:331-343`, per player each tick:
```
kind        = *(int*)(param_1 + 0x40)          // player "kind"/action index (0..15)
framesPerDir= DAT_00664fb8[kind]               // .data table, values below
base        = DAT_006744e8[kind]               // .bss  -> cumulative, filled at load
phase       = clamp(anim_counter, 0, framesPerDir-1)   // anim_counter @ param_1+0x2c
frameSlot   = JUGbank + (framesPerDir*dir + base + phase) * 0x4c
```
So the JUG bank is laid out **per kind as `[direction][phase]`** — direction is the
**OUTER** index, `framesPerDir` phases inner. (The app's `export_match_art.py` baked
`fr[row*8+d]` = phase-outer / 8-dir-inner, the **transpose**, and treated the first
24 frames as `[3 phase × 8 dir]` — structurally wrong.)

Per-kind tables (`DAT_006650e0` mode, `DAT_00664fb8` framesPerDir; kinds 0..15):

| kind | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 |
|------|---|---|---|---|---|---|---|---|---|---|----|----|----|----|----|----|
| mode | 7 | 5 | 5 | 5 | 8 | 8 | 5 | 5 | 5 | 5 | 5  | 5  | 8  | 5  | 5  | 5  |
| fpd  | 1 | 14| 14| 14| 8 | 12| 12| 15| 20| 18| 12 | 9  | 1  | 13 | 14 | 14 |

`kind` = the same unconfirmed "player kind byte" gap (INVENTORY §5). Which kind is a
running outfielder is NOT yet source-confirmed, so the exact base/fpd for the WATCH
run-cycle is unknown.

## 3. Direction bucketing + mirror (only 5 unique dirs, camera-relative)
Two render modes, chosen by `abs(DAT_006650e0[kind])` (`FUN_005a5460:199`):
`{5,8,1} → 8-way (octant)`, else `→ 12-way`.

**8-way (octant) path** (`:206-282`):
- The player facing angle relative to the camera (`uVar22 = facing − cameraAngle`,
  16-bit, full circle = 65536) is bucketed by counting how many of the **8 non-uniform
  thresholds** `DAT_006653e0 = [3584, 13312, 19456, 29184, 36352, 46080, 52224, 61952]`
  are below it → `dir & 7`, then `dir = dir + 2 & 7` (`:237`).
- **Mirror:** `if (dir > 4) { dir = 8 - dir; horizScale = -horizScale }` (`:251-254`).
  So only **dirs 0,1,2,3,4** ever index the bank; 5,6,7 are 3,2,1 **horizontally
  flipped**. This matches the symmetric anchor palindrome measured in the JUG headers
  (`h0`/`h2` = 17,15,12,10,10,15,17…) — the "wide/narrow/wide" width spread A7 flagged
  is the mirrored half-sweep, **not** a 45°/step compass.

**12-way path** (`:284-330`): uniform thresholds
`DAT_00665430 = [2730, 8191, 13652, …]` (≈65536/12 apart), `dir % 12`, mirror when
`dir > 6` (`dir = 12 - dir`).

The thresholds being **non-uniform for 8-way** proves the quantization is a
**camera-relative 3/4-perspective** bucketing, not `atan2` at uniform 45°. The engine
draws each player as **two rotated billboard quads** (frames at `uVar36` and `uVar37`,
`:337/343`, rasterised by `FUN_005cc670` via the `DAT_006d31c8` cos LUT) — a pseudo-3D
sprite under a fixed overhead camera. There is **no side-on 2D view in the engine.**

## 4. Consequence for the app (AUDIT A7 → A8)
`app/scenes/MatchSimulador.gd` is a side-on 2D WATCH view the engine never renders.
Its `_facing()` (uniform 45° `atan2`, frame 0 = "down") and the `export_match_art.py`
`[3×8]` bake are stylised app constructs, **not** the source model — same class of
documented app-layout choice already noted for the WATCH camera/tiling in
`match_view_re.md §3`. They are now labelled as such in code; the false "source-faithful
8-compass" claim is removed. **No invented remap is applied.**

Faithful-rebuild path (not done; needs the still-un-reversed PCF5DAT 3/4 camera +
the `kind` byte): implement §2 `[dir][phase]` indexing + §3 mirror against a recovered
camera angle. Until then the WATCH view stays an honest approximation.

## 5. Still-open GAPs
- `kind` byte semantics (which index = running outfielder / GK / etc.) — unconfirmed.
- `JUGCAM.IND` (55296 B) role in render not yet traced to a reader (loaded by
  `FUN_005923f0`; not shown feeding `FUN_005a5460`'s index math).
- PGF header `h5 ∈ {1,2}` meaning.
- The camera angle source (`param_2 + 0xdc/0xde`) and the 3/4 tile-scroll camera.
