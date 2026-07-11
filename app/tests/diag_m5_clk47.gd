extends SceneTree
## M5 s31: clk-47 setup_shot draw-gap localizer. Dumps, at each tick start for clk 44..52,
## the ball ownership block (+0x40/44/48/4c/54), the match possession/controller mirrors
## (+0x1664/+0x438/+0x43c/+0x460), and per-player velocity-block gate inputs (action, pos,
## anchor, cond1/cond2, marked-receiver) -- the ref draws 1/clk (t0.i6 wander) from clk 47
## through 117 (ball+0x4c mark, wide-q recv column) while the port draws 0.
## Run: ~/godot462 --headless --path app --script res://tests/diag_m5_clk47.gd

const REF_DIR := "/home/mats/MWM-AI/data/pm98-m4-oracle/capture2"
const STRUCT_JSON := REF_DIR + "/frame0_struct_import.json"
const FRAME0_SEED := 0xea0d2a8d
const TICK_CAP := 90
const CLK_LO := 0
const CLK_HI := 4


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
	MatchEngine.Pm98Rng._log_on = true
	var scanned := false
	var t := 0
	while t < TICK_CAP:
		if t == 3 and not scanned:
			scanned = true
			_verbose_scan(teams[1] as Dictionary, built)
		var clk_pre := _g(m, 0x450)
		if clk_pre >= CLK_LO and clk_pre <= CLK_HI:
			_dump_state(m, ball, built, clk_pre, t)
		MatchEngine.Pm98Rng._draws.clear()
		var ret := Pm98Driver.tick(m, rng)
		t += 1
		if ret == 0:
			m[0x1a1e] = 1
		var clk := _g(m, 0x450)
		if clk >= CLK_LO and clk <= CLK_HI:
			var draws: Array = MatchEngine.Pm98Rng._draws.duplicate()
			print("TICK t=%d clk=%d ndraws=%d seed=%d sites=%s" % [t, clk, draws.size(), rng.state, str(draws)])
	MatchEngine.Pm98Rng._log_on = false


## Verbose replica of select_mark_target's scan for every t1 player: prints per-candidate
## gate values so the systematically-killing gate is nameable (port assigns NO marks while
## the ref's walking t1 roster implies the binary's 36f0 scan assigns them broadly).
func _verbose_scan(ctx: Dictionary, built: Array) -> void:
	var players: Array = ctx.get("players", [])
	var opp: Array = Pm98Movement._opp_players(ctx)
	var td: Dictionary = ctx.get("team_desc", {})
	print("=== VERBOSE 36f0 SCAN t1 (td=%s) ===" % [str(td)])
	for p_idx in range(players.size()):
		var p: Dictionary = players[p_idx]
		if _g(p, 0x2bc) == 0:
			continue
		var p_metric: int = absi(Pm98Trig._i32(_g(p, 0x4) - _g(p, 0x3a4)))
		var lines: Array = []
		for k in range(opp.size()):
			var cand: Dictionary = opp[k]
			var taken := int(cand.get(0x154, -1)) != -1
			var score: int = _g(p, Pm98Movement._dist_off(_g(cand, 0x2c4), _g(cand, 0x2b8)))
			var raw := score
			var inbox: bool = Pm98Movement._in_box_excl(p, cand)
			if not inbox:
				score = Pm98Trig.mul16(score, 0x13333 if _g(td, 0x310) != 0 else 0x18000)
			var cand_metric: int = absi(Pm98Trig._i32(_g(cand, 0x4) + _g(cand, 0x3a4)))
			if cand_metric <= p_metric:
				score = Pm98Trig.mul16(score, absi(Pm98Trig._i32(_g(cand, 0x4) - _g(p, 0x4))) / 0xf + 0x10000)
			var rbest := Pm98Movement.MATRIX_INIT
			var rnearest := -1
			for r in range(players.size()):
				var rp: Dictionary = players[r]
				if _g(rp, 0x2bc) == 0:
					continue
				var rd: int = _g(cand, Pm98Movement._dist_off(_g(rp, 0x2c4), _g(rp, 0x2b8)))
				if rd < rbest:
					rbest = rd
					rnearest = r
			lines.append("    cand t0.i%d taken=%s raw=%d inbox=%s cm=%d pm=%d score=%d 2bc=%d recip=%d" % [
				k, str(taken), raw, str(inbox), cand_metric, p_metric, score, _g(cand, 0x2bc), rnearest])
		print("  t1.i%d (pos %d,%d box[%d..%d]x[%d..%d]y):" % [p_idx,
			Pm98Trig._i32(_g(p, 4)), Pm98Trig._i32(_g(p, 8)),
			Pm98Trig._i32(_g(p, 0x210)), Pm98Trig._i32(_g(p, 0x21c)),
			Pm98Trig._i32(_g(p, 0x214)), Pm98Trig._i32(_g(p, 0x220))])
		for l in lines:
			print(l)


