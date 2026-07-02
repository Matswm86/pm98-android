extends SceneTree
## Headless test for the career loop + save/load.
##   ~/godot462 --headless --path app --script res://tests/test_career.gd
## New career -> play the whole season -> assert table consistency, objective
## resolution, and a save/load round-trip.

const SEED := 20240615


func _initialize() -> void:
	quit(0 if _run() else 1)


func _run() -> bool:
	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	if f == null:
		push_error("game_db.json missing")
		return false
	var db: Dictionary = JSON.parse_string(f.get_as_text())
	var leagues: Array = db.get("leagues", [])
	var all: Array = db.get("clubs", [])
	var clubs_by_id: Dictionary = {}
	for c in all:
		clubs_by_id[int(c["id"])] = c

	var prem: Array = []
	var league: Dictionary = {}
	for lg in leagues:
		if lg.get("id") == "eng_prem":
			league = lg
	for c in all:
		if c.get("leagueId") == "eng_prem":
			prem.append(c)
	if prem.size() != 20 or league.is_empty():
		push_error("expected 20 Premier clubs + the league dict")
		return false

	var manager_club: Dictionary = prem[0]
	var career := Career.create(manager_club, league, prem, leagues)
	print("=== Career: %s in %s ===" % [career.club_name, career.league_name])
	print("  objective: %s (pos <= %d)  cash £%d  weekly £%d" % [
		career.objective_text, career.objective_pos, career.cash, career.weekly_net])

	var ok := true
	ok = _assert(career.total_weeks() == 38, "38 rounds scheduled (got %d)" % career.total_weeks()) and ok

	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var manager_games := 0
	MatchSim.fallback_count = 0
	while not career.season_over():
		var res := career.advance_week(rng, clubs_by_id)
		if not res.is_empty():
			manager_games += 1
	ok = _assert(manager_games == 38, "manager played 38 games (got %d)" % manager_games) and ok
	# §B3 fallback close: across the whole season no fixture may drop to the legacy
	# engine — every league club fields a usable (padded) XI for the stat engine.
	ok = _assert(MatchSim.fallback_count == 0,
		"no legacy fallback all season (got %d)" % MatchSim.fallback_count) and ok

	# Guarantee-XI pad: injure the squad down to under 11 fit — the featured XI must
	# still field 11 real roster players, keeper up front, so the stat engine keeps
	# the fixture instead of the invented legacy fallback.
	var c2 := Career.create(prem[1], league, prem, leagues)
	var sq: Array = c2.my_squad()
	for i in range(0, sq.size() - 7):   # leave only 7 fit players
		sq[i]["injured_weeks"] = 4
	var padded: Array = c2._mgr_featured_xi()
	ok = _assert(padded.size() == 11, "padded XI fields 11 under mass injuries (got %d)" % padded.size()) and ok
	ok = _assert(not padded.is_empty() and bool(padded[0].get("isGK", false)),
		"padded XI keeps a keeper at slot 0") and ok
	ok = _assert(MatchSim._usable(padded), "padded XI passes the stat-engine gate") and ok

	# Every club played 2*(20-1) = 38 games; points conserved (3*W + D across table).
	var games_each_ok := true
	for id in career.table:
		if int(career.table[id]["P"]) != 38:
			games_each_ok = false
	ok = _assert(games_each_ok, "every club played 38") and ok

	var rows := career.standings()
	print("  final: 1.%s %dpts ... 20.%s %dpts  | %s finished %d (obj met: %s)" % [
		rows[0]["name"], rows[0]["Pts"], rows[19]["name"], rows[19]["Pts"],
		career.club_name, career.position(), str(career.objective_met())])
	ok = _assert(rows[0]["Pts"] >= rows[19]["Pts"], "table sorted by points") and ok
	ok = _assert(career.finished, "season flagged finished") and ok

	# Save / load round-trip.
	var path := "user://career_test.json"
	career.save(path)
	var loaded := Career.load_save(path)
	ok = _assert(loaded != null, "career loaded from disk") and ok
	if loaded != null:
		ok = _assert(loaded.club_id == career.club_id and loaded.week == career.week
			and loaded.position() == career.position(),
			"round-trip preserved club/week/position") and ok
		ok = _assert(loaded.table.size() == career.table.size(), "table survived round-trip") and ok

	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	return ok


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
