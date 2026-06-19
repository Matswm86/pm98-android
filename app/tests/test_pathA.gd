extends SceneTree
## Oracle-backed parity test for FUN_005b73a0 slice H (the phase-5 tail PATH A, defensive
## distribution), ported in Pm98Movement._phase5_tail_pathA (via position_team / _position_phase5_tail).
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_pathA.gd
##
## ORACLE = the REAL FUN_005b73a0 phase-5 branch under the Ghidra PCode emulator (the wall runs first,
## then path A; relmatrix throttle-skipped; atan/cos LUT + faithful _ftol + a faithful backward-copy
## memmove injected), tools/re/run_pathA_oracle.sh -> specs/pathA_oracle.txt. OUR players base 0x240000,
## stride 0x3bc (ids 1/2/3/4, EXCLUDED roles 12/13/14/16 -> wall endpoint1; P1 endpoint sits outside the
## box so path A reflects it). N = match+0x19cc fixes the fan size. Reads +0x4/+0x8/+0xc/+0x34/+0x40.
##
## Only EVEN N is exercised: a fan radius = ftol(14745.6 * (2*slot - N)), so even N keeps every radius a
## multiple of 2*0.225*65536 (fraction .0/.2/.4), OFF the .5 truncation boundary. The port truncates
## toward zero (the real x87 _ftol, per Pm98Trig); the PCode emulator's `fist` round-to-nearests at .5
## (ignoring the injected truncate control word), so an ODD-N radius like -44236.8 would bank the
## emulator's -44237 artifact instead of the real binary's -44236. Even N keeps oracle == binary == port.

const U32 := 0xffffffff
const BASE := 0x240000
const STRIDE := 0x3bc
const FIX := ["pathA_n2", "pathA_n4"]

var _fail := 0
var _pass := 0


func _init() -> void:
	var orc := _load_oracle()
	if orc.is_empty():
		_ok(false, "pathA oracle file empty/unreadable")
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
	var f := FileAccess.open(_spec_path("pathA_oracle.txt"), FileAccess.READ)
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


func _chk(name: String, players: Array, idx: int, off: int, exp: Dictionary) -> void:
	var addr := BASE + idx * STRIDE + off
	if not exp.has(addr):
		return
	var got := int((players[idx] as Dictionary).get(off, 0)) & U32
	var want := int(exp[addr]) & U32
	_ok(got == want, "%s P%d+0x%x: got 0x%x want 0x%x" % [name, idx, off, got, want])


func _run(name: String, exp: Dictionary) -> void:
	var n := int(name.substr(name.length() - 1))            # pathA_nK -> K
	# Match: phase 5, 0x19cc = N, opponent's set-piece (0x45c=1 != team0), goalx 0x140000, ball.
	var m := {
		0x448: 5, 0x19cc: n, 0x45c: 1, 0x19a0: 0, 0x16a4: 0, 0x1820: 0x140000,
		0x1614: 0x80000, 0x1618: 0, 0x161c: 0,
		0x1828: -0x800000, 0x1834: 0x800000, 0x182c: -0x800000, 0x1838: 0x800000,
		0x1830: -0x800000, 0x183c: 0x800000,
	}
	var taker := {0x4: 0x5000000, 0x8: 0, 0xc: 0, 0x34: 0x2000}
	m[0x438] = taker
	var keeper := {0x2c4: 0, 0x18c: m}                      # O0, pre-claimed -> never a candidate
	# OUR players: ids 1/2/3/4, excluded roles -> wall endpoint1; P1 endpoint OUTSIDE box -> reflect.
	var players := [
		_mk(m, 1, 12, 0x100000, 0x100000, 0),
		_mk(m, 2, 13, 0x2000000, 0, 0),
		_mk(m, 3, 14, -0x100000, 0x200000, 0),
		_mk(m, 4, 16, 0x300000, -0x180000, 0),
	]
	var ctx := {
		0x0: 0, 0x4: players.size(), 0x8: 0, 0x138: m, 0x2e0: 0,
		"players": players, "opponents": [keeper], "opp_keeper": 0,
	}

	Pm98Movement.position_team(ctx, MatchEngine.Pm98Rng.new(1))

	for idx in players.size():
		for off in [0x4, 0x8, 0xc, 0x34, 0x40]:
			_chk(name, players, idx, off, exp)


## A player: on-pitch, given id/role, endpoint1 (+0x1e0) = the wall loop-4 miss target = its pre-pass-1
## position; team 0; +0x18c -> match.
func _mk(m: Dictionary, id: int, role: int, ex: int, ey: int, ez: int) -> Dictionary:
	return {
		0x2bc: 1, 0x2c8: role, 0x2c4: id, 0x18c: m, 0x2b8: 0,
		0x1e0: ex, 0x1e4: ey, 0x1e8: ez, 0x4: ex, 0x8: ey, 0xc: ez,
	}
