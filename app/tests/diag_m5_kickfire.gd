extends SceneTree
## M5 kickoff KICK-FIRE localizer (diag-only). Byte-loads the SAME team-1 kicktiming frame-0
## (steertgt_2026-07-15, seed 0xc357aa2c) the silicon armwatch used, drives Pm98Driver.tick with
## the Pm98Rng call-site log ON, and prints PER TICK the taker t1.i10 windup state
## (act 0x40 / frm 0x2c / sub 0x30 / wind 0x48) + ndraws + the taker's OWN tagged draws.
## GOAL: name the exact tick + draw where move_dispatch's r2 roll fires kick_setup, and compare
## the port's windup schedule (should be 180->156 over ~24 ticks, kick at ~etick 27) to silicon.
##   ~/godot462 --headless --path app --script res://tests/diag_m5_kickfire.gd
const REF_DIR := "/home/mats/MWM-AI/data/pm98-m4-oracle/steertgt_2026-07-15"
const STRUCT_JSON := REF_DIR + "/frame0_struct_import.json"
const FRAME0_SEED := 0xc357aa2c
const TICK_CAP := 60


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

	var taker: Dictionary = (built[1] as Array)[10]   # t1.i10

	var rng := MatchEngine.Pm98Rng.new(0)
	rng.state = FRAME0_SEED
	MatchEngine.Pm98Rng._log_on = true
	print("PORT kick-fire probe. frame0 seed=0x%08x (silicon: wind 180->156 over etick 2-26, KICK act=4 at etick 27)" % rng.state)
	print("%-4s %-3s | %-4s %-4s %-3s %-5s | %-6s | %s" % ["t", "clk", "act", "frm", "sub", "wind", "ndraw", "taker-draws (who:file:line)"])
	var t := 0
	var kicked := false
	while t < TICK_CAP:
		MatchEngine.Pm98Rng._draws.clear()
		var vel_pre := [_g(ball, 0x20), _g(ball, 0x24)]
		var ret := Pm98Driver.tick(m, rng)
		var draws: Array = MatchEngine.Pm98Rng._draws.duplicate()
		# taker's OWN draws this tick (tagged with "t1.i10 ")
		var tk_draws := []
		for tag in draws:
			if (tag as String).begins_with("t1.i10 "):
				tk_draws.append((tag as String).substr(7))
		var vel_post := [_g(ball, 0x20), _g(ball, 0x24)]
		var flag := ""
		if not kicked and (vel_post[0] != 0 or vel_post[1] != 0):
			kicked = true
			flag = "  <<< KICK (ball vel=%s)" % str(vel_post)
		print("%-4d %-3d | %-4d %-4d %-3d %-5d | %-6d | %s%s" % [
			t, _g(m, 0x450), _g(taker, 0x40), _g(taker, 0x2c), _g(taker, 0x30), _si(taker, 0x48),
			draws.size(), str(tk_draws), flag])
		t += 1
		if ret == 0:
			m[0x1a1e] = 1
		if kicked and _g(m, 0x450) >= 3:
			break
	MatchEngine.Pm98Rng._log_on = false


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
