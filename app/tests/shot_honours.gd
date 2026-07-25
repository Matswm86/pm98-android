extends SceneTree
## Render the OURS HONOURS + CAREER screen (docs/SPEC_ours_additions.md item 1).
## Not a parity harness — the original has no such screen — but the port's rule is that
## nothing ships unlooked-at, so both pages get a shot.
##   DISPLAY=:5 PM98_SHOT_DIR=/tmp/pm98shots ~/godot462 --path app --resolution 640x480 \
##       -s tests/shot_honours.gd
func _initialize() -> void:
	_run()


func _run() -> void:
	var dir := OS.get_environment("PM98_SHOT_DIR")
	if dir == "":
		dir = "/tmp"
	get_root().size = Vector2i(640, 480)

	var c := Career.new()
	c.club_id = 59
	c.club_name = "Bolton W"
	c.league_name = "Premier League"
	c.manager_name = "mwm"
	c.club_names = {59: "Bolton W", 60: "Leeds Utd", 61: "Arsenal", 1003: "Real Madrid C.F."}
	c.euro_names = {1003: "Real Madrid C.F."}
	c.rosters = {59: [], 60: [], 61: []}
	c.objective_text = "Finish in the top half"
	c.objective_pos = 10
	for i in 4:
		c.season = "%d-%02d" % [1997 + i, (98 + i) % 100]
		c.year = i + 1
		c.fa_cup = {"rounds": [{"ties": [{"home_id": 59, "away_id": 60,
			"winner_id": 59 if i % 2 == 0 else 60, "loser_id": 60 if i % 2 == 0 else 59,
			"decided": "pens" if i == 0 else ""}]}],
			"champion_id": 59 if i % 2 == 0 else 60}
		c.league_cup = {"rounds": [{"ties": [{"home_id": 61, "away_id": 59,
			"winner_id": 61, "loser_id": 59}]}], "champion_id": 61}
		c.euro = {"uefa_cup": {"rounds": [{"ties": [{"home_id": 59, "away_id": 1003,
			"winner_id": 59, "loser_id": 1003}]}], "champion_id": 59}} if i == 1 else {}
		c.charity_shield = {"winner_id": 59, "loser_id": 61, "decided": ""} if i == 2 else {}
		c._capture_season_honours()

	var scr: HonoursScreen = load("res://scenes/HonoursScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	get_root().add_child(scr)
	await process_frame
	scr.setup(c.manager_name, c.honours_board(), c.career_resume())
	await _shot(dir, "shot_honours_board.png")
	scr._page = 1
	scr.queue_redraw()
	await _shot(dir, "shot_honours_career.png")
	print("HONOURS shots -> %s" % dir)
	quit(0)


func _shot(dir: String, name: String) -> void:
	for _i in 6:
		await process_frame
	get_root().get_texture().get_image().save_png("%s/%s" % [dir, name])
