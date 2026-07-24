extends SceneTree
## M5 s52: dump the FULL steer APPLY chain for t1.i10 over clk 630-650.
##
## s51 captured live silicon: 0x34 slews -0x400/tick straight through clk 639 and 0x64 stages
## 28286 -> 9258 -> 765 -> 763. The disassembly of the apply path (FUN_005b0040 tail ->
## FUN_005b1330 clamp -> FUN_005a89c0 -> FUN_005a8bc0 -> FUN_005a8f20) says:
##   * 0x64 := heading ONLY when |s16(heading - face)| < 0x1555, else 0x68 decays by 0x1ca
##   * 0x34 SNAPS to heading when |s16(heading - face)| < 0x500, else slews +/-0x400
## so the silicon 0x34/0x64/0x68 ladder pins down what heading the real game APPLIED per tick.
## This prints the port's applied heading + every gate input so the two can be compared directly.
##
## Run: ~/godot462 --headless --path app --script res://tests/diag_m5_t1i10_apply.gd

const REF_DIR := "/home/mats/MWM-AI/data/pm98-m4-oracle/capture2"
const STRUCT_JSON := REF_DIR + "/frame0_struct_import.json"
const FRAME0_SEED := 0xea0d2a8d
const TICK_CAP := 1400
const CLK_LO := 628
const CLK_HI := 652
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
	var who := "t%d.i%d" % [TEAM, IDX]
	print("# clk | tgt(x,y) | hdg  face  ad    dec   | 0x34  0x64  0x68  0x6c  p90 | pos(x,y)")
	var t := 0
	while t < TICK_CAP:
		var clk_pre := _g(m, 0x450)
		var in_win := clk_pre >= CLK_LO and clk_pre <= CLK_HI
		if in_win:
			MatchEngine.Pm98Rng._log_on = true
			Pm98Movement.steerhdg_trace.clear()
			Pm98Movement.steersite_trace.clear()
			Pm98Movement.b0040_trace.clear()
		var ret := Pm98Driver.tick(m, rng)
		t += 1
		if ret == 0:
			m[0x1a1e] = 1
		var clk := _g(m, 0x450)
		if not in_win:
			continue
		MatchEngine.Pm98Rng._log_on = false
		var pre_tgt := "-"
		for e in Pm98Movement.steersite_trace:
			var d: Dictionary = e
			if str(d["who"]).strip_edges() == who:
				var tg: Array = d["target"]
				pre_tgt = "%d,%d" % [Pm98Trig._i32(int(tg[0])), Pm98Trig._i32(int(tg[1]))]
		var line := "-"
		for e in Pm98Movement.steerhdg_trace:
			var d: Dictionary = e
			if str(d["who"]).strip_edges() != who:
				continue
			var hdg := int(d["heading"]) & 0xffff
			var face := int(d["face"])
			var ad := int(d["ad"])
			var dec := "SNAP" if ad < 0x500 else ("slew" + ("+" if Pm98Trig._s16(hdg - face) > 0 else "-"))
			var cm := "commit" if ad < 0x1555 else "DECAY"
			line = "%5d %5d %5d  %s/%s  dxy=%s p90=%d" % [hdg, face, ad, dec, cm, str(d["dxy"]), int(d["p90"])]
		print("clk %d | tgt=%s | %s | 0x34=%d 0x64=%d 0x68=%d 0x6c=%d | pos=(%d,%d)" % [
			clk, pre_tgt, line, _g(p, 0x34) & 0xffff, _g(p, 0x64) & 0xffff,
			Pm98Trig._i32(_g(p, 0x68)), Pm98Trig._i32(_g(p, 0x6c)), _si(p, 4), _si(p, 8)])
		for e in Pm98Movement.b0040_trace:
			var d: Dictionary = e
			if str(d["who"]).strip_edges() != who:
				continue
			print("      b0040 in: p=%s ball=%s bvel=%s face=%d facedir=%s crate=%d p70=%d p3ac=%d p3a8=%d" % [
				str(d["p_pos"]), str(d["ball_pos"]), str(d["ball_vel"]), int(d["ball_face"]),
				str(d["facedir"]), int(d["curve_rate"]), int(d["p_70"]), int(d["p_3ac"]), int(d["p_3a8"])])
			print("      b0040 lead0=%d lead=%d k=%d pre=%s | mk_b0=%d mk_bc=%d mk_cc=%s mk_d8=%s p2bc=%d" % [
				int(d["lead0"]), int(d["lead_final"]), int(d["kiters"]), str(d["point_preclamp"]),
				int(d["mk_b0"]), int(d["mk_bc"]), str(d["mk_cc"]), str(d["mk_d8"]), int(d["p_2bc"])])
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
