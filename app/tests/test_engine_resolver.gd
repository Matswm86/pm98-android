extends SceneTree
## Task #4b WIRING parity for Pm98Action.engine_tick's action switch CASE 8/9 (FUN_005a4600 -> the
## post-shot RESOLVER FUN_005aeda0). The arm is now wired to Pm98Resolver.resolve_action, threading the
## shared match RNG and the target/stats refs (player+0xac / +0x3b8).
##
## Run: ~/godot462 --headless --path app --script res://tests/test_engine_resolver.gd
##
## PROOF STRATEGY (transitive, no new Ghidra run -- the same method test_engine_wire.gd uses for the 7
## Family-A handlers):
##   engine_tick residue  ==  bare resolve_action residue  ==  the binary.
## The right-hand identity is the GREEN tree oracle: resolve_action delegates to resolve_tree, which is
## verified bit-for-bit against the REAL FUN_005aeda0 under the PCode emulator (test_resolver_tree.gd,
## tools/re/specs/tree_oracle_streams.txt). So we only need the LEFT identity here: build two IDENTICAL
## states from each oracle-anchored resolver-tree fixture, run the bare resolver on one and engine_tick
## on the other at the SAME seed, and assert they agree on EVERY int field of player/target/stats/match
## (+ ball/gs) outside the inert-prologue set, plus identical rng end-state (-> rng threaded correctly).
##
## REACHABILITY: engine_tick dispatches case 8/9 on player+0x40 (the action code). The resolver ALSO
## reads player+0x40 for the forward-finishing bonus (is_fwd = +0x40 == 9). These are the same field, so
## the resolver-tree fixtures with role 9 (pos=9) are exactly the ones reachable via the case-8/9 arm
## with is_fwd=1 preserved -- we use those 7. (Case 8 shares the SAME switch arm; testing case 9 with
## is_fwd matched exercises the dispatch.) The baseline pos=0 fixtures route to a different switch arm,
## so they are not engine-reachable through case 8/9 and are excluded.
##
## NON-INTERFERENCE (why the engine wrapper is transparent here): the state is set so engine_tick's
## prologue/epilogue draw ZERO rng and never touch the resolver's I/O:
##   * +0x48 locked (= 5) -> tick_action (FUN_005a50c0) takes its decrement-and-return path: it touches
##     ONLY +0x48 (decrement) and +0x30 (the 2-bit sub-tick advance); the resolver reads neither on the
##     tree path, and +0x40/+0x2c (the dispatch + play-state) are preserved.
##   * +0x88 = 0 -> the 16-tick stamina block is skipped (no +0x70/+0x74, no rng).
##   * +0x80 = +0x84 = 0 -> the post-switch interpolation is skipped (-> _movement_decision, whose
##     leaves are still NO-OP stubs) so the resolver's target/match writes survive untouched.
##   * +0x184 gs+0x2ee = 0 -> the highlight power-accumulate AND open-play power reset are both inactive
##     (they would otherwise clobber +0x54/+0x58, which the resolver tail zeroes on BOTH sides anyway).
##   * sign(+4) == sign(+0x3a4) (both 0) -> the teammate-count (FUN_005b0b40) is not called.
##   * match+0x448 = 0 -> required for the resolver to run at all (its L38 entry guard) AND it enables
##     the phase-0 possession touch on +0x50 (a fixed, handler-independent write, in the inert set).
## The remaining prologue writes are a FIXED set (INERT_P) excluded from the player diff; any OTHER
## divergence -- a missed dispatch, a clobbered output, a wrong/extra rng draw -- fails loudly.

const SEED := 1   # srand(1): matches the tree oracle's banked draw stream (41,18467,6334,26500,...).

# Fields the inert prologue legitimately writes on the engine_tick side but not on the bare-resolver side:
#   0x30 the sub-tick advance · 0x48 the tick_action decrement · 0x88 the &0xf counter · 0x6c cleared ·
#   0x2d7/0x2d8 the prologue flags · 0x50 the phase-0 possession touch · 0x4c the (unreached) owner touch.
const INERT_P := {0x30: true, 0x48: true, 0x88: true, 0x6c: true, 0x2d7: true, 0x2d8: true,
	0x50: true, 0x4c: true}

# The 7 role-9 resolver-tree fixtures (mirror test_resolver_tree.gd / resolver_tree.tmpl). pos == +0x40
# is fixed at 9 so the engine switch reaches case 8/9 and is_fwd is preserved.
const FIXTURES := [
	{"name": "fwd_skill",     "pang": 0, "tang": 0,      "eng": 0, "skill": 0x32, "hdr": 0},
	{"name": "header",        "pang": 0, "tang": 0,      "eng": 0, "skill": 0x32, "hdr": 0x14},
	{"name": "engaged_hdr",   "pang": 0, "tang": 0,      "eng": 1, "skill": 0x32, "hdr": 0x14},
	{"name": "angle_else",    "pang": 0, "tang": 0x4000, "eng": 0, "skill": 0x32, "hdr": 0x14},
	{"name": "engaged_angle", "pang": 0, "tang": 0x4000, "eng": 1, "skill": 0x50, "hdr": 0x14},
	{"name": "hi_face",       "pang": 0, "tang": 0,      "eng": 0, "skill": 0x64, "hdr": 0x14},
	{"name": "hi_angle",      "pang": 0, "tang": 0x4000, "eng": 0, "skill": 0x64, "hdr": 0x14},
]

