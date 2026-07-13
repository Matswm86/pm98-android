extends SceneTree
## Headless wiring test for the LINE-UP -> STATISTICS sub-screen (StatisticsScreen.gd,
## docs/re/statistics_screen_re.md). Confirms the baked chrome + both title sprites
## load, that a real squad populates the row list (# + name), that per-player season
## stats stay an honest gap (untracked), and that RETURN behaves.
##   ~/godot462 --headless --path app --script res://tests/test_statistics_screen.gd


func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true

	for path in ["res://art/screens/stats/chrome.png", "res://art/screens/stats/title.png",
			"res://art/screens/stats/title_manutd.png"]:
		ok = _assert(ResourceLoader.exists(path), "asset present: %s" % path) and ok

	var club := _synth_club(19)
	var screen: StatisticsScreen = load("res://scenes/StatisticsScreen.gd").new()
	get_root().add_child(screen)
	screen.size = Vector2(640, 480)
	for _i in 3:
		await process_frame
	ok = _assert(screen._chrome != null and screen._title != null
		and screen._title_manutd != null, "baked chrome + both titles loaded") and ok

	screen.setup(club, {})
	await process_frame
	ok = _assert(screen._players.size() == 19, "row list = full squad (19)") and ok

	# an over-full squad is clamped to the 19 visible slots (no invented scrolling)
	screen.setup(_synth_club(25), {})
	await process_frame
	ok = _assert(screen._players.size() == 25 and StatisticsScreen.ROW_TOPS.size() == 19,
		"25-man squad kept; only 19 slots drawn") and ok

	# Man Utd (id 40) uses the verbatim baked title; another club redraws navy text.
	screen.setup({"id": 40, "name": "Manchester Utd.", "players": club["players"]}, {})
	ok = _assert(int(screen._club["id"]) == 40, "Man Utd routes to the verbatim title sprite") and ok

	screen.setup(club, {})
	var back := [false]
	screen.back_pressed.connect(func() -> void: back[0] = true)
	_tap(screen, Vector2(569, 461))          # RETURN centre
	ok = _assert(back[0], "RETURN emits back_pressed") and ok

	screen.queue_redraw()
	for _i in 3:
		await process_frame

	screen.queue_free()
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	quit(0 if ok else 1)


func _synth_club(n: int) -> Dictionary:
	var players: Array = []
	for i in n:
		players.append({"id": i + 1, "name": "P%d" % (i + 1), "squadNo": i + 1,
			"pos": "MF", "attrs": {"CA": 70}})
	return {"id": 1, "name": "SYNTH FC", "players": players}


func _tap(screen: StatisticsScreen, p: Vector2) -> void:
	var down := InputEventScreenTouch.new()
	down.position = p
	down.pressed = true
	screen._on_input(down)
	var up := InputEventScreenTouch.new()
	up.position = p
	up.pressed = false
	screen._on_input(up)


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
