extends SceneTree
## Real-render the FULL TIME read-out with the WITNESSED Old Trafford board's own
## numbers, so it can be pixel-diffed against
## screenshots/wine-captures-2026-07-12/match_result_fulltime.png
## (tools/re/diff_result_ft_parity.py). Proves the rebuilt stadium panel (all five
## labelled rows) and the MAN OF THE MATCH band land on the original's pixels.
##   PM98_SHOT_DIR=out/rft ~/godot462 --rendering-driver opengl3 --path app \
##       --script res://tests/shot_result_ft.gd


func _initialize() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("SHOTS SKIPPED: needs a rendering driver, not --headless")
		quit(1)
		return
	var dir := OS.get_environment("PM98_SHOT_DIR")
	if dir == "":
		dir = "/tmp"
	get_root().size = Vector2i(640, 480)
	var rs: MatchResultScreen = load("res://scenes/MatchResultScreen.gd").new()
	get_root().add_child(rs)
	rs.set_anchors_preset(Control.PRESET_TOP_LEFT)
	rs.position = Vector2.ZERO
	rs.size = Vector2(640, 480)
	await process_frame
	# The witnessed board: Man Utd 1-2 Bolton at Old Trafford. The MoM line is the
	# other witness's ("Holdsworth (Bolton W)", 15_fulltime) — the diff only scopes
	# the two lower panels, so the fixture behind the name does not matter here.
	rs.setup("Manchester Utd.", "Bolton W", 1, 2, [], -1, -1, {},
		{"name": "Old Trafford", "capacity": 55300, "attendance": 19355,
			"gate": 145162, "boards": 6750, "boards_pct": 31}, false,
		{"name": "HOLDSWORTH", "club": "Bolton W", "photo_id": null})
	await process_frame
	await RenderingServer.frame_post_draw
	var img := get_root().get_texture().get_image()
	var err := img.save_png(dir.path_join("result_ft_render.png"))
	print("SHOT result_ft_render.png err=%d %dx%d" % [err, img.get_width(), img.get_height()])
	quit(0)
