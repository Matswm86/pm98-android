extends SceneTree
## M5 s50: full spec-ready input dump + per-iteration bisection trace of _b0040_target for
## t1.i10 across the clk 638 -> 639 target flip.
##
## diag_m5_t1i10_site.gd proved the call site is _move_b0040 (Pm98Movement.gd:1614) on EVERY
## tick 635..650 -- NOT a goal-anchor steer -- and that the team/orient terms (p+0x2b8=1,
## m+0x19a0=0, m+0x1820=3768320) are CONSTANT across the flip. So no wrong-team / wrong-goal
## selection is involved. What flips is the bisection result:
##   clk 638  lead0=-381975  lead= 1061501930  k=18(cap)  pre=[ 1045495016,  187543173]
##   clk 639  lead0=-394836  lead=-1040510322  k=18(cap)  pre=[-1023306846, -187689993]
## i.e. the <=0x12-iteration interception loop never converges, `lead` runs to ~1e9, and the
## per-axis pitch clamp pins the target to the +x/+y corner one tick and the -x/-y corner the
## next. This dumps every input the PCode oracle spec needs (curve terms, the 16 formation
## marker slots ctrl+(idx+0x17)*0xc, the clamp box) plus each loop iteration.
##
## Run: ~/godot462 --headless --path app --script res://tests/diag_m5_t1i10_b0040iter.gd

const REF_DIR := "/home/mats/MWM-AI/data/pm98-m4-oracle/capture2"
const STRUCT_JSON := REF_DIR + "/frame0_struct_import.json"
const FRAME0_SEED := 0xea0d2a8d
const TICK_CAP := 1400
const CLK_LO := 637
const CLK_HI := 640
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
	var t := 0
	while t < TICK_CAP:
		var clk_pre := _g(m, 0x450)
		var in_win := clk_pre >= CLK_LO and clk_pre <= CLK_HI
		if in_win:
			MatchEngine.Pm98Rng._log_on = true
			Pm98Movement.b0040_trace.clear()
			Pm98Movement.b0040_iter_trace.clear()
		var pre_pos := [_si(p, 4), _si(p, 8), _si(p, 0xc)]
		var ret := Pm98Driver.tick(m, rng)
		t += 1
		if ret == 0:
			m[0x1a1e] = 1
		var clk := _g(m, 0x450)
		if not in_win:
			continue
		MatchEngine.Pm98Rng._log_on = false
		for e in Pm98Movement.b0040_trace:
			var d: Dictionary = e
			if str(d["who"]).strip_edges() != who:
				continue
			print("=== clk %d  (pos at fn entry = %s) ===" % [clk, str(d["p_pos"])])
			print("  pos_before_tick=%s" % str(pre_pos))
			print("  ball_pos=%s ball_vel=%s ball_face=%d facedir=%s" % [
				str(d["ball_pos"]), str(d["ball_vel"]), int(d["ball_face"]), str(d["facedir"])])
			print("  p_2bc=%d ctrl4c_is_p=%s p70=%d p3ac=%d p3a8=%d curve_rate=%d" % [
				int(d["p_2bc"]), str(d["ctrl_4c_is_p"]), int(d["p_70"]), int(d["p_3ac"]),
				int(d["p_3a8"]), int(d["curve_rate"])])
			print("  mk_b0=%d mk_bc=%d mk_cc=%s mk_d8=%s carrier84=%s" % [
				int(d["mk_b0"]), int(d["mk_bc"]), str(d["mk_cc"]), str(d["mk_d8"]),
				str(d["carrier_84"])])
			print("  lead0=%d lead_final=%d kiters=%d pre=%s lo=%s hi=%s" % [
				int(d["lead0"]), int(d["lead_final"]), int(d["kiters"]),
				str(d["point_preclamp"]), str(d["clamp_lo"]), str(d.get("clamp_hi", "?"))])
		var ctrl: Dictionary = ball
		var slots := []
		for i in range(16):
			var off := (i + 0x17) * 0xc
			slots.append("%d:%d,%d" % [i, _si(ctrl, off), _si(ctrl, off + 4)])
		print("  marker slots (idx: x,y) = %s" % str(slots))
		for e in Pm98Movement.b0040_iter_trace:
			var d: Dictionary = e
			if str(d["who"]).strip_edges() != who:
				continue
			print("  k=%2d lead_in=%d lp=%s d=(%d,%d) mag=%d ticks=%d uv9=%d idx=%d mk=0x%x mkv=%s tp=%s nd=%d" % [
				int(d["k"]), int(d["lead_in"]), str(d["lp"]), int(d["dx"]), int(d["dy"]),
				int(d["mag"]), int(d["ticks"]), int(d["uv9"]), int(d["idx"]), int(d["mk"]),
				str(d["mkv"]), str(d["tp"]), int(d["nd"])])
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
