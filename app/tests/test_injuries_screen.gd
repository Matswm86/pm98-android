extends SceneTree
## Headless wiring test for the LINE-UP -> INJURIES sub-screen (InjuriesScreen.gd,
## docs/re/injuries_screen_re.md). Confirms the baked chrome + title + physio star
## load, that Availability's injured_weeks drives which players list (and in which
## GOAL/DEF/MID/FOR section), that suspensions are excluded, that the physio band
## reads Career.staff, and that INSURANCE (no-op) + RETURN behave.
##   ~/godot462 --headless --path app --script res://tests/test_injuries_screen.gd


func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true

	for path in ["res://art/screens/injuries/chrome.png", "res://art/screens/injuries/title.png",
			"res://art/screens/injuries/phys_star.png"]:
		ok = _assert(ResourceLoader.exists(path), "asset present: %s" % path) and ok

	var club := _synth_club()
	# injure a defender (2 weeks) + a forward (1 week); suspend a midfielder (must NOT list)
	club["players"][3]["injured_weeks"] = 2      # a DF
	club["players"][12]["injured_weeks"] = 1     # a FW
	club["players"][8]["suspended_weeks"] = 1    # a MF (excluded)
	var physio := {"id": 800001, "role": Staff.PHYSIO, "name": "R. Physio", "quality": 4,
		"wage": Staff.wage_for(Staff.PHYSIO, 4)}

	var screen: InjuriesScreen = load("res://scenes/InjuriesScreen.gd").new()
	get_root().add_child(screen)
	screen.size = Vector2(640, 480)
	for _i in 3:
		await process_frame
	ok = _assert(screen._chrome != null and screen._phys_star != null,
		"baked chrome + physio star loaded") and ok

	screen.setup(club, [physio], {})
	await process_frame
	ok = _assert(screen._injured["def"].size() == 1, "the injured defender lists in DEF") and ok
	ok = _assert(screen._injured["fwd"].size() == 1, "the injured forward lists in FOR") and ok
	ok = _assert(screen._injured["mid"].size() == 0, "the suspended midfielder is excluded") and ok
	ok = _assert(int(screen._injured["def"][0]["injured_weeks"]) == 2,
		"the Week value carries injured_weeks (2)") and ok
	ok = _assert(not screen._physio().is_empty() and int(screen._physio()["quality"]) == 4,
		"the hired physio is read from staff (q4)") and ok

	# no-physio career: the band is simply blank (must not crash)
	screen.setup(club, [], {})
	await process_frame
	ok = _assert(screen._physio().is_empty(), "no physio -> empty band") and ok

	screen.setup(club, [physio], {})
	var back := [false]
	screen.back_pressed.connect(func() -> void: back[0] = true)
	_tap(screen, Vector2(420, 451))          # INSURANCE centre (no-op)
	ok = _assert(not back[0], "INSURANCE is a safe no-op") and ok
	_tap(screen, Vector2(567, 451))          # RETURN centre
	ok = _assert(back[0], "RETURN emits back_pressed") and ok

	screen.queue_redraw()
	for _i in 3:
		await process_frame

	screen.queue_free()
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	quit(0 if ok else 1)


func _synth_club() -> Dictionary:
	var players: Array = []
	var spec := [["GK", 2], ["DF", 5], ["MF", 5], ["FW", 3]]
	var pid := 1
	for pair in spec:
		for _n in int(pair[1]):
			var gk: bool = pair[0] == "GK"
			players.append({
				"id": pid, "name": "P%d" % pid, "squadNo": pid,
				"isGK": gk, "pos": str(pair[0]),
				"injured_weeks": 0, "suspended_weeks": 0,
				"attrs": {"VE": 70, "RE": 70, "AG": 70, "CA": 70, "RM": 70, "RG": 70,
					"PA": 70, "TI": 70, "EN": 70, "PO": 78 if gk else 12},
			})
			pid += 1
	return {"id": 1, "name": "SYNTH FC", "players": players}


func _tap(screen: InjuriesScreen, p: Vector2) -> void:
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
