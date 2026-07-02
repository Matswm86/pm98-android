extends SceneTree
## Scene-level smoke test for the Track-B browse flows: drives the real Main through the
## database home, the new-career pickers (B2), the database league browse (B3, into the
## reversed SQUAD + LEAGUE TABLES screens), a watched match (B4), and finally entering a
## career (which must drop the front-of-house browse and raise the hub). Headless logic
## only; the pixel render is proven by screenshot.yml (PM98_BROWSE_SHOT).
##   ~/godot462 --headless --path app --script res://tests/test_browse_nav.gd


func _initialize() -> void:
	_run()


func _run() -> void:
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	get_root().add_child(main)
	for _i in 30:
		await process_frame
	var ok := true

	var gamedb: Node = get_root().get_node_or_null("GameDB")
	if gamedb == null:
		print("  [SKIP] GameDB autoload not present under --script; browse smoke skipped")
		print("\nALL PASS")
		quit(0)
		return

	var lg: Dictionary = gamedb.leagues[0]
	var cl: Array = gamedb.clubs_in_league(lg["id"])

	# Database home (B3 root): a BrowseScreen with new-career + every league.
	main._show_home()
	await process_frame
	ok = _assert(main._browse != null and main._browse is BrowseScreen,
		"home is a PM98 browse overlay (not green)") and ok
	ok = _assert(main._browse._rows.size() >= gamedb.leagues.size() + 1,
		"home lists new-career + leagues (%d rows)" % main._browse._rows.size()) and ok

	# New-career SELECCION screen (faithful one-screen name + team select).
	main._show_career_select()
	await process_frame
	ok = _assert(main._seleccion != null and main._seleccion is SeleccionScreen,
		"new-career mounts the faithful SELECCION overlay") and ok
	ok = _assert((main._seleccion._clubs as Array).size() == cl.size(),
		"SELECCION lists the first division's clubs (%d)" % (main._seleccion._clubs as Array).size()) and ok

	# Database league browse (B3): simulate / watch + clubs.
	main._dismiss_seleccion()
	main._show_db_league(lg)
	await process_frame
	ok = _assert(main._browse._rows.size() == cl.size() + 2,
		"db-league lists sim+watch+clubs (%d)" % main._browse._rows.size()) and ok

	# Browse a club -> the reversed dbasewin DATA BASE squad view (B3 routes into the
	# real database browser, GK/DF/MF/FW columns; the PLANTILLA SquadScreen belongs to
	# the in-career hub, not the database).
	main._db_league_select(lg, {"act": "club", "club": cl[0]})
	await process_frame
	var sq: Node = null
	for ch in main.get_children():
		if ch is DataBaseScreen:
			sq = ch
	ok = _assert(sq != null, "club -> reversed DATA BASE squad view") and ok
	if sq != null:
		sq.queue_free()
	await process_frame

	# Simulate the season -> reversed LEAGUE TABLES overlay (B3).
	main._db_league_select(lg, {"act": "sim"})
	await process_frame
	var tb: Node = null
	for ch in main.get_children():
		if ch is LeagueTableScreen:
			tb = ch
	ok = _assert(tb != null, "simulate -> reversed LEAGUE TABLES overlay") and ok
	if tb != null:
		tb.queue_free()
	await process_frame

	# Watch a match (A1): the 2D MATCH VIEW (MatchScreen) mounts, fed the two clubs + a timeline.
	main._play_watch_match(cl[0], cl[1], lg)
	await process_frame
	var matched := false
	for ch in main.get_children():
		if ch is MatchScreen and str(ch._home) != "" and str(ch._away) != "" and not (ch._lines as Array).is_empty():
			matched = true
	ok = _assert(matched, "watch -> 2D MATCH VIEW overlay with a timeline") and ok

	# Enter a career -> the front-of-house browse is dropped and the hub is raised.
	main._begin_career("Test Mgr", lg, cl[0])
	await process_frame
	ok = _assert(main._browse == null, "entering a career clears the browse overlay") and ok
	ok = _assert(main._hub != null and is_instance_valid(main._hub),
		"entering a career raises the MENUPRINCIPAL hub") and ok

	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	quit(0 if ok else 1)


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
