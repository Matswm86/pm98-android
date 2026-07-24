extends SceneTree
## Render the ROLE popup for the witnessed player and dump it, for a render-diff
## against the original's own frame (`tools/re/diff_role_popup_parity.py`).
##   DISPLAY=:1 PM98_SHOT_DIR=out ~/godot462 --rendering-driver opengl3 --path app \
##       --script res://tests/shot_role_popup.gd

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
	win.transparent_bg = false
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0)
	bg.size = Vector2(640, 480)
	win.add_child(bg)
	var pop: RolePopup = load("res://scenes/RolePopup.gd").new()
	pop.size = Vector2(640, 480)
	win.add_child(pop)
	# the witnessed row: Bolton W week 1, Bergsson (posFine 2, posAlts [5, 6])
	pop.setup({"id": 1, "name": "BERGSSON", "posFine": 2, "posAlts": [5, 6]})
	for _i in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := win.get_texture().get_image()
	img.save_png("%s/rolepopup_bergsson.png" % dir)
	print("wrote %s/rolepopup_bergsson.png" % dir)
	quit(0)
