extends SceneTree
## M5 s34: localize the clk-209 dart-init timing skew. Silicon (seedwatch_clk220.jsonl)
## fires the FUN_005b2f30 dart-init pair (0x5b2f67 duration + 0x5b2fae polar) at clk 209
## via 0x5b4118 (= _role_leaf_3e50, roles 9/12/14); the port fires the same pair at
## clk 217. Draw indices align for every clk 0-208 and re-align from 217 (ladder), so a
## no-draw-cost state divergence delays the dart gate ~8 clks. This dumps, per clk in
## [CLK_LO, CLK_HI]: the tick's draw tags + the FULL roster as
## `PL team idx x y sub13c 17c 180 id` rows, for diffing against the silicon
## m5_gdbrsp_dartwatch.py capture (dartwatch_full218.jsonl). Findings:
## docs/re/M5_DART209_POSDRIFT.md.
##
## Run: ~/godot462 --headless --path app --script res://tests/diag_m5_dart209.gd

const REF_DIR := "/home/mats/MWM-AI/data/pm98-m4-oracle/capture2"
const STRUCT_JSON := REF_DIR + "/frame0_struct_import.json"
## s55: PM98_SEED overrides the frame-0 LCG seed so the port can mirror a cross-seed silicon
## capture (m5_rsp_capture.py honours the same variable). Everything else stays the reference
## frame-0 state, so only the RNG stream differs.
const FRAME0_SEED := 0xea0d2a8d
## s54: window + cap are env-overridable (PM98_TICK_CAP / PM98_CLK_LO / PM98_CLK_HI) so the same
## dump feeds the parity differs over any range without editing the s34 defaults.
var TICK_CAP := int(OS.get_environment("PM98_TICK_CAP")) if OS.get_environment("PM98_TICK_CAP") != "" else 700
var CLK_LO := int(OS.get_environment("PM98_CLK_LO")) if OS.get_environment("PM98_CLK_LO") != "" else 0
var CLK_HI := int(OS.get_environment("PM98_CLK_HI")) if OS.get_environment("PM98_CLK_HI") != "" else 306


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
		var ret := Pm98Driver.tick(m, rng)
		t += 1
		if ret == 0:
			m[0x1a1e] = 1
		var clk := _g(m, 0x450)
		if not in_win:
			continue
		MatchEngine.Pm98Rng._log_on = false
		var draws: Array = MatchEngine.Pm98Rng._draws.duplicate()
		var ctrl_v: Variant = ball.get(0x40, null)
		var cdesc := "-"
		if ctrl_v is Dictionary:
			var cd: Dictionary = ctrl_v
			cdesc = "t%d.id%d" % [_g(cd, 0x2b8), _g(cd, 0x2c8)]
		# s57: `rng=` is the LCG state at the END of this tick. The Z2 capture records the
		# same word at every RSP stop, so the once-per-tick anchor stop (ret0 0x5910fd, the
		# FUN_005910c0 replay-record read that runs after the +0x450 bump and before the
		# movement core) carries the state at the START of silicon tick clk+1 -- i.e. the
		# same instant as this line. m5_anchor_posdiff.py diffs the two directly.
		print("clk=%3d tick=%3d ball=(%d,%d) ctrl=%s rng=%d draws=%s" % [
			clk, t, Pm98Trig._i32(_g(ball, 4)), Pm98Trig._i32(_g(ball, 8)), cdesc,
			rng.state, str(draws)])
		# s56: the BALL row carries what m5_rsp_capture.py's ball_row() carries in the same
		# order (x y z vx vy vz face34 own54 +0x58 N5c), so the widened differ can check the
		# ball's velocity and facing, not just its x/y.
		print("   BALL %d %d %d %d %d %d %d %d %d %d" % [
			_si(ball, 4), _si(ball, 8), _si(ball, 0xc),
			_si(ball, 0x20), _si(ball, 0x24), _si(ball, 0x28),
			_g(ball, 0x34) & 0xffff, _si(ball, 0x54), _si(ball, 0x58), _si(ball, 0x5c)])
		# s57: the rest of m5_rsp_capture.py's ball_row() -- the FUN_0058fda0 predicted-
		# trajectory buffer ball+0x114..0x1d4 (16 vec3, stride 12 = 48 i32) then the three
		# bounce-segment lengths ball+0x74/0x78/0x7c. s56 named these as "in the capture but
		# not in the port dump"; without them the ball parity claim covered 10 of 63 words.
		var traj: Array = []
		for k in range(48):
			traj.append(_si(ball, 0x114 + 4 * k))
		for off in [0x74, 0x78, 0x7c]:
			traj.append(_si(ball, off))
		print("   BTRAJ %s" % " ".join(traj.map(func(v): return str(v))))
		for ti in range(2):
			var arr: Array = built[ti]
			for i in range(arr.size()):
				var p: Dictionary = arr[i]
				# The first eight columns are the s34 layout every existing differ parses
				# positionally; s56 APPENDS the rest of m5_rsp_capture.py's players_row so
				# the widened differ can check orientation, speed and the gate inputs too.
				print("   PL %d %d %d %d %d %x %x %d %d %d %d %d %d %d %d %d %d %d %d" % [
					ti, i, _si(p, 4), _si(p, 8), _g(p, 0x13c),
					_si(p, 0x17c) & 0xffffffff, _si(p, 0x180) & 0xffffffff, _g(p, 0x2c8),
					_g(p, 0x34) & 0xffff, _g(p, 0x64) & 0xffff,
					_si(p, 0x68), _si(p, 0x6c), _si(p, 0x54), _si(p, 0x58),
					_g(p, 0x5c) & 0xff, _si(p, 0x2b8), _si(p, 0x2bc),
					_g(p, 0x2d7) & 0xff, _g(p, 0x2d8) & 0xff])
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
