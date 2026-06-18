extends SceneTree
## Oracle-backed parity test for the per-tick relationship matrix + role selection
## (Stage 3 task 2, slice 2): FUN_005b8690 (Pm98Movement.build_relationship_matrix)
## and its tail-called role selector FUN_005b8a60 (Pm98Movement._select_roles).
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_relmatrix.gd
##
## ORACLE = the PM98 binary's own FUN_005b8690 under the Ghidra PCode emulator
## (tools/re/run_relmatrix_oracle.sh; faithful truncating _ftol injected, cos/atan LUT
## injected, exact-integer ball distances), banked at specs/relmatrix_oracle.txt as one
## verbatim `CALL 0 RET ... mem[0xADDR:W]=VAL ...` line per fixture. The fixture INPUTS
## are mirrored below; the EXPECTED outputs are read straight from the banked memory.
##
## Three readback classes: the role slots (S+0x1fc/+0x200/+0x204) hold PLAYER POINTERS
## in the oracle, mapped to the index model via (addr-0x230000)/0x3bc (0 -> null=-1);
## the tick counter (S+0x2e0) and the matrix fields are compared directly (masked to
## their byte width). Geometry mirrors the runner: t0_2v2 (full team-0 path: within +
## cross + roles + the +0x180 cone split), t1_within (team-1 within-only at the +11
## slots, nonzero facings exercising the ang-facing store, no cross/opp/+0x17c), tick_skip
## (the &7 throttle), ctrl_forced (controller forces the nearest-to-ball role slot).

const U32 := 0xffffffff
const U16 := 0xffff
const P_BASE := 0x230000
const P_STRIDE := 0x3bc

# Fixture inputs mirror tools/re/run_relmatrix_oracle.sh FIX. P = [x,y,z,facing,anchor],
# Q = [x,y,z,facing]. team / tick / optional ctrl(index)+ctrl_team match the pokes.
const FIXTURES := {
	"t0_2v2": {
		"team": 0, "tick": 7,
		"P": [[0x30000, 0x40000, 0, 0, 0x10000], [0x80000, 0x60000, 0, 0, 0x70000]],
		"Q": [[0x60000, 0x40000, 0, 0], [0x40000, 0xc0000, 0, 0]],
	},
	"t1_within": {
		"team": 1, "tick": 7,
		"P": [[0x30000, 0x40000, 0, 0x1000, 0x10000], [0x80000, 0x60000, 0, 0x9000, 0x70000]],
		"Q": [[0, 0, 0, 0], [0, 0, 0, 0]],
	},
	"tick_skip": {
		"team": 0, "tick": 0,
		"P": [[0x30000, 0x40000, 0, 0, 0], [0x80000, 0x60000, 0, 0, 0]],
		"Q": [[0x60000, 0x40000, 0, 0], [0x40000, 0xc0000, 0, 0]],
	},
	"ctrl_forced": {
		"team": 0, "tick": 7, "ctrl": 1, "ctrl_team": 0,
		"P": [[0x30000, 0x40000, 0, 0, 0x10000], [0x80000, 0x60000, 0, 0, 0x70000]],
		"Q": [[0x60000, 0x40000, 0, 0], [0x40000, 0xc0000, 0, 0]],
	},
}

# Matrix readback table: [obj, oracle_abs_addr, port_offset, width]. Mirrors the runner's
# READS exactly. obj selects the port Dict (P0/P1 = ctx players, Q0/Q1 = opponents).
const MATRIX_READS := [
	["P0", 0x2300ba, 0xba, 2], ["P0", 0x2300e8, 0xe8, 4], ["P0", 0x2300ce, 0xce, 2], ["P0", 0x2300d0, 0xd0, 2],
	["P0", 0x230110, 0x110, 4], ["P0", 0x230114, 0x114, 4], ["P0", 0x23017c, 0x17c, 4], ["P0", 0x230180, 0x180, 4],
	["P1", 0x230474, 0xb8, 2], ["P1", 0x2304a0, 0xe4, 4], ["P1", 0x23048a, 0xce, 2], ["P1", 0x23048c, 0xd0, 2],
	["P1", 0x2304cc, 0x110, 4], ["P1", 0x2304d0, 0x114, 4], ["P1", 0x230538, 0x17c, 4], ["P1", 0x23053c, 0x180, 4],
	["Q0", 0x2400b8, 0xb8, 2], ["Q0", 0x2400ba, 0xba, 2], ["Q0", 0x2400e4, 0xe4, 4], ["Q0", 0x2400e8, 0xe8, 4],
	["Q0", 0x24017c, 0x17c, 4], ["Q0", 0x240180, 0x180, 4],
	["Q1", 0x240474, 0xb8, 2], ["Q1", 0x240476, 0xba, 2], ["Q1", 0x2404a0, 0xe4, 4], ["Q1", 0x2404a4, 0xe8, 4],
	["Q1", 0x240538, 0x17c, 4], ["Q1", 0x24053c, 0x180, 4],
]

