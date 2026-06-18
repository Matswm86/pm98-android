extends SceneTree
## Oracle-backed parity test for the marker-assignment pass (Stage 3 task 2, slice 4):
## FUN_005b94f0 (Pm98Movement.assign_markers), which assembles slice 3's selector
## (select_mark_target = FUN_005b36f0) into the per-tick marking wiring.
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_assignmarker.gd
##
## ORACLE = the PM98 binary's own FUN_005b94f0 under the Ghidra PCode emulator
## (tools/re/run_assignmarker_oracle.sh; integer-only, no _ftol/LUT injection), banked at
## specs/assignmarker_oracle.txt as one `CALL 0 RET ... mem[...]=...` line per fixture.
## The fixture INPUTS are mirrored below (defaults + per-fixture overrides matching the
## runner pokes); the EXPECTED output is the mutated +0x150/+0x154 marker links and the
## possession-change scalar clears. +0x150 holds an OPP pointer, +0x154 an OUR pointer, so
## each link is mapped to the index model via (ptr - base) / 0x3bc (0 -> none = -1).

const OUR_BASE := 0x230000
const OPP_BASE := 0x240000
const STRIDE := 0x3bc

# Readback addresses, grouped by how the banked pointer maps back to an index.
const LINK_OPP := [0x230150, 0x23050c, 0x240150, 0x24050c]   # +0x150 -> opp index
const LINK_OUR := [0x230154, 0x230510, 0x240154, 0x240510]   # +0x154 -> our index
const SCALAR := [0x23013c, 0x230158, 0x230178]               # raw marking-block scalars

# Defaults mirror run_assignmarker_oracle.sh's base spec (passB_route2: Q0 holds the ball
# via route 2, P0 is its best marker, PASS C wires P1->Q1).
const DEF := {
	"team": 0, "poss_cur": 1, "poss_prev": 1, "ball_opp": 0, "blk40": -1,
	"p0x": 0x40000, "p0z": 0x40000, "p0anchor": 0x40000, "p0onp": 1, "p0tgt": -1,
	"p0q0": 0x50000, "p0q1": 0x90000, "p0_13c": 0, "p0_158": 0, "p0_178": 0,
	"p1x": 0x40000, "p1z": 0x40000, "p1anchor": 0x40000, "p1onp": 1, "p1tgt": -1,
	"p1q0": 0x90000, "p1q1": 0x50000,
	# +0x154 marker link inits to -1 = none (the binary's null; PASS B re-clears it anyway).
	"q0x": 0x50000, "q0z": 0x50000, "q0anchor": 0, "q0taken": -1, "q0p0": 0x40000, "q0p1": 0x80000,
	"q1x": 0x30000, "q1z": 0x30000, "q1anchor": 0, "q1taken": -1, "q1p0": 0x70000, "q1p1": 0x30000,
}

# Per-fixture overrides (must match the runner's FIX poke deltas exactly).
const FIXTURES := {
	"passB_route2": {},
	"in_possession": {"poss_cur": 0, "poss_prev": 0},
	"poss_change": {"poss_prev": 0, "p0_13c": 0x111, "p0_158": 0x222, "p0_178": 0x333},
	"passB_route1": {"ball_opp": -1, "blk40": 0},
	"passB_reject": {"q0x": 0, "q0anchor": 0},
	"passC_taken_guard": {"ball_opp": -1, "p0tgt": 0, "p1tgt": 0},
	"off_pitch": {"p1onp": 0},
}

var _fail := 0
var _pass := 0


func _init() -> void:
	var orc := _load_oracle()
	if orc.is_empty():
		_ok(false, "assignmarker oracle file empty/unreadable")
	else:
		for name in FIXTURES:
			if not orc.has(name):
				_ok(false, name + ": missing from oracle file")
				continue
			_run_fixture(name, orc[name])
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


func _ptr2idx(val: int, base: int) -> int:
	if val == 0:
		return -1
	return (val - base) / STRIDE


func _load_oracle() -> Dictionary:
	var out := {}
	var f := FileAccess.open(_spec_path("assignmarker_oracle.txt"), FileAccess.READ)
	if f == null:
		return {}
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if not line.begins_with("FIX "):
			continue
		var toks := line.split(" ", false)
		if toks.size() < 3:
			continue
		var ret := ""
		var reads := {}
		for t in toks:
			if t == "RET" or t == "HALT":
				ret = t
			elif t.begins_with("mem["):
				var inner := t.substr(4)                       # "0x230150:4]=2359296"
				var lb := inner.find("]")
				if lb < 0:
					continue
				var addr := inner.substr(0, lb).split(":")[0].hex_to_int()
				reads[addr] = inner.substr(lb + 2).to_int()    # after "]="
		out[toks[1]] = {"ret": ret, "reads": reads}
	return out


