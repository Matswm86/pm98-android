extends SceneTree
## Owner frames 2026-07-23: the three unblocked GROUND IMPROVEMENTS tabs (CAR PARK / FACILITIES
## / SERVICES) + the concurrent WORK IN PROGRESS ledger (frame 07), rendered for a Man Utd
## career for a pixel comparison against frames 09 / 10 / 12 / 07.
##   PM98_SHOT_DIR=out godot462 --rendering-driver opengl3 --path app \
##     --script res://tests/shot_ground_verify.gd

func _initialize() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("SHOTS SKIPPED: needs a rendering driver")
		quit(1)
		return
	var dir := OS.get_environment("PM98_SHOT_DIR")
	if dir == "":
		dir = "/tmp"
	get_root().size = Vector2i(640, 480)

	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	var db: Dictionary = JSON.parse_string(f.get_as_text())
	var leagues: Array = db.get("leagues", [])
	var league: Dictionary = {}
	for lg in leagues:
		if lg.get("id") == "eng_prem":
			league = lg
	var prem: Array = []
	var manu: Dictionary = {}
	for c in db.get("clubs", []):
		if c.get("leagueId") == "eng_prem":
			prem.append(c)
			if str(c.get("name", "")).to_lower().contains("manchester utd"):
				manu = c
	var career := Career.create(manu, league, prem, leagues)
	career.cash = 40_000_000
	# Reproduce frame 07's concurrent ledger: SEATS 8k, CAR PARK quad-0 +1, CHANG. ROOMS, SICKROOM.
	career.start_works(8000, 7_437_500, 35)
	career.begin_work("carpark", 0, "500 spaces", 2_975_000, 7, {"added": 500})
	career.begin_work("facility", 2, "CHANG. ROOMS", 225_000, 3, {"grade": 2})
	career.begin_work("service", 0, "SICKROOM", 150_000, 2, {"grade": 2})

	var states := [
		["ground_carpark.png", "improve", "carpark"],
		["ground_facilities.png", "improve", "facilities"],
		["ground_services.png", "improve", "services"],
		["ground_ledger.png", "works", "seats"],
		["ground_matchday.png", "matchday", "seats"],
	]
	for st in states:
		var scr: StadiumScreen = load("res://scenes/StadiumScreen.gd").new()
		get_root().add_child(scr)
		scr.set_anchors_preset(Control.PRESET_TOP_LEFT)
		scr.position = Vector2.ZERO
		scr.size = Vector2(640, 480)
		for _i in 3:
			await process_frame
		scr.setup("Manchester Utd.", "asdf", "1997-98", "Old Trafford", 55300, 34000, 21300,
			2000, career.works_status(), 7, 750, career.week + 1, "Premier",
			str(manu.get("objective", "")))
		# Feed the STATURE band, exactly as Main does, so the shot exercises the live
		# GroundCost path (FUN_0057ddd0) rather than the legacy witnessed-club lookup.
		# Man Utd's band is 0, which is what makes these frames the price witness.
		scr.set_improve_state(career.car_park_levels, 2_975_000, career.works_ledger(),
			career.ground_grades, career.works_total(), career.my_band())
		scr.set_matchday_state(7, 750, "Manchester Utd.", "Southampton", true, false)
		scr._view = str(st[1])
		scr._tab = str(st[2])
		scr.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		var img := get_root().get_texture().get_image()
		img.save_png(dir.path_join(str(st[0])))
		print("SHOT %s" % st[0])
		scr.queue_free()
		await process_frame

	print("ALL SHOTS DONE")
	quit(0)
