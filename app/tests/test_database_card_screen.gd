extends SceneTree
## Headless wiring test for the frame-baked DATA BASE player card (Dbasewin.exe,
## app/scenes/DataBaseCardScreen.gd): confirms the bake-pinned geometry (PANEL,
## NAME_BOX, PHOTO_BOX, BTN_PRINT, BTN_RETURN, SCROLL_UP, the 7 TAB_X hit rects)
## stays inside the 640x480 canvas, the chrome art + PROMAN/kkita fonts referenced
## by _ready()/_draw() exist and load, setup() wires a REAL player+club (sourced
## from GameDB, matching the frame-verified sentinel table in
## docs/re/dbase_player_card_re.md), the tab-disable SENTINEL (all-false _tab_ok)
## dead-clicks a disabled tab while an enabled one still switches _view, RETURN
## fires back_pressed, and PRINT is the documented no-op (mobile has no printer).
##   cd /home/mats/MWM-AI/projects/pm98-android && timeout 150 /home/mats/godot4 \
##     --headless --path app --script res://tests/test_database_card_screen.gd


func _initialize() -> void:
	_run()


func _click(screen: DataBaseCardScreen, pos: Vector2) -> void:
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.position = pos
	press.pressed = true
	screen._on_input(press)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.position = pos
	release.pressed = false
	screen._on_input(release)


