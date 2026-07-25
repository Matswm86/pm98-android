extends SceneTree
## The owner's 2026-07-24 report: "scout screen isn't working as original. The scout
## results are supposed to be clickable to make offers directly there in that screen."
##
## The signal was wired all along — `ScoutScreen.player_pressed` -> `_show_make_offer_card`.
## What broke was the DESTINATION: that handler resolved the player with
## `Career._find_in`, which only walks `rosters`, i.e. the manager's own division. A
## scout searches the WHOLE WORLD (E.U. / NON E.U.) and the free-agent pool, so every
## foreign hit — the great majority of results — fell through to
## "That player is no longer available." and the card never opened.
##
## Drives the REAL Main UI: arm a world search, tick it to completion, tap a FOREIGN
## result row and a FREE-AGENT row, and assert a MakeOfferScreen actually mounts.
##   ~/godot462 --headless --path app --script res://tests/test_scout_offer_route.gd

func _initialize() -> void:
	_run()


func _run() -> void:
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	get_root().add_child(main)
	for _i in 40:
		await process_frame
	var gamedb: Node = get_root().get_node_or_null("GameDB")
	if gamedb == null:
		print("  [SKIP] GameDB autoload absent under --script")
		print("test_scout_offer_route: PASS")
		quit(0)
		return
	var ok := true
	var league: Dictionary = {}
	for lg in gamedb.leagues:
		if lg.get("id") == "eng_prem":
			league = lg
	main._begin_career("Test Mgr", league, gamedb.clubs_in_league("eng_prem")[0])
	for _i in 12:
		await process_frame
	for _s in 12:
		var n: Node = _top(main)
		if n == null or not _fire(n):
			break
		for _i in 5:
			await process_frame
	var c = main._career

	# ---- arm a world + free-agent search ------------------------------------
	var world: Array = []
	for cl in gamedb.clubs:
		var cd: Dictionary = cl
		if int(cd.get("id", -1)) == c.club_id or c.rosters.has(int(cd.get("id", -1))):
			continue
		world.append(cd)
	c.start_scout_search({"eu": true, "non_eu": true, "no_team": true}, [], world)
	c.week += 10                       # jump past the search's due week
	c._tick_scout_search()
	ok = _assert(not c.scout_results.is_empty(),
		"the search returned %d rows" % c.scout_results.size()) and ok

	var foreign := {}
	var freeagent := {}
	for r in c.scout_results:
		var rd: Dictionary = r
		var cid := int(rd.get("club_id", -2))
		if cid == -1 and freeagent.is_empty():
			freeagent = rd
		elif cid > 0 and not c.rosters.has(cid) and foreign.is_empty():
			foreign = rd
	ok = _assert(not foreign.is_empty(), "the search found a FOREIGN club's player") and ok
	ok = _assert(not freeagent.is_empty(), "and a PLAYER WITHOUT TEAM") and ok

	# ---- tapping a foreign row must open the card, not toast ---------------
	for probe in [{"row": foreign, "what": "foreign"}, {"row": freeagent, "what": "free agent"}]:
		var rd: Dictionary = (probe as Dictionary)["row"]
		if rd.is_empty():
			continue
		main._show_scout_screen()
		for _i in 8:
			await process_frame
		var scr: ScoutScreen = _first(main, "ScoutScreen") as ScoutScreen
		ok = _assert(scr != null, "the SCOUT screen opened") and ok
		if scr == null:
			continue
		scr.player_pressed.emit(rd)
		for _i in 8:
			await process_frame
		var card: MakeOfferScreen = _first(main, "MakeOfferScreen") as MakeOfferScreen
		ok = _assert(card != null, "a %s row opens the MAKE OFFER card (%s of %s)"
			% [str((probe as Dictionary)["what"]), rd.get("name", "?"),
				rd.get("club_name", "?")]) and ok
		if card != null:
			ok = _assert(str(card._p.get("name", "")) == str(rd.get("name", "")),
				"the card is showing the player that was tapped") and ok
			ok = _assert(card._offer >= MakeOfferScreen.FLOOR,
				"CLUB OFFER seeded (£%d)" % card._offer) and ok
		for ch in main.get_children():
			if ch is Control and ch != main._hub:
				ch.queue_free()
		for _i in 4:
			await process_frame

	# ---- and an OWN-DIVISION row still routes the live way ------------------
	var live := {}
	for r in c.scout_results:
		var rd2: Dictionary = r
		if c.rosters.has(int(rd2.get("club_id", -2))):
			live = rd2
			break
	if not live.is_empty():
		main._show_make_offer_card(live)
		for _i in 8:
			await process_frame
		ok = _assert(_first(main, "MakeOfferScreen") != null,
			"an own-division scout row still opens the card") and ok

	print("test_scout_offer_route: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)


func _first(main: Node, cls: String) -> Node:
	for ch in main.get_children():
		if ch.get_script() != null and str(ch.get_script().resource_path).ends_with("%s.gd" % cls) \
				and not ch.is_queued_for_deletion():
			return ch
	return null


func _top(main: Node) -> Node:
	var last: Node = null
	for ch in main.get_children():
		if ch is Control and ch != main._hub and is_instance_valid(ch) \
				and not ch.is_queued_for_deletion():
			last = ch
	return last


func _fire(n: Node) -> bool:
	for s in ["continue_pressed", "ok_pressed", "back_pressed", "done"]:
		if n.has_signal(s):
			n.emit_signal(s)
			return true
	return false


func _assert(cond: bool, label: String) -> bool:
	print(("  ok   " if cond else "  FAIL ") + label)
	return cond
