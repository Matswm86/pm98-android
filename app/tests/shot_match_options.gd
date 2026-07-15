extends SceneTree
## REAL-render capture of the MATCH OPTIONS tabbed settings dialog (MatchOptions.gd)
## through the actual Godot GL renderer (Xvfb + software GL). One PNG per tab, with a
## couple of live overlays exercised (SKY OFF + PITCH MIN on GRAPHICS, AUTO on CAMERAS,
## AMBIENT OFF on SOUND) so the drawn state is visible.
##   PM98_SHOT_DIR=out DISPLAY=:1 godot462 --rendering-driver opengl3 --path app \
##       --script res://tests/shot_match_options.gd

func _initialize() -> void:
	_run()


func _run() -> void:
	var dir := OS.get_environment("PM98_SHOT_DIR")
	if dir == "":
		dir = "/tmp"
	get_root().size = Vector2i(640, 480)
	var opt: MatchOptions = load("res://scenes/MatchOptions.gd").new()
	get_root().add_child(opt)
	opt.anchor_left = 0.0
	opt.anchor_top = 0.0
	opt.anchor_right = 0.0
	opt.anchor_bottom = 0.0
	opt.position = Vector2.ZERO
	opt.size = Vector2(640, 480)
	opt.setup("brief")

	# [tab_index, name, control mutations to show the live overlay]
	var scenes := [
		[0, "match", {}],
		[1, "graphics", {"gfx_sky": false, "pitch_detail": "min", "stadium_detail": "low"}],
		[2, "cameras", {"camera_mode": "auto"}],
		[3, "sound", {"snd_ambient": false}],
	]
	for sc in scenes:
		opt._tab = int(sc[0])
		for k in (sc[2] as Dictionary):
			opt._s[k] = sc[2][k]
		opt.queue_redraw()
		for _i in 12:
			await process_frame
		await RenderingServer.frame_post_draw
		var img := get_root().get_texture().get_image()
		var name := "match_options_%s.png" % sc[1]
		var err := img.save_png(dir.path_join(name))
		print("SHOT %s err=%d %dx%d" % [name, err, img.get_width(), img.get_height()])
	print("SHOTS DONE")
	quit(0)
