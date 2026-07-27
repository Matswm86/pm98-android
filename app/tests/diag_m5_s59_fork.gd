extends SceneTree
## M5 s59 (diag-only): name the leaf behind the clk-1422 ball-flight fork.
## The s59 capture shows silicon flying the 1421 kick BALLISTIC (vx,vy const, vz -178/tick,
## grounds at 1426 per its 5-tick first segment) while the port re-accelerates the ball each
## tick (~ -334,+60,+30). The captured words matched through 1421, so the router state is
## UNCAPTURED ball internals (timers +0x68/+0x6c, target +0x9c..a4, held +0x63). This dumps,
## per clk in [PM98_CLK_LO, PM98_CLK_HI]: the ball row, those internals, the carrier's motion
## state, the ballvel_probe phase tags and the tick's tagged draws.
##
## Run: PM98_CLK_LO=1410 PM98_CLK_HI=1432 PM98_TICK_CAP=1520 \
##   ~/godot462 --headless --path app --script res://tests/diag_m5_s59_fork.gd
const REF_DIR := "/home/mats/MWM-AI/data/pm98-m4-oracle/capture2"
const STRUCT_JSON := REF_DIR + "/frame0_struct_import.json"
const FRAME0_SEED := 0xea0d2a8d
var TICK_CAP := int(OS.get_environment("PM98_TICK_CAP")) if OS.get_environment("PM98_TICK_CAP") != "" else 1520
var CLK_LO := int(OS.get_environment("PM98_CLK_LO")) if OS.get_environment("PM98_CLK_LO") != "" else 1410
var CLK_HI := int(OS.get_environment("PM98_CLK_HI")) if OS.get_environment("PM98_CLK_HI") != "" else 1432
var _last_score := [0, 0]


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
	var seed_env := OS.get_environment("PM98_SEED")
	rng.state = (seed_env.hex_to_int() if seed_env.begins_with("0x") else int(seed_env)) \
		if seed_env != "" else FRAME0_SEED
	var t := 0
	while t < TICK_CAP:
		var in_win := _g(m, 0x450) >= CLK_LO and _g(m, 0x450) <= CLK_HI
		if in_win:
			MatchEngine.Pm98Rng._log_on = true
			MatchEngine.Pm98Rng._draws.clear()
			Pm98Driver.ballvel_probe.clear()
			Pm98Driver._bv_last = [int(ball.get(0x20, 0)), int(ball.get(0x24, 0))]
		var ret := Pm98Driver.tick(m, rng)
		t += 1
		if ret == 0:
			m[0x1a1e] = 1
		var clk := _g(m, 0x450)
		# GOAL lines print on any score change, independent of the log window, so a
		# full-match run can grep goals without per-tick output (s59 kill-test aid).
		var sc := [_g(m, 0x478), _g(m, 0x798)]
		if sc != _last_score:
			_last_score = sc
			print("GOAL clk=%d bank=%d tick=%d score=%d-%d min=%d" % [clk, _g(m, 0x19a8), t,
				int(sc[0]), int(sc[1]),
				((_g(m, 0x19a8) + clk) * 0x2d) / max(1, _g(m, 0x19ac))])
		if _g(m, 0x1a38) == 10:
			print("FULLTIME clk=%d bank=%d tick=%d score=%d-%d" % [clk, _g(m, 0x19a8), t,
				int(sc[0]), int(sc[1])])
			break
		if not in_win:
			continue
		MatchEngine.Pm98Rng._log_on = false
		var carrier_v: Variant = ball.get(0x40, null)
		var cdesc := "-"
		if carrier_v is Dictionary:
			var cd: Dictionary = carrier_v
			cdesc = "t%d.id%d spd68=%d curve6c=%d pos=(%d,%d) act=0x%x" % [
				_g(cd, 0x2b8), _g(cd, 0x2c8), _si(cd, 0x68), _si(cd, 0x6c),
				_si(cd, 4), _si(cd, 8), _g(cd, 0x40)]
		var recv_v: Variant = ball.get(0x4c, null)
		var rdesc := "-"
		if recv_v is Dictionary:
			rdesc = "t%d.id%d" % [_g(recv_v as Dictionary, 0x2b8), _g(recv_v as Dictionary, 0x2c8)]
		print("clk=%4d tick=%4d pos=(%d,%d,%d) vel=(%d,%d,%d) face=%d" % [
			clk, t, _si(ball, 4), _si(ball, 8), _si(ball, 0xc),
			_si(ball, 0x20), _si(ball, 0x24), _si(ball, 0x28), _g(ball, 0x34) & 0xffff])
		print("   INT t54=%d t58=%d t5c=%d held63=%d t68=%d t6c=%d t70=%d tgt=(%d,%d,%d) seg=(%d,%d,%d)" % [
			_si(ball, 0x54), _si(ball, 0x58), _si(ball, 0x5c), _g(ball, 0x63) & 0xff,
			_si(ball, 0x68), _si(ball, 0x6c), _si(ball, 0x70),
			_si(ball, 0x9c), _si(ball, 0xa0), _si(ball, 0xa4),
			_si(ball, 0x74), _si(ball, 0x78), _si(ball, 0x7c)])
		print("   CARRIER %s  RECV %s" % [cdesc, rdesc])
		var taker_v: Variant = m.get(0x438, null)
		var tkdesc := "-"
		if taker_v is Dictionary:
			tkdesc = "t%d.id%d act=0x%x p48=%d" % [_g(taker_v as Dictionary, 0x2b8),
				_g(taker_v as Dictionary, 0x2c8), _g(taker_v as Dictionary, 0x40),
				_si(taker_v as Dictionary, 0x48)]
		print("   MATCH score=%d-%d bank19a8=%d ph448=%d disp1a38=%d m19a0=%d m460=%d m45c=%d m44c=%d gate1a1e=%d cool454=%d m461=0x%x m160c=%d taker=%s" % [
			_g(m, 0x478), _g(m, 0x798), _g(m, 0x19a8),
			_g(m, 0x448), _g(m, 0x1a38), _g(m, 0x19a0), _g(m, 0x460), _g(m, 0x45c),
			_g(m, 0x44c), _g(m, 0x1a1e) & 0xff, _g(m, 0x454), _g(m, 0x461), _g(m, 0x160c) & 0xff, tkdesc])
		for r in Pm98Driver.ballvel_probe:
			print("   BV %s -> (%d,%d)" % [r[0], int(r[1]), int(r[2])])
		print("   DRAWS %s" % str(MatchEngine.Pm98Rng._draws))
		if clk >= CLK_HI:
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
