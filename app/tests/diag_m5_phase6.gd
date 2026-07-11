extends SceneTree
## M5 phase-6 STALL diagnostic. Byte-loads frame-0 (same as diag_m5_tick_trace), drives the
## driver until phase 6 is armed, then for the next N ticks dumps the GK-slot players (+0x2bc==0)
## action(+0x40)/windup(+0x48) and the ball controller, to confirm WHICH branch of ball_touch_7260
## the keeper hits during the stall (the deferred phase-6 `return` vs the live path).
## Run: ~/godot462 --headless --path app --script res://tests/diag_m5_phase6.gd

const REF_DIR := "/home/mats/MWM-AI/data/pm98-m4-oracle/capture2"
const STRUCT_JSON := REF_DIR + "/frame0_struct_import.json"
const FRAME0_SEED := 0xea0d2a8d
const TICK_CAP := 2600


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

	var b := _ball(m)
	var dumped := 0
	var t := 0
	while t < TICK_CAP:
		var ret := Pm98Driver.tick(m, rng)
		t += 1
		if ret == 0:
			m[0x1a1e] = 1
		var phase := _g(m, 0x448)
		if phase == 6 and dumped < 6:
			dumped += 1
			_dump(m, b, t)
		# NEW freeze (div#3): once phase 6 has cleared and the ball sits still in open play, snapshot
		# the loose-ball collection state once.
		if t == 2500 and phase == 0:
			_freeze_dump(m, b, t)
	print("done t=%d phase=%d" % [t, _g(m, 0x448)])


func _freeze_dump(m: Dictionary, b: Dictionary, t: int) -> void:
	var bx := Pm98Trig._i32(_g(b, 4)); var by := Pm98Trig._i32(_g(b, 8))
	var ctrl: Variant = b.get(0x40, null)
	print("=== FREEZE t=%d phase=%d ball=(%d,%d,%d) vel=(%d,%d,%d) ctrl=%s armed=%d bside=%d b+0x44=%s ===" % [
		t, _g(m, 0x448), bx, by, Pm98Trig._i32(_g(b, 0xc)),
		Pm98Trig._i32(_g(b, 0x20)), Pm98Trig._i32(_g(b, 0x24)), Pm98Trig._i32(_g(b, 0x28)),
		("dict" if ctrl is Dictionary else str(ctrl)), _g(b, 0x63) & 0xff, _g(b, 0x54),
		("dict" if b.get(0x44, null) is Dictionary else str(b.get(0x44, 0)))])
	var sim: Array = m["sim"]
	var rows := []
	for ti in range(2):
		var players: Array = (sim[ti] as Dictionary).get("players", [])
		for pi in range(players.size()):
			var p: Dictionary = players[pi]
			var px := Pm98Trig._i32(_g(p, 4)); var py := Pm98Trig._i32(_g(p, 8))
			var d := int(sqrt(float((px - bx) * (px - bx) + (py - by) * (py - by))))
			rows.append([d, ti, pi, _g(p, 0x40), _g(p, 0x2bc), int(p.get(0x150, -1)), px, py])
	rows.sort_custom(func(a, c): return a[0] < c[0])
	for r in rows.slice(0, 6):
		print("  team%d #%d act=0x%x onpitch=%d engage=%d pos=(%d,%d) dist2ball=%d" % [
			r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[0]])


func _dump(m: Dictionary, b: Dictionary, t: int) -> void:
	var ctrl: Variant = b.get(0x40, null)
	print("--- PHASE6 t=%d  m45c=%d  m438(taker)=%s  19dc=%d  ball_ctrl_act=%s ---" % [
		t, _g(m, 0x45c), _idv(m.get(0x438, null)), _g(m, 0x19dc),
		("0x%x" % _g(ctrl, 0x40)) if ctrl is Dictionary else "none"])
	var sim: Array = m["sim"]
	for ti in range(2):
		var players: Array = (sim[ti] as Dictionary).get("players", [])
		for pi in range(players.size()):
			var p: Dictionary = players[pi]
			if _g(p, 0x2bc) == 0:  # GK slot
				var is_taker := (m.get(0x438, null) is Dictionary) and is_same(m[0x438], p)
				var is_ctrl := (ctrl is Dictionary) and is_same(ctrl, p)
				print("   GK team%d #%d act=0x%x windup(0x48)=%d 0x2c=%d 0x30=%d taker=%s ctrl=%s pos=(%d,%d,%d)" % [
					ti, pi, _g(p, 0x40), _si(p, 0x48), _g(p, 0x2c), _g(p, 0x30),
					is_taker, is_ctrl, _si(p, 4), _si(p, 8), _si(p, 0xc)])


func _idv(v: Variant) -> String:
	if v is Dictionary: return "dict"
	if v is int: return str(v)
	return "-"


# ---- byte-load helpers (copied from diag_m5_tick_trace.gd) ----
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