var _fail := 0
var _pass := 0


func _init() -> void:
	var orc := _load_oracle()
	if orc.is_empty():
		_ok(false, "relmatrix oracle file empty/unreadable")
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


# Map an oracle role POINTER to the index model (0 -> null=-1).
func _addr_to_idx(addr: int) -> int:
	if addr == 0:
		return -1
	return (addr - P_BASE) / P_STRIDE


func _load_oracle() -> Dictionary:
	var out := {}
	var f := FileAccess.open(_spec_path("relmatrix_oracle.txt"), FileAccess.READ)
	if f == null:
		return {}
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if not line.begins_with("FIX "):
			continue
		var toks := line.split(" ", false)
		if toks.size() < 5:
			continue
		var mem := {}
		for t in toks:
			if t.begins_with("mem["):
				# mem[0xADDR:W]=VAL
				var br := t.substr(4).split("]")     # ["0xADDR:W", "=VAL"]
				if br.size() < 2:
					continue
				var addr := br[0].split(":")[0].hex_to_int()
				mem[addr] = br[1].substr(1).to_int()  # drop the leading '='
		out[toks[1]] = {"ret": toks[4], "mem": mem}
	return out


func _build_ctx(fx: Dictionary) -> Dictionary:
	var team := int(fx["team"])
	var m := {
		0x1614: 0, 0x1618: 0, 0x161c: 0, 0x790: int(fx["Q"].size()),
		0x1650: int(fx.get("ctrl", -1)), 0x1664: int(fx.get("ctrl_team", -1)),
	}
	var players: Array = []
	var pp: Array = fx["P"]
	for i in pp.size():
		players.append({
			0x4: int(pp[i][0]), 0x8: int(pp[i][1]), 0xc: int(pp[i][2]), 0x34: int(pp[i][3]),
			0x2b8: team, 0x2bc: 1, 0x2c4: i, 0x3a4: int(pp[i][4]),
		})
	var opp: Array = []
	var qq: Array = fx["Q"]
	for k in qq.size():
		opp.append({
			0x4: int(qq[k][0]), 0x8: int(qq[k][1]), 0xc: int(qq[k][2]), 0x34: int(qq[k][3]),
			0x2b8: 1, 0x2bc: 1, 0x2c4: k,
		})
	m[0x78c] = opp
	return {"players": players, 0x8: team, 0x138: m, 0x2e0: int(fx["tick"])}


func _eq_role(name: String, field: String, port_idx: int, oracle_ptr: int) -> void:
	var want := _addr_to_idx(oracle_ptr)
	_ok(port_idx == want, "%s role.%s: got %d want %d" % [name, field, port_idx, want])


func _run_fixture(name: String, exp: Dictionary) -> void:
	if exp.ret != "RET":
		_ok(false, "%s: oracle did not cleanly RET (%s)" % [name, exp.ret])
		return
	var fx: Dictionary = FIXTURES[name]
	var ctx := _build_ctx(fx)
	Pm98Movement.build_relationship_matrix(ctx)
	var mem: Dictionary = exp.mem

	# Role slots: oracle stores player pointers; map to indices.
	_eq_role(name, "furthest", int(ctx.get(0x1fc, -1)), int(mem.get(0x2001fc, 0)))
	_eq_role(name, "nearest", int(ctx.get(0x200, -1)), int(mem.get(0x200200, 0)))
	_eq_role(name, "ball", int(ctx.get(0x204, -1)), int(mem.get(0x200204, 0)))
	# Tick counter (post-increment, masked).
	_ok(int(ctx.get(0x2e0, 0)) == (int(mem.get(0x2002e0, 0)) & U32), "%s tick: got %d want %d" % [name, int(ctx.get(0x2e0, 0)), int(mem.get(0x2002e0, 0))])

	# Matrix fields (direct, masked to byte width).
	var players: Array = ctx["players"]
	var opp: Array = ctx[0x138][0x78c]
	var objmap := {"P0": players[0], "P1": players[1], "Q0": opp[0], "Q1": opp[1]}
	for r in MATRIX_READS:
		var obj: Dictionary = objmap[r[0]]
		var mask := U16 if int(r[3]) == 2 else U32
		var got := int(obj.get(int(r[2]), 0)) & mask
		var want := int(mem.get(int(r[1]), 0)) & mask
		_ok(got == want, "%s %s@0x%x: got %d want %d" % [name, r[0], int(r[2]), got, want])
