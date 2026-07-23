extends SceneTree
## M5 s49: drill the t1.i10 fork at clk 644.
##
## m5_skewaware_posdiff.py (which, unlike m5_sparse_posdiff.py, discounts free-run sampling
## skew) puts the first REAL port-vs-silicon divergence at clk 644 on ONE player, t1.i10 --
## not the clk 636 / t1.i9+t1.i10 pair s48 reported, which is skew-explained.
##
## The steering target is NOT the problem: port and silicon agree exactly on 0x17c/0x180
## (213333 / 1409458) through clk 647, while x/y already differ at 644. Silicon's own mover
## tail is what moves at 644 -- 0x64 goes 9258 -> 765 and 0x68 goes 0 -> 786 while 0x34
## counts down -- so the failure is in APPLYING the step, not in choosing it.
##
## This dumps the port's mover tail for t1.i10 over the window, in the same field set that
## m5_freerun_poll.py records on the silicon side, so the two are directly comparable:
##   clk x y 0x13c 0x17c 0x180 0x34&0xffff 0x64&0xffff 0x68 0x6c 0x54 0x58
##
## Run: ~/godot462 --headless --path app --script res://tests/diag_m5_t1i10_mover.gd

const REF_DIR := "/home/mats/MWM-AI/data/pm98-m4-oracle/capture2"
const STRUCT_JSON := REF_DIR + "/frame0_struct_import.json"
const FRAME0_SEED := 0xea0d2a8d
const TICK_CAP := 1400
const CLK_LO := 600
const CLK_HI := 700
const TEAM := 1
const IDX := 10


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
	var p: Dictionary = (built[TEAM] as Array)[IDX]
	var t := 0
	var last := ""
	print("clk x y 0x13c 0x17c 0x180 0x34w 0x64w 0x68 0x6c 0x54 0x58 | draws")
	while t < TICK_CAP:
		var clk_pre := _g(m, 0x450)
		var in_win := clk_pre >= CLK_LO and clk_pre <= CLK_HI
		if in_win:
			MatchEngine.Pm98Rng._log_on = true
			MatchEngine.Pm98Rng._draws.clear()
			Pm98Movement.steerhdg_trace.clear()
		var ret := Pm98Driver.tick(m, rng)
		t += 1
		if ret == 0:
			m[0x1a1e] = 1
		var clk := _g(m, 0x450)
		if not in_win:
			continue
		MatchEngine.Pm98Rng._log_on = false
		var draws: Array = MatchEngine.Pm98Rng._draws.duplicate()
		var row := "%d %d %d %d %d %d %d %d %d %d %d %d raw34=%x raw64=%x" % [
			clk, _si(p, 4), _si(p, 8), _g(p, 0x13c), _si(p, 0x17c), _si(p, 0x180),
			_g(p, 0x34) & 0xffff, _g(p, 0x64) & 0xffff, _si(p, 0x68), _si(p, 0x6c),
			_si(p, 0x54), _si(p, 0x58), _g(p, 0x34) & 0xffffffff, _g(p, 0x64) & 0xffffffff]
		var hdg := "-"
		for e in Pm98Movement.steerhdg_trace:
			var d: Dictionary = e
			if str(d["who"]).strip_edges() == "t%d.i%d" % [TEAM, IDX]:
				hdg = "hdg=%d ad=%d curve=%d p90=%d d=%s" % [
					d["heading"], d["ad"], d["curve"], d["p90"], str(d["dxy"])]
		if row.substr(row.find(" ")) != last:
			print("%s | %d draws | %s" % [row, draws.size(), hdg])
			last = row.substr(row.find(" "))
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
