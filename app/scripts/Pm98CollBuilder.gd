class_name Pm98CollBuilder
extends RefCounted
## EXACT port of MANAGER.EXE FUN_005946f0 -- the goal/pitch collision-geometry BUILDER that
## fills match+0x17f4 (the post/collider array the headless ball physics iterates) +0x17f8
## (its count). See docs/re/goal/collision_geometry_builder_re.md.
##
## The binary grows its arrays through FUN_005bbf10 (a Win32 GlobalReAlloc wrapper) and runs
## element ctors/dtors + an RGB565 palette lookup -- NONE of which touch the post geometry, so
## the port models the allocator as Array.append, the ctors/dtors as no-ops, and skips the
## color (post +0x64 is never read by the collision). Every PURE geometry leaf is the already
## oracle-validated Pm98Trig primitive. The whole thing is validated bit-exact against the
## PCode emu (allocator/ctor/dtor/color/net-pair stubbed) in tools/re/run_collbuilder_oracle.sh
## -> specs/collbuilder_oracle.txt, and phase 0 alone against run_collbuilder_frame.sh ->
## specs/collbuilder_frame.txt, both locked in app/tests/test_collbuilder.gd.
##
## ADDRESS MODEL: the constant-fold (phase 0) builds stack-resident source quad tables that the
## phase 1-4 loops walk by pointer. We model the frame as a Dictionary F keyed by the Ghidra
## local NUMBER X (so F[0x48c] == decompile local_48c). A vec3 pointer holds an X; the 3 ints it
## points at are at INCREASING address = DECREASING X: vec3(X) = [F[X], F[X-4], F[X-8]]. Pointer
## arithmetic in int units: `p + n` == X - 4n, `p - n` == X + 4n. (Frame dump maps X -> esp
## offset 0x618 - X, used only by the test.)

const I32 := 0xffffffff


static func _mi(m: Dictionary, off: int) -> int:
	return Pm98Trig._i32(int(m.get(off, 0)))


