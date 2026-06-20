# PM98 — goal/pitch collision-geometry builder (FUN_005946f0) RE map — 2026-06-20

Verified by reading the decompile (`/tmp/pm98dec/fn_005946f0`), the disasm
(`/tmp/pm98_disasm.txt`), the ball-collision gate, the match ctor, and the leaf
decompiles. This is the function that POPULATES the per-tick collider list the headless
ball physics iterates — i.e. the genuine prerequisite for the full-match KILL-TEST,
NOT the goal-frame mesh sweep the prior handoff led with. Cite this; do not re-derive.

## TL;DR — the priority correction
The prior handoff (`handoff-pm98-balltail-keeper-collloop-2026-06-20`) put **FUN_005f3b80
+ FUN_005f3850 (goal-frame TRIANGLE-MESH swept-sphere)** as the next-session priority,
blocked on the mesh asset loader. **That whole path is DISPLAY-ONLY and is NOT on the
headless scoreline path.** Proof below. The real unblock for the kill-test is
**FUN_005946f0**, the collision-geometry builder, which fills `match+0x17f4` (the post
array the ball physics actually collides against) inside its `match+0x5fac == 0`
(headless) branch.

## Proof: f3b80 is gated OUT in headless (so item-1 is not a kill-test blocker)
Ball ADVANCE FUN_0058e2c0, collision phase (disasm):
```
58e43a:  mov  cl, BYTE PTR [eax+0x5fac]   ; eax = match
58e440:  test cl,cl
58e442:  je   0x58e632                     ; 0x5fac==0  -> SKIP the whole goal-frame block
  58e4a9:  call 0x5f3b80                    ; (inside the skipped block)
  58e56e:  call 0x5f3b80                    ; (inside the skipped block)
58e632:  ...                               ; <-- headless lands here
  58e65b:  call 0x590b30                    ; post-loop seg-test (PORTED)
  58e67d:  call 0x5efac0                    ; post-loop narrow-phase = _post_narrow (PORTED)
```
`match+0x5fac` is written exactly once, in the match ctor FUN_00591180 @ 0x591524
(`mov BYTE PTR [esi+0x5fac],bl`, bl=0). No other writer via the literal offset. So in a
headless run it stays 0, the two `call 0x5f3b80` never execute, and the woodwork/goal
collision for the scoreline comes entirely from the **post loop** over
`match+0x17f4 / +0x17f8` (both leaves already ported). The goal-frame mesh sweep (f3b80
→ f3850 → FUN_005ef4b0) draws/handles the on-screen net only.

Corollary: FUN_005946f0's own tail at lines 1249-1260 (`if (match+0x5fac != 0)`) and
the mesh selectors at `ball+0x100/+0x108` are also display-side. The mesh asset loader
the prior handoff wanted is NOT required for the headless engine.

## FUN_005946f0 — what it is
`void __fastcall FUN_005946f0(int match)` — entry 0x5946f0, size 0x1ce5 (7397 bytes),
frame 0x60c. Called from match setup (0x593d8b, 0x593e62) and 0x5982ee. It procedurally
builds the goal/pitch collision + render geometry from the match's goal-dimension fields
and writes FOUR container members on `match`:

| member       | stride | dtor       | content                                            |
|--------------|--------|------------|----------------------------------------------------|
| `+0x27c8`    | 0x78   | FUN_005963e0 | the master geometry array (render quads + meta). Built first; the post array is COPIED from its `+0x20` quad sub-field. Count in `+0x27cc`. |
| `+0x17f4`    | 0x58   | 0x4ec5c0   | **the post/collider array** (the headless-relevant one). Count in `+0x17f8`. |
| `+0x27d0`    | 0x18   | FUN_005a1d40/00596410 | pointer list: post addrs + the 4 sub-entities (`+0xaac` GK1, `+0xe74` GK2, `+0x123c` ref, `+0x1610` ball) + player rows (`+0x46c`, stride 0x3bc). Count in `+0x27d4`. |
| `+0x2ba4`    | 0xc    | —          | a 2-entry array (net corner pair, via FUN_005ba7d0). Count in `+0x2ba8`. |

All four are grown element-by-element through **FUN_005bbf10** (a Win32
GlobalAlloc/GlobalReAlloc wrapper — see "oracle blocker").

