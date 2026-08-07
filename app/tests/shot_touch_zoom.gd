extends SceneTree
## Drives the REAL app (Main.tscn, a booted career hub) through a two-finger pinch and
## banks the frames, so the zoom is verified by looking rather than by arithmetic.
## Headless tests prove _pz_apply's numbers; this proves the running app renders them.
##
##   PM98_SHOT_DIR=<dir> LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 640x480x24" \
##     ~/godot462 --rendering-driver opengl3 --resolution 640x480 --path app \
##     --script res://tests/shot_touch_zoom.gd

var _dir := ""


func _initialize() -> void:
	_dir = OS.get_environment("PM98_SHOT_DIR")
	if _dir == "":
		print("shot_touch_zoom: set PM98_SHOT_DIR")
		quit(1)
		return
	_run()


func _run() -> void:
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	get_root().add_child(main)
	for i in 90:
		await process_frame
	_snap("zoom_00_unzoomed.png")

	# Two fingers down, then spread them: Main._input pinches about their midpoint.
	_touch(0, Vector2(220, 180), true)
	_touch(1, Vector2(420, 300), true)
	await process_frame
	_drag(0, Vector2(140, 120))
	_drag(1, Vector2(500, 360))
	for i in 4:
		await process_frame
	var z: float = (main as Control).scale.x
	_snap("zoom_01_pinched.png")
	print("  zoom after spread: %.3f  pos %s" % [z, str((main as Control).position)])

	# Two-finger pan at the held zoom.
	_drag(0, Vector2(180, 200))
	_drag(1, Vector2(540, 440))
	for i in 4:
		await process_frame
	_snap("zoom_02_panned.png")
	print("  after pan: zoom %.3f pos %s" % [(main as Control).scale.x,
		str((main as Control).position)])

	# Pinch back in: below 1.06x it must snap to exactly 1.0 and sit at the origin.
	_drag(0, Vector2(300, 250))
	_drag(1, Vector2(320, 260))
	for i in 4:
		await process_frame
	_touch(0, Vector2(300, 250), false)
	_touch(1, Vector2(320, 260), false)
	for i in 4:
		await process_frame
	var home_z: float = (main as Control).scale.x
	var home_p: Vector2 = (main as Control).position
	_snap("zoom_03_home.png")
	print("  after pinch-in: zoom %.3f pos %s" % [home_z, str(home_p)])

	var ok := z > 1.2 and is_equal_approx(home_z, 1.0) and home_p.length() < 0.5
	print("shot_touch_zoom: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)


func _touch(idx: int, p: Vector2, pressed: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = idx
	e.position = p
	e.pressed = pressed
	Input.parse_input_event(e)


func _drag(idx: int, p: Vector2) -> void:
	var e := InputEventScreenDrag.new()
	e.index = idx
	e.position = p
	Input.parse_input_event(e)


func _snap(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var img := get_root().get_texture().get_image()
	var err := img.save_png(_dir.path_join(name))
	print("SHOT %s err=%d %dx%d" % [name, err, img.get_width(), img.get_height()])
