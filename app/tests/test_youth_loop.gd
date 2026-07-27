extends SceneTree
## The youth LOOP fixes (Session D, B1-B10 — docs/re/youth_re.md §"The loop"):
##   B1  the six LED capability flags persist on Career (save/load round-trip)
##   B2  a zero-LED search is REFUSED (it could never match: the predicate is an
##       OR over the lit flags — arming it was a guaranteed dead 15-28 weeks)
##   B3  the youth manager's "ready to be promoted" line rides pending_alerts
##   B6  easter-egg arrivals (wonderkid / talents) never block the faithful loop:
##       the declared SQUAD_CAP counts POOL-scouted members only, and the pool's
##       exclude list carries pool ids only
##   B8  the two youth randomize() sites now draw from ONE career RNG whose state
##       survives save/load (the S3 seed-reproducibility step)
##   ~/godot462 --headless --path app --script res://tests/test_youth_loop.gd

const SEED := 33220011
const POOL_CLUB := 1383

var _db: Dictionary = {}
var _clubs_by_id: Dictionary = {}


func _initialize() -> void:
	quit(0 if _run() else 1)


func _load_db() -> bool:
	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	if f == null:
		push_error("game_db.json missing")
		return false
	_db = JSON.parse_string(f.get_as_text())
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	for c in _db.get("clubs", []):
		_clubs_by_id[int(c["id"])] = c
		if int(c["id"]) == POOL_CLUB:
			for p in c.get("players", []):
				Youth.degrade(p, rng)
	return true


func _fixture() -> Career:
	var leagues: Array = _db.get("leagues", [])
	var league: Dictionary = {}
	for lg in leagues:
		if lg.get("id") == "eng_prem":
			league = lg
	var prem: Array = []
	for c in _db.get("clubs", []):
		if c.get("leagueId") == "eng_prem":
			prem.append(c)
	var career := Career.create(prem[0], league, prem, leagues)
	career.youth_pool = Youth.pool_of(_clubs_by_id)
	career.staff = [{"id": 1, "role": Staff.YOUTH_TEAM_SCOUT, "name": "P. Mitchell",
		"stars": 5.0, "wage": 40000}]
	return career


func _run() -> bool:
	if not _load_db():
		return false
	var ok := true
	ok = _b2_zero_led_guard() and ok
	ok = _b1_caps_persist() and ok
	ok = _b8_career_rng() and ok
	ok = _b6_easter_eggs_dont_block() and ok
	ok = _b3_ready_alert() and ok
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	return ok


# ---- B2: the "recruitment doesn't work" bug ------------------------------

func _b2_zero_led_guard() -> bool:
	var ok := true
	var c := _fixture()
	c.start_youth_search([])
	ok = _assert(c.youth_search.is_empty(),
		"B2: a zero-LED search never arms (it could never match)") and ok
	c.start_youth_search(["DRIBBLING"])
	ok = _assert(not c.youth_search.is_empty(), "B2: a lit search still arms") and ok
	return ok


# ---- B1: the six LED flags survive leaving the screen --------------------

func _b1_caps_persist() -> bool:
	var ok := true
	var c := _fixture()
	c.youth_caps = {"DRIBBLING": true, "HEADING": true, "PASSING": false}
	var path := "user://career_youth_loop_test.json"
	c.save(path)
	var loaded := Career.load_save(path)
	ok = _assert(loaded != null and bool(loaded.youth_caps.get("DRIBBLING", false))
		and bool(loaded.youth_caps.get("HEADING", false))
		and not bool(loaded.youth_caps.get("PASSING", true)),
		"B1: youth_caps round-trip save/load") and ok
	var legacy := Career.from_dict({"club_id": 1, "rosters": {}})
	ok = _assert(legacy.youth_caps.is_empty(), "B1: a pre-caps save loads empty flags") and ok
	return ok


# ---- B8: one career RNG, state persisted ---------------------------------

