extends SceneTree
## Headless test for the PRESEASON friendly sim (docs/re/pretemporada_screen_re.md).
##   ~/godot462 --headless --path app --script res://tests/test_friendly.gd
## Picks -> pending gate -> play through the same engine path -> league table
## untouched -> friendlies exhaust -> league round 1 proceeds -> save round-trip.

const SEED := 20260704


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
	var by_id: Dictionary = {}
	for c in all:
		by_id[int(c["id"])] = c

	var prem: Array = []
	var league: Dictionary = {}
	for lg in leagues:
		if lg.get("id") == "eng_prem":
			league = lg
	for c in all:
		if c.get("leagueId") == "eng_prem":
			prem.append(c)

	var career := Career.create(prem[0], league, prem, leagues)
	var ok := true

	# The run-2 walked schedule: Juventus away (Fri 1), Barcelona away (Mon 4),
	# Sao Paulo home (Wed 6) — Europe-tab rivals host, the S.AMERICA pick visits.
	career.preseason_rivals = [
		{"date": "1997-08-01", "club_id": 1021, "name": "JUVENTUS", "home": false},
		{"date": "1997-08-04", "club_id": 1000, "name": "F.C. BARCELONA", "home": false},
		{"date": "1997-08-06", "club_id": 1301, "name": "SAO PAULO", "home": true},
	]

	var rng := RandomNumberGenerator.new()
	rng.seed = SEED

	# Gate: pending friendly first, league untouched while friendlies run.
	ok = _assert(not career.pending_friendly().is_empty(), "friendly pending at week 0") and ok
	ok = _assert(int(career.pending_friendly().get("club_id", -1)) == 1021,
		"first pending = Juventus (slot order)") and ok

	var played: Array = []
	while not career.pending_friendly().is_empty():
		var pick := career.pending_friendly()
		var rid := int(pick.get("club_id", -1))
		var rival: Dictionary = by_id.get(rid, {})
		var res := career.play_friendly(rng, rival)
		ok = _assert(not res.is_empty(), "friendly vs %s returned a result" % pick.get("name")) and ok
		ok = _assert(bool(res.get("friendly", false)), "result flagged friendly") and ok
		ok = _assert(bool(res.get("manager_home", false)) == bool(pick.get("home", false)),
			"home/away matches the pick (%s)" % pick.get("name")) and ok
		var mine_home := int(res.get("home_id", -1)) == career.club_id
		ok = _assert(mine_home == bool(pick.get("home", false)),
			"fixture ids honour the pick side (%s)" % pick.get("name")) and ok
		ok = _assert(int(res.get("hg", -1)) >= 0 and int(res.get("ag", -1)) >= 0,
			"sane scoreline %d-%d" % [int(res.get("hg", -1)), int(res.get("ag", -1))]) and ok
		played.append(res)

	ok = _assert(played.size() == 3, "all 3 friendlies played (got %d)" % played.size()) and ok
	ok = _assert(career.friendlies_played == 3, "friendlies_played counter = 3") and ok
	ok = _assert(career.friendly_results.size() == 3, "friendly_results stored") and ok
	ok = _assert(career.week == 0, "league week untouched by friendlies") and ok

	# The league table must be a clean slate — friendlies never touch it.
	var table_clean := true
	for id in career.table:
		if int(career.table[id]["P"]) != 0:
			table_clean = false
	ok = _assert(table_clean, "league table untouched (all P == 0)") and ok
	ok = _assert(career.results.is_empty(), "league results feed untouched") and ok

	# Friendlies exhausted -> league round 1 proceeds normally.
	var res1 := career.advance_week(rng, by_id)
	ok = _assert(not res1.is_empty(), "league round 1 played after friendlies") and ok
	ok = _assert(career.week == 1, "league week advanced to 1") and ok
	ok = _assert(career.pending_friendly().is_empty(), "no pending friendly after kick-off") and ok

	# Save / load round-trip preserves the friendly state.
	var path := "user://friendly_test.json"
	career.save(path)
	var loaded := Career.load_save(path)
	ok = _assert(loaded != null, "career loaded from disk") and ok
	if loaded != null:
		ok = _assert(loaded.friendlies_played == 3, "friendlies_played survived round-trip") and ok
		ok = _assert((loaded.friendly_results as Array).size() == 3,
			"friendly_results survived round-trip") and ok
		ok = _assert(loaded.pending_friendly().is_empty(),
			"loaded career has no pending friendly") and ok

	# Mid-preseason persistence: a career saved with 1 of 2 played resumes at pick 2.
	var c2 := Career.create(prem[1], league, prem, leagues)
	c2.preseason_rivals = [
		{"date": "1997-08-01", "club_id": 1021, "name": "JUVENTUS", "home": false},
		{"date": "1997-08-04", "club_id": 1000, "name": "F.C. BARCELONA", "home": false},
	]
	var r2 := c2.play_friendly(rng, by_id.get(1021, {}))
	ok = _assert(not r2.is_empty(), "second career played friendly 1") and ok
	c2.save(path)
	var l2 := Career.load_save(path)
	ok = _assert(l2 != null and int(l2.pending_friendly().get("club_id", -1)) == 1000,
		"mid-preseason resume points at Barcelona") and ok

	# Season rollover clears the friendly slate (no season-2 re-pick UI).
	while not career.season_over():
		career.advance_week(rng, by_id)
	career.advance_season(leagues, rng)
	ok = _assert(career.preseason_rivals.is_empty() and career.friendlies_played == 0
		and career.friendly_results.is_empty(), "advance_season cleared the friendly slate") and ok

	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	return ok


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
