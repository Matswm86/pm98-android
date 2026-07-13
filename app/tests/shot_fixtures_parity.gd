extends SceneTree
## Frame-parity capture of THE CALENDAR (FixturesScreen) in the EXACT state
## binding frame 051_154519.png shows: fresh Man Utd career, Friday 1 August
## 1997, preseason friendlies 1/4/6/8 AUG (Juventus/Barcelona/Sao Paulo/River),
## Charity Shield 3 AUG, league 10/14/23/28/31 AUG + 13/20/25/27 SEP, a
## European-League date 17 SEP. Diff with:
##   python3 tools/re/diff_fixtures_parity.py <shot_dir>
## Needs a real renderer (Xvfb / local X11), same as shot_screens.gd:
##   PM98_SHOT_DIR=out godot --rendering-driver opengl3 --path app --script res://tests/shot_fixtures_parity.gd


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

	var screen: FixturesScreen = load("res://scenes/FixturesScreen.gd").new()
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	get_root().add_child(screen)
	await process_frame
	screen.size = Vector2(640, 480)
	screen.setup(_header(), _frame_entries(), {"y": 1997, "m": 8, "d": 1})
	await process_frame
	await RenderingServer.frame_post_draw
	var img := get_root().get_texture().get_image()
	img.save_png("%s/fixtures_051.png" % dir)
	print("saved %s/fixtures_051.png" % dir)
	quit(0)


func _frame_entries() -> Array:
	var out: Array = [
		{"y": 1997, "m": 8, "d": 1, "comp": "preseason", "comp_name": "Preseason",
			"round": "Preparation", "home_id": 1021, "away_id": 40,
			"home": "Juventus", "away": "Manchester Utd.", "home_flag": 36, "away_flag": 30},
		{"y": 1997, "m": 8, "d": 3, "comp": "charity", "comp_name": "Charity Shield",
			"round": "Final", "home_id": 40, "away_id": 49,
			"home": "Manchester Utd.", "away": "Chelsea", "home_flag": 30, "away_flag": 30},
		{"y": 1997, "m": 8, "d": 4, "comp": "preseason", "comp_name": "Preseason",
			"round": "Preparation", "home_id": 1000, "away_id": 40,
			"home": "F.C. Barcelona", "away": "Manchester Utd.", "home_flag": 71, "away_flag": 30},
		{"y": 1997, "m": 8, "d": 6, "comp": "preseason", "comp_name": "Preseason",
			"round": "Preparation", "home_id": 40, "away_id": 1301,
			"home": "Manchester Utd.", "away": "Sao Paulo", "home_flag": 30, "away_flag": 20},
		{"y": 1997, "m": 8, "d": 8, "comp": "preseason", "comp_name": "Preseason",
			"round": "Preparation", "home_id": 40, "away_id": 1361,
			"home": "Manchester Utd.", "away": "River", "home_flag": 30, "away_flag": 5},
	]
	for d in [10, 14, 23, 28, 31]:
		out.append({"y": 1997, "m": 8, "d": d, "comp": "league", "comp_name": "League",
			"round": "Week", "home_id": 40, "away_id": 49, "home": "Manchester Utd.",
			"away": "Chelsea", "home_flag": 30, "away_flag": 30})
	for d in [13, 20, 25, 27]:
		out.append({"y": 1997, "m": 9, "d": d, "comp": "league", "comp_name": "League",
			"round": "Week", "home_id": 40, "away_id": 49, "home": "Manchester Utd.",
			"away": "Chelsea", "home_flag": 30, "away_flag": 30})
	out.append({"y": 1997, "m": 9, "d": 17, "comp": "euro_league", "comp_name": "European League",
		"round": "Round 1", "home_id": 40, "away_id": 1021, "home": "Manchester Utd.",
		"away": "Juventus", "home_flag": 30, "away_flag": 36})
	return out


func _header() -> Dictionary:
	return {"mode": "manager", "top": "MWM", "bottom": "Manchester Utd.", "club_id": 40,
		"weekday": "Friday", "day": "1", "month": "August", "year": "1997",
		"status_top": "Preseason", "status_bottom": "Preparation"}