# ---- phase 0: the constant-fold (decompile 382-692). Returns F keyed by local number. -------
static func build_frame(m: Dictionary) -> Dictionary:
	var F := {}
	var l498 := _mi(m, 0x1974); F[0x498] = l498
	F[0x4b0] = Pm98Trig._i32(-0x10000 - l498)
	var l494 := _mi(m, 0x1978); F[0x494] = l494
	F[0x4a4] = Pm98Trig._i32(l498 + 0x10000)
	F[0x4ac] = Pm98Trig._i32(l494 + 0x10000)
	F[0x4a8] = 0x11999
	var l468 := _mi(m, 0x1970); F[0x468] = l468
	F[0x48c] = Pm98Trig._i32(-l498)
	F[0x474] = Pm98Trig._i32(l468 + 0x10000)
	var l464 := _mi(m, 0x197c); F[0x464] = l464
	F[0x49c] = 0x11999
	F[0x470] = Pm98Trig._i32(l464 + 0x10000)
	F[0x450] = Pm98Trig._i32(l468 + 0x10000)
	F[0x44c] = Pm98Trig._i32(l464 + 0x10000)
	F[0x444] = Pm98Trig._i32(l468 + 0x10000)
	F[0x440] = Pm98Trig._i32(-0x10000 - l464)
	F[0x434] = Pm98Trig._i32(-l464)
	F[0x420] = Pm98Trig._i32(l468 + 0x10000)
	F[0x414] = Pm98Trig._i32(l498 + 0x10000)
	F[0x410] = Pm98Trig._i32(-0x10000 - l494)
	F[0x490] = 0; F[0x484] = 0; F[0x478] = 0x11999; F[0x46c] = 0x11999
	F[0x460] = 0; F[0x454] = 0; F[0x448] = 0x11999; F[0x43c] = 0x11999
	F[0x430] = 0; F[0x424] = 0; F[0x418] = 0x11999; F[0x40c] = 0x11999
	F[0x404] = Pm98Trig._i32(-l494)
	F[0x3f0] = Pm98Trig._i32(l498 + 0x10000)
	F[0x3b4] = Pm98Trig._i32(-0x10000 - l468)
	F[0x35c] = Pm98Trig._i32(l464 + 0x10000)
	F[0x380] = Pm98Trig._i32(l464 + 0x10000)
	F[0x350] = Pm98Trig._i32(l494 + 0x10000)
	F[0x3a8] = Pm98Trig._i32(-l468)
	var l264 := _mi(m, 0x1820); F[0x264] = l264
	F[0x400] = 0; F[0x3f4] = 0; F[0x3e8] = 0x11999; F[0x3dc] = 0x11999
	F[0x3d0] = 0; F[0x3c4] = 0; F[0x3b8] = 0x11999; F[0x3ac] = 0x11999
	F[0x3a0] = 0; F[0x394] = 0; F[0x388] = 0x11999; F[0x37c] = 0x11999
	F[0x370] = 0; F[0x364] = 0; F[0x358] = 0x11999; F[0x34c] = 0x11999
	F[0x340] = 0; F[0x334] = 0
	F[0x32c] = 0x3a8f5; F[0x320] = 0x3a8f5; F[0x314] = 0x3a8f5
	F[0x330] = Pm98Trig._i32(-0x10000 - l264)
	F[0x324] = Pm98Trig._i32(-l264)
	F[0x30c] = Pm98Trig._i32(-0x20000 - l264)
	F[0x270] = Pm98Trig._i32(l264 + 0x10000)
	F[0x24c] = Pm98Trig._i32(l264 + 0x20000)
	F[0x328] = 0x270a3; F[0x31c] = 0x270a3; F[0x310] = 0; F[0x308] = 0x3a8f5; F[0x304] = 0
	F[0x2fc] = -0x3a8f5; F[0x2f8] = 0x270a3; F[0x2f0] = -0x3a8f5; F[0x2ec] = 0x270a3
	F[0x2e4] = -0x3a8f5; F[0x2e0] = 0; F[0x2d8] = -0x3a8f5; F[0x2d4] = 0; F[0x2cc] = -0x3a8f5
	F[0x2c8] = 0x270a3; F[0x2c0] = 0x3a8f5; F[0x2bc] = 0x270a3; F[0x2b4] = 0x3a8f5; F[0x2b0] = 0
	F[0x2a8] = -0x3a8f5; F[0x2a4] = 0; F[0x29c] = 0x3a8f5; F[0x298] = 0x270a3; F[0x290] = -0x3a8f5
	F[0x28c] = 0x270a3; F[0x284] = -0x3a8f5; F[0x280] = 0x270a3; F[0x278] = 0x3a8f5; F[0x274] = 0x270a3
	F[0x26c] = -0x3a8f5; F[0x268] = 0x270a3; F[0x260] = -0x3a8f5; F[0x25c] = 0x270a3; F[0x254] = -0x3a8f5
	F[0x250] = 0; F[0x248] = -0x3a8f5; F[0x244] = 0; F[0x23c] = 0x3a8f5; F[0x238] = 0x270a3
	F[0x230] = 0x3a8f5; F[0x22c] = 0x270a3; F[0x224] = 0x3a8f5; F[0x220] = 0; F[0x218] = 0x3a8f5
	F[0x208] = 0x270a3; F[0x1e8] = 0x3a8f5; F[0x1d0] = 0x3a8f5; F[0x1c4] = 0x3a8f5
	var l1a4 := _mi(m, 0x1954); F[0x1a4] = l1a4
	F[0x1fc] = 0x270a3; F[0x1d8] = 0x270a3; F[0x1cc] = 0x270a3; F[0x1c0] = 0x270a3; F[0x1b4] = 0x270a3
	F[0x1b0] = Pm98Trig._i32(-l1a4)
	F[0x200] = -0x3a8f5; F[0x1f4] = -0x3a8f5; F[0x1dc] = -0x3a8f5; F[0x1b8] = -0x3a8f5
	F[0x1ac] = _mi(m, 0x1960)
	var l198 := _mi(m, 0x1958); F[0x198] = l198
	F[0x18c] = Pm98Trig._i32(-l198)
	F[0x180] = _mi(m, 0x1954)
	F[0x17c] = Pm98Trig._i32(-_mi(m, 0x1960))
	var l194 := _mi(m, 0x1968); F[0x194] = l194
	F[0x164] = Pm98Trig._i32(-l194)
	F[0x150] = _mi(m, 0x1950)
	F[0x1a8] = Pm98Trig._i32((_mi(m, 0x194c) * 3) / 2)
	F[0x14c] = Pm98Trig._i32(-_mi(m, 0x1964))
	F[0x214] = 0; F[0x20c] = 0x3a8f5; F[0x1f0] = 0; F[0x1e4] = 0; F[0x190] = 0; F[0x184] = 0
	F[0x160] = 0; F[0x154] = 0
	F[0x144] = _mi(m, 0x1950); F[0x140] = _mi(m, 0x1964)
	F[0x120] = Pm98Trig._i32(-_mi(m, 0x1950)); F[0x11c] = _mi(m, 0x1964)
	F[0xf0] = _mi(m, 0x1954); F[0xec] = _mi(m, 0x1960)
	F[0xe4] = _mi(m, 0x1950); F[0xe0] = _mi(m, 0x1964)
	F[0xd4] = _mi(m, 0x196c); F[0xcc] = _mi(m, 0x195c)
	F[0xa4] = Pm98Trig._i32(-_mi(m, 0x196c)); F[0x9c] = Pm98Trig._i32(-_mi(m, 0x195c))
	F[0x8c] = _mi(m, 0x1964)
	F[0x130] = 0; F[0x124] = 0; F[0x100] = 0; F[0xf4] = 0; F[0xd0] = 0; F[0xc4] = 0; F[0xa0] = 0; F[0x94] = 0
	F[0x68] = _mi(m, 0x196c); F[0x48] = _mi(m, 0x195c); F[0x60] = _mi(m, 0x1950)
	F[0x80] = _mi(m, 0x1960); F[0x54] = _mi(m, 0x1954)
	# array-style writes (local_568[i], local_5d0[i], local_538[i])
	F[0x564] = 1; F[0x55c] = 1; F[0x554] = 1; F[0x54c] = 1            # local_568[1], 55c, 554, 54c
	F[0x5c8] = 0x1000; F[0x5c4] = 0x1000                              # local_5d0[2],[3]
	F[0x534] = 0x1000; F[0x530] = 0x1000                              # local_538[1],[2]
	F[0x70] = 0; F[0x64] = 0; F[0x40] = 0; F[0x34] = 0
	F[0x568] = 8; F[0x560] = 5; F[0x558] = 8; F[0x550] = 5            # local_568[0], 560, 558, 550
	F[0x5d0] = -0x1000; F[0x5cc] = -0x1000                            # local_5d0[0],[1]
	F[0x538] = -0x1000; F[0x52c] = Pm98Trig._i32(0xfffff000)          # local_538[0],[3]
	# the local_A = local_B copies (582-692)
	F[0x4a0] = F[0x4ac]; F[0x488] = l494; F[0x480] = F[0x4a4]; F[0x47c] = F[0x4ac]
	F[0x45c] = l498; F[0x458] = l494; F[0x438] = l468; F[0x42c] = l468; F[0x428] = l464
	F[0x41c] = F[0x440]; F[0x408] = l498; F[0x3fc] = l468; F[0x3f8] = F[0x434]; F[0x3ec] = F[0x410]
	F[0x3e4] = F[0x4b0]; F[0x3e0] = F[0x410]; F[0x3d8] = F[0x48c]; F[0x3d4] = F[0x404]
	F[0x3cc] = l498; F[0x3c8] = F[0x404]; F[0x3c0] = F[0x4b0]; F[0x3bc] = F[0x410]
	F[0x3b0] = F[0x440]; F[0x3a4] = F[0x434]; F[0x39c] = F[0x48c]; F[0x398] = F[0x404]
	F[0x390] = F[0x3b4]; F[0x38c] = F[0x440]; F[0x384] = F[0x3b4]; F[0x378] = F[0x3a8]
	F[0x374] = l464; F[0x36c] = F[0x3a8]; F[0x368] = F[0x434]; F[0x360] = F[0x3b4]
	F[0x354] = F[0x4b0]; F[0x348] = F[0x48c]; F[0x344] = l494; F[0x33c] = F[0x3a8]; F[0x338] = l464
	F[0x318] = F[0x324]; F[0x300] = F[0x324]; F[0x2f4] = F[0x330]; F[0x2e8] = F[0x30c]
	F[0x2dc] = F[0x324]; F[0x2d0] = F[0x330]; F[0x2c4] = F[0x330]; F[0x2b8] = F[0x30c]
	F[0x2ac] = F[0x30c]; F[0x2a0] = F[0x330]; F[0x294] = F[0x330]; F[0x288] = F[0x324]; F[0x27c] = F[0x324]
	F[0x258] = l264; F[0x240] = l264; F[0x234] = F[0x270]; F[0x228] = F[0x24c]; F[0x21c] = l264
	F[0x210] = F[0x270]; F[0x204] = F[0x270]; F[0x1f8] = F[0x24c]; F[0x1ec] = F[0x24c]
	F[0x1e0] = F[0x270]; F[0x1d4] = F[0x270]; F[0x1c8] = l264; F[0x1bc] = l264
	F[0x1a0] = F[0x1ac]; F[0x19c] = F[0x1a8]; F[0x188] = l194; F[0x178] = F[0x1a8]
	F[0x174] = F[0x1b0]; F[0x170] = F[0x17c]; F[0x16c] = F[0x1a8]; F[0x168] = F[0x18c]
	F[0x15c] = l198; F[0x158] = F[0x164]; F[0x148] = F[0x1a8]; F[0x13c] = F[0x1a8]
	F[0x138] = l198; F[0x134] = l194; F[0x12c] = l198; F[0x128] = F[0x164]; F[0x118] = F[0x1a8]
	F[0x114] = F[0x120]; F[0x110] = F[0x14c]; F[0x10c] = F[0x1a8]; F[0x108] = F[0x18c]; F[0x104] = F[0x164]
	F[0xfc] = F[0x18c]; F[0xf8] = l194; F[0xe8] = F[0x1a8]; F[0xdc] = F[0x1a8]; F[0xd8] = l198
	F[0xc8] = l194; F[0xc0] = F[0x1b0]; F[0xbc] = F[0x17c]; F[0xb8] = F[0x1a8]
	F[0xb4] = F[0x120]; F[0xb0] = F[0x14c]; F[0xac] = F[0x1a8]; F[0xa8] = F[0x18c]; F[0x98] = F[0x164]
	F[0x90] = F[0x120]; F[0x88] = F[0x1a8]; F[0x84] = F[0x1b0]; F[0x7c] = F[0x1a8]; F[0x78] = F[0x9c]
	F[0x74] = l194; F[0x6c] = F[0x18c]; F[0x5c] = F[0x14c]; F[0x58] = F[0x1a8]; F[0x50] = F[0x17c]
	F[0x4c] = F[0x1a8]; F[0x44] = F[0x164]; F[0x3c] = l198; F[0x38] = F[0xa4]
	# ---- phase-0 scratch temporaries: disasm [esp+0x10..0x38] (D = 0x61c - X), the negated
	# goal-dim seeds the phase-1 group setup/inner-loop reads. Re-derived from disasm with the
	# +4 edi-push correction (dump EBASE is the 3-push body esp; the [esp+X] writes run after a
	# 4th `push edi`, so disasm off D maps to dump off D-4, i.e. X = 0x61c - D). Each matches the
	# emu frame dump bit-exact. F[0x5ec] = disasm [esp+0x30] = the `this`/match base POINTER, not
	# geometry, so it is deliberately NOT modeled (excluded from the test completeness check).
	F[0x60c] = Pm98Trig._i32(-_mi(m, 0x1960))           # [esp+0x10]
	F[0x608] = Pm98Trig._i32(-_mi(m, 0x1950))           # [esp+0x14]
	F[0x604] = Pm98Trig._i32(-_mi(m, 0x1958))           # [esp+0x18]
	F[0x600] = Pm98Trig._i32(-_mi(m, 0x1978))           # [esp+0x1c]
	F[0x5fc] = Pm98Trig._i32(-_mi(m, 0x1968))           # [esp+0x20]
	F[0x5f8] = Pm98Trig._i32(-_mi(m, 0x1964))           # [esp+0x24]
	F[0x5f4] = Pm98Trig._i32(-_mi(m, 0x196c))           # [esp+0x28]
	F[0x5f0] = Pm98Trig._i32(_mi(m, 0x1820) - 0xccc)    # [esp+0x2c] goal-line x - 0xccc
	F[0x5e4] = Pm98Trig._i32(-_mi(m, 0x195c))           # [esp+0x38]
	return F


