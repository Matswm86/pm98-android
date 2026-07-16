extends SceneTree
## Frame-parity captures of the MANAGER HISTORY screen in the EXACT states the
## live-witnessed originals show, for pixel-diffing (diff_managerhistory_parity.py):
##   mh_15.png  mwm @ Brighton & HA wk1, all-zero record, TOTAL off   vs frame 15
##   mh_16.png  same with TOTAL lit                                   vs frame 16
## Needs a real renderer (Xvfb / local X11):
##   DISPLAY=:1 PM98_SHOT_DIR=out ~/godot462 --rendering-driver opengl3 \
##       --path app --script res://tests/shot_managerhistory_parity.gd

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

	var scr: ManagerHistoryScreen = load("res://scenes/ManagerHistoryScreen.gd").new()
	get_root().add_child(scr)
	scr.position = Vector2.ZERO
	scr.size = Vector2(640, 480)

	# Witnessed frame-15 state.
	var spell := {"team": "Brighton & HA", "division": "3rd Div.", "pos": "23rd",
		"obj": "YES", "directors": "5", "public": "5"}
	var zeros: Dictionary = {}
	for k in ManagerHistoryScreen.COMP_KEYS:
		zeros[k] = {"pla": 0, "win": 0, "dr": 0, "los": 0, "gf": 0, "ga": 0}
	scr.setup("mwm", [spell], zeros)
	await _grab(dir, "mh_15.png")

	# Frame-16 state: TOTAL lit (tables identical in the witness).
	scr._total_on = true
	scr.queue_redraw()
	await _grab(dir, "mh_16.png")

	quit(0)


func _grab(dir: String, name: String) -> void:
	await process_frame
	await process_frame
	var img := get_root().get_texture().get_image()
	img.save_png(dir.path_join(name))
	print("SHOT %s" % dir.path_join(name))
