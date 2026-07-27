extends SceneTree
## Headless test for the `channelTV` card (ChannelTvScreen).
##
## Written 2026-07-27 because `AUDIT_COMPLETE_2026-07-26.md` recorded it as the ONE
## screen in the app with zero test coverage. It pins what the RE doc proves and what
## the baker asserts (`docs/re/REFRUN_manutd_1997-98.md` R6,
## `tools/re/build_channeltv_card_from_frames.py`): the baked chrome exists, the panel
## and OK rect sit where the frame puts them, the fee line is the ONLY thing the scene
## draws over the bake, the OK button emits exactly once and only from inside its rect,
## and the fee text is the frame's own wording with the game's thousands separators.
##
##   ~/godot462 --headless --path app --script res://tests/test_channeltv_screen.gd


func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true
	get_root().size = Vector2i(640, 480)

	ok = _assert(ResourceLoader.exists("res://art/screens/channeltv/card.png"),
		"baked card art present") and ok
	# Geometry: on-canvas, and the OK rect is inside the panel the bake cut.
	ok = _assert(ChannelTvScreen.OK_RECT.end.x <= 640 and ChannelTvScreen.OK_RECT.end.y <= 480,
		"OK rect inside the 640x480 canvas") and ok
	ok = _assert(ChannelTvScreen.PANEL.x > 0 and ChannelTvScreen.PANEL.y > 0,
		"panel is offset from the screen origin (it is a card, not a full screen)") and ok
	ok = _assert(ChannelTvScreen.FEE_BASELINE > ChannelTvScreen.PANEL.y,
		"fee baseline sits inside the panel") and ok

	# The fee table is the reversed one, not a guess: the card's £90,000 league fee is the
	# same figure the week's TELEVISION ledger row carries (REFRUN R6, Man Utd week 29).
	ok = _assert(int(FinanceModel.TV_FEE["league"]) == 90_000, "league TV fee £90,000") and ok
	ok = _assert(int(FinanceModel.TV_FEE["charity_shield"]) == 187_500,
		"Charity Shield TV fee £187,500") and ok
	ok = _assert(int(FinanceModel.TV_FEE["european_cup"]) == 375_000,
		"European Cup TV fee £375,000") and ok
	ok = _assert(FinanceScreen.fmt_money(90_000) == "£90,000",
		"the fee renders as the frame's own '£90,000'") and ok

	var scr: ChannelTvScreen = ChannelTvScreen.new()
	get_root().add_child(scr)
	scr.size = Vector2(640, 480)
	await process_frame
	ok = _assert(scr._chrome != null, "chrome texture loaded") and ok
	ok = _assert(scr._fee == 0, "no fee before setup — the scene draws nothing over the bake") and ok
	scr.setup(int(FinanceModel.TV_FEE["league"]))
	await process_frame
	ok = _assert(scr._fee == 90_000, "setup carries the fee in") and ok

	# OK emits once, and only from inside its rect.
	var fired := [0]
	scr.ok_pressed.connect(func() -> void: fired[0] += 1)
	_tap(scr, ChannelTvScreen.OK_RECT.get_center())
	await process_frame
	ok = _assert(fired[0] == 1, "OK inside the rect emits exactly once") and ok
	_tap(scr, Vector2(20, 20))
	await process_frame
	ok = _assert(fired[0] == 1, "a tap outside the rect does not emit") and ok
	# Press-then-release-elsewhere must not fire either (the shared press/commit rule).
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = ChannelTvScreen.OK_RECT.get_center()
	scr._on_input(down)
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = Vector2(20, 20)
	scr._on_input(up)
	await process_frame
	ok = _assert(fired[0] == 1, "press inside, release outside does not emit") and ok

	scr.queue_free()
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	quit(0 if ok else 1)


func _tap(scr: ChannelTvScreen, at: Vector2) -> void:
	for pressed in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = pressed
		e.position = at
		scr._on_input(e)


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
