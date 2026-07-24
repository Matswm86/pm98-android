extends SceneTree
## The TACTICS ROLE picker (RolePopup) against the original.
##
## The one load-bearing claim is the colour rule of `FUN_0056a1d0`: the player's NATURAL
## role (engine +0x1d) is painted GOLD 0x0000dfff = (255,223,0), his five ALTERNATIVES
## (+0x1e..+0x22) WHITE, everything else the default black — over all 18 roles, never a
## filtered list. Live witness `13_pos_arrow.png` (Bolton W week 1, Bergsson): RIGHT BACK
## gold, INSIDE CENTRE LEFT + INSIDE CENTRE RIGHT white, the other 15 black. The database
## must agree: EQUIPOS.PKF stores him posFine 2 with posAlts [5, 6].
##
##   ~/godot462 --headless --path app --script res://tests/test_role_popup.gd

func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true
	var pop: RolePopup = load("res://scenes/RolePopup.gd").new()
	get_root().add_child(pop)
	pop.size = Vector2(640, 480)
	await process_frame

	ok = _assert(not pop._spec.is_empty(), "rolepopup.json loaded") and ok
	ok = _assert(pop.popup_rect() == Rect2(220, 87, 200, 277),
		"popup rect is the frame's own (220,87) 200x277") and ok

	# --- the witnessed player -------------------------------------------------
	pop.setup({"id": 7, "name": "BERGSSON", "posFine": 2, "posAlts": [5, 6]})
	ok = _assert(pop.ink_for(1) == RolePopup.C_NATURAL,
		"RIGHT BACK (his natural role) is GOLD 255,223,0") and ok
	ok = _assert(pop.ink_for(4) == RolePopup.C_ALTERNATE
		and pop.ink_for(5) == RolePopup.C_ALTERNATE,
		"INSIDE CENTRE LEFT + INSIDE CENTRE RIGHT are WHITE") and ok
	var others := 0
	for i in 18:
		if pop.ink_for(i) == RolePopup.C_OTHER:
			others += 1
	ok = _assert(others == 15, "the other 15 roles keep the default ink (got %d)" % others) and ok

	# --- the whole list is always offered ------------------------------------
	ok = _assert(TacticsBoardScreen.FINE_ROLE_LONG.size() == 18,
		"all 18 fine roles are listed") and ok
	ok = _assert(pop.role_at(Vector2(300, 112 + 7)) == 1, "row 0 hit-tests to GOALKEEPER") and ok
	ok = _assert(pop.role_at(Vector2(300, 112 + 14 * 17 + 7)) == 18,
		"row 17 hit-tests to INSIDE LEFT") and ok
	ok = _assert(pop.role_at(Vector2(300, 90)) == 0, "the title bar is not a role row") and ok

	# --- a keeper has no alternatives at all (195/195 in the DB) -------------
	pop.setup({"id": 8, "name": "BRANAGAN", "posFine": 1, "posAlts": []})
	var white := 0
	for i in 18:
		if pop.ink_for(i) == RolePopup.C_ALTERNATE:
			white += 1
	ok = _assert(white == 0, "a keeper shows no white alternates") and ok
	ok = _assert(pop.ink_for(0) == RolePopup.C_NATURAL, "GOALKEEPER is his gold row") and ok

	# --- the database really carries the field --------------------------------
	var gamedb: Node = get_root().get_node_or_null("GameDB")
	if gamedb != null:
		var found := {}
		for cl in gamedb.clubs_in_league("eng_prem"):
			for p in cl.get("players", []):
				if str(p.get("name", "")).to_upper() == "BERGSSON":
					found = p
		if not found.is_empty():
			var alts: Array = []
			for a in found.get("posAlts", []):
				alts.append(int(a))
			ok = _assert(int(found.get("posFine", 0)) == 2 and alts == [5, 6],
				"EQUIPOS.PKF gives Bergsson posFine 2 + posAlts [5,6] (got %s / %s)"
					% [int(found.get("posFine", 0)), alts]) and ok
	else:
		print("  [SKIP] GameDB autoload absent under --script")

	print("test_role_popup: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)


func _assert(cond: bool, label: String) -> bool:
	print(("  ok   " if cond else "  FAIL ") + label)
	return cond
