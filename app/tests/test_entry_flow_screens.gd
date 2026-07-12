extends SceneTree
## Headless wiring test for the career-entry flow (walkthrough frames 002-016):
## NIVEL "SELECT LEVEL OF THE GAME" dialog -> SELECCION real body -> PRESEASON screen.
## Asserts the RE'd geometry anchors, the baked assets, the exact .rdata caption
## strings, the frame-verified CONTINUE semantics (lock slot -> blank CONTINUE starts),
## the 47-flag Europe map spec, and the Career save round-trip of the entry picks.
##   ~/godot462 --headless --path app --script res://tests/test_entry_flow_screens.gd


func _initialize() -> void:
	_run()


## Nodes only get _ready on the first process frame, so this is async: each screen is
## added, then a frame is awaited before poking it (same reason shot_screens awaits).
func _run() -> void:
	var ok := true

	# ---- baked assets --------------------------------------------------------
	for p in ["res://art/screens/nivel/fondo.png", "res://art/screens/nivel/entrenador0.png",
			"res://art/screens/nivel/entrenador1.png", "res://art/screens/nivel/manager0.png",
			"res://art/screens/nivel/presidente0.png", "res://art/screens/nivel/total1.png",
			"res://art/screens/nivel/ok.png", "res://art/icons/carga.png",
			"res://art/icons/borra.png", "res://art/screens/pretemp/europa.png",
			"res://art/screens/pretemp/sudamerica.png",
			"res://art/screens/pretemp/hoja_calendario.png"]:
		ok = _assert(ResourceLoader.exists(p), "asset baked: %s" % p) and ok

	# ---- NIVEL geometry (docs/re/nivel_screen_re.md) ---------------------------
	ok = _assert(NivelScreen.DLG == Rect2(93, 32, 453, 415), "dialog POS(93,32) 453x415") and ok
	ok = _assert(NivelScreen.R_ENT == Rect2(30, 55, 120, 105)
		and NivelScreen.R_MAN == Rect2(279, 56, 149, 104)
		and NivelScreen.R_PRE == Rect2(28, 209, 132, 124)
		and NivelScreen.R_TOT == Rect2(272, 206, 153, 128), "level art rects (capstone)") and ok
	ok = _assert(NivelScreen.R_CHK == Rect2(14, 364, 14, 14), "Players age ? checkbox (14,364)") and ok
	ok = _assert(NivelScreen.R_LOAD == Rect2(6, 385, 132, 25)
		and NivelScreen.R_CANCEL == Rect2(143, 385, 103, 25), "LOAD/CANCEL on the strip") and ok
	# exact .rdata bullet strings
	ok = _assert(NivelScreen.BULLETS["trainer"] == ["- Automatic finances", "- Automatic contract renewal"]
		and NivelScreen.BULLETS["manager"] == ["- Automatic contract renewal"]
		and NivelScreen.BULLETS["accountant"] == ["- Automatic tactics and squad"]
		and NivelScreen.BULLETS["total"] == ["- Total control"], "level bullets verbatim") and ok

	var nivel: NivelScreen = load("res://scenes/NivelScreen.gd").new()
	get_root().add_child(nivel)
	await process_frame
	_pin(nivel)
	nivel.setup(true, {"club": "MANCHESTER UTD.", "name": "MWM"})
	ok = _assert(nivel.has_signal("level_chosen") and nivel.has_signal("load_game")
		and nivel.has_signal("cancel_pressed"), "NIVEL signals live") and ok
	var picked: Array = []
	nivel.level_chosen.connect(func(lv: String, age: bool) -> void: picked.append_array([lv, age]))
	nivel._players_age = true
	nivel._on_input(_tap(true, Vector2(93 + 90, 32 + 100)))   # inside TRAINER art
	nivel._on_input(_tap(false, Vector2(93 + 90, 32 + 100)))
	ok = _assert(picked == ["trainer", true], "tap TRAINER art -> level_chosen(trainer, age)") and ok
	nivel.queue_free()

	# ---- SELECCION real body (frames 008-012) ---------------------------------
	var leagues := [{"id": "L1", "name": "Premier League"}, {"id": "L2", "name": "First Division"}]
	var clubs: Array = []
	for i in 20:
		clubs.append({"id": i + 1, "name": "CLUB %02d" % (i + 1)})
	var sel: SeleccionScreen = load("res://scenes/SeleccionScreen.gd").new()
	get_root().add_child(sel)
	await process_frame
	_pin(sel)
	sel.setup(leagues, false, func(_lid: String) -> Array: return clubs.duplicate())
	ok = _assert(sel._slots.size() == 20, "20 PLAYER save slots") and ok
	ok = _assert(sel._kit_cols() == 10, "kit panel = 2 rows of 10 for 20 clubs") and ok
	ok = _assert(SeleccionScreen.R_CONTINUE == Rect2(508, 427, 112, 25)
		and SeleccionScreen.R_RETURN == Rect2(25, 427, 112, 25), "reversed bottom row") and ok
	var begun: Array = []
	sel.career_begun.connect(func(nm: String, lg: Dictionary, cl: Dictionary) -> void:
		begun.append_array([nm, lg, cl]))
	# frame 010 -> 011: name + club + CONTINUE locks slot 1, PLAYER 2 becomes active
	sel._name_edit.text = "MWM"
	sel._sel = 3
	sel._continue()
	ok = _assert(not sel._slots[0].is_empty() and sel._active == 1 and begun.is_empty(),
		"CONTINUE locks slot 1 and advances to PLAYER 2 (no start yet)") and ok
	# frame 012 -> 013: blank CONTINUE starts player 1's career
	sel._continue()
	ok = _assert(not begun.is_empty() and str(begun[0]) == "MWM"
		and str((begun[2] as Dictionary).get("name", "")) == "CLUB 04",
		"blank CONTINUE starts the game with slot 1's pick") and ok
	sel.queue_free()

	# ---- PRESEASON (frames 013-016) --------------------------------------------
	ok = _assert(PreseasonScreen.R_SKIP == Rect2(503, 333, 112, 25)
		and PreseasonScreen.R_DELETE == Rect2(383, 440, 112, 25)
		and PreseasonScreen.R_CONTINUE == Rect2(503, 440, 112, 25)
		and PreseasonScreen.R_MAP == Rect2(27, 80, 300, 220)
		and PreseasonScreen.R_TAB_EU == Rect2(3, 78, 21, 112), "preseason reversed rects") and ok
	var pre: PreseasonScreen = load("res://scenes/PreseasonScreen.gd").new()
	get_root().add_child(pre)
	await process_frame
	_pin(pre)
	pre.setup("Manchester Utd.", "MWM", leagues,
		func(_lid: String) -> Array: return clubs.duplicate(),
		func(_en: String) -> Array: return [])
	ok = _assert(pre._markers.size() == 47, "47 Europe flag markers (frame 013 spec)") and ok
	ok = _assert(pre._markers_sa.size() == 10,
		"10 S.America flag markers (wine capture 2026-07-12)") and ok
	var codes_ok := true
	var names := {}
	for m in pre._markers:
		names[str(m["name"])] = true
		if PMChrome.flag(int(m["code"])) == null:
			codes_ok = false
	ok = _assert(codes_ok, "every marker code has baked flag art") and ok
	ok = _assert(names.has("ENGLAND") and names.has("HUNGARY") and names.has("GREECE")
		and names.has("ICELAND") and names.has("ISRAEL"), "marker identities incl. frame-015 HUNGARY") and ok
	ok = _assert(pre._country == "ENGLAND" and pre._country_clubs.size() == 20,
		"boots on ENGLAND with the division's clubs") and ok
	# pick two rivals + delete one; SKIP hands back the picks
	var done: Array = []
	pre.preseason_done.connect(func(rv: Array) -> void: done.append_array(rv))
	pre._rivals.append(clubs[0])
	pre._rivals.append(clubs[1])
	pre._on_input(_tap(true, Vector2(390, 450)))    # DELETE
	pre._on_input(_tap(false, Vector2(390, 450)))
	ok = _assert(pre._rivals.size() == 1, "DELETE clears the last filled rival slot") and ok
	pre._on_input(_tap(true, Vector2(560, 345)))    # SKIP
	pre._on_input(_tap(false, Vector2(560, 345)))
	ok = _assert(done.size() == 1 and str((done[0] as Dictionary).get("name", "")) == "CLUB 01",
		"SKIP/CONTINUE emits the picked rivals") and ok
	pre.queue_free()

	# ---- PRESEASON venue rule (FUN_004c7570 + FUN_0057a340, captures 2026-07-12) --
	var strong := {"id": 90, "name": "STRONG", "stadium": "Big Ground",
		"players": [{"attrs": {"VE": 90, "RE": 90, "AG": 90, "CA": 90}}]}
	var tiny := {"id": 91, "name": "TINY", "stadium": "Tiny Park",
		"players": [{"attrs": {"VE": 10, "RE": 10, "AG": 10, "CA": 10}}]}
	var twin := {"id": 92, "name": "TWIN", "stadium": "Twin Ground",
		"players": [{"attrs": {"VE": 50, "RE": 51, "AG": 52, "CA": 53}}]}
	var own := {"id": 93, "name": "OWN", "stadium": "Own Ground",
		"players": [{"attrs": {"VE": 50, "RE": 51, "AG": 52, "CA": 53}}]}
	ok = _assert(PreseasonScreen.club_av(strong) == 90 and PreseasonScreen.club_av(own) == 51,
		"club_av = floored engine 4-attr squad average") and ok
	var pre2: PreseasonScreen = load("res://scenes/PreseasonScreen.gd").new()
	get_root().add_child(pre2)
	await process_frame
	_pin(pre2)
	pre2.setup("Own", "MWM", leagues,
		func(_lid: String) -> Array: return [strong, tiny, twin],
		func(_en: String) -> Array: return [], 93, own)
	for i in 3:
		pre2._on_input(_tap(true, pre2._kit_rect(i).get_center()))
		pre2._on_input(_tap(false, pre2._kit_rect(i).get_center()))
	ok = _assert(pre2._rivals.size() == 3
		and pre2._rivals[0].get("home") == false
		and str(pre2._rivals[0].get("venue_stadium")) == "Big Ground"
		and pre2._rivals[1].get("home") == true
		and str(pre2._rivals[1].get("venue_stadium")) == "Own Ground"
		and pre2._rivals[2].get("home") == false
		and str(pre2._rivals[2].get("venue_stadium")) == "Twin Ground",
		"venue = stronger club's ground; ties away (stadium line witnesses)") and ok
	pre2.queue_free()

	# ---- Career round-trip of the entry picks -----------------------------------
	var dc := {"id": 1, "name": "CLUB 01", "capacity": 30000, "players": []}
	var career := Career.create(dc, leagues[0], clubs, leagues)
	career.manager_level = "trainer"
	career.players_age = true
	career.preseason_rivals = [{"date": "1997-08-01", "club_id": 2, "name": "CLUB 02"}]
	var back := Career.from_dict(career.to_dict())
	ok = _assert(back.manager_level == "trainer" and back.players_age
		and back.preseason_rivals.size() == 1
		and str((back.preseason_rivals[0] as Dictionary).get("date", "")) == "1997-08-01",
		"entry picks survive the save round-trip") and ok

	# country bridge data ships in the app
	ok = _assert(FileAccess.file_exists("res://data/country_es_en.json")
		and FileAccess.file_exists("res://data/pretemp_flag_markers.json"),
		"country bridge + flag spec ship in app/data") and ok

	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	quit(0 if ok else 1)


## Pin a screen to the native 640x480 so design coords == event coords (scale 1).
func _pin(n: Control) -> void:
	n.set_anchors_preset(Control.PRESET_TOP_LEFT)
	n.position = Vector2.ZERO
	n.size = Vector2(640, 480)


func _tap(pressed: bool, pos: Vector2) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = pressed
	e.position = pos
	return e


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
