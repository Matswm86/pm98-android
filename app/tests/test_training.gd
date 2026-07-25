extends SceneTree
## Headless test for the TRAINING lever + its Career integration.
##   ~/godot462 --headless --path app --script res://tests/test_training.gd
## The DEVELOPMENT MODEL itself is `test_training_exact.gd` — a clause-by-clause check
## against FUN_00582760. What is left here is the surrounding machinery: the intensity
## lookups (which now only feed the injury roll), `trend()`'s screen arrows, and the
## Career loop (a season of FOCUSED training moves the squad, intensity changes the
## injury count and persists, ages tick at rollover).

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
	var a := {"VE": ca, "RE": ca, "AG": ca, "CA": ca, "RM": ca,
		"RG": ca, "PA": ca, "TI": ca, "EN": ca, "PO": ca}
	return {"id": 0, "name": name_, "age": age, "fitness": 70,
		"attrs": a, "attrs_base": a.duplicate()}


# ---- unit: lookups -------------------------------------------------------

func _unit_lookups() -> bool:
	var ok := true
	ok = _assert(Training.intensity_factor("Intensive") > Training.intensity_factor("Normal")
		and Training.intensity_factor("Normal") > Training.intensity_factor("Light"),
		"intensity factor ordered Light<Normal<Intensive") and ok
	ok = _assert(Training.injury_multiplier("Intensive") > 1.0 and Training.injury_multiplier("Light") < 1.0,
		"intensity injury multiplier: Intensive>1, Light<1") and ok
	# The ten labels are the PLAYER INFORMATION card's own (Cole, frame p0056) — RM is
	# DRIBBLING and RG is HEADING, which this dict had backwards until 2026-07-25.
	ok = _assert(Training.attr_name("PA") == "Passing" and Training.attr_name("VE") == "Speed",
		"attribute code names resolve") and ok
	ok = _assert(Training.attr_name("RM") == "Dribbling" and Training.attr_name("RG") == "Heading",
		"RM is DRIBBLING and RG is HEADING (Cole's card)") and ok
	ok = _assert(Training.attr_name("CA") == "Quality" and Training.attr_name("PO") == "Handling",
		"CA is QUALITY and PO is HANDLING (Cole's card)") and ok
	return ok


# ---- unit: the lever only changes injury risk -----------------------------

func _unit_direction() -> bool:
	var ok := true
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	# The engine's pass has NO age term and NO intensity term. Two players 15 years
	# apart, both focused on the same skill, move IDENTICALLY.
	var young := _player("Kid", 19, 60)
	var vet := _player("Veteran", 34, 60)
	for _w in 10:
		Training.develop_week(rng, [young], {0: "SHOOTING"})
		Training.develop_week(rng, [vet], {0: "SHOOTING"})
	ok = _assert(int(young["attrs"]["TI"]) == 70 and int(vet["attrs"]["TI"]) == 70,
		"age does not change development (%d vs %d)" % [
			int(young["attrs"]["TI"]), int(vet["attrs"]["TI"])]) and ok
	ok = _assert(int(young["attrs"]["CA"]) == 60 and int(vet["attrs"]["CA"]) == 60,
		"and neither ages nor trains the untrainable core") and ok
	return ok


# ---- unit: caps / floors -------------------------------------------------

func _unit_caps() -> bool:
	var ok := true
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var star := _player("Star", 18, 99)      # already at the engine ceiling
	for _w in 60:
		Training.develop_week(rng, [star], {0: "SHOOTING"})
	var over := false
	for c in star["attrs"]:
		if int(star["attrs"][c]) > 99:
			over = true
	ok = _assert(not over, "no attribute climbs past 99") and ok

	# Decay never takes a man below his shipped base.
	var done := _player("Done", 39, 30)
	for _w in 60:
		Training.develop_week(rng, [done])
	var under := false
	for c in done["attrs"]:
		if int(done["attrs"][c]) < 30:
			under = true
	ok = _assert(not under, "decay stops at the shipped base") and ok
	# unrated player (no attrs) is skipped without error
	var fringe := {"id": 1, "name": "Fringe", "age": 20, "attrs": {}}
	Training.develop_week(rng, [fringe], {1: "SHOOTING"})
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

	# the engine's BASE attribute block is seeded on the squad.
	var seeded := true
	for p in career.my_squad():
		if not p.has("attrs_base"):
			seeded = false
	ok = _assert(seeded, "squad seeded with the base attribute block") and ok

	# Cycle intensity wraps.
	career.cycle_training()
	ok = _assert(career.training_intensity == "Intensive", "Normal cycles to Intensive") and ok
	career.cycle_training()
	ok = _assert(career.training_intensity == "Light", "Intensive cycles to Light") and ok

	# Play a season on Intensive: development news accrues and at least one player's
	# ability moves from where it started.
	career.training_intensity = "Intensive"
	# Hire the six skill coaches and let AUTO assign the focus — without a coach the
	# original trains NOBODY (TOTAL TRAINABLE PLAYERS = 0), so neither do we.
	var sid := 700
	for skill in Staff.TRAINER_SKILLS:
		career.staff.append({"id": sid, "name": "COACH", "role": skill,
			"stars": 5.0, "quality": 5, "wage": 1000})
		sid += 1
	career.auto_training_focus()
	ok = _assert(not career.training_focus.is_empty(),
		"AUTO assigned %d players to the coaches" % career.training_focus.size()) and ok
	var before: Dictionary = {}
	for p in career.my_squad():
		before[int(p.get("id", -1))] = int((p.get("attrs", {}) as Dictionary).get("TI", 0)) \
			+ int((p.get("attrs", {}) as Dictionary).get("EN", 0)) \
			+ int((p.get("attrs", {}) as Dictionary).get("PO", 0)) \
			+ int((p.get("attrs", {}) as Dictionary).get("PA", 0)) \
			+ int((p.get("attrs", {}) as Dictionary).get("RM", 0)) \
			+ int((p.get("attrs", {}) as Dictionary).get("RG", 0))
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	while not career.season_over():
		career.advance_week(rng)
	var moved := 0
	var dev_news := 0
	for p in career.my_squad():
		var a: Dictionary = p.get("attrs", {})
		var now := int(a.get("TI", 0)) + int(a.get("EN", 0)) + int(a.get("PO", 0)) \
			+ int(a.get("PA", 0)) + int(a.get("RM", 0)) + int(a.get("RG", 0))
		if now != before.get(int(p.get("id", -1)), -999):
			moved += 1
	for n in career.news_log:
		if n is Dictionary and n.get("kind") == "training":
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
	# Track ONE man by id: contract terms are now the engine's own roll (OfferRecord),
	# so an expiring player can leave at the rollover and squad[0] need not be the same
	# person on both sides. Pick someone on a multi-year deal and follow him.
	var tracked := -1
	var age_before := 0
	for p in career.my_squad():
		if int((p as Dictionary).get("contract_years", 0)) > 1:
			tracked = int((p as Dictionary).get("id", -1))
			age_before = int((p as Dictionary).get("age", 0))
			break
	career.advance_season(leagues)
	var age_after := -1
	for p in career.my_squad():
		if int((p as Dictionary).get("id", -2)) == tracked:
			age_after = int((p as Dictionary).get("age", 0))
			break
	ok = _assert(tracked != -1 and age_after == age_before + 1,
		"squad ages a year at rollover (%d->%d)" % [age_before, age_after]) and ok

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
