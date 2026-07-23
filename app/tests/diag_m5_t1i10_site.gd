extends SceneTree
## M5 s50: WHICH steer_89c0 call site fires for t1.i10 at clk 638 vs 639?
##
## s49 localised the first real port-vs-silicon fork (clk 644, t1.i10) to the TARGET, not the
## steering: at clk 638->639 target_pos flips through the origin,
##   clk 638  d=[ 3418744,  4199808]
##   clk 639  d=[-4118722,  -519801]
## while the player barely moved (350402 -> 350939). Heading, turn direction, speed decay and
## the 17-tick freeze are all correct consequences of that one flip.
##
## Pm98Movement.steersite_trace (new, get_stack()-based, gated on Pm98Rng._log_on) records the
## caller frames of every steer_89c0, so this prints per clk, for t1.i10:
##   - the steer_89c0 call site + the raw target it was handed
##   - the _b0040_target term snapshot when the b0040 path is the one that fired
##   - the goal-anchor sign-gate inputs (p+0x2b8 team, m+0x19a0 orient, m+0x1820 gx) so a
##     wrong-team / wrong-goal selection is visible directly
##
## Run: ~/godot462 --headless --path app --script res://tests/diag_m5_t1i10_site.gd

const REF_DIR := "/home/mats/MWM-AI/data/pm98-m4-oracle/capture2"
const STRUCT_JSON := REF_DIR + "/frame0_struct_import.json"
const FRAME0_SEED := 0xea0d2a8d
const TICK_CAP := 1400
const CLK_LO := 630
const CLK_HI := 650
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
		for e in Pm98Movement.steersite_trace:
			var d: Dictionary = e
			if str(d["who"]).strip_edges() != who:
				continue
			print("clk %d  pos=(%d,%d)  target=%s  scale=%d" % [
				clk, _si(p, 4), _si(p, 8), str(d["target"]), int(d["scale"])])
			print("    sites: %s" % str(d["sites"]))
		print("clk %d  team p2b8=%d  m19a0=%d (&1=%d)  m1820=%d  m1824=%d  p63=%d  p2bc=%d  active=%s" % [
			clk, _g(p, 0x2b8), _g(m, 0x19a0), _g(m, 0x19a0) & 1, _si(m, 0x1820), _si(m, 0x1824),
			_g(p, 0x63), _g(p, 0x2bc), str(is_same((ball as Dictionary).get(0x40, null), p))])
		# b1420 ARM SELECTOR inputs: which of B0040 / B1500 / B1C80 the formation gate picks is decided
		# by (gs+0x204 designate == p) AND (ball+0x40 carrier is null); else ball+0x54 vs p+0x2b8.
		var gsd: Dictionary = teams[TEAM]
		var desig = Pm98Movement._desig(gsd, 0x204)
		var desig_raw = gsd.get(0x204, null)
		var carrier = (ball as Dictionary).get(0x40, null)
		print("    b1420: desig_raw=%s desig_is_p=%s  carrier_is_dict=%s  ball54=%d  p2b8=%d  gs2ee=%d  p5c=%d -> arm=%s" % [
			str(desig_raw), str(is_same(desig, p)), str(carrier is Dictionary), _g(ball, 0x54), _g(p, 0x2b8),
			_g(gsd, 0x2ee) & 0xff, _g(p, 0x5c) & 0xff,
			("B0040" if (is_same(desig, p) and not (carrier is Dictionary))
				else ("B1500" if _g(ball, 0x54) != _g(p, 0x2b8) else "B1C80"))])
		for e in Pm98Movement.b0040_trace:
			var d: Dictionary = e
			if str(d["who"]).strip_edges() != who:
				continue
			print("    b0040 ball=%s bvel=%s face=%d facedir=%s p2bc=%d ctrl4c_is_p=%s" % [
				str(d["ball_pos"]), str(d["ball_vel"]), int(d["ball_face"]), str(d["facedir"]),
				int(d["p_2bc"]), str(d["ctrl_4c_is_p"])])
			print("    b0040 lead0=%d lead=%d k=%d to_common=%s stat=%s pre=%s lo=%s hi=%s carrier84=%s" % [
				int(d["lead0"]), int(d["lead_final"]), int(d["kiters"]), str(d["to_common"]),
				str(d["ball_stationary"]), str(d["point_preclamp"]), str(d["clamp_lo"]),
				str(d.get("clamp_hi", "?")), str(d["carrier_84"])])
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
