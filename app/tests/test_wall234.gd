extends SceneTree
## Oracle-backed parity test for FUN_005b73a0 phase-4 DEFENSIVE-WALL LOOPS 2-4 (disasm
## 0x5b763e..0x5b7ba0), ported in Pm98Movement._position_wall + _wall_nearest_opp (via position_team).
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_wall234.gd
##
## ORACLE = the REAL FUN_005b73a0 phase-4 branch under the Ghidra PCode emulator (relmatrix
## throttle-skipped, faithful _ftol injected, loop-5 atan LUT injected, RNG seed @0x6d3184),
## tools/re/run_wall234_oracle.sh -> specs/wall234_oracle.txt.
## Players: base 0x240000, stride 0x3bc (P0=GK id0 parked far @0x240000, P1=target @0x2403bc).
## Every fixture: match+0x448=4, +0x45c=1 (opponent's set-piece), team 0 -> _position_wall fires;
## P0 (GK id0) is auto-skipped (our-assigned seed {0}); only P1 falls through to loops 2-4.

const U32 := 0xffffffff
const BASE := 0x240000
const STRIDE := 0x3bc
const WIDE := 0x40000000
const FIX := [
	"l2_marktarget", "l3_nearest_o0", "l3_nearest_o1", "l4_hit_o0", "l4_hit_o1",
	"l4_endpoint", "l4_goalrng_o0", "l4_goalrng_o1",
]

var _fail := 0
var _pass := 0


func _init() -> void:
	var orc := _load_oracle()
	if orc.is_empty():
		_ok(false, "wall234 oracle file empty/unreadable")
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


func _load_oracle() -> Dictionary:
	var out := {}
	var f := FileAccess.open(_spec_path("wall234_oracle.txt"), FileAccess.READ)
	if f == null:
		return {}
	var rx := RegEx.new()
	rx.compile("mem\\[0x([0-9a-fA-F]+):[0-9]+\\]=(-?[0-9]+)")
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if not line.begins_with("FIX "):
			continue
		var toks := line.split(" ", false)
		var row := {}
		for mtch in rx.search_all(line):
			row[("0x" + mtch.get_string(1)).hex_to_int()] = mtch.get_string(2).to_int()
		out[toks[1]] = row
	return out


## Wide-box match so pos_forward_ok's box test always passes; goalx base 0x140000.
func _mk_match(orient: int) -> Dictionary:
	return {
		0x448: 4, 0x45c: 1, 0x19a0: orient, 0x1820: 0x140000, 0x16a4: 0,
		0x1614: 0, 0x1618: 0, 0x161c: 0,
		0x1828: -WIDE, 0x1834: WIDE, 0x182c: -WIDE, 0x1838: WIDE, 0x1830: -WIDE, 0x183c: WIDE,
	}


## A valid-forward opponent at (x,y,z): on-pitch, given id/role, anchor sign opposite x.
func _opp(m: Dictionary, id: int, role: int, x: int, y: int, z: int, anchor: int) -> Dictionary:
	return {0x2c4: id, 0x2c8: role, 0x2bc: 1, 0x18c: m, 0x4: x, 0x8: y, 0xc: z, 0x3a4: anchor}


func _chk(name: String, players: Array, idx: int, off: int, exp: Dictionary) -> void:
	var addr := BASE + idx * STRIDE + off
	if not exp.has(addr):
		return
	var got := int((players[idx] as Dictionary).get(off, 0)) & U32
	var want := int(exp[addr]) & U32
	_ok(got == want, "%s P%d+0x%x: got 0x%x want 0x%x" % [name, idx, off, got, want])


func _run(name: String, exp: Dictionary) -> void:
	var orient := 1 if name.ends_with("_o1") else 0
	var m := _mk_match(orient)
	var gk := {0x2c8: 0xc, 0x2c4: 0, 0x2bc: 1, 0x18c: m, 0x4: -0x2000000, 0x2b8: 0}
	var p1 := {0x2c8: 4, 0x2c4: 1, 0x2bc: 1, 0x18c: m, 0x2b8: 0, 0x4: 0, 0x8: 0, 0xc: 0}
	var keeper := {0x2c4: 0, 0x18c: m}                       # O0, seeds opp-claimed {0}
	var opps := [keeper]

	match name:
		"l2_marktarget":
			var o1 := _opp(m, 1, 7, 0x100000, 0x40000, 0x20000, -0x10000)
			opps.append(o1)
			p1[0xb0] = o1                                    # mark-target ptr -> O1
		"l3_nearest_o0", "l3_nearest_o1":
			opps.append(_opp(m, 1, 7, 0x80000, 0, 0, -0x10000))   # near -> chosen
			opps.append(_opp(m, 2, 7, 0x200000, 0, 0, -0x10000))  # far
		"l4_hit_o0", "l4_hit_o1":
			p1[0x2c8] = 0xc                                  # EXCLUDED role -> loop 3 skips it
			opps.append(_opp(m, 1, 7, 0x100000, 0, 0, -0x10000))  # within 100.0 -> loop-4 hit
		"l4_endpoint":
			p1[0x2c8] = 0xc                                  # excluded role
			p1[0x1e0] = 0x111111; p1[0x1e4] = 0x222222; p1[0x1e8] = 0x333333
			opps.append(_opp(m, 1, 7, 0x2000000, 0, 0, -0x10000)) # > 100.0 -> miss -> endpoint1
		"l4_goalrng_o0", "l4_goalrng_o1":
			pass                                             # keeper-only: no candidate -> goal+RNG

	var players := [gk, p1]
	var ctx := {0x0: 0, 0x4: players.size(), 0x8: 0, 0x138: m, 0x2e0: 0,
		"players": players, "opponents": opps, "opp_keeper": 0}

	Pm98Movement.position_team(ctx, MatchEngine.Pm98Rng.new(1))

	_chk(name, players, 1, 0x4, exp)
	_chk(name, players, 1, 0x8, exp)
	_chk(name, players, 1, 0xc, exp)
