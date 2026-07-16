extends SceneTree
## Frame-parity captures of the NEWS extra overlay in the EXACT states the original
## walkthrough frames show, for pixel-diffing against them (diff_news_parity.py):
##   news_155.png  front page: Premier tab, MARKET, ACTUAL, empty feed  vs 155_154857
##   news_156.png  same + INJURIES bottom tab held (over-art)           vs 156_154859
##   news_158.png  1st Div. tab: masthead-less page, MARKET             vs 158_154905
## Only the overlay footprint (page rect 145,27,350,425) gates — outside it the
## original shows the live hub, which the bare shot leaves black.
## Needs a real renderer (Xvfb / local X11):
##   DISPLAY=:1 PM98_SHOT_DIR=out ~/godot462 --rendering-driver opengl3 \
##       --path app --script res://tests/shot_news_parity.gd

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

	var node: NewsScreen = load("res://scenes/NewsScreen.gd").new()
	get_root().add_child(node)
	node.position = Vector2.ZERO
	node.size = Vector2(640, 480)

	# ---- frame 155 state: fresh preseason career, empty feed, front page ----
	node.setup([], 1, 0)
	await _grab(dir, "news_155.png")

	# ---- frame 156: INJURIES bottom tab held (its witnessed over-art) ----
	node._press = "cat:INJURIES"
	node.queue_redraw()
	await _grab(dir, "news_156.png")
	node._press = ""

	# ---- frame 158: the 1st Div. tab selected (masthead-less division page) ----
	node._division = 1
	node.queue_redraw()
	await _grab(dir, "news_158.png")

	print("SHOTS DONE")
	quit(0)


func _grab(dir: String, name: String) -> void:
	for _i in 16:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := get_root().get_texture().get_image()
	var err := img.save_png(dir.path_join(name))
	print("SHOT %s err=%d %dx%d" % [name, err, img.get_width(), img.get_height()])
