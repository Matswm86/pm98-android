extends SceneTree
## M5 KICKOFF diagnostic: byte-load frame0, drive to the kickoff (phase 2->0), and dump the
## kickoff-taker's kick decision -- the chosen receiver (controller+0x4c: slot/team/pos), the
## aim point (p+0xa0/0xa4/0xa8), and the resulting ball velocity. Compares against the correct-
## seed reference (real receiver = Villa slot-8, collected at clk 12). Invention guard for the
## kickoff-velocity divergence. Run: ~/godot462 --headless --path app --script res://tests/diag_m5_kickoff.gd

const REF_DIR := "/home/mats/MWM-AI/data/pm98-m4-oracle/capture2"
const STRUCT_JSON := REF_DIR + "/frame0_struct_import.json"
const FRAME0_SEED := 0xea0d2a8d


func _init() -> void:
	_run()
	quit(0)


func _run() -> void:
	var dump := _load_json(STRUCT_JSON)
	if dump.is_empty():
		push_error("no struct json"); return
	var throwaway := MatchEngine.Pm98Rng.new(1)
	var m := Pm98Match.build_match(throwaway)
	Pm98CollBuilder.populate_posts(m)
	for k in (dump["match"] as Dictionary):
		m[_hx(k)] = int((dump["match"] as Dictionary)[k])
	var session := {}
	for k in (dump["session"] as Dictionary):
		if k == "_va": continue
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

	# dump all players' kickoff positions + slots (so we can see slot-8's start pos)
	print("== FRAME0 player kickoff positions (team0=Villa, team1=Bolton) ==")
	for ti in range(2):
		var players: Array = (teams[ti] as Dictionary).get("players", [])
		for pi in range(players.size()):
			var p: Dictionary = players[pi]
			print("  team%d idx%d slot(0x2c4)=%d role(0x2c8)=%d pos=(%d,%d,%d) onpitch=%d" % [
				ti, pi, _g(p, 0x2c4), _g(p, 0x2c8), _si(p, 4), _si(p, 8), _si(p, 0xc), _g(p, 0x2bc)])

	var b := _ball(m)
	var t := 0
	while t < 40:
		var pre_ctrl: Variant = b.get(0x40, null)
		var ret := Pm98Driver.tick(m, rng)
		t += 1
		if ret == 0:
			m[0x1a1e] = 1
		var phase := _g(m, 0x448)
		# the kickoff kick executes at the phase 2->0 transition; dump the taker's aim/receiver
		var active: Variant = m.get(0x438, null)
		if active is Dictionary:
			var pa: Dictionary = active
			var recv: Variant = b.get(0x4c, null)
			var aim := [_si(pa, 0xa0), _si(pa, 0xa4), _si(pa, 0xa8)]
			var recv_s := "none"
			if recv is Dictionary:
				recv_s = "slot%d team%d pos=(%d,%d)" % [_g(recv, 0x2c4), _g(recv, 0x2b8), _si(recv, 4), _si(recv, 8)]
			print("t=%d phase=%d taker slot%d act=0x%x aim=(%d,%d,%d) recv={%s} ball=(%d,%d,%d) vel=(%d,%d,%d) rng=%d" % [
				t, phase, _g(pa, 0x2c4), _g(pa, 0x40), aim[0], aim[1], aim[2], recv_s,
				_si(b, 4), _si(b, 8), _si(b, 0xc), _si(b, 0x20), _si(b, 0x24), _si(b, 0x28), rng.state])
		if phase == 0 and t > 26:
			break


func _load_player(src: Dictionary, own: Dictionary, opp: Dictionary, m: Dictionary, ball: Dictionary) -> Dictionary:
	var p := {}
	for k in (src["dwords"] as Dictionary):
		p[_hx(k)] = int((src["dwords"] as Dictionary)[k])
	for k in src:
		if k == "dwords" or k == "_va": continue
		p[_hx(k)] = int(src[k])
	p[0x184] = own; p[0x188] = opp; p[0x18c] = m; p[0x190] = ball
	return p


func _load_team_header(team: Dictionary, hdr: Dictionary, players: Array, ti: int, m: Dictionary) -> void:
	team[0x0] = players; team[0x4] = players.size(); team["players"] = players
	team[0x8] = ti; team[0x138] = m; team[0xc] = int(hdr["score_0xc"])
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
	team[0x2e0] = int(hdr["0x2e0"]); team[0x2ec] = int(hdr["0x2ec"])
	team[0x2ed] = int(hdr["0x2ed"]); team[0x20c] = int(hdr["0x20c"])


func _ball(m: Dictionary) -> Dictionary:
	var v: Variant = m.get("ball", null)
	return v if v is Dictionary else {}


func _g(d: Variant, k: int) -> int:
	if d is Dictionary: return int((d as Dictionary).get(k, 0))
	return 0


func _si(d: Variant, k: int) -> int:
	return Pm98Trig._i32(_g(d, k))


func _hx(k: Variant) -> int:
	if k is int: return k
	var s := str(k)
	return s.hex_to_int() if s.begins_with("0x") else int(s)


func _load_json(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null: return {}
	var d: Variant = JSON.parse_string(f.get_as_text())
	return d if d is Dictionary else {}
