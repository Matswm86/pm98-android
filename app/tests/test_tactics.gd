extends SceneTree
## Headless test for team selection + tactics (S6).
##   ~/godot462 --headless --path app --script res://tests/test_tactics.gd
## auto-pick validity per formation, ratings parity vs auto-best-XI, the
## formation/marking att-def trade-offs, manual swaps, validation, save/load,
## named presets, and that a new career routes the manager's club through its XI.

func _initialize() -> void:
	quit(0 if _run() else 1)


func _run() -> bool:
	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	if f == null:
		push_error("game_db.json missing")
		return false
	var db: Dictionary = JSON.parse_string(f.get_as_text())
	var leagues: Array = db.get("leagues", [])
	var prem: Array = []
	var league: Dictionary = {}
	for lg in leagues:
		if lg.get("id") == "eng_prem":
			league = lg
	for c in db.get("clubs", []):
		if c.get("leagueId") == "eng_prem":
			prem.append(c)
	var club: Dictionary = prem[0]
	var ok := true

	# --- auto-pick is a valid XI for every formation, with the right role counts.
	for form in Tactics.FORMATION_ORDER:
		var t := Tactics.auto_pick(club, form)
		ok = _assert(t.validate(club) == "", "%s auto-pick is a valid line-up" % form) and ok
		ok = _assert(t.xi.size() == 11, "%s XI has 11 players" % form) and ok
		var rs := t.roles()
		var lines: Array = Tactics.FORMATIONS[form]
		var n_def := rs.count("DEF")
		var n_mid := rs.count("MID")
		var n_fwd := rs.count("FWD")
		ok = _assert(n_def == int(lines[0]) and n_mid == int(lines[1]) and n_fwd == int(lines[2]),
			"%s slot roles match the shape" % form) and ok
		# no duplicate players in the XI
		var uniq: Dictionary = {}
		for id in t.xi:
			uniq[int(id)] = true
		ok = _assert(uniq.size() == 11, "%s XI has no duplicates" % form) and ok

	# --- a 4-4-2 of the best players sits ~ on the auto-best-XI scale.
	var t442 := Tactics.auto_pick(club, "4-4-2")
	var rx := t442.ratings(club)
	var auto := MatchEngine.team_ratings(club)
	ok = _assert(absf(rx["att"] - auto["att"]) < 8.0 and absf(rx["def"] - auto["def"]) < 8.0,
		"4-4-2 best XI ~ team_ratings (att %.1f/%.1f def %.1f/%.1f)" % [
			rx["att"], auto["att"], rx["def"], auto["def"]]) and ok

	# --- formation is an att/def trade-off (same squad, best XI each).
	var atk := Tactics.auto_pick(club, "4-3-3").ratings(club)
	var defv := Tactics.auto_pick(club, "5-3-2").ratings(club)
	ok = _assert(atk["att"] > defv["att"], "4-3-3 attacks more than 5-3-2 (%.1f > %.1f)" % [atk["att"], defv["att"]]) and ok
	ok = _assert(defv["def"] > atk["def"], "5-3-2 defends more than 4-3-3 (%.1f > %.1f)" % [defv["def"], atk["def"]]) and ok

	# --- marking trade-off.
	var zonal := Tactics.auto_pick(club, "4-4-2")
	var manm := Tactics.auto_pick(club, "4-4-2")
	manm.marking = "Man-to-man"
	var rz := zonal.ratings(club)
	var rm := manm.ratings(club)
	ok = _assert(rm["def"] > rz["def"] and rm["att"] < rz["att"], "man-to-man: more def, less att") and ok

	# --- TEAM-TACTICS modal levers: default is neutral (parity anchor) and each lever is
	# a bounded att/def trade-off. Base = the auto-picked 4-4-2 with all levers at default.
	var base := Tactics.auto_pick(club, "4-4-2")
	var rb := base.ratings(club)
	ok = _assert(base.mentality == "Mixed" and base.passing_pct == 50 and base.counter_pct == 50
		and base.tackling == "Medium" and base.clearances == "Short" and base.pressurise == "Midfield",
		"default tactics are the neutral/parity anchors") and ok
	# A clone with the neutral options set EXPLICITLY rates identically (anchor == [1,1]).
	var neutral := Tactics.auto_pick(club, "4-4-2")
	neutral.set_mentality("Mixed"); neutral.set_tackling("Medium")
	neutral.set_clearances("Short"); neutral.set_pressurise("Midfield")
	var rn := neutral.ratings(club)
	ok = _assert(absf(rn["att"] - rb["att"]) < 0.001 and absf(rn["def"] - rb["def"]) < 0.001,
		"neutral levers leave ratings at parity (%.2f/%.2f)" % [rb["att"], rb["def"]]) and ok

	# A single helper: clone the base, mutate one lever, rate.
	var lever := func(setup: Callable) -> Dictionary:
		var t := Tactics.auto_pick(club, "4-4-2")
		setup.call(t)
		return t.ratings(club)

	var atkr: Dictionary = lever.call(func(t): t.set_mentality("Attacking"))
	var spec: Dictionary = lever.call(func(t): t.set_mentality("Speculative"))
	ok = _assert(atkr["att"] > rb["att"] and atkr["def"] < rb["def"], "mentality Attacking: +att -def") and ok
	ok = _assert(spec["def"] > rb["def"] and spec["att"] < rb["att"], "mentality Speculative: +def -att") and ok

	var aggr: Dictionary = lever.call(func(t): t.set_tackling("Aggressive"))
	ok = _assert(aggr["def"] > rb["def"] and aggr["att"] < rb["att"], "tackling Aggressive: +def -att") and ok

	var lng: Dictionary = lever.call(func(t): t.set_clearances("Long"))
	ok = _assert(lng["def"] > rb["def"] and lng["att"] < rb["att"], "clearances Long: +def -att") and ok

	var press_hi: Dictionary = lever.call(func(t): t.set_pressurise("Opponent"))
	var press_lo: Dictionary = lever.call(func(t): t.set_pressurise("Own"))
	ok = _assert(press_hi["att"] > rb["att"] and press_hi["def"] < rb["def"], "press Opponent: +att -def") and ok
	ok = _assert(press_lo["def"] > rb["def"] and press_lo["att"] < rb["att"], "press Own: +def -att") and ok

	var longball: Dictionary = lever.call(func(t): t.step_passing(-50))   # 50 -> 0 (all long ball)
	var possession: Dictionary = lever.call(func(t): t.step_passing(50))  # 50 -> 100 (all passing)
	ok = _assert(longball["att"] > rb["att"] and longball["def"] < rb["def"], "long-ball: +att -def") and ok
	ok = _assert(possession["def"] > rb["def"] and possession["att"] < rb["att"], "passing: +def -att") and ok

	var cnt: Dictionary = lever.call(func(t): t.step_counter(50))         # 50 -> 100 (max counter)
	ok = _assert(cnt["att"] > rb["att"] and cnt["def"] < rb["def"], "counter Yes: +att -def break") and ok

	# Sliders clamp to [0,100] and long_ball is the complement.
	var clamp_t := Tactics.auto_pick(club, "4-4-2")
	clamp_t.step_passing(999); clamp_t.step_counter(-999)
	ok = _assert(clamp_t.passing_pct == 100 and clamp_t.long_ball_pct() == 0
		and clamp_t.counter_pct == 0, "sliders clamp to [0,100]; long-ball = complement") and ok

	# Levers survive the dict round-trip and the named-preset path.
	var full := Tactics.auto_pick(club, "3-5-2")
	full.set_mentality("Attacking"); full.set_tackling("Aggressive")
	full.set_clearances("Long"); full.set_pressurise("Opponent")
	full.step_passing(-30); full.step_counter(20)
	var full2 := Tactics.from_dict(full.to_dict())
	ok = _assert(full2.mentality == "Attacking" and full2.tackling == "Aggressive"
		and full2.clearances == "Long" and full2.pressurise == "Opponent"
		and full2.passing_pct == 20 and full2.counter_pct == 70,
		"levers survive to_dict/from_dict round-trip") and ok

	# --- manual swap keeps a valid 11 and no duplicates.
	var ts := Tactics.auto_pick(club, "4-4-2")
	var bench_id := _a_bench_outfielder(club, ts)
	ok = _assert(bench_id != -1, "found a benched outfielder to swap in") and ok
	if bench_id != -1:
		ts.assign(5, bench_id)   # slot 5 is a midfielder in 4-4-2
		ok = _assert(ts.xi[5] == bench_id, "swap put the player in the slot") and ok
		ok = _assert(ts.validate(club) == "", "swap kept a valid line-up") and ok
		var uniq2: Dictionary = {}
		for id in ts.xi:
			uniq2[int(id)] = true
		ok = _assert(uniq2.size() == 11, "swap left no duplicates") and ok

	# --- validation rejects bad line-ups with PM98's exact message.
	var bad := Tactics.auto_pick(club, "4-4-2")
	bad.xi.remove_at(10)   # 10 players
	ok = _assert(bad.validate(club) == Tactics.LINEUP_BAD, "short XI -> '%s'" % Tactics.LINEUP_BAD) and ok
	var bad2 := Tactics.auto_pick(club, "4-4-2")
	bad2.xi[1] = bad2.xi[0]   # a keeper in an outfield slot + duplicate
	ok = _assert(bad2.validate(club) == Tactics.LINEUP_BAD, "keeper outfield -> rejected") and ok

	# --- to_dict / from_dict round-trip.
	var t_round := Tactics.from_dict(t442.to_dict())
	ok = _assert(t_round.formation == t442.formation and t_round.xi == t442.xi
		and t_round.captain_id == t442.captain_id, "tactics survived a dict round-trip") and ok

	# --- named presets: save, list, apply.
	var p := Tactics.auto_pick(club, "3-5-2")
	p.marking = "Man-to-man"
	p.save_preset("S6 Test Preset")
	var names: Array = []
	for pr in Tactics.list_presets():
		names.append(pr.get("name"))
	ok = _assert(names.has("S6 Test Preset"), "saved preset appears in the list") and ok
	ok = _assert(names.has("4-4-2") and names.size() >= 5, "predefined formations present too") and ok
	var applied := Tactics.auto_pick(club, "4-4-2")
	applied.apply_preset({"formation": "3-5-2", "marking": "Man-to-man"}, club)
	ok = _assert(applied.formation == "3-5-2" and applied.marking == "Man-to-man"
		and applied.validate(club) == "", "apply_preset switched shape + refilled a valid XI") and ok
	DirAccess.remove_absolute("user://tactic_s6_test_preset.json")   # cleanup

	# --- a fresh career routes the manager's own club through its tactics.
	var career := Career.create(club, league, prem, leagues)
	ok = _assert(not career.tactics.is_empty(), "new career seeds tactics") and ok
	ok = _assert(Tactics.from_dict(career.tactics).validate(club) == "", "career tactics are a valid XI") and ok
	var clubs_by_id: Dictionary = {}
	for c in prem:
		clubs_by_id[int(c["id"])] = c
	# A wrecked line-up must auto-fill (engine never breaks on a bad XI).
	var wrecked := Tactics.from_dict(career.tactics)
	wrecked.xi = [wrecked.xi[0]]
	var r_auto := wrecked.ratings(club)
	var r_team := MatchEngine.team_ratings(club)
	ok = _assert(absf(r_auto["att"] - r_team["att"]) < 0.01, "invalid XI falls back to team_ratings") and ok

	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	return ok


## An outfielder in the squad who is NOT in the current XI, or -1.
func _a_bench_outfielder(club: Dictionary, t: Tactics) -> int:
	var in_xi: Dictionary = {}
	for id in t.xi:
		in_xi[int(id)] = true
	for p in club.get("players", []):
		if not p.get("isGK") and not in_xi.has(int(p["id"])):
			return int(p["id"])
	return -1


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
