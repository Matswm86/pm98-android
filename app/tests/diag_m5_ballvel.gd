extends SceneTree
## M5 s46 sub-LSB drill: per-RNG-draw ball positions, clk window 270-302 (capture2 seed
## 0xea0d2a8d). Draws are in seed-lockstep with the silicon RSP Z2 stops, so port draw k
## of tick N diffs 1:1 against capture stop k's ball row (m5_rsp_capture.py `ball` field,
## s46 extension). Finds the first tick where the mid-tick ball pos diverges — the t1.i2
## clk-286 face fork (7b3c vs 7b3d) needs silicon ball x ~+87 at the b1500 tail read
## (diag_m5_t1i2_lsb_probe.gd: tx+44 / ty+6 flips the LSB; target x = tdiv(ballx+a3x,2)).
## Output: JSONL lines {"clk":N,"t":tick,"draws":[...]} with b=(x,y,z) appended per draw.
## Run: ~/godot462 --headless --path app --script res://tests/diag_m5_ball_perdraw.gd

const REF_DIR := "/home/mats/MWM-AI/data/pm98-m4-oracle/capture2"
const STRUCT_JSON := REF_DIR + "/frame0_struct_import.json"
const FRAME0_SEED := 0xea0d2a8d
const TICK_CAP := 340
const CLK_LO := 282
const CLK_HI := 292


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
		var in_win := _g(m, 0x450) >= CLK_LO and _g(m, 0x450) <= CLK_HI
		if in_win:
			MatchEngine.Pm98Rng._draws.clear()
			Pm98Driver.ballvel_probe.clear()
			Pm98Driver._bv_last = [_g(ball, 0x20), _g(ball, 0x24)]
			MatchEngine.Pm98Rng._log_on = true
			MatchEngine.Pm98Rng._ball_watch = ball
		var ret := Pm98Driver.tick(m, rng)
		t += 1
		if ret == 0:
			m[0x1a1e] = 1
		var clk := _g(m, 0x450)
		if not in_win:
			continue
		MatchEngine.Pm98Rng._log_on = false
		MatchEngine.Pm98Rng._ball_watch = null
		print(JSON.stringify({"clk": clk, "t": t, "seed": rng.state,
			"ball_end": [_si(ball, 4), _si(ball, 8), _si(ball, 0xc)],
			"bvel_end": [_si(ball, 0x20), _si(ball, 0x24), _si(ball, 0x28)],
			"draws": MatchEngine.Pm98Rng._draws.duplicate(), "bv": Pm98Driver.ballvel_probe.duplicate()}))
		if clk > CLK_HI:
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
