extends SceneTree
## Oracle-backed parity test for the EXACT match-event DISPATCHER (Stage 3 task 2):
## FUN_005966d0 (-> Pm98Dispatch.dispatch) + the case-1 aggregate helper FUN_00450e60
## (-> Pm98Dispatch._agg_decision).
##
## Run headless from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_dispatch.gd
##
## ORACLE = the PM98 binary's own FUN_005966d0 / FUN_00450e60 under the Ghidra PCode
## emulator (tools/re/run_dispatch_oracle.sh: realloc FUN_005bbf10 + lstrcpyA stubbed,
## event buffer pre-set, cos/atan LUT injected for case 2, commentary flag 0x180b OFF,
## RNG state seeded to 1), banked at tools/re/specs/dispatch_oracle.txt. Fixture INPUTS
## are embedded below (mirroring the runner's matrices); EXPECTED outputs are read from
## the banked file, so there is no hand-transcription. Each dispatch is seeded with the
## same RNG state (1) so the final rng.state proves the conditional draws (case 2 / 6)
## fire in exactly the binary's places (1 == no draw, 2745024 == one draw).

const U32 := 0xffffffff
const RNG_SEED := 1

var _fail := 0
var _pass := 0


func _init() -> void:
	var orc := _load_oracle()
	var disp: Dictionary = orc.get("disp", {})
	var agg: Dictionary = orc.get("agg", {})
	if disp.is_empty() or agg.is_empty():
		_ok(false, "dispatch oracle file empty/unreadable")
	for name in _disp_names():
		if not disp.has(name):
			_ok(false, "D " + name + ": missing from oracle file")
			continue
		_run_disp(name, disp[name])
	for name in _agg_fixtures():
		if not agg.has(name):
			_ok(false, "A " + name + ": missing from oracle file")
			continue
		_run_agg(name, _agg_fixtures()[name], int(agg[name]))
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


func _eq(name: String, field: String, got: int, want: int) -> void:
	_ok((got & U32) == (want & U32), "%s %s: got %d want %d" % [name, field, got & U32, want & U32])


func _spec_path(n: String) -> String:
	return ProjectSettings.globalize_path("res://").path_join("../tools/re/specs/").path_join(n).simplify_path()


# Parse the banked table. D rows: name|count|e0|e1|e2|rng|d4|frz|p448|p44c|cd|a2c|RET
# (each eN = "c,x,y,d"). A rows: name|result|RET.
func _load_oracle() -> Dictionary:
	var disp := {}
	var agg := {}
	var f := FileAccess.open(_spec_path("dispatch_oracle.txt"), FileAccess.READ)
	if f == null:
		return {}
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if line == "" or line.begins_with("#"):
			continue
		var c := line.split("|")
		var head := c[0].strip_edges().split(" ", false)
		if head.size() < 2:
			continue
		var nm := head[1]
		if head[0] == "D" and c.size() >= 13:
			disp[nm] = {
				"count": c[1].strip_edges().to_int(),
				"events": [_ev(c[2]), _ev(c[3]), _ev(c[4])],
				"rng": c[5].strip_edges().to_int(), "d4": c[6].strip_edges().to_int(),
				"frz": c[7].strip_edges().to_int(), "p448": c[8].strip_edges().to_int(),
				"p44c": c[9].strip_edges().to_int(), "cd": c[10].strip_edges().to_int(),
				"a2c": c[11].strip_edges().to_int(),
			}
		elif head[0] == "A" and c.size() >= 2:
			agg[nm] = c[1].strip_edges().to_int()
	return {"disp": disp, "agg": agg}


func _ev(cell: String) -> Array:
	var p := cell.strip_edges().split(",")
	var out: Array = []
	for x in p:
		out.append(x.strip_edges().to_int())
	return out  # [code, x, y, delay]


