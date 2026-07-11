extends SceneTree
## M5 clk-9 gate-4 g0 single-step (s30, executes the s29 NEXT). Byte-loads the reference frame0
## (seed 0xea0d2a8d), runs to clk 8, then captures via Pm98Movement.lean_trace the EXACT inputs the
## Villa slot-8 receiver's lean consumes at clk 9 and clk 10: p.pos/facing at the lean call (post
## clk-N interpolation), raw traj slot 0 (ball+0x114), ball pos/vel, and the built g0 row + exit gate.
## Also dumps the post-tick clk-8 ball pos/vel + ALL 16 traj slots — the fixture for re-running the
## REAL FUN_0058fda0 under the PCode emu (run_ballpredict_oracle.sh) to compare buffers bit-for-bit.
## Run: ~/godot462 --headless --path app --script res://tests/diag_m5_g0chain.gd

const REF_DIR := "/home/mats/MWM-AI/data/pm98-m4-oracle/capture2"
const STRUCT_JSON := REF_DIR + "/frame0_struct_import.json"
const FRAME0_SEED := 0xea0d2a8d
const TICK_CAP := 40


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

	var villa: Array = (teams[0] as Dictionary).get("players", [])
	var recv: Dictionary = villa[8]

	var t := 0
	while t < TICK_CAP:
		Pm98Movement.lean_trace = []
		Pm98Movement.lean_trace_on = true
		Pm98Driver.tick(m, rng)
		Pm98Movement.lean_trace_on = false
		t += 1
		var clk := _g(m, 0x450)
		print("tick %d -> clk=%d ph=%d trace=%d" % [t, clk, _g(m, 0x448), Pm98Movement.lean_trace.size()])
		if clk < 7 or clk > 11:
			continue
		print("\n=== tick -> clk=%d  rng=%d ===" % [clk, rng.state])
		# post-tick ball state + full traj buffer (what NEXT tick's lean reads).
		var bl := "  BALL pos=(%d,%d,%d) vel=(%d,%d,%d) b68=%d b6c=%d b40=%s b4c=%s" % [
			_si(ball, 4), _si(ball, 8), _si(ball, 0xc),
			_si(ball, 0x20), _si(ball, 0x24), _si(ball, 0x28),
			_g(ball, 0x68), _g(ball, 0x6c), _who(ball.get(0x40, null), villa), _who(ball.get(0x4c, null), villa)]
		print(bl)
		var tb := "  TRAJ "
		for i in 16:
			var off := 0x114 + i * 0xc
			tb += "[%d]=(%d,%d,%d) " % [i, _si(ball, off), _si(ball, off + 4), _si(ball, off + 8)]
		print(tb)
		print("  SEGLEN +0x74/78/7c = %d/%d/%d" % [_si(ball, 0x74), _si(ball, 0x78), _si(ball, 0x7c)])
		print("  RECV post-tick pos=(%d,%d,%d) face=0x%x act=0x%x p80=%d p84=%d tgt94/98=(%d,%d) p66=0x%x" % [
			_si(recv, 4), _si(recv, 8), _si(recv, 0xc), _g(recv, 0x34) & 0xffff, _g(recv, 0x40),
			_g(recv, 0x80), _g(recv, 0x84), _si(recv, 0x94), _si(recv, 0x98), _g(recv, 0x66) & 0xffff])
		# the receiver's lean record for THIS tick (at-call inputs, mid-tick).
		for rv in Pm98Movement.lean_trace:
			var rd: Dictionary = rv
			if not is_same(rd.get("p", null), recv):
				continue
			print("  LEAN@recv gate=%s pos=%s face=0x%x act=0x%x p54=%d p2bc=%d" % [
				rd["gate"], str(rd["pos"]), int(rd["face"]), int(rd["act"]), int(rd["p54"]), int(rd["p2bc"])])
			print("            bpos=%s bvel=%s b40=%s b4c=%s b70=%d b68=%d b6c=%d traj0=%s" % [
				str(rd["bpos"]), str(rd["bvel"]), _who(rd.get("b40"), villa), _who(rd.get("b4c"), villa),
				int(rd["b70"]), int(rd["b68"]), int(rd["b6c"]), str(rd["traj0"])])
			if rd.has("g0"):
				var g0: Array = rd["g0"]
				var in_catch := int(g0[2]) <= 0x1e665 and absi(int(g0[1])) <= 0x8000 \
					and absi(Pm98Trig._i32(int(g0[0]) - 0x4ccc)) <= 0x4ccb
				print("            g0=%s inCatch=%s (x bound 0x9997=%d) sc=%s applied=%s" % [
					str(g0), str(in_catch), 0x9997, str(rd.get("sc")), str(rd.get("applied", "-"))])
				# hand-recompute g0 from the recorded inputs to prove the transform chain.
				var dx := Pm98Trig._i32(int((rd["traj0"] as Array)[0]) - int((rd["pos"] as Array)[0]))
				var dy := Pm98Trig._i32(int((rd["traj0"] as Array)[1]) - int((rd["pos"] as Array)[1]))
				var dz := Pm98Trig._i32(int((rd["traj0"] as Array)[2]) - int((rd["pos"] as Array)[2]))
				var rg: Array = Pm98Trig.rot_vec3([dx, dy, dz], -Pm98Trig._s16(int(rd["face"])), 0)
				print("            recompute rot(traj0-pos,-face)=%s" % str(rg))


func _who(v: Variant, villa: Array) -> String:
	if v is Dictionary:
		for i in villa.size():
			if is_same(villa[i], v):
				return "V%d" % i
		return "opp"
	return str(v)


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
		team[0x4f + slot] = players[int(act[slot])] if act[slot] is float or act[slot] is int else 0
	var rol: Array = hdr["role_table"]
	for k in range(rol.size()):
		team[0x5b + k] = players[int(rol[k])] if rol[k] is float or rol[k] is int else 0
	var sh: Array = hdr["squad_header"]
	for k in range(sh.size()):
		team[0xbf + k] = int(sh[k])
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
