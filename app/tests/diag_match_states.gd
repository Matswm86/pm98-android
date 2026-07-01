extends SceneTree
## DIAGNOSTIC (not a lock): same setup as run_full_match.gd, but records WHICH gates block the
## goal-scoring path -- per-tick action-code histogram (player+0x40), ball state (pos/vel/owner/
## engaged), set-piece mode (match+0x44c), restart kind (match+0x19a0), taker (match+0x438) --
## so the next port target is chosen from evidence, not guessed.
## Run: ~/godot462 --headless --path app --script res://tests/diag_match_states.gd

const TICK_CAP := 3000


func _init() -> void:
	_run(1)
	quit(0)


func _rec(role: int, shirt: int, px: int, py: int) -> Dictionary:
	return {
		0x4: shirt,
		0x8: px, 0xc: py, 0x10: px, 0x14: py,
		0x18: px, 0x1c: py, 0x20: px, 0x24: py,
		0x28: 0, 0x2c: 11, 0x30: 11,
		0x34: 60, 0x35: 60, 0x36: 60, 0x37: 60, 0x38: 60,
		0x3c: 60, 0x3d: 60, 0x3e: 60, 0x3f: 60, 0x40: 65, 0x41: 60,
		0x42: 40,
		0x44: role,
		0x98: 0,
	}


func _lineup(team: int) -> Dictionary:
	var slots: Array = []
	var sgn := 1 if team == 0 else -1
	var rows := [
		[1, -45, 0],
		[2, -30, -20], [3, -30, -7], [4, -30, 7], [5, -30, 20],
		[6, -5, -22], [7, -5, -7], [8, -5, 7], [9, -5, 22],
		[10, 15, -10], [11, 15, 10],
	]
	for i in range(11):
		var r: Array = rows[i]
		slots.append(_rec(int(r[0]), team * 100 + i + 1, int(r[1]) * sgn * 0x10000, int(r[2]) * 0x10000))
	return {"header": [0, 0, 0, 0, 0, 0, 0, 0, 0], "slots": slots}


func _session() -> Dictionary:
	return {
		0x4c: 0x680000,
		0x50: 0x440000,
		0xfd0: 0, 0xfd4: 0, 0xfd8: 0, 0xfdc: 0,
		0xff4: 0,
		0xfa0: 1,
		0xfe8: 0, 0xfec: 0, 0xff0: 0,
		0x14: 0, 0x20: 0, 0x24: 0, 0x44: 0, 0x48: 0,
	}


func _all_players(m: Dictionary) -> Array:
	var out: Array = []
	for t in range(2):
		for q in ((m["sim"][t] as Dictionary).get("players", []) as Array):
			if q is Dictionary:
				out.append(q)
	return out


func _ptr_tag(m: Dictionary, players: Array, v: Variant) -> String:
	if v is Dictionary:
		for i in range(players.size()):
			if is_same(players[i], v):
				return "P%d" % i
		for key in [[0xaac, "GK0"], [0xe74, "GK1"], [0x123c, "REF"]]:
			var o: Variant = m.get(key[0], null)
			if o is Dictionary and is_same(o, v):
				return String(key[1])
		return "obj?"
	return str(v)


