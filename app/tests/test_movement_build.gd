extends SceneTree
## RE Stage 3 task 2 item 3c -- reconcile the Pm98Movement OPPONENT-descriptor model with
## the faithful roster build. Pm98Match builds the match with the two team HEADERS nested at
## m[0x46c]/m[0x78c] (and m["sim"] = [team0, team1]); each header carries its roster in
## team["players"]. The earlier Movement slices read m[0x78c] as a FLAT opponent players
## Array (a team-0 fixture simplification). This test proves the reconciled path: with a real
## built match, m[0x78c] is a Dict HEADER (indexing it as an array would crash / read garbage),
## yet build_relationship_matrix now reaches the opponent roster via _opp_players(ctx) =
## m["sim"][1-team]["players"] and writes the full cross-team matrix. Run:
##   ~/godot462 --headless --path app --script res://tests/test_movement_build.gd
##
## This is structural wiring proof (not an oracle pin): the matrix VALUES are oracle-locked
## by test_relmatrix; here we assert the build's nested headers feed Movement at all.

const U32 := 0xffffffff
const SEED := 0x12345678
const SESSION := {0x4c: 0x6000000, 0x50: 0x4000000, 0xfd8: 1, 0xfdc: 0, 0xff4: 2}

var _fail := 0
var _pass := 0


func _init() -> void:
	_test_model_shape()
	_test_opp_team_helper()
	_test_matrix_drives_built_roster()
	print("")
	if _fail == 0:
		print("ALL PASS (%d checks)" % _pass)
	else:
		print("FAILED: %d / %d" % [_fail, _pass + _fail])
	quit(1 if _fail > 0 else 0)


func _gk_record() -> Dictionary:
	return {0x4: 1, 0x28: 0, 0x2c: 1, 0x30: 1, 0x34: 60, 0x35: 70, 0x36: 20, 0x38: 40,
		0x3c: 30, 0x3d: 80, 0x3e: 50, 0x3f: 60, 0x40: 50, 0x41: 70, 0x42: 100, 0x44: 2, 0x98: 0}

func _outfield_record(shirt: int, ability: int) -> Dictionary:
	return {0x4: shirt, 0x8: 11, 0xc: 22, 0x10: 33, 0x14: 44, 0x18: 55, 0x1c: 66, 0x20: 77,
		0x24: 88, 0x28: 111, 0x2c: 3, 0x30: 5, 0x34: 70, 0x35: 80, 0x36: 30, 0x38: 50, 0x3c: 40,
		0x3d: 90, 0x3e: 55, 0x3f: 65, 0x40: ability, 0x41: 75, 0x42: 100, 0x44: 5, 0x98: 1}

func _lineup() -> Dictionary:
	var slots := [_gk_record(), _outfield_record(7, 60), _outfield_record(9, 80)]
	slots.resize(11)
	return {"header": [10, 20, 30, 40, 50, 60, 70, 80, 90], "slots": slots}


## A full built match with BOTH teams' rosters loaded (kickoff_init drives the per-team build).
func _built_match() -> Dictionary:
	var m := Pm98Match.build_match(MatchEngine.Pm98Rng.new(0xDEADBEEF))
	m["sim"][0][0x9c] = _lineup()
	m["sim"][1][0x9c] = _lineup()
	Pm98Match.kickoff_init(m, SESSION.duplicate(), MatchEngine.Pm98Rng.new(SEED))
	return m


# 1. The data-model contract that BROKE the old flat read: m[0x78c] is the team1 HEADER Dict
#    (== m["sim"][1]), NOT a bare players Array. Indexing it as opp[k] would have read header
#    fields (ints) and crashed on opp[k][0x17c] = ... ; the reconciliation routes around it.
func _test_model_shape() -> void:
	var m := _built_match()
	_ok(m.get(0x78c) is Dictionary, "m[0x78c] is the team header Dict (not an Array)")
	_ok(m.get(0x46c) is Dictionary, "m[0x46c] is the team0 header Dict")
	_ok(m[0x78c] == m["sim"][1], "m[0x78c] === m['sim'][1] (same header object)")
	_ok(m[0x46c] == m["sim"][0], "m[0x46c] === m['sim'][0] (same header object)")
	_ok((m["sim"][1]["players"] as Array).size() == 3, "team1 header carries its 3-player roster")


