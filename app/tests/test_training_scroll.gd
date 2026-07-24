extends SceneTree
## TRAINING per-section scrolling — the owner's "newly signed players never appear
## in TRAINING" (2026-07-24).
##
## The grid used to draw only `mini(bucket.size(), tops.size())` men per section, so a
## squad with more than 3 GK / 6 DF / 6 MF / 5 FW silently lost the overflow, and since
## `Career` appends a signing to the END of the squad the new man was always the one
## that fell off. The original does NOT cap: each section carries its own scrollbar.
## Witnessed live 2026-07-24 (Bolton W, 9 defenders in 6 slots) — one DOWN click moves
## the list by exactly one row.
##
##   ~/godot462 --headless --path app --script res://tests/test_training_scroll.gd

func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true
	var scr: TrainingScreen = load("res://scenes/TrainingScreen.gd").new()
	get_root().add_child(scr)
	scr.size = Vector2(640, 480)
	await process_frame

	# a Bolton-shaped squad: 3 keepers, NINE defenders, 4 midfielders, 6 forwards
	var players: Array = []
	var pid := 1
	for spec in [["GK", 3], ["DF", 9], ["MF", 4], ["FW", 6]]:
		for i in int(spec[1]):
			players.append({"id": pid, "name": "%s%d" % [spec[0], i], "pos": str(spec[0]),
				"isGK": str(spec[0]) == "GK", "squadNo": pid,
				"attrs": {"VE": 70, "RE": 70, "AG": 70, "CA": 70,
					"RM": 70, "RG": 70, "PA": 70, "TI": 70, "EN": 70, "PO": 70}})
			pid += 1
	scr.setup({"id": 1, "name": "Bolton W", "players": players})
	await process_frame

	ok = _assert((scr._buckets["def"] as Array).size() == 9, "9 defenders bucketed") and ok
	ok = _assert(scr._first_of("def") == 0, "the section opens at the top") and ok

	# every man must be REACHABLE, which is what the cap broke
	var seen := {}
	for step in 4:
		for sect in TrainingScreen.SECT:
			var key := str(sect["key"])
			var bucket: Array = scr._buckets[key]
			var first := scr._first_of(key)
			for i in mini(bucket.size() - first, (sect["tops"] as Array).size()):
				seen[int((bucket[first + i] as Dictionary).get("id", -1))] = true
		for sect2 in TrainingScreen.SECT:
			scr._scroll_by(str(sect2["key"]), 1)
	ok = _assert(seen.size() == players.size(),
		"every one of the %d players is reachable by scrolling (saw %d)"
			% [players.size(), seen.size()]) and ok

	# one arrow click == one row (the witnessed step)
	scr._scroll.clear()
	var top0 := int((scr._buckets["def"][scr._first_of("def")] as Dictionary)["id"])
	scr._scroll_by("def", 1)
	var top1 := int((scr._buckets["def"][scr._first_of("def")] as Dictionary)["id"])
	ok = _assert(top1 == top0 + 1, "a DOWN click advances the list by exactly one row") and ok

	# clamping: never past the end, never before the start
	scr._scroll_by("def", 99)
	ok = _assert(scr._first_of("def") == 3, "clamped at total-visible (9-6=3)") and ok
	scr._scroll_by("def", -99)
	ok = _assert(scr._first_of("def") == 0, "clamped at the top") and ok

	# a section that fits has NO live arrows; one that overflows has them
	ok = _assert(scr._scroll_hit(Vector2(320, 90)) == "",
		"KEEPERS (3 of 3) has no live UP arrow") and ok
	var band: Array = TrainingScreen.SCROLL_BAND["def"]
	var dn := Vector2(TrainingScreen.SCROLL_X + 8,
		int(band[0]) + int(band[1]) - TrainingScreen.SCROLL_BTN_H + 7)
	ok = _assert(scr._scroll_hit(dn) == "scroll:def:1",
		"DEFENDERS' DOWN arrow is live (got '%s')" % scr._scroll_hit(dn)) and ok
	ok = _assert(scr._scroll_hit(Vector2(TrainingScreen.SCROLL_X + 8, int(band[0]) + 7)) == "",
		"its UP arrow is dead while parked at the top") and ok
	scr._scroll_by("def", 1)
	ok = _assert(scr._scroll_hit(Vector2(TrainingScreen.SCROLL_X + 8, int(band[0]) + 7))
		== "scroll:def:-1", "and lights once scrolled") and ok

	# the hit test must follow the scroll, or a tap selects the wrong man
	var row0 := Rect2(TrainingScreen.BAR_X0, float((TrainingScreen.SECT[1]["tops"] as Array)[0]),
		TrainingScreen.BAR_W, TrainingScreen.BAR_H)
	ok = _assert(scr._grid_pid_at(row0.get_center()) == top0 + 1,
		"the top DEFENDERS row hit-tests to the scrolled-to player") and ok

	# assets exist (the baker's own output)
	for n in ["scroll_up_on", "scroll_dn_on", "scroll_track_on",
			"scroll_thumb_top", "scroll_thumb_mid", "scroll_thumb_bot"]:
		ok = _assert(ResourceLoader.exists("res://art/screens/training/%s.png" % n),
			"%s.png present" % n) and ok

	scr.queue_redraw()
	await process_frame
	print("test_training_scroll: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)


func _assert(cond: bool, label: String) -> bool:
	print(("  ok   " if cond else "  FAIL ") + label)
	return cond
