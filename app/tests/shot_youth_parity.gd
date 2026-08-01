extends SceneTree
## Frame-parity captures of the YOUTH TEAM screen in the EXACT states the original
## walkthrough frames show, for pixel-diffing against them (diff_youth_parity.py):
##   youth_087.png  fresh career, NO staff (frame 087_154632): all-NO capabilities,
##                  disabled LEDs/SEARCH, hire-a-scout message, empty roster,
##                  PARAMETERS selected.
##   youth_088.png  same + RATING held (white ring)          vs 088_154633
##   youth_089.png  same + RETURN held (white ring)          vs 089_154635
##   youth_047.png  scout P. Mitchell 5.0 + manager G. Keeping 3.5, "3 PLAYERS",
##                  all YES, DRIBBLING/PASSING/SHOOTING lit, searching message,
##                  RATING selected (frame 047_164509).
##   youth_048.png  same + SEARCH held (red ring)            vs 048_164510
## Needs a real renderer (Xvfb / local X11):
##   DISPLAY=:1 PM98_SHOT_DIR=out ~/godot462 --rendering-driver opengl3 \
##       --path app --script res://tests/shot_youth_parity.gd

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

	var node: YouthScreen = load("res://scenes/YouthScreen.gd").new()
	get_root().add_child(node)
	node.anchor_left = 0.0
	node.anchor_top = 0.0
	node.anchor_right = 0.0
	node.anchor_bottom = 0.0
	node.position = Vector2.ZERO
	node.size = Vector2(640, 480)

	# ---- frame 087 state: run1, MWM / Man Utd, Friday 1 August 1997, Week 1 ----
	PMChrome.header_phase = "preseason"
	PMChrome.header_date = {"wd": "Friday", "day": "1", "mon": "August", "year": "1997"}
	node.setup([], [], "MWM", "Manchester Utd.", "1997-98", 1, -1)
	await _grab(dir, "youth_087.png")

	# 088: RATING held (white ring; PARAMETERS stays the selected plaque)
	node._press = "btn:rating"
	node.queue_redraw()
	await _grab(dir, "youth_088.png")
	# 089: RETURN held
	node._press = "btn:return"
	node.queue_redraw()
	await _grab(dir, "youth_089.png")
	node._press = ""

	# ---- frame 047 state: run3, "asdf", Sunday 10 August 1997, Week 2 ----
	# Witnessed values transcribed from the frame (youth_chrome.json ref_live_state):
	# scout P. Mitchell (5 stars) / manager G. Keeping (3.5) / "3 PLAYERS" over an
	# empty visible list (counter semantics unresolved -> pinned via _count_override).
	PMChrome.header_date = {"wd": "Sunday", "day": "10", "mon": "August", "year": "1997"}
	var staff := [
		{"id": 1, "role": Staff.YOUTH_TEAM_SCOUT, "name": "P. Mitchell", "stars": 5.0, "wage": 40000},
		{"id": 2, "role": Staff.YOUTH_TEAM_MANAGER, "name": "G. Keeping", "stars": 3.5, "wage": 20000},
	]
	var sel := {"DRIBBLING": true, "PASSING": true, "SHOOTING": true}
	node.setup([], staff, "asdf", "Manchester Utd.", "1997-98", 2, -1, true, sel)
	node._mode = "rating"
	node._count_override = 3
	node.queue_redraw()
	await _grab(dir, "youth_047.png")

	# 048: SEARCH held (red ring)
	node._press = "btn:search"
	node.queue_redraw()
	await _grab(dir, "youth_048.png")
	node._press = ""

	# ---- B9: the FILLED PLAYERS FOUND list ------------------------------------------
	# `tools/re/refs/b9-players-found-2026-08-01/02_players_found_first.png`
	# — a TOTAL-level Bolton W career, Saturday 28 March 1998, Premier week 34, whose
	# YOUTH TEAM SCOUT C. Stump (4.5*) has reported his first prospect. Every value below
	# is read off that frame: all six capabilities YES, all six LEDs still LIT after the
	# report, the manager P. Klachinsky (5*) over "4 PLAYERS" and an EMPTY roster, the
	# PARAMETERS plaque selected — and one row, `Chapman  41  [ROL 10]  £5,000  19`.
	PMChrome.header_phase = "season"
	PMChrome.header_date = {"wd": "Saturday", "day": "28", "mon": "March", "year": "1998"}
	var staff_b9 := [
		{"id": 1, "role": Staff.YOUTH_TEAM_SCOUT, "name": "C. Stump", "stars": 4.5,
			"wage": 32000},
		{"id": 2, "role": Staff.YOUTH_TEAM_MANAGER, "name": "P. Klachinsky", "stars": 5.0,
			"wage": 36000},
	]
	var found := [{
		"id": 9001, "name": "Chapman", "age": 19, "posFine": 10, "contract_wage": 5000,
		"attrs": {"VE": 41, "RE": 41, "AG": 41, "CA": 41},
	}]
	var lit := {}
	for skill in ["HANDLING", "PASSING", "DRIBBLING", "HEADING", "TACKLING", "SHOOTING"]:
		lit[skill] = true
	node.setup([], staff_b9, "matts", "Bolton W", "1997-98", 34, -1, false, lit, found)
	node._mode = "parameters"
	node._arrow_row = "parameters"
	node._count_override = 4
	node.queue_redraw()
	await _grab(dir, "youth_b9found.png")

	# ---- B9's LAST gap: a FILLED YOUTH TEAM ROSTER row ------------------------------
	# `tools/re/refs/youth-roster-2026-08-01/b9_roster_signed_1998-10-03.png` — the same
	# Bolton W career after the prospect was actually SIGNED (the row tap raises the
	# contract card and only OFFER puts him on the roster), Saturday 3 October 1998. Two
	# frames of it 14 months apart differ by 1,672 px and every one of those is in the
	# header date plaque, so the widget is stable and one cut is enough — the same test s84
	# applied to the PLAYERS FOUND panel.
	# Read off the frame: scout S. Munt 1.5* (so HANDLING / TACKLING only, the whole point
	# of `CAP_BY_STARS`), manager H. Constantine 4.5* over "4 PLAYERS", the PLAYERS FOUND
	# panel empty, PARAMETERS selected, and one row:
	#   Burgess | SP 20 | ST 19 | AG 20 | QU 21 | AV 20 | ROL | £5,000 | 3 | 3
	PMChrome.header_phase = "season"
	PMChrome.header_date = {"wd": "Saturday", "day": "3", "mon": "October", "year": "1998"}
	var staff_row := [
		{"id": 1, "role": Staff.YOUTH_TEAM_SCOUT, "name": "S. Munt", "stars": 1.5,
			"wage": 32000},
		{"id": 2, "role": Staff.YOUTH_TEAM_MANAGER, "name": "H. Constantine", "stars": 4.5,
			"wage": 36000},
	]
	# AV is `Youth.ability`, which averages the four; the frame's 20 is that average of
	# 20 / 19 / 20 / 21.
	var roster := [{
		"id": 9101, "name": "Burgess", "age": 17, "posFine": 10,
		"contract_wage": 5000, "contract_years": 3, "contract_left": 3,
		"attrs": {"VE": 20, "RE": 19, "AG": 20, "CA": 21},
	}]
	node.setup(roster, staff_row, "mats", "Bolton W", "1998-99", 9, -1, false,
		{"HANDLING": true, "TACKLING": true}, [])
	node._mode = "parameters"
	node._arrow_row = "parameters"
	node._count_override = 4
	node.queue_redraw()
	await _grab(dir, "youth_b9roster.png")

	print("SHOTS DONE")
	quit(0)


func _grab(dir: String, name: String) -> void:
	for _i in 16:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := get_root().get_texture().get_image()
	var err := img.save_png(dir.path_join(name))
	print("SHOT %s err=%d %dx%d" % [name, err, img.get_width(), img.get_height()])
