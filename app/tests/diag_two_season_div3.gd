extends SceneTree
## TWO-SEASON DIAGNOSTIC — a Third Division career driven headless end to end, covering
## the 2026-08-26 user reports on the real model:
##   1. FINES: floodlights BUILT in week 0 must never fine again (the plural-key read).
##   2. GROUND SEED: promotion must not re-seed the ground from the new division.
##   3. AGEING: the WORLD ages with the season year (GameDB.stamp_season_ages) — own
##      squad, live-division rivals, static English clubs, foreign clubs (Aimar/River).
##   4. R13 division finals: each OTHER division's final table queues ONCE, as that
##      division finishes (the Premier's 38 rounds end weeks before a Div 3 season).
##
##   ~/godot462 --headless --path app --script res://tests/diag_two_season_div3.gd

const SEED := 19980826


func _initialize() -> void:
	quit(0 if _run() else 1)


func _sample(tag: String, p: Dictionary) -> String:
	return "%s: %s age=%d" % [tag, p.get("name", "?"), int(p.get("age", -1))]


func _run() -> bool:
	var gdb: Node = get_root().get_node_or_null("GameDB")
	if gdb == null:
		push_error("GameDB autoload missing")
		return false
	if (gdb.clubs as Array).is_empty():
		gdb._load()
	var leagues: Array = gdb.leagues
	var all: Array = gdb.clubs
	var clubs_by_id: Dictionary = gdb.clubs_by_id

	var league: Dictionary = {}
	var div3: Array = []
	for lg in leagues:
		if lg.get("id") == "eng_div3":
			league = lg
	for c in all:
		if c.get("leagueId") == "eng_div3":
			div3.append(c)
	if league.is_empty() or div3.is_empty():
		push_error("no eng_div3 league/clubs in game_db")
		return false
	div3.sort_custom(func(a, b): return a["name"] < b["name"])

	# The full pyramid context, the same construction as Main._pyramid_context.
	var divs: Array = []
	for lg in leagues:
		var members: Array = []
		for c in all:
			if c.get("leagueId") == lg.get("id"):
				members.append(c)
		divs.append({"league_id": str(lg["id"]), "name": str(lg["name"]),
			"tier": int(lg.get("tier", 0)), "clubs": members})
	var seeds: Dictionary = {}
	if FileAccess.file_exists("res://data/season_seed_1997.json"):
		var sf := FileAccess.open("res://data/season_seed_1997.json", FileAccess.READ)
		var parsed: Variant = JSON.parse_string(sf.get_as_text())
		if typeof(parsed) == TYPE_DICTIONARY:
			seeds = parsed.get("seeds", {})

	# Main._begin_career's order: stamp year-1 ages BEFORE create (rosters deep-copy).
	gdb.stamp_season_ages(1997)
	var club: Dictionary = div3[0]
	var career := Career.create(club, league, div3, leagues, {"divisions": divs, "seeds": seeds})
	career.players_age = true
	career.manager_name = "Diag"
	career.youth_pool = Youth.pool_of(clubs_by_id)
	print("=== %s (%s) tier=%d cash=£%d ===" % [career.club_name, career.league_name,
		career.tier, career.cash])
	print("ground_seed at create: %s" % [career.ground_seed])

	var ok := true
	# 1. Build the floodlights NOW (completed work, the state after the builders leave).
	career._complete_work({"cat": "facility", "key": 0, "label": "FLOODLIGHTS",
		"effect": {"grade": 1}})

	# Age witnesses BEFORE any rollover.
	var own: Dictionary = career.my_squad()[0]
	var static_eng: Dictionary = {}
	for c in all:
		if str(c.get("name", "")).to_lower().contains("manchester utd"):
			static_eng = c["players"][0]
	var aimar: Dictionary = {}
	for c in all:
		for p in c.get("players", []):
			if str(p.get("name", "")).to_lower() == "aimar":
				aimar = p
	print("-- ages at career start --")
	for s in [_sample("own", own), _sample("staticManUtd", static_eng),
			_sample("Aimar(River)", aimar)]:
		print("  " + s)
	ok = _assert(int(aimar.get("age", -1)) == 18, "Aimar starts 1997-98 aged 18") and ok

	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var fines_seen: Array = []
	var seed0: Array = career.ground_seed.duplicate()
	for season_i in [1, 2]:
		var weeks := 0
		var finals_log: Array = []
		while not career.season_over():
			career.advance_week(rng, clubs_by_id)
			weeks += 1
			for fine in career.take_fines():
				fines_seen.append("S%d w%d: %s" % [season_i, weeks,
					(fine as Dictionary).get("message", "?").replace("\n", " ")])
			# The hub drains due final tables the same week they queue (R13).
			var t := career.take_division_final()
			while t >= 0:
				finals_log.append([weeks, t])
				t = career.take_division_final()
			if weeks > 80:
				push_error("season %d never ended" % season_i)
				return false
		print("season %d over after %d weeks in %s" % [season_i, weeks, career.league_name])
		print("  R13 finals (week, tier): %s  shown=%s" % [finals_log,
			career.division_finals_shown])
		# Every OTHER tracked division presented exactly once, none left for a
		# season-end duplicate; the Premier's 38 rounds finish well before week 40.
		var tiers_seen: Array = []
		for e in finals_log:
			tiers_seen.append(int((e as Array)[1]))
		ok = _assert(tiers_seen.size() == 3 and not tiers_seen.has(career.tier),
			"S%d: the three OTHER divisions' finals each queued once" % season_i) and ok
		for e2 in finals_log:
			if int((e2 as Array)[1]) == 1:
				ok = _assert(int((e2 as Array)[0]) <= 40,
					"S%d: the Premier's table came as it finished (week %d <= 40)" %
					[season_i, int((e2 as Array)[0])]) and ok
		# Main._season_end_final_tables would now show ONLY the manager's own tier.
		var dup := 0
		for t2 in [4, 3, 2, 1]:
			if t2 != career.tier and career.has_division(t2) \
					and not career.division_finals_shown.has(t2):
				dup += 1
		ok = _assert(dup == 0,
			"S%d: season-end walk re-shows no lower-division table" % season_i) and ok
		# Main._next_season's order: stamp the COMING year, then roll over.
		gdb.stamp_season_ages(1996 + career.year + 1)
		career.advance_season(leagues, rng)
		print("-- after rollover %d: %s (tier %d), season %s --" % [season_i,
			career.league_name, career.tier, career.season])
		var own2: Array = career.my_squad()
		for s2 in [_sample("own[0]", own2[0] if not own2.is_empty() else {}),
				_sample("staticManUtd", static_eng), _sample("Aimar(River)", aimar)]:
			print("  " + s2)

	ok = _assert(int(aimar.get("age", -1)) == 20,
		"Aimar aged 18 -> 20 across two rollovers (got %d)" % int(aimar.get("age", -1))) and ok
	ok = _assert(fines_seen.is_empty(),
		"BUILT floodlights: zero fines across two seasons (got %d)" % fines_seen.size()) and ok
	for s3 in fines_seen:
		print("  " + s3)
	ok = _assert(career.ground_seed == seed0,
		"ground_seed unchanged across two rollovers") and ok
	ok = _assert(career.ground_grade("facility", 0, -1) == 1,
		"the built floodlight grade survives both rollovers") and ok

	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	return ok


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
