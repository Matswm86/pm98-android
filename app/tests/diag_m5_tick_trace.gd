extends SceneTree
## M5 DIAGNOSTIC (handoff-pm98-m5-killtest-run-2026-07-07 NEXT step 1): a TICK-LEVEL driver
## trace of the byte-loaded frame-0, to find WHY the port converts a shot at clk~601 (min 1')
## where the reference plays on to clk~2837 (min 8'). Same byte-load as run_match_from_struct.gd
## but drives Pm98Driver.tick DIRECTLY (Outer.step spins in the pause branch), arming the
## +0x1a1e restart gate on a tick-ret-0 exactly like Pm98Outer._live_branch, and logs the ball
## kinematics + phase/clk/rng every tick so the trajectory into the goal mouth is visible.
##
## Run: ~/godot462 --headless --path app --script res://tests/diag_m5_tick_trace.gd
## CSV: /tmp/claude-1000/.../scratchpad/m5_tick_trace.csv  (path printed at end)

const REF_DIR := "/home/mats/MWM-AI/data/pm98-m4-oracle/capture2"
const STRUCT_JSON := REF_DIR + "/frame0_struct_import.json"
const FRAME0_SEED := 0xea0d2a8d
const TICK_CAP := 4000
const CSV_PATH := "/tmp/claude-1000/-home-mats-MWM-AI/9d2c2b92-0f78-4b56-8a19-5fc81cea675c/scratchpad/m5_tick_trace.csv"


var _contest_ticks := 0
var _marked_ticks := 0
var _in_range_ticks := 0
var _min_opp_sum := 0
var _min_opp_min := 1 << 60


func _init() -> void:
	_run()
	quit(0)


func _run() -> void:
	var dump := _load_json(STRUCT_JSON)
	if dump.is_empty():
		push_error("could not load %s" % STRUCT_JSON)
		return

	# ---- byte-load (identical to run_match_from_struct.gd) ---------------------------------
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
	var force_ps := OS.get_environment("PM98_FORCE_PS")
	if force_ps != "":
		session[0xfa0] = force_ps.to_int()
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

	var line := Pm98Trig._i32(_g(m, 0x1820))
	print("== M5 tick trace ==  ps=%d  line(+0x1820)=0x%x  post(+0x1824)=0x%x  half(+0x19ac)=%d" % [
		int(session.get(0xfa0, -1)), line, _g(m, 0x1824), _g(m, 0x19ac)])
	print("goal_area x-window: |x| in [0x%x, 0x%x] (line..line+0x10000), |y|<0x3a8f5, z in [0,0x270a3]" % [line, line + 0x10000])

	var csv := FileAccess.open(CSV_PATH, FileAccess.WRITE)
	csv.store_line("tick,clk,phase,poss,m45c,rng,bx,by,bz,bvx,bvy,bvz,bctrl,bside,barmed,active,ret")

	var b := _ball(m)
	var prev_score := [_g(m, 0x478), _g(m, 0x798)]
	_min_opp_min = 1 << 60
	var kickoff_done := -1
	var goal_tick := -1
	var window := []                                  # rolling last-8 ticks for goal context
	var t := 0
	while t < TICK_CAP:
		var ret := Pm98Driver.tick(m, rng)
		t += 1
		if ret == 0:
			m[0x1a1e] = 1                             # arm restart next tick (Outer._live_branch)

		var clk := _g(m, 0x450)
		var phase := _g(m, 0x448)
		var bx := Pm98Trig._i32(_g(b, 4))
		var by := Pm98Trig._i32(_g(b, 8))
		var bz := Pm98Trig._i32(_g(b, 0xc))
		var ctrl_v: Variant = b.get(0x40, null)
		var ctrl_id := _obj_id(ctrl_v)
		var active_v: Variant = m.get(0x438, null)
		var active_id := _obj_id(active_v)
		var row := "%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%s,%d,%d,%s,%d" % [
			t, clk, phase, _g(m, 0x19a0), _g(m, 0x45c), rng.state,
			bx, by, bz, Pm98Trig._i32(_g(b, 0x20)), Pm98Trig._i32(_g(b, 0x24)), Pm98Trig._i32(_g(b, 0x28)),
			ctrl_id, _g(b, 0x54), _g(b, 0x63) & 0xff, active_id, ret]
		csv.store_line(row)

		# phase 2 -> 0 transition (kickoff complete, open play begins)
		if kickoff_done < 0 and phase == 0:
			kickoff_done = t
			print("[kickoff->openplay] tick=%d clk=%d rng=%d ball=(%d,%d,%d) ctrl=%s" % [
				t, clk, rng.state, bx, by, bz, ctrl_id])

		window.append(row)
		if window.size() > 8:
			window.pop_front()

		var cur := [_g(m, 0x478), _g(m, 0x798)]
		if cur[0] > prev_score[0] or cur[1] > prev_score[1]:
			goal_tick = t
			print("\n[GOAL] tick=%d clk=%d (min %d)  score=%d-%d  <-- 8-tick context:" % [
				t, clk, (clk * 0x2d) / max(1, _g(m, 0x19ac)), cur[0], cur[1]])
			print("  tick,clk,ph,poss,m45c,rng,bx,by,bz,bvx,bvy,bvz,ctrl,side,armed,active,ret")
			for w in window:
				print("  " + w)
			break

		# progress sampling every 100 ticks
		if t % 100 == 0:
			print("  t=%d clk=%d ph=%d poss=%d  ball=(%d,%d,%d) |x|/line=%.2f  vel=(%d,%d,%d) ctrl=%s" % [
				t, clk, phase, _g(m, 0x19a0), bx, by, bz, float(absi(bx)) / float(max(1, line)),
				Pm98Trig._i32(_g(b, 0x20)), Pm98Trig._i32(_g(b, 0x24)), Pm98Trig._i32(_g(b, 0x28)), ctrl_id])

		if t in [100, 300, 500, 560, 579]:
			_snapshot(m, b, t, bx, by)

		# per-tick contest metric: is the ball-carrier marked, and how close is the nearest opponent?
		var cv: Variant = b.get(0x40, null)
		if cv is Dictionary and phase == 0:
			var carrier: Dictionary = cv
			var cteam := _g(carrier, 0x2b8)
			var cmarked := int(carrier.get(0x154, -1))
			var opp_players: Array = (m["sim"][1 - cteam] as Dictionary).get("players", [])
			var mind := 1 << 60
			for op in opp_players:
				if _g(op, 0x2bc) == 0:
					continue                          # skip keeper slot
				var dxo := Pm98Trig._i32(_g(op, 4)) - bx
				var dyo := Pm98Trig._i32(_g(op, 8)) - by
				var dd := dxo * dxo + dyo * dyo
				if dd < mind:
					mind = dd
			_contest_ticks += 1
			if cmarked >= 0:
				_marked_ticks += 1
			var md := int(sqrt(float(mind)))
			_min_opp_sum += md
			if md < _min_opp_min:
				_min_opp_min = md
			if md < 0x60000:
				_in_range_ticks += 1

	csv.close()
	print("\nkickoff_done tick = %d   goal_tick = %d   csv = %s" % [kickoff_done, goal_tick, CSV_PATH])
	print("\n== CONTEST METRIC (phase-0 ticks, carrier vs nearest outfield opponent) ==")
	print("  open-play ticks         = %d" % _contest_ticks)
	print("  carrier HAS a marker    = %d ticks (%.1f%%)" % [_marked_ticks, 100.0 * _marked_ticks / max(1, _contest_ticks)])
	print("  nearest opp in tackle-range (<0x60000) = %d ticks (%.1f%%)" % [_in_range_ticks, 100.0 * _in_range_ticks / max(1, _contest_ticks)])
	print("  nearest-opp dist: min=%d (0x%x)  mean=%d" % [_min_opp_min, _min_opp_min, _min_opp_sum / max(1, _contest_ticks)])
	print("  (tackle-range threshold 0x60000 = %d; goal line = %d)" % [0x60000, line])


