extends SceneTree
## Render-verify OFFERS vs the ORIGINAL witnesses:
##   resting   -> wine 44 (England, Premier selected, empty list, Bolton washed)
##   spain     -> wine 45 (strip SPAIN + enlarged flag + Spain kit grid,
##                          buttons gone)
##   barca     -> wine 46 (F.C. Barcelona list, gold OVER cell, name label)
##   blackpool -> run-3 100 (Second Division + Blackpool list; the run-3 career
##                          managed Man Utd -> managed_id 40)
## The squad rows are the REAL GameDB data (names/numbers/AV witnessed to
## match). The star-rating mapping is un-RE'd (parity-excluded, FICHA
## precedent) -> the comparator masks the stars column. The live barra (y<62)
## is masked as always; non-Premier kit grids render via the nano fallback
## (masked in the blackpool state).
## DISPLAY=:1 ~/godot462 --path app -s tests/shot_offers_verify.gd
func _initialize() -> void:
	_run()


func _run() -> void:
	var dir := OS.get_environment("PM98_SHOT_DIR")
	if dir == "":
		dir = "/tmp"
	get_root().size = Vector2i(640, 480)

	var gamedb: Node = load("res://scripts/GameDB.gd").new()
	gamedb.name = "GameDBShot"
	get_root().add_child(gamedb)
	await process_frame

	var scr: OffersScreen = load("res://scenes/OffersScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	get_root().add_child(scr)
	await process_frame

	var clubs_of := func(lid: String) -> Array:
		return gamedb.clubs_in_league(lid)
	var clubs_of_country := func(nm: String) -> Array:
		return gamedb.clubs_in_country(nm)

	# 1. resting (wine 44: Bolton career, Premier, own kit washed)
	scr.setup(gamedb.leagues, clubs_of, clubs_of_country, 0, 59, {},
		"Bolton W", "mwm", "1997-98", 3, "Premier League", 59)
	await _shot(dir, "shot_offers_resting.png")

	# 2. Spain tapped (wine 45)
	for m in scr._markers:
		if str(m["name"]) == "SPAIN":
			scr._sel_flag = m
			scr._sel_tab = 0
	scr._strip_country = "SPAIN"
	# Archive order, NOT alphabetical — witness 45 opens on Barcelona (EQ96001.DBC).
	var cc: Array = gamedb.clubs_in_country("SPAIN")
	scr._country = "SPAIN"
	scr._country_clubs = cc
	scr.queue_redraw()
	await _shot(dir, "shot_offers_spain.png")

	# 3. first Spanish kit tapped = F.C. Barcelona (wine 46)
	var barca_i := -1
	for i in cc.size():
		if str((cc[i] as Dictionary).get("name", "")) == "F.C. Barcelona":
			barca_i = i
	scr._sel_club_i = barca_i
	scr._squad_club = cc[barca_i]
	scr._rows = scr._build_rows(cc[barca_i])
	scr._first = 0
	scr._last_pick = PMChrome.title_case_name("F.C. Barcelona")
	scr._strip_country = ""
	scr._sel_flag = {}
	scr.queue_redraw()
	await _shot(dir, "shot_offers_barca.png")

	# 4. England Second Division -> Blackpool (run-3 100; managed = Man Utd 40)
	scr.setup(gamedb.leagues, clubs_of, clubs_of_country, 0, 40,
		{}, "Manchester Utd.", "asdf", "1997-98", 3, "Premier League", 40)
	scr._div = 2
	scr._select_england()
	var bp_i := -1
	for i in scr._country_clubs.size():
		if str((scr._country_clubs[i] as Dictionary).get("name", "")) == "Blackpool":
			bp_i = i
	scr._sel_club_i = bp_i
	scr._squad_club = scr._country_clubs[bp_i]
	scr._rows = scr._build_rows(scr._squad_club)
	scr._first = 0
	scr._last_pick = PMChrome.title_case_name("Blackpool")
	scr._press = "row:7"   # the witnessed Brabin pressed ring (100)
	scr.queue_redraw()
	await _shot(dir, "shot_offers_blackpool.png")

	print("OFFERS verify shots -> %s" % dir)
	quit(0)


func _shot(dir: String, name: String) -> void:
	for _i in 6:
		await process_frame
	get_root().get_texture().get_image().save_png("%s/%s" % [dir, name])
