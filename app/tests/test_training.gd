extends SceneTree
## Headless test for player development through training (Track A engine depth).
##   ~/godot462 --headless --path app --script res://tests/test_training.gd
## Covers the Training unit model (intensity lookups, age-driven dev direction, the
## ±1 attribute crossing + news, caps/floors, trend) and the Career integration
## (a season develops a youngster and declines a veteran, intensity changes the
## injury count, intensity persists, ages tick at rollover).

const SEED := 33445566


func _initialize() -> void:
	quit(0 if _run() else 1)


func _run() -> bool:
	var ok := true
	ok = _unit_lookups() and ok
	ok = _unit_direction() and ok
	ok = _unit_caps() and ok
	ok = _unit_trend() and ok
	ok = _career_integration() and ok
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	return ok


func _player(name_: String, age: int, ca: int) -> Dictionary:
	return {"name": name_, "age": age, "dev_progress": 0.0,
		"attrs": {"VE": ca, "RE": ca, "AG": ca, "CA": ca, "RM": ca,
			"RG": ca, "PA": ca, "TI": ca, "EN": ca, "PO": ca}}


# ---- unit: lookups -------------------------------------------------------

func _unit_lookups() -> bool:
	var ok := true
	ok = _assert(Training.intensity_factor("Intensive") > Training.intensity_factor("Normal")
		and Training.intensity_factor("Normal") > Training.intensity_factor("Light"),
		"intensity factor ordered Light<Normal<Intensive") and ok
	ok = _assert(Training.injury_multiplier("Intensive") > 1.0 and Training.injury_multiplier("Light") < 1.0,
		"intensity injury multiplier: Intensive>1, Light<1") and ok
	ok = _assert(Training.attr_name("PA") == "Passing" and Training.attr_name("VE") == "Pace",
		"attribute code names resolve") and ok
	return ok


# ---- unit: development direction by age ----------------------------------

func _unit_direction() -> bool:
	var ok := true
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	# A 19yo trained Intensive for a season climbs; a 34yo declines; a 27yo barely moves.
	var young := _player("Kid", 19, 60)
	var vet := _player("Veteran", 34, 70)
	var prime := _player("Prime", 27, 75)
	var young_news := 0
	var vet_news := 0
	for _w in 38:
		for it in Training.train_week(rng, [young], "Intensive"):
			if it["kind"] == "develop":
				young_news += 1
		for it in Training.train_week(rng, [vet], "Intensive"):
			if it["kind"] == "decline":
				vet_news += 1
		Training.train_week(rng, [prime], "Normal")
	ok = _assert(int(young["attrs"]["CA"]) > 60, "a 19yo improves over a season (CA %d->%d)" % [60, int(young["attrs"]["CA"])]) and ok
	ok = _assert(young_news > 0, "improvement fires develop news (%d items)" % young_news) and ok
	ok = _assert(int(vet["attrs"]["CA"]) < 70, "a 34yo declines over a season (CA %d->%d)" % [70, int(vet["attrs"]["CA"])]) and ok
	ok = _assert(vet_news > 0, "decline fires decline news (%d items)" % vet_news) and ok
	ok = _assert(absi(int(prime["attrs"]["CA"]) - 75) <= 2, "a 27yo holds roughly steady (CA %d)" % int(prime["attrs"]["CA"])) and ok
	# Intensive develops faster than Light for the same youngster/seed.
	var r1 := RandomNumberGenerator.new(); r1.seed = 99
	var r2 := RandomNumberGenerator.new(); r2.seed = 99
	var a := _player("A", 18, 55)
	var b := _player("B", 18, 55)
	for _w in 20:
		Training.train_week(r1, [a], "Intensive")
		Training.train_week(r2, [b], "Light")
	ok = _assert(int(a["attrs"]["CA"]) >= int(b["attrs"]["CA"]),
		"Intensive develops >= Light (%d vs %d)" % [int(a["attrs"]["CA"]), int(b["attrs"]["CA"])]) and ok
	return ok


# ---- unit: caps / floors -------------------------------------------------

func _unit_caps() -> bool:
	var ok := true
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var star := _player("Star", 18, Training.ATTR_CAP)   # already maxed
	for _w in 60:
		Training.train_week(rng, [star], "Intensive")
	var over := false
	for c in star["attrs"]:
		if int(star["attrs"][c]) > Training.ATTR_CAP:
			over = true
	ok = _assert(not over, "no attribute climbs past the cap") and ok

	var done := _player("Done", 39, Training.ATTR_FLOOR)  # already floored
	for _w in 60:
		Training.train_week(rng, [done], "Intensive")
	var under := false
	for c in done["attrs"]:
		if int(done["attrs"][c]) < Training.ATTR_FLOOR:
			under = true
	ok = _assert(not under, "no attribute drops below the floor") and ok
	# unrated player (no attrs) is skipped without error
	var fringe := {"name": "Fringe", "age": 20, "dev_progress": 0.0, "attrs": {}}
	Training.train_week(rng, [fringe], "Normal")
	ok = _assert(true, "unrated player trains without error") and ok
	return ok


