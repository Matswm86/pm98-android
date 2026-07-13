extends SceneTree
## Headless wiring test for the RESULTS screen (frame 038 rebuild): baked art +
## glyph strips load, Career-shaped data maps to pages/rows/dates, the manager-only
## score lookup stays honest (AI fixtures = no score), arrows clamp, RETURN emits.
##   ~/godot4 --headless --path app -s tests/test_results_screen.gd
## With a real renderer (not --headless) and PM98_SHOT_DIR set, also captures the
## frame-038 state to results_038.png for pixel-diffing against the walkthrough.

var _ok := true
var _back_fired := false


func _initialize() -> void:
	_run()


func _run() -> void:
	# ---- baked art + spec ------------------------------------------------------
	for p in ["res://art/screens/results/chrome.png",
			"res://art/screens/results/hdr_names.png",
			"res://art/screens/results/hdr_kit.png",
			"res://art/screens/results/hdr_cal.png",
			"res://art/screens/results/hdr_status.png",
			"res://art/screens/results/title_patch.png",
			"res://art/screens/results/title_caps.png",
			"res://art/screens/results/date_digits.png",
			"res://art/screens/results/arrow_left_on.png",
			"res://art/screens/results/arrow_left_off.png",
			"res://art/screens/results/arrow_right_on.png",
			"res://art/screens/results/arrow_right_off.png",
			"res://art/fonts/proman10.fnt", "res://art/fonts/proman14.fnt",
			"res://art/fonts/proman18.fnt", "res://art/fonts/calend12.fnt"]:
		_assert(ResourceLoader.exists(p) and load(p) != null, "asset loads: %s" % p)
	var sf := FileAccess.open("res://data/results_chrome_samples.json", FileAccess.READ)
	_assert(sf != null, "results_chrome_samples.json present")
	var spec: Dictionary = JSON.parse_string(sf.get_as_text())
	_assert(spec.has("date") and spec.has("title"), "spec has date+title strips")
	for c in "0123456789/":
		_assert((spec["date"]["cells"] as Dictionary).has(c), "date cell %s" % c)

	# ---- screen + Career-shaped data (frame 038's matchday-1 pairings) ----------
	var screen: ResultsScreen = load("res://scenes/ResultsScreen.gd").new()
	get_root().add_child(screen)
	for _i in 3:
		await process_frame
	screen.size = Vector2(640, 480)
	_assert(screen._chrome != null, "chrome texture loaded into screen")
	_assert(screen._f10 != null and screen._f8 != null, "PROMAN fonts loaded")

	var round1 := [[68, 48], [38, 56], [53, 49], [39, 63], [43, 46], [57, 45],
		[44, 52], [54, 59], [51, 42]]
	var names := {68: "Barnsley", 48: "West Ham Utd", 38: "Blackburn R.",
		56: "Derby County", 53: "Coventry", 49: "Chelsea", 39: "Everton",
		63: "Crystal Pal.", 43: "Leeds Utd", 46: "Arsenal", 57: "Leicester",
		45: "Aston Villa", 44: "Newcastle Utd", 52: "Sheffield W.",
		54: "Southampton", 59: "Bolton W", 51: "Wimbledon", 42: "Liverpool"}
	var round2 := round1.duplicate(true)
	var header := {"top": "MWM", "bottom": "Manchester Utd.", "club_id": 40,
		"weekday": "Friday", "day": "1", "month": "August", "year": "1997",
		"status_top": "Preseason", "status_bottom": "Preparation"}
	screen.setup(header, "Premier League", "1997-98", [round1, round2],
		[], 0, 68, names)
	await process_frame

	_assert(screen._pages.size() == 2, "9-fixture rounds -> 1 page each (%d)"
		% screen._pages.size())
	_assert(screen._idx == 0, "fresh career opens on round 1")
	var d: Dictionary = screen._date_for(0, 0)
	_assert(d["day"] == 9 and d["month"] == 8 and d["year"] == 1997,
		"round 1 date is 9/8/1997 (frame truth), got %s" % str(d))
	var d2: Dictionary = screen._date_for(1, 0)
	_assert(d2["day"] == 16 and d2["month"] == 8, "round 2 date is 16/8/1997")

	# every witness club has its RIDIESC kit
	var kits_ok := true
	for pr in round1:
		for cid in pr:
			kits_ok = kits_ok and PMChrome.ridi_kit(int(cid)) != null
	_assert(kits_ok, "all 18 witness clubs have RIDIESC kits")

	# ---- honest score mapping ----------------------------------------------------
	screen.setup(header, "Premier League", "1997-98", [round1, round2],
		[{"week": 1, "opp_id": 48, "home": true, "hg": 2, "ag": 1}], 1, 68, names)
	_assert(screen._score_for(0, 68, 48) == [2, 1], "manager score found for round 1")
	_assert(screen._score_for(0, 38, 56) == [], "AI fixture has NO score (honest)")
	_assert(screen._score_for(1, 68, 48) == [], "unplayed round has no score")
	_assert(screen._idx == 1, "week 1 career opens on round 2")

	# ---- paging: a 10-fixture round splits 9+1 across dates -----------------------
	var big := round1.duplicate(true)
	big.append([40, 47])
	screen.setup(header, "Premier League", "1997-98", [big], [], 0, 40, names)
	_assert(screen._pages.size() == 2, "10-fixture round -> 2 date pages")
	_assert(int(screen._pages[1]["day_off"]) == 1, "overflow page is next-day")
	_assert((screen._pages[1]["pairs"] as Array).size() == 1, "overflow page has 1 row")
	var d3: Dictionary = screen._date_for(0, 1)
	_assert(d3["day"] == 10 and d3["month"] == 8, "overflow date is 10/8/1997")

	# ---- taps: arrows clamp, RETURN emits ------------------------------------------
	_assert(screen._target_at(Vector2(560, 447)) == "return", "RETURN tap target")
	_assert(screen._target_at(Vector2(320, 139)) == "", "prev disabled on page 1")
	_assert(screen._target_at(Vector2(470, 139)) == "next", "next enabled on page 1")
	screen._idx = 1
	_assert(screen._target_at(Vector2(320, 139)) == "prev", "prev enabled on page 2")
	_assert(screen._target_at(Vector2(470, 139)) == "", "next disabled on last page")
	screen._idx = 0
	screen.back_pressed.connect(func() -> void: _back_fired = true)
	_tap(screen, Vector2(560, 447))
	_assert(_back_fired, "RETURN release emits back_pressed")
	_tap(screen, Vector2(470, 139))
	_assert(screen._idx == 1, "next arrow advances the page")
	_tap(screen, Vector2(320, 139))
	_assert(screen._idx == 0, "prev arrow steps back")

	# ---- empty fresh-career state: chrome only, no crash ----------------------------
	screen.setup(header, "Premier League", "1997-98", [], [], 0, 40, {})
	_assert(screen._pages.is_empty(), "no fixtures -> no pages (empty state)")
	screen.queue_redraw()
	for _i in 3:
		await process_frame

	# ---- non-premier title path (patch + caps stamp) ---------------------------------
	screen.setup(header, "First Division", "1997-98", [round1], [], 0, 68, names)
	screen.queue_redraw()
	for _i in 3:
		await process_frame

	# ---- optional parity shot (needs a real renderer) ---------------------------------
	var shot_dir := OS.get_environment("PM98_SHOT_DIR")
	if shot_dir != "" and DisplayServer.get_name() != "headless":
		get_root().size = Vector2i(640, 480)
		screen.setup(header, "Premier League", "1997-98", [round1, round2],
			[], 0, 68, names)
		screen.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		var img := get_root().get_texture().get_image()
		img.save_png(shot_dir.path_join("results_038.png"))
		print("SHOT results_038.png %dx%d" % [img.get_width(), img.get_height()])

	screen.queue_free()
	print("\n%s" % ("ALL PASS" if _ok else "FAILURES ABOVE"))
	quit(0 if _ok else 1)


func _tap(screen: ResultsScreen, at: Vector2) -> void:
	for pressed in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = pressed
		ev.position = at
		screen._on_input(ev)


func _assert(cond: bool, label: String) -> void:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	_ok = _ok and cond
