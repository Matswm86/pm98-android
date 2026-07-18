extends SceneTree
## M5 s45: t0.i9 clk-47 fork (RESOLVED — docs/re/M5_S45_CTRL_MIRROR_DESIGNATION.md).
## Pre-fix the port re-aimed t0.i9 (slope 0.3996, full speed) on the shot tick while
## silicon kept the pre-shot heading with the -458/tick decel: the stale m[0x1650]
## controller mirror froze gs+0x204 on the kickoff taker, so b1420 routed t0.i9 into a
## diverging _move_b0040 bisection the moment the shot cleared ball+0x40. Dumps per tick
## in clk 25-55: every t0.i9 steer_89c0 call, the role-9 leaf inputs (0x17c matrix min,
## 0x1ec anchor, ball pos/vel, 0x13c sub-state, face/speed/curve), the b1420 routing
## fields (gs0+0x204/0x200, m1650/m1664, ball+0x40/0x4c) and t0.i9's b0040 trace.
## Run: ~/godot462 --headless --path app --script res://tests/diag_m5_t0i9_clk47.gd

const REF_DIR := "/home/mats/MWM-AI/data/pm98-m4-oracle/capture2"
const STRUCT_JSON := REF_DIR + "/frame0_struct_import.json"
const FRAME0_SEED := 0xea0d2a8d
const TICK_CAP := 120
const CLK_LO := 25
const CLK_HI := 55


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
	var p: Dictionary = (built[0] as Array)[9]
	var gs0: Dictionary = teams[0]
	var t := 0
	while t < TICK_CAP:
		var in_win := _g(m, 0x450) >= CLK_LO and _g(m, 0x450) <= CLK_HI
		if in_win:
			Pm98Movement.steer_trace.clear()
			Pm98Movement.b0040_trace.clear()
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
		var strc := ""
		for s in Pm98Movement.steer_trace:
			if String(s[0]).begins_with("t0.i9"):
				strc += str(s)
		print("t=%3d clk=%3d pos=(%d,%d) 13c=%d 17c=%x face=%x spd68=%d cur6c=%d ph448=%d steer=%s" % [
			t, clk, _si(p, 4), _si(p, 8), _g(p, 0x13c), _si(p, 0x17c) & 0xffffffff,
			_g(p, 0x34) & 0xffff, _si(p, 0x68), _si(p, 0x6c), _g(m, 0x448), strc])
		print("     anchor1ec=(%d,%d,%d) 164=(%d,%d) 158=(%d,%d) 144=%d 148=%d 84=(%d,%d)" % [
			_si(p, 0x1ec), _si(p, 0x1f0), _si(p, 0x1f4),
			_si(p, 0x164), _si(p, 0x168), _si(p, 0x158), _si(p, 0x15c),
			_si(p, 0x144), _si(p, 0x148), _si(p, 0x84), _si(p, 0x88)])
		print("     ball=(%d,%d,%d) bvel=(%d,%d,%d) bface=%x bact40=%s draws=%s" % [
			_si(ball, 4), _si(ball, 8), _si(ball, 0xc),
			_si(ball, 0x20), _si(ball, 0x24), _si(ball, 0x28), _g(ball, 0x34) & 0xffff,
			"P" if ball.get(0x40, null) is Dictionary else "-",
			str(MatchEngine.Pm98Rng._draws)])
		var d204: Variant = Pm98Movement._desig(gs0, 0x204)
		var d200: Variant = Pm98Movement._desig(gs0, 0x200)
		print("     gs0: 204=%s 200=%s 2ee=%d ball54=%d p5c=%d p48=%d p40=%d p63=%d m1650=%d m1664=%d ctx2e0=%d b40=%s b4c=%s" % [
			_pdesc(d204), _pdesc(d200), _g(gs0, 0x2ee), _g(ball, 0x54),
			_g(p, 0x5c), _si(p, 0x48), _g(p, 0x40), _g(p, 0x63),
			int(m.get(0x1650, -99)), int(m.get(0x1664, -99)), _g(gs0, 0x2e0),
			_pdesc(ball.get(0x40, null)), _pdesc(ball.get(0x4c, null))])
		for b in Pm98Movement.b0040_trace:
			var bd: Dictionary = b
			if String(bd.get("who", "")).begins_with("t0.i9"):
				print("     b0040: lead0=%d lead=%d kiters=%d preclamp=%s target=%s common=%s stat=%s" % [
					int(bd.get("lead0", 0)), int(bd.get("lead_final", 0)), int(bd.get("kiters", 0)),
					str(bd.get("point_preclamp")), str(bd.get("target")),
					str(bd.get("to_common")), str(bd.get("ball_stationary"))])
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


func _pdesc(v: Variant) -> String:
	if v is Dictionary:
		return "t%d.i%d" % [int((v as Dictionary).get(0x2b8, -1)), int((v as Dictionary).get(0x2c8, -1))]
	return str(v)


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