func _run() -> void:
	var ok := true

	# ---- bake-pinned geometry stays inside the 640x480 design canvas ----------
	var rects: Array = [["PANEL", DataBaseCardScreen.PANEL], ["NAME_BOX", DataBaseCardScreen.NAME_BOX],
		["PHOTO_BOX", DataBaseCardScreen.PHOTO_BOX], ["BTN_PRINT", DataBaseCardScreen.BTN_PRINT],
		["BTN_RETURN", DataBaseCardScreen.BTN_RETURN], ["SCROLL_UP", DataBaseCardScreen.SCROLL_UP]]
	for i in DataBaseCardScreen.TAB_X.size():
		var tx: Array = DataBaseCardScreen.TAB_X[i]
		rects.append(["TAB_X[%d]" % i,
			Rect2(tx[0], DataBaseCardScreen.TAB_Y0, tx[1] - tx[0], 20)])
	for entry in rects:
		var r: Rect2 = entry[1]
		ok = _assert(r.position.x >= 0 and r.position.y >= 0 and r.end.x <= 640 and r.end.y <= 480,
			"rect in canvas: %s" % entry[0]) and ok

	# ---- chrome art + fonts the screen's own _ready()/_draw() resolve ---------
	# PMChrome.font("8"/"10"/"12"/"18") -> proman*.fnt; _ready() loads kkita.fnt
	# directly; _draw() blits these exact frame-cut PNGs on the default PERSONAL
	# DATA view regardless of tab state (view_pdata/title_pdata/bottom_data/
	# btn_print/btn_return/banner/fondo_dbase are unconditional; tab0..6 always
	# render in either the _dis or _rest state).
	var assets := ["res://art/fonts/proman8.fnt", "res://art/fonts/proman10.fnt",
		"res://art/fonts/proman12.fnt", "res://art/fonts/proman18.fnt", "res://art/fonts/kkita.fnt",
		"res://art/screens/fondo_dbase.png", "res://art/screens/dbase_card/banner.png",
		"res://art/screens/dbase_card/btn_print.png", "res://art/screens/dbase_card/btn_return.png",
		"res://art/screens/dbase_card/view_pdata.png", "res://art/screens/dbase_card/title_pdata.png",
		"res://art/screens/dbase_card/bottom_data.png"]
	for i in 7:
		assets.append("res://art/screens/dbase_card/tab%d_dis.png" % i)
		assets.append("res://art/screens/dbase_card/tab%d_rest.png" % i)
	for path in assets:
		ok = _assert(ResourceLoader.exists(path), "asset present: %s" % path) and ok
		ok = _assert(load(path) != null, "asset loads: %s" % path) and ok

	# ---- source REAL players+clubs from GameDB (no autoload under --script) ---
	var gamedb: Node = load("res://scripts/GameDB.gd").new()
	gamedb.name = "GameDB"
	get_root().add_child(gamedb)
	for _i in 10:
		if not gamedb.clubs.is_empty():
			break
		await process_frame
	ok = _assert(not gamedb.clubs.is_empty(), "GameDB loaded clubs") and ok
	if gamedb.clubs.is_empty():
		print("\nFAILURES ABOVE (GameDB never loaded)")
		quit(1)
		return

	var by_id := {}
	var club_of := {}
	for c in gamedb.clubs:
		for p in c.get("players", []):
			by_id[int(p.get("id", -1))] = p
			club_of[int(p.get("id", -1))] = c

	# Schmeichel (45, Man Utd 40): docs/re/dbase_player_card_re.md's own witness
	# for "ALL enabled" (6 real pages + a real career blob, bios.json intl=Denmark).
	# Hiden (93, Leeds Utd 43): the RE doc's "ALL 7 disabled" witness (TXT ?/5x
	# Sin datos./career Sin datos.) -- the all-false sentinel this test proves stays
	# inert.
	ok = _assert(by_id.has(45) and by_id.has(93), "GameDB holds both walked witness players") and ok
	if not (by_id.has(45) and by_id.has(93)):
		print("\nFAILURES ABOVE (walked witness players missing from the shipped DB)")
		quit(1)
		return
	var schmeichel: Dictionary = by_id[45]
	var man_utd: Dictionary = club_of[45]
	var hiden: Dictionary = by_id[93]
	var leeds: Dictionary = club_of[93]
	ok = _assert(int(man_utd.get("id", -1)) == 40, "Schmeichel's club is Man Utd (40)") and ok
	ok = _assert(int(leeds.get("id", -1)) == 43, "Hiden's club is Leeds Utd (43)") and ok

	# ---- instantiate, add_child, await 3 frames --------------------------------
	get_root().size = Vector2i(640, 480)
	var screen: DataBaseCardScreen = load("res://scenes/DataBaseCardScreen.gd").new()
	get_root().add_child(screen)
	for _i in 3:
		await process_frame
	ok = _assert(screen._f8 != null and screen._f10 != null and screen._f12 != null
		and screen._f18 != null and screen._fkk != null, "PROMAN + kkita fonts loaded") and ok
	# Default state pre-setup: _tab_ok starts all-false, so _ready()'s queue_redraw()
	# already baked the unconditional chrome + the "dis" tab state into _tex.
	for key in ["banner", "view_pdata", "title_pdata", "bottom_data", "btn_print", "btn_return"]:
		ok = _assert(screen._tex.get(key) != null, "baked chrome loaded: %s" % key) and ok

	# ---- setup() wires a REAL player+club --------------------------------------
	screen.setup(schmeichel, man_utd)
	await process_frame
	ok = _assert(int(screen._p.get("id", -1)) == 45, "setup wires the REAL player") and ok
	ok = _assert(int(screen._club.get("id", -1)) == 40, "setup wires the REAL club") and ok
	ok = _assert(screen._view == "pdata", "setup defaults to PERSONAL DATA") and ok
	ok = _assert(screen._scroll == 0, "setup resets scroll") and ok
	ok = _assert(not screen._bio.is_empty(), "setup wires Schmeichel's bios.json entry") and ok
	ok = _assert(str(screen._bio.get("intl", "")) == "Denmark",
		"bio intl renders VERBATIM ('Denmark', not re-cased)") and ok
	# Schmeichel is the RE doc's ALL-enabled witness (6 real pages + a real career blob).
	ok = _assert(screen._tab_ok == [true, true, true, true, true, true, true],
		"Schmeichel: every tab enabled (real bios.json, section_enabled rule)") and ok

	screen.queue_redraw()
	for _i in 3:
		await process_frame
	# With _tab_ok all true and _view=="pdata" (no tab selected), every tab draws
	# its "rest" state -- proves _draw_tabs() actually reads the wired _tab_ok,
	# not the pre-setup all-false default.
	for i in 7:
		ok = _assert(screen._tex.get("tab%d_rest" % i) != null,
			"tab%d renders 'rest' once its section is enabled" % i) and ok

	# ---- _hit(): BTN_RETURN center resolves; a clearly-empty point does not ---
	ok = _assert(screen._hit(DataBaseCardScreen.BTN_RETURN.get_center()) == "return",
		"_hit: BTN_RETURN centre resolves to the return action") and ok
	ok = _assert(screen._hit(Vector2(0, 0)) == "",
		"_hit: a clearly-empty design-space point resolves to nothing") and ok

	# RETURN tap fires the real back_pressed signal. (Array cell: GDScript lambdas
	# capture outer locals BY VALUE, so a plain bool wouldn't observe the signal.)
	screen.size = Vector2(640, 480)
	var back_fired := [false]
	screen.back_pressed.connect(func() -> void: back_fired[0] = true)
	_click(screen, DataBaseCardScreen.BTN_RETURN.get_center())
	ok = _assert(back_fired[0], "RETURN tap emits back_pressed") and ok

	# PRINT is the documented no-op (mobile has no printer): _hit resolves it,
	# but the dispatch's `elif hit == "print": pass` leaves state untouched.
	ok = _assert(screen._hit(DataBaseCardScreen.BTN_PRINT.get_center()) == "print",
		"_hit: BTN_PRINT centre resolves to the print action") and ok
	var view_before_print := screen._view
	var scroll_before_print := screen._scroll
	_click(screen, DataBaseCardScreen.BTN_PRINT.get_center())
	ok = _assert(screen._view == view_before_print and screen._scroll == scroll_before_print,
		"PRINT tap is a deliberate no-op (view/scroll unchanged)") and ok

	# A genuinely enabled tab (Schmeichel's CAREER, index 3) still switches _view --
	# the positive control proving the dispatch is wired, not just coincidentally inert.
	var career_x: Array = DataBaseCardScreen.TAB_X[3]
	_click(screen, Vector2((career_x[0] + career_x[1]) * 0.5, DataBaseCardScreen.TAB_Y0 + 10))
	ok = _assert(screen._view == "career", "enabled CAREER tab tap switches _view") and ok

	# ---- the all-false sentinel keeps EVERY tab a dead-click -------------------
	# Hiden (93) is the RE doc's "ALL 7 disabled" witness (TXT ?/Sin datos. x5/
	# career Sin datos.) -- section_enabled() computes every entry false.
	screen.setup(hiden, leeds)
	await process_frame
	ok = _assert(screen._tab_ok == [false, false, false, false, false, false, false],
		"Hiden: all-false _tab_ok is the disable SENTINEL (RE-doc witness)") and ok
	ok = _assert(screen._view == "pdata", "setup() resets the view for the new player") and ok
	for i in DataBaseCardScreen.TAB_KEYS.size():
		var tx2: Array = DataBaseCardScreen.TAB_X[i]
		_click(screen, Vector2((tx2[0] + tx2[1]) * 0.5, DataBaseCardScreen.TAB_Y0 + 10))
		ok = _assert(screen._view == "pdata",
			"disabled tab %d (%s) dead-clicks: _view stays pdata" %
				[i, DataBaseCardScreen.TAB_KEYS[i]]) and ok

	# ---- final redraw, no crash -------------------------------------------------
	screen.queue_redraw()
	for _i in 3:
		await process_frame

	screen.queue_free()
	gamedb.queue_free()
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	quit(0 if ok else 1)


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
