extends SceneTree
## M5 s36: dump t1.i9 in the EXACT silicon armwatch field layout (x,y,act,frame,sub,
## 0x48,0x54,0x58,0x80,0x84,face0x34,yaw0x64,speed0x68,curve0x6c) per tick 20-30, to
## diff every field against armwatch2 clk 0-3 and localize the constant 0x130 first-step
## facing offset. Run: ~/godot462 --headless --path app --script res://tests/diag_m5_t1i9.gd

const REF_DIR := "/home/mats/MWM-AI/data/pm98-m4-oracle/capture2"
const STRUCT_JSON := REF_DIR + "/frame0_struct_import.json"
const FRAME0_SEED := 0xea0d2a8d
const TICK_CAP := 60


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
	print("PORT t1.i9  (fields as silicon armwatch): x y act frm sub 0x48 0x54 0x58 0x80 0x84 face yaw speed curve")
	var t := 0
	while t < TICK_CAP:
		Pm98Movement.steer_trace.clear()
		MatchEngine.Pm98Rng._log_on = true
		var ret := Pm98Driver.tick(m, rng)
		MatchEngine.Pm98Rng._log_on = false
		t += 1
		if ret == 0:
			m[0x1a1e] = 1
		var clk := _g(m, 0x450)
		if t >= 20 and t <= 30:
			var strc := ""
			for s in Pm98Movement.steer_trace:
				if String(s[0]).begins_with("t1.i9"):
					strc += str(s)
			print("t=%2d clk=%3d  %d %d %d %d %d %d %d %d %d %d %x %x %d %d  steer=%s" % [
				t, clk, _si(p, 4), _si(p, 8), _g(p, 0x40), _g(p, 0x2c), _g(p, 0x30),
				_si(p, 0x48), _si(p, 0x54), _si(p, 0x58), _g(p, 0x80), _si(p, 0x84),
				_g(p, 0x34) & 0xffff, _g(p, 0x64) & 0xffff, _si(p, 0x68), _si(p, 0x6c), strc])
			var ctrl: Dictionary = p.get(0x190, {})
			print("     tgtfields 0x158=(%d,%d,%d) 0x164=(%d,%d,%d) 0x170=(%d,%d,%d) 0x1ec=(%d,%d,%d) 0x2b0=%d 0x3a4=%d" % [
				_si(p, 0x158), _si(p, 0x15c), _si(p, 0x160), _si(p, 0x164), _si(p, 0x168), _si(p, 0x16c),
				_si(p, 0x170), _si(p, 0x174), _si(p, 0x178), _si(p, 0x1ec), _si(p, 0x1f0), _si(p, 0x1f4),
				_si(p, 0x2b0), _si(p, 0x3a4)])
			print("     ball=(%d,%d) goalx=%d/%d 0x3a8=%d 0x3ac=%d act0x40=%d role0x5b8=%d 0x2b8=%d" % [
				_si(ctrl, 4), _si(ctrl, 8), _si(m, 0x1970), _si(m, 0x1978),
				_si(p, 0x3a8), _si(p, 0x3ac), _g(p, 0x40), _si(p, 0x5b8), _si(p, 0x2b8)])
		if clk >= 6:
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
