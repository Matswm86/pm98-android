extends SceneTree
## M5 s39b (diag-only): identify the KICKOFF TAKER (ball controller ball+0x40) and dump its
## facing/pos/action/target per tick 20-30, plus the attack-side fields, to find WHY the port
## kicks the kickoff ball toward 108.9deg (-x) instead of silicon's 75.3deg (+x).
##   ~/godot462 --headless --path app --script res://tests/diag_m5_kickoff_taker.gd

const REF_DIR := "/home/mats/MWM-AI/data/pm98-m4-oracle/steertgt_2026-07-15"
const STRUCT_JSON := REF_DIR + "/frame0_struct_import.json"
const FRAME0_SEED := 0xc357aa2c
const TICK_CAP := 120


func _init() -> void:
	_run()
	quit(0)


func _run() -> void:
	var dump := _load_json(STRUCT_JSON)
	var throwaway := MatchEngine.Pm98Rng.new(1)
	var m := Pm98Match.build_match(throwaway)
	Pm98CollBuilder.populate_posts(m)
	for k in (dump["match"] as Dictionary):
		m[_hx(k)] = int((dump["match"] as Dictionary)[k])
	var session := {}
	for k in (dump["session"] as Dictionary):
		if k == "_va":
			continue
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
	print("PORT kickoff-taker trace   side(0x19c8)=%d  0x45c=%d  attack? goal_x(0x1820)=%d" % [
		_g(m, 0x19c8), _g(m, 0x45c), _si(m, 0x1820)])
	# receiver t1.i9 lives at pos ~ (26214, 98304) = +x,+y (75deg). silicon kick target 75.3deg.
	var taker: Dictionary = (built[0] as Array)[9]           # t0.i9 = the controller at tick 20-25
	var t := 0
	while t < TICK_CAP:
		if t >= 20 and t <= 30:
			var isctrl := is_same(ball.get(0x40, null), taker)
			print("t=%2d clk=%3d  ball_pos=%s vel=%s face=0x%04x  t0.i9: facing=0x%04x(%5.1fdeg) pos=%s act=%d aim0x94=%s ctrl?=%s" % [
				t, _g(m, 0x450), str([_si(ball, 4), _si(ball, 8)]),
				str([_si(ball, 0x20), _si(ball, 0x24)]), _g(ball, 0x34) & 0xffff,
				_g(taker, 0x34) & 0xffff, _deg(_g(taker, 0x34) & 0xffff),
				str([_si(taker, 4), _si(taker, 8)]), _g(taker, 0x40),
				str([_si(taker, 0x94), _si(taker, 0x98)]), str(isctrl)])
		var ret := Pm98Driver.tick(m, rng)
		t += 1
		if ret == 0:
			m[0x1a1e] = 1
		if _g(m, 0x450) >= 10:
			break


func _find_player(built: Array, target) -> String:
	for ti in range(2):
		for i in range((built[ti] as Array).size()):
			if is_same((built[ti] as Array)[i], target):
				return "t%d.i%d" % [ti, i]
	return "?"


func _deg(a16: int) -> float:
	return float(a16) / 65536.0 * 360.0


func _load_player(src: Dictionary, own: Dictionary, opp: Dictionary,
		m: Dictionary, ball: Dictionary) -> Dictionary:
	var p := {}
	for k in (src["dwords"] as Dictionary):
		p[_hx(k)] = int((src["dwords"] as Dictionary)[k])
	for k in src:
		if k == "dwords" or k == "_va":
			continue
		p[_hx(k)] = int(src[k])
	p[0x184] = own
	p[0x188] = opp
	p[0x18c] = m
	p[0x190] = ball
	return p


func _load_team_header(team: Dictionary, hdr: Dictionary, players: Array, ti: int, m: Dictionary) -> void:
	team[0x0] = players
	team[0x4] = players.size()
	team["players"] = players
	team[0x8] = ti
	team[0x138] = m
	team[0xc] = int(hdr["score_0xc"])
	team[0x168] = int(hdr["active_idx_0x168"])
	var act: Array = hdr["active_table"]
	for slot in range(act.size()):
		var actp = players[int(act[slot])] if act[slot] is float or act[slot] is int else 0
		team[0x4f + slot] = actp
		team[0x13c + slot * 4] = actp
	var rol: Array = hdr["role_table"]
	for k in range(rol.size()):
		team[0x5b + k] = players[int(rol[k])] if rol[k] is float or rol[k] is int else 0
	var sh: Array = hdr["squad_header"]
	for k in range(sh.size()):
		team[0xbf + k] = int(sh[k])
		team[0x2fc + k * 4] = int(sh[k])
	team[0x2e0] = int(hdr["0x2e0"])
	team[0x2ec] = int(hdr["0x2ec"])
	team[0x2ed] = int(hdr["0x2ed"])
	team[0x20c] = int(hdr["0x20c"])


func _g(d: Dictionary, off: int) -> int:
	return int(d.get(off, 0))


func _si(d: Dictionary, off: int) -> int:
	return Pm98Trig._i32(int(d.get(off, 0)))


func _hx(k) -> int:
	return (k as String).hex_to_int()


func _load_json(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	return parsed if parsed is Dictionary else {}
