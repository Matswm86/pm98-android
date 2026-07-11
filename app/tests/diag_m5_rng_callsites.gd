extends SceneTree
## M5 RNG DRAW-COUNT DESYNC localizer. Byte-loads the capture2 frame-0 (seed 0xea0d2a8d,
## the real-engine reference), drives Pm98Driver.tick, and tallies WHICH call-site draws RNG
## each tick. The reference (capture2/timeline.jsonl) draws ~1 RNG/tick in a settled dribble
## (clk ~49-60); the port draws ~5/tick. This dumps the per-tick call-site breakdown so the
## over-drawing leaf is named. Clean window (clk 5-12, port==ref lockstep) is the control.
##
## Run: ~/godot462 --headless --path app --script res://tests/diag_m5_rng_callsites.gd

const REF_DIR := "/home/mats/MWM-AI/data/pm98-m4-oracle/capture2"
const STRUCT_JSON := REF_DIR + "/frame0_struct_import.json"
const FRAME0_SEED := 0xea0d2a8d
const TICK_CAP := 620
# clk windows to dump per-tick call-site detail (control vs over-draw)
const DUMP_LO := 0    # dump per-tick detail for clk in [DUMP_LO, DUMP_HI]
const DUMP_HI := 60


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

	var b := _ball(m)
	MatchEngine.Pm98Rng._log_on = true
	var agg_clean := {}       # call-site -> count over clean window
	var agg_over := {}        # call-site -> count over over-draw window
	var t := 0
	while t < TICK_CAP:
		MatchEngine.Pm98Rng._draws.clear()
		var ret := Pm98Driver.tick(m, rng)
		t += 1
		if ret == 0:
			m[0x1a1e] = 1
		var clk := _g(m, 0x450)
		var draws: Array = MatchEngine.Pm98Rng._draws.duplicate()
		if clk >= DUMP_LO and clk <= DUMP_HI:
			var tally := {}
			for tag in draws:
				tally[tag] = int(tally.get(tag, 0)) + 1
			var bx := Pm98Trig._i32(_g(b, 4))
			var by := Pm98Trig._i32(_g(b, 8))
			var ctrl_v: Variant = b.get(0x40, null)
			var ctrl := "p%d" % (ctrl_v as Dictionary).get(0x2c8, -1) if ctrl_v is Dictionary else "-"
			print("clk=%3d tick=%3d ndraws=%d ball=(%d,%d) carrier=%s" % [clk, t, draws.size(), bx, by, ctrl])
			var keys := tally.keys()
			keys.sort()
			for kk in keys:
				print("      %3dx  %s" % [tally[kk], kk])
			if clk >= 5 and clk <= 12:
				for kk in tally:
					agg_clean[kk] = int(agg_clean.get(kk, 0)) + int(tally[kk])
			elif clk >= 44 and clk <= 60:
				for kk in tally:
					agg_over[kk] = int(agg_over.get(kk, 0)) + int(tally[kk])
	MatchEngine.Pm98Rng._log_on = false

	print("\n==== AGGREGATE call-site draw counts ====")
	print("-- CLEAN window clk 5-12 (port==ref lockstep) --")
	_dump_bucket(agg_clean)
	print("-- OVER-DRAW window clk 44-60 (port ~5/tick vs ref ~1/tick) --")
	_dump_bucket(agg_over)
	print("\n-- call-sites present in OVER but ~absent in CLEAN (the suspects) --")
	var ck := agg_over.keys()
	ck.sort()
	for kk in ck:
		var co := int(agg_over.get(kk, 0))
		var cc := int(agg_clean.get(kk, 0))
		if co >= 4 and cc == 0:
			print("   OVER=%3d CLEAN=%3d  %s" % [co, cc, kk])


func _dump_bucket(bucket: Dictionary) -> void:
	var keys := bucket.keys()
	keys.sort_custom(func(a, b): return int(bucket[a]) > int(bucket[b]))
	for kk in keys:
		print("   %4dx  %s" % [bucket[kk], kk])


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
