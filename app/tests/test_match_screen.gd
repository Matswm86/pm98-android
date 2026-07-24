extends SceneTree
## Headless test for BRIEF-mode (MatchScreen.gd) — the real PM98 running-match read-out.
## Asserts the honest feed: the fabricated RATE_* lines (shots/fouls/cards/corners) are
## DROPPED and only Kick Off + the REAL goal lines survive; the screen is a pure function
## of the minute (score counts goals passed, feed grows, half label flips, seek is pure);
## and KICK OFF (at full time) + EXIT emit back_pressed.
##   ~/godot462 --headless --path app --script res://tests/test_match_screen.gd


func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true

	for path in ["res://art/screens/matchflow/brief.png", "res://art/fonts/proman18.fnt",
			"res://art/fonts/proman10.fnt"]:
		ok = _assert(ResourceLoader.exists(path), "asset present: %s" % path) and ok

	var scr: MatchScreen = load("res://scenes/MatchScreen.gd").new()
	get_root().add_child(scr)
	scr.size = Vector2(640, 480)
	scr.set_process(false)          # freeze the clock; seek() drives the minute
	for _i in 3:
		await process_frame
	ok = _assert(scr._bg != null, "BRIEF background (brief.png) loaded") and ok

	# A timeline mixing real goals with FABRICATED lines the stat engine never produces.
	var lines: Array = [
		{"minute": 0, "side": -1, "text": "KICK OFF"},
		{"minute": 12, "side": 0, "text": "Corner taken by A"},          # fabricated -> DROP
		{"minute": 23, "side": 0, "text": "Goal by A", "goal": true},    # real goal
		{"minute": 34, "side": 1, "text": "Shot saved by B"},            # fabricated -> DROP
		{"minute": 45, "side": -1, "text": "HALF TIME"},
		{"minute": 58, "side": 1, "text": "Goal by B", "goal": true},    # real goal
		{"minute": 71, "side": 0, "text": "Goal by C", "goal": true},    # real goal
		{"minute": 77, "side": 0, "text": "Yellow card: D"},             # fabricated -> DROP
	]
	scr.setup("ARSENAL", "CHELSEA", 2, 1, lines, 38, 39)
	await process_frame

	# FEED: kick-off + every SIDE-TAGGED event. Since 2026-07-23 the BRIEF keeps the
	# surrounding narrative (shots, corners, cards) as well as the goals -- owner: "there
	# are many more match events in the original BRIEF, not only goals". Only the phase
	# markers (side == -1: HALF TIME / FULL TIME) are dropped, because MatchScreen draws
	# the clock itself.
	ok = _assert(scr._feed.size() == 7, "feed = kick-off + 6 side-tagged events (%d)" % scr._feed.size()) and ok
	ok = _assert(bool(scr._feed[0].get("kickoff", false)), "row 0 is the KICK OFF line") and ok
	var phase_markers := 0
	for i in range(1, scr._feed.size()):
		if int(scr._feed[i].get("side", -1)) < 0:
			phase_markers += 1
	ok = _assert(phase_markers == 0, "no phase-marker line survives into the feed") and ok
	var goal_minutes: Array = []
	for i in range(1, scr._feed.size()):
		if bool(scr._feed[i].get("goal", false)):
			goal_minutes.append(int(scr._feed[i]["minute"]))
	ok = _assert(goal_minutes == [23, 58, 71], "the 3 real goals keep their flag + minutes (%s)" % str(goal_minutes)) and ok
	ok = _assert(str(scr._feed[1]["text"]) == "Corner taken by A", "a MatchCommentary line passes through verbatim") and ok

	# The RAW stat-engine goal vector (no pre-formatted text) is the shape that gets the
	# club appended.
	var raw: MatchScreen = load("res://scenes/MatchScreen.gd").new()
	get_root().add_child(raw)
	raw.setup("ARSENAL", "CHELSEA", 1, 0, [{"minute": 23, "side": 0, "scorer": "A"}], 38, 39)
	await process_frame
	ok = _assert(str(raw._feed[1]["text"]) == "Goal by A (ARSENAL)", "raw goal vector names scorer + club") and ok
	raw.queue_free()

	# Score counts goals as the clock passes them.
	ok = _assert(scr._score_at(5.0) == Vector2i(0, 0), "0:0 before any goal") and ok
	ok = _assert(scr._score_at(30.0) == Vector2i(1, 0), "1:0 after 23' home goal") and ok
	ok = _assert(scr._score_at(60.0) == Vector2i(1, 1), "1:1 after 58' away goal") and ok
	ok = _assert(scr._score_at(90.0) == Vector2i(2, 1), "2:1 full time") and ok

	# Feed grows with the clock.
	ok = _assert(scr._events_upto(10.0).size() == 1, "only kick-off before 23'") and ok
	# By 30' the clock has passed the 12' corner and the 23' goal.
	ok = _assert(scr._events_upto(30.0).size() == 3, "kick-off + 12' + 23' by 30' (%d)" % scr._events_upto(30.0).size()) and ok

	# Half/state label flips with the clock.
	ok = _assert(scr._half_label(0.0) == "KICK OFF", "kick off at 0'") and ok
	ok = _assert(scr._half_label(20.0) == "FIRST HALF", "first half") and ok
	ok = _assert(scr._half_label(60.0) == "SECOND HALF", "second half") and ok
	ok = _assert(scr._half_label(90.0) == "FULL TIME", "full time") and ok

	# seek() is pure.
	scr.seek(58.0)
	ok = _assert(absf(scr._minute - 58.0) < 0.01 and scr._score_at(scr._minute) == Vector2i(1, 1),
		"seek(58) shows 1:1") and ok

	# KICK OFF starts the match (does NOT skip to full time). At FULL TIME the
	# chrome swaps (parity orig/68): KICK OFF + doors are GONE and the EXIT slot
	# holds CONTINUE -> continue_pressed; before full time EXIT -> back_pressed.
	var backs: Array = []
	var conts: Array = []
	scr.back_pressed.connect(func() -> void: backs.append(true))
	scr.continue_pressed.connect(func() -> void: conts.append(true))
	scr.seek(20.0)
	scr._playing = false
	scr._on_input(_touch(scr.BTN["kick"].get_center(), true))
	scr._on_input(_touch(scr.BTN["kick"].get_center(), false))
	ok = _assert(scr._playing and scr._minute < 90.0 and backs.is_empty() and conts.is_empty(),
		"KICK OFF starts the match (no skip)") and ok
	scr._on_input(_touch(scr.BTN["exit"].get_center(), true))
	scr._on_input(_touch(scr.BTN["exit"].get_center(), false))
	ok = _assert(backs.size() == 1 and conts.is_empty(), "EXIT before full time emits back_pressed") and ok
	scr.seek(90.0)
	scr._on_input(_touch(scr.BTN["kick"].get_center(), true))
	scr._on_input(_touch(scr.BTN["kick"].get_center(), false))
	ok = _assert(conts.is_empty() and backs.size() == 1, "KICK OFF slot dead at full time (button gone, orig/68)") and ok
	scr._on_input(_touch(scr.BTN["exit"].get_center(), true))
	scr._on_input(_touch(scr.BTN["exit"].get_center(), false))
	ok = _assert(conts.size() == 1 and backs.size() == 1, "EXIT slot at full time is CONTINUE -> continue_pressed") and ok
	ok = _assert(scr._ft_bg != null, "FULL TIME chrome (brief_ft.png) loaded") and ok

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