## Snapshot every player + keeper: pos, action(+0x40), on-pitch(+0x2bc), marker links
## (+0x150 target / +0x154 markedby), dist-to-ball. Reveals whether the defense converges.
func _snapshot(m: Dictionary, b: Dictionary, t: int, bx: int, by: int) -> void:
	print("--- SNAPSHOT t=%d  ball=(%d,%d)  carrier=%s ---" % [t, bx, by, _obj_id(b.get(0x40, null))])
	var sim: Array = m["sim"]
	for ti in range(2):
		var players: Array = (sim[ti] as Dictionary).get("players", [])
		var tag := "Villa" if ti == 0 else "Bolton"
		for pi in range(players.size()):
			var p: Dictionary = players[pi]
			var px := Pm98Trig._i32(_g(p, 4))
			var py := Pm98Trig._i32(_g(p, 8))
			var d := int(sqrt(float((px - bx) * (px - bx) + (py - by) * (py - by))))
			print("  %-6s#%2d role=%d act=0x%x onpitch=%d mark_tgt=%d marked_by=%d pos=(%d,%d) dist2ball=%d" % [
				tag, pi, _g(p, 0x2c8), _g(p, 0x40), _g(p, 0x2bc),
				int(p.get(0x150, -1)), int(p.get(0x154, -1)), px, py, d])
	var ks: Variant = m.get("keepers", null)
	if ks is Array:
		for ki in range((ks as Array).size()):
			var k: Dictionary = (ks as Array)[ki]
			print("  KEEPER#%d pos=(%d,%d,%d) act=0x%x" % [
				ki, Pm98Trig._i32(_g(k, 4)), Pm98Trig._i32(_g(k, 8)), Pm98Trig._i32(_g(k, 0xc)), _g(k, 0x40)])


func _obj_id(v: Variant) -> String:
	if v is Dictionary:
		return "p%d" % (v as Dictionary).get(0x2c8, -1)   # 0x2c8 = role-ish stable-ish tag if present
	if v is int:
		return str(v)
	return "-"


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


func _ball(m: Dictionary) -> Dictionary:
	var v: Variant = m.get("ball", null)
	return v if v is Dictionary else {}


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
