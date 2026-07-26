extends SceneTree
## The SCOUT bottom bar: the original's per-row ROLLOVER READOUT (three witnesses in
## screenshots/refrun-manutd-1997-98/novel/, docs/re/scout_screen_re.md §"The bottom bar")
## plus the OURS door that occupies the same bar only while the readout is empty.
## The PIXEL claim is tools/re/diff_scout_bar_parity.py's; this asserts the STATE machine —
## which states read out, which stay blank, and that the two never draw at once.
##   DISPLAY=:1 ~/godot462 --rendering-driver opengl3 --path app -s tests/test_scout_bar.gd

var _fails := 0


func _initialize() -> void:
	_run()


func _row(club_id: int, club: String, name: String, legal: String) -> Dictionary:
	return {"pid": 0, "club_id": club_id, "club_name": club, "name": name,
		"legalName": legal, "flagCode": null, "nationality": "SPAIN", "pos": "FW",
		"posFine": 13, "age": 20, "av": 81, "ca": 80, "mo": 88, "fee": 10000000,
		"wage": 300000, "years": 3, "left": 3, "key": false}


func _run() -> void:
	var ok := true
	get_root().size = Vector2i(640, 480)
	var scr: ScoutScreen = load("res://scenes/ScoutScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	get_root().add_child(scr)
	await process_frame

	# ---- the three witness readouts, as strings -----------------------------------------
	var rows: Array = [
		_row(1004, "Athletic Club", "Etxeberria", "Joseba ETXEBERRIA Lizardi"),
		_row(1020, "Milan", "Kluivert", "Patrick KLUIVERT"),
		_row(1023, "Lazio", "Nesta", "Alessandro NESTA"),
	]
	var scout := {"name": "K. BURROWES", "stars": 3.0, "wage": 20000}
	scr.setup(scout, false, rows, "Bolton W", "mwm", "1997-98", 3, "Premier League", 59)
	for i in rows.size():
		scr._hover_row = i
		var r := scr.rollover_row()
		ok = _assert(not r.is_empty(), "row %d held -> the bar reads out" % i) and ok
		ok = _assert(PMChrome.card_name(r) == str(rows[i]["legalName"]),
			"readout name = %s" % rows[i]["legalName"]) and ok
		ok = _assert(str(r.get("club_name", "")) == str(rows[i]["club_name"]),
			"readout club = %s" % rows[i]["club_name"]) and ok
		ok = _assert(PMChrome.ridi_kit(int(rows[i]["club_id"])) != null,
			"ridi kit %d present" % rows[i]["club_id"]) and ok

	# ---- every state the original leaves the bar blank ----------------------------------
	scr._hover_row = -1
	ok = _assert(scr.rollover_row().is_empty(), "nothing held -> blank (p0245)") and ok
	scr._hover_row = 1
	scr._ours_open = true
	ok = _assert(scr.rollover_row().is_empty(), "a modal up -> blank (p0242/p0281)") and ok
	scr._ours_open = false
	scr._searching = true
	ok = _assert(scr.rollover_row().is_empty(), "searching -> blank") and ok
	scr._searching = false
	scr._hover_row = 99
	ok = _assert(scr.rollover_row().is_empty(), "a row past the list -> blank") and ok

	# ---- the door: it is a press on the bar, and only with a scout ----------------------
	scr._hover_row = -1
	ok = _assert(scr._hit(Vector2(250, 450)) == "ours_open",
		"a tap on the bar opens the OURS panel") and ok
	ok = _assert(scr.extra_filters_active() == 0, "no filters set -> 0 active") and ok
	scr._attr_idx["PA"] = 8
	ok = _assert(scr.extra_filters_active() == 1, "one threshold -> 1 active") and ok
	scr._sort_i = 1
	ok = _assert(scr.extra_filters_active() == 2, "+ a sort -> 2 active") and ok
	scr._attr_idx["PA"] = -1
	scr._sort_i = -1
	scr.setup({}, false, [], "Bolton W", "mwm", "1997-98", 3, "Premier League", 59)
	ok = _assert(scr._hit(Vector2(250, 450)) == "",
			"no scout hired -> the bar is dead, as the whole body is (43)") and ok

	# ---- the press wiring: held row frames, release clears -------------------------------
	scr.setup(scout, false, rows, "Bolton W", "mwm", "1997-98", 3, "Premier League", 59)
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.position = Vector2(200, ScoutScreen.ROW_Y0 + ScoutScreen.ROW_PITCH + 5)
	down.pressed = true
	scr._on_input(down)
	ok = _assert(scr._hover_row == 1, "press on row 2 -> rollover on row 2") and ok
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.position = down.position
	up.pressed = false
	scr._on_input(up)
	ok = _assert(scr._hover_row == -1, "release -> the rollover clears") and ok

	# ---- the name rule the readout depends on -------------------------------------------
	# A mixed-case legalName is the original's own rendering and is printed verbatim; the
	# rebuild is only for the 97 all-uppercase records. Five frame witnesses.
	ok = _assert(PMChrome.card_name({"name": "De la Peña",
		"legalName": "Iván DE LA PEÑA López"}) == "Iván DE LA PEÑA López",
		"middle surname survives (ficha p0282)") and ok
	ok = _assert(PMChrome.card_name({"name": "Del Piero",
		"legalName": "Alessandro DEL PIERO"}) == "Alessandro DEL PIERO",
		"compound surname (ficha p0242)") and ok
	ok = _assert(PMChrome.card_name({"name": "VAN DER GOUW",
		"legalName": "RAIMOND VAN DER GOUW"}) == "Raimond VAN DER GOUW",
		"all-uppercase input still takes the rebuild (081)") and ok

	scr.queue_free()
	await process_frame
	print("\n%s" % ("ALL PASS" if ok else "FAILURES: %d" % _fails))
	quit(0 if ok else 1)


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	if not cond:
		_fails += 1
	return cond
