extends SceneTree
## M5 clk-12 divergence probe: instrument Villa slot-8 (the kickoff RECEIVER) around collection.
## Dumps per tick (clk 6..20): receiver pos/facing(+0x34)/action(+0x40)/chase(+0x63)/anchor(+0x3a4)/
## team(+0x2b8), ball pos+vel+ctrl, m+0x19a0 orient, and the move65a0_trace tag for the receiver.
## Run: ~/godot462 --headless --path app --script res://tests/diag_m5_receiver.gd

const REF_DIR := "/home/mats/MWM-AI/data/pm98-m4-oracle/capture2"
const STRUCT_JSON := REF_DIR + "/frame0_struct_import.json"
const FRAME0_SEED := 0xea0d2a8d
const TICK_CAP := 45
var _prevx := 0
var _prevy := 0


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

	var villa: Array = (teams[0] as Dictionary).get("players", [])
	var recv: Dictionary = villa[8]
	var b := ball
	_prevx = Pm98Trig._i32(_si(recv, 4)); _prevy = Pm98Trig._i32(_si(recv, 8))

	print("line(+0x1820)=%d  half orient(+0x19a0)=%d" % [Pm98Trig._i32(_g(m, 0x1820)), _g(m, 0x19a0)])
	print("recv slot-8 anchor(+0x3a4)=%d team(+0x2b8)=%d" % [Pm98Trig._i32(_g(recv, 0x3a4)), _g(recv, 0x2b8)])
	var t := 0
	while t < TICK_CAP:
		var ret := Pm98Driver.tick(m, rng)
		t += 1
		if ret == 0:
			m[0x1a1e] = 1
		var clk := _g(m, 0x450)
		if clk > 16:
			continue
		var ctrl_v: Variant = b.get(0x40, null)
		var is_carrier := ctrl_v is Dictionary and is_same(ctrl_v, recv)
		if clk >= 6 and clk <= 8:
			var tbline := "   TRAJBUF: "
			for i in 16:
				var off := 0x114 + i * 0xc
				tbline += "[%d](%d,%d) " % [i, Pm98Trig._i32(_g(b, off)), Pm98Trig._i32(_g(b, off + 4))]
			print(tbline)
		print("   ball+0x34=0x%x  ball vel(%d,%d)  ball+0x54=%d" % [_g(b, 0x34) & 0xffff, Pm98Trig._i32(_g(b, 0x20)), Pm98Trig._i32(_g(b, 0x24)), _g(b, 0x54)])
		var tgt: Array = Pm98Movement._b0040_target(recv)
		var tgt_ang := Pm98Trig.atan_angle(Pm98Trig._i32(int(tgt[0]) - _si(recv, 4)), Pm98Trig._i32(int(tgt[1]) - _si(recv, 8))) & 0xffff
		print("   b0040_tgt=(%d,%d) ang=0x%x | trajbuf[0x114]=(%d,%d) [0x120]=(%d,%d)" % [
			int(tgt[0]), int(tgt[1]), tgt_ang,
			Pm98Trig._i32(_g(b, 0x114)), Pm98Trig._i32(_g(b, 0x118)),
			Pm98Trig._i32(_g(b, 0x120)), Pm98Trig._i32(_g(b, 0x124))])
		var dir2ball := Pm98Trig.atan_angle(Pm98Trig._i32(_g(b, 4) - _si(recv, 4)), Pm98Trig._i32(_g(b, 8) - _si(recv, 8))) & 0xffff
		print("   dir2ball=0x%x  recvΔ=(%d,%d)  p388=%d pace0x2c8?=%d" % [dir2ball, Pm98Trig._i32(_si(recv, 4)) - _prevx, Pm98Trig._i32(_si(recv, 8)) - _prevy, _g(recv, 0x388), _g(recv, 0x2c8)])
		_prevx = Pm98Trig._i32(_si(recv, 4)); _prevy = Pm98Trig._i32(_si(recv, 8))
		print("clk=%2d ph=%d | BALL(%d,%d) v(%d,%d) ctrl=%s b68=%d b6c=%d b9c/a0=(%d,%d) b4c=%s | RECV pos(%d,%d) face=0x%x act=0x%x c63=%d p80=%d p84=%d p94/98=(%d,%d) p66=0x%x carr=%s" % [
			clk, _g(m, 0x448),
			Pm98Trig._i32(_g(b, 4)), Pm98Trig._i32(_g(b, 8)),
			Pm98Trig._i32(_g(b, 0x20)), Pm98Trig._i32(_g(b, 0x24)),
			("recv" if is_carrier else _who(ctrl_v, villa)),
			_g(b, 0x68), _g(b, 0x6c),
			Pm98Trig._i32(_g(b, 0x9c)), Pm98Trig._i32(_g(b, 0xa0)),
			_who(b.get(0x4c, null), villa),
			Pm98Trig._i32(_g(recv, 4)), Pm98Trig._i32(_g(recv, 8)),
			_g(recv, 0x34) & 0xffff, _g(recv, 0x40), _g(recv, 0x63) & 0xff,
			_g(recv, 0x80), _g(recv, 0x84),
			Pm98Trig._i32(_g(recv, 0x94)), Pm98Trig._i32(_g(recv, 0x98)),
			_g(recv, 0x66) & 0xffff,
			("Y" if is_carrier else "n")])


func _who(v: Variant, villa: Array) -> String:
	if not (v is Dictionary):
		return str(v)
	for i in villa.size():
		if is_same(villa[i], v):
			return "V%d" % i
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
