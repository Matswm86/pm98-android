extends SceneTree
## The LINE-UP T/I/S plate — the owner's "where is injuries and statistics ... I
## can't see either" (2026-07-24).
##
## They are the plate's rows 2 and 3, and the original REPLACES the whole plate
## with UNDO while a pending change exists — an XI edit this visit, or an injured
## starter still in the XI. Both states are witnessed:
##   walkthrough 155_162931  Beckham injured (7 WEEKS) IN the XI  -> UNDO
##   wine 31_lineup / 85_xi_fixed  injured man on the BENCH       -> TRAINING /
##                                                                   INJURIES /
##                                                                   STATISTICS
## So this test pins BOTH halves: the plate hides exactly when the original hides
## it, AND the way out works — moving the injured man to the bench and re-entering
## LINE-UP brings the plate (and with it INJURIES / STATISTICS) back.
##   ~/godot462 --headless --path app --script res://tests/test_lineup_tis_plate.gd


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
		print("test_lineup_tis_plate: PASS")
		quit(0)
		return
	var ok := true
	var league: Dictionary = {}
	for lg in gamedb.leagues:
		if lg.get("id") == "eng_prem":
			league = lg
	var club: Dictionary = gamedb.clubs_in_league("eng_prem")[0]
	main._begin_career("Test Mgr", league, club)
	for _i in 12:
		await process_frame
	for ch in main.get_children():
		if ch is Control and ch != main._hub:
			ch.queue_free()
	for _i in 4:
		await process_frame
	var c = main._career

	# ---- fit squad: the plate must show all three doors ---------------------
	main._show_lineup_screen()
	for _i in 6:
		await process_frame
	var lu: LineupScreen = _first(main, "LineupScreen") as LineupScreen
	ok = _assert(lu != null, "LINE-UP mounted") and ok
	if lu == null:
		print("test_lineup_tis_plate: FAIL")
		quit(1)
		return
	ok = _assert(not lu._pending_change(), "fit squad: no pending change") and ok
	lu.size = Vector2(640, 480)
	for _i in 3:
		await process_frame
	for i in 3:
		var r: Rect2 = LineupScreen.TIS_BTNS[i]
		ok = _assert(lu._hit(r.get_center()) == ["training", "injuries", "statistics"][i],
			"plate row %d hit-tests as %s" % [i + 1, ["training", "injuries", "statistics"][i]]) and ok
	# and each one really opens its screen
	for pair in [["injuries_pressed", "InjuriesScreen"], ["statistics_pressed", "StatisticsScreen"]]:
		main._show_lineup_screen()
		for _i in 5:
			await process_frame
		var l2: LineupScreen = _first(main, "LineupScreen") as LineupScreen
		l2.emit_signal(str(pair[0]))
		for _i in 6:
			await process_frame
		ok = _assert(_first(main, str(pair[1])) != null, "%s opens %s" % [pair[0], pair[1]]) and ok
		for ch in main.get_children():
			if ch is Control and ch != main._hub:
				ch.queue_free()
		for _i in 3:
			await process_frame

	# ---- injured starter: the original hides the plate behind UNDO ----------
	var xi: Array = c.tactics.get("xi", [])
	var hurt := -1
	for p in c.my_squad():
		if xi.has(int(p.get("id", -1))) and not bool(p.get("isGK", false)):
			hurt = int(p["id"])
			(p as Dictionary)["injured_weeks"] = 3
			break
	ok = _assert(hurt != -1, "picked an outfield starter to injure") and ok
	main._show_lineup_screen()
	for _i in 6:
		await process_frame
	lu = _first(main, "LineupScreen") as LineupScreen
	ok = _assert(lu._pending_change(), "injured starter -> UNDO replaces the plate (frame 155)") and ok
	ok = _assert(lu._hit(Rect2(LineupScreen.TIS_BTNS[1]).get_center()) != "injuries",
		"the INJURIES row is inert while UNDO shows") and ok

	# ---- the way out: bench him, re-enter, the plate is back ----------------
	# a FIT OUTFIELD replacement: swapping a keeper into an outfield slot is
	# illegal in the original too (LineupScreen._swap_legal)
	var bench := -1
	for p in c.my_squad():
		var id := int(p.get("id", -1))
		if xi.has(id) or bool(p.get("isGK", false)) or int(p.get("injured_weeks", 0)) > 0:
			continue
		bench = id
		break
	ok = _assert(bench != -1, "found a fit outfield replacement on the bench") and ok
	var items: Array = lu._flat_items()
	var i_hurt := -1
	var i_bench := -1
	for i in items.size():
		if str(items[i].get("t", "")) != "row":
			continue
		if int(items[i]["pid"]) == hurt:
			i_hurt = i
		elif int(items[i]["pid"]) == bench:
			i_bench = i
	ok = _assert(i_hurt >= 0 and i_bench >= 0, "both rows are in the list") and ok
	if i_hurt >= 0 and i_bench >= 0:
		lu._tap_row(i_hurt)
		lu._tap_row(i_bench)
		for _i in 4:
			await process_frame
		var xi2: Array = c.tactics.get("xi", [])
		ok = _assert(not xi2.has(hurt) and xi2.has(bench),
			"the swap moved the injured man out of the XI") and ok
	for ch in main.get_children():
		if ch is Control and ch != main._hub:
			ch.queue_free()
	for _i in 4:
		await process_frame
	main._show_lineup_screen()
	for _i in 6:
		await process_frame
	lu = _first(main, "LineupScreen") as LineupScreen
	ok = _assert(not lu._pending_change(),
		"re-entering LINE-UP clears the pending change -> the plate is back") and ok
	ok = _assert(lu._hit(Rect2(LineupScreen.TIS_BTNS[2]).get_center()) == "statistics",
		"STATISTICS is reachable again") and ok

	print("test_lineup_tis_plate: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)


func _first(main: Node, cls: String) -> Node:
	for ch in main.get_children():
		if ch.get_script() != null and str(ch.get_script().resource_path).ends_with("%s.gd" % cls):
			return ch
	return null


func _assert(cond: bool, label: String) -> bool:
	print(("  ok   " if cond else "  FAIL ") + label)
	return cond