## vec3 at frame local X: increasing address = decreasing X (see ADDRESS MODEL header).
static func _vec3(F: Dictionary, x: int) -> Array:
	return [Pm98Trig._i32(int(F.get(x, 0))), Pm98Trig._i32(int(F.get(x - 4, 0))), Pm98Trig._i32(int(F.get(x - 8, 0)))]


# ---- phase 1: the +0x27c8 master-geometry fan (decompile loop, disasm 0x5952ff..0x5955c4).
# 8 groups, counts [8,1,5,1,8,1,5,1] = 30 master entries (MASTER 0-29). Each group walks a
# 4-corner SOURCE quad in the phase-0 frame: src pointer = &local_48c stepping -0x30 BYTES per
# group, i.e. src_X = 0x48c - g*0x30; corners A=src B=src-0xc C=src-0x18 D=src-0x24 (byte ptr
# DECR addr = X+0xc each). For entry i of N the master quad is the trapezoid slice:
#   c0=lerp(D,C, i,N)  c1=lerp(D,C, i+1,N)  c2=lerp(A,B, i+1,N)  c3=lerp(A,B, i,N)
# (the binary's 3 chained vec3_lerp + 3 quad_bilerp reduce to exactly these 4 edge lerps; the
# stdcall arg-recycling was decoded structurally and confirmed bit-exact vs the MASTER oracle).
const _PHASE1_COUNTS := [8, 1, 5, 1, 8, 1, 5, 1]