func _b8_career_rng() -> bool:
	var ok := true
	var a := _fixture()
	var b := _fixture()
	a.career_rng_state = "987654321"
	b.career_rng_state = "987654321"
	ok = _assert(a.career_rng().randi() == b.career_rng().randi(),
		"B8: same persisted state -> same stream") and ok
	# the consumed state is what to_dict writes, so a save/load CONTINUES the stream
	var d := a.to_dict()
	var c := Career.from_dict({"club_id": 1, "rosters": {},
		"career_rng_state": d.get("career_rng_state", "")})
	ok = _assert(c.career_rng().randi() == b.career_rng().randi(),
		"B8: save/load continues the stream, not restarts it") and ok
	# the youth sites draw from it: arming a search with equal state gives equal weeks
	var e := _fixture()
	var f := _fixture()
	e.career_rng_state = "1122334455"
	f.career_rng_state = "1122334455"
	e.start_youth_search(["SHOOTING"])
	f.start_youth_search(["SHOOTING"])
	ok = _assert(int(e.youth_search.get("weeks", -1)) == int(f.youth_search.get("weeks", -2)),
		"B8: search duration drawn from the career stream") and ok
	return ok


# ---- B6: the easter-egg lane never blocks the faithful loop --------------

func _b6_easter_eggs_dont_block() -> bool:
	var ok := true
	var c := _fixture()
	# Fill the academy PAST the cap with easter-egg arrivals (no _from_youth_pool).
	for i in Youth.SQUAD_CAP + 2:
		c.youth.append({"id": 900100 + i, "name": "EGG %d" % i, "age": 16,
			"is_youth": true, "ready": false,
			"attrs": {"CA": 50}, "attrs_base": {"CA": 70}})
	ok = _assert(c._scouted_youth_count() == 0,
		"B6: easter-egg members don't count against the declared cap") and ok
	var taken: Array = c._youth_taken()
	ok = _assert(taken.is_empty(),
		"B6: the pool exclude list carries pool ids only") and ok
	# A pool prospect still signs with the academy nominally over-cap.
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	c.youth_found = Youth.scout_search(rng, ["HANDLING", "PASSING", "SHOOTING"],
		c.youth_pool, c._youth_taken())
	ok = _assert(not c.youth_found.is_empty(), "B6 fixture: the scout found one") and ok
	if not c.youth_found.is_empty():
		var res := c.sign_youth_prospect(int((c.youth_found[0] as Dictionary)["id"]), rng)
		ok = _assert(bool(res.get("ok", false)),
			"B6: a scouted signing is not blocked by easter-egg members") and ok
	# A talent enters with his ceiling reachable: BASE CA == potential.
	var t := Talent.make_youth({"id": 1, "name": "T", "tier": 1, "potential": 90,
		"ca": 55, "pos": "FW"}, rng, 1997)
	ok = _assert(int((t.get("attrs_base", {}) as Dictionary).get("CA", 0)) == 90,
		"B6: a talent's BASE CA is his potential (growth can reach it)") and ok
	return ok


# ---- B3: READY rides pending_alerts --------------------------------------

func _b3_ready_alert() -> bool:
	var ok := true
	var c := _fixture()
	# One kid a single point short of BASE on one CORE4 attr; the 60% weekly gate
	# means he reports ready within a few weeks.
	var attrs := {"VE": 59, "RE": 60, "AG": 60, "CA": 60,
		"RM": 60, "RG": 60, "PA": 60, "TI": 60, "EN": 60, "PO": 20}
	var base := attrs.duplicate()
	base["VE"] = 60
	c.youth = [{"id": 900500, "name": "NEARLY READY", "age": 17, "is_youth": true,
		"ready": false, "clubId": c.club_id, "_from_youth_pool": 1,
		"attrs": attrs, "attrs_base": base}]
	c.pending_alerts = []
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var got := false
	for _w in 25:
		if c.season_over():
			break
		c.advance_week(rng, _clubs_by_id)
		for msg in c.pending_alerts:
			if str(msg).begins_with("Your youth manager has informed you"):
				got = true
		if got:
			break
	ok = _assert(got, "B3: the READY report lands in pending_alerts") and ok
	return ok


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
