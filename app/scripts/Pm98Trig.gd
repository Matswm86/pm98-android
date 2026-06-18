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


## FUN_005b1260: LUT-approximated length of the 2D vector (x, y) -- the projection of (x,y)
## onto its own unit direction. ang = atan_angle(x, y); return muladd16(x, cos_a(ang), y,
## sin_a(ang)). The reusable planar magnitude the player-move fns (FUN_005b70e0 nearest-search,
## FUN_005a3400 decide) call; integer-only. Disasm 0x5b1260: atan -> two cos-LUT reads (the cos
## at (ang+8>>4), the sin at (0x3ff8-ang>>4)) -> FUN_005edfb0(x, cos, y, sin). Oracle-pinned by
## run_planarmag_oracle.sh (specs/planarmag_oracle.txt) -> test_trig_lut.gd.
static func planar_mag(x: int, y: int) -> int:
	var ang := atan_angle(x, y)
	return muladd16(x, cos_a(ang), y, sin_a(ang))


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


# ---- vector geometry leaves (FUN_00590aa0 / 590ae0 / 5ee290 / 5ee2d0 / 5ee3f0) -------
# The small per-tick movement geometry primitives the player-move shells (FUN_005b70e0)
# and the per-player DECIDE (FUN_005a3400) call. All pure: no RNG, no persistent state.
# A vec3 is modelled as a 3-int Array [x, y, z] (the binary's three int32 dword slots).
# Each is oracle-pinned bit-for-bit by tools/re/run_moveleaf_oracle.sh ->
# specs/moveleaf_oracle.txt, locked in test_trig_lut.gd._test_moveleaves.


## Truncate-toward-zero integer divide -- the x86 `idiv` quotient. GDScript int `/`
## already truncates toward zero (unlike `_asr`, which floors); this names the intent
## so the fixed-point ports read unambiguously against the disasm.
static func _tdiv(a: int, b: int) -> int:
	return a / b


## ftol(sqrt(dx^2 + dy^2 + dz^2)) -- the binary's unbound msvcrt _ftol truncates toward
## zero, reproduced by int(sqrt()). The squared terms are exact in 64-bit; the oracle
## uses perfect-square distances so the float64 sqrt lands on the same integer the x87
## 80-bit fsqrt + ftol does (the same convention select_nearest/run_movement_oracle use).
static func _dist3(dx: int, dy: int, dz: int) -> int:
	return int(sqrt(float(dx * dx + dy * dy + dz * dz)))


## FUN_00590aa0: write a vec3 (three dword stores, `ret 0xc`). Returns [x, y, z].
static func vec3_store(x: int, y: int, z: int) -> Array:
	return [_i32(x), _i32(y), _i32(z)]


## FUN_00590ae0: component-wise a - b, each stored as int32 (`ret 0x8`; a=this, b=param_3).
static func vec3_sub(a: Array, b: Array) -> Array:
	return [_i32(a[0] - b[0]), _i32(a[1] - b[1]), _i32(a[2] - b[2])]


## FUN_005ee290: scale a vec3 by the ratio mult/div, in place. Each component is
## (v[i] * mult) / div with a 64-bit signed product (imul) then a truncating idiv.
static func vec3_scale_ratio(v: Array, mult: int, div: int) -> Array:
	return [_i32(_tdiv(v[0] * mult, div)), _i32(_tdiv(v[1] * mult, div)), _i32(_tdiv(v[2] * mult, div))]


## FUN_005ee2d0: minimum-separation clamp. If p1 lies inside the L-inf box of half-size
## `box` around p2 (each |delta| strictly < box) AND its Euclidean distance to p2 is
## < box, push p1 OUT to exactly `box` from p2 along the (p1 - p2) direction (delta
## scaled by box/dist via FUN_005ee290); if p1 == p2 exactly (dist == 0), offset p1 by
## polar_vec(box, 0). Otherwise p1 is unchanged. Returns the (possibly new) p1.
static func clamp_min_sep(p1: Array, p2: Array, box: int) -> Array:
	var dx := _i32(p1[0] - p2[0])
	var dy := _i32(p1[1] - p2[1])
	var dz := _i32(p1[2] - p2[2])
	if not (absi(dx) < box and absi(dy) < box and absi(dz) < box):
		return [p1[0], p1[1], p1[2]]
	var dist := _dist3(dx, dy, dz)
	if dist >= box:
		return [p1[0], p1[1], p1[2]]
	if dist != 0:
		var sd := vec3_scale_ratio([dx, dy, dz], box, dist)
		return [_i32(sd[0] + p2[0]), _i32(sd[1] + p2[1]), _i32(sd[2] + p2[2])]
	var off := polar_vec(box, 0)
	return [_i32(p1[0] + off[0]), _i32(p1[1] + off[1]), _i32(p1[2] + off[2])]


## FUN_005ee3f0: midpoint-offset. If p1 lies inside the L-inf box of half-size `box`
## around p2 AND dist(p1, p2) < box, move p1 to p4 + the midpoint of (p1, p2):
## p1[i] = p4[i] + trunc((p1[i] - p2[i]) / 2) + p2[i]. The /2 is the cdq/sub/sar
## truncate-toward-zero idiom (NOT a floor). Otherwise p1 is unchanged. Returns p1.
static func mid_offset(p1: Array, p2: Array, box: int, p4: Array) -> Array:
	var dx := _i32(p1[0] - p2[0])
	var dy := _i32(p1[1] - p2[1])
	var dz := _i32(p1[2] - p2[2])
	if not (absi(dx) < box and absi(dy) < box and absi(dz) < box):
		return [p1[0], p1[1], p1[2]]
	var dist := _dist3(dx, dy, dz)
	if dist >= box:
		return [p1[0], p1[1], p1[2]]
	return [
		_i32(p4[0] + _tdiv(dx, 2) + p2[0]),
		_i32(p4[1] + _tdiv(dy, 2) + p2[1]),
		_i32(p4[2] + _tdiv(dz, 2) + p2[2]),
	]
