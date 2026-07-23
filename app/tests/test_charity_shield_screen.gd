extends SceneTree
## Headless wiring test for the frame-baked CHARITY SHIELD screen: confirms the baked
## shield.png chrome + proman12/proman8 fonts load, the button/kit geometry stays inside
## the 640x480 canvas, setup() wires winner/runner state (shape exactly as Main.gd's
## _show_shield_card feeds it: {club, manager, club_id, pens}), OK-button hit-testing
## resolves at BTN_OK's centre and misses elsewhere, and a redraw after setup doesn't crash.
##   ~/godot4 --headless --path app --script res://tests/test_charity_shield_screen.gd


func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true

	# Frame-baked chrome + fonts present and loadable.
	for path in ["res://art/screens/seasonflow/shield.png",
			"res://art/fonts/proman12.fnt", "res://art/fonts/proman8.fnt"]:
		ok = _assert(ResourceLoader.exists(path), "asset present: %s" % path) and ok
		ok = _assert(load(path) != null, "asset loads: %s" % path) and ok

	# BTN_OK / KIT_WINNER / KIT_RUNNER stay inside the 640x480 canvas.
	for entry in [["BTN_OK", CharityShieldScreen.BTN_OK], ["KIT_WINNER", CharityShieldScreen.KIT_WINNER],
			["KIT_RUNNER", CharityShieldScreen.KIT_RUNNER]]:
		var r: Rect2 = entry[1]
		ok = _assert(r.position.x >= 0 and r.position.y >= 0 and r.end.x <= 640 and r.end.y <= 480,
			"rect in canvas: %s" % entry[0]) and ok

	# Text baseline Y consts stay inside the canvas.
	for entry in [["WINNER_BASE", CharityShieldScreen.WINNER_BASE],
			["WINNER_MGR_BASE", CharityShieldScreen.WINNER_MGR_BASE],
			["RUNNER_BASE", CharityShieldScreen.RUNNER_BASE],
			["RUNNER_MGR_BASE", CharityShieldScreen.RUNNER_MGR_BASE]]:
		var y: int = entry[1]
		ok = _assert(y >= 0 and y <= 480, "baseline in canvas: %s" % entry[0]) and ok
	ok = _assert(CharityShieldScreen.TXT_X >= 0 and CharityShieldScreen.TXT_X <= 640, "TXT_X in canvas") and ok

	# Instantiate + let _ready load art/fonts.
	var screen: CharityShieldScreen = load("res://scenes/CharityShieldScreen.gd").new()
	get_root().add_child(screen)
	for _i in 3:
		await process_frame
	ok = _assert(screen._chrome != null, "shield chrome loaded") and ok
	ok = _assert(screen._f12 != null and screen._f8 != null, "proman12/proman8 fonts loaded") and ok

	# setup() wires winner/runner exactly as Main.gd's _show_shield_card feeds them.
	var winner := {"club": "Manchester Utd.", "manager": "MWM", "club_id": 1, "pens": true}
	var runner := {"club": "Newcastle", "manager": "Kevin Keegan", "club_id": 2}
	screen.setup(winner, runner)
	await process_frame
	ok = _assert(screen._winner == winner, "winner dict wired") and ok
	ok = _assert(screen._runner == runner, "runner dict wired") and ok

	# BTN_OK hit-testing: centre point (design space, no scaling applied since size==0
	# pre-layout means _to_design's scale s falls back to 1.0) resolves ok_pressed; a
	# point clearly outside the rect does not.
	var fired := [false]  # array wrapper: GDScript lambdas capture locals by value, not by ref
	screen.ok_pressed.connect(func() -> void: fired[0] = true)
	var center := CharityShieldScreen.BTN_OK.position + CharityShieldScreen.BTN_OK.size * 0.5
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = center
	screen._on_input(press)
	ok = _assert(screen._press, "press inside BTN_OK arms _press") and ok
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = center
	screen._on_input(release)
	ok = _assert(fired[0], "release inside BTN_OK fires ok_pressed") and ok
	ok = _assert(not screen._press, "release clears _press") and ok

	fired[0] = false
	var outside := Vector2(-50, -50)
	var press2 := InputEventMouseButton.new()
	press2.button_index = MOUSE_BUTTON_LEFT
	press2.pressed = true
	press2.position = outside
	screen._on_input(press2)
	var release2 := InputEventMouseButton.new()
	release2.button_index = MOUSE_BUTTON_LEFT
	release2.pressed = false
	release2.position = outside
	screen._on_input(release2)
	ok = _assert(not fired[0], "outside-BTN_OK click does not fire ok_pressed") and ok

	# Redraw after setup + input handling doesn't crash.
	screen.queue_redraw()
	for _i in 3:
		await process_frame

	screen.queue_free()
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	quit(0 if ok else 1)


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
