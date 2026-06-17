extends SceneTree
## Headless test for the MATCH SCREEN (MatchScreen.gd) — the real PM98 results /
## commentary view (clock + half, shirts + score, POSSESSION PERCENTAGE bar, the
## minute-by-minute EVENTS table, REPLAY/CONTINUE/EXIT). Asserts the screen is a PURE
## function of the minute over the commentary timeline: score counts goals passed, the
## EVENTS list grows + tracks the latest line, possession eases toward the full split,
## the half label flips, and CONTINUE/EXIT emit back_pressed.
##   ~/godot462 --headless --path app --script res://tests/test_match_screen.gd


func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true

	for path in ["res://art/screens/match_bg.png", "res://art/fonts/proman14.fnt",
			"res://art/fonts/proman10.fnt"]:
		ok = _assert(ResourceLoader.exists(path), "asset present: %s" % path) and ok

	var scr: MatchScreen = load("res://scenes/MatchScreen.gd").new()
	get_root().add_child(scr)
	scr.size = Vector2(640, 480)
	scr.set_process(false)          # freeze clock; seek() drives the minute
	for _i in 3:
		await process_frame
	ok = _assert(scr._bg != null, "blue match background (FONDO9) loaded") and ok

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
	scr.setup("ARSENAL", "CHELSEA", 2, 1, lines, 38, 39)
	await process_frame
	ok = _assert(scr._home_kit != null and scr._away_kit != null, "both shirt escudos loaded") and ok

	# Score counts goals as the clock passes them.
	ok = _assert(scr._score_at(5.0) == Vector2i(0, 0), "0:0 before any goal") and ok
	ok = _assert(scr._score_at(30.0) == Vector2i(1, 0), "1:0 after 23' home goal") and ok
	ok = _assert(scr._score_at(60.0) == Vector2i(1, 1), "1:1 after 58' away goal") and ok
	ok = _assert(scr._score_at(90.0) == Vector2i(2, 1), "2:1 full time") and ok

	# EVENTS list grows with the clock and the newest visible line is the latest event.
	var e10 := scr._events_upto(10.0)
	var e30 := scr._events_upto(30.0)
	ok = _assert(e10.size() == 1 and e30.size() == 3, "events accumulate with the minute (%d -> %d)" % [e10.size(), e30.size()]) and ok
	ok = _assert(str(e30[-1]["text"]) == "Goal by A", "latest event tracks the clock") and ok

	# Possession eases from 50/50 at kick-off toward the full-match split (more home events).
	var p0 := scr._possession_at(0.0)
	var p90 := scr._possession_at(90.0)
	ok = _assert(p0 == 50, "possession is 50%% at kick-off (%d)" % p0) and ok
	ok = _assert(p90 > 50 and p90 == scr._poss_home, "possession resolves to the full-match home split (%d)" % p90) and ok

	# Half label flips with the clock.
	ok = _assert(scr._half_label(20.0) == "FIRST HALF", "first half") and ok
	ok = _assert(scr._half_label(60.0) == "SECOND HALF", "second half") and ok
	ok = _assert(scr._half_label(90.0) == "FULL TIME", "full time") and ok

	# seek() is pure: it sets the minute and stays reproducible.
	scr.seek(58.0)
	ok = _assert(absf(scr._minute - 58.0) < 0.01 and scr._score_at(scr._minute) == Vector2i(1, 1),
		"seek(58) shows 1:1") and ok

	# CONTINUE and EXIT both emit back_pressed; REPLAY restarts the clock.
	var backs: Array = []
	scr.back_pressed.connect(func() -> void: backs.append(true))
	scr._on_input(_touch(scr.CONT_BTN.get_center(), true))
	scr._on_input(_touch(scr.CONT_BTN.get_center(), false))
	scr._on_input(_touch(scr.EXIT_BTN.get_center(), true))
	scr._on_input(_touch(scr.EXIT_BTN.get_center(), false))
	ok = _assert(backs.size() == 2, "CONTINUE + EXIT each emit back_pressed (%d)" % backs.size()) and ok
	scr.seek(90.0)
	scr._on_input(_touch(scr.REPLAY_BTN.get_center(), true))
	scr._on_input(_touch(scr.REPLAY_BTN.get_center(), false))
	ok = _assert(scr._minute == 0.0, "REPLAY restarts the clock") and ok

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
