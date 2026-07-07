extends SceneTree
## Oracle-backed parity test for the s15 ports of FUN_005b1500 (opponent-possession off-ball
## mover) + FUN_005b1c80 (own-possession mover) and their role-leaf family:
## Pm98Movement.offball_opp_b1500 / offball_own_b1c80 (+ _anchor_3b20 / _dart_2f30 /
## _unmark_2b70 / _pushup_3060 / _pass_via_3a10 / _cross_pick_35c0 / _runtarget_4820 /
## _role_leaf_41c0/4a80/4f70/3d00/3e50/5520/5150).
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_b1500family.gd
##
## ORACLE = the REAL binary functions under the Ghidra PCode emulator with NO stubs
## (tools/re/run_b1500family_oracle.sh -> specs/b1500family_oracle.txt). Every fixture seeds
## the LCG @0x6d3184 = 1 == Pm98Rng.new(1); the final LCG state is asserted, so the DRAW
## COUNT and ORDER are pinned, not just the field writes. The binary's marker link p+0x150
## is a POINTER in the emu; the port models it as a FOREIGN-ROSTER INDEX -- the fixture
## translation (0x320000 -> index 0) happens here.

const ADDR_P := 0x230000
const ADDR_M := 0x210000
const ADDR_C := 0x240000
const ADDR_T := 0x250000
const ADDR_F := 0x260000
const ADDR_Q0 := 0x310000
const ADDR_Q1 := 0x3103bc
const ADDR_R0 := 0x320000
const ADDR_R1 := 0x3203bc
const U32 := 0xffffffff
const BYTE_OFFS := {0x5e: true, 0x5f: true}
const WORD_OFFS := {0x34: true, 0x66: true}

var _fail := 0
var _pass := 0


# Per-fixture INPUTS -- mirror tools/re/run_b1500family_oracle.sh EXACTLY. Anything absent = 0.
# entry: "b1500"|"b1c80". refs: b40r0/b40q0/b40p (ball+0x40), b4cr0 (ball+0x4c),
# mark_r0 (p+0x150 = R0 -> port index 0), desig_q0 (gs+0x200 = Q0).
const FIX := {
	"b15_keeperhold":   {"entry": "b1500", "refs": ["b40r0offpitch"]},
	"b15_shadow":       {"entry": "b1500", "refs": ["mark_r0"], "p": {0x8: 0x400000}, "r0": {0xe4: 0x100000}},
	"b15_press_recv":   {"entry": "b1500", "refs": ["mark_r0", "b4cr0"], "p": {0xe8: 0x300000}},
	"b15_tackle":       {"entry": "b1500", "refs": ["mark_r0", "b40r0"],
		"r0": {0x4: 0x70000, 0x8: 0x10000}, "p": {0x4: 0x90000, 0xe4: 0x10000}},
	"b15_role4":        {"entry": "b1500", "refs": ["b40r0"], "p": {0x2c8: 4}},
	"b15_role4_loose":  {"entry": "b1500", "refs": ["desig_q0"], "p": {0x2c8: 4}},
	"b15_anchor":       {"entry": "b1500", "p": {0x2c8: 7}},
	"b1c_state6":       {"entry": "b1c80", "p": {0x13c: 6, 0x2d8: 1, 0x2c8: 7}},
	"b1c_state6_entry": {"entry": "b1c80", "refs": ["b40q0"],
		"p": {0x2d8: 1, 0x4: 0x1200000, 0x2c8: 7}, "q0": {0x4: 0x70000}},
	"b1c_carrier5":     {"entry": "b1c80", "refs": ["b40p"],
		"p": {0x4: 0x1300000, 0x2c8: 9, 0x3a0: 50, 0x388: 50}},
	"b1c_carrier_deep": {"entry": "b1c80", "refs": ["b40p"],
		"p": {0x4: -0x600000, 0x2c8: 2, 0x17c: 0x100000, 0x180: 0x100000, 0xe4: 0x100000},
		"q0": {0x4: 0x600000}},
	"b1c_dart_leaf9":   {"entry": "b1c80", "refs": ["b40q0"],
		"p": {0x13c: 1, 0x144: 2, 0x148: 10, 0x164: 0x100000, 0x168: 0x40000, 0x2c8: 9, 0x17c: 0x100000},
		"b": {0x4: 0x300000}},
	"b1c_leaf2_promote": {"entry": "b1c80", "refs": ["b40q0"],
		"p": {0x2c8: 2, 0x8: 0x40000}, "b": {0x8: 0x30000}},
	"b1c_leaf2_carrier": {"entry": "b1c80", "refs": ["b40p"],
		"p": {0x2c8: 2, 0x4: -0x200000, 0x17c: 0x100000, 0x180: 0x100000}},
	"b1c_leaf4":        {"entry": "b1c80", "refs": ["b40q0", "desig_q0"], "p": {0x2c8: 4}},
	"b1c_leaf5_carrier": {"entry": "b1c80", "refs": ["b40p"],
		"p": {0x2c8: 5, 0x180: 0x100000, 0x17c: 0x100000}},
	"b1c_leaf9_loose":  {"entry": "b1c80",
		"p": {0x2c8: 9, 0x4: 0x200000, 0x17c: 0x100000}, "b": {0x4: -0x800000}},
	"b1c_leaf10":       {"entry": "b1c80", "refs": ["b40q0"],
		"p": {0x2c8: 10}, "b": {0x4: 0x300000, 0x8: 0x80000}},
	"b1c_leaf13_carrier": {"entry": "b1c80", "refs": ["b40p"],
		"p": {0x2c8: 13, 0x180: 0x100000, 0x17c: 0x100000}},
}


