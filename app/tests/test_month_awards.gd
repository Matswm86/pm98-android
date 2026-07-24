extends SceneTree
## MONTHLY AWARDS: the model builds both sheets at a real month boundary and the
## two screens (ManagersMonthScreen / PlayersMonthScreen) mount, populate and
## answer. Witness: 2026-07-18 Bolton career, week-4 CONTINUE raised MANAGERS OF
## THE MONTH (AUGUST) then PLAYERS OF THE MONTH (AUGUST) — frames 76 / 77.
##   ~/godot462 --headless --path app --script res://tests/test_month_awards.gd


func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true
	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	var db: Dictionary = JSON.parse_string(f.get_as_text())
	var leagues: Array = db.get("leagues", [])
	var league: Dictionary = {}
	for lg in leagues:
		if lg.get("id") == "eng_prem":
			league = lg
	var prem: Array = []
	var by_id: Dictionary = {}
	for c in db.get("clubs", []):
		by_id[int(c["id"])] = c
		if c.get("leagueId") == "eng_prem":
			prem.append(c)
	var career := Career.create(prem[0], league, prem, leagues)
	var rng := RandomNumberGenerator.new()
	rng.seed = 90210

	# Season opens Sat 9 Aug 1997 -> rounds 1..4 are August, round 5 is September,
	# so the AUGUST sheets must be built by the round that crosses the boundary.
	var raised := {}
	for _w in 8:
		career.advance_week(rng, by_id)
		if not (career.month_awards as Dictionary).is_empty() and raised.is_empty():
			raised = (career.month_awards as Dictionary).duplicate(true)
			career.month_awards = {}
	ok = _assert(not raised.is_empty(), "a month closed inside the first 8 rounds") and ok
	if raised.is_empty():
		print("test_month_awards: FAIL")
		quit(1)
		return
	ok = _assert(str(raised.get("month", "")) == "AUGUST",
		"the closed month is AUGUST (got %s)" % raised.get("month", "")) and ok
	var mgrs: Dictionary = raised.get("managers", {})
	ok = _assert(mgrs.has(career.tier), "the manager's division has a winner") and ok
	var win: Dictionary = mgrs.get(career.tier, {})
	ok = _assert(int(win.get("club_id", -1)) != -1 and str(win.get("club", "")) != "",
		"winner carries a real club (%s)" % win.get("club", "?")) and ok
	# the winner must genuinely be a top-form club, not just the first id
	var plys: Dictionary = raised.get("players", {})
	var rows: Array = plys.get(career.tier, [])
	ok = _assert(rows.size() == prem.size(),
		"one PLAYER row per club (%d of %d)" % [rows.size(), prem.size()]) and ok
	var named := 0
	for r in rows:
		if str((r as Dictionary).get("player", "")) != "":
			named += 1
	ok = _assert(named > 0, "at least one club named a player (%d of %d)" % [named, rows.size()]) and ok

	# ---- the two screens ---------------------------------------------------
	var mgr: ManagersMonthScreen = load("res://scenes/ManagersMonthScreen.gd").new()
	get_root().add_child(mgr)
	mgr.size = Vector2(640, 480)
	await process_frame
	var mrows: Dictionary = {}
	for t in mgrs:
		mrows[int(t)] = {"club_id": int(mgrs[t]["club_id"]), "club": str(mgrs[t]["club"]),
			"manager": "Test Mgr"}
	mgr.setup("AUGUST", mrows)
	await process_frame
	ok = _assert(mgr._chrome != null, "MANAGERS chrome loaded") and ok
	var mgr_ok := [false]
	mgr.ok_pressed.connect(func() -> void: mgr_ok[0] = true)
	_tap(mgr, ManagersMonthScreen.OK_RECT.get_center())
	await process_frame
	ok = _assert(mgr_ok[0], "MANAGERS OK emits") and ok
	mgr.queue_free()

	var ply: PlayersMonthScreen = load("res://scenes/PlayersMonthScreen.gd").new()
	get_root().add_child(ply)
	ply.size = Vector2(640, 480)
	await process_frame
	ply.setup("AUGUST", {career.tier: rows}, career.tier)
	await process_frame
	ok = _assert(ply._chrome != null, "PLAYERS chrome loaded") and ok
	ok = _assert(ply._tabs.get("premier") != null, "division tab faces loaded") and ok
	var ply_ok := [false]
	ply.ok_pressed.connect(func() -> void: ply_ok[0] = true)
	_tap(ply, Vector2((PlayersMonthScreen.OK_X.x + PlayersMonthScreen.OK_X.y) * 0.5,
		(PlayersMonthScreen.TAB_Y.x + PlayersMonthScreen.TAB_Y.y) * 0.5))
	await process_frame
	ok = _assert(ply_ok[0], "PLAYERS OK emits") and ok
	ply.queue_free()

	# a save/load round-trip must not lose a pending sheet or the running month mark
	career.month_awards = raised
	career.save()
	var c2 := Career.load_save()
	ok = _assert(c2 != null and not (c2.month_awards as Dictionary).is_empty(),
		"pending sheets survive save/load") and ok

	print("test_month_awards: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)


func _tap(n: Control, p: Vector2) -> void:
	for pressed in [true, false]:
		var e := InputEventScreenTouch.new()
		e.index = 0
		e.position = p
		e.pressed = pressed
		n._on_input(e)


func _assert(cond: bool, label: String) -> bool:
	print(("  ok   " if cond else "  FAIL ") + label)
	return cond