static func _build_phase1(F: Dictionary, master: Array) -> void:
	for g in range(8):
		var src := 0x48c - g * 0x30
		var a := _vec3(F, src)
		var b := _vec3(F, src + 0xc)
		var c := _vec3(F, src + 0x18)
		var d := _vec3(F, src + 0x24)
		var n: int = _PHASE1_COUNTS[g]
		for i in range(n):
			var c0 := Pm98Trig.vec3_lerp(d, c, i, n)
			var c1 := Pm98Trig.vec3_lerp(d, c, i + 1, n)
			var c2 := Pm98Trig.vec3_lerp(a, b, i + 1, n)
			var c3 := Pm98Trig.vec3_lerp(a, b, i, n)
			master.append(c0 + c1 + c2 + c3)


# ---- phase 2: the net box (MASTER 30-37), disasm 0x5955e9.. The loop does NO lerp -- it
# `rep movs 0xc` a straight 12-int quad from the frame, 8 entries, source X = 0x330 - e*0x30
# (src ptr = &local_314, copy reads ptr-0x1c = X 0x330 first). Each quad = 4 consecutive
# vec3s. (The per-entry +0x64 color / +0x68 render-rect are display fields, not in the +0x20
# quad oracle, so omitted.)
static func _build_phase2(F: Dictionary, master: Array) -> void:
	for e in range(8):
		var x := 0x330 - e * 0x30
		master.append(_vec3(F, x) + _vec3(F, x - 0xc) + _vec3(F, x - 0x18) + _vec3(F, x - 0x24))


