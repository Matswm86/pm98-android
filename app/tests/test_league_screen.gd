extends SceneTree
## Headless wiring test for the FRAME-TRUE LEAGUE TABLES screen. Confirms the baked ma_10
## chrome + PROMAN fonts load, the screen accepts a live SeasonSim standings table, the
## row grid / RETURN geometry are the frame-measured anchors, and the RETURN + row-tap
## hit-tests fire back_pressed / club_selected. (Headless can't rasterize, so this asserts
## asset loading + geometry + signals, not pixels — see tests/shot_screens.gd for pixels.)
##   ~/godot462 --headless --path app --script res://tests/test_league_screen.gd


var _back := 0
var _club := -1


func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true

	# Baked chromes (all four divisions, live-witnessed 2026-07-19) + movement
	# markers + PROMAN fonts must import + load.
	for path in ["res://art/screens/leaguetable/chrome.png",
			"res://art/screens/leaguetable/chrome_first.png",
			"res://art/screens/leaguetable/chrome_second.png",
			"res://art/screens/leaguetable/chrome_third.png",
			"res://art/screens/leaguetable/marker_up.png",
			"res://art/screens/leaguetable/marker_down.png",
			"res://art/screens/leaguetable/marker_flat.png",
			"res://art/fonts/proman12.fnt", "res://art/fonts/proman8.fnt"]:
		ok = _assert(ResourceLoader.exists(path), "asset present: %s" % path) and ok
		ok = _assert(load(path) != null, "asset loads: %s" % path) and ok

	# A real Premier standings table from the engine.
	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	if f == null:
		return _assert(false, "game_db.json present")
	var db: Dictionary = JSON.parse_string(f.get_as_text())
	var prem: Array = []
	for c in db.get("clubs", []):
		if c.get("leagueId") == "eng_prem":
			prem.append(c)
	ok = _assert(prem.size() == 20, "20 Premier clubs (%d)" % prem.size()) and ok
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var rows: Array = SeasonSim.simulate_season(rng, prem)["table"]
	ok = _assert(rows.size() == 20, "season table has 20 rows") and ok
	ok = _assert(int(rows[0]["Pts"]) >= int(rows[19]["Pts"]), "table sorted by points") and ok
	# Standings rows carry the keys the screen renders (real data, not invented).
	for k in ["id", "name", "P", "W", "D", "L", "GF", "GA", "Pts"]:
		ok = _assert((rows[0] as Dictionary).has(k), "standings row has key '%s'" % k) and ok

	# Instantiate the real screen and feed it the live table.
	var screen: LeagueTableScreen = load("res://scenes/LeagueTableScreen.gd").new()
	get_root().add_child(screen)
	# Pin to native 640x480 at origin (NOT FULL_RECT, which would stretch to the root
	# window size and break the 1:1 design-space hit-test map below).
	screen.anchor_left = 0.0
	screen.anchor_top = 0.0
	screen.anchor_right = 0.0
	screen.anchor_bottom = 0.0
	screen.position = Vector2.ZERO
	screen.size = Vector2(640, 480)
	for _i in 3:
		await process_frame
	var chromes_ok := true
	for t in [1, 2, 3, 4]:
		var tex: Texture2D = screen._chromes.get(t)
		if tex == null or tex.get_width() != 640 or tex.get_height() != 480:
			chromes_ok = false
	ok = _assert(chromes_ok, "all four division chromes loaded, 640x480") and ok
	ok = _assert(screen._markers.get("up") != null and screen._markers.get("down") != null
		and screen._markers.get("flat") != null, "movement-marker sprites loaded") and ok
	ok = _assert(screen._f12 != null and screen._f8 != null, "PROMAN fonts loaded") and ok
	ok = _assert(PMChrome.font("12") != null, "PMChrome fonts available") and ok

	# Frame-measured geometry (must not drift from the bake anchors).
	ok = _assert(screen.ROW_Y0 == 114 and screen.ROW_PITCH == 16, "row grid y0=114 pitch=16") and ok
	ok = _assert(screen.ROW24_Y0 == 115 and screen.ROW24_PITCH == 15,
		"24-row grid y0=115 pitch=15 (witnessed)") and ok
	ok = _assert(screen.RETURN_BTN == Rect2(525, 423, 99, 25), "RETURN rect = frame anchor") and ok

	var my_id := int(prem[0]["id"])
	screen.setup(rows, prem[0]["name"], db.get("meta", {}).get("season", "1997-98"),
		"Week 38", 1, my_id)
	await process_frame
	ok = _assert(screen._rows.size() == 20, "screen received 20 standings rows") and ok
	ok = _assert(screen._my_id == my_id, "my_id wired for the managed-club highlight") and ok

	# Every club kit the rows blit must load (PMChrome.kit, id-named MINIESC art).
	var kits_ok := true
	for c in prem:
		kits_ok = kits_ok and PMChrome.kit(int(c["id"])) != null
	ok = _assert(kits_ok, "all 20 Premier club kits load") and ok
	ok = _assert(PMChrome.kit(-1) == null, "missing-kit id resolves to null (no crash)") and ok

	# Signals: RETURN dismisses, a row tap raises that club.
	screen.back_pressed.connect(func() -> void: _back += 1)
	screen.club_selected.connect(func(id: int) -> void: _club = id)
	_tap(screen, Vector2(574, 435))                    # inside RETURN_BTN
	ok = _assert(_back == 1, "RETURN tap emits back_pressed") and ok
	_tap(screen, Vector2(200, screen.ROW_Y0 + 4))      # inside row 0
	ok = _assert(_club == int(rows[0]["id"]), "row-0 tap emits club_selected(row0.id)") and ok
	# WITHOUT pyramid data a division-tab tap stays inert (never invents a table).
	var before := _club
	_tap(screen, Vector2(575, 300))                    # over the Third tab
	ok = _assert(_club == before and screen.selected_tier() == 1,
		"division tab inert without pyramid data") and ok

	# WITH pyramid data (the living lower divisions) the witnessed tabs go live:
	# build a fake 24-row Div-1 table and a prev map, tap First, expect a switch.
	var d1_rows: Array = []
	var d1_prev: Dictionary = {}
	for i in 24:
		d1_rows.append({"id": 9000 + i, "name": "Club %d" % i,
			"P": 1, "W": 0, "D": 1, "L": 0, "GF": 0, "GA": 0, "Pts": 1})
		d1_prev[9000 + i] = 24 - i
	screen.set_pyramid(func(t: int) -> Dictionary:
		if t == 2:
			return {"rows": d1_rows, "prev": d1_prev}
		return {"rows": [], "prev": {}})
	_tap(screen, Vector2(575, 230))                    # the First tab (y224..250)
	ok = _assert(screen.selected_tier() == 2, "First tab switches to tier 2") and ok
	ok = _assert(screen._rows.size() == 24, "24-row division table mounted") and ok
	ok = _assert(not screen._prev.is_empty(), "prev-revision positions carried (markers)") and ok
	# An empty division (no data from the provider) leaves the view unchanged.
	_tap(screen, Vector2(575, 300))                    # the Third tab -> provider returns []
	ok = _assert(screen.selected_tier() == 2, "empty-division tab is inert") and ok
	# Row hit-tests follow the 24-row grid while a lower division is shown.
	_tap(screen, Vector2(200, screen.ROW24_Y0 + 2))    # row 0 of the 24-row grid
	ok = _assert(_club == 9000, "row-0 tap on the 24-row grid emits its club id") and ok
	# Back to Premier via its tab (provider not consulted for the home division...
	# it IS: give it the premier rows too).
	screen.set_pyramid(func(t: int) -> Dictionary:
		if t == 1:
			return {"rows": rows, "prev": {}}
		elif t == 2:
			return {"rows": d1_rows, "prev": d1_prev}
		return {"rows": [], "prev": {}})
	_tap(screen, Vector2(575, 200))                    # the Premier tab
	ok = _assert(screen.selected_tier() == 1 and screen._rows.size() == 20,
		"Premier tab returns to the 20-row table") and ok

	# Force a paint pass (dummy driver headless; still catches null-deref / API misuse).
	screen.queue_redraw()
	for _i in 3:
		await process_frame

	screen.queue_free()
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	quit(0 if ok else 1)


func _tap(screen: LeagueTableScreen, pos: Vector2) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = pos
	screen._on_input(ev)


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
