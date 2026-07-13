extends SceneTree
## Real-render capture of the BOARD OF DIRECTORS (DIRECTIVA) screen at native 640x480.
## Renders the actual Godot scene (not a Python mirror) so the PNG is a device-equivalent
## fidelity gate against walkthrough frame 167_154921. Two captures: preseason 3/3/5 (the
## witnessed frame state) and an in-season sample.
##   PM98_SHOT_DIR=/tmp/pm98shots godot --rendering-driver opengl3 \
##     --path app --script res://tests/shot_directiva.gd

func _initialize() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("SHOTS SKIPPED: shot_directiva needs a rendering driver (xvfb/X11), not --headless")
		quit(1)
		return
	var dir := OS.get_environment("PM98_SHOT_DIR")
	if dir == "":
		dir = "/tmp"
	get_root().size = Vector2i(640, 480)

	var shots := [
		# [png, directors, supporters, rating, week, phase]
		["directiva_preseason.png", 30, 30, 50, 1, "preseason"],
		["directiva_inseason.png", 62, 48, 71, 12, "season"],
	]
	for s in shots:
		PMChrome.header_phase = String(s[5])
		PMChrome.header_date = {}
		var node: DirectivaScreen = load("res://scenes/DirectivaScreen.gd").new()
		get_root().add_child(node)
		node.anchor_left = 0.0
		node.anchor_top = 0.0
		node.anchor_right = 0.0
		node.anchor_bottom = 0.0
		node.position = Vector2.ZERO
		node.size = Vector2(640, 480)
		node.setup("Manchester Utd.", "MWM", "1997-98", 0,
			int(s[1]), int(s[2]), int(s[3]),
			"", "0-0-0", "1st", int(s[4]), "Premier League")
		for _i in 14:
			await process_frame
		await RenderingServer.frame_post_draw
		var img := get_root().get_texture().get_image()
		var err := img.save_png(dir.path_join(String(s[0])))
		print("SHOT %s err=%d %dx%d" % [s[0], err, img.get_width(), img.get_height()])
		node.queue_free()
		for _i in 3:
			await process_frame
	print("SHOTS DONE")
	quit(0)
