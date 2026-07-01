extends SceneTree
## Diag: why does H2 never re-enter phase 0 after the lean wire (2026-07-01)?
## Same fixture as run_full_match.gd (verbatim _rec/_lineup/_session), seed 1, run to frame
## 12000 (past the HT restart), then dump the stall state: phase flips, m gates, ball
## owner/pos/vel, and every player's action/+0x2bc/+0x54 to see WHAT gate is stuck.

const FRAMES := 12000


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


func _pdesc(m: Dictionary, p) -> String:
	if not (p is Dictionary):
		return str(p)
	var team := int(p.get(0x2b8, -1))
	var idx := Pm98Movement._team_index_of(m, team, p)
	return "t%d#%d" % [team, idx]


func _dump(m: Dictionary, t: int) -> void:
	var p00: Dictionary = ((m["sim"][0] as Dictionary)["players"] as Array)[0]
	var ball: Dictionary = p00[0x190]
	print("--- t=%d  448=%d 44c=%d 461=0x%x 460=%s 43c=%s 438=%s 1650=%s 1a38=%d 19a0=%d" % [
		t, Pm98Driver._g(m, 0x448), Pm98Driver._g(m, 0x44c), Pm98Driver._g(m, 0x461),
		_pdesc(m, m.get(0x460, 0)), _pdesc(m, m.get(0x43c, 0)), _pdesc(m, m.get(0x438, 0)),
		str(m.get(0x1650, "-")), Pm98Driver._g(m, 0x1a38), Pm98Driver._g(m, 0x19a0)])
	print("    ball owner=%s soft4c=%s last44=%s pos=(%d,%d) vel=(%d,%d) anim=%d" % [
		_pdesc(m, ball.get(0x40, 0)), _pdesc(m, ball.get(0x4c, 0)), _pdesc(m, ball.get(0x44, 0)),
		Pm98Driver._g(ball, 4), Pm98Driver._g(ball, 8),
		Pm98Driver._g(ball, 0x20), Pm98Driver._g(ball, 0x24), Pm98Driver._g(ball, 0x68)])
	for team in 2:
		var roster: Array = (m["sim"][team] as Dictionary)["players"]
		var rows: Array = []
		for i in roster.size():
			var p: Dictionary = roster[i]
			rows.append("#%d a=0x%x 54=%d" % [i, Pm98Driver._g(p, 0x40), Pm98Driver._g(p, 0x54)])
		print("    t%d: %s" % [team, " | ".join(rows)])


func _init() -> void:
	var rng := MatchEngine.Pm98Rng.new(1)
	var m := Pm98Match.build_match(rng)
	Pm98CollBuilder.populate_posts(m)
	(m["sim"][0] as Dictionary)[0x9c] = _lineup(0)
	(m["sim"][1] as Dictionary)[0x9c] = _lineup(1)
	Pm98Match.kickoff_init(m, _session(), rng)
	var phase_flips: Array = []
	var last_ph := -999
	for t in FRAMES:
		Pm98Outer.step(m, rng)
		var ph: int = Pm98Driver._g(m, 0x448)
		if ph != last_ph:
			phase_flips.append("t%d:%d" % [t, ph])
			last_ph = ph
		if t == 10 or t == 7960:
			_dump(m, t)
	var p00: Dictionary = ((m["sim"][0] as Dictionary)["players"] as Array)[0]
	var ball: Dictionary = p00[0x190]
	print("phase flips (last 25 of %d): %s" % [phase_flips.size(),
		str(phase_flips.slice(maxi(0, phase_flips.size() - 25)))])
	print("m: 448=%d 44c=%d 461=0x%x 460=%s 43c=%s 1a38=%d 19a0=%d 450=%d 19a8=%d" % [
		Pm98Driver._g(m, 0x448), Pm98Driver._g(m, 0x44c), Pm98Driver._g(m, 0x461),
		"P" if m.get(0x460) is Dictionary else str(m.get(0x460, 0)),
		"P" if m.get(0x43c) is Dictionary else str(m.get(0x43c, 0)),
		Pm98Driver._g(m, 0x1a38), Pm98Driver._g(m, 0x19a0), Pm98Driver._g(m, 0x450),
		Pm98Driver._g(m, 0x19a8)])
	print("ball: owner=%s soft4c=%s last44=%s pos=(%d,%d,%d) vel=(%d,%d,%d) anim68=%d b62=%d" % [
		_pdesc(m, ball.get(0x40, 0)), _pdesc(m, ball.get(0x4c, 0)), _pdesc(m, ball.get(0x44, 0)),
		Pm98Driver._g(ball, 4), Pm98Driver._g(ball, 8), Pm98Driver._g(ball, 0xc),
		Pm98Driver._g(ball, 0x20), Pm98Driver._g(ball, 0x24), Pm98Driver._g(ball, 0x28),
		Pm98Driver._g(ball, 0x68), Pm98Driver._g(ball, 0x62)])
	for team in 2:
		var roster: Array = (m["sim"][team] as Dictionary)["players"]
		var rows: Array = []
		for i in roster.size():
			var p: Dictionary = roster[i]
			rows.append("#%d a=0x%x 2bc=%d 54=%d pos=(%d,%d)" % [i, Pm98Driver._g(p, 0x40),
				Pm98Driver._g(p, 0x2bc), Pm98Driver._g(p, 0x54),
				Pm98Driver._g(p, 4) / 0x10000, Pm98Driver._g(p, 8) / 0x10000])
		print("team%d: %s" % [team, " | ".join(rows)])
	quit(0)
