extends SceneTree
## Headless test for T2 #5 — stadium WORKS expansion. Builds a Premier career, starts a
## ground expansion, plays the build weeks, and asserts the capacity rises, the bigger gate
## feeds weekly_net, the guards (in-progress / ceiling / affordability) hold, the save
## round-trips the new state, and StadiumScreen's WORKS/RETURN hit-testing routes correctly.
##   ~/godot462 --headless --path app --script res://tests/test_stadium_works.gd

const SEED := 4242


func _initialize() -> void:
	quit(0 if await _run() else 1)


func _run() -> bool:
	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	if f == null:
		push_error("game_db.json missing")
		return false
	var db: Dictionary = JSON.parse_string(f.get_as_text())
	var leagues: Array = db.get("leagues", [])
	var clubs_by_id: Dictionary = {}
	var prem: Array = []
	var league: Dictionary = {}
	for lg in leagues:
		if lg.get("id") == "eng_prem":
			league = lg
	for c in db.get("clubs", []):
		clubs_by_id[int(c["id"])] = c
		if c.get("leagueId") == "eng_prem":
			prem.append(c)

	var career := Career.create(prem[0], league, prem, leagues)
	var ok := true

	var cap0: int = career.stadium_capacity
	var net0: int = career.weekly_net
	ok = _assert(cap0 > 0, "career seeded stadium capacity (%d)" % cap0) and ok
	career.cash = 20_000_000   # guarantee affordability

	# Start a +5,000 expansion that completes in 3 weeks.
	ok = _assert(career.start_works(5000, 3_900_000, 3), "works started") and ok
	ok = _assert(career.cash == 20_000_000 - 3_900_000, "cost paid up front (cash £%d)" % career.cash) and ok
	ok = _assert(not career.works.is_empty() and career.stadium_capacity == cap0,
		"capacity unchanged until the build completes") and ok
	ok = _assert(not career.start_works(2000, 1_600_000, 6), "second works refused while one is running") and ok

	# Play the build weeks; the expansion lands when weeks_left hits 0.
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	for _w in 3:
		if career.season_over():
			break
		career.advance_week(rng, clubs_by_id)
	ok = _assert(career.works.is_empty(), "works cleared on completion") and ok
	ok = _assert(career.stadium_capacity == cap0 + 5000,
		"capacity rose by the built amount (%d -> %d)" % [cap0, career.stadium_capacity]) and ok
	ok = _assert(career.weekly_net > net0,
		"bigger gate lifts weekly_net (£%d -> £%d)" % [net0, career.weekly_net]) and ok

	# Finance summary reflects the larger ground (gate income up).
	var sm := FinanceModel.summary({"capacity": career.stadium_capacity, "players": career.my_squad()}, career.tier)
	ok = _assert(int(sm["capacity"]) == cap0 + 5000, "finance sees the expanded capacity") and ok

	# Ceiling guard: a build that would breach MAX_STADIUM is refused.
	career.stadium_capacity = Career.MAX_STADIUM - 1000
	ok = _assert(not career.start_works(5000, 100, 4), "expansion past the ceiling refused") and ok

	# Save / load round-trips the new state.
	var mid := Career.create(prem[1], league, prem, leagues)
	mid.cash = 20_000_000
	mid.start_works(2000, 1_600_000, 5)
	var path := "user://stadium_works_test.json"
	mid.save(path)
	var loaded := Career.load_save(path)
	ok = _assert(loaded != null and loaded.stadium_capacity == mid.stadium_capacity
		and not loaded.works.is_empty() and int(loaded.works["added"]) == 2000,
		"stadium state survived save/load") and ok

	# StadiumScreen WORKS / RETURN hit-testing.
	var scr: StadiumScreen = load("res://scenes/StadiumScreen.gd").new()
	get_root().add_child(scr)
	scr.size = Vector2(640, 480)
	for _i in 2:
		await process_frame
	scr.setup("ARSENAL", "", "1997-98", "Highbury", 38000, 23000, 15000, 1400, "+5,000 in 3 wk")
	ok = _assert(scr._hit(StadiumScreen.BTN_WORKS.get_center()) == "works", "WORKS button hit-tests") and ok
	ok = _assert(scr._hit(StadiumScreen.BTN_RETURN.get_center()) == "return", "RETURN button hit-tests") and ok
	# Empty-space taps are a no-op — the screen exits via RETURN only (the old
	# tap-anywhere dismiss bounced players to the hub mid-reading).
	ok = _assert(scr._hit(Vector2(320, 250)) == "", "an empty-space tap is a no-op") and ok
	scr.queue_free()

	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	return ok


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
