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

	# Drive the tactics screens through the real UI (catches wiring bugs).
	main._push(main._show_tactics)
	await process_frame
	main._show_lineup()                         # render LINE-UP
	await process_frame
	main._activate_formation("4-3-3")           # change shape (pops back to tactics)
	await process_frame
	ok = _assert(Tactics.from_dict(main._career.tactics).formation == "4-3-3",
		"UI formation change persisted") and ok
	main._push(main._show_lineup)
	await process_frame
	main._assign_slot(10, _bench_outfielder(gamedb, main))   # swap a forward
	await process_frame
	ok = _assert(Tactics.from_dict(main._career.tactics).validate(
		gamedb.club(main._career.club_id)) == "", "UI line-up still valid after swap") and ok
	main._activate_tactics({"a": "marking"})    # toggle marking in place
	await process_frame
	main._show_takers()
	await process_frame
	main._show_load_tactics()
	await process_frame

	main._show_career()                         # back to hub
	await process_frame
	main._activate_career({"act": "save"})      # save path
	ok = _assert(Career.has_save(), "career saved to disk") and ok

	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	quit(0 if ok else 1)


## A squad outfielder not currently in the manager's XI (to test a swap).
func _bench_outfielder(gamedb: Node, main: Node) -> int:
	var club: Dictionary = gamedb.club(main._career.club_id)
	var t := Tactics.from_dict(main._career.tactics)
	var in_xi: Dictionary = {}
	for id in t.xi:
		in_xi[int(id)] = true
	for p in club.get("players", []):
		if not p.get("isGK") and not in_xi.has(int(p["id"])):
			return int(p["id"])
	return t.xi[10]


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
