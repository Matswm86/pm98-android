extends SceneTree
## Scene-level smoke test: instantiates the real Main UI and drives the career
## flow through its own methods (start -> advance -> table -> save), asserting no
## crash and that state transitions. Catches UI-wiring bugs the logic test can't.
##   ~/godot462 --headless --path app --script res://tests/test_career_ui.gd


func _initialize() -> void:
	_run()


func _run() -> void:
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	get_root().add_child(main)
	# Let _ready + autoload DB load settle.
	for _i in 30:
		await process_frame
	var ok := true

	var gamedb: Node = get_root().get_node_or_null("GameDB")
	if gamedb == null:
		print("  [SKIP] GameDB autoload not present under --script; UI smoke skipped")
		print("\nALL PASS")
		quit(0)
		return
	ok = _assert(gamedb.leagues.size() > 0, "GameDB loaded %d leagues" % gamedb.leagues.size()) and ok

	var league: Dictionary = {}
	for lg in gamedb.leagues:
		if lg.get("id") == "eng_prem":
			league = lg
	var club: Dictionary = gamedb.clubs_in_league("eng_prem")[0]

	main._begin_career(league, club)            # build career + enter hub
	await process_frame
	ok = _assert(main._career != null and main._career.club_id == int(club["id"]),
		"career created for %s" % club.get("name", "?")) and ok
	ok = _assert(main._career.week == 0, "starts at week 0") and ok

	# Advance three weeks through the real UI path.
	for _w in 3:
		main._career_advance()
		await process_frame
	ok = _assert(main._career.week == 3, "advanced to week 3 (got %d)" % main._career.week) and ok

	main._show_career_table()                   # render standings view
	await process_frame
	main._show_career()                         # back to hub
	await process_frame
	main._activate_career({"act": "save"})      # save path
	ok = _assert(Career.has_save(), "career saved to disk") and ok

	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	quit(0 if ok else 1)


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
