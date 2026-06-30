extends SceneTree
## Headless test for the WATCH 2D simulador (MatchSimulador.gd). Asserts it is a PURE
## function of the same MatchCommentary timeline as BRIEF: the score, possession and the
## attacking side it derives match the feed exactly; the ball stays on the pitch at every
## minute; and the BRIEF / CONTINUE / EXIT buttons route correctly.
##   ~/godot462 --headless --path app --script res://tests/test_match_simulador.gd


func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true

	for path in ["res://art/match/player_base.png", "res://art/match/player_kit.png",
			"res://art/match/ball.png", "res://art/match/arrow.png"]:
		ok = _assert(ResourceLoader.exists(path), "real DATSIM sprite present: %s" % path) and ok

	# A synthetic timeline in the exact MatchCommentary shape: 1-1, home @12, away @58.
	var lines: Array = [
		{"minute": 0, "side": -1, "text": "KICK OFF"},
		{"minute": 12, "side": 0, "text": "Goal by A (Home)", "goal": true},
		{"minute": 30, "side": 1, "text": "Corner taken by B"},
		{"minute": 45, "side": -1, "text": "HALF TIME"},
		{"minute": 58, "side": 1, "text": "Goal by C (Away)", "goal": true},
		{"minute": 70, "side": 0, "text": "Shot saved by D (Away)"},
		{"minute": 90, "side": -1, "text": "FULL TIME"},
	]

	var sim: MatchSimulador = load("res://scenes/MatchSimulador.gd").new()
	get_root().add_child(sim)
	sim.size = Vector2(640, 480)
	for _i in 3:
		await process_frame
	sim.setup("Home", "Away", 1, 1, lines, -1, -1)

	# Score is the same pure function as MatchScreen: goals already played.
	ok = _assert(sim._score_at(0) == Vector2i(0, 0), "score 0' = 0-0") and ok
	ok = _assert(sim._score_at(12) == Vector2i(1, 0), "score 12' = 1-0") and ok
	ok = _assert(sim._score_at(57) == Vector2i(1, 0), "score 57' still 1-0") and ok
	ok = _assert(sim._score_at(58) == Vector2i(1, 1), "score 58' = 1-1") and ok
	ok = _assert(sim._score_at(90) == Vector2i(1, 1), "score FT = 1-1") and ok

	# Attacking side = most recent side-attributed event <= minute (-1 before the first).
	ok = _assert(sim._attacking_side(5) == -1, "loose before first event") and ok
	ok = _assert(sim._attacking_side(20) == 0, "home attacking after 12'") and ok
	ok = _assert(sim._attacking_side(35) == 1, "away attacking after 30' corner") and ok
	ok = _assert(sim._attacking_side(80) == 0, "home attacking after 70' save") and ok

	# Possession: 2 home + 2 away side-events -> 50%, eased from 50 at kick-off.
	ok = _assert(sim._possession_home() == 50, "balanced possession = 50%") and ok
	ok = _assert(sim._possession_at(0) == 50, "possession eases from 50 at KO") and ok

	# The ball never leaves the pitch, at any minute.
	var inside := true
	for mm in range(0, 91, 3):
		sim.seek(float(mm))
		var b: Vector2 = sim._ball_field()
		if b.x < sim.PITCH.position.x - 0.5 or b.x > sim.PITCH.end.x + 0.5 \
				or b.y < sim.PITCH.position.y - 0.5 or b.y > sim.PITCH.end.y + 0.5:
			inside = false
	ok = _assert(inside, "ball stays on the pitch at every minute") and ok

	# seek() drives the clock.
	sim.seek(63.0)
	ok = _assert(is_equal_approx(sim._minute, 63.0), "seek sets the minute") and ok

	# Buttons: BRIEF -> brief_pressed, CONTINUE -> jump to FT, EXIT -> back_pressed.
	var got: Array = []
	sim.brief_pressed.connect(func() -> void: got.append("brief"))
	sim.back_pressed.connect(func() -> void: got.append("back"))

	_tap(sim, sim.BRIEF_BTN.get_center())
	ok = _assert(got == ["brief"], "BRIEF emits brief_pressed") and ok
	_tap(sim, sim.CONT_BTN.get_center())
	ok = _assert(is_equal_approx(sim._minute, 90.0), "CONTINUE runs to full time") and ok
	_tap(sim, sim.EXIT_BTN.get_center())
	ok = _assert(got == ["brief", "back"], "EXIT emits back_pressed") and ok

	# A press on one button released over another must NOT fire.
	got.clear()
	sim._on_input(_touch(sim.BRIEF_BTN.get_center(), true))
	sim._on_input(_touch(sim.EXIT_BTN.get_center(), false))
	ok = _assert(got.is_empty(), "press/release on different buttons does not fire") and ok

	sim.queue_free()
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	quit(0 if ok else 1)


func _tap(sim: MatchSimulador, c: Vector2) -> void:
	sim._on_input(_touch(c, true))
	sim._on_input(_touch(c, false))


func _touch(pos: Vector2, pressed: bool) -> InputEventScreenTouch:
	var e := InputEventScreenTouch.new()
	e.position = pos
	e.pressed = pressed
	return e


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
