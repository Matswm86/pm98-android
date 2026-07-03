extends SceneTree
## Frame-parity captures of the career-entry screens in the EXACT states the
## original walkthrough frames show, for pixel-diffing against them:
##   nivel_003.png      NivelScreen settled (zoom done)          vs 003_154332
##   nivel_005.png      + LOAD GAME modal open (no save)         vs 005_154338
##   seleccion_008.png  fresh (slot 1 active, PLAYER 1)          vs 008_154345
##   seleccion_011.png  slot 1 locked MWM/Man Utd, PLAYER 2      vs 011_154354
##   pretemp_013.png    fresh (Man Utd, ENGLAND panel)           vs 013_154358
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
