extends SceneTree
## Headless test for A1 — the 2D MATCH VIEW (MatchScreen.gd). Asserts the DATSIM
## atlases load, the timeline -> ball-keyframe + formation build is sane, the layout
## is a PURE function of the minute that keeps all 22 players + the ball on-pitch,
## the scoreboard counts goals as the clock passes them, the ticker tracks the latest
## line, and RETURN emits back_pressed.
##   ~/godot462 --headless --path app --script res://tests/test_match_screen.gd


func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true

	for path in ["res://art/match/player_base.png", "res://art/match/player_kit.png",
			"res://art/match/ball.png", "res://art/match/arrow.png",
			"res://art/screens/barra0.png", "res://art/fonts/proman14.fnt"]:
		ok = _assert(ResourceLoader.exists(path), "asset present: %s" % path) and ok

	var scr: MatchScreen = load("res://scenes/MatchScreen.gd").new()
	get_root().add_child(scr)
	scr.size = Vector2(640, 480)
	scr.set_process(false)          # freeze clock; seek() drives the minute
	for _i in 3:
		await process_frame
	ok = _assert(scr._pbase != null and scr._pkit != null and scr._ball != null, "DATSIM atlases loaded") and ok

	# A synthetic fixture: home goals @23 + @71, away goal @58.
	var lines: Array = [
		{"minute": 0, "side": -1, "text": "KICK OFF"},
		{"minute": 12, "side": 0, "text": "Corner taken by A"},
		{"minute": 23, "side": 0, "text": "Goal by A", "goal": true},
		{"minute": 45, "side": -1, "text": "HALF TIME"},
		{"minute": 58, "side": 1, "text": "Goal by B", "goal": true},
		{"minute": 71, "side": 0, "text": "Goal by C", "goal": true},
		{"minute": 90, "side": -1, "text": "FULL TIME"},
	]
	scr.setup("ARSENAL", "CHELSEA", 2, 1, lines)
	await process_frame
	ok = _assert(scr._slots.size() == 22, "formation has 22 players (%d)" % scr._slots.size()) and ok
	ok = _assert(scr._keys.size() >= lines.size(), "keyframes built (%d)" % scr._keys.size()) and ok
	ok = _assert(scr._col_home != scr._col_away, "the two kits are kept visually distinct") and ok

	# Kit-colour deriver: a club with real kit art yields a saturated colour off the fallback.
	if ResourceLoader.exists("res://art/kits/38.png"):
		var fb := Color(0.5, 0.5, 0.5)
		var c := scr._kit_colour(38, true, fb)
		var sat: float = max(c.r, max(c.g, c.b)) - min(c.r, min(c.g, c.b))
		ok = _assert(c != fb and sat > 0.2, "kit colour derived from kit art (%s sat=%.2f)" % [str(c), sat]) and ok

	# Layout is pure + on-pitch for a sweep of minutes.
	var all_in := true
	for mi in range(0, 91, 3):
		var ball := scr._ball_at(float(mi))
		all_in = all_in and ball["l"] >= -0.01 and ball["l"] <= 1.01 and ball["w"] >= -0.01 and ball["w"] <= 1.01
		var ps := scr._players_at(float(mi), ball)
		all_in = all_in and ps.size() == 22
		for p in ps:
			if p["x"] < -40 or p["x"] > 680 or p["y"] < 80 or p["y"] > 480:
				all_in = false
	ok = _assert(all_in, "ball + 22 players stay on-pitch across all minutes") and ok

	# Painter order is far->near (ascending y) so near players overdraw.
	var ps0 := scr._players_at(40.0, scr._ball_at(40.0))
	var sorted_y := true
	for i in range(1, ps0.size()):
		if ps0[i]["y"] < ps0[i - 1]["y"]:
			sorted_y = false
	ok = _assert(sorted_y, "players painted far->near (y ascending)") and ok

	# Scoreboard counts goals as the clock passes them.
	ok = _assert(scr._score_at(5.0) == Vector2i(0, 0), "0:0 before any goal") and ok
	ok = _assert(scr._score_at(30.0) == Vector2i(1, 0), "1:0 after 23' home goal") and ok
	ok = _assert(scr._score_at(60.0) == Vector2i(1, 1), "1:1 after 58' away goal") and ok
	ok = _assert(scr._score_at(90.0) == Vector2i(2, 1), "2:1 full time") and ok

	# Ticker tracks the latest line at/under the minute.
	ok = _assert(scr._ticker_at(13.0) == "Corner taken by A", "ticker shows latest line") and ok
	ok = _assert(scr._ticker_at(24.0) == "Goal by A", "ticker advances to the goal") and ok

	# A goal keyframe drives the ball to the scoring side's far goal (home -> l~0.95).
	var bg := scr._ball_at(23.0)
	ok = _assert(bg["l"] > 0.8, "ball driven to the right goal on the home goal (l=%.2f)" % bg["l"]) and ok

	# RETURN emits back_pressed.
	var backs: Array = []
	scr.back_pressed.connect(func() -> void: backs.append(true))
	scr._on_input(_touch(Vector2(579, 461), true))
	scr._on_input(_touch(Vector2(579, 461), false))
	ok = _assert(backs.size() == 1, "RETURN emits back_pressed") and ok

	scr.queue_free()
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