# 2. _opp_players/_opp_team resolve the opponent roster from the nested headers, for BOTH
#    team contexts (the binary's match+0x78c-800*team), returning the SAME array object the
#    build stored -- i.e. the sim-sourced path, not the legacy fallback.
func _test_opp_team_helper() -> void:
	var m := _built_match()
	var t0: Dictionary = m["sim"][0]
	var t1: Dictionary = m["sim"][1]
	# team-0 context -> opponent is team1's roster.
	_ok(Pm98Movement._opp_team(t0) == t1, "_opp_team(team0) == team1 header")
	_ok(Pm98Movement._opp_players(t0) == t1["players"], "_opp_players(team0) IS team1['players'] (shared ref)")
	# team-1 context -> opponent is team0's roster (proves the team-1 generality the old hardcode lacked).
	_ok(Pm98Movement._opp_team(t1) == t0, "_opp_team(team1) == team0 header")
	_ok(Pm98Movement._opp_players(t1) == t0["players"], "_opp_players(team1) IS team0['players'] (shared ref)")


# 3. The relationship matrix, driven on the team-0 built header, reaches the opponent roster
#    via the nested model and writes the cross-team matrix into team1's players in place.
func _test_matrix_drives_built_roster() -> void:
	var m := _built_match()
	var t0: Dictionary = m["sim"][0]
	var t1: Dictionary = m["sim"][1]
	var us: Array = t0["players"]
	var them: Array = t1["players"]

	# give the players live planar coordinates (the build sets start-pos fields, not 0x4/0x8/0xc).
	for i in us.size():
		us[i][0x4] = (i + 1) * 0x100000   # x
		us[i][0x8] = 0                    # y
		us[i][0xc] = 0                    # z
		us[i][0x34] = 0                   # facing
	for k in them.size():
		them[k][0x4] = -(k + 1) * 0x100000
		them[k][0x8] = 0x80000
		them[k][0xc] = 0
		them[k][0x34] = 0

	# opponents start with NO matrix fields; the build never writes 0x17c/0x180/the dist keys.
	for q in them:
		_ok(not q.has(0x17c), "pre: opponent has no nearest-opp field 0x17c")

	# throttle: build_relationship_matrix runs only when (ctx[0x2e0]+1)&7 == 0.
	t0[0x2e0] = 7
	Pm98Movement.build_relationship_matrix(t0)

	_eqx(_g(t0, 0x2e0), 0, "throttle fired: team0[0x2e0] == 0")

	# every opponent now carries the seeded nearest-opp fields -> Movement reached team1['players'].
	for k in them.size():
		var q: Dictionary = them[k]
		_ok(q.has(0x17c), "opponent[%d] nearest-opp 0x17c written" % k)
		_ok(q.has(0x180), "opponent[%d] nearest-in-front 0x180 written" % k)
		_ok(int(q[0x17c]) >= 0 and int(q[0x17c]) <= Pm98Movement.MATRIX_INIT,
			"opponent[%d] 0x17c in (0 .. 1000.0]" % k)

	# our players carry the cross-team matrix dist key for each opponent slot (team col 1).
	for i in us.size():
		for k in them.size():
			_ok(us[i].has(Pm98Movement._dist_off(k, 1)),
				"our[%d] has cross-team dist to opp slot %d" % [i, k])

	# at least one real (nonzero) cross-team projection flowed through (geometry, not just seeds).
	var any_nonzero := false
	for i in us.size():
		for k in them.size():
			if int(us[i].get(Pm98Movement._dist_off(k, 1), 0)) != 0:
				any_nonzero = true
	_ok(any_nonzero, "a nonzero cross-team matrix distance was computed")


func _ok(cond: bool, msg: String) -> void:
	if cond:
		_pass += 1
	else:
		_fail += 1
		print("  [FAIL] ", msg)


func _eqx(got: int, want: int, msg: String) -> void:
	_ok((got & U32) == (want & U32), "%s: got 0x%x want 0x%x" % [msg, got & U32, want & U32])


func _g(d: Dictionary, off: int) -> int:
	return int(d.get(off, 0))
