extends SceneTree
## M5 KICKOFF PLACEMENT diagnostic: byte-load frame0, drive to the kick, and dump for BOTH team0
## forwards (slot-9 taker + slot-8 receiver) the actual pos (0x4/0x8), the slice-A endpoints
## (0x1e0/0x1ec), and the case-2 box inputs (m 0x19a0/0x1820/0x1824, goal_target_x, yscale).
## Real reference (correct-seed capture): slot-9 @clk0 (-26214,-39); slot-8 @clk12 (-21415,-80668).
## Run: ~/godot462 --headless --path app --script res://tests/diag_m5_kickplace.gd

const REF_DIR := "/home/mats/MWM-AI/data/pm98-m4-oracle/capture2"
const STRUCT_JSON := REF_DIR + "/frame0_struct_import.json"
const FRAME0_SEED := 0xea0d2a8d


func _init() -> void:
	_run()
	quit(0)


func _run() -> void:
	var dump := _load_json(STRUCT_JSON)
	if dump.is_empty():
		push_error("no struct json"); return
	var throwaway := MatchEngine.Pm98Rng.new(1)
	var m := Pm98Match.build_match(throwaway)
	Pm98CollBuilder.populate_posts(m)
	for k in (dump["match"] as Dictionary):
		m[_hx(k)] = int((dump["match"] as Dictionary)[k])
	var session := {}
	for k in (dump["session"] as Dictionary):
		if k == "_va": continue
		session[_hx(k)] = int((dump["session"] as Dictionary)[k])
	m[0x468] = session
	var ball: Dictionary = m["ball"]
	var teams: Array = m["sim"]
	var built := [[], []]
	for ti in range(2):
		var own: Dictionary = teams[ti]
		var opp: Dictionary = teams[1 - ti]
		for src in ((dump["players"] as Array)[ti] as Array):
			(built[ti] as Array).append(_load_player(src as Dictionary, own, opp, m, ball))
	for ti in range(2):
		_load_team_header(teams[ti] as Dictionary, (dump["team_headers"] as Array)[ti] as Dictionary,
			built[ti] as Array, ti, m)
	var rng := MatchEngine.Pm98Rng.new(0)
	rng.state = FRAME0_SEED

	print("m: 0x19a0(orient)=%d 0x1820(xscale)=%d 0x1824(yscale)=%d 0x448(phase)=%d 0x438(taker set)=%s" % [
		_si(m, 0x19a0), _si(m, 0x1820), _si(m, 0x1824), _g(m, 0x448), str(m.get(0x438, null) != null)])
	print("goal_target_x(orient,xscale,team0)=%d  goal_target_x(...,team1)=%d" % [
		Pm98Movement.goal_target_x(_g(m, 0x19a0), _si(m, 0x1820), 0),
		Pm98Movement.goal_target_x(_g(m, 0x19a0), _si(m, 0x1820), 1)])

	var players0: Array = (teams[0] as Dictionary).get("players", [])
	var s8: Dictionary = players0[8]
	var s9: Dictionary = players0[9]

	var b := _ball(m)
	var t := 0
	while t < 30:
		Pm98Driver.tick(m, rng)
		t += 1
		var phase := _g(m, 0x448)
		print("t=%2d phase=%d | s9 pos=(%d,%d) ep1=(%d,%d) act=0x%x | s8 pos=(%d,%d) ep1=(%d,%d) ep2=(%d,%d) act=0x%x | ball=(%d,%d) vel=(%d,%d)" % [
			t, phase,
			_si(s9, 4), _si(s9, 8), _si(s9, 0x1e0), _si(s9, 0x1e4), _g(s9, 0x40),
			_si(s8, 4), _si(s8, 8), _si(s8, 0x1e0), _si(s8, 0x1e4), _si(s8, 0x1ec), _si(s8, 0x1f0), _g(s8, 0x40),
			_si(b, 4), _si(b, 8), _si(b, 0x20), _si(b, 0x24)])
		if phase == 0 and t > 8:
			break


func _load_player(src: Dictionary, own: Dictionary, opp: Dictionary, m: Dictionary, ball: Dictionary) -> Dictionary:
	var p := {}
	for k in (src["dwords"] as Dictionary):
		p[_hx(k)] = int((src["dwords"] as Dictionary)[k])
	for k in src:
		if k == "dwords" or k == "_va": continue
		p[_hx(k)] = int(src[k])
	p[0x184] = own; p[0x188] = opp; p[0x18c] = m; p[0x190] = ball
	return p


func _load_team_header(team: Dictionary, hdr: Dictionary, players: Array, ti: int, m: Dictionary) -> void:
	team[0x0] = players; team[0x4] = players.size(); team["players"] = players
	team[0x8] = ti; team[0x138] = m; team[0xc] = int(hdr["score_0xc"])
	team[0x168] = int(hdr["active_idx_0x168"])
	var act: Array = hdr["active_table"]
	for slot in range(act.size()):
		team[0x4f + slot] = players[int(act[slot])] if act[slot] is float or act[slot] is int else 0
	var rol: Array = hdr["role_table"]
	for k in range(rol.size()):
		team[0x5b + k] = players[int(rol[k])] if rol[k] is float or rol[k] is int else 0
	var sh: Array = hdr["squad_header"]
	for k in range(sh.size()):
		team[0xbf + k] = int(sh[k])
	team[0x2e0] = int(hdr["0x2e0"]); team[0x2ec] = int(hdr["0x2ec"])
	team[0x2ed] = int(hdr["0x2ed"]); team[0x20c] = int(hdr["0x20c"])


func _ball(m: Dictionary) -> Dictionary:
	var v: Variant = m.get("ball", null)
	return v if v is Dictionary else {}


func _g(d: Variant, k: int) -> int:
	if d is Dictionary: return int((d as Dictionary).get(k, 0))
	return 0


func _si(d: Variant, k: int) -> int:
	return Pm98Trig._i32(_g(d, k))


func _hx(k: Variant) -> int:
	if k is int: return k
	var s := str(k)
	return s.hex_to_int() if s.begins_with("0x") else int(s)


func _load_json(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null: return {}
	var d: Variant = JSON.parse_string(f.get_as_text())
	return d if d is Dictionary else {}
