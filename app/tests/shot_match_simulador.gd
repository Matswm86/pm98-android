extends SceneTree
## REAL-render capture of the WATCH 2D simulador (MatchSimulador.gd) through the actual
## Godot GL renderer (Xvfb + software GL). Captures the pitch with the real DATSIM sprites
## at three moments of a synthetic 1-1 fixture: kick-off, the home goal lunge (12'), and the
## away pressure late on (80'), so the sprite kits, ball, arrow and HUD can be eyeballed.
##   PM98_SHOT_DIR=out DISPLAY=:1 godot462 --rendering-driver opengl3 --path app \
##       --script res://tests/shot_match_simulador.gd

func _initialize() -> void:
	_run()


func _run() -> void:
	var dir := OS.get_environment("PM98_SHOT_DIR")
	if dir == "":
		dir = "/tmp"
	get_root().size = Vector2i(640, 480)

	var lines: Array = [
		{"minute": 0, "side": -1, "text": "KICK OFF"},
		{"minute": 12, "side": 0, "text": "Goal by A (Home)", "goal": true},
		{"minute": 30, "side": 1, "text": "Corner taken by B"},
		{"minute": 45, "side": -1, "text": "HALF TIME"},
		{"minute": 58, "side": 1, "text": "Goal by C (Away)", "goal": true},
		{"minute": 70, "side": 0, "text": "Shot saved by D (Away)"},
		{"minute": 90, "side": -1, "text": "FULL TIME"},
	]

	var sim: MatchSimulador = load("res://scenes/MatchSimulador.gd").new()
	get_root().add_child(sim)
	sim.anchor_left = 0.0
	sim.anchor_top = 0.0
	sim.anchor_right = 0.0
	sim.anchor_bottom = 0.0
	sim.position = Vector2.ZERO
	sim.size = Vector2(640, 480)
	sim.setup("Liverpool", "Everton", 1, 1, lines, 264, 261)
	sim.set_process(false)   # freeze the clock; we drive the minute by seek()

	for shot in [["ko", 1.0], ["home_goal", 12.0], ["away_press", 80.0]]:
		sim.seek(float(shot[1]))
		sim.queue_redraw()
		for _i in 12:
			await process_frame
		await RenderingServer.frame_post_draw
		var img := get_root().get_texture().get_image()
		var name := "match_sim_%s.png" % shot[0]
		var err := img.save_png(dir.path_join(name))
		print("SHOT %s err=%d %dx%d" % [name, err, img.get_width(), img.get_height()])
	print("SHOTS DONE")
	quit(0)
