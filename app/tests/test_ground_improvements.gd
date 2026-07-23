extends SceneTree
## GROUND IMPROVEMENTS: the CAR PARK / FACILITIES / SERVICES tabs unblocked by the owner's
## 2026-07-23 capture. Asserts the generalised concurrent works model (car-park level,
## facility/service grade), the WORK IN PROGRESS ledger totals, save/load, and StadiumScreen's
## tab + quadrant + grade hit-testing and works_requested payloads.
##   ~/godot462 --headless --path app --script res://tests/test_ground_improvements.gd

const SEED := 909


func _initialize() -> void:
	quit(0 if await _run() else 1)


func _run() -> bool:
	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	var db: Dictionary = JSON.parse_string(f.get_as_text())
	var leagues: Array = db.get("leagues", [])
	var league: Dictionary = {}
	for lg in leagues:
		if lg.get("id") == "eng_prem":
			league = lg
	var prem: Array = []
	var manu: Dictionary = {}
	for c in db.get("clubs", []):
		if c.get("leagueId") == "eng_prem":
			prem.append(c)
			if str(c.get("name", "")).to_lower().contains("manchester utd"):
				manu = c
	var ok := true

	var career := Career.create(manu, league, prem, leagues)
	career.cash = 40_000_000
	ok = _assert(career.car_park_levels == [1, 1, 1, 1], "car park base = 4 quadrants @ level 1") and ok
	ok = _assert(career.car_park_spaces() == 2000, "base car-park spaces = 2,000") and ok

	# Concurrent works: SEATS + CAR PARK quad-0 + a FACILITIES grade + a SERVICES grade.
	ok = _assert(career.start_works(8000, 7_437_500, 35), "SEATS work started") and ok
	ok = _assert(career.begin_work("carpark", 0, "500 spaces", 2_975_000, 7, {"added": 500}),
		"CAR PARK work started") and ok
	ok = _assert(not career.begin_work("carpark", 0, "500 spaces", 2_975_000, 7, {"added": 500}),
		"a second work on the same quadrant is refused") and ok
	ok = _assert(career.begin_work("facility", 2, "CHANG. ROOMS", 225_000, 3, {"grade": 2}),
		"FACILITIES work started") and ok
	ok = _assert(career.begin_work("service", 0, "SICKROOM", 150_000, 2, {"grade": 2}),
		"SERVICES work started") and ok
	ok = _assert(career.works_total() == 10_787_500,
		"TOTAL IMPROVEMENTS sums every live work (£%d)" % career.works_total()) and ok
	ok = _assert(career.works_ledger().size() == 4, "four works in the ledger") and ok

	# Tick to completion: each effect lands (SERVICES 2wk first, then FACILITIES 3, CAR PARK 7).
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	for _w in 7:
		if career.season_over():
			break
		career.advance_week(rng, {})
	ok = _assert(career.car_park_level(0) == 2, "car park quadrant 0 rose to level 2") and ok
	ok = _assert(career.car_park_spaces() == 2500, "car-park spaces rose to 2,500") and ok
	ok = _assert(career.ground_grade("facility", 2, 1) == 2, "CHANGING ROOMS grade -> COMPLETE") and ok
	ok = _assert(career.ground_grade("service", 0, 1) == 2, "MEDICAL EQUIPMENT grade -> I.C.U.") and ok
	ok = _assert(career.work_for("service", 0).is_empty(), "completed works cleared") and ok

	# Save / load round-trips the new state.
	var path := "user://ground_improvements_test.json"
	career.begin_work("carpark", 1, "500 spaces", 2_975_000, 7, {"added": 500})
	career.save(path)
	var loaded := Career.load_save(path)
	ok = _assert(loaded != null and loaded.car_park_levels == career.car_park_levels
		and loaded.ground_grades == career.ground_grades
		and loaded.works_ledger().size() == career.works_ledger().size(),
		"GROUND state survived save/load") and ok

	# StadiumScreen: tab + quadrant + grade hit-testing and works_requested payloads.
	var scr: StadiumScreen = load("res://scenes/StadiumScreen.gd").new()
	scr.size = Vector2(640, 480)
	get_root().add_child(scr)
	for _i in 2:
		await process_frame
	scr.setup("Manchester Utd.", "M", "1997-98", "Old Trafford", 55300, 34000, 21000, 2000,
		"", 7, 750, 1, "Premier", str(manu.get("objective", "")))
	scr.set_improve_state([1, 1, 1, 1], 2_975_000, [], {}, 0)
	scr._view = "improve"
	ok = _assert(scr._hit(StadiumScreen.TAB_CARPARK.get_center()) == "tab:carpark",
		"CAR PARK tab hit-tests") and ok
	ok = _assert(scr._hit(StadiumScreen.TAB_FACILITIES.get_center()) == "tab:facilities",
		"FACILITIES tab hit-tests") and ok
	ok = _assert(scr._hit(StadiumScreen.TAB_SERVICES.get_center()) == "tab:services",
		"SERVICES tab hit-tests") and ok

	var picks := {"req": null}
	scr.works_requested.connect(func(cat: String, key: int, label: String, cost: int, weeks: int, effect: Dictionary) -> void:
		picks["req"] = [cat, key, cost, weeks, effect])
	scr._tab = "carpark"
	scr._buy_carpark(0)
	ok = _assert(picks["req"] != null and picks["req"][0] == "carpark" and picks["req"][2] == 2_975_000,
		"CAR PARK tap emits a +500 work at the witnessed price") and ok
	# An un-witnessed club (no car-park price) never emits (honest gap).
	picks["req"] = null
	scr.set_improve_state([1, 1, 1, 1], 0, [], {}, 0)
	scr._buy_carpark(0)
	ok = _assert(picks["req"] == null, "un-witnessed car-park price = honest gap (no emit)") and ok
	# FACILITIES: the witnessed CHANGING ROOMS (item 2) upgrade emits; a bare item is inert.
	picks["req"] = null
	scr.set_improve_state([1, 1, 1, 1], 2_975_000, [], {}, 0)
	scr._tab = "facilities"
	scr._fac_sel = 2
	scr._buy_grade("facility", 2, StadiumScreen.FAC_WITNESS[2])
	ok = _assert(picks["req"] != null and picks["req"][0] == "facility" and picks["req"][2] == 225_000,
		"CHANGING ROOMS upgrade emits at £225,000") and ok
	picks["req"] = null
	scr._buy_grade("facility", 0, StadiumScreen.FAC_WITNESS.get(0, {}))
	ok = _assert(picks["req"] == null, "un-witnessed facility = honest gap (no emit)") and ok

	# --- GROUND MATCH DAY (owner frame 06) ---
	# The MATCH DAY action button opens the sub-view (was inert) from any view.
	ok = _assert(scr._hit(StadiumScreen.BTN_MATCHDAY.get_center()) == "matchday",
		"MATCH DAY button hit-tests") and ok
	scr._view = "matchday"
	# Witness (Man Utd, not sold): ticket/board arrows + the sponsor-board ACCEPT all live.
	scr.set_matchday_state(7, 750, "Manchester Utd.", "Southampton", true, false)
	ok = _assert(scr._hit(StadiumScreen.MD_TICKET_UP.get_center()) == "tkt_up"
		and scr._hit(StadiumScreen.MD_TICKET_DN.get_center()) == "tkt_dn",
		"ticket price arrows hit-test") and ok
	ok = _assert(scr._hit(StadiumScreen.MD_BOARD_UP.get_center()) == "brd_up"
		and scr._hit(StadiumScreen.MD_BOARD_DN.get_center()) == "brd_dn",
		"board price arrows hit-test") and ok
	ok = _assert(scr._hit(StadiumScreen.MD_ACCEPT.get_center()) == "accept",
		"sponsor-board ACCEPT hit-tests for the witnessed offer") and ok
	var steps := {"tk": 0, "bd": 0, "sold": false}
	scr.matchday_ticket_step.connect(func(up: bool) -> void: steps["tk"] = 1 if up else -1)
	scr.matchday_board_step.connect(func(up: bool) -> void: steps["bd"] = 1 if up else -1)
	scr.boards_sold.connect(func() -> void: steps["sold"] = true)
	scr._press = "tkt_up"; scr._on_input(_touch(StadiumScreen.MD_TICKET_UP.get_center(), false))
	ok = _assert(steps["tk"] == 1, "ticket up arrow emits matchday_ticket_step(true)") and ok
	scr._press = "accept"; scr._on_input(_touch(StadiumScreen.MD_ACCEPT.get_center(), false))
	ok = _assert(steps["sold"], "ACCEPT emits boards_sold") and ok
	# A club with no witnessed offer, or one that has sold, hides ACCEPT (honest gap / inert).
	scr.set_matchday_state(8, 150, "Southampton", "Manchester Utd.", false, false)
	ok = _assert(scr._hit(StadiumScreen.MD_ACCEPT.get_center()) == "",
		"un-witnessed club: ACCEPT inert (no offer)") and ok
	scr.set_matchday_state(7, 750, "Manchester Utd.", "Southampton", true, true)
	ok = _assert(scr._hit(StadiumScreen.MD_ACCEPT.get_center()) == "",
		"already-sold: ACCEPT inert") and ok

	# Career: the season sponsor-board sale credits once, sets the flag, and survives save/load.
	var md := Career.create(manu, league, prem, leagues)
	var cash_before := md.cash
	ok = _assert(md.sell_sponsor_boards(1_120_000)
		and md.cash == cash_before + 1_120_000 and md.boards_sold_season,
		"sell_sponsor_boards credits the witnessed lump sum + marks sold") and ok
	ok = _assert(not md.sell_sponsor_boards(1_120_000),
		"a second board sale in the same season is refused") and ok
	ok = _assert(md.next_home_opponent() >= 0, "next home opponent resolves for a fresh career") and ok
	md.save("user://matchday_test.json")
	var md2 := Career.load_save("user://matchday_test.json")
	ok = _assert(md2 != null and md2.boards_sold_season, "boards_sold_season survives save/load") and ok

	if ok:
		print("ALL PASS")
	else:
		print("FAILURES ABOVE")
	return ok


func _assert(cond: bool, msg: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", msg])
	return cond


## A screen-touch event at design point `d` (release by default), for the release-path
## hit that emits the MATCH DAY signals.
func _touch(d: Vector2, pressed: bool) -> InputEventScreenTouch:
	var e := InputEventScreenTouch.new()
	e.index = 0
	e.position = d
	e.pressed = pressed
	return e
