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

	# --- 3. marker geometry: disc+arrow per XI slot, all inside the 258x154 layer
	var markers: Array = screen._rival_markers()
	ok = _assert(markers.size() == 22, "22 rival markers (disc + arrow per slot)") and ok
	var inside := true
	for m in markers:
		var mk: Array = m["mk"]
		if int(mk[0]) < 0 or int(mk[0]) > 242 or int(mk[1]) < 0 or int(mk[1]) > 138:
			inside = false
	ok = _assert(inside, "every marker box fits the marker layer (<=242,<=138)") and ok

	# --- 4. the injected walked-marker lever wins over the auto-picked layout ---
	rival["rival_markers"] = [{"kind": "disc", "mk": [0, 68], "num": 1}]
	screen.setup(rival, own, 2, "A. LEIGH", "Premier")
	ok = _assert(screen._rival_markers().size() == 1, "injected rival_markers used verbatim") and ok
	rival.erase("rival_markers")

	# --- 5. RETURN / TACTICS / toggle hit-tests + a synthetic tap round-trip ----
	ok = _assert(screen._hit(RivalScreen.R_RETURN.get_center()) == "return", "_hit RETURN") and ok
	ok = _assert(screen._hit(RivalScreen.R_TACTICS.get_center()) == "tactics", "_hit TACTICS") and ok
	ok = _assert(screen._hit(RivalScreen.TOGGLE_PARAM.get_center()) == "param", "_hit PARAMETERS") and ok
	ok = _assert(screen._hit(RivalScreen.TOGGLE_RATING.get_center()) == "rating", "_hit RATING") and ok
	ok = _assert(screen._hit(Vector2(240, 150)) == "", "a tap on the table is a no-op") and ok
	_tap(screen, RivalScreen.TOGGLE_PARAM.get_center())
	ok = _assert(not screen._rating_view, "PARAMETERS tap flips to the numeric view") and ok
	_tap(screen, RivalScreen.TOGGLE_RATING.get_center())
	ok = _assert(screen._rating_view, "RATING tap flips back") and ok

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

	# --- 7. the club's OWN stored tactic (club_tactics.json / EQUIPOS.PKF) ------
	# Barcelona (app id 1000): custom 4-5-1 shape, layout matches no stock formation.
	var barca := _synth_club(1000, "F.C. BARCELONA", "L. VAN GAAL", 16, [1])
	screen.setup(barca, own, 2, "A. LEIGH", "Premier")
	ok = _assert(screen._club_slots.size() == 11, "Barcelona: 11 own-tactic slots loaded") and ok
	ok = _assert(screen._tactics.formation == "4-5-1",
		"Barcelona: band shape 4-5-1 (sourced FUN_004fe2d0 thresholds)") and ok
	var own_mks: Array = screen._rival_markers()
	ok = _assert(own_mks.size() == 22, "Barcelona: 22 markers from the stored slots") and ok
	var mk1s: Array = []
	var got1: Array = []
	for s in screen._club_slots:
		mk1s.append((s as Dictionary)["mk1"])
	for m in own_mks:
		if m["kind"] == "disc":
			got1.append(m["mk"])
	mk1s.sort()
	got1.sort()
	ok = _assert(str(got1) == str(mk1s), "Barcelona: disc markers == stored mk1 set") and ok
	var gk_mk: Array = screen._club_slots[0]["mk1"]
	ok = _assert(int(gk_mk[0]) == 0 and int(gk_mk[1]) == 68,
		"GK slot first (the (0,68) park spot)") and ok

	# River (app id 1361): 4-6-0 — a shape with NO stock formation name; the fill
	# must still field 11 with zero forwards, and markers must stay in the window.
	var river := _synth_club(1361, "RIVER", "R. DIAZ", 16, [1])
	screen.setup(river, own, 2, "A. LEIGH", "Premier")
	ok = _assert(screen._tactics.xi.size() == 11, "4-6-0 club: XI still 11") and ok
	var rmks: Array = screen._rival_markers()
	ok = _assert(rmks.size() == 22, "4-6-0 club: 22 markers") and ok
	var rin := true
	for m in rmks:
		var rmk: Array = m["mk"]
		if int(rmk[0]) < 0 or int(rmk[0]) > 242 or int(rmk[1]) < 0 or int(rmk[1]) > 138:
			rin = false
	ok = _assert(rin, "4-6-0 club: markers inside the layer window") and ok

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