# ---- phase 3: the goal-frame boxes (MASTER 38-61 = the 0x9eb8 scoring posts), disasm
# 0x5957da..0x595d5a (the +0x27d70/+0x751ea nested grid). Decode result: every corner is
# (x, y, z) where ONLY x depends on m: x = sx*F[0x5f0] + tx, sx=+-1, tx=+-0x1000 (the post
# half-thickness, a frame literal); F[0x5f0]=m[0x1820]-0xccc is the goal-line plane. y and z
# are hardcoded immediates in the binary (0x3a8f5/0x27d70/0x751ea/0x28ccc +-0x1000), m-INDEP,
# so they are baked verbatim from the oracle. Per-corner (sx, tx, y, z) template below; 8
# groups x 3 sub-quads. Validated bit-exact vs oracle MASTER 38-61 (synthetic F[0x5f0]=0x8f334).
const _PHASE3 := [
	[-1, -4096, -239861, 159088, -1, -4096, -239861, 167280, -1, -4096, 239861, 167280, -1, -4096, 239861, 159088],
	[-1, -4096, -243957, 167116, -1, -4096, -235765, 167116, -1, -4096, -235765, 0, -1, -4096, -243957, 0],
	[-1, -4096, 235765, 167116, -1, -4096, 243957, 167116, -1, -4096, 243957, 0, -1, -4096, 235765, 0],
	[1, -4096, -239861, 159088, 1, -4096, -239861, 167280, 1, -4096, 239861, 167280, 1, -4096, 239861, 159088],
	[1, -4096, -243957, 167116, 1, -4096, -235765, 167116, 1, -4096, -235765, 0, 1, -4096, -243957, 0],
	[1, -4096, 235765, 167116, 1, -4096, 243957, 167116, 1, -4096, 243957, 0, 1, -4096, 235765, 0],
	[-1, -4096, -239861, 167280, -1, 4096, -239861, 167280, -1, 4096, 239861, 167280, -1, -4096, 239861, 167280],
	[-1, -4096, -235765, 167116, -1, 4096, -235765, 167116, -1, 4096, -235765, 0, -1, -4096, -235765, 0],
	[-1, -4096, 243957, 167116, -1, 4096, 243957, 167116, -1, 4096, 243957, 0, -1, -4096, 243957, 0],
	[1, -4096, -239861, 167280, 1, 4096, -239861, 167280, 1, 4096, 239861, 167280, 1, -4096, 239861, 167280],
	[1, -4096, -235765, 167116, 1, 4096, -235765, 167116, 1, 4096, -235765, 0, 1, -4096, -235765, 0],
	[1, -4096, 243957, 167116, 1, 4096, 243957, 167116, 1, 4096, 243957, 0, 1, -4096, 243957, 0],
	[-1, 4096, -239861, 167280, -1, 4096, -239861, 159088, -1, 4096, 239861, 159088, -1, 4096, 239861, 167280],
	[-1, 4096, -235765, 167116, -1, 4096, -243957, 167116, -1, 4096, -243957, 0, -1, 4096, -235765, 0],
	[-1, 4096, 243957, 167116, -1, 4096, 235765, 167116, -1, 4096, 235765, 0, -1, 4096, 243957, 0],
	[1, 4096, -239861, 167280, 1, 4096, -239861, 159088, 1, 4096, 239861, 159088, 1, 4096, 239861, 167280],
	[1, 4096, -235765, 167116, 1, 4096, -243957, 167116, 1, 4096, -243957, 0, 1, 4096, -235765, 0],
	[1, 4096, 243957, 167116, 1, 4096, 235765, 167116, 1, 4096, 235765, 0, 1, 4096, 243957, 0],
	[-1, 4096, -239861, 159088, -1, -4096, -239861, 159088, -1, -4096, 239861, 159088, -1, 4096, 239861, 159088],
	[-1, 4096, -243957, 167116, -1, -4096, -243957, 167116, -1, -4096, -243957, 0, -1, 4096, -243957, 0],
	[-1, 4096, 235765, 167116, -1, -4096, 235765, 167116, -1, -4096, 235765, 0, -1, 4096, 235765, 0],
	[1, 4096, -239861, 159088, 1, -4096, -239861, 159088, 1, -4096, 239861, 159088, 1, 4096, 239861, 159088],
	[1, 4096, -243957, 167116, 1, -4096, -243957, 167116, 1, -4096, -243957, 0, 1, 4096, -243957, 0],
	[1, 4096, 235765, 167116, 1, -4096, 235765, 167116, 1, -4096, 235765, 0, 1, 4096, 235765, 0],
]


