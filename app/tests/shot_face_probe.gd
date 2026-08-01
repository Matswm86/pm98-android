extends SceneTree
## Render one string in EVERY extracted face at several sizes, so a cell in a captured
## frame can be matched to its own face by SHAPE rather than by eye or by width.
##
## Written 2026-08-01 for the YOUTH TEAM "PLAYERS FOUND" money column, which is 33 px wide
## for "£5,000" where the bold list face renders it 43 px — near enough that a width guess
## could pick the wrong face, and far enough that the diff never reaches 0. The probe plus
## `tools/re/probe_text_face.py` settled it by XOR against the witness cell's own ink mask:
## `euro8` at 11 is the only face/size pair in the whole set that scores 0.
##
##   DISPLAY=:1 PM98_SHOT_DIR=out PM98_FACE_TEXT='£5,000' PM98_FACE_INK=150,0,0 \
##       ~/godot462 --rendering-driver opengl3 --path app \
##       --script res://tests/shot_face_probe.gd
##   python3 tools/re/probe_text_face.py out <frame.png> <x0> <y0> <x1> <y1> 150,0,0

const FACES := ["8", "10", "12", "euro8", "futcon8", "micro8", "calend8", "kkita"]
const SIZES := [8, 10, 11, 12]


func _initialize() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("PROBE SKIPPED: needs a rendering driver (xvfb/X11), not --headless")
		quit(1)
		return
	var dir := OS.get_environment("PM98_SHOT_DIR")
	if dir == "":
		dir = "/tmp"
	var text := OS.get_environment("PM98_FACE_TEXT")
	if text == "":
		text = "£5,000"
	var ink := Color8(150, 0, 0)
	var raw := OS.get_environment("PM98_FACE_INK")
	if raw != "":
		var p := raw.split(",")
		if p.size() == 3:
			ink = Color8(int(p[0]), int(p[1]), int(p[2]))

	get_root().size = Vector2i(200, 24)
	for name in FACES:
		var f: Font = PMChrome.font(name)
		if f == null:
			continue
		for sz in SIZES:
			var node := Control.new()
			node.size = Vector2(200, 24)
			var draw := func() -> void:
				node.draw_rect(Rect2(0, 0, 200, 24), Color.WHITE, true)
				node.draw_string(f, Vector2(10, 18), text,
					HORIZONTAL_ALIGNMENT_LEFT, -1, sz, ink)
			node.draw.connect(draw)
			get_root().add_child(node)
			await process_frame
			await RenderingServer.frame_post_draw
			var img := get_root().get_texture().get_image()
			img.save_png("%s/face_%s_%d.png" % [dir, name, sz])
			node.queue_free()
			await process_frame
	print("PROBE DONE: %d faces x %d sizes -> %s" % [FACES.size(), SIZES.size(), dir])
	quit(0)
