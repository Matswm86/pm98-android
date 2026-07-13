extends SceneTree
## Headless test for MATCH OPTIONS (MatchOptions.gd) — the rebuilt in-match presentation
## picker (the real modal, cut verbatim to art/screens/matchflow/mo_modal.png). Asserts the
## modal sprite loads, the WATCH/HIGHLIGHTS/BRIEF/RESULTS + CANCEL/OK hit-rects route
## correctly, that WATCH/BRIEF/RESULTS emit picked() with the right mode, HIGHLIGHTS (3D
## .p3d absent) only shows its honest note, and OK/CANCEL confirm/dismiss.
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
	# Reversed source rects recorded for the record (FUN_004e2630, panel-local).
	ok = _assert(opt.SRC_RECTS[0] == Rect2(5, 100, 98, 25) and opt.SRC_RECTS[3] == Rect2(317, 100, 98, 25),
		"reversed source view-rects recorded") and ok

	# Hit-testing at each target's centre returns that target; a gap returns "".
	for m in ["watch", "highlights", "brief", "results", "cancel", "ok"]:
		var c: Vector2 = opt._rect(m).get_center()
		ok = _assert(opt._hit(c) == m, "%s hit-tests to itself" % m) and ok
	ok = _assert(opt._hit(Vector2(2, 2)) == "", "outside the modal is dead space") and ok

	# Routing: WATCH/BRIEF/RESULTS emit picked(); HIGHLIGHTS only notes; CANCEL->brief.
	var got: Array = []
	opt.picked.connect(func(m: String) -> void: got.append(m))

	_tap(opt, "watch")
	ok = _assert(got == ["watch"], "WATCH emits picked(watch)") and ok
	_tap(opt, "highlights")
	ok = _assert(got == ["watch"] and opt._note != "", "HIGHLIGHTS notes 3D-absent, does not proceed") and ok
	_tap(opt, "brief")
	ok = _assert(got == ["watch", "brief"], "BRIEF emits picked(brief)") and ok
	_tap(opt, "results")
	ok = _assert(got == ["watch", "brief", "results"], "RESULTS emits picked(results)") and ok
	_tap(opt, "cancel")
	ok = _assert(got[-1] == "brief", "CANCEL dismisses to the running BRIEF") and ok

	# OK confirms the current selection (BRIEF was last picked -> _sel == brief).
	got.clear()
	_tap(opt, "ok")
	ok = _assert(got == ["results"] or got == [opt.MODES[opt._sel]], "OK confirms the current selection (%s)" % opt.MODES[opt._sel]) and ok

	# A press on one target released over another must NOT fire.
	got.clear()
	opt._on_input(_touch(opt._rect("brief").get_center(), true))
	opt._on_input(_touch(opt._rect("results").get_center(), false))
	ok = _assert(got.is_empty(), "press/release on different targets does not fire") and ok

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
