extends SceneTree
## Render-verify the GROUND views vs the ORIGINAL frames:
##   works  -> frame 172_154930 (WORK IN PROGRESS, Man Utd / Old Trafford)
##   improve-> frame 173_154935 (IMPROVEMENTS SEATS picker, Man Utd, witnessed £ prices)
## Man Utd is the binding club, so the redrawn prices should land on the baked cells 1:1.
## DISPLAY=:1 ~/godot462 --path app -s tests/shot_improvements_verify.gd
func _initialize() -> void:
	_run()
func _run() -> void:
	var dir := OS.get_environment("PM98_SHOT_DIR")
	if dir == "":
		dir = "/tmp"
	await process_frame
	var st: StadiumScreen = load("res://scenes/StadiumScreen.gd").new()
	st.set_anchors_preset(Control.PRESET_FULL_RECT)
	get_root().add_child(st)
	get_root().size = Vector2i(640, 480)
	# Man Utd / Old Trafford, real 55,300 capacity (tier 4, matches the frame render).
	st.setup("Manchester Utd.", "MWM", "1997-98", "Old Trafford", 55300, 0, 0, 0, "", 0, 0, 0, "Premier")
	for _i in 6:
		await process_frame
	get_root().get_texture().get_image().save_png("%s/shot_ground_works.png" % dir)
	st.open_improve()
	for _i in 6:
		await process_frame
	get_root().get_texture().get_image().save_png("%s/shot_ground_improve.png" % dir)
	print("GROUND verify shots -> %s" % dir)
	quit(0)
