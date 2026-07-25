extends SceneTree
## Render the YOUTH TEAM screen with the PLAYERS FOUND shortlist populated — the state
## the owner asked for ("the players they find are supposed to be possible to click on
## to offer contract"). Not a parity shot: the original's FILLED panel is in no frame we
## hold, so this is an eyeball check that the rows land inside the frame-measured
## interior and hit-test back to themselves.
##   DISPLAY=:5 PM98_SHOT_DIR=out ~/godot462 --rendering-driver opengl3 \
##       --path app --script res://tests/shot_youth_found.gd

func _initialize() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("SHOT SKIPPED: needs a rendering driver")
		quit(1)
		return
	var dir := OS.get_environment("PM98_SHOT_DIR")
	if dir == "":
		dir = "/tmp"
	get_root().size = Vector2i(640, 480)
	var node: YouthScreen = load("res://scenes/YouthScreen.gd").new()
	get_root().add_child(node)
	node.position = Vector2.ZERO
	node.size = Vector2(640, 480)

	# FUN_00575e80 keeps exactly ONE match, out of the shipped 0x26e4 pool — so the
	# panel this renders is the real one, with a real shipped youngster in it.
	var by_id: Dictionary = {}
	var db: Dictionary = JSON.parse_string(
		FileAccess.open("res://data/game_db.json", FileAccess.READ).get_as_text())
	var drng := RandomNumberGenerator.new()
	drng.seed = 20260725
	for c in db.get("clubs", []):
		by_id[int(c["id"])] = c
		if int(c["id"]) == Youth.POOL_CLUB_ID:
			for pl in c.get("players", []):
				Youth.degrade(pl, drng)
	var found := Youth.scout_search(drng, ["DRIBBLING"], Youth.pool_of(by_id))
	PMChrome.header_phase = "season"
	node.setup([], [{"id": 1, "name": "P. MITCHELL", "role": Staff.YOUTH_TEAM_SCOUT,
			"stars": 5.0, "wage": 1000},
		{"id": 2, "name": "G. KEEPING", "role": Staff.YOUTH_TEAM_MANAGER,
			"stars": 3.5, "wage": 900}],
		"MATS", "Bolton W", "1997-98", 20, 25, false, {"DRIBBLING": true}, found)
	await process_frame
	await process_frame
	var img := get_root().get_texture().get_image()
	img.save_png("%s/youth_found.png" % dir)
	print("wrote %s/youth_found.png" % dir)

	# the rows must hit-test back to themselves
	var ok := true
	for fr in node._found_rects:
		var c: Vector2 = (fr["rect"] as Rect2).get_center()
		var hit := node._hit(c)
		if hit != "found:%d" % int(fr["pid"]):
			ok = false
			print("  FAIL row %d hit-tests to '%s'" % [int(fr["pid"]), hit])
	print("found rows: %d, hit-test %s" % [node._found_rects.size(), "OK" if ok else "BROKEN"])
	quit(0 if ok and node._found_rects.size() == 1 else 1)