static func _build_phase3(F: Dictionary, master: Array) -> void:
	var f5f0 := Pm98Trig._i32(int(F.get(0x5f0, 0)))
	for row in _PHASE3:
		var quad := []
		for c in range(4):
			var sx: int = row[c * 4]
			var tx: int = row[c * 4 + 1]
			quad.append(Pm98Trig._i32(sx * f5f0 + tx))   # x
			quad.append(row[c * 4 + 2])                  # y
			quad.append(row[c * 4 + 3])                  # z
		master.append(quad)


# ---- phase 4: fill the post/collider array +0x17f4 (disasm 0x595d94..0x59617f). Three copy
# loops; each post (22 oracle words) = quad(12) + AABB(6) + normal(3) + id(1):
#   1. crossbar  id 0x7ae1  (if m[0x1a1b]!=0): quad = master[0..29] +0x20 quad.
#   2. net-post  id 0x8000  (always, 8): quad copied from the frame net table X=0x1b0-e*0x30.
#   3. goal-line id 0x9eb8  (if master count > 0x26): quad = master[38..61].
# Per post: AABB = aabb_init -> expand over the 4 corners -> expand once more by (min + 1)
# (gives a degenerate axis thickness 1; verified vs POST 38 maxx=minx+1). normal = face_normal.
static func _make_post(quad: Array, post_id: int) -> Array:
	var aabb := Pm98Trig.aabb_init()
	for c in range(4):
		aabb = Pm98Trig.aabb_expand_point(aabb, [quad[c * 3], quad[c * 3 + 1], quad[c * 3 + 2]])
	aabb = Pm98Trig.aabb_expand_point(
		aabb, [Pm98Trig._i32(aabb[0] + 1), Pm98Trig._i32(aabb[1] + 1), Pm98Trig._i32(aabb[2] + 1)]
	)
	return quad + aabb + Pm98Trig.quad_face_normal(quad) + [post_id]


static func _build_posts(F: Dictionary, m: Dictionary, master: Array, posts: Array) -> void:
	if _mi(m, 0x1a1b) != 0:
		for i in range(30):
			posts.append(_make_post(master[i], 0x7ae1))
	for e in range(8):
		var x := 0x1b0 - e * 0x30
		var quad := _vec3(F, x) + _vec3(F, x - 0xc) + _vec3(F, x - 0x18) + _vec3(F, x - 0x24)
		posts.append(_make_post(quad, 0x8000))
	if master.size() > 0x26:
		for i in range(38, 62):
			posts.append(_make_post(master[i], 0x9eb8))


# ---- top-level builder: returns {"master": [[12 ints]...], "posts": [[22 ints]...]}.
static func build(m: Dictionary) -> Dictionary:
	var F := build_frame(m)
	var master := []
	_build_phase1(F, master)
	_build_phase2(F, master)
	_build_phase3(F, master)
	var posts := []
	_build_posts(F, m, master, posts)
	return {"master": master, "posts": posts}
