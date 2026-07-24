extends SceneTree
## Render the TRAINING screen with hired skill coaches + an AUTO-assigned focus, so the
## CURRENT TRAINING STAFF band, the TP column, TOTAL TRAINABLE PLAYERS, the grid tags
## and the grid TOTAL can be render-diffed against the live captures.
##   PM98_SHOT_DIR=<dir> godot4 --path app --script res://tests/shot_training_focus.gd

func _initialize() -> void:
	_run()


func _run() -> void:
	var dir := OS.get_environment("PM98_SHOT_DIR")
	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	var db: Dictionary = JSON.parse_string(f.get_as_text())
	var league: Dictionary = {}
	var prem: Array = []
	for lg in db.get("leagues", []):
		if lg.get("id") == "eng_prem":
			league = lg
	for cl in db.get("clubs", []):
		if cl.get("leagueId") == "eng_prem":
			prem.append(cl)
	var c := Career.create(prem[0], league, prem, [league])
	# Hire the two coaches the live capture had: HANDLING 4.0* and SHOOTING 2.5*.
	c.staff = [
		{"id": 1, "role": Staff.HANDLING, "name": "F. Bush", "stars": 4.0, "wage": 30000},
		{"id": 2, "role": Staff.SHOOTING, "name": "G. Slattery", "stars": 2.5, "wage": 6000},
	]
	print("total_trainable=%d (expect 6)" % Training.total_trainable(c.staff))
	c.auto_training_focus()
	print("AUTO assigned=%d  focus=%s" % [c.training_focus.size(), c.training_focus])

	var scr: TrainingScreen = load("res://scenes/TrainingScreen.gd").new()
	scr.size = Vector2(TrainingScreen.W, TrainingScreen.H)
	root.add_child(scr)
	var club: Dictionary = (prem[0] as Dictionary).duplicate()
	club["players"] = c.my_squad()
	scr.setup(club, c.staff, {}, c.training_focus)
	scr._sel_pid = int((c.my_squad()[0] as Dictionary).get("id", -1))
	await process_frame
	await process_frame
	if dir != "":
		var img := root.get_texture().get_image()
		img.save_png("%s/training_focus.png" % dir)
		print("SHOT training_focus.png")
	# Cap behaviour, printed so the run is self-verifying.
	var extra := -1
	for p in c.my_squad():
		if not c.training_focus.has(int(p.get("id", -1))):
			extra = int(p.get("id", -1))
			break
	print("over-cap add -> %s (expect the FULL_MSG alert)" % c.set_training_focus(extra, "GENERAL"))
	quit(0)
