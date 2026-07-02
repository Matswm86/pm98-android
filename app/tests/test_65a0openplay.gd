extends SceneTree
## Oracle-backed parity test for the s12 FULL port of FUN_005a65a0 (the per-player movement
## dispatcher), Pm98Movement.move_dispatch: the velocity block for EVERY player (the p+0x54 wander
## re-arm), the param_2==0 FUN_005b1420 formation gate, arm-1 (b0040 / goal-anchor steer /
## chase-return + FUN_005aa490 handoff), arm-2 (8f20 / b0040 / sideline steer + AA870 tail), the
## IF-A anim-end and the phase-2-holder / phase-4 taker arms.
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_65a0openplay.gd
##
## ORACLE = the REAL FUN_005a65a0 under the Ghidra PCode emulator with ONLY b1420's b1500/b1c80 role
## sub-leaves stubbed (ret 1), exactly the port's deferral (tools/re/run_65a0openplay_oracle.sh ->
## specs/65a0openplay_oracle.txt). Every fixture seeds the LCG @0x6d3184 = 1 == Pm98Rng.new(1); the
## final LCG state is asserted, so the DRAW COUNT and ORDER are pinned, not just the field writes.
## Pointer-valued fields (p+0xb4, ball+0x40, ball+0x4c, m+0x438/0x440) are compared via the fixture
## window ADDRESS MAP (Dict identity -> emu address); everything else is masked numeric.

const ADDR_P := 0x230000
const ADDR_M := 0x210000
const ADDR_C := 0x240000
const ADDR_T := 0x250000
const ADDR_Q0 := 0x310000
const ADDR_Q1 := 0x3103bc
const U32 := 0xffffffff
const BYTE_OFFS := {0x5c: true, 0x5e: true, 0x5f: true, 0x63: true, 0x2d7: true}
const WORD_OFFS := {0x34: true, 0x66: true}

var _fail := 0
var _pass := 0


# Per-fixture INPUTS -- mirror tools/re/run_65a0openplay_oracle.sh EXACTLY. Anything absent is 0.
# refs: b40p (ball+0x40=P) / b40q0 (=Q0) / b4cq0 (ball+0x4c=Q0) / m438p / m440q0 / roster2 / q0pos.
const FIX := {
	"velobail":      {"param2": 0, "p": {0x40: 2, 0x48: 5}},
	"veloact_near":  {"param2": 0, "p": {0x40: 2, 0x48: 5, 0x3a4: 0x100000}, "refs": ["b40p"]},
	"veloact_mid":   {"param2": 0, "p": {0x40: 2, 0x48: 5, 0x3a4: 0x1b0000}, "refs": ["b40p"]},
	"veloact_far":   {"param2": 0, "p": {0x40: 2, 0x48: 5, 0x3a4: 0x290000}, "refs": ["b40p"]},
	"b1420_b1500":   {"param2": 0, "p": {0x40: 2}, "b": {0x54: 1}},
	"b1420_b1c80":   {"param2": 0, "p": {0x40: 2}},
	"arm1_b0040":    {"param2": 1, "p": {0x40: 2}},
	"arm1_simple":   {"param2": 1, "p": {0x40: 2}, "m": {0x1820: 0x1400000}, "refs": ["b40p"]},
	"chase_pass":    {"param2": 1, "p": {0x40: 2, 0x63: 1, 0x3a4: 0x100000, 0x2bc: 1},
		"m": {0x1820: 0x1400000}, "refs": ["b40p", "roster2"]},
	"chase_nopass":  {"param2": 1, "p": {0x40: 2, 0x63: 1, 0x3a4: 0x100000, 0x2bc: 1},
		"m": {0x1820: 0x1400000}, "refs": ["b40p"]},
	"chase_far":     {"param2": 1, "p": {0x40: 2, 0x63: 1, 0x34: 0x4000},
		"m": {0x1820: 0x1400000}, "refs": ["b40p"]},
	"arm2_8f20":     {"param2": 1, "p": {0x40: 2}, "refs": ["m440q0", "b40q0"]},
	"arm2_b0040":    {"param2": 1, "p": {0x40: 2}, "refs": ["m440q0"]},
	"arm2_aa870":    {"param2": 1, "p": {0x40: 2, 0x34: 0x4000}, "refs": ["m440q0", "b40p"]},
	"arm2_steeronly": {"param2": 1, "p": {0x40: 2, 0x34: 0x2000}, "m": {0x1824: 0xd0000},
		"refs": ["m440q0", "b40p"]},
	"ifa_end":       {"param2": 0, "p": {0x40: 0x35, 0x2c: 11}, "m": {0x461: 0x40}},
	"ifa_notend":    {"param2": 0, "p": {0x40: 0x35, 0x2c: 5}, "m": {0x461: 0x40}},
	"phase2_holder": {"param2": 0, "p": {0x40: 0, 0x2bc: 1}, "m": {0x448: 2},
		"refs": ["m438p", "b40p", "b4cq0", "q0pos"]},
	"phase4_taker":  {"param2": 0, "p": {0x40: 2}, "m": {0x448: 4, 0x1820: 0x1400000},
		"refs": ["m438p"]},
}


