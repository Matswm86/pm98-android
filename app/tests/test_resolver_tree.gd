extends SceneTree
## Oracle-backed parity test for the EXACT resolver DECISION TREE (Stage 2b):
## FUN_005aeda0 lines 120-485, ported in Pm98Resolver.resolve_tree.
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_resolver_tree.gd
##
## ORACLE = the PM98 binary itself under the Ghidra PCode emulator
## (tools/re/ghidra_scripts/PcodeEmu.java). tools/re/run_tree_oracle.sh drove the
## REAL resolver through a branch-covering fixture matrix (movement block gated off
## via M+0x70 != 0, so this isolates the resolution tree) and captured, per fixture,
## the RNG draw count + final LCG state + match+0x461 outcome bits + target play-state.
## Ground truth: tools/re/specs/tree_oracle_streams.txt. This test reconstructs each
## fixture's struct inputs, runs the GDScript port, and asserts it reproduces the
## binary's draw count, final RNG state, outcome bits, and target state bit-for-bit.
## The RNG draw ORDER is load-bearing -- a wrong branch consumes the wrong draws and
## desynchronises the whole match, so draw-count + final-state parity is the kill-test.
## Proven LUT-invariant (tools/re/check_lut_invariance.sh), so geometry is not needed.

# Each fixture mirrors a row of resolver_tree.tmpl + its oracle result.
# {pang, tang, pos, engaged, skill, hdr  ->  draws, state, bits, tstate; g/o/a = stats
#  +0x98/+0x9c/+0xa0, default 0}. The last two are bVar5-TRUE goal/save outcomes
# (Stage 2c): they exercise the resolved-outcome block -- match+0x461 bit0 via the
# FUN_0058fb50 goal-box port, bit2 = save (bvar7), and the stat counters. hi_face is
# a save (bvar7 -> bit2 + stats o/a); hi_angle is an on-target miss (bvar5 set but no
# save/goal -> bit0 ONLY, the direct kill-test for the FUN_0058fb50 port: the old
# bvar17=0 stub would give bits=8 here, not the oracle's 9).
const FIXTURES := [
	{"name": "baseline",      "pang": 0, "tang": 0,       "pos": 0, "eng": 0, "skill": 0,    "hdr": 0,
	 "draws": 4,  "state": 3884216597, "bits": 0, "tstate": 5},
	{"name": "fwd_skill",     "pang": 0, "tang": 0,       "pos": 9, "eng": 0, "skill": 0x32, "hdr": 0,
	 "draws": 4,  "state": 3884216597, "bits": 0, "tstate": 5},
	{"name": "header",        "pang": 0, "tang": 0,       "pos": 9, "eng": 0, "skill": 0x32, "hdr": 0x14,
	 "draws": 9,  "state": 1766988168, "bits": 8, "tstate": 7},
	{"name": "engaged_hdr",   "pang": 0, "tang": 0,       "pos": 9, "eng": 1, "skill": 0x32, "hdr": 0x14,
	 "draws": 10, "state": 3750785579, "bits": 8, "tstate": 7},
	{"name": "angle_else",    "pang": 0, "tang": 0x4000,  "pos": 9, "eng": 0, "skill": 0x32, "hdr": 0x14,
	 "draws": 7,  "state": 752224798,  "bits": 8, "tstate": 6},
	{"name": "engaged_angle", "pang": 0, "tang": 0x4000,  "pos": 9, "eng": 1, "skill": 0x50, "hdr": 0x14,
	 "draws": 8,  "state": 1924036713, "bits": 8, "tstate": 6},
	{"name": "hi_face",       "pang": 0, "tang": 0,       "pos": 9, "eng": 0, "skill": 0x64, "hdr": 0x14,
	 "draws": 7,  "state": 752224798,  "bits": 13, "tstate": 7, "g": 0, "o": 1, "a": 1},
	{"name": "hi_angle",      "pang": 0, "tang": 0x4000,  "pos": 9, "eng": 0, "skill": 0x64, "hdr": 0x14,
	 "draws": 8,  "state": 1924036713, "bits": 9, "tstate": 6, "g": 0, "o": 0, "a": 0},
]


func _initialize() -> void:
	quit(0 if _run() else 1)


func _run() -> bool:
	var ok := true
	print("=== PM98 resolver decision-tree parity (vs PCode-emulator oracle) ===")
	for fx in FIXTURES:
		# Reconstruct the fixture's struct fields (same offsets as resolver_tree.tmpl).
		var p := {0x2c: 3, 0x30: 0, 0x34: fx.pang, 0x40: fx.pos, 0x60: fx.eng, 0x384: fx.skill}
		var t := {0x34: fx.tang, 0x40: 5, 0x2bc: 1, 0x388: 0}
		var m := {4: fx.hdr, 0x43c: 0, 0x448: 0, 0x461: 0}
		var stats := {}
		var rng := MatchEngine.Pm98Rng.new(1)
		var r := Pm98Resolver.resolve_tree(p, t, m, stats, rng)

		ok = _eq("%s: draws" % fx.name, r.draws, fx.draws) and ok
		ok = _eq("%s: final RNG state" % fx.name, rng.state, fx.state) and ok
		ok = _eq("%s: match+0x461 bits" % fx.name, r.bits, fx.bits) and ok
		ok = _eq("%s: target play-state" % fx.name, r.target_state, fx.tstate) and ok
		# Stat counters (goals +0x98, off-target +0x9c, shots +0xa0) -- only the
		# bVar5-true fixtures touch these; the rest assert they stay 0.
		ok = _eq("%s: stats +0x98 (goals)" % fx.name, int(stats.get(0x98, 0)), fx.get("g", 0)) and ok
		ok = _eq("%s: stats +0x9c (off-tgt)" % fx.name, int(stats.get(0x9c, 0)), fx.get("o", 0)) and ok
		ok = _eq("%s: stats +0xa0 (shots)" % fx.name, int(stats.get(0xa0, 0)), fx.get("a", 0)) and ok

	print("\n%s" % ("ALL PASS" if ok else "FAIL"))
	return ok


func _eq(label: String, got: int, want: int) -> bool:
	var p := got == want
	print("  [%s] %s = %d (want %d)" % ["PASS" if p else "FAIL", label, got, want])
	return p