func _merged(name: String) -> Dictionary:
	var o := DEF.duplicate()
	for k in FIXTURES[name]:
		o[k] = FIXTURES[name][k]
	return o


func _build_ctx(o: Dictionary) -> Dictionary:
	var d0 := Pm98Movement._dist_off(0, 0)   # 0xe4  (our slot 0 = P0)
	var d1 := Pm98Movement._dist_off(1, 0)   # 0xe8  (our slot 1 = P1)
	var dq0 := Pm98Movement._dist_off(0, 1)  # 0x110 (opp slot 0 = Q0)
	var dq1 := Pm98Movement._dist_off(1, 1)  # 0x114 (opp slot 1 = Q1)
	var blk := {0x40: int(o.blk40)}          # shared controller block (player+0x190)
	var box := {0x210: 0, 0x214: 0, 0x218: 0, 0x21c: 0x1000000, 0x220: 0x1000000, 0x224: 0x1000000}
	var p0 := {
		0x4: int(o.p0x), 0x8: int(o.p0z), 0xc: 0, 0x3a4: int(o.p0anchor),
		0x2b8: 0, 0x2bc: int(o.p0onp), 0x2c4: 0, 0xb0: int(o.p0tgt), 0x1e0: 0,
		dq0: int(o.p0q0), dq1: int(o.p0q1),
		0x13c: int(o.p0_13c), 0x158: int(o.p0_158), 0x178: int(o.p0_178),
	}
	p0.merge(box)
	var p1 := {
		0x4: int(o.p1x), 0x8: int(o.p1z), 0xc: 0, 0x3a4: int(o.p1anchor),
		0x2b8: 0, 0x2bc: int(o.p1onp), 0x2c4: 1, 0xb0: int(o.p1tgt), 0x1e0: 0,
		dq0: int(o.p1q0), dq1: int(o.p1q1),
	}
	p1.merge(box)
	var q0 := {
		0x4: int(o.q0x), 0x8: int(o.q0z), 0xc: 0, 0x3a4: int(o.q0anchor),
		0x2b8: 1, 0x2bc: 1, 0x2c4: 0, 0x154: int(o.q0taken), 0x190: blk,
		d0: int(o.q0p0), d1: int(o.q0p1),
	}
	var q1 := {
		0x4: int(o.q1x), 0x8: int(o.q1z), 0xc: 0, 0x3a4: int(o.q1anchor),
		0x2b8: 1, 0x2bc: 1, 0x2c4: 1, 0x154: int(o.q1taken), 0x190: blk,
		d0: int(o.q1p0), d1: int(o.q1p1),
	}
	var m := {0x78c: [q0, q1], 0x165c: int(o.ball_opp), 0x1664: int(o.poss_cur), 0x1668: int(o.poss_prev), 0x1820: 0}
	var td := {0x2fc: 0, 0x300: 0, 0x310: 0}
	return {"players": [p0, p1], 0x8: int(o.team), 0x138: m, "team_desc": td}


func _run_fixture(name: String, exp: Dictionary) -> void:
	if exp.ret != "RET":
		_ok(false, "%s: oracle did not cleanly RET (%s)" % [name, exp.ret])
		return
	var ctx := _build_ctx(_merged(name))
	Pm98Movement.assign_markers(ctx)
	var players: Array = ctx["players"]
	var opp: Array = ctx[0x138][0x78c]
	var got := {
		0x230150: int(players[0].get(0x150, -1)), 0x230154: int(players[0].get(0x154, -1)),
		0x23050c: int(players[1].get(0x150, -1)), 0x230510: int(players[1].get(0x154, -1)),
		0x240150: int(opp[0].get(0x150, -1)), 0x240154: int(opp[0].get(0x154, -1)),
		0x24050c: int(opp[1].get(0x150, -1)), 0x240510: int(opp[1].get(0x154, -1)),
		0x23013c: int(players[0].get(0x13c, 0)), 0x230158: int(players[0].get(0x158, 0)),
		0x230178: int(players[0].get(0x178, 0)),
	}
	var reads: Dictionary = exp.reads
	for addr in got:
		if not reads.has(addr):
			_ok(false, "%s: addr 0x%x missing from oracle row" % [name, addr])
			continue
		var raw := int(reads[addr])
		var want: int
		if addr in LINK_OPP:
			want = _ptr2idx(raw, OPP_BASE)
		elif addr in LINK_OUR:
			want = _ptr2idx(raw, OUR_BASE)
		else:
			want = raw
		_ok(got[addr] == want, "%s @0x%x: got %d want %d (raw=%d)" % [name, addr, got[addr], want, raw])
