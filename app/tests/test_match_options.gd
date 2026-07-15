extends SceneTree
## Headless test for MATCH OPTIONS (MatchOptions.gd) — the hub's view-mode SETTINGS dialog
## (the real modal, cut verbatim to art/screens/matchflow/mo_modal.png). Asserts the modal
## sprite loads, the WATCH/HIGHLIGHTS/BRIEF/RESULTS + CANCEL/OK hit-rects route correctly,
## that a mode tap only SELECTS (no proceed), OK confirms the selection (persist), HIGHLIGHTS
## (3D .p3d absent) can be selected but cannot be confirmed, and CANCEL emits cancelled.
##   ~/godot462 --headless --path app --script res://tests/test_match_options.gd


func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true

	for path in ["res://art/screens/matchflow/mo_modal.png", "res://art/fonts/proman10.fnt"]:
		ok = _assert(ResourceLoader.exists(path), "asset present: %s" % path) and ok

	var opt: MatchOptions = load("res://scenes/MatchOptions.gd").new()
	get_root().add_child(opt)
	opt.size = Vector2(640, 480)
	for _i in 3:
		await process_frame

	ok = _assert(opt._modal != null, "modal sprite (mo_modal.png) loaded") and ok
	ok = _assert(opt.SRC_RECTS[0] == Rect2(5, 100, 98, 25) and opt.SRC_RECTS[3] == Rect2(317, 100, 98, 25),
		"reversed source view-rects recorded") and ok

	# Hit-testing at each target's centre returns that target; a gap returns "".
	for m in ["watch", "highlights", "brief", "results", "cancel", "ok"]:
		var c: Vector2 = opt._rect(m).get_center()
		ok = _assert(opt._hit(c) == m, "%s hit-tests to itself" % m) and ok
	ok = _assert(opt._hit(Vector2(2, 2)) == "", "outside the modal is dead space") and ok

	# Settings-dialog routing: a mode tap SELECTS (no emit); OK confirms; CANCEL cancels.
	var got: Array = []
	var cancelled := [false]
	opt.confirmed.connect(func(m: String) -> void: got.append(m))
	opt.cancelled.connect(func() -> void: cancelled[0] = true)

	# setup() opens the dialog showing the stored mode as selected.
	opt.setup("results")
	ok = _assert(opt._sel == opt.MODES.find("results"), "setup(results) selects RESULTS") and ok

	# A view-mode tap only SELECTS it — it must NOT confirm/proceed.
	_tap(opt, "watch")
	ok = _assert(got.is_empty() and opt._sel == opt.MODES.find("watch"), "WATCH tap selects, no emit") and ok
	_tap(opt, "brief")
	ok = _assert(got.is_empty() and opt._sel == opt.MODES.find("brief"), "BRIEF tap selects, no emit") and ok

	# OK confirms the current selection (brief).
	_tap(opt, "ok")
	ok = _assert(got == ["brief"], "OK confirms the selected mode (brief)") and ok

	# HIGHLIGHTS can be selected but OK cannot confirm it (3D .p3d absent) — only notes.
	got.clear()
	_tap(opt, "highlights")
	ok = _assert(opt._sel == opt.MODES.find("highlights") and opt._note != "",
		"HIGHLIGHTS selects + notes 3D-absent") and ok
	_tap(opt, "ok")
	ok = _assert(got.is_empty(), "OK does not confirm HIGHLIGHTS (3D absent)") and ok

	# CANCEL emits cancelled (no mode change committed).
	_tap(opt, "cancel")
	ok = _assert(cancelled[0], "CANCEL emits cancelled") and ok

	# A press on one target released over another must NOT change selection or fire.
	got.clear()
	opt.setup("brief")
	opt._on_input(_touch(opt._rect("brief").get_center(), true))
	opt._on_input(_touch(opt._rect("results").get_center(), false))
	ok = _assert(got.is_empty() and opt._sel == opt.MODES.find("brief"),
		"press/release on different targets does not fire") and ok

	opt.queue_free()
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	quit(0 if ok else 1)


func _tap(opt: MatchOptions, m: String) -> void:
	var c: Vector2 = opt._rect(m).get_center()
	opt._on_input(_touch(c, true))
	opt._on_input(_touch(c, false))


func _touch(pos: Vector2, pressed: bool) -> InputEventScreenTouch:
	var e := InputEventScreenTouch.new()
	e.position = pos
	e.pressed = pressed
	return e


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