### post array element (stride 0x58) layout — read by the ball collision + _post_narrow
- `+0x00..+0x2c` : 4×vec3 oriented-quad corners (copied from a `+0x27c8` entry's `+0x20`)
- `+0x04..+0x18` : overwritten with segment endpoints + edge data (the leaves below)
- `+0x30..+0x47` : AABB (min/max vec3) — FUN_00590aa0/ac0/be0 accumulate it
- `+0x48..+0x53` : `+0x48` edge orientation vec (FUN_005efa40 edge-normal), used by efac0
- `+0x50`        : restitution/material id (1 or 2)
- `+0x54`        : **post id** — `0x7ae1` crossbar, `0x8000` net-post, `0x9eb8` goal-line,
                   `0x0001` (id=1 generic), `0x0002`. The scoreline only cares about `0x9eb8`.
- `+0x58`        : flag (0/1)
- `+0x5c`        : `4 - (match+0x1988 == 0)`  (3 or 4 — a layer/bounce count)
- `+0x60`        : 0 / 7 / 9 (group tag)
- `+0x64`        : color/material (palette via FUN_005a1c00) or `match+0x1a4c + 0x10000`
- `+0x68..+0x77` : a 4-int render rect (only set for the net/woodwork groups)

### the post-array fill (lines 1037-1167, the `match+0x5fac == 0` HEADLESS branch)
Three copy loops, each: grow `+0x17f4` by one 0x58 slot, `rep movs 0xc` the quad from a
`+0x27c8` entry's `+0x20`, run the segment/AABB/normal leaves, stamp the id:
1. **crossbar** id `0x7ae1` — only if `match+0x1a1b != 0`; src offset 0..0xe10 step 0x78
   (30 entries) into `+0x27c8`.
2. **net-post** id `0x8000` — always; 8 entries from the `local_1b0` corner table.
3. **goal-line** id `0x9eb8` — only if `0x26 < match+0x27cc`; src offset 0x11d0 step 0x78.

## Input fields on `match` (the goal/pitch dimensions this reads)
`+0x1950, +0x1954, +0x1958, +0x195c, +0x1960, +0x1964, +0x1968, +0x196c` (pitch/goal box
extents), `+0x1970, +0x1974, +0x1978, +0x197c` (goal mouth corners), `+0x1820` (goal-line
x), `+0x1988` (home/away or half selector — gates the `4 - (==0)` and the rect choice),
`+0x1a1b` (crossbar-present flag), `+0x1a1c` (net flag, → FUN_005ba7d0 arg), `+0x1a4c`
(net top z), `+0x27cc` (master geometry count, decremented to 0 at entry then rebuilt),
`+0x1954` reused. The `±0x10000` (=1.0 in 16.16), `0x11999` (~1.1), `0x3a8f5`/`0x270a3`/
`0xfffc570b`/`0x751ea` constants are the fixed goal-frame corner offsets / net-fan angles.

## Leaf inventory (what the GDScript port needs)
PURE (no allocator → individually PCode-oracle-able):
- FUN_00590aa0 vec3 store — **PORTED** (Pm98Trig.vec3_store).
- FUN_005ee290 vec3 scale by ratio (64-bit mul/idiv) — **PORTED** (Pm98Trig.vec3_scale_ratio).
- FUN_005a1870 vec3 ÷ scalar (truncating idiv) — **PORTED 2026-06-20** (Pm98Trig.vec3_div_scalar).
- FUN_005a1990 quad copy (12 int32 straight move) — **PORTED 2026-06-20** (Pm98Trig.quad_copy).
- FUN_005a18a0 vec3 lerp `a+(b-a)*m/d` — **PORTED 2026-06-20** (Pm98Trig.vec3_lerp).
- FUN_005a1a30 quad bilinear `lerp(lerp(c0,c1,f1),lerp(c3,c2,f1),f2)` — **PORTED 2026-06-20** (Pm98Trig.quad_bilerp).
- FUN_005a1c00 RGB565→palette byte (DAT_00675398 LUT) — DEFERRED (needs 64KB palette
  export; only feeds the render `+0x64` color, not collision). 
- FUN_005efa40 quad face-normal — **PORTED 2026-06-20** (Pm98Trig.quad_face_normal). NOT
  fsqrt/ftol: its only callee FUN_005ee540 is a pure 16.16 cross product (64-bit imul +
  `sar 16`, Pm98Trig.cross16), no normalization. The prior "needs ftol stub" note was wrong
  (verified disasm 0x5ee540 = imul/shrd only; emu RET clean with no stubs).
- FUN_005a1730 broadcast-translate vec3 (+scalar to all 3) — **PORTED 2026-06-20** (vec3_add_scalar).
- FUN_005a1910 AABB init (+BIG/-BIG sentinels) — **PORTED 2026-06-20** (aabb_init).
- FUN_005a19d0 AABB expand-to-point (signed per-component min/max) — **PORTED 2026-06-20** (aabb_expand_point).
- FUN_00590ac0 vec3 copy — PORTED (Pm98Trig.vec3_store). FUN_00590be0 6-int/AABB copy — **PORTED 2026-06-20** (copy6).
ALLOCATOR / dtor (NOT emulatable, NOT needed once the loop structure is transcribed):
- FUN_005bbf10 GlobalReAlloc grow, FUN_005963e0 / FUN_00596410 / FUN_005a1d40 element
  dtors, FUN_00404a80 / FUN_005c8f80 / FUN_0044cac0 the `+0x27c8` element ctor.

## Oracle blocker (why this is multi-session, like f3850 was)
FUN_005bbf10 calls Win32 `GlobalAlloc`/`GlobalReAlloc`/`GlobalHandle`/`GlobalLock`
(imports) — uncallable in the Ghidra PCode emu, exactly the class of blocker the prior
handoff flagged for f3850. So FUN_005946f0 **cannot be run end-to-end in the emu** to
bank a ground-truth `+0x17f4`. The port strategy is therefore:
1. Port + oracle every PURE leaf individually (allocator-free) — DONE 2026-06-20 (9 done:
   div_scalar/quad_copy/lerp/bilerp + face_normal/add_scalar/aabb_init/aabb_expand/copy6;
   only the render-side RGB565 leaf FUN_005a1c00 deferred). test_geomleaf.gd = 93 checks.
2. Transcribe the loop structure from the decompile/disasm (the allocator becomes a
   GDScript `Array.append`; the dtors become no-ops).
3. Validate the ASSEMBLED `+0x17f4` against a ground-truth snapshot captured another way
   — either (a) a wine/debugger memory dump of `match+0x17f4` after FUN_005946f0 on a
   real kickoff, or (b) a hand-derived fixture for the simple goal-line posts, since the
   goal-line geometry is a pure function of `match+0x1820/+0x1970..0x197c`.

## Next-session plan (in order)
1. ~~Finish the pure leaves: FUN_005efa40, FUN_005a1730/1910/19d0, FUN_00590be0 (+oracles).~~
   DONE 2026-06-20 (all oracle-validated, test_geomleaf.gd 93 checks). NEXT real step ↓:
2. Port FUN_005946f0 phases 1-3 (the `+0x27c8` master geometry) using the leaves; then
   phase 4 (the `+0x17f4` post copy) is mechanical.
3. Capture/derive a ground-truth `+0x17f4` for one kickoff and pin it in a GDScript test.
4. Wire the post array into the ball free-flight collision loop (replace the empty array
   the loop currently sees) → then the woodwork bounces + goal-line crossing go live.
5. Port the driver FUN_00598740 → the full-match KILL-TEST (event-stream + scoreline
   parity, fixed seed, N>=50). Driver map: `docs/re/MATCH_TICK_DRIVER_MAP.md`.

## Disasm landmarks
FUN_005946f0 = 0x5946f0 (post fill 0x595d94..0x59617f, ids @ 0x595e67/0x595f69/0x59607e).
match ctor FUN_00591180 (zero-inits +0x17f4/+0x17f8 @ 0x591259, +0x5fac=0 @ 0x591524,
constructs the 8 `+0x2884`-stride-0x64 goal objects via ctor 0x5f2ad0). Ball collision
gate 0x58e43a. Decompiles in `/tmp/pm98dec/` (regen via DecompileAt.java).
