extends SceneTree
## Headless test for VIEW RIVAL (VERRIVAL): the opponent-scouting screen (RivalScreen.gd,
## FUN_005733d0). The defining rule -- report depth scales with the manager's ASSISTANT --
## is asserted at its sourced extremes: assistant quality 0 -> no report (the hire-Assistant
## message), >=1 -> the rival XI + team rating + formation dots.
## Also drives the RETURN / TACTICS hit-tests and a synthetic tap round-trip.
##   ~/godot462 --headless --path app --script res://tests/test_rival_screen.gd


func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true

	var rival := _synth_club(38, "F.C. RIVAL", "R. GUARDIOLA", 16, [1])
	var own := _synth_club(7, "OUR CLUB", "THE GAFFER", 16, [1])

	var screen: RivalScreen = load("res://scenes/RivalScreen.gd").new()
	get_root().add_child(screen)
	for _i in 2:
		await process_frame
	screen.size = Vector2(640, 480)           # native -> hit-tests map 1:1

	# --- 1. NO assistant (q==0): the report is the hire-Assistant message ------
	screen.setup(rival, own, 0, "", "Premier")
	ok = _assert(not screen.has_report(), "q==0 -> no rival report") and ok
	ok = _assert(screen._tactics != null and screen._tactics.xi.size() == 11,
		"rival XI auto-picked (11) even when hidden") and ok
	ok = _assert(RivalScreen.HIRE_MSG.contains("hire an Assistant"),
		"hire-Assistant message present verbatim") and ok

	# --- 2. WITH an assistant (q>=1): the full report is shown -----------------
	screen.setup(rival, own, 2, "A. LEIGH", "Premier")
	ok = _assert(screen.has_report(), "q>=1 -> rival report shown") and ok
	ok = _assert(screen._assist_q == 2 and screen._assist_name == "A. LEIGH",
		"assistant quality + name stored") and ok
	ok = _assert(screen._team_rating() > 0, "team rating computed from the rival XI") and ok

	# --- 3. formation geometry: 11 slots inside the marker layer ---------------
	var slots: Array = screen._slot_positions()
	ok = _assert(slots.size() == 11, "11 formation slots") and ok
	var inside := true
	for tac in slots:
		var c: Vector2 = screen._mark_center(tac)
		if c.x < RivalScreen.R_CAMPO.position.x or c.x > RivalScreen.R_CAMPO.end.x \
				or c.y < RivalScreen.R_CAMPO.position.y or c.y > RivalScreen.R_CAMPO.end.y:
			inside = false
	ok = _assert(inside, "every formation dot lands inside the CAMPO pitch rect") and ok

	# --- 5. RETURN / TACTICS hit-tests + a synthetic tap round-trip ------------
	ok = _assert(screen._hit(RivalScreen.R_RETURN.get_center()) == "return", "_hit RETURN") and ok
	ok = _assert(screen._hit(RivalScreen.R_TACTICS.get_center()) == "tactics", "_hit TACTICS") and ok
	ok = _assert(screen._hit(Vector2(240, 150)) == "", "a tap on the table is a no-op") and ok

	var got := {"back": 0, "tac": 0}
	screen.back_pressed.connect(func() -> void: got["back"] += 1)
	screen.tactics_pressed.connect(func() -> void: got["tac"] += 1)
	_tap(screen, RivalScreen.R_RETURN.get_center())
	ok = _assert(got["back"] == 1, "RETURN tap emits back_pressed") and ok
	_tap(screen, RivalScreen.R_TACTICS.get_center())
	ok = _assert(got["tac"] == 1, "TACTICS tap emits tactics_pressed") and ok

	# --- 6. empty rival is safe (bye / missing club) ---------------------------
	screen.setup({}, own, 3, "A. LEIGH", "Premier")
	ok = _assert(screen._tactics == null and screen._team_rating() == 0,
		"empty rival: no tactics, zero rating, no crash") and ok

	screen.queue_free()
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	quit(0 if ok else 1)


## An N-man synth club with a name + manager; `gks` ids are keepers, all with decoded attrs.
func _synth_club(club_id: int, cname: String, manager: String, n: int, gks: Array) -> Dictionary:
	var players: Array = []
	for i in n:
		var pid := i + 1
		var gk: bool = gks.has(pid)
		players.append({
			"id": pid, "clubId": club_id, "name": "P%d" % pid, "isGK": gk,
			"pos": "GK" if gk else "OUT", "posFine": 1 if gk else 7,
			"attrs": {"VE": 70, "RE": 70, "AG": 70, "CA": 70, "RM": 70, "RG": 70,
				"PA": 70, "TI": 70, "EN": 70, "PO": 78 if gk else 12},
		})
	return {"id": club_id, "name": cname, "manager": manager, "players": players}


func _tap(screen: RivalScreen, p: Vector2) -> void:
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