func _init() -> void:
	var oracle := _load_oracle()
	if oracle.is_empty():
		print("NO ORACLE SPEC (run tools/re/run_b1500family_oracle.sh first)")
		quit(1)
		return
	for name in FIX:
		if not oracle.has(name):
			_ok(false, name + ": missing from the oracle spec")
			continue
		_run(name, oracle[name])
	if _fail == 0:
		print("ALL PASS (%d checks)" % _pass)
	else:
		print("FAILED %d / passed %d" % [_fail, _pass])
	quit(1 if _fail > 0 else 0)


func _ok(cond: bool, msg: String) -> void:
	if cond:
		_pass += 1
	else:
		_fail += 1
		print("  [FAIL] ", msg)


func _spec_path(n: String) -> String:
	return ProjectSettings.globalize_path("res://").path_join("../tools/re/specs/").path_join(n).simplify_path()


# Parse specs/b1500family_oracle.txt into {name: {"mem": {abs: val}, "ret": bool, "eax": int}}.
func _load_oracle() -> Dictionary:
	var out := {}
	var f := FileAccess.open(_spec_path("b1500family_oracle.txt"), FileAccess.READ)
	if f == null:
		return {}
	var rx_mem := RegEx.new()
	rx_mem.compile("mem\\[0x([0-9a-fA-F]+):[0-9]+\\]=(-?[0-9]+)")
	var rx_eax := RegEx.new()
	rx_eax.compile("EAX=0x([0-9a-fA-F]+)")
	var cur := ""
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if line.begins_with("## FIX "):
			cur = line.substr(7).strip_edges().split(" ")[0]
			out[cur] = {"mem": {}, "ret": false, "eax": -1}
		elif cur == "":
			continue
		elif line.find(" RET ") >= 0 or line.find(" HALT ") >= 0:
			out[cur]["ret"] = line.find(" RET ") >= 0
			var em := rx_eax.search(line)
			if em != null:
				out[cur]["eax"] = ("0x" + em.get_string(1)).hex_to_int()
			for mtch in rx_mem.search_all(line):
				out[cur]["mem"][("0x" + mtch.get_string(1)).hex_to_int()] = mtch.get_string(2).to_int()
	return out


