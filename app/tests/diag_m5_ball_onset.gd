extends SceneTree
## M5 s39 (diag-only): dump the port BALL state (pos/vel/face) at the START of each tick and
## FORCE-run _b0040_target(t1.i9) at that same pre-tick state, ticks 20..30. Goal: settle whether
## silicon's unarmed-step target (11420,43624) implies the port kicks the kickoff ball LATE.
##
## Reasoning this checks (from source, no live drive): _b0040_target SKIPS its interception loop
## when the ball is stationary (bvx==bvy==bvz==0), so a stationary ball -> target == ball.pos. Silicon
## returns (11420,43624) at the UNARMED step (s37), which is NOT the kickoff-centre ball.pos -> silicon's
## ball is already MOVING there. If the port's ball is still stationary at the same tick, the port kicks
## the kickoff ball too late, and THAT (not _b0040_target) is the t1.i9 arm-step root.
##
##   ~/godot462 --headless --path app --script res://tests/diag_m5_ball_onset.gd

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
	var p: Dictionary = (built[1] as Array)[9]
	print("PORT ball-onset + forced t1.i9 _b0040_target trace  (silicon unarmed target = 11420,43624 ; arm = 12361,47217)")
	var t := 0
	while t < TICK_CAP:
		var clk := _g(m, 0x450)
		if t >= 20 and t <= 30:
			# pre-tick ball state = exactly what a receiver reads during this tick's player-advance
			var bpos := [_g(ball, 4), _g(ball, 8), _g(ball, 0xc)]
			var bvel := [_g(ball, 0x20), _g(ball, 0x24), _g(ball, 0x28)]
			var bface := _g(ball, 0x34) & 0xffff
			var stationary: bool = (int(bvel[0]) == 0 and int(bvel[1]) == 0 and int(bvel[2]) == 0)
			# force _b0040_target for t1.i9 at this pre-tick state
			Pm98Movement.b0040_trace.clear()
			MatchEngine.Pm98Rng._log_on = true
			MatchEngine.Pm98Rng._who = "t1.i9(forced)"
			var forced := Pm98Movement._b0040_target(p)
			MatchEngine.Pm98Rng._log_on = false
			var row: Dictionary = Pm98Movement.b0040_trace[0] if Pm98Movement.b0040_trace.size() > 0 else {}
			print("t=%2d clk=%3d act=%d spd=%5d  ball_pos=%s vel=%s face=0x%04x stationary=%s  forced_target=%s  loop_ran=%s" % [
				t, clk, _g(p, 0x40), _si(p, 0x68),
				str(bpos), str(bvel), bface, str(stationary), str(forced),
				str(row.get("to_common", null) == true and not bool(row.get("ball_stationary", true)))])
		Pm98Movement.b0040_trace.clear()
		MatchEngine.Pm98Rng._log_on = false
		var ret := Pm98Driver.tick(m, rng)
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
