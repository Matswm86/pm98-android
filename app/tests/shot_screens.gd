extends SceneTree
## Minimal REAL-render capture of the original-art screens — one PNG each, then quit.
## Deliberately tiny and Main-scene-free (no career, no season sim) so it cannot hang
## the screenshot CI the way the full devshot walk can. Renders each screen's own
## background + chrome through the actual Godot renderer (Xvfb + software GL in CI), so
## the PNGs are ground-truth device-equivalent captures, not Python mirror renders.
##   PM98_SHOT_DIR=out godot --rendering-driver opengl3 --path app --script res://tests/shot_screens.gd

func _initialize() -> void:
	_run()


func _run() -> void:
	var dir := OS.get_environment("PM98_SHOT_DIR")
	if dir == "":
		dir = "/tmp"
	# [scene script, png name]; both use the bezel + full-screen bg draw pattern, so a
	# grey result on either tells us the art-screen render path itself is broken.
	var screens := [
		["res://scenes/TitleScreen.gd", "title.png"],
		["res://scenes/MenuScreen.gd", "menu.png"],
	]
	# Render at the game's native 640x480 so each screen draws at scale 1, origin 0 (full,
	# centred, uncut). Pinning the window + node to 640x480 avoids the FULL_RECT-vs-window
	# race that drew screens offset/zoomed when sized to the OS window.
	get_root().size = Vector2i(640, 480)
	for s in screens:
		var node: Control = load(s[0]).new()
		get_root().add_child(node)
		node.anchor_left = 0.0
		node.anchor_top = 0.0
		node.anchor_right = 0.0
		node.anchor_bottom = 0.0
		node.position = Vector2.ZERO
		node.size = Vector2(640, 480)
		if node.has_method("setup") and s[1] == "menu.png":
			node.setup("SAMPLE FC", "Premier League", "1997-98", 1_000_000, "1st")
		for _i in 14:
			await process_frame
		await RenderingServer.frame_post_draw
		var img := get_root().get_texture().get_image()
		var err := img.save_png(dir.path_join(s[1]))
		print("SHOT %s err=%d %dx%d" % [s[1], err, img.get_width(), img.get_height()])
		node.queue_free()
		for _i in 3:
			await process_frame
	print("SHOTS DONE")
	quit(0)
