extends SceneTree
## M5 s35: trace the kickoff-arm state for the residual drift players (t0.i9 taker,
## t1.i9, t0.i8) over every engine tick (phase-2 ticks included) through clk 30.
## Dumps per tick: phase, ball controller, and per player pos/vel/act/counters
## (+0x48 windup, +0x54/+0x58 wander, +0x5c active, +0x63 chase, +0x13c sub-state,
## +0x34 facing) to localize why the port arms the post-kick walk at tick 13 while
## silicon holds to tick 20 (handoff-pm98-m5-dart209-posdrift-2026-07-12 NEXT-1).
##
## Run: ~/godot462 --headless --path app --script res://tests/diag_m5_takerarm.gd

const REF_DIR := "/home/mats/MWM-AI/data/pm98-m4-oracle/capture2"
const STRUCT_JSON := REF_DIR + "/frame0_struct_import.json"
const FRAME0_SEED := 0xea0d2a8d
const TICK_CAP := 60
const WATCH := [[0, 9], [1, 9], [0, 8]]


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
	var t := 0
	while t < TICK_CAP:
		MatchEngine.Pm98Rng._log_on = true
		Pm98Movement.steer_trace.clear()
		var ret := Pm98Driver.tick(m, rng)
		MatchEngine.Pm98Rng._log_on = false
		var steers: Array = []
		for s in Pm98Movement.steer_trace:
			if String(s[0]).begins_with("t0.i9") or String(s[0]).begins_with("t1.i9"):
				steers.append(s)
		t += 1
		if ret == 0:
			m[0x1a1e] = 1
		var clk := _g(m, 0x450)
		var ctrl_v: Variant = ball.get(0x40, null)
		var cdesc := "-"
		if ctrl_v is Dictionary:
			var cd: Dictionary = ctrl_v
			cdesc = "t%d.i%d" % [_g(cd, 0x2b8), _g(cd, 0x2c4)]
		print("tick=%2d clk=%3d phase=%d ctrl=%s b4c=%s steers=%s" % [
			t, clk, _g(m, 0x448), cdesc, str(ball.get(0x4c, 0) is Dictionary), str(steers)])
		for w in WATCH:
			var p: Dictionary = (built[int(w[0])] as Array)[int(w[1])]
			print("   t%d.i%d pos=(%d,%d) vel=(%d,%d) act=%d 48=%d 54=%d 58=%d 5c=%d 63=%d 13c=%d 34=%x 2c=%d 30=%d 80=%d 84=%d" % [
				int(w[0]), int(w[1]), _si(p, 4), _si(p, 8), _si(p, 0x20), _si(p, 0x24),
				_g(p, 0x40), _si(p, 0x48), _si(p, 0x54), _si(p, 0x58),
				_g(p, 0x5c), _g(p, 0x63), _g(p, 0x13c), _g(p, 0x34) & 0xffff,
				_g(p, 0x2c), _g(p, 0x30), _g(p, 0x80), _si(p, 0x84)])
		if clk >= 30:
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