func _run(seed_: int) -> void:
	var rng := MatchEngine.Pm98Rng.new(seed_)
	var m := Pm98Match.build_match(rng)
	Pm98CollBuilder.populate_posts(m)
	(m["sim"][0] as Dictionary)[0x9c] = _lineup(0)
	(m["sim"][1] as Dictionary)[0x9c] = _lineup(1)
	Pm98Match.kickoff_init(m, _session(), rng)

	var players := _all_players(m)
	# the ball ref, reached through a player (+0x190) -- same route the engine takes
	var ball: Dictionary = (players[0] as Dictionary).get(0x190, {})
	print("players=%d  ball_found=%s" % [players.size(), str(not ball.is_empty())])

	var act_hist := {}        # cumulative action-code counts across all players x ticks
	var m44c_hist := {}       # set-piece mode histogram
	var m19a0_hist := {}      # restart-kind histogram
	var phase_hist := {}
	var owner_ticks := 0      # ticks where ball+0x44 (possessor) is a player
	var engaged_ticks := 0    # ticks where ball+0x40 (engaged) is a player
	var b4c_ticks := 0        # ticks where ball+0x4c (feed target) set
	var moved := false
	var b0 := [ball.get(0x4, 0), ball.get(0x8, 0), ball.get(0xc, 0)]

	var prev_act := {}
	for i in range(players.size()):
		prev_act[i] = int((players[i] as Dictionary).get(0x40, -1))
	var prev_land := [ball.get(0x84, 0), ball.get(0x88, 0), ball.get(0x8c, 0)]
	var prev_462: int = Pm98Driver._g(m, 0x462)
	var prev_qn: int = (m.get(0x1a24, []) as Array).size()
	var trans_logged := 0
	var shot_lands := 0
	var t := 0
	while t < TICK_CAP:
		Pm98Driver.tick(m, rng)
		for i in range(players.size()):
			var na := int((players[i] as Dictionary).get(0x40, -1))
			if na != prev_act[i]:
				if trans_logged < 90:
					print("  t%03d P%d act 0x%x -> 0x%x" % [t, i, prev_act[i], na])
					trans_logged += 1
				prev_act[i] = na
		var land := [ball.get(0x84, 0), ball.get(0x88, 0), ball.get(0x8c, 0)]
		if land != prev_land:
			shot_lands += 1
			if shot_lands <= 10:
				print("  t%03d SETUP_SHOT landing write #%d: (%x,%x,%x)" % [t, shot_lands, int(land[0]), int(land[1]), int(land[2])])
			prev_land = land
		var f462: int = Pm98Driver._g(m, 0x462)
		if f462 != prev_462:
			print("  t%03d match+0x462: 0x%x -> 0x%x (kick_resolve flag)" % [t, prev_462, f462])
			prev_462 = f462
		var qn: int = (m.get(0x1a24, []) as Array).size()
		if qn != prev_qn:
			print("  t%03d event queue %d -> %d: %s" % [t, prev_qn, qn, str((m.get(0x1a24, []) as Array).slice(prev_qn))])
			prev_qn = qn
		var ph: int = Pm98Driver._g(m, 0x448)
		phase_hist[ph] = int(phase_hist.get(ph, 0)) + 1
		m44c_hist[Pm98Driver._g(m, 0x44c)] = int(m44c_hist.get(Pm98Driver._g(m, 0x44c), 0)) + 1
		m19a0_hist[Pm98Driver._g(m, 0x19a0)] = int(m19a0_hist.get(Pm98Driver._g(m, 0x19a0), 0)) + 1
		for q in players:
			var a: int = int((q as Dictionary).get(0x40, -1))
			act_hist[a] = int(act_hist.get(a, 0)) + 1
		if ball.get(0x44, null) is Dictionary:
			owner_ticks += 1
		if ball.get(0x40, null) is Dictionary:
			engaged_ticks += 1
		if ball.get(0x4c, null) is Dictionary:
			b4c_ticks += 1
		if not moved and (ball.get(0x4, 0) != b0[0] or ball.get(0x8, 0) != b0[1] or ball.get(0xc, 0) != b0[2]):
			moved = true
			print("tick %d: BALL FIRST MOVED to (%x,%x,%x) vel=(%x,%x,%x)" % [
				t, int(ball.get(0x4, 0)), int(ball.get(0x8, 0)), int(ball.get(0xc, 0)),
				int(ball.get(0x20, 0)), int(ball.get(0x24, 0)), int(ball.get(0x28, 0))])
		if t == 40 or t == 500:
			print("--- tick %d snapshot: phase=%d 44c=%d 19a0=%d taker=%s ball@(%x,%x,%x) vel=(%x,%x,%x) eng=%s own=%s" % [
				t, ph, Pm98Driver._g(m, 0x44c), Pm98Driver._g(m, 0x19a0),
				_ptr_tag(m, players, m.get(0x438, null)),
				int(ball.get(0x4, 0)), int(ball.get(0x8, 0)), int(ball.get(0xc, 0)),
				int(ball.get(0x20, 0)), int(ball.get(0x24, 0)), int(ball.get(0x28, 0)),
				_ptr_tag(m, players, ball.get(0x40, null)), _ptr_tag(m, players, ball.get(0x44, null))])
		t += 1

	var keys := act_hist.keys()
	keys.sort()
	var acts := ""
	for k in keys:
		acts += "0x%x:%d " % [k, act_hist[k]]
	print("action-code histogram (player+0x40, %d player-ticks): %s" % [players.size() * t, acts])
	print("phase histogram  = %s" % str(phase_hist))
	print("match+0x44c hist = %s" % str(m44c_hist))
	print("match+0x19a0 hist= %s" % str(m19a0_hist))
	print("ball owner/engaged/feedtgt ticks = %d / %d / %d" % [owner_ticks, engaged_ticks, b4c_ticks])
	print("ball ever moved  = %s" % str(moved))
	print("trace stub calls last tick = %s" % str(Pm98Action.trace_calls))
	print("DONE")
