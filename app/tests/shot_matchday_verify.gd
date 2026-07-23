extends SceneTree
## Owner frame 06 (2026-07-23): the GROUND MATCH DAY sub-screen (TICKET PRICE stepper + SPONSOR
## BOARDS price + the sell-all-boards ACCEPT offer), rendered for a Man Utd career for a pixel
## comparison against the native frame. Prices/teams are fed as the witnessed frame values
## (£7 / £750 / Man Utd v Southampton) so the layout diffs against frame 06 directly.
##   PM98_SHOT_DIR=out godot462 --rendering-driver opengl3 --path app \
##     --script res://tests/shot_matchday_verify.gd

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

	var scr: StadiumScreen = load("res://scenes/StadiumScreen.gd").new()
	get_root().add_child(scr)
	scr.set_anchors_preset(Control.PRESET_TOP_LEFT)
	scr.position = Vector2.ZERO
	scr.size = Vector2(640, 480)
	for _i in 3:
		await process_frame
	scr.setup("Manchester Utd.", "asdf", "1997-98", "Old Trafford", 55300, 34000, 21300,
		2000, "", 7, 750, 2, "Premier", "Champion")
	scr.set_matchday_state(7, 750, "Manchester Utd.", "Southampton", true, false)
	scr._view = "matchday"
	scr.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var img := get_root().get_texture().get_image()
	img.save_png(dir.path_join("matchday.png"))
	print("SHOT matchday.png")

	# Non-witness club: ground/league overdrawn, sponsor offer hidden (honest gap).
	scr.setup("Southampton", "asdf", "1997-98", "The Dell", 15200, 9000, 6200,
		560, "", 8, 150, 2, "Premier", "Avoid Relegation")
	scr.set_matchday_state(8, 150, "Southampton", "Manchester Utd.", false, false)
	scr._view = "matchday"
	scr.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png(dir.path_join("matchday_nonwitness.png"))
	print("SHOT matchday_nonwitness.png")

	print("ALL SHOTS DONE")
	quit(0)
