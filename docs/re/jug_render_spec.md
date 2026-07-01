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

**CORRECTION 2026-07-01 (raw-binary + frame-count cross-validated):** there are **74
kinds (0..73)**, not 16. The three per-kind tables are three parallel `0x128`-byte
(74×`i32`) blocks laid back-to-back in `.data`: `DAT_00664fb8` (fpd), `DAT_006650e0`
(mode), `DAT_00665208` (next-state). The earlier "kinds 0..15" table was **truncated**
(only the first 16 of 74 read). Full dump + validation: **`tools/re/dump_jug_kind_tables.py`**.

`base` is NOT a runtime unknown. It is filled once at load by **`FUN_005a2830`** (guarded by
the one-time flag `DAT_00674628`) with exactly:
```
base[k] = running_total;  if (mode[k] > 0)  running_total += fpd[k] * mode[k]
```
so **`mode[k]` is the literal stored-direction count** and **negative-mode kinds add 0
frames** (they are mirror-twins that reuse a positive kind's bank offset, §3). Summing this
over all 74 kinds gives **4211 — EXACTLY** the JUG.PGF header frameCount (independently read
from the `LFGP` bank @`0x1547ea` in `DATSIM.PKF`). That exact match is the proof the model is
complete. Per-kind `mode/fpd/base/next/flag` for all 74 kinds: run the tool (canonical output
checked against the binary each run).

`kind` = the player action/animation-state byte at `player+0x40`, set across the movement/AI
code (see §4a). Its **numeric range and per-frame layout are now fully source-resolved**; only
the human-readable action *label* per kind (e.g. which exact kind the engine treats as the
run cycle) is still not nailed to a single source string (§5).

## 3. Direction bucketing + mirror (mode = stored-dir count; mirror is mode-gated)
Render path chosen by `iVar32 = abs(DAT_006650e0[kind])` (`FUN_005a5460:199`):
`iVar32 ∈ {5,8,1} → 8-way (octant) path`, else `→ 12-way path`. A separate flag
`bVar7 = (iVar32 == 8 || iVar32 == 12)` (`:189`) gates whether the octant mirror runs.

**CORRECTION 2026-07-01:** the earlier "only 5 unique dirs, always" was wrong — mirroring
is **mode-gated**. `mode[k]` (the *signed* `DAT_006650e0` value) is the literal count of
directions actually stored in the bank for that kind (cross-checked: `base` increments by
`fpd*mode`, §2). Per observed |mode|:
- **|mode| = 8 (8-way, `bVar7` true):** the `if(!bVar7)` mirror block (`:245-282`) is
  **skipped** → all **8 directions** are stored and indexed directly, no horizontal flip.
- **|mode| = 5 (8-way, `bVar7` false):** mirror **does** run — `if (dir > 4) { dir = 8-dir;
  horizScale = -horizScale }` (`:251-254`) → only **dirs 0..4** index the bank; 5,6,7 are
  3,2,1 flipped. (This is the palindrome A7 saw — it holds for mode-5 kinds only.)
- **|mode| = 1 (8-way, `bVar7` false):** `if (iVar32==1) { dir = 0 }` (`:246-248`) → single
  stored direction, facing ignored.
- **|mode| = 7 (12-way path, `:284-330`):** own mirror `if (dir > 6) dir = 12-dir`
  (`:322-329`) → **7 directions** stored.
- **mode < 0:** a mirror-twin — shares its positive twin's `base` (e.g. kind 25 = -8 reuses
  kind 26's offset 1393) and flips `horizScale`; contributes 0 new frames (§2 algorithm).

The facing angle relative to the camera (`uVar22 = facing − cameraAngle` at `param_2+0xdc`,
16-bit, full circle = 65536) is bucketed by counting how many of the **8 non-uniform
thresholds** `DAT_006653e0 = [3584,13312,19456,29184,36352,46080,52224,61952]` are below it
→ `dir & 7`, then `dir = dir + 2 & 7` (`:237`).

**12-way path** (`:284-330`): uniform thresholds
`DAT_00665430 = [2730, 8191, 13652, …]` (≈65536/12 apart), `dir % 12`, mirror when
`dir > 6` (`dir = 12 - dir`). **No JUG kind has |mode| == 12**, so this path is unused for
JUG (the only non-{5,8,1} mode present is 7, which routes here as a 7-of-12 octant).

The thresholds being **non-uniform for 8-way** proves the quantization is a
**camera-relative 3/4-perspective** bucketing, not `atan2` at uniform 45°. The engine
draws each player as **two rotated billboard quads** (frames at `uVar36` and `uVar37`,
`:337/343`, rasterised by `FUN_005cc670` via the `DAT_006d31c8` cos LUT) — a pseudo-3D
sprite under a fixed overhead camera. There is **no side-on 2D view in the engine.**

## 4a. Animation state machine + `kind` setters (source-anchored 2026-07-01)
Per-tick phase advance = **`FUN_005a50c0`**: increments `player+0x2c` (phase), wraps mod
`fpd[kind]`, and on wrap transitions `kind = DAT_00665208[kind]` (the "next-state" column
in the §2 dump — e.g. one-shot kinds fall back to their looping/idle kind; self-referential
entries loop). `kind` itself is assigned via the setter `FUN_005a5430(kind)`
(`player+0x40 = kind`). Every assignment traced this pass (constants are source, roles are
described only as far as the branch condition proves):
- **Locomotion/gait** — `FUN_005a8f20` sets kinds **0, 1, 2, 3** (`:191/195/198`, gait tiers;
  0 = single static frame, 1/2/3 = 14-phase 8-way loops that self-loop via `next=self`), plus
  30/34/35 branches. `FUN_005a50c0:28-40` reverse-plays kinds 0..3 when `player+0x68 < 0`.
- **Directional pairs** picked by an angle test: `FUN_005aeda0:260` → **6 or 7**
  (`(angle < 0x4000) + 6`); `FUN_005a9490:287` flips **25 → 26** when angle < 0.
- **Action→kind LUT** `DAT_006655b0[0..11]` = `[20,21,25,22,5,0,9,5,4,6,3,0]`
  (`FUN_005a9490:273`).
- **Set-piece / timed states** (`FUN_005a3400`, with a `player+0x48` frame-delay counter):
  kinds **0x13(19), 0x1d(29), 0x1e(30), 0x20(32)**; `FUN_005a7260` set-piece LUTs
  `DAT_006654c0 = [46,47,48,51,40,44,52,41,45]` and `DAT_006654e8 = [-1,-1,53,49,38,42,50,39,43]`.
- **Goalkeeper** — `FUN_005a65a0` sets 0x35(53), ~0x11(17), 0x1e(30), 0 (it also branches on
  `kind == 0x11`); `player+700 (0x2bc)` is a boolean that shifts many kinds into a parallel
  high band (`-(x+700==0)&0x1e` etc.) — the 30..55 kinds are the `+700`-set variants of the
  low band (semantics of the flag itself not yet confirmed → §5).
- **Misc actions**: 0xb(11)/0xd(13) `FUN_005a9490`, 0x17(23) `FUN_005aeda0`, 0x1c(28)
  `FUN_005b73a0`, 0x23(35) `FUN_005a8f20`.

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
**RESOLVED this pass (2026-07-01):** `kind` numeric range (74 kinds), all per-kind
tables (mode/fpd/next/flag), the `base` frame-offset table (via `FUN_005a2830`,
validated to the exact 4211-frame total), and the mode=dir-count / sign=mirror model.
Remaining:
- **Human-readable action label per kind** — the *setters* are now traced (§4a) but the
  engine carries no per-kind name string; do not invent labels (e.g. "kind 2 = run").
- **`player+700 (0x2bc)` boolean** meaning (splits kinds into a low/high band) — unconfirmed.
- `JUGCAM.IND` (55296 B) role in render not yet traced to a reader (loaded by
  `FUN_005923f0`; not shown feeding `FUN_005a5460`'s index math).
- PGF header `h5 ∈ {1,2}` meaning.
- The camera angle source (`param_2 + 0xdc/0xde`) and the 3/4 tile-scroll camera (PCF5DAT).