func _run_disp(name: String, exp: Dictionary) -> void:
	var built := _build_disp(name)
	var m: Dictionary = built[0]
	var outcome: int = built[1]
	var rng := MatchEngine.Pm98Rng.new(RNG_SEED)
	var ret := Pm98Dispatch.dispatch(m, outcome, rng, 0)
	# queue + per-event records
	var q: Array = m.get(0x1a24, [])
	_eq(name, "count", int(m.get(0x1a28, 0)), exp.count)
	_eq(name, "qsize", q.size(), exp.count)
	for i in range(exp.count):
		if i >= q.size():
			_ok(false, "%s ev%d: missing (queue too short)" % [name, i])
			continue
		var got: Array = q[i]
		var want: Array = exp.events[i]
		_eq(name, "ev%d.code" % i, int(got[0]), int(want[0]))
		_eq(name, "ev%d.x" % i, int(got[1]), int(want[1]))
		_eq(name, "ev%d.y" % i, int(got[2]), int(want[2]))
		_eq(name, "ev%d.delay" % i, int(got[3]), int(want[3]))
	# RNG draw parity, the display/bookkeeping fields, and the freeze (== return).
	_eq(name, "rng", rng.state, exp.rng)
	_eq(name, "d4", int(m.get(0x19d4, 0)), exp.d4)
	_eq(name, "frz", int(m.get(0x1a38, 0)), exp.frz)
	_eq(name, "ret==frz", ret, exp.frz)
	_eq(name, "p448", int(m.get(0x448, 0)), exp.p448)
	_eq(name, "p44c", int(m.get(0x44c, 0)), exp.p44c)
	_eq(name, "cd", int(m.get(0x454, 0)), exp.cd)
	_eq(name, "a2c", int(m.get(0x1a2c, 0)), exp.a2c)


func _run_agg(name: String, team: Dictionary, want: int) -> void:
	_eq(name, "result", Pm98Dispatch._agg_decision(team), want)


# ---- fixture inputs (mirror tools/re/run_dispatch_oracle.sh DISP / AGG) ----------
# A player == {0x2b8: display-x/team-id, 0x2c0: display-y}; the team object lives at
# match+0x468 with phase +0xfa0, cup flags +0x44/+0x48, +0x14. Base match has the
# commentary flag implicitly OFF (the port never reads 0x180b).
func _team(extra := {}) -> Dictionary:
	var t := {0xfa0: 0, 0x14: 0, 0x44: 0, 0x48: 0}
	for k in extra:
		t[k] = extra[k]
	return t


func _disp_names() -> Array:
	return ["busy", "sub_corner", "phase_ko", "phase_ht", "phase_et_end", "phase_ft_replay",
		"phase_ft_2leg", "phase_ft_done", "buildup_nodraw", "buildup_draw", "buildup_sub",
		"restart", "restart_et", "corner", "foul_normal", "foul_yellow", "foul_2yellow",
		"foul_red", "offside", "goal", "goal_draw", "owngoal", "pen_nocard", "pen_yellow",
		"pen_red"]