# ---- unit: trend ---------------------------------------------------------

func _unit_trend() -> bool:
	var ok := true
	ok = _assert(Training.trend(_player("Y", 20, 60))["dir"] == "up", "young player trends up") and ok
	ok = _assert(Training.trend(_player("V", 33, 60))["dir"] == "down", "veteran trends down") and ok
	ok = _assert(Training.trend(_player("P", 27, 60))["dir"] == "hold", "prime player holds") and ok
	return ok


# ---- integration: a career feels training --------------------------------

func _career_integration() -> bool:
	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	if f == null:
		push_error("game_db.json missing")
		return false
	var db: Dictionary = JSON.parse_string(f.get_as_text())
	var leagues: Array = db.get("leagues", [])
	var league: Dictionary = {}
	for lg in leagues:
		if lg.get("id") == "eng_prem":
			league = lg
	var prem: Array = []
	for c in db.get("clubs", []):
		if c.get("leagueId") == "eng_prem":
			prem.append(c)
	if prem.is_empty() or league.is_empty():
		push_error("no Premier League fixture in the DB")
		return false

	var career := Career.create(prem[0], league, prem, leagues)
	var ok := true
	ok = _assert(career.training_intensity == Training.DEFAULT_INTENSITY, "career defaults to Normal training") and ok

	# dev_progress seeded on the squad.
	var seeded := true
	for p in career.my_squad():
		if not p.has("dev_progress"):
			seeded = false
	ok = _assert(seeded, "squad seeded with dev_progress") and ok

	# Cycle intensity wraps.
	career.cycle_training()
	ok = _assert(career.training_intensity == "Intensive", "Normal cycles to Intensive") and ok
	career.cycle_training()
	ok = _assert(career.training_intensity == "Light", "Intensive cycles to Light") and ok

	# Play a season on Intensive: development news accrues and at least one player's
	# ability moves from where it started.
	career.training_intensity = "Intensive"
	var before: Dictionary = {}
	for p in career.my_squad():
		before[int(p.get("id", -1))] = int((p.get("attrs", {}) as Dictionary).get("CA", 0))
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	while not career.season_over():
		career.advance_week(rng)
	var moved := 0
	var dev_news := 0
	for p in career.my_squad():
		if int((p.get("attrs", {}) as Dictionary).get("CA", 0)) != before.get(int(p.get("id", -1)), -999):
			moved += 1
	for n in career.news_log:
		if n is Dictionary and (n.get("kind") == "develop" or n.get("kind") == "decline"):
			dev_news += 1
	ok = _assert(moved > 0, "a season of training moves squad ability (%d players changed)" % moved) and ok
	ok = _assert(dev_news > 0, "development surfaces as club news (%d items)" % dev_news) and ok

	# Intensity raises injury risk: with identical rng draws over the same always-fit XI,
	# the Intensive multiplier injures a strict superset of Light (so count is >=). Done at
	# the Availability layer so the comparison is deterministic, not rng-alignment-dependent.
	var inj_light := _roll_injuries(Training.injury_multiplier("Light"))
	var inj_hard := _roll_injuries(Training.injury_multiplier("Intensive"))
	ok = _assert(inj_hard > inj_light, "Intensive injury risk > Light (%d vs %d over 300 matches)" % [inj_hard, inj_light]) and ok

	# Season rollover: ages tick and intensity persists through save/load.
	var age_before := int((career.my_squad()[0] as Dictionary).get("age", 0)) if not career.my_squad().is_empty() else 0
	career.advance_season(leagues)
	var age_after := int((career.my_squad()[0] as Dictionary).get("age", 0)) if not career.my_squad().is_empty() else 0
	ok = _assert(age_after == age_before + 1, "squad ages a year at rollover (%d->%d)" % [age_before, age_after]) and ok

	var path := "user://career_train_test.json"
	career.training_intensity = "Light"
	career.save(path)
	var loaded := Career.load_save(path)
	ok = _assert(loaded != null and loaded.training_intensity == "Light", "training intensity survives round-trip") and ok
	return ok


## Injuries from 300 match-rolls of an always-fit XI at a given injury multiplier, with
## a fixed rng seed so the two multipliers see identical draws (a clean superset compare).
func _roll_injuries(mult: float) -> int:
	var rng := RandomNumberGenerator.new()
	rng.seed = 50607080
	var n := 0
	for _m in 300:
		var xi: Array = []
		for i in 11:
			xi.append({"name": "P%d" % i, "injured_weeks": 0, "suspended_weeks": 0, "yellows": 0})
		for item in Availability.roll_match(rng, xi, mult):
			if item["kind"] == "injury":
				n += 1
	return n


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
