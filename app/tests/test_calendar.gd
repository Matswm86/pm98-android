extends SceneTree
## Headless test for T2 #13 — the season fixtures calendar. Builds a Premier career, plays
## a few weeks, and asserts Career.season_fixtures() returns one entry per round in order,
## the played rounds carry the right mine/theirs/W-D-L (agreeing with results), the next
## round is flagged, and the rest are unplayed.
##   ~/godot462 --headless --path app --script res://tests/test_calendar.gd

const SEED := 5150


func _initialize() -> void:
	quit(0 if _run() else 1)


func _run() -> bool:
	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	var db: Dictionary = JSON.parse_string(f.get_as_text())
	var clubs_by_id: Dictionary = {}
	var prem: Array = []
	var league: Dictionary = {}
	for lg in db.get("leagues", []):
		if lg.get("id") == "eng_prem":
			league = lg
	for c in db.get("clubs", []):
		clubs_by_id[int(c["id"])] = c
		if c.get("leagueId") == "eng_prem":
			prem.append(c)

	var career := Career.create(prem[0], league, prem, db.get("leagues", []))
	var ok := true
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED

	# Before any match: one entry per round, none played, round 0 is next.
	var cal0 := career.season_fixtures()
	ok = _assert(cal0.size() == career.total_weeks(),
		"calendar has one row per round (%d)" % cal0.size()) and ok
	ok = _assert(not cal0[0]["played"] and bool(cal0[0]["is_next"]),
		"round 1 is the next fixture, unplayed") and ok
	# Ordered by round.
	var ordered := true
	for i in range(1, cal0.size()):
		if int(cal0[i]["round"]) <= int(cal0[i - 1]["round"]):
			ordered = false
	ok = _assert(ordered, "calendar rows are in round order") and ok

	# Play 5 weeks, then the first 5 are played, the 6th is next, and the played scores
	# agree with the results log.
	for _w in 5:
		career.advance_week(rng, clubs_by_id)
	var cal := career.season_fixtures()
	var played := 0
	for e in cal:
		if bool(e["played"]):
			played += 1
	ok = _assert(played == 5, "5 rounds shown as played (got %d)" % played) and ok
	ok = _assert(bool(cal[5]["is_next"]) and not bool(cal[5]["played"]),
		"the 6th round is flagged NEXT") and ok

	# Cross-check round 1's scoreline against the results log.
	var r0: Dictionary = career.results[0]
	var mine0: int = int(r0["hg"]) if bool(r0["home"]) else int(r0["ag"])
	var theirs0: int = int(r0["ag"]) if bool(r0["home"]) else int(r0["hg"])
	ok = _assert(int(cal[0]["mine"]) == mine0 and int(cal[0]["theirs"]) == theirs0,
		"calendar scoreline matches the results log (%d-%d)" % [mine0, theirs0]) and ok
	ok = _assert(cal[0]["wdl"] in ["W", "D", "L"], "played round carries a W/D/L verdict") and ok

	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	return ok


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
