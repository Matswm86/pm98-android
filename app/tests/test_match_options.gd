extends SceneTree
## Headless test for MATCH OPTIONS (MatchOptions.gd) — the reversed in-match view picker.
## Asserts the four buttons hit-test at their SOURCE-EXACT panel-local rects (from
## FUN_004e2630, docs/re/match_view_re.md), that WATCH/BRIEF/RESULTS emit picked() with the
## right mode, and that HIGHLIGHTS (3D .p3d absent from source) only highlights, never proceeds.
##   ~/godot462 --headless --path app --script res://tests/test_match_options.gd


func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true

	for path in ["res://art/fonts/proman18.fnt", "res://art/fonts/proman12.fnt",
			"res://art/fonts/proman10.fnt"]:
		ok = _assert(ResourceLoader.exists(path), "asset present: %s" % path) and ok

	var opt: MatchOptions = load("res://scenes/MatchOptions.gd").new()
	get_root().add_child(opt)
	opt.size = Vector2(640, 480)
	for _i in 3:
		await process_frame

	# Source-exact rects: WATCH(5,100) HIGHLIGHTS(109,100) BRIEF(214,100) RESULTS(317,100), 98x25.
	var expect := [Rect2(5, 100, 98, 25), Rect2(109, 100, 98, 25),
		Rect2(214, 100, 98, 25), Rect2(317, 100, 98, 25)]
	ok = _assert(opt.BTN_RECTS == expect, "button rects are the reversed source rects") and ok

	# Hit-test at each button's centre (panel-local -> design) returns that index; gaps return -1.
	for i in expect.size():
		var centre: Vector2 = opt.PANEL.position + (expect[i] as Rect2).get_center()
		ok = _assert(opt._btn_at(centre) == i, "%s hit-tests to index %d" % [opt.BTN_LABELS[i], i]) and ok
	# The ~6px gap between WATCH(right=103) and HIGHLIGHTS(left=109) is dead space.
	ok = _assert(opt._btn_at(opt.PANEL.position + Vector2(106, 112)) == -1, "inter-button gap is dead space") and ok
	# Outside the panel entirely.
	ok = _assert(opt._btn_at(Vector2(2, 2)) == -1, "outside the panel is dead space") and ok

	# Routing: WATCH, BRIEF and RESULTS emit picked(); HIGHLIGHTS (3D absent) does not.
	var got: Array = []
	opt.picked.connect(func(m: String) -> void: got.append(m))

	_tap(opt, 0)   # WATCH -> 2D simulador (now built)
	ok = _assert(got == ["watch"] and opt._sel == 0, "WATCH emits picked(watch)") and ok
	_tap(opt, 1)   # HIGHLIGHTS -> 3D .p3d absent: highlights only
	ok = _assert(got == ["watch"] and opt._sel == 1, "HIGHLIGHTS highlights but does not proceed") and ok
	_tap(opt, 2)   # BRIEF
	ok = _assert(got == ["watch", "brief"], "BRIEF emits picked(brief)") and ok
	_tap(opt, 3)   # RESULTS
	ok = _assert(got == ["watch", "brief", "results"], "RESULTS emits picked(results)") and ok

	# A press on one button released over another must NOT fire (press==release guard).
	got.clear()
	opt._on_input(_touch(opt.PANEL.position + (expect[2] as Rect2).get_center(), true))   # press BRIEF
	opt._on_input(_touch(opt.PANEL.position + (expect[3] as Rect2).get_center(), false))  # release on RESULTS
	ok = _assert(got.is_empty(), "press/release on different buttons does not fire") and ok

	opt.queue_free()
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	quit(0 if ok else 1)


func _tap(opt: MatchOptions, i: int) -> void:
	var c: Vector2 = opt.PANEL.position + (opt.BTN_RECTS[i] as Rect2).get_center()
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
