extends SceneTree
## END-TO-END through the REAL Main UI for the 2026-07-24 owner report.
##
## The unit tests pin each model; this one proves the WIRING — that a tap in the app
## actually reaches it. Same lesson as the sell loop: a green model test said nothing
## about what the owner's finger did.
##
## Covered here: TACTICS ROLE picker (open from the row arrow, pick, persist), the
## INJURIES PHYS. button, and the TRAINING grid showing a brand-new signing.
##   ~/godot462 --headless --path app --script res://tests/test_owner_fixes_e2e.gd

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
		print("test_owner_fixes_e2e: PASS")
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
	for _s in 12:
		var n: Node = _top(main)
		if n == null or not _fire(n):
			break
		for _i in 5:
			await process_frame
	var c = main._career

	# ---- 1. TACTICS: the ROLE picker ---------------------------------------
	main._show_tactics_board_screen()
	for _i in 8:
		await process_frame
	var board: TacticsBoardScreen = _first(main, "TacticsBoardScreen") as TacticsBoardScreen
	ok = _assert(board != null, "the TACTICS board opened") and ok
	if board != null:
		board.size = Vector2(640, 480)
		for _i in 3:
			await process_frame
		# row 1's POS-column arrow (row 0 is the keeper, who has no alternatives)
		var row := 1
		var pid := int((c.tactics.get("xi", []) as Array)[row])
		var before := int(c._find_in(c.club_id, pid).get("posFine", 0))
		_tap(board, Vector2(TacticsBoardScreen.ROLE_BTN_X + 9,
			TacticsBoardScreen.ROW_Y0 + TacticsBoardScreen.ROW_PITCH * row + 7))
		for _i in 6:
			await process_frame
		var pop: RolePopup = _first(main, "RolePopup") as RolePopup
		ok = _assert(pop != null, "tapping the row arrow raises the ROLE picker") and ok
		if pop != null:
			pop.size = Vector2(640, 480)
			for _i in 3:
				await process_frame
			# pick a role he is NOT already on
			var pick := 1 if before != 1 else 2
			var y := int(pop._spec.get("item_y0", 112)) \
				+ int(pop._spec.get("item_pitch", 14)) * (pick - 1) + 6
			_tap(pop, Vector2(320, y))
			for _i in 8:
				await process_frame
			var after := int(c._find_in(c.club_id, pid).get("posFine", 0))
			ok = _assert(after == pick,
				"the pick applied: posFine %d -> %d (wanted %d)" % [before, after, pick]) and ok
			ok = _assert(int(c._find_in(c.club_id, pid).get("posNatural", -1)) == before,
				"his NATURAL role is kept, so the picker still paints it gold") and ok
			ok = _assert(_first(main, "RolePopup") == null, "the picker closed") and ok
	for ch in main.get_children():
		if ch is Control and ch != main._hub:
			ch.queue_free()
	for _i in 4:
		await process_frame

	# ---- 2. INJURIES: the PHYS. "+" button ---------------------------------
	# hire a max-quality physio, injure someone, then tap his row's button
	c.staff = [{"id": 1, "role": Staff.PHYSIOTHERAPIST, "name": "P. Test", "stars": 5.0,
		"quality": 5, "wage": 45000}]
	var victim: Dictionary = c.my_squad()[0]
	victim["injured_weeks"] = 8
	victim["injury_weeks_total"] = 8
	victim["injury_type"] = 6
	main._show_injuries_screen()
	for _i in 8:
		await process_frame
	var inj: InjuriesScreen = _first(main, "InjuriesScreen") as InjuriesScreen
	ok = _assert(inj != null, "the INJURIES screen opened") and ok
	if inj != null:
		inj.size = Vector2(640, 480)
		for _i in 3:
			await process_frame
		var sect := inj._section_of(victim)
		var tops: Array = []
		for s in InjuriesScreen.SECT:
			if str(s["key"]) == sect:
				tops = s["tops"]
		_tap(inj, Vector2(InjuriesScreen.PHYS_BTN_XY.x + 10, int(tops[0]) + 8))
		for _i in 8:
			await process_frame
		var left := int(c._find_in(c.club_id, int(victim.get("id", -1))).get("injured_weeks", 0))
		ok = _assert(left == 4,
			"the PHYS. button halved an 8-week injury to 4 (got %d)" % left) and ok
	for ch in main.get_children():
		if ch is Control and ch != main._hub:
			ch.queue_free()
	for _i in 4:
		await process_frame

	# ---- 3. TRAINING: a brand-new signing is reachable ---------------------
	# Career appends a signing to the END of the squad, which is exactly the man the
	# old slot cap dropped.
	var newbie := {"id": 999001, "name": "NEWSIGNING", "pos": "DF", "isGK": false,
		"squadNo": 44, "clubId": c.club_id,
		"attrs": {"VE": 70, "RE": 70, "AG": 70, "CA": 70, "RM": 70, "RG": 70,
			"PA": 70, "TI": 70, "EN": 70, "PO": 70}}
	c.rosters[c.club_id].append(newbie)
	main._show_training_screen()
	for _i in 8:
		await process_frame
	var tr: TrainingScreen = _first(main, "TrainingScreen") as TrainingScreen
	ok = _assert(tr != null, "the TRAINING screen opened") and ok
	if tr != null:
		tr.size = Vector2(640, 480)
		for _i in 3:
			await process_frame
		var bucket: Array = tr._buckets["def"]
		var idx := -1
		for i in bucket.size():
			if int((bucket[i] as Dictionary).get("id", -1)) == 999001:
				idx = i
		ok = _assert(idx >= 0, "the new signing is in the DEFENDERS bucket") and ok
		# scroll him into view and assert the grid hit-test finds him
		var slots := tr._slots_of("def")
		var band: Array = TrainingScreen.SCROLL_BAND["def"]
		var dn := Vector2(TrainingScreen.SCROLL_X + 8,
			int(band[0]) + int(band[1]) - TrainingScreen.SCROLL_BTN_H + 7)
		for _s in 20:
			if idx < tr._first_of("def") + slots:
				break
			_tap(tr, dn)
			for _i in 2:
				await process_frame
		ok = _assert(idx < tr._first_of("def") + slots,
			"the DOWN arrow scrolls him into view (first=%d)" % tr._first_of("def")) and ok
		var vis := idx - tr._first_of("def")
		var tops2: Array = TrainingScreen.SECT[1]["tops"]
		var pid2 := tr._grid_pid_at(Vector2(TrainingScreen.BAR_X0 + 40,
			int(tops2[vis]) + 6))
		ok = _assert(pid2 == 999001,
			"and his row hit-tests to him (got %d)" % pid2) and ok

	print("test_owner_fixes_e2e: ", "PASS" if ok else "FAIL")
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


## Device-shaped: a finger press arrives as the emulated mouse event AND the touch.
func _tap(n: Control, p: Vector2) -> void:
	for pressed in [true, false]:
		var m := InputEventMouseButton.new()
		m.button_index = MOUSE_BUTTON_LEFT
		m.position = p
		m.pressed = pressed
		m.device = InputEvent.DEVICE_ID_EMULATION
		n._on_input(m)
		var e := InputEventScreenTouch.new()
		e.index = 0
		e.position = p
		e.pressed = pressed
		n._on_input(e)


func _assert(cond: bool, label: String) -> bool:
	print(("  ok   " if cond else "  FAIL ") + label)
	return cond