func _init() -> void:
	var orc := _load_oracle()
	if orc.is_empty():
		_ok(false, "65a0 open-play oracle empty/unreadable (run tools/re/run_65a0openplay_oracle.sh)")
	else:
		for name in FIX:
			if not orc.has(name):
				_ok(false, name + ": missing from oracle file")
				continue
			_run(name, orc[name])
	print("")
	if _fail == 0:
		print("ALL PASS (%d checks)" % _pass)
	else:
		print("FAILED: %d / %d" % [_fail, _pass + _fail])
	quit(1 if _fail > 0 else 0)


func _ok(cond: bool, msg: String) -> void:
	if cond:
		_pass += 1
	else:
		_fail += 1
		print("  [FAIL] ", msg)


func _spec_path(n: String) -> String:
	return ProjectSettings.globalize_path("res://").path_join("../tools/re/specs/").path_join(n).simplify_path()


# Parse specs/65a0openplay_oracle.txt into {name: {"mem": {abs_addr: val}, "ret": bool}}.
func _load_oracle() -> Dictionary:
	var out := {}
	var f := FileAccess.open(_spec_path("65a0openplay_oracle.txt"), FileAccess.READ)
	if f == null:
		return {}
	var rx_mem := RegEx.new()
	rx_mem.compile("mem\\[0x([0-9a-fA-F]+):[0-9]+\\]=(-?[0-9]+)")
	var cur := ""
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if line.begins_with("## FIX "):
			cur = line.substr(7).strip_edges().split(" ")[0]
			out[cur] = {"mem": {}, "ret": false}
		elif cur == "":
			continue
		elif line.find(" RET ") >= 0 or line.find(" HALT ") >= 0:
			out[cur]["ret"] = line.find(" RET ") >= 0
			for mtch in rx_mem.search_all(line):
				out[cur]["mem"][("0x" + mtch.get_string(1)).hex_to_int()] = mtch.get_string(2).to_int()
	return out


func _run(name: String, exp: Dictionary) -> void:
	var fx: Dictionary = FIX[name]
	var p := {}
	var m := {}
	var ball := {}
	var gs := {}
	var q0 := {}
	var q1 := {}
	for off in fx.get("p", {}):
		p[int(off)] = int(fx["p"][off])
	for off in fx.get("m", {}):
		m[int(off)] = int(fx["m"][off])
	for off in fx.get("b", {}):
		ball[int(off)] = int(fx["b"][off])
	p[0x18c] = m
	p[0x190] = ball
	p[0x184] = gs
	var refs: Array = fx.get("refs", [])
	if refs.has("b40p"):
		ball[0x40] = p
	if refs.has("b40q0"):
		ball[0x40] = q0
	if refs.has("b4cq0"):
		ball[0x4c] = q0
	if refs.has("m438p"):
		m[0x438] = p
	if refs.has("m440q0"):
		m[0x440] = q0
	if refs.has("roster2"):
		q0[0x2bc] = 1
		q0[4] = 0x70000
		q0[8] = 0x10000
		gs[0] = [q0, q1]
	if refs.has("q0pos"):
		q0[4] = 0x70000
		q0[8] = 0x10000

	_ok(bool(exp["ret"]), name + ": oracle row is a clean RET (re-run the oracle if HALT)")
	var rng = MatchEngine.Pm98Rng.new(1)
	Pm98Movement.move_dispatch(p, m, int(fx["param2"]), rng)

	# The fixture-window address map: Dict identity -> emu address (pointer-field comparisons).
	var addr_map := [[p, ADDR_P], [m, ADDR_M], [ball, ADDR_C], [gs, ADDR_T], [q0, ADDR_Q0], [q1, ADDR_Q1]]
	for abs_addr in exp["mem"]:
		var want := int(exp["mem"][abs_addr])
		if abs_addr == 0x6d3184:
			_ok((rng.state & U32) == (want & U32),
				"%s rng state: got 0x%x want 0x%x" % [name, rng.state & U32, want & U32])
			continue
		var ent: Dictionary
		var off := 0
		if abs_addr >= ADDR_P and abs_addr < ADDR_P + 0x1000:
			ent = p
			off = abs_addr - ADDR_P
		elif abs_addr >= ADDR_C and abs_addr < ADDR_C + 0x1000:
			ent = ball
			off = abs_addr - ADDR_C
		else:
			continue
		var got_v: Variant = ent.get(off, 0)
		if got_v is Dictionary:
			var got_addr := -1
			for pair in addr_map:
				if is_same(pair[0], got_v):
					got_addr = int(pair[1])
					break
			_ok(got_addr == want, "%s +0x%x (ptr): got addr 0x%x want 0x%x" % [name, off, got_addr, want])
			continue
		var mask := U32
		if BYTE_OFFS.has(off):
			mask = 0xff
		elif WORD_OFFS.has(off):
			mask = 0xffff
		var got := int(got_v) & mask
		_ok(got == (want & mask), "%s %s+0x%x: got 0x%x want 0x%x" % \
			[name, "p" if is_same(ent, p) else "ball", off, got, want & mask])
