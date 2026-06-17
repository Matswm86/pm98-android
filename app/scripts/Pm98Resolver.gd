class_name Pm98Resolver
extends RefCounted
## EXACT ports of decoded primitives from MANAGER.EXE's shot/tackle/save resolver
## FUN_005aeda0 (docs/re/EXACT_PORT_PLAN.md, stage S3-B). Unlike MatchEngine.gd's
## CALIBRATED per-shot model, every function here is verified bit-for-bit against
## the original binary: the raw x86 disassembly AND the Ghidra PCode emulator (the
## oracle in tools/re/ghidra_scripts/PcodeEmu.java). Do NOT "tune" these numbers --
## they are not parameters, they are the binary. tests/test_resolver_gate.gd locks
## them to the emulator's output table.
##
## This is the first decoded slice. The full positional sim + tactics coupling are
## still to be ported (stages S4-S6); MatchEngine.simulate() keeps using the
## calibrated model until the exact engine is wired in at stage S7.


## PM98's per-mil probability scaling, the exact x86 idiom from the resolver:
##   roll*1000  -> cdq/and 0x7fff (round toward zero for negatives) -> sar 15
## For a valid RNG draw (0..32767) the product is non-negative, so the rounding
## term is 0 and this reduces to (roll*1000) >> 15 -- a uniform value in [0,1000).
## Verified at 0x5aeee2..0x5aeeff: draw 41 -> 1, matching the emulator.
static func permil_scale(roll: int) -> int:
	var p := roll * 1000
	var round_term := 0
	if p < 0:
		round_term = (p >> 31) & 0x7fff
	return (p + round_term) >> 15


## Finishing-gate threshold (per-mil), piecewise-linear in the shooter's finishing
## attribute at player+0x398, with a KINK at 55. Exact form from FUN_005aeda0
## (0x5aeec3..0x5aeefc): `imul 0x55555556` = signed div-by-3 (truncating), then x9;
## above the kink it is (ATTR-25)*9. The sub-55 branch is STEPPED -- 9*floor(ATTR/3),
## NOT linear 3*ATTR (e.g. ATTR 50 -> 144, not 150). The emulator's register dump
## confirms the whole table (tests/test_resolver_gate.gd): 54->162 then 55->270.
static func finishing_threshold_permil(attr: int) -> int:
	if attr < 55:
		return 9 * (attr / 3)   # integer division: 9 * floor(attr/3)
	return 9 * (attr - 25)


## The shot-proceeds gate itself: consume one RNG draw and compare. Returns true
## when the chance is taken to resolution. `rng` is MatchEngine.Pm98Rng (the exact
## MSVC LCG, itself oracle-verified against srand(1) -> 41,18467,6334,26500,19169).
static func shot_proceeds(rng: MatchEngine.Pm98Rng, attr: int) -> bool:
	return permil_scale(rng.next()) < finishing_threshold_permil(attr)
