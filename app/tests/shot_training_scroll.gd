extends SceneTree
## Render the TRAINING screen with the witnessed Bolton-shaped squad (9 defenders in
## 6 slots) at scroll offsets 0 and 1, for a render-diff of the scrollbar column
## against the original (`tools/re/diff_training_scroll_parity.py`).
##   DISPLAY=:1 PM98_SHOT_DIR=out ~/godot462 --rendering-driver opengl3 --path app \
##       --script res://tests/shot_training_scroll.gd

func _initialize() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("SKIPPED: needs a rendering driver, not --headless")
		quit(1)
		return
	var dir := OS.get_environment("PM98_SHOT_DIR")
	if dir == "":
		dir = "/tmp"
	var win := get_root()
	win.size = Vector2i(640, 480)
	var scr: TrainingScreen = load("res://scenes/TrainingScreen.gd").new()
	scr.size = Vector2(640, 480)
	win.add_child(scr)
	var players: Array = []
	var pid := 1
	for spec in [["GK", 3], ["DF", 9], ["MF", 4], ["FW", 6]]:
		for i in int(spec[1]):
			players.append({"id": pid, "name": "%s%d" % [spec[0], i], "pos": str(spec[0]),
				"isGK": str(spec[0]) == "GK", "squadNo": pid,
				"attrs": {"VE": 70, "RE": 70, "AG": 70, "CA": 70,
					"RM": 70, "RG": 70, "PA": 70, "TI": 70, "EN": 70, "PO": 70}})
			pid += 1
	scr.setup({"id": 1, "name": "Bolton W", "players": players})
	for off in 2:
		if off > 0:
			scr._scroll_by("def", 1)
		scr.queue_redraw()
		for _i in 5:
			await process_frame
		await RenderingServer.frame_post_draw
		var img := win.get_texture().get_image()
		img.save_png("%s/training_scroll_%d.png" % [dir, off])
		print("wrote %s/training_scroll_%d.png" % [dir, off])
	quit(0)
