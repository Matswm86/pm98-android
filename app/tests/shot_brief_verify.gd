extends SceneTree
## Verify #7a (feed geometry) + #7b (possession) against parity orig/67_brief_feed.png:
## Aston Villa (home) v Bolton W (away), "Goal by Blake (Bolton W)", engine POSS [48,52].
## DISPLAY=:1 ~/godot462 --path app -s tests/shot_brief_verify.gd
func _initialize() -> void:
	_run()
func _run() -> void:
	var dir := OS.get_environment("PM98_SHOT_DIR")
	if dir == "": dir = "/tmp"
	await process_frame
	var br: MatchScreen = load("res://scenes/MatchScreen.gd").new()
	br.set_anchors_preset(Control.PRESET_FULL_RECT)
	get_root().add_child(br)
	get_root().size = Vector2i(640, 480)
	br.set_process(false)
	var lines: Array = [
		{"minute":36,"side":1,"scorer":"Blake","goal":true},      # away goal
		{"minute":40,"side":0,"scorer":"Milosevic","goal":true}]  # home goal
	# possession [home,away] raw engine counters -> 48/52
	br.setup("Aston Villa","Bolton W",1,2,lines,45,59,[48,52])
	# FULL TIME: the exact 48/52 split (unaeased) + all goal lines visible
	br.seek(90.0)
	for _i in 8: await process_frame
	get_root().get_texture().get_image().save_png("%s/shot_brief_verify_ft.png" % dir)
	# mid-match eased view at 41'
	br.seek(41.0)
	for _i in 6: await process_frame
	get_root().get_texture().get_image().save_png("%s/shot_brief_verify_41.png" % dir)
	print("BRIEF verify shots -> %s" % dir)
	quit(0)