func _pid(built: Array, v: Variant) -> String:
	if not (v is Dictionary):
		return str(v) if v != null else "null"
	for ti in range(2):
		var arr: Array = built[ti]
		for i in range(arr.size()):
			if is_same(arr[i], v):
				return "t%d.i%d" % [ti, i]
	return "?dict"


func _dump_state(m: Dictionary, ball: Dictionary, built: Array, clk: int, t: int) -> void:
	print("== tick-start t=%d clk=%d  ball40=%s ball44=%s ball48=%s ball4c=%s ball54=%d  m1664=%s m438=%s m43c=%s m460=%s" % [
		t, clk,
		_pid(built, ball.get(0x40, null)), _pid(built, ball.get(0x44, null)),
		_pid(built, ball.get(0x48, null)), _pid(built, ball.get(0x4c, null)),
		_g(ball, 0x54),
		str(m.get(0x1664, null)), _pid(built, m.get(0x438, null)),
		_pid(built, m.get(0x43c, null)), str(m.get(0x460, null))])
	var sess: Dictionary = m.get(0x468, {})
	var sim: Array = m.get("sim", [])
	print("   m44c=%d m448=%d m461=%d m462=%d sess.fa0=%s gs0.2ee=%s gs1.2ee=%s" % [
		_g(m, 0x44c), _g(m, 0x448), _g(m, 0x461), _g(m, 0x462), str(sess.get(0xfa0, null)),
		str((sim[0] as Dictionary).get(0x2ee, null)), str((sim[1] as Dictionary).get(0x2ee, null))])
	for ti in range(2):
		var arr: Array = built[ti]
		for i in range(arr.size()):
			var p: Dictionary = arr[i]
			var px := Pm98Trig._i32(_g(p, 4))
			var py := Pm98Trig._i32(_g(p, 8))
			var anchor := Pm98Trig._i32(_g(p, 0x3a4))
			var cond1 := absi(Pm98Trig._i32(anchor + px)) > 0x13ffff or absi(py) > 0xbffff
			var cond2 := absi(Pm98Trig._i32(px - anchor)) > 0x13ffff or absi(py) > 0xbffff
			var marked := is_same(ball.get(0x4c, null), p)
			var active := is_same(ball.get(0x40, null), p)
			print("  t%d.i%-2d act=%-4d pos=(%d,%d) anc=%d 5c=%d 14c=%d c1=%s c2=%s mk=%s actv=%s 2bc=%d 63=%d 80=%d 84=%d" % [
				ti, i, _g(p, 0x40), px, py, anchor, _g(p, 0x5c), _g(p, 0x14c),
				str(cond1), str(cond2), str(marked), str(active),
				_g(p, 0x2bc), _g(p, 0x63), _g(p, 0x80), _g(p, 0x84)])
			if ti == 1 and (i == 1 or i == 3):
				print("    i%d+ role=%d 150=%s 154=%s 13c=%d anc1e0=(%d,%d,%d) anc1ec=(%d,%d) slots1f8=(%d,%d,%d) 2cc=%d" % [
					i, _g(p, 0x2c8), str(p.get(0x150, null)), str(p.get(0x154, null)),
					_g(p, 0x13c),
					Pm98Trig._i32(_g(p, 0x1e0)), Pm98Trig._i32(_g(p, 0x1e4)), Pm98Trig._i32(_g(p, 0x1e8)),
					Pm98Trig._i32(_g(p, 0x1ec)), Pm98Trig._i32(_g(p, 0x1f0)),
					Pm98Trig._i32(_g(p, 0x1f8)), Pm98Trig._i32(_g(p, 0x1fc)), Pm98Trig._i32(_g(p, 0x200)),
					Pm98Trig._i32(_g(p, 0x2cc))])


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


func _hx(k) -> int:
	return (k as String).hex_to_int()


func _load_json(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	return parsed if parsed is Dictionary else {}
