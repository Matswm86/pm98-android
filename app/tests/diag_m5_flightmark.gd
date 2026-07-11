extends SceneTree
## M5 s33: dump ball possession pointers + every player's mark index / role / act through
## the clk 84-122 ball-flight window, to find why NO port player reaches the b1500 press
## arm (the binary draws FUN_005b3c90(0,0x29999) via 0x5b19c7 once per clk 89-114 —
## the marker of the designated receiver ball+0x4c presses; the port never rolls it).
## Run: ~/godot462 --headless --path app --script res://tests/diag_m5_flightmark.gd

const REF_DIR := "/home/mats/MWM-AI/data/pm98-m4-oracle/capture2"
const STRUCT_JSON := REF_DIR + "/frame0_struct_import.json"
const FRAME0_SEED := 0xea0d2a8d
const TICK_CAP := 200
const CLK_LO := 76
const CLK_HI := 122


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
		var ret := Pm98Driver.tick(m, rng)
		t += 1
		if ret == 0:
			m[0x1a1e] = 1
		var clk := _g(m, 0x450)
		if clk < CLK_LO or clk > CLK_HI:
			continue
		var line := "clk=%3d t=%3d seed=%d ball54=%d ctrl=%s recv=%s |" % [
			clk, t, rng.state, _g(ball, 0x54), _pid(ball.get(0x40, null), built),
			_pid(ball.get(0x4c, null), built)]
		for ti in range(2):
			for i in range((built[ti] as Array).size()):
				var p: Dictionary = (built[ti] as Array)[i]
				var mk := int(p.get(0x150, -1))
				if mk != -1:
					line += " t%d.i%d(mk=%d,act=%d,role=%d)" % [ti, i, mk, _g(p, 0x2c8), _g(p, 0x2c4)]
		print(line)


func _pid(v: Variant, built: Array) -> String:
	if not (v is Dictionary):
		return "0"
	for ti in range(2):
		var arr: Array = built[ti]
		for i in range(arr.size()):
			if is_same(arr[i], v):
				return "t%d.i%d" % [ti, i]
	return "?"


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
