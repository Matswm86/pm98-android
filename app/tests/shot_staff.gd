extends SceneTree
## REAL-render capture of the rebuilt CLUB PERSONNEL (StaffScreen) screen.
##   DISPLAY=:1 PM98_SHOT_DIR=out ~/godot462 --rendering-driver opengl3 \
##       --path app --script res://tests/shot_staff.gd
## Emits two PNGs:
##   staff_ref.png  = default/empty personnel -> the VACANT state a career opens in
##                    (all bars blank, no staff hired), matching walkthrough frame 115.
##   staff_live.png = a synthetic hired backroom -> proves the live-value overlay
##                    (bar/name/half-stars/wage redraw over the blanked cells).

func _initialize() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("SHOTS SKIPPED: shot_staff needs a rendering driver (X11/xvfb), not --headless")
		quit(1)
		return
	var dir := OS.get_environment("PM98_SHOT_DIR")
	if dir == "":
		dir = "/tmp"
	# match frame 121's header state (preseason / Friday 1 August 1997)
	PMChrome.header_phase = "preseason"
	PMChrome.header_date = {"wd": "Friday", "day": "1", "mon": "August", "year": "1997"}
	get_root().size = Vector2i(640, 480)

	var node: StaffScreen = load("res://scenes/StaffScreen.gd").new()
	get_root().add_child(node)
	node.anchor_left = 0.0
	node.anchor_top = 0.0
	node.anchor_right = 0.0
	node.anchor_bottom = 0.0
	node.position = Vector2.ZERO
	node.size = Vector2(640, 480)

	# 1) default: empty personnel -> the VACANT career-start state (no staff hired)
	node.setup({}, "MWM", "Manchester Utd.", "1997-98", 1, -1)
	await _grab(dir, "staff_ref.png")

	# 1b) frame-121 oracle: render the WITNESSED Man Utd backroom (ref_staff, the
	# builder's pixel transcription of frame 121) so the live value layer (names/
	# stars/wages) can be diffed against the original frame directly.
	var spec_f := FileAccess.open("res://art/screens/staff/personnel_chrome.json", FileAccess.READ)
	var ref121: Dictionary = {}
	if spec_f != null:
		var spec: Variant = JSON.parse_string(spec_f.get_as_text())
		if typeof(spec) == TYPE_DICTIONARY:
			ref121 = spec.get("ref_staff", {})
	node.setup(ref121, "MWM", "Manchester Utd.", "1997-98", 1, -1)
	await _grab(dir, "staff_ref121.png")

	# 2) live overlay: a synthetic OTHER-club backroom over the baked cells
	var live := {
		"HANDLING": {"name": "R. Olsen", "stars": 2.0, "wage": 9000},
		"PASSING": {"name": "K. Berg", "stars": 3.5, "wage": 14000},
		"DRIBBLING": {"name": "T. Dahl", "stars": 1.5, "wage": 6000},
		"HEADING": {"name": "S. Vik", "stars": 4.0, "wage": 18000},
		"TACKLING": {"name": "M. Ruud", "stars": 2.5, "wage": 11000},
		"SHOOTING": {"name": "J. Moe", "stars": 5.0, "wage": 40000},
		"PHYSIOTHERAPIST": {"name": "L. Haug", "stars": 3.0, "wage": 22000},
		"PSYCHOLOGIST": {"name": "E. Lie", "stars": 2.0, "wage": 8000},
		"ASSISTANT_MANAGER": {"name": "P. Sund", "stars": 4.5, "wage": 30000},
		"SCOUT": {"name": "A. Nes", "stars": 3.5, "wage": 19000},
		"YOUTH_TEAM_MANAGER": {"name": "B. Aas", "stars": 3.0, "wage": 13000},
		"YOUTH_TEAM_SCOUT": {"name": "F. Ek", "stars": 1.0, "wage": 5000},
		"GROUNDSMAN": {"name": "O. Rye", "stars": 4.0, "wage": 4000},
	}
	node.setup(live, "T. TESTER", "Rosenborg BK", "1997-98", 1, -1)
	await _grab(dir, "staff_live.png")
	print("SHOTS DONE")
	quit(0)


func _grab(dir: String, name: String) -> void:
	for _i in 16:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := get_root().get_texture().get_image()
	var err := img.save_png(dir.path_join(name))
	print("SHOT %s err=%d %dx%d" % [name, err, img.get_width(), img.get_height()])
