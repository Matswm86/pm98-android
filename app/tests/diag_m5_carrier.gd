extends SceneTree
## M5 clk-16..27 possession-handoff probe (s28 NEXT from clk12 fix).
## Reference (correctseed): ctrl flips Villa-slot8 -> Bolton-slot9 at clk 16, reverts to
## Villa-slot8 at clk 27. Port allegedly keeps Villa-slot8. This dumps, per clk 10..35, the
## port's ball pos/vel and the carrier pointer resolved to (team,slot,action) for BOTH the
## b+0x40 carrier and the b+0x4c secondary link, plus the two nearest players to the ball.
## Run: ~/godot462 --headless --path app --script res://tests/diag_m5_carrier.gd

const REF_DIR := "/home/mats/MWM-AI/data/pm98-m4-oracle/capture2"
const STRUCT_JSON := REF_DIR + "/frame0_struct_import.json"
const FRAME0_SEED := 0xea0d2a8d
const TICK_CAP := 80


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
	print("line(+0x1820)=%d  half orient(+0x19a0)=%d" % [Pm98Trig._i32(_g(m, 0x1820)), _g(m, 0x19a0)])

	var t := 0
	var last_clk := -1
	while t < TICK_CAP:
		var ret := Pm98Driver.tick(m, rng)
		t += 1
		if ret == 0:
			m[0x1a1e] = 1
		var clk := _g(m, 0x450)
		if clk == last_clk:
			continue          # only print once per clk (end-of-clk state)
		last_clk = clk
		if clk < 10 or clk > 35:
			continue
		var bx := Pm98Trig._i32(_g(b, 4))
		var by := Pm98Trig._i32(_g(b, 8))
		var carrier := _who(b.get(0x40, null), players)
		var link4c := _who(b.get(0x4c, null), players)
		# nearest two players to ball across both teams
		var near := _nearest(players, bx, by)
		print("clk=%2d ph=%d | BALL(%d,%d) v(%d,%d) b54=%d b63=%d | carrier=%s  b4c=%s | %s" % [
			clk, _g(m, 0x448), bx, by,
			Pm98Trig._i32(_g(b, 0x20)), Pm98Trig._i32(_g(b, 0x24)),
			_g(b, 0x54), _g(b, 0x63) & 0xff,
			carrier, link4c, near])


func _nearest(players: Array, bx: int, by: int) -> String:
	var lst := []
	for ti in range(2):
		var arr: Array = players[ti]
		for pi in range(arr.size()):
			var p: Dictionary = arr[pi]
			var px := Pm98Trig._i32(_g(p, 4))
			var py := Pm98Trig._i32(_g(p, 8))
			var d := int(sqrt(float((px - bx) * (px - bx) + (py - by) * (py - by))))
			lst.append([d, ti, pi, _g(p, 0x40)])
	lst.sort_custom(func(a, b): return a[0] < b[0])
	var out := "near:"
	for i in range(3):
		var e = lst[i]
		out += " %s%d(d=%d,act=0x%x)" % ["V" if e[1] == 0 else "B", e[2], e[0], e[3]]
	return out


func _who(v: Variant, players: Array) -> String:
	if not (v is Dictionary):
		return str(v)
	for ti in range(2):
		var arr: Array = players[ti]
		for pi in range(arr.size()):
			if is_same(arr[pi], v):
				var p: Dictionary = arr[pi]
				return "%s%d(act=0x%x,pos=%d,%d)" % [
					"V" if ti == 0 else "B", pi, _g(p, 0x40),
					Pm98Trig._i32(_g(p, 4)), Pm98Trig._i32(_g(p, 8))]
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
