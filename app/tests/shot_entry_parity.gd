extends SceneTree
## Frame-parity captures of the career-entry screens in the EXACT states the
## original walkthrough frames show, for pixel-diffing against them:
##   nivel_003.png      NivelScreen settled (zoom done)          vs 003_154332
##   nivel_005.png      + LOAD GAME modal open (no save)         vs 005_154338
##   seleccion_008.png  fresh (slot 1 active, PLAYER 1)          vs 008_154345
##   seleccion_011.png  slot 1 locked MWM/Man Utd, PLAYER 2      vs 011_154354
##   pretemp_013.png    fresh (Man Utd, ENGLAND panel)           vs 013_154358
##   teamoffer_086.png  Thornley card, row-1 REFUSE (fresh)      vs 086_164647 (run 3)
##   teamoffer_088.png  row-1 toggled ACCEPT                     vs 088_164650 (run 3)
## Needs a real renderer (Xvfb / local X11), same as shot_screens.gd:
##   PM98_SHOT_DIR=out godot --rendering-driver opengl3 --path app --script res://tests/shot_entry_parity.gd

func _initialize() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("SHOTS SKIPPED: needs a rendering driver (xvfb/X11), not --headless")
		quit(1)
		return
	var dir := OS.get_environment("PM98_SHOT_DIR")
	if dir == "":
		dir = "/tmp"
	get_root().size = Vector2i(640, 480)

	# autoloads are absent under --script: bring the real GameDB up by hand
	var gamedb: Node = get_root().get_node_or_null("GameDB")
	if gamedb == null:
		gamedb = load("res://scripts/GameDB.gd").new()
		gamedb.name = "GameDB"
		get_root().add_child(gamedb)
		await process_frame

	# ---- NIVEL settled + modal (the dialog overlays the LIVE title screen) -------
	var title: Control = load("res://scenes/TitleScreen.gd").new()
	_mount(title)
	await process_frame
	var nivel: NivelScreen = load("res://scenes/NivelScreen.gd").new()
	_mount(nivel)
	await process_frame
	nivel.setup(false)
	for i in 14:      # let the 0.15s zoom tween finish
		await process_frame
	nivel._zoom = 1.0
	nivel.queue_redraw()
	await _shot(dir, "nivel_003.png")
	nivel._modal = true
	nivel.queue_redraw()
	await _shot(dir, "nivel_005.png")
	nivel.queue_free()
	title.queue_free()
	await process_frame

	# ---- SELECCION fresh + locked ------------------------------------------------
	var sel: SeleccionScreen = load("res://scenes/SeleccionScreen.gd").new()
	_mount(sel)
	await process_frame
	sel.setup(gamedb.leagues, false, Callable(gamedb, "clubs_in_league"))
	await _shot(dir, "seleccion_008.png")
	# frame 011 state: slot 1 locked to MWM / Manchester Utd., PLAYER 2 active
	var manu := {}
	for c in gamedb.clubs_in_league(str(gamedb.leagues[0].get("id", ""))):
		if str(c.get("name", "")).begins_with("MANCHESTER U"):
			manu = c
	sel._slots[0] = {"name": "MWM", "club": manu, "league": gamedb.leagues[0]}
	sel._active = 1
	sel.queue_redraw()
	await _shot(dir, "seleccion_011.png")
	sel.queue_free()
	await process_frame

	# ---- PRESEASON fresh ----------------------------------------------------------
	var pre: PreseasonScreen = load("res://scenes/PreseasonScreen.gd").new()
	_mount(pre)
	await process_frame
	pre.setup("Manchester Utd.", "MWM", gamedb.leagues, Callable(gamedb, "clubs_in_league"),
		func(_en: String) -> Array: return [])
	await _shot(dir, "pretemp_013.png")
	# frame 015 state: HUNGARY flag tapped -> strip names it, its flag enlarges,
	# panel stays ENGLAND
	pre._strip_country = "HUNGARY"
	for m in pre._markers:
		if str(m["name"]) == "HUNGARY":
			pre._sel_flag = m
	pre.queue_redraw()
	await _shot(dir, "pretemp_015.png")
	pre.queue_free()
	await process_frame

	# ---- TEAM OFFER (run-3 frames 086/088: Thornley, Aston Villa bid) -------------
	var manu2 := {}
	for c in gamedb.clubs_in_league(str(gamedb.leagues[0].get("id", ""))):
		if str(c.get("name", "")).begins_with("MANCHESTER U"):
			manu2 = c
	var thornley := {}
	for p in manu2.get("players", []):
		if str(p.get("name", "")) == "THORNLEY":
			thornley = (p as Dictionary).duplicate()
	# the frame's live-form values (FITNESS/MORAL are dynamic; AGE as of week 3)
	thornley["fitness"] = 67
	thornley["morale"] = 85
	thornley["age"] = 22
	var toffer: TeamOfferScreen = load("res://scenes/TeamOfferScreen.gd").new()
	_mount(toffer)
	await process_frame
	toffer.setup(thornley, manu2, [{"buyer_id": -1, "buyer_name": "ASTON VILLA",
		"offer": 8644999}], 9500000, 500000, 4, 4, [0])
	await _shot(dir, "teamoffer_086.png")
	toffer._accept[0] = true    # frame 088: the row-1 chip toggled to ACCEPT
	toffer.queue_redraw()
	await _shot(dir, "teamoffer_088.png")
	toffer.queue_free()
	await process_frame

	print("PARITY SHOTS DONE")
	quit(0)


func _mount(n: Control) -> void:
	get_root().add_child(n)
	n.set_anchors_preset(Control.PRESET_TOP_LEFT)
	n.position = Vector2.ZERO
	n.size = Vector2(640, 480)


func _shot(dir: String, name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var img := get_root().get_texture().get_image()
	var err := img.save_png(dir.path_join(name))
	print("SHOT %s err=%d %dx%d" % [name, err, img.get_width(), img.get_height()])
