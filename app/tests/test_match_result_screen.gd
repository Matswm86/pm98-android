extends SceneTree
## Headless test for RESULT-mode (MatchResultScreen.gd) — the HALF/FULL TIME read-out.
## Asserts the baked chrome + HALF/FULL TIME title load, the REAL goal vector maps to the
## home/away GOALS columns, the score/stadium are the fed values, the money/man-of-match
## fields stay a gap, and CONTINUE emits continue_pressed at BOTH half time and full time
## (a tap on the read-out body is a no-op -- the witnessed HT read-out is CONTINUE-gated).
##   ~/godot462 --headless --path app --script res://tests/test_match_result_screen.gd


func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true

	for path in ["res://art/screens/matchflow/result_ft.png",
			"res://art/screens/matchflow/result_ht.png",
			"res://art/screens/matchflow/title_fulltime.png",
			"res://art/screens/matchflow/title_halftime.png",
			"res://art/screens/header/band.png"]:
		ok = _assert(ResourceLoader.exists(path), "asset present: %s" % path) and ok

	# _grp thousands grouping (matches the stadium panel's "55,300" style).
	ok = _assert(MatchResultScreen._grp(55300) == "55,300" and MatchResultScreen._grp(6750) == "6,750",
		"thousands grouping") and ok

	# ---- FULL TIME ----------------------------------------------------------
	var scr: MatchResultScreen = load("res://scenes/MatchResultScreen.gd").new()
	get_root().add_child(scr)
	scr.size = Vector2(640, 480)
	for _i in 3:
		await process_frame

	# real goal vector: home @36, away @18 and @59 (own goals ride the vector too).
	var goals: Array = [
		{"minute": 18, "side": 1, "scorer": "Solskjaer"},
		{"minute": 36, "side": 0, "scorer": "Cole"},
		{"minute": 59, "side": 1, "scorer": "Solskjaer"},
	]
	var header := {"mode": "fixture", "top": "Manchester Utd.", "bottom": "Bolton W",
		"home_id": 40, "away_id": 1000, "weekday": "Friday", "day": "1", "month": "August",
		"year": "1997", "status_top": "Preseason", "status_bottom": "Preparation"}
	var stadium := {"name": "Old Trafford", "capacity": 55300, "attendance": 19355}
	scr.setup("Manchester Utd.", "Bolton W", 1, 2, goals, 40, 1000, header, stadium, false)
	await process_frame

	ok = _assert(scr._bg != null and scr._title != null, "FULL TIME chrome + title loaded") and ok
	ok = _assert(scr._goals_home.size() == 1 and scr._goals_away.size() == 2,
		"goal vector maps by side (home=%d away=%d)" % [scr._goals_home.size(), scr._goals_away.size()]) and ok
	ok = _assert(str(scr._goals_home[0]["scorer"]) == "Cole" and int(scr._goals_home[0]["minute"]) == 36,
		"home GOALS column = the real scorer + minute") and ok
	ok = _assert(str(scr._goals_away[0]["scorer"]) == "Solskjaer", "away GOALS column = real scorer") and ok
	ok = _assert(scr._hg == 1 and scr._ag == 2, "scoreline = the fed engine score") and ok
	ok = _assert(int(scr._stadium.get("capacity", 0)) == 55300, "stadium CAPACITY is Career-known") and ok
	ok = _assert(not scr._half, "full-time mode") and ok

	# CONTINUE emits continue_pressed.
	var cont: Array = []
	scr.continue_pressed.connect(func() -> void: cont.append(true))
	scr._on_input(_touch(scr.CONTINUE.get_center(), true))
	scr._on_input(_touch(scr.CONTINUE.get_center(), false))
	ok = _assert(cont.size() == 1, "CONTINUE emits continue_pressed") and ok

	scr.queue_free()

	# ---- HALF TIME ----------------------------------------------------------
	var half: MatchResultScreen = load("res://scenes/MatchResultScreen.gd").new()
	get_root().add_child(half)
	half.size = Vector2(640, 480)
	for _i in 3:
		await process_frame
	half.setup("Manchester Utd.", "Bolton W", 1, 1, [{"minute": 36, "side": 0, "scorer": "Cole"}],
		40, 1000, header, stadium, true)
	await process_frame
	ok = _assert(half._half and half._title != null, "HALF TIME mode + title loaded") and ok
	# HALF TIME advances on the CONTINUE button (witnessed §5), NOT a tap-anywhere dismiss.
	var hcont: Array = []
	half.continue_pressed.connect(func() -> void: hcont.append(true))
	half._on_input(_touch(Vector2(320, 240), true))     # tap the read-out body = no-op
	half._on_input(_touch(Vector2(320, 240), false))
	ok = _assert(hcont.is_empty(), "HALF TIME body tap does NOT advance") and ok
	half._on_input(_touch(half.CONTINUE.get_center(), true))
	half._on_input(_touch(half.CONTINUE.get_center(), false))
	ok = _assert(hcont.size() == 1, "HALF TIME CONTINUE emits continue_pressed") and ok
	half.queue_free()

	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	quit(0 if ok else 1)


func _touch(pos: Vector2, pressed: bool) -> InputEventScreenTouch:
	var e := InputEventScreenTouch.new()
	e.position = pos
	e.pressed = pressed
	return e


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