# Returns [match_dict, outcome] for the named fixture.
func _build_disp(name: String) -> Array:
	var m := {0x454: 0, 0x1998: 0, 0x1a38: 0, 0x468: _team()}
	match name:
		"busy":
			m[0x454] = 0x99
			return [m, 6]
		"sub_corner":
			m[0x440] = {0x2b8: 0x11, 0x2c0: 0x22}
			m[0x45c] = 0
			m[0x46c] = {0x2b8: 0x33, 0x2c0: 0x44}
			return [m, 4]
		"phase_ko":
			m[0x19a0] = 0
			return [m, 1]
		"phase_ht":
			m[0x19a0] = 2
			return [m, 1]
		"phase_et_end":
			m[0x19a0] = 4
			return [m, 1]
		"phase_ft_replay":
			m[0x19a0] = 1
			m[0x468] = _team({0x44: 1})
			return [m, 1]
		"phase_ft_2leg":
			m[0x19a0] = 1
			m[0x468] = _team({0x48: 1})
			return [m, 1]
		"phase_ft_done":
			m[0x19a0] = 1
			return [m, 1]
		"buildup_nodraw":
			m[0x165c] = 0
			m[0x1630] = 0x30000
			m[0x1634] = 0x40000
			return [m, 2]
		"buildup_draw":
			m[0x165c] = 1
			m[0x1630] = 0x30000
			m[0x1634] = 0x40000
			return [m, 2]
		"buildup_sub":
			m[0x440] = {0x2b8: 0x11, 0x2c0: 0x22}
			m[0x165c] = 1
			m[0x1630] = 0x30000
			m[0x1634] = 0x40000
			return [m, 2]
		"restart":
			m[0x19a0] = 0
			return [m, 3]
		"restart_et":
			m[0x19a0] = 4
			return [m, 3]
		"corner":
			m[0x45c] = 0
			m[0x46c] = {0x2b8: 0x55, 0x2c0: 0x66}
			return [m, 4]
		"foul_normal":
			m[0x460] = 0
			m[0x461] = 0
			m[0x43c] = {0x2b8: 0x77, 0x2c0: 0x88}
			return [m, 5]
		"foul_yellow":
			m[0x460] = 0
			m[0x461] = 2
			m[0x43c] = {0x2b8: 0x77, 0x2c0: 0x88}
			return [m, 5]
		"foul_2yellow":
			m[0x460] = 0
			m[0x461] = 4
			m[0x43c] = {0x2b8: 0x77, 0x2c0: 0x88}
			return [m, 5]
		"foul_red":
			m[0x460] = 0
			m[0x461] = 6
			m[0x43c] = {0x2b8: 0x77, 0x2c0: 0x88}
			return [m, 5]
		"offside":
			m[0x460] = 1
			m[0x43c] = {0x2b8: 0x77, 0x2c0: 0x88}
			return [m, 5]
		"goal":
			m[0x444] = {0x2b8: 1, 0x2c0: 0x99}
			m[0x45c] = 0
			m[0x19a0] = 0
			m[0x461] = 0
			m[0x462] = 0
			return [m, 6]
		"goal_draw":
			m[0x444] = {0x2b8: 1, 0x2c0: 0x99}
			m[0x45c] = 0
			m[0x19a0] = 0
			m[0x461] = 0x20
			m[0x462] = 0
			return [m, 6]
		"owngoal":
			m[0x444] = {0x2b8: 0, 0x2c0: 0x99}
			m[0x45c] = 0
			m[0x19a0] = 0
			m[0x461] = 0x20
			m[0x462] = 0
			return [m, 6]
		"pen_nocard":
			m[0x461] = 0
			m[0x43c] = {0x2b8: 0xaa, 0x2c0: 0xbb}
			return [m, 7]
		"pen_yellow":
			m[0x461] = 2
			m[0x43c] = {0x2b8: 0xaa, 0x2c0: 0xbb}
			return [m, 7]
		"pen_red":
			m[0x461] = 6
			m[0x43c] = {0x2b8: 0xaa, 0x2c0: 0xbb}
			return [m, 7]
	return [m, 0]


# Aggregate fixtures: team object (+0x468 sub-struct) with a goal log at +0xf98 =
# Array of 4-int records [type, _, sideflag, teamid], ids at +0x7e8 (home) / +0xf88.
func _agg_fixtures() -> Dictionary:
	return {
		"agg_draw0": {0x48: 0},
		"agg_leaf1": {0x48: 0, 0x7e8: 7, 0xf88: 9, 0xf98: [[7, 0, 0, 7]]},
		"agg_2leg1": {0x48: 1, 0x2c: 0xff, 0x30: 0xff, 0x7e8: 7, 0xf88: 9,
			0xf98: [[7, 0, 0, 7], [7, 0, 0, 7]]},
		"agg_2leg2": {0x48: 1, 0x2c: 0xff, 0x30: 0xff, 0x7e8: 7, 0xf88: 9,
			0xf98: [[7, 0, 0, 9], [7, 0, 0, 9]]},
	}
