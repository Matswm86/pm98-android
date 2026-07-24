extends SceneTree
## Render the INJURIES screen with one untreated and one treated row, so the PHYS.
## button's two states (BOTONOFF grey cross / BOTONON red cross) can be eyeballed.
##   DISPLAY=:1 PM98_SHOT_DIR=out ~/godot462 --rendering-driver opengl3 --path app \
##       --script res://tests/shot_injuries_phys.gd

func _initialize() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("SKIPPED: needs a rendering driver")
		quit(1)
		return
	var dir := OS.get_environment("PM98_SHOT_DIR")
	if dir == "":
		dir = "/tmp"
	var win := get_root()
	win.size = Vector2i(640, 480)
	var scr: InjuriesScreen = load("res://scenes/InjuriesScreen.gd").new()
	scr.size = Vector2(640, 480)
	win.add_child(scr)
	var players: Array = [
		{"id": 1, "name": "GIGGS", "pos": "MF", "injured_weeks": 7,
			"injury_weeks_total": 7, "injury_type": 6, "insurance_group": 1},
		{"id": 2, "name": "SCHOLES", "pos": "MF", "injured_weeks": 4,
			"injury_weeks_total": 8, "injury_type": 6, "physio_treated": 10},
	]
	scr.setup({"id": 1, "name": "Manchester Utd.", "players": players},
		[{"id": 9, "role": Staff.PHYSIOTHERAPIST, "name": "E. Wragg", "stars": 4.5,
			"quality": 5, "wage": 42000}])
	for _i in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	win.get_texture().get_image().save_png("%s/injuries_phys.png" % dir)
	print("wrote %s/injuries_phys.png" % dir)
	quit(0)
