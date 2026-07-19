extends SceneTree
## REAL-render parity shot for the lower-division LEAGUE TABLES (living pyramid).
## Reproduces the WITNESSED w5_lt_default state — Manchester C (w5) career, FIRST
## DIVISION seed table at P=0 — and captures the redrawn screen for diffing against
## screenshots/wine-captures-2026-07-19-lowerdiv/w5_lt_default.png. Also captures
## the Third Division view (tab switch) and a movement-marker state.
##   PM98_SHOT_DIR=out ~/godot462 --rendering-driver opengl3 --path app \
##     --script res://tests/shot_league_divisions.gd

func _initialize() -> void:
	_run()


func _load_json(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("SHOTS SKIPPED: needs a rendering driver (X11), not --headless")
		quit(1)
		return
	var dir := OS.get_environment("PM98_SHOT_DIR")
	if dir == "":
		dir = "/tmp"
	get_root().content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	get_root().size = Vector2i(640, 480)

	var db := _load_json("res://data/game_db.json")
	var seeds_file := _load_json("res://data/season_seed_1997.json")
	var leagues: Array = db.get("leagues", [])
	var by_league: Dictionary = {}
	for c in db.get("clubs", []):
		if c.get("leagueId") != null:
			if not by_league.has(c["leagueId"]):
				by_league[c["leagueId"]] = []
			(by_league[c["leagueId"]] as Array).append(c)
	var divs: Array = []
	var league_by_id: Dictionary = {}
	for lg in leagues:
		league_by_id[lg["id"]] = lg
		divs.append({"league_id": lg["id"], "name": lg["name"], "tier": int(lg["tier"]),
			"clubs": by_league.get(lg["id"], [])})
	var pyramid := {"divisions": divs, "seeds": seeds_file.get("seeds", {})}

	# The witnessed w5 career: Manchester C in Division One, week 0.
	var d1: Array = by_league["eng_div1"]
	var city: Dictionary = {}
	for c in d1:
		if c["name"] == "Manchester C":
			city = c
	var career := Career.create(city, league_by_id["eng_div1"], d1, leagues, pyramid)
	career.manager_name = "w5"

	var scr: LeagueTableScreen = load("res://scenes/LeagueTableScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	get_root().add_child(scr)
	scr.setup(career.standings(), career.club_name, career.season, "Week 1",
		career.tier, career.club_id, career.manager_name)
	scr.set_pyramid(func(t: int) -> Dictionary:
		return {"rows": career.standings_for(t), "prev": career.prev_positions_for(t)})
	await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png(dir + "/lt_div1_seed.png")
	print("wrote ", dir, "/lt_div1_seed.png")

	# Third Division via the witnessed tab (P=1 head-start table).
	scr._select_division(4)
	await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png(dir + "/lt_div3_headstart.png")
	print("wrote ", dir, "/lt_div3_headstart.png")

	# Movement markers: play a week, re-open on the manager's division.
	var rng := RandomNumberGenerator.new()
	rng.seed = 19970809
	career.advance_week(rng)
	scr._selected = career.tier
	scr.setup(career.standings(), career.club_name, career.season, "Week 2",
		career.tier, career.club_id, career.manager_name)
	scr.set_pyramid(func(t: int) -> Dictionary:
		return {"rows": career.standings_for(t), "prev": career.prev_positions_for(t)},
		career.prev_positions_for(career.tier))
	await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png(dir + "/lt_div1_wk2_markers.png")
	print("wrote ", dir, "/lt_div1_wk2_markers.png")
	quit(0)