func _run(name: String, exp: Dictionary) -> void:
	var fx: Dictionary = FIX[name]
	var p := {}
	var m := {}
	var ball := {}
	var q0 := {}
	var q1 := {}
	var r0 := {}
	var r1 := {}
	var gs := {}
	var fgs := {}

	# --- common wiring (the shell's PTRS/PITCH/PBOX/PANCH/OWN/FRN/FRN2/PID blocks) ---
	p[0x18c] = m
	p[0x190] = ball
	p[0x184] = gs
	p[0x188] = fgs
	m[0x1820] = 0x1400000
	m[0x1824] = 0xd0000
	m[0x1828] = -0x1400000
	m[0x1834] = 0x1400000
	m[0x182c] = -0xd00000
	m[0x1838] = 0xd00000
	m[0x1830] = 0
	m[0x183c] = 0x100000
	p[0x210] = -0x800000
	p[0x21c] = 0x800000
	p[0x214] = -0x400000
	p[0x220] = 0x400000
	p[0x218] = 0
	p[0x224] = 0x100000
	p[0x1e0] = -0x300000
	p[0x1e4] = 0x80000
	p[0x1ec] = -0x200000
	p[0x1f0] = 0x60000
	gs[0] = [q0, q1]
	gs[4] = 2
	fgs[0] = [r0, r1]
	fgs[4] = 2
	q0[0x2bc] = 1
	q0[0x2b8] = 0
	q0[0x2c4] = 1
	q0[4] = 0x70000
	q0[8] = 0x10000
	q0[0x18c] = m
	q0[0x190] = ball
	q0[0x184] = gs
	q0[0x188] = fgs
	q0[0x3a4] = -0x1400000
	r0[0x2bc] = 1
	r0[0x2b8] = 1
	r0[0x2c4] = 0
	r0[4] = 0x200000
	r0[8] = -0x20000
	r0[0x18c] = m
	r0[0x190] = ball
	r0[0x3a4] = 0x1400000
	r1[0x2bc] = 1
	r1[0x2b8] = 1
	r1[0x2c4] = 1
	r1[4] = -0x100000
	r1[8] = 0x90000
	r1[0x18c] = m
	r1[0x190] = ball
	r1[0x3a4] = 0x1400000
	p[0x2b8] = 0
	p[0x2c4] = 0
	p[0x2bc] = 1
	p[0x3a4] = -0x1400000

	# --- per-fixture pokes ---
	for off in fx.get("p", {}):
		p[int(off)] = int(fx["p"][off])
	for off in fx.get("m", {}):
		m[int(off)] = int(fx["m"][off])
	for off in fx.get("b", {}):
		ball[int(off)] = int(fx["b"][off])
	for off in fx.get("q0", {}):
		q0[int(off)] = int(fx["q0"][off])
	for off in fx.get("r0", {}):
		r0[int(off)] = int(fx["r0"][off])
	var refs: Array = fx.get("refs", [])
	if refs.has("b40r0offpitch"):
		r0[0x2bc] = 0
		ball[0x40] = r0
	if refs.has("b40r0"):
		ball[0x40] = r0
	if refs.has("b40q0"):
		ball[0x40] = q0
	if refs.has("b40p"):
		ball[0x40] = p
	if refs.has("b4cr0"):
		ball[0x4c] = r0
	if refs.has("mark_r0"):
		p[0x150] = 0                                      # index model: R0 = foreign[0]
	else:
		p[0x150] = -1
	if refs.has("desig_q0"):
		gs[0x200] = q0

	_ok(bool(exp["ret"]), name + ": oracle row is a clean RET (re-run the oracle if HALT)")
	var rng = MatchEngine.Pm98Rng.new(1)
	var got_ret: int
	if String(fx["entry"]) == "b1500":
		got_ret = Pm98Movement.offball_opp_b1500(p, rng)
	else:
		got_ret = Pm98Movement.offball_own_b1c80(p, rng)
	if int(exp["eax"]) >= 0:
		_ok((got_ret & 0xff) == (int(exp["eax"]) & 0xff),
			"%s return: got %d want %d" % [name, got_ret & 0xff, int(exp["eax"]) & 0xff])

	var addr_map := [[p, ADDR_P], [m, ADDR_M], [ball, ADDR_C], [gs, ADDR_T], [fgs, ADDR_F],
		[q0, ADDR_Q0], [q1, ADDR_Q1], [r0, ADDR_R0], [r1, ADDR_R1]]
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
