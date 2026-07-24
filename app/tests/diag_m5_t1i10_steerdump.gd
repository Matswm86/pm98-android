extends SceneTree
## M5 s53: dump the PORT's FUN_005b1420 arm inputs for t1.i10 over clk 628-652, in the exact
## shape the live-silicon capture now records (m5_rsp_capture.py s53 tail + tools/re/m5_b1420_arm_solve.py).
##
## s52 closed every b0040 INPUT as byte-identical yet silicon applied heading 765 where the port
## applies 34078, so the open question is whether the live engine ran B0040 for this player at all.
## FUN_005b1420 dispatches B0040 only when `p == *(gs+0x204) && ball+0x40 == 0`, so the designate
## (+0x204, FUN_005b8a60's in-possession pick) plus the carrier decide the arm. This prints both,
## per tick, next to the applied-heading ladder 0x34/0x64/0x68 — nothing else is needed to compare.
##
## Run: ~/godot462 --headless --path app --script res://tests/diag_m5_t1i10_steerdump.gd

const REF_DIR := "/home/mats/MWM-AI/data/pm98-m4-oracle/capture2"
const STRUCT_JSON := REF_DIR + "/frame0_struct_import.json"
const FRAME0_SEED := 0xea0d2a8d
const TICK_CAP := 1400
const CLK_LO := 636
const CLK_HI := 645
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
	print("# PORT %s — EVERY steer_8f20 entry per tick (s53 handoff step 3)." % who)
	print("# The b1420 designate gs+0x204 HOLDS on this player in live silicon at every clk 630-657,")
	print("# so both builds dispatch B0040. What is left is WHICH steer reaches FUN_005a8f20 first:")
	print("# the +0x2d7 guard makes the FIRST caller in the tick the only one that moves the player.")
	print("# clk | 0x34   0x64   0x68 | steers: heading guard APPLIED/noop <- call site")
	var t := 0
	while t < TICK_CAP:
		var clk_pre := _g(m, 0x450)
		var in_win := clk_pre >= CLK_LO and clk_pre <= CLK_HI
		if in_win:
			MatchEngine.Pm98Rng._log_on = true
			Pm98Movement.steer8f20_trace.clear()
		var ret := Pm98Driver.tick(m, rng)
		t += 1
		if ret == 0:
			m[0x1a1e] = 1
		var clk := _g(m, 0x450)
		if not in_win:
			if clk > CLK_HI:
				break
			continue
		MatchEngine.Pm98Rng._log_on = false
		var mine := []
		for e in Pm98Movement.steer8f20_trace:
			var d: Dictionary = e
			if str(d["who"]).strip_edges() == who:
				mine.append("%d g=%d %s <- %s" % [int(d["heading"]), int(d["guard"]),
					"APPLIED" if bool(d["applied"]) else "noop", str(d["sites"])])
		print("  %d | %5d %5d %6d | %d steer(s)" % [clk, _g(p, 0x34) & 0xffff,
			_g(p, 0x64) & 0xffff, Pm98Trig._i32(_g(p, 0x68)), mine.size()])
		for s in mine:
			print("        %s" % s)
		if clk > CLK_HI:
			break


## A role slot as its roster index (the port stores indices; -1/absent = unset).
func _slot(gs: Dictionary, off: int) -> String:
	var v = gs.get(off, null)
	if v is int:
		return str(v)
	if v is Dictionary:
		return "D"
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
