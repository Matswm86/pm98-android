extends SceneTree
## M5 s40 (diag-only): NAME the sub-step that first writes the kickoff ball velocity.
## s39c proved vel (-4338,12667) at tick 26 is NOT a proximity player kick. This enables the
## gated Pm98Driver ball-velocity change-probe (ballvel_probe) across ticks 20..30 and prints,
## per tick, every tagged sub-phase where ball+0x20/+0x24 changed. The tag that first shows a
## non-zero vel is the writer; from there we chase the X-sign/attack-direction term.
##
##   ~/godot462 --headless --path app --script res://tests/diag_m5_ballvel_writer.gd

const REF_DIR := "/home/mats/MWM-AI/data/pm98-m4-oracle/steertgt_2026-07-15"
const STRUCT_JSON := REF_DIR + "/frame0_struct_import.json"
const FRAME0_SEED := 0xc357aa2c
const TICK_CAP := 120


func _init() -> void:
	_run()
	quit(0)


func _run() -> void:
	var dump := _load_json(STRUCT_JSON)
	if dump.is_empty():
		print("MISSING struct json: ", STRUCT_JSON)
		return
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
	print("PORT ball-vel WRITER probe  (target = who first sets vel != 0 ; silicon dir = 75.3deg +x)")
	var t := 0
	while t < TICK_CAP:
		var probe := (t >= 20 and t <= 90)
		if probe:
			# seed _bv_last with the ball's current vel so the FIRST change this tick is captured
			Pm98Driver._bv_last = [int(ball.get(0x20, 0)), int(ball.get(0x24, 0))]
			Pm98Driver.ballvel_probe.clear()
			Pm98Movement.b0040_trace.clear()
			Pm98Movement.goalaim_trace.clear()
			MatchEngine.Pm98Rng._log_on = true
		var gate := _g(m, 0x1a1e) & 0xff
		var clk_pre := _g(m, 0x450)
		var vel_pre := [_g(ball, 0x20), _g(ball, 0x24)]
		if t == 25:
			var taker: Variant = m.get(0x438, null)
			var owner: Variant = ball.get(0x4c, null)
			var taker_team := int((taker as Dictionary).get(0x2b8, -1)) if taker is Dictionary else -99
			print("  --- match kickoff-side flags @ start of tick 25 ---")
			print("    m[0x45c]=%d  m[0x19c8]=%d  m[0x45c(dup)]=%d  m[0x19a0]=%d  m[0x448]=%d  taker_team(0x438.0x2b8)=%d" % [
				_g(m, 0x45c), _g(m, 0x19c8), _g(m, 0x45c), _g(m, 0x19a0), _g(m, 0x448), taker_team])
			for tm in range(2):
				print("  --- team%d roster @ start of tick 25 (taker=m[0x438], target=ball[0x4c]) ---" % tm)
				for i in range((built[tm] as Array).size()):
					var q: Dictionary = (built[tm] as Array)[i]
					var mark := ""
					if taker is Dictionary and is_same(q, taker): mark += " <TAKER>"
					if owner is Dictionary and is_same(q, owner): mark += " <TARGET(ball0x4c)>"
					print("    t%d.i%-2d pos=(%d,%d) act=0x%x anchor_x=%d 2bc=%d%s" % [
						tm, i, _si(q, 4), _si(q, 8), _g(q, 0x40), _si(q, 0x3a4), _g(q, 0x2bc), mark])
		var ret := Pm98Driver.tick(m, rng)
		if probe and t >= 43 and t <= 48:
			# post-kick: force t1.i9's receiver b0040 target; silicon s37 = (11420,43624)/(12361,47217)
			var p19: Dictionary = (built[1] as Array)[9]
			Pm98Movement.b0040_trace.clear()
			MatchEngine.Pm98Rng._log_on = true
			var ft := Pm98Movement._b0040_target(p19)
			print("      t1.i9 b0040 forced_target=%s  ball_vel=%s" % [str(ft), str([_g(ball, 0x20), _g(ball, 0x24)])])
		if probe:
			MatchEngine.Pm98Rng._log_on = false
			var rows: Array = Pm98Driver.ballvel_probe
			var vel_post := [_g(ball, 0x20), _g(ball, 0x24)]
			print("t=%2d clk=%d gate=%d vel_pre=%s vel_post=%s  changes=%d" % [
				t, clk_pre, gate, str(vel_pre), str(vel_post), rows.size()])
			for r in rows:
				print("      [%-28s] vel=(%d,%d)" % [str(r[0]), int(r[1]), int(r[2])])
			for ga in Pm98Movement.goalaim_trace:
				print("      GOALAIM who=%s p_team=%d tgt_team=%d tgt_pos=%s p_pos=%s p_anchor_x=%d orient=%d goalx=%d redir_5f=%d ball_pos=%s" % [
					str(ga.get("who")), int(ga.get("p_team")), int(ga.get("tgt_team")),
					str(ga.get("tgt_pos")), str(ga.get("p_pos")), int(ga.get("p_anchor_x")),
					int(ga.get("orient")), int(ga.get("goalx")), int(ga.get("redirect_5f")),
					str(ga.get("ball_pos"))])
		t += 1
		if ret == 0:
			m[0x1a1e] = 1
		if _g(m, 0x450) >= 10:
			break


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
