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
##   alert_093.png      hub alert: McClair signing, OK normal    vs 093_164659 (run 3, box ROI)
##   alert_149.png      hub alert: 2-line rejection, OK hot      vs 149_164911 (run 3, box ROI)
##   ficha_081.png      FICHA: Van der Gouw, Free+Matches(20), OK held  vs 081_154619 (card ROI)
##   ficha_084.png      FICHA: Solskjaer, Free+Scoring(£5,000), OK held vs 084_154626 (card ROI)
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
		if str(c.get("name", "")).to_upper().begins_with("MANCHESTER U"):
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
		if str(c.get("name", "")).to_upper().begins_with("MANCHESTER U"):
			manu2 = c
	var thornley := {}
	for p in manu2.get("players", []):
		if str(p.get("name", "")).to_upper() == "THORNLEY":
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
			if str(c.get("name", "")).to_upper() == "BLACKPOOL":
				bpool = c
	var taylor := {}
	for p in bpool.get("players", []):
		if str(p.get("legalName", "")).to_upper() == "SCOTT TAYLOR":
			taylor = (p as Dictionary).duplicate()
	# the frame's live-form values (FITNESS/MORAL dynamic; AGE as of week 3)
	taylor["age"] = 21
	taylor["fitness"] = 67
	taylor["morale"] = 81
	var moffer: Control = load("res://scenes/MakeOfferScreen.gd").new()
	_mount(moffer)
	await process_frame
	# Frame 101 is the ORIGINAL's cold-approach state: CLUB FEE £3,000,000, CLUB OFFER
	# £5,000. The port's cold default is the FEE instead (the owner deviation recorded
	# in MakeOfferScreen.setup — the stepper costs ~640 taps otherwise), so the parity
	# shot asks for the original's number explicitly. What this pair proves is the
	# CHROME and every other cell; the opening default is a caller-level choice and is
	# pinned by test_make_offer_seed, not here.
	moffer.setup(taylor, bpool, 3000000, 3200000, {"offer": MakeOfferScreen.FLOOR})
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
		if str(c.get("name", "")).to_upper().begins_with("MANCHESTER U"):
			manu3 = c
	# The frame's XI in slot order (read off the pitch discs: outfield slots 0..9 =
	# shirts 2,3,21,6,8,7,10,9,11,20; GK 1) and its displayed AVs — AV = Morale.av6
	# (FUN_00581e60), but it reads the frame's DYNAMIC FI/MO, which no fresh app
	# state reproduces, so the frame-true values are injected (morale_re.md).
	var frame_av := {"SCHMEICHEL": 88, "GARY NEVILLE": 81, "IRWIN": 84, "BERG": 85,
		"PALLISTER": 81, "BUTT": 83, "BECKHAM": 87, "SHERINGHAM": 80, "COLE": 84,
		"GIGGS": 87, "SOLSKJAER": 85}
	var order := ["SCHMEICHEL", "GARY NEVILLE", "IRWIN", "BERG", "PALLISTER", "BUTT",
		"BECKHAM", "SHERINGHAM", "COLE", "GIGGS", "SOLSKJAER"]
	var xi_ids: Array = []
	for nm in order:
		for p in manu3.get("players", []):
			if str(p.get("name", "")).to_upper() == nm:
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

	# ---- LINE-UP FULL FRAME (run-2 frame 155: MU home vs Sao Paulo, Wed 6) --------
	# The frame's exact state: 3-5-2 XI (tactics 014 slot order), the walked AVs
	# (frame-dynamic FI/MO — injected like tactics_014), Beckham INJURED
	# 7 weeks (FI 82 / MO 99 -> the gold row + UNDO), Solskjaer SELECTED (2px row
	# frame, name band, attr values, coverage zone + white markers), TEAM RATING
	# 77, and the save's bench/reserve order pinned on the club dict.
	var manu4: Dictionary = {}
	for c in gamedb.clubs_in_league(str(gamedb.leagues[0].get("id", ""))):
		if str(c.get("name", "")).to_upper().begins_with("MANCHESTER U"):
			manu4 = (c as Dictionary).duplicate()
	var av155 := {"SCHMEICHEL": 89, "GARY NEVILLE": 82, "IRWIN": 85, "BERG": 86,
		"PALLISTER": 82, "BUTT": 84, "BECKHAM": 88, "SHERINGHAM": 81, "COLE": 85,
		"GIGGS": 88, "SOLSKJAER": 86, "JOHNSEN": 82, "VAN DER GOUW": 81,
		"PHIL NEVILLE": 81, "SCHOLES": 82, "MCCLAIR": 82, "JORDI CRUYFF": 81,
		"KEANE": 87, "MAY": 80, "CURTIS": 79}
	var by_name := {}
	for p in manu4.get("players", []):
		by_name[str(p.get("name", "")).to_upper()] = p
		if av155.has(str(p.get("name", "")).to_upper()):
			(p as Dictionary)["av"] = av155[str(p.get("name", "")).to_upper()]
	var beck: Dictionary = by_name["BECKHAM"]
	beck["injured_weeks"] = 7
	beck["fitness"] = 82
	beck["morale"] = 99
	var xi155: Array = []
	for nm in ["SCHMEICHEL", "GARY NEVILLE", "IRWIN", "BERG", "PALLISTER", "BUTT",
			"BECKHAM", "SHERINGHAM", "COLE", "GIGGS", "SOLSKJAER"]:
		xi155.append(int((by_name[nm] as Dictionary).get("id", -1)))
	var pid_of := func(nm: String) -> int: return int((by_name[nm] as Dictionary).get("id", -1))
	manu4["bench"] = [pid_of.call("JOHNSEN"), pid_of.call("VAN DER GOUW"),
		pid_of.call("PHIL NEVILLE"), pid_of.call("SCHOLES"), pid_of.call("MCCLAIR")]
	manu4["reserves"] = [pid_of.call("JORDI CRUYFF"), pid_of.call("KEANE"),
		pid_of.call("MAY"), pid_of.call("CURTIS"), pid_of.call("CASPER"),
		pid_of.call("CLEGG"), pid_of.call("NEVLAND"), pid_of.call("THORNLEY")]
	manu4["team_rating"] = 77
	var tac155 := Tactics.new()
	tac155.formation = "3-5-2"
	tac155.xi = xi155
	var lu: LineupScreen = load("res://scenes/LineupScreen.gd").new()
	_mount(lu)
	await process_frame
	lu.setup(manu4, tac155, "", "Premier League", "1997-98", 1,
		{"mode": "fixture", "top": "Manchester Utd.", "bottom": "Sao Paulo",
		"home_id": 40, "away_id": 1301, "weekday": "Wednesday", "day": "6",
		"month": "August", "year": "1997",
		"status_top": "Preseason", "status_bottom": "Preparation"})
	lu._sel_pid = pid_of.call("SOLSKJAER")
	lu.queue_redraw()
	await _shot(dir, "lineup_155.png")
	lu.queue_free()
	await process_frame

	# ---- LINE-UP PARAMETERS view (run-1 frame 128: MU at Juventus, Fri 1 Aug) -----
	# FORMULA-DRIVEN pair: nothing but the frame-visible dynamics is injected.
	# FI/MO are set to the frame's own cells (FI 70 whole squad, MO per row);
	# every AV then comes out of the live Morale.av6 (frame-verified 20/20
	# exact) and TEAM RATING 82 out of the sourced sum-fit-XI/11 rule — no
	# "av"/"team_rating" overrides. EN column = the +0xa8 byte (99 across the
	# board, en_cap default). Same XI/bench/reserve order as 155; no injury,
	# no selection (T/I/S default block), PARAMETERS toggle active.
	var manu128: Dictionary = {}
	for c in gamedb.clubs_in_league(str(gamedb.leagues[0].get("id", ""))):
		if str(c.get("name", "")).to_upper().begins_with("MANCHESTER U"):
			manu128 = (c as Dictionary).duplicate(true)
	var mo128 := {"SCHMEICHEL": 97, "GARY NEVILLE": 95, "IRWIN": 99, "BERG": 93,
		"PALLISTER": 93, "BUTT": 99, "BECKHAM": 99, "SHERINGHAM": 99, "COLE": 99,
		"GIGGS": 99, "SOLSKJAER": 99, "JOHNSEN": 99, "VAN DER GOUW": 99,
		"PHIL NEVILLE": 99, "SCHOLES": 99, "MCCLAIR": 99, "JORDI CRUYFF": 99,
		"KEANE": 99, "MAY": 99, "CURTIS": 99}
	var by_name128 := {}
	for p in manu128.get("players", []):
		by_name128[str(p.get("name", "")).to_upper()] = p
		# earlier shot blocks mutate the SHARED gamedb dicts ("av" overrides,
		# Beckham's 155 injury) — scrub them so this pair stays formula-driven
		(p as Dictionary).erase("av")
		(p as Dictionary).erase("injured_weeks")
		(p as Dictionary).erase("suspended_weeks")
		if mo128.has(str(p.get("name", "")).to_upper()):
			(p as Dictionary)["fitness"] = 70
			(p as Dictionary)["morale"] = mo128[str(p.get("name", "")).to_upper()]
	var xi128: Array = []
	for nm in ["SCHMEICHEL", "GARY NEVILLE", "IRWIN", "BERG", "PALLISTER", "BUTT",
			"BECKHAM", "SHERINGHAM", "COLE", "GIGGS", "SOLSKJAER"]:
		xi128.append(int((by_name128[nm] as Dictionary).get("id", -1)))
	var pid128 := func(nm: String) -> int: return int((by_name128[nm] as Dictionary).get("id", -1))
	manu128["bench"] = [pid128.call("JOHNSEN"), pid128.call("VAN DER GOUW"),
		pid128.call("PHIL NEVILLE"), pid128.call("SCHOLES"), pid128.call("MCCLAIR")]
	manu128["reserves"] = [pid128.call("JORDI CRUYFF"), pid128.call("KEANE"),
		pid128.call("MAY"), pid128.call("CURTIS"), pid128.call("CASPER"),
		pid128.call("CLEGG"), pid128.call("NEVLAND"), pid128.call("THORNLEY")]
	var tac128 := Tactics.new()
	tac128.formation = "4-4-2"   # frame-proven: row tints D,D,D,D/M,M,M,F,M,F = the 4-4-2 slot bands (run-1 default; run 2 later plays 3-5-2)
	tac128.xi = xi128
	var lu128: LineupScreen = load("res://scenes/LineupScreen.gd").new()
	_mount(lu128)
	await process_frame
	lu128.setup(manu128, tac128, "", "Premier League", "1997-98", 1,
		{"mode": "fixture", "top": "Juventus", "bottom": "Manchester Utd.",
		"home_id": 1021, "away_id": 40, "weekday": "Friday", "day": "1",
		"month": "August", "year": "1997",
		"status_top": "Preseason", "status_bottom": "Preparation"})
	lu128._rating_view = false
	lu128.queue_redraw()
	await _shot(dir, "lineup_128.png")
	lu128.queue_free()
	await process_frame

	# ---- VIEW RIVAL FULL FRAME (run-2 frame 015: at F.C. Barcelona, Monday 4) -----
	# The frame's exact state: Barcelona XI rows 1..11 with the walked AVs (frame-
	# dynamic FI/MO — injected), TEAM RATING 87 (= 959/11), assistant A. Leigh 4*, the
	# walked marker layout (Barcelona's own tactic matches no stock formation —
	# injected from the bake's derivation), and MU's 3-5-2 (frame 014 XI) as the
	# OWN tactics feeding the mirrored ghost overlay.
	var barca: Dictionary = gamedb.club(1000)
	var bar_av := {"HESP": 83, "REIZIGER": 87, "ABELARDO": 84, "GUARDIOLA": 89,
		"F. COUTO": 85, "SERGI": 89, "FIGO": 89, "LUIS ENRIQUE": 84,
		"ANDERSON": 88, "GIOVANNI": 91, "RIVALDO": 90}
	var bar_order := ["HESP", "REIZIGER", "ABELARDO", "GUARDIOLA", "F. COUTO", "SERGI",
		"FIGO", "LUIS ENRIQUE", "ANDERSON", "GIOVANNI", "RIVALDO"]
	var bar_xi: Array = []
	for nm in bar_order:
		for p in barca.get("players", []):
			if str(p.get("name", "")).to_upper() == nm:
				(p as Dictionary)["av"] = bar_av[nm]
				bar_xi.append(int(p.get("id", -1)))
	barca["team_rating"] = 87
	var rsamples := FileAccess.open("res://data/rival_chrome_samples.json", FileAccess.READ)
	if rsamples != null:
		var rs: Variant = JSON.parse_string(rsamples.get_as_text())
		if rs is Dictionary:
			barca["rival_markers"] = (rs as Dictionary).get("rival_markers_015", [])
	var rv: RivalScreen = load("res://scenes/RivalScreen.gd").new()
	_mount(rv)
	await process_frame
	rv.setup(barca, manu3, 4, "A. Leigh", "Premier League", "1997-98", 1,
		{"mode": "fixture", "top": "F.C. Barcelona", "bottom": "Manchester Utd.",
		"home_id": 1000, "away_id": 40, "weekday": "Monday", "day": "4",
		"month": "August", "year": "1997",
		"status_top": "Preseason", "status_bottom": "Preparation"}, tac)
	var rtac := Tactics.new()
	rtac.formation = "3-5-2"
	rtac.xi = bar_xi
	rv._tactics = rtac
	rv.queue_redraw()
	await _shot(dir, "rival_015.png")
	rv.queue_free()
	await process_frame

	# ---- hub ALERT BOX (run-3 frames 093/149; docs/re/alert_box_re.md) -------------
	# Box-ROI pairs: the diff scopes to the alert rect (the hub behind is menu-bg
	# parity + the dim story; the +5,+5 shadow band is per-palette-ambiguous and
	# excluded). 093 = the McClair signing message, OK normal. 149 = the two-line
	# offer rejection with the OK button caught in its HOT state.
	var hub: MenuScreen = load("res://scenes/MenuScreen.gd").new()
	_mount(hub)
	await process_frame
	hub.setup("Manchester Utd.", "Premier", "1997-98", 1000000, "1st", 40,
		3, "Leicester", 71, true, "asdf", "O`Neill")
	hub.alert("McClair has been signed by Liverpool.")
	hub._alert_anim = 1.0
	hub.queue_redraw()
	await _shot(dir, "alert_093.png")
	print("ALERT-BOX 093 rect=%s" % hub._alert_box)
	hub._next_alert()   # clear
	hub.alert("Taylor, player of Blackpool,\nhas rejected your offer.")
	hub._alert_anim = 1.0
	hub._alert_ok_held = true   # frame 149 caught the OK button hot
	hub.queue_redraw()
	await _shot(dir, "alert_149.png")
	print("ALERT-BOX 149 rect=%s" % hub._alert_box)
	hub.queue_free()
	await process_frame

	# ---- FICHA card (run-1 frames 081/084: Van der Gouw / Solskjaer, Man Utd) -----
	# Card-ROI pairs (the squad screen behind is the host-dim story + its own body
	# parity). Both frames caught OK HELD (the red ring persists across captures).
	# Contract figures + live-form values are frame-pinned (our market/wage model
	# differs from the original save's stored figures); clauses per the frames.
	var manu5 := {}
	for c in gamedb.clubs_in_league(str(gamedb.leagues[0].get("id", ""))):
		if str(c.get("name", "")).to_upper().begins_with("MANCHESTER U"):
			manu5 = c
	var vdg := {}
	var ole := {}
	for p in manu5.get("players", []):
		if str(p.get("name", "")).to_upper() == "VAN DER GOUW":
			vdg = (p as Dictionary).duplicate()
		elif str(p.get("name", "")).to_upper() == "SOLSKJAER":
			ole = (p as Dictionary).duplicate()
	vdg["age"] = 34
	vdg["fitness"] = 70
	vdg["morale"] = 94
	vdg["clauses"] = [0, 1]
	vdg["clause_matches"] = 20
	vdg["clause_apps"] = 0
	var ficha: PlayerInfoScreen = load("res://scenes/PlayerInfoScreen.gd").new()
	ficha.host_dims = true   # ROI = the card; the LUT host-dim is SquadScreen's story
	_mount(ficha)
	await process_frame
	ficha.setup(vdg, manu5, 1, true)
	ficha._fee = 450000
	ficha._yearly = 225000
	ficha._years = 1
	ficha._left = 1
	ficha._press = "ok"
	ficha.queue_redraw()
	await _shot(dir, "ficha_081.png")
	ole["age"] = 24
	ole["fitness"] = 70
	ole["morale"] = 90
	ole["clauses"] = [0, 2]
	ole["clause_bonus"] = 5000
	ole["clause_goals"] = 0
	ficha.setup(ole, manu5, 1, true)
	ficha._fee = 8500000
	ficha._yearly = 575000
	ficha._years = 1
	ficha._left = 1
	ficha._press = "ok"
	ficha.queue_redraw()
	await _shot(dir, "ficha_084.png")
	ficha.queue_free()
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
