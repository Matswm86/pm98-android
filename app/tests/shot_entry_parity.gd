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
##   tactics_014.png    TACTICS board, Man Utd 3-5-2, RATING     vs 014_162413 (run 2)
##   lineup_155.png     LINE-UP, MU home vs Sao Paulo, Wed 6     vs 155_162931 (run 2, header ROI)
##   rival_015.png      VIEW RIVAL, Barcelona vs MU, Mon 4       vs 015_162415 (run 2, header ROI)
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

	# ---- MAKE-OFFER card (run-3 frames 101/113: Taylor, Blackpool) ----------------
	var bpool := {}
	for lg in gamedb.leagues:
		for c in gamedb.clubs_in_league(str(lg.get("id", ""))):
			if str(c.get("name", "")) == "BLACKPOOL":
				bpool = c
	var taylor := {}
	for p in bpool.get("players", []):
		if str(p.get("legalName", "")) == "SCOTT TAYLOR":
			taylor = (p as Dictionary).duplicate()
	# the frame's live-form values (FITNESS/MORAL dynamic; AGE as of week 3)
	taylor["age"] = 21
	taylor["fitness"] = 67
	taylor["morale"] = 81
	var moffer: Control = load("res://scenes/MakeOfferScreen.gd").new()
	_mount(moffer)
	await process_frame
	moffer.setup(taylor, bpool, 3000000, 3200000)
	await _shot(dir, "makeoffer_101.png")
	# frame 113 state: offer 3,050,000 / wage 25,000 / Scoring bonus checked £5,000
	moffer._offer = 3050000
	moffer._wage_yearly = 25000
	moffer._checked["scoring"] = true
	moffer.queue_redraw()
	await _shot(dir, "makeoffer_113.png")
	moffer.queue_free()
	await process_frame

	# ---- TACTICS board (run-2 frame 014: Man Utd, 3-5-2, RATING view) -------------
	var manu3 := {}
	for c in gamedb.clubs_in_league(str(gamedb.leagues[0].get("id", ""))):
		if str(c.get("name", "")).begins_with("MANCHESTER U"):
			manu3 = c
	# The frame's XI in slot order (read off the pitch discs: outfield slots 0..9 =
	# shirts 2,3,21,6,8,7,10,9,11,20; GK 1) and its displayed AVs — the AV formula
	# is un-RE'd (tacticas_screen_re.md), so the frame-true values are injected.
	var frame_av := {"SCHMEICHEL": 88, "GARY NEVILLE": 81, "IRWIN": 84, "BERG": 85,
		"PALLISTER": 81, "BUTT": 83, "BECKHAM": 87, "SHERINGHAM": 80, "COLE": 84,
		"GIGGS": 87, "SOLSKJAER": 85}
	var order := ["SCHMEICHEL", "GARY NEVILLE", "IRWIN", "BERG", "PALLISTER", "BUTT",
		"BECKHAM", "SHERINGHAM", "COLE", "GIGGS", "SOLSKJAER"]
	var xi_ids: Array = []
	for nm in order:
		for p in manu3.get("players", []):
			if str(p.get("name", "")) == nm:
				(p as Dictionary)["av"] = frame_av[nm]
				xi_ids.append(int(p.get("id", -1)))
	var tac := Tactics.new()
	tac.formation = "3-5-2"
	tac.xi = xi_ids
	var board: TacticsBoardScreen = load("res://scenes/TacticsBoardScreen.gd").new()
	_mount(board)
	await process_frame
	# frame 014 header: preseason friendly at F.C. Barcelona, Monday 4 August 1997
	board.setup(manu3, tac, "", "Premier League", "1997-98", 1,
		{"mode": "fixture", "top": "F.C. Barcelona", "bottom": "Manchester Utd.",
		"home_id": 1000, "away_id": 40, "weekday": "Monday", "day": "4",
		"month": "August", "year": "1997",
		"status_top": "Preseason", "status_bottom": "Preparation"})
	await _shot(dir, "tactics_014.png")
	board.queue_free()
	await process_frame

	# ---- LINE-UP header (run-2 frame 155: MU home vs Sao Paulo, Wednesday 6) ------
	# Header-ROI pair only: the LINE-UP body parity story is separate, so the XI is
	# just a valid auto-pick; the diff scopes to the y<62 match-header band.
	var lu: LineupScreen = load("res://scenes/LineupScreen.gd").new()
	_mount(lu)
	await process_frame
	lu.setup(manu3, Tactics.auto_pick(manu3, "4-4-2"), "", "Premier League", "1997-98", 1,
		{"mode": "fixture", "top": "Manchester Utd.", "bottom": "Sao Paulo",
		"home_id": 40, "away_id": 1301, "weekday": "Wednesday", "day": "6",
		"month": "August", "year": "1997",
		"status_top": "Preseason", "status_bottom": "Preparation"})
	await _shot(dir, "lineup_155.png")
	lu.queue_free()
	await process_frame

	# ---- VIEW RIVAL header (run-2 frame 015: at F.C. Barcelona, Monday 4) ---------
	# Header-ROI pair only (body story separate); assistant present so the report
	# body renders, as in the frame.
	var barca: Dictionary = gamedb.club(1000)
	var rv: RivalScreen = load("res://scenes/RivalScreen.gd").new()
	_mount(rv)
	await process_frame
	rv.setup(barca, manu3, 1, "A. Leigh", "Premier League", "1997-98", 1,
		{"mode": "fixture", "top": "F.C. Barcelona", "bottom": "Manchester Utd.",
		"home_id": 1000, "away_id": 40, "weekday": "Monday", "day": "4",
		"month": "August", "year": "1997",
		"status_top": "Preseason", "status_bottom": "Preparation"})
	await _shot(dir, "rival_015.png")
	rv.queue_free()
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
