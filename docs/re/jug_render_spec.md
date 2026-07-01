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
- `JUGCAM.IND` (55296 B = 256x216, `DATSIM.PKF` @off 5311682) role **NARROWED 2026-07-01**:
  it is **NOT a sprite/image** (decoded both orientations to noise, viewed; a width sweep
  finds no coherent bitmap at any divisor width, min vertical-gradient >= 20). Byte profile
  is 72% zero with ~180 distinct small **monotonically-increasing indices**, i.e. an
  index/lookup table (consistent with the `.IND` convention). It is opened as a **FILE** at
  sim (re)entry: the filename is built at VA `0x592a63` (its ONLY code xref) inside
  `FUN_005923f0`'s re-entry (`+0x5fac != 0`) block and passed to the file-open method
  `FUN_005ec020` (TLS -> `FUN_005eaf80`, handle stored at `obj+0x100`). It is **NOT read by
  `FUN_005a5460`'s per-player frame-index math** (that path uses only `ctx+0x2468` JUG bank +
  the `.data` kind tables + `DAT_006653e0` thresholds). STILL GAP: its internal record layout
  and its actual consumer function.
- PGF header `h5 ∈ {1,2}` meaning.
- Camera-angle source (`param_2 + 0xdc`) — **ORIGIN RESOLVED 2026-07-01 (s3), full write chain
  traced byte-for-byte.** The draw `FUN_005a5460` is a virtual method reached through **four**
  distinct vtables that all carry `0x5a5460` (whole-image search for the pointer: `.rdata`
  `0x6391f8`, `0x639208`, `0x639228`), at **different slots** — draw is slot0 for bases
  `0x639208`/`0x6391f8`, slot`+8` for base `0x639220`, slot`+0x10` for base `0x639218`. The two
  `0x5946f0`/`0x5963e0` constructors build the `0x639220` variant; the match-scene constructor
  `FUN_00591180` builds `0x639208`/`0x6391f8`/`0x639218` view-actor objects at `matchctx+{0x430,
  0xaac,0xe74,0x123c}` (these are special actors — GK/set-piece band, kinds `0x42..0x48`; their
  slot`+8`=`0x5a4560` is a replay ring-buffer copy, NOT the draw). Calling convention (draw
  prologue `0x5a5460..0x5a54d8`): **`param_1 = ecx = this`; `param_2` = a caller-pushed first stack
  arg** at `[esp+0x32c]`. `param_2` reads confirmed: `mov ax,[param_2+0xdc]` (`0x5a58d0`, 16-bit
  yaw), `movsx eax,[param_2+0xde]` (`0x5a5978`/`0x5a5b7b`, second Euler term). Sim ctx is a
  *separate* pointer `*(this+0x18c)` (holds `0x5fac` flag, `0x5e88` base table, JUG bank `+0x2468`).

  **`param_2` = the render device object `D`**, and its `+0xdc`/`+0xde` are written by the camera
  setter **`FUN_005d7db0` (`SetCamera`)** — proven the *sole* writer of both `+0xdc` AND `+0xde`
  (Ghidra `FindWordStore 0xdc 0xde`). `SetCamera(this=D, pos=&cam[0x3c], yaw=param_3, pitch=param_4,
  roll=param_5, mode=param_6)` stores `D[0x37]=(short)yaw` (`=+0xdc`), `(short)+0xde=pitch`,
  `+0xe0=roll`, `+0xe4..+0xec=pos vec3`, `+0x100=mode`, then builds the view matrix. Arg chain
  (all exact-disasm, not Ghidra vararg guess):
  `sim @0x59a3c2` `lea eax,[matchctx+0x27f0]`(cam `A`) + `lea ecx,[matchctx+0x430]`(sceneRoot) +
  `push A; push esi`(device `D`) → **`FUN_005f7150(sceneRoot, D, A)`** → `FUN_005d7b20(ecx=D,
  stackarg=A)` → `FUN_005f6230(ecx=A=viewCtx, stackarg=D)` → `SetCamera(this=D, yaw=A+0x8c, …)`.
  So **`D+0xdc  =  A+0x8c  =  matchctx+0x287c`** (16-bit) and `D+0xde = matchctx+0x287e`.
  Independent cross-check: `FUN_00598740:113` copies `*(word)(matchctx+0x287c)` → `matchctx+0x181c`,
  confirming `+0x287c` is the live camera-yaw word. `FUN_005f7150` also threads `D` down as the
  scene-draw arg (`push edi(=D); call [sceneRoot_vt]`), so `D` reaches each player draw as `param_2`.
  (`FUN_005a1820`, earlier suspected a camera setter, is actually an **AABB overlap test** used by
  `FUN_00598740` to pick the view mode from the `0x134000/0x164000/0xa8000/0x38000` angle family —
  ruled out.)
  **YAW-WRITER RESOLVED 2026-07-01 (s4) — the match camera does NOT rotate; yaw is a constant 0.**
  There is **no per-frame yaw writer** (the s3 "camera-follow" assumption was wrong). Proof, static
  and byte-verified:
  - The camera-controller sub-object `camctrl = matchctx+0x27f0` is a plain data struct (its `+0`/`+4`
    are zeroed by its ctor, so no vtable). Every address computation of it in `.text` was found by a
    byte-search of disp `0x27f0` (`\xf0\x27\x00\x00`) — **8 sites**: seven `lea reg,[matchctx+0x27f0]`
    (`0x5913a5 0x59373a 0x593fa4 0x597900 0x597952 0x597c48 0x59a3c2`) + one init store
    `0x5a0e79 mov [matchctx+0x27f0],eax`. At each `lea`, camctrl is passed straight into a thiscall/arg
    (never stored into a persistent field), so the only code that can write `camctrl+0x8c` is one of
    those callees: `0x5f56a0 0x5f5740 0x5f5840 0x5f57e0` (+ the read-only draw entry `0x5f7150`).
  - Of those, **only `FUN_005f56a0` writes `+0x8c`** — and it is the camctrl **constructor/reset**:
    `mov eax,ecx` (eax=this), then after `xor ecx,ecx` it stores `[eax+0x90]=[eax+0x8e]=[eax+0x8c]=cx=0`
    (`0x5f5723/0x5f572a/0x5f5731`, 16-bit) — i.e. **roll=pitch=yaw = 0**, alongside its other default
    inits (`+0x88=+0x84=+0x80=0x10000`, `+0x92=1`, position vecs zeroed).
  - The other three camctrl methods mutate **position/target only, never orientation**:
    `FUN_005f5740`→vec3s at `+0x54`/`+0x48`, `FUN_005f57e0`→vec3 at `+0x6c`, `FUN_005f5840`→scalar `+0x84`.
    So the camera *pans* to follow play (position updates per frame) but its yaw/pitch/roll never change.
  - No **matchctx-relative** store to the orientation words exists either: byte-search of disp `0x287c`
    /`0x287e`/`0x2880` in `.text` finds a single access — `0x5989f4 mov eax,[matchctx+0x287c]`, a **read**
    (the `+0x287c → +0x181c` copy noted above). Pitch/roll (`+0x287e`/`+0x2880`) have no direct access.
  - Value chain closed: `FUN_005f6230` reads `yaw=*(u16)(camctrl+0x8c)`, `pitch=+0x8e`, `roll=+0x90`,
    `param=+0x88` and calls `SetCamera`, which stores them at `D+0xdc/+0xde/+0xe0` and feeds
    `FUN_005eeba0(pos,yaw,pitch,roll)` (the view-matrix build — so the word IS consumed, not dead).
  - **Corollary for the DRAW:** `cameraAngle = *(short)(param_2+0xdc) = 0` for the whole match, so the
    sprite-direction pick `uVar22 = playerFacing − cameraAngle + 0x4000` collapses to a **fixed**
    `playerFacing + 0x4000` — the match view is orientation-fixed; no camera-angle recovery is needed
    for the yaw. Evidence decompiles: `docs/re/move/fn_005f56a0`,`_005f5740`,`_005f5840`,`_005f57e0`,
    `_005f6230`,`_005d7db0`.
  - **NOTE on the s3 candidate stores:** `0x5a27ed [esi+0x8c]`, `0x5a31bc [ebp+0x8c]`, `0x5af9bf [eax+0x8c]`
    are **NOT** camctrl writers — base `esi`/`ebp` there is a **player** struct (the same block zeroes the
    `+0x34` facing *word*), and `eax=[esi+0x3b8]` is a counter object (`dec`); they share offset `0x8c`
    with camctrl only numerically.

  **POSITION-FOLLOW inputs traced 2026-07-01 (s4) — the camera pans by tracking a world anchor + an
  actor, orientation still fixed:**
  - **Eye/position** (`FUN_005f5740`, sets camctrl vec3 `+0x54`/`+0x48`): source is the vec3
    `matchctx+0x1614` (`0x593f8e mov eax,[ebp+0x1614]; [ebp+0x1618]; [ebp+0x161c]` → local at `[esp+0x18]`),
    with a fixed `+0x500000` added to the 3rd component (`0x593fb2 add edx,0x500000` = a constant Z/height
    offset). So the eye sits at a fixed height above the anchor point.
  - **Look-at/target** (`FUN_005f57e0`, sets camctrl vec3 `+0x6c`): follows a tracked **actor** — arg =
    `*(matchctx+0x43c)+4` when that ptr is non-null and the `matchctx+0x460` band-flag ≤1
    (`0x597c0e..0x597c31`), else `*(matchctx+0x440)+4` (`0x597c33`), else fallback to the same anchor
    `matchctx+0x1614` (`0x597c42`). `+0x43c`/`+0x440` are actor-object pointers, `+4` is their position vec3.
  - **Zoom/distance scalar** (`FUN_005f5840`, sets camctrl `+0x84`): a value from `FUN_005edfa0(
    matchctx+0x2874, 0x1051e)` clamped to `[0x8000, 0x20000]` (`0x5978c2..0x597906`) — not a position.

  Still open (genuine, do NOT invent): **what `matchctx+0x1614` (the eye anchor) is** — WRITER now
  resolved in the s6 block below (`FUN_0058e2c0`, vtable slot 3 of the `matchctx+0x1610` object); the
  residual GAP is the object's *semantic name* (target-setter of `this+0x9c`), not the writer. Do not
  name it "ball / play centroid" until the target-setter or a dynamic trace proves it; likewise which
  actors `matchctx+0x43c`/`+0x440` point to. The exact vtable slot
  inside the generic retained-mode scene-graph traversal at which `ecx`=a specific player is set
  (base-class stubs `0x605d96` obscure the static path — likely needs a dynamic trace); and the 3/4
  tile-scroll camera (PCF5DAT, hard GAP).

  **VIEW-MATRIX + PROJECTION RESOLVED 2026-07-01 (s5) — `FUN_005eeba0` reversed; no rotation tilt
  anywhere in the match camera. The on-screen look is NOT a tilted camera.** All decompile-verified
  (Ghidra `DecompileAt`, evidence in `docs/re/move/fn_005eeba0`,`_005eea80`,`_005eea50`,`_005ee800`;
  the three angle composers `_005eea80`/`_005eeae0`/`_005eeb40` are the same shape).
  - **`FUN_005eeba0(out, eye, yaw, pitch, roll)` builds a fixed-point (16.16) Euler VIEW matrix**
    `V = T(-eye) · R(-yaw) · R(-pitch) · R(-roll)`. It takes `eye` + the three angle **words only —
    there is no look-at/target argument.** Each `R` (`FUN_005eea80` etc.) is a single-axis rotation
    read from a **cos/sin LUT** `DAT_006d31c8` (angle unit `0x10000` = full turn; index
    `(angle+8)>>4 & 0xfff`, sin via `(0x3ff8-angle)>>4`), matmul'd via `FUN_005ee800` (3×3 16.16).
  - Since yaw=pitch=roll are the **constant-0** words `camctrl+0x8c/0x8e/0x90` (s4), every `R` reduces
    to identity (`cos0=0x10000`, `sin0≈0`, and `param_1[8]=0x10000` unconditionally) ⇒ **`V` = pure
    translation `T(-eye)`.** The camera is world-axis-aligned; it never rotates toward the tracked
    actor (no look-at→Euler conversion exists — consistent with §5 "yaw is a constant 0").
  - **The 2nd matrix `SetCamera` composes is a projection SCALE, not a tilt:** `FUN_005eea50(0x10000,
    k, k)` (Ghidra: a diagonal builder — sets `[0]/[4]/[8]` only) composed via `FUN_005ee800`, where
    `k = FUN_005edfa0(ftol(width · C1 · C2), camctrl+0x88) = (that·camctrl+0x88)>>16`, `width =
    camctrl[0x44]-camctrl[0x42]`, `C1 = double@0x639ac0`, `C2 = double@0x639ae0`. A uniform-ish scale
    keyed to viewport width; introduces no rotation.
  - **`D` (the render-device object threaded down the draw) IS `camctrl = matchctx+0x27f0` — one
    struct, not two.** `FUN_005d7b20(param)→FUN_005f6230(param)→SetCamera(this=param)` all thiscall the
    same object; `SetCamera` writes its outputs back onto it (`+0xdc/+0xde/+0xe0` = matchctx+0x287c…,
    matrices at `+0x7c…`/`+0xe4…`). This corrects the earlier "(D, cam)" two-object phrasing and
    confirms `D+0xdc = matchctx+0x287c`. `camctrl+0x88` ctor default = `0x10000` (`FUN_005f56a0`).
  - **GAP (flag, do NOT fill):** whether `camctrl+0x88` (the projection-scale input) is ever set ≠`1.0`
    — 13 `lea reg,[esi+0x2878]` sites in a `0x4aXXXX` cluster pass its address into `FUN_005c9f60`/
    `FUN_005c0d50` (looks like a settings load/serialize path); base `esi` not yet confirmed = matchctx.
    Even if it changes, it only scales the projection — never rotates it, so the "no-tilt" result holds.
    Also open (position, s4): `SetCamera` reads eye from `camctrl+0x3c` while `FUN_005f5740` writes
    `+0x48/+0x54` → an unproven `+0x48→+0x3c` copy.

  **ANCHOR-WRITER RESOLVED 2026-07-01 (s6) — the s4 "what writes `matchctx+0x1614`" GAP is closed.
  The anchor is the position field of a vtable object, updated by its own per-frame method — not a
  raw copy from a named "ball". Position-only; no rotation implication (s5 "no-tilt" holds).**
  Byte-search (disp `0x1614/0x1618/0x161c`, all reads) + Ghidra
  (`docs/re/move/camwriter/fn_0058e2c0`,`_0058e050`,`_0058e120`,`_0058e220`,`_005902b0`,`_00598740`):
  - **`matchctx+0x1610` is a C++ object**: vtable `0x639080` (4 slots `0x5902b0`/`0x58e120`/
    `0x58e220`/`0x58e2c0`), ctor **`FUN_0058e050`** (`mov [this],0x639080`, called `0x591254`,
    `this=matchctx+0x1610`; back-ptr `this+0x1d4→matchctx`). The **anchor vec3 is `this+4/+8/+0xc`
    = `matchctx+0x1614/0x1618/0x161c`** (the object's *position*), so writes are `[this+4]` — which is
    why no matchctx-relative `mov [..+0x1614],reg` exists (all disp-`0x1614` hits are reads/`lea`).
  - **Writer = vtable slot 3 (`+0xc`) = `FUN_0058e2c0`**, run per-frame at `FUN_00598740:192`. Two
    paths: **(A) lerp** `pos += (target − pos)/n` toward `this+0x9c/+0xa0/+0xa4` over `this+0x6c`
    sub-steps; **(B) velocity-integrate** `pos += vel` (`this+0x20/+0x24/+0x28`) **clamped to the pitch
    AABB `matchctx+0x1828..+0x183c`**, fixed `±0x23d7` Z bias, gated on flag `this+0x63`.
  - **`+0x1610` is UNIQUE (1 + 3, not 4-of-one).** Only it uses ctor `0x58e050`/vtable `0x639080`.
    The 3 objects `+0xaac`/`+0xe74`/`+0x123c` are a **different class** (shared ctor **`FUN_005a2640`**,
    MI vtables `0x639224`→`0x639238`→`0x639228`) that each store a **pointer to the `+0x1610` object**
    (`this+0x190 = matchctx+0x1610`) + matchctx (`this+0x18c`). All 4 share the update interface, so
    `FUN_00598740` runs slot 2 (`+8`: record copy → `this+0x40`, idx `DAT_006d31c0`) then slot 3 (`+0xc`)
    on all 4 (`:182-185,192-195`). The `+0x1610` one feeds the camera look-at fallback
    (`0x597c42`→`FUN_005f57e0`) and the AI orientation reference (`FUN_005b73a0:588/630`).
  - Slot 0 (`FUN_005902b0`) READS this position → `FUN_00590aa0` → render device
    `[matchctx+0x1d4]+0x294c+0x40`: camera POSITION only, no rotation.
  - **Identity = the match BALL (byte-evidence, strong):** `FUN_0058fbe0`/`FUN_0058f3c0` do 3D ball
    physics on this object — velocity `this+0x20/0x24/0x28`, **boundary velocity-reflection** (bounce:
    `this+0x24=-this+0x24`, `this+0x28=-this+0x28`), pitch-AABB clamp `matchctx+0x1828..+0x183c`,
    attacking-side flag `this+0x54`, goal-target geometry `this+0x90/0x94/0x98`; `FUN_0058eca0` =
    `SetPossessor(this,player)` (`this+0x40`, possession counter `this+0x80`). It is also what all
    players orient to and what the 3 sibling objects point at. No other football-sim object fits.
  - **GAP (flag, do NOT fill):** a literal goal-line-cross test as the final nail; and the **class of
    the 3 sibling objects** (`FUN_005a2640`; each holds ball-ptr `this+0x190`) — likely teams / a
    tracker, but not named without reading `FUN_005a2640`'s methods. **→ resolved in s7 below.**

  **3-SIBLING CLASS RESOLVED 2026-07-01 (s7, CORRECTED s8) — they are the two per-team KEEPERS + the
  REFEREE, matching the existing `Pm98Match` port.** ⚠️ s7 first mislabelled `+0xaac`/`+0xe74` as
  "TEAM 1/TEAM 2" — WRONG: one object per side (not 11), placed *in its own goal*, and keeper-save
  `FUN_0058f140` runs on this class → it is the GOALKEEPER; the 20 outfield players are a separate
  array (`Pm98Match._build_player`). Construction disasm `0x5911d7-0x591242` + Ghidra
  (`docs/re/move/siblings/fn_005a2140`,`_005b5790`,`_005a2240`,`_005b5940`,`_005a4560`; ctor
  `move/camwriter/fn_005a2640`) + `Pm98Match.gd`/`Pm98Predicates.gd`:
  - Ctor `FUN_005a2640(this,matchctx)` → base vtables `0x639224→0x639238→0x639228`, `this+0x18c=matchctx`,
    `this+0x190=matchctx+0x1610` (ball). Construction then stamps team index `this+0x3bc`: `+0xaac`→**1**,
    `+0xe74`→**2** (keeper vtable `0x639208`); `+0x123c` gets no index + referee vtable `0x6391f8`.
  - **`+0xaac` = KEEPER (team 1), `+0xe74` = KEEPER (team 2).** Keeper slot-1 `FUN_005a2140`, at reset,
    positions each keeper **in its own goal by the 1/2 index**: idx1 `y=-0x10000-[mc+0x1824]`,
    `x=[mc+0x1820]/2`; idx2 `y=[mc+0x1824]+0x10000`, `x=-[mc+0x1820]/2` (`mc+0x1820/0x1824` = pitch
    width / half-length). Per-keeper data block `this+0x2dc = [mc+0x1a5c]+(idx==1?5:6)*0x100`
    (base+0x500 / +0x600). Keeper-save geometry = `FUN_0058f140`.
  - **`+0x123c` = REFEREE.** `FUN_005b5790` forces `this+0x3bc=0`, block base+0x400, and positions from
    the **ball + restart type**: `switch([mc+0x448])` reads ball goal-geom `ball+0x90/0x94/0x98`
    (`this+0x190`); on free-kick/penalty (`FUN_005b5dd0`) it walks to restart target `mc+0x16a0..0x16a8`.
  - Shared per-frame quadruplet `{5a5460,5a3400,5a4560,5a4600}`; slot 2 `FUN_005a4560` copies an
    **81-dword (0x51) record** `this+0x3b0[DAT_006d31c0] → this+0x40` per frame (corrects s6's loose
    "0x1dc + idx*0x191" → base `this+0x3b0`, stride `0x51` dwords).
  - **Still-open GAPs:** ball goal-line-cross test; home/away ↔ keeper-idx 1/2 mapping;
    `matchctx+0x1a5c` provenance (embedded object, vtable `0x6267b0`, built `0x5420c5` on unverified base).
