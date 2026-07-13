extends SceneTree
## Headless wiring test for the LINE-UP -> TRAINING sub-screen (TrainingScreen.gd,
## docs/re/training_screen_re.md). Confirms the baked chrome + title + star sprites
## load, that a real squad groups into the KEEPERS/DEFENDERS/MIDFIELDERS/FORWARDS
## buckets and hit-tests to a selectable player, that the AVER panel opens on a
## grid tap, and that AUTO (a documented no-op), TACTICS and RETURN behave.
## (Headless can't rasterize; this exercises geometry + signals + a paint pass.)
##   ~/godot462 --headless --path app --script res://tests/test_training_screen.gd


func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true

	for path in ["res://art/screens/training/chrome.png", "res://art/screens/training/title.png",
			"res://art/screens/training/star_on.png", "res://art/screens/training/star_off.png",
			"res://art/screens/training/star_sel_on.png", "res://art/screens/training/rp_star_on.png",
			"res://art/screens/training/rp_star_on_strip.png"]:
		ok = _assert(ResourceLoader.exists(path), "asset present: %s" % path) and ok

	var club := _synth_club()
	var screen: TrainingScreen = load("res://scenes/TrainingScreen.gd").new()
	get_root().add_child(screen)
	screen.size = Vector2(640, 480)
	for _i in 3:
		await process_frame
	ok = _assert(screen._f8 != null and screen._f10 != null, "PROMAN fonts loaded") and ok
	ok = _assert(screen._chrome != null and screen._title != null, "baked chrome + title loaded") and ok

	screen.setup(club, [], {})
	await process_frame
	ok = _assert(screen._by_id.size() == (club["players"] as Array).size(),
		"indexed the full squad (%d)" % screen._by_id.size()) and ok
	ok = _assert(screen._buckets["gk"].size() == 2, "2 keepers bucketed") and ok
	ok = _assert(screen._buckets["def"].size() == 5, "5 defenders bucketed") and ok
	ok = _assert(screen._buckets["mid"].size() == 5, "5 midfielders bucketed") and ok
	ok = _assert(screen._buckets["fwd"].size() == 3, "3 forwards bucketed") and ok

	# a keeper falls in the gk section even without a 'pos' string (isGK path)
	var gk: Dictionary = screen._buckets["gk"][0]
	ok = _assert(screen._section_of(gk) == "gk", "isGK routes to the KEEPERS section") and ok

	# AV mirrors LineupScreen._av_of (mean of the 8 outfield attrs); here all 70 -> 70
	var mid0: Dictionary = screen._buckets["mid"][0]
	ok = _assert(screen._av_of(mid0) == 70, "AV = app rating (70)") and ok

	# grid hit-test: tapping the first keeper's bar selects him; tapping again clears
	var gk_pid := int(gk["id"])
	ok = _assert(screen._hit(Vector2(120, 94)) == "grid:%d" % gk_pid, "keeper row hit-tests") and ok
	var back := [false]
	var tac := [false]
	screen.back_pressed.connect(func() -> void: back[0] = true)
	screen.tactics_pressed.connect(func() -> void: tac[0] = true)
	_tap(screen, Vector2(120, 94))
	ok = _assert(screen._sel_pid == gk_pid and not back[0], "grid tap selects, opens AVER panel") and ok
	_tap(screen, Vector2(120, 94))
	ok = _assert(screen._sel_pid == -1, "tapping the selected player deselects") and ok

	# AUTO is a documented no-op (must not crash, must not select or dismiss)
	_tap(screen, Vector2(390, 459))          # R_AUTO centre
	ok = _assert(not back[0] and not tac[0] and screen._sel_pid == -1, "AUTO is a safe no-op") and ok
	# TACTICS + RETURN emit
	_tap(screen, Vector2(490, 459))          # R_TACTICS centre
	ok = _assert(tac[0], "TACTICS emits tactics_pressed") and ok
	_tap(screen, Vector2(590, 459))          # R_RETURN centre
	ok = _assert(back[0], "RETURN emits back_pressed") and ok

	# select a player and force a paint pass (panel + grid, catches null-deref)
	screen._sel_pid = int(screen._buckets["fwd"][0]["id"])
	screen.queue_redraw()
	for _i in 3:
		await process_frame

	screen.queue_free()
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	quit(0 if ok else 1)


## 15-man squad: 2 GK, 5 DF, 5 MF, 3 FW, decoded attrs so AV + stars have numbers.
func _synth_club() -> Dictionary:
	var players: Array = []
	var spec := [["GK", 2], ["DF", 5], ["MF", 5], ["FW", 3]]
	var pid := 1
	for pair in spec:
		for _n in int(pair[1]):
			var gk: bool = pair[0] == "GK"
			players.append({
				"id": pid, "name": "P%d" % pid, "squadNo": pid,
				"isGK": gk, "pos": str(pair[0]), "posFine": 1 if gk else 7,
				"attrs": {"VE": 70, "RE": 70, "AG": 70, "CA": 70, "RM": 70, "RG": 70,
					"PA": 70, "TI": 70, "EN": 70, "PO": 78 if gk else 12},
			})
			pid += 1
	return {"id": 1, "name": "SYNTH FC", "players": players}


func _tap(screen: TrainingScreen, p: Vector2) -> void:
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
