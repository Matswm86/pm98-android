extends SceneTree
## Oracle-backed parity test for the EXACT resolver finishing gate (stage S3-B).
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_resolver_gate.gd
##
## ORACLE = the PM98 binary itself, executed by the Ghidra PCode emulator
## (tools/re/ghidra_scripts/PcodeEmu.java). The emulator drove the REAL resolver
## FUN_005aeda0 through its guards + geometry sub-calls to the finishing gate and
## read the gate's computed threshold (EDX) and per-mil (EAX) straight out of the
## CPU registers, seeded srand(1) so the gate draw is always the first RNG value 41.
## Table captured in tools/re/specs/gate_oracle_table.txt. This test asserts the
## GDScript port (Pm98Resolver.gd) reproduces that table bit-for-bit. Exit 0 = PASS.

# ATTR -> threshold(per-mil), straight from the emulator's EDX at 0x5aeeff.
const ORACLE_THRESHOLD := {
	0: 0, 1: 0, 2: 0, 3: 9, 9: 27, 10: 27, 30: 90,
	53: 153, 54: 162, 55: 270, 56: 279, 90: 585, 100: 675,
}
# Oracle gate draw + per-mil for srand(1): first RNG draw 41 -> (41*1000)>>15 = 1.
const ORACLE_GATE_DRAW := 41
const ORACLE_GATE_PERMIL := 1


func _initialize() -> void:
	quit(0 if _run() else 1)


func _run() -> bool:
	var ok := true
	print("=== PM98 resolver finishing-gate parity (vs PCode-emulator oracle) ===")

	# 1. The RNG itself, against the canonical srand(1) sequence (the emulator
	#    reproduced exactly the same five values).
	var rng := MatchEngine.Pm98Rng.new(1)
	var canon := [41, 18467, 6334, 26500, 19169]
	for i in canon.size():
		var got := rng.next()
		ok = _eq("rng srand(1)[%d]" % i, got, canon[i]) and ok

	# 2. The gate draw + per-mil idiom match the emulator's registers for seed 1.
	ok = _eq("gate draw (first srand(1))", MatchEngine.Pm98Rng.new(1).next(), ORACLE_GATE_DRAW) and ok
	ok = _eq("permil_scale(41)", Pm98Resolver.permil_scale(ORACLE_GATE_DRAW), ORACLE_GATE_PERMIL) and ok

	# 3. The threshold table matches the binary at every sampled ATTR, incl. the
	#    stepped sub-55 region and the kink (54->162, 55->270).
	for attr in ORACLE_THRESHOLD:
		ok = _eq("threshold(ATTR=%d)" % attr, Pm98Resolver.finishing_threshold_permil(attr),
				ORACLE_THRESHOLD[attr]) and ok

	# 4. Full 0..100 self-consistency: never negative, monotonic non-decreasing,
	#    and exactly one upward jump (the kink) of the expected size 162->270.
	var prev := -1
	var jumps := 0
	for attr in range(0, 101):
		var th := Pm98Resolver.finishing_threshold_permil(attr)
		if th < 0:
			ok = _fail("threshold(%d) negative: %d" % [attr, th]) and ok
		if th < prev:
			ok = _fail("threshold(%d)=%d < threshold(%d)=%d (non-monotonic)" % [attr, th, attr - 1, prev]) and ok
		if attr == 55:
			ok = _eq("kink jump 54->55", th - prev, 270 - 162) and ok
		prev = th

	# 5. The gate decision composes correctly: with seed-1 draw (per-mil 1) a
	#    world-class finisher (ATTR 90, threshold 585) takes the shot; a hopeless
	#    one (ATTR 0, threshold 0) does not.
	ok = _eq("shot_proceeds(seed1, ATTR=90)", int(Pm98Resolver.shot_proceeds(MatchEngine.Pm98Rng.new(1), 90)), 1) and ok
	ok = _eq("shot_proceeds(seed1, ATTR=0)", int(Pm98Resolver.shot_proceeds(MatchEngine.Pm98Rng.new(1), 0)), 0) and ok

	print("\n%s" % ("ALL PASS" if ok else "FAIL"))
	return ok


func _eq(label: String, got: int, want: int) -> bool:
	var p := got == want
	print("  [%s] %s = %d (want %d)" % ["PASS" if p else "FAIL", label, got, want])
	return p


func _fail(msg: String) -> bool:
	print("  [FAIL] %s" % msg)
	return false
