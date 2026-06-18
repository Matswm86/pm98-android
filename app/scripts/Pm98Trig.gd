class_name Pm98Trig
extends RefCounted
## EXACT port of MANAGER.EXE's trig / fixed-point subsystem -- the boot LUT
## initializer FUN_005edff0 and the reader primitives that consume it
## (docs/re/EXACT_PORT_PLAN.md, Stage 3 task 1). Like Pm98Resolver, every value
## here is the binary, not a parameter: do NOT "tune" it.
##
## FUN_005edff0 (disasm 0x5edff0..0x5ee073) fills TWO tables at boot, both used by
## the positional movement physics for real ball coordinates:
##   * cos LUT  @0x6d31c8 : 4096 int32, COS[k] = ftol(cos(k*C1)*C2),  k=0..4095
##   * atan LUT @0x6d71c8 : 8193 int16, ATAN[j] = ftol(atan(8j*C3)*C4), j=0..8192
## C1=2pi/4096, C2=65536.0, C3=1/65536, C4=0x4000/(pi/2) -- the EXACT 8-byte doubles
## from .rdata (0x63a040/48/50/58). ftol is the MSVC float->long cast (jmp *0x6233a4),
## i.e. TRUNCATION toward zero, NOT round-half (the prior session's round() guess was
## wrong; it happens to agree here only because no entry lands near a trunc boundary).
##
## Bit-exactness verified three ways (tools/re/lut_oracle.c): the binary's real x87
## `fcos`/`fpatan` under PC=64 AND PC=53 precision-control both equal the 64-bit
## double `cos()`/`atan2()` truncation for ALL 4096+8193 entries (0 differ). So
## GDScript's `int(cos(...)*65536)` reproduces the table exactly. The angle unit is
## 0x10000 = full circle (the cos table is indexed by angle>>4, 4096 steps).
##
## NOTE C1: the binary's cos-arg double is 0.0015339807878856446, which is NOT the
## naive `TAU/4096` (0.0015339807878856412, ~10 ULP off -- the compiler used a more
## precise pi). Using TAU/4096 would shift boundary entries, so the exact literal is
## pinned below. test_trig_lut.gd locks the whole table to tools/re/specs/*_lut.txt
## (banked from the real fcos/fpatan), and the readers to Python-derived vectors.

# Exact double constants from MANAGER.EXE .rdata (verified round-trip).
const _C1 := 0.0015339807878856446   # cos arg   @0x63a040  (2*pi/4096)
const _C2 := 65536.0                 # cos scale @0x63a048
const _C3 := 1.52587890625e-05       # atan arg  @0x63a050  (1/65536)
const _C4 := 10430.37835047043       # atan scale@0x63a058  (0x4000/(pi/2))

# Built once at class load by _static_init (mirrors FUN_005edff0 running at the
# match-subsystem init, guarded by flag 0x674ea4).
static var COS: PackedInt32Array
static var ATAN: PackedInt32Array


static func _static_init() -> void:
	COS = PackedInt32Array()
	COS.resize(4096)
	for k in 4096:
		# fild k; fmul C1; fcos; fmul C2; ftol(trunc) -- int() truncates toward zero.
		COS[k] = int(cos(float(k) * _C1) * _C2)
	ATAN = PackedInt32Array()
	ATAN.resize(8193)
	for j in 8193:
		# fild i; fmul C3; fld1; fpatan(atan2(i*C3,1)); fmul C4; ftol.  i = 8*j.
		ATAN[j] = int(atan2(float(8 * j) * _C3, 1.0) * _C4)


# ---- bit-width helpers ------------------------------------------------------

## Wrap to signed 32-bit (the binary stores results into 32-bit slots/eax).
static func _i32(v: int) -> int:
	v &= 0xffffffff
	return v - 0x100000000 if v >= 0x80000000 else v


## Sign-extend a 16-bit angle (the facing angles are `short`).
static func _s16(v: int) -> int:
	v &= 0xffff
	return v - 0x10000 if v >= 0x8000 else v


## Arithmetic shift right = floor(v / 2^n). x86 `sar`/`shrd` floor toward -inf;
## GDScript `>>` rejects negative operands and `/` truncates toward zero, so this
## is the faithful primitive for every fixed-point `>>16`/`sar` in the cluster.
static func _asr(v: int, n: int) -> int:
	if v >= 0:
		return v >> n
	return -(((-v) + ((1 << n) - 1)) >> n)


# ---- fixed-point 16.16 primitives -------------------------------------------

## FUN_005edfa0: (a*b) >> 16, signed (64-bit imul then shrd $0x10).
static func mul16(a: int, b: int) -> int:
	return _i32(_asr(a * b, 16))


## FUN_005edfb0: (c*d + a*b) >> 16 -- the fixed-point dot/muladd.
static func muladd16(a: int, b: int, c: int, d: int) -> int:
	return _i32(_asr(c * d + a * b, 16))


## FUN_005edf90: (0x10000 * a) / b -- signed truncating divide (imul 0x10000; idiv).
## GDScript int `/` truncates toward zero, matching x86 idiv. b must be nonzero.
static func ratio16(a: int, b: int) -> int:
	return _i32((0x10000 * a) / b)


# ---- trig readers -----------------------------------------------------------

## cos(angle): COS[((angle + 8) >> 4) & 0xfff]  (the `+8` is round-to-nearest index).
static func cos_a(angle: int) -> int:
	return COS[_asr(_s16(angle) + 8, 4) & 0xfff]


## sin(angle): COS[((0x3ff8 - angle) >> 4) & 0xfff]  (quarter-turn shifted cos).
static func sin_a(angle: int) -> int:
	return COS[_asr(0x3ff8 - _s16(angle), 4) & 0xfff]


## FUN_005ee0f0: polar -> cartesian. out = [(r*cos)>>16, (r*sin)>>16, 0].
static func polar_vec(r: int, angle: int) -> Array:
	return [mul16(r, cos_a(angle)), mul16(r, sin_a(angle)), 0]


## FUN_005ee670: rotate a 2D vector by `angle` in place.
##   x' = (x*cos - y*sin) >> 16 ;  y' = (x*sin + y*cos) >> 16
static func rotate_vec(x: int, y: int, angle: int) -> Array:
	var c := cos_a(angle)
	var s := sin_a(angle)
	return [muladd16(x, c, -y, s), muladd16(y, c, x, s)]


## FUN_005ee170: scale a 3D vector by a 16.16 scalar -> out[i] = (v[i]*s) >> 16.
static func scale_vec3(vx: int, vy: int, vz: int, s: int) -> Array:
	return [mul16(vx, s), mul16(vy, s), mul16(vz, s)]


## FUN_005ee080: atan2-like angle (0x10000 = full circle) of the vector (p1, p2),
## via the arctan LUT. Returns a signed 16-bit angle. p1 is the first arg (esi),
## p2 the second (edi); the quadrant fold + sign flips are the binary's exactly.
static func atan_angle(p1: int, p2: int) -> int:
	if p1 == 0 and p2 == 0:
		return 0
	var a1 := absi(p1)
	var a2 := absi(p2)
	var ang: int
	if a1 < a2:
		ang = 0x4000 - ATAN[ratio16(a1, a2) >> 3]
	else:
		ang = ATAN[ratio16(a2, a1) >> 3]
	if p1 < 0:
		ang = -0x8000 - ang
	if p2 < 0:
		ang = -ang
	return _s16(ang)