var _fail := 0
var _pass := 0


func _init() -> void:
	for fx in FIXTURES:
		_run(fx)
	print("")
	print("ALL PASS (%d checks)" % _pass if _fail == 0 else "FAILED: %d / %d" % [_fail, _pass + _fail])
	quit(1 if _fail > 0 else 0)


func _run(fx: Dictionary) -> void:
	var label: String = fx.name
	var sa := _build(fx)   # bare standalone resolver
	var et := _build(fx)   # independent identical state for engine_tick

	var rng_sa := MatchEngine.Pm98Rng.new(SEED)
	var rng_et := MatchEngine.Pm98Rng.new(SEED)
	# Bare side: call the resolver exactly as the engine arm does, sourcing t/m/stats from p's own refs.
	Pm98Resolver.resolve_action(sa["p"], sa["p"][0xac], sa["p"][0x18c], sa["p"][0x3b8], rng_sa)
	# Engine side: the per-player engine; case 8/9 dispatches to the wired resolver.
	Pm98Action.engine_tick(et["p"], et["p"][0x18c], rng_et)

	# rng threaded identically (same draw count + order). The resolver always draws (>=4 here), so an
	# equal-AND-advanced end-state is positive proof the shared rng reached the resolver via the switch.
	_ok(rng_sa.state != SEED, "%s: bare resolver drew no rng (fixture broken?)" % label)
	_ok(rng_et.state == rng_sa.state,
		"%s rng end-state: engine_tick 0x%x vs bare 0x%x" % [label, rng_et.state, rng_sa.state])

	# Every int field of player (excl inert) / target / stats / match / ball / gs must agree.
	_diff(label, "p", sa["p"], et["p"], INERT_P)
	_diff(label, "t", sa["p"][0xac], et["p"][0xac], {})
	_diff(label, "stats", sa["p"][0x3b8], et["p"][0x3b8], {})
	_diff(label, "m", sa["p"][0x18c], et["p"][0x18c], {})
	_diff(label, "ball", sa["p"][0x190], et["p"][0x190], {})
	_diff(label, "gs", sa["p"][0x184], et["p"][0x184], {})


## Build one full state for a resolver-tree fixture: player + linked target/match/stats/ball/gs, plus the
## engine control fields that keep the prologue/epilogue inert (see the NON-INTERFERENCE note above).
func _build(fx: Dictionary) -> Dictionary:
	var t := {0x34: int(fx.tang), 0x40: 5, 0x2bc: 1, 0x388: 0}
	var m := {4: int(fx.hdr), 0x43c: 0, 0x448: 0, 0x461: 0}
	var stats := {}
	var ball := {}
	var gs := {0x2ee: 0}
	var p := {
		# --- resolver inputs (identical to resolver_tree.tmpl) ---
		0x2c: 3, 0x30: 0, 0x34: int(fx.pang), 0x40: 9, 0x60: int(fx.eng), 0x384: int(fx.skill),
		0x4: 0, 0x8: 0, 0xc: 0, 0x3a4: 0,
		# --- pointer refs (player+0xac target, +0x18c match, +0x190 ball, +0x184 gs, +0x3b8 stats) ---
		0xac: t, 0x18c: m, 0x190: ball, 0x184: gs, 0x3b8: stats,
		# --- engine control fields that hold the prologue/epilogue inert ---
		0x48: 5, 0x88: 0, 0x80: 0, 0x84: 0, 0x2bc: 0,
	}
	return {"p": p}


## Assert two field dicts agree on all INT keys outside `skip`. Dict/Array values are topology pointers
## (each state owns its own copies) -> compared by TYPE only. A type mismatch (int vs Dict) is a real bug.
func _diff(label: String, region: String, a: Dictionary, b: Dictionary, skip: Dictionary) -> void:
	var keys := {}
	for k in a: keys[k] = true
	for k in b: keys[k] = true
	for k in keys:
		if skip.has(k):
			continue
		var va: Variant = a.get(k, 0)
		var vb: Variant = b.get(k, 0)
		var ia := va is int or va is float
		var ib := vb is int or vb is float
		if ia and ib:
			_ok(int(va) == int(vb),
				"%s %s+0x%x: bare 0x%x vs engine_tick 0x%x"
					% [label, region, int(k), int(va) & 0xffffffff, int(vb) & 0xffffffff])
		elif ia != ib:
			_ok(false, "%s %s+0x%x: type mismatch (bare %s vs engine_tick %s)"
				% [label, region, int(k), typeof(va), typeof(vb)])
		# both Dict/Array -> topology pointer, skip.


func _ok(cond: bool, msg: String) -> void:
	if cond:
		_pass += 1
	else:
		_fail += 1
		print("  [FAIL] ", msg)
