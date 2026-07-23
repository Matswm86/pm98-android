extends SceneTree
## Render-verify the INJURIES sub-screen with real binary-sourced diagnoses in the
## "TYPE OF INJURY" column (Availability.INJURY_TYPES; MANAGER.EXE @ 0x6622e8).
## Eyeball against docs/re/injuries_screen_re.md column map (TYPE OF INJURY x209..324).
##   PM98_SHOT_DIR=out godot4 --rendering-driver opengl3 --path app \
##     --script res://tests/shot_injuries_verify.gd

func _initialize() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("SHOTS SKIPPED: needs a rendering driver")
		quit(1)
		return
	var dir := OS.get_environment("PM98_SHOT_DIR")
	if dir == "":
		dir = "/tmp"
	get_root().size = Vector2i(640, 480)

	var club := _synth_club()
	# One injury per section, spanning the ordinary and serious tiers. Durations
	# are ROLLED from the binary model (Availability._injury_weeks) so the Week
	# column shows the game's real per-type spans (broken leg = season-ending,
	# dead-leg/groin short) instead of a hand-picked number.
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260723
	for pair in [[0, 17], [3, 13], [8, 9], [12, 2]]:
		var idx: int = pair[0]
		var ti: int = pair[1]
		club["players"][idx]["injury_type"] = ti
		club["players"][idx]["injured_weeks"] = Availability._injury_weeks(rng, ti)
	var physio := {"id": 800001, "role": Staff.PHYSIO, "name": "P. Gelbier", "quality": 5,
		"wage": Staff.wage_for(Staff.PHYSIO, 5)}

	var scr: InjuriesScreen = load("res://scenes/InjuriesScreen.gd").new()
	get_root().add_child(scr)
	scr.set_anchors_preset(Control.PRESET_TOP_LEFT)
	scr.position = Vector2.ZERO
	scr.size = Vector2(640, 480)
	for _i in 3:
		await process_frame
	scr.setup(club, [physio], {})
	scr.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var img := get_root().get_texture().get_image()
	img.save_png(dir.path_join("injuries_typed.png"))
	print("SHOT injuries_typed.png")
	quit(0)


func _synth_club() -> Dictionary:
	var players: Array = []
	var spec := [["GK", 2], ["DF", 5], ["MF", 5], ["FW", 3]]
	var pid := 1
	for pair in spec:
		for _n in int(pair[1]):
			var gk: bool = pair[0] == "GK"
			players.append({
				"id": pid, "name": "Player %d" % pid, "squadNo": pid,
				"isGK": gk, "pos": str(pair[0]),
				"injured_weeks": 0, "suspended_weeks": 0,
			})
			pid += 1
	return {"id": 1, "name": "Manchester Utd.", "players": players}
