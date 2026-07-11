extends SceneTree
## M5 clk-9 disambiguation (s29): PORT marker table at clk 0..12 vs the wide reference
## capture (m5cap/clk9_timeline.jsonl, tools/re/wine s29 run).
##
## Reference facts (observable ticks clk 0..3 and 10, seed 0xea0d2a8d):
##   Bolton slot-8 marks the Villa RECEIVER t0.i8 (from clk 1; t0.i9 the taker at clk 0)
##   Bolton slot-9 marks t0.i10 -- NOT the receiver
##   ball+0x4c = receiver through clk 0..3; at clk 10 ctrl=t0.i8, +0x4c cleared.
## This prints the SAME table from the port engine per clk 0..12, so the two candidates
## split: identical marker tables => candidate 1 (engage timing); port slot-9 (or any
## other unit than slot-8) marking the receiver => candidate 2 (wrong marked man).
## Run: ~/godot462 --headless --path app --script res://tests/diag_m5_markers.gd

const REF_DIR := "/home/mats/MWM-AI/data/pm98-m4-oracle/capture2"
const STRUCT_JSON := REF_DIR + "/frame0_struct_import.json"
const FRAME0_SEED := 0xea0d2a8d
const TICK_CAP := 60
const CLK_HI := 12


func _init() -> void:
	_run()
	quit(0)


func _run() -> void:
	var dump := _load_json(STRUCT_JSON)
	if dump.is_empty():
		push_error("could not load %s" % STRUCT_JSON)
		return
	var throwaway := MatchEngine.Pm98Rng.new(1)
	var m := Pm98Match.build_match(throwaway)
	Pm98CollBuilder.populate_posts(m)
	for k in (dump["match"] as Dictionary):
		m[_hx(k)] = int((dump["match"] as Dictionary)[k])
	var session := {}
	for k in (dump["session"] as Dictionary):
		if k == "_va":
			continue
		session[_hx(k)] = int(dump["session"][k])
	m[0x468] = session
	var ball: Dictionary = m["ball"]
	var teams: Array = m["sim"]
	var built := [[], []]
	for ti in range(2):
		var own: Dictionary = teams[ti]
		var opp: Dictionary = teams[1 - ti]
		for src in ((dump["players"] as Array)[ti] as Array):
			var p := _load_player(src as Dictionary, own, opp, m, ball)
			(built[ti] as Array).append(p)
	for ti in range(2):
		_load_team_header(teams[ti] as Dictionary, (dump["team_headers"] as Array)[ti] as Dictionary,
			built[ti] as Array, ti, m)

	var rng := MatchEngine.Pm98Rng.new(0)
	rng.state = FRAME0_SEED

	var players := [
		(teams[0] as Dictionary).get("players", []),
		(teams[1] as Dictionary).get("players", []),
	]
	var b := ball

	var t := 0
	var last_clk := -1
	while t < TICK_CAP:
		var ret := Pm98Driver.tick(m, rng)
		t += 1
		if ret == 0:
			m[0x1a1e] = 1
		var clk := _g(m, 0x450)
		if clk == last_clk:
			continue
		last_clk = clk
		if clk > CLK_HI:
			break
		print("== clk=%2d ph=%d rng=%d ctrl=%s recv=%s" % [
			clk, _g(m, 0x448), rng.state,
			_who(b.get(0x40, null), players), _who(b.get(0x4c, null), players)])
		for ti in range(2):
			var arr: Array = players[ti]
			for pi in range(arr.size()):
				var p: Dictionary = arr[pi]
				# port marker link +0x150 is an OPPONENT INDEX (-1 = none); a raw
				# Dictionary is tolerated for older builds.
				var mk = p.get(0x150, -1)
				var mk_s := ""
				if mk is Dictionary:
					mk_s = _who(mk, players)
				elif int(mk) >= 0:
					mk_s = "%s.i%d" % ["t0" if ti == 1 else "t1", int(mk)]
				if mk_s == "":
					continue      # only print assigned markers (reference table is sparse)
				print("   %s.i%d slot=%d id2c8=%d act=0x%x mk=%s" % [
					"t0" if ti == 0 else "t1", pi, _g(p, 0x2bc), _g(p, 0x2c8),
					_g(p, 0x40), mk_s])


func _who(v: Variant, players: Array) -> String:
	if not (v is Dictionary):
		return str(v) if v != null else "0"
	for ti in range(2):
		var arr: Array = players[ti]
		for pi in range(arr.size()):
			if is_same(arr[pi], v):
				return "%s.i%d" % ["t0" if ti == 0 else "t1", pi]
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
